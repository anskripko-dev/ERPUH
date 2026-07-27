&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	Var Prop;
	
	// Заполнить доступные функции
	FillAvailableFunctions();
	
	QueryWizardAddress = Parameters["QueryWizardAddress"];
	NestedQueryPositionAddress = Parameters["NestedQueryPositionAddress"];

	Expression = Parameters["Expression"];
	OldExpression = Expression;
	Changed = Parameters["Changed"];

	// Запонить доступные поля для QueryWizard
	Prop = Undefined;
	Parameters.Property("FieldsAddress", Prop);
	If Prop <> Undefined Then
		FieldsBase = GetFromTempStorage(Parameters["FieldsAddress"]);
		ValueToFormAttribute(FieldsBase, "Fields");
		
		CurrentQuerySchemaSelectQuery = Parameters["CurrentQuerySchemaSelectQuery"];
		CurrentQuerySchemaOperator = Parameters["CurrentQuerySchemaOperator"];
	EndIf;
	
	// ITK 1, 2, 27 + {
	ИТК_КонструкторЗапросов.ФормаРедактированиеПоляПриСозданииНаСервереПередЗаполнением(ЭтотОбъект);
	// }
	
	// Запонить доступные поля для AvailableTableParameters
	Prop = Undefined;
	Parameters.Property("PropertyName", Prop);
	If Prop <> Undefined Then
		CurrentQuerySchemaSelectQuery = Parameters["CurrentQuerySchemaSelectQuery"];
		CurrentQuerySchemaOperator = Parameters["CurrentQuerySchemaOperator"];
		PropertyName = Parameters["PropertyName"];
		TableIndex = Parameters["TableIndex"];
						   
		FillPropertyFields();
	EndIf;
	
EndProcedure

&AtServer
Procedure FillPropertyFields()
	Var MainObject;

	MainObject = FormAttributeToValue("Object");
	MainObject.FillPropertyFields(QueryWizardAddress, CurrentQuerySchemaSelectQuery,CurrentQuerySchemaOperator, 
								  NestedQueryPositionAddress, PropertyName, Fields, TableIndex);
EndProcedure

&AtClient
Procedure OK(Command)
	If OldExpression <> Expression Then
		ThisForm.OnCloseNotifyDescription.AdditionalParameters["Changed"] = True;
	EndIf;
	ThisForm.OnCloseNotifyDescription.AdditionalParameters["Expression"] =  Expression;

	OldExpression = Expression;
	Changed = False;
	ThisForm.Close();
EndProcedure

&AtClient
Procedure Cancel(Command)
	OldExpression = Expression;
	ThisForm.OnCloseNotifyDescription.AdditionalParameters["Changed"] = False;
	Changed = False;
	ThisForm.Close();
EndProcedure

