#!/usr/bin/env python3
"""Правила ERP.2026.14 без ИБ 1С: норматив N, разделы, права, состав файлов."""
from __future__ import annotations

import datetime as dt
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

ROOT = Path(__file__).resolve().parents[1]
CFG = ROOT / "configurator"
MODULE = (CFG / "CommonModules/нп_ДатыЗапретаИзменения/Ext/Module.bsl").read_text(encoding="utf-8")
RIGHTS = (CFG / "Roles/нп_БазовыеПраваДатЗапрета/Ext/Rights.xml").read_text(encoding="utf-8")
CFG_XML = (CFG / "Configuration.xml").read_text(encoding="utf-8")
SCHEDULE = (CFG / "ScheduledJobs/нп_СдвигДатЗапретаИзменения/Ext/Schedule.xml").read_text(encoding="utf-8")
DOC_XML = (CFG / "Documents/нп_ЗаявкаНаОткрытиеПериода.xml").read_text(encoding="utf-8")
STATE_XML = (CFG / "InformationRegisters/нп_СостояниеОткрытыхПериодов.xml").read_text(encoding="utf-8")
SETTINGS_XML = (CFG / "InformationRegisters/нп_НастройкиАвтоматическойУстановкиДатЗапрета.xml").read_text(
    encoding="utf-8"
)
FORM_XML = (
    CFG / "Documents/нп_ЗаявкаНаОткрытиеПериода/Forms/ФормаДокумента/Ext/Form.xml"
).read_text(encoding="utf-8")
DCS = (
    CFG / "Reports/нп_ДействующиеДатыЗапрета/Templates/ОсновнаяСхемаКомпоновкиДанных/Ext/Template.xml"
).read_text(encoding="utf-8")
REPORT_MODULE = (CFG / "Reports/нп_ДействующиеДатыЗапрета/Ext/ObjectModule.bsl").read_text(encoding="utf-8")


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

    def test_bsl_subtracts_n_days_in_seconds(self) -> None:
        self.assertIn("Возврат НачалоДня(ДатаРасчета) - ЧислоДней * 86400;", MODULE)
        self.assertNotIn("Возврат НачалоДня(ДатаРасчета) - ЧислоДней;", MODULE)

    def test_restore_end_date_inclusive(self) -> None:
        end = dt.date(2026, 8, 22)
        self.assertFalse(restore_due(dt.date(2026, 8, 22), end))
        self.assertTrue(restore_due(dt.date(2026, 8, 23), end))
        self.assertIn("Состояние.ДатаОкончанияДействия < &ДатаСеанса", MODULE)

    def test_cutoff_is_period_start_minus_one_day(self) -> None:
        period_from = dt.date(2026, 7, 1)
        self.assertEqual(period_from - dt.timedelta(days=1), dt.date(2026, 6, 30))
        self.assertIn("Отсечка = НачалоДня(Реквизиты.ПериодС) - 86400;", MODULE)

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

    def test_saves_previous_skip_flag(self) -> None:
        self.assertIn("ДатыЗапретаИзменения.ПроверкаДатЗапретаОтключена()", MODULE)
        self.assertIn("ЗакончитьЗаписьТиповогоРегистра(ПроверкаБылаОтключена)", MODULE)
        self.assertNotIn("Процедура ВыполнитьЗаписьТиповогоРегистра", MODULE)


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

    def test_section_uuid_compare_is_case_insensitive(self) -> None:
        self.assertIn("НРег(Строка(СсылкаРаздела.УникальныйИдентификатор()))", MODULE)


