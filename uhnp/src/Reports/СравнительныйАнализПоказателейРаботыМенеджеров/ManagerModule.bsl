//@strict-types

#Если Сервер Или ТолстыйКлиентОбычноеПриложение Или ВнешнееСоединение Тогда

#Область ПрограммныйИнтерфейс

#Область ДляВызоваИзДругихПодсистем

// Задает расширенные настройки отчета
//
// Параметры:
//   Настройки - см. ВариантыОтчетовПереопределяемый.НастроитьВариантыОтчетов.Настройки.
//
Процедура НастроитьВариантыОтчета(Настройки) Экспорт
	
	ОписаниеОтчета = ВариантыОтчетов.ОписаниеОтчета(Настройки, Метаданные.Отчеты.СравнительныйАнализПоказателейРаботыМенеджеров);
	ОписаниеОтчета.ФорматНастроекСКД = Ложь;
	ОписаниеВарианта = ВариантыОтчетов.ОписаниеВарианта(Настройки, ОписаниеОтчета, "");
	ОписаниеВарианта.Описание = НСтр("ru = 'Комплексный анализ показателей, характеризующих эффективность работы менеджеров.';
									|en = 'Comprehensive analysis of sales person efficiency indicators.'");
	ОписаниеВарианта.НастройкиДляПоиска.НаименованияПолей = НСтр("ru = 'Продажи
		|Прибыль
		|Поступление денежных средств
		|Выручка (по оплате) минус себестоимость (по отгрузке)
		|Соблюдение условий продаж
		|Потери
		|Ручные скидки
		|Продажи на одну сделку
		|Продажи на одно взаимодействие
		|Основные этапы потерь
		|Причины проигрыша сделок
		|Причины неудовлетворения первичного спроса
		|Динамика клиентской базы
		|Продажи новым клиентам
		|Претензии клиентов
		|Причины возникновения претензий клиентов';
		|en = 'Sales
		|Profit
		|Receipt
		|Revenue (by payment) minus cost (by shipment)
		|Compliance with sales terms and conditions
		|Losses
		|Discount adjustments
		|Sales per sales opportunity
		|Sales per interaction
		|Main stages of losses
		|Reasons for losing sales opportunities
		|Reasons for primary demand non-fulfillment
		|Customer base trends
		|Sales to new customers
		|Customer complaints
		|Reasons for customer complaints'");
	ОписаниеВарианта.НастройкиДляПоиска.НаименованияПараметровИОтборов = НСтр("ru = 'Анализируемый период
		|Период для сравнения
		|Показатели
		|Годовая ставка
		|Подразделение
		|Менеджер';
		|en = 'Analyzed period
		|Period for comparison
		|Indicators
		|Annual rate
		|Business unit
		|Manager'");
	ОписаниеВарианта = ВариантыОтчетов.ОписаниеВарианта(Настройки, ОписаниеОтчета, "Основной");
	ОписаниеВарианта.Описание = НСтр("ru = 'Комплексный анализ показателей, характеризующих эффективность работы менеджеров.
		|Таких, как продажи, прибыль, поступление ДС, скидки и другие.';
		|en = 'Comprehensive analysis of sales person efficiency indicators
		|, such as sales, income, cash receipt, discounts, and other.'");
	ОписаниеВарианта.НастройкиДляПоиска.НаименованияПолей = НСтр("ru = 'Продажи
		|Прибыль
		|Поступление денежных средств
		|Выручка (по оплате) минус себестоимость (по отгрузке)
		|Соблюдение условий продаж
		|Потери
		|Ручные скидки
		|Продажи на одну сделку
		|Продажи на одно взаимодействие
		|Основные этапы потерь
		|Причины проигрыша сделок
		|Причины неудовлетворения первичного спроса
		|Динамика клиентской базы
		|Продажи новым клиентам
		|Претензии клиентов
		|Причины возникновения претензий клиентов';
		|en = 'Sales
		|Profit
		|Receipt
		|Revenue (by payment) minus cost (by shipment)
		|Compliance with sales terms and conditions
		|Losses
		|Discount adjustments
		|Sales per sales opportunity
		|Sales per interaction
		|Main stages of losses
		|Reasons for losing sales opportunities
		|Reasons for primary demand non-fulfillment
		|Customer base trends
		|Sales to new customers
		|Customer complaints
		|Reasons for customer complaints'");
	ОписаниеВарианта.НастройкиДляПоиска.НаименованияПараметровИОтборов = НСтр("ru = 'Анализируемый период
		|Период для сравнения
		|Показатели
		|Годовая ставка
		|Подразделение
		|Менеджер';
		|en = 'Analyzed period
		|Period for comparison
		|Indicators
		|Annual rate
		|Business unit
		|Manager'");
	
КонецПроцедуры

#КонецОбласти

#КонецОбласти

#КонецЕсли