&AtServer
Procedure FillAvailableFunctions()
	Var DataProcessor;
	Var LavelColumn;
	Var Row;
	Var Template;
	Var Lavel;
	Var LastItem;
	Var NameColumn;
	Var TranslatedNameColumn;
	Var Parent;
	Var TreeItems;
	Var NewItem;
	Var Picture;
	Var Name;
	Var ValueColumn;
	Var F;

	DataProcessor = FormAttributeToValue("Object");
    Template = DataProcessor.GetTemplate("Functions");
	Row = 2;
	LavelColumn = "C1";
	TranslatedNameColumn = "C6";
	// ITK32 + {
	PlatformColumn = "C7";
	// }
	
	If Metadata.ScriptVariant = Metadata.ObjectProperties.ScriptVariant.English Then
		ValueColumn = "C4";
		NameColumn = "C5";
	Else
		ValueColumn = "C2";
		NameColumn = "C3";
	EndIf;

	TreeItems = AvailableFunctions.GetItems();
	Parent = New Structure("Lavel", -1);
	LastItem = Undefined;
	Lavel = Template.Area("R" + Row + LavelColumn).Text;
	While Lavel <> "-1" Do
		If Lavel = "" Then
			Lavel = LastItem["Lavel"] + 1;
			Picture = -1;
			F = False;
			Name = Template.Area("R" + Row + NameColumn).Parameter;
		Else
			Lavel = Number(Lavel);
			Picture = 0;
			F = True;
			Name = Template.Area("R" + Row + TranslatedNameColumn).Text;
		EndIf;
		// ITK32 + {
		Platform = Template.Area("R" + Row + PlatformColumn).Text;
		// }

		If Lavel - Parent["Lavel"] = 1 Then
			NewItem = TreeItems.Add();
		ElsIf Lavel - Parent["Lavel"] > 1 Then
			Parent = LastItem;
			TreeItems = Parent.GetItems();
			NewItem = TreeItems.Add();
		ElsIf Lavel - Parent["Lavel"] < 1 Then
			While Lavel - Parent["Lavel"] < 1 Do
				Parent = Parent.GetParent();
				TreeItems = Parent.GetItems();
			EndDo;
			NewItem = TreeItems.Add();
		EndIf;

		NewItem["Lavel"] = Lavel;
		NewItem["Picture"] = Picture;
		NewItem["Presentation"] = Name;
		NewItem["Value"] = Template.Area("R" + Row + ValueColumn).Parameter;
		
		// ITK32 + {
		Если ЗначениеЗаполнено(Platform)
				И Lavel = 3
				И НЕ ИТК_ОбщийКлиентСервер.ПоддерживаетсяПлатформой(Platform) Тогда
				
			TreeItems.Удалить(NewItem);
			
		КонецЕсли;
		// }

		Row = Row + 1;
		Lavel = Template.Area("R" + Row + LavelColumn).Text;

		If F Then
			LastItem = NewItem;
		EndIf;
	EndDo;
EndProcedure

&AtClient
Procedure FieldsBeforeExpand(Val Item, 
							 Val Row, 
							 Val Cancel)
	
	AttachIdleHandler("FieldsBeforeExpandHandler", 0.01, True);
	EditedRow = Row;
EndProcedure							 
&AtClient
Procedure FieldsBeforeExpandHandler()
	Var CurrentItems;
	Var DataProcessor;
	Var Prop;

	Try
		DataProcessor = GetForm("DataProcessor.ИТК_QueryWizard252627.Form.QueryWizard");
	Except
		Message(ErrorDescription());
		Return;
	EndTry;

	CurrentItems = Fields.FindByID(EditedRow);

	If (CurrentItems["AvailableField"])
		OR (CurrentItems["Type"] < 0)
		OR NOT(DataProcessor.IsFakeItem(CurrentItems)) Then
		Return;
	EndIf;

	Prop = Undefined;
	ThisForm.OnCloseNotifyDescription.AdditionalParameters.Property("FieldsAddress", Prop);
	If Prop <> Undefined Then
		SourcesBeforeExpandAtServer(QueryWizardAddress, CurrentQuerySchemaSelectQuery, 
                                    CurrentQuerySchemaOperator, NestedQueryPositionAddress, EditedRow);
	EndIf;

	Prop = Undefined;
	ThisForm.OnCloseNotifyDescription.AdditionalParameters.Property("PropertyName", Prop);
	If Prop <> Undefined Then
		FillPropertyFieldsExpand(QueryWizardAddress,
								 CurrentQuerySchemaSelectQuery,
								 CurrentQuerySchemaOperator,
								 NestedQueryPositionAddress,
								 EditedRow,
								 PropertyName,
								 TableIndex);
	EndIf;
EndProcedure

&AtServer
Procedure SourcesBeforeExpandAtServer(Val QueryWizardAddress, 
									  Val CurrentQuerySchemaSelectQuery, 
									  Val CurrentQuerySchemaOperator, 
									  Val NestedQueryPositionAddress,
	                                  Val Row)
	Var MainObject;

	MainObject = FormAttributeToValue("Object");
	MainObject.SourcesBeforeExpandAtServer(QueryWizardAddress, CurrentQuerySchemaSelectQuery, 
                                           CurrentQuerySchemaOperator, NestedQueryPositionAddress, Row, Fields);