class JobAndRightsTests(unittest.TestCase):
    def test_job_order_restore_then_settings(self) -> None:
        restore_at = MODULE.index("ВосстановитьИстекшиеОткрытыеПериоды")
        apply_at = MODULE.index("ПрименитьВключенныеНастройки")
        self.assertLess(restore_at, apply_at)
        skip = MODULE.index("ЕстьДействующееСостояниеКомбинации")
        self.assertGreater(skip, apply_at)

    def test_job_actualizes_auto_and_skips_manual(self) -> None:
        self.assertIn("УдалитьУстаревшиеАвтозаписи", MODULE)
        self.assertIn("ЭтоРучнаяТиповаяЗапись", MODULE)
        self.assertIn("ЭтоАвтоматическаяТиповаяЗапись", MODULE)
        self.assertLess(
            MODULE.index("ПрименитьОднуНастройку"),
            MODULE.index("УдалитьУстаревшиеАвтозаписи"),
        )
        self.assertIn("Даты.Комментарий ПОДОБНО &ПрефиксАвто", MODULE)
        self.assertIn("ТекущаяТиповая.ЕстьЗапись И ЭтоРучнаяТиповаяЗапись", MODULE)
        self.assertIn("Если ОшибокНастроек = 0 Тогда", MODULE)
        self.assertIn("Удалены устаревшие автоматические записи типового регистра", MODULE)

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
        self.assertNotIn("нп_ФормаПолучателейУведомленийСдвигаДатЗапрета", RIGHTS)

    def test_state_register_in_command_interface(self) -> None:
        self.assertIn("<UseStandardCommands>true</UseStandardCommands>", STATE_XML)
        self.assertIn("Состояния открытых периодов (НП)", STATE_XML)
        self.assertIn(
            "InformationRegister.нп_СостояниеОткрытыхПериодов.Form.ФормаСписка",
            STATE_XML,
        )
        subsystem = (CFG / "Subsystems/нп_ДатыЗапретаИзменения.xml").read_text(
            encoding="utf-8"
        )
        self.assertIn("<IncludeInCommandInterface>true</IncludeInCommandInterface>", subsystem)
        self.assertIn(
            "InformationRegister.нп_СостояниеОткрытыхПериодов",
            subsystem,
        )
        state_rights = RIGHTS.split(
            "InformationRegister.нп_СостояниеОткрытыхПериодов", 1
        )[1].split("</object>", 1)[0]
        self.assertIn("<name>View</name>", state_rights)
        self.assertNotIn("<name>Update</name>", state_rights)
        list_form = (
            CFG
            / "InformationRegisters/нп_СостояниеОткрытыхПериодов/Forms/ФормаСписка/Ext/Form.xml"
        ).read_text(encoding="utf-8")
        self.assertIn("InformationRegister.нп_СостояниеОткрытыхПериодов", list_form)
        self.assertLess(
            list_form.find("Список.Пользователь"),
            list_form.find("Список.ОбъектДатыЗапрета"),
        )

    def test_settings_allow_empty_pair(self) -> None:
        self.assertNotIn(
            "Нельзя записывать настройку с незаполненными объектом и разделом",
            MODULE,
        )
        self.assertIn("Пустые объект и раздел одновременно допустимы", MODULE)
        self.assertIn("ДобавитьКомбинацию(Результат, ПустойРаздел, ПустойРаздел)", MODULE)

    def test_request_allows_empty_pair(self) -> None:
        self.assertNotIn("Укажите хотя бы один раздел", MODULE)
        self.assertNotIn("Укажите разделы и объекты в таблице", MODULE)
        self.assertIn("РазвернутыеКомбинацииНастройки(Неопределено, РазделШапки)", MODULE)

    def test_native_np_object_synonyms_have_np_marker(self) -> None:
        missing = []
        paths = [CFG / "Configuration.xml", *sorted(CFG.glob("*/нп_*.xml"))]
        self.assertGreaterEqual(len(paths), 12, paths)
        for path in paths:
            text = path.read_text(encoding="utf-8")
            props = text.split("<Properties>", 1)[-1].split("</Properties>", 1)[0]
            if "(НП)" not in props:
                missing.append(str(path.relative_to(CFG)))
        self.assertEqual(missing, [])

    def test_report_dcs_titles_have_np_marker(self) -> None:
        self.assertIn("Действующие даты запрета (НП)", DCS)
        self.assertNotIn("<v8:content>Действующие даты запрета</v8:content>", DCS)

    def test_user_mandatory_on_request(self) -> None:
        self.assertGreaterEqual(
            MODULE.count("Пользователь (или группа пользователей) обязателен"),
            2,
        )
        self.assertIn("не «для всех»", MODULE)

    def test_document_posting_denied(self) -> None:
        self.assertIn("<Posting>Deny</Posting>", DOC_XML)

    def test_keep_mapping_false_in_configurator(self) -> None:
        self.assertIn(
            "<KeepMappingToExtendedConfigurationObjectsByIDs>false</KeepMappingToExtendedConfigurationObjectsByIDs>",
            CFG_XML,
        )

    def test_do_after_handler(self) -> None:
        handler = (
            CFG
            / "CommonModules/ИнтеграцияС1СДокументооборотБазоваяФункциональностьПереопределяемый/Ext/Module.bsl"
        ).read_text(encoding="utf-8")
        self.assertIn('&После("ПриИзмененииСостоянияСогласования")', handler)
        self.assertIn('&После("ПриОпределенииТиповОбъектовПоддерживающихИнтеграцию")', handler)
        self.assertIn(
            '&После("ПриОпределенииНеобходимостиВыводитьКомандуПрисоединенныхФайловДО")',
            handler,
        )
        self.assertIn(
            'Форма.ИмяФормы <> "Документ.нп_ЗаявкаНаОткрытиеПериода.Форма.ФормаДокумента"',
            handler,
        )
        self.assertIn("ДокументСсылка.нп_ЗаявкаНаОткрытиеПериода", handler)

    def test_request_is_in_do_integration_defined_types(self) -> None:
        all_refs = (
            CFG / "DefinedTypes/ИнтеграцияС1СДокументооборотВсеСсылкиПереопределяемый.xml"
        ).read_text(encoding="utf-8")
        doc_objects = (
            CFG / "DefinedTypes/ИнтеграцияС1СДокументооборотДокументыОбъектыПереопределяемый.xml"
        ).read_text(encoding="utf-8")
        self.assertIn("DocumentRef.нп_ЗаявкаНаОткрытиеПериода", all_refs)
        self.assertIn("<ObjectBelonging>Adopted</ObjectBelonging>", all_refs)
        self.assertIn("<xr:Property>Type</xr:Property>", all_refs)
        self.assertIn("<xr:State>Extended</xr:State>", all_refs)
        self.assertIn("DocumentObject.нп_ЗаявкаНаОткрытиеПериода", doc_objects)
        self.assertIn("<ObjectBelonging>Adopted</ObjectBelonging>", doc_objects)
        self.assertIn("<xr:Property>Type</xr:Property>", doc_objects)
        self.assertIn("<xr:State>Extended</xr:State>", doc_objects)
        self.assertIn(
            "<DefinedType>ИнтеграцияС1СДокументооборотВсеСсылкиПереопределяемый</DefinedType>",
            CFG_XML,
        )
        self.assertIn(
            "<DefinedType>ИнтеграцияС1СДокументооборотДокументыОбъектыПереопределяемый</DefinedType>",
            CFG_XML,
        )
        form_module = (
            CFG / "Documents/нп_ЗаявкаНаОткрытиеПериода/Forms/ФормаДокумента/Ext/Form/Module.bsl"
        ).read_text(encoding="utf-8")
        self.assertIn(
            "ИнтеграцияС1СДокументооборотБазоваяФункциональность.ПриСозданииНаСервере",
            form_module,
        )
        self.assertIn("ПодключаемыеКоманды.ПриСозданииНаСервере", form_module)
        self.assertIn("ПодключаемыеКомандыКлиент.ПослеЗаписи(ЭтотОбъект, Объект, ПараметрыЗаписи)", form_module)
        self.assertNotIn(
            "ПодключаемыеКомандыКлиент.ПослеЗаписи(ЭтотОбъект, ПараметрыЗаписи)",
            form_module,
        )
        self.assertIn("Подключаемый_ВыполнитьКомандуИнтеграции", form_module)
        self.assertIn("РаботаСФайлами.ПриСозданииНаСервере", form_module)
        self.assertIn("Подключаемый_КомандаПанелиПрисоединенныхФайлов", form_module)
        self.assertNotIn("РазместитьКомандуДокументооборотНаФорме", form_module)
        self.assertIn("Form.Command.ЗакрытьПериодДосрочно", FORM_XML)
        self.assertNotIn("Form.Command.Печать", FORM_XML)
        self.assertNotIn("Form.Command.Файлы", FORM_XML)
        self.assertNotIn("Form.Command.ОтправитьНаСогласование", FORM_XML)
        self.assertNotIn("CommandName>CommonCommand.ИнтеграцияС1СДокументооборот", FORM_XML)
        self.assertNotIn("CommandName>CommonCommand.ПрисоединенныеФайлы", FORM_XML)
        self.assertNotIn("CommonCommand.ИнтеграцияС1СДокументооборотНачатьОбработку", FORM_XML)
        self.assertIn("<PagesRepresentation>None</PagesRepresentation>", FORM_XML)
        self.assertIn(">Основное</v8:content>", FORM_XML)
        self.assertIn("<Command>CommonCommand.ПрисоединенныеФайлы</Command>", FORM_XML)
        self.assertNotIn("<Command>CommonCommand.нп_Документооборот</Command>", FORM_XML)
        self.assertNotIn("<Command>CommonCommand.ИнтеграцияС1СДокументооборот</Command>", FORM_XML)
        self.assertIn("<CommandGroup>FormNavigationPanelGoTo</CommandGroup>", FORM_XML)
        self.assertNotIn("<CommandGroup>CommandGroup.Документооборот</CommandGroup>", FORM_XML)
        self.assertIn("<Attribute>Объект.Ссылка</Attribute>", FORM_XML)
        self.assertIn("<Type>Added</Type>", FORM_XML)
        self.assertIn("<NavigationPanel>", FORM_XML)
        self.assertLess(
            FORM_XML.find("</AutoCommandBar>"),
            FORM_XML.find('<Pages name="Страницы"'),
        )
        self.assertGreater(
            FORM_XML.find('<Pages name="Страницы"'),
            FORM_XML.find("\t<ChildItems>\n\t\t<Pages"),
        )
        self.assertNotIn("УправлениеПечатьюКлиент.ВыполнитьКомандуПечати", form_module)
        self.assertNotIn("ПрисоединитьПечатнуюФормуКДокументу", form_module)
        self.assertNotIn("ИнтеграцияС1СДокументооборот3Клиент.НачатьОбработку", form_module)
        self.assertIn("<CommonCommand>ИнтеграцияС1СДокументооборот</CommonCommand>", CFG_XML)
        self.assertIn("<CommonCommand>нп_Документооборот</CommonCommand>", CFG_XML)
        self.assertIn("<CommonCommand>ПрисоединенныеФайлы</CommonCommand>", CFG_XML)
        self.assertIn("<CommandGroup>Документооборот</CommandGroup>", CFG_XML)
        self.assertIn(
            "<CommonModule>СозданиеНаОснованииПереопределяемый</CommonModule>",
            CFG_XML,
        )
        create_based = (
            CFG / "CommonModules/СозданиеНаОснованииПереопределяемый/Ext/Module.bsl"
        ).read_text(encoding="utf-8")
        self.assertIn('&После("ПриОпределенииОбъектовСКомандамиСозданияНаОсновании")', create_based)
        self.assertIn("Метаданные.Документы.нп_ЗаявкаНаОткрытиеПериода", create_based)
        self.assertTrue(
            (CFG / "CommonCommands/ИнтеграцияС1СДокументооборот.xml").is_file()
        )
        self.assertTrue(
            (CFG / "CommonCommands/ИнтеграцияС1СДокументооборотНачатьОбработку.xml").is_file()
        )
        self.assertTrue((CFG / "CommonCommands/ПрисоединенныеФайлы.xml").is_file())
        self.assertTrue((CFG / "CommonCommands/нп_Документооборот.xml").is_file())
        self.assertTrue(
            (CFG / "CommonCommands/нп_Документооборот/Ext/CommandModule.bsl").is_file()
        )
        self.assertIn(
            "<ExtendedConfigurationObject>b8a32c33-4e15-4c21-baab-64a86d44321b</ExtendedConfigurationObject>",
            (CFG / "CommonCommands/ПрисоединенныеФайлы.xml").read_text(encoding="utf-8"),
        )
        do_cmd = (CFG / "CommonCommands/ИнтеграцияС1СДокументооборот.xml").read_text(
            encoding="utf-8"
        )
        start_cmd = (
            CFG / "CommonCommands/ИнтеграцияС1СДокументооборотНачатьОбработку.xml"
        ).read_text(encoding="utf-8")
        native_cmd = (CFG / "CommonCommands/нп_Документооборот.xml").read_text(
            encoding="utf-8"
        )
        native_module = (
            CFG / "CommonCommands/нп_Документооборот/Ext/CommandModule.bsl"
        ).read_text(encoding="utf-8")
        self.assertNotIn("<xr:Property>CommandParameterType</xr:Property>", do_cmd)
        self.assertNotIn("<CommandParameterType>", do_cmd)
        self.assertNotIn("DocumentRef.нп_ЗаявкаНаОткрытиеПериода", do_cmd)
        self.assertIn("<ObjectBelonging>Adopted</ObjectBelonging>", do_cmd)
        self.assertIn(
            "<ExtendedConfigurationObject>68dc1359-7c42-42d1-afe3-445c6347a703</ExtendedConfigurationObject>",
            do_cmd,
        )
        self.assertNotIn("<xr:Property>CommandParameterType</xr:Property>", start_cmd)
        self.assertNotIn("<CommandParameterType>", start_cmd)
        self.assertIn("DocumentRef.нп_ЗаявкаНаОткрытиеПериода", native_cmd)
        self.assertIn("<Group>CommandGroup.Документооборот</Group>", native_cmd)
        self.assertIn(">Документооборот</v8:content>", native_cmd)
        self.assertIn(
            "ИнтеграцияС1СДокументооборотБазоваяФункциональностьКлиент.ПередВыполнениемКоманды",
            native_module,
        )
        self.assertIn(
            "Обработка.ИнтеграцияС1СДокументооборот3.Форма.Документооборот",
            native_module,
        )
        self.assertIn("CommonCommand.нп_Документооборот", RIGHTS)
        self.assertNotIn("CommonCommand.ИнтеграцияС1СДокументооборот<", RIGHTS)
        self.assertTrue((CFG / "CommandGroups/Документооборот.xml").is_file())
        self.assertNotIn("РазместитьКомандуДокументооборотНаФорме", MODULE)
        self.assertNotIn('Кнопка.ИмяКоманды = "ОбщаяКоманда.ИнтеграцияС1СДокументооборот"', MODULE)


