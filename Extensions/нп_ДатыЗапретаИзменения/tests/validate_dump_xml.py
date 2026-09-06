#!/usr/bin/env python3
"""Структурная проверка XML выгрузки конфигуратора (формат 2.20).

Ловит ошибки вида «текущее ChildObjects, ожидаемое Constant»: лишние
дочерние элементы объекта, которых нет в XSD MDClasses. Также ловит
ввод по строке по Коду при CodeLength=0. Не заменяет загрузку в
конфигуратор и не требует лицензии OneRPA.

Схемы: yellow-hammer/namespace-forest (XSD платформы, © 1С-Софт).
Скачиваются в кэш при первом запуске, в git не кладутся.
"""
from __future__ import annotations

import argparse
import sys
import urllib.request
import xml.etree.ElementTree as ET
from collections import defaultdict
from pathlib import Path

XS = "{http://www.w3.org/2001/XMLSchema}"
MD = "{http://v8.1c.ru/8.3/MDClasses}"
XR = "{http://v8.1c.ru/8.3/xcf/readable}"
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

DOCUMENT_ROOT_TYPE_PREFIXES = (
    "DocumentObject.",
    "DocumentRef.",
    "DocumentSelection.",
    "DocumentList.",
    "DocumentManager.",
)


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
        rel = path.relative_to(dump_root) if dump_root in path.parents else path
        if extras:
            errors.append(
                f"{rel}: extra {extras} in {tname}; allowed={sorted(allowed)}"
            )
        if tname == "Constant":
            default_form = obj.find(f"{MD}Properties/{MD}DefaultForm")
            ref = (default_form.text if default_form is not None else "") or ""
            if ref.strip():
                errors.append(
                    f"{rel}: Constant DefaultForm={ref!r} but dump format has no constant forms"
                )
        if tname == "Document":
            internal = obj.find(f"{MD}InternalInfo")
            if internal is not None:
                for gt in internal.findall(f"{XR}GeneratedType"):
                    name = gt.get("name") or ""
                    if not name.startswith(DOCUMENT_ROOT_TYPE_PREFIXES):
                        errors.append(
                            f"{rel}: Document InternalInfo has {name}; "
                            "TabularSection types belong on the tabular section"
                        )
        for up in tree.iter():
            if local(up.tag) != "UsePurposes":
                continue
            if list(up):
                continue
            if (up.text or "").strip():
                errors.append(f"{path}: UsePurposes must be FixedArray, not a scalar")
    errors.extend(duplicate_generated_id_errors(dump_root))
    errors.extend(common_picture_file_errors(dump_root))
    errors.extend(catalog_input_by_string_errors(dump_root))
    return errors


GENERATED_ID_TAGS = {"TypeId", "ValueId", "ObjectId"}


def duplicate_generated_id_errors(dump_root: Path) -> list[str]:
    """Конфигуратор: «тип порождаемый объектом InternalInfo содержит не уникальное значение»."""
    locations: dict[str, list[str]] = defaultdict(list)
    for path in sorted(dump_root.rglob("*.xml")):
        if path.name == "ConfigDumpInfo.xml":
            continue
        try:
            tree = ET.parse(path)
        except ET.ParseError:
            continue
        rel = path.relative_to(dump_root) if dump_root in path.parents else path
        for el in tree.iter():
            if local(el.tag) not in GENERATED_ID_TAGS:
                continue
            value = (el.text or "").strip().lower()
            if not value:
                continue
            locations[value].append(f"{rel}:{local(el.tag)}")
    errors: list[str] = []
    for value, places in sorted(locations.items()):
        if len(places) < 2:
            continue
        errors.append(
            f"duplicate InternalInfo id {value} in {', '.join(sorted(set(places)))}"
        )
    return errors


def catalog_input_by_string_errors(dump_root: Path) -> list[str]:
    """Конфигуратор: «Указано неверное поле для ввода по строке: Код» при CodeLength=0."""
    errors: list[str] = []
    catalogs = dump_root / "Catalogs"
    if not catalogs.is_dir():
        return errors
    for path in sorted(catalogs.glob("*.xml")):
        try:
            tree = ET.parse(path)
        except ET.ParseError:
            continue
        root = tree.getroot()
        if root.tag != f"{MD}MetaDataObject":
            continue
        catalog = root.find(f"{MD}Catalog")
        if catalog is None:
            continue
        props = catalog.find(f"{MD}Properties")
        if props is None:
            continue
        code_length_el = props.find(f"{MD}CodeLength")
        if code_length_el is None:
            continue
        try:
            code_length = int(float((code_length_el.text or "0").strip() or "0"))
        except ValueError:
            continue
        if code_length != 0:
            continue
        rel = path.relative_to(dump_root) if dump_root in path.parents else path
        input_by_string = props.find(f"{MD}InputByString")
        fields: list[str] = []
        if input_by_string is not None:
            for field in input_by_string:
                text = (field.text or "").strip()
                if text:
                    fields.append(text)
        if not fields:
            errors.append(
                f"{rel}: CodeLength=0 requires InputByString on Description, "
                "not the default Code field"
            )
            continue
        for field in fields:
            tail = field.rsplit(".", 1)[-1]
            if tail == "Code" or field.endswith("StandardAttribute.Code"):
                errors.append(
                    f"{rel}: InputByString uses Code while CodeLength=0: {field}"
                )
        if not any(f.endswith("StandardAttribute.Description") or f.endswith(".Description") for f in fields):
            errors.append(
                f"{rel}: CodeLength=0 InputByString must include StandardAttribute.Description"
            )
    return errors


def common_picture_file_errors(dump_root: Path) -> list[str]:
    """Конфигуратор ищет бинарник в Ext/Picture/<имя из xr:Abs>, не в Ext/."""
    errors: list[str] = []
    pictures_root = dump_root / "CommonPictures"
    if not pictures_root.is_dir():
        return errors
    for meta in sorted(pictures_root.glob("*.xml")):
        ext_dir = pictures_root / meta.stem / "Ext"
        picture_xml = ext_dir / "Picture.xml"
        if not picture_xml.is_file():
            continue
        try:
            tree = ET.parse(picture_xml)
        except ET.ParseError as exc:
            errors.append(f"{picture_xml.relative_to(dump_root)}: XML parse error: {exc}")
            continue
        abs_name = ""
        for el in tree.iter():
            if local(el.tag) == "Abs":
                abs_name = (el.text or "").strip()
                break
        if not abs_name:
            continue
        expected = ext_dir / "Picture" / abs_name
        if expected.is_file():
            continue
        rel = expected.relative_to(dump_root)
        errors.append(
            f"{rel}: CommonPicture binary missing; configurator path is Ext/Picture/{abs_name}"
        )
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
