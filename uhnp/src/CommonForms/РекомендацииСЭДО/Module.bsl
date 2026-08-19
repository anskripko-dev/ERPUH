&НаСервере
Процедура ПриСозданииНаСервере(Отказ, СтандартнаяОбработка)
	
	Параметры.Свойство("Действие", Действие); 
	Параметры.Свойство("ДанныеОшибок", ДанныеОшибок);
	Если ТипЗнч(ДанныеОшибок) = Тип("Структура")
		И ДанныеОшибок.ОрганизацииСОшибками.Количество() > 0  Тогда
		ТекущаяОрганизация = ДанныеОшибок.ОрганизацииСОшибками[0];
	КонецЕсли;
	
	РезультатАнализаСообщений = ЭлектронныйДокументооборотСФСС.СделатьАнализПроблемСообщенийСЭДО(Действие);
	
	ТекстыТаблицНайденныхПроблем = РезультатАнализаСообщений.ТекстыТаблицНайденныхПроблем;
	
	ЕстьПроблемыПроактив = РезультатАнализаСообщений.ЕстьПроблемыПроактив;
	ЕстьПроблемыТребования = РезультатАнализаСообщений.ЕстьПроблемыТребования;
	
	ЕстьПроблемы = РезультатАнализаСообщений.ЕстьПроблемы;
	
	Элементы.ПодробноHTML.Высота = 8 
		+ ?(ЕстьПроблемыПроактив, 2, 0) 
		+ ?(ЕстьПроблемыТребования, 2, 0) 
		+ РезультатАнализаСообщений.ИдентификаторыНеполученныхПроактив.Количество() * 1.48
		+ РезультатАнализаСообщений.ИдентификаторыНеполученныхТребований.Количество() * 1.48;
		
	РезультатАнализаОрганизаций = ЭлектронныйДокументооборотСФСС.ПроанализироватьОрганизацииПоОбменуСЭДО();
	НадписьПереходНаОператораСЭДО_ДанныеАнализа = РезультатАнализаОрганизаций;
	
	ПодробноHTML = "<!DOCTYPE HTML>
			|<html>
			| <head>
			|  <meta charset=""utf-8"">
			|  <style>
			|  body {
			|	font-family: 'Arial'; 
			|	font-size: 10pt;    
			|	margin: 0;
			|}  
			|html {
			|   overflow: hidden;
			|}          
			|p {
			|    display: block;
			|    margin-block-start: 1em;
			|    margin-block-end: 1em;
			|    margin-inline-start: 0px;
			|    margin-inline-end: 0px;
			|}
			|#container {
			|   max-width: 850px;  
			|	padding-right: 50px;
			|	padding-right: 20px;
   			|	padding-left: 20px;
			|}
			|#textBlock {
			|   float: right;
			|}
			|#leftcol {
			|    width: 50px;
			|}
			|#leftcol img {
			|	width: 50px;
			|	height: 50px;
			|	float: left; 
			|	margin: 10px 10px 0px 0px;
			|}      
			|table {
			|	border-color: gray;
			|	border-width: 0.5px;
			|	border-spacing: 2px;
			|	box-sizing: border-box;
			|	display: table;
			|	border-collapse: collapse;
			|	border-style: solid;
			|}    
			|tbody {
			|   display: table-row-group;
			|   vertical-align: middle;
			|   border-color: gray;  
			|	border-width: 0.5px;
			|}
			|td {
			|	padding: 5px; 
			|	height: 12px;
			|	font-size: 9pt;
			|}    
			|#tabheader {
			|	margin-bottom: 3px;
			|	padding-top: 10px;
			|}
			|#colorblock {
			|	background: #FFF1AB;
			|}
			|#bottom {
			|    clear: both;
			|}
			|  </style>
			| </head>
			|<body>
			|<div id=""container"">
			|    <div id=""textBlock"">  
			|	<div id=""leftcol"">
			|   	<img alt="""" src=""data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNjUiIGhlaWdodD0iNjQiIHZpZXdCb3g9IjAgMCA2NSA2NCIgZmlsbD0iI0YzODAwMCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPHBhdGggZmlsbC1ydWxlPSJldmVub2RkIiBkPSJNMzQgNUwzIDYxSDY0LjVMMzQgNVpNMzMuOTg1NyA5LjE1NTI4TDYuMzkzMTQgNTlINjEuMTMzM0wzMy45ODU3IDkuMTU1MjhaIi8+CjxwYXRoIGQ9Ik0zMyAyN0gzNVY0M0gzM1YyN1oiLz4KPHBhdGggZD0iTTM2IDUwQzM2IDUxLjEwNDYgMzUuMTA0NiA1MiAzNCA1MkMzMi44OTU0IDUyIDMyIDUxLjEwNDYgMzIgNTBDMzIgNDguODk1NCAzMi44OTU0IDQ4IDM0IDQ4QzM1LjEwNDYgNDggMzYgNDguODk1NCAzNiA1MFoiLz4KPC9zdmc+Cg=="" />
			|	</div>
			|    <p>Возникли ошибки при работе с СЭДО СФР."
				+ ?(ЕстьПроблемы, " Ниже перечислены проблемы с документами СЭДО, обнаруженные при анализе данных базы:", "") + "</p>" 
				+ ?(ЕстьПроблемыПроактив, "
			|<p id=""tabheader""><strong>Запросы недостающих сведений по проактивным выплатам</strong></p>
			|<table border=""1"" style=""border-collapse: collapse; width: 100%;"">
			|<tbody>
			|<tr>
			|<td style=""width: 25%; background-color: #fafafa;""><strong>Организация</strong></td>
			|<td style=""width: 35%; background-color: #fafafa;""><strong>Вид документа</strong></td>
			|<td style=""width: 25%; background-color: #fafafa;""><strong>Идентификатор СФР</strong></td>
			|<td style=""width: 15%; background-color: #fafafa;""><strong>Проблема</strong></td>
			|</tr>" + ТекстыТаблицНайденныхПроблем.ТекстТаблицыПроактив + "
			|</tbody>
			|</table>", "")
				+ ?(ЕстьПроблемыТребования, "
			|<br>
			|<p id=""tabheader""><strong>Требования СФР</strong></p>
			|<table border=""1"" style=""border-collapse: collapse; width: 100%;"">
			|<tbody>
			|<tr>
			|<td style=""width: 25%; background-color: #fafafa;""><strong>Организация</strong></td>
			|<td style=""width: 35%; background-color: #fafafa;""><strong>Вид документа</strong></td>
			|<td style=""width: 25%; background-color: #fafafa;""><strong>Идентификатор СФР</strong></td>
			|<td style=""width: 15%; background-color: #fafafa;""><strong>Проблема</strong></td>
			|</tr>" + ТекстыТаблицНайденныхПроблем.ТекстТаблицыТребования + "
			|</tbody>
			|</table>", "") + "
			|<br>
			|</div>
			|</body>
			|</html>";
				

КонецПроцедуры

&НаКлиенте
Процедура ПодробноHTMLПриНажатии(Элемент, ДанныеСобытия, СтандартнаяОбработка)
	
	СсылкаДляПерехода = Неопределено;
	ДанныеСобытия.Свойство("Href", СсылкаДляПерехода);
	
	Если СсылкаДляПерехода <> Неопределено Тогда
		СтандартнаяОбработка = Ложь;
		ЭлектронныйДокументооборотСФССКлиент.ПереключениеНаОператораСЭДООбработкаНавигационнойСсылки(
			ЭтотОбъект, Элемент, СсылкаДляПерехода);
	КонецЕсли;
	
КонецПроцедуры