class PrintFormTests(unittest.TestCase):
    def test_print_command_registered_for_bsp_and_do(self) -> None:
        manager = (
            CFG / "Documents/нп_ЗаявкаНаОткрытиеПериода/Ext/ManagerModule.bsl"
        ).read_text(encoding="utf-8")
        print_overridable = (
            CFG / "CommonModules/УправлениеПечатьюПереопределяемый/Ext/Module.bsl"
        ).read_text(encoding="utf-8")
        self.assertIn("Процедура ПриОпределенииНастроекПечати(Настройки) Экспорт", manager)
        self.assertIn("Настройки.ПриДобавленииКомандПечати = Истина", manager)
        self.assertIn("Процедура ДобавитьКомандыПечати(КомандыПечати) Экспорт", manager)
        self.assertIn("Процедура ДобавитьКомандыСозданияНаОсновании(КомандыСозданияНаОсновании, Параметры) Экспорт", manager)
        self.assertIn('КомандаПечати.Идентификатор = "ЗаявкаНаОткрытиеПериода"', manager)
        self.assertIn(
            'КомандаПечати.МенеджерПечати = "Документ.нп_ЗаявкаНаОткрытиеПериода"',
            manager,
        )
        self.assertIn("Процедура Печать(", manager)
        self.assertIn('НужноПечататьМакет(КоллекцияПечатныхФорм, "ЗаявкаНаОткрытиеПериода")', manager)
        self.assertIn("ПроверкаПроведенияПередПечатью = Ложь", manager)
        self.assertIn('ПолучитьМакет("ПФ_MXL_ЗаявкаНаОткрытиеПериода")', manager)
        self.assertIn("ВывестиЗаявкиБезМакета", manager)
        self.assertIn("ВывестиЗаявкиПоМакету", manager)
        print_proc = manager.split("Процедура Печать(", 1)[1].split("КонецПроцедуры", 1)[0]
        self.assertIn("Попытка", print_proc)
        self.assertIn("ПрисоединитьПечатнуюФормуКДокументу(ДокументСсылка)", print_proc)
        self.assertIn("ЗаписатьОшибкуПечати", print_proc)
        self.assertGreater(print_proc.find("Попытка"), print_proc.find("ВывестиТабличныйДокументВКоллекцию"))
        self.assertGreater(
            print_proc.find("ПрисоединитьПечатнуюФормуКДокументу(ДокументСсылка)"),
            print_proc.find("Попытка"),
        )
        self.assertIn('&После("ПриОпределенииНастроекПечати")', print_overridable)
        self.assertIn(
            "Настройки.ОбъектыПечати.Добавить(Документы.нп_ЗаявкаНаОткрытиеПериода)",
            print_overridable,
        )
        self.assertIn(
            "<CommonModule>УправлениеПечатьюПереопределяемый</CommonModule>",
            CFG_XML,
        )
        self.assertIn("<ObjectBelonging>Adopted</ObjectBelonging>", (
            CFG / "CommonModules/УправлениеПечатьюПереопределяемый.xml"
        ).read_text(encoding="utf-8"))

    def test_print_template_has_named_areas_and_main_fields(self) -> None:
        template = (
            CFG
            / "Documents/нп_ЗаявкаНаОткрытиеПериода/Templates/ПФ_MXL_ЗаявкаНаОткрытиеПериода/Ext/Template.xml"
        ).read_text(encoding="utf-8")
        manager = (
            CFG / "Documents/нп_ЗаявкаНаОткрытиеПериода/Ext/ManagerModule.bsl"
        ).read_text(encoding="utf-8")
        self.assertIn("<TemplateType>SpreadsheetDocument</TemplateType>", (
            CFG
            / "Documents/нп_ЗаявкаНаОткрытиеПериода/Templates/ПФ_MXL_ЗаявкаНаОткрытиеПериода.xml"
        ).read_text(encoding="utf-8"))
        self.assertIn("<Name>ПФ_MXL_ЗаявкаНаОткрытиеПериода</Name>", (
            CFG
            / "Documents/нп_ЗаявкаНаОткрытиеПериода/Templates/ПФ_MXL_ЗаявкаНаОткрытиеПериода.xml"
        ).read_text(encoding="utf-8"))
        for area in ("Заголовок", "Шапка", "ШапкаТаблицы", "Строка", "СтрокаПустая"):
            self.assertIn(f"<name>{area}</name>", template)
            self.assertIn(f'ПолучитьОбласть("{area}")', manager)
        for parameter in (
            "Пользователь",
            "ПериодС",
            "СрокДействия",
            "СпособУказания",
            "ПричинаОткрытия",
            "Ответственный",
            "Раздел",
            "Объект",
        ):
            self.assertIn(f"<parameter>{parameter}</parameter>", template)
        self.assertIn("Все разделы/объекты", manager)
        self.assertIn("Все разделы/объекты", template)
        self.assertNotIn("все разделы / общая дата адресата", manager)
        self.assertNotIn("общая дата адресата. Пользователь", template)
        self.assertIn("общая дата раздела", manager)
        self.assertIn("ПрефиксацияОбъектовКлиентСервер.НомерНаПечать", manager)
        self.assertIn("<horizontalAlignment>Left</horizontalAlignment>", template)
        self.assertIn("Открыть период с", template)
        self.assertNotIn(">Период с</v8:content>", template)
        self.assertIn("<Template>ПФ_MXL_ЗаявкаНаОткрытиеПериода</Template>", DOC_XML)
        self.assertIn(
            "<DefaultListForm>Document.нп_ЗаявкаНаОткрытиеПериода.Form.ФормаСписка</DefaultListForm>",
            DOC_XML,
        )

    def test_list_form_has_connected_commands(self) -> None:
        list_module = (
            CFG
            / "Documents/нп_ЗаявкаНаОткрытиеПериода/Forms/ФормаСписка/Ext/Form/Module.bsl"
        ).read_text(encoding="utf-8")
        list_form = (
            CFG
            / "Documents/нп_ЗаявкаНаОткрытиеПериода/Forms/ФормаСписка/Ext/Form.xml"
        ).read_text(encoding="utf-8")
        self.assertIn("ПодключаемыеКоманды.ПриСозданииНаСервере", list_module)
        self.assertIn(
            "ИнтеграцияС1СДокументооборотБазоваяФункциональность.ПриСозданииНаСервере",
            list_module,
        )
        self.assertIn("Document.нп_ЗаявкаНаОткрытиеПериода", list_form)
        self.assertIn("<Form>ФормаСписка</Form>", DOC_XML)
        self.assertNotIn("Form.Command.Печать", list_form)
        self.assertNotIn("Form.Command.Файлы", list_form)
        self.assertNotIn("CommandName>CommonCommand.ИнтеграцияС1СДокументооборот", list_form)
        self.assertNotIn("CommonCommand.ИнтеграцияС1СДокументооборотНачатьОбработку", list_form)
        self.assertNotIn("<Command>CommonCommand.нп_Документооборот</Command>", list_form)
        self.assertNotIn("<Command>CommonCommand.ИнтеграцияС1СДокументооборот</Command>", list_form)
        self.assertNotIn("<Attribute>Список.Ссылка</Attribute>", list_form)
        self.assertNotIn("<CommandGroup>CommandGroup.Документооборот</CommandGroup>", list_form)
        self.assertNotIn("<NavigationPanel>", list_form)
        self.assertIn("Подключаемый_ВыполнитьКомандуИнтеграции", list_module)
        self.assertNotIn("РазместитьКомандуДокументооборотНаФорме", list_module)
        self.assertNotIn("<Command name=\"Печать\"", list_form)
        self.assertNotIn("<Command name=\"Файлы\"", list_form)
        self.assertNotIn("УправлениеПечатьюКлиент.ВыполнитьКомандуПечати", list_module)
        self.assertNotIn("Обработка.РаботаСФайлами.Форма.ПрисоединенныеФайлы", list_module)
        self.assertNotIn("Элементы.Список.ТекущаяСтрока", list_module)
        self.assertNotIn("ТекущиеДанные.Ссылка", list_module)

    def test_attached_files_catalog_registered_for_bsp_and_do(self) -> None:
        files_xml = (
            CFG / "Catalogs/нп_ЗаявкаНаОткрытиеПериодаПрисоединенныеФайлы.xml"
        ).read_text(encoding="utf-8")
        owner_type = (
            CFG / "DefinedTypes/ВладелецПрисоединенныхФайлов.xml"
        ).read_text(encoding="utf-8")
        owner_object = (
            CFG / "DefinedTypes/ВладелецПрисоединенныхФайловОбъект.xml"
        ).read_text(encoding="utf-8")
        file_type = (CFG / "DefinedTypes/ПрисоединенныйФайл.xml").read_text(encoding="utf-8")
        file_object = (
            CFG / "DefinedTypes/ПрисоединенныйФайлОбъект.xml"
        ).read_text(encoding="utf-8")
        manager = (
            CFG / "Documents/нп_ЗаявкаНаОткрытиеПериода/Ext/ManagerModule.bsl"
        ).read_text(encoding="utf-8")
        self.assertIn("<Name>нп_ЗаявкаНаОткрытиеПериодаПрисоединенныеФайлы</Name>", files_xml)
        self.assertIn("<Name>ВладелецФайла</Name>", files_xml)
        self.assertIn("DocumentRef.нп_ЗаявкаНаОткрытиеПериода", files_xml)
        self.assertIn("<Name>Том</Name>", files_xml)
        self.assertIn("<Name>Служебный</Name>", files_xml)
        self.assertIn("<Name>ТипХраненияФайла</Name>", files_xml)
        self.assertIn("<Hierarchical>true</Hierarchical>", files_xml)
        self.assertIn("<UseStandardCommands>false</UseStandardCommands>", files_xml)
        self.assertIn("<CodeLength>0</CodeLength>", files_xml)
        self.assertIn("<InputByString>", files_xml)
        self.assertIn(
            "Catalog.нп_ЗаявкаНаОткрытиеПериодаПрисоединенныеФайлы.StandardAttribute.Description",
            files_xml,
        )
        self.assertNotIn("StandardAttribute.Code", files_xml)
        self.assertIn("<CreateOnInput>DontUse</CreateOnInput>", files_xml)
        self.assertIn("<xr:State>Extended</xr:State>", owner_type)
        self.assertIn("DocumentRef.нп_ЗаявкаНаОткрытиеПериода", owner_type)
        self.assertIn("DocumentObject.нп_ЗаявкаНаОткрытиеПериода", owner_object)
        self.assertIn("CatalogRef.нп_ЗаявкаНаОткрытиеПериодаПрисоединенныеФайлы", file_type)
        self.assertIn("CatalogObject.нп_ЗаявкаНаОткрытиеПериодаПрисоединенныеФайлы", file_object)
        self.assertIn(
            "<DefinedType>ВладелецПрисоединенныхФайлов</DefinedType>",
            CFG_XML,
        )
        self.assertIn(
            "<Catalog>нп_ЗаявкаНаОткрытиеПериодаПрисоединенныеФайлы</Catalog>",
            CFG_XML,
        )
        self.assertIn("Catalog.нп_ЗаявкаНаОткрытиеПериодаПрисоединенныеФайлы", RIGHTS)
        self.assertIn("Процедура ПрисоединитьПечатнуюФормуКДокументу(", manager)
        self.assertIn("ПрисоединитьПечатнуюФормуКДокументу(ДокументСсылка)", manager)
        self.assertIn("РаботаСФайлами.ДобавитьФайл", manager)
        self.assertIn("РаботаСФайлами.ОбновитьФайл", manager)
        self.assertIn("ТипФайлаТабличногоДокумента.PDF", manager)
        self.assertIn(
            "<Catalog>ТомаХраненияФайлов</Catalog>",
            CFG_XML,
        )
        self.assertTrue(
            (
                CFG
                / "Catalogs/нп_ЗаявкаНаОткрытиеПериодаПрисоединенныеФайлы/Ext/ManagerModule.bsl"
            ).is_file()
        )

    def test_prefix_np(self) -> None:
        self.assertIn("<NamePrefix>нп_</NamePrefix>", CFG_XML)
        self.assertIn("нп_СдвигДатЗапретаИзменения", MODULE)
        self.assertIn("нп_авто", MODULE)

    def test_role_name_does_not_clash_with_np(self) -> None:
        self.assertIn("<Role>нп_БазовыеПраваДатЗапрета</Role>", CFG_XML)
        self.assertNotIn("<Role>нп_БазовыеПрава</Role>", CFG_XML)
        self.assertIn("<Name>нп_БазовыеПраваДатЗапрета</Name>", (CFG / "Roles/нп_БазовыеПраваДатЗапрета.xml").read_text(encoding="utf-8"))


