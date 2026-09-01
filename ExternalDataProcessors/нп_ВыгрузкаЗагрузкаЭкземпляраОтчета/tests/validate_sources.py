#!/usr/bin/env python3
"""Validate source dump of нп_ВыгрузкаЗагрузкаЭкземпляраОтчета without 1C."""

from __future__ import annotations

import sys
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
NS = {"md": "http://v8.1c.ru/8.3/MDClasses", "lf": "http://v8.1c.ru/8.3/xcf/logform"}
PACKAGE_ROOT = "нп_ПакетЭкземпляровОтчетов"
FORMAT_VERSION = "1.0"
PROCESSOR = "нп_ВыгрузкаЗагрузкаЭкземпляраОтчета"

errors: list[str] = []


def fail(message: str) -> None:
    errors.append(message)


def parse_xml(path: Path) -> ET.Element:
    try:
        return ET.parse(path).getroot()
    except ET.ParseError as exc:
        fail(f"XML parse error in {path.relative_to(ROOT)}: {exc}")
        raise SystemExit(1) from exc


def text_of(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def main() -> int:
    meta = ROOT / f"{PROCESSOR}.xml"
    object_module = ROOT / PROCESSOR / "Ext" / "ObjectModule.bsl"
    form_meta = ROOT / PROCESSOR / "Forms" / "Форма.xml"
    form_xml = ROOT / PROCESSOR / "Forms" / "Форма" / "Ext" / "Form.xml"
    form_module = ROOT / PROCESSOR / "Forms" / "Форма" / "Ext" / "Form" / "Module.bsl"
    readme = ROOT / "README.md"
    sample = Path(__file__).parent / "sample_package.xml"

    for path in (meta, object_module, form_meta, form_xml, form_module, readme, sample):
        if not path.exists():
            fail(f"missing file: {path}")

    if errors:
        print("\n".join(errors))
        return 1

    root = parse_xml(meta)
    name = root.findtext(".//{http://v8.1c.ru/8.3/MDClasses}Name")
    if name != PROCESSOR:
        fail(f"processor name {name!r} != {PROCESSOR!r}")

    default_form = root.findtext(".//{http://v8.1c.ru/8.3/MDClasses}DefaultForm") or ""
    if PROCESSOR not in default_form or "Form.Форма" not in default_form:
        fail(f"unexpected DefaultForm: {default_form}")

    processor_el = root.find("{http://v8.1c.ru/8.3/MDClasses}ExternalDataProcessor")
    processor_uuid = processor_el.attrib.get("uuid") if processor_el is not None else None
    object_id_el = root.find(".//{http://v8.1c.ru/8.3/xcf/readable}ObjectId")
    if not processor_uuid or object_id_el is None or object_id_el.text != processor_uuid:
        fail(f"ObjectId must match processor uuid {processor_uuid}")

    object_ids = [el.text for el in root.findall(".//{http://v8.1c.ru/8.3/xcf/readable}TypeId") if el.text]
    object_ids += [el.text for el in root.findall(".//{http://v8.1c.ru/8.3/xcf/readable}ValueId") if el.text]
    form_root = parse_xml(form_meta)
    form_el = form_root.find("{http://v8.1c.ru/8.3/MDClasses}Form")
    form_uuid = form_el.attrib.get("uuid") if form_el is not None else None
    if not form_uuid:
        fail("form metadata is missing uuid")

    collected = [processor_uuid] + object_ids
    if form_uuid:
        collected.append(form_uuid)
    if len(collected) != len(set(collected)):
        fail(f"duplicate UUIDs: {collected}")

    bsl = text_of(object_module)
    for needle in (
        "Функция СведенияОВнешнейОбработке()",
        "Функция ВыгрузитьВДвоичныеДанные(",
        "Функция ЗагрузитьИзДвоичныхДанных(",
        'Возврат "нп_ПакетЭкземпляровОтчетов"',
        'Возврат "1.0"',
        "ОбменДанными.Загрузка = Истина",
        "ЗначенияПоказателейОтчетов",
        "ВерсииЗначенийПоказателей",
        "КомментарииЗначенийПоказателей",
        "БезопасныйРежим = Ложь",
        "ТипКомандыОткрытиеФормы()",
    ):
        if needle not in bsl:
            fail(f"object module missing {needle!r}")

    if "ЭтоГруппа" in bsl:
        fail("query must not use ЭтоГруппа: catalog ВерсииЗначенийПоказателей is not hierarchical")

    form_bsl = text_of(form_module)
    for needle in (
        "Процедура ВыгрузитьВФайл(",
        "Процедура ЗагрузитьИзФайла(",
        "ПоместитьФайлНаСерверАсинх(,,, ПараметрыДиалога, УникальныйИдентификатор)",
        "ПолучитьФайлССервераАсинх",
        "Диалог.Расширение = \"xml\"",
        "Укажите хотя бы один экземпляр отчета",
    ):
        if needle not in form_bsl:
            fail(f"form module missing {needle!r}")

    form = parse_xml(form_xml)
    command_names = [el.attrib.get("name") for el in form.iter() if el.tag.endswith("Command") and el.attrib.get("name")]
    if "ВыгрузитьВФайл" not in command_names or "ЗагрузитьИзФайла" not in command_names:
        fail(f"form commands {command_names} missing export/import")

    attr_names = [el.attrib.get("name") for el in form.iter() if el.tag.endswith("Attribute") and el.attrib.get("name")]
    for required in ("Экземпляры", "ТолькоАктивныеВерсии", "ВыгружатьЧерновыеВерсии", "ЗамещатьСуществующие", "Протокол"):
        if required not in attr_names:
            fail(f"form attribute missing {required}")

    readme_text = text_of(readme)
    if PACKAGE_ROOT not in readme_text or FORMAT_VERSION not in readme_text:
        fail("README does not document package root / format version")

    sample_root = parse_xml(sample)
    if sample_root.tag != PACKAGE_ROOT:
        fail(f"sample root {sample_root.tag!r} != {PACKAGE_ROOT!r}")
    if sample_root.attrib.get("ВерсияФормата") != FORMAT_VERSION:
        fail("sample format version mismatch")
    if sample_root.find("Описание") is None or sample_root.find("Описание/Экземпляр") is None:
        fail("sample package missing Описание/Экземпляр")

    if errors:
        print("FAILED")
        print("\n".join(f"- {item}" for item in errors))
        return 1

    print("OK")
    print(f"processor: {PROCESSOR}")
    print(f"package root: {PACKAGE_ROOT} v{FORMAT_VERSION}")
    print("checked: metadata XML, object module, form, README, sample package")
    return 0


if __name__ == "__main__":
    sys.exit(main())