EndProcedure

&AtServer
Procedure FillPropertyFieldsExpand(Val QueryWizardAddress, 
								   Val CurrentQuerySchemaSelectQuery, 
								   Val CurrentQuerySchemaOperator, 
								   Val NestedQueryPositionAddress,
								   Val Row, 
                                   Val PropertyName, 
								   Val TableIndex)
	Var MainObject;
	
	MainObject = FormAttributeToValue("Object");
	MainObject.FillPropertyFieldsExpand(QueryWizardAddress, CurrentQuerySchemaSelectQuery, CurrentQuerySchemaOperator, 
										NestedQueryPositionAddress, Row, Fields, PropertyName, TableIndex);
EndProcedure

&AtClient
Procedure AvailableFunctionsDragStart(Val Item, Val DragParameters, Perform)
	Var CurrentItems;

	CurrentItems = AvailableFunctions.FindByID(Item.CurrentRow);
	If CurrentItems["Value"] = "" Then
		Perform = False;
	EndIf;
	DragParameters.Value = CurrentItems["Value"];
EndProcedure

&AtClient
Procedure FieldsDragStart(Val Item, Val DragParameters, Perform)
	Var CurrentItems;

	CurrentItems = Fields.FindByID(Item.CurrentRow);
	If CurrentItems["Type"] <> 2 Then
		Perform = False;
	EndIf;
	DragParameters.Value = CurrentItems["Name"];
EndProcedure

&AtClient
Procedure FieldsBeforeRowChange(Item, Cancel)
	Cancel = True;
	CurrentItems = Fields.FindByID(Item.CurrentRow);
	If CurrentItems["Type"] <> 2 Then
		Return;
	EndIf;
	
	// ITK 27 * {
	//Items.Expression.SelectedText = CurrentItems["Name"];
	Элемент = Элементы.Выражение;
	ИТК_РедакторКодаКлиент.УстановитьВыделенныйТекст(Элемент, CurrentItems["Name"]);
	// }
EndProcedure

