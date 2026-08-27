#!/usr/bin/env python3
"""Правила ERP.2026.14 без ИБ 1С: норматив N, разделы, права, состав файлов."""
from __future__ import annotations

import datetime as dt
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
CFG = ROOT / "configurator"
MODULE = (SRC / "CommonModules/нп_ДатыЗапретаИзменения/Module.bsl").read_text(encoding="utf-8")
RIGHTS = (SRC / "Roles/нп_БазовыеПрава/Rights.rights").read_text(encoding="utf-8")
CFG_XML = (CFG / "Configuration.xml").read_text(encoding="utf-8")
SCHEDULE = (CFG / "ScheduledJobs/нп_СдвигДатЗапретаИзменения/Ext/Schedule.xml").read_text(encoding="utf-8")
DOC_MDO = (SRC / "Documents/нп_ЗаявкаНаОткрытиеПериода/нп_ЗаявкаНаОткрытиеПериода.mdo").read_text(encoding="utf-8")
STATE_MDO = (SRC / "InformationRegisters/нп_СостояниеОткрытыхПериодов/нп_СостояниеОткрытыхПериодов.mdo").read_text(
    encoding="utf-8"
)
SETTINGS_MDO = (
    SRC / "InformationRegisters/нп_НастройкиАвтоматическойУстановкиДатЗапрета/нп_НастройкиАвтоматическойУстановкиДатЗапрета.mdo"
).read_text(encoding="utf-8")


def date_by_n(n: int, run_date: dt.date) -> dt.date:
    return run_date - dt.timedelta(days=n)


def restore_due(session_date: dt.date, end_date: dt.date) -> bool:
    return session_date > end_date


def auto_comment(is_group: bool, n: int) -> str:
    if is_group:
        return f"нп_авто|{n:05d}"
    return "нп_авто"


ORG_SECTIONS = [
    "АвансовыеОтчеты",
    "БухгалтерскийУчет",
    "ВводОстатков",
    "ВнеоборотныеАктивы",
    "ВнутреннееТовародвижение",
    "Закупки",
    "МеждународныйУчет",
    "Продажи",
    "ПродажиМеждуОрганизациями",
    "Производство",
    "РегламентныеОперации",
    "РозничныеПродажи",
    "СверкиИКорректировкиЗадолженности",
    "ФинансовыйКонтур",
    "РетроБонусыКлиентов",
    "РетроБонусыПоставщиков",
    "УправлениеРемонтами",
    "УчетПоМСФО",
]

SECTION_UUIDS = {
    "АвансовыеОтчеты": "199db5e2-c45a-4004-9e87-742579e7a749",
    "Банк": "0f558de9-37af-484b-8f46-1ba523cf01d2",
    "БухгалтерскийУчет": "2bdf6479-8eaf-4ec0-93a1-412e8659a178",
    "Бюджетирование": "10b010bf-ff02-407a-b71d-fa3d2c8186cc",
    "ВводОстатков": "c061d639-5929-11ea-87c6-1831bf523f36",
    "ВнеоборотныеАктивы": "1dc4b831-3ca1-11e7-9d6b-e0cb4ed5f5dc",
    "ВнутреннееТовародвижение": "a7c88ae7-129c-45c5-bdcd-df587700fa2d",
    "Закупки": "fc4596d4-f365-4986-b633-fe77017b938f",
    "Касса": "97e0cfbc-3a80-40d5-bbce-ce9c3e87e7d8",
    "МеждународныйУчет": "759a6987-ef82-442c-a4eb-2735afaa10d2",
    "Планирование": "0c370df6-fb93-499d-bec3-81c4b7dcfcf2",
    "Продажи": "f9d6852a-09c2-4505-901e-ac07fa0a73eb",
    "ПродажиМеждуОрганизациями": "c061d63b-5929-11ea-87c6-1831bf523f36",
    "Производство": "8795bd29-84ab-47b5-a59f-4fff6b242bab",
    "РегламентныеОперации": "49fca300-0137-4f5e-bc8d-af6cc30545a3",
    "РозничныеПродажи": "c061d646-5929-11ea-87c6-1831bf523f36",
    "СверкиИКорректировкиЗадолженности": "ece392ee-5209-4bfa-9f32-5b1244b1f74e",
    "СкладскиеОперации": "f37d661e-6540-4890-8642-f7481ff1ee7b",
    "ФинансовыйКонтур": "66a40e05-5ebd-11ea-87c6-1831bf523f36",
    "РетроБонусыКлиентов": "2974da80-1b5e-4d98-8a14-9cb26b560892",
    "РетроБонусыПоставщиков": "9a629851-6440-11ef-8435-005056be3dc8",
    "УправлениеРемонтами": "4fbd7445-50f5-4aa4-ac19-be884591f1b6",
    "УчетПоМСФО": "8a725811-e24d-4522-8995-070a4c2d0784",
}


