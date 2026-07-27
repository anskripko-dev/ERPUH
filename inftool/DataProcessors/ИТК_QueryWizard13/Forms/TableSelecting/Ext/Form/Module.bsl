&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	Var StartTableName;
	
	AvailableTablesBase = GetFromTempStorage(Parameters["AvailableTablesAddress"]);
	ValueToFormAttribute(AvailableTablesBase, "AvailableTables");
			  
	// ITK2 + {
	ИТК_КонструкторЗапросов.ФормаВыбораТаблицыПриСозданииНаСервере(ЭтотОбъект);
	// }
	                                  
	// ITK2 + {
	ИТК_КонструкторЗапросов.ФормаВыбораТаблицыПриСозданииНаСервере(ЭтотОбъект);
	// }

	StartTableName = Parameters["StartTableName"];     
	DisplayChangesTables = Parameters["DisplayChangesTables"];
	QueryWizardAddress = Parameters["QueryWizardAddress"];
	CurrentQuerySchemaSelectQuery = Parameters["CurrentQuerySchemaSelectQuery"];
	NestedQueryPositionAddress = Parameters["NestedQueryPositionAddress"];
	FindTable(QueryWizardAddress, 
	          CurrentQuerySchemaSelectQuery, 
			  StartTableName, 
              Parameters["SourcesImagesCacheAddress"], 
			  Parameters["ExpressionsImagesCacheAddress"]);
	
EndProcedure

&AtClient
Procedure AvailableTablesBeforeExpand(Item, Row, Cancel)
	Var CurrentItems;
	Var DataProcessor;
	
	Try
		DataProcessor = GetForm("DataProcessor.ИТК_QueryWizard13.Form.QueryWizard");
	Except
		Message(ErrorDescription());
		Return;
	EndTry;
	
	CurrentItems = AvailableTables.FindByID(Row);
	If DataProcessor.IsFakeItem(CurrentItems) Then
		EditedRow = Row;
		AttachIdleHandler("AvailableTablesBeforeExpandHandler", 0.01, True);
	EndIf;
EndProcedure

&AtClient
Procedure AvailableTablesBeforeExpandHandler()
	AvailableTablesBeforeExpandAtServer(QueryWizardAddress, Number(CurrentQuerySchemaSelectQuery), NestedQueryPositionAddress, EditedRow);
EndProcedure

&AtServer
Procedure FindTable(Val QueryWizardAddress, 
					Val CurrentQuerySchemaSelectQuery, 
					Val StartTableName, 
					Val SourcesImagesCacheAddress, 
                    Val ExpressionsImagesCacheAddress)
	Var MainObject;
	Var RootItem;
	Var QueryT;
	Var Item;

	If StartTableName <> "" Then
		MainObject = FormAttributeToValue("Object");
		QueryT = MainObject.GetSchemaQuery(GetFromTempStorage(QueryWizardAddress), CurrentQuerySchemaSelectQuery, NestedQueryPositionAddress);
		For Each RootItem In AvailableTables.GetItems() Do
			If (RootItem.GetItems().Count() = 1) AND (RootItem.GetItems().Get(0)["Name"] = "FakeFieldeItem") Then
				AvailableTablesBeforeExpandAtServer(QueryWizardAddress, CurrentQuerySchemaSelectQuery, NestedQueryPositionAddress, RootItem.GetID(), 
                                                    SourcesImagesCacheAddress, ExpressionsImagesCacheAddress, MainObject, 
                                                    QueryT);
			EndIf;

			For Each Item In RootItem.GetItems() Do
				If Item["Name"] = StartTableName Then
					Items.AvailableTables.CurrentRow = Item.GetID();

				EndIf;
			EndDo;
		EndDo;
	EndIf;
EndProcedure

&AtServer
Procedure AvailableTablesBeforeExpandAtServer(Val QueryWizardAddress, 
											  Val CurrentQuerySchemaSelectQuery, 
											  Val NestedQueryPositionAddress, 
											  Val Row, 
                                              Val SourcesImagesCacheAddress = Undefined, 
											  Val ExpressionsImagesCacheAddress = Undefined, 
											  Val MainObject = Undefined, 
											  Val Query = Undefined)
	Var MainObjectT;

	If MainObject = Undefined Then
		MainObjectT = FormAttributeToValue("Object");

		MainObjectT.AvailableTablesBeforeExpandAtServer(QueryWizardAddress, CurrentQuerySchemaSelectQuery, 
                                                        NestedQueryPositionAddress, Row, AvailableTables);
	Else
		MainObject.AvailableTablesBeforeExpandAtServer(QueryWizardAddress, CurrentQuerySchemaSelectQuery, 
                                                       NestedQueryPositionAddress, Row, AvailableTables, ,DisplayChangesTables, SourcesImagesCacheAddress, 
                                                       ExpressionsImagesCacheAddress, Query);
	EndIf;
EndProcedure

&AtClient
Function  GetItemIndexes(Item)
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
Procedure AvailableTablesSelection(Item, SelectedRow, Field, StandardProcessing)
	OK(Undefined);
EndProcedure

&AtClient
Procedure OK(Command)
	Var CurrentRow;
	Var CurrentItems;

	CurrentRow = Items.AvailableTables.CurrentRow;
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	CurrentItems = AvailableTables.FindByID(CurrentRow);

	If CurrentItems.GetParent() = Undefined Then
		Return;
	EndIf;

	While (CurrentItems["Type"] <> 1)
		AND (CurrentItems["Type"] <> 3)
		AND (CurrentItems <> Undefined) Do
		CurrentItems = CurrentItems.GetParent();
	EndDo;
	If (CurrentItems = Undefined)
		OR ((CurrentItems["Type"] <> 1) AND (CurrentItems["Type"] <> 3)) Then
		Return;
	EndIf;
	ThisForm.OnCloseNotifyDescription.AdditionalParameters["ItemIndexes"] = GetItemIndexes(CurrentItems);
	ThisForm.Close(DialogReturnCode.OK);
EndProcedure

&AtClient
Procedure Cancel(Command)
	ThisForm.Close(DialogReturnCode.Cancel);
EndProcedure