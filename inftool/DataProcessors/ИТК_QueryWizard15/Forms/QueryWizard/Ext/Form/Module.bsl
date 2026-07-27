// ITK 20 + {
&НаКлиенте
Перем СвязиТаблица1, СвязиТаблица2, СвязиВсе1, СвязиВсе2, СвязиУсловие, СвязиСОшибкой, СвязиНоваяСтрока, СвязиУсловиеСОшибкой Экспорт;
// }

// Инициализация на сервере
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	Var SourcesImagesCache;
	Var ExpressionsImagesCache;
	Var Prop;
	Var QuerySchema;
	Var Query;
	Var State;
	Var ChoiceList;
	Var NewItem;
	  
	// создадим схему запроса и сохраним во временное хранилище
	PagesState = New Structure;
	FieldsDropList = New Structure;
	PagesState.Insert("QueryBatchPage", True);
	PagesState.Insert("ConditionsPage", True);
	PagesState.Insert("ConditionsFieldsPage", True);
	PagesState.Insert("IndexPage", True);
	PagesState.Insert("OrderPage", True);
	PagesState.Insert("AutoorderPage", True);
	PagesState.Insert("UnionsPage", True);
	PagesState.Insert("AliasesPage", True);
	PagesState.Insert("GroupingPage", True);
	PagesState.Insert("JoinsPage", True);
	PagesState.Insert("TotalsPage", True);

	PagesState.Insert("AvailableTablesPage", True);
	PagesState.Insert("SourcesPage", True);
	PagesState.Insert("AvailableFieldsPage", True);

	PagesState.Insert("AdditionallyTablesPage", True);
	PagesState.Insert("AdditionallyItemsPage", True);

	PagesState.Insert("OverallPage", True);

	PagesState.Insert("DropTablePage", True);
	
	PagesState.Insert("DataCompositionRequiredJoinsPage", True);
	PagesState.Insert("DataCompositionFieldsPage", True);
	PagesState.Insert("DataCompositionFiltersPage", True);
	PagesState.Insert("CharacteristicsPage", True);
	
	NeedFillChoiceList = True;
	IsNestedQuery = False;
	MoveJoinTable = -1;
	CheckQueryToEmpty = True;
	IgnoreErrorMessage = False;
	SourceTypes = New Structure();
	SourceTypes.Insert("Array", Undefined);
	NestedQueryPositionAddress = Undefined;
	
	If Metadata.ScriptVariant = Metadata.ObjectProperties.ScriptVariant.English Then
		TemporaryTableDefaultName = "TemporaryTable";
	Else
		TemporaryTableDefaultName = "ВременнаяТаблица";
	EndIf;

	// Кэш картинок для таблиц
	SourcesImagesCache = New Map();
	ExpressionsImagesCache = New Map();

	SourcesImagesCacheAddress = PutToTempStorage(SourcesImagesCache, ThisForm.UUID);
	ExpressionsImagesCacheAddressCache = PutToTempStorage(ExpressionsImagesCache, ThisForm.UUID);	
	AllFieldsForGroupingAddress = PutToTempStorage(FormAttributeToValue("AllFieldsForGrouping"), ThisForm.UUID);
	AvailableTablesAddress = PutToTempStorage(FormAttributeToValue("AvailableTables"), ThisForm.UUID);
	
	CurrentQuerySchemaSelectQuery = 0; // текущий запрос выбора
	CurrentQuerySchemaOperator = 0;    // текущий оператор выбора схемы запроса
	
	Prop = Undefined;
	Parameters.Property("NestedQuerySourceIndex", Prop);
	If Prop <> Undefined Then
		NestedQuerySourceIndex = Parameters["NestedQuerySourceIndex"]; 		
	EndIf;
	
	Prop = Undefined;
	Parameters.Property("DataCompositionMode", Prop);
	If Prop <> Undefined Then
		DataCompositionMode = False;
		If (Prop) Then
			DataCompositionMode = True;
		EndIf;
	EndIf;
	
	Prop = Undefined;
	Parameters.Property("IsNestedQuery", Prop);
	If Prop = Undefined Then // если не вложенный запрос
		QuerySchema = New QuerySchema;		
		QueryWizardAddress = PutToTempStorage(QuerySchema, ThisForm.UUID); // запомним адрес схемы запроса
	Else                     // если вложенный запрос
		IsNestedQuery = True; 
		QueryWizardAddress = Parameters["QueryWizardAddress"];
		NestedQueryPositionAddress = Parameters["NestedQueryPositionAddress"];
		CurrentQuerySchemaSelectQuery = Parameters["CurrentQuerySchemaSelectQuery"];

		ThisForm.Title = NStr("ru = 'Вложенный запрос';
								|SYS = 'QueryEditor.NestedQuery'", "ru");
	EndIf;

	If QuerySchema = Undefined Then
		QuerySchema = GetFromTempStorage(QueryWizardAddress);
	EndIf;
	
	QuerySchema.DataCompositionMode = DataCompositionMode;
	
	Prop = Undefined;
	Parameters.Property("QueryText", Prop);
	If Prop <> Undefined Then
		Query = Prop;
		QueryTextOld = Query;
	EndIf;
	
	If (Query <> Undefined) AND (Query <> "") Then		
		QuerySchema.SetQueryText(Query);
	EndIf;
	
	// ITK1,3,20... + {
	ИТК_КонструкторЗапросов.ФормаОсновнаяПриСозданииНаСервереПередЗаполнением(ЭтотОбъект, QuerySchema);
	// }
	
	PutToTempStorage(QuerySchema, QueryWizardAddress);
	
	FillPagesAtServer(PagesState);
	For Each state In PagesState Do
		PagesState[state.Key] = False;
	EndDo;
	
	// ITK3,23,26 + {
	ИТК_КонструкторЗапросов.ФормаОсновнаяПриСозданииНаСервереПослеЗаполнения(ЭтотОбъект, Cancel);
	// }
	
EndProcedure

// Инициализация на клиенте
&AtClient
Procedure OnOpen(Cancel)
	If QueryTextWillBeSet <> "" Then
		SetQueryText(QueryTextWillBeSet);
		QueryTextWillBeSet = "";
	EndIf;
	
	ChangeAdditionallyPageControlsSatate();
	
	ChoiceList = Items.Characteristics.ChildItems.CharacteristicsCharacteristicTypesSource.ChoiceList;
	NewItem = ChoiceList.Add();
	NewItem.Value = NStr("ru = 'Таблица';
						|SYS = 'Table'", "ru");
	NewItem.Presentation = NStr("ru = 'Таблица';
								|SYS = 'Table'", "ru");
	NewItem = ChoiceList.Add();
	NewItem.Value = NStr("ru = 'Запрос';
						|SYS = 'Query'", "ru");
	NewItem.Presentation = NStr("ru = 'Запрос';
								|SYS = 'Query'", "ru");
	ChoiceList = Items.Characteristics.ChildItems.CharacteristicsCharacteristicValuesSource.ChoiceList;
	NewItem = ChoiceList.Add();
	NewItem.Value = NStr("ru = 'Таблица';
						|SYS = 'Table'", "ru");
	NewItem.Presentation = NStr("ru = 'Таблица';
								|SYS = 'Table'", "ru");
	NewItem = ChoiceList.Add();
	NewItem.Value = NStr("ru = 'Запрос';
						|SYS = 'Query'", "ru");
	NewItem.Presentation = NStr("ru = 'Запрос';
								|SYS = 'Query'", "ru");
	
	Items.DataCompositionPage.Visible = DataCompositionMode;
	Items.CharacteristicsPage.Visible = DataCompositionMode;
	Items.TotalsPage.Visible = NOT DataCompositionMode;
	
	// ITK3,26 + {
	PagesState["TotalsPage"] = True;
	FillPagesAtClient();
	ИТК_КонструкторЗапросовКлиент.ФормаОсновнаяПриОткрытииПосле(ЭтотОбъект, Cancel);
	// }
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Заполнение вкладок
&AtClient
Procedure FillPagesAtClient(ItemForErrorMessage = Undefined)
	Var PagesItems;

	PagesItems = PreFillAtClient();
	// Перезаполняем измененные вкладки
	If (PagesItems <> Undefined)
		AND (PagesItems.Count() > 0) Then

		FillPagesAtServer(PagesItems);  // выполним серверный вызов
		PostFillAtClient(PagesItems);
		ShowErrorMessage(ItemForErrorMessage);

		NewQueryBatchCount = 0;
	EndIf;
EndProcedure

&AtClient
Function PreFillAtClient()
	Var PageItem;
	Var PagesItems;
	Var PageItems;

	// Проверяем изменения по вкладкам

	PagesItems = Undefined;

	For Each PageItem In PagesState Do
		If PageItem.Value Then
			If PagesItems = Undefined Then
				PagesItems = New Structure;
			EndIf;

			If PageItem.Key = "QueryBatchPage" Then
			 	SavePageState("QueryBatchPage", "0", "QueryBatch", "QueryBatch", PagesItems);
	        ElsIf  PageItem.Key = "ConditionsPage" Then
				SavePageState("ConditionsPage", "0", "Conditions", "Conditions", PagesItems);
			ElsIf  PageItem.Key = "ConditionsFieldsPage" Then
				SavePageState("ConditionsFieldsPage", "0", "AllFieldsForConditions", "AllFieldsForConditions", PagesItems);
			ElsIf  PageItem.Key = "IndexPage" Then
				SavePageState("IndexPage", "0", "Indexes", "Indexes", PagesItems, True);
				SavePageState("IndexPage", "1", "AllFieldsForIndex", "AllFieldsForIndex", PagesItems, True);
				SavePageState("IndexPage", "2", "AllFieldsForIndex", "AllFieldsForIndex", PagesItems,, -1);
			ElsIf  PageItem.Key = "OrderPage" Then
				SavePageState("OrderPage", "0", "Order", "Order", PagesItems, True);
				SavePageState("OrderPage", "1", "AllFieldsForOrder", "AllFieldsForOrder", PagesItems, True);
				SavePageState("OrderPage", "2", "AllFieldsForOrder", "AllFieldsForOrder", PagesItems,, -1);
			ElsIf  PageItem.Key = "UnionsPage" Then
				SavePageState("UnionsPage", "0", "Unions", "Unions", PagesItems);
			ElsIf  PageItem.Key = "AliasesPage" Then
				SavePageState("AliasesPage", "0", "Aliases", "Aliases", PagesItems);
			ElsIf  PageItem.Key = "GroupingPage" Then
				SavePageState("GroupingPage", "0", "GroupingFields", "GroupingFields", PagesItems, True);
				SavePageState("GroupingPage", "1", "SummingFields", "SummingFields", PagesItems, True);
				SavePageState("GroupingPage", "2", "AllFieldsForGrouping", "AllFieldsForGrouping", PagesItems, True);
				SavePageState("GroupingPage", "3", "AllFieldsForGrouping", "AllFieldsForGrouping", PagesItems,, -1);
			ElsIf  PageItem.Key = "JoinsPage" Then
				SavePageState("JoinsPage", "0", "Joins", "Joins", PagesItems);
			ElsIf  PageItem.Key = "TotalsPage" AND NOT DataCompositionMode Then
				SavePageState("TotalsPage", "0", "TotalsGroupingFields", "TotalsGroupingFields", PagesItems, True);
				SavePageState("TotalsPage", "1", "TotalsExpressions", "TotalsExpressions", PagesItems, True);
				SavePageState("TotalsPage", "2", "AllFieldsForTotals", "AllFieldsForTotals", PagesItems, True);
				SavePageState("TotalsPage", "3", "AllFieldsForTotals", "AllFieldsForTotals", PagesItems,, -1);
			ElsIf  PageItem.Key = "AvailableTablesPage" Then
				SavePageState("AvailableTablesPage", "0", "AvailableTables", "AvailableTables", PagesItems);
			ElsIf  PageItem.Key = "SourcesPage" Then
				SavePageState("SourcesPage", "0", "Sources", "Sources", PagesItems);
			ElsIf  PageItem.Key = "AvailableFieldsPage" Then
				SavePageState("AvailableFieldsPage", "0", "AvailableFields", "AvailableFields", PagesItems);
			ElsIf  PageItem.Key = "AdditionallyTablesPage" Then
				SavePageState("AdditionallyTablesPage", "0", "AdditionallyTables", "AdditionallyTables", PagesItems, True);
				SavePageState("AdditionallyTablesPage", "1", "AdditionallyTablesForChanging", "AdditionallyTablesForChanging",
                              PagesItems);
			ElsIf  PageItem.Key = "AutoorderPage" Then
				SetPageState(PageItem.Key, False);
				PageItems = "";
				PagesItems.Insert(PageItem.Key, PageItems);
			ElsIf  PageItem.Key = "AdditionallyItemsPage" Then
				SetPageState(PageItem.Key, False);
				PageItems = "";
				PagesItems.Insert(PageItem.Key, PageItems);
			ElsIf  PageItem.Key = "OverallPage" Then
				SetPageState(PageItem.Key, False);
				PageItems = "";
				PagesItems.Insert(PageItem.Key, PageItems);
			ElsIf  PageItem.Key = "DropTablePage" Then
				SetPageState(PageItem.Key, False);
				PageItems = "";
				PagesItems.Insert(PageItem.Key, PageItems);
			ElsIf  PageItem.Key = "DataCompositionRequiredJoinsPage" Then
				SavePageState("DataCompositionRequiredJoinsPage", "0", "DataCompositionRequiredJoins", "DataCompositionRequiredJoins", PagesItems);
			ElsIf  PageItem.Key = "DataCompositionFieldsPage" Then
				SavePageState("DataCompositionFieldsPage", "0", "DataCompositionFields", "DataCompositionFields", PagesItems);
			ElsIf  PageItem.Key = "DataCompositionFiltersPage" Then
				SavePageState("DataCompositionFiltersPage", "0", "DataCompositionFilters", "DataCompositionFilters", PagesItems);
			ElsIf  PageItem.Key = "CharacteristicsPage" Then
				SavePageState("CharacteristicsPage", "0", "Characteristics", "Characteristics", PagesItems);
			EndIf;
		EndIf;
	EndDo;
	Return PagesItems;
EndFunction

&AtClient
Procedure PostFillAtClient(Val PagesItems)
	Var ParametersCount;
	Var ParamPos;

	If PagesItems = Undefined Then
		Return;
	EndIf;

	If PagesItems.Property("JoinsPage")  AND Items.JoinsPage.Visible Then
		LoadPageState("JoinsPage", "0", "Joins", Joins, PagesItems);
		If Items.Joins.Parent.Visible Then
			If (Joins.GetItems().Count()) AND (PagesItems["JoinsPage"]["p0"].Count() = 0) Then
				Items.Joins.Expand(Joins.GetItems().Get(0).GetID(), True);
			EndIf;
		EndIf;
	EndIf;

	If PagesItems.Property("QueryBatchPage") Then
		LoadPageState("QueryBatchPage", "0", "QueryBatch", QueryBatch, PagesItems);
	EndIf;

	If PagesItems.Property("ConditionsPage") Then
		LoadPageState("ConditionsPage", "0", "Conditions", Conditions, PagesItems);
	EndIf;

	If PagesItems.Property("ConditionsFieldsPage") Then
		LoadPageState("ConditionsFieldsPage", "0", "AllFieldsForConditions", AllFieldsForConditions, PagesItems);
	EndIf;

	If PagesItems.Property("IndexPage") Then
		LoadPageState("IndexPage", "0", "Indexes", Indexes, PagesItems);
		LoadPageState("IndexPage", "1", "AllFieldsForIndex", AllFieldsForIndex, PagesItems);
		LoadPageState("IndexPage", "2", "AllFieldsForIndex", AllFieldsForIndex, PagesItems, -1);
	EndIf;

	If PagesItems.Property("OrderPage") Then
		LoadPageState("OrderPage", "0", "Order", Order, PagesItems);
		LoadPageState("OrderPage", "1", "AllFieldsForOrder", AllFieldsForOrder, PagesItems);
		LoadPageState("OrderPage", "2", "AllFieldsForOrder", AllFieldsForOrder, PagesItems, -1);
	EndIf;

	If PagesItems.Property("UnionsPage") Then
		LoadPageState("UnionsPage", "0", "Unions", Unions, PagesItems);
	EndIf;

	If PagesItems.Property("AliasesPage") Then
		LoadPageState("AliasesPage", "0", "Aliases", Aliases, PagesItems);
	EndIf;

	If PagesItems.Property("GroupingPage") Then
		LoadPageState("GroupingPage", "0", "GroupingFields", GroupingFields, PagesItems);
		LoadPageState("GroupingPage", "1", "SummingFields", SummingFields, PagesItems);
		LoadPageState("GroupingPage", "2", "AllFieldsForGrouping", AllFieldsForGrouping, PagesItems);
		LoadPageState("GroupingPage", "3", "AllFieldsForGrouping", AllFieldsForGrouping, PagesItems, -1);
	EndIf;

	If PagesItems.Property("TotalsPage") AND Items.TotalsPage.Visible  AND NOT DataCompositionMode Then
		Items.TotalsGroupingFieldsPeriodStart.ChoiceList.Clear();
		Items.TotalsGroupingFieldsPeriodEnd.ChoiceList.Clear();

		Items.PeriodStart.ChoiceList.Clear();
		Items.PeriodEnd.ChoiceList.Clear();

		ParametersCount = QueryParameters.Count();
		For ParamPos = 0 To ParametersCount - 1 Do
			Items.TotalsGroupingFieldsPeriodStart.ChoiceList.Add(QueryParameters.Get(ParamPos)["Name"]);
			Items.TotalsGroupingFieldsPeriodEnd.ChoiceList.Add(QueryParameters.Get(ParamPos)["Name"]);

			Items.PeriodStart.ChoiceList.Add(QueryParameters.Get(ParamPos)["Name"]);
			Items.PeriodEnd.ChoiceList.Add(QueryParameters.Get(ParamPos)["Name"]);
		EndDo;

		LoadPageState("TotalsPage", "0", "TotalsGroupingFields", TotalsGroupingFields, PagesItems);
		LoadPageState("TotalsPage", "1", "TotalsExpressions", TotalsExpressions, PagesItems);
		LoadPageState("TotalsPage", "2", "AllFieldsForTotals", AllFieldsForTotals, PagesItems);
		LoadPageState("TotalsPage", "3", "AllFieldsForTotals", AllFieldsForTotals, PagesItems, -1);
	EndIf;

	If PagesItems.Property("AvailableTablesPage") Then
		LoadPageState("AvailableTablesPage", "0", "AvailableTables", AvailableTables, PagesItems);
	EndIf;

	If PagesItems.Property("SourcesPage") Then
		LoadPageState("SourcesPage", "0", "Sources", Sources, PagesItems);
		SourcesOnActivateRow(Undefined);
	EndIf;

	If PagesItems.Property("AvailableFieldsPage") Then
		LoadPageState("AvailableFieldsPage", "0", "AvailableFields", AvailableFields, PagesItems);
	EndIf;

	If PagesItems.Property("AdditionallyTablesPage") Then
		LoadPageState("AdditionallyTablesPage", "0", "AdditionallyTables", AdditionallyTables, PagesItems);
		LoadPageState("AdditionallyTablesPage", "1", "AdditionallyTablesForChanging", AdditionallyTablesForChanging,
                      PagesItems);
	EndIf;
				  
	If PagesItems.Property("DataCompositionRequiredJoinsPage") Then
		LoadPageState("DataCompositionRequiredJoinsPage", "0", "DataCompositionRequiredJoins", DataCompositionRequiredJoins, PagesItems);
	EndIf;
	
	If  PagesItems.Property("DataCompositionFieldsPage") Then
		LoadPageState("DataCompositionFieldsPage", "0", "DataCompositionFields", DataCompositionFields, PagesItems);
	EndIf;
			
	If  PagesItems.Property("DataCompositionFiltersPage") Then
		LoadPageState("DataCompositionFiltersPage", "0", "DataCompositionFilters", DataCompositionFilters, PagesItems);
	EndIf;
	
	If  PagesItems.Property("CharacteristicsPage") Then
		LoadPageState("CharacteristicsPage", "0", "Characteristics", Characteristics, PagesItems);
	EndIf;

	If PagesItems.Property("AdditionallyItemsPage")  AND Items.AdditionallyPage.Visible Then
		ChangeAdditionallyPageControlsSatate();
	EndIf;
EndProcedure

&AtServer
Procedure FillPagesAtServer(Val PagesItems)
	Var Tmp;
	Var QuerySchema;
	Var Batch;
	Var Query;
	Var PageItems;
	Var NewQueryType;
	Var Count;
	Var Pos;
	Var Item;
	Var NewItem;
	Var OperatorsNamesValues;
	Var Operators;
	Var MainObject;
	Var Operator;
	Var AdFirstCount;

	// Зафиксируем изменения из кеша
	ErrorMessages = "";
	If ChangesCache.Count() > 0 Then
		ApplyChangesFromCache(ChangesCache, QueryWizardAddress, CurrentQuerySchemaSelectQuery, CurrentQuerySchemaOperator, ErrorMessages);
		ChangesCache.Clear();
	EndIf;

	If PagesItems = Undefined Then
		Return;
	EndIf;

	// Получим схему запроса из хранилища
	QuerySchema = GetFromTempStorage(QueryWizardAddress);
	If QuerySchema = Undefined Then
		Return;
	EndIf;

	Batch = QuerySchema.QueryBatch;
	If CurrentQuerySchemaSelectQuery >= Batch.Count() Then
		CurrentQuerySchemaSelectQuery = 0;
		CurrentQuerySchemaOperator = 0;
	EndIf;

	Query = GetSchemaQuery(QuerySchema, CurrentQuerySchemaSelectQuery, NestedQueryPositionAddress);

	// Начинаем заполнять
	PageItems = 0;
	If TypeOf(Query) = Type("QuerySchemaTableDropQuery") Then
		PagesItems.Property("AdditionallyItemsPage", PageItems);
		If PageItems <> Undefined Then
			NewQueryType = 2;
			If QueryType <> NewQueryType Then
				QueryType = NewQueryType;
			EndIf;

			TempTableName = Query.TableName;
			DropTableName = TempTableName;
		EndIf;
	EndIf;

	PageItems = 0;
	PagesItems.Property("QueryBatchPage", PageItems);
	If PageItems <> Undefined Then
		FillQueryBatchTable(QueryBatch, Batch, OperatorsNames);

		TempTablesNames.Clear();
		Count = QuerySchema.QueryBatch.Count();
		For Pos = 0 To Count - 1 Do
		    Item = QuerySchema.QueryBatch.Get(Pos);
			If (TypeOf(Item) = Type("QuerySchemaSelectQuery"))
				AND (Item.PlacementTable <> "") Then
			    NewItem = TempTablesNames.Add();
				NewItem["Name"] = Item.PlacementTable;
			EndIf;
		EndDo;

		// заполним список запросов
		Count = QueryBatch.Count();
		Items.CurrentQuerySchemaSelectQuery.ChoiceList.Clear();
		For Pos = 0 To Count - 1 Do
			Items.CurrentQuerySchemaSelectQuery.ChoiceList.Add(Pos, QueryBatch.Get(Pos)["Name"]);
		EndDo;

		Count = OperatorsNames.GetItems().Count();
		Items.CurrentQuerySchemaOperator.ChoiceList.Clear();
		If NOT(IsNestedQuery) Then
			OperatorsNamesValues = OperatorsNames.GetItems().Get(CurrentQuerySchemaSelectQuery).GetItems();
			Count = OperatorsNamesValues.Count();
			For Pos = 0 To Count - 1 Do
				Items.CurrentQuerySchemaOperator.ChoiceList.Add(Pos, OperatorsNamesValues.Get(Pos)["Name"]);
			EndDo;
		Else
			Pos = 0;
			For Each Operator In Query.Operators Do
				Items.CurrentQuerySchemaOperator.ChoiceList.Add(Pos, Operator.Presentation());
				Pos = Pos + 1;
			EndDo; 
		EndIf;

		Items.DropTableName.ChoiceList.Clear();
		Count = TempTablesNames.Count();
		For Pos = 0 To Count - 1 Do
		    Items.DropTableName.ChoiceList.Add(TempTablesNames.Get(Pos)["Name"]);
		EndDo;
	EndIf;

	If TypeOf(Query) = Type("QuerySchemaTableDropQuery") Then
		HidePagesServer();
		Return;
	EndIf;

	MainObject = FormAttributeToValue("Object");

	Operators  = Query.Operators;
	If CurrentQuerySchemaOperator >= Operators.Count()  Then
		CurrentQuerySchemaOperator = 0;
	EndIf;

	Operator = Operators.Get(CurrentQuerySchemaOperator);

	PageItems = 0;
	PagesItems.Property("AvailableTablesPage", PageItems);
	If PageItems <> Undefined Then
		AvailableTables.GetItems().Clear();
		FillSourcesByIndex(MainObject, AvailableTables.GetItems(),
                           Query.AvailableTables,,,Items.AvailableTablesAvailableTablesSortList.Check,
                           Items.AvailableTablesDisplayChangesTable.Check);
		IsChangedForSaveAvailableTables = True;
	EndIf;

	PageItems = 0;
	PagesItems.Property("SourcesPage", PageItems);
	If PageItems <> Undefined Then
		// ITK30 + {
		ИТК_КонструкторЗапросов.ОбновитьПоляВременныхТаблиц(ЭтотОбъект, QuerySchema, Operator);
		// }
		FillSourcesByIndex(MainObject, Sources.GetItems(), Operator.Sources,, Query.AvailableTables);
		If TypeOf(PagesItems["SourcesPage"]) = Type("Structure") Then
			LoadSelectionModelForSources(PagesItems["SourcesPage"]["p0"], Sources,,,, MainObject, Query);
		EndIf;
	EndIf;

	PageItems = 0;
	PagesItems.Property("AvailableFieldsPage", PageItems);
	If PageItems <> Undefined Then
		AvailableFields.GetItems().Clear();
		FillExpressions(AvailableFields.GetItems(), Operator.SelectedFields, Query, Operator, MainObject);
	EndIf;

	PageItems = 0;
	PagesItems.Property("ConditionsPage", PageItems);
	If PageItems <> Undefined Then
		FillConditions(Conditions.GetItems(), Operator.Filter);
	EndIf;

	PageItems = 0;
	PagesItems.Property("ConditionsFieldsPage", PageItems);
	If PageItems <> Undefined Then
		FillSourcesByIndex(MainObject, AllFieldsForConditions.GetItems(), Operator.Sources);
		If TypeOf(PagesItems["ConditionsFieldsPage"]) = Type("Structure") Then
			LoadSelectionModelForSources(PagesItems["ConditionsFieldsPage"]["p0"], AllFieldsForConditions,,
                                         AllFieldsForConditions, -1, MainObject, Query);
		EndIf;
	EndIf;
		
	PageItems = 0;
	PagesItems.Property("UnionsPage", PageItems);
	If PageItems <> Undefined Then
		FillUnions(Query.Operators);
	EndIf;

	PageItems = 0;
	PagesItems.Property("IndexPage", PageItems);
	If PageItems <> Undefined Then
		FillIndexes(AllFieldsForIndex.GetItems(), Query.Columns, Indexes.GetItems(), Query.Index, Operators, MainObject,
        Query);
		If TypeOf(PagesItems["IndexPage"]) = Type("Structure") Then
			LoadSelectionModelForSources(PagesItems["IndexPage"]["p2"], AllFieldsForIndex,, AllFieldsForIndex, -1, MainObject,
                                         Query);
		EndIf;
	EndIf;

	PageItems = 0;
	PagesItems.Property("OrderPage", PageItems);
	If PageItems <> Undefined Then
		FillOrder(AllFieldsForOrder.GetItems(), Query.Columns, Order.GetItems(), Query.Order, Operators, MainObject, Query);
		If TypeOf(PagesItems["OrderPage"]) = Type("Structure") Then
			LoadSelectionModelForSources(PagesItems["OrderPage"]["p2"], AllFieldsForOrder,, AllFieldsForOrder, -1, MainObject,
                                         Query);
		EndIf;
	EndIf;

	PageItems = 0;
	PagesItems.Property("AutoorderPage", PageItems);
	If PageItems <> Undefined Then
		Autoorder = Query.AutoOrder;
	EndIf;

	PageItems = 0;
	PagesItems.Property("AliasesPage", PageItems);
	If PageItems <> Undefined Then
		FillAliases(Aliases.GetItems(), Unions, Query.Columns, Query,, MainObject);
		GetFieldsDropList(FieldsDropList, Query)
	EndIf;

	PageItems = 0;
	PagesItems.Property("GroupingPage", PageItems);
	If PageItems <> Undefined Then
		FillGroupings(AllFieldsForGrouping.GetItems(), GroupingFields.GetItems(), SummingFields.GetItems(), Query, Operator,
                      MainObject);
		If TypeOf(PagesItems["GroupingPage"]) = Type("Structure") Then
			LoadSelectionModelForSources(PagesItems["GroupingPage"]["p3"], AllFieldsForGrouping,, AllFieldsForGrouping, -1,
                                         MainObject, Query);
									 EndIf;
		IsChangedForSaveAllFieldsForGrouping = True;
	EndIf;

	PageItems = 0;
	PagesItems.Property("TotalsPage", PageItems);
	If PageItems <> Undefined AND NOT DataCompositionMode Then
		FillTotals(AllFieldsForTotals.GetItems(), Query.Columns, TotalsGroupingFields.GetItems(), 
                   Query.TotalCalculationFields,
                   TotalsExpressions.GetItems(), Query.TotalExpressions, Operators, MainObject, Query);
		If TypeOf(PagesItems["TotalsPage"]) = Type("Structure") Then
			LoadSelectionModelForSources(PagesItems["TotalsPage"]["p3"], AllFieldsForTotals,, AllFieldsForTotals, -1, 
                                         MainObject,
                                         Query);
		EndIf;

		FillParameters(QueryParameters, QuerySchema);
	EndIf;

	PageItems = 0;
	PagesItems.Property("OverallPage", PageItems);
	If PageItems <> Undefined Then
		Overall = Query.Overall;
	EndIf;

	PageItems = 0;
	PagesItems.Property("AdditionallyTablesPage", PageItems);
	If PageItems <> Undefined Then
		FillTablesForChange(AdditionallyTables.GetItems(), Operator.Sources, AdditionallyTablesForChanging.GetItems(),
                            Operator.TablesForUpdate, MainObject);
	EndIf;

	PageItems = 0;
	PagesItems.Property("AdditionallyItemsPage", PageItems);
	If PageItems <> Undefined Then
		AdFirstCount = Operator.RetrievedRecordsCount;
		If AdFirstCount = Undefined Then
			AdditionallyFirstCount = 1;
			AdditionallyFirst = False;
		Else
			AdditionallyFirstCount = AdFirstCount;
			AdditionallyFirst = True;
		EndIf;

		AdditionallyWithoutDuplicate = Operator.SelectDistinct;
		AdditionallyPermitted = Query.SelectAllowed;
		LockingData = Operator.SelectForUpdate;
		TempTableName = Query.PlacementTable;
		If Query.PlacementTable = "" Then
			NewQueryType = 0;
		Else
			NewQueryType = 1;
		EndIf;

		If QueryType <> NewQueryType Then
			QueryType = NewQueryType;
		EndIf;
	EndIf;

	PageItems = 0;
	PagesItems.Property("JoinsPage", PageItems);
	If PageItems <> Undefined Then
		FillSourcesJoins(Joins.GetItems(), Operator.Sources, MainObject);
	EndIf;
	
	PageItems = 0;
	PagesItems.Property("DataCompositionRequiredJoinsPage", PageItems);
	If PageItems <> Undefined Then
		FillDataCompositionRequiredJoinsPage(DataCompositionRequiredJoins.GetItems(), Operator.Sources, MainObject);
	EndIf;
	
	PageItems = 0;
	PagesItems.Property("DataCompositionFieldsPage", PageItems);
	If PageItems <> Undefined Then
		FillDataCompositionFields(AllFieldsForDataCompositionFields.GetItems(), DataCompositionFields.GetItems(), Query, MainObject);
		If TypeOf(PagesItems["DataCompositionFieldsPage"]) = Type("Structure") Then
			LoadSelectionModelForSources(PagesItems["DataCompositionFieldsPage"]["p0"], AllFieldsForDataCompositionFields,,
										 AllFieldsForDataCompositionFields, -1, MainObject, Query);
		EndIf;
	EndIf;
	
	PageItems = 0;
	PagesItems.Property("DataCompositionFiltersPage", PageItems);
	If PageItems <> Undefined Then
		FillDataCompositionFilters(AllFieldsForDataCompositionFilters.GetItems(), DataCompositionFilters.GetItems(), Query, Operator, MainObject);
		If TypeOf(PagesItems["DataCompositionFiltersPage"]) = Type("Structure") Then
			LoadSelectionModelForSources(PagesItems["DataCompositionFiltersPage"]["p0"], AllFieldsForDataCompositionFilters,,
										 AllFieldsForDataCompositionFilters, -1, MainObject, Query);
			EndIf;
	EndIf;
	
	PageItems = 0;
	PagesItems.Property("CharacteristicsPage", PageItems);
	If PageItems <> Undefined Then
		FillCharacteristics(Characteristics.GetItems(), Query);
	EndIf;
		
	HidePagesServer();
	
	// ITK1 + {
	ИТК_КонструкторЗапросов.ФормаОсновнаяПослеFillPagesAtServer(ЭтотОбъект);
	// }
	
EndProcedure

&AtServer
Function MakeCache(Val ItemsForChaching, Val CacheField, Val NestedFieldsInOneMap = False)
	Var Item;
	Var Cache;
	Var SubItem;
	Var SubItemsCache;

	Cache = New Map();
	For Each Item In ItemsForChaching Do
		If Item.GetItems().Count() = 0 Then  // Если нет вложенных строк
			Cache.Insert(Item[CacheField], True);
		Else
			If NOT(NestedFieldsInOneMap) Then
				SubItemsCache = New Map(); // если есть вложенные строки
				For Each SubItem In Item.GetItems() Do
					SubItemsCache.Insert(SubItem[CacheField], True);
				EndDo;
				Cache.Insert(Item[CacheField], SubItemsCache);
			Else
				For Each SubItem In Item.GetItems() Do
					Cache.Insert(SubItem[CacheField], True);
				EndDo;
			EndIf;
		EndIf;
	EndDo;
	Return Cache;
EndFunction

&AtClient
Procedure ShowErrorMessage(Val Item = Undefined)
	If ErrorMessages <> "" Then
		ShowMessageBox(, ErrorMessages);
		ErrorMessages = "";
	EndIf;
EndProcedure

&AtClient
Procedure AddErrorMessage(Val NewMessage)
	If ErrorMessages <> "" Then
		ErrorMessages = ErrorMessages + Chars.LF;
	EndIf;
	ErrorMessages = ErrorMessages + NewMessage;
EndProcedure

&AtServer
Procedure AddErrorMessageAtServer(Val NewMessage)
	If ErrorMessages <> "" Then
		ErrorMessages = ErrorMessages + Chars.LF;
	EndIf;
	ErrorMessages = ErrorMessages + NewMessage;
EndProcedure

&AtServerNoContext
Procedure AddErrorMessageAtServerNoContext(ErrorMessages, Val NewMessage)
	If ErrorMessages <> "" Then
		ErrorMessages = ErrorMessages + Chars.LF;
	EndIf;
	ErrorMessages = ErrorMessages + NewMessage;
EndProcedure

&AtServer
Procedure ApplyChangesFromCache(Val ChangesCache, 
								Val QueryWizardAddress, 
								CurrentQuerySchemaSelectQuery,
                                CurrentQuerySchemaOperator, 
								ErrorMessages)
	Var QuerySchema;
	Var Query;
	Var Operators;
	Var Operator;

	QuerySchema = GetFromTempStorage(QueryWizardAddress);
	If QuerySchema = Undefined Then
		Return;
	EndIf;
	Batch = QuerySchema.QueryBatch;
	Query = GetSchemaQuery(QuerySchema, CurrentQuerySchemaSelectQuery, NestedQueryPositionAddress);

	Operators = Undefined;
	Operator = Undefined;

	PageItems = 0;
	If TypeOf(Query) = Type("QuerySchemaSelectQuery") Then
		Operators  = Query.Operators;
		Operator = Operators.Get(CurrentQuerySchemaOperator);
	EndIf;

	// ITK1 * { 
	//ApplyChangesFromCacheNoContext(ChangesCache, QuerySchema, Query, Operators, Operator, ErrorMessages,
	//                               CurrentQuerySchemaSelectQuery, CurrentQuerySchemaOperator);
	ВнешниеИсточники = ИТК_КонструкторЗапросов.ВнешниеИсточники(ЭтотОбъект);
	ApplyChangesFromCacheNoContext(ChangesCache, QuerySchema, Query, Operators, Operator, ErrorMessages,
                                   CurrentQuerySchemaSelectQuery, CurrentQuerySchemaOperator, ВнешниеИсточники);
	// }
	If ChangesCache.Count() > 0 Then
		PutToTempStorage(QuerySchema, QueryWizardAddress);    			
	EndIf; 
EndProcedure

&AtServerNoContext
Procedure ApplyChangesFromCacheNoContext(Val ChangesCache, 
										 Val QuerySchema, 
										 Query, 
										 Val Operators, 
										 Val Operator, 
										 ErrorMessages,
                                         CurrentQuerySchemaSelectQuery, 
// ITK1 * {
										//CurrentQuerySchemaOperator)
										CurrentQuerySchemaOperator,
										ВнешниеИсточники)
// }
	Var Count;
	Var Pos;
	Var Change;
	Var Parameters;
	Var TableName;
	Var ItemIndexes;
	Var NewOrderField;
	Var Field;
	Var Expressions;
	Var Count1;
	Var Pos1;
	Var Index;
	Var Fields;
	Var ParentIndex;
	Var TotalCalculationFields;
	Var NewIndex;
	Var TotalControlPoint;
	Var Interval;
	Var NewPeriod;
	Var NewAlias;
	Var PointType;
	Var TotalExpression;
	Var Expression;
	Var Source;
	Var SourceName;
	Var Name;
	Var Param;

	// Применим все изменения из кэша
	Count = ChangesCache.Count();
	For Pos = 0 To Count - 1 Do
	    Change = ChangesCache.Get(Pos);
		Parameters = Change["Parameters"];

		// имя таблицы для изменения
		If Change["ChangeType"] = "DropTable" Then
			TableName = Parameters["TableName"];
			If TypeOf(Query) = Type("QuerySchemaSelectQuery") Then
				Query.PlacementTable = TableName;
			ElsIf TypeOf(Query) = Type("QuerySchemaTableDropQuery") Then
				Query.TableName = TableName;
			EndIf;
		EndIf;

		// Изменим список условий
		If Change["ChangeType"] = "ChangeConditions" Then
			If Parameters["Type"] = "Clear" Then
				Operator.Filter.Clear();
			EndIf;
			If Parameters["Type"] = "Add" Then
				If Parameters["Condition"] <> "" Then
					Try
						Operator.Filter.Add(Parameters["Condition"]);
					Except
					EndTry;
				EndIf;
			EndIf;
		EndIf;

		// Изменить запрос в пакете запросов
		If Change["ChangeType"] = "ChangeQueryBatch" Then
			// Type = 1 - добавить
			// Type = 2 - добавить копированием
			// Type = 3 - удалить
			// Type = 4 - переместить
			// Type = 5 - добавить запрос уничтожения таблицы

			If Parameters["Type"] = 1 Then
				CurrentQuerySchemaSelectQuery = AddQueryBatchAtServer(QuerySchema);
				CurrentQuerySchemaOperator = 0;
			EndIf;
			If Parameters["Type"] = 2 Then
				Try
					CurrentQuerySchemaSelectQuery = AddQueryBatchCopyAtServer(Parameters["Index"], QuerySchema);
					CurrentQuerySchemaOperator = 0;
				Except
					AddErrorMessageAtServerNoContext(ErrorMessages, BriefErrorDescription(ErrorInfo()));
				EndTry;
			EndIf;
			If Parameters["Type"] = 3 Then
				DeleteQueryBatchAtServer(Parameters["Index"], QuerySchema);
				CurrentQuerySchemaOperator = 0;
				If CurrentQuerySchemaSelectQuery >= QuerySchema.QueryBatch.Count() Then
					CurrentQuerySchemaSelectQuery = QuerySchema.QueryBatch.Count() - 1;
				EndIf;
			EndIf;
			If Parameters["Type"] = 4 Then
				MoveQueryBatchAtServer(Parameters["Index"], Parameters["NewIndex"], QuerySchema);
			EndIf;                                         
			If Parameters["Type"] = 5 Then
				CurrentQuerySchemaSelectQuery = AddQueryBatchDropQueryAtServer(QuerySchema, Parameters["TemporaryTableName"]);
				CurrentQuerySchemaOperator = 0;
			EndIf;
		EndIf;

		// Изменить индекс
		If Change["ChangeType"] = "Index" Then
			// Type = 1 - добавить
			// Type = 2 - удалить
			// Type = 3 - переместить
			// Type = 4 - удалить все
			If Parameters["Type"] = 1 Then
				AddIndexAtServer(Query, Parameters["ParentIndex"], Parameters["Index"], Parameters["Name"], Operator);
			EndIf;
			If Parameters["Type"] = 2 Then
				DeleteIndexAtServer(Parameters["Index"], Query);
			EndIf;
			If Parameters["Type"] = 3 Then
				MoveIndexAtServer(Parameters["Index"], Parameters["NewIndex"], Query);
			EndIf;
			If Parameters["Type"] = 4 Then
				DeleteAllIndexAtServer(Query);
			EndIf;
		EndIf;

		// Изменить порядок
		If Change["ChangeType"] = "Order" Then
			// Type = 1 - добавить
			// Type = 2 - удалить
			// Type = 3 - переместить
			// Type = 4 - Удалить все
     		// Type = 5 - Установить направление порядка

			If Parameters["Type"] = 1 Then
				ItemIndexes = Parameters["Indexes"];
				If Parameters["AddType"] = 1 Then     // выражение добавляем
					NewOrderField = GetSource(Operator.Sources, ItemIndexes);
				ElsIf Parameters["AddType"] = 2 Then  // алиас добавляем
					NewOrderField = GetSource(Query.Columns, ItemIndexes);
				EndIf;
				AddOrderAtServer(Query, NewOrderField);
			EndIf;
			If Parameters["Type"] = 2 Then
				DeleteOrderAtServer(Parameters["Index"], Query);
			EndIf;
			If Parameters["Type"] = 3 Then
				MoveOrderAtServer(Parameters["Index"], Parameters["NewIndex"], Query);
			EndIf;
			If Parameters["Type"] = 4 Then
				DeleteAllOrderAtServer(Query);
			EndIf;
			If Parameters["Type"] = 5 Then


				SetOrderTypeAtServer(Parameters["Index"], Parameters["OrderType"], Query);
			EndIf;
		EndIf;

		If Change["ChangeType"] = "Autoorder" Then
			Query.AutoOrder = Parameters["Autoorder"];
		EndIf;

		If Change["ChangeType"] = "Unions" Then
			// Type = 1 - добавить
			// Type = 2 - удалить
			// Type = 3 - переместить
			// Type = 4 - установить без дубликатов

			If Parameters["Type"] = 1 Then
				CurrentQuerySchemaOperator = UnionAddAtServer(Operators, Parameters["Index"]);
			EndIf;
			If Parameters["Type"] = 2 Then
				UnionDeleteAtServer(Operators, Parameters["Index"]);
				If CurrentQuerySchemaOperator >= Operators.Count() Then
					CurrentQuerySchemaOperator = Operators.Count() - 1;
				EndIf;
			EndIf;
			If Parameters["Type"] = 3 Then
				UnionMoveAtServer(Operators, Parameters["Index"], Parameters["NewIndex"]);
			EndIf;
			If Parameters["Type"] = 4 Then
				UnionSetWithoutDuplicatesAtServer(Operators, Parameters["Index"], Parameters["WithoutDuplicates"]);
			EndIf;
		EndIf;

		If Change["ChangeType"] = "Aliases" Then
			// Type = 1 - удалить
			// Type = 2 - переместить
			// Type = 3 - переименовать
			// Type = 4 - установить поле

			If Parameters["Type"] = 1 Then
				AliasDeleteAtServer(Parameters["ParentIndex"], Parameters["Index"], Query);
			EndIf;
			If Parameters["Type"] = 2 Then
				AliasMoveAtServer(Parameters["ParentIndex"], Parameters["Index"], Parameters["NewIndex"], Query);
			EndIf;
			If Parameters["Type"] = 3 Then
				AliasRenameAtServer(Parameters["ParentIndex"], Parameters["Index"], Parameters["Name"], Query);
			EndIf;
			If Parameters["Type"] = 4 Then
				AliasSetFieldAtServer(Parameters["ParentIndex"], Parameters["Index"], Parameters["QueryPosition"],
                                       Parameters["FieldPosition"], Query);
			EndIf;
		EndIf;

		If Change["ChangeType"] = "Group" Then
			// Type = 1 - добавить
			// Type = 4 - добавлять и игнорировать исключения
			// Type = 2 - удалить
			// Type = 3 - удалить все
			// Type = 5 - добавить из агрегатных полей

			If (Parameters["Type"] = 1) OR (Parameters["Type"] = 4) Then
				Try
					Operator.Group.Add(Parameters["Name"]);
					Except
					If Parameters["Type"] <> 4 Then
						AddErrorMessageAtServerNoContext(ErrorMessages, BriefErrorDescription(ErrorInfo()));
					EndIf;
				EndTry;
			EndIf;

			If Parameters["Type"] = 2 Then
				Operator.Group.Delete(Parameters["Index"]);
			EndIf;
			If Parameters["Type"] = 3 Then
				Operator.Group.Clear();
			EndIf;

			If Parameters["Type"] = 5 Then
				Try
					Field = FindFieldByIndex(Operator.SelectedFields, Parameters["ParentIndex"], Parameters["Index"]);
					If Field <> Undefined Then
						RemoveAgregateField(Parameters["ParentIndex"], Parameters["Index"], Query, Operator);
						Operator.Group.Add(Field);
					EndIf;
					Except
				EndTry;
			EndIf;
		EndIf;

		If Change["ChangeType"] = "Summ" Then
			// Type = 1 - добавить
			// Type = 4 - изменить
			// Type = 5 - изменить на агрегатное поле
			// Type = 6 - изменить на агрегатное поле и игнорировать исключения
			// Type = 2 - удалить
			// Type = 3 - удалить все агрегатные поля
			// Type = 7 - добавить поле из группировки

			If (Parameters["Type"] = 1) OR (Parameters["Type"] = 5)  OR (Parameters["Type"] = 6) OR (Parameters["Type"] = 7) 
            Then

				Expressions = GetAgregateExpressions(Parameters["Name"]);
			EndIf;

			If Parameters["Type"] = 1 Then
				Count1 = Expressions.Count();
				For Pos1 = 0 To Count1 - 1 Do
					Try
						AddFieldAtServer(Expressions.Get(Pos1), Operator);
						Break;
					Except
					EndTry;
				EndDo;
			EndIf;

			If (Parameters["Type"] = 5) OR (Parameters["Type"] = 6) Then
				Count1 = Expressions.Count();
				For Pos1 = 0 To Count1 - 1 Do
					Try
						ChangeExpressionAtServer(Parameters["ParentIndex"], Parameters["Index"], Expressions.Get(Pos1), Operator);
						Break;
					Except
					EndTry;
				EndDo;
			EndIf;

			If Parameters["Type"] = 7 Then
				Count1 = Expressions.Count();
				Field =  Operator.Group.Get(Parameters["ParentIndex"]);
				Operator.Group.Delete(Parameters["ParentIndex"]);
				Index = Undefined;
				Fields = FindFieldIndex(Field, Operator.SelectedFields, Index);
				If (Fields <> Undefined)
					AND (Index <> Undefined)
					AND (Index >= 0) Then

					For Pos1 = 0 To Count1 - 1 Do
						Try
							If TypeOf(Field) = Type("QuerySchemaExpression") Then
								Fields.Set(Index, New QuerySchemaExpression(Expressions.Get(Pos1)));
							EndIf;
							Break;
						Except
						EndTry;
					EndDo;
				EndIf;
			EndIf;

			If Parameters["Type"] = 4 Then
				Try
					ChangeExpressionAtServer(Parameters["ParentIndex"], Parameters["Index"], Parameters["Name"], Operator);
				Except
					AddErrorMessageAtServerNoContext(ErrorMessages, BriefErrorDescription(ErrorInfo()));
				EndTry;
			EndIf;

			If Parameters["Type"] = 2 Then
				RemoveAgregateField(Parameters["ParentIndex"], Parameters["Index"], Query, Operator);
			EndIf;

			If Parameters["Type"] = 3 Then
				DeleteAllSummingFields(Operator.SelectedFields, Query, Operator);
			EndIf;
		EndIf;

		If Change["ChangeType"] = "Join" Then
			// Type = 1 - добавить условие
			// Type = 2 - удалить условие
			// Type = 3 - изменить тип
			// Type = 4 - заменить условие

			If Parameters["Type"] = 1 Then
				Try
					AddJoin(Parameters["ParentTable"], Parameters["ChildTable"], Parameters["Expression"], Operator);
					RemoveJoin(Parameters["ParentTable"], Parameters["ChildTable"], Operator);
					AddJoin(Parameters["ParentTable"], Parameters["ChildTable"], Parameters["Expression"], Operator);
				Except
					AddErrorMessageAtServerNoContext(ErrorMessages, BriefErrorDescription(ErrorInfo()));
				EndTry;
			EndIf;

			If Parameters["Type"] = 2 Then
				RemoveJoin(Parameters["ParentTable"], Parameters["ChildTable"], Operator);
			EndIf;

			If Parameters["Type"] = 3 Then
				SetJoinType(Parameters["ParentTable"], Parameters["ChildTable"], Parameters["JoinType"], Operator);
			EndIf;

			If Parameters["Type"] = 4 Then
				Try
					SetJoin(Parameters["ParentTable"], Parameters["ChildTable"], Parameters["Expression"], Operator);
				Except
					AddErrorMessageAtServerNoContext(ErrorMessages, BriefErrorDescription(ErrorInfo()));
				EndTry;
			EndIf;
		EndIf;

		If Change["ChangeType"] = "TotalsFields" Then
			// Type = 1 - добавить
			// Type = 2 - удалить
			// Type = 3 - удалить все
			// Type = 4 - переместить
			// Type = 5 - добавить поле по имени
			// Type = 6 - добавить из выражений
			// Type = 7 - тип дополнения
			// Type = 8 - начало перода
			// Type = 9 - конец периода
			// Type = 10 - общие итоги
			// Type = 11 - установить алиас
			// Type = 12 - установить тип

			If Parameters["Type"] = 1 Then
				ParentIndex = Parameters["ParentIndex"];
				If ParentIndex < 0 Then
					Field = Query.Columns.Get(Parameters["Index"]);
				Else
					Field = Query.Columns.Get(ParentIndex).Columns.Get(Parameters["Index"]);
				EndIf;

				If Field <> Undefined Then
					Order = Query.TotalCalculationFields.Add(Field);
				EndIf;
			EndIf;

			If Parameters["Type"] = 5 Then
				Query.TotalCalculationFields.Add(Parameters["FieldName"]);
			EndIf;

			If Parameters["Type"] = 2 Then
				Query.TotalCalculationFields.Delete(Parameters["Index"]);
			EndIf;

			If Parameters["Type"] = 3 Then
				Query.TotalCalculationFields.Clear();
			EndIf;

			If Parameters["Type"] = 4 Then
				Index = Parameters["Index"];
				NewIndex = Parameters["ParentIndex"];
				TotalCalculationFields = Query.TotalCalculationFields;
				Count = TotalCalculationFields.Count();
				If (NewIndex >= 0) OR NewIndex < Count Then
					TotalCalculationFields.MoveTo(Index, NewIndex);
				EndIf;
			EndIf;

			If Parameters["Type"] = 6 Then
				Field = Query.TotalExpressions.Get(Parameters["Index"]).Field;
				Query.TotalExpressions.Delete(Parameters["Index"]);
				Query.TotalCalculationFields.Add(Field);
			EndIf;

			If Parameters["Type"] = 7 Then
				Interval = Parameters["Param"];
				TotalControlPoint = Query.TotalCalculationFields.Get(Parameters["Index"]);
				If TotalControlPoint <> Undefined Then
					If Interval = "Day" Then
						TotalControlPoint.PeriodAdditionType = QuerySchemaPeriodAdditionType.Day;
					ElsIf Interval = "TenDays" Then
					    TotalControlPoint.PeriodAdditionType = QuerySchemaPeriodAdditionType.TenDays ;
					ElsIf Interval = "HalfYear" Then
					    TotalControlPoint.PeriodAdditionType = QuerySchemaPeriodAdditionType.HalfYear;
					ElsIf Interval = "Hour" Then
					    TotalControlPoint.PeriodAdditionType = QuerySchemaPeriodAdditionType.Hour;
					ElsIf Interval = "Minute" Then
					    TotalControlPoint.PeriodAdditionType = QuerySchemaPeriodAdditionType.Minute;
					ElsIf Interval = "Month" Then
					    TotalControlPoint.PeriodAdditionType = QuerySchemaPeriodAdditionType.Month;
					ElsIf Interval = "NoAddition" Then
					    TotalControlPoint.PeriodAdditionType = QuerySchemaPeriodAdditionType.NoAddition;
					ElsIf Interval = "Quarter" Then
					    TotalControlPoint.PeriodAdditionType = QuerySchemaPeriodAdditionType.Quarter;
					ElsIf Interval = "Second" Then
					    TotalControlPoint.PeriodAdditionType = QuerySchemaPeriodAdditionType.Second;
					ElsIf Interval = "Week" Then
					    TotalControlPoint.PeriodAdditionType = QuerySchemaPeriodAdditionType.Week;
					ElsIf Interval = "Year" Then
					    TotalControlPoint.PeriodAdditionType = QuerySchemaPeriodAdditionType.Year;
					EndIf;
				EndIf;
			EndIf;

			If Parameters["Type"] = 8 Then
				NewPeriod = Parameters["Param"];
				TotalControlPoint = Query.TotalCalculationFields.Get(Parameters["Index"]);
				TotalControlPoint.PeriodAdditionBegin = NewPeriod;
			EndIf;

			If Parameters["Type"] = 9 Then
				NewPeriod = Parameters["Param"];
				TotalControlPoint = Query.TotalCalculationFields.Get(Parameters["Index"]);
				TotalControlPoint.PeriodAdditionEnd = NewPeriod;
			EndIf;

			If Parameters["Type"] = 10 Then

			EndIf;

			If Parameters["Type"] = 11 Then
				NewAlias = Parameters["Param"];
				TotalControlPoint = Query.TotalCalculationFields.Get(Parameters["Index"]);
				Try
					TotalControlPoint.ColumnName = NewAlias;
				Except
					AddErrorMessageAtServerNoContext(ErrorMessages, BriefErrorDescription(ErrorInfo()));
				EndTry;
			EndIf;

			If Parameters["Type"] = 12 Then
				PointType = Parameters["Param"];
				TotalControlPoint = Query.TotalCalculationFields.Get(Parameters["Index"]);
				If PointType = "Items" Then
					TotalControlPoint.TotalCalculationFieldType = QuerySchemaTotalCalculationFieldType.Items;
				ElsIf PointType = "Hierarchy" Then
				    TotalControlPoint.TotalCalculationFieldType = QuerySchemaTotalCalculationFieldType.Hierarchy ;
				ElsIf PointType = "HierarchyOnly" Then
				    TotalControlPoint.TotalCalculationFieldType = QuerySchemaTotalCalculationFieldType.HierarchyOnly;
				EndIf;
			EndIf;
		EndIf;

		If Change["ChangeType"] = "Overall" Then
			Query.Overall = Parameters["Overall"];
		EndIf;

		If Change["ChangeType"] = "TotalsExpressions" Then
			// Type = 1 - добавить
			// Type = 2 - удалить
			// Type = 3 - удалить все
			// Type = 4 - доавить из группировочных полей
			// Type = 5 - установить выражение

			If Parameters["Type"] = 1 Then
				ParentIndex = Parameters["ParentIndex"];
				If ParentIndex < 0 Then
					Field = Query.Columns.Get(Parameters["Index"]);
				Else
					Field = Query.Columns.Get(ParentIndex).Columns.Get(Parameters["Index"]);
				EndIf;

				If Field <> Undefined Then
					Query.TotalExpressions.Add(Field);
				EndIf;
			EndIf;

			If Parameters["Type"] = 2 Then
				Query.TotalExpressions.Delete(Parameters["Index"]);
			EndIf;

			If Parameters["Type"] = 3 Then
				Query.TotalExpressions.Clear();
			EndIf;

			If Parameters["Type"] = 4 Then
				Field = Query.TotalCalculationFields.Get(Parameters["Index"]).Expression;
				If TypeOf(Field) = Type("QuerySchemaColumn") Then
					Query.TotalCalculationFields.Delete(Parameters["Index"]);
					Query.TotalExpressions.Add(Field);
				EndIf;
			EndIf;

			If Parameters["Type"] = 5 Then
				Try
				    TotalExpression = Query.TotalExpressions.Get(Parameters["Index"]);
					TotalExpression.Expression = Parameters["Expression"];
				Except
					AddErrorMessageAtServerNoContext(ErrorMessages, BriefErrorDescription(ErrorInfo()));
				EndTry;
			EndIf;
		EndIf;

		If Change["ChangeType"] = "AvailableFields" Then
			// Type = 1 - добавить
			// Type = 2 - удалить
			// Type = 3 - удалить все
			// Type = 4 - изменить

			If Parameters["Type"] = 1 Then
				ItemIndexes = Parameters["ItemIndexes"];
				If ItemIndexes <> Undefined Then
					Expression = GetSource(Query.AvailableTables, ItemIndexes);
					// ITK1 + {
					ИТК_КонструкторЗапросов.ФормаОсновнаяВнутриApplyChangesFromCacheNoContextДобавитьВременнуюТаблицуВИсточникиОператора(ВнешниеИсточники, Source, Operator, ItemIndexes, Expression);
					// }
					Else
					Expression = Parameters["Expression"];
				EndIf;

				Try
					AddExpressionAtServer(Expression, Operator);
				Except
					AddErrorMessageAtServerNoContext(ErrorMessages, BriefErrorDescription(ErrorInfo()));
				EndTry;
			EndIf;

			If Parameters["Type"] = 2 Then
				ParentIndex = Parameters["ParentIndex"];

				If ParentIndex < 0 Then
					Fields = Operator.SelectedFields;
				Else
					Fields = Operator.SelectedFields.Get(ParentIndex).Fields;
				EndIf;
				If Fields <> Undefined Then
					Fields.Delete(Parameters["Index"]);
				EndIf;
			EndIf;

			If Parameters["Type"] = 3 Then
				Operator.SelectedFields.Clear();
			EndIf;

			If Parameters["Type"] = 4 Then
				Try
					ChangeExpressionAtServer(Parameters["ParentIndex"], Parameters["Index"], Parameters["Expression"], Operator);
				Except
					AddErrorMessageAtServerNoContext(ErrorMessages, BriefErrorDescription(ErrorInfo()));
				EndTry;
			EndIf;
		EndIf;

		If Change["ChangeType"] = "Sources" Then
			// Type = 1 - добавить
			// Type = 2 - удалить
			// Type = 3 - удалить все
			// Type = 4 - переименовать
			// Type = 5 - заменить таблицу

			If Parameters["Type"] = 1 Then
				ItemIndexes = Parameters["Index"];
				Source = GetSource(Query.AvailableTables, ItemIndexes);
				// ITK1 + {
				ИТК_КонструкторЗапросов.ФормаОсновнаяВнутриApplyChangesFromCacheNoContextДобавитьВременнуюТаблицуВИсточникиОператора(ВнешниеИсточники, Source, Operator, ItemIndexes);
				// }
				Try
				    Operator.Sources.Add(Source);
				Except
				EndTry;
			EndIf;

			If Parameters["Type"] = 2 Then
				SourceName = Parameters["Name"];
				Operator.Sources.Delete(SourceName);
			EndIf;

			If Parameters["Type"] = 3 Then
				Operator.Sources.Clear();
			EndIf;

			If Parameters["Type"] = 4 Then
				Name = Parameters["Name"];
				Index = Parameters["Index"];
				Try
					Operator.Sources.Get(Index).Source.Alias = Name;
				Except
					AddErrorMessageAtServerNoContext(ErrorMessages, BriefErrorDescription(ErrorInfo()));
				EndTry;
			EndIf;

			If Parameters["Type"] = 5 Then
				Index = Parameters["Index"];
				ItemIndexes = Parameters["Name"];
				Source = GetSource(Query.AvailableTables, ItemIndexes);
				If (Index >=0) AND Index < Operator.Sources.Count() Then
					Operator.Sources.Replace(Index, Source);
				EndIf;
			EndIf;

		EndIf;

		If Change["ChangeType"] = "TablesForChange" Then
			// Type = 1 - добавить
			// Type = 2 - удалить
			// Type = 3 - удалить все

			// Type = 4 - Первые
			// Type = 5 - Без повторяющихся
			// Type = 6 - Разрешенные
			// Type = 7 - Блокировать получаемые данные для последующего изменения
			// Type = 8 - Тип запроса

			If Parameters["Type"] = 1 Then
				Index = Parameters["Index"];
				Try
					Operator.TablesForUpdate.Add(Operator.Sources.Get(Index));
				Except
				EndTry;
			EndIf;

			If Parameters["Type"] = 2 Then
				Index = Parameters["Index"];
				Operator.TablesForUpdate.Delete(Index);
			EndIf;

			If Parameters["Type"] = 3 Then
				Index = Parameters["Index"];
				Operator.TablesForUpdate.Clear();
			EndIf;

			If Parameters["Type"] = 4 Then
				Param = Parameters["Param"];
				If (TypeOf(Param) = Type("Boolean"))
					AND NOT(Param) Then
					Operator.RetrievedRecordsCount = Undefined;
				Else
					Operator.RetrievedRecordsCount = Param;
				EndIf;
			EndIf;

			If Parameters["Type"] = 5 Then
				Param = Parameters["Param"];
				Operator.SelectDistinct = Param;
			EndIf;

			If Parameters["Type"] = 6 Then
				Param = Parameters["Param"];
				Query.SelectAllowed = Param;
			EndIf;

			If Parameters["Type"] = 7 Then
				Param = Parameters["Param"];
				Operator.SelectForUpdate = Param;
			EndIf;

			If Parameters["Type"] = 8 Then
				Param = Parameters["Param"];
				Name = Parameters["Name"];

				If Param = 0 Then
					Query.PlacementTable = "";
				EndIf;

				If Param = 1 OR Param = 2 Then
					Query.PlacementTable = Name;
				EndIf;
			EndIf;
		EndIf;
		
		// Применим изменения обязательности соединений
		If Change["ChangeType"] = "ChangeDataCompositionRequiredJoins" Then
			Try
				Param = Change["Parameters"];
				Join = Operator.Sources.FindByAlias(Param["Parent"]).Joins.FindByAlias(Param["Alias"]);
				Join.RequiredJoin = Param["Required"];
				Join.OptionalJoinsGroupBegin = Param["GroupBegin"];
			Except
			EndTry;
		EndIf;
		
		// Изменим список полей выбора компоновки данных
		If Change["ChangeType"] = "ChangeDataCompositionFields" Then
			If Parameters["Type"] = "Clear" Then
				Query.DataCompositionSelectionFields.Clear();
			EndIf;
			If Parameters["Type"] = "Add" Then
				If Parameters["Expression"] <> "" Then
					Try
						Query.DataCompositionSelectionFields.Add(Parameters["Expression"]);
						Field = Query.DataCompositionSelectionFields.Get(Query.DataCompositionSelectionFields.Count() - 1);
						Field.UseAttributes = Parameters["UseAttributes"];
						Field.Alias = Parameters["Alias"];
					Except
					EndTry;
				EndIf;
			EndIf;
		EndIf;
		
		// Изменим список выражений отбора компоновки данных
		If Change["ChangeType"] = "ChangeDataCompositionFilters" Then
			If Parameters["Type"] = "Clear" Then
				Operator.DataCompositionFilterExpressions.Clear();
			EndIf;
			If Parameters["Type"] = "Add" Then
				If Parameters["Expression"] <> "" Then
					Try
						Operator.DataCompositionFilterExpressions.Add(Parameters["Expression"]);
						Filter = Operator.DataCompositionFilterExpressions.Get(Operator.DataCompositionFilterExpressions.Count() - 1);
						Filter.UseAttributes = Parameters["UseAttributes"];
						Filter.Alias = Parameters["Alias"];
					Except
					EndTry;
				EndIf;
			EndIf;
		EndIf;
		
		// Изменим список характеристик
		If Change["ChangeType"] = "ChangeCharacteristics" Then
			If Parameters["Type"] = "Clear" Then
				Query.Characteristics.Clear();
			EndIf;
			If Parameters["Type"] = "Add" Then
				Try
					Query.Characteristics.Add(Parameters["CharType"],
								  			  Parameters["CharacteristicTypesTable"], Parameters["CharacteristicTypesQuery"],
											  Parameters["KeyField"], Parameters["NameField"], Parameters["ValueTypeField"],
											  Parameters["CharacteristicValuesTable"], Parameters["CharacteristicValuesQuery"],
											  Parameters["ObjectField"], Parameters["TypeField"], Parameters["ValueField"]);
				Except
				EndTry;
			EndIf;
		EndIf;
		
	EndDo;
EndProcedure

&AtServer
Procedure SetPageVisableServer(Val Page, Val State)
	If Page.Visible <> State Then
		Page.Visible = State;
	EndIf;
EndProcedure

&AtServer
Procedure HidePagesServer()
	Var State;
	Var SourcesCount;
	
	SourcesCount = Sources.GetItems().Count();

	State = (QueryType <> 2);
	SetPageVisableServer(Items.TablesAndFieldsPage, State);

	State = (SourcesCount > 1) AND (QueryType <> 2);
	SetPageVisableServer(Items.JoinsPage, State);

	State = (QueryType <> 2);
	SetPageVisableServer(Items.GroupingPage, State);

	State = (QueryType <> 2);
	SetPageVisableServer(Items.ConditionsPage, State);

	State = (QueryType <> 2);
	SetPageVisableServer(Items.AdditionallyPage, State);

	State = (QueryType <> 2);
	SetPageVisableServer(Items.UnionsAliasesPage, State);

	State = (QueryType = 1);
	SetPageVisableServer(Items.IndexPage, State);

	State = (QueryType = 0) AND NOT(IsNestedQuery);
	// ITK34 + {
	State = State ИЛИ AdditionallyFirst;
	// }
	// ITK777 + {
	QuerySchema = GetFromTempStorage(QueryWizardAddress);
	Query = GetSchemaQuery(QuerySchema, CurrentQuerySchemaSelectQuery, NestedQueryPositionAddress);
	Элементы["DataCompositionPage"].Видимость = (ТипЗнч(Query) = Тип("ЗапросВыбораСхемыЗапроса"));
	// }
	SetPageVisableServer(Items.OrderPage, State);

	State = (QueryType = 0) AND NOT(IsNestedQuery) AND NOT (DataCompositionMode);
	SetPageVisableServer(Items.TotalsPage, State);

	State = (QueryType = 2);
	SetPageVisableServer(Items.DropTablePage, State);

	State = (IsNestedQuery = False);
	SetPageVisableServer(Items.QueryBatchPage, State);

	If IsNestedQuery Then
		If Items.CurrentQuerySchemaSelectQuery.Enabled Then
			Items.CurrentQuerySchemaSelectQuery.Enabled = False;
		EndIf;

		If AdditionallyFirst Then
			SetPageVisableServer(Items.OrderPage, True);
		Else
			SetPageVisableServer(Items.OrderPage, False);
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure SetPageState(Val PageName, Val State) Экспорт // ITK17 + Добавлен экспорт
	
	// ITK15 + {
	ИТК_КонструкторЗапросовКлиент.ОсновнаяФормаПередSetPageState(ЭтотОбъект, PageName, State);
	// }
	
	If PagesState[PageName] = State Then
		Return;
	EndIf;

	If State Then
		Items.AcceptChanges.Enabled = True;
		LastPage = Items.Query.CurrentPage.Name;
	EndIf;

	PagesState[PageName] = State;
	
EndProcedure

&AtClient
Procedure InvalidateAllPages(Val State = False)
	Var Item;

	For Each Item In PagesState Do
		PagesState[Item.Key] = State;
	EndDo;
EndProcedure

&AtClient
Procedure FixChanges()
	// ITK28 + {
	Если PagesState["GroupingPage"]	Тогда
		SummingFieldsBeforeEditEndHandler();
	КонецЕсли;
	// }
	If PagesState["ConditionsPage"] Then
		ConditionChangesToCache();
	EndIf;

	If PagesState["AdditionallyItemsPage"] Then
		If AdditionallyFirst Then
			ChangeTablesForChangeAtCache(4,,,AdditionallyFirstCount);
		Else
			ChangeTablesForChangeAtCache(4,,,False);
		EndIf;

		ChangeTablesForChangeAtCache(5,,,AdditionallyWithoutDuplicate);
		ChangeTablesForChangeAtCache(6,,,AdditionallyPermitted);
		ChangeTablesForChangeAtCache(7,,,LockingData);
		ChangeTablesForChangeAtCache(8,, TempTableName, QueryType);
	EndIf;

	If PagesState["DropTablePage"] Then
		ChangeDropTableAtCache(DropTableName);
	EndIf;
	
	If PagesState["DataCompositionRequiredJoinsPage"] Then
		DataCompositionRequiredJoinsChangesToCache();
	EndIf;
	
	If PagesState["DataCompositionFieldsPage"] Then
		DataCompositionFieldsChangesToCache();
	EndIf;
	
	If PagesState["DataCompositionFiltersPage"] Then
		DataCompositionFiltersChangesToCache();
	EndIf;
	
	If PagesState["CharacteristicsPage"] Then
		CharacteristicsChangesToCache();
	EndIf;
		
EndProcedure

&AtClient
Procedure ConditionChangesToCache()
	Var Change;
	Var NewItem;
	Var TreeItems;
	Var Count;
	Var Pos;
	Var Item;

	Change = New Structure;
	Change.Insert("Type", "Clear");
	NewItem = ChangesCache.Add();
	NewItem["ChangeType"] = "ChangeConditions";
	NewItem["Parameters"] = Change;

	TreeItems = Conditions.GetItems();
	Count = TreeItems.Count();
	For Pos= 0 To Count - 1 Do
		Item = TreeItems.Get(Pos);

		Change = New Structure;
		Change.Insert("Type", "Add");
		Change.Insert("Condition", Item["Condition"]);

		NewItem = ChangesCache.Add();
		NewItem["ChangeType"] = "ChangeConditions";
		NewItem["Parameters"] = Change;
	EndDo;
EndProcedure

&AtClient
Procedure SavePageState(Val PageName, 
						Val Position, 
						Val ItemName, 
						Val AttributeName, 
						Val PagesItems, 
						Val State = False, 
						Val StartIndex = Undefined)
	Var Item;
	Var Attribute;
	Var AttributeItem;
	Var SelectionModel;
	Var PageItems;

	If PagesState[PageName] Then
		SetPageState(PageName, State);
		Item = Items[ItemName];
		SelectionModel = New Map;
		If Item.Parent.Visible
			AND ((Item.Parent.Parent = Undefined) OR Item.Parent.Parent.Visible) Then
			Attribute = ThisForm[AttributeName];
			If StartIndex <> Undefined Then
				For Each AttributeItem In Attribute.GetItems() Do
					If AttributeItem["Index"] = StartIndex Then
						Attribute = AttributeItem;
						Break;
					EndIf;
				EndDo;
			EndIf;
			SaveSelectionModel(SelectionModel, Item, Attribute);
		EndIf;

		If PagesItems.Property(PageName) Then
			PagesItems[PageName].Insert("p" + String(Position), SelectionModel);
		Else
			PageItems = New Structure;
			PageItems.Insert("p" + String(Position), SelectionModel);
			PagesItems.Insert(PageName, PageItems);
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure LoadPageState(Val PageName, 
						Val Position, 
						Val ItemName, 
						Val Attribute, 
						Val PagesItems, 
						Val StartIndex = Undefined)
	Var Item;
	Var AttributeItem;
	Var AttributeForLoad;

	If PagesItems.Property(PageName) Then
		Item = Items[ItemName];
		If Item.Parent.Visible Then
			AttributeForLoad = Attribute;
			If StartIndex <> Undefined Then
					For Each AttributeItem In Attribute.GetItems() Do
					If AttributeItem["Index"] = StartIndex Then
						AttributeForLoad = AttributeItem;
						Break;
					EndIf;
				EndDo;
			EndIf;
			LoadSelectionModel(PagesItems[PageName]["p" + String(Position)], Item, AttributeForLoad);
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure SaveSelectionModel(Val TreeSelectionModel, Val ItemsTree, Val Tree, Val ParentPosition = "p0")
	Var TreeItems;
	Var Count;
	Var Pos;
	Var TreeType;
	Var Item;
	Var CurrentRow;
	Var Type;
	Var Id;
	Var IsExpanded;

	If ParentPosition = "p0" Then
		TreeSelectionModel.Clear();
	EndIf;
	If (TypeOf(Tree) = Type("FormDataTree"))  OR (TypeOf(Tree) = Type("FormDataTreeItem")) Then
		TreeType = 1;
	    TreeItems = Tree.GetItems();
	Else
		TreeType = 2;
		TreeItems = Tree;
	EndIf;

	Count = TreeItems.Count();
	For Pos = 0 To Count - 1 Do
		Item = TreeItems.Get(Pos);
		IsExpanded = False;
		If TreeType = 1 Then
			If ItemsTree.Expanded(Item.GetID()) = True Then
				Type = "1";
				IsExpanded = True;
			Else
				Type = "0";
			EndIf;
		Else
			Type = "0";
		EndIf;

		CurrentRow = ItemsTree.CurrentRow;
		If (CurrentRow <> Undefined) AND (Item.GetID() = CurrentRow) Then
			Type = Type + "1";
		Else
			Type =  Type + "0";
		EndIf;

		Id = ParentPosition + "_" + String(Pos);
		If Type <> "00" Then
			TreeSelectionModel.Insert(Id, Type);
		EndIf;

		If (TreeType = 1)
			AND IsExpanded Then
			SaveSelectionModel(TreeSelectionModel, ItemsTree, Item, Id);
		EndIf;
	EndDo;
EndProcedure

&AtServerNoContext
Function FindFieldIndex(Val SearchingField, Val Fields, RetIndex)
	Var Field;

	RetIndex = Fields.IndexOf(SearchingField);
	If (RetIndex <> Undefined)
		AND (RetIndex >=0) Then

		Return Fields;
	Else
		For Each Field In Fields Do
			If TypeOf(Field) = Type("QuerySchemaNestedTable") Then
				RetIndex = Field.Fields.IndexOf(SearchingField);
				If (RetIndex <> Undefined)
					AND (RetIndex >=0) Then

					Return Field.Fields;
				EndIf;
			EndIf;
		EndDo;
	EndIf;

	Return Undefined;
EndFunction

&AtClient
Procedure LoadSelectionModel(Val TreeSelectionModel, Val ItemsTree, Val Tree, Val ParentPosition = "p0")
	Var TreeItems;
	Var Count;
	Var Pos;
	Var Id;
	Var Type;
	Var TreeType;
	Var Prop;
	Var Item;
	Var IsExpanded;

	If TreeSelectionModel.Count() = 0 Then
		Return;
	EndIf;

	If (TypeOf(Tree) = Type("FormDataTree"))  OR (TypeOf(Tree) = Type("FormDataTreeItem")) Then
		TreeType = 1;
	    TreeItems = Tree.GetItems();
	Else
		TreeType = 2;
		TreeItems = Tree;
	EndIf;

	Count = TreeItems.Count();
	For Pos = 0 To Count - 1 Do
		Item = TreeItems.Get(Pos);
		Id = ParentPosition + "_" + String(Pos);
		IsExpanded = False;
		Try
			Type = TreeSelectionModel.Get(Id);
			If Type <> Undefined Then
				If (TreeType = 1) AND (Mid(Type, 1, 1) = "1") Then
					If (TreeItems.Count() = 1) Then
						Prop = 0;
						TreeItems.Get(0).Property("Name", Prop);
						If (Prop <> Undefined)
							AND (TreeItems.Get(0)["Name"] = "FakeFieldeItem") Then
							Return;
						EndIf;
					EndIf;
					ItemsTree.Expand(Item.GetID());
					IsExpanded = True;
				EndIf;

				If Mid(Type, 2, 1) = "1" Then
					ItemsTree.CurrentRow = Item.GetID();
				EndIf;
			EndIf;

			If TreeType = 1 Then
				If IsExpanded Then
					LoadSelectionModel(TreeSelectionModel, ItemsTree, Item, Id);
				EndIf;
			EndIf;
		Except
		EndTry;
	EndDo;
EndProcedure

&AtServer
Procedure LoadSelectionModelForSources(Val TreeSelectionModel, 
									   Val TreeParam, 
									   Val ParentPosition = "p0", 
									   Val Parent = Undefined,
                                       StartPosition = Undefined, 
									   MainOblect = Undefined, 
									   Query = Undefined)
	Var Tree;
	Var TreeTmpItem;
	Var TreeItems;
	Var Count;
	Var Pos;
	Var Id;
	Var Type;
	Var TreeType;
	Var Prop;
	Var Item;

	Tree = TreeParam;
	If Parent = Undefined Then
		Parent = Tree;
	EndIf;

	If (StartPosition <> Undefined)
		AND (TypeOf(Tree) = Type("FormDataTree")) Then
		For Each TreeTmpItem In Tree.GetItems() Do
			If TreeTmpItem["Index"] = StartPosition Then
				Tree = TreeTmpItem;
			EndIf;
		EndDo;
		StartPosition = Undefined;
	EndIf;

	If NOT(TreeSelectionModel.Count()) Then
		Return;
	EndIf;

	If (TypeOf(Tree) = Type("FormDataTree"))  OR (TypeOf(Tree) = Type("FormDataTreeItem")) Then
		TreeType = 1;
	    TreeItems = Tree.GetItems();
	Else
		TreeType = 2;
		TreeItems = Tree;
	EndIf;

	Count = TreeItems.Count();
	For Pos = 0 To Count - 1 Do
		Item = TreeItems.Get(Pos);
		Id = ParentPosition + "_" + String(Pos);

		Type = TreeSelectionModel.Get(Id);
		If Type <> Undefined Then
			If (TreeType = 1) AND (Mid(Type, 1, 1) = "1") Then
				If (TreeItems.Count() = 1) Then
					Prop = 0;
					TreeItems.Get(0).Property("Name", Prop);
					If (Prop <> Undefined)
						AND (TreeItems.Get(0)["Name"] = "FakeFieldeItem") Then
						Return;
					EndIf;
				EndIf;
				FillSourcesBeforeExpand(Item.GetID(), Parent,, MainOblect, Query);
			EndIf;
		EndIf;

		If TreeType = 1 Then
			LoadSelectionModelForSources(TreeSelectionModel, Item, Id, Parent,, MainOblect, Query);
		EndIf;
	EndDo;
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Заполнение отдельных таблиц и контролов
&AtServer
Function GetPictureForSource(MainObject, Val TableName, Val IsNestedTableRet = Undefined, Val ParentItemPicture = Undefined)
	Return MainObject.GetPictureForSource(TableName, SourcesImagesCacheAddress, IsNestedTableRet, ParentItemPicture);
EndFunction

&AtServer
Function GetPictureForAvailableField(MainObject, Val Field, Query = Undefined, Val Operator = Undefined)
	Return MainObject.GetPictureForAvailableField(Field, SourcesImagesCacheAddress, Query, Operator);
EndFunction

&AtServerNoContext
Function AddSourceType(Val SourceTypes, 
					   Val Name, 
					   Val Image, 
					   Val HaveNested = False, 
					   Val Equival = "", 
					   Val StartPos = 1, 
					   Val ParentItemPicture = Undefined)
	Var Item;

	Item = New Structure;
	Item.Insert("Name", Name);
	Item.Insert("Image", Image);
	Item.Insert("HaveNested", HaveNested);
	Item.Insert("Equival", Equival);
	Item.Insert("StartPos", StartPos);
	Item.Insert("ParentItemPicture", ParentItemPicture);

	SourceTypes.Add(Item);
EndFunction

&AtServer
Function GetSchemaQuery(Val QuerySchema, Val CurrentQuerySchemaSelectQuery, Val NestedQueryPositionAddress)
	Var MainObject;

	MainObject = FormAttributeToValue("Object");
	Return MainObject.GetSchemaQuery(QuerySchema, CurrentQuerySchemaSelectQuery, NestedQueryPositionAddress);
EndFunction

&AtServer
Procedure FillSourcesByIndex(MainObject, ItemsTree, DataSource, Indexes = Undefined, 
							 AvailableTables = Undefined, EnableSort = True, ShowTablesForChange = True)
	MainObject.FillSourcesByIndex(ItemsTree, DataSource, SourcesImagesCacheAddress, ExpressionsImagesCacheAddress, 
								  Indexes, AvailableTables, EnableSort, ShowTablesForChange);
EndProcedure

&AtClient
Function IsFakeItem(Val Item) Export
	Var ItemItems;

	ItemItems = Item.GetItems();
	If (ItemItems.Count() = 1)
		AND (ItemItems.Get(0)["Name"] = "FakeFieldeItem") Then
	    Return True;
	Else
		Return False;
	EndIf;
EndFunction

&AtServer
Procedure qSort(Val Collection, Val Field, Val low = Undefined, Val high = Undefined, MainObject = Undefined)
	Var MainObjectT;

	If MainObject = Undefined Then
		MainObjectT = FormAttributeToValue("Object");
		MainObjectT.qSort(Collection, Field, low, high);
	Else
		MainObject.qSort(Collection, Field, low, high);
	EndIf;
EndProcedure

&AtServerNoContext
Function GetSource(Val DataSource, Val Indexes)
	Var Source;
	Var Pos;

	Source = DataSource;
	For Pos = 0 To Indexes.Count() - 1 Do
		If TypeOf(Source) = Type("QuerySchemaAvailableTables") Then
			Source = Source.Get(Indexes[Pos]);
		ElsIf TypeOf(Source) = Type("QuerySchemaSources") Then
			Source = Source.Get(Indexes[Pos]);
		ElsIf TypeOf(Source) = Type("QuerySchemaSource") Then
			Source = Source.Source.AvailableFields.Get(Indexes[Pos]);
		ElsIf TypeOf(Source) = Type("QuerySchemaAvailableTablesGroup") Then
			Source = Source.Content.Get(Indexes[Pos]);
		ElsIf TypeOf(Source) = Type("QuerySchemaAvailableTable") Then
			Source = Source.Fields.Get(Indexes[Pos]);
		ElsIf TypeOf(Source) = Type("QuerySchemaAvailableNestedTable") Then
			Source = Source.Fields.Get(Indexes[Pos]);
		ElsIf TypeOf(Source) = Type("QuerySchemaAvailableField") Then
			Source = Source.Fields.Get(Indexes[Pos]);
		ElsIf TypeOf(Source) = Type("QuerySchemaAvailableFields") Then
			Source = Source.Get(Indexes[Pos]);
		ElsIf TypeOf(Source) = Type("QuerySchemaTable") Then
			Source = Source.AvailableFields.Get(Indexes[Pos]);
		ElsIf TypeOf(Source) = Type("QuerySchemaNestedQuery") Then
			Source = Source.AvailableFields.Get(Indexes[Pos]);
		ElsIf TypeOf(Source) = Type("QuerySchemaTempTableDescription") Then
			Source = Source.AvailableFields.Get(Indexes[Pos]);
		ElsIf TypeOf(Source) = Type("QuerySchemaColumns") Then
			Source = Source.Get(Indexes[Pos]);
		ElsIf TypeOf(Source) = Type("QuerySchemaNestedTableColumn") Then
			Source = Source.Columns.Get(Indexes[Pos]);
		Else
			Return Undefined;
		EndIf;
	EndDo;
	Return Source;
EndFunction

&AtServerNoContext
Procedure FillQueryBatchTable(Val QueryBatchTable, Val QueryBatch, Val OperatorsNames)
	Var OperatorsTree;
	Var Count;
	Var Pos;
	Var Query;
	Var NewElement;
	Var NewOperatorName;
	Var Operators;
	Var OperatorsCount;
	Var NewOperatorItems;
	Var NewOperatorItem;
	Var OperatorPos;

	// заполняет список запросов из пакета запросов
	QueryBatchTable.Clear();
	Count = QueryBatch.Count();
	OperatorsTree = OperatorsNames.GetItems();
	OperatorsTree.Clear();
	For Pos = 0 To Count-1 Do
		Query = QueryBatch.Get(Pos);
		NewElement = QueryBatchTable.Add();
		If TypeOf(Query) = Type("QuerySchemaSelectQuery") Then
			NewElement["Name"] = Query.Presentation();
			NewElement["Index"] = Pos;
			NewOperatorName = OperatorsTree.Add();
			NewOperatorName["Name"] = NewElement["Name"];
			
			Operators = Query.Operators;
			OperatorsCount = Operators.Count();
			NewOperatorItems = NewOperatorName.GetItems();
			For OperatorPos = 0 To OperatorsCount - 1 Do
				NewOperatorItem = NewOperatorItems.Add();
				NewOperatorItem["Name"] = Operators.Get(OperatorPos).Presentation()
			EndDo;
		ElsIf TypeOf(Query) = Type("QuerySchemaTableDropQuery") Then
			NewElement["Name"] = "- " + Query.TableName;
			NewElement["Index"] = Pos;
			NewOperatorName = OperatorsTree.Add();
			NewOperatorName["Name"] = NewElement["Name"];
		EndIf;
	EndDo;
EndProcedure

&AtServerNoContext
Procedure FillConditions(Val ConditionsTree, Val Conditions)
	Var Count;
	Var Pos;
	Var NewElement;
	Var Expression;

	// заполняем таблицу с условиями
	ConditionsTree.Clear();
	Count = Conditions.Count();
	For Pos = 0 To Count-1 Do
		Expression = Conditions.Get(Pos);
		NewElement = ConditionsTree.Add();
		NewElement["Condition"] = String(Expression);
		NewElement["Prefix"] = "";
	EndDo;
EndProcedure

&AtServer
Procedure FillIndexes(Val IndexFieldsTree, Val FieldMappings, Val IndexesTree, Val Indexes, Val Operators, MainObject, Query)
	Var Count;
	Var Pos;
	Var NewElement;
	Var Ind;
	Var Operator;

	IndexesTree.Clear();
	IndexFieldsTree.Clear();
	Count = Indexes.Count();
	For Pos = 0 To Count-1 Do
		Ind = Indexes.Get(Pos);
		NewElement = IndexesTree.Add();
		NewElement["Index"] = Pos;
		If TypeOf(Ind.Expression) = Type("QuerySchemaColumn")  Then
			NewElement["Name"] = Ind.Expression.Alias;
		Else
			NewElement["Name"] = String(Ind.Expression);
		EndIf;
		NewElement["Picture"] = GetPictureForAvailableField(MainObject, Ind.Expression, Query, Operators.Get(0));
		NewElement["Type"] = 2;
		NewElement["Prefix"] = "";
		NewElement["AliasIndex"] = -1;
	EndDo;

	FillIndexFields(IndexFieldsTree, FieldMappings, IndexesTree, MainObject, Query);

	If Operators.Count() = 1 Then
		Operator = Operators.Get(0);
		NewElement = IndexFieldsTree.Add();
		NewElement["Index"] = -1;
		NewElement["Picture"] = -1;
		NewElement["Type"] = -1;
		NewElement["Presentation"] = NStr("ru = 'Все поля';
											|SYS = 'QueryEditor.AllFields'", "ru");
		FillSourcesByIndex(MainObject, NewElement.GetItems(), Operator.Sources);
	EndIf;
EndProcedure

&AtServer
Procedure FillIndexFields(Val IndexFieldsTree, Val FieldMappings, Val Indexes, MainObject, Query)
	Var Count;
	Var Cache;
	Var Pos;
	Var Alias;
	Var NewElement;

	IndexFieldsTree.Clear();
	Count = FieldMappings.Count();

	Cache = Indexes;
	If (Count > 0)
		AND (TypeOf(Cache) <> Type("Map"))
		AND (Cache <> Undefined) Then
		Cache = MakeCache(Cache, "Name");
	EndIf;

	For Pos = 0 To Count-1 Do
		Alias = FieldMappings.Get(Pos);

		If TypeOf(Alias) = Type("QuerySchemaNestedTableColumn")  Then
			NewElement = IndexFieldsTree.Add();
			NewElement["Picture"] = GetPictureForAvailableField(MainObject, Alias, Query);
			NewElement["Type"] = 3;
			NewElement["Index"] = Pos;
			NewElement["Name"] = "";
			NewElement["Presentation"] = Alias.Alias;
			FillIndexFields(NewElement.GetItems(), Alias.Columns, Cache[Alias.Alias], MainObject, Query);
			If NewElement.GetItems().Count() = 0 Then
				IndexFieldsTree.Delete(IndexFieldsTree.Count() - 1);
			EndIf;
		Else
			If NOT(IsItemInCache(Alias.Alias, Cache)) Then
				NewElement = IndexFieldsTree.Add();
				NewElement["Picture"] = GetPictureForAvailableField(MainObject, Alias, Query);
				NewElement["Type"] = 2;
				NewElement["Index"] = Pos;
				NewElement["Name"] = "";
				NewElement["Presentation"] = Alias.Alias;
			EndIf;
		EndIf;
	EndDo;
EndProcedure

&AtServer
Procedure FillOrder(Val OrderFieldsTree, Val FieldMappings, Val OrderTree, Val Order, Val Operators, MainObject, Query)
	Var Count;
	Var Pos;
	Var Ind;
	Var ParentColumn;
	Var OrderTreeItem;
	Var ParentTree;
	Var NewElement;
	Var Name;
	Var Operator;

	OrderTree.Clear();
	OrderFieldsTree.Clear();
	Count = Order.Count();
	For Pos = 0 To Count-1 Do
		Ind = Order.Get(Pos);
		ParentTree = OrderTree;
		If TypeOf(Ind.Item) = Type("QuerySchemaColumn")  Then
			ParentColumn = GetFieldSchemaColumnParent(Ind.Item, FieldMappings);
			If ParentColumn <> Undefined Then
				ParentTree = Undefined;
				For Each OrderTreeItem In OrderTree Do
					If OrderTreeItem["Name"] = ParentColumn.Alias Then
						ParentTree = OrderTreeItem.GetItems();
						Break;
					EndIf;
				EndDo;

				If ParentTree = Undefined Then
					ParentTree = OrderTree.Add();
					ParentTree["Index"] = -1;
					ParentTree["Name"] = ParentColumn.Alias;
					ParentTree["Picture"] = GetPictureForSource(MainObject, "NestedTable");

					ParentTree = ParentTree.GetItems();
				EndIf;
			EndIf;
			Name = Ind.Item.Alias;
		Else
			Name = String(Ind.Item);
		EndIf;
		NewElement = ParentTree.Add();
		NewElement["Index"] = Pos;
		NewElement["Name"] = Name;
		NewElement["Picture"] = GetPictureForAvailableField(MainObject, Ind.Item, Query, Operators.Get(0));
		NewElement["Type"] = 2;
		NewElement["Prefix"] = "";

		If Ind.Direction = QuerySchemaOrderDirection.Ascending Then
			NewElement["Order"] = NStr("ru = 'Возрастание';
										|SYS = 'QueryEditor.Ascending'", "ru");
		ElsIf Ind.Direction = QuerySchemaOrderDirection.Descending Then
		    NewElement["Order"] = NStr("ru = 'Убывание';
										|SYS = 'QueryEditor.Descending'", "ru");
		ElsIf Ind.Direction = QuerySchemaOrderDirection.HierarchyAscending Then
		    NewElement["Order"] = NStr("ru = 'Возрастание иерархии';
										|SYS = 'QueryEditor.HierarchyAscending'", "ru");
		ElsIf Ind.Direction = QuerySchemaOrderDirection.HierarchyDescending Then
		    NewElement["Order"] = NStr("ru = 'Убывание иерархии';
										|SYS = 'QueryEditor.HierarchyDescending'", "ru");
		EndIf;
	EndDo;

	FillIndexFields(OrderFieldsTree, FieldMappings, OrderTree, MainObject, Query);

	If Operators.Count() = 1 Then
		Operator = Operators.Get(0);
		NewElement = OrderFieldsTree.Add();
		NewElement["Index"] = -1;
		NewElement["Picture"] = -1;
		NewElement["Type"] = -1;
		NewElement["Presentation"] = NStr("ru = 'Все поля';
											|SYS = 'QueryEditor.AllFields'", "ru");
		FillSourcesByIndex(MainObject, NewElement.GetItems(), Operator.Sources);
	EndIf;
EndProcedure

&AtServerNoContext
Function GetFieldSchemaColumnParent(Val SchemaColumn, Val AllColumns)
	Var Column;

	If AllColumns.IndexOf(SchemaColumn) >= 0 Then
		Return Undefined;
	EndIf;

	For Each Column In AllColumns Do
		If TypeOf(Column) = Type("QuerySchemaNestedTableColumn") Then
			If Column.Columns.IndexOf(SchemaColumn) >= 0 Then
				Return Column;
			EndIf;
		EndIf;
	EndDo;
	Return Undefined;
EndFunction

&AtServerNoContext
Function IsItemInCache(Val Name, Val FieldMappings)
	Var Res;

	If TypeOf(FieldMappings) = Type("Map") Then
		Res = FieldMappings.Get(Name);
		If Res <> Undefined Then
			Return True;
		Else
			Return False;
		EndIf;
	EndIf;
	Return False;
EndFunction

&AtServerNoContext
Function FindFieldByIndex(Val BaseFields, Val ParentIndex, Val Index, Val Parent = Undefined)
	Var Count;
	Var Fields;

	Count = BaseFields.Count();
	If (ParentIndex >= 0) AND (ParentIndex >= Count) Then
		Return Undefined;
	EndIf;

	If ParentIndex >= 0 Then
		Fields = BaseFields.Get(ParentIndex).Fields;
	Else
		Fields = BaseFields;
	EndIf;

	Count = Fields.Count();
	If (Index < 0) OR (Index >= Count) Then
		Return Undefined;
	Else
		Parent = Fields;
		Return Fields.Get(Index);
	EndIf;
EndFunction

&AtServer
Procedure FillUnions(Val Operators)
	Var DeletingAttributes;
	Var StrtCol;
	Var Count;
	Var Pos;
	Var Rebuild;
	Var Item;
	Var Path;
	Var DeletingArray;
	Var TypesAttribute;
	Var HeaderName;
	Var TypesForAttribute;
	Var NewAttributeName;
	Var AdditionalyAttribute;
	Var NewAttribute;
	Var NewFormElement;
	Var NewElement;
	Var Operator;

	Unions.Clear();
	DeletingAttributes = GetAttributes("Aliases");
	Count = DeletingAttributes.Count();

	StrtCol = 5;
	// ITK33 +{
	StrtCol = 7;
	// }
	Rebuild = True;
	If (Count - StrtCol) = Operators.Count() Then
		Rebuild = False;
		For Pos = StrtCol To Count - 1 Do
			If DeletingAttributes.Get(Pos).Name <> StrReplace(Operators.Get(Pos - StrtCol).Presentation(), " ", "") Then
				Rebuild = True;
				Break;
			EndIf;
		EndDo;
	EndIf;

	If Rebuild Then
		DeletingArray = New Array;
		For Pos = StrtCol To Count - 1 Do
			Item = DeletingAttributes.Get(Pos);
			// ITK2, 33 +{
			Если СтрНачинаетсяС(Item.Имя, ИТК_ТуллкитКлиентСервер.Префикс()) Тогда
				Продолжить;
			КонецЕсли;
			// }
			Path = Item.Path + "." + Item.Name;
			DeletingArray.Add(Path);

			// ITK33 *{
			//Items.Delete(Items.Aliases.ChildItems.Get(1));
			Items.Delete(Items.Aliases.ChildItems.Get(3));
			// }
		EndDo;
		
		Count = Operators.Count();
		UnionsCount = Count;
		
		AdditionalyAttribute = New Array;
		For Pos = 0 To Count - 1 Do
			TypesAttribute = New Array;
			TypesAttribute.Add(Type("String"));

			HeaderName = Operators.Get(Pos).Presentation();
			NewAttributeName = StrReplace(HeaderName, " ", "");
			TypesForAttribute = New TypeDescription(TypesAttribute);
			NewAttribute = New FormAttribute(NewAttributeName, TypesForAttribute, "Aliases", NewAttributeName, False);
			AdditionalyAttribute.Add(NewAttribute);
		EndDo;
		
		ChangeAttributes(AdditionalyAttribute, DeletingArray);

		For Pos = 0 To Count - 1 Do
			HeaderName = Operators.Get(Pos).Presentation();
			NewAttributeName = StrReplace(HeaderName, " ", "");

			NewFormElement = Items.Add(NewAttributeName, Type("FormField"), Items.Aliases);
			NewFormElement.DataPath = "Aliases." + NewAttributeName;
			NewFormElement.Type = FormFieldType.InputField;
			NewFormElement.DropListButton = True;
			NewFormElement.ListChoiceMode = False;
			NewFormElement.ClearButton = True;
			NewFormElement.ChooseType = True;
			NewFormElement.TextEdit = False;
			NewFormElement.Title = HeaderName;
			ИТК_КонструкторЗапросов.ПриДобавленииКолонкиЗапросаВОбъединения(NewFormElement); // ITK43+

			NewFormElement.SetAction("OnChange", "AliasFieldOnChange");
			NewFormElement.SetAction("Clearing", "AliasFieldOnClearing");
		EndDo;
	EndIf;
	
	Count = Operators.Count();
	For Pos = 0 To Count-1 Do
		Operator = Operators.Get(Pos);
		NewElement = Unions.Add();
		NewElement["Name"] = Operator.Presentation();
		If Operator.UnionType = QuerySchemaUnionType.Union Then
			NewElement["WithoutDuplicates"] = True;
		ElsIf Operator.UnionType = QuerySchemaUnionType.UnionAll Then
			NewElement["WithoutDuplicates"] = False;
		EndIf;
		NewElement["Index"] = Pos;
	EndDo;
EndProcedure

&AtServer
Procedure FillAliases(Val AliasesTree, Val UnionsTable, Val Columns, Query, Val ForNestedTable = False, MainObject)
	Var Count;
	Var Pos;
	Var NewElement;
	Var Prop;
	Var Alias;
	Var UnionsCount;
	Var UnionPos;
	Var FieldsCount;
	Var ItemName;
	Var TmpTable;

	AliasesTree.Clear();
	Count = Columns.Count();
	For Pos = 0 To Count-1 Do
		Alias = Columns.Get(Pos);
		NewElement = AliasesTree.Add();

		Prop = 0;
		NewElement.Property("Picture", Prop);
		If (Prop <> Undefined) Then
			NewElement["Picture"] = GetPictureForAvailableField(MainObject, Alias, Query);
		EndIf;

		NewElement["Name"]  =  Alias.Alias;
		NewElement["Index"] = Pos;

		UnionsCount = UnionsTable.Count();
		FieldsCount = Alias.Fields.Count();
		For UnionPos = 0 To UnionsCount - 1 Do
			ItemName = StrReplace(UnionsTable.Get(UnionPos)["Name"], " ", "");
			If (FieldsCount > (UnionPos - 1)) Then
				If TypeOf(Alias.Fields.Get(UnionPos)) = Type("QuerySchemaExpression")  Then
					If ForNestedTable Then
						TmpTable = GetNameForNastedTableField(Alias.Fields.Get(UnionPos), NewElement.GetParent()[ItemName]);
						NewElement[ItemName] = TmpTable;
					Else
						NewElement[ItemName] = String(Alias.Fields.Get(UnionPos));
					EndIf;
				ElsIf TypeOf(Alias.Fields.Get(UnionPos)) = Type("QuerySchemaNestedTable") Then
					NewElement[ItemName] = Alias.Fields.Get(UnionPos).Name;
				Else
					NewElement[ItemName] = "<" + NStr("ru = 'Отсутствует';
														|SYS = 'QueryEditor.Missing'", "ru") + ">";
				EndIf;
			EndIf;
		EndDo;

		If TypeOf(Alias) = Type("QuerySchemaNestedTableColumn")  Then
			FillAliases(NewElement.GetItems(), UnionsTable, Alias.Columns, Query, True, MainObject);
			NewElement["Type"] = 3;
		Else
			NewElement["Type"] = 2;
		EndIf;
		// ITK2, 33 +{
		ИТК_КонструкторЗапросов.ЗаполнитьДополнительныеПоляПолейОбъединения(NewElement, Alias);
		// }

	EndDo;
EndProcedure

&AtServerNoContext
Procedure GetFieldsDropList(Val FieldsDropList, Query)
	Var Operators;
	Var Count;
	Var Pos;
	Var Operator;
	Var List;

	FieldsDropList.Clear();
	Operators = Query.Operators;
	Count = Operators.Count();
	For Pos = 0 To Count - 1 Do
		List = New Map;
		Operator = Operators.Get(Pos);
		FillFieldsDropList(List, Operator.SelectedFields, Query);
		FieldsDropList.Insert(StrReplace(Operator.Presentation(), " ", ""), List);
	EndDo;
EndProcedure

&AtServerNoContext
Procedure FillFieldsDropList(Val List, Val Fields, Query, Val ParentName = "")
	Var Count;
	Var Pos;
	Var Field;
	Var ChoiceList;
	Var TmpTable;

	ChoiceList = New Array;
	Count = Fields.Count();
	For Pos = 0 To Count - 1 Do
		Field = Fields.Get(Pos);
		If TypeOf(Field) = Type("QuerySchemaNestedTable")  Then
			ChoiceList.Add(Field.Name);
			FillFieldsDropList(List, Field.Fields, Query, Field.Name);
		ElsIf TypeOf(Field) = Type("QuerySchemaExpression")  Then
			If ParentName <> "" Then
				TmpTable = GetNameForNastedTableField(String(Field), ParentName);
				ChoiceList.Add(TmpTable);
			Else
				ChoiceList.Add(String(Field));
			EndIf;
		EndIf;
	EndDo;
	List.Insert(ParentName, ChoiceList);
EndProcedure

&AtServer
Procedure FillGroupings(Val AllFieldsTree, Val GroupingFieldsTree, Val SummingFieldsTree, Query, Val Operator, MainObject)
	Var OperatorGroupingFields;
	Var AllFields;
	Var Count;
	Var CacheGroupingFields;
	Var CacheSummingFields;
	Var Pos;
	Var Expression;
	Var ExpressionString;
	Var NewElement;
	Var Fields;
	Var CountOfExpressions;
	Var Pos1;
	Var Field;
	Var NestedTableString;
	Var InsertedElement;
	Var TmpTable;

	AllFieldsTree.Clear();
	GroupingFieldsTree.Clear();
	SummingFieldsTree.Clear();

	AllFields = Operator.SelectedFields;
	OperatorGroupingFields = Operator.Group;

	FillGroupingField(GroupingFieldsTree, OperatorGroupingFields, Query, Operator, MainObject);
	FillSummingField(SummingFieldsTree, AllFields, Query, Operator, MainObject);

	Count = AllFields.Count();

	CacheGroupingFields = GroupingFieldsTree;
	If (Count > 0)
		AND (TypeOf(CacheGroupingFields) <> Type("Map"))
		AND (CacheGroupingFields <> Undefined) Then
		CacheGroupingFields = MakeCache(CacheGroupingFields, "Name");
	EndIf;

	CacheSummingFields = SummingFieldsTree;
	If (Count > 0)
		AND (TypeOf(CacheSummingFields) <> Type("Map"))
		AND (CacheSummingFields <> Undefined) Then
		CacheSummingFields = MakeCache(CacheSummingFields, "Name", True);
	EndIf;

	For Pos = 0 To Count-1 Do
		Expression = AllFields.Get(Pos);

		If TypeOf(Expression) = Type("QuerySchemaExpression")  Then
			ExpressionString = String(Expression);
			If IsItemInCache(ExpressionString, CacheGroupingFields)
				OR IsItemInCache(ExpressionString, CacheSummingFields)  Then
				Continue;
			EndIf;

			NewElement = AllFieldsTree.Add();
			NewElement["Presentation"] = ExpressionString;
			NewElement["Index"] = Pos;
			NewElement["AvailableField"] = True;
			NewElement["Type"] = 2;
			NewElement["Name"] = ExpressionString;
			NewElement["Picture"] = GetPictureForAvailableField(MainObject, Expression, Query, Operator);
			NewElement["ValueType"] = Expression.ValueType();
		ElsIf TypeOf(Expression) = Type("QuerySchemaNestedTable")  Then
			NestedTableString = Expression.Name;
			NewElement = Undefined;
			Fields = Expression.Fields;
			CountOfExpressions = Fields.Count();
			For Pos1 = 0 To CountOfExpressions-1 Do
				Field = Fields.Get(Pos1);
				ExpressionString = String(Field);

				If IsItemInCache(ExpressionString, CacheGroupingFields)
					OR IsItemInCache(ExpressionString, CacheSummingFields)  Then
					Continue;
				EndIf;

				If NewElement = Undefined Then
				    NewElement = AllFieldsTree.Add();
					NewElement["Presentation"] = NestedTableString;
					NewElement["Index"] = Pos;
					NewElement["AvailableField"] = True;
					NewElement["Type"] = 3;
					NewElement["Name"] = NestedTableString;
					NewElement["Picture"] = GetPictureForAvailableField(MainObject, Expression, Query, Operator);
				EndIf;
				InsertedElement = NewElement.GetItems().Add();
				InsertedElement["Index"] = Pos1;
				InsertedElement["AvailableField"] = True;
				InsertedElement["Type"] = 2;
				InsertedElement["Name"] = ExpressionString;
				InsertedElement["Picture"] = GetPictureForAvailableField(MainObject, Field, Query, Operator);
				InsertedElement["ValueType"] = Field.ValueType();

				TmpTable = GetNameForNastedTableField(Field, InsertedElement.GetParent()["Presentation"]);
				InsertedElement["Presentation"] = TmpTable;
			EndDo;

			If (NewElement <> Undefined) AND (NewElement.GetItems().Count() = 0) Then
				AllFieldsTree.Delete(AllFieldsTree.Count()-1);
			EndIf;
		EndIf;
	EndDo;

 	NewElement = AllFieldsTree.Add();
	NewElement["Index"] = -1;
	NewElement["Type"] = -1;
	NewElement["Presentation"] = NStr("ru = 'Все поля';
										|SYS = 'QueryEditor.AllFields'", "ru");
	NewElement["Picture"] = -1;
	FillSourcesByIndex(MainObject, NewElement.GetItems(), Operator.Sources);
EndProcedure

&AtServerNoContext
Function FindFieldInGroupingAndSummingFields(Val Name, Val GroupingFieldsTree = Undefined, Val SummingFieldsTree = Undefined)
	Var Count;
	Var Pos;
	Var Item;

	If GroupingFieldsTree <> Undefined Then
		Count = GroupingFieldsTree.Count();
		For Pos = 0 To Count-1 Do
			Item = GroupingFieldsTree.Get(Pos);
			If (Item["Name"] = Name) AND (Item["IsUsed"] = False) Then
				Item["IsUsed"] = True;
				Return True;
			EndIf;
			If FindFieldInGroupingAndSummingFields(Name, Item.GetItems()) Then
				Return True;
			EndIf;
		EndDo;
	EndIf;

	If SummingFieldsTree <> Undefined Then
		Count = SummingFieldsTree.Count();
		For Pos = 0 To Count-1 Do
			Item = SummingFieldsTree.Get(Pos);
			If (Item["Name"] = Name) AND (Item["IsUsed"] = False) Then
				Item["IsUsed"] = True;
				Return True;
			EndIf;
			If FindFieldInGroupingAndSummingFields(Name, , Item.GetItems()) Then
				Return True;
			EndIf;
		EndDo;
	EndIf;

	Return False;
EndFunction

&AtServer
Procedure FillGroupingField(Val GroupingFieldTree, Val GroupingField, Query, Val Operator, MainObject)
	Var Count;
	Var Pos;
	Var Field;
	Var NewItem;

	Count = GroupingField.Count();
	For Pos = 0 To Count - 1 Do
		Field = GroupingField.Get(Pos);
		NewItem = GroupingFieldTree.Add();
		NewItem["Presentation"] = String(Field);
		NewItem["Index"] = Pos;
		NewItem["IsUsed"] = False;
		NewItem["Type"] = 2;
		NewItem["Name"] = NewItem["Presentation"];
		NewItem["Picture"] = GetPictureForAvailableField(MainObject, Field, Query, Operator);
	EndDo;
EndProcedure

&AtServer
Procedure FillSummingField(Val SummingFieldTree, Val SummingField, Query, Val Operator, MainObject)
	Var Count;
	Var Pos;
	Var Field;
	Var NewItem;
	Var CountOfExpressions;
	Var Pos1;
	Var NestedField;
	Var InsertedElement;

	Count = SummingField.Count();
	For Pos = 0 To Count - 1 Do
		Field = SummingField.Get(Pos);
		If TypeOf(Field) = Type("QuerySchemaExpression")  Then
			If Field.ContainsAggregateFunction() Then
				NewItem = SummingFieldTree.Add();
				NewItem["Index"] = Pos;
				NewItem["IsUsed"] = False;
				NewItem["Type"] = 2;
				NewItem["Name"] = String(Field);
				NewItem["Picture"] = GetPictureForAvailableField(MainObject, Field, Query, Operator);
			EndIf;
		ElsIf TypeOf(Field) = Type("QuerySchemaNestedTable")  Then
			NewItem = Undefined;

			CountOfExpressions = Field.Fields.Count();
			For Pos1 = 0 To CountOfExpressions-1 Do
				NestedField = Field.Fields.Get(Pos1);
				If NestedField.ContainsAggregateFunction() Then
					If NewItem = Undefined Then
						NewItem = SummingFieldTree.Add();
						NewItem["Index"] = Pos;
						NewItem["IsUsed"] = False;
						NewItem["Type"] = 3;
						NewItem["Name"] = Field.Name;
						NewItem["Picture"] = GetPictureForAvailableField(MainObject, Field, Query, Operator);
					EndIf;
					InsertedElement = NewItem.GetItems().Add();
					InsertedElement["Index"] = Pos1;
					InsertedElement["IsUsed"] = False;
					InsertedElement["Type"] = 2;
					InsertedElement["Name"] = String(NestedField);
					InsertedElement["Picture"] = GetPictureForAvailableField(MainObject, NestedField, Query, Operator);
				EndIf;
			EndDo
		EndIf;
	EndDo;
EndProcedure

&AtServerNoContext
Function GetAgregateExpressions(Val FieldName, Val Replace = False, Val ParentName = "", Val Remove = False)
	Var SubString;
	Var Pos;
	Var NewFieldName;
	Var Expressions;
	Var NewExpression;
	
	If ParentName <> "" Then
		ParentName = ParentName + ".";
	EndIf;

	Expressions = New Array;
	If Replace Then
		// EN
		SubString = "SUM(";
		Pos = Find(FieldName, SubString);
		If Pos = 0 Then
			SubString = "COUNT(DISTINCT ";
			Pos = Find(FieldName, SubString);
		EndIf;
		If Pos = 0 Then
			SubString = "AVG(";
			Pos = Find(FieldName, SubString);
		EndIf;
		If Pos = 0 Then
			SubString = "MIN(";
			Pos = Find(FieldName,SubString);
		EndIf;
		If Pos = 0 Then
			SubString = "MAX(";
			Pos = Find(FieldName, SubString);
		EndIf;
		If Pos = 0 Then
			SubString = "COUNT(";
			Pos = Find(FieldName, SubString);
		EndIf;

		// RU
		If Pos = 0 Then
			SubString = "СУММА(";
			Pos = Find(FieldName, SubString);
		EndIf;
		If Pos = 0 Then
			SubString = "КОЛИЧЕСТВО(РАЗЛИЧНЫЕ ";
			Pos = Find(FieldName, SubString);
		EndIf;
		If Pos = 0 Then
			SubString = "СРЕДНЕЕ(";
			Pos = Find(FieldName, SubString);
		EndIf;
		If Pos = 0 Then
			SubString = "МИНИМУМ(";
			Pos = Find(FieldName,SubString);
		EndIf;
		If Pos = 0 Then
			SubString = "МАКСИМУМ(";
			Pos = Find(FieldName, SubString);
		EndIf;
		If Pos = 0 Then
			SubString = "КОЛИЧЕСТВО(";
			Pos = Find(FieldName, SubString);
		EndIf;

		//
		If Pos = 0 Then
			If Remove Then
				Return FieldName;
			EndIf;

			Replace = False;
		Else
			If Remove Then
				NewExpression = StrReplace(FieldName, SubString, "(" + ParentName);
				// ITK36 + {
				Return NewExpression;
				// }
				Return Mid(NewExpression, Pos, Find(NewExpression, ")") - Pos + 1);
			EndIf;

			NewFieldName = StrReplace(FieldName, SubString, "SUM(" + ParentName);
			Expressions.Add(NewFieldName);
			NewFieldName = StrReplace(FieldName, SubString, "COUNT(DISTINCT " + ParentName);
			Expressions.Add(NewFieldName);
			NewFieldName = StrReplace(FieldName, SubString, "AVG(" + ParentName);
			Expressions.Add(NewFieldName);
			NewFieldName = StrReplace(FieldName, SubString, "MIN(" + ParentName);
			Expressions.Add(NewFieldName);
			NewFieldName = StrReplace(FieldName, SubString, "MAX(" + ParentName);
			Expressions.Add(NewFieldName);
			NewFieldName = StrReplace(FieldName, SubString, "COUNT(" + ParentName);
			Expressions.Add(NewFieldName);
		EndIf;

	EndIf;

	If Replace = False Then
		Expressions.Add("SUM(" + ParentName + FieldName + ")");
		Expressions.Add("COUNT(DISTINCT " + ParentName  + FieldName + ")");
		Expressions.Add("AVG(" + ParentName + FieldName + ")");
		Expressions.Add("MIN(" + ParentName + FieldName + ")");
	    Expressions.Add("MAX(" + ParentName + FieldName + ")");
		Expressions.Add("COUNT(" + ParentName + FieldName + ")");
	EndIf;

	Return Expressions;
EndFunction

&AtServerNoContext
Procedure  RemoveAgregateField(Val ParentIndex, Val Index, Query, Val Operator)
	Var Parent;
	Var Field;
	Var FieldName;

	Parent = Undefined;
	Field = FindFieldByIndex(Operator.SelectedFields, ParentIndex, Index, Parent);
	If Field <> Undefined Then
		FieldName = GetAgregateExpressions(String(Field), True,, True);
		If FieldName <> String(Field) Then
			Try
				ChangeExpressionAtServer(ParentIndex, Index, FieldName, Operator);
			Except
				If Parent <> Undefined Then
					Try	    
						Parent.Delete(Index);
					Except
					EndTry
				EndIf; 
			EndTry;
		Else
			If Parent <> Undefined Then
				Try	    
					Parent.Delete(Index);
				Except
				EndTry
			EndIf;
		EndIf;
	EndIf;
EndProcedure

&AtServerNoContext
Procedure DeleteAllSummingFields(Val SelectedFields, Query, Val Operator, Val ParentIndex = -1)
	Var Field;
	Var N;

	If SelectedFields.Count() Then
		Field = SelectedFields.Get(0);
	Else
		Field = Undefined;
	EndIf;
	// ITK36 * {
	//N = 0;
	//While Field <> Undefined Do
	//	If TypeOf(Field) = Type("QuerySchemaExpression") Then
	//		If Field.ContainsAggregateFunction() Then
	//			RemoveAgregateField(ParentIndex, N, Query, Operator);
	//		Else
	//			N = N + 1;
	//		EndIf;
	//	ElsIf TypeOf(Field) = Type("QuerySchemaNestedTable") Then
	//		DeleteAllSummingFields(Field.Fields, Query, Operator, N);
	//		N = N + 1;
	//	EndIf;
	//	If N >= SelectedFields.Count() Then
	//		Field = Undefined;
	//	Else
	//		Field = SelectedFields.Get(N);
	//	EndIf;
	//EndDo;
	N = 0;
	While Field <> Undefined Do
		If TypeOf(Field) = Type("QuerySchemaExpression") Then
			If Field.ContainsAggregateFunction() Then
				RemoveAgregateField(ParentIndex, N, Query, Operator);
			EndIf;
		ElsIf TypeOf(Field) = Type("QuerySchemaNestedTable") Then
			DeleteAllSummingFields(Field.Fields, Query, Operator, N);
		EndIf;
		
		N = N + 1;
		If N >= SelectedFields.Count() Then
			Field = Undefined;
		Else
			Field = SelectedFields.Get(N);
		EndIf;
		
	EndDo;
	// }
EndProcedure

&AtServerNoContext
Function ChangeExpressionAtServer(Val ParentIndex, Val Index, Val NewExpression, Val Operator, Val ContainsAggregateFunction = Undefined)
	Var Fields;
	Var Field;
	Var RetStr;

	RetStr = NewExpression;
	If ParentIndex >= 0 Then
		Fields = Operator.SelectedFields.Get(ParentIndex).Fields;
	Else
		Fields = Operator.SelectedFields
	EndIf;
	Field = Fields[Index];

	If TypeOf(Field) = Type("QuerySchemaExpression") Then
		If NewExpression <> String(Field) Then
			Fields.Set(Index, New QuerySchemaExpression(NewExpression));
			RetStr = String(Fields.Get(Index));
		EndIf;
		If ContainsAggregateFunction <> Undefined Then
			ContainsAggregateFunction = Field.ContainsAggregateFunction();
		EndIf
	EndIf;
	Return RetStr;
EndFunction

&AtServerNoContext
Procedure AddExpressionAtServer(Val Expression, Val Operator)
	Operator.SelectedFields.Add(Expression);
EndProcedure

&AtServerNoContext
Procedure AddFieldAtServer(Val Expression, Val Operator)
	Operator.SelectedFields.Add(Expression);
EndProcedure

&AtServer
Procedure FillSourcesJoins(Val SourceJoinsTree, Val SchemSources, MainObject)
	Var JoinsRoot;
	Var Count;
	Var Pos;
	Var SchemSource;
	Var Array;
	Var Alias;
	Var P;
	Var ArrayItem;
	Var Picture;
	Var JoinsCount;
	Var Pos1;
	Var Join;
	Var ErrorMess;
	Var JoinType;
	Var Condition;
	Var JoinTypePicture;

	If SourceJoinsTree.Count() > 0 Then
		JoinsRoot = SourceJoinsTree.Get(0);
		JoinsRoot.GetItems().Clear();
	Else
		JoinsRoot = SourceJoinsTree.Add();

		JoinsRoot["Table"] = NStr("ru = 'Таблицы';
									|SYS = 'QueryEditor.Tables'", "ru");
		JoinsRoot["Type"] = 0;
		JoinsRoot["JoinPicture"] = -1;
		JoinsRoot["Picture"] = -1;
	EndIf;

	SourceJoinsTree = JoinsRoot.GetItems();
	Array = New Array;
	Count = SchemSources.Count();
	For Pos = 0 To Count-1 Do
		SchemSource = SchemSources.Get(Pos);
		Alias = SchemSource.Source.Alias;

		Picture = -1;
		If TypeOf(SchemSource.Source) = Type("QuerySchemaTable") Then
			Picture = GetPictureForSource(MainObject, SchemSource.Source.TableName);
		ElsIf TypeOf(SchemSource.Source) = Type("QuerySchemaNestedQuery") Then
			Picture = GetPictureForSource(MainObject, "NestedQuery");
		ElsIf TypeOf(SchemSource.Source) = Type("QuerySchemaTempTableDescription") Then
			Picture = GetPictureForSource(MainObject, "TempTable");
		EndIf;

		JoinsCount = SchemSource.Joins.Count();
		P = FindItemInJoinsArray(Array, "", Alias, True);
		If P = -1 Then
			ArrayItem = New Structure("Parent", "");
			ArrayItem.Insert("JoinType", "");
			ArrayItem.Insert("Expression", "");
			ArrayItem.Insert("Child", Alias);
			ArrayItem.Insert("JoinTypePicture", -1);
			ArrayItem.Insert("Picture", Picture);
			Array.Add(ArrayItem);
		EndIf;

		For Pos1 = 0 To JoinsCount - 1 Do
			Try
				Join = SchemSource.Joins.Get(Pos1);
				Condition = Join.Condition;
			Except
				ErrorMess = BriefErrorDescription(ErrorInfo());
				AddErrorMessageAtServerNoContext(ErrorMessages, ErrorMess);
				Condition = ErrorMess;
			EndTry;

			ArrayItem = New Structure("Parent", Alias);
			JoinType = "";
			JoinTypePicture = -1;
			If Join.JoinType = QuerySchemaJoinType.FullOuter Then
				JoinType = NStr("ru = 'Полное';
								|SYS = 'QueryEditor.FullOuter'", "ru");
				JoinTypePicture = 0;
			ElsIf Join.JoinType = QuerySchemaJoinType.Inner Then
				JoinType = NStr("ru = 'Внутреннее';
								|SYS = 'QueryEditor.Inner'", "ru");
				JoinTypePicture = 1;
			ElsIf Join.JoinType = QuerySchemaJoinType.LeftOuter Then
				JoinType = NStr("ru = 'Левое';
								|SYS = 'QueryEditor.LeftOuter'", "ru");
				JoinTypePicture = 2;
			ElsIf Join.JoinType = QuerySchemaJoinType.RightOuter Then
				JoinType = NStr("ru = 'Правое';
								|SYS = 'QueryEditor.RightOuter'", "ru");
				JoinTypePicture = 3;
			EndIf;

			Picture = -1;
			If TypeOf(Join.Source.Source) = Type("QuerySchemaTable") Then
				Picture = GetPictureForSource(MainObject, Join.Source.Source.TableName);
			ElsIf TypeOf(Join.Source.Source) = Type("QuerySchemaNestedQuery") Then
				Picture = GetPictureForSource(MainObject, "NestedQuery");
			ElsIf TypeOf(Join.Source.Source) = Type("QuerySchemaTempTableDescription") Then
				Picture = GetPictureForSource(MainObject, "TempTable");
			EndIf;

			ArrayItem.Insert("JoinType", JoinType);
			ArrayItem.Insert("Expression", String(Condition));
			ArrayItem.Insert("Child", Join.Source.Source.Alias);
			ArrayItem.Insert("JoinTypePicture", JoinTypePicture);
			ArrayItem.Insert("Picture", Picture);

			P = FindItemInJoinsArray(Array, "", Join.Source.Source.Alias, False);
			If P <> -1 Then
				Array.Delete(P);
			EndIf;

			Array.Add(ArrayItem);
		EndDo;
	EndDo;

	SourceJoinsTree.Clear();
	FillJoins(SourceJoinsTree, Array, "");
EndProcedure

&AtServerNoContext
Function FindItemInJoinsArray(Val Array, Val Parent, Val Child, Val JustChild = False)
	Var Count;
	Var Pos;

	Count = Array.Count();
	For Pos = 0 To Count - 1 Do
		If (Array[Pos]["Parent"] = Parent) AND NOT(JustChild) Then
			If 	Child = Array[Pos]["Child"] Then
				Return Pos;
			EndIf;
		ElsIf JustChild Then
			If Child = Array[Pos]["Child"] Then
				Return Pos;
			EndIf;
		EndIf;
	EndDo;
	Return -1;
EndFunction

&AtServerNoContext
Procedure FillJoins(Val SourceJoinsTree, Val Array, Val ParentName)
	Var Count;
	Var Pos;
	Var ChildItemCount;
	Var P;
	Var ChildItem;
	Var NewTable;
	Var NewElement;
	Var JoinElement;
	Var AndText;
	
	Count = Array.Count();
	For Pos = 0 To  Count-1 Do
		If Array[Pos]["Parent"] = ParentName Then
			NewTable = Array[Pos]["Child"];
			ChildItemCount = SourceJoinsTree.Count();
			NewElement = Undefined;
			For P = 0 To  ChildItemCount-1 Do
				ChildItem = SourceJoinsTree.Get(P);
				If ChildItem["Table"] = NewTable Then
					NewElement = ChildItem;
					Break;
				EndIf;
			EndDo;
			If NewElement = Undefined Then
				NewElement = SourceJoinsTree.Add();
			EndIf;

			If ParentName = "" Then
				NewElement["Type"] = 3;
			Else
				NewElement["Type"] = 1;
			EndIf;
			NewElement["Table"] = NewTable;
			NewElement["JoinType"] = Array[Pos]["JoinType"];
			NewElement["Flag"] = False;
			NewElement["JoinPicture"] = Array[Pos]["JoinTypePicture"];
			NewElement["Picture"] = Array[Pos]["Picture"];

			FillJoins(NewElement.GetItems(), Array, NewTable);

			// Добавим выражение
			If ParentName <> "" Then
				ChildItemCount = NewElement.GetItems().Count();
				JoinElement = Undefined;
				For P = 0 To  ChildItemCount-1 Do
					ChildItem = NewElement.GetItems().Get(P);
					If ChildItem["Type"] = 2 Then
						JoinElement = ChildItem;
						Break;
					EndIf;
				EndDo;
				If JoinElement = Undefined Then
					JoinElement = NewElement.GetItems().Add();
				EndIf;
				JoinElement["ExpressionPicture"] = "ПО";
				If JoinElement["Expression"] <> "" Then
					If Metadata.ScriptVariant = Metadata.ObjectProperties.ScriptVariant.English Then
						AndText = "AND ";
					Else
						AndText = "И ";
					EndIf;
					
					JoinElement["Expression"] = JoinElement["Expression"] + Chars.LF + AndText + Array[Pos]["Expression"];
				Else
					JoinElement["Expression"] = Array[Pos]["Expression"];
				EndIf;
				JoinElement["Type"] = 2;
			EndIf;
		EndIf;
	EndDo;
EndProcedure

&AtServer
Procedure FillTotals(Val TotalsFieldsTree, 
					 Val FieldMappings, 
					 Val TotalsTree, 
					 Val Totals, 
					 Val TotalsExpressionsTree, 
					 Val TotalsExpressions,
                     Val Operators,
					 MainObject, 
					 Query)
	Var Count;
	Var Pos;
	Var NewElement;
	Var Total;
	Var FieldsCount;
	Var FieldPos;
	Var Expression;
	Var Operator;

	TotalsTree.Clear();
	Count = Totals.Count();
	For Pos = 0 To Count-1 Do
		Total = Totals.Get(Pos);
		NewElement = TotalsTree.Add();
		NewElement["Type"] = 2;
		NewElement["Index"] = Pos;
		NewElement["Alias"] = Total.ColumnName;
		NewElement["PointType"] = Total.TotalCalculationFieldType;
		NewElement["Interval"] = Total.PeriodAdditionType;
		NewElement["PeriodStart"] = Total.PeriodAdditionBegin;
		NewElement["PeriodEnd"] = Total.PeriodAdditionEnd;
		NewElement["Picture"] = GetPictureForAvailableField(MainObject, Total.Expression, Query, Operators.Get(0));

		If TypeOf(Total.Expression) = Type("QuerySchemaColumn")  Then
			NewElement["Name"] = Total.Expression.Alias;
			FieldsCount = Total.Expression.Fields.Count();
			For FieldPos = 0 To FieldsCount - 1 Do
				If Total.Expression.Fields.Get(FieldPos) <> Undefined Then
					NewElement["ValueType"] = Total.Expression.Fields.Get(FieldPos).ValueType();
					Break;
				EndIf;
			EndDo;
		Else
			NewElement["Name"] = String(Total.Expression);
			NewElement["ValueType"] = Total.Expression.ValueType();
		EndIf;
	EndDo;

	TotalsExpressionsTree.Clear();
	Count = TotalsExpressions.Count();
	For Pos = 0 To Count-1 Do
		Expression = TotalsExpressions.Get(Pos);
		NewElement = TotalsExpressionsTree.Add();
		NewElement["Index"] = Pos;
		NewElement["Name"] = Expression.Field.Alias;
		NewElement["Picture"] = GetPictureForAvailableField(MainObject, Expression.Field, Query, Operators.Get(0));
		NewElement["Expression"] = String(Expression.Expression);
	EndDo;

	FillTotalsFields(TotalsFieldsTree, FieldMappings, TotalsTree, TotalsExpressionsTree, MainObject, Query);

	If Operators.Count() = 1 Then
		Operator = Operators.Get(0);
		NewElement = TotalsFieldsTree.Add();
		NewElement["Index"] = -1;
		NewElement["Picture"] = -1;
		NewElement["Type"] = -1;
		NewElement["Presentation"] = NStr("ru = 'Все поля';
											|SYS = 'QueryEditor.AllFields'", "ru");
		FillSourcesByIndex(MainObject, NewElement.GetItems(), Operator.Sources);
	EndIf;
EndProcedure

&AtServer
Procedure FillTotalsFields(Val TotalsFieldsTree, 
						   Val FieldMappings, 
						   Val Totals, 
						   Val TotalsExpressions, 
						   MainObject, 
						   Query)
	Var Count;
	Var CacheTotals;
	Var CacheTotalsExpressions;
	Var Pos;
	Var Alias;
	Var NewElement;
	Var Fields;
	Var Count1;
	Var Pos1;
	Var Fld;

	TotalsFieldsTree.Clear();
	Count = FieldMappings.Count();

	CacheTotals = Totals;
	If (Count > 0)
		AND (TypeOf(CacheTotals) <> Type("Map"))
		AND (CacheTotals <> Undefined) Then
		CacheTotals = MakeCache(CacheTotals, "Name");
	EndIf;

	CacheTotalsExpressions = TotalsExpressions;
	If (Count > 0)
		AND (TypeOf(CacheTotalsExpressions) <> Type("Map"))
		AND (CacheTotalsExpressions <> Undefined) Then
		CacheTotalsExpressions = MakeCache(CacheTotalsExpressions, "Name");
	EndIf;

	For Pos = 0 To Count-1 Do
		Alias = FieldMappings.Get(Pos);

		If TypeOf(Alias) = Type("QuerySchemaNestedTableColumn")  Then
			NewElement = TotalsFieldsTree.Add();
			NewElement["Picture"] = GetPictureForAvailableField(MainObject, Alias, Query);
			NewElement["Type"] = 3;
			NewElement["Index"] = Pos;
			NewElement["Name"] = Alias.Alias;
			NewElement["Presentation"] = NewElement["Name"];
			NewElement["IsAlias"] = True;
			NewElement["ValueType"] = "";
			FillTotalsFields(NewElement.GetItems(), Alias.Columns, CacheTotals, CacheTotalsExpressions, MainObject, Query);
			If NewElement.GetItems().Count() = 0 Then
				TotalsFieldsTree.Delete(TotalsFieldsTree.Count() - 1);
			EndIf;
		Else
			If (NOT(IsItemInCache(Alias.Alias, CacheTotals))) AND (NOT(IsItemInCache(Alias.Alias, CacheTotalsExpressions))) Then
				NewElement = TotalsFieldsTree.Add();
				NewElement["Picture"] = GetPictureForAvailableField(MainObject, Alias, Query);
				NewElement["Type"] = 2;
				NewElement["Index"] = Pos;
				NewElement["Name"] = Alias.Alias;
				NewElement["Presentation"] = NewElement["Name"];
				NewElement["IsAlias"] = True;

				Fields = Alias.Fields;
				Count1 = Fields.Count();
				For Pos1 = 0 To Count1 - 1 Do
					Fld = Fields.Get(Pos1);
					If (TypeOf(Fld) = Type("QuerySchemaExpression")) Then
						NewElement["ValueType"] = Fld.ValueType();
						Break;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndDo;
EndProcedure

&AtServerNoContext
Procedure FillParameters(Val List, Val QuerySchema)
	Var Parameters;
	Var NewItem;
	Var Parameter;

	List.Clear();
	Parameters = QuerySchema.FindParameters();
	For Each Parameter In Parameters Do
		NewItem = List.Add();
		NewItem["Name"] = "&" + Parameter.Name;
	EndDo;
EndProcedure

&AtServer
Procedure FillExpressions(Val ExpressionsTree, Val Expressions, Query, Val Operator, MainObject)
	Var Count;
	Var Pos;
	Var Expression;
	Var NewElement;
	Var Prop;
	Var CountOfExpressions;
	Var InsertedElement;
	Var Pos1;
	Var TmpTable;

// заполняет список выражений
	Count = Expressions.Count();
	For Pos = 0 To Count-1 Do

		NewElement = ExpressionsTree.Add();
		Expression = Expressions.Get(Pos);

		If TypeOf(Expression) = Type("QuerySchemaExpression")  Then
			NewElement["Presentation"] = String(Expression);
			NewElement["FullFieldPresentation"] = NewElement["Presentation"];
			NewElement["Index"] = Pos;
			NewElement["Type"] = 2;

			Prop = 0;
			NewElement.Property("Picture", Prop);
			If (Prop <> Undefined) Then
				NewElement["Picture"] = GetPictureForAvailableField(MainObject, Expression, Query, Operator);
			EndIf;
		ElsIf TypeOf(Expression) = Type("QuerySchemaNestedTable")  Then

			NewElement["Presentation"] = Expression.Name;
			NewElement["FullFieldPresentation"] = NewElement["Presentation"];
			NewElement["Index"] = Pos;
			NewElement["Type"] = 3;

			Prop = 0;
			NewElement.Property("Picture", Prop);
			If (Prop <> Undefined) Then
				NewElement["Picture"] = GetPictureForAvailableField(MainObject, Expression);
			EndIf;

			CountOfExpressions = Expression.Fields.Count();
			For Pos1 = 0 To CountOfExpressions-1 Do
				InsertedElement = NewElement.GetItems().Add();
				InsertedElement["FullFieldPresentation"] = Expression.Fields.Get(Pos1);
				TmpTable = GetNameForNastedTableField(InsertedElement["FullFieldPresentation"],
                                                       InsertedElement.GetParent()["Presentation"]);
				InsertedElement["Presentation"] = TmpTable;
				InsertedElement["Index"] = Pos1;
				InsertedElement["Type"] = 2;

				Prop = 0;
				InsertedElement.Property("Picture", Prop);
				If (Prop <> Undefined) Then
					InsertedElement["Picture"] = GetPictureForAvailableField(MainObject, Expression.Fields.Get(Pos1), Query, Operator);
				EndIf;
			EndDo
		EndIf;
	EndDo;

EndProcedure

&AtServerNoContext
Function GetNameForNastedTableField(Val Name, Val ParentName)
	Var Pos;
	Var NewName;

	Pos = Find(Name,ParentName);
	If Pos = 0 Then
		Return Name;
	EndIf;
	NewName = Mid(Name, 1, Pos - 1);
	Return NewName + Mid(Name, Pos + StrLen(ParentName) + 1, StrLen(Name));
EndFunction

&AtServer
Procedure FillTablesForChange(Val AllTablesForChangeTree, 
							  Val AllTablesForChange, 
							  Val TablesForChangeTree,
							  Val TablesForChange,
                              MainObject)
	Var Count;
	Var Pos;
	Var Table;
	Var NewElement;
	Var Presentation;
	Var F;

	TablesForChangeTree.Clear();
	Count = TablesForChange.Count();
	For Pos = 0 To Count-1 Do
		Table = TablesForChange.Get(Pos);
		NewElement = TablesForChangeTree.Add();
		NewElement["Name"] = Table.TableName;

		Presentation = NewElement["Name"];
		F = Find(Presentation, ".");
		If F > 0 Then
			Presentation = Mid(Presentation, F+1, StrLen(Presentation));
		EndIf;

		NewElement["Presentation"] = Presentation;
		NewElement["Type"] = 1;
		NewElement["Index"] = Pos;
		If Find(Table.TableName, ".") <> 0 Then
			NewElement["Picture"] = GetPictureForSource(MainObject, Table.TableName);
		Else
			NewElement["Picture"] = GetPictureForSource(MainObject, "TempTable");
		EndIf;
	EndDo;

	FillAllTablesForChange(AllTablesForChangeTree, AllTablesForChange, TablesForChangeTree, MainObject);
EndProcedure

&AtServer
Procedure FillAllTablesForChange(Val AllTablesForChangeTree, Val AllTablesForChange, Val TablesForChangeTree, MainObject)
	Var Count;
	Var Pos;
	Var SchemSource;
	Var TableName;
	Var F;
	Var SourceTableName;
	Var IsNestedTable;
	Var FNew;
	Var TmpTableName;
	Var FLast;
	Var NewElement;
	Var Picture;

	AllTablesForChangeTree.Clear();
	Count = AllTablesForChange.Count();
	For Pos = 0 To Count-1 Do
		SchemSource = AllTablesForChange.Get(Pos);

		If TypeOf(SchemSource.Source) = Type("QuerySchemaTable")  Then
			TableName = SchemSource.Source.TableName;
			SourceTableName = TableName;
			While True Do
				F = Find(TableName, ".");
				If F > 0 Then
					TableName = Mid(TableName, F+1, StrLen(TableName));
				EndIf;

				If (FindItem("Name", SourceTableName, TablesForChangeTree) = Undefined)
					AND (FindItem("Name", SourceTableName, AllTablesForChangeTree) = Undefined) Then

					IsNestedTable = False;
					Picture = GetPictureForSource(MainObject, SourceTableName, IsNestedTable);

					If IsNestedTable Then
						TmpTableName = SourceTableName;

						FNew = 0;
						FLast = FNew;
						FNew = Find(TmpTableName, ".");
						TmpTableName = Mid(TmpTableName, FNew + 1, StrLen(TmpTableName));

						While FNew > 0 Do
							FLast = FLast + FNew;
							FNew = Find(TmpTableName, ".");
							TmpTableName = Mid(TmpTableName, FNew + 1, StrLen(TmpTableName));
						EndDo;

						TableName = Mid(SourceTableName, 0, FLast - 1);
						SourceTableName = TableName;
						Continue;
					EndIf;

					NewElement = AllTablesForChangeTree.Add();
					NewElement["Presentation"] = TableName;
					NewElement["Type"] = 1;
					NewElement["Name"] =  SourceTableName;
					NewElement["Index"] = Pos;
					NewElement["Picture"] = Picture;
				EndIf;
				Break;
			EndDo;
		ElsIf TypeOf(SchemSource.Source) = Type("QuerySchemaTempTableDescription")  Then
			If FindItem("Presentation", SchemSource.Source.Alias, TablesForChangeTree) = Undefined Then
				NewElement = AllTablesForChangeTree.Add();
				NewElement["Presentation"] = SchemSource.Source.Alias;
				NewElement["Type"] = 1;
				NewElement["Name"] =  SchemSource.Source.Alias;
				NewElement["Index"] = Pos;
				NewElement["Picture"] = GetPictureForSource(MainObject, "TempTable");
			EndIf;
		EndIf;
	EndDo;
EndProcedure

&AtServerNoContext
Function FindItem(Val Field, Val Value, Val ItemsTree, Val Hierarchy = False)
	Var Count;
	Var Pos;
	Var Item;
	Var Ret;

	Num = 0;
	Count =  ItemsTree.Count();
	For Pos = 0 To Count-1 Do
		Item =  ItemsTree.Get(Pos);
		If Item[Field] = Value Then
			Return Item;
		EndIf;
		If Hierarchy Then
			Ret = FindItem(Field, Value, Item.GetItems(), True);
			If Ret <> Undefined Then
				Return Ret;
			EndIf;
		EndIf;
	EndDo;
	Return Undefined;
EndFunction

//////////////////////////////////////////////////////////////////////////////////
// Внесение изменений в схему запроса на сервере и на клиенте

// Добавить новый пакет запроса
&AtClient
Procedure AddQueryBatchAtClient()
	Var NewItem;
	Var NewIndex;

	NewIndex = QueryBatch.Get(QueryBatch.Count() - 1)["Index"] + 1;
	NewItem = QueryBatch.Add();
	NewQueryBatchCount = NewQueryBatchCount + 1;
	NewItem["Name"] = "* " + NStr("ru = 'Новый пакет';
									|SYS = 'QueryEditor.NewBatch'", "ru") + " " + NewQueryBatchCount;
	NewItem["Index"] = NewIndex;

	ChangeQueryBatchAtCache(NewIndex, 1);
	SetPageState("QueryBatchPage", True);

	FillPagesAtClient();
EndProcedure

// Добавить копию запроса
&AtClient
Procedure AddQueryBatchCopyAtClient(Val Index)
	Var NewItem;
	Var Count;
	Var Pos;
	Var Item;

	NewItem = QueryBatch.Insert(Index + 1);
	NewQueryBatchCount = NewQueryBatchCount + 1;
	NewItem["Name"] = "* " + NStr("ru = 'Новый пакет';
									|SYS = 'QueryEditor.NewBatch'", "ru") + " " + NewQueryBatchCount;

	Count = QueryBatch.Count();
	For Pos = 0 To Count - 1 Do
	    Item = QueryBatch.Get(Pos);
		Item["Index"] = Pos;
	EndDo;

	ChangeQueryBatchAtCache(Index, 2);
	SetPageState("QueryBatchPage", True);
EndProcedure

// Удалить запрос
&AtClient
Procedure DeleteQueryBatchAtClient(Val Index)
	Var Count;
	Var Pos;
	Var Item;

	QueryBatch.Delete(Index);

	Count = QueryBatch.Count();
	For Pos = 0 To Count - 1 Do
	    Item = QueryBatch.Get(Pos);
		Item["Index"] = Pos;
	EndDo;

	ChangeQueryBatchAtCache(Index, 3);
	SetPageState("QueryBatchPage", True);

	CurrentQuerySchemaOperatorOnChange(Undefined);
EndProcedure

// Переместить запрос
&AtClient
Procedure MoveQueryBatchAtClient(Val Index, NewIndex)
	Var Count;
	Var Pos;
	Var Item;
	Var Ind;

	Ind = Index;
	QueryBatch.Move(Index, NewIndex - Index);

	Count = QueryBatch.Count();
	For Pos = 0 To Count - 1 Do
	    Item = QueryBatch.Get(Pos);
		Item["Index"] = Pos;
	EndDo;

	ChangeQueryBatchAtCache(Ind, 4, NewIndex);
	SetPageState("QueryBatchPage", True);
EndProcedure

&AtClient
Procedure ChangeQueryBatchAtCache(Val Index, Type, NewIndex = Undefined)
	Var Change;
	Var NewItem;

	// Type = 1 - добавить
	// Type = 2 - добавить копированием
	// Type = 3 - удалить
	// Type = 4 - переместить
	// Type = 5 - добавить запрос уничтожения таблицы

	Change = New Structure;
	Change.Insert("Index", Index);
	Change.Insert("Type", Type);

	If (Type = 4) And (NewIndex <> Undefined) Then
		Change.Insert("NewIndex", NewIndex);
	EndIf;
	
	If Type = 5 Then
		Change.Insert("TemporaryTableName", TemporaryTableDefaultName);
	EndIf;

	NewItem = ChangesCache.Add();
	NewItem["ChangeType"] = "ChangeQueryBatch";
	NewItem["Parameters"] = Change;
EndProcedure

&AtServerNoContext
Function AddQueryBatchAtServer(Val QuerySchema)
	Return QuerySchema.QueryBatch.IndexOf(QuerySchema.QueryBatch.Add(Type("QuerySchemaSelectQuery")));
EndFunction

&AtServerNoContext
Function AddQueryBatchDropQueryAtServer(Val QuerySchema, Val TemporaryTableName)
	Var Query;
	Var Count;
	Var Pos;
	Var Item;

	Query = QuerySchema.QueryBatch.Add(Type("QuerySchemaTableDropQuery"));
    Query.TableName = TemporaryTableName;
	
	Count = QuerySchema.QueryBatch.Count();
	For Pos = 0 To Count - 1 Do
	    Item = QuerySchema.QueryBatch.Get(Pos);
		If (TypeOf(Item) = Type("QuerySchemaSelectQuery"))
			AND (Item.PlacementTable <> "") Then
		    Query.TableName = Item.PlacementTable;
		EndIf;
	EndDo;
	Return QuerySchema.QueryBatch.IndexOf(Query);
EndFunction

&AtServerNoContext
Function AddQueryBatchCopyAtServer(Val Index, Val QuerySchema)
	Return QuerySchema.QueryBatch.IndexOf(QuerySchema.QueryBatch.AddCopy(Index));
EndFunction

&AtServerNoContext
Procedure DeleteQueryBatchAtServer(Val Index, Val QuerySchema)
	QuerySchema.QueryBatch.Delete(Index);
EndProcedure

&AtServerNoContext
Procedure MoveQueryBatchAtServer(Val Index, Val NewIndex, Val QuerySchema)
	QuerySchema.QueryBatch.MoveTo(Index, NewIndex);
EndProcedure

&AtServerNoContext
Procedure DeleteIndexAtServer(Val Index, Query)
	Query.Index.Delete(Index);
EndProcedure

&AtServerNoContext
Procedure MoveIndexAtServer(Val Index, Val NewIndex, Query)
	Query.Index.MoveTo(Index, NewIndex);
EndProcedure

&AtServerNoContext
Procedure DeleteAllIndexAtServer(Query)
	Query.Index.Clear();
EndProcedure

&AtServerNoContext
Procedure AddIndexAtServer(Query, Val ParentIndex, Val FieldIndex, Val FieldName, Val Operator)
	Var Field;

	If FieldName = "" Then
		If ParentIndex < 0 Then
			Field = Query.Columns.Get(FieldIndex);
		Else
			Field = Query.Columns.Get(ParentIndex).Columns.Get(FieldIndex);
		EndIf;
	EndIf;

	If Field = Undefined Then
		Query.Index.Add(FieldName);
	Else
		Query.Index.Add(Field);
	EndIf;
EndProcedure

&AtClient
Procedure ChangeIndexAtCache(Val Index, Val Type, Val NewIndex = Undefined, Val ParentIndex = Undefined, Val Name = Undefined)
	Var Change;
	Var NewItem;

	// Type = 1 - добавить
	// Type = 2 - удалить
	// Type = 3 - переместить
	// Type = 4 - Удалить все

	Change = New Structure;
	If (Type <> 4) Then
		Change.Insert("Index", Index);
	EndIf;
	Change.Insert("Type", Type);

	If (Type = 1) Then
		Change.Insert("ParentIndex", ParentIndex);
		Change.Insert("Name", Name);
	EndIf;

	If (Type = 3) And (NewIndex <> Undefined) Then
		Change.Insert("NewIndex", NewIndex);
	EndIf;

	NewItem = ChangesCache.Add();
	NewItem["ChangeType"] = "Index";
	NewItem["Parameters"] = Change;
EndProcedure

&AtServerNoContext
Procedure AddOrderAtServer(Query, Val NewOrderField)
	Query.Order.Add(NewOrderField);
EndProcedure

&AtServerNoContext
Procedure DeleteOrderAtServer(Val Index, Query)
	Query.Order.Delete(Index);
EndProcedure

&AtServerNoContext
Procedure DeleteAllOrderAtServer(Query)
	Query.Order.Clear();
EndProcedure

&AtServerNoContext
Procedure MoveOrderAtServer(Val Index, Val NewIndex, Query)
	Query.Order.MoveTo(Index, NewIndex);
EndProcedure

&AtServerNoContext
Procedure SetOrderTypeAtServer(Val Index, Val OrderType, Query)
	Var OrderItem;

	OrderItem = Query.Order.Get(Index);
	If OrderItem = Undefined Then
		Return;
	EndIf;

	If OrderType = "Ascending" Then
		OrderItem.Direction = QuerySchemaOrderDirection.Ascending;
	EndIf;
	If OrderType = "Descending" Then
		OrderItem.Direction =  QuerySchemaOrderDirection.Descending;
	EndIf;
	If OrderType = "HierarchyAscending" Then
		OrderItem.Direction = QuerySchemaOrderDirection.HierarchyAscending;
	EndIf;
	If OrderType = "HierarchyDescending" Then
		OrderItem.Direction = QuerySchemaOrderDirection.HierarchyDescending;
	EndIf;

EndProcedure

&AtClient
Procedure ChangeOrderAtCache(Val Index, 
							 Val Type, 
							 Val NewIndex = Undefined, 
							 Val Indexes = Undefined, 
							 Val AddType = Undefined, 
							 Val OrderType = Undefined)
	Var Change;
	Var NewItem;

	// Type = 1 - добавить
	// Type = 2 - удалить
	// Type = 3 - переместить
	// Type = 4 - Удалить все
	// Type = 5 - Установить направление порядка

	Change = New Structure;
	If (Type <> 4) Then
		Change.Insert("Index", Index);
	EndIf;
	Change.Insert("Type", Type);

	If (Type = 1) Then
		//AddType = 1 - выражение
		//AddType = 2- алиас
		Change.Insert("Indexes", Indexes);
		Change.Insert("AddType", AddType);
	EndIf;

	If (Type = 3) And (NewIndex <> Undefined) Then
		Change.Insert("NewIndex", NewIndex);
	EndIf;

	If (Type = 5) And (OrderType <> Undefined) Then
		Change.Insert("OrderType", OrderType);
	EndIf;

	NewItem = ChangesCache.Add();
	NewItem["ChangeType"] = "Order";
	NewItem["Parameters"] = Change;
EndProcedure

&AtClient
Procedure ChangeAutoorderAtCache(Val Autoorder)
	Var Change;
	Var NewItem;

	Change = New Structure;
	Change.Insert("Autoorder", Autoorder);

	NewItem = ChangesCache.Add();
	NewItem["ChangeType"] = "Autoorder";
	NewItem["Parameters"] = Change;
EndProcedure

&AtServerNoContext
Function UnionAddAtServer(Val Operators, Val Index = Undefined)
	If (Index = Undefined) OR (Index < 0) OR (Index >= Operators.Count()) Then // добавить новый запрос
		Return Operators.IndexOf(Operators.Add());
	ElsIf Index >= 0 Then // добавить запрос копированием
		Return Operators.IndexOf(Operators.Add(Operators.Get(Index)));
	EndIf;
EndFunction

&AtServerNoContext
Procedure UnionDeleteAtServer(Val Operators, Val Index)
	Operators.Delete(Index);
EndProcedure

&AtServerNoContext
Procedure UnionMoveAtServer(Val Operators, Val Index, Val NewIndex)
	Operators.MoveTo(Index, NewIndex);
EndProcedure

&AtServerNoContext
Procedure UnionSetWithoutDuplicatesAtServer(Val Operators, Val Index, Val WithoutDuplicates);
	If WithoutDuplicates Then
		Operators.Get(Index).UnionType = QuerySchemaUnionType.Union;
	Else
		Operators.Get(Index).UnionType = QuerySchemaUnionType.UnionAll;
	EndIf;
EndProcedure

&AtClient
Procedure ChangeUnionAtCache(Val Type, Val Index, Val NewIndex = Undefined, Val WithoutDuplicates = Undefined)
	Var Change;
	Var NewItem;

	Change = New Structure;
	Change.Insert("Index", Index);
	Change.Insert("Type", Type);
	Change.Insert("NewIndex", NewIndex);
	Change.Insert("WithoutDuplicates", WithoutDuplicates);

	NewItem = ChangesCache.Add();
	NewItem["ChangeType"] = "Unions";
	NewItem["Parameters"] = Change;
EndProcedure

&AtServerNoContext
Procedure AliasDeleteAtServer(Val ParentIndex, Val Index, Query)
	Var Aliases;

	If ParentIndex < 0 Then
		Aliases = Query.Columns;
	Else
		If TypeOf(Query.Columns.Get(ParentIndex)) = Type("QuerySchemaNestedTableColumn") Then
			Aliases = Query.Columns.Get(ParentIndex).Columns;
		Else
			Return;
		EndIf;
	EndIf;
	Aliases.Delete(Index);
EndProcedure

&AtServerNoContext
Procedure AliasMoveAtServer(Val ParentIndex, Val Index, Val NewIndex, Query)
	Var Aliases;

	If ParentIndex < 0 Then
		Aliases = Query.Columns;
	Else
		If TypeOf(Query.Columns.Get(ParentIndex)) = Type("QuerySchemaNestedTableColumn") Then
			Aliases = Query.Columns.Get(ParentIndex).Columns;
		Else
			Return;
		EndIf;
	EndIf;
	Aliases.MoveTo(Index, NewIndex);
EndProcedure

&AtServerNoContext
Procedure AliasRenameAtServer(Val ParentIndex, Val Index, Val Name, Query)
	Var Aliases;
	Var Alias;

	If ParentIndex < 0 Then
		Aliases = Query.Columns;
	Else
		If TypeOf(Query.Columns.Get(ParentIndex)) = Type("QuerySchemaNestedTableColumn") Then
			Aliases = Query.Columns.Get(ParentIndex).Columns;
		Else
			Return;
		EndIf;
	EndIf;
	Alias = Aliases.Get(Index);
	Alias.Alias = Name;
EndProcedure

&AtServerNoContext
Procedure AliasSetFieldAtServer(Val ParentIndex, Val Index, Val QueryPosition, Val FieldPosition, Query)
	Var Alias;
	Var Fields;
	Var Aliases;
	Var NewField;

	NewField = Undefined;
	If ParentIndex < 0 Then
		If Number(FieldPosition) >= 0 Then
			NewField = Query.Operators.Get(QueryPosition).SelectedFields.Get(Number(FieldPosition));
		EndIf;
		Aliases = Query.Columns;
	Else
		If  Number(FieldPosition) >= 0 Then
			Alias = Query.Columns.Get(ParentIndex);
			Fields = Alias.Fields.Get(QueryPosition);
			NewField = Fields.Fields.Get(Number(FieldPosition));
		EndIf;
		Aliases = Query.Columns.Get(ParentIndex).Columns;
	EndIf;
	Alias = Aliases.Get(Index);
	Fields = Alias.Fields;
	If (QueryPosition >= Fields.Count()) OR (QueryPosition < 0) Then
		Return;
	EndIf;

	Fields[QueryPosition] = NewField;
EndProcedure

&AtClient
Procedure ChangeAliasAtCache(Val Type, Val ParentIndex, Val Index, Val NewIndex = Undefined, Val Name = Undefined)
	Var Change;
	Var NewItem;

	Change = New Structure;
	Change.Insert("ParentIndex", ParentIndex);
	Change.Insert("Index", Index);
	Change.Insert("Type", Type);
	Change.Insert("NewIndex", NewIndex);
	Change.Insert("Name", Name);

	NewItem = ChangesCache.Add();
	NewItem["ChangeType"] = "Aliases";
	NewItem["Parameters"] = Change;
EndProcedure

&AtClient
Procedure ChangeAliasFieldAtCache(Val ParentIndex, Val Index, Val QueryPosition, Val FieldPosition)
	Var Change;
	Var NewItem;

	Change = New Structure;
	Change.Insert("Type", 4);
	Change.Insert("ParentIndex", ParentIndex);
	Change.Insert("Index", Index);
	Change.Insert("QueryPosition", QueryPosition);
	Change.Insert("FieldPosition", FieldPosition);

	NewItem = ChangesCache.Add();
	NewItem["ChangeType"] = "Aliases";
	NewItem["Parameters"] = Change;
EndProcedure

&AtClient
Procedure ChangeGroupAtCache(Val Index, Val Type, Val Name = Undefined, Val ParentIndex = Undefined)
	Var Change;
	Var NewItem;

	// Type = 1 - добавить
	// Type = 4 - добавлять и игнорировать исключения
	// Type = 2 - удалить
	// Type = 3 - удалить все
	// Type = 5 - добавить из агрегатных полей

	Change = New Structure;
	Change.Insert("Index", Index);
	Change.Insert("Type", Type);
	Change.Insert("Name", Name);
	Change.Insert("ParentIndex", ParentIndex);

	NewItem = ChangesCache.Add();
	NewItem["ChangeType"] = "Group";
	NewItem["Parameters"] = Change;
EndProcedure

&AtClient
Procedure ChangeSummAtCache(Val Type, Val ParentIndex = Undefined, Val Index = Undefined, Val Name = Undefined)
	Var Change;
	Var NewItem;

	// Type = 1 - добавить
	// Type = 4 - изменить
	// Type = 5 - изменить на агрегатное поле
	// Type = 6 - изменить на агрегатное поле и игнорировать исключения
	// Type = 2 - удалить
	// Type = 3 - удалить все агргатные поля
	// Type = 7 - добавить поле из группировки

	Change = New Structure;
	Change.Insert("ParentIndex", ParentIndex);
	Change.Insert("Index", Index);
	Change.Insert("Type", Type);
	Change.Insert("Name", Name);

	NewItem = ChangesCache.Add();
	NewItem["ChangeType"] = "Summ";
	NewItem["Parameters"] = Change;
EndProcedure

&AtServerNoContext
Procedure AddJoin(Val ParentTable, Val ChildTable, Val Expression, Val Operator)
	Var Source;
	Var JoinPos;
	Var JoinsCount;
	Var Removed;
	Var ChildSource;
	Var ParentSource;
	Var ParentOfChildSource;
	Var OldJoins;
	
	// найдем QuerySchemaSource с соответствующими алиасами
	For Each Source In Operator.Sources Do
		If Source.Source.Alias = ChildTable  Then
			ChildSource = Source;
		EndIf;
		
		If Source.Source.Alias = ParentTable  Then
			ParentSource = Source;	
		EndIf;
	EndDo;
	
	If ParentSource = Undefined Then
		Return;	
	EndIf; 
	
	// может быть уже есть связь от ChildTable к ParentTable
	If IsHaveWayToSource(ChildTable, ParentTable, Operator) Then
		ParentOfChildSource = FindParent(ChildTable, Operator); 		
		
		If ParentOfChildSource <> Undefined Then
			OldJoins = New Array;
			For Each Join In ChildSource.Joins Do
				OldJoins.Add(Join.Source.Source.Alias);    							
			EndDo;
			ChildSource.Joins.Clear();

			For Each Join In OldJoins Do
				ParentOfChildSource.Joins.Add(Join); 							
			EndDo;
		Else
			ChildSource.Joins.Clear();
		EndIf; 
	EndIf;
	
	// удалим существующие сязи с дочерним источником
	Removed = False;
	For Each Source In Operator.Sources Do
		JoinsCount = Source.Joins.Count();
		JoinPos = 0;
		While JoinPos <  JoinsCount Do
			Join = Source.Joins.Get(JoinPos);
			If Join.Source.Source.Alias = ChildTable Then
				Source.Joins.Delete(JoinPos);    
				JoinsCount = JoinsCount - 1;
				Removed = True;
			EndIf; 	
			JoinPos = JoinPos + 1;
		EndDo; 
		
		If Removed Then
		    Break;					
		EndIf; 
	EndDo;
	
	// создать новую связь
	ParentSource.Joins.Add(ChildTable, Expression); 
EndProcedure

&AtServerNoContext
Function IsHaveWayToSource(Val ParentTable, Val ChildTable, Val Operator)
	Var Source;
	Var Join;
	
	// проверяет, есть ли ChildTable в связях у ParentTable вниз по иерархии
	For Each Source In  Operator.Sources Do
		If Source.Source.Alias = ParentTable Then
			For Each Join In Source.Joins Do 
				If Join.Source.Source.Alias = ChildTable Then						
					Return True;			
				EndIf; 	
				
				If IsHaveWayToSource(Join.Source.Source.Alias, ChildTable, Operator) Then
					Return True;	
				EndIf; 
			EndDo;	
		EndIf;  
	EndDo;
	
	Return False;	
EndFunction

&AtServerNoContext
Function FindParent(Val TableName, Val Operator)
	Var Source;
	Var Join;
	
	For Each Source In  Operator.Sources Do
		For Each Join In Source.Joins Do 	
			If Join.Source.Source.Alias = TableName Then						
		    	Return Source;			
			EndIf; 	
		EndDo; 
	EndDo;
	
	Return Undefined;
EndFunction

&AtServerNoContext
Procedure SetJoin(Val ParentTable, Val ChildTable, Expression, Val Operator)
	Var Count;
	Var Pos;
	Var Source;
	Var JoinsCount;
	Var Pos1;
	Var Join;

	Count = Operator.Sources.Count();
	For Pos = 0 To  Count - 1 Do
		Source = Operator.Sources.Get(Pos);
		If Source.Source.Alias = ParentTable  Then
			JoinsCount = Source.Joins.Count();
			For Pos1 = 0 To  JoinsCount - 1 Do
				Join = Source.Joins.Get(Pos1);
				If Join.Source.Source.Alias = ChildTable Then
					RemoveJoin(ParentTable, ChildTable, Operator, 1);
					Source.Joins.Get(Pos1).Condition =  New QuerySchemaExpression(Expression);
					Expression = String(Source.Joins.Get(Pos1).Condition);
					Return;
				EndIf;
			EndDo;
		EndIf;
	EndDo;
EndProcedure

&AtServerNoContext
Procedure RemoveJoin(Val ParentTable, Val ChildTable, Val Operator, Val StartPosition = 0)
	Var Count;
	Var Pos;
	Var Source;
	Var JoinsCount;
	Var JoinPos;
	Var Join; 
	
	// оставляет StartPosition соединений с одним и тем же источником
	Count = Operator.Sources.Count();
	For Each Source In Operator.Sources Do
		If Source.Source.Alias = ParentTable  Then
			JoinsCount = Source.Joins.Count();
			JoinPos = 0;
			While JoinPos < JoinsCount Do
				Join = Source.Joins.Get(JoinPos);
				If Join.Source.Source.Alias = ChildTable Then
					If StartPosition = 0 Then
					    Source.Joins.Delete(JoinPos);							
						JoinPos = JoinPos - 1;
						JoinsCount = Source.Joins.Count();
					Else
						StartPosition = StartPosition - 1;	
					EndIf; 		
				EndIf;
				JoinPos = JoinPos + 1;
			EndDo; 			
		EndIf;	
	EndDo; 
EndProcedure

&AtServerNoContext
Procedure SetJoinType(Val ParentName, Val ChildName, Val JoinType, Val Operator)
	Var Count;
	Var Pos;
	Var Source;
	Var Count1;
	Var Pos1;
	Var Join;

	Count = Operator.Sources.Count();
	For Pos = 0 To  Count - 1 Do
		Source = Operator.Sources.Get(Pos);
		If Source.Source.Alias = ParentName  Then
			Source = Operator.Sources.Get(Pos);
			Count1 = Source.Joins.Count();
			For Pos1 = 0 To  Count1 - 1 Do
				Join = Source.Joins.Get(Pos1);
				If Join.Source.Source.Alias = ChildName Then
					If JoinType = "Inner" Then
						Join.JoinType = QuerySchemaJoinType.Inner;
					ElsIf JoinType = "LeftOuter" Then
						Join.JoinType = QuerySchemaJoinType.LeftOuter;
					ElsIf JoinType = "RightOuter" Then
						Join.JoinType = QuerySchemaJoinType.RightOuter;
					ElsIf JoinType = "FullOuter" Then
						Join.JoinType = QuerySchemaJoinType.FullOuter;
					EndIf;
				EndIf;
			EndDo;
		EndIf;
	EndDo;
EndProcedure

&AtClient
Procedure ChangeJoinAtCache(Val Type, 
							Val ParentTable, 
							Val ChildTable, 
							Val Expression = Undefined, 
							Val CheckExpression = Undefined, 
                            Val JoinType = Undefined)
	Var Change;
	Var NewItem;

	// Type = 1 - добавить условие
	// Type = 2 - удалить условие
	// Type = 3 - изменить тип
	// Type = 4 - заменить условие

	Change = New Structure;
	Change.Insert("Type", Type);
	Change.Insert("ParentTable", ParentTable);
	Change.Insert("ChildTable", ChildTable);
	Change.Insert("Expression", Expression);
	Change.Insert("CheckExpression", CheckExpression);
	Change.Insert("JoinType", JoinType);

	NewItem = ChangesCache.Add();
	NewItem["ChangeType"] = "Join";
	NewItem["Parameters"] = Change;
EndProcedure

&AtClient
Procedure ChangeTotalsGroupingFieldsAtCache(Val Type, 
											Val Index = Undefined, 
											Val ParentIndex = Undefined, 
											Val FieldName = Undefined,
                                            Val Param = Undefined)
	Var Change;
	Var NewItem;

	// Type = 1 - добавить
	// Type = 2 - удалить
	// Type = 3 - удалить все
	// Type = 4 - переместить
	// Type = 5 - добавить поле по имени
	// Type = 6 - добавить из выражений
	// Type = 7 - тип дополнения
	// Type = 8 - начало перода
	// Type = 9 - конец периода
	// Type = 11 - установить алиас
	// Type = 12 - установить тип

	Change = New Structure;
	Change.Insert("Type", Type);
	Change.Insert("Index", Index);
	Change.Insert("ParentIndex", ParentIndex);
	Change.Insert("FieldName", FieldName);
	Change.Insert("Param", Param);

	NewItem = ChangesCache.Add();
	NewItem["ChangeType"] = "TotalsFields";
	NewItem["Parameters"] = Change;
EndProcedure

&AtClient
Procedure ChangeTotalsExpressionsAtCache(Val Type, 
										 Val Index = Undefined, 
										 Val ParentIndex = Undefined, 
										 Val Expression = Undefined)
	Var Change;
	Var NewItem;

	// Type = 1 - добавить
	// Type = 2 - удалить
	// Type = 3 - удалить все
	// Type = 4 - добавить из группировочных полей
	// Type = 5 - установить выражение

	Change = New Structure;
	Change.Insert("Type", Type);
	Change.Insert("ParentIndex", ParentIndex);
	Change.Insert("Index", Index);
	Change.Insert("Expression", Expression);

	NewItem = ChangesCache.Add();
	NewItem["ChangeType"] = "TotalsExpressions";
	NewItem["Parameters"] = Change;
EndProcedure

&AtClient
Procedure ChangeExpressionAtCache(Val Type, 
								  Val Index = Undefined, 
								  Val ParentIndex = Undefined,
								  Val Expression = Undefined,
								  Val ItemIndexes = Undefined)
	Var Change;
	Var NewItem;

	// Type = 1 - добавить
	// Type = 2 - удалить
	// Type = 3 - удалить все
	// Type = 4 - изменить

	Change = New Structure;
	Change.Insert("Type", Type);
	Change.Insert("ParentIndex", ParentIndex);
	Change.Insert("Index", Index);
	Change.Insert("Expression", Expression);
	Change.Insert("ItemIndexes", ItemIndexes);

	NewItem = ChangesCache.Add();
	NewItem["ChangeType"] = "AvailableFields";
	NewItem["Parameters"] = Change;
EndProcedure

&AtServer
Procedure ChangeExpressionAtCacheAtServer(Val Type, 
										  Val Index = Undefined, 
										  Val ParentIndex = Undefined, 
										  Val Expression = Undefined,
                                          Val ItemIndexes = Undefined)
	Var Change;
	Var NewItem;

	// Type = 1 - добавить
	// Type = 2 - удалить
	// Type = 3 - удалить все
	// Type = 4 - изменить

	Change = New Structure;
	Change.Insert("Type", Type);
	Change.Insert("ParentIndex", ParentIndex);
	Change.Insert("Index", Index);
	Change.Insert("Expression", Expression);
	Change.Insert("ItemIndexes", ItemIndexes);

	NewItem = ChangesCache.Add();
	NewItem["ChangeType"] = "AvailableFields";
	NewItem["Parameters"] = Change;
EndProcedure

&AtClient
Procedure ChangeSourceAtCache(Val Type, Val Name = Undefined, Val Index =  Undefined)
	Var Change;
	Var NewItem;

	// Type = 1 - добавить
	// Type = 2 - удалить
	// Type = 3 - удалить все
	// Type = 4 - переименовать
	// Type = 5 - заменить таблицу

	Change = New Structure;
	Change.Insert("Type", Type);
	Change.Insert("Name", Name);
	Change.Insert("Index", Index);

	NewItem = ChangesCache.Add();
	NewItem["ChangeType"] = "Sources";
	NewItem["Parameters"] = Change;
EndProcedure

&AtClient
Procedure ChangeTablesForChangeAtCache(Val Type, Val Index = Undefined, Val Name = Undefined, Val Param = Undefined)
	Var Change;
	Var NewItem;

	// Type = 1 - добавить
	// Type = 2 - удалить
	// Type = 3 - удалить все

	// Type = 4 - Первые
	// Type = 5 - Без повторяющихся
	// Type = 6 - Разрешенные
	// Type = 7 - Блокировать получаемые данные для последующего изменения
	// Type = 8 - Тип запроса

	Change = New Structure;
	Change.Insert("Type", Type);
	Change.Insert("Index", Index);
	Change.Insert("Name", Name);
	Change.Insert("Param", Param);

	NewItem = ChangesCache.Add();
	NewItem["ChangeType"] = "TablesForChange";
	NewItem["Parameters"] = Change;
EndProcedure

&AtClient
Procedure ChangeOverallAtCache(Val Overall)
	Var Change;
	Var NewItem;

	Change = New Structure;
	Change.Insert("Overall", Overall);

	NewItem = ChangesCache.Add();
	NewItem["ChangeType"] = "Overall";
	NewItem["Parameters"] = Change;
EndProcedure

&AtClient
Procedure ChangeDropTableAtCache(Val TableName)
	Var Change;
	Var NewItem;

	Change = New Structure;
	Change.Insert("TableName", TableName);

	NewItem = ChangesCache.Add();
	NewItem["ChangeType"] = "DropTable";
	NewItem["Parameters"] = Change;
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Команды формы
&AtClient
Procedure AcceptChanges(Command)
	FixChanges();
	FillPagesAtClient();
EndProcedure

&AtClient
Procedure CurrentQueryControlsState(Val CurrentQuerySchemaSelectQueryState, Val CurrentQuerySchemaOperatorState)
	If Items.CurrentQuerySchemaSelectQuery.Visible <> CurrentQuerySchemaSelectQueryState Then
		Items.CurrentQuerySchemaSelectQuery.Visible = CurrentQuerySchemaSelectQueryState;
	EndIf;

	If Items.CurrentQuerySchemaOperator.Visible <> CurrentQuerySchemaOperatorState Then
		Items.CurrentQuerySchemaOperator.Visible = CurrentQuerySchemaOperatorState;
	EndIf;
EndProcedure

&AtClient
Procedure QueryOnCurrentPageChange(Item, CurrentPage)
	Var CurrentPageName;

    CurrentPageName = CurrentPage.Name;
    If CurrentPageName = "QueryBatchPage" Then
    	CurrentQueryControlsState(True, False);
    ElsIf CurrentPageName = "ConditionsPage" Then
    	CurrentQueryControlsState(True, True);
    ElsIf CurrentPageName = "TablesAndFieldsPage" Then
    	CurrentQueryControlsState(True, True);
    ElsIf CurrentPageName = "IndexPage" Then
    	CurrentQueryControlsState(True, False);
    ElsIf CurrentPageName = "OrderPage" Then
    	CurrentQueryControlsState(True, False);
    ElsIf CurrentPageName = "UnionsAliasesPage" Then
    	CurrentQueryControlsState(True, False);
    ElsIf CurrentPageName = "GroupingPage" Then
    	CurrentQueryControlsState(True, True);
    ElsIf CurrentPageName = "JoinsPage" Then
    	CurrentQueryControlsState(True, True);
    ElsIf CurrentPageName = "TotalsPage" Then
    	CurrentQueryControlsState(True, False);
    ElsIf CurrentPageName = "AdditionallyPage" Then
    	CurrentQueryControlsState(True, True);
    ElsIf CurrentPageName = "DropTablePage" Then
    	CurrentQueryControlsState(True, False);
	ElsIf CurrentPageName = "DataCompositionTablesPage" Then
    	CurrentQueryControlsState(True, True);
	ElsIf CurrentPageName = "DataCompositionFieldsPage" Then
    	CurrentQueryControlsState(True, False);
	ElsIf CurrentPageName = "DataCompositionFiltersPage" Then
    	CurrentQueryControlsState(True, True);
	ElsIf CurrentPageName = "DataCompositionCharacteristicsPage" Then
    	CurrentQueryControlsState(True, False);
    EndIf;

	ApplyChangesForOtherTabs();
	LastPage = "";

	FixChanges();
	FillPagesAtClient();
EndProcedure

&AtClient
Procedure ApplyChangesForOtherTabs()
	// если изменились данные на странице, то какие еще нужно обновить страницы?
	If LastPage = "TablesAndFieldsPage" Then
		PagesState["ConditionsPage"] = True;
		PagesState["ConditionsFieldsPage"] = True;
		PagesState["IndexPage"] = True;
		PagesState["OrderPage"] = True;
		PagesState["AutoorderPage"] = True;
		PagesState["UnionsPage"] = True;
		PagesState["AliasesPage"] = True;
		PagesState["GroupingPage"] = True;
		PagesState["JoinsPage"] = True;
		PagesState["TotalsPage"] = True;
		PagesState["SourcesPage"] = True;
		PagesState["AvailableFieldsPage"] = True;
		PagesState["AdditionallyTablesPage"] = True;
		PagesState["AdditionallyItemsPage"] = True;
		PagesState["DataCompositionRequiredJoinsPage"] = True;
		PagesState["DataCompositionFieldsPage"] = True;
		PagesState["DataCompositionFiltersPage"] = True;
		PagesState["CharacteristicsPage"] = True;
	ElsIf LastPage = "GroupingPage" Then
		PagesState["SourcesPage"] = True;
		PagesState["AvailableFieldsPage"] = True;
		PagesState["AliasesPage"] = True;
	ElsIf LastPage = "ConditionsPage" Then
		PagesState["TotalsPage"] = True;
	ElsIf LastPage = "AdditionallyPage" Then
		PagesState["QueryBatchPage"] = True;
	ElsIf LastPage = "UnionsAliasesPage" Then
		PagesState["AvailableFieldsPage"] = True;
		PagesState["ConditionsFieldsPage"] = True;
		PagesState["ConditionsPage"] = True;
		PagesState["IndexPage"] = True;
		PagesState["OrderPage"] = True;
		PagesState["AutoorderPage"] = True;
		PagesState["GroupingPage"] = True;
		PagesState["TotalsPage"] = True;
		PagesState["DataCompositionFieldsPage"] = True;
		PagesState["DataCompositionFiltersPage"] = True;
	ElsIf LastPage = "JoinsPage" Then
		PagesState["DataCompositionRequiredJoinsPage"] = True;
	ElsIf LastPage = "DropTablePage" Then
		PagesState["QueryBatchPage"] = True;
	EndIf;
EndProcedure

&AtClient
Procedure CurrentQuerySchemaOperatorOnChange(Item)
	AvailableTables.GetItems().Clear();
	IsCurrentOperatorChanged = True;
	InvalidateAllPages(True);
	FillPagesAtClient();
EndProcedure

&AtClient
Procedure CurrentQuerySchemaOperatorChoiceProcessing(Item, SelectedValue, StandardProcessing)
	// ITK42 ++
	CurrentQuerySchemaOperatorChoiceProcessingHandler();
	//AttachIdleHandler("CurrentQuerySchemaOperatorChoiceProcessingHandler", 0.01, True);
	// ITK42 --
EndProcedure

&AtClient
Procedure CurrentQuerySchemaOperatorChoiceProcessingHandler()
	FixChanges();
	FillPagesAtClient();
EndProcedure

&AtClient
Procedure CurrentQuerySchemaSelectQueryOnChange(Item)
	FixChanges();
	FillPagesAtClient();

	If TmpNumber <> CurrentQuerySchemaSelectQuery Then
		CurrentQuerySchemaOperator = 0;
		CurrentQuerySchemaOperatorOnChange(Undefined);
	EndIf;
EndProcedure

&AtClient
Procedure CurrentQuerySchemaSelectQueryChoiceProcessing(Item, SelectedValue, StandardProcessing)
	FixChanges();
	FillPagesAtClient();
	TmpNumber = CurrentQuerySchemaSelectQuery;
EndProcedure

&AtClient
Procedure QueryAdd(Command)
	Var Item;

	AddQueryBatchAtClient();

	For Each Item In AvailableTables.GetItems() Do
		Items.AvailableTables.Collapse(Item.GetID());
	EndDo;

	InvalidateAllPages(True);
	FillPagesAtClient();
	SetCurrentTab();
EndProcedure

&AtClient
Procedure QueryAddCopy(Command)
	Var CurrentRow;
	Var CurrentItems;
	Var Item;

	CurrentRow = Items.QueryBatch.CurrentRow;
	If (CurrentRow = Undefined) Then
		Return;
	EndIf;
	CurrentItems = QueryBatch.FindByID(CurrentRow);
	AddQueryBatchCopyAtClient(CurrentItems["Index"]);

	For Each Item In AvailableTables.GetItems() Do
		Items.AvailableTables.Collapse(Item.GetID());
	EndDo;

	InvalidateAllPages(True);
	FillPagesAtClient();
	SetCurrentTab();
EndProcedure

&AtClient
Procedure QueryDelete(Command)
	Var CurrentRow;
	Var Item;
	Var CurrentItems;

	CurrentRow = Items.QueryBatch.CurrentRow;
	If (CurrentRow = Undefined) Then
		Return;
	EndIf;

	For Each Item In AvailableTables.GetItems() Do
		Items.AvailableTables.Collapse(Item.GetID());
	EndDo;

	CurrentItems = QueryBatch.FindByID(CurrentRow);
	DeleteQueryBatchAtClient(CurrentItems["Index"]);
EndProcedure

&AtClient
Procedure QueryMoveUp(Command)
	Var CurrentRow;
	Var CurrentItems;
	Var NewIndex;

	CurrentRow = Items.QueryBatch.CurrentRow;
	If (CurrentRow = Undefined) Then
		Return;
	EndIf;

	CurrentItems = QueryBatch.FindByID(CurrentRow);
	NewIndex = CurrentItems["Index"] - 1;
	If NewIndex < 0 Then
		Return;
	EndIf;

	MoveQueryBatchAtClient(CurrentItems["Index"], NewIndex);
EndProcedure

&AtClient
Procedure QueryMoveDown(Command)
	Var CurrentRow;
	Var CurrentItems;
	Var NewIndex;

	CurrentRow = Items.QueryBatch.CurrentRow;
	If (CurrentRow = Undefined) Then
		Return;
	EndIf;

	CurrentItems = QueryBatch.FindByID(CurrentRow);
	NewIndex = CurrentItems["Index"] + 1;
	If NewIndex >= QueryBatch.Count() Then
		Return;
	EndIf;

	MoveQueryBatchAtClient(CurrentItems["Index"], NewIndex);
EndProcedure

&AtClient
Procedure ConditionsOnStartEdit(Item, NewRow, Clone)
	If NOT(StartEdit) Then
		TmpString = Item.CurrentData["Condition"];
	EndIf;
	StartEdit = True;
EndProcedure

&AtClient
Procedure ConditionsOnEditEnd(Item, NewRow, CancelEdit)
	If TmpString <> Item.CurrentData["Condition"] Then
		Item.CurrentData["Prefix"] = "*";
		SetPageState("ConditionsPage", True);
	EndIf;
EndProcedure

&AtClient
Procedure ConditionsBeforeEditEnd(Item, NewRow, CancelEdit, Cancel)
	Var CurrentRow;
	
	If CancelEdit Then
		Item.CurrentData["Condition"] = TmpString;
	EndIf;

	If NOT(StartEdit) Then
		Return;
	EndIf;
	
	CurrentRow = Items.Conditions.CurrentRow;
	If (CurrentRow = Undefined) Then
		Return;
	EndIf;

	RowForEdit = CurrentRow;
	AttachIdleHandler("ConditionsBeforeEditEndHandler", 0.01, True);
EndProcedure

&AtClient
Procedure ConditionsBeforeEditEndHandler()
	Var CurrentItems;
	
	CurrentItems = Conditions.FindByID(RowForEdit);
	If CurrentItems = Undefined Then
		Return;
	EndIf;
	If NOT(CheckCondition(CurrentItems["Condition"])) Then
		ShowErrorMessage();
		Items.Conditions.CurrentRow = RowForEdit;
		Items.Conditions.ChangeRow();
		StartEdit = True;
		Return;
	EndIf;
	StartEdit = False;
EndProcedure

&AtServer
Function CheckCondition(Condition, ErrorMessage = Undefined)
	Var QuerySchema;
	Var Query;
	Var Operators;
	Var Operator;

	QuerySchema = GetFromTempStorage(QueryWizardAddress);
	If QuerySchema = Undefined Then
		Return True;
	EndIf;

	Batch = QuerySchema.QueryBatch;
	Query = GetSchemaQuery(QuerySchema, CurrentQuerySchemaSelectQuery, NestedQueryPositionAddress);

	If TypeOf(Query) = Type("QuerySchemaSelectQuery") Then
		Operators  = Query.Operators;
		Operator = Operators.Get(CurrentQuerySchemaOperator);
	Else
		Return True;
	EndIf;

	Try
		Operator.Filter.Add(Condition);
		Condition = String(Operator.Filter.Get(Operator.Filter.Count() - 1));
		Operator.Filter.Delete(Operator.Filter.Count() - 1);
	Except
		If ErrorMessage = Undefined Then
			AddErrorMessageAtServer(BriefErrorDescription(ErrorInfo()));
		Else
			ErrorMessage = BriefErrorDescription(ErrorInfo());
		EndIf;
		Return False;
	EndTry;
	Return True;
EndFunction

&AtClient
Procedure ConditionDelete(Command)
	Var CurrentRow;
	Var CurrentItems;

	While Items.Conditions.SelectedRows.Count() > 0 Do
		CurrentRow = Items.Conditions.SelectedRows[0];
		If (CurrentRow = Undefined) Then
			Return;
		EndIf;
		CurrentItems = Conditions.FindByID(CurrentRow);
		Conditions.GetItems().Delete(Conditions.GetItems().IndexOf(CurrentItems));
	EndDo;
	SetPageState("ConditionsPage", True);
EndProcedure

&AtClient
Procedure ConditionDeleteAll(Command)
	Conditions.GetItems().Clear();
	SetPageState("ConditionsPage", True);
EndProcedure

&AtClient
Procedure ConditionCopy(Command)
	Var Rows;
	Var CurrentRow;
	Var CurrentItems;
	Var NewItem;

	Rows = Items.Conditions.SelectedRows;
	For Each CurrentRow In Rows Do
		If (CurrentRow = Undefined) Then
			Return;
		EndIf;
		CurrentItems = Conditions.FindByID(CurrentRow);
		NewItem = Conditions.GetItems().Add();
		NewItem["Condition"] = CurrentItems["Condition"];
		NewItem["Prefix"] = "*";
	EndDo;
	Items.Conditions.CurrentRow = NewItem.GetID();
	SetPageState("ConditionsPage", True);
EndProcedure

&AtClient
Procedure ConditionAdd(Command)
	Var NewItem;

	NewItem = Conditions.GetItems().Add();
	NewItem["Condition"] = "";
	NewItem["Prefix"] = "*";
	Items.Conditions.CurrentRow = NewItem.GetID();
	SetPageState("ConditionsPage", True);
EndProcedure

&AtClient
Procedure ConditionAddFromFields(Command)
	Var Rows;
	Var CurrentRow;
	Var CurrentItems;

	Rows = Items.AllFieldsForConditions.SelectedRows;
	For Each CurrentRow In Rows Do
		If (CurrentRow = Undefined) Then
			Return;
		EndIf;
		CurrentItems = AllFieldsForConditions.FindByID(CurrentRow);

		If CurrentItems["Type"] = 2 Then
			// ITK4 * {
			// AddConditionFromFields(CurrentItems["Name"], CurrentItems["Presentation"]);
			ITKДобавитьПолеУсловия(CurrentItems);
			// }
		EndIf;
	EndDo;
EndProcedure

&AtClient
Procedure ConditionAddAll(Command)
	Var CurrentRow;
	Var CurrentItems;
	Var ConditionItems;

	CurrentRow = Items.AllFieldsForConditions.CurrentRow;
	If (CurrentRow = Undefined) Then
		Return;
	EndIf;
	CurrentItems = AllFieldsForConditions.FindByID(CurrentRow);

	If CurrentItems["Type"] = 2 Then
		ConditionItems = CurrentItems.GetParent();
		If ConditionItems = Undefined Then
			Return;
		EndIf;
	Else
		ConditionItems = CurrentItems;
	EndIf;

	If (ConditionItems.GetItems().Count() = 1)
		AND (ConditionItems.GetItems().Get(0)["Name"] = "FakeFieldeItem") Then
		
		FillConditionsBeforeExpandServer(ConditionItems.GetID());
	EndIf;

	For Each CurrentItems In ConditionItems.GetItems() Do
		If CurrentItems["Type"] = 2 Then
			// ITK4 * {
			// AddConditionFromFields(CurrentItems["Name"], CurrentItems["Presentation"]);
			ITKДобавитьПолеУсловия(CurrentItems);
			// }
		EndIf;
	EndDo;
EndProcedure

&AtServer
Procedure FillConditionsBeforeExpandServer(Row)
	FillSourcesBeforeExpand(Row, AllFieldsForConditions)	
EndProcedure	

&AtClient
Procedure AddConditionFromFields(Val FieldName, Val FieldPresentation)
	Var NewItem;

	NewItem = Conditions.GetItems().Add();
	NewItem["Condition"] = FieldName + " = &" + FieldPresentation;
	// ITK4 + {
	ИТК_КонструкторЗапросовКлиент.ОсновнаяФормаВнутриAddConditionFromFields(NewItem, FieldName, FieldPresentation);
	// }
	NewItem["Prefix"] = "*";
	Items.Conditions.CurrentRow = NewItem.GetID();
	SetPageState("ConditionsPage", True);
EndProcedure

&AtClient
Procedure AllFieldsForConditionsDrdagStart(Item, DragParameters, Perform)
	DragParameters.AllowedActions = DragAllowedActions.Copy;
	DragParameters.Value = "DragFromConditionFields";
EndProcedure

&AtClient
Procedure ConditionsDragCheck(Item, DragParameters, StandardProcessing, Row, Field)
	If DragParameters.Value = "DragFromConditionFields" Then
		StandardProcessing = False;
	EndIf;
EndProcedure

&AtClient
Procedure ConditionsDrag(Item, DragParameters, StandardProcessing, Row, Field)
	Var Rows;
	Var CurrentRow;
	Var CurrentItems;                                   

	StandardProcessing = False;
	Rows = Items.AllFieldsForConditions.SelectedRows;
	For Each CurrentRow In Rows Do
		If (CurrentRow = Undefined) Then
			Return;
		EndIf;
		CurrentItems = AllFieldsForConditions.FindByID(CurrentRow);
		If CurrentItems["Type"] = 2 Then
			// ITK4 * {
			// AddConditionFromFields(Item.CurrentData["Name"], Item.CurrentData["Presentation"]);
			ITKДобавитьПолеУсловия(CurrentItems);
			// }
		EndIf;
	EndDo;
EndProcedure

&AtClient
Procedure IndexDelete(Command)	
	Var CurrentRow;
	Var CurrentItems;
	Var Index;

	While Items.Indexes.SelectedRows.Count() > 0 Do
		CurrentRow = Items.Indexes.SelectedRows[0];
		If (CurrentRow = Undefined) Then
			Return;
		EndIf;
		CurrentItems = Indexes.FindByID(CurrentRow);
		Index = Indexes.GetItems().IndexOf(CurrentItems);
		DeleteIndexAtClient(Index);
	EndDo;

	If Index = Undefined Then
		Return;
	EndIf;

	If Index >= Indexes.GetItems().Count() Then
		Index = Index - 1;
	EndIf;

	If Index >= 0 Then
		Items.Indexes.CurrentRow = Indexes.GetItems().Get(Index).GetID();
	EndIf;

	SetPageState("IndexPage", True);
	FillPagesAtClient();
EndProcedure

&AtClient
Procedure DeleteIndexAtClient(Val Index)
	Var Count;
	Var Pos;

	ChangeIndexAtCache(Index, 2);

	Indexes.GetItems().Delete(Index);

	Count = Indexes.GetItems().Count();
	For Pos = 0 To Count - 1 Do
		Indexes.GetItems().Get(Pos)["Index"] = Pos;
	EndDo;
EndProcedure

&AtClient
Procedure IndexDeleteAll(Command)
	ChangeIndexAtCache(Undefined, 4);
	SetPageState("IndexPage", True);
	FillPagesAtClient();
EndProcedure

&AtClient
Procedure IndexAdd(Command)
	Var Rows;
	Var CurrentRow;
	Var CurrentItems;
	Var FieldIndex;
	Var Parent;
	Var Next;
	Var ParentIndex;
	Var Count;
	Var Pos;
	
	Rows = Items.AllFieldsForIndex.SelectedRows;
	For Each CurrentRow In Rows Do
		If (CurrentRow = Undefined) Then
			Return;
		EndIf;

		CurrentItems = AllFieldsForIndex.FindByID(CurrentRow);
		FieldIndex = CurrentItems["Index"];
		If (FieldIndex < 0) OR (CurrentItems["Type"] <> 2) Then
			Continue;
		EndIf;
		Parent =  CurrentItems.GetParent();
		If Parent = Undefined Then
			ParentIndex = -1;
		Else
		    ParentIndex = Parent["Index"];
		EndIf;

		If Parent <> Undefined Then
			Next = False;
			While (Parent <> Undefined) Do
				If Parent["Type"] = 3 Then
					Next = True;
					Break;
				EndIf;
				Parent = Parent.GetParent();
			EndDo;
			If Next Then
				Continue;
			EndIf;
		EndIf;

		AddIndexAtClient(ParentIndex, FieldIndex, CurrentItems["Name"], CurrentItems["Presentation"],
        CurrentItems["Picture"]);

		If CurrentItems["Name"] = "" Then
			AllFieldsForIndex.GetItems().Delete(AllFieldsForIndex.GetItems().IndexOf(CurrentItems));
		EndIf;

		Count = Indexes.GetItems().Count();
		For Pos = 0 To Count - 1 Do
			Indexes.GetItems().Get(Pos)["Index"] = Pos;
		EndDo;
	EndDo;
	
	// ITK 15 + {
	FillPagesAtClient();
	// }
	
EndProcedure

&AtClient
Procedure AddIndexAtClient(Val ParentIndex, Val Index, Val Name, Val Presentation, Val Picture)
	Var Pr;
	Var Count;
	Var Pos;
	Var NewElement;

	Pr = Name;
	If Pr = "" Then
		Pr = Presentation;
	EndIf;

	Count = Indexes.GetItems().Count();
	For Pos = 0 To Count - 1 Do
		If Indexes.GetItems().Get(Pos)["Name"] = Pr Then
			Return;
		EndIf;
	EndDo;

	NewElement = Indexes.GetItems().Add();

	If Name = "" Then
		NewElement["Name"] = Presentation;
	Else
		NewElement["Name"] = Name;
	EndIf;
	NewElement["Prefix"] = "*";
	NewElement["Type"] = 2;
	NewElement["Picture"] = Picture;

	ChangeIndexAtCache(Index, 1,, ParentIndex, Name);
	SetPageState("IndexPage", True);
EndProcedure

&AtClient
Procedure IndexAddAll(Command)
	Var IndexItems;
	Var Count;
	Var Pos;
	Var Item;
	Var FieldIndex;
	Var P;

	IndexItems = AllFieldsForIndex.GetItems();
	Count = IndexItems.Count();
	For Pos = 0 To Count - 1 Do
		Item = IndexItems.Get(Pos);
		If (Item["Index"] < 0) OR (Item["Type"] < 0) Then
			Break;
		EndIf;
		If Item["Type"] <> 2 Then
			Continue;
		EndIf;

		FieldIndex = Item["Index"];
		AddIndexAtClient(-1, FieldIndex, Item["Name"], Item["Presentation"], Item["Picture"]);
	EndDo;

	P = 0;
	While IndexItems.Count() - P Do
		Item = IndexItems.Get(P);
		If (Item["Index"] < 0) OR (Item["Type"] < 0) Then
			Break;
		EndIf;
		If Item["Type"] <> 2 Then
			P = P + 1;
			Continue;
		EndIf;

		AllFieldsForIndex.GetItems().Delete(AllFieldsForIndex.GetItems().IndexOf(Item));
	EndDo;

	Count = Indexes.GetItems().Count();
	For Pos = 0 To Count - 1 Do
		Indexes.GetItems().Get(Pos)["Index"] = Pos;
	EndDo;
EndProcedure

&AtClient
Procedure IndexMoveUp(Command)
	Var CurrentRow;
	Var CurrentItems;
	Var Count;
	Var Pos;

	CurrentRow = Items.Indexes.CurrentRow;
	If (CurrentRow = Undefined) Then
		Return;
	EndIf;

	CurrentItems = Indexes.FindByID(CurrentRow);

	MoveIndexAtClient(CurrentItems["Index"], CurrentItems["Index"] - 1);

	Count = Indexes.GetItems().Count();
	For Pos = 0 To Count - 1 Do
		Indexes.GetItems().Get(Pos)["Index"] = Pos;
	EndDo;
EndProcedure

&AtClient
Procedure IndexMoveDown(Command)
	Var CurrentRow;
	Var CurrentItems;
	Var Count;
	Var Pos;

	CurrentRow = Items.Indexes.CurrentRow;
	If (CurrentRow = Undefined) Then
		Return;
	EndIf;

	CurrentItems = Indexes.FindByID(CurrentRow);

	MoveIndexAtClient(CurrentItems["Index"], CurrentItems["Index"] + 1);

	Count = Indexes.GetItems().Count();
	For Pos = 0 To Count - 1 Do
		Indexes.GetItems().Get(Pos)["Index"] = Pos;
	EndDo;
EndProcedure

&AtClient
Procedure MoveIndexAtClient(Val Index, Val NewIndex)
	If (NewIndex < 0) OR (Index = NewIndex) OR (NewIndex >= Indexes.GetItems().Count()) Then
		Return;
	EndIf;

	Indexes.GetItems().Get(Index)["Prefix"] = "*";

	Indexes.GetItems().Move(Index, NewIndex - Index);
	ChangeIndexAtCache(Index, 3, NewIndex);
	SetPageState("IndexPage", True);
EndProcedure

&AtClient
Procedure ShowQuery(Command)
	FixChanges();
	FillPagesAtClient();

	ShowQueryEditor(GetQuerySchemaText(QueryWizardAddress));
EndProcedure

&AtClient
Procedure ShowQueryEditor(Val QueryText, OldQueryText = "", Val StartRow = -1, Val StartCol = -1)
	Var Params;
	Var Notification;
	Var Form;

	FixChanges();
	FillPagesAtClient();

	If OldQueryText = "" Then
		OldQueryText = QueryText;
	EndIf;
	Params = New Structure("QueryText", QueryText);
	Params.Insert("OldQueryText", OldQueryText);
	// ITK1 + {
	ИдентификаторВнешнихИсточников = ИТК_КонструкторЗапросовКлиентСервер.ИдентификаторЗначенийВнешнихИсточников();
	Params.Insert(ИдентификаторВнешнихИсточников, ЭтотОбъект.Object[ИдентификаторВнешнихИсточников]);
	// }

	Notification = New NotifyDescription("SetQueryTextAtClient", ThisForm, Params);
	Form = OpenForm("DataProcessor.ИТК_QueryWizard15.Form.QueryEditor", Params, ThisForm,,,,Notification,
                    FormWindowOpeningMode.LockOwnerWindow);
	Form.SetTextSelectionBounds(StartRow, StartCol);
EndProcedure

&AtServer
Function GetQuerySchemaText(Val QueryWizardAddress) Export
	Var QuerySchema;

	QuerySchema = GetFromTempStorage(QueryWizardAddress);
	If QuerySchema = Undefined Then
		Return "";
	EndIf;
	
	If NOT(IsNestedQuery) Then
		Return QuerySchema.GetQueryText();
	Else
		Return GetSchemaQuery(QuerySchema, CurrentQuerySchemaSelectQuery, NestedQueryPositionAddress).GetQueryText();
	EndIf;
	
 EndFunction

&AtServer
Function SetQuerySchemaText(Val QueryText, Val QueryWizardAddress, Val Reset = False, Val CheckToEmpty = False, IsQueyEmpty = Undefined) Export
	Var QuerySchema;
	Var OldQuery;
	Var Query;
	
	If CheckToEmpty Then
		If IsQueryHaveNoOneField(QueryWizardAddress) Then
			IsQueyEmpty = True;
			Return False;
		EndIf;
	EndIf;

	QuerySchema = GetFromTempStorage(QueryWizardAddress);
	If QuerySchema = Undefined Then
		Return False;
	EndIf;

	OldQuery = GetQuerySchemaText(QueryWizardAddress);
	If (OldQuery <> QueryText) OR Reset Then
		Try
			If NOT(IsNestedQuery) Then
				OldQueryText = QuerySchema.GetQueryText();
				QuerySchema.SetQueryText(QueryText);
			Else
				Query = GetSchemaQuery(QuerySchema, CurrentQuerySchemaSelectQuery, NestedQueryPositionAddress);
				OldQueryText = Query.GetQueryText();
				Query.SetQueryText(QueryText);
			EndIf;
			
			PutToTempStorage(QuerySchema, QueryWizardAddress);
			Return True;
		Except
			Raise;
		EndTry;
	Else
		Return False;
	EndIf;
EndFunction

&AtServer
Function GetQueryText(Val QueryWizardAddress, Val CurrentQuerySchemaSelectQuery)
	Var QuerySchema;
	Var Query;

	QuerySchema = GetFromTempStorage(QueryWizardAddress);
	If QuerySchema = Undefined Then
		Return "";
	EndIf;

	Batch = QuerySchema.QueryBatch;
	Query = GetSchemaQuery(QuerySchema, CurrentQuerySchemaSelectQuery, NestedQueryPositionAddress);

	PageItems = 0;
	If TypeOf(Query) = Type("QuerySchemaSelectQuery") Then
		Return Query.GetQueryText();
	EndIf;
	Return "";
EndFunction

&AtClient
Procedure SetQueryText(Val QueryText)
	If QueryText <> "" Then
		SetQuerySchemaText(QueryText, QueryWizardAddress);
		InvalidateAllPages(True);
		FillPagesAtClient();
	EndIf;
EndProcedure

&AtClient
Procedure SetQueryTextAtClient(ChildForm, Params) Export
	Var ErrorText;
	Var StartCol;
	Var StartRow;

	If ChildForm = Undefined Then
		Return;
	EndIf;
	Try
		If SetQuerySchemaText(Params["QueryText"], QueryWizardAddress) Then
			InvalidateAllPages(True);
			FillPagesAtClient();
		EndIf;
		ChildForm.Closing = True;
		ChildForm.Close();
	Except
		ErrorText = BriefErrorDescription(ErrorInfo());
		AddErrorMessage(ErrorText);

		StartRow = -1;
		StartCol = -1;
		GetErrorTextBounds(StartRow, StartCol, ErrorText);

		ChildForm.SetTextSelectionBounds(StartRow, StartCol);
		ChildForm.SetOldQueryText(Params["OldQueryText"]);
		ShowErrorMessage();
	EndTry;
EndProcedure

&AtClient
Procedure AllFieldsForIndexDragStart(Item, DragParameters, Perform)
	DragParameters.AllowedActions = DragAllowedActions.Copy;
	DragParameters.Value = "DragFromIndexFields";
EndProcedure

&AtClient
Procedure IndexesDragCheck(Item, DragParameters, StandardProcessing, Row, Field)
	If DragParameters.Value = "DragFromIndexFields" Then
		StandardProcessing = False;
	EndIf;
	If DragParameters.Value = "DragFromIndexes" Then
		StandardProcessing = False;
	EndIf;
EndProcedure

&AtClient
Procedure IndexesDrag(Item, DragParameters, StandardProcessing, Row, Field)
	Var CurrentRow;
	Var CurrentItems;
	Var Index;
	Var NewIndex;
	Var Count;
	Var Pos;

	StandardProcessing = False;
	If DragParameters.Value = "DragFromIndexFields" Then
		IndexAdd(Undefined);
	EndIf;
	If DragParameters.Value = "DragFromIndexes" Then
		CurrentRow = Items.Indexes.CurrentRow;
		If (CurrentRow = Undefined) OR (Row = Undefined) Then
			Return;
		EndIf;

		CurrentItems = Indexes.FindByID(CurrentRow);
		Index = CurrentItems["Index"];
		NewIndex = Indexes.FindByID(Row)["Index"];
		If (NewIndex < 0) OR (Index = NewIndex) Then
			Return;
		EndIf;
		MoveIndexAtClient(Index, NewIndex);

		Count = Indexes.GetItems().Count();
		For Pos = 0 To Count - 1 Do
			Indexes.GetItems().Get(Pos)["Index"] = Pos;
		EndDo;
	EndIf;
EndProcedure

&AtClient
Procedure IndexesDragStart(Item, DragParameters, Perform)
	DragParameters.AllowedActions = DragAllowedActions.Copy;
	DragParameters.Value = "DragFromIndexes";
EndProcedure

&AtClient
Procedure AllFieldsForIndexDragCheck(Item, DragParameters, StandardProcessing, Row, Field)
	If DragParameters.Value = "DragFromIndexes" Then
		StandardProcessing = False;
	EndIf;
EndProcedure

&AtClient
Procedure AllFieldsForIndexDrag(Item, DragParameters, StandardProcessing, Row, Field)
	StandardProcessing = False;
	IndexDelete(Undefined);
EndProcedure

&AtClient
Procedure OrderAdd(Command)
	Var Rows;
	Var CurrentRow;
	Var CurrentItems;
	Var FieldIndex;
	Var Parent;

	Rows = Items.AllFieldsForOrder.SelectedRows;
	For Each CurrentRow In Rows Do
		If (CurrentRow = Undefined) Then
			Return;
		EndIf;

		CurrentItems = AllFieldsForOrder.FindByID(CurrentRow);
		FieldIndex = CurrentItems["Index"];
		If (FieldIndex < 0) OR (CurrentItems["Type"] <> 2) Then
			Continue;
		EndIf;
		Parent =  CurrentItems.GetParent();
		If Parent = Undefined Then
			ParentIndex = -1;
		Else
		    ParentIndex = Parent["Index"];
		EndIf;

		AddOrderAtClient(CurrentItems);
	EndDo;
	FillPagesAtClient();
EndProcedure

&AtClient
Procedure OrderAddAll(Command)
	Var OrderItems;
	Var Count;
	Var Pos;
	Var Item;

	OrderItems = AllFieldsForOrder.GetItems();
	Count = OrderItems.Count();
	For Pos = 0 To Count - 1 Do
		Item = OrderItems.Get(Pos);
		If (Item["Index"] < 0)  OR (Item["Type"] < 0) Then
			Break;
		EndIf;
		If Item["Type"] <> 2 Then
			Continue;
		EndIf;

		FieldIndex = Item["Index"];
		AddOrderAtClient(Item);
	EndDo;
	FillPagesAtClient();
EndProcedure

&AtClient
Function AddOrderAtClient(CurrentItems)
	Var Name;
	Var Item;
	Var ItemIndexes;
	Var NewElement;
	Var AddType;

	Name = CurrentItems["Name"];
	If Name <> "" Then
		AddType = 1;
	Else
		AddType = 2;
	EndIf;

	Item = CurrentItems;
	ItemIndexes = New Array;
	While (Item <> Undefined) AND (Item["Index"] >= 0) Do
		ItemIndexes.Insert(0, Item["Index"]);
		Item = Item.GetParent();
	EndDo;

	NewElement = Order.GetItems().Add();
	If Name = "" Then
		NewElement["Name"] = CurrentItems["Presentation"];
	Else
		NewElement["Name"] = Name;
	EndIf;

	NewElement["Picture"] = CurrentItems["Picture"];
	NewElement["Prefix"] = "*";
	NewElement["Type"] = 2;
	NewElement["Order"] = NStr("ru = 'Возрастание';
								|SYS = 'QueryEditor.Ascending'", "ru");

	ChangeOrderAtCache(Undefined, 1,, ItemIndexes, AddType);
	SetPageState("OrderPage", True);
	Return True;
EndFunction

&AtClient
Procedure OrderDelete(Command)
	Var CurrentRow;
	Var CurrentItems;
	Var Index;

	While Items.Order.SelectedRows.Count() > 0 Do
		CurrentRow = Items.Order.SelectedRows[0];
		If (CurrentRow = Undefined) Then
			Return;
		EndIf;
		CurrentItems = Order.FindByID(CurrentRow);
		Index = Order.GetItems().IndexOf(CurrentItems);
		ChangeOrderAtCache(Index, 2);
		Order.GetItems().Delete(Index);
	EndDo;

	If Index <> Undefined Then
		SetPageState("OrderPage", True);
		FillPagesAtClient();
	EndIf;
EndProcedure

&AtClient
Procedure OrderDeleteAll(Command)
	ChangeOrderAtCache(Undefined, 4);
	SetPageState("OrderPage", True);
	FillPagesAtClient();
EndProcedure

&AtClient
Procedure OrderMoveUp(Command)
	Var CurrentRow;
	Var CurrentItems;

	CurrentRow = Items.Order.CurrentRow;
	If (CurrentRow = Undefined) Then
		Return;
	EndIf;

	CurrentItems = Order.FindByID(CurrentRow);
	MoveOrderAtClient(CurrentItems["Index"], -1, CurrentItems.GetParent(), CurrentItems);
EndProcedure

&AtClient
Procedure OrderMoveDown(Command)
	Var CurrentRow;
	Var CurrentItems;

	CurrentRow = Items.Order.CurrentRow;
	If (CurrentRow = Undefined) Then
		Return;
	EndIf;

	CurrentItems = Order.FindByID(CurrentRow);
	MoveOrderAtClient(CurrentItems["Index"], 1, CurrentItems.GetParent(), CurrentItems);
EndProcedure

&AtClient
Procedure MoveOrderAtClient(Val Index, MovePos, Parent, Val CurrentItems)
	Var CollectIndex;
	Var NewIndex;

	If Parent = Undefined Then
		Parent = Order;
	EndIf;
	CollectIndex = Parent.GetItems().IndexOf(CurrentItems);

	If ((CollectIndex + MovePos) < 0)
		OR (MovePos = 0)
		OR ((CollectIndex + MovePos) >= Parent.GetItems().Count()) Then
		Return;
	EndIf;

	NewIndex = Parent.GetItems()[CollectIndex + MovePos]["Index"];
	While (NewIndex < 0) OR ((CollectIndex + MovePos) >= Parent.GetItems().Count()) Do
		If MovePos >= 0 Then
			MovePos = MovePos + 1;
		Else
			MovePos = MovePos - 1;
		EndIf;

		If (CollectIndex + MovePos < 0)
			OR ((CollectIndex + MovePos) >= Parent.GetItems().Count()) Then
		    Return;
		EndIf;
		NewIndex = Parent.GetItems()[CollectIndex + MovePos]["Index"];
	EndDo;

	ChangeOrderAtCache(Index, 3, NewIndex);
	Parent.GetItems().Move(CollectIndex, MovePos);
	SetPageState("OrderPage", True);
	FillPagesAtClient();
EndProcedure

&AtClient
Procedure OrderBeforeRowChange(Item, Cancel)
	If Item.CurrentData["Index"] < 0 Then
		Cancel = True;
		Return;
	EndIf;

	If (Item.CurrentItem.Name = "OrderName") OR (Item.CurrentItem.Name = "OrderPicture") Then
		Cancel = True;
	EndIf;
EndProcedure

&AtClient
Procedure AllFieldsForOrderDragStart(Item, DragParameters, Perform)
	DragParameters.AllowedActions = DragAllowedActions.Copy;
	DragParameters.Value = "DragFromOrderFields";
EndProcedure

&AtClient
Procedure AllFieldsForOrderDragCheck(Item, DragParameters, StandardProcessing, Row, Field)
	If DragParameters.Value = "DragFromOrder" Then
		StandardProcessing = False;
	EndIf;
EndProcedure

&AtClient
Procedure AllFieldsForOrderDrag(Item, DragParameters, StandardProcessing, Row, Field)
	StandardProcessing = False;
	OrderDelete(Undefined);
EndProcedure

&AtClient
Procedure OrderDragStart(Item, DragParameters, Perform)
	If Item.CurrentData["Index"] < 0 Then
		DragParameters.AllowedActions = DragAllowedActions.DontProcess;
		Return;
	EndIf;
	DragParameters.AllowedActions = DragAllowedActions.Copy;
	DragParameters.Value = "DragFromOrder";
EndProcedure

&AtClient
Procedure OrderDragCheck(Item, DragParameters, StandardProcessing, Row, Field)
	If DragParameters.Value = "DragFromOrderFields" Then
		StandardProcessing = False;
	EndIf;
	If DragParameters.Value = "DragFromOrder" Then
		StandardProcessing = False;
	EndIf;
EndProcedure

&AtClient
Procedure OrderDrag(Item, DragParameters, StandardProcessing, Row, Field)
	Var CurrentRow;
	Var CurrentItems;
	Var NewItems;
	Var Parent;
	Var Index;
	Var NewIndex;

	StandardProcessing = False;
	If DragParameters.Value = "DragFromOrderFields" Then
		OrderAdd(Undefined);
	EndIf;

	If DragParameters.Value = "DragFromOrder" Then
		CurrentRow = Items.Order.CurrentRow;
		If (CurrentRow = Undefined) OR (Row = Undefined) Then
			Return;
		EndIf;

		CurrentItems = Order.FindByID(CurrentRow);
		NewItems = Order.FindByID(Row);

		Parent = CurrentItems.GetParent();
		If Parent <> NewItems.GetParent() Then
			Return;
		EndIf;

		If Parent = Undefined Then
			Parent = Order;
		EndIf;

		Index = Parent.GetItems().IndexOf(CurrentItems);
		NewIndex = Parent.GetItems().IndexOf(NewItems);

		If (NewIndex < 0) OR (Index = NewIndex) Then
			Return;
		EndIf;
		MoveOrderAtClient(CurrentItems["Index"], NewIndex - Index, CurrentItems.GetParent(), CurrentItems);
	EndIf;
EndProcedure

&AtClient
Procedure AutoorderOnChange(Item)
	ChangeAutoorderAtCache(Autoorder);
	SetPageState("AutoorderPage", True);
EndProcedure

&AtClient
Procedure SetCurrentTab()
	If Items.TablesAndFieldsPage.Visible Then
		Items.Query.CurrentPage = Items.TablesAndFieldsPage;
	Else
		Items.Query.CurrentPage = Items.DropTablePage;
	EndIf;
	QueryOnCurrentPageChange(Undefined, Items.Query.CurrentPage);
EndProcedure

&AtClient
Procedure UnionAdd(Command)
	UnionAddAtClient();

	FillPagesAtClient();
	InvalidateAllPages(True);
	FillPagesAtClient();
	SetCurrentTab();
EndProcedure

&AtClient
Procedure UnionAddCopy(Command)
	Var CurrentRow;
	Var CurrentItems;

	CurrentRow = Items.Unions.CurrentRow;
	If (CurrentRow = Undefined) Then
		Return;
	EndIf;
	CurrentItems = Unions.FindByID(CurrentRow);
	UnionAddAtClient(CurrentItems["Index"]);

	FillPagesAtClient();
	InvalidateAllPages(True);
	FillPagesAtClient();
	SetCurrentTab();
EndProcedure

&AtClient
Procedure UnionDelete(Command)
	Var CurrentRow;
	Var CurrentItems;

	CurrentRow = Items.Unions.CurrentRow;
	If (CurrentRow = Undefined) Then
		Return;
	EndIf;
	CurrentItems = Unions.FindByID(CurrentRow);
	UnionDeleteAtClient(CurrentItems["Index"]);
	CurrentQuerySchemaOperatorOnChange(Undefined);
EndProcedure

&AtClient
Procedure UnionMoveUp(Command)
	Var CurrentRow;
	Var CurrentItems;

	CurrentRow = Items.Unions.CurrentRow;
	If (CurrentRow = Undefined) Then
		Return;
	EndIf;
	CurrentItems = Unions.FindByID(CurrentRow);
	UnionMoveAtClient(CurrentItems["Index"], CurrentItems["Index"] - 1);
	FillPagesAtClient();
EndProcedure

&AtClient
Procedure UnionMoveDown(Command)
	Var CurrentRow;
	Var CurrentItems;

	CurrentRow = Items.Unions.CurrentRow;
	If (CurrentRow = Undefined) Then
		Return;
	EndIf;
	CurrentItems = Unions.FindByID(CurrentRow);
	UnionMoveAtClient(CurrentItems["Index"], CurrentItems["Index"] + 1);
	FillPagesAtClient();
EndProcedure

&AtClient
Procedure UnionAddAtClient(Val Index = Undefined)
	ChangeUnionAtCache(1, Index);
	SetPageState("UnionsPage", True);
	SetPageState("AliasesPage", True);
EndProcedure

&AtClient
Procedure UnionDeleteAtClient(Val Index)
	ChangeUnionAtCache(2, Index);
	SetPageState("UnionsPage", True);
	SetPageState("AliasesPage", True);
EndProcedure

&AtClient
Procedure UnionMoveAtClient(Val Index, Val NewIndex)
	If (NewIndex < 0) OR (Index = NewIndex) OR (NewIndex >= Unions.Count()) Then
		Return;
	EndIf;
	Items.Unions.CurrentRow = Unions.Get(NewIndex).GetID();
	ChangeUnionAtCache(3, Index, NewIndex);
	SetPageState("UnionsPage", True);
	SetPageState("AliasesPage", True);
EndProcedure

&AtClient
Procedure UnionsBeforeRowChange(Item, Cancel)
	If Item.CurrentItem.Name = "UnionsName" Then
		Cancel = True;
	EndIf;
EndProcedure

&AtClient
Procedure UnionsOnEditEnd(Item, NewRow, CancelEdit)
	Var CurrentRow;
	Var CurrentItems;

	If Item.CurrentItem.Name = "UnionsWithoutDuplicates" Then
		CurrentRow = Items.Unions.CurrentRow;
		If (CurrentRow = Undefined) Then
			Return;
		EndIf;
		CurrentItems = Unions.FindByID(CurrentRow);
		ChangeUnionAtCache(4, CurrentItems["Index"],,Item.CurrentData["WithoutDuplicates"]);
		SetPageState("UnionsPage", True);
		SetPageState("AliasesPage", True);
	EndIf;
EndProcedure

&AtClient
Procedure AliasDelete(Command)
	Var CurrentRow;
	Var CurrentItems;
	Var Parent;
	Var ParentIndex;
	Var Index;

	CurrentRow = Items.Aliases.CurrentRow;
	If (CurrentRow = Undefined) Then
		Return;
	EndIf;
	CurrentItems = Aliases.FindByID(CurrentRow);

	Parent = CurrentItems.GetParent();
	ParentIndex = -1;
	If Parent = Undefined Then
		Parent = Aliases;
	Else
		ParentIndex = Parent["Index"];
	EndIf;

	Index = CurrentItems["Index"];
	ChangeAliasAtCache(1, ParentIndex, Index);
	SetPageState("AliasesPage", True);
	FillPagesAtClient();
EndProcedure

&AtClient
Procedure AliasMoveUp(Command)
	Var CurrentRow;
	Var CurrentItems;
	Var Parent;
	Var ParentIndex;
	Var Index;

	CurrentRow = Items.Aliases.CurrentRow;
	If (CurrentRow = Undefined) Then
		Return;
	EndIf;
	CurrentItems = Aliases.FindByID(CurrentRow);

	Parent = CurrentItems.GetParent();
	ParentIndex = -1;
	If Parent = Undefined Then
		Parent = Aliases;
	Else
		ParentIndex = Parent["Index"];
	EndIf;

	Index = CurrentItems["Index"];
	CurrentItems["Prefix"] = "*";
	AliaseMoveAtClient(Parent, ParentIndex, Index, Index - 1);
EndProcedure

&AtClient
Procedure AliasMoveDown(Command)
	Var CurrentRow;
	Var CurrentItems;
	Var Parent;
	Var ParentIndex;
	Var Index;

	CurrentRow = Items.Aliases.CurrentRow;
	If (CurrentRow = Undefined) Then
		Return;
	EndIf;
	CurrentItems = Aliases.FindByID(CurrentRow);

	Parent = CurrentItems.GetParent();
	ParentIndex = -1;
	If Parent = Undefined Then
		Parent = Aliases;
	Else
		ParentIndex = Parent["Index"];
	EndIf;

	Index = CurrentItems["Index"];
	CurrentItems["Prefix"] = "*";
	AliaseMoveAtClient(Parent, ParentIndex, Index, Index + 1);
EndProcedure

&AtClient
Procedure AliaseMoveAtClient(Val Parent, Val ParentIndex, Val Index, Val NewIndex)
	Var Count;
	Var Pos;

	Count = Parent.GetItems().Count();
	If (NewIndex < 0) OR (Index = NewIndex) OR (NewIndex >= Count) Then
		Return;
	EndIf;
	ChangeAliasAtCache(2, ParentIndex, Index, NewIndex);
	Parent.GetItems().Move(Index, NewIndex - Index);

	For Pos = 0 To Count - 1 Do
		Parent.GetItems().Get(Pos)["Index"] = Pos;
	EndDo;

	SetPageState("AliasesPage", True);
	FillPagesAtClient();
EndProcedure

&AtClient
Procedure AliasesDragStart(Item, DragParameters, Perform)
	DragParameters.AllowedActions = DragAllowedActions.Copy;
	DragParameters.Value = "DragFromAliases";
EndProcedure

&AtClient
Procedure AliasesDragCheck(Item, DragParameters, StandardProcessing, Row, Field)
	If DragParameters.Value = "DragFromAliases" Then
		StandardProcessing = False;
	EndIf;
EndProcedure

&AtClient
Procedure AliasesDrag(Item, DragParameters, StandardProcessing, Row, Field)
	Var CurrentRow;
	Var CurrentItems;
	Var Parent;
	Var NewIndex;
	Var Index;
	Var ParentIndex;

	StandardProcessing = False;
	If DragParameters.Value = "DragFromAliases" Then
		CurrentRow = Items.Aliases.CurrentRow;
		If (CurrentRow = Undefined) OR (Row = Undefined) Then
			Return;
		EndIf;

		CurrentRow = Items.Aliases.CurrentRow;
		If (CurrentRow = Undefined) Then
			Return;
		EndIf;
		CurrentItems = Aliases.FindByID(CurrentRow);

		Parent = CurrentItems.GetParent();
		ParentIndex = -1;
		If Parent = Undefined Then
			Parent = Aliases;
		Else
			ParentIndex = Parent["Index"];
		EndIf;

		Index = CurrentItems["Index"];
		NewIndex = Aliases.FindByID(Row)["Index"];
		If (NewIndex < 0)
			OR (Index = NewIndex)
			OR (Aliases.FindByID(Row).GetParent() <> CurrentItems.GetParent()) Then
			Return;
		EndIf;
		CurrentItems["Prefix"] = "*";
		AliaseMoveAtClient(Parent, ParentIndex, Index, NewIndex);
	EndIf;
EndProcedure

&AtClient
Procedure AliasesOnStartEdit(Item, NewRow, Clone)
	Var CurrentRow;
	Var CurrentItems;
	Var Parent;
	Var List;
	Var ParentName;
	Var Pos;

	If (Item.CurrentItem.Name = "AliasesName")
		OR (Item.CurrentItem.Name = "AliasesPicture") Then
		If NOT(StartEdit) Then
			TmpString = Item.CurrentData["Name"];
		EndIf;
		StartEdit = True;
	Else // нужно заполнить выпадающий список
		Item.CurrentItem.ChoiceList.Clear();

		CurrentRow = Items.Aliases.CurrentRow;
		If (CurrentRow = Undefined) Then
			Return;
		EndIf;
		CurrentItems = Aliases.FindByID(CurrentRow);

		Parent = CurrentItems.GetParent();
		ParentName = "";
		If Parent <> Undefined Then
			ParentName = Parent[Item.CurrentItem.Name];
		EndIf;

		List = Undefined;
		FieldsDropList.Property(Item.CurrentItem.Name, List);
		If List <> Undefined Then
			List = List[ParentName];
		EndIf;

		If List = Undefined Then
			Return;
		EndIf;

		// ITK33 + {
		ИТК_КонструкторЗапросовКлиент.ДополнитьСписокВыбораПоляОбъединения(Item, CurrentItems);
		// }
		For Pos = 0 To List.Count() - 1 Do
			Item.CurrentItem.ChoiceList.Add(String(Pos), List.Get(Pos));
		EndDo;
	EndIf;
EndProcedure

&AtClient
Procedure AliasesBeforeEditEnd(Item, NewRow, CancelEdit, Cancel)
	Var CurrentRow;
	Var CurrentItems;

	If StartEdit Then
		CurrentRow = Items.Aliases.CurrentRow;
		If CurrentRow = Undefined Then
			Return;
		EndIf;
		CurrentItems = Aliases.FindByID(CurrentRow);
		If CurrentItems = Undefined Then
			Return;
		EndIf;

		If (Item.CurrentItem.Name = "AliasesName")
			OR (Item.CurrentItem.Name = "AliasesPicture") Then
			If CancelEdit Then
				CurrentItems["Name"] = TmpString;
				StartEdit = False;
				Return;
			EndIf;
			
			RowForEdit = CurrentRow;
			AttachIdleHandler("ChangeTableAliasHandler", 0.01, True);
		EndIf;
	EndIf;
	StartEdit = False;
	LastPage = "UnionsAliasesPage";
EndProcedure

&AtClient
Procedure ChangeTableAliasHandler()
	If NOT(ChangeTableAlias(RowForEdit)) Then
		ShowErrorMessage();
		StartEdit = True;
		Items.Aliases.CurrentRow = RowForEdit;
		Items.Aliases.ChangeRow();
		Return;
	EndIf;
	StartEdit = False;
EndProcedure

&AtServer
Function ChangeTableAlias(Val CurrentRow)
	Var QuerySchema;
	Var Query;
	Var CurrentItems;
	Var Parent;
	Var Index;
	Var ParentIndex;

	If CurrentRow = Undefined Then
		Return True;
	EndIf;
	CurrentItems = Aliases.FindByID(CurrentRow);

	QuerySchema = GetFromTempStorage(QueryWizardAddress);
	If QuerySchema = Undefined Then
		Return True;
	EndIf;

	Batch = QuerySchema.QueryBatch;
	Query = GetSchemaQuery(QuerySchema, CurrentQuerySchemaSelectQuery, NestedQueryPositionAddress);

	If TypeOf(Query) <> Type("QuerySchemaSelectQuery") Then
		Return True;
	EndIf;

	Parent = CurrentItems.GetParent();
	ParentIndex = -1;
	If Parent = Undefined Then
		Parent = Aliases;
	Else
		ParentIndex = Parent["Index"];
	EndIf;

	Index = CurrentItems["Index"];

	Try
		AliasRenameAtServer(ParentIndex, Index, CurrentItems["Name"], Query);
		PutToTempStorage(QuerySchema, QueryWizardAddress);
	Except
		AddErrorMessageAtServer((BriefErrorDescription(ErrorInfo())));
		Return False;
	EndTry;

	Items.Aliases.CurrentRow = Undefined;
	Items.Aliases.CurrentRow = CurrentRow;
	Return True;
EndFunction

&AtClient
Procedure AliasFieldOnChange(Item)
	Var CurrentRow;
	Var Count;
	Var Pos;
	Var QueryPosition;
	Var CurrentItems;
	Var Parent;
	Var ParentIndex;
	Var Index;

	CurrentRow = Items.Aliases.CurrentRow;
	If ((Item.EditText <> "") AND ((CurrentRow = Undefined) OR (TmpString = Item.EditText))) Then
		Return;
	EndIf;
	CurrentItems = Aliases.FindByID(CurrentRow);

	// ITK33 + {
	Если ИТК_КонструкторЗапросовКлиент.ОбработкаЗаполненияПустыхПолейОбъединения(Items.Aliases) Тогда
		
        ПараметрыЗаполнения = ИТК_КонструкторЗапросовКлиент.ПараметрыЗаполненияПустыхПолейОбъединения(Items.Aliases);
		ОбработкаЗаполненияПустыхПолейОбъединения(ПараметрыЗаполнения);
		
		SetPageState("AliasesPage", True);
		Items.Aliases.CurrentRow = Undefined;
		Items.Aliases.CurrentRow = CurrentRow;
		FillPagesAtClient();

		Возврат;
		
	КонецЕсли;
	// }
	Count = Unions.Count();
	For Pos = 0 To Count - 1 Do
		If StrReplace(Unions.Get(Pos)["Name"], " ", "") = Item.Name Then
			QueryPosition = Pos;
			Break;
		EndIf;
	EndDo;

	If QueryPosition = Undefined Then
		Return;
	EndIf;

	Parent = CurrentItems.GetParent();
	ParentIndex = -1;
	If Parent = Undefined Then
		Parent = Aliases;
	Else
		ParentIndex = Parent["Index"];
	EndIf;

	Index = CurrentItems["Index"];
	CurrentItems["Prefix"] = "*";
	If (Item.EditText <> "") Then
		ChangeAliasFieldAtCache(ParentIndex, Index, QueryPosition, CurrentItems[Item.Name]);
	Else
		ChangeAliasFieldAtCache(ParentIndex, Index, QueryPosition, -1);
	EndIf;
	CurrentItems[Item.Name] = Item.EditText;
	SetPageState("AliasesPage", True);
	Items.Aliases.CurrentRow = Undefined;
	Items.Aliases.CurrentRow = CurrentRow;
	FillPagesAtClient();
EndProcedure

&AtClient
Procedure AliasFieldOnClearing(Item, StandardProcessing)
	Var It;

	It = New Structure;
	It.Insert("Name", Item.Name);
	It.Insert("EditText", "");
	AliasFieldOnChange(It);
EndProcedure

&AtClient
Procedure GroupAdd(Command)
	Var Rows;
	Var CurrentRow;
	Var CurrentItems;
	Var NeedUpdate;

	NeedUpdate = False;
	Rows = Items.AllFieldsForGrouping.SelectedRows;
	For Each CurrentRow In Rows Do
		If (CurrentRow = Undefined) Then
			Return;
		EndIf;
		CurrentItems = AllFieldsForGrouping.FindByID(CurrentRow);
		If CurrentItems["Type"] = 2 Then
			ChangeGroupAtCache(Undefined, 1, CurrentItems["Name"]);
			SetPageState("GroupingPage", True);
			NeedUpdate = True;
		EndIf;
	EndDo;
	If NeedUpdate Then
		FillPagesAtClient(Items.AllFieldsForGrouping);
	EndIf;
EndProcedure

&AtClient
Procedure GroupAddAll(Command)
	GroupAddAtClient(AllFieldsForGrouping.GetItems());
	SetPageState("GroupingPage", True);
	FillPagesAtClient();
EndProcedure

&AtClient
Procedure GroupAddAtClient(Val GroupingFields)
	Var Count;
	Var Pos;
	Var Item;

	Count = GroupingFields.Count();
	For Pos = 0 To Count - 1 Do
		Item = GroupingFields.Get(Pos);
		If Item["AvailableField"] <> True Then
			Break;
		EndIf;
		If Item["Type"] = 2 Then
			ChangeGroupAtCache(Undefined, 4, Item["Name"]);
		Else
			GroupAddAtClient(Item.GetItems());
		EndIf;
	EndDo;
	FillPagesAtClient();
EndProcedure

&AtClient
Procedure GroupDelete(Command)
	Var Rows;
	Var CurrentRow;
	Var CurrentItems;
	Var Index;
	Var N;
	Var Item;

	Rows = Items.GroupingFields.SelectedRows;
	For Each CurrentRow In Rows Do
		If (CurrentRow = Undefined) Then
			Return;
		EndIf;
		CurrentItems = GroupingFields.FindByID(CurrentRow);
		Index = CurrentItems["Index"];
		ChangeGroupAtCache(Index, 2);

		GroupingFields.GetItems().Delete(GroupingFields.GetItems().IndexOf(CurrentItems));

		N = 0;
		For Each Item In GroupingFields.GetItems() Do
			Item["Index"] = N;
			N = N + 1;
		EndDo;
	EndDo;

	If Index = Undefined Then
		Return;
	EndIf;

	If Index >= GroupingFields.GetItems().Count() Then
		Index = Index - 1;
	EndIf;

	If Index >= 0 Then
		Items.GroupingFields.CurrentRow	= GroupingFields.GetItems().Get(Index).GetID();
	EndIf;

	SetPageState("GroupingPage", True);
	FillPagesAtClient();
EndProcedure

&AtClient
Procedure GroupDeleteAll(Command)
	ChangeGroupAtCache(-1, 3);
	SetPageState("GroupingPage", True);
	FillPagesAtClient();
EndProcedure

&AtClient
Procedure SummAdd(Command)
	Var Rows;
	Var CurrentRow;
	Var CurrentItems;
	Var Parent;
	Var ParentIndex;

	Rows = Items.AllFieldsForGrouping.SelectedRows;
	For Each CurrentRow In Rows Do
		If (CurrentRow = Undefined) Then
			Return;
		EndIf;
		CurrentItems = AllFieldsForGrouping.FindByID(CurrentRow);
		If CurrentItems["AvailableField"] <> True  Then
			ChangeSummAtCache(1,,, CurrentItems["Name"]); // добавить
		Else
			Parent = CurrentItems.GetParent();
			ParentIndex = -1;
			If Parent <> Undefined Then
				ParentIndex = Parent["Index"];
			EndIf;
			ChangeSummAtCache(5, ParentIndex, CurrentItems["Index"], CurrentItems["Name"]); // изменить
		EndIf;
	EndDo;
	SetPageState("GroupingPage", True);
	FillPagesAtClient();
EndProcedure

&AtClient
Procedure SummAddAll(Command)
	SummAddAtClient(AllFieldsForGrouping.GetItems());
	SetPageState("GroupingPage", True);
	FillPagesAtClient();
EndProcedure

&AtClient
Procedure SummAddAtClient(Val GroupingFields)
	Var Count;
	Var Pos;
	Var Item;
	Var Parent;
	Var ParentIndex;

	Count = GroupingFields.Count();
	For Pos = 0 To Count - 1 Do
		Item = GroupingFields.Get(Pos);
		If Item["AvailableField"] <> True Then
			Break;
		EndIf;
		Try
			If (Item["Type"] = 2)
				AND (Item["ValueType"] <> "")
				AND ((Item["ValueType"] = "Number") OR (Item["ValueType"] = "Число"))
				Then
				Parent = Item.GetParent();
				ParentIndex = -1;
				If Parent <> Undefined Then
					ParentIndex = Parent["Index"];
				EndIf;
				ChangeSummAtCache(6, ParentIndex, Item["Index"], Item["Name"]);
			Else
				SummAddAtClient(Item.GetItems());
			EndIf;
		Except
		EndTry;
	EndDo;
EndProcedure

&AtClient
Procedure SummDelete(Command)
	Var CurrentRow;
	Var CurrentItems;
	Var Parent;
	Var ParentIndex;
	Var Index;

	While Items.SummingFields.SelectedRows.Count() > 0 Do
		CurrentRow = Items.SummingFields.SelectedRows[0];
		If (CurrentRow = Undefined) Then
			Return;
		EndIf;
		CurrentItems = SummingFields.FindByID(CurrentRow);
		If CurrentItems["Type"] <> 2 Then
			Continue;
		EndIf;
		Parent = CurrentItems.GetParent();
		ParentIndex = -1;
		If Parent = Undefined Then
			Parent = SummingFields;
		Else
			ParentIndex = Parent["Index"];
		EndIf;
		ChangeSummAtCache(2, ParentIndex, CurrentItems["Index"]);
		Index = Parent.GetItems().IndexOf(CurrentItems);
		Parent.GetItems().Delete(Parent.GetItems().IndexOf(CurrentItems));
	EndDo;

	If Index = Undefined Then
		Return;
	EndIf;

	If Index >= Parent.GetItems().Count() Then
		Index = Index - 1;
	EndIf;

	If Index >= 0 Then
		Items.SummingFields.CurrentRow	= Parent.GetItems().Get(Index).GetID();
	EndIf;

	SetPageState("GroupingPage", True);
	FillPagesAtClient();
EndProcedure

&AtClient
Procedure SummDeleteAll(Command)
	ChangeSummAtCache(3);
	SetPageState("GroupingPage", True);
	FillPagesAtClient();
EndProcedure

&AtClient
Procedure SummingFieldsOnStartEdit(Item, NewRow, Clone)
	If NOT(StartEdit) Then
		TmpString = Item.CurrentData["Name"];
	EndIf;
	StartEdit = True;
EndProcedure

&AtClient
Procedure SummingFieldsBeforeEditEnd(Item, NewRow, CancelEdit, Cancel)
	Var CurrentRow;
	Var CurrentItems;

	If NOT(StartEdit) Then
	    Return;
	EndIf;

	CurrentRow = Items.SummingFields.CurrentRow;
	If (CurrentRow = Undefined) Then
		Return;
	EndIf;

	CurrentItems = SummingFields.FindByID(CurrentRow);
	If CurrentItems = Undefined Then
		Return;
	EndIf;

	If CancelEdit Then
		CurrentItems["Name"] = TmpString;
	EndIf;
	
	RowForEdit = CurrentRow;
	SetPageState("GroupingPage", True);
	
	// ITK37 * {
	//AttachIdleHandler("SummingFieldsBeforeEditEndHandler", 0.01, True);
	SummingFieldsBeforeEditEndHandler();
	// }
EndProcedure

&AtClient
Procedure SummingFieldsBeforeEditEndHandler()
	Var CurrentItems;
	
	CurrentItems = SummingFields.FindByID(RowForEdit);	
	If CurrentItems = Undefined Then
		Return;
	EndIf;
	
	If ChangeSummingField(CurrentItems["Name"]) = False Then
		ShowErrorMessage();
		StartEdit = True;
		NeedFillChoiceList = False;
		Items.SummingFields.CurrentRow = RowForEdit;
		Items.SummingFields.ChangeRow();
		Return;
	Else
		If CurrentItems["Name"] = "" Then
			FillPagesAtClient();
		EndIf;
	EndIf;
	StartEdit = False;
EndProcedure

&AtServer
Function ChangeSummingField(Expression, ErrorMessage = Undefined)
	Var CurrentRow;
	Var CurrentItems;
	Var Parent;
	Var QuerySchema;
	Var Query;
	Var Operators;
	Var ContainsAggregateFunction;
	Var ParentIndex;
	Var Operator;
	Var StatedExpression;

	CurrentRow = Items.SummingFields.CurrentRow;
	If (CurrentRow = Undefined) Then
		Return True;
	EndIf;

	CurrentItems = SummingFields.FindByID(CurrentRow);
	If CurrentItems = Undefined Then
		Return True;
	EndIf;

	If CurrentItems["Type"] <> 2 Then
		Return False;
	EndIf;

	Parent = CurrentItems.GetParent();
	ParentIndex = -1;
	If Parent = Undefined Then
		Parent = Aliases;
	Else
		ParentIndex = Parent["Index"];
	EndIf;

	QuerySchema = GetFromTempStorage(QueryWizardAddress);
	If QuerySchema = Undefined Then
		Return True;
	EndIf;

	Batch = QuerySchema.QueryBatch;
	Query = GetSchemaQuery(QuerySchema, CurrentQuerySchemaSelectQuery, NestedQueryPositionAddress);

	If TypeOf(Query) = Type("QuerySchemaSelectQuery") Then
		Operators  = Query.Operators;
		Operator = Operators.Get(CurrentQuerySchemaOperator);
	Else
		Return True;
	EndIf;

	Try
		ContainsAggregateFunction = True;
		StatedExpression = ChangeExpressionAtServer(ParentIndex, CurrentItems["Index"], Expression, Operator,
                                                    ContainsAggregateFunction);
		If ContainsAggregateFunction Then
			Expression = StatedExpression;
		Else
			Expression = "";
		EndIf;
	Except

		If ErrorMessage <> Undefined Then
			ErrorMessage = BriefErrorDescription(ErrorInfo());
		Else
			AddErrorMessageAtServer(BriefErrorDescription(ErrorInfo()));
		EndIf;
		Return False;
	EndTry;
	
	PutToTempStorage(QuerySchema, QueryWizardAddress);
	Return True;
EndFunction

&AtClient
Procedure JoinsBeforeRowChange(Item, Cancel)
	If Item.CurrentData["Type"] = 2 Then
		Cancel = False;
		Return;
	EndIf;
	If (Item.CurrentData["Type"] = 1) AND (Item.CurrentItem.Name = "JoinsJoinType") Then
		Cancel = False;
		Return;
	EndIf;
	Cancel = True;
EndProcedure

&AtClient
Procedure JoinsOnStartEdit(Item, NewRow, Clone)
	If Item.CurrentData["Type"] = 2 AND NOT(StartEdit) Then
		TmpString = Item.CurrentData["Expression"];
		StartEdit = True;
	EndIf;
	If (Item.CurrentData["Type"] = 1) AND (Item.CurrentItem.Name = "Joins1JoinType") Then
		TmpString = Item.CurrentData["JoinType"];
	EndIf;
EndProcedure

&AtClient
Procedure JoinsBeforeEditEnd(Item, NewRow, CancelEdit, Cancel)
	Var CurrentRow;
	Var CurrentItems;

	If NOT(StartEdit)
		OR (Item.CurrentItem.Name <> "JoinsExpression") Then
	    Return;
	EndIf;

	CurrentRow = Items.Joins.CurrentRow;
	If (CurrentRow = Undefined) Then
		Return;
	EndIf;

	CurrentItems = Joins.FindByID(CurrentRow);
	If CurrentItems = Undefined Then
		Return;
	EndIf;

	If CancelEdit Then
		CurrentItems["Expression"] = TmpString;
		AttachIdleHandler("CancelChangeJoinExpressionHandler", 0.01, True);
		StartEdit = False;
		Return;
	EndIf;
	
	RowForEdit = CurrentRow;
	StartEdit = False;
	AttachIdleHandler("ChangeJoinExpressionHandler", 0.01, True);	
EndProcedure

&AtClient
Procedure CancelChangeJoinExpressionHandler()
	ChangeJoinExpression(RowForEdit, TmpString);
EndProcedure

&AtClient
Procedure ChangeJoinExpressionHandler()
	If NOT(ChangeJoinExpression(RowForEdit)) Then
		ShowErrorMessage();
		StartEdit = True;
		Items.Joins.CurrentRow = RowForEdit;
		Items.Joins.ChangeRow();
		Return;
	EndIf;
	StartEdit = False;
EndProcedure


&AtServer
Function ChangeJoinExpression(Val CurrentRow, Val NewExpression = Undefined, Val ShowMessage = True, ErrorMessage = Undefined)
	Var CurrentItems;
	Var Expression;
	Var QuerySchema;
	Var Query;
	Var Operators;
	Var ParentTable;
	Var ChildTable;
	Var Operator;

	If (CurrentRow = Undefined) Then
		Return True;
	EndIf;
	CurrentItems = Joins.FindByID(CurrentRow);

	If CurrentItems["Type"] <> 2 Then
		Return True;
	EndIf;

	ChildTable = CurrentItems.GetParent()["Table"];
	ParentTable = CurrentItems.GetParent().GetParent()["Table"];

	If NewExpression = Undefined Then
		Expression = CurrentItems["Expression"];
	Else
		Expression = NewExpression;
		CurrentItems["Expression"] = NewExpression;
	EndIf;

	If  (Expression = TmpString) AND (NewExpression = Undefined) Then
		Return True;
	EndIf;

	QuerySchema = GetFromTempStorage(QueryWizardAddress);
	If QuerySchema = Undefined Then
		Return True;
	EndIf;

	Batch = QuerySchema.QueryBatch;
	Query = GetSchemaQuery(QuerySchema, CurrentQuerySchemaSelectQuery, NestedQueryPositionAddress);

	If TypeOf(Query) = Type("QuerySchemaSelectQuery") Then
		Operators  = Query.Operators;
		Operator = Operators.Get(CurrentQuerySchemaOperator);
	Else
		Return True;
	EndIf;

	Try
		SetJoin(ParentTable, ChildTable, Expression, Operator);
		CurrentItems["Expression"] = Expression;
	Except
		If ShowMessage Then
			AddErrorMessageAtServer(BriefErrorDescription(ErrorInfo()));
		EndIf;

		If ErrorMessage <> Undefined Then
			ErrorMessage = BriefErrorDescription(ErrorInfo());
		EndIf;
		Return False;
	EndTry;
	
	PutToTempStorage(QuerySchema, QueryWizardAddress);
	Return True;
EndFunction

&AtClient
Procedure JoinsOnEditEnd(Item, NewRow, CancelEdit)
	Var CurrentRow;
	Var CurrentItems;
	Var JoinType;
	Var ChildName;
	Var ParentName;
	Var JoinTypeStr;

	CurrentRow = Item.CurrentRow;
	If (CurrentRow = Undefined) Then
		Return;
	EndIf;
	CurrentItems = Joins.FindByID(CurrentRow);

	If Item.CurrentData["Type"] = 2 Then
		Return;
	EndIf;
	If (Item.CurrentData["Type"] = 1) AND (Item.CurrentItem.Name = "JoinsJoinType") Then
		ChildName = CurrentItems["Table"];
		ParentName = CurrentItems.GetParent()["Table"];
		JoinType = CurrentItems["JoinType"];
		If  JoinType = TmpString Then
			Return;
		EndIf;
		
		ChangeJoinAtCache(3, ParentName, ChildName,,, JoinType);
		
		For Each JoinTypeStr In Items.JoinsJoinType.ChoiceList Do
			If (JoinType = JoinTypeStr.Value) Then
				CurrentItems["JoinType"] = JoinTypeStr.Presentation;
				Break;	
			EndIf;			
		EndDo;
	EndIf;

	SetPageState("JoinsPage", True);
EndProcedure

&AtClient
Procedure JoinsJoinTypeChoiceProcessing(Item, SelectedValue, StandardProcessing)

EndProcedure

&AtClient
Procedure JoinsDragStart(Item, DragParameters, Perform)
	DragParameters.AllowedActions = DragAllowedActions.Move;
	DragParameters.Value = "Allow";
EndProcedure

&AtClient
Procedure JoinsDragCheck(Item, DragParameters, StandardProcessing, Row, Field)
	If DragParameters.Value = "Allow" Then
		StandardProcessing = False;
	EndIf;
EndProcedure

&AtClient
Procedure JoinsDrag(Item, DragParameters, StandardProcessing, Row, Field)
	Var CurrentRow;
	Var ReceivingItem;
	Var CurrentItems;

	If Row = Undefined Then
		Return;
	EndIf;

	StandardProcessing = False;
	CurrentRow = Items.Joins.CurrentRow;
	If (CurrentRow = Undefined) Then
		Return;
	EndIf;

	CurrentItems = Joins.FindByID(CurrentRow);
	ReceivingItem = Joins.FindByID(Row);

	MakeJoin(CurrentItems, ReceivingItem);
EndProcedure

&AtClient
Procedure MakeJoin(Val CurrentItems, Val ReceivingItem)
	Var CurRow;

	If (ReceivingItem["Table"] = "")
		OR (CurrentItems["Table"] = "") Then
		Return;
	EndIf;

	If (ReceivingItem = Undefined) Then
		Return;
	EndIf;

	If (CurrentItems["Type"] = 1) AND (ReceivingItem["Type"] = 0) Then
		ChangeJoinAtCache(2, CurrentItems.GetParent()["Table"], CurrentItems["Table"]); // удалить
	ElsIf (CurrentItems["Type"] = 1) OR (CurrentItems["Type"] = 3) Then
		ChangeJoinAtCache(1, ReceivingItem["Table"], CurrentItems["Table"], ""); // добавить
	EndIf;

	SetPageState("JoinsPage", True);
	FillPagesAtClient();

	CurRow = FindJoin(CurrentItems["Table"], Joins.GetItems());
	If CurRow <> Undefined Then
	    Items.Joins.CurrentRow = Undefined;
		Items.Joins.CurrentRow = CurRow;
	EndIf;
EndProcedure

&AtClient
Function FindJoin(TableName, Tree)
	Var Count;
	Var Pos;
	Var Item;
	Var Row;

	Count = Tree.Count();
	For Pos = 0 To Count - 1 Do
	    Item = Tree.Get(Pos);
		If Item["Table"] = TableName Then
			Return  Item.GetID();
		EndIf;
		Row = FindJoin(TableName, Item.GetItems());
		If Row <> Undefined Then
			Return Row;
		EndIf;
	EndDo;
	Return Undefined;
EndFunction

&AtClient
Procedure AllFieldsForGroupingDragStart(Item, DragParameters, Perform)
	DragParameters.AllowedActions = DragAllowedActions.Copy;
	DragParameters.Value = "DragFromGroupFields";
EndProcedure

&AtClient
Procedure GroupingFieldsDragCheck(Item, DragParameters, StandardProcessing, Row, Field)
	If DragParameters.Value = "DragFromGroupFields" Then
		StandardProcessing = False;
	EndIf;
	If DragParameters.Value = "DragFromSumm" Then
		StandardProcessing = False;
	EndIf;
EndProcedure

&AtClient
Procedure GroupingFieldsDrag(Item, DragParameters, StandardProcessing, Row, Field)
	Var Rows;
	Var CurrentRow;
	Var CurrentItems;
	Var Parent;
	Var ParentIndex;
	Var N;

	StandardProcessing = False;
	If DragParameters.Value = "DragFromGroupFields" Then
		GroupAdd(Undefined);
	EndIf;
	If DragParameters.Value = "DragFromSumm" Then
		Rows = Items.SummingFields.SelectedRows;
		For Each CurrentRow In Rows Do
			If (CurrentRow = Undefined) Then
				Return;
			EndIf;
			CurrentItems = SummingFields.FindByID(CurrentRow);
			If CurrentItems["Type"] <> 2 Then
				Continue;
			EndIf;
			Parent = CurrentItems.GetParent();
			ParentIndex = -1;
			If Parent = Undefined Then
				Parent = Aliases;
			Else
				ParentIndex = Parent["Index"];
			EndIf;
			ChangeGroupAtCache(CurrentItems["Index"], 5,, ParentIndex);

			N = 0;
			For Each Item In GroupingFields.GetItems() Do
				Item["Index"] = N;
				N = N + 1;
			EndDo;
		EndDo;
		SetPageState("GroupingPage", True);
		FillPagesAtClient();
	EndIf;
EndProcedure

&AtClient
Procedure SummingFieldsDragCheck(Item, DragParameters, StandardProcessing, Row, Field)
	If DragParameters.Value = "DragFromGroupFields" Then
		StandardProcessing = False;
	EndIf;
	If DragParameters.Value = "DragFromGroup" Then
		StandardProcessing = False;
	EndIf;
EndProcedure

&AtClient
Procedure SummingFieldsDrag(Item, DragParameters, StandardProcessing, Row, Field)
	Var CurrentRow;
	Var CurrentItems;
	Var N;

	StandardProcessing = False;
	If DragParameters.Value = "DragFromGroupFields" Then
		SummAdd(Undefined);
	EndIf;
	If DragParameters.Value = "DragFromGroup" Then
		While Items.GroupingFields.SelectedRows.Count() > 0 Do
			CurrentRow = Items.GroupingFields.SelectedRows[0];
			If (CurrentRow = Undefined) Then
				Return;
			EndIf;
			CurrentItems = GroupingFields.FindByID(CurrentRow);
			ChangeSummAtCache(7, CurrentItems["Index"],, CurrentItems["Name"]);

			GroupingFields.GetItems().Delete(CurrentItems["Index"]);

			N = 0;
			For Each Item In GroupingFields.GetItems() Do
				Item["Index"] = N;
				N = N + 1;
			EndDo;
		EndDo;
		SetPageState("GroupingPage", True);
		FillPagesAtClient();
	EndIf;
EndProcedure

&AtClient
Procedure GroupingFieldsDragStart(Item, DragParameters, Perform)
	DragParameters.AllowedActions = DragAllowedActions.Copy;
	DragParameters.Value = "DragFromGroup";
EndProcedure

&AtClient
Procedure SummingFieldsDragStart(Item, DragParameters, Perform)
	DragParameters.AllowedActions = DragAllowedActions.Copy;
	DragParameters.Value = "DragFromSumm";
EndProcedure

&AtClient
Procedure AllFieldsForGroupingDragCheck(Item, DragParameters, StandardProcessing, Row, Field)
	If DragParameters.Value = "DragFromGroup" Then
		StandardProcessing = False;
	EndIf;
	If DragParameters.Value = "DragFromSumm" Then
		StandardProcessing = False;
	EndIf;
EndProcedure

&AtClient
Procedure AllFieldsForGroupingDrag(Item, DragParameters, StandardProcessing, Row, Field)
	StandardProcessing = False;
	If DragParameters.Value = "DragFromGroup" Then
		GroupDelete(Undefined);
	EndIf;
	If DragParameters.Value = "DragFromSumm" Then
		SummDelete(Undefined);
	EndIf;
EndProcedure

&AtClient
Procedure TotalsFieldsDelete(Command)
	Var CurrentRow;
	Var CurrentItems;
	Var Index;
	Var Count;
	Var Pos;

	While Items.TotalsGroupingFields.SelectedRows.Count() > 0 Do
		CurrentRow = Items.TotalsGroupingFields.SelectedRows[0];
		If (CurrentRow = Undefined) Then
			Return;
		EndIf;
		CurrentItems = TotalsGroupingFields.FindByID(CurrentRow);
		Index = CurrentItems["Index"];
		ChangeTotalsGroupingFieldsAtCache(2, Index);

		TotalsGroupingFields.GetItems().Delete(Index);
		Count = TotalsGroupingFields.GetItems().Count();
		For Pos = 0 To Count - 1 Do
			TotalsGroupingFields.GetItems().Get(Pos)["Index"] = Pos;
		EndDo;
	EndDo;

	If Index = Undefined Then
		Return;
	EndIf;

	If Index >= TotalsGroupingFields.GetItems().Count() Then
		Index = Index - 1;
	EndIf;

	If Index >= 0 Then
		Items.TotalsGroupingFields.CurrentRow = TotalsGroupingFields.GetItems().Get(Index).GetID();
	EndIf;

	SetPageState("TotalsPage", True);
	FillPagesAtClient();
EndProcedure

&AtClient
Procedure TotalsFieldsDeleteAll(Command)
	ChangeTotalsGroupingFieldsAtCache(3);
	SetPageState("TotalsPage", True);
	FillPagesAtClient();
EndProcedure

&AtClient
Procedure TotalsFieldsAdd(Command)
	Var Rows;
	Var CurrentRow;
	Var CurrentItems;
	Var FieldIndex;
	Var Parent;
	Var ParentIndex;

	Rows = Items.AllFieldsForTotals.SelectedRows;
	For Each CurrentRow In Rows Do
		If (CurrentRow = Undefined) Then
			Return;
		EndIf;

		CurrentItems = AllFieldsForTotals.FindByID(CurrentRow);
		If CurrentItems["Type"] <> 2 Then
			Continue;
		EndIf;
		FieldIndex = CurrentItems["Index"];
		If (FieldIndex < 0) OR (CurrentItems["Type"] = 0) Then
			Continue;
		EndIf;
		If CurrentItems["IsAlias"] Then
			Parent =  CurrentItems.GetParent();
			If Parent = Undefined Then
				ParentIndex = -1;
			Else
			    ParentIndex = Parent["Index"];
			EndIf;

			ChangeTotalsGroupingFieldsAtCache(1, CurrentItems["Index"], ParentIndex);
		Else
			ChangeTotalsGroupingFieldsAtCache(5,,, CurrentItems["Name"]);
		EndIf;
	EndDo;
	SetPageState("TotalsPage", True);
	FillPagesAtClient();
EndProcedure

&AtClient
Procedure TotalsFieldsAddAll(Command)
	Var FieldsItems;
	Var Count;
	Var Pos;
	Var Item;
	Var Parent;
	Var ParentIndex;

	FieldsItems = AllFieldsForTotals.GetItems();
	Count = FieldsItems.Count();
	For Pos = 0 To Count - 1 Do
		Item = FieldsItems.Get(Pos);
		If (Item["Index"] < 0)  OR (Item["Type"] < 0) Then
			Break;
		EndIf;

		If Item["Type"] <> 2 Then
			Continue;
		EndIf;

		Parent =  Item.GetParent();
		If Parent = Undefined Then
			ParentIndex = -1;
		Else
		    ParentIndex = Parent["Index"];
		EndIf;

		ChangeTotalsGroupingFieldsAtCache(1, Item["Index"], ParentIndex);
	EndDo;
	SetPageState("TotalsPage", True);
	FillPagesAtClient();
EndProcedure

&AtClient
Procedure TotalsFieldsMoveUp(Command)
	Var CurrentRow;
	Var CurrentItems;
	Var Count;
	Var Pos;

	CurrentRow = Items.TotalsGroupingFields.CurrentRow;
	If (CurrentRow = Undefined) Then
		Return;
	EndIf;

	CurrentItems = TotalsGroupingFields.FindByID(CurrentRow);
	MoveTotalsFieldAtClient(CurrentItems["Index"], CurrentItems["Index"] - 1);
	Count = TotalsGroupingFields.GetItems().Count();
	For Pos = 0 To Count - 1 Do
		TotalsGroupingFields.GetItems().Get(Pos)["Index"] = Pos;
	EndDo;
	FillPagesAtClient();
EndProcedure

&AtClient
Procedure TotalsFieldsMoveDown(Command)
	Var CurrentRow;
	Var CurrentItems;
	Var Count;
	Var Pos;

	CurrentRow = Items.TotalsGroupingFields.CurrentRow;
	If (CurrentRow = Undefined) Then
		Return;
	EndIf;

	CurrentItems = TotalsGroupingFields.FindByID(CurrentRow);
	MoveTotalsFieldAtClient(CurrentItems["Index"], CurrentItems["Index"] + 1);
	Count = TotalsGroupingFields.GetItems().Count();
	For Pos = 0 To Count - 1 Do
		TotalsGroupingFields.GetItems().Get(Pos)["Index"] = Pos;
	EndDo;
	FillPagesAtClient();
EndProcedure

&AtClient
Procedure MoveTotalsFieldAtClient(Val Index, Val NewIndex)
	If (NewIndex < 0) OR (Index = NewIndex) OR (NewIndex >= TotalsGroupingFields.GetItems().Count()) Then
		Return;
	EndIf;

	TotalsGroupingFields.GetItems().Move(Index, NewIndex - Index);
	ChangeTotalsGroupingFieldsAtCache(4, Index, NewIndex);
	SetPageState("TotalsPage", True);
EndProcedure

&AtClient
Procedure TotalsExpressionsDelete(Command)
	Var CurrentRow;
	Var CurrentItems;
	Var Index;
	Var Count;
	Var Pos;

	While Items.TotalsExpressions.SelectedRows.Count() > 0 Do
		CurrentRow = Items.TotalsExpressions.SelectedRows[0];
		If (CurrentRow = Undefined) Then
			Return;
		EndIf;
		CurrentItems = TotalsExpressions.FindByID(CurrentRow);
		Index = CurrentItems["Index"];
		ChangeTotalsExpressionsAtCache(2, Index);

		TotalsExpressions.GetItems().Delete(Index);
		Count = TotalsExpressions.GetItems().Count();
		For Pos = 0 To Count - 1 Do
			TotalsExpressions.GetItems().Get(Pos)["Index"] = Pos;
		EndDo;
	EndDo;

	If Index = Undefined Then
		Return;
	EndIf;

	If Index >= TotalsExpressions.GetItems().Count() Then
		Index = Index - 1;
	EndIf;

	If Index >= 0 Then
		Items.TotalsExpressions.CurrentRow = TotalsExpressions.GetItems().Get(Index).GetID();
	EndIf;

	SetPageState("TotalsPage", True);
	FillPagesAtClient();
EndProcedure

&AtClient
Procedure TotalsExpressionsDeleteAll(Command)
	ChangeTotalsExpressionsAtCache(3);
	SetPageState("TotalsPage", True);
	FillPagesAtClient();
EndProcedure

&AtClient
Procedure TotalsExpressionsAdd(Command)
	Var Rows;
	Var CurrentRow;
	Var CurrentItems;
	Var FieldIndex;
	Var Parent;
	Var ParentIndex;

	Rows = Items.AllFieldsForTotals.SelectedRows;
	For Each CurrentRow In Rows Do
		If (CurrentRow = Undefined) Then
			Return;
		EndIf;

		CurrentItems = AllFieldsForTotals.FindByID(CurrentRow);
		If (CurrentItems["Type"] <> 2) OR (CurrentItems["IsAlias"] <> True) Then
			Continue;
		EndIf;
		FieldIndex = CurrentItems["Index"];
		If (FieldIndex < 0) OR (CurrentItems["Type"] = 0) Then
			Continue;
		EndIf;
		Parent =  CurrentItems.GetParent();
		If Parent = Undefined Then
			ParentIndex = -1;
		Else
		    ParentIndex = Parent["Index"];
		EndIf;
		ChangeTotalsExpressionsAtCache(1, CurrentItems["Index"], ParentIndex);
	EndDo;
	SetPageState("TotalsPage", True);
	FillPagesAtClient();
EndProcedure

&AtClient
Procedure TotalsExpressionsAddAll(Command)
	Var FieldsItems;
	Var Count;
	Var Pos;
	Var Item;
	Var Parent;
	Var ParentIndex;

	FieldsItems = AllFieldsForTotals.GetItems();
	Count = FieldsItems.Count();
	For Pos = 0 To Count - 1 Do
		Item = FieldsItems.Get(Pos);
		If (Item["Index"] < 0)  OR (Item["Type"] < 0) Then
			Break;
		EndIf;

		If Item["Type"] <> 2 Then
			Continue;
		EndIf;

		Try
			If (Item["ValueType"] = "")
				OR ((Item["ValueType"] <> "Number") AND (Item["ValueType"] <> "Число")) Then
				Continue;
			EndIf;
		Except
			Continue;
		EndTry;

		Parent =  Item.GetParent();
		If Parent = Undefined Then
			ParentIndex = -1;
		Else
		    ParentIndex = Parent["Index"];
		EndIf;

		ChangeTotalsExpressionsAtCache(1, Item["Index"], ParentIndex);
	EndDo;
	SetPageState("TotalsPage", True);
	FillPagesAtClient();
EndProcedure

&AtClient
Procedure AllFieldsForTotalsDragStart(Item, DragParameters, Perform)
	DragParameters.AllowedActions = DragAllowedActions.Copy;
	DragParameters.Value = "DragFromFieldsForGrouping";
EndProcedure

&AtClient
Procedure TotalsGroupingFieldsDragCheck(Item, DragParameters, StandardProcessing, Row, Field)
	If DragParameters.Value = "DragFromFieldsForGrouping" Then
		StandardProcessing = False;
	EndIf;
	If DragParameters.Value = "DragFromTotalsExpressions" Then
		StandardProcessing = False;
	EndIf;
EndProcedure

&AtClient
Procedure TotalsGroupingFieldsDrag(Item, DragParameters, StandardProcessing, Row, Field)
	Var CurrentRow;
	Var CurrentItems;
	Var Count;
	Var Pos;

	StandardProcessing = False;
	If DragParameters.Value = "DragFromFieldsForGrouping" Then
		TotalsFieldsAdd(Undefined);
	EndIf;
	If DragParameters.Value = "DragFromTotalsExpressions" Then
		While Items.TotalsExpressions.SelectedRows.Count() > 0 Do
			CurrentRow = Items.TotalsExpressions.SelectedRows[0];
			If (CurrentRow = Undefined) Then
				Return;
			EndIf;
			CurrentItems = TotalsExpressions.FindByID(CurrentRow);
			ChangeTotalsGroupingFieldsAtCache(6, CurrentItems["Index"]);

			TotalsExpressions.GetItems().Delete(CurrentItems["Index"]);
			Count = TotalsExpressions.GetItems().Count();
			For Pos = 0 To Count - 1 Do
				TotalsExpressions.GetItems().Get(Pos)["Index"] = Pos;
			EndDo;
		EndDo;
		SetPageState("TotalsPage", True);
		FillPagesAtClient();
	EndIf;
EndProcedure

&AtClient
Procedure TotalsExpressionsDragCheck(Item, DragParameters, StandardProcessing, Row, Field)
	If DragParameters.Value = "DragFromFieldsForGrouping" Then
		StandardProcessing = False;
	EndIf;
	If DragParameters.Value = "DragFromTotalsGroupingFields" Then
		StandardProcessing = False;
	EndIf;
EndProcedure

&AtClient
Procedure TotalsExpressionsDrag(Item, DragParameters, StandardProcessing, Row, Field)
	Var CurrentRow;
	Var CurrentItems;
	Var Count;
	Var Pos;

	StandardProcessing = False;
	If DragParameters.Value = "DragFromFieldsForGrouping" Then
		TotalsExpressionsAdd(Undefined);
	EndIf;
	If DragParameters.Value = "DragFromTotalsGroupingFields" Then
		While Items.TotalsGroupingFields.SelectedRows.Count() > 0 Do
			CurrentRow = Items.TotalsGroupingFields.SelectedRows[0];
			If (CurrentRow = Undefined) Then
				Return;
			EndIf;
			CurrentItems = TotalsGroupingFields.FindByID(CurrentRow);
			ChangeTotalsExpressionsAtCache(4, CurrentItems["Index"]);

			TotalsGroupingFields.GetItems().Delete(CurrentItems["Index"]);
			Count = TotalsGroupingFields.GetItems().Count();
			For Pos = 0 To Count - 1 Do
				TotalsGroupingFields.GetItems().Get(Pos)["Index"] = Pos;
			EndDo;
		EndDo;
		SetPageState("TotalsPage", True);
		FillPagesAtClient();
	EndIf;
EndProcedure

&AtClient
Procedure AllFieldsForTotalsDragCheck(Item, DragParameters, StandardProcessing, Row, Field)
	If DragParameters.Value = "DragFromTotalsGroupingFields" Then
		StandardProcessing = False;
	EndIf;
	If DragParameters.Value = "DragFromTotalsExpressions" Then
		StandardProcessing = False;
	EndIf;
EndProcedure

&AtClient
Procedure AllFieldsForTotalsDrag(Item, DragParameters, StandardProcessing, Row, Field)
	StandardProcessing = False;
	If DragParameters.Value = "DragFromTotalsGroupingFields" Then
		TotalsFieldsDelete(Undefined);
	EndIf;
	If DragParameters.Value = "DragFromTotalsExpressions" Then
		TotalsExpressionsDelete(Undefined);
	EndIf;
EndProcedure

&AtClient
Procedure TotalsGroupingFieldsDragStart(Item, DragParameters, Perform)
	DragParameters.AllowedActions = DragAllowedActions.Copy;
	DragParameters.Value = "DragFromTotalsGroupingFields";
EndProcedure

&AtClient
Procedure TotalsExpressionsDragStart(Item, DragParameters, Perform)
	DragParameters.AllowedActions = DragAllowedActions.Copy;
	DragParameters.Value = "DragFromTotalsExpressions";
EndProcedure

&AtClient
Procedure TotalsGroupingFieldsBeforeRowChange(Item, Cancel)
	If Item.CurrentItem.Name = "TotalsGroupingFieldsName" Then
		Cancel = True;
	EndIf;
EndProcedure

&AtClient
Procedure TotalsGroupingFieldsOnStartEdit(Item, NewRow, Clone)
	If Item.CurrentItem.Name = "TotalsGroupingFieldsAlias" Then
		If NOT(StartEdit) Then
			TmpString = Item.CurrentData["Alias"];
		EndIf;	
		StartEdit = True;
	EndIf;
EndProcedure

&AtClient
Procedure TotalsGroupingFieldsBeforeEditEnd(Item, NewRow, CancelEdit, Cancel)
	Var CurrentRow;
	Var CurrentItems;

	If StartEdit Then
		CurrentRow = Items.TotalsGroupingFields.CurrentRow;
		If CurrentRow = Undefined Then
			Return;
		EndIf;
		CurrentItems = TotalsGroupingFields.FindByID(CurrentRow);
		If CurrentItems = Undefined Then
			Return;
		EndIf;

		If Item.CurrentItem.Name = "TotalsGroupingFieldsAlias" Then
			If CancelEdit Then
				CurrentItems["Alias"] = TmpString;
				Return;
			EndIf;
			
			RowForEdit = CurrentRow;
			AttachIdleHandler("TotalsGroupingFieldsBeforeEditEndHandler", 0.01, True);			
		EndIf;
	EndIf;
	StartEdit = False;
EndProcedure

&AtClient
Procedure TotalsGroupingFieldsBeforeEditEndHandler()
	If NOT(ChangeTotalsAlias(RowForEdit)) Then
		ShowErrorMessage();
		StartEdit = True;
		Items.TotalsGroupingFields.CurrentRow = RowForEdit;
		Items.TotalsGroupingFields.ChangeRow();
		Return;
	EndIf;
	StartEdit = False;
EndProcedure

&AtServer
Function ChangeTotalsAlias(Val CurrentRow)
	Var QuerySchema;
	Var Query;
	Var CurrentItems;
	Var TotalControlPoint;

	QuerySchema = GetFromTempStorage(QueryWizardAddress);
	If QuerySchema = Undefined Then
		Return True;
	EndIf;

	Batch = QuerySchema.QueryBatch;
	Query = GetSchemaQuery(QuerySchema, CurrentQuerySchemaSelectQuery, NestedQueryPositionAddress);

	If TypeOf(Query) <> Type("QuerySchemaSelectQuery") Then
		Return True;
	EndIf;

	If (CurrentRow = Undefined) Then
		Return True;
	EndIf;
	CurrentItems = TotalsGroupingFields.FindByID(CurrentRow);

	Try
		TotalControlPoint = Query.TotalCalculationFields.Get(CurrentItems["Index"]);
		TotalControlPoint.ColumnName = CurrentItems["Alias"];
	Except
		AddErrorMessageAtServer(BriefErrorDescription(ErrorInfo()));
		Return False;
	EndTry;


	Items.TotalsGroupingFields.CurrentRow = Undefined;
	Items.TotalsGroupingFields.CurrentRow = CurrentRow;
	
	PutToTempStorage(QuerySchema, QueryWizardAddress);
	Return True;
EndFunction

&AtClient
Procedure TotalsExpressionsBeforeRowChange(Item, Cancel)
	If (Item.CurrentItem.Name = "TotalsExpressionsName") OR (Item.CurrentItem.Name = "TotalsExpressionsPicture") Then
		Cancel = True;
	EndIf;
	
	If Item.CurrentItem.Name = "TotalsExpressionsExpression" Then
		RowForEdit = Item.CurrentRow;
		If NeedFillChoiceList Then
			AttachIdleHandler("TotalsExpressionsBeforeRowChangeHandler", 0.01, True);
			Cancel = True;
		Else
			NeedFillChoiceList = True;
		EndIf;		
	EndIf;
EndProcedure

&AtClient
Procedure TotalsExpressionsBeforeRowChangeHandler()
	Var Expressions;
	Var Count;
	Var Pos;
	
	Item = TotalsExpressions.FindByID(RowForEdit);
	Expressions = TotalsExpressionBeforeRowChangeAtServer(Item.Expression, Item.Index);
	Items.TotalsExpressionsExpression.ChoiceList.Clear();

	Count = Expressions.Count();
	For Pos = 0 To Count - 1 Do
		Items.TotalsExpressionsExpression.ChoiceList.Add(Expressions.Get(Pos));
	EndDo;
	NeedFillChoiceList = False;
	Items.TotalsExpressions.ChangeRow();
EndProcedure

&AtServer
Function TotalsExpressionBeforeRowChangeAtServer(Val Expression,  Val Index)
	Var QuerySchema;
	Var Query;
	Var Operators;
	Var Expressions;
	Var Count;
	Var TotalExpression;
	Var OldTotalExpression;
	Var Pos;
	Var Arr;

	QuerySchema = GetFromTempStorage(QueryWizardAddress);
	If QuerySchema = Undefined Then
		Return Undefined;
	EndIf;

	Batch = QuerySchema.QueryBatch;
	Query = GetSchemaQuery(QuerySchema, CurrentQuerySchemaSelectQuery, NestedQueryPositionAddress);

	If TypeOf(Query) <> Type("QuerySchemaSelectQuery") Then
		Return Undefined;
	EndIf;
	
	OldTotalExpression = String(Query.TotalExpressions.Get(Index).Expression);	
	Expressions = GetAgregateExpressions(OldTotalExpression, True);
	Count = Expressions.Count();
	Arr = New Array;
	For Pos = 0 To Count - 1 Do
		Try
			TotalExpression = Query.TotalExpressions.Get(Index);
			TotalExpression.Expression = New QuerySchemaExpression(Expressions.Get(Pos));
			Arr.Add(String(TotalExpression.Expression));
		Except
		EndTry;
	EndDo;

	TotalExpression = Query.TotalExpressions.Get(Index);
	TotalExpression.Expression = New QuerySchemaExpression(OldTotalExpression);

	Return Arr;
EndFunction

&AtClient
Procedure TotalsExpressionsOnStartEdit(Item, NewRow, Clone)
	If NOT(StartEdit) Then
		TmpString = Item.CurrentData["Expression"];
	EndIf;	
	StartEdit = True;
EndProcedure

&AtClient
Procedure TotalsExpressionsBeforeEditEnd(Item, NewRow, CancelEdit, Cancel)
	Var CurrentRow;
	Var CurrentItems;

	If StartEdit Then
		CurrentRow = Items.TotalsExpressions.CurrentRow;
		If CurrentRow = Undefined Then
			Return;
		EndIf;
		CurrentItems = TotalsExpressions.FindByID(CurrentRow);
		If CurrentItems = Undefined Then
			Return;
		EndIf;

		If CancelEdit Then
			CurrentItems["Expression"] = TmpString;
		EndIf;

		If Item.CurrentItem.Name = "TotalsExpressionsExpression" Then
			RowForEdit = CurrentRow;
			EditText = CurrentItems["Expression"];
			
			AttachIdleHandler("TotalsExpressionsBeforeEditEndHandler", 0.01, True);
			Return;
		EndIf;
	EndIf;
	StartEdit = False;
EndProcedure

&AtClient
Procedure TotalsExpressionsBeforeEditEndHandler()
	If NOT(ChangeTotalsExpression(RowForEdit, EditText)) Then
		ShowErrorMessage();
		Items.TotalsExpressions.CurrentRow = RowForEdit;
		Items.TotalsExpressions.ChangeRow();
		StartEdit = True;
		Return;
	EndIf;
	Item = TotalsExpressions.FindByID(RowForEdit);
	Item["Expression"] = EditText;
	StartEdit = False;
EndProcedure

&AtServer
Function ChangeTotalsExpression(Val CurrentRow, Expression, ErrorMessage = Undefined)
	Var QuerySchema;
	Var Query;
	Var CurrentItems;
	Var TotalExpression;

	QuerySchema = GetFromTempStorage(QueryWizardAddress);
	If QuerySchema = Undefined Then
		Return True;
	EndIf;

	Batch = QuerySchema.QueryBatch;
	Query = GetSchemaQuery(QuerySchema, CurrentQuerySchemaSelectQuery, NestedQueryPositionAddress);

	If TypeOf(Query) <> Type("QuerySchemaSelectQuery") Then
		Return True;
	EndIf;

	If (CurrentRow = Undefined) Then
		Return True;
	EndIf;
	CurrentItems = TotalsExpressions.FindByID(CurrentRow);

	Try
		TotalExpression = Query.TotalExpressions.Get(CurrentItems["Index"]);
		TotalExpression.Expression = New QuerySchemaExpression(Expression);
		Expression = String(TotalExpression.Expression);
	Except
		If ErrorMessage <> Undefined Then
			ErrorMessage = BriefErrorDescription(ErrorInfo());
		Else
			AddErrorMessageAtServer(BriefErrorDescription(ErrorInfo()));
		EndIf;
		Return False;
	EndTry;
	TmpString = "";
	
	PutToTempStorage(QuerySchema, QueryWizardAddress);	
	Return True;
EndFunction

&AtClient
Procedure PeriodOnChange(Item)
	Var CurrentRow;
	Var CurrentItems;
	Var NoAddition;

	CurrentRow = Items.TotalsGroupingFields.CurrentRow;
	If (CurrentRow = Undefined) Then
		Return;
	EndIf;

	CurrentItems = TotalsGroupingFields.FindByID(CurrentRow);
	If (CurrentItems = Undefined) Then
		Return;
	EndIf;
	NoAddition = NStr("ru = 'Без дополнения';
						|SYS = 'QueryEditor.NoAddition'", "ru");
	If Period Then
		If CurrentItems["Interval"] = NoAddition Then
			CurrentItems["Interval"] = NStr("ru = 'День';
											|SYS = 'QueryEditor.Day'", "ru");
			ChangeTotalsGroupingFieldsAtCache(7, CurrentItems["Index"],,, "Day");
			SetPageState("TotalsPage", True);
		EndIf;
	Else
		CurrentItems["PeriodStart"] = "";
		CurrentItems["PeriodEnd"] = "";
		ChangeTotalsGroupingFieldsAtCache(8, CurrentItems["Index"],,, "");; // начало периода
		ChangeTotalsGroupingFieldsAtCache(9, CurrentItems["Index"],,, "");; // конец периода

		CurrentItems["Interval"] = NoAddition;
		ChangeTotalsGroupingFieldsAtCache(7, CurrentItems["Index"],,, "NoAddition");
		SetPageState("TotalsPage", True);
	EndIf;
EndProcedure

&AtClient
Procedure IntervalOnChange(Item)
	Var CurrentRow;
	Var CurrentItems;

	CurrentRow = Items.TotalsGroupingFields.CurrentRow;
	If (CurrentRow = Undefined) Then
		Return;
	EndIf;
	CurrentItems = TotalsGroupingFields.FindByID(CurrentRow);
	If (CurrentItems["Index"] >= 0) Then
		ChangeTotalsGroupingFieldsAtCache(7, CurrentItems["Index"],,, Item.EditText);
		CurrentItems["Interval"] = Item.EditText;
		SetPageState("TotalsPage", True);

		If Item.EditText = "NoAddition" Then
			CurrentItems["Interval"] = NStr("ru = 'Без дополнения';
											|SYS = 'QueryEditor.NoAddition'", "ru");
		ElsIf Item.EditText = "Day" Then
			CurrentItems["Interval"] = NStr("ru = 'День';
											|SYS = 'QueryEditor.Day'", "ru");
		ElsIf Item.EditText = "Second" Then
			CurrentItems["Interval"] = NStr("ru = 'Секунда';
											|SYS = 'QueryEditor.Second'", "ru");
		ElsIf Item.EditText = "Minute" Then
			CurrentItems["Interval"] = NStr("ru = 'Минута';
											|SYS = 'QueryEditor.Minute'", "ru");
		ElsIf Item.EditText = "Hour" Then
			CurrentItems["Interval"] = NStr("ru = 'Час';
											|SYS = 'QueryEditor.Hour'", "ru");
		ElsIf Item.EditText = "Week" Then
			CurrentItems["Interval"] = NStr("ru = 'Неделя';
											|SYS = 'QueryEditor.Week'", "ru");
		ElsIf Item.EditText = "Month" Then
			CurrentItems["Interval"] = NStr("ru = 'Месяц';
											|SYS = 'QueryEditor.Month'", "ru");
		ElsIf Item.EditText = "Quarter" Then
			CurrentItems["Interval"] = NStr("ru = 'Квартал';
											|SYS = 'QueryEditor.Quarter'", "ru");
		ElsIf Item.EditText = "HalfYear" Then
			CurrentItems["Interval"] = NStr("ru = 'Полугодие';
											|SYS = 'QueryEditor.HalfYear'", "ru");
		ElsIf Item.EditText = "Year" Then
			CurrentItems["Interval"] = NStr("ru = 'Год';
											|SYS = 'QueryEditor.Year'", "ru");
		ElsIf Item.EditText = "TenDays" Then
			CurrentItems["Interval"] = NStr("ru = 'Декада';
											|SYS = 'QueryEditor.Decade'", "ru");
		EndIf;

		Interval = CurrentItems["Interval"];
	EndIf;
EndProcedure

&AtClient
Procedure PeriodStartOnChange(Item)
	Var CurrentRow;
	Var CurrentItems;

	CurrentRow = Items.TotalsGroupingFields.CurrentRow;
	If (CurrentRow = Undefined) Then
		Return;
	EndIf;
	CurrentItems = TotalsGroupingFields.FindByID(CurrentRow);
	If (CurrentItems["Index"] >= 0) Then
		ChangeTotalsGroupingFieldsAtCache(8, CurrentItems["Index"],,, Item.EditText);
		CurrentItems["PeriodStart"] = Item.EditText;
		SetPageState("TotalsPage", True);
		PeriodStart = CurrentItems["PeriodStart"];
	EndIf;
	SetPageState("TotalsPage", True);
EndProcedure

&AtClient
Procedure PeriodEndOnChange(Item)
	Var CurrentRow;
	Var CurrentItems;

	CurrentRow = Items.TotalsGroupingFields.CurrentRow;
	If (CurrentRow = Undefined) Then
		Return;
	EndIf;
	CurrentItems = TotalsGroupingFields.FindByID(CurrentRow);
	If (CurrentItems["Index"] >= 0) Then
		ChangeTotalsGroupingFieldsAtCache(9, CurrentItems["Index"],,, Item.EditText);
		CurrentItems["PeriodEnd"] = Item.EditText;
		SetPageState("TotalsPage", True);
		PeriodEnd = CurrentItems["PeriodEnd"];
	EndIf;
	SetPageState("TotalsPage", True);
EndProcedure

&AtClient
Procedure TotalsFlagOnChange(Item)
	ChangeOverallAtCache(Overall);
	SetPageState("OverallPage", True);
EndProcedure

&AtClient
Procedure AvailableFieldsDelete(Command)
	Var CurrentRow;
	Var CurrentItems;
	Var Parent;
	Var ParentIndex;
	Var Count;
	Var Pos;

	While Items.AvailableFields.SelectedRows.Count() > 0 Do
		CurrentRow = Items.AvailableFields.SelectedRows[0];
		If (CurrentRow = Undefined) Then
			Return;
		EndIf;
		CurrentItems = AvailableFields.FindByID(CurrentRow);

		Parent = CurrentItems.GetParent();
		If Parent = Undefined Then
			ParentIndex = -1;
			Parent = AvailableFields;
		Else
			ParentIndex = Parent["Index"];
		EndIf;

		ChangeExpressionAtCache(2, CurrentItems["Index"], ParentIndex);
		Parent.GetItems().Delete(Parent.GetItems().IndexOf(CurrentItems));

		Count = Parent.GetItems().Count();
		If NOT(Count) AND ParentIndex >= 0 Then
			AvailableFields.GetItems().Delete(ParentIndex);
		EndIf;

		For Pos = 0 To Count - 1 Do
			Parent.GetItems().Get(Pos)["Index"] = Pos;
		EndDo;
	EndDo;
	SetPageState("AvailableFieldsPage", True);
EndProcedure

&AtClient
Procedure AvailableFieldsDeleteAll(Command)
	ChangeExpressionAtCache(3);
	AvailableFields.GetItems().Clear();
	SetPageState("AvailableFieldsPage", True);
EndProcedure

&AtClient
Procedure SourcesDelete(Command)
	Var CurrentRow;
	Var CurrentItems;
	Var Parent;

	While Items.Sources.SelectedRows.Count() > 0 Do
		CurrentRow = Items.Sources.SelectedRows[0];
		If (CurrentRow = Undefined) Then
			Return;
		EndIf;
		CurrentItems = Sources.FindByID(CurrentRow);

		If CurrentItems["Type"] <> 1 Then
			Return;
		EndIf;

		Parent = CurrentItems.GetParent();
		If Parent = Undefined Then
			Parent = Sources;
		EndIf;

		ChangeSourceAtCache(2, CurrentItems["Presentation"]);
		RemoveAllFieldsForSource(CurrentItems["Presentation"], AvailableFields.GetItems());
		Parent.GetItems().Delete(Parent.GetItems().IndexOf(CurrentItems));
	EndDo;
	SetJoinsPageVisibleServer();
	
	SetPageState("SourcesPage", True);
	SetPageState("AvailableFieldsPage", True);
EndProcedure

&AtClient
Procedure SourcesDeleteAll(Command)
	ChangeSourceAtCache(3);
	Sources.GetItems().Clear();
	AvailableFields.GetItems().Clear();
	SetPageState("SourcesPage", True);
	SetPageState("AvailableFieldsPage", True);
	SetJoinsPageVisibleServer();
EndProcedure

&AtClient
Procedure AvailableFieldsAdd(Command)
	Var Rows;
	Var CurrentRow;
	Var CurrentItems;
	Var Expression;
	Var PagesItems;

	Rows = Items.Sources.SelectedRows;
	If Rows.Count() = 0 Then
		Return;
	Else
		SetPageState("AvailableFieldsPage", True);
	EndIf;

	For Each CurrentRow In Rows Do
		If (CurrentRow = Undefined) Then
			Return;
		EndIf;

		CurrentItems = Sources.FindByID(CurrentRow);
		Expression = CurrentItems["Name"];

		If CurrentItems["Type"] = 2 Then
			ChangeExpressionAtCache(1,,, Expression);
		EndIf;
	EndDo;

	PagesItems = PreFillAtClient();
	AvailableFieldsAddAtServer(PagesItems);
	PostFillAtClient(PagesItems);
EndProcedure

&AtServer
Procedure AvailableFieldsAddAtServer(Val PagesItems)
	Var Rows;
	Var CurrentRow;
	Var CurrentItems;

	Rows = Items.Sources.SelectedRows;
	For Each CurrentRow In Rows Do
		If (CurrentRow = Undefined) Then
			Return;
		EndIf;

		CurrentItems = Sources.FindByID(CurrentRow);
		Expression = CurrentItems["Name"];

		If CurrentItems["Type"] <> 2 Then
			AddExpressionsAtServer(CurrentItems);
		EndIf;
	EndDo;
	FillPagesAtServer(PagesItems);
EndProcedure

&AtClient
Procedure AvailableFieldsAddAll(Command)
	Var Rows;
	Var PagesItems;

	Rows = Items.Sources.SelectedRows;
	If Rows.Count() = 0 Then
		Return;
	Else
		SetPageState("AvailableFieldsPage", True);
	EndIf;

	PagesItems = PreFillAtClient();
	AvailableFieldsAddAllAtServer(PagesItems);
	PostFillAtClient(PagesItems);
EndProcedure

&AtServer
Procedure AvailableFieldsAddAllAtServer(Val PagesItems)
	Var Rows;
	Var CurrentRow;
	Var CurrentItems;

	Rows = Items.Sources.SelectedRows;
	For Each CurrentRow In Rows Do
		If (CurrentRow = Undefined) Then
			Return;
		EndIf;

		CurrentItems = Sources.FindByID(CurrentRow);
		AddExpressionsAtServer(CurrentItems);
	EndDo;
	FillPagesAtServer(PagesItems);
EndProcedure

&AtClient
Procedure RemoveAllFieldsForSource(Val SourceName, Val AllFields)
	Var Count;
	Var Pos;
	Var Presentation;

	Count = AllFields.Count();
	For Pos = 0 To Count - 1 Do
		If Pos = AllFields.Count() Then
			Break
		EndIf;
		Presentation = AllFields.Get(Pos)["Presentation"];
		If (Find(Presentation, SourceName + ".") = 1)
			OR (Find(Presentation, " " + SourceName + ".") > 0)
			OR (Find(Presentation, "(" + SourceName + ".") > 0) Then
			AllFields.Delete(Pos);
			Pos = Pos - 1;
		EndIf;
	EndDo;
EndProcedure

&AtClient
Function  GetItemIndexes(Val Item)
	Var ItemIndexes;
	Var Parent;

	ItemIndexes = New Array;
	ItemIndexes.Insert(0, Item["Index"]);
	Parent = Item.GetParent();
	While (Parent <> Undefined) AND (Parent["Type"] > 0) Do
		ItemIndexes.Insert(0, Parent["Index"]);
		Parent = Parent.GetParent();
	EndDo;
	Return ItemIndexes;
EndFunction

&AtServer
Function  GetItemIndexesAtServer(Val Item)
	Var ItemIndexes;
	Var Parent;

	ItemIndexes = New Array;
	ItemIndexes.Insert(0, Item["Index"]);
	Parent = Item.GetParent();
	While (Parent <> Undefined) AND (Parent["Type"] > 0) Do
		ItemIndexes.Insert(0, Parent["Index"]);
		Parent = Parent.GetParent();
	EndDo;
	Return ItemIndexes;
EndFunction

&AtClient
Procedure SourcesAdd(Command)
	Var Rows;
	Var CurrentRow;
	Var CurrentItems;
	Var ItemIndexes;

	Rows = Items.AvailableTables.SelectedRows;
	For Each CurrentRow In Rows Do
		If (CurrentRow = Undefined) Then
			Return;
		EndIf;
		CurrentItems = AvailableTables.FindByID(CurrentRow);
		ItemIndexes = GetItemIndexes(CurrentItems);
		If (CurrentItems["Type"] = 1) OR (CurrentItems["Type"] = 3) Then
			ChangeSourceAtCache(1, CurrentItems["Name"], ItemIndexes);
			SetPageState("SourcesPage", True);
		ElsIf CurrentItems["Type"] = 2 Then
			ChangeExpressionAtCache(1,,,, ItemIndexes);
			SetPageState("SourcesPage", True);
			SetPageState("AvailableFieldsPage", True);
		EndIf;
	EndDo;
	FillPagesAtClient();
EndProcedure

&AtClient
Procedure SourcesAddAll(Command)
	Var Rows;
	Var CurrentRow;
	Var CurrentItems;
	Var CItems;
	Var Item;
	Var ItemIndexes;
	Var PagesItems;

	Rows = Items.AvailableTables.SelectedRows;
	If Rows.Count() = 0 Then
		Return;
	Else
		SetPageState("SourcesPage", True);
		SetPageState("AvailableFieldsPage", True);
	EndIf;

	For Each CurrentRow In Rows Do
		If (CurrentRow = Undefined) Then
			Return;
		EndIf;

		CurrentItems = AvailableTables.FindByID(CurrentRow);
		If CurrentItems.GetParent() = Undefined Then
			If (CurrentItems.GetItems().Count() = 1)
				AND (CurrentItems.GetItems().Get(0)["Name"] = "FakeFieldeItem") Then

				AvailableTablesBeforeExpandAtServer(CurrentItems.GetID(),,2)
			EndIf;

			CItems = CurrentItems.GetItems();
			For Each Item In CItems Do
				ItemIndexes = GetItemIndexes(Item);
				ChangeSourceAtCache(1, Item["Name"], ItemIndexes);
			EndDo;
		EndIf;
	EndDo;
	PagesItems = PreFillAtClient();
	SourcesAddAllAtServer(PagesItems);
	PostFillAtClient(PagesItems);
EndProcedure

&AtServer
Procedure SourcesAddAllAtServer(Val PagesItems)
	Var QuerySchema;
	Var Rows;
	Var CurrentRow;
	Var CurrentItems;
	Var MainObject;
	Var Query;

	Rows = Items.AvailableTables.SelectedRows;
	MainObject = FormAttributeToValue("Object");
	QuerySchema = GetFromTempStorage(QueryWizardAddress);
	If QuerySchema = Undefined Then
		Return;
	EndIf;
	Batch = QuerySchema.QueryBatch;
	Query = GetSchemaQuery(QuerySchema, CurrentQuerySchemaSelectQuery, NestedQueryPositionAddress);

	For Each CurrentRow In Rows Do
		If (CurrentRow = Undefined) Then
			Return;
		EndIf;

		CurrentItems = AvailableTables.FindByID(CurrentRow);
		If CurrentItems.GetParent() <> Undefined Then
			AddExpressionsAtServer(CurrentItems, 1, 2, MainObject, Query);
		EndIf;
	EndDo;
	
	PutToTempStorage(QuerySchema, QueryWizardAddress);
	FillPagesAtServer(PagesItems);
EndProcedure

&AtServer
Procedure AddExpressionsAtServer(CurrentItems, 
								 Val Level = 1, 
								 Val OperationType = 1, 
								 MainObject = Undefined, 
								 Query = Undefined)
	Var QuerySchema;
	Var CurrentExpressions;
	Var Prop;
	Var Count;
	Var Pos;
	Var Type;
	Var Expression;
	Var ItemIndexes;

	//OperationType = 1 - для добавления выражений из списка таблиц в базе
	//OperationType = 2 - для добавления выражений из списка источников

	If MainObject = Undefined Then
		MainObject = FormAttributeToValue("Object");
	EndIf;

	If Query = Undefined Then
		QuerySchema = GetFromTempStorage(QueryWizardAddress);
		If QuerySchema = Undefined Then
			Return;
		EndIf;
		Batch = QuerySchema.QueryBatch;
		Query = GetSchemaQuery(QuerySchema, CurrentQuerySchemaSelectQuery, NestedQueryPositionAddress);
	EndIf;

	If CurrentItems["Type"] = 2 Then // Если поле
		CurrentItems = CurrentItems.GetParent();
	EndIf;

	CurrentExpressions = CurrentItems.GetItems();
	If (CurrentExpressions.Count() = 1)
		AND (CurrentExpressions.Get(0)["Name"] = "FakeFieldeItem") Then

		Prop = 0;
		CurrentItems.Property("ParametersCount", Prop);
		If (Prop = Undefined) Then
			AvailableTablesBeforeExpandAtServer(CurrentItems.GetID(),,2, MainObject, Query);
		Else
			SourcesBeforeExpandAtServer(CurrentItems.GetID(),,2, MainObject, Query)
		EndIf;
	EndIf;

	Count = CurrentExpressions.Count();
	For Pos = 0 To Count-1 Do

		Expression = CurrentExpressions[Pos]["Name"];
		Type = CurrentExpressions[Pos]["Type"];

		If OperationType = 1 Then
			If Type = 2 Then
				ChangeExpressionAtCacheAtServer(1,,,Expression);
			Else
				If Level < 2 Then
 					AddExpressionsAtServer(CurrentExpressions[Pos], Level + 1,, MainObject, Query);
				Else
					AddExpressionsAtServer(Expression,,, MainObject, Query);
				EndIf;
			EndIf;
		EndIf;

		If OperationType = 2 Then
			If CurrentItems.GetParent() = Undefined Then
				Break;
			EndIf;

			ItemIndexes = GetItemIndexesAtServer(CurrentExpressions[Pos]);
			If Type = 2 Then // Если поле
				ChangeExpressionAtCacheAtServer(1,,,,ItemIndexes);
			Else
				If Level < 2 Then
					ChangeExpressionAtCacheAtServer (1,,,,ItemIndexes);
				Else
					AddExpressionsAtServer(CurrentExpressions[Pos], Level + 1, OperationType, MainObject, Query);
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	
	PutToTempStorage(QuerySchema, QueryWizardAddress);
EndProcedure

&AtClient
Procedure AvailableTablesDragStart(Item, DragParameters, Perform)
	DragParameters.AllowedActions = DragAllowedActions.Copy;
	DragParameters.Value = "DragFromAvailableTables";
EndProcedure

&AtClient
Procedure AvailableTablesDragCheck(Item, DragParameters, StandardProcessing, Row, Field)
	If DragParameters.Value = "DragFromSources" Then
		StandardProcessing = False;
	EndIf;
	If DragParameters.Value = "DragFromAvailableFields" Then
		StandardProcessing = False;
	EndIf;
EndProcedure

&AtClient
Procedure AvailableTablesDrag(Item, DragParameters, StandardProcessing, Row, Field)
	StandardProcessing = False;
	If DragParameters.Value = "DragFromSources" Then
		SourcesDelete(Undefined);
	EndIf;
	If DragParameters.Value = "DragFromAvailableFields" Then
		AvailableFieldsDelete(Undefined);
	EndIf;
EndProcedure

&AtClient
Procedure SourcesDragStart(Item, DragParameters, Perform)
	DragParameters.AllowedActions = DragAllowedActions.Copy;
	DragParameters.Value = "DragFromSources";
EndProcedure

&AtClient
Procedure SourcesDragCheck(Item, DragParameters, StandardProcessing, Row, Field)
	If DragParameters.Value = "DragFromAvailableTables" Then
		StandardProcessing = False;
	EndIf;
	If DragParameters.Value = "DragFromAvailableFields" Then
		StandardProcessing = False;
	EndIf;
EndProcedure

&AtClient
Procedure SourcesDrag(Item, DragParameters, StandardProcessing, Row, Field)
	StandardProcessing = False;
	If DragParameters.Value = "DragFromAvailableTables" Then
		SourcesAdd("");
	EndIf;
	If DragParameters.Value = "DragFromAvailableFields" Then
		AvailableFieldsDelete("");
	EndIf;
EndProcedure

&AtClient
Procedure AvailableFieldsDragStart(Item, DragParameters, Perform)
	DragParameters.AllowedActions = DragAllowedActions.Copy;
	DragParameters.Value = "DragFromAvailableFields";
EndProcedure

&AtClient
Procedure AvailableFieldsDragCheck(Item, DragParameters, StandardProcessing, Row, Field)
	If DragParameters.Value = "DragFromSources" Then
		StandardProcessing = False;
	EndIf;
	If DragParameters.Value = "DragFromAvailableTables" Then
		StandardProcessing = False;
	EndIf;
EndProcedure

&AtClient
Procedure AvailableFieldsDrag(Item, DragParameters, StandardProcessing, Row, Field)
	Var CurrentRow;
	Var CurrentItems;
	Var Type;

	StandardProcessing = False;
	If DragParameters.Value = "DragFromAvailableTables" Then
		CurrentRow = Items.AvailableTables.CurrentRow;
		If (CurrentRow = Undefined) Then
			Return;
		EndIf;
		CurrentItems = AvailableTables.FindByID(CurrentRow);
		Type = CurrentItems["Type"];
		If Type = 2 Then
			SourcesAdd(Undefined);
		Else
			SourcesAddAll(Undefined);
		EndIf;
	EndIf;
	If DragParameters.Value = "DragFromSources" Then
		AvailableFieldsAdd(Undefined);
	EndIf;
EndProcedure

&AtClient
Procedure AvailableFieldsAddNew(Command)
	If LastPage = "TablesAndFieldsPage" Then
		SetPageState("GroupingPage", True);
		FillPagesAtClient();
	EndIf;
	ExpressionChange(True,,True);
EndProcedure

&AtClient
Procedure AvailableFieldsChange(Command)
	If LastPage = "TablesAndFieldsPage" Then
		SetPageState("GroupingPage", True);
		FillPagesAtClient();
	EndIf;
	ExpressionChange(False);
EndProcedure

&AtClient
Procedure ExpressionChange(Val IsExpression, Val NewExpression = Undefined, Val IsExpressionChanged = Undefined)
	Var CurrentRow;
	Var CurrentItems;
	Var Parent;
	Var Params;
	Var Expression;
	Var Notification;

	Expression = "";
	Params = New Structure;
	If NOT(IsExpression) Then
		CurrentRow = Items.AvailableFields.CurrentRow;
		If (CurrentRow = Undefined) Then
			Return;
		EndIf;
		CurrentItems = AvailableFields.FindByID(CurrentRow);

		Expression = CurrentItems["FullFieldPresentation"];
		Parent = CurrentItems.GetParent();
		If Parent <> Undefined Then
			Params.Insert("ParentIndex", Parent["Index"]);
		Else
			Params.Insert("ParentIndex", -1);
		EndIf;
		Params.Insert("Index", CurrentItems["Index"]);
	EndIf;

	If NewExpression <> Undefined Then
		Expression = NewExpression;
	EndIf;

	Params.Insert("Expression", Expression);
	Params.Insert("IsNew", IsExpression);
	If IsExpressionChanged <> Undefined Then
		Params.Insert("Changed", IsExpressionChanged);
	Else
		Params.Insert("Changed", False);
	EndIf;                           
	
	SaveAllFieldsForGroupingToTempStorage();	
	Params.Insert("FieldsAddress", AllFieldsForGroupingAddress);
	
	Params.Insert("QueryWizardAddress", QueryWizardAddress);
	Params.Insert("CurrentQuerySchemaSelectQuery", CurrentQuerySchemaSelectQuery);
	Params.Insert("CurrentQuerySchemaOperator", CurrentQuerySchemaOperator);
	Params.Insert("NestedQueryPositionAddress", NestedQueryPositionAddress);
	// ITK1 + {
	ИдентификаторВнешнихИсточников = ИТК_КонструкторЗапросовКлиентСервер.ИдентификаторЗначенийВнешнихИсточников();
	Params.Insert(ИдентификаторВнешнихИсточников, ЭтотОбъект.Object[ИдентификаторВнешнихИсточников]);
	// }
	Notification = New NotifyDescription("ExpressionChanged", ThisForm, Params);
    OpenForm("DataProcessor.ИТК_QueryWizard15.Form.ArbitraryExpression", Params, ThisForm,,,,Notification,
             FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure GetErrorTextBounds(StartRow, StartCol, Val ErrorText)
	Var Text;
	Var Pos;

	Text = Mid(ErrorText, 0, Find(ErrorText, ")") - 1);
	Text = StrReplace(Text, "{(", "");
	Pos = Find(Text, ",");
	StartRow = -1;
	StartCol = -1;
	Try
		StartRow = Number(Mid(Text, 0, Pos));
		StartCol = Number(Mid(Text, Pos + 1, StrLen(Text)));
	Except
		StartRow = -1;
		StartCol = -1;
	EndTry;
EndProcedure

&AtClient
Procedure ExpressionChanged(Val ChildForm, Val Params) Export
	Var Expression;
	Var PagesItems;
	Var StartCol;
	Var StartRow;

	If ChildForm = Undefined Then
		Return;
	EndIf;

	If Params["Changed"] Then
		SetPageState("AvailableFieldsPage", True);
		PagesItems = PreFillAtClient();

		If Params["IsNew"] Then
			Expression = Params["Expression"];
			ChangeExpression(PagesItems, Expression);
		Else
			ChangeExpression(PagesItems, Params["Expression"], Params["Index"], Params["ParentIndex"]);
		EndIf;

		If ExpressionChangeError <> "" Then
			StartRow = -1;
			StartCol = -1;
			GetErrorTextBounds(StartRow, StartCol, ExpressionChangeError);
			ChildForm.SetTextSelectionBounds(StartRow, StartCol);
			AddErrorMessage(ExpressionChangeError);
			ShowErrorMessage();
		Else
			ChildForm.Closing = True;
			ChildForm.Close();
			PostFillAtClient(PagesItems);
		EndIf;
	Else
		ChildForm.Closing = True;
		ChildForm.Close();
	EndIf;
EndProcedure

&AtServer
Procedure ChangeExpression(Val PagesItems, Val Expression, Val Index = Undefined, Val ParentIndex = Undefined)
	Var QuerySchema;
	Var Query;
	Var Operators;
	Var Operator;

	ExpressionChangeError = "";
	QuerySchema = GetFromTempStorage(QueryWizardAddress);
	If QuerySchema = Undefined Then
		Return;
	EndIf;

	Batch = QuerySchema.QueryBatch;
	Query = GetSchemaQuery(QuerySchema, CurrentQuerySchemaSelectQuery, NestedQueryPositionAddress);

	If TypeOf(Query) = Type("QuerySchemaTableDropQuery") Then
		Return;
	EndIf;

	Operators  = Query.Operators;
	Operator = Operators.Get(CurrentQuerySchemaOperator);

	Try
		If Index = Undefined Then
			AddExpressionAtServer(Expression, Operator);
		Else
			ChangeExpressionAtServer(ParentIndex, Index, Expression, Operator);
		EndIf;
		FillPagesAtServer(PagesItems);
	Except
		ExpressionChangeError = BriefErrorDescription(ErrorInfo());
	EndTry;
	
	PutToTempStorage(QuerySchema, QueryWizardAddress);	
EndProcedure

&AtClient
Procedure ChangeAdditionallyPageControlsSatate()
	Var LockTables;
	Var LockSelectingRecords;

	If NOT(AdditionallyFirst) Then
		If Items.AdditionallyFirstCount.Enabled Then
			Items.AdditionallyFirstCount.Enabled = False;
		EndIf;
	Else
		If NOT(Items.AdditionallyFirstCount.Enabled) Then
			Items.AdditionallyFirstCount.Enabled = True;
		EndIf;
	EndIf;

	LockTables = True;
	LockSelectingRecords = False;
	If NOT(LockingData) Then
		LockTables = True;
	Else
		LockTables = False;
	EndIf;

	If QueryType = 0 Then
		LockSelectingRecords = False;
		If Items.TempTableName.Enabled Then
			Items.TempTableName.Enabled = False;
		EndIf;
	ElsIf QueryType = 1 Then
		LockSelectingRecords = False;
		If NOT(Items.TempTableName.Enabled) Then
			Items.TempTableName.Enabled = True;
		EndIf;
	EndIf;

	If NOT(LockTables) Then
		If NOT(Items.AdditionallyTables.Enabled) Then
			Items.AdditionallyTables.Enabled = True;
		EndIf;
		If NOT(Items.AdditionallyTablesForChanging.Enabled) Then
			Items.AdditionallyTablesForChanging.Enabled = True;
		EndIf;

		If NOT(Items.AdditionallyAdd.Enabled) Then
			Items.AdditionallyAdd.Enabled = True;
		EndIf;
		If NOT(Items.AdditionallyAddAll.Enabled) Then
			Items.AdditionallyAddAll.Enabled = True;
		EndIf;
		If NOT(Items.AdditionallyDelete.Enabled) Then
			Items.AdditionallyDelete.Enabled = True;
		EndIf;
		If NOT(Items.AdditionallyDeleteAll.Enabled) Then
			Items.AdditionallyDeleteAll.Enabled = True;
		EndIf;
	Else
		If Items.AdditionallyTables.Enabled Then
			Items.AdditionallyTables.Enabled = False;
		EndIf;
		If Items.AdditionallyTablesForChanging.Enabled Then
			Items.AdditionallyTablesForChanging.Enabled = False;
		EndIf;

		If Items.AdditionallyAdd.Enabled Then
			Items.AdditionallyAdd.Enabled = False;
		EndIf;
		If Items.AdditionallyAddAll.Enabled Then
			Items.AdditionallyAddAll.Enabled = False;
		EndIf;
		If Items.AdditionallyDelete.Enabled Then
			Items.AdditionallyDelete.Enabled = False;
		EndIf;
		If Items.AdditionallyDeleteAll.Enabled Then
			Items.AdditionallyDeleteAll.Enabled = False;
		EndIf;
	EndIf;

	If LockSelectingRecords Then
		If Items.AdditionallyFirst.Enabled Then
			Items.AdditionallyFirst.Enabled = False;
		EndIf;
		If Items.AdditionallyWithoutDuplicate.Enabled Then
			Items.AdditionallyWithoutDuplicate.Enabled = False;
		EndIf;
		If Items.AdditionallyPermitted.Enabled Then
			Items.AdditionallyPermitted.Enabled = False;
		EndIf;
		If Items.LockingData.Enabled Then
			Items.LockingData.Enabled = False;
		EndIf;
		If Items.AdditionallyFirstCount.Enabled Then
			Items.AdditionallyFirstCount.Enabled = False;
		EndIf;
	Else
		If NOT(Items.AdditionallyFirst.Enabled) Then
			Items.AdditionallyFirst.Enabled = True;
		EndIf;
		If NOT(Items.AdditionallyWithoutDuplicate.Enabled) Then
			Items.AdditionallyWithoutDuplicate.Enabled = True;
		EndIf;
		If NOT(Items.AdditionallyPermitted.Enabled) Then
			Items.AdditionallyPermitted.Enabled = True;
		EndIf;
		If NOT(Items.LockingData.Enabled) Then
			Items.LockingData.Enabled = True;
		EndIf;
	EndIf;

	If IsNestedQuery Then
		If Items.QueryType.Enabled Then
			Items.QueryType.Enabled = False;
		EndIf;

		If Items.QueryType.Enabled Then
			Items.QueryType.Enabled = False;
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure AdditionallyDelete(Command)
	Var CurrentRow;
	Var CurrentItems;

	FixChanges();

	CurrentRow = Items.AdditionallyTablesForChanging.CurrentRow;
	If (CurrentRow = Undefined) Then
		Return;
	EndIf;
	CurrentItems = AdditionallyTablesForChanging.FindByID(CurrentRow);
	ChangeTablesForChangeAtCache(2, CurrentItems["Index"]);
	SetPageState("AdditionallyTablesPage", True);
	FillPagesAtClient();
EndProcedure

&AtClient
Procedure AdditionallyDeleteAll(Command)
	FixChanges();

	ChangeTablesForChangeAtCache(3);
	SetPageState("AdditionallyTablesPage", True);
	FillPagesAtClient();
EndProcedure

&AtClient
Procedure AdditionallyAdd(Command)
	Var CurrentRow;
	Var CurrentItems;

	CurrentRow = Items.AdditionallyTables.CurrentRow;
	If (CurrentRow = Undefined) Then
		Return;
	EndIf;
	FixChanges();

	CurrentItems = AdditionallyTables.FindByID(CurrentRow);
	ChangeTablesForChangeAtCache(1,CurrentItems["Index"]);
	SetPageState("AdditionallyTablesPage", True);
	FillPagesAtClient();
EndProcedure

&AtClient
Procedure AdditionallyAddAll(Command)
	Var Count;
	Var Pos;

	FixChanges();

	Count = AdditionallyTables.GetItems().Count();
	For Pos = 0 To Count - 1 Do
		ChangeTablesForChangeAtCache(1, AdditionallyTables.GetItems().Get(Pos)["Index"]);
	EndDo;
	SetPageState("AdditionallyTablesPage", True);
	FillPagesAtClient();
EndProcedure

&AtClient
Procedure QueryTypeOnChange(Item)
	Var State;
	Var TempTableNameTmp;
	Var N;

	If QueryType = 1 Then
		TempTableNameTmp = TemporaryTableDefaultName;
		N = 0;
		State = True;
		While State Do
			For Each Item In Items.CurrentQuerySchemaSelectQuery.ChoiceList Do
				If Item.Presentation <> TempTableNameTmp Then
					State = False;
				Else
					State = True;
					N = N + 1;
					Break;
				EndIf;
			EndDo;
			If State Then
				TempTableNameTmp = TemporaryTableDefaultName + String(N);
			EndIf;
		EndDo;
	EndIf;
	TempTableName = TempTableNameTmp;
	ChangeAdditionallyPageControlsSatate();
	SetPageState("AdditionallyItemsPage", True);
	// ITK19 + {
	QueryOnCurrentPageChange(Элементы.Query, Элементы.Query.ТекущаяСтраница);
	// }
	// ITK 48 + {
	ИТК_КонструкторЗапросовКлиент.ПослеПереключенияТипаЗапроса(ЭтотОбъект);
	// }
EndProcedure

&AtClient
Procedure LockingDataOnChange(Item)
	ChangeAdditionallyPageControlsSatate();
	SetPageState("AdditionallyItemsPage", True);
EndProcedure

&AtClient
Procedure AdditionallyFirstOnChange(Item)
	ChangeAdditionallyPageControlsSatate();

	HidePagesServer();

	SetPageState("AdditionallyItemsPage", True);
EndProcedure

&AtClient
Procedure AdditionallyFirstCountOnChange(Item)
	SetPageState("AdditionallyItemsPage", True);
EndProcedure

&AtClient
Procedure AdditionallyWithoutDuplicateOnChange(Item)
	SetPageState("AdditionallyItemsPage", True);
EndProcedure

&AtClient
Procedure AdditionallyPermittedOnChange(Item)
	SetPageState("AdditionallyItemsPage", True);
EndProcedure

&AtClient
Procedure TempTableNameOnChange(Item)
	SetPageState("AdditionallyItemsPage", True);
EndProcedure

&AtClient
Procedure AdditionallyTablesDragStart(Item, DragParameters, Perform)
	DragParameters.AllowedActions = DragAllowedActions.Copy;
	DragParameters.Value = "DragFromAdditionallyTables";
EndProcedure

&AtClient
Procedure AdditionallyTablesForChangingDragCheck(Item, DragParameters, StandardProcessing, Row, Field)
	If DragParameters.Value = "DragFromAdditionallyTables" Then
		StandardProcessing = False;
	EndIf;
EndProcedure

&AtClient
Procedure AdditionallyTablesForChangingDrag(Item, DragParameters, StandardProcessing, Row, Field)
	StandardProcessing = False;
	If DragParameters.Value = "DragFromAdditionallyTables" Then
		AdditionallyAdd(Undefined);
	EndIf;
EndProcedure

&AtClient
Procedure AdditionallyTablesForChangingDragStart(Item, DragParameters, Perform)
	DragParameters.AllowedActions = DragAllowedActions.Copy;
	DragParameters.Value = "DragFromAdditionallyTablesForChanging";
EndProcedure

&AtClient
Procedure AdditionallyTablesDragCheck(Item, DragParameters, StandardProcessing, Row, Field)
	If DragParameters.Value = "DragFromAdditionallyTablesForChanging" Then
		StandardProcessing = False;
	EndIf;
EndProcedure

&AtClient
Procedure AdditionallyTablesDrag(Item, DragParameters, StandardProcessing, Row, Field)
	StandardProcessing = False;
	If DragParameters.Value = "DragFromAdditionallyTablesForChanging" Then
		AdditionallyDelete(Undefined);
	EndIf;
EndProcedure

&AtClient
Procedure SourcesRemoveTheCurrent(Command)
	SourcesDelete(Undefined);
EndProcedure

&AtClient
Procedure SourcesParametersOfTheVirtualTable(Command)
	Var CurrentRow;
	Var CurrentItems;
	Var Params;
	Var Notification;

	FixChanges();
	FillPagesAtClient();

	CurrentRow = Items.Sources.CurrentRow;
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	CurrentItems = Sources.FindByID(CurrentRow);

	If CurrentItems["Type"] <> 1 Then
		Return;
	EndIf;
	Params = New Structure;
	Params.Insert("Index", CurrentItems["Index"]);
	Params.Insert("QueryWizardAddress", QueryWizardAddress);
	Params.Insert("CurrentQuerySchemaSelectQuery", CurrentQuerySchemaSelectQuery);
	Params.Insert("CurrentQuerySchemaOperator", CurrentQuerySchemaOperator);
	Params.Insert("NestedQueryPositionAddress", NestedQueryPositionAddress);
	// ITK1 + {
	ИдентификаторВнешнихИсточников = ИТК_КонструкторЗапросовКлиентСервер.ИдентификаторЗначенийВнешнихИсточников();
	Params.Insert(ИдентификаторВнешнихИсточников, ЭтотОбъект.Object[ИдентификаторВнешнихИсточников]);
	// }
	Notification = New NotifyDescription("TableParametersChanged", ThisForm, Params);
	OpenForm("DataProcessor.ИТК_QueryWizard15.Form.AvailableTableParameters", Params, ThisForm,,,,Notification,
             FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure TableParametersChanged(Result, Params) Export
	SetPageState("SourcesPage", True);
	SetPageState("AvailableFieldsPage", True);
	FillPagesAtClient();
EndProcedure

&AtClient
Procedure SourcesOnActivateRow(Item)
	Var CurrentRow;
	Var CurrentItems;

	CurrentRow = Items.Sources.CurrentRow;
	If CurrentRow = Undefined Then
		Items.SourcesSourcesChangeTheCurrentItem.Enabled = False;
		Items.SourcesSourcesParametersOfTheVirtualTable.Enabled = False;
		Items.SourcesSourcesRemoveTheCurrent.Enabled = False;
		Items.SourcesSourcesReplaceTheTable.Enabled = False;
		Return;
	EndIf;
	CurrentItems = Sources.FindByID(CurrentRow);
	If CurrentItems = Undefined Then
		Return;
	EndIf;

	If CurrentItems["ValueType"] = "QuerySchemaTable" Then
		// ITK 47 * {
		//Items.SourcesSourcesChangeTheCurrentItem.Enabled = False;
		Items.SourcesSourcesChangeTheCurrentItem.Enabled = (СтрНайти(CurrentItems["TableName"], ".") = 0);
		// ITK 47 }
		Items.SourcesSourcesParametersOfTheVirtualTable.Enabled = False;
		Items.SourcesSourcesRemoveTheCurrent.Enabled = True;
		Items.SourcesSourcesReplaceTheTable.Enabled = True;
		Items.SourcesRenameSource.Enabled = True;
		If CurrentItems["ParametersCount"] > 0 Then
			Items.SourcesSourcesParametersOfTheVirtualTable.Enabled = True;
		EndIf;
	ElsIf CurrentItems["ValueType"] = "QuerySchemaNestedQuery" Then
		Items.SourcesSourcesChangeTheCurrentItem.Enabled = True;
		Items.SourcesSourcesParametersOfTheVirtualTable.Enabled = False;
		Items.SourcesSourcesRemoveTheCurrent.Enabled = True;
		Items.SourcesSourcesReplaceTheTable.Enabled = True;
		Items.SourcesRenameSource.Enabled = True;
	ElsIf CurrentItems["ValueType"] = "QuerySchemaTempTableDescription" Then
		Items.SourcesSourcesChangeTheCurrentItem.Enabled = True;
		Items.SourcesSourcesParametersOfTheVirtualTable.Enabled = False;
		Items.SourcesSourcesRemoveTheCurrent.Enabled = True;
		Items.SourcesSourcesReplaceTheTable.Enabled = True;
		Items.SourcesRenameSource.Enabled = True;
	Else
		Items.SourcesSourcesChangeTheCurrentItem.Enabled = False;
		Items.SourcesSourcesParametersOfTheVirtualTable.Enabled = False;
		Items.SourcesSourcesRemoveTheCurrent.Enabled = False;
		Items.SourcesSourcesReplaceTheTable.Enabled = False;
		Items.SourcesRenameSource.Enabled = False;
	EndIf;
EndProcedure

&AtClient
Procedure SourcesCreateDescriptionOfTheTemporaryTable(Command)
	Var Params;
	Var Notification;

	FixChanges();
	FillPagesAtClient();

	Params = New Structure;
	Params.Insert("Index", -1);
	Params.Insert("QueryWizardAddress", QueryWizardAddress);
	Params.Insert("CurrentQuerySchemaSelectQuery", CurrentQuerySchemaSelectQuery);
	Params.Insert("CurrentQuerySchemaOperator", CurrentQuerySchemaOperator);
	Params.Insert("NestedQueryPositionAddress", NestedQueryPositionAddress);
	Notification = New NotifyDescription("TableParametersChanged", ThisForm, Params);
	OpenForm("DataProcessor.ИТК_QueryWizard15.Form.TempTable", Params, ThisForm,,,,Notification,
             FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtServer
Function GetNestedQueryText(SourceIndex)
	Var Batch;
	Var Query;
	Var Operator;
	Var QuerySchema;
	Var Source;
	
	QuerySchema = GetFromTempStorage(QueryWizardAddress);
	If QuerySchema = Undefined Then
		Return "";
	EndIf;

	Batch = QuerySchema.QueryBatch;
	Query = GetSchemaQuery(QuerySchema, CurrentQuerySchemaSelectQuery, NestedQueryPositionAddress);
	Operator = Query.Operators[CurrentQuerySchemaOperator];

	Source = Operator.Sources[SourceIndex];
	If (TypeOf(Source.Source) <> Type("QuerySchemaNestedQuery")) 
		OR (TypeOf(Source.Source.Query) <> Type("QuerySchemaSelectQuery")) Then
		Return "";
	EndIf;	
	
	Return Source.Source.Query.GetQueryText();				
EndFunction

&AtClient
Procedure SourcesChangeTheCurrentItem(Command)
	Var CurrentRow;
	Var CurrentItems;
	Var Params;
	Var Notification;
	Var Source; 
	Var QueryText;
	
	FillPagesAtClient();

	CurrentRow = Items.Sources.CurrentRow;
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	CurrentItems = Sources.FindByID(CurrentRow);

	If CurrentItems["ValueType"] = "QuerySchemaNestedQuery" Then		
		QueryText = GetQuerySchemaText(QueryWizardAddress);	
		EditNestedQuery("SetNestedQuery", CurrentItems["Index"], False, QueryText);
	// ITK 47 + {
	ElsIf CurrentItems["ValueType"] = "QuerySchemaTable" Then
		
		FixChanges();
		
		ЭлементВременнаяТаблица = ИТК_ОбщийКлиентСервер.СписокЗначенийНайтиПоПредставлению(
			Элементы.CurrentQuerySchemaSelectQuery.СписокВыбора, CurrentItems.TableName);
		CurrentQuerySchemaSelectQuery = ЭлементВременнаяТаблица.Значение;
		
		CurrentQuerySchemaOperator = 0;
		CurrentQuerySchemaOperatorOnChange(Undefined);
		
		FillPagesAtClient();
	// ITK 47 }
	ElsIf CurrentItems["ValueType"] = "QuerySchemaTempTableDescription" Then
		Params = New Structure;
		Params.Insert("Index", CurrentItems["Index"]);
		Params.Insert("QueryWizardAddress", QueryWizardAddress);
		Params.Insert("CurrentQuerySchemaSelectQuery", CurrentQuerySchemaSelectQuery);
		Params.Insert("CurrentQuerySchemaOperator", CurrentQuerySchemaOperator);
		Params.Insert("NestedQueryPositionAddress", NestedQueryPositionAddress);	
		Notification = New NotifyDescription("TableParametersChanged", ThisForm, Params);
		OpenForm("DataProcessor.ИТК_QueryWizard15.Form.TempTable", Params, ThisForm,,,,Notification,
                 FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
EndProcedure

&AtServer
Procedure AvailableTablesBeforeExpandAtServer(Val Row, 
											  Val AvailableTablesTree = Undefined, 
											  Val Lavel = 1, 
											  MainObject = Undefined,
                                              Query = Undefined) Export
	Var QuerySchema;
	Var QueryT;
	Var MainObjectT;

	If MainObject = Undefined Then
		MainObjectT = FormAttributeToValue("Object");

		QuerySchema = GetFromTempStorage(QueryWizardAddress);
		If QuerySchema = Undefined Then
			Return;
		EndIf;
		Batch = QuerySchema.QueryBatch;
		QueryT = GetSchemaQuery(QuerySchema, CurrentQuerySchemaSelectQuery, NestedQueryPositionAddress);
		MainObjectT.AvailableTablesBeforeExpandAtServer(QueryWizardAddress, CurrentQuerySchemaSelectQuery,                                                        
													    NestedQueryPositionAddress, Row, AvailableTables, Lavel,
                                                        Items.AvailableTablesDisplayChangesTable.Check,
                                                        SourcesImagesCacheAddress, ExpressionsImagesCacheAddress,
	                                                    QueryT);
	Else
		MainObject.AvailableTablesBeforeExpandAtServer(QueryWizardAddress, CurrentQuerySchemaSelectQuery,                                                       
		                                               NestedQueryPositionAddress, Row, AvailableTables, Lavel,
                                                       Items.AvailableTablesDisplayChangesTable.Check,
                                                       SourcesImagesCacheAddress, ExpressionsImagesCacheAddress,
	                                                   Query);
	EndIf;
EndProcedure

&AtClient
Procedure AvailableTablesBeforeExpand(Item, Row, Cancel)
	Var CurrentItems;

	CurrentItems = AvailableTables.FindByID(Row);
	If NOT(IsFakeItem(CurrentItems)) Then
	    Return;
	EndIf;
	Cancel = True;	
	RowForExpand = Row;
	AttachIdleHandler("AvailableTablesBeforeExpandHandler", 0.01, True);	
EndProcedure

&AtClient
Procedure AvailableTablesBeforeExpandHandler()
	AvailableTablesBeforeExpandAtServer(RowForExpand);
	Items.AvailableTables.Expand(RowForExpand);
	// ITK 41 + {
	ИТК_КонструкторЗапросовКлиент.АктивацияСтрокиДоступнойТаблицы(ЭтотОбъект, RowForExpand);
	// }
EndProcedure

&AtClient
Procedure SourcesBeforeExpand(Item, Row, Cancel)
	Var CurrentItems;

	CurrentItems = Sources.FindByID(Row);
	If NOT(IsFakeItem(CurrentItems)) Then
	    Return;
	EndIf;
	Cancel = True;	
	RowForExpand = Row;
	AttachIdleHandler("SourcesBeforeExpandHandler", 0.01, True);	
EndProcedure

&AtClient
Procedure SourcesBeforeExpandHandler()
	SourcesBeforeExpandAtServer(RowForExpand);
	Items.Sources.Expand(RowForExpand);
EndProcedure

&AtServer
Procedure SourcesBeforeExpandAtServer(Val Row, 
									  Val SourcesTree = Undefined, 
									  Val Lavel = 1, 
									  MainObject = Undefined, 
									  Query = Undefined) Export
	Var Src;
	Var QuerySchema;
	Var QueryT;
	Var MainObjectT;

	If SourcesTree = Undefined Then
		Src = Sources;
	Else
		Src = SourcesTree;
	EndIf;

	If  (MainObject <> Undefined) AND (Query <> Undefined) Then
		FillSourcesBeforeExpand(Row, Src, Lavel, MainObject, Query);
	Else
		MainObjectT = FormAttributeToValue("Object");

		QuerySchema = GetFromTempStorage(QueryWizardAddress);
		If QuerySchema = Undefined Then
			Return;
		EndIf;
		Batch = QuerySchema.QueryBatch;
		QueryT = GetSchemaQuery(QuerySchema, CurrentQuerySchemaSelectQuery, NestedQueryPositionAddress);

		FillSourcesBeforeExpand(Row, Src, Lavel, MainObjectT, QueryT);
	EndIf;
EndProcedure

&AtServer
Procedure FillSourcesBeforeExpand(Val Row, 
								  Val SourcesTree, 
								  Val Lavel = 1, 
								  MainObject = Undefined, 
								  Query = Undefined)
	Var QuerySchema;

	If MainObject = Undefined Then
		MainObject = FormAttributeToValue("Object");

		QuerySchema = GetFromTempStorage(QueryWizardAddress);
		If QuerySchema = Undefined Then
			Return;
		EndIf;
		Batch = QuerySchema.QueryBatch;
		Query = GetSchemaQuery(QuerySchema, CurrentQuerySchemaSelectQuery, NestedQueryPositionAddress);
	EndIf;

	MainObject.SourcesBeforeExpandAtServer(QueryWizardAddress, CurrentQuerySchemaSelectQuery,
                                           CurrentQuerySchemaOperator, NestedQueryPositionAddress, Row, SourcesTree, Lavel,
                                           SourcesImagesCacheAddress, ExpressionsImagesCacheAddress, Query);
EndProcedure

&AtClient
Procedure AllFieldsForGroupingBeforeExpand(Item, Row, Cancel)
	Var CurrentItems;

	CurrentItems = AllFieldsForGrouping.FindByID(Row);
	If CurrentItems["AvailableField"]
		OR (CurrentItems["Type"] < 0)
		OR NOT(IsFakeItem(CurrentItems)) Then
		Return;
	EndIf;
	
	Cancel = True;
	RowForExpand = Row;
	AttachIdleHandler("AllFieldsForGroupingBeforeExpandHandler", 0.01, True);
EndProcedure

&AtClient
Procedure AllFieldsForGroupingBeforeExpandHandler()
	AllFieldsForGroupingBeforeExpandAtServer();
	Items.AllFieldsForGrouping.Expand(RowForExpand);
EndProcedure

&AtServer
Procedure AllFieldsForGroupingBeforeExpandAtServer()
	FillSourcesBeforeExpand(RowForExpand, AllFieldsForGrouping);	
EndProcedure

&AtClient
Procedure AllFieldsForConditionsBeforeExpand(Item, Row, Cancel)
	Var CurrentItems;

	CurrentItems = AllFieldsForConditions.FindByID(Row);
	If NOT(IsFakeItem(CurrentItems)) Then
	    Return;
	EndIf;
	Cancel = True;
	RowForExpand = Row;
	AttachIdleHandler("AllFieldsForConditionsBeforeExpandHandler", 0.01, True);
EndProcedure

&AtClient
Procedure AllFieldsForConditionsBeforeExpandHandler()
	AllFieldsForConditionsBeforeExpandAtServer();
	Items.AllFieldsForConditions.Expand(RowForExpand);
EndProcedure

&AtServer
Procedure AllFieldsForConditionsBeforeExpandAtServer()
	FillSourcesBeforeExpand(RowForExpand, AllFieldsForConditions);
EndProcedure

&AtClient
Procedure AllFieldsForIndexBeforeExpand(Item, Row, Cancel)
	Var CurrentItems;

	CurrentItems = AllFieldsForIndex.FindByID(Row);
	If (CurrentItems["Name"] = "")
		OR (CurrentItems["Type"] < 0)
		OR (NOT(IsFakeItem(CurrentItems))) Then
		Return;
	EndIf;
	
	Cancel = True;
	RowForExpand = Row;
	AttachIdleHandler("AllFieldsForIndexBeforeExpandHandler", 0.01, True);
EndProcedure

&AtClient
Procedure AllFieldsForIndexBeforeExpandHandler()
	AllFieldsForIndexBeforeExpandAtServer(RowForExpand);
	Items.AllFieldsForIndex.Expand(RowForExpand);
EndProcedure

&AtServer
Procedure AllFieldsForIndexBeforeExpandAtServer(Row)
	FillSourcesBeforeExpand(Row, AllFieldsForIndex);
EndProcedure

&AtClient
Procedure AllFieldsForOrderBeforeExpand(Item, Row, Cancel)
	Var CurrentItems;

	CurrentItems = AllFieldsForOrder.FindByID(Row);
	If (CurrentItems["Name"] = "")
		OR (CurrentItems["Type"] < 0)
		OR (NOT(IsFakeItem(CurrentItems))) Then
		Return;
	EndIf;
	
	Cancel = True;
	RowForExpand = Row;
	AttachIdleHandler("AllFieldsForOrderBeforeExpandHandler", 0.01, True);
EndProcedure

&AtClient
Procedure AllFieldsForOrderBeforeExpandHandler()
	AllFieldsForOrderBeforeExpandAtServer(RowForExpand);
	Items.AllFieldsForOrder.Expand(RowForExpand);
EndProcedure

&AtServer
Procedure AllFieldsForOrderBeforeExpandAtServer(Row)
	FillSourcesBeforeExpand(Row, AllFieldsForOrder);
EndProcedure

&AtClient
Procedure AllFieldsForTotalsBeforeExpand(Item, Row, Cancel)
	Var CurrentItems;

	CurrentItems = AllFieldsForTotals.FindByID(Row);
	If CurrentItems["IsAlias"]
		OR (CurrentItems["Type"] < 0)
		OR (NOT(IsFakeItem(CurrentItems))) Then
		Return;
	EndIf;
	Cancel = True;
	RowForExpand = Row;
	AttachIdleHandler("AllFieldsForTotalsBeforeExpandHandler", 0.01, True);
EndProcedure

&AtClient
Procedure AllFieldsForTotalsBeforeExpandHandler()
	AllFieldsForTotalsBeforeExpandAtServer(RowForExpand);
	Items.AllFieldsForTotals.Expand(RowForExpand);
EndProcedure

&AtServer
Procedure AllFieldsForTotalsBeforeExpandAtServer(Row)
	FillSourcesBeforeExpand(Row, AllFieldsForTotals);
EndProcedure

&AtClient
Procedure DropTableNameOnChange(Item)
	SetPageState("DropTablePage", True);
EndProcedure

&AtClient
Procedure NewDropTableQuery(Command)
	Var NewItem;
	Var Count;
	Var Pos;
	Var Item;

	NewItem = QueryBatch.Add();
	NewQueryBatchCount = NewQueryBatchCount + 1;
	NewItem["Name"] = "* " + NStr("ru = 'Новый пакет';
									|SYS = 'QueryEditor.NewBatch'", "ru") + " " + NewQueryBatchCount;

	Count = QueryBatch.Count();
	For Pos = 0 To Count - 1 Do
	    Item = QueryBatch.Get(Pos);
		Item["Index"] = Pos;
	EndDo;

	ChangeQueryBatchAtCache(-1, 5);
	SetPageState("QueryBatchPage", True);

	For Each Item In AvailableTables.GetItems() Do
		Items.AvailableTables.Collapse(Item.GetID());
	EndDo;

	InvalidateAllPages(True);
	FillPagesAtClient();
	SetCurrentTab();
EndProcedure

&AtClient
Procedure EditNestedQuery(Val NotificationName, Val NestedQuerySourceIndex, Val IsNew, Val QueryText = Undefined)
	Var Params;
	Var Notification;
	Var NestedQueryPosition;
	Var Address;
	
	If TypeOf(NestedQueryPositionAddress) = Type("String")  Then
		NestedQueryPosition = GetFromTempStorage(NestedQueryPositionAddress);    			
	Else
		NestedQueryPosition = New Array();
	EndIf; 
	
	NestedQueryPosition.Add(CurrentQuerySchemaOperator); 
	NestedQueryPosition.Add(NestedQuerySourceIndex); 
	Address = PutToTempStorage(NestedQueryPosition, New UUID);
	
	Params = New Structure;
	Params.Insert("NestedQuerySourceIndex", NestedQuerySourceIndex);
	Params.Insert("NestedQueryPositionAddress", Address);
	Params.Insert("IsNestedQuery", True);	
	Params.Insert("IsNewNestedQuery", IsNew);
	Params.Insert("QueryWizardAddress", QueryWizardAddress);	
	Params.Insert("CurrentQuerySchemaSelectQuery", CurrentQuerySchemaSelectQuery);
	Params.Insert("DataCompositionMode", DataCompositionMode);
	If (QueryText <> Undefined) Then
		Params.Insert("OldQueryText", QueryText);	
	EndIf;
	
	Notification = New NotifyDescription(NotificationName, ThisForm, Params);
	
	// ITK1 + {
	ИдентификаторВнешнихИсточников = ИТК_КонструкторЗапросовКлиентСервер.ИдентификаторЗначенийВнешнихИсточников();
	Params.Insert(ИдентификаторВнешнихИсточников, ЭтотОбъект.Object[ИдентификаторВнешнихИсточников]);
	// }
	
	OpenForm("DataProcessor.ИТК_QueryWizard15.Form.QueryWizard", Params,, True,,,
		Notification, FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtServer
Function AddNestedQuerySource()
	Var QuerySchema;
	Var Batch; 
	Var Query; 
	Var Operator; 
	Var Source; 
	
	QuerySchema = GetFromTempStorage(QueryWizardAddress);
	If QuerySchema = Undefined Then
		Return Undefined;
	EndIf;

	Batch = QuerySchema.QueryBatch;
	Query = GetSchemaQuery(QuerySchema, CurrentQuerySchemaSelectQuery, NestedQueryPositionAddress);
			
	// Начинаем заполнять
	Operator = Query.Operators[CurrentQuerySchemaOperator];	
	Source = Operator.Sources.Add(Type("QuerySchemaNestedQuery"));
	
	PutToTempStorage(QuerySchema, QueryWizardAddress);

	Return Operator.Sources.IndexOf(Source);
EndFunction

&AtClient
Procedure SourcesCreateNestedQuery(Command)
	FillPagesAtClient();
	EditNestedQuery("SetNestedQuery", AddNestedQuerySource(), True);
EndProcedure

&AtClient
Procedure SetNestedQuery(Result, Params) Export
	Var Notification;

	Try
		SetNestedQueryAtServer(Result, Params);
		SetPageState("SourcesPage", True);
		SetPageState("AvailableFieldsPage", True);
		FillPagesAtClient();
	Except
		AddErrorMessage(BriefErrorDescription(ErrorInfo()));
		ShowErrorMessage();
		Notification = New NotifyDescription("AddNestedQuery", ThisForm, Params);
		OpenForm("DataProcessor.ИТК_QueryWizard15.Form.QueryWizard", Params,, True,,,
			Notification, FormWindowOpeningMode.LockOwnerWindow);
	EndTry;		
EndProcedure

&AtServer
Procedure SetNestedQueryAtServer(Result, Params)
	Var Prop;
	Var QuerySchema;
	Var QuerySource;
	Var Query;
	Var QueryText;
	Var Operator;
	Var Source;
	Var Batch;
	
	DeleteFromTempStorage(Params["NestedQueryPositionAddress"]);
	
	Prop = Undefined;
	Params.Property("NestedQuerySourceIndex", Prop);
	If (Prop <> Undefined) AND (Result = Undefined) Then 		
		// Откатим изменения
		QuerySchema = GetFromTempStorage(QueryWizardAddress);
		If QuerySchema = Undefined Then
			Return;
		EndIf;
		
		Batch = QuerySchema.QueryBatch;
		Query = GetSchemaQuery(QuerySchema, CurrentQuerySchemaSelectQuery, NestedQueryPositionAddress);
		Operator = Query.Operators[CurrentQuerySchemaOperator];
		
		QuerySource = Params["NestedQuerySourceIndex"];
		
		Prop = Undefined;
		Params.Property("IsNewNestedQuery", Prop);
		If (Prop <> Undefined) AND (Params["IsNewNestedQuery"] = True) Then
			Operator.Sources.Delete(QuerySource);	
			Return;
		EndIf;
		
		Source = Operator.Sources[QuerySource];	
		If (TypeOf(Source.Source) <> Type("QuerySchemaNestedQuery")) 
			OR (TypeOf(Source.Source.Query) <> Type("QuerySchemaSelectQuery")) Then
			Return;
		EndIf;
		
		Try
			Prop = Undefined;
			Params.Property("OldQueryText", Prop);
			If Prop <> Undefined Then
				SetQuerySchemaText(Params["OldQueryText"], QueryWizardAddress);
			EndIf; 
		Except
		EndTry;
		
		PutToTempStorage(QuerySchema, QueryWizardAddress);
	EndIf;	
EndProcedure

&AtServer
Function IsQueryHaveNoOneField(Val QueryWizardAddress)
	Var QuerySchema;
	Var QueryBatch;
	Var CurQuery;

	QuerySchema = GetFromTempStorage(QueryWizardAddress);
	If QuerySchema = Undefined Then
		Return False;
	EndIf;
	
	// ITK31 * {
	ТекущийЗапрос = GetSchemaQuery(QuerySchema, CurrentQuerySchemaSelectQuery, NestedQueryPositionAddress);
	Если Тип(ТекущийЗапрос) = Тип("ЗапросУничтоженияТаблицыСхемыЗапроса") Тогда
		Возврат Ложь; 
	КонецЕсли;
	
	Возврат НЕ ЗначениеЗаполнено(ТекущийЗапрос.Колонки); 
	// }
	
	If NOT(IsNestedQuery) Then
		QueryBatch = QuerySchema.QueryBatch;
		For Each CurQuery In QueryBatch Do
			If TypeOf(CurQuery) <> Type("QuerySchemaSelectQuery") Then
				Continue;
			EndIf;

			If CurQuery.Columns.Count() > 0  Then
				Return False;
			EndIf;
		EndDo;
	Else		
		Query = GetSchemaQuery(QuerySchema, CurrentQuerySchemaSelectQuery, NestedQueryPositionAddress);
		If Query.Columns.Count() > 0  Then
			Return False;
		EndIf;
	EndIf; 
	
	Return True;
EndFunction

&AtClient
Procedure  AskQueryEmpty(Result, Params) Export
	If Result = DialogReturnCode.Yes Then
		CheckQueryToEmpty = False;
		IgnoreErrorMessage = True;
		OK(Undefined);
	EndIf;
EndProcedure

&AtClient
Procedure OK(Command)
	Var CheckQuery;
	Var ResultQueryText;
	Var ErrorMessage;
	Var Notification;
	Var Type;
	Var IgnoreError;
	Var IsQueryEmpty;

	FixChanges();
	FillPagesAtClient();
	ResultQueryText = GetQuerySchemaText(QueryWizardAddress);
	CheckQuery = CheckQueryToEmpty;
	CheckQueryToEmpty = True;

	IgnoreError = IgnoreErrorMessage;
	IgnoreErrorMessage = False;

	Try
		IsQueryEmpty = False;
		
		SetQuerySchemaText(ResultQueryText, QueryWizardAddress, True, CheckQuery, IsQueryEmpty);
		
		If CheckQuery AND IsQueryEmpty Then
			Notification = New NotifyDescription("AskQueryEmpty", ThisForm);
			Type = QuestionDialogMode.YesNo;
			ShowQueryBox(Notification, NStr("ru = 'В запросе не выбрано ни одного поля. Игнорировать предупреждение?';
											|SYS = 'QueryEditor.QueryIsEmpty'",                                          
                                            "ru"), Type);
			Return;    					
		EndIf; 
	Except
		ErrorMessage = BriefErrorDescription(ErrorInfo());
		If (ErrorMessage <> "QueryEmpty") AND NOT(IgnoreError) Then
			Notification = New NotifyDescription("AskQueryEmpty", ThisForm);
			Type = QuestionDialogMode.YesNo;
			ShowQueryBox(Notification, ErrorMessage + ". " + NStr("ru = 'Игнорировать предупреждение?';
																	|SYS = 'QueryEditor.IgnoreErrorMessage'",                                                               
                                                                  "ru"), Type);
			Return;
		EndIf;
	EndTry;

	QueryTextOld = ResultQueryText;
	CloseQueryEditor = True;
	ThisForm.Close(ResultQueryText);
EndProcedure

&AtClient
Procedure Cancel(Command)
	Var Prop;

	FillPagesAtClient();

	Prop = Undefined;
	Parameters.Property("QueryText", Prop);
	If Prop <> Undefined Then
		Parameters["QueryText"] = QueryTextOld;
	EndIf;
	QueryTextOld = GetQuerySchemaText(QueryWizardAddress);
	ThisForm.Close();
EndProcedure

&AtClient
Procedure AskWhatToDo(Result, Params) Export
	If Result = DialogReturnCode.OK Then
		CloseQueryEditor = True;
		ThisForm.Close();
		Return;
	EndIf;
	CloseQueryEditor = False;
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, MessageText, StandardProcessing)
	Var Prop;
	Var Notification;
	Var Type;
	
	If Exit = True Then
		// Если происходи закрытие приложения
		// не можем выполнять серверные вызовы
		Cancel = True;
		MessageText = NStr("ru = 'Конструктор запроса будет закрыт';
							|SYS = 'QueryEditor.QueryWizardWillClose'", "ru");
		Return;
	EndIf;
	
	FixChanges();
	FillPagesAtClient();

	If CloseQueryEditor Then
		Cancel = False;
		Return;
	EndIf;

	CloseQueryEditor = False;
	If GetQuerySchemaText(QueryWizardAddress) = QueryTextOld Then
		Prop = Undefined;
		Parameters.Property("QueryText", Prop);
		If Prop <> Undefined Then
			Parameters["QueryText"] = QueryTextOld;
		EndIf;
	Else
		Cancel = True;
		Type = QuestionDialogMode.OKCancel;
		Notification = New NotifyDescription("AskWhatToDo", ThisForm);
		ShowQueryBox(Notification, NStr("ru = 'Запрос был изменен. Закрытие приведет к отмене изменений.';
										|SYS = 'QueryEditor.QueryWasChanged'",                                
                                        "ru"), Type);
	EndIf;
EndProcedure

&AtClient
Procedure AvailableTablesSortList(Command)
	Var Field;

	Items.AvailableTablesAvailableTablesSortList.Check = NOT(Items.AvailableTablesAvailableTablesSortList.Check);
	If Items.AvailableTablesAvailableTablesSortList.Check Then
		Field = "Presentation";
	Else
		Field = "Index";
	EndIf;
	AvailableTablesSortListAtServer(Field);
EndProcedure

&AtServer
Procedure AvailableTablesSortListAtServer(Val Field)
	Var MainObject;
	Var Pos;
	Var Item;

	MainObject = FormAttributeToValue("Object")	;
	AvailableTablesSortListAtServerNoContext(MainObject, AvailableTables.GetItems(), Field);
	For Pos = 0 To Sources.GetItems().Count() - 1 Do
		Item = Sources.GetItems().Get(Pos).GetItems();
		AvailableTablesSortListAtServerNoContext(MainObject, Item, Field);
	EndDo;
EndProcedure

&AtServer
Procedure AvailableTablesSortListAtServerNoContext(MainObject, Val AvailableTables, Val Field = "Presentation")
	Var Pos;
	Var Item;

	qSort(AvailableTables, Field,,, MainObject);
	For Pos = 0 To AvailableTables.Count() - 1 Do
		Item = AvailableTables.Get(Pos).GetItems();
		AvailableTablesSortListAtServerNoContext(MainObject, Item, Field);
	EndDo;
EndProcedure

&AtClient
Procedure AvailableTablesDisplayChangesTable(Command)
	Items.AvailableTablesDisplayChangesTable.Check = NOT(Items.AvailableTablesDisplayChangesTable.Check);
	SetPageState("AvailableTablesPage", True);
	FillPagesAtClient();
EndProcedure

&AtClient
Procedure RenameSource(Command)
	Var CurrentRow;
	Var CurrentItems;
	
	FixChanges();
	FillPagesAtClient();
	
	CurrentRow = Items.Sources.CurrentRow;
	If (CurrentRow = Undefined) Then
		Return;
	EndIf;
	CurrentItems = Sources.FindByID(CurrentRow);

	If CurrentItems["Type"] <> 1 Then
		Return;
	EndIf;

	Items.Sources.ChangeRow();
EndProcedure

&AtClient
Procedure SourcesOnStartEdit(Item, NewRow, Clone)
	If NOT(StartEdit) Then
		TmpString = Item.CurrentData["Presentation"];		
	EndIf; 
	
	StartEdit = True;
EndProcedure

&AtClient
Procedure SourcesBeforeEditEnd(Item, NewRow, CancelEdit, Cancel)
	Var CurrentRow;
	Var CurrentItems;

	If NOT(StartEdit) OR TmpString = Item.CurrentData["Presentation"] Then
		StartEdit = False;
	    Return;
	EndIf;

	CurrentRow = Items.Sources.CurrentRow;
	If (CurrentRow = Undefined) Then
		Return;
	EndIf;

	CurrentItems = Sources.FindByID(CurrentRow);
	If CurrentItems = Undefined Then
		Return;
	EndIf;

	If CancelEdit Then
		CurrentItems["Presentation"] = TmpString;
	EndIf;	
	
	RowForEdit = CurrentRow;
	AttachIdleHandler("SourcesBeforeEditEndHandler", 0.01, True);
EndProcedure

&AtClient
Procedure SourcesBeforeEditEndHandler()	
	If NOT(ChangeSourceName(RowForEdit)) Then
		ShowErrorMessage();
		Items.Sources.CurrentRow = RowForEdit;
		StartEdit = True;
		Items.Sources.ChangeRow();
		Return;
	EndIf;
	
	StartEdit = False;
	
	SetPageState("SourcesPage", True);
	SetPageState("AvailableFieldsPage", True);	
	// ITK 51 + {
	SetPageState("ConditionsPage", True);
	SetPageState("ConditionsFieldsPage", True);
	//}
	FillPagesAtClient();
EndProcedure	

&AtServer
Function ChangeSourceName(Val CurrentRow)
	Var QuerySchema;
	Var Query;
	Var Operators;
	Var CurrentItems;
	Var Index;
	Var Name;
	Var Operator;

	If (CurrentRow = Undefined) Then
		Return True;
	EndIf;
	CurrentItems = Sources.FindByID(CurrentRow);

	QuerySchema = GetFromTempStorage(QueryWizardAddress);
	If QuerySchema = Undefined Then
		Return True;
	EndIf;

	Batch = QuerySchema.QueryBatch;
	Query = GetSchemaQuery(QuerySchema, CurrentQuerySchemaSelectQuery, NestedQueryPositionAddress);

	If TypeOf(Query) = Type("QuerySchemaSelectQuery") Then
		Operators  = Query.Operators;
		Operator = Operators.Get(CurrentQuerySchemaOperator);
	Else
		Return True;
	EndIf;

	Name = CurrentItems["Presentation"];
	Index = CurrentItems["Index"];
	Try
		Operator.Sources.Get(Index).Source.Alias = Name;
	Except
		AddErrorMessageAtServer(BriefErrorDescription(ErrorInfo()));
		Return False;
	EndTry;
	
	PutToTempStorage(QuerySchema, QueryWizardAddress);
	Return True;
EndFunction

&AtClient
Procedure SaveAllFieldsForGroupingToTempStorage()
	If IsChangedForSaveAllFieldsForGrouping Then
		SaveAllFieldsForGroupingToTempStorageAtServer();
	EndIf;
EndProcedure

&AtServer
Procedure SaveAllFieldsForGroupingToTempStorageAtServer()
	PutToTempStorage(FormAttributeToValue("AllFieldsForGrouping"), AllFieldsForGroupingAddress);
	IsChangedForSaveAllFieldsForGrouping = False;
EndProcedure

&AtClient
Procedure SaveAvailableTablesToTempStorage()
	If IsChangedForSaveAvailableTables Then
		SaveAvailableTablesToTempStorageAtServer();
	EndIf;
EndProcedure

&AtServer
Procedure SaveAvailableTablesToTempStorageAtServer()
	PutToTempStorage(FormAttributeToValue("AvailableTables"), AvailableTablesAddress);
	IsChangedForSaveAvailableTables = False;
EndProcedure

&AtClient
Procedure SourcesReplaceTheTable(Command)
	Var CurrentRow;
	Var CurrentItems;
	Var Params;
	Var Notification;

	CurrentRow = Items.Sources.CurrentRow;
	If (CurrentRow = Undefined) Then
		Return;
	EndIf;
	CurrentItems = Sources.FindByID(CurrentRow);

	If CurrentItems["Type"] <> 1 Then
		Return;
	EndIf;

	FixChanges();
	FillPagesAtClient();

	CurrentRow = Items.Sources.CurrentRow;
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	SaveAvailableTablesToTempStorage();	
	
	Params = New Structure;
	Params.Insert("FormMode", "ReplaceTabmeMode");
	Params.Insert("AvailableTablesAddress", AvailableTablesAddress);
	Params.Insert("ItemIndexes", "");
	Params.Insert("StartTableName", CurrentItems["TableName"]);
	Params.Insert("TableIndex", CurrentRow);     
	Params.Insert("DisplayChangesTables", Items.AvailableTablesDisplayChangesTable.Check);
	Params.Insert("QueryWizardAddress", QueryWizardAddress);
	Params.Insert("CurrentQuerySchemaSelectQuery", CurrentQuerySchemaSelectQuery);
	Params.Insert("SourcesImagesCacheAddress", SourcesImagesCacheAddress);
	Params.Insert("ExpressionsImagesCacheAddress", ExpressionsImagesCacheAddress);
	Params.Insert("NestedQueryPositionAddress", NestedQueryPositionAddress);			  
	// ITK1 + {
	ИдентификаторВнешнихИсточников = ИТК_КонструкторЗапросовКлиентСервер.ИдентификаторЗначенийВнешнихИсточников();
	Params.Insert(ИдентификаторВнешнихИсточников, ЭтотОбъект.Object[ИдентификаторВнешнихИсточников]);
	// }
	Notification = New NotifyDescription("ReplaceTable", ThisForm, Params);
	OpenForm("DataProcessor.ИТК_QueryWizard15.Form.TableSelecting", Params, ThisForm,,,,Notification,
             FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure ReplaceTable(Result, Params) Export
	Var CurrentItems;
	Var Parent;

	If Result = DialogReturnCode.OK Then
		CurrentItems = Sources.FindByID(Params["TableIndex"]);
		If (CurrentItems = Undefined) Then
			Return;
		EndIf;

		If CurrentItems["Type"] <> 1 Then
			Return;
		EndIf;

		Parent = CurrentItems.GetParent();
		If Parent = Undefined Then
			Parent = Sources;
		EndIf;

		ChangeSourceAtCache(5, Params["ItemIndexes"], CurrentItems["Index"]);
		SetPageState("SourcesPage", True);
		SetPageState("AvailableFieldsPage", True);
		FillPagesAtClient();
	EndIf;
EndProcedure

&AtClient
Procedure SummingFieldsBeforeRowChange(Item, Cancel)
	Var Parent;
	
	RowForEdit = Item.CurrentRow;
	If NeedFillChoiceList Then
		AttachIdleHandler("SummingFieldsBeforeRowChangeHandler", 0.01, True);
		Cancel = True;
	EndIf;
	NeedFillChoiceList = True;
EndProcedure

&AtClient
Procedure SummingFieldsBeforeRowChangeHandler()
	Var Expressions;
	Var Count;
	Var Pos;
	Var Item;
	
	Item = SummingFields.FindByID(RowForEdit);
	Expressions = SummingFieldsBeforeRowChangeAtServer(Item.Name, "", Item.Index);
	Items.SummingFieldsName.ChoiceList.Clear();

	Count = Expressions.Count();
	For Pos = 0 To Count - 1 Do
		Items.SummingFieldsName.ChoiceList.Add(Expressions.Get(Pos));
	EndDo;
	
	NeedFillChoiceList = False;
	Items.SummingFields.ChangeRow();
EndProcedure

&AtServer
Function SummingFieldsBeforeRowChangeAtServer(Name, ParentName, Index)
	Var QuerySchema;
	Var Query;
	Var Operators;
	Var Expressions;
	Var Count;
	Var Operator;
	Var Pos;
	Var NewExpression;
	Var StrPos;
	Var Arr;

	QuerySchema = GetFromTempStorage(QueryWizardAddress);
	If QuerySchema = Undefined Then
		Return Undefined;
	EndIf;

	Batch = QuerySchema.QueryBatch;
	Query = GetSchemaQuery(QuerySchema, CurrentQuerySchemaSelectQuery, NestedQueryPositionAddress);

	If TypeOf(Query) = Type("QuerySchemaSelectQuery") Then
		Operators  = Query.Operators;
		Operator = Operators.Get(CurrentQuerySchemaOperator);
	Else
		Return Undefined;
	EndIf;

	Expressions = GetAgregateExpressions(Name, True, ParentName);
	Count = Expressions.Count();
	Arr = New Array;
	For Pos = 0 To Count - 1 Do
		Try
			Operator.Filter.Add(Expressions.Get(Pos) + " IS NULL");
			NewExpression = String(Operator.Filter[Operator.Filter.Count() - 1]);
			Operator.Filter.Delete(Operator.Filter.Count() - 1);

			StrPos = Find(NewExpression,  " IS NULL");
			StrPos = StrPos + Find(NewExpression,  " ЕСТЬ NULL");
			Arr.Add(Mid(NewExpression, 1, StrPos - 1));
		Except
		EndTry;
	EndDo;
	Return Arr;
EndFunction

&AtClient
Procedure AllFieldsForConditionsDragStart(Item, DragParameters, Perform)
	DragParameters.AllowedActions = DragAllowedActions.Copy;
	DragParameters.Value = "DragFromConditionFields";
EndProcedure

&AtClient
Procedure JoinsExpressionChangeInDialog(Val Expression, Val IsExpressionChanged = Undefined)
	Var Params;
	Var CurrentRow;
	Var Notification;

	SaveAllFieldsForGroupingToTempStorage();
	
	Params = New Structure;
	Params.Insert("FieldsAddress", AllFieldsForGroupingAddress);
	Params.Insert("Expression", Expression);

	CurrentRow = Items.Joins.CurrentRow;
	Items.Joins.CurrentRow = Undefined;
	Items.Joins.CurrentRow = CurrentRow;

	Params.Insert("Changed", True);
	Params.Insert("QueryWizardAddress", QueryWizardAddress);
	Params.Insert("CurrentQuerySchemaSelectQuery", CurrentQuerySchemaSelectQuery);
	Params.Insert("CurrentQuerySchemaOperator", CurrentQuerySchemaOperator);
	Params.Insert("NestedQueryPositionAddress", NestedQueryPositionAddress);
	// ITK1 + {
	ИдентификаторВнешнихИсточников = ИТК_КонструкторЗапросовКлиентСервер.ИдентификаторЗначенийВнешнихИсточников();
	Params.Insert(ИдентификаторВнешнихИсточников, ЭтотОбъект.Object[ИдентификаторВнешнихИсточников]);
	// }
	Notification = New NotifyDescription("JoinConditionChanged", ThisForm, Params);
    OpenForm("DataProcessor.ИТК_QueryWizard15.Form.ArbitraryExpression", Params, ThisForm,,,,Notification,
             FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure JoinConditionChanged(ChildForm, Params) Export
	Var ErrorMessage;
	Var StartCol;
	Var StartRow;
	Var CurrentItems;

	If ChildForm = Undefined Then
		Return;
	EndIf;

	If Params["Changed"] Then
		ErrorMessage = "";
		If NOT(ChangeJoinExpression(Items.Joins.CurrentRow, Params["Expression"], False, ErrorMessage)) Then
			StartRow = -1;
			StartCol = -1;
			GetErrorTextBounds(StartRow, StartCol, ErrorMessage);
			ChildForm.SetTextSelectionBounds(StartRow, StartCol);
			AddErrorMessage(ErrorMessage);
			ShowErrorMessage();
		Else
			ChildForm.Closing = True;
			ChildForm.Close();
			StartEdit = False;
		EndIf;
	Else
		ChildForm.Closing = True;
		ChildForm.Close();
		StartEdit = False;

		CurrentItems = Joins.FindByID(Items.Joins.CurrentRow);
		CurrentItems["Expression"] = TmpString;
	EndIf;
EndProcedure

&AtClient
Procedure JoinsExpressionStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	EditText = Item.EditText;
	AttachIdleHandler("JoinsExpressionChangeInDialogHandler", 0.01, True);
EndProcedure

&AtClient
Procedure JoinsExpressionChangeInDialogHandler()
	JoinsExpressionChangeInDialog(EditText);
EndProcedure

&AtClient
Procedure JoinsOnChange(Item)
	If Item.CurrentItem.Name = "JoinsJoinType" Then
		Items.Joins.EndEditRow(False);
	EndIf;
EndProcedure

&AtClient
Procedure ConditionsConditionStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	EditText = Item.EditText;
	AttachIdleHandler("ConditionsConditionStartChoiceHandler", 0.01, True);
EndProcedure

&AtClient
Procedure ConditionsConditionStartChoiceHandler()
	ConditionChangeInDialog(EditText);
EndProcedure

&AtClient
Procedure ConditionChangeInDialog(Val Expression, Val IsExpressionChanged = Undefined)
	Var Params;
	Var CurrentRow;
	Var Notification;

	SaveAllFieldsForGroupingToTempStorage();	
	
	Params = New Structure;
	Params.Insert("FieldsAddress", AllFieldsForGroupingAddress);
	Params.Insert("Expression", Expression);

	CurrentRow = Items.Conditions.CurrentRow;
	Items.Conditions.CurrentRow = Undefined;
	Items.Conditions.CurrentRow = CurrentRow;

	If IsExpressionChanged <> Undefined Then
		Params.Insert("Changed", IsExpressionChanged);
	Else
		Params.Insert("Changed", False);
	EndIf;
	
	Params.Insert("QueryWizardAddress", QueryWizardAddress);
	Params.Insert("CurrentQuerySchemaSelectQuery", CurrentQuerySchemaSelectQuery);
	Params.Insert("CurrentQuerySchemaOperator", CurrentQuerySchemaOperator);
	Params.Insert("NestedQueryPositionAddress", NestedQueryPositionAddress);
	// ITK1 + {
	ИдентификаторВнешнихИсточников = ИТК_КонструкторЗапросовКлиентСервер.ИдентификаторЗначенийВнешнихИсточников();
	Params.Insert(ИдентификаторВнешнихИсточников, ЭтотОбъект.Object[ИдентификаторВнешнихИсточников]);
	// }
	Notification = New NotifyDescription("ConditionChanged", ThisForm, Params);
    OpenForm("DataProcessor.ИТК_QueryWizard15.Form.ArbitraryExpression", Params, ThisForm,,,,Notification,
             FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure ConditionChanged(ChildForm, Params) Export
	Var ErrorMessage;
	Var StartCol;
	Var StartRow;
	Var CurrentItems;

	If ChildForm = Undefined Then
		Return;
	EndIf;

	If Params["Changed"] Then
		ErrorMessage = "";
		If NOT(CheckCondition(Params["Expression"], ErrorMessage)) Then
			StartRow = -1;
			StartCol = -1;
			GetErrorTextBounds(StartRow, StartCol, ErrorMessage);
			ChildForm.SetTextSelectionBounds(StartRow, StartCol);
			AddErrorMessage(ErrorMessage);
			ShowErrorMessage();
		Else
			ChildForm.Closing = True;
			ChildForm.Close();

			If Items.Conditions.CurrentRow <> Undefined Then
				CurrentItems = Conditions.FindByID(Items.Conditions.CurrentRow);
			EndIf;
			If (CurrentItems = Undefined) Then
				Return;
			EndIf;
			CurrentItems["Condition"] = Params["Expression"];
			SetPageState("ConditionsPage", True);
		EndIf;
	Else
		ChildForm.Closing = True;
		ChildForm.Close();
		CurrentItems = Conditions.FindByID(Items.Conditions.CurrentRow);
		CurrentItems["Condition"] = TmpString;
	EndIf;
	StartEdit = False;

EndProcedure

&AtClient
Procedure SourcesBeforeDeleteRow(Item, Cancel)
	SourcesRemoveTheCurrent(Undefined);
	Cancel = True;
EndProcedure

&AtClient
Procedure AvailableFieldsBeforeDeleteRow(Item, Cancel)
	AvailableFieldsDelete(Undefined);
	Cancel = True;
EndProcedure

&AtClient
Procedure GroupingFieldsBeforeDeleteRow(Item, Cancel)
	GroupDelete(Undefined);
	Cancel = True;
EndProcedure

&AtClient
Procedure SummingFieldsBeforeDeleteRow(Item, Cancel)
	SummDelete(Undefined);
	Cancel = True;
EndProcedure

&AtClient
Procedure ConditionsBeforeDeleteRow(Item, Cancel)
	ConditionDelete(Undefined);
	Cancel = True;
EndProcedure

&AtClient
Procedure AdditionallyTablesForChangingBeforeDeleteRow(Item, Cancel)
	AdditionallyDelete(Undefined);
	Cancel = True;
EndProcedure

&AtClient
Procedure UnionsBeforeDeleteRow(Item, Cancel)
	Cancel = True;
	AttachIdleHandler("UnionDeleteHandler", 0.01, True);
EndProcedure

&AtClient
Procedure UnionDeleteHandler()
	UnionDelete(Undefined);
EndProcedure

&AtClient
Procedure AliasesBeforeDeleteRow(Item, Cancel)
	Cancel = True;
	AttachIdleHandler("AliasDeleteHandler", 0.01, True);
EndProcedure

&AtClient
Procedure AliasDeleteHandler()
	AliasDelete(Undefined);
EndProcedure

&AtClient
Procedure UnionsBeforeAddRow(Item, Cancel, Clone, Parent, Folder, Parameter)	
	Cancel = True;
	If NOT(Clone) Then
		AttachIdleHandler("UnionAddHandler", 0.01, True);
	Else
		AttachIdleHandler("UnionCopyHandler", 0.01, True);
	EndIf;
EndProcedure

&AtClient
Procedure UnionAddHandler()
	UnionAdd(Undefined);
EndProcedure

&AtClient
Procedure UnionCopyHandler()
	UnionAddCopy(Undefined);
EndProcedure

&AtClient
Procedure AliasesBeforeAddRow(Item, Cancel, Clone, Parent, Folder, Parameter)
	Cancel = True;
EndProcedure

&AtClient
Procedure SourcesBeforeAddRow(Item, Cancel, Clone, Parent, Folder, Parameter)
	Cancel = True;
EndProcedure

&AtClient
Procedure AvailableFieldsBeforeAddRow(Item, Cancel, Clone, Parent, Folder, Parameter)
	Cancel = True;
	AttachIdleHandler("AvailableFieldsAddNewHandler", 0.01, True);		
EndProcedure

&AtClient
Procedure AvailableFieldsAddNewHandler()
	AvailableFieldsAddNew(Undefined);
EndProcedure

&AtClient
Procedure GroupingFieldsBeforeAddRow(Item, Cancel, Clone, Parent, Folder, Parameter)
	Cancel = True;
EndProcedure

&AtClient
Procedure SummingFieldsBeforeAddRow(Item, Cancel, Clone, Parent, Folder, Parameter)
	Cancel = True;
EndProcedure

&AtClient
Procedure ConditionsBeforeAddRow(Item, Cancel, Clone, Parent, Folder, Parameter)
	If NOT(Clone) Then
		ConditionAdd(Undefined);
	Else
		ConditionCopy(Undefined);
	EndIf;
	Cancel = True;
EndProcedure

&AtClient
Procedure AdditionallyTablesForChangingBeforeAddRow(Item, Cancel, Clone, Parent, Folder, Parameter)
	Cancel = True;
EndProcedure

&AtClient
Procedure IndexesBeforeAddRow(Item, Cancel, Clone, Parent, Folder, Parameter)
	Cancel = True;
EndProcedure

&AtClient
Procedure OrderBeforeAddRow(Item, Cancel, Clone, Parent, Folder, Parameter)
	Cancel = True;
EndProcedure

&AtClient
Procedure TotalsGroupingFieldsBeforeAddRow(Item, Cancel, Clone, Parent, Folder, Parameter)
	Cancel = True;
EndProcedure

&AtClient
Procedure TotalsExpressionsBeforeAddRow(Item, Cancel, Clone, Parent, Folder, Parameter)
	Cancel = True;
EndProcedure

&AtClient
Procedure IndexesBeforeDeleteRow(Item, Cancel)
	IndexDelete(Undefined);
	Cancel = True;
EndProcedure

&AtClient
Procedure OrderBeforeDeleteRow(Item, Cancel)
	OrderDelete(Undefined);
	Cancel = True;
EndProcedure

&AtClient
Procedure TotalsGroupingFieldsBeforeDeleteRow(Item, Cancel)
	TotalsFieldsDelete(Undefined);
	Cancel = True;
EndProcedure

&AtClient
Procedure TotalsExpressionsBeforeDeleteRow(Item, Cancel)
	TotalsExpressionsDelete(Undefined);
	Cancel = True;
EndProcedure

&AtClient
Procedure QueryBatchBeforeAddRow(Item, Cancel, Clone, Parent, Folder, Parameter)
	If NOT(Clone) Then
		AttachIdleHandler("QueryAddHandler", 0.01, True);
	Else
		AttachIdleHandler("QueryAddCopyHandler", 0.01, True);
	EndIf;
	Cancel = True;
EndProcedure

&AtClient
Procedure QueryAddHandler()
	QueryAdd(Undefined);
EndProcedure

&AtClient
Procedure QueryAddCopyHandler()
	QueryAddCopy(Undefined);
EndProcedure

&AtClient
Procedure QueryBatchBeforeDeleteRow(Item, Cancel)
	Cancel = True;
	AttachIdleHandler("QueryDeleteHandler", 0.01, True);
EndProcedure

&AtClient
Procedure QueryDeleteHandler()
	QueryDelete(Undefined);
EndProcedure

&AtClient
Procedure MoveJoin(Command)
	MoveJoinTable = -1;
	If Items.Joins.CurrentRow = Undefined Then
		Return;
	Else
		MoveJoinTable = Items.Joins.CurrentRow;
	EndIf;

	If MoveJoinText = "" Then
		MoveJoinText = NStr("ru = 'Укажите, с каким источником создать связь';
							|SYS = 'QueryEditor.MakeJoin'", "ru");
		Items.MoveJoin.Enabled = False;
	EndIf;
EndProcedure

&AtClient
Procedure JoinsOnActivateRow()
	AttachIdleHandler("JoinsOnActivateRowHandler", 0.01, True);		
EndProcedure

&AtClient
Procedure JoinsOnActivateRowHandler()
	Var CurrentItems;
	Var ReceivingItem;
	Var CurrentRow;

	If (MoveJoinTable = Items.Joins.CurrentRow)
		AND (Items.Joins.CurrentRow <> Undefined) Then
		Return;
	EndIf;

	If MoveJoinTable >= 0 Then
		CurrentItems = Joins.FindByID(MoveJoinTable);
		ReceivingItem = Joins.FindByID(Items.Joins.CurrentRow);
		MoveJoinTable = -1;
		If (CurrentItems = Undefined)
			OR (CurrentItems = ReceivingItem) Then
			Return;
		EndIf;
		MakeJoin(CurrentItems, ReceivingItem);
	EndIf;
	MoveJoinTable = -1;

	If MoveJoinText <> "" Then
		MoveJoinText = "";
	EndIf;

	CurrentRow = Items.Joins.CurrentRow;
	If (CurrentRow = Undefined) Then
		Return;
	EndIf;
	CurrentItems = Joins.FindByID(CurrentRow);

	If (CurrentItems["Type"] = 1) OR (CurrentItems["Type"] = 3) Then
		If Items.MoveJoin.Enabled <> True Then
			Items.MoveJoin.Enabled = True;
		EndIf;
	Else
		If Items.MoveJoin.Enabled <> False Then
			Items.MoveJoin.Enabled = False;
		EndIf;
	EndIf;

	If (CurrentItems["Type"] = 2) Then
		If Items.DeleteJoin.Enabled <> True Then
			Items.DeleteJoin.Enabled = True;
		EndIf;
	Else
		If Items.DeleteJoin.Enabled <> False Then
			Items.DeleteJoin.Enabled = False;
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure AvailableTablesSelection(Item, SelectedRow, Field, StandardProcessing)
	
	// ITK5 + {
	Если Item.ТекущиеДанные.ПолучитьРодителя() = Неопределено Тогда
		Возврат;
	КонецЕсли;
	// }
	SourcesAdd(Undefined);
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure SourcesSelection(Item, SelectedRow, Field, StandardProcessing)
	AvailableFieldsAdd(Undefined);
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure AvailableFieldsSelection(Item, SelectedRow, Field, StandardProcessing)
	AvailableFieldsChange(Undefined);
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure AllFieldsForGroupingSelection(Item, SelectedRow, Field, StandardProcessing)
	GroupAdd(Undefined);
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure GroupingFieldsSelection(Item, SelectedRow, Field, StandardProcessing)
	GroupDelete(Undefined);
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure AllFieldsForConditionsSelection(Item, SelectedRow, Field, StandardProcessing)
	If Item.CurrentData["Type"] = 2 Then
		// ITK4 * {
		// AddConditionFromFields(Item.CurrentData["Name"], Item.CurrentData["Presentation"]);
		ITKДобавитьПолеУсловия(Item.CurrentData);
		// }
	EndIf;
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure AdditionallyTablesSelection(Item, SelectedRow, Field, StandardProcessing)
	AdditionallyAdd(Undefined);
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure AdditionallyTablesForChangingSelection(Item, SelectedRow, Field, StandardProcessing)
	AdditionallyDelete(Undefined);
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure UnionsSelection(Item, SelectedRow, Field, StandardProcessing)
	If Item.CurrentItem.Name = "UnionsName" Then
		CurrentQuerySchemaOperator = Item.CurrentData["Index"];
		FillPagesAtClient();
		InvalidateAllPages(True);
		FillPagesAtClient();
		SetCurrentTab();
	EndIf;
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure AllFieldsForIndexSelection(Item, SelectedRow, Field, StandardProcessing)
	IndexAdd(Undefined);
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure IndexesSelection(Item, SelectedRow, Field, StandardProcessing)
	IndexDelete(Undefined);
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure AllFieldsForOrderSelection(Item, SelectedRow, Field, StandardProcessing)
	OrderAdd(Undefined);
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure OrderSelection(Item, SelectedRow, Field, StandardProcessing)
	If Item.CurrentData["Index"] < 0 Then
		StandardProcessing = False;
		Return;
	EndIf;

	If Item.CurrentItem.Name = "OrderName" Then
		OrderDelete(Undefined);
		StandardProcessing = False;
	EndIf;
EndProcedure

&AtClient
Procedure AllFieldsForTotalsSelection(Item, SelectedRow, Field, StandardProcessing)
	TotalsFieldsAdd(Undefined);
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure TotalsGroupingFieldsSelection(Item, SelectedRow, Field, StandardProcessing)
	If Item.CurrentItem.Name = "TotalsGroupingFieldsName" Then
		TotalsFieldsDelete(Undefined);
		StandardProcessing = False;
	EndIf;
EndProcedure

&AtClient
Procedure QueryBatchSelection(Item, SelectedRow, Field, StandardProcessing)
	CurrentQuerySchemaSelectQuery = Item.CurrentData["Index"];
	CurrentQuerySchemaOperator = 0;
	FillPagesAtClient();
	InvalidateAllPages(True);
	FillPagesAtClient();
	SetCurrentTab();
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure AvailableFieldsBeforeRowChange(Item, Cancel)
	Cancel = True;
	AttachIdleHandler("AvailableFieldsChangeHandler", 0.01, True);	
EndProcedure

&AtClient
Procedure AvailableFieldsChangeHandler()
	AvailableFieldsChange(Undefined);
EndProcedure

&AtClient
Procedure GroupingFieldsBeforeRowChange(Item, Cancel)
	// ITK6 - {
	//Cancel = True;
	// }
EndProcedure

&AtClient
Procedure QueryBatchBeforeRowChange(Item, Cancel)
	Cancel = True;
EndProcedure

&AtClient
Procedure ConditionsDragStart(Item, DragParameters, Perform)
	DragParameters.AllowedActions = DragAllowedActions.Copy;
	DragParameters.Value = "DragFromConditions";
EndProcedure

&AtClient
Procedure AllFieldsForConditionsDragCheck(Item, DragParameters, StandardProcessing, Row, Field)
	If DragParameters.Value = "DragFromConditions" Then
		StandardProcessing = False;
	EndIf;
EndProcedure

&AtClient
Procedure AllFieldsForConditionsDrag(Item, DragParameters, StandardProcessing, Row, Field)
	ConditionDelete(Undefined);
EndProcedure

&AtClient
Procedure AvailableFieldsOnActivateRow(Item)
	Var CurrentRow;
	Var CurrentItems;
	Var State;

	CurrentRow = Items.AvailableFields.CurrentRow;
	If (CurrentRow = Undefined) Then
		Return;
	EndIf;
	CurrentItems = AvailableFields.FindByID(CurrentRow);
	If CurrentItems.GetItems().Count() > 0 Then
		State = False;
	Else
		State = True;
	EndIf;

	If Items.AvailableFieldsAvailableFieldsChange.Enabled <> State Then
		Items.AvailableFieldsAvailableFieldsChange.Enabled = State;
	EndIf;
EndProcedure

&AtClient
Procedure OrderOrderChoiceProcessing(Item, SelectedValue, StandardProcessing)
	Var CurrentRow;
	Var CurrentItems;

	StandardProcessing = False;

	CurrentRow = Items.Order.CurrentRow;
	If (CurrentRow = Undefined) Then
		Return;
	EndIf;

	CurrentItems = Order.FindByID(CurrentRow);
	If SelectedValue = "Ascending" Then
		CurrentItems["Order"] = NStr("ru = 'Возрастание';
									|SYS = 'QueryEditor.Ascending'", "ru");
	EndIf;
	If SelectedValue = "Descending" Then
		CurrentItems["Order"] = NStr("ru = 'Убывание';
									|SYS = 'QueryEditor.Descending'", "ru");
	EndIf;
	If SelectedValue = "HierarchyAscending" Then
		CurrentItems["Order"] = NStr("ru = 'Возрастание иерархии';
									|SYS = 'QueryEditor.HierarchyAscending'", "ru");
	EndIf;
	If SelectedValue = "HierarchyDescending" Then
		CurrentItems["Order"] = NStr("ru = 'Убывание иерархии';
									|SYS = 'QueryEditor.HierarchyDescending'", "ru");
	EndIf;

	ChangeOrderAtCache(CurrentItems["Index"], 5,,,, SelectedValue);
	SetPageState("OrderPage", True);
	Items.Order.CurrentRow = Undefined;
	Items.Order.CurrentRow = CurrentRow;
EndProcedure

&AtClient
Procedure TotalsGroupingFieldsPointTypeChoiceProcessing(Item, SelectedValue, StandardProcessing)
	Var CurrentRow;
	Var CurrentItems;

	StandardProcessing = False;
	CurrentRow = Items.TotalsGroupingFields.CurrentRow;
	If (CurrentRow = Undefined) Then
		Return;
	EndIf;

	CurrentItems = TotalsGroupingFields.FindByID(CurrentRow);
	If SelectedValue = "Items" Then
		CurrentItems["PointType"] = NStr("ru = 'Элементы';
										|SYS = 'QueryEditor.Items'", "ru");
	EndIf;
	If SelectedValue = "Hierarchy" Then
		CurrentItems["PointType"] = NStr("ru = 'Иерархия';
										|SYS = 'QueryEditor.Hierarchy'", "ru");
	EndIf;
	If SelectedValue = "HierarchyOnly" Then
		CurrentItems["PointType"] = NStr("ru = 'Только иерархия';
										|SYS = 'QueryEditor.HierarchyOnly'", "ru");
	EndIf;

	ChangeTotalsGroupingFieldsAtCache(12, CurrentItems["Index"],,, SelectedValue);
	Items.TotalsGroupingFields.CurrentRow = Undefined;
	Items.TotalsGroupingFields.CurrentRow = CurrentRow;
	SetPageState("TotalsPage", True);
EndProcedure

&AtClient
Procedure TotalsGroupingFieldsIntervalChoiceProcessing(Item, SelectedValue, StandardProcessing)
	Var CurrentRow;
	Var CurrentItems;

	StandardProcessing = False;
	CurrentRow = Items.TotalsGroupingFields.CurrentRow;
	If (CurrentRow = Undefined) Then
		Return;
	EndIf;

	CurrentItems = TotalsGroupingFields.FindByID(CurrentRow);
	If (CurrentItems["Index"] >= 0) Then
		If SelectedValue = "NoAddition" Then
			CurrentItems["Interval"] = NStr("ru = 'Без дополнения';
											|SYS = 'QueryEditor.NoAddition'", "ru");
			CurrentItems["PeriodStart"] = "";
			CurrentItems["PeriodEnd"] = "";

			ChangeTotalsGroupingFieldsAtCache(8, CurrentItems["Index"],,, ""); // начало периода
			ChangeTotalsGroupingFieldsAtCache(9, CurrentItems["Index"],,, ""); // конец периода
		ElsIf SelectedValue = "Day" Then
			CurrentItems["Interval"] = NStr("ru = 'День';
											|SYS = 'QueryEditor.Day'", "ru");
		ElsIf SelectedValue = "Second" Then
			CurrentItems["Interval"] = NStr("ru = 'Секунда';
											|SYS = 'QueryEditor.Second'", "ru");
		ElsIf SelectedValue = "Minute" Then
			CurrentItems["Interval"] = NStr("ru = 'Минута';
											|SYS = 'QueryEditor.Minute'", "ru");
		ElsIf SelectedValue = "Hour" Then
			CurrentItems["Interval"] = NStr("ru = 'Час';
											|SYS = 'QueryEditor.Hour'", "ru");
		ElsIf SelectedValue = "Week" Then
			CurrentItems["Interval"] = NStr("ru = 'Неделя';
											|SYS = 'QueryEditor.Week'", "ru");
		ElsIf SelectedValue = "Month" Then
			CurrentItems["Interval"] = NStr("ru = 'Месяц';
											|SYS = 'QueryEditor.Month'", "ru");
		ElsIf SelectedValue = "Quarter" Then
			CurrentItems["Interval"] = NStr("ru = 'Квартал';
											|SYS = 'QueryEditor.Quarter'", "ru");
		ElsIf SelectedValue = "HalfYear" Then
			CurrentItems["Interval"] = NStr("ru = 'Полугодие';
											|SYS = 'QueryEditor.HalfYear'", "ru");
		ElsIf SelectedValue = "Year" Then
			CurrentItems["Interval"] = NStr("ru = 'Год';
											|SYS = 'QueryEditor.Year'", "ru");
		ElsIf SelectedValue = "TenDays" Then
			CurrentItems["Interval"] = NStr("ru = 'Декада';
											|SYS = 'QueryEditor.Decade'", "ru");
		EndIf;

		ChangeTotalsGroupingFieldsAtCache(7, CurrentItems["Index"],,, SelectedValue);
		Items.TotalsGroupingFields.CurrentRow = Undefined;
		Items.TotalsGroupingFields.CurrentRow = CurrentRow;
		SetPageState("TotalsPage", True);
	EndIf;
EndProcedure

&AtClient
Procedure TotalsGroupingFieldsPeriodStartChoiceProcessing(Item, SelectedValue, StandardProcessing)
	Var CurrentRow;
	Var CurrentItems;

	StandardProcessing = False;
	CurrentRow = Items.TotalsGroupingFields.CurrentRow;
	If (CurrentRow = Undefined) Then
		Return;
	EndIf;
	CurrentItems = TotalsGroupingFields.FindByID(CurrentRow);
	If (CurrentItems["Index"] >= 0) Then
		ChangeTotalsGroupingFieldsAtCache(8, CurrentItems["Index"],,, SelectedValue);
		CurrentItems["PeriodStart"] = SelectedValue;
		Items.TotalsGroupingFields.CurrentRow = Undefined;
		Items.TotalsGroupingFields.CurrentRow = CurrentRow;
		SetPageState("TotalsPage", True);
	EndIf;
EndProcedure

&AtClient
Procedure TotalsGroupingFieldsPeriodEndChoiceProcessing(Item, SelectedValue, StandardProcessing)
	Var CurrentRow;
	Var CurrentItems;

	StandardProcessing = False;
	CurrentRow = Items.TotalsGroupingFields.CurrentRow;
	If (CurrentRow = Undefined) Then
		Return;
	EndIf;
	CurrentItems = TotalsGroupingFields.FindByID(CurrentRow);
	If (CurrentItems["Index"] >= 0) Then
		ChangeTotalsGroupingFieldsAtCache(9, CurrentItems["Index"],,, SelectedValue);
		CurrentItems["PeriodEnd"] = SelectedValue;
		Items.TotalsGroupingFields.CurrentRow = Undefined;
		Items.TotalsGroupingFields.CurrentRow = CurrentRow;
		SetPageState("TotalsPage", True);
	EndIf;
EndProcedure

&AtClient
Procedure TotalsGroupingFieldsPeriodStartClearing(Item, StandardProcessing)
	TotalsGroupingFieldsPeriodStartChoiceProcessing(Item, "", StandardProcessing);
EndProcedure

&AtClient
Procedure TotalsGroupingFieldsPeriodEndClearing(Item, StandardProcessing)
	TotalsGroupingFieldsPeriodEndChoiceProcessing(Item, "", StandardProcessing);
EndProcedure

&AtClient
Procedure TotalsGroupingFieldsPeriodStartTextEditEnd(Item, Text, ChoiceData, Parameters, StandardProcessing)
	TotalsGroupingFieldsPeriodStartChoiceProcessing(Item, Text, False);
EndProcedure

&AtClient
Procedure TotalsGroupingFieldsPeriodEndTextEditEnd(Item, Text, ChoiceData, Parameters, StandardProcessing)
	TotalsGroupingFieldsPeriodEndChoiceProcessing(Item, Text, False);
EndProcedure

&AtClient
Procedure JoinsBeforeDeleteRow(Item, Cancel)	
	Cancel = True;
	AttachIdleHandler("JoinsBeforeDeleteRowHandler", 0.01, True);	
EndProcedure

&AtClient
Procedure JoinsBeforeDeleteRowHandler()
	Var CurrentRow;
	Var CurrentItems;
	Var TableName;
	Var CurRow;
	
	CurrentRow = Items.Joins.CurrentRow;
	If (CurrentRow = Undefined) Then
		Return;
	EndIf;
	CurrentItems = Joins.FindByID(CurrentRow);
	If CurrentItems["Type"] <> 2 Then
		Return;
	EndIf;

	TableName = CurrentItems.GetParent()["Table"];
	ChangeJoinAtCache(2, CurrentItems.GetParent().GetParent()["Table"], TableName);
	SetPageState("JoinsPage", True);
	FillPagesAtClient();

	CurRow = FindJoin(TableName, Joins.GetItems());
	If CurRow <> Undefined Then
	    Items.Joins.CurrentRow = Undefined;
		Items.Joins.CurrentRow = CurRow;
	EndIf;	
EndProcedure

&AtClient
Procedure JoinsBeforeAddRow(Item, Cancel, Clone, Parent, Folder, Parameter)
	Cancel = True;
EndProcedure

&AtClient
Procedure SummingFieldsNameStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	EditText = Item.EditText;
	AttachIdleHandler("SummingFieldsNameStartChoiceHandler", 0.01, True);
EndProcedure

&AtClient
Procedure SummingFieldsNameStartChoiceHandler()
	SummingFieldChangeInDialog(EditText);
EndProcedure

&AtClient
Procedure SummingFieldChangeInDialog(Val Expression, Val IsExpressionChanged = Undefined)
	Var Params;
	Var CurrentRow;
	Var Notification;

	SaveAllFieldsForGroupingToTempStorage();	
	
	Params = New Structure;
	Params.Insert("FieldsAddress", AllFieldsForGroupingAddress);
	Params.Insert("Expression", Expression);

	CurrentRow = Items.SummingFields.CurrentRow;
	Items.SummingFields.CurrentRow = Undefined;
	Items.SummingFields.CurrentRow = CurrentRow;

	If IsExpressionChanged <> Undefined Then
		Params.Insert("Changed", IsExpressionChanged);
	Else
		Params.Insert("Changed", False);
	EndIf;
	
	Params.Insert("QueryWizardAddress", QueryWizardAddress);
	Params.Insert("CurrentQuerySchemaSelectQuery", CurrentQuerySchemaSelectQuery);
	Params.Insert("CurrentQuerySchemaOperator", CurrentQuerySchemaOperator);
	Params.Insert("NestedQueryPositionAddress", NestedQueryPositionAddress);
	// ITK1 + {
	ИдентификаторВнешнихИсточников = ИТК_КонструкторЗапросовКлиентСервер.ИдентификаторЗначенийВнешнихИсточников();
	Params.Insert(ИдентификаторВнешнихИсточников, ЭтотОбъект.Object[ИдентификаторВнешнихИсточников]);
	// }
	Notification = New NotifyDescription("SummingFieldChanged", ThisForm, Params);
    OpenForm("DataProcessor.ИТК_QueryWizard15.Form.ArbitraryExpression", Params, ThisForm,,,,Notification,
             FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure SummingFieldChanged(ChildForm, Params) Export
	Var ErrorMessage;
	Var StartCol;
	Var StartRow;
	Var CurrentItems;

	If ChildForm = Undefined Then
		Return;
	EndIf;

	CurrentItems = SummingFields.FindByID(Items.SummingFields.CurrentRow);
	If Params["Changed"] Then
		ErrorMessage = "";
		If NOT(ChangeSummingField(Params["Expression"], ErrorMessage)) Then
			StartRow = -1;
			StartCol = -1;
			GetErrorTextBounds(StartRow, StartCol, ErrorMessage);
			ChildForm.SetTextSelectionBounds(StartRow, StartCol);
			AddErrorMessage(ErrorMessage);
			ShowErrorMessage();
		Else
			CurrentItems["Name"] = Params["Expression"];
			ChildForm.Closing = True;
			ChildForm.Close();

			If CurrentItems["Name"] = "" Then
				SetPageState("GroupingPage", True);
				FillPagesAtClient();
			EndIf;
		EndIf;
	Else
		ChildForm.Closing = True;
		ChildForm.Close();
		CurrentItems["Name"] = TmpString;
	EndIf;
	StartEdit = False;
EndProcedure

&AtClient
Procedure TotalsExpressionsExpressionStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	EditText = Item.EditText;
	AttachIdleHandler("TotalsExpressionsExpressionStartChoiceHandler", 0.01, True);
EndProcedure

&AtClient
Procedure TotalsExpressionsExpressionStartChoiceHandler()
	TotalsExpressionChangeInDialog(EditText);
EndProcedure

&AtClient
Procedure TotalsExpressionChangeInDialog(Val Expression, Val IsExpressionChanged = Undefined)
	Var Params;
	Var CurrentRow;
	Var Notification;

	SaveAllFieldsForGroupingToTempStorage();	
	Params = New Structure;
	Params.Insert("FieldsAddress", AllFieldsForGroupingAddress);
	Params.Insert("Expression", Expression);

	CurrentRow = Items.TotalsExpressions.CurrentRow;
	Items.TotalsExpressions.CurrentRow = Undefined;
	Items.TotalsExpressions.CurrentRow = CurrentRow;

	If IsExpressionChanged <> Undefined Then
		Params.Insert("Changed", IsExpressionChanged);
	Else
		Params.Insert("Changed", False);
	EndIf;
	
	Params.Insert("QueryWizardAddress", QueryWizardAddress);
	Params.Insert("CurrentQuerySchemaSelectQuery", CurrentQuerySchemaSelectQuery);
	Params.Insert("CurrentQuerySchemaOperator", CurrentQuerySchemaOperator);
	Params.Insert("NestedQueryPositionAddress", NestedQueryPositionAddress);
	// ITK1 + {
	ИдентификаторВнешнихИсточников = ИТК_КонструкторЗапросовКлиентСервер.ИдентификаторЗначенийВнешнихИсточников();
	Params.Insert(ИдентификаторВнешнихИсточников, ЭтотОбъект.Object[ИдентификаторВнешнихИсточников]);
	// }
	Notification = New NotifyDescription("TotalsExpressionChanged", ThisForm, Params);
    OpenForm("DataProcessor.ИТК_QueryWizard15.Form.ArbitraryExpression", Params, ThisForm,,,,Notification,
             FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure TotalsExpressionChanged(ChildForm, Params) Export
	Var ErrorMessage;
	Var StartCol;
	Var StartRow;
	Var CurrentItems;

	If ChildForm = Undefined Then
		Return;
	EndIf;

	CurrentItems = TotalsExpressions.FindByID(Items.TotalsExpressions.CurrentRow);
	If Params["Changed"] Then
		ErrorMessage = "";
		If NOT(ChangeTotalsExpression(Items.TotalsExpressions.CurrentRow, Params["Expression"], ErrorMessage)) Then
			StartRow = -1;
			StartCol = -1;
			GetErrorTextBounds(StartRow, StartCol, ErrorMessage);
			ChildForm.SetTextSelectionBounds(StartRow, StartCol);
			AddErrorMessage(ErrorMessage);
			ShowErrorMessage();
		Else
			CurrentItems["Expression"] = Params["Expression"];
			ChildForm.Closing = True;
			ChildForm.Close();

			If CurrentItems["Name"] = "" Then
				SetPageState("TotalsPage", True);
				FillPagesAtClient();
			EndIf;
		EndIf;
	Else
		ChildForm.Closing = True;
		ChildForm.Close();		
		CurrentItems["Expression"] = TmpString;
	EndIf;
	StartEdit = False;
EndProcedure

// ITK17,20,21 + {
&НаКлиенте
Процедура ITKПодключаемаяКоманда(Команда) Экспорт
	
	Имя = Команда.Имя;
	
	Если СтрНайти(Имя, "ПерейтиКПолюВВыбранных") Тогда
		
		ПерейтиКПолюВВыбранных();
		
	КонецЕсли;
	
	ИТК_КонструкторЗапросовКлиент.ОсновнаяФормаОбработатьПодключаемуюКоманду(ЭтотОбъект, Имя);

КонецПроцедуры

// ITK4
&НаКлиенте
Процедура ITKДобавитьПолеУсловия(CurrentData)
	
	Если CurrentData.ValueType = "Булево" Тогда
		AddConditionFromFields(CurrentData["Name"], "");
	Иначе
		AddConditionFromFields(CurrentData["Name"], CurrentData["Presentation"]);
	КонецЕсли;
	
КонецПроцедуры

&НаКлиенте
Процедура ПерейтиКПолюВВыбранных()
	
	ТекущиеДанные = ТекущийЭлемент.ТекущиеДанные;
	Если ТекущиеДанные = Неопределено Тогда
		
		Возврат;
		
	КонецЕсли;
	
	НомерТекущегоОператора = ЭтотОбъект["CurrentQuerySchemaOperator"] + 1;
	ИмяТекущейКолонки = ТекущийЭлемент.ТекущийЭлемент.Имя;
	Если ИмяТекущейКолонки = "AliasesName" Тогда
		НомерОператора = НомерТекущегоОператора;
	Иначе
		НомерОператора = ИТК_Строки.ИндексИдентификатора(ИмяТекущейКолонки);
	КонецЕсли;
	
	ИмяПоля = "Запрос" + ИТК_Строки.ЧислоВСтроку(НомерОператора);
	Поле = ТекущиеДанные[ИмяПоля];
	Если Поле = ИТК_КонструкторЗапросовКлиентСервер.ПолеОтсутствует() Тогда
		
		Возврат;
		
	КонецЕсли;
	
	ДополнительныеПараметры = Новый Структура;
	ДополнительныеПараметры.Вставить("НомерТекущегоОператора", НомерТекущегоОператора);
	ДополнительныеПараметры.Вставить("НомерОператора", НомерОператора);
	ДополнительныеПараметры.Вставить("Родитель", ТекущиеДанные.ПолучитьРодителя());
	ДополнительныеПараметры.Вставить("Имя", ИмяПоля);
	ДополнительныеПараметры.Вставить("Поле", Поле);
	ДополнительныеПараметры.Вставить("Индекс", ТекущиеДанные.Index);
	ОписаниеОповещения = Новый ОписаниеОповещения("ПерейтиКВыбраннымЗавершение", ЭтотОбъект, ДополнительныеПараметры);
	
	Если НомерОператора <> НомерТекущегоОператора Тогда
		
		ТекстВопроса = НСтр("ru = 'Поле находится в другом запросе объединения. Показать?';
							|en = 'The field is in another join request. Show?'");
		ЗаголовокВопроса = ИТК_КонструкторЗапросовКлиентСервер.Заголовок();
		
		ПоказатьВопрос(ОписаниеОповещения, ТекстВопроса, РежимДиалогаВопрос.ОКОтмена, , , ЗаголовокВопроса);
		
	Иначе
		
		ВыполнитьОбработкуОповещения(ОписаниеОповещения, КодВозвратаДиалога.ОК);
		
	КонецЕсли;
		
КонецПроцедуры

&НаКлиенте
Процедура ПерейтиКВыбраннымЗавершение(Результат, ДополнительныеПараметры) Экспорт
	
	Если Результат <> КодВозвратаДиалога.ОК Тогда
		
		Возврат;
		
	КонецЕсли;
	
	НомерОператора = ДополнительныеПараметры.НомерОператора;
	
	Если НомерОператора <> ДополнительныеПараметры.НомерТекущегоОператора Тогда
		
		CurrentQuerySchemaOperator = НомерОператора - 1;
		FillPagesAtClient();
		InvalidateAllPages(True);
		FillPagesAtClient();
		SetCurrentTab();
		
	КонецЕсли;
	
	ТекущаяСтрока = ИТК_КонструкторЗапросовКлиент.НайтиСтрокуВВыбранныхПолях(ЭтотОбъект, ДополнительныеПараметры.Родитель,
												ДополнительныеПараметры.Поле, ДополнительныеПараметры.Имя, ДополнительныеПараметры.Индекс);

	// Активируем страницу, элемент, строку
	Если ТекущаяСтрока <> Неопределено Тогда
		
		Элементы["Query"].ТекущаяСтраница = Элементы["TablesAndFieldsPage"];

		ЭлементВыбранныеПоля = Элементы["AvailableFields"];
		ТекущийЭлемент = ЭлементВыбранныеПоля;
		ЭлементВыбранныеПоля.ТекущаяСтрока = ТекущаяСтрока;
		
	КонецЕсли;
	
КонецПроцедуры

&НаКлиенте
&НаКлиенте
Процедура ПодключаемыйITKСвязиПриНачалеРедактирования(Элемент, НоваяСтрока, Копирование) Экспорт
	
	ТекущиеДанные = Элементы.ITKСвязи.ТекущиеДанные;
	
	Если НоваяСтрока Тогда
		ТекущиеДанные.Все1 = Истина;
	КонецЕсли;
	
	СвязиТаблица1 = ТекущиеДанные.Таблица1;
	СвязиТаблица2 = ТекущиеДанные.Таблица2;
	СвязиВсе1 = ТекущиеДанные.Все1;
	СвязиВсе2 = ТекущиеДанные.Все2;
	
	Если СвязиСОшибкой = Неопределено Тогда
		СвязиСОшибкой = Ложь;
	КонецЕсли;
	Если НЕ СвязиСОшибкой Тогда
		СвязиНоваяСтрока = НоваяСтрока;
		СвязиУсловие = ТекущиеДанные.Условие;
	КонецЕсли;
	
КонецПроцедуры

&НаКлиенте
Процедура ПодключаемыйITKСвязиПередОкончаниемРедактирования(Элемент, НоваяСтрока, ОтменаРедактирования, Отказ) Экспорт
	
	Если ОтменаРедактирования Тогда
		Возврат;
	КонецЕсли;
	
	ИмяРеквизитаСвязи = ИТК_КонструкторЗапросовКлиентСервер.ИмяРеквизитаСвязи();
	ТекущиеДанные = Элементы[ИмяРеквизитаСвязи].ТекущиеДанные;
	
	Ошибки = Новый Массив;
	
	// Связь таблиц может задаваться только одной строкой
	Отбор = Новый Структура("Таблица1, Таблица2", ТекущиеДанные.Таблица1, ТекущиеДанные.Таблица2);
	НайденныеСтроки = ЭтотОбъект[ИмяРеквизитаСвязи].НайтиСтроки(Отбор);
	
	Если НайденныеСтроки.Количество() > 1 Тогда
		
		ТекстОшибки = НСтр("ru = 'Связь таблиц может задаваться только одной строкой';
							|en = 'Table relationships can be specified in only one row'");
		Ошибки.Добавить(ТекстОшибки);
		
	КонецЕсли;
	
	Если ПустаяСтрока(ТекущиеДанные.Таблица1) Тогда
		
		ТекстОшибки = НСтр("ru = 'Не заполнена Таблица1';
							|en = 'Not completed Table1'");
		Ошибки.Добавить(ТекстОшибки);
		
	КонецЕсли;
	
	Если ПустаяСтрока(ТекущиеДанные.Таблица2) Тогда
		
		ТекстОшибки = НСтр("ru = 'Не заполнена Таблица2';
							|en = 'Not completed Table2'");
		Ошибки.Добавить(ТекстОшибки);
		
	КонецЕсли;
	
	Если ПустаяСтрока(ТекущиеДанные.Условие) Тогда
		
		ТекстОшибки = НСтр("ru = 'Не заполнено условие';
							|en = 'Not filled condition'");
		Ошибки.Добавить(ТекстОшибки);
		
	КонецЕсли;
	
	Если ЗначениеЗаполнено(Ошибки) Тогда
		
		Отказ = Истина;
		ТекстПредупреждения = СтрСоединить(Ошибки, Символы.ПС);
		ПоказатьПредупреждение( , ТекстПредупреждения, , ИТК_КонструкторЗапросовКлиентСервер.Заголовок());
		
	КонецЕсли;
	
КонецПроцедуры

&НаКлиенте
Процедура ПодключаемыйITKСвязиПриОкончанииРедактирования(Элемент, НоваяСтрока, ОтменаРедактирования) Экспорт
	
	ТекущиеДанные = Элемент.ТекущиеДанные;
	Если ТекущиеДанные = Неопределено Тогда
		Возврат;
	КонецЕсли;
	
	Если ОтменаРедактирования Тогда
		
		Если СвязиНоваяСтрока Тогда
			
			Если СвязиСОшибкой Тогда
				ЭтотОбъект["ITKСвязи"].Удалить(ТекущиеДанные);
			КонецЕсли;
			
		Иначе
			
			ТекущиеДанные.Таблица1 = СвязиТаблица1;
			ТекущиеДанные.Таблица2 = СвязиТаблица2;
			ТекущиеДанные.Все1 = СвязиВсе1;
			ТекущиеДанные.Все2 = СвязиВсе2;
			ТекущиеДанные.Условие = СвязиУсловие;
			
		КонецЕсли;
		
		Возврат;
		
	КонецЕсли;
	
	Если НЕ СвязиНоваяСтрока
			И (СвязиТаблица1 <> ТекущиеДанные.Таблица1
				ИЛИ СвязиТаблица2 <> ТекущиеДанные.Таблица2) Тогда
			
		// Удаление связи
		ChangeJoinAtCache(2, СвязиТаблица1, СвязиТаблица2, ТекущиеДанные.Условие);
		СвязиНоваяСтрока = Истина;
		
	КонецЕсли;
		
	Если СвязиНоваяСтрока Тогда
		ТипИзмененияСвязи  = 1; // Добавление связи
	ИначеЕсли Элемент.ТекущийЭлемент = Элементы.ITKСвязиУсловие Тогда
		ТипИзмененияСвязи  = 4; // Заменить условие
	Иначе
		ТипИзмененияСвязи  = 3; // Изменить тип соединения
	КонецЕсли;
	
	JoinType = ИТК_КонструкторЗапросовКлиентСервер.JoinType(ТекущиеДанные.Все1, ТекущиеДанные.Все2);
	ChangeJoinAtCache(ТипИзмененияСвязи, ТекущиеДанные.Таблица1, ТекущиеДанные.Таблица2, ТекущиеДанные.Условие, , JoinType);
	// Внутренняя особенность изменение типа связи при добавлении происходит только дополнительным шагом
	ChangeJoinAtCache(3, ТекущиеДанные.Таблица1, ТекущиеДанные.Таблица2, ТекущиеДанные.Условие, , JoinType);
	
	СвязиТаблица1 = ТекущиеДанные.Таблица1;
	СвязиТаблица2 = ТекущиеДанные.Таблица2;
	
	ТекстОшибки = ОбновитьСвязи();
	СвязиСОшибкой = ЗначениеЗаполнено(ТекстОшибки);
	Если СвязиСОшибкой Тогда
		
		Если СвязиНоваяСтрока Тогда
			
			ВосстановленнаяСтрока = ЭтотОбъект["ITKСвязи"].Добавить();
			ЗаполнитьЗначенияСвойств(ВосстановленнаяСтрока, ТекущиеДанные);
			
		Иначе
			СвязиУсловиеСОшибкой = ТекущиеДанные.Условие;
		КонецЕсли;
		
		ОповещениеОповещения = Новый ОписаниеОповещения("ИТК_ЗавершенВопросОбновлениеСвязейПрошлоСОшибкойЗавершение", ЭтотОбъект);
		
		ШаблонТекстаВопроса = НСтр("ru = 'В условии связи ошибка:
									|%1'; en = 'There is an error in the connection condition:
									|%1'");
		
		КнопкиВопроса = Новый СписокЗначений;
		КнопкиВопроса.Добавить(КодВозвратаДиалога.Да, НСтр("ru = 'Продолжить редактирование'; en = 'Continue editing'"));
		КнопкиВопроса.Добавить(Неопределено, НСтр("ru = 'Отменить изменения'; en = 'Canceled changes'"));
		ПоказатьВопрос(ОповещениеОповещения, СтрШаблон(ШаблонТекстаВопроса, ТекстОшибки), КнопкиВопроса, , КодВозвратаДиалога.Да);
		
	Иначе
		СвязиУсловиеСОшибкой = Неопределено;
	КонецЕсли;
	
КонецПроцедуры

&НаКлиенте
Процедура ПодключаемыйITKСвязиПередУдалением(Элемент, Отказ) Экспорт
	
	ТекущиеДанные = Элемент.ТекущиеДанные;
	
	ChangeJoinAtCache(2, ТекущиеДанные.Таблица1, ТекущиеДанные.Таблица2);
	
	ОбновитьСвязи();
	
КонецПроцедуры

&НаКлиенте
Процедура ПодключаемыйITKСвязиТаблица1НачалоВыбора(Элемент, ДанныеВыбора, СтандартнаяОбработка) Экспорт
	
	ИТК_КонструкторЗапросовКлиент.ЗаполнитьСписокВыбораИсточникаСвязей(ЭтотОбъект, ДанныеВыбора, СтандартнаяОбработка, "Таблица2");
	
КонецПроцедуры

&НаКлиенте
Процедура ПодключаемыйITKСвязиТаблица2НачалоВыбора(Элемент, ДанныеВыбора, СтандартнаяОбработка) Экспорт
	
	ИТК_КонструкторЗапросовКлиент.ЗаполнитьСписокВыбораИсточникаСвязей(ЭтотОбъект, ДанныеВыбора, СтандартнаяОбработка, "Таблица1");
	
КонецПроцедуры

&НаКлиенте
Процедура ПодключаемыйITKСвязиУсловиеНачалоВыбора(Элемент, ДанныеВыбора, СтандартнаяОбработка) Экспорт
	
	СтандартнаяОбработка = Ложь;
	ТекущиеДанные = Элементы.ITKСвязи.ТекущиеДанные;
	
	// Вызвать стандартное изменение
	SaveAllFieldsForGroupingToTempStorage();
	
	Params = New Structure;
	Params.Insert("FieldsAddress", AllFieldsForGroupingAddress);
	Params.Insert("Expression", ТекущиеДанные.Условие);

	CurrentRow = Items.Joins.CurrentRow;
	Items.Joins.CurrentRow = Undefined;
	Items.Joins.CurrentRow = CurrentRow;

	Params.Insert("Changed", True);
	Params.Insert("QueryWizardAddress", QueryWizardAddress);
	Params.Insert("CurrentQuerySchemaSelectQuery", CurrentQuerySchemaSelectQuery);
	Params.Insert("CurrentQuerySchemaOperator", CurrentQuerySchemaOperator);
	Params.Insert("NestedQueryPositionAddress", NestedQueryPositionAddress);
	
	ИдентификаторВнешнихИсточников = ИТК_КонструкторЗапросовКлиентСервер.ИдентификаторЗначенийВнешнихИсточников();
	Params.Insert(ИдентификаторВнешнихИсточников, ЭтотОбъект.Object[ИдентификаторВнешнихИсточников]);
	
	Notification = New NotifyDescription("ИзмененоУсловияСвязи", ThisForm, Params);
    OpenForm("DataProcessor.ИТК_QueryWizard15.Form.ArbitraryExpression", Params, ThisForm,,,,Notification,
             FormWindowOpeningMode.LockOwnerWindow);
	
КонецПроцедуры

&НаКлиенте
Процедура ИзмененоУсловияСвязи(ChildForm, Params) Экспорт 
	
	If ChildForm = Undefined Then
		Return;
	EndIf;

	If Params["Changed"] Then
		ErrorMessage = "";
		If NOT(ChangeJoinExpression(Items.Joins.CurrentRow, Params["Expression"], False, ErrorMessage)) Then
			StartRow = -1;
			StartCol = -1;
			GetErrorTextBounds(StartRow, StartCol, ErrorMessage);
			ChildForm.SetTextSelectionBounds(StartRow, StartCol);
			AddErrorMessage(ErrorMessage);
			ShowErrorMessage();
		Else
			ChildForm.Closing = True;
			ChildForm.Close();
			
			ТекущиеДанные = Элементы.ITKСвязи.ТекущиеДанные;
			ТекущиеДанные.Условие = Params.Expression;
			
			StartEdit = False;
		EndIf;
	Else
		ChildForm.Closing = True;
		ChildForm.Close();
		StartEdit = False;
	EndIf;
	
КонецПроцедуры

&НаКлиенте
Функция ОбновитьСвязи()
	
	Var PagesItems;
	
	SetPageState("JoinsPage", True);
	
	ТекстОшибки = Неопределено;
	// Содержимое FillPagesAtClient()
	PagesItems = PreFillAtClient();
	If (PagesItems <> Undefined)
			AND (PagesItems.Count() > 0) Then
		FillPagesAtServer(PagesItems);
		PostFillAtClient(PagesItems);
		
		ТекстОшибки = ErrorMessages;
		ErrorMessages = Неопределено;
		NewQueryBatchCount = 0;
		
	EndIf;
	
	ПодключитьОбработчикОжидания("ВернутьВыделениеСвязей", 0.1, Истина);
	
	Возврат ТекстОшибки;
	
КонецФункции

&НаКлиенте
Процедура ВернутьВыделениеСвязей() Экспорт
	
	Имя = ИТК_КонструкторЗапросовКлиентСервер.ИмяРеквизитаСвязи();
	Данные = ЭтотОбъект[Имя];
	Элемент = Элементы[Имя];
	
	// Ищем по именам таблиц
	ТекущаяСтрока = Неопределено;
	Для Каждого СтрокаСвязи Из Данные Цикл 
		
		Если СтрокаСвязи.Таблица1 = СвязиТаблица1
				И СтрокаСвязи.Таблица2 = СвязиТаблица2 Тогда
				
			ТекущаяСтрока = СтрокаСвязи.ПолучитьИдентификатор();
			Прервать;
				
		КонецЕсли;

	КонецЦикла;
	
	АктивироватьПервуюСтроку = (ТекущаяСтрока = Неопределено И ЗначениеЗаполнено(Данные));
	Если АктивироватьПервуюСтроку Тогда
			
		ТекущаяСтрока = Данные[0].ПолучитьИдентификатор();
		
	КонецЕсли;
	
	Элемент.ТекущаяСтрока = ТекущаяСтрока;
	
КонецПроцедуры

&НаКлиенте
Процедура ИТК_ЗавершенВопросОбновлениеСвязейПрошлоСОшибкойЗавершение(Результат, ДополнительныеПараметры) Экспорт
	
	Если Результат = Неопределено Тогда
		
		СвязиСОшибкой = Неопределено;
		СвязиУсловиеСОшибкой = Неопределено;
		
	Иначе
		
		ТекущиеДанные = Элементы.ITKСвязи.ТекущиеДанные;
		
		Если НЕ СвязиНоваяСтрока Тогда
			ТекущиеДанные.Условие = СвязиУсловиеСОшибкой;
		КонецЕсли;
		
		ТекущийЭлемент = Элементы.ITKСвязиУсловие;
		Элементы.ITKСвязи.ИзменитьСтроку();
		
	КонецЕсли;
	
КонецПроцедуры

&НаСервере
Процедура ОбработкаЗаполненияПустыхПолейОбъединения(ПараметрыЗаполнения)
	
	ИТК_КонструкторЗапросов.ОбработкаЗаполненияПустыхПолейОбъединения(ЭтотОбъект, ПараметрыЗаполнения);
	
КонецПроцедуры

&НаСервере
Процедура ИТК_УдалитьИзЗапросаИтогиАвтоупорядочивание() Экспорт
	ИТК_КонструкторЗапросов.УдалитьИзЗапросаИтогиАвтоупорядочивание(ЭтотОбъект);
КонецПроцедуры

&НаКлиенте
Procedure ИТК_SourcesПередНачаломИзменения(Элемент, Отказ)
	
	// ITK 50
	ТекущиеДанные = Sources.НайтиПоИдентификатору(Элемент.ТекущаяСтрока);
	Если ТекущиеДанные.ПолучитьРодителя() <> Неопределено Тогда
		Отказ = Истина;
	КонецЕсли;
	
EndProcedure

&AtServer
Procedure SetJoinsPageVisibleServer()
	State = (Sources.GetItems().Count() > 1) AND (QueryType <> 2);
	SetPageVisableServer(Items.JoinsPage, State);
EndProcedure

&AtClient
Procedure DataCompositionRequiredJoinsChildsToCache(RootTreeItem)
	Var TreeItems;
	Var lTreeItem;
	Var ChangeParam;
	Var NewItem;
	
	TreeItems = RootTreeItem.GetItems();
	For Each TreeItem In TreeItems Do
		
		ChangeParam = New Structure;
		ChangeParam.Insert("Parent", 		RootTreeItem["Presentation"]);
		ChangeParam.Insert("Alias", 		TreeItem["Presentation"]);
		ChangeParam.Insert("Required", 		TreeItem["Required"]);
		ChangeParam.Insert("GroupBegin",	TreeItem["GroupBegin"]);
		
		NewItem = ChangesCache.Add();
		NewItem["ChangeType"] = "ChangeDataCompositionRequiredJoins";
		NewItem["Parameters"] = ChangeParam;
		
		DataCompositionRequiredJoinsChildsToCache(TreeItem);
	EndDo;	
EndProcedure

&AtClient
Procedure DataCompositionRequiredJoinsChangesToCache()
	Var RootItem;
	Var TreeItems;
	Var TreeItem;
	
	RootItem = DataCompositionRequiredJoins.GetItems()[0];	
	TreeItems = RootItem.GetItems();
	For Each TreeItem In TreeItems Do		
		DataCompositionRequiredJoinsChildsToCache(TreeItem);
	EndDo;		
EndProcedure

&AtClient
Procedure DataCompositionFieldsChangesToCache()
	Var Change;
	Var NewItem;
	Var TreeItems;
	Var Count;
	Var Pos;
	Var Item;

	Change = New Structure;
	Change.Insert("Type", "Clear");
	NewItem = ChangesCache.Add();
	NewItem["ChangeType"] = "ChangeDataCompositionFields";
	NewItem["Parameters"] = Change;

	TreeItems = DataCompositionFields.GetItems();
	Count = TreeItems.Count();
	For Pos = 0 To Count - 1 Do
		Item = TreeItems.Get(Pos);

		Change = New Structure;
		Change.Insert("Type", 			"Add");
		Change.Insert("Expression", 	Item["Expression"]);
		Change.Insert("UseAttributes", 	Item["UseAttributes"]);
		Change.Insert("Alias", 			Item["Alias"]);

		NewItem = ChangesCache.Add();
		NewItem["ChangeType"] = "ChangeDataCompositionFields";
		NewItem["Parameters"] = Change;
	EndDo;
EndProcedure

&AtClient
Procedure DataCompositionFiltersChangesToCache()
	Var Change;
	Var NewItem;
	Var TreeItems;
	Var Count;
	Var Pos;
	Var Item;

	Change = New Structure;
	Change.Insert("Type", "Clear");
	NewItem = ChangesCache.Add();
	NewItem["ChangeType"] = "ChangeDataCompositionFilters";
	NewItem["Parameters"] = Change;

	TreeItems = DataCompositionFilters.GetItems();
	Count = TreeItems.Count();
	For Pos = 0 To Count - 1 Do
		Item = TreeItems.Get(Pos);

		Change = New Structure;
		Change.Insert("Type", 			"Add");
		Change.Insert("Expression", 	Item["Expression"]);
		Change.Insert("UseAttributes", 	Item["UseAttributes"]);
		Change.Insert("Alias", 			Item["Alias"]);

		NewItem = ChangesCache.Add();
		NewItem["ChangeType"] = "ChangeDataCompositionFilters";
		NewItem["Parameters"] = Change;
	EndDo;
EndProcedure

&AtClient
Procedure CharacteristicsChangesToCache()
	Var Change;
	Var NewItem;
	Var TreeItems;
	Var Count;
	Var Pos;
	Var Item;

	Change = New Structure;
	Change.Insert("Type", "Clear");
	NewItem = ChangesCache.Add();
	NewItem["ChangeType"] = "ChangeCharacteristics";
	NewItem["Parameters"] = Change;

	TreeItems = Characteristics.GetItems();
	Count = TreeItems.Count();
	For Pos = 0 To Count - 1 Do
		Item = TreeItems.Get(Pos);

		Change = New Structure;
		Change.Insert("Type", "Add");
		Change.Insert("CharType", 		Item["Type"]);
		Change.Insert("KeyField", 		Item["KeyField"]);
		Change.Insert("NameField", 		Item["NameField"]);
		Change.Insert("ValueTypeField", Item["ValueTypeField"]);
		Change.Insert("ObjectField", 	Item["ObjectField"]);
		Change.Insert("TypeField", 		Item["TypeField"]);
		Change.Insert("ValueField", 	Item["ValueField"]);

		If (Item["CharacteristicTypesSource"] = Nstr("ru = 'Таблица';
													|SYS = 'Table'", "ru")) Then
			Change.Insert("CharacteristicTypesTable", Item["CharacteristicTypes"]);
			Change.Insert("CharacteristicTypesQuery", "");
		ElsIf (Item["CharacteristicTypesSource"] = Nstr("ru = 'Запрос';
														|SYS = 'Query'", "ru")) Then
			Change.Insert("CharacteristicTypesQuery", Item["CharacteristicTypes"]);
			Change.Insert("CharacteristicTypesTable", "");			
		EndIf;
		
		If (Item["CharacteristicValuesSource"] = Nstr("ru = 'Таблица';
														|SYS = 'Table'", "ru")) Then
			Change.Insert("CharacteristicValuesTable", Item["CharacteristicValues"]);
			Change.Insert("CharacteristicValuesQuery", "");
		ElsIf (Item["CharacteristicValuesSource"] = Nstr("ru = 'Запрос';
														|SYS = 'Query'", "ru")) Then
			Change.Insert("CharacteristicValuesQuery", Item["CharacteristicValues"]);
			Change.Insert("CharacteristicValuesTable", "");			
		EndIf;
		
		NewItem = ChangesCache.Add();
		NewItem["ChangeType"] = "ChangeCharacteristics";
		NewItem["Parameters"] = Change;
	EndDo;
EndProcedure

&AtServer
Procedure FillDataCompositionRequiredJoinsPage(Val RequiredJoinsTree, Val SchemSources, MainObject)
	Var JoinsRoot;
	Var Count;
	Var Pos;
	Var SchemSource;
	Var Array;
	Var Alias;
	Var P;
	Var ArrayItem;
	Var Picture;
	Var JoinsCount;
	Var Pos1;
	Var Join;
	Var ErrorMess;
	Var Condition;
	Var RequiredJoin;
	Var NotRequiredJoinsGroupBegin;
	Var CanHaveParameters;

	If RequiredJoinsTree.Count() > 0 Then
		JoinsRoot = RequiredJoinsTree.Get(0);
		JoinsRoot.GetItems().Clear();
	Else
		JoinsRoot = RequiredJoinsTree.Add();

		JoinsRoot["Presentation"] = NStr("ru = 'Таблицы';
										|SYS = 'QueryEditor.Tables'", "ru");
		JoinsRoot["Type"] = 0;
		JoinsRoot["Picture"] = -1;
		JoinsRoot["CanHaveParameters"] = False;
		JoinsRoot["Required"] = True;
		JoinsRoot["GroupBegin"] = False;
		JoinsRoot["Index"] = -1;
	EndIf;

	RequiredJoinsTree = JoinsRoot.GetItems();
	Array = New Array;
	Count = SchemSources.Count();
	For Pos = 0 To Count-1 Do
		SchemSource = SchemSources.Get(Pos);
		Alias = SchemSource.Source.Alias;

		Picture = -1;
		If TypeOf(SchemSource.Source) = Type("QuerySchemaTable") Then
			Picture = GetPictureForSource(MainObject, SchemSource.Source.TableName);
		ElsIf TypeOf(SchemSource.Source) = Type("QuerySchemaNestedQuery") Then
			Picture = GetPictureForSource(MainObject, "NestedQuery");
		ElsIf TypeOf(SchemSource.Source) = Type("QuerySchemaTempTableDescription") Then
			Picture = GetPictureForSource(MainObject, "TempTable");
		EndIf;

		JoinsCount = SchemSource.Joins.Count();
		P = FindItemInJoinsArray(Array, "", Alias, True);
		If P = -1 Then
			ArrayItem = New Structure("Parent", "");
			ArrayItem.Insert("Expression", "");
			ArrayItem.Insert("Child", Alias);
			ArrayItem.Insert("Picture", Picture);
			ArrayItem.Insert("CanHaveParameters", 
								(TypeOf(SchemSource.Source) = Type("QuerySchemaTable")) AND 
								(SchemSource.Source.DataCompositionParameters.Count() > 0));
			ArrayItem.Insert("RequiredJoin", True);
			ArrayItem.Insert("NotRequiredJoinsGroupBegin", False);
			Array.Add(ArrayItem);
		EndIf;

		For Pos1 = 0 To JoinsCount - 1 Do
			RequiredJoin = True;
			NotRequiredJoinsGroupBegin = False;
			Try
				Join = SchemSource.Joins.Get(Pos1);
				Condition = Join.Condition;
				RequiredJoin = Join.RequiredJoin;
				NotRequiredJoinsGroupBegin = Join.OptionalJoinsGroupBegin;
			Except
				ErrorMess = BriefErrorDescription(ErrorInfo());
				AddErrorMessageAtServerNoContext(ErrorMessages, ErrorMess);
				Condition = ErrorMess;
			EndTry;

			ArrayItem = New Structure("Parent", Alias);

			CanHaveParameters = False;
			Picture = -1;
			If TypeOf(Join.Source.Source) = Type("QuerySchemaTable") Then
				Picture = GetPictureForSource(MainObject, Join.Source.Source.TableName);
				If (Join.Source.Source.DataCompositionParameters.Count() > 0) Then
					CanHaveParameters = True;
				EndIf;
			ElsIf TypeOf(Join.Source.Source) = Type("QuerySchemaNestedQuery") Then
				Picture = GetPictureForSource(MainObject, "NestedQuery");
			ElsIf TypeOf(Join.Source.Source) = Type("QuerySchemaTempTableDescription") Then
				Picture = GetPictureForSource(MainObject, "TempTable");
			EndIf;

			ArrayItem.Insert("Expression", String(Condition));
			ArrayItem.Insert("Child", Join.Source.Source.Alias);
			ArrayItem.Insert("Picture", Picture);
			ArrayItem.Insert("CanHaveParameters", CanHaveParameters);
			ArrayItem.Insert("RequiredJoin", RequiredJoin);
			ArrayItem.Insert("NotRequiredJoinsGroupBegin", NotRequiredJoinsGroupBegin);

			P = FindItemInJoinsArray(Array, "", Join.Source.Source.Alias, False);
			If P <> -1 Then
				Array.Delete(P);
			EndIf;

			Array.Add(ArrayItem);
		EndDo;
	EndDo;

	RequiredJoinsTree.Clear();
	TmpNumber = 0;
	FillRequiredJoins(RequiredJoinsTree, Array, "");
EndProcedure

&AtServer
Procedure FillRequiredJoins(Val RequiredJoinsTree, Val Array, Val ParentName)
	Var Count;
	Var Pos;
	Var ChildItemCount;
	Var P;
	Var ChildItem;
	Var NewTable;
	Var NewElement;
	Var JoinElement;
	Var AndText;
	
	Count = Array.Count();
	For Pos = 0 To  Count-1 Do
		If Array[Pos]["Parent"] = ParentName Then
			NewTable = Array[Pos]["Child"];
			ChildItemCount = RequiredJoinsTree.Count();
			NewElement = Undefined;
			For P = 0 To  ChildItemCount-1 Do
				ChildItem = RequiredJoinsTree.Get(P);
				If ChildItem["Presentation"] = NewTable Then
					NewElement = ChildItem;
					Break;
				EndIf;
			EndDo;
			If NewElement = Undefined Then
				NewElement = RequiredJoinsTree.Add();
			EndIf;

			If ParentName = "" Then
				NewElement["Type"] = 1;
			Else
				NewElement["Type"] = 2;
			EndIf;
			NewElement["Picture"] = Array[Pos]["Picture"];
			NewElement["Presentation"] = NewTable;
			NewElement["CanHaveParameters"] = Array[Pos]["CanHaveParameters"];
			NewElement["Required"] = Array[Pos]["RequiredJoin"];
			NewElement["GroupBegin"] = Array[Pos]["NotRequiredJoinsGroupBegin"];
			NewElement["Index"] = TmpNumber;
			TmpNumber = TmpNumber + 1;

			FillRequiredJoins(NewElement.GetItems(), Array, NewTable);
		EndIf;
	EndDo;
EndProcedure

&AtServer
Procedure FillDataCompositionFields(Val AllFieldsTree, Val FieldsFieldsTree, Query, MainObject)
	Var OperatorFieldFields;
	Var AllFields;
	Var Count;
	Var Pos;
	Var ExpressionString;
	Var NewElement;

	AllFieldsTree.Clear();
	FieldsFieldsTree.Clear();

	AllFields = Query.Columns;
	QueryDataCompositionSelectionFields = Query.DataCompositionSelectionFields;

	FillDataCompositionFieldsField(FieldsFieldsTree, QueryDataCompositionSelectionFields, Query, MainObject);
	Count = AllFields.Count();

	For Pos = 0 To Count-1 Do		
		 Column = AllFields.Get(Pos);
		 ExpressionString = Column.Alias;
		 NewElement = AllFieldsTree.Add();
		 NewElement["Presentation"] = Column.Alias;
		 NewElement["Index"] = Pos;
		 NewElement["AvailableField"] = True;
		 NewElement["Type"] = 2;
		 NewElement["Name"] = Column.Alias;
		 NewElement["Picture"] = GetPictureForAvailableField(MainObject, Column, Query);		
	EndDo;
EndProcedure

&AtServer
Procedure FillDataCompositionFieldsField(Val FieldsFieldsTree, Val QueryDataCompositionFields, Query, MainObject)
	Var Count;
	Var Pos;
	Var Field;
	Var NewItem;
	Var CheckRes;

	Count = QueryDataCompositionFields.Count();
	For Pos = 0 To Count - 1 Do
		Field = QueryDataCompositionFields.Get(Pos);
		
		If(TypeOf(Field.Field) = Type("QuerySchemaColumn")) Then
			CheckRes = CheckDataCompositionField(Field.Field.Alias);
			
			NewItem = FieldsFieldsTree.Add();
			NewItem["Expression"] = String(Field.Field.Alias);
			NewItem["UseAttributes"] = Field.UseAttributes;
			NewItem["Alias"] = Field.Alias;
			NewItem["CanUseAttributes"] = CheckRes["CanUseAttributes"];
		ElsIf (TypeOf(Field.Field) = Type("String")) Then
			CheckRes = CheckDataCompositionField(Field.Field);
			
			If (NOT CheckRes["CorrectExpression"]) Then
				Continue;
			EndIf;
			
			NewItem = FieldsFieldsTree.Add();
			NewItem["Expression"] = String(Field.Field);
			NewItem["UseAttributes"] = Field.UseAttributes;
			NewItem["Alias"] = Field.Alias;
			NewItem["CanUseAttributes"] = CheckRes["CanUseAttributes"];
		EndIf;
	EndDo;
EndProcedure

&AtServer
Procedure FillDataCompositionFilters(Val AllFieldsTree, Val FiltersFieldsTree, Query, Val Operator, MainObject)
	Var OperatorFilterFields;
	Var AllFields;
	Var Count;
	Var Pos;
	Var Expression;
	Var ExpressionString;
	Var NewElement;

	AllFieldsTree.Clear();
	FiltersFieldsTree.Clear();

	AllFields = Operator.SelectedFields;
	OperatorFilterFields = Operator.DataCompositionFilterExpressions;

	FillDataCompositionFiltersField(FiltersFieldsTree, OperatorFilterFields, Query, Operator, MainObject);
	Count = AllFields.Count();

	For Pos = 0 To Count-1 Do
		Expression = AllFields.Get(Pos);

		If TypeOf(Expression) = Type("QuerySchemaExpression") Then
			ExpressionString = String(Expression);

			NewElement = AllFieldsTree.Add();
			NewElement["Presentation"] = ExpressionString;
			NewElement["Index"] = Pos;
			NewElement["AvailableField"] = True;
			NewElement["Type"] = 2;
			NewElement["Name"] = ExpressionString;
			NewElement["Picture"] = GetPictureForAvailableField(MainObject, Expression, Query, Operator);
			NewElement["ValueType"] = Expression.ValueType();
		EndIf;
	EndDo;

 	NewElement = AllFieldsTree.Add();
	NewElement["Index"] = -1;
	NewElement["Type"] = -1;
	NewElement["Presentation"] = NStr("ru = 'Все поля';
										|SYS = 'QueryEditor.AllFields'", "ru");
	NewElement["Picture"] = -1;
	FillSourcesByIndex(MainObject, NewElement.GetItems(), Operator.Sources);
EndProcedure

&AtServer
Procedure FillDataCompositionFiltersField(Val FiltersFieldsTree, Val FilterFields, Query, Val Operator, MainObject)
	Var Count;
	Var Pos;
	Var Field;
	Var NewItem;
	Var CheckRes;

	Count = FilterFields.Count();
	For Pos = 0 To Count - 1 Do
		Field = FilterFields.Get(Pos);
		CheckRes = CheckDataCompositionFilter(Field.Expression);
		
		NewItem = FiltersFieldsTree.Add();
		NewItem["Expression"] = String(Field.Expression);
		NewItem["UseAttributes"] = Field.UseAttributes;
		NewItem["Alias"] = Field.Alias;
		NewItem["CanUseAttributes"] = CheckRes["CanUseAttributes"];
	EndDo;
EndProcedure

&AtServer
Procedure FillCharacteristics(Val AllCharacteristicsTree, Query)
	Var AllCharacteristics;
	Var Count;
	Var Pos;
	Var CurElement;

	AllCharacteristicsTree.Clear();

	AllCharacteristics = Query.Characteristics;
	
	Count = AllCharacteristics.Count();

	For Pos = 0 To Count-1 Do
		CurElement = AllCharacteristics.Get(Pos);
		NewItem = Characteristics.GetItems().Add();
		NewItem["Type"] = CurElement["Type"];
		NewItem["KeyField"] = CurElement["KeyField"];
		NewItem["NameField"] = CurElement["NameField"];
		NewItem["ValueTypeField"] = CurElement["ValueTypeField"];
		NewItem["ObjectField"] = CurElement["ObjectField"];
		NewItem["TypeField"] = CurElement["TypeField"];
		NewItem["ValueField"] = CurElement["ValueField"];
		
		If (CurElement["CharacteristicTypesTable"] <> "") Then
			NewItem["CharacteristicTypes"] = CurElement["CharacteristicTypesTable"];
			NewItem["CharacteristicTypesSource"] = Nstr("ru = 'Таблица';
														|SYS = 'Table'", "ru");
		Else
			NewItem["CharacteristicTypes"] = CurElement["CharacteristicTypesQuery"];
			NewItem["CharacteristicTypesSource"] = Nstr("ru = 'Запрос';
														|SYS = 'Query'", "ru");
		EndIf;
		
		If (CurElement["CharacteristicValuesTable"] <> "") Then
			NewItem["CharacteristicValues"] = CurElement["CharacteristicValuesTable"];
			NewItem["CharacteristicValuesSource"] = Nstr("ru = 'Таблица';
														|SYS = 'Table'", "ru");
		Else
			NewItem["CharacteristicValues"] = CurElement["CharacteristicValuesQuery"];
			NewItem["CharacteristicValuesSource"] = Nstr("ru = 'Запрос';
														|SYS = 'Query'", "ru");
		EndIf;		
	EndDo;
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Страница "Таблицы компоновки данных"

&AtClient
Procedure DataCompositionRequiredJoinsOnActivateRow(Item)
	Var CurrentItems;
	Var CurrentRow;

	CurrentRow = Items.DataCompositionRequiredJoins.CurrentRow;
	If (CurrentRow = Undefined) Then
		Return;
	EndIf;
	CurrentItems = DataCompositionRequiredJoins.FindByID(CurrentRow);

	If (Items.DataCompositionTableParameters.Enabled <> CurrentItems["CanHaveParameters"]) Then
		Items.DataCompositionTableParameters.Enabled = CurrentItems["CanHaveParameters"];
	EndIf;
EndProcedure

&AtClient
Procedure DataCompositionRequiredJoinsRequiredOnChange(Item)
	Var CurrentItems;
	Var CurrentRow;
	
	CurrentRow = Items.DataCompositionRequiredJoins.CurrentRow;
	If (CurrentRow = Undefined) Then
		Return;
	EndIf;
	CurrentItems = DataCompositionRequiredJoins.FindByID(CurrentRow);

	If (CurrentItems["Type"] <> 2) Then
		CurrentItems["Required"] = True;
		Return;
	EndIf;
	
	CurrentItems["GroupBegin"] = False;
	DataCompositionRequiredJoinsGroupBeginOnChange(Undefined);
	SetPageState("DataCompositionRequiredJoinsPage", True);
EndProcedure

&AtClient
Procedure DataCompositionRequiredJoinsGroupBeginOnChange(Item)
	Var CurrentItems;
	Var CurrentRow;
	Var Rit;
	Var IsInGroup;
	
	CurrentRow = Items.DataCompositionRequiredJoins.CurrentRow;
		
	If (CurrentRow = Undefined) Then
		Return;
	EndIf;
	CurrentItems = DataCompositionRequiredJoins.FindByID(CurrentRow);

	If (CurrentItems["Type"] <> 2) Then
		CurrentItems["GroupBegin"] = False;
		Return;
	EndIf;
	
	IsInGroup = False;
	For Each Rit In CurrentItems.GetParent().GetItems() Do
		If(NOT IsInGroup) Then				
			If (NOT Rit["Required"]) Then
				IsInGroup = True;
				If (NOT Rit["GroupBegin"]) Then
					Rit["GroupBegin"] = True;
				EndIf;					
			Else
				IsInGroup = False;
				If (Rit["GroupBegin"]) Then
					Rit["GroupBegin"] = False;
				EndIf;
			EndIf;
		ElsIf (Rit["Required"]) Then
			Rit["GroupBegin"] = False;
		EndIf;
	EndDo;
			
	SetPageState("DataCompositionRequiredJoinsPage", True);
EndProcedure

&AtClient
Procedure DataCompositionRequiredJoinsParametersOfTheVirtualTable(Command)
	Var CurrentRow;
	Var CurrentItems;
	Var Params;
	Var Notification;

	FixChanges();
	FillPagesAtClient();

	CurrentRow = Items.DataCompositionRequiredJoins.CurrentRow;
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	CurrentItems = DataCompositionRequiredJoins.FindByID(CurrentRow);

	Params = New Structure;
	Params.Insert("Index", CurrentItems["Index"]);
	Params.Insert("QueryWizardAddress", QueryWizardAddress);
	Params.Insert("CurrentQuerySchemaSelectQuery", CurrentQuerySchemaSelectQuery);
	Params.Insert("CurrentQuerySchemaOperator", CurrentQuerySchemaOperator);
	Params.Insert("NestedQueryPositionAddress", NestedQueryPositionAddress);
	// ITK1 + {
	ИдентификаторВнешнихИсточников = ИТК_КонструкторЗапросовКлиентСервер.ИдентификаторЗначенийВнешнихИсточников();
	Params.Insert(ИдентификаторВнешнихИсточников, ЭтотОбъект.Object[ИдентификаторВнешнихИсточников]);
	// }
	Notification = New NotifyDescription("DataCompositionTableParametersChanged", ThisForm, Params);
	OpenForm("DataProcessor.ИТК_QueryWizard15.Form.DataCompositionAvailableTableParameters", Params, ThisForm,,,,Notification,
             FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure DataCompositionTableParametersChanged(Result, Params) Export
	SetPageState("DataCompositionRequiredJoinsPage", True);
	FillPagesAtClient();
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Страница "Поля компоновки данных"

////////////////////////////////////////////////////////////////////////////////
// События таблицы полей для полей компоновки данных

&AtClient
Procedure AllFieldsForDataCompositionFieldsBeforeExpand(Item, Row, Cancel)
	Var CurrentItems;

	CurrentItems = AllFieldsForDataCompositionFields.FindByID(Row);
	If CurrentItems["AvailableField"]
		OR (CurrentItems["Type"] < 0)
		OR NOT(IsFakeItem(CurrentItems)) Then
		Return;
	EndIf;
	
	Cancel = True;
	RowForExpand = Row;
	AttachIdleHandler("AllFieldsForDataCompositionFieldsBeforeExpandHandler", 0.01, True);
EndProcedure

&AtClient
Procedure AllFieldsForDataCompositionFieldsBeforeExpandHandler()
	AllFieldsForDataCompositionFieldsBeforeExpandAtServer();
	Items.AllFieldsForDataCompositionFields.Expand(RowForExpand);
EndProcedure

&AtServer
Procedure AllFieldsForDataCompositionFieldsBeforeExpandAtServer()
	FillSourcesBeforeExpand(RowForExpand, AllFieldsForDataCompositionFields);	
EndProcedure

&AtClient
Procedure AllFieldsForDataCompositionFieldsSelection(Item, SelectedRow, Field, StandardProcessing)
	Var NamesArray;

	NamesArray = new Array();
	If Item.CurrentData["Type"] = 2 Then
		NamesArray.Add(Item.CurrentData["Name"]);
		AddDataCompositionFieldsFromFields(NamesArray);
		SetPageState("DataCompositionFieldsPage", True);
	EndIf;
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure AllFieldsForDataCompositionFieldsDragStart(Item, DragParameters, Perform)
	DragParameters.AllowedActions = DragAllowedActions.Copy;
	DragParameters.Value = "DragFromAllFieldsForDataCompositionFields";
EndProcedure

&AtClient
Procedure AllFieldsForDataCompositionFieldsDragCheck(Item, DragParameters, StandardProcessing, Row, Field)
	If DragParameters.Value = "DragFromDataCompositionFields" Then
		StandardProcessing = False;
	EndIf;
EndProcedure

&AtClient
Procedure AllFieldsForDataCompositionFieldsDrag(Item, DragParameters, StandardProcessing, Row, Field)
	DataCompositionFieldsDeleteButton(Undefined);
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// События таблицы полей компоновки данных

&AtClient
Procedure DataCompositionFieldsBeforeAddRow(Item, Cancel, Clone, Parent, Folder, Parameter)
	If NOT(Clone) Then
		DataCompositionFieldsAdd(Undefined);
	Else
		DataCompositionFieldsCopy(Undefined);
	EndIf;
	Cancel = True;
EndProcedure

&AtClient
Procedure DataCompositionFieldsBeforeDeleteRow(Item, Cancel)
	DataCompositionFieldsDelete(Undefined);
	Cancel = True;
EndProcedure

&AtClient
Procedure DataCompositionFieldsOnStartEdit(Item, NewRow, Clone)
	If NOT(StartEdit) Then
		TmpString = Item.CurrentData["Expression"];
		TmpAlias = Item.CurrentData["Alias"];
	EndIf;
	StartEdit = True;
EndProcedure

&AtClient
Procedure DataCompositionFieldsBeforeEditEnd(Item, NewRow, CancelEdit, Cancel)
	Var CurrentRow;
	
	If CancelEdit Then
		Item.CurrentData["Expression"] = TmpString;
		Item.CurrentData["Alias"] = TmpAlias;
	EndIf;

	If NOT(StartEdit) Then
		Return;
	EndIf;
	
	CurrentRow = Items.DataCompositionFields.CurrentRow;
	If (CurrentRow = Undefined) Then
		Return;
	EndIf;

	RowForEdit = CurrentRow;
	AttachIdleHandler("DataCompositionFieldsBeforeEditEndHandler", 0.01, True);
EndProcedure

&AtClient
Procedure DataCompositionFieldsOnEditEnd(Item, NewRow, CancelEdit)
	If TmpString <> Item.CurrentData["Expression"] OR
	   TmpAlias <> Item.CurrentData["Alias"] Then
		
		SetPageState("DataCompositionFieldsPage", True);
	EndIf;
EndProcedure

&AtClient
Procedure DataCompositionFieldsDragStart(Item, DragParameters, Perform)
	DragParameters.AllowedActions = DragAllowedActions.Copy;
	DragParameters.Value = "DragFromDataCompositionFields";
EndProcedure

&AtClient
Procedure DataCompositionFieldsDragCheck(Item, DragParameters, StandardProcessing, Row, Field)
	If DragParameters.Value = "DragFromAllFieldsForDataCompositionFields" Then
		StandardProcessing = False;
	EndIf;
EndProcedure

&AtClient
Procedure DataCompositionFieldsDrag(Item, DragParameters, StandardProcessing, Row, Field)
	Var Rows;
	Var CurrentRow;
	Var CurrentItems;
	Var NamesArray;

	If (DragParameters.Value = "DragFromAllFieldsForDataCompositionFields") Then
		NamesArray = new Array();
		StandardProcessing = False;
		Rows = Items.AllFieldsForDataCompositionFields.SelectedRows;
		For Each CurrentRow In Rows Do
			If (CurrentRow = Undefined) Then
				Return;
			EndIf;
			CurrentItems = AllFieldsForDataCompositionFields.FindByID(CurrentRow);
			If CurrentItems["Type"] = 2 Then
				NamesArray.Add(CurrentItems["Name"]);
			EndIf;
		EndDo;
		
		If NamesArray.Count() > 0 Then
			AddDataCompositionFieldsFromFields(NamesArray);
		EndIf;
	EndIf;
	
	SetPageState("DataCompositionFieldsPage", True);
EndProcedure

&AtClient
Procedure DataCompositionFieldExpressionStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	EditText = Item.EditText;
	AttachIdleHandler("DataCompositionFieldExpressionStartChoiceHandler", 0.01, True);
EndProcedure

&AtClient
Procedure DataCompositionFieldExpressionStartChoiceHandler()
	DataCompositionFieldExpressionChangeInDialog(EditText);
EndProcedure

&AtClient
Procedure DataCompositionFieldExpressionChangeInDialog(Val Expression, Val IsExpressionChanged = Undefined)
	Var Params;
	Var Notification;

	Params = New Structure;
	Params.Insert("FieldsAddress", AllFieldsForGroupingAddress);
	Params.Insert("Expression", Expression);

	If IsExpressionChanged <> Undefined Then
		Params.Insert("Changed", IsExpressionChanged);
	Else
		Params.Insert("Changed", False);
	EndIf;
	
	Params.Insert("QueryWizardAddress", QueryWizardAddress);
	Params.Insert("CurrentQuerySchemaSelectQuery", CurrentQuerySchemaSelectQuery);
	Params.Insert("CurrentQuerySchemaOperator", CurrentQuerySchemaOperator);
	Params.Insert("NestedQueryPositionAddress", NestedQueryPositionAddress);
	// ITK1 + {
	ИдентификаторВнешнихИсточников = ИТК_КонструкторЗапросовКлиентСервер.ИдентификаторЗначенийВнешнихИсточников();
	Params.Insert(ИдентификаторВнешнихИсточников, ЭтотОбъект.Object[ИдентификаторВнешнихИсточников]);
	// }
	Notification = New NotifyDescription("DataCompositionFieldExpressionChanged", ThisForm, Params);
    OpenForm("DataProcessor.ИТК_QueryWizard15.Form.ArbitraryExpression", Params, ThisForm,,,,Notification,
             FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure DataCompositionFieldExpressionChanged(ChildForm, Params) Export
	Var ErrorMessage;
	Var StartCol;
	Var StartRow;
	Var CurrentItems;
	Var CheckRes;

	If ChildForm = Undefined Then
		Return;
	EndIf;

	If Params["Changed"] Then
		ErrorMessage = "";
		CheckRes = CheckDataCompositionField(Params["Expression"], ErrorMessage);
		
		If NOT(CheckRes["CorrectExpression"]) Then
			StartRow = -1;
			StartCol = -1;
			GetErrorTextBounds(StartRow, StartCol, ErrorMessage);
			ChildForm.SetTextSelectionBounds(StartRow, StartCol);
			AddErrorMessage(ErrorMessage);
			ShowErrorMessage();
		Else
			ChildForm.Closing = True;
			ChildForm.Close();

			If Items.DataCompositionFields.CurrentRow <> Undefined Then
				CurrentItems = DataCompositionFields.FindByID(Items.DataCompositionFields.CurrentRow);
			EndIf;
			If (CurrentItems = Undefined) Then
				Return;
			EndIf;
			CurrentItems["Expression"] = Params["Expression"];
			CurrentItems["CanUseAttributes"] = CheckRes["CanUseAttributes"];
			
			If CurrentItems["UseAttributes"] AND NOT CheckRes["CanUseAttributes"] Then
				CurrentItems["UseAttributes"] = CheckRes["CanUseAttributes"];
			EndIf;
			
			SetPageState("DataCompositionFieldsPage", True);
		EndIf;
	Else
		ChildForm.Closing = True;
		ChildForm.Close();
		CurrentItems = DataCompositionFields.FindByID(Items.DataCompositionFields.CurrentRow);
		CurrentItems["Expression"] = TmpString;
	EndIf;
	StartEdit = False;

EndProcedure

&AtClient
Procedure DataCompositionFieldsUseAttributesOnChange(Item)
	Var CurrentRow;
	
	CurrentRow = DataCompositionFields.FindByID(Items.DataCompositionFields.CurrentRow);
	TmpBool = NOT CurrentRow["UseAttributes"];
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	If CurrentRow["UseAttributes"] AND NOT CurrentRow["CanUseAttributes"] Then
		CurrentRow["UseAttributes"] = False;
	EndIf;
	
	If CurrentRow["UseAttributes"] <> TmpBool Then
		SetPageState("DataCompositionFieldsPage", True);
	EndIf;
EndProcedure

&AtClient
Procedure DataCompositionFieldsBeforeEditEndHandler()
	Var CurrentRow;
	Var CheckRes;
	Var ErrorMessage;
	
	CurrentRow = DataCompositionFields.FindByID(RowForEdit);
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	ErrorMessage = "";
	CheckRes = CheckDataCompositionField(CurrentRow["Expression"], ErrorMessage);
	
	If NOT(CheckRes["CorrectExpression"]) Then
		ShowMessageBox( , ErrorMessage);
		Items.DataCompositionFields.CurrentRow = RowForEdit;
		Items.DataCompositionFields.ChangeRow();
		StartEdit = True;
		Return;
	EndIf;
	
	If CurrentRow["UseAttributes"] AND NOT CheckRes["CanUseAttributes"] Then
		CurrentRow["UseAttributes"] = CheckRes["CanUseAttributes"];
	EndIf;
	CurrentRow["CanUseAttributes"] = CheckRes["CanUseAttributes"];
	StartEdit = False;
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Команды таблицы полей компоновки данных

&AtClient
Procedure DataCompositionFieldsAdd(Command)
	Var NewItem;

	NewItem = DataCompositionFields.GetItems().Add();
	NewItem["Expression"] = "";
	NewItem["UseAttributes"] = False;
	NewItem["Alias"] = "";
	NewItem["CanUseAttributes"] = False;
	Items.DataCompositionFields.CurrentRow = NewItem.GetID();
	SetPageState("DataCompositionFieldsPage", True);
EndProcedure

&AtClient
Procedure DataCompositionFieldsCopy(Command)
	Var Rows;
	Var CurrentRow;
	Var CurrentItems;
	Var NewItem;

	Rows = Items.DataCompositionFields.SelectedRows;
	For Each CurrentRow In Rows Do
		CurrentItems = DataCompositionFields.FindByID(CurrentRow);
		NewItem = DataCompositionFields.GetItems().Add();
		NewItem["Expression"] = CurrentItems["Expression"];
		NewItem["UseAttributes"] = CurrentItems["UseAttributes"];
		NewItem["Alias"] = CurrentItems["Alias"];
		NewItem["CanUseAttributes"] = CurrentItems["CanUseAttributes"];
	EndDo;
	Items.DataCompositionFields.CurrentRow = NewItem.GetID();
	SetPageState("DataCompositionFieldsPage", True);
EndProcedure

&AtClient
Procedure DataCompositionFieldsDelete(Command)
	Var CurrentRow;
	Var CurrentItems;

	While Items.DataCompositionFields.SelectedRows.Count() > 0 Do
		CurrentRow = Items.DataCompositionFields.SelectedRows[0];
		CurrentItems = DataCompositionFields.FindByID(CurrentRow);
		DataCompositionFields.GetItems().Delete(DataCompositionFields.GetItems().IndexOf(CurrentItems));
	EndDo;
	SetPageState("DataCompositionFieldsPage", True);
EndProcedure

&AtClient
Procedure DataCompositionFieldsAddButton(Command)
	Var Rows;
	Var CurrentRow;
	Var CurrentItems;
	Var CanUseAttributes;
	Var NamesArray;

	NamesArray = new Array();
	Rows = Items.AllFieldsForDataCompositionFields.SelectedRows;
	For Each CurrentRow In Rows Do
		If (CurrentRow = Undefined) Then
			Break;;
		EndIf;
		CurrentItems = AllFieldsForDataCompositionFields.FindByID(CurrentRow);

		If CurrentItems["Type"] = 2 Then
			NamesArray.Add(CurrentItems["Name"]);
		EndIf;
	EndDo;
	
	If NamesArray.Count() > 0 Then
		AddDataCompositionFieldsFromFields(NamesArray);
		SetPageState("DataCompositionFieldsPage", True);
	EndIf;
EndProcedure

&AtClient
Procedure DataCompositionFieldsAddAllButton(Command)
	Var CurrentRow;
	Var CurrentItems;
	Var ConditionItems;
	Var CanUseAttributes;
	Var NamesArray;

	NamesArray = new Array();

	For Each CurrentItems In AllFieldsForDataCompositionFields.GetItems() Do
				
		If CurrentItems["Type"] = 2 Then
			NamesArray.Add(CurrentItems["Name"]);
		EndIf;
	EndDo;
	
	If NamesArray.Count() > 0 Then
		AddDataCompositionFieldsFromFields(NamesArray);
		SetPageState("DataCompositionFieldsPage", True);
	EndIf;
EndProcedure

&AtClient
Procedure DataCompositionFieldsDeleteButton(Command)
	Var CurrentRow;
	Var CurrentItems;

	While Items.DataCompositionFields.SelectedRows.Count() > 0 Do
		CurrentRow = Items.DataCompositionFields.SelectedRows[0];
		CurrentItems = DataCompositionFields.FindByID(CurrentRow);
		DataCompositionFields.GetItems().Delete(DataCompositionFields.GetItems().IndexOf(CurrentItems));
	EndDo;
	SetPageState("DataCompositionFieldsPage", True);
EndProcedure

&AtClient
Procedure DataCompositionFieldsDeleteAllButton(Command)
	DataCompositionFields.GetItems().Clear();
	SetPageState("DataCompositionFieldsPage", True);
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Серверные вызовы для полей компоновки данных

&AtServer
Procedure AddDataCompositionFieldsFromFields(Val NamesArray)
	Var NewItem;
	Var CheckRes;
	Var FieldName;
	
	For Each FieldName In NamesArray Do
		
		CheckRes = CheckDataCompositionField(FieldName);
		NewItem = DataCompositionFields.GetItems().Add();
		NewItem["Expression"] = FieldName;
		NewItem["UseAttributes"] = CheckRes["CanUseAttributes"];
		NewItem["Alias"] = "";
		NewItem["CanUseAttributes"] = CheckRes["CanUseAttributes"];
	EndDo;
	
	Items.DataCompositionFields.CurrentRow = NewItem.GetID();
EndProcedure

&AtServer
Function CheckDataCompositionField(Expression, ErrorMessage = Undefined)
	Var QuerySchema;
	Var Query;
	Var Operators;
	Var Operator;
	Var RetStruct;
	
	RetStruct = new Structure("CorrectExpression, CanUseAttributes");

	QuerySchema = GetFromTempStorage(QueryWizardAddress);
	If QuerySchema = Undefined Then
		RetStruct["CorrectExpression"] = True;
		RetStruct["CanUseAttributes"] = False;
		Return RetStruct;
	EndIf;

	Batch = QuerySchema.QueryBatch;
	Query = GetSchemaQuery(QuerySchema, CurrentQuerySchemaSelectQuery, NestedQueryPositionAddress);

	If TypeOf(Query) = Type("QuerySchemaSelectQuery") Then
		Operators  = Query.Operators;
		Operator = Operators.Get(CurrentQuerySchemaOperator);
	Else
		RetStruct["CorrectExpression"] = True;
		RetStruct["CanUseAttributes"] = False;
		Return RetStruct;
	EndIf;

	Try
		Query.DataCompositionSelectionFields.Add(Expression);
		Condition = String(Query.DataCompositionSelectionFields.Get(Query.DataCompositionSelectionFields.Count() - 1).Field);
		RetStruct["CorrectExpression"] = True;
		
		Query.DataCompositionSelectionFields.Get(Query.DataCompositionSelectionFields.Count() - 1).UseAttributes = True;
		RetStruct["CanUseAttributes"] = Query.DataCompositionSelectionFields.Get(Query.DataCompositionSelectionFields.Count() - 1).UseAttributes;
		
		Query.DataCompositionSelectionFields.Delete(Query.DataCompositionSelectionFields.Count() - 1);
	Except
		If ErrorMessage = Undefined Then
			AddErrorMessageAtServer(BriefErrorDescription(ErrorInfo()));
		Else
			ErrorMessage = BriefErrorDescription(ErrorInfo());
		EndIf;
		RetStruct["CorrectExpression"] = False;
	EndTry;
	
	Return RetStruct;
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Страница "Условия компоновки данных"

////////////////////////////////////////////////////////////////////////////////
// События таблицы полей для условий компоновки данных

&AtClient
Procedure AllFieldsForDataCompositionFiltersBeforeExpand(Item, Row, Cancel)
	Var CurrentItems;

	CurrentItems = AllFieldsForDataCompositionFilters.FindByID(Row);
	If CurrentItems["AvailableField"]
		OR (CurrentItems["Type"] < 0)
		OR NOT(IsFakeItem(CurrentItems)) Then
		Return;
	EndIf;
	
	Cancel = True;
	RowForExpand = Row;
	AttachIdleHandler("AllFieldsForDataCompositionFiltersBeforeExpandHandler", 0.01, True);
EndProcedure

&AtClient
Procedure AllFieldsForDataCompositionFiltersBeforeExpandHandler()
	AllFieldsForDataCompositionFiltersBeforeExpandAtServer();
	Items.AllFieldsForDataCompositionFilters.Expand(RowForExpand);
EndProcedure

&AtServer
Procedure AllFieldsForDataCompositionFiltersBeforeExpandAtServer()
	FillSourcesBeforeExpand(RowForExpand, AllFieldsForDataCompositionFilters);	
EndProcedure

&AtClient
Procedure AllFieldsForDataCompositionFiltersSelection(Item, SelectedRow, Field, StandardProcessing)
	Var NamesArray;

	NamesArray = new Array();
	If Item.CurrentData["Type"] = 2 Then
		NamesArray.Add(Item.CurrentData["Name"]);
		AddDataCompositionFiltersFromFields(NamesArray);
		SetPageState("DataCompositionFiltersPage", True);
	EndIf;
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure AllFieldsForDataCompositionFiltersDragStart(Item, DragParameters, Perform)
	DragParameters.AllowedActions = DragAllowedActions.Copy;
	DragParameters.Value = "DragFromAllFieldsForDataCompositionFilters";
EndProcedure

&AtClient
Procedure AllFieldsForDataCompositionFiltersDragCheck(Item, DragParameters, StandardProcessing, Row, Field)
	If DragParameters.Value = "DragFromDataCompositionFilters" Then
		StandardProcessing = False;
	EndIf;
EndProcedure

&AtClient
Procedure AllFieldsForDataCompositionFiltersDrag(Item, DragParameters, StandardProcessing, Row, Field)
	DataCompositionFiltersDeleteButton(Undefined);
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// События таблицы условий компоновки данных

&AtClient
Procedure DataCompositionFiltersBeforeAddRow(Item, Cancel, Clone, Parent, Folder, Parameter)
	If NOT(Clone) Then
		DataCompositionFiltersAdd(Undefined);
	Else
		DataCompositionFiltersCopy(Undefined);
	EndIf;
	Cancel = True;
EndProcedure

&AtClient
Procedure DataCompositionFiltersBeforeDeleteRow(Item, Cancel)
	DataCompositionFiltersDelete(Undefined);
	Cancel = True;
EndProcedure

&AtClient
Procedure DataCompositionFiltersOnStartEdit(Item, NewRow, Clone)
	If NOT(StartEdit) Then
		TmpString = Item.CurrentData["Expression"];
		TmpAlias = Item.CurrentData["Alias"];
	EndIf;
	StartEdit = True;
EndProcedure

&AtClient
Procedure DataCompositionFiltersBeforeEditEnd(Item, NewRow, CancelEdit, Cancel)
	Var CurrentRow;
	
	If CancelEdit Then
		Item.CurrentData["Expression"] = TmpString;
		Item.CurrentData["Alias"] = TmpAlias;
	EndIf;

	If NOT(StartEdit) Then
		Return;
	EndIf;
	
	CurrentRow = Items.DataCompositionFilters.CurrentRow;
	If (CurrentRow = Undefined) Then
		Return;
	EndIf;

	RowForEdit = CurrentRow;
	AttachIdleHandler("DataCompositionFiltersBeforeEditEndHandler", 0.01, True);
EndProcedure

&AtClient
Procedure DataCompositionFiltersOnEditEnd(Item, NewRow, CancelEdit)
	If TmpString <> Item.CurrentData["Expression"] OR
	   TmpAlias <> Item.CurrentData["Alias"] Then
		
		SetPageState("DataCompositionFiltersPage", True);
	EndIf;
EndProcedure

&AtClient
Procedure DataCompositionFiltersDragStart(Item, DragParameters, Perform)
	DragParameters.AllowedActions = DragAllowedActions.Copy;
	DragParameters.Value = "DragFromDataCompositionFilters";
EndProcedure

&AtClient
Procedure DataCompositionFiltersDragCheck(Item, DragParameters, StandardProcessing, Row, Field)
	If DragParameters.Value = "DragFromAllFieldsForDataCompositionFilters" Then
		StandardProcessing = False;
	EndIf;
EndProcedure

&AtClient
Procedure DataCompositionFiltersDrag(Item, DragParameters, StandardProcessing, Row, Field)
	Var Rows;
	Var CurrentRow;
	Var CurrentItems;
	Var NamesArray;

	If (DragParameters.Value = "DragFromAllFieldsForDataCompositionFilters") Then
		NamesArray = new Array();
		StandardProcessing = False;
		Rows = Items.AllFieldsForDataCompositionFilters.SelectedRows;
		For Each CurrentRow In Rows Do
			If (CurrentRow = Undefined) Then
				Return;
			EndIf;
			CurrentItems = AllFieldsForDataCompositionFilters.FindByID(CurrentRow);
			If CurrentItems["Type"] = 2 Then
				NamesArray.Add(CurrentItems["Name"]);
			EndIf;
		EndDo;
		
		If NamesArray.Count() > 0 Then
			AddDataCompositionFiltersFromFields(NamesArray);
		EndIf;
	EndIf;
	
	SetPageState("DataCompositionFiltersPage", True);
EndProcedure

&AtClient
Procedure DataCompositionFilterExpressionStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	EditText = Item.EditText;
	AttachIdleHandler("DataCompositionFilterExpressionStartChoiceHandler", 0.01, True);
EndProcedure

&AtClient
Procedure DataCompositionFilterExpressionStartChoiceHandler()
	DataCompositionFilterExpressionChangeInDialog(EditText);
EndProcedure

&AtClient
Procedure DataCompositionFilterExpressionChangeInDialog(Val Expression, Val IsExpressionChanged = Undefined)
	Var Params;
	Var CurrentRow;
	Var Notification;
	
	Params = New Structure;
	Params.Insert("FieldsAddress", AllFieldsForGroupingAddress);
	Params.Insert("Expression", Expression);

	CurrentRow = Items.DataCompositionFilters.CurrentRow;
	Items.DataCompositionFilters.CurrentRow = Undefined;
	Items.DataCompositionFilters.CurrentRow = CurrentRow;

	If IsExpressionChanged <> Undefined Then
		Params.Insert("Changed", IsExpressionChanged);
	Else
		Params.Insert("Changed", False);
	EndIf;
	
	Params.Insert("QueryWizardAddress", QueryWizardAddress);
	Params.Insert("CurrentQuerySchemaSelectQuery", CurrentQuerySchemaSelectQuery);
	Params.Insert("CurrentQuerySchemaOperator", CurrentQuerySchemaOperator);
	Params.Insert("NestedQueryPositionAddress", NestedQueryPositionAddress);
	// ITK1 + {
	ИдентификаторВнешнихИсточников = ИТК_КонструкторЗапросовКлиентСервер.ИдентификаторЗначенийВнешнихИсточников();
	Params.Insert(ИдентификаторВнешнихИсточников, ЭтотОбъект.Object[ИдентификаторВнешнихИсточников]);
	// }
	Notification = New NotifyDescription("DataCompositionFilterExpressionChanged", ThisForm, Params);
    OpenForm("DataProcessor.ИТК_QueryWizard15.Form.ArbitraryExpression", Params, ThisForm,,,,Notification,
             FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure DataCompositionFilterExpressionChanged(ChildForm, Params) Export
	Var ErrorMessage;
	Var StartCol;
	Var StartRow;
	Var CurrentItems;
	Var CheckRes;

	If ChildForm = Undefined Then
		Return;
	EndIf;

	If Params["Changed"] Then
		ErrorMessage = "";
		CheckRes = CheckDataCompositionFilter(Params["Expression"], ErrorMessage);
		
		If NOT(CheckRes["CorrectExpression"]) Then
			StartRow = -1;
			StartCol = -1;
			GetErrorTextBounds(StartRow, StartCol, ErrorMessage);
			ChildForm.SetTextSelectionBounds(StartRow, StartCol);
			AddErrorMessage(ErrorMessage);
			ShowErrorMessage();
		Else
			ChildForm.Closing = True;
			ChildForm.Close();

			If Items.DataCompositionFilters.CurrentRow <> Undefined Then
				CurrentItems = DataCompositionFilters.FindByID(Items.DataCompositionFilters.CurrentRow);
			EndIf;
			If (CurrentItems = Undefined) Then
				Return;
			EndIf;
			CurrentItems["Expression"] = Params["Expression"];
			CurrentItems["CanUseAttributes"] = CheckRes["CanUseAttributes"];
			
			If CurrentItems["UseAttributes"] AND NOT CheckRes["CanUseAttributes"] Then
				CurrentItems["UseAttributes"] = CheckRes["CanUseAttributes"];
			EndIf;
			
			SetPageState("DataCompositionFiltersPage", True);
		EndIf;
	Else
		ChildForm.Closing = True;
		ChildForm.Close();
		CurrentItems = DataCompositionFilters.FindByID(Items.DataCompositionFilters.CurrentRow);
		CurrentItems["Expression"] = TmpString;
	EndIf;
	StartEdit = False;

EndProcedure

&AtClient
Procedure DataCompositionFiltersUseAttributesOnChange(Item)
	Var CurrentRow;
	
	CurrentRow = DataCompositionFilters.FindByID(Items.DataCompositionFilters.CurrentRow);
	TmpBool = NOT CurrentRow["UseAttributes"];
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	If CurrentRow["UseAttributes"] AND NOT CurrentRow["CanUseAttributes"] Then
		CurrentRow["UseAttributes"] = False;
	EndIf;
	
	If CurrentRow["UseAttributes"] <> TmpBool Then
		SetPageState("DataCompositionFiltersPage", True);
	EndIf;
EndProcedure

&AtClient
Procedure DataCompositionFiltersBeforeEditEndHandler()
	Var CurrentRow;
	Var CheckRes;
	Var ErrorMessage;
	
	CurrentRow = DataCompositionFilters.FindByID(RowForEdit);
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	ErrorMessage = "";
	CheckRes = CheckDataCompositionFilter(CurrentRow["Expression"], ErrorMessage);
	
	If NOT(CheckRes["CorrectExpression"]) Then
		ShowMessageBox( , ErrorMessage);
		Items.DataCompositionFilters.CurrentRow = RowForEdit;
		Items.DataCompositionFilters.ChangeRow();
		StartEdit = True;
		Return;
	EndIf;
	
	If CurrentRow["UseAttributes"] AND NOT CheckRes["CanUseAttributes"] Then
		CurrentRow["UseAttributes"] = CheckRes["CanUseAttributes"];
	EndIf;
	CurrentRow["CanUseAttributes"] = CheckRes["CanUseAttributes"];
	StartEdit = False;
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Команды таблицы условий компоновки данных

&AtClient
Procedure DataCompositionFiltersAdd(Command)
	Var NewItem;

	NewItem = DataCompositionFilters.GetItems().Add();
	NewItem["Expression"] = "";
	NewItem["UseAttributes"] = False;
	NewItem["Alias"] = "";
	NewItem["CanUseAttributes"] = False;
	Items.DataCompositionFilters.CurrentRow = NewItem.GetID();
	SetPageState("DataCompositionFiltersPage", True);
EndProcedure

&AtClient
Procedure DataCompositionFiltersCopy(Command)
	Var Rows;
	Var CurrentRow;
	Var CurrentItems;
	Var NewItem;

	Rows = Items.DataCompositionFilters.SelectedRows;
	For Each CurrentRow In Rows Do
		CurrentItems = DataCompositionFilters.FindByID(CurrentRow);
		NewItem = DataCompositionFilters.GetItems().Add();
		NewItem["Expression"] = CurrentItems["Expression"];
		NewItem["UseAttributes"] = CurrentItems["UseAttributes"];
		NewItem["Alias"] = CurrentItems["Alias"];
		NewItem["CanUseAttributes"] = CurrentItems["CanUseAttributes"];
	EndDo;
	Items.DataCompositionFilters.CurrentRow = NewItem.GetID();
	SetPageState("DataCompositionFiltersPage", True);
EndProcedure

&AtClient
Procedure DataCompositionFiltersDelete(Command)
	Var CurrentRow;
	Var CurrentItems;

	While Items.DataCompositionFilters.SelectedRows.Count() > 0 Do
		CurrentRow = Items.DataCompositionFilters.SelectedRows[0];
		CurrentItems = DataCompositionFilters.FindByID(CurrentRow);
		DataCompositionFilters.GetItems().Delete(DataCompositionFilters.GetItems().IndexOf(CurrentItems));
	EndDo;
	SetPageState("DataCompositionFiltersPage", True);
EndProcedure

&AtClient
Procedure DataCompositionFiltersAddButton(Command)
	Var Rows;
	Var CurrentRow;
	Var CurrentItems;
	Var CanUseAttributes;
	Var NamesArray;

	NamesArray = new Array();
	Rows = Items.AllFieldsForDataCompositionFilters.SelectedRows;
	For Each CurrentRow In Rows Do
		CurrentItems = AllFieldsForDataCompositionFilters.FindByID(CurrentRow);

		If CurrentItems["Type"] = 2 Then
			NamesArray.Add(CurrentItems["Name"]);
		EndIf;
	EndDo;
	
	If NamesArray.Count() > 0 Then
		AddDataCompositionFiltersFromFields(NamesArray);
		SetPageState("DataCompositionFiltersPage", True);
	EndIf;
EndProcedure

&AtClient
Procedure DataCompositionFiltersAddAllButton(Command)
	Var CurrentRow;
	Var CurrentItems;
	Var ConditionItems;
	Var CanUseAttributes;
	Var NamesArray;

	NamesArray = new Array();
	CurrentRow = Items.AllFieldsForDataCompositionFilters.CurrentRow;
	If (CurrentRow = Undefined) Then
		Return;
	EndIf;
	DataCompositionFilterItems = AllFieldsForDataCompositionFilters.FindByID(CurrentRow);

	If (DataCompositionFilterItems.GetItems().Count() = 1)
		AND (DataCompositionFilterItems.GetItems().Get(0)["Name"] = "FakeFieldeItem") Then
		
		RowForExpand = DataCompositionFilterItems.GetID();
		AllFieldsForDataCompositionFiltersBeforeExpandAtServer();
	EndIf;

	For Each CurrentItems In DataCompositionFilterItems.GetItems() Do
				
		If CurrentItems["Type"] = 2 Then
			NamesArray.Add(CurrentItems["Name"]);
		EndIf;
	EndDo;
	
	If NamesArray.Count() > 0 Then
		AddDataCompositionFiltersFromFields(NamesArray);
		SetPageState("DataCompositionFiltersPage", True);
	EndIf;
EndProcedure

&AtClient
Procedure DataCompositionFiltersDeleteButton(Command)
	Var CurrentRow;
	Var CurrentItems;

	While Items.DataCompositionFilters.SelectedRows.Count() > 0 Do
		CurrentRow = Items.DataCompositionFilters.SelectedRows[0];
		CurrentItems = DataCompositionFilters.FindByID(CurrentRow);
		DataCompositionFilters.GetItems().Delete(DataCompositionFilters.GetItems().IndexOf(CurrentItems));
	EndDo;
	SetPageState("DataCompositionFiltersPage", True);
EndProcedure

&AtClient
Procedure DataCompositionFiltersDeleteAllButton(Command)
	DataCompositionFilters.GetItems().Clear();
	SetPageState("DataCompositionFiltersPage", True);
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Серверные вызовы для условий компоновки данных

&AtServer
Procedure AddDataCompositionFiltersFromFields(Val NamesArray)
	Var NewItem;
	Var CheckRes;
	Var FieldName;
	
	For Each FieldName In NamesArray Do
		
		CheckRes = CheckDataCompositionFilter(FieldName);
		NewItem = DataCompositionFilters.GetItems().Add();
		NewItem["Expression"] = FieldName;
		NewItem["UseAttributes"] = CheckRes["CanUseAttributes"];
		NewItem["Alias"] = "";
		NewItem["CanUseAttributes"] = CheckRes["CanUseAttributes"];
	EndDo;
	
	Items.DataCompositionFilters.CurrentRow = NewItem.GetID();
EndProcedure

&AtServer
Function CheckDataCompositionFilter(Expression, ErrorMessage = Undefined)
	Var QuerySchema;
	Var Query;
	Var Operators;
	Var Operator;
	Var RetStruct;
	
	RetStruct = new Structure("CorrectExpression, CanUseAttributes");

	QuerySchema = GetFromTempStorage(QueryWizardAddress);
	If QuerySchema = Undefined Then
		RetStruct["CorrectExpression"] = True;
		RetStruct["CanUseAttributes"] = False;
		Return RetStruct;
	EndIf;

	Batch = QuerySchema.QueryBatch;
	Query = GetSchemaQuery(QuerySchema, CurrentQuerySchemaSelectQuery, NestedQueryPositionAddress);

	If TypeOf(Query) = Type("QuerySchemaSelectQuery") Then
		Operators  = Query.Operators;
		Operator = Operators.Get(CurrentQuerySchemaOperator);
	Else
		RetStruct["CorrectExpression"] = True;
		RetStruct["CanUseAttributes"] = False;
		Return RetStruct;
	EndIf;

	Try
		Operator.DataCompositionFilterExpressions.Add(Expression);
		Condition = String(Operator.DataCompositionFilterExpressions.Get(Operator.DataCompositionFilterExpressions.Count() - 1).Expression);
		RetStruct["CorrectExpression"] = True;
		
		Operator.DataCompositionFilterExpressions.Get(Operator.DataCompositionFilterExpressions.Count() - 1).UseAttributes = True;
		RetStruct["CanUseAttributes"] = Operator.DataCompositionFilterExpressions.Get(Operator.DataCompositionFilterExpressions.Count() - 1).UseAttributes;
		
		Operator.DataCompositionFilterExpressions.Delete(Operator.DataCompositionFilterExpressions.Count() - 1);
	Except
		If ErrorMessage = Undefined Then
			AddErrorMessageAtServer(BriefErrorDescription(ErrorInfo()));
		Else
			ErrorMessage = BriefErrorDescription(ErrorInfo());
		EndIf;
		RetStruct["CorrectExpression"] = False;
	EndTry;
	
	Return RetStruct;
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Страница "Характеристики"

&AtClient
Procedure CharacteristicsBeforeAddRow(Item, Cancel, Clone, Parent, Folder, Parameter)
	If NOT(Clone) Then
		CharacteristicsAdd(Undefined);
	Else
		CharacteristicsCopy(Undefined);
	EndIf;
	Cancel = True;
EndProcedure

&AtClient
Procedure CharacteristicsBeforeDeleteRow(Item, Cancel)
	CharacteristicsDelete(Undefined);
	Cancel = True;
EndProcedure

&AtClient
Procedure CharacteristicsOnStartEdit(Item, NewRow, Clone)
	Var TmpCharacteristic;
	
	If NOT(StartEdit) Then		
		TmpCharacteristics.Clear();		
		TmpCharacteristic = TmpCharacteristics.Add();
		TmpCharacteristic["Type"]		 				= Item.CurrentData["Type"];
		TmpCharacteristic["CharacteristicTypesSource"] 	= Item.CurrentData["CharacteristicTypesSource"];
		TmpCharacteristic["CharacteristicTypes"] 		= Item.CurrentData["CharacteristicTypes"];
		TmpCharacteristic["KeyField"] 					= Item.CurrentData["KeyField"];
		TmpCharacteristic["NameField"] 					= Item.CurrentData["NameField"];
		TmpCharacteristic["ValueTypeField"] 			= Item.CurrentData["ValueTypeField"];
		TmpCharacteristic["CharacteristicValuesSource"] = Item.CurrentData["CharacteristicValuesSource"];
		TmpCharacteristic["CharacteristicValues"] 		= Item.CurrentData["CharacteristicValues"];
		TmpCharacteristic["ObjectField"] 				= Item.CurrentData["ObjectField"];
		TmpCharacteristic["TypeField"]				 	= Item.CurrentData["TypeField"];
		TmpCharacteristic["ValueField"] 				= Item.CurrentData["ValueField"];
		
		ErrorMessage = "";
		If  (TmpCharacteristic["Type"] = Undefined OR TmpCharacteristic["Type"].Types().Count() = 0) OR
		    (TmpCharacteristic["CharacteristicTypesSource"]  = "") OR
			(TmpCharacteristic["CharacteristicTypes"] 		 = "") OR
			(TmpCharacteristic["KeyField"] 					 = "") OR
			(TmpCharacteristic["NameField"]	 				 = "") OR
			(TmpCharacteristic["CharacteristicValuesSource"] = "") OR
			(TmpCharacteristic["CharacteristicValues"] 		 = "") OR
			(TmpCharacteristic["ObjectField"] 				 = "") OR
			(TmpCharacteristic["ValueField"] 				 = "") Then
			
			TmpCharacteristics.Delete(TmpCharacteristics.Count() - 1);
		EndIf;
	EndIf;
	StartEdit = True;
EndProcedure

&AtClient
Procedure CharacteristicsBeforeEditEnd(Item, NewRow, CancelEdit, Cancel)
	Var CurrentRow;
	Var TmpCharacteristic;
	
	If CancelEdit Then
		
		If (TmpCharacteristics.Count() = 0) Then
			CharacteristicsDelete(Undefined);
			StartEdit = False;
			Cancel = True;
			Return;
		EndIf;
		
		TmpCharacteristic = TmpCharacteristics.Get(0);
		
		Item.CurrentData["Type"]		 				= TmpCharacteristic["Type"];
		Item.CurrentData["CharacteristicTypesSource"] 	= TmpCharacteristic["CharacteristicTypesSource"];
		Item.CurrentData["CharacteristicTypes"] 		= TmpCharacteristic["CharacteristicTypes"];
		Item.CurrentData["KeyField"] 					= TmpCharacteristic["KeyField"];
		Item.CurrentData["NameField"] 					= TmpCharacteristic["NameField"];
		Item.CurrentData["ValueTypeField"] 				= TmpCharacteristic["ValueTypeField"];
		Item.CurrentData["CharacteristicValuesSource"] 	= TmpCharacteristic["CharacteristicValuesSource"];
		Item.CurrentData["CharacteristicValues"] 		= TmpCharacteristic["CharacteristicValues"];
		Item.CurrentData["ObjectField"] 				= TmpCharacteristic["ObjectField"];
		Item.CurrentData["TypeField"]				 	= TmpCharacteristic["TypeField"];
		Item.CurrentData["ValueField"] 					= TmpCharacteristic["ValueField"];
	EndIf;

	If NOT(StartEdit) Then
		Return;
	EndIf;
	
	CurrentRow = Items.Characteristics.CurrentRow;
	If (CurrentRow = Undefined) Then
		Return;
	EndIf;

	RowForEdit = CurrentRow;
	AttachIdleHandler("CharacteristicsBeforeEditEndHandler", 0.01, True);
EndProcedure

&AtClient
Procedure CharacteristicsOnEditEnd(Item, NewRow, CancelEdit)
	SetPageState("CharacteristicsPage", True);
EndProcedure

&AtClient
Procedure CharacteristicsBeforeEditEndHandler()
	Var CurrentRow;
	Var CheckRes;
	Var ErrorMessage;
	Var CharStruct;
	
	CurrentRow = Characteristics.FindByID(RowForEdit);
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	CharStruct = New Structure();
	CharStruct.Insert("Type", CurrentRow["Type"]);
	CharStruct.Insert("KeyField", CurrentRow["KeyField"]);
	CharStruct.Insert("NameField", CurrentRow["NameField"]);
	CharStruct.Insert("ValueTypeField", CurrentRow["ValueTypeField"]);
	CharStruct.Insert("ObjectField", CurrentRow["ObjectField"]);
	CharStruct.Insert("TypeField", CurrentRow["TypeField"]);
	CharStruct.Insert("ValueField", CurrentRow["ValueField"]);
	
	If (CurrentRow["CharacteristicTypesSource"] = NStr("ru = 'Таблица';
														|SYS = 'Table'", "ru")) Then
		CharStruct.Insert("CharacteristicTypesTable", CurrentRow["CharacteristicTypes"]);
		CharStruct.Insert("CharacteristicTypesQuery", "");
	Else
		CharStruct.Insert("CharacteristicTypesQuery", CurrentRow["CharacteristicTypes"]);
		CharStruct.Insert("CharacteristicTypesTable", "");
	EndIf;
	
	If (CurrentRow["CharacteristicValuesSource"] = NStr("ru = 'Таблица';
														|SYS = 'Table'", "ru")) Then
		CharStruct.Insert("CharacteristicValuesTable", CurrentRow["CharacteristicValues"]);
		CharStruct.Insert("CharacteristicValuesQuery", "");
	Else
		CharStruct.Insert("CharacteristicValuesQuery", CurrentRow["CharacteristicValues"]);
		CharStruct.Insert("CharacteristicValuesTable", "");
	EndIf;
	
	ErrorMessage = "";	
	If NOT(CheckCharacteristics(CharStruct, ErrorMessage)) Then
		ShowMessageBox( , ErrorMessage);
		Items.Characteristics.CurrentRow = RowForEdit;
		Items.Characteristics.ChangeRow();
		Return;
	EndIf;
	SetPageState("CharacteristicsPage", True);
	StartEdit = False;
EndProcedure

&AtClient
Procedure CharacteristicsAdd(Command)
	Var NewItem;

	NewItem = Characteristics.GetItems().Add();
	NewItem["Type"] = New TypeDescription();
	NewItem["CharacteristicTypesSource"] =  "";
	NewItem["KeyField"] = "";
	NewItem["CharacteristicTypes"] = "";
	NewItem["NameField"] = "";
	NewItem["ValueTypeField"] = "";
	NewItem["CharacteristicValuesSource"] = "";
	NewItem["CharacteristicValues"] = "";
	NewItem["ObjectField"] = "";
	NewItem["TypeField"] = "";
	NewItem["ValueField"] = "";
	Items.Characteristics.CurrentRow = NewItem.GetID();
	Items.Characteristics.ChangeRow();
	SetPageState("CharacteristicsPage", True);
EndProcedure

&AtClient
Procedure CharacteristicsCopy(Command)
	Var Rows;
	Var CurrentRow;
	Var CurrentItems;
	Var NewItem;

	Rows = Items.Characteristics.SelectedRows;
	For Each CurrentRow In Rows Do
		If (CurrentRow = Undefined) Then
			Return;
		EndIf;
		CurrentItems = Characteristics.FindByID(CurrentRow);
		NewItem = Characteristics.GetItems().Add();
		NewItem["Type"] = CurrentItems["Type"];
		NewItem["CharacteristicTypesSource"] = CurrentItems["CharacteristicTypesSource"];
		NewItem["KeyField"] = CurrentItems["KeyField"];
		NewItem["CharacteristicTypes"] = CurrentItems["CharacteristicTypes"];
		NewItem["NameField"] = CurrentItems["NameField"];
		NewItem["ValueTypeField"] = CurrentItems["ValueTypeField"];
		NewItem["CharacteristicValuesSource"] = CurrentItems["CharacteristicValuesSource"];
		NewItem["CharacteristicValues"] = CurrentItems["CharacteristicValues"];
		NewItem["ObjectField"] = CurrentItems["ObjectField"];
		NewItem["TypeField"] = CurrentItems["TypeField"];
		NewItem["ValueField"] = CurrentItems["ValueField"];
	EndDo;
	Items.Characteristics.CurrentRow = NewItem.GetID();
	SetPageState("CharacteristicsPage", True);
EndProcedure

&AtClient
Procedure CharacteristicsDelete(Command)
	Var CurrentRow;
	Var CurrentItems;

	While Items.Characteristics.SelectedRows.Count() > 0 Do
		CurrentRow = Items.Characteristics.SelectedRows[0];
		CurrentItems = Characteristics.FindByID(CurrentRow);
		Characteristics.GetItems().Delete(Characteristics.GetItems().IndexOf(CurrentItems));
	EndDo;
	SetPageState("CharacteristicsPage", True);
EndProcedure

&AtClient
Function CheckCharacteristics(Char, ErrorMessage)
	If (Char["Type"] = Undefined OR Char["Type"].Types().Count() = 0) Then
		ErrorMessage = NStr("ru = 'Не заполнен тип!';
							|SYS = 'Type is not filled!'", "ru");
		Return False;
	ElsIf (Char["CharacteristicTypesTable"] = "" AND Char["CharacteristicTypesQuery"] = "") Then
		ErrorMessage = NStr("ru = 'Не указаны виды характеристик!';
							|SYS = 'Characteristic types are not specified!'", "ru");
		Return False;
	ElsIf (Char["KeyField"] = "") Then
		ErrorMessage = NStr("ru = 'Не заполнено поле ключа!';
							|SYS = 'Key field is not filled!'", "ru");
		Return False;
	ElsIf (Char["NameField"] = "") Then
		ErrorMessage = NStr("ru = 'Не заполнено поле имени!';
							|SYS = 'name field is not filled!'", "ru");
		Return False;
	ElsIf (Char["CharacteristicValuesTable"] = "" AND Char["CharacteristicValuesQuery"] = "") Then
		ErrorMessage = NStr("ru = 'Не указаны значения характеристик!';
							|SYS = 'Characteristic values are not specified!'", "ru");
		Return False;
	ElsIf (Char["ObjectField"] = "") Then
		ErrorMessage = NStr("ru = 'Не заполнено поле объекта!';
							|SYS = 'Object field is not filled!'", "ru");
		Return False;
	ElsIf (Char["TypeField"] = "") Then
		ErrorMessage = NStr("ru = 'Не заполнено поле типа!';
							|SYS = 'Type field is not filled!'", "ru");
		Return False;
	EndIf;
	
	Return CheckCharacteristicsAtServer(Char, ErrorMessage);
EndFunction

&AtServer
Function CheckCharacteristicsAtServer(Char, ErrorMessage)
	Var QuerySchema;
	Var Query;
	Var Operators;
	Var Operator;
	
	QuerySchema = GetFromTempStorage(QueryWizardAddress);
	If QuerySchema = Undefined Then
		Return False;
	EndIf;

	Batch = QuerySchema.QueryBatch;
	Query = GetSchemaQuery(QuerySchema, CurrentQuerySchemaSelectQuery, NestedQueryPositionAddress);

	Try
		Query.Characteristics.Add(Char.Type,
								  Char.CharacteristicTypesTable, Char.CharacteristicTypesQuery,
								  Char.KeyField, Char.NameField, Char.ValueTypeField,
								  Char.CharacteristicValuesTable, Char.CharacteristicValuesQuery,
								  Char.ObjectField, Char.TypeField, Char.ValueField);
		Condition = String(Query.Characteristics.Get(Query.Characteristics.Count() - 1).NameField);
		
		Query.Characteristics.Delete(Query.Characteristics.Count() - 1);
	Except
		If ErrorMessage = Undefined Then
			AddErrorMessageAtServer(BriefErrorDescription(ErrorInfo()));
		Else
			ErrorMessage = BriefErrorDescription(ErrorInfo());
		EndIf;
		Return False;
	EndTry;
	
	Return True;
EndFunction

&AtClient
Procedure CharacteristicsTypeStartChoice(Item, ChoiceData, StandardProcessing)
	Var CurrentRow;
	Var CurrentItems;
	Var Params;
	Var Notification;
	
	StandardProcessing = False;

	CurrentRow = Items.Characteristics.CurrentRow;
	If (CurrentRow = Undefined) Then
		Return;
	EndIf;
	CurrentItems = Characteristics.FindByID(CurrentRow);
	
	SaveAvailableTablesToTempStorage();
	
	Params = New Structure;
	Params.Insert("FormMode", "CharacteristicTypeMode");
	Params.Insert("AvailableTablesAddress", AvailableTablesAddress);
	Params.Insert("ItemIndexes", "");
	Params.Insert("StartTableName", "");
	Params.Insert("TableIndex", CurrentRow);     
	Params.Insert("DisplayChangesTables", False);
	Params.Insert("QueryWizardAddress", QueryWizardAddress);
	Params.Insert("CurrentQuerySchemaSelectQuery", CurrentQuerySchemaSelectQuery);
	Params.Insert("SourcesImagesCacheAddress", SourcesImagesCacheAddress);
	Params.Insert("ExpressionsImagesCacheAddress", ExpressionsImagesCacheAddress);
	Params.Insert("NestedQueryPositionAddress", NestedQueryPositionAddress);
	// ITK1 + {
	ИдентификаторВнешнихИсточников = ИТК_КонструкторЗапросовКлиентСервер.ИдентификаторЗначенийВнешнихИсточников();
	Params.Insert(ИдентификаторВнешнихИсточников, ЭтотОбъект.Object[ИдентификаторВнешнихИсточников]);
	// }
	Notification = New NotifyDescription("TablesForCaracteristicsTypesSourcesChanges", ThisForm, Params);
	OpenForm("DataProcessor.ИТК_QueryWizard15.Form.TableSelecting", Params, ThisForm,,,,Notification,
             FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure TablesForCaracteristicsTypesSourcesChanges(Result, Params) Export
	Var Types;

	If Result = DialogReturnCode.OK Then
		Types = Params["ItemIndexes"];
		ChangeCharacteristicType(Types);
	EndIf;
EndProcedure

&AtServer
Procedure ChangeCharacteristicType(SelectedTypes)
	Var CurrentRow;
	Var CurrentItem;
	Var Types;
	Var Type;
	Var TmpStringType;
	Var PointPosition;
	
	CurrentRow = Items.Characteristics.CurrentRow;
	If (CurrentRow = Undefined) Then
		Return;
	EndIf;
	CurrentItem = Characteristics.FindByID(CurrentRow);

	Types = New Array();                                     
	For Each Type In SelectedTypes Do
		TmpStringType = "";
		PointPosition = StrFind(Type.Value, ".");
		TmpStringType = Left(Type.Value, PointPosition - 1) + Nstr("ru = 'Ссылка';
																	|SYS = 'Ref'", "ru") +
													Right(Type.Value, StrLen(Type.Value) - PointPosition + 1);
		Types.Add(Type(TmpStringType));
	EndDo;
	CurrentItem["Type"] = New TypeDescription(Types);
EndProcedure

&AtClient
Procedure CharacteristicsCharacteristicTypesSourceChoiceProcessing(Item, ChoiceData, StandardProcessing)
	Var CurrentRow;
	Var CurrentItem;
	
	CurrentRow = Items.Characteristics.CurrentRow;
	If (CurrentRow = Undefined) Then
		Return;
	EndIf;
	CurrentItem = Characteristics.FindByID(CurrentRow);
	
	If (CurrentItem["CharacteristicTypesSource"] = "" OR ChoiceData = "") Then
		Return;
	EndIf;
	
	If (ChoiceData <> CurrentItem["CharacteristicTypesSource"]) Then
		CurrentItem["CharacteristicTypes"] = "";
		CurrentItem["KeyField"] = "";
		CurrentItem["NameField"] = "";
		CurrentItem["ValueTypeField"] = "";
	EndIf;
EndProcedure

&AtClient
Procedure CharacteristicsCharacteristicTypesStartChoice(Item, ChoiceData, StandardProcessing)
	Var CurrentRow;
	Var CurrentItem;
	Var IsNew;
	Var Params;
	Var Notification;	
		
	StandardProcessing = False;
	CurrentRow = Items.Characteristics.CurrentRow;
	If (CurrentRow = Undefined) Then
		Return;
	EndIf;
	CurrentItem = Characteristics.FindByID(CurrentRow);
	RowForEdit = CurrentRow;

	TmpString = CurrentItem["CharacteristicTypes"];	
	If (CurrentItem["CharacteristicTypesSource"] = Nstr("ru = 'Таблица';
														|SYS = 'Table'", "ru")) Then
		SaveAvailableTablesToTempStorage();
	
		Params = New Structure;
		Params.Insert("FormMode", "CharacteristicSourceMode");
		Params.Insert("AvailableTablesAddress", AvailableTablesAddress);
		Params.Insert("ItemIndexes", "");
		Params.Insert("StartTableName", "");
		Params.Insert("TableIndex", CurrentRow);     
		Params.Insert("DisplayChangesTables", False);
		Params.Insert("QueryWizardAddress", QueryWizardAddress);
		Params.Insert("CurrentQuerySchemaSelectQuery", CurrentQuerySchemaSelectQuery);
		Params.Insert("SourcesImagesCacheAddress", SourcesImagesCacheAddress);
		Params.Insert("ExpressionsImagesCacheAddress", ExpressionsImagesCacheAddress);
		Params.Insert("NestedQueryPositionAddress", NestedQueryPositionAddress);
		Params.Insert("CompositeChoiceMode", True);
		// ITK1 + {
		ИдентификаторВнешнихИсточников = ИТК_КонструкторЗапросовКлиентСервер.ИдентификаторЗначенийВнешнихИсточников();
		Params.Insert(ИдентификаторВнешнихИсточников, ЭтотОбъект.Object[ИдентификаторВнешнихИсточников]);
		// }
		Notification = New NotifyDescription("TypesMetadataTypeChanged", ThisForm, Params);
		OpenForm("DataProcessor.ИТК_QueryWizard15.Form.TableSelecting", Params, ThisForm,,,,Notification,
	             FormWindowOpeningMode.LockOwnerWindow);
	ElsIf (CurrentItem["CharacteristicTypesSource"] = Nstr("ru = 'Запрос';
															|SYS = 'Query'", "ru")) Then
		EditCharacteristicsQuery("TypesQueryChanged", CurrentItem["CharacteristicTypes"]);
	EndIf;
EndProcedure

&AtServer
Procedure FillCharacteristicTypesChoiceListsByTable()
	Var CurrentRow;
	Var CurrentItem;
	Var ChoiceList;
	Var Attribute;
	Var NewItem;
	Var AttributesList;
	
	CurrentRow = Items.Characteristics.CurrentRow;
	If (CurrentRow = Undefined) Then
		Return;
	EndIf;
	CurrentItem = Characteristics.FindByID(CurrentRow);
	
	AttributesList = FillAttributesListByTable(CurrentItem["CharacteristicTypes"]);
	
	ChoiceList = Items.Characteristics.ChildItems.CharacteristicsGroup1.ChildItems.CharacteristicsGroup2.ChildItems.CharacteristicsKeyField.ChoiceList;
	ChoiceList.Clear();	
	For Each Attribute In AttributesList Do
		NewItem = ChoiceList.Add();                           
		NewItem.Value = Attribute;
		NewItem.Presentation = Attribute;
	EndDo;
	
	ChoiceList = Items.Characteristics.ChildItems.CharacteristicsGroup1.ChildItems.CharacteristicsGroup2.ChildItems.CharacteristicsNameField.ChoiceList;
	ChoiceList.Clear();
	For Each Attribute In AttributesList Do
		NewItem = ChoiceList.Add();                           
		NewItem.Value = Attribute;
		NewItem.Presentation = Attribute;
	EndDo;
	
	ChoiceList = Items.Characteristics.ChildItems.CharacteristicsGroup1.ChildItems.CharacteristicsGroup2.ChildItems.CharacteristicsValueTypeField.ChoiceList;
	ChoiceList.Clear();
	For Each Attribute In AttributesList Do
		NewItem = ChoiceList.Add();                           
		NewItem.Value = Attribute;
		NewItem.Presentation = Attribute;
	EndDo;
	
	NewItem = ChoiceList.Add();                           
	NewItem.Value = "";
	NewItem.Presentation = NStr("ru = '<Пустое значение>';
								|SYS = '<Empty value>'", "ru");
EndProcedure

&AtServer
Procedure FillCharacteristicTypesChoiceListsByQuery()
	Var CurrentRow;
	Var CurrentItem;
	Var CharacteristicTypesQuerySchema;
	Var ChoiceList;
	Var Column;
	Var NewItem;
	
	CurrentRow = Items.Characteristics.CurrentRow;
	If (CurrentRow = Undefined) Then
		Return;
	EndIf;
	CurrentItem = Characteristics.FindByID(CurrentRow);
	
	CharacteristicTypesQuerySchema = New QuerySchema();
	CharacteristicTypesQuerySchema.DataCompositionMode = DataCompositionMode;
	CharacteristicTypesQuerySchema.SetQueryText(CurrentItem["CharacteristicTypes"]);
	
	ChoiceList = Items.Characteristics.ChildItems.CharacteristicsGroup1.ChildItems.CharacteristicsGroup2.ChildItems.CharacteristicsKeyField.ChoiceList;
	ChoiceList.Clear();
	For Each Column In CharacteristicTypesQuerySchema.QueryBatch[0].Columns Do
		NewItem = ChoiceList.Add();
		NewItem.Value = Column.Alias;
		NewItem.Presentation = Column.Alias;
	EndDo;
	
	ChoiceList = Items.Characteristics.ChildItems.CharacteristicsGroup1.ChildItems.CharacteristicsGroup2.ChildItems.CharacteristicsNameField.ChoiceList;
	ChoiceList.Clear();
	For Each Column In CharacteristicTypesQuerySchema.QueryBatch[0].Columns Do
		NewItem = ChoiceList.Add();
		NewItem.Value = Column.Alias;
		NewItem.Presentation = Column.Alias;
	EndDo;
	
	ChoiceList = Items.Characteristics.ChildItems.CharacteristicsGroup1.ChildItems.CharacteristicsGroup2.ChildItems.CharacteristicsValueTypeField.ChoiceList;
	ChoiceList.Clear();
	For Each Column In CharacteristicTypesQuerySchema.QueryBatch[0].Columns Do
		NewItem = ChoiceList.Add();
		NewItem.Value = Column.Alias;
		NewItem.Presentation = Column.Alias;
	EndDo;
	
	NewItem = ChoiceList.Add();                           
	NewItem.Value = "";
	NewItem.Presentation = NStr("ru = '<Пустое значение>';
								|SYS = '<Empty value>'", "ru");

EndProcedure

&AtClient
Procedure EditCharacteristicTypesQuery(Val NotificationName, Val QueryText = "")
	Var Params;
	Var Notification;
	Var Address;
		
	Params = New Structure;	
	If (QueryText <> "") Then
		Params.Insert("QueryText", QueryText);	
	EndIf;
	
	Notification = New NotifyDescription(NotificationName, ThisForm, Params);
	
	OpenForm("DataProcessor.ИТК_QueryWizard15.Form.QueryWizard", Params,, True,,,
		Notification, FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure TypesQueryChanged(Result, Params) Export
	Var ErrorMessage;
	Var StartCol;
	Var StartRow;
	Var CurrentItems;
	Var CheckRes;

	If Result = Undefined OR Result = "" Then
		Items.Characteristics.CurrentRow = RowForEdit;
		Items.Characteristics.ChangeRow();
		Return;
	EndIf;
	
	If Items.Characteristics.CurrentRow <> Undefined Then
		CurrentItems = Characteristics.FindByID(Items.Characteristics.CurrentRow);
	EndIf;
	If (CurrentItems = Undefined) Then
		Return;
	EndIf;
	CurrentItems["CharacteristicTypes"] = Result;
	FillCharacteristicTypesChoiceListsByQuery();
	CurrentItems["KeyField"] = "";
	CurrentItems["NameField"] = "";
	CurrentItems["ValueTypeField"] = "";
	
	Items.Characteristics.CurrentRow = RowForEdit;
	Items.Characteristics.ChangeRow();

EndProcedure

&AtClient
Procedure TypesMetadataTypeChanged(Result, Params) Export
	Var CurrentRow;
	Var CurrentItem;
	Var Type;
	Var NewTable;

	If Result <> DialogReturnCode.OK Then
		Return;
	EndIf;
	
	CurrentRow = Items.Characteristics.CurrentRow;
	If (CurrentRow = Undefined) Then
		Return;
	EndIf;
	CurrentItem = Characteristics.FindByID(CurrentRow);
	
	Type = Params["ItemIndexes"];
	NewTable = Type["Table"];
	If NewTable <> "" Then
		CurrentItem["CharacteristicTypes"] = NewTable;
		FillCharacteristicTypesChoiceListsByTable();
		CurrentItem["KeyField"] = "";
		CurrentItem["NameField"] = "";
		CurrentItem["ValueTypeField"] = "";
	Else
		CurrentItem["CharacteristicTypes"] = TmpString;
	EndIf;
	
	Items.Characteristics.CurrentRow = RowForEdit;
	Items.Characteristics.ChangeRow();
EndProcedure

&AtClient
Procedure CharacteristicsCharacteristicValuesSourceChoiceProcessing(Item, ChoiceData, StandardProcessing)
	Var CurrentRow;
	Var CurrentItem;
	
	CurrentRow = Items.Characteristics.CurrentRow;
	If (CurrentRow = Undefined) Then
		Return;
	EndIf;
	CurrentItem = Characteristics.FindByID(CurrentRow);
	
	If (CurrentItem["CharacteristicValuesSource"] = "" OR ChoiceData = "") Then
		Return;
	EndIf;
	
	If (ChoiceData <> CurrentItem["CharacteristicValuesSource"]) Then
		CurrentItem["CharacteristicValues"] = "";
		CurrentItem["ObjectField"] = "";
		CurrentItem["TypeField"] = "";
		CurrentItem["ValueField"] = "";
	EndIf;
EndProcedure

&AtClient
Procedure CharacteristicsCharacteristicValuesStartChoice(Item, ChoiceData, StandardProcessing)
	Var CurrentRow;
	Var CurrentItem;
	Var IsNew;
	Var Params;
	Var Notification;
	
	CurrentRow = Items.Characteristics.CurrentRow;
	If (CurrentRow = Undefined) Then
		Return;
	EndIf;
	CurrentItem = Characteristics.FindByID(CurrentRow);
	RowForEdit = CurrentRow;
	
	TmpString = CurrentItem["CharacteristicValues"];	
	If (CurrentItem["CharacteristicValuesSource"] = Nstr("ru = 'Таблица';
														|SYS = 'Table'", "ru")) Then
		SaveAvailableTablesToTempStorage();
	
		Params = New Structure;
		Params.Insert("FormMode", "CharacteristicSourceMode");
		Params.Insert("AvailableTablesAddress", AvailableTablesAddress);
		Params.Insert("ItemIndexes", "");
		Params.Insert("StartTableName", "");
		Params.Insert("TableIndex", CurrentRow);     
		Params.Insert("DisplayChangesTables", False);
		Params.Insert("QueryWizardAddress", QueryWizardAddress);
		Params.Insert("CurrentQuerySchemaSelectQuery", CurrentQuerySchemaSelectQuery);
		Params.Insert("SourcesImagesCacheAddress", SourcesImagesCacheAddress);
		Params.Insert("ExpressionsImagesCacheAddress", ExpressionsImagesCacheAddress);
		Params.Insert("NestedQueryPositionAddress", NestedQueryPositionAddress);
		Params.Insert("CompositeChoiceMode", True);
		// ITK1 + {
		ИдентификаторВнешнихИсточников = ИТК_КонструкторЗапросовКлиентСервер.ИдентификаторЗначенийВнешнихИсточников();
		Params.Insert(ИдентификаторВнешнихИсточников, ЭтотОбъект.Object[ИдентификаторВнешнихИсточников]);
		// }
		Notification = New NotifyDescription("ValuesMetadataTypeChanged", ThisForm, Params);
		OpenForm("DataProcessor.ИТК_QueryWizard15.Form.TableSelecting", Params, ThisForm,,,,Notification,
	             FormWindowOpeningMode.LockOwnerWindow);
	ElsIf (CurrentItem["CharacteristicValuesSource"] = Nstr("ru = 'Запрос';
															|SYS = 'Query'", "ru")) Then
		EditCharacteristicsQuery("ValuesQueryChanged", CurrentItem["CharacteristicValues"]);
	EndIf;	
EndProcedure

&AtServer
Procedure FillCharacteristicValuesChoiceListsByTable()
	Var CurrentRow;
	Var CurrentItem;
	Var ChoiceList;
	Var Attribute;
	Var NewItem;
	Var AttributesList;
	
	CurrentRow = Items.Characteristics.CurrentRow;
	If (CurrentRow = Undefined) Then
		Return;
	EndIf;
	CurrentItem = Characteristics.FindByID(CurrentRow);
	
	AttributesList = FillAttributesListByTable(CurrentItem["CharacteristicValues"]);
	
	ChoiceList = Items.Characteristics.ChildItems.CharacteristicsGroup3.ChildItems.CharacteristicsGroup4.ChildItems.CharacteristicsObjectField.ChoiceList;
	ChoiceList.Clear();	
	For Each Attribute In AttributesList Do
		NewItem = ChoiceList.Add();                           
		NewItem.Value = Attribute;
		NewItem.Presentation = Attribute;
	EndDo;
	
	ChoiceList = Items.Characteristics.ChildItems.CharacteristicsGroup3.ChildItems.CharacteristicsGroup4.ChildItems.CharacteristicsTypeField.ChoiceList;
	ChoiceList.Clear();
	For Each Attribute In AttributesList Do
		NewItem = ChoiceList.Add();                           
		NewItem.Value = Attribute;
		NewItem.Presentation = Attribute;
	EndDo;
	
	ChoiceList = Items.Characteristics.ChildItems.CharacteristicsGroup3.ChildItems.CharacteristicsGroup4.ChildItems.CharacteristicsValueField.ChoiceList;
	ChoiceList.Clear();
	For Each Attribute In AttributesList Do
		NewItem = ChoiceList.Add();                           
		NewItem.Value = Attribute;
		NewItem.Presentation = Attribute;
	EndDo;
	
	NewItem = ChoiceList.Add();                           
	NewItem.Value = "";
	NewItem.Presentation = NStr("ru = '<Пустое значение>';
								|SYS = '<Empty value>'", "ru");
EndProcedure

&AtServer
Procedure FillCharacteristicValuesChoiceListsByQuery()
	Var CurrentRow;
	Var CurrentItem;
	Var CharacteristicValuesQuerySchema;
	Var ChoiceList;
	Var Column;
	Var NewItem;
	
	CurrentRow = Items.Characteristics.CurrentRow;
	If (CurrentRow = Undefined) Then
		Return;
	EndIf;
	CurrentItem = Characteristics.FindByID(CurrentRow);
	
	CharacteristicValuesQuerySchema = New QuerySchema();
	CharacteristicValuesQuerySchema.DataCompositionMode = DataCompositionMode;
	CharacteristicValuesQuerySchema.SetQueryText(CurrentItem["CharacteristicValues"]);
	
	ChoiceList = Items.Characteristics.ChildItems.CharacteristicsGroup3.ChildItems.CharacteristicsGroup4.ChildItems.CharacteristicsObjectField.ChoiceList;
	ChoiceList.Clear();
	For Each Column In CharacteristicValuesQuerySchema.QueryBatch[0].Columns Do
		NewItem = ChoiceList.Add();
		NewItem.Value = Column.Alias;
		NewItem.Presentation = Column.Alias;
	EndDo;
	
	ChoiceList = Items.Characteristics.ChildItems.CharacteristicsGroup3.ChildItems.CharacteristicsGroup4.ChildItems.CharacteristicsTypeField.ChoiceList;
	ChoiceList.Clear();
	For Each Column In CharacteristicValuesQuerySchema.QueryBatch[0].Columns Do
		NewItem = ChoiceList.Add();
		NewItem.Value = Column.Alias;
		NewItem.Presentation = Column.Alias;
	EndDo;
	
	ChoiceList = Items.Characteristics.ChildItems.CharacteristicsGroup3.ChildItems.CharacteristicsGroup4.ChildItems.CharacteristicsValueField.ChoiceList;
	ChoiceList.Clear();
	For Each Column In CharacteristicValuesQuerySchema.QueryBatch[0].Columns Do
		NewItem = ChoiceList.Add();
		NewItem.Value = Column.Alias;
		NewItem.Presentation = Column.Alias;
	EndDo;
	
	NewItem = ChoiceList.Add();                           
	NewItem.Value = "";
	NewItem.Presentation = NStr("ru = '<Пустое значение>';
								|SYS = '<Empty value>'", "ru");
EndProcedure

&AtClient
Procedure ValuesQueryChanged(Result, Params) Export
	Var ErrorMessage;
	Var StartCol;
	Var StartRow;
	Var CurrentItems;
	Var CheckRes;

	If Result = Undefined OR Result = "" Then
		Items.Characteristics.CurrentRow = RowForEdit;
		Items.Characteristics.ChangeRow();
		Return;
	EndIf;
	
	If Items.Characteristics.CurrentRow <> Undefined Then
		CurrentItems = Characteristics.FindByID(Items.Characteristics.CurrentRow);
	EndIf;
	If (CurrentItems = Undefined) Then
		Return;
	EndIf;
	CurrentItems["CharacteristicValues"] = Result;
	FillCharacteristicValuesChoiceListsByQuery();
	CurrentItems["ObjectField"] = "";
	CurrentItems["TypeField"] = "";
	CurrentItems["ValueField"] = "";
	
	Items.Characteristics.CurrentRow = RowForEdit;
	Items.Characteristics.ChangeRow();
EndProcedure

&AtClient
Procedure ValuesMetadataTypeChanged(Result, Params) Export
	Var CurrentRow;
	Var CurrentItem;
	Var Type;
	Var NewTable;
	
	If Result <> DialogReturnCode.OK Then
		Return;
	EndIf;
	
	CurrentRow = Items.Characteristics.CurrentRow;
	If (CurrentRow = Undefined) Then
		Return;
	EndIf;
	CurrentItem = Characteristics.FindByID(CurrentRow);
	
	Type = Params["ItemIndexes"];
	NewTable = Type["Table"];
	If NewTable <> "" Then
		CurrentItem["CharacteristicValues"] = NewTable;
		FillCharacteristicValuesChoiceListsByTable();
		CurrentItem["ObjectField"] = "";
		CurrentItem["TypeField"] = "";
		CurrentItem["ValueField"] = "";
	Else
		CurrentItem["CharacteristicTypes"] = TmpString;
	EndIf;
	
	Items.Characteristics.CurrentRow = RowForEdit;
	Items.Characteristics.ChangeRow();
EndProcedure

&AtClient
Procedure EditCharacteristicsQuery(Val NotificationName, Val QueryText = "")
	Var Params;
	Var Notification;
	Var Address;
		
	Params = New Structure;	
	If (QueryText <> "") Then
		Params.Insert("QueryText", QueryText);	
	EndIf;
	
	Notification = New NotifyDescription(NotificationName, ThisForm, Params);
	
	OpenForm("DataProcessor.ИТК_QueryWizard15.Form.QueryWizard", Params,, True,,,
		Notification, FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtServer
Function FillAttributesListByTable(TableName)
	Var MetadataObject;
	Var AttributesList;
	
	AttributesList = New Array();
	
	MetadataObject = Metadata.FindByFullName(TableName);
	
	Try
		For Each Attribute In MetadataObject.StandardAttributes Do
			AttributesList.Add(Attribute.Name);                           
		EndDo;
	Except
	EndTry;
	
	Try
		For Each Attribute In MetadataObject.Attributes Do
			AttributesList.Add(Attribute.Name);
		EndDo;
	Except
	EndTry;
	
	If (Metadata.InformationRegisters.Contains(MetadataObject) OR
		Metadata.AccumulationRegisters.Contains(MetadataObject) OR
		Metadata.AccountingRegisters.Contains(MetadataObject)) Then
		
		For Each Attribute In MetadataObject.Resources Do
			AttributesList.Add(Attribute.Name);
		EndDo;
		For Each Attribute In MetadataObject.Dimensions Do
			AttributesList.Add(Attribute.Name);
		EndDo;
	EndIf;
	
	Return AttributesList;
EndFunction

&AtServer
Function CheckQuery(QueryText, ErrorMessage)
	Var TmpSchema;
	Var TmpText;
	
	Try
		TmpSchema = New QuerySchema();
		TmpSchema.DataCompositionMode = DataCompositionMode;
		TmpSchema.SetQueryText(QueryText);
		TmpText = TmpSchema.GetQueryText();
		Return True;
	Except
		If ErrorMessage = Undefined Then
			AddErrorMessageAtServer(BriefErrorDescription(ErrorInfo()));
		Else
			ErrorMessage = BriefErrorDescription(ErrorInfo());
		EndIf;
		Return False;
	EndTry;	
EndFunction

// }
