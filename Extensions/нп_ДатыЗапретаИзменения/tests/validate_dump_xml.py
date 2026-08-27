#!/usr/bin/env python3
"""Структурная проверка XML выгрузки конфигуратора (формат 2.20).

Ловит ошибки вида «текущее ChildObjects, ожидаемое Constant»: лишние
дочерние элементы объекта, которых нет в XSD MDClasses. Не заменяет
загрузку в конфигуратор и не требует лицензии OneRPA.

Схемы: yellow-hammer/namespace-forest (XSD платформы, © 1С-Софт).
Скачиваются в кэш при первом запуске, в git не кладутся.
"""
from __future__ import annotations

import argparse
import sys
import urllib.request
import xml.etree.ElementTree as ET
from pathlib import Path

XS = "{http://www.w3.org/2001/XMLSchema}"
MD = "{http://v8.1c.ru/8.3/MDClasses}"
XSD_URL = (
    "https://raw.githubusercontent.com/yellow-hammer/namespace-forest/"
    "main/schemas/2.20/v8.1c.ru-8.3-MDClasses.xsd"
)
CACHE = Path("/tmp/1c-dump-xsd/v8.1c.ru-8.3-MDClasses.xsd")

# Fallback, если сеть недоступна: типы без ChildObjects.
NO_CHILD_OBJECTS = {
    "Constant",
    "CommonModule",
    "Role",
    "ScheduledJob",
    "Language",
    "DefinedType",
    "EventSubscription",
}


def load_xsd(path: Path | None = None) -> ET.Element:
    xsd_path = path or CACHE
    if not xsd_path.is_file():
        xsd_path.parent.mkdir(parents=True, exist_ok=True)
        with urllib.request.urlopen(XSD_URL, timeout=30) as resp:
            xsd_path.write_bytes(resp.read())
    return ET.parse(xsd_path).getroot()


def type_sequences(xsd_root: ET.Element) -> dict[str, dict[str, object]]:
    types: dict[str, dict[str, object]] = {}
    for ct in xsd_root.findall(f"{XS}complexType"):
        name = ct.get("name")
        if not name:
            continue
        elems: list[str] = []
        base = None
        for ext in ct.findall(f".//{XS}extension"):
            base = ext.get("base")
            if base and ":" in base:
                base = base.split(":", 1)[1]
        for el in ct.findall(f".//{XS}element"):
            n = el.get("name")
            if n:
                elems.append(n)
        types[name] = {"base": base, "elems": elems}
    return types


def allowed_children(types: dict[str, dict[str, object]], tname: str) -> set[str]:
    seen: list[str] = []
    cur: str | None = tname
    for _ in range(10):
        if not cur:
            break
        info = types.get(cur)
        if not info:
            break
        for e in info["elems"]:  # type: ignore[union-attr]
            if e not in seen:
                seen.append(e)
        cur = info["base"]  # type: ignore[assignment]
    return set(seen)


def local(tag: str) -> str:
    return tag.split("}")[-1]


def validate_tree(dump_root: Path, xsd_root: ET.Element | None = None) -> list[str]:
    types = type_sequences(xsd_root) if xsd_root is not None else {}
    errors: list[str] = []
    for path in sorted(dump_root.rglob("*.xml")):
        try:
            tree = ET.parse(path)
        except ET.ParseError as exc:
            errors.append(f"{path}: XML parse error: {exc}")
            continue
        root = tree.getroot()
        if root.tag != f"{MD}MetaDataObject":
            continue
        kids = list(root)
        if not kids:
            errors.append(f"{path}: empty MetaDataObject")
            continue
        obj = kids[0]
        tname = local(obj.tag)
        if types:
            allowed = allowed_children(types, tname)
            if not allowed:
                errors.append(f"{path}: unknown MDClasses type {tname}")
                continue
        else:
            allowed = {"InternalInfo", "Properties"}
            if tname not in NO_CHILD_OBJECTS:
                allowed.add("ChildObjects")
        extras = [local(ch.tag) for ch in obj if local(ch.tag) not in allowed]
        if extras:
            rel = path.relative_to(dump_root) if dump_root in path.parents else path
            errors.append(
                f"{rel}: extra {extras} in {tname}; allowed={sorted(allowed)}"
            )
        for up in tree.iter():
            if local(up.tag) != "UsePurposes":
                continue
            if list(up):
                continue
            if (up.text or "").strip():
                errors.append(f"{path}: UsePurposes must be FixedArray, not a scalar")
    return errors


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "dump",
        nargs="?",
        default=str(Path(__file__).resolve().parents[1] / "configurator"),
        help="Каталог выгрузки (с Configuration.xml)",
    )
    parser.add_argument("--xsd", type=Path, default=None)
    args = parser.parse_args(argv)
    dump = Path(args.dump)
    try:
        xsd = load_xsd(args.xsd)
    except Exception as exc:  # noqa: BLE001 — сеть опциональна
        print(f"warn: cannot load MDClasses.xsd ({exc}); using fallback rules", file=sys.stderr)
        xsd = None
    errors = validate_tree(dump, xsd)
    if errors:
        print("DUMP XML ERRORS:")
        for err in errors:
            print(f"  {err}")
        return 1
    print(f"ok: dump XML structure matches MDClasses 2.20 ({dump})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