class DateRulesTests(unittest.TestCase):
    def test_normative_table(self) -> None:
        cases = [
            (0, dt.date(2026, 8, 20), dt.date(2026, 8, 20)),
            (1, dt.date(2026, 8, 20), dt.date(2026, 8, 19)),
            (5, dt.date(2026, 8, 20), dt.date(2026, 8, 15)),
            (5, dt.date(2026, 9, 1), dt.date(2026, 8, 27)),
            (30, dt.date(2026, 9, 1), dt.date(2026, 8, 2)),
        ]
        for n, run, expected in cases:
            self.assertEqual(date_by_n(n, run), expected, f"N={n} on {run}")

    def test_bsl_uses_start_of_day_minus_n(self) -> None:
        self.assertIn("Возврат НачалоДня(ДатаРасчета) - ЧислоДней;", MODULE)

    def test_restore_end_date_inclusive(self) -> None:
        end = dt.date(2026, 8, 22)
        self.assertFalse(restore_due(dt.date(2026, 8, 22), end))
        self.assertTrue(restore_due(dt.date(2026, 8, 23), end))
        self.assertIn("Состояние.ДатаОкончанияДействия < &ДатаСеанса", MODULE)

    def test_cutoff_is_period_start_minus_one_day(self) -> None:
        period_from = dt.date(2026, 7, 1)
        self.assertEqual(period_from - dt.timedelta(days=1), dt.date(2026, 6, 30))
        self.assertIn("Отсечка = НачалоДня(Реквизиты.ПериодС) - 1;", MODULE)

    def test_k_end_date_inclusive(self) -> None:
        agreed = dt.date(2026, 8, 20)
        k = 3
        end = agreed + dt.timedelta(days=k - 1)
        self.assertEqual(end, dt.date(2026, 8, 22))
        self.assertIn("ДатаОкончания = ДатаСогласованияДень + (Реквизиты.СрокДействия - 1) * 86400;", MODULE)


class CanonicalWriteTests(unittest.TestCase):
    def test_for_all_users_enum(self) -> None:
        self.assertIn("Перечисления.ВидыНазначенияДатЗапрета.ДляВсехПользователей", MODULE)

    def test_section_level_object_equals_section(self) -> None:
        self.assertIn("ДобавитьКомбинацию(Результат, РазделДатыЗапрета, РазделДатыЗапрета);", MODULE)

    def test_group_comment_has_padded_n(self) -> None:
        self.assertEqual(auto_comment(True, 30), "нп_авто|00030")
        self.assertEqual(auto_comment(True, 5), "нп_авто|00005")
        self.assertEqual(auto_comment(False, 5), "нп_авто")
        self.assertIn('ПрефиксАвтоКомментария() + "|" + Формат(ЧислоДней, "ЧЦ=5; ЧВН=; ЧГ=0")', MODULE)

    def test_empty_description_on_auto_write(self) -> None:
        self.assertIn("Запись.ОписаниеДатыЗапрета = \"\";", MODULE)

    def test_overlap_keeps_min_cutoff_max_end(self) -> None:
        first, second = dt.date(2026, 6, 30), dt.date(2026, 5, 31)
        self.assertEqual(min(first, second), dt.date(2026, 5, 31))
        self.assertIn("НоваяОтсечка = Мин(ТекущаяТиповая.ДатаЗапрета, Отсечка);", MODULE)
        self.assertIn("НовоеОкончание = Макс(ТекущееСостояние.ДатаОкончанияДействия, ДатаОкончания);", MODULE)
        self.assertIn("ТекущееСостояние.ЗаявкаНаОткрытиеПериода", MODULE)
        self.assertIn("ТекущееСостояние.ДатаЗапретаДоОткрытия", MODULE)