class LayoutTests(unittest.TestCase):
    REQUIRED = [
        "configurator/Configuration.xml",
        "configurator/ConfigDumpInfo.xml",
        "configurator/CommonModules/нп_ДатыЗапретаИзменения/Ext/Module.bsl",
        "configurator/Documents/нп_ЗаявкаНаОткрытиеПериода/Ext/ObjectModule.bsl",
        "configurator/Documents/нп_ЗаявкаНаОткрытиеПериода/Ext/ManagerModule.bsl",
        "configurator/Documents/нп_ЗаявкаНаОткрытиеПериода/Templates/ПФ_MXL_ЗаявкаНаОткрытиеПериода/Ext/Template.xml",
        "configurator/Documents/нп_ЗаявкаНаОткрытиеПериода/Forms/ФормаСписка/Ext/Form.xml",
        "configurator/Catalogs/нп_ЗаявкаНаОткрытиеПериодаПрисоединенныеФайлы.xml",
        "configurator/DefinedTypes/ВладелецПрисоединенныхФайлов.xml",
        "configurator/DefinedTypes/ПрисоединенныйФайл.xml",
        "configurator/CommonModules/УправлениеПечатьюПереопределяемый/Ext/Module.bsl",
        "configurator/CommonModules/СозданиеНаОснованииПереопределяемый/Ext/Module.bsl",
        "configurator/CommonCommands/ИнтеграцияС1СДокументооборот.xml",
        "configurator/CommonCommands/ИнтеграцияС1СДокументооборотНачатьОбработку.xml",
        "configurator/CommonCommands/ПрисоединенныеФайлы.xml",
        "configurator/CommonCommands/нп_Документооборот.xml",
        "configurator/CommonCommands/нп_Документооборот/Ext/CommandModule.bsl",
        "configurator/CommandGroups/Документооборот.xml",
        "configurator/Reports/нп_ДействующиеДатыЗапрета/Templates/ОсновнаяСхемаКомпоновкиДанных/Ext/Template.xml",
        "configurator/InformationRegisters/нп_СостояниеОткрытыхПериодов/Forms/ФормаСписка.xml",
        "configurator/InformationRegisters/нп_СостояниеОткрытыхПериодов/Forms/ФормаСписка/Ext/Form.xml",
        "configurator/CommonPictures/нп_ДатыЗапретаИзменения16.xml",
        "configurator/CommonPictures/нп_ДатыЗапретаИзменения16/Ext/Picture.xml",
        "configurator/CommonPictures/нп_ДатыЗапретаИзменения16/Ext/Picture/Picture.png",
        "configurator/DefinedTypes/ИнтеграцияС1СДокументооборотВсеСсылкиПереопределяемый.xml",
        "configurator/DefinedTypes/ИнтеграцияС1СДокументооборотДокументыОбъектыПереопределяемый.xml",
        "README.md",
    ]

    def test_required_files(self) -> None:
        for rel in self.REQUIRED:
            self.assertTrue((ROOT / rel).is_file(), rel)
        self.assertFalse((ROOT / "src").exists(), "EDT src/ must not be shipped")

    def test_report_classifies_three_sources(self) -> None:
        self.assertIn("Временно открытый период", DCS)
        self.assertIn("Автоматическая установка", DCS)
        self.assertIn("Установлено вручную", DCS)
        self.assertIn("Ответственный", DCS)

    def test_report_empty_composite_join(self) -> None:
        self.assertIn("ЗНАЧЕНИЕ(Справочник.Организации.ПустаяСсылка)", DCS)
        self.assertIn("ЗНАЧЕНИЕ(Справочник.Пользователи.ПустаяСсылка)", DCS)
        self.assertIn("ПриКомпоновкеРезультата", REPORT_MODULE)
        self.assertIn("УстановитьПривилегированныйРежим(Истина)", REPORT_MODULE)

    def test_report_dcs_binds_query_to_defined_data_source(self) -> None:
        self.assertIn("<name>ИсточникДанных1</name>", DCS)
        self.assertIn("<dataSource>ИсточникДанных1</dataSource>", DCS)
        self.assertNotIn("ИсточникДанных2", DCS)

    def test_subsystem_has_16px_picture(self) -> None:
        subsystem = (CFG / "Subsystems/нп_ДатыЗапретаИзменения.xml").read_text(encoding="utf-8")
        self.assertIn("CommonPicture.нп_ДатыЗапретаИзменения16", subsystem)
        self.assertIn("<Comment>По заявке на доработку ERP.2026.14</Comment>", subsystem)
        self.assertIn("<CommonPicture>нп_ДатыЗапретаИзменения16</CommonPicture>", CFG_XML)
        png = CFG / "CommonPictures/нп_ДатыЗапретаИзменения16/Ext/Picture/Picture.png"
        self.assertGreaterEqual(png.stat().st_size, 50)
        self.assertEqual(png.read_bytes()[:8], b"\x89PNG\r\n\x1a\n")

    def test_settings_list_has_single_form_command_bar(self) -> None:
        list_form = (
            CFG
            / "InformationRegisters/нп_НастройкиАвтоматическойУстановкиДатЗапрета/Forms/ФормаСписка/Ext/Form.xml"
        ).read_text(encoding="utf-8")
        self.assertIn("<CommandBarLocation>None</CommandBarLocation>", list_form)
        self.assertIn("<Autofill>false</Autofill>", list_form)
        self.assertIn("<AutoAdd>false</AutoAdd>", list_form)

    def test_notify_recipients_single_service_command(self) -> None:
        constant = (
            CFG / "Constants/нп_ПолучателиУведомленийСдвигаДатЗапрета.xml"
        ).read_text(encoding="utf-8")
        form_meta = (
            CFG / "CommonForms/нп_ФормаПолучателейУведомленийСдвигаДатЗапрета.xml"
        ).read_text(encoding="utf-8")
        subsystem = (CFG / "Subsystems/нп_ДатыЗапретаИзменения.xml").read_text(encoding="utf-8")
        self.assertIn("<UseStandardCommands>false</UseStandardCommands>", constant)
        self.assertIn("<UseStandardCommands>true</UseStandardCommands>", form_meta)
        self.assertIn("CommonForm.нп_ФормаПолучателейУведомленийСдвигаДатЗапрета", subsystem)
        self.assertEqual(subsystem.count("нп_ФормаПолучателейУведомленийСдвигаДатЗапрета"), 1)

    def test_settings_object_types(self) -> None:
        for catalog in (
            "Организации",
            "Кассы",
            "Склады",
            "БанковскиеСчетаОрганизаций",
            "Сценарии",
            "СценарииТоварногоПланирования",
        ):
            self.assertIn(f"CatalogRef.{catalog}", SETTINGS_XML)

    def test_form_uses_decorations_and_russian_standard_attrs(self) -> None:
        self.assertIn('<LabelDecoration name="ПояснениеОтсечки"', FORM_XML)
        self.assertIn('<LabelDecoration name="СостояниеСогласования"', FORM_XML)
        self.assertNotIn("LabelField", FORM_XML)
        self.assertIn("<DataPath>Объект.Номер</DataPath>", FORM_XML)
        self.assertIn("<DataPath>Объект.Дата</DataPath>", FORM_XML)
        self.assertNotIn("Объект.Number", FORM_XML)
        self.assertNotIn("Объект.Date", FORM_XML)

    def test_request_form_plain_labels_and_typical_mode(self) -> None:
        self.assertIn("Пользователь (кому)", FORM_XML)
        self.assertIn(">Раздел</v8:content>", FORM_XML)
        self.assertIn(">Объект</v8:content>", FORM_XML)
        self.assertNotIn("Раздел даты запрета", FORM_XML)
        self.assertNotIn("Объект даты запрета", FORM_XML)
        self.assertIn("<Height>2</Height>", FORM_XML)
        self.assertIn("<HorizontalStretch>true</HorizontalStretch>", FORM_XML)
        self.assertIn('name="СпособУказания"', FORM_XML)
        self.assertIn("Объект.Объекты.РазделДатыЗапрета", FORM_XML)
        self.assertIn("Согласованная заявка разрешает менять документы", MODULE)
        self.assertNotIn("задание каждый день в 23:00", MODULE)
        self.assertIn(">Открыть период с</v8:content>", DOC_XML)
        self.assertIn("«Открыть период с»", MODULE)
        self.assertNotIn(">Период с</v8:content>", DOC_XML)
        self.assertNotIn("Отсечка открывает", MODULE)
        enum_xml = (CFG / "Enums/нп_СпособыУказанияОткрытияПериода.xml").read_text(encoding="utf-8")
        self.assertIn("<Name>ПоРазделам</Name>", enum_xml)
        self.assertIn("<Name>ПоРазделамИОбъектам</Name>", enum_xml)
        self.assertIn("УказаниеЗаявкиПоРазделам", MODULE)
        self.assertIn("<Enum>нп_СпособыУказанияОткрытияПериода</Enum>", CFG_XML)

    def test_settings_list_has_columns(self) -> None:
        list_form = (
            CFG
            / "InformationRegisters/нп_НастройкиАвтоматическойУстановкиДатЗапрета/Forms/ФормаСписка/Ext/Form.xml"
        ).read_text(encoding="utf-8")
        record_form = (
            CFG
            / "InformationRegisters/нп_НастройкиАвтоматическойУстановкиДатЗапрета/Forms/ФормаЗаписи/Ext/Form.xml"
        ).read_text(encoding="utf-8")
        self.assertIn("Список.ОбъектДатыЗапрета", list_form)
        self.assertIn("Список.ЧислоДней", list_form)
        self.assertIn("Список.Включено", list_form)
        user_pos = SETTINGS_XML.find("<Name>Пользователь</Name>")
        object_pos = SETTINGS_XML.find("<Name>ОбъектДатыЗапрета</Name>")
        section_pos = SETTINGS_XML.find("<Name>РазделДатыЗапрета</Name>")
        self.assertLess(user_pos, object_pos)
        self.assertLess(object_pos, section_pos)
        self.assertLess(
            list_form.find("Список.Пользователь"),
            list_form.find("Список.ОбъектДатыЗапрета"),
        )
        self.assertLess(
            list_form.find("Список.ОбъектДатыЗапрета"),
            list_form.find("Список.РазделДатыЗапрета"),
        )
        self.assertLess(
            record_form.find("Запись.Пользователь"),
            record_form.find("Запись.ОбъектДатыЗапрета"),
        )
        self.assertLess(
            record_form.find("Запись.ОбъектДатыЗапрета"),
            record_form.find("Запись.РазделДатыЗапрета"),
        )

    def test_tz_settings_dimensions_order(self) -> None:
        tz = (
            ROOT.parents[1]
            / "openspec/changes/np-dates-of-prohibition-setup/tz-extract.txt"
        ).read_text(encoding="utf-8")
        table = tz.split("--- ТАБЛИЦА 2 ---", 1)[1].split("--- ТАБЛИЦА 3 ---", 1)[0]
        self.assertLess(table.find("Пользователь | Измерение"), table.find("ОбъектДатыЗапрета | Измерение"))
        self.assertLess(table.find("ОбъектДатыЗапрета | Измерение"), table.find("РазделДатыЗапрета | Измерение"))

    def test_tz_request_has_no_italic_notes(self) -> None:
        import zipfile

        italic_notes = (
            "уточнены алгоритмы, добавлены критерии приёмки",
            "Заполняется инициатором совместно с администратором ИБ",
            "предложением инициатора и может быть скорректирован",
            "Подробные алгоритмы и структура метаданных детализируются",
        )
        tz = (
            ROOT.parents[1]
            / "openspec/changes/np-dates-of-prohibition-setup/tz-extract.txt"
        ).read_text(encoding="utf-8")
        docx = ROOT.parents[1] / "ERP.2026.14 Заявка на доработку 1С ERP УХ (ред. 2)_1.docx"
        with zipfile.ZipFile(docx) as archive:
            body = archive.read("word/document.xml").decode("utf-8")
        self.assertNotIn("<w:i/>", body)
        self.assertNotIn("<w:i>", body)
        for note in italic_notes:
            self.assertNotIn(note, tz)
            self.assertNotIn(note, body)

    def test_form_use_purposes_is_fixed_array(self) -> None:
        found = 0
        for path in CFG.rglob("*.xml"):
            text = path.read_text(encoding="utf-8")
            if "<UsePurposes>" not in text:
                continue
            found += 1
            self.assertNotRegex(
                text,
                r"<UsePurposes>[^<\s]",
                msg=f"UsePurposes must be FixedArray in {path.relative_to(CFG)}",
            )
            self.assertIn(
                '<v8:Value xsi:type="app:ApplicationUsePurpose">PlatformApplication</v8:Value>',
                text,
            )
        self.assertGreaterEqual(found, 4)