&AtClient
Procedure AvailableFunctionsBeforeRowChange(Item, Cancel)
	Var CurrentItems;

	Cancel = True;
	CurrentItems = AvailableFunctions.FindByID(Item.CurrentRow);
	// ITK 27 * {
	//Items.Expression.SelectedText = CurrentItems["Value"]; 
	Элемент = Элементы.Выражение;
	ИТК_РедакторКодаКлиент.УстановитьВыделенныйТекст(Элемент, CurrentItems["Value"]);
	// }
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
		Cancel = True;
		MessageText = NStr("ru = 'Редактор произвольного выражения будет закрыт';
							|SYS = 'QueryEditor.ArbitraryExpressionWillClose'", "ru");
		Return;
	EndIf;
		
	If (Expression <> OldExpression)
		OR Changed Then
		Cancel = True;
		Type = QuestionDialogMode.YesNoCancel;
		Notification = New NotifyDescription("AskWhatToDo", ThisForm);
		ShowQueryBox(Notification, NStr("ru = 'Применить изменения?';
										|SYS = 'QueryEditor.ApplyChanges'", "ru"), Type);
		Return;
	EndIf;

	If ThisForm.OnCloseNotifyDescription <> Undefined Then
		ExecuteNotifyProcessing(ThisForm.OnCloseNotifyDescription, ThisForm);
		Cancel = NOT(Closing);
		StandardProcessing = False;
	EndIf;
EndProcedure

&AtClient
Procedure AskWhatToDo(Result, Params) Export
	If Result = DialogReturnCode.Yes Then
		OK(Undefined);
	ElsIf Result = DialogReturnCode.No Then
		Cancel(Undefined);
	EndIf;
EndProcedure

&AtClient
Procedure SetTextSelectionBounds(Val StartRow, Val StartCol) Export
	If (StartRow > 0) AND (StartCol > 0) Then
		Items.Expression.SetTextSelectionBounds(StartRow, StartCol, StartRow, StartCol);
	EndIf;
EndProcedure

// ITK27 + {
&НаКлиенте
Процедура ПриОткрытии(Отказ)
	
	ИТК_РедакторКодаКлиент.Инициализация(ЭтотОбъект, "Выражение");

КонецПроцедуры

&НаКлиенте
Процедура ITKПодключаемаяКоманда(Команда) Экспорт
	
	ИТК_КонструкторЗапросовКлиент.ОсновнаяФормаОбработатьПодключаемуюКоманду(ЭтотОбъект, Команда.Имя);

КонецПроцедуры

&НаКлиенте
Процедура ИТК_ПодключаемыйРедакторПриИзменении(Элемент)
	
	Модифицированность = Истина;
	Expression = ИТК_РедакторКодаКлиент.Текст(ЭтотОбъект, "Выражение");
	
КонецПроцедуры

&НаКлиенте
Процедура ИТК_ПодключаемыйДокументСформирован(Элемент)
	
	ДополнительныеПараметры = Новый Структура;
	ДополнительныеПараметры.Вставить("Текст", Expression);
	ДополнительныеПараметры.Вставить("ПользовательскиеОбъекты", ПользовательскиеОбъектыПодсказки());
	
	ИТК_РедакторКодаКлиент.ДополнительнаяИнициализация(ЭтотОбъект, Элемент, ДополнительныеПараметры);
	
КонецПроцедуры

&НаКлиенте
Процедура ИТК_ПодключаемыйПриНажатии(Элемент, ДанныеСобытия, СтандартнаяОбработка)
	
	ОписаниеОповещения = Новый ОписаниеОповещения("ОбработкаВыражениеПриИзменении", ЭтотОбъект);
	ИТК_РедакторКодаКлиент.ОбработкаСобытий(ЭтотОбъект, Элемент, ДанныеСобытия, СтандартнаяОбработка, ОписаниеОповещения);
	
	Если ИТК_РедакторКодаКлиент.ЭтоСобытиеНажатиеКлавишиEscape(ЭтотОбъект, ДанныеСобытия) Тогда
		BeforeClose(Ложь, Ложь, Неопределено, Истина);
	КонецЕсли;
	
КонецПроцедуры

&НаКлиенте
Процедура ОбработкаВыражениеПриИзменении(Результат, ДополнительныеПараметры) Экспорт
	
	Модифицированность = Истина;
	Expression = ИТК_РедакторКодаКлиент.Текст(ЭтотОбъект, "Выражение");
	
КонецПроцедуры

&НаКлиенте
Процедура ИТК_ПодключаемаяКомандаРедакторКодаОбработчик(Команда)
	
	Если СтрНайти(Команда.Имя, "КонструкторЗапроса") Тогда
		
		ITKОткрытьКонструкторВложенногоЗапроса();
		Возврат;
		
	КонецЕсли;
		
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
	Expression = Результат;
	
КонецПроцедуры

&НаКлиенте
Процедура ITKОткрытьКонструкторВложенногоЗапроса()
	
	Попытка
		
		ВыделенныйТекст = ИТК_РедакторКодаКлиент.ВыделенныйТекст(Элементы.Выражение);
		NestedQuerySourceIndex = ДобавитьВременныйВложенныйЗапрос(ВыделенныйТекст);
		
	Исключение
		
		Ошибка = КраткоеПредставлениеОшибки(ИнформацияОбОшибке());
		ПоказатьПредупреждение( , Ошибка, , ИТК_КонструкторЗапросовКлиентСервер.Заголовок());
		
		Возврат;
		
	КонецПопытки;
	
	NestedQueryPosition = New Array();
	NestedQueryPosition.Add(CurrentQuerySchemaOperator); 
	NestedQueryPosition.Add(NestedQuerySourceIndex); 
	Address = PutToTempStorage(NestedQueryPosition, New UUID);
	
	ПараметрыФормы = Новый Структура;
	ПараметрыФормы.Вставить("NestedQuerySourceIndex", NestedQuerySourceIndex);
	ПараметрыФормы.Вставить("NestedQueryPositionAddress", Address);
	ПараметрыФормы.Вставить("IsNestedQuery", Истина);	
	ПараметрыФормы.Вставить("IsNewNestedQuery", Истина);
	ПараметрыФормы.Вставить("QueryWizardAddress", QueryWizardAddress);	
	ПараметрыФормы.Вставить("CurrentQuerySchemaSelectQuery", CurrentQuerySchemaSelectQuery);	
	
	ИдентификаторВнешнихИсточников = ИТК_КонструкторЗапросовКлиентСервер.ИдентификаторЗначенийВнешнихИсточников();
	ПараметрыФормы.Вставить(ИдентификаторВнешнихИсточников, ЭтотОбъект.Object[ИдентификаторВнешнихИсточников]);
	
	ОписаниеОповещения = Новый ОписаниеОповещения("РедактированиеВложенногоЗапросаОкончено", ЭтотОбъект);
	
	ПолноеИмяФормы = ИТК_КонструкторЗапросов.ПолноеИмяФормыОбработки();
	ОткрытьФорму(ПолноеИмяФормы, ПараметрыФормы, ЭтотОбъект, , , ,ОписаниеОповещения, РежимОткрытияОкнаФормы.БлокироватьОкноВладельца);
	
КонецПроцедуры

&НаКлиенте
Процедура РедактированиеВложенногоЗапросаОкончено(Результат, ДополнительныеПараметры) Экспорт
	
	УдалитьВременныйВложенныйЗапрос();
	
	Если Результат = Неопределено Тогда
		Возврат;
	КонецЕсли;
	
	Элемент = Элементы.Выражение;
	ИТК_РедакторКодаКлиент.УстановитьВыделенныйТекст(Элемент, Результат);

	Модифицированность = Истина;
	Expression = ИТК_РедакторКодаКлиент.Текст(ЭтотОбъект, "Выражение");
	
КонецПроцедуры

&НаСервере
Функция ДобавитьВременныйВложенныйЗапрос(Текст) Экспорт
	
	Схема = ПолучитьИзВременногоХранилища(QueryWizardAddress);

	Запрос = ЗапросСхемы(Схема, CurrentQuerySchemaSelectQuery, NestedQueryPositionAddress);
	
	Оператор = Запрос.Операторы[CurrentQuerySchemaOperator];	
	Источник = Оператор.Источники.Добавить(Тип("ВложенныйЗапросСхемыЗапроса"));	
	
	Если ЗначениеЗаполнено(Текст) Тогда
		
		Источник.Источник.Запрос.УстановитьТекстЗапроса(Текст);
	
	КонецЕсли;
	Источник.Источник.Псевдоним = ПсевдонимВременногоЗапроса();
	
	ПоместитьВоВременноеХранилище(Схема, QueryWizardAddress);

	Возврат Оператор.Источники.Индекс(Источник);
	
КонецФункции

&НаСервере
Процедура УдалитьВременныйВложенныйЗапрос() Экспорт
	
	Схема = ПолучитьИзВременногоХранилища(QueryWizardAddress);

	Запрос = ЗапросСхемы(Схема, CurrentQuerySchemaSelectQuery, NestedQueryPositionAddress);
	
	Оператор = Запрос.Операторы[CurrentQuerySchemaOperator];	
	Оператор.Источники.Удалить(ПсевдонимВременногоЗапроса());
	
	ПоместитьВоВременноеХранилище(Схема, QueryWizardAddress);
	
КонецПроцедуры

&НаСервере
Функция ЗапросСхемы(Val QuerySchema, Val CurrentQuerySchemaSelectQuery, Val NestedQueryPositionAddress)

	МодульОбъекта = РеквизитФормыВЗначение("Object");
	
	Возврат МодульОбъекта.GetSchemaQuery(QuerySchema, CurrentQuerySchemaSelectQuery, NestedQueryPositionAddress);
	
КонецФункции

&НаКлиентеНаСервереБезКонтекста
Функция ПсевдонимВременногоЗапроса()
	
	Возврат "ITKВременныйВложенныйЗапросУдалить";
	
КонецФункции

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