class SectionMapTests(unittest.TestCase):
    def test_eighteen_org_sections_including_ifrs(self) -> None:
        self.assertEqual(len(ORG_SECTIONS), 18)
        self.assertIn("УчетПоМСФО", ORG_SECTIONS)
        block = MODULE.split("Тип(\"СправочникСсылка.Организации\")")[1].split("ИначеЕсли")[0]
        for name in ORG_SECTIONS:
            self.assertIn(f'Имена.Добавить("{name}");', block)

    def test_uuids_match_typical_fill(self) -> None:
        for name, uuid in SECTION_UUIDS.items():
            self.assertIn(f'СоответствиеИдентификаторов.Вставить("{name}", "{uuid}");', MODULE)

    def test_other_object_types(self) -> None:
        self.assertIn('ЗначениеВМассиве("Касса")', MODULE)
        self.assertIn('ЗначениеВМассиве("СкладскиеОперации")', MODULE)
        self.assertIn('ЗначениеВМассиве("Банк")', MODULE)
        self.assertIn('ЗначениеВМассиве("Бюджетирование")', MODULE)
        self.assertIn('ЗначениеВМассиве("Планирование")', MODULE)


class JobAndRightsTests(unittest.TestCase):
    def test_job_order_restore_then_settings(self) -> None:
        restore_at = MODULE.index("ВосстановитьИстекшиеОткрытыеПериоды")
        apply_at = MODULE.index("ПрименитьВключенныеНастройки")
        self.assertLess(restore_at, apply_at)
        skip = MODULE.index("ЕстьДействующееСостояниеКомбинации")
        self.assertGreater(skip, apply_at)

    def test_schedule_2300_daily(self) -> None:
        self.assertIn("T23:00:00", SCHEDULE)
        self.assertIn("<v8:DaysRepeatPeriod>1</v8:DaysRepeatPeriod>", SCHEDULE)

    def test_disable_check_and_version_update(self) -> None:
        self.assertIn("ДатыЗапретаИзменения.ОтключитьПроверкуДатЗапрета", MODULE)
        self.assertIn("ДатыЗапретаИзмененияСлужебный.ОбновитьВерсиюДатЗапретаИзменения", MODULE)

    def test_basic_rights_exclude_settings_and_constant(self) -> None:
        self.assertIn("Document.нп_ЗаявкаНаОткрытиеПериода", RIGHTS)
        self.assertIn("Report.нп_ДействующиеДатыЗапрета", RIGHTS)
        self.assertIn("InformationRegister.нп_СостояниеОткрытыхПериодов", RIGHTS)
        self.assertNotIn("нп_НастройкиАвтоматическойУстановкиДатЗапрета", RIGHTS)
        self.assertNotIn("нп_ПолучателиУведомленийСдвигаДатЗапрета", RIGHTS)

    def test_state_register_not_in_command_interface(self) -> None:
        self.assertIn("<useStandardCommands>false</useStandardCommands>", STATE_MDO)

    def test_settings_reject_empty_pair(self) -> None:
        self.assertIn("Нельзя записывать настройку с незаполненными объектом и разделом", MODULE)

    def test_user_mandatory_on_request(self) -> None:
        self.assertIn("Пользователь (или группа пользователей) обязателен", MODULE)

    def test_document_posting_denied(self) -> None:
        self.assertIn("<posting>Deny</posting>", DOC_MDO)

    def test_keep_mapping_false_in_configurator(self) -> None:
        self.assertIn(
            "<KeepMappingToExtendedConfigurationObjectsByIDs>false</KeepMappingToExtendedConfigurationObjectsByIDs>",
            CFG_XML,
        )

    def test_do_after_handler(self) -> None:
        handler = (
            SRC / "CommonModules/ИнтеграцияС1СДокументооборотБазоваяФункциональностьПереопределяемый/Module.bsl"
        ).read_text(encoding="utf-8")
        self.assertIn('&После("ПриИзмененииСостоянияСогласования")', handler)

    def test_prefix_np(self) -> None:
        self.assertIn("<namePrefix>нп_</namePrefix>", (SRC / "Configuration/Configuration.mdo").read_text(encoding="utf-8"))
        self.assertIn("нп_СдвигДатЗапретаИзменения", MODULE)
        self.assertIn("нп_авто", MODULE)