class DumpXmlStructureTests(unittest.TestCase):
    def test_constant_has_no_child_objects(self) -> None:
        constant = (
            CFG / "Constants/нп_ПолучателиУведомленийСдвигаДатЗапрета.xml"
        ).read_text(encoding="utf-8")
        self.assertNotIn("<ChildObjects>", constant)
        self.assertIn("<DefaultForm/>", constant)
        self.assertNotIn("Form.ФормаКонстанты", constant)
        self.assertTrue(
            (
                CFG
                / "CommonForms/нп_ФормаПолучателейУведомленийСдвигаДатЗапрета.xml"
            ).is_file()
        )
        self.assertTrue(
            (
                CFG
                / "CommonForms/нп_ФормаПолучателейУведомленийСдвигаДатЗапрета/Ext/Form.xml"
            ).is_file()
        )
        self.assertFalse(
            (
                CFG
                / "Constants/нп_ПолучателиУведомленийСдвигаДатЗапрета/Forms"
            ).exists()
        )

    def test_document_internal_info_has_no_tabular_section_types(self) -> None:
        internal = DOC_XML.split("<Properties>", 1)[0]
        self.assertNotIn("DocumentTabularSection.", internal)
        self.assertIn("DocumentTabularSection.нп_ЗаявкаНаОткрытиеПериода.Объекты", DOC_XML)

    def test_mdclasses_rejects_extra_children(self) -> None:
        from validate_dump_xml import load_xsd, validate_tree

        xsd = load_xsd()
        errors = validate_tree(CFG, xsd)
        self.assertEqual(errors, [], "\n".join(errors))

    def test_validator_catches_constant_child_objects(self) -> None:
        from validate_dump_xml import load_xsd, validate_tree
        import tempfile

        snippet = """<?xml version="1.0" encoding="UTF-8"?>
<MetaDataObject xmlns="http://v8.1c.ru/8.3/MDClasses" version="2.20">
	<Constant uuid="00000000-0000-0000-0000-000000000001">
		<Properties><Name>Test</Name></Properties>
		<ChildObjects><Form>ФормаКонстанты</Form></ChildObjects>
	</Constant>
</MetaDataObject>
"""
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "Constants" / "Test.xml"
            path.parent.mkdir(parents=True)
            path.write_text(snippet, encoding="utf-8")
            errors = validate_tree(Path(tmp), load_xsd())
        self.assertTrue(any("ChildObjects" in e and "Constant" in e for e in errors), errors)

    def test_validator_catches_constant_default_form_ref(self) -> None:
        from validate_dump_xml import load_xsd, validate_tree
        import tempfile

        snippet = """<?xml version="1.0" encoding="UTF-8"?>
<MetaDataObject xmlns="http://v8.1c.ru/8.3/MDClasses" version="2.20">
	<Constant uuid="00000000-0000-0000-0000-000000000001">
		<Properties>
			<Name>Test</Name>
			<DefaultForm>Constant.Test.Form.ФормаКонстанты</DefaultForm>
		</Properties>
	</Constant>
</MetaDataObject>
"""
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "Constants" / "Test.xml"
            path.parent.mkdir(parents=True)
            path.write_text(snippet, encoding="utf-8")
            errors = validate_tree(Path(tmp), load_xsd())
        self.assertTrue(any("DefaultForm" in e for e in errors), errors)

    def test_generated_type_ids_are_unique(self) -> None:
        from validate_dump_xml import duplicate_generated_id_errors

        self.assertEqual(duplicate_generated_id_errors(CFG), [])
        enum_xml = (CFG / "Enums/нп_СпособыУказанияОткрытияПериода.xml").read_text(
            encoding="utf-8"
        )
        report_xml = (CFG / "Reports/нп_ДействующиеДатыЗапрета.xml").read_text(
            encoding="utf-8"
        )
        self.assertIn("0000000020a0", enum_xml)
        self.assertNotIn("000000002094", enum_xml)
        self.assertIn("000000002094", report_xml)

    def test_common_picture_binary_is_in_ext_picture_folder(self) -> None:
        from validate_dump_xml import common_picture_file_errors

        self.assertEqual(common_picture_file_errors(CFG), [])
        png = CFG / "CommonPictures/нп_ДатыЗапретаИзменения16/Ext/Picture/Picture.png"
        self.assertTrue(png.is_file(), png)
        self.assertFalse(
            (CFG / "CommonPictures/нп_ДатыЗапретаИзменения16/Ext/Picture.png").exists()
        )

    def test_validator_catches_common_picture_in_wrong_folder(self) -> None:
        from validate_dump_xml import common_picture_file_errors
        import tempfile

        picture_xml = """<?xml version="1.0" encoding="UTF-8"?>
<ExtPicture xmlns="http://v8.1c.ru/8.3/xcf/extrnprops" xmlns:xr="http://v8.1c.ru/8.3/xcf/readable" version="2.20">
	<Picture>
		<xr:Abs>Picture.png</xr:Abs>
	</Picture>
</ExtPicture>
"""
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            ext = root / "CommonPictures" / "Тест" / "Ext"
            ext.mkdir(parents=True)
            (root / "CommonPictures" / "Тест.xml").write_text(
                "<MetaDataObject/>", encoding="utf-8"
            )
            (ext / "Picture.xml").write_text(picture_xml, encoding="utf-8")
            (ext / "Picture.png").write_bytes(b"\x89PNG\r\n\x1a\nnot-a-real-png")
            errors = common_picture_file_errors(root)
        self.assertTrue(any("Ext/Picture/Picture.png" in e for e in errors), errors)

    def test_validator_catches_duplicate_generated_ids(self) -> None:
        from validate_dump_xml import duplicate_generated_id_errors
        import tempfile

        snippet_a = """<?xml version="1.0" encoding="UTF-8"?>
<MetaDataObject xmlns="http://v8.1c.ru/8.3/MDClasses" xmlns:xr="http://v8.1c.ru/8.3/xcf/readable" version="2.20">
	<Report uuid="00000000-0000-0000-0000-0000000000aa">
		<InternalInfo>
			<xr:GeneratedType name="ReportObject.Тест" category="Object">
				<xr:TypeId>aaaaaaaa-bbbb-cccc-dddd-000000000001</xr:TypeId>
				<xr:ValueId>aaaaaaaa-bbbb-cccc-dddd-000000000002</xr:ValueId>
			</xr:GeneratedType>
		</InternalInfo>
		<Properties><Name>Тест</Name></Properties>
	</Report>
</MetaDataObject>
"""
        snippet_b = snippet_a.replace("0000000000aa", "0000000000bb").replace(
            "ReportObject.Тест", "EnumRef.Тест"
        )
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "Reports").mkdir()
            (root / "Enums").mkdir()
            (root / "Reports" / "A.xml").write_text(snippet_a, encoding="utf-8")
            (root / "Enums" / "B.xml").write_text(snippet_b, encoding="utf-8")
            errors = duplicate_generated_id_errors(root)
        self.assertTrue(any("aaaaaaaa-bbbb-cccc-dddd-000000000001" in e for e in errors), errors)

    def test_validator_catches_document_tabular_types_on_root(self) -> None:
        from validate_dump_xml import load_xsd, validate_tree
        import tempfile

        snippet = """<?xml version="1.0" encoding="UTF-8"?>
<MetaDataObject xmlns="http://v8.1c.ru/8.3/MDClasses" xmlns:xr="http://v8.1c.ru/8.3/xcf/readable" version="2.20">
	<Document uuid="00000000-0000-0000-0000-000000000002">
		<InternalInfo>
			<xr:GeneratedType name="DocumentObject.Тест" category="Object"/>
			<xr:GeneratedType name="DocumentTabularSection.Тест.Объекты" category="TabularSection"/>
		</InternalInfo>
		<Properties><Name>Тест</Name></Properties>
		<ChildObjects/>
	</Document>
</MetaDataObject>
"""
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "Documents" / "Тест.xml"
            path.parent.mkdir(parents=True)
            path.write_text(snippet, encoding="utf-8")
            errors = validate_tree(Path(tmp), load_xsd())
        self.assertTrue(any("TabularSection" in e for e in errors), errors)

    def test_validator_catches_code_input_by_string_when_code_length_zero(self) -> None:
        from validate_dump_xml import catalog_input_by_string_errors
        import tempfile

        snippet = """<?xml version="1.0" encoding="UTF-8"?>
<MetaDataObject xmlns="http://v8.1c.ru/8.3/MDClasses" xmlns:xr="http://v8.1c.ru/8.3/xcf/readable" version="2.20">
	<Catalog uuid="00000000-0000-0000-0000-000000000003">
		<InternalInfo/>
		<Properties>
			<Name>Файлы</Name>
			<CodeLength>0</CodeLength>
			<InputByString>
				<xr:Field>Catalog.Файлы.StandardAttribute.Code</xr:Field>
			</InputByString>
		</Properties>
		<ChildObjects/>
	</Catalog>
</MetaDataObject>
"""
        missing = """<?xml version="1.0" encoding="UTF-8"?>
<MetaDataObject xmlns="http://v8.1c.ru/8.3/MDClasses" xmlns:xr="http://v8.1c.ru/8.3/xcf/readable" version="2.20">
	<Catalog uuid="00000000-0000-0000-0000-000000000004">
		<InternalInfo/>
		<Properties>
			<Name>ФайлыБезВвода</Name>
			<CodeLength>0</CodeLength>
		</Properties>
		<ChildObjects/>
	</Catalog>
</MetaDataObject>
"""
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "Catalogs").mkdir()
            (root / "Catalogs" / "Файлы.xml").write_text(snippet, encoding="utf-8")
            (root / "Catalogs" / "ФайлыБезВвода.xml").write_text(missing, encoding="utf-8")
            errors = catalog_input_by_string_errors(root)
        self.assertTrue(any("CodeLength=0" in e and "Code" in e for e in errors), errors)
        self.assertTrue(any("requires InputByString" in e for e in errors), errors)


if __name__ == "__main__":
    suite = unittest.defaultTestLoader.loadTestsFromModule(sys.modules[__name__])
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    sys.exit(0 if result.wasSuccessful() else 1)
