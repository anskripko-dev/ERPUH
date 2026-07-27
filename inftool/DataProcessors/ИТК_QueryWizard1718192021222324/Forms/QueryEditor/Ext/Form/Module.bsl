&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	Closing = False;
	QueryText = Parameters["QueryText"];
	OldQueryText = Parameters["OldQueryText"];
	If OldQueryText = "" Then
		OldQueryText = QueryText;
	EndIf;	
	// ITK10,12,27 + {
	ИТК_КонструкторЗапросов.ФормаРедактированиеТекстаПослеПриСозданииНаСервере(ЭтотОбъект);
	// }
EndProcedure

&AtClient
Procedure CancelChanges(Command)
	// ITK11 - {
	//QueryText = OldQueryText;
	// }
	ThisForm.Close();
EndProcedure

&AtClient
Procedure ApplyChanges(Command)
	OldQueryText = QueryText;
	ThisForm.Close();
EndProcedure

&AtClient
Procedure AskWhatToDo(Result, Params) Export
	If Result = DialogReturnCode.Yes Then
		ApplyChanges(Undefined);
	ElsIf Result = DialogReturnCode.No Then
		// ITK11 + {
		QueryText = OldQueryText;
		// }
		CancelChanges(Undefined);
	EndIf;
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, MessageText, StandardProcessing)
	Var Notification;
	Var Type;

	If Closing Then
		Return;
	EndIf;

	If Exit = True Then
		// Если происходи закрытие приложения
		If QueryText <> OldQueryText Then			
			Cancel = True;
			MessageText = NStr("ru = 'Редактор запроса будет закрыт';
								|SYS = 'QueryEditor.QueryEditorWillClose'", "ru");
		EndIf;
		
		Return;
	EndIf;

	If QueryText = OldQueryText Then
		ThisForm.OnCloseNotifyDescription.AdditionalParameters["QueryText"] = QueryText;
		If ThisForm.OnCloseNotifyDescription <> Undefined Then
			ExecuteNotifyProcessing(ThisForm.OnCloseNotifyDescription, ThisForm);
			Cancel = NOT(Closing);
			StandardProcessing = False;
		EndIf;
	Else
		Cancel = NOT(Closing);
		Type = QuestionDialogMode.YesNoCancel;
		Notification = New NotifyDescription("AskWhatToDo", ThisForm);
		ShowQueryBox(Notification, NStr("ru = 'Применить изменения?';
										|SYS = 'QueryEditor.ApplyChanges'", "ru"), Type);
	EndIf;
EndProcedure

&AtClient
Procedure SetTextSelectionBounds(Val StartRow, Val StartCol) Export
	If (StartRow > 0) AND (StartCol > 0) Then
		Items.QueryText.SetTextSelectionBounds(StartRow, StartCol, StartRow, StartCol);
	EndIf;
EndProcedure

&AtClient
Procedure SetOldQueryText(Val Text) Export
	OldQueryText = Text;
EndProcedure

// ITK10,12,27 + {
&НаКлиенте
Процедура ПриОткрытии(Отказ)
	
	ИТК_РедакторКодаКлиент.Инициализация(ЭтотОбъект, "ТекстЗапроса");

КонецПроцедуры

&НаКлиенте
Процедура ИТК_ПодключаемыйРедакторПриИзменении(Элемент)
	
	Модифицированность = Истина;
	QueryText = ИТК_РедакторКодаКлиент.Текст(ЭтотОбъект, "ТекстЗапроса");
	
КонецПроцедуры

&НаКлиенте
Процедура ИТК_ПодключаемыйДокументСформирован(Элемент)
	
	ДополнительныеПараметры = Новый Структура;
	ДополнительныеПараметры.Вставить("Текст", QueryText);
	ДополнительныеПараметры.Вставить("ПользовательскиеОбъекты", ПользовательскиеОбъектыПодсказки());
	
	ИТК_РедакторКодаКлиент.ДополнительнаяИнициализация(ЭтотОбъект, Элемент, ДополнительныеПараметры);
	
КонецПроцедуры

&НаКлиенте
Процедура ИТК_ПодключаемыйПриНажатии(Элемент, ДанныеСобытия, СтандартнаяОбработка)
	
	ОписаниеОповещения = Новый ОписаниеОповещения("ОбработкаТекстЗапросаПриИзменении", ЭтотОбъект);
	ИТК_РедакторКодаКлиент.ОбработкаСобытий(ЭтотОбъект, Элемент, ДанныеСобытия, СтандартнаяОбработка, ОписаниеОповещения);
	
	Если ИТК_РедакторКодаКлиент.ЭтоСобытиеНажатиеКлавишиEscape(ЭтотОбъект, ДанныеСобытия) Тогда
		BeforeClose(Ложь, Ложь, Неопределено, Истина);
	КонецЕсли;
	
КонецПроцедуры

&НаКлиенте
Процедура ОбработкаТекстЗапросаПриИзменении(Результат, ДополнительныеПараметры) Экспорт
	
	QueryText = ИТК_РедакторКодаКлиент.Текст(ЭтотОбъект, "ТекстЗапроса");
	
КонецПроцедуры

&НаКлиенте
Процедура ИТК_ПодключаемаяКомандаРедакторКодаОбработчик(Команда)
	
	ДополнительныеПараметры = Новый Структура;
	ОповещениеОЗавершении = Новый ОписаниеОповещения("ОбработкаКомандыРедактораЗавершена", ЭтотОбъект, ДополнительныеПараметры);
	ИТК_РедакторКодаКлиент.ПодключаемыйОбработчикКоманд(ЭтотОбъект, Команда.Имя, ОповещениеОЗавершении);
	
КонецПроцедуры

&НаКлиенте
Процедура ОбработкаКомандыРедактораЗавершена(Результат, ДополнительныеПараметры) Экспорт

	Если Результат = Неопределено Тогда
		Возврат;
	КонецЕсли;
	
	ИТК_РедакторКодаКлиент.СтандартныйОбработчикЗавершенияКоманды(Результат, ДополнительныеПараметры);	
	
	Модифицированность = Истина;
	QueryText = Результат;
	
КонецПроцедуры

&НаСервере
Функция ПользовательскиеОбъектыПодсказки()
	
	Возврат ИТК_КонструкторЗапросов.ПользовательскиеОбъектыПодсказки(ЭтотОбъект);
	
КонецФункции

&НаКлиенте
Процедура ИТК_ПодключаемыйВосстановлениеФокусаРедактора() Экспорт 
	
	ИТК_РедакторКодаКлиент.ВосстановлениеФокусаРедактора(ЭтотОбъект);
	
КонецПроцедуры

&НаКлиенте
Процедура ОбработкаОповещения(ИмяСобытия, Параметр, Источник)
	
	ИТК_РедакторКодаКлиент.ОбработкаОповещения(ЭтотОбъект, ИмяСобытия, Параметр, Источник);
	
КонецПроцедуры
// }