class LayoutTests(unittest.TestCase):
    REQUIRED = [
        "src/Configuration/Configuration.mdo",
        "src/CommonModules/нп_ДатыЗапретаИзменения/Module.bsl",
        "src/Documents/нп_ЗаявкаНаОткрытиеПериода/ObjectModule.bsl",
        "src/Reports/нп_ДействующиеДатыЗапрета/Templates/ОсновнаяСхемаКомпоновкиДанных/Template.dcs",
        "configurator/Configuration.xml",
        "configurator/ConfigDumpInfo.xml",
        "README.md",
    ]

    def test_required_files(self) -> None:
        for rel in self.REQUIRED:
            self.assertTrue((ROOT / rel).is_file(), rel)

    def test_src_and_configurator_modules_match(self) -> None:
        pairs = [
            (
                "src/CommonModules/нп_ДатыЗапретаИзменения/Module.bsl",
                "configurator/CommonModules/нп_ДатыЗапретаИзменения/Ext/Module.bsl",
            ),
            (
                "src/Documents/нп_ЗаявкаНаОткрытиеПериода/ObjectModule.bsl",
                "configurator/Documents/нп_ЗаявкаНаОткрытиеПериода/Ext/ObjectModule.bsl",
            ),
            (
                "src/Documents/нп_ЗаявкаНаОткрытиеПериода/Forms/ФормаДокумента/Module.bsl",
                "configurator/Documents/нп_ЗаявкаНаОткрытиеПериода/Forms/ФормаДокумента/Ext/Form/Module.bsl",
            ),
        ]
        for src_rel, cfg_rel in pairs:
            self.assertEqual(
                (ROOT / src_rel).read_text(encoding="utf-8"),
                (ROOT / cfg_rel).read_text(encoding="utf-8"),
                src_rel,
            )

    def test_report_classifies_three_sources(self) -> None:
        dcs = (
            SRC / "Reports/нп_ДействующиеДатыЗапрета/Templates/ОсновнаяСхемаКомпоновкиДанных/Template.dcs"
        ).read_text(encoding="utf-8")
        self.assertIn("Временно открытый период", dcs)
        self.assertIn("Автоматическая установка", dcs)
        self.assertIn("Установлено вручную", dcs)
        self.assertIn("Ответственный", dcs)

    def test_settings_object_types(self) -> None:
        for catalog in (
            "Организации",
            "Кассы",
            "Склады",
            "БанковскиеСчетаОрганизаций",
            "Сценарии",
            "СценарииТоварногоПланирования",
        ):
            self.assertIn(f"CatalogRef.{catalog}", SETTINGS_MDO)


if __name__ == "__main__":
    suite = unittest.defaultTestLoader.loadTestsFromModule(sys.modules[__name__])
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    sys.exit(0 if result.wasSuccessful() else 1)
