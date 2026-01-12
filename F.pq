let
// todo Сделать тип функций Extract - будет извлекать из текста например: Даты, Фамилии, ... (куда извлекать, в новую колонку или оставлять тут)
// тут, для возможности сослаться на функцию из этой библиотеки, но с возможностью вставки кода в проект
//	= let path = "G:\=EXCEL BI - мои проекты\= PQ - база знаний =\F.pq" in 	Expression.Evaluate(Text.FromBinary(File.Contents(path)), #shared)
// 	F = Expression.Evaluate(Text.FromBinary(Binary.Buffer(Web.Contents("https://raw.githubusercontent.com/Medvedevav632/PQ_function/main/" & "F.pq"))), #shared)
	F      	= let path = "G:\=EXCEL BI - мои проекты\= PQ - база знаний =\F.pq" 
			  in 	Expression.Evaluate(Text.FromBinary(File.Contents(path)), #shared),
	F_Form 	= let path = "G:\=EXCEL BI - мои проекты\2024.01 - Анализ Отчетности\2. PQ запросы\F_Form.pq" 
			  in Expression.Evaluate(Text.FromBinary(File.Contents(path)), #shared),	

Параметры = [ //  
	GetParam       = // универсальная функция. Но и в других тоже еще есть полезные моменты
		/*
			Описание:
				Функция возвращает параметры из таблицы на листе файла Excel.
				Таблица должна иметь имя "Parameters", а колонки "Parameter" и "Value"

			Алгоритм:
				Безопасно получаем таблицу по имени. Если таблица не найдена, возвращается null
				Ищем строку, где значение в столбце ParamColumn равно parameterName
				Если строка найдена, извлекается значение из столбца ValColumn
				Если таблица или строка не найдены, возвращается null

			Преимущества:
				Гибкость 		Поддерживает настраиваемые имена таблиц и столбцов
				Надежность 		Обрабатывает случаи, когда таблица или параметр не найдены
				Корректность	Использует все переданные параметры, включая ValColumn
				Простота		Логика функции осталась простой и понятной

			Пример 1: все по умолчанию
				let
					FolderPath  = GetParam("FolderPath"),  // Возвращает "C:\Projects"
					FileName    = GetParam("FileName"),    // Возвращает "data.xlsx"
					NonExistent = GetParam("NonExistent")  // Возвращает null
				in
					[FolderPath = FolderPath, FileName = FileName, NonExistent = NonExistent]
			
			Пример 2: свои названия
				to = GetParam("ParameterName", "MyTable", "MyParameterColumn", "MyValueColumn") */

		(	parameterName as text,              // Имя параметра, который нужно найти
			optional tableName as text,         // Имя таблицы 				 (по умолчанию "Parameters")
			optional parameterColumn as text,   // Имя столбца с параметрами (по умолчанию "Parameter")
			optional valueColumn as text        // Имя столбца со значениями (по умолчанию "Value")
		) as any =>
		let
			// 	Устанавливаем значения по умолчанию
				TABLE_NAME 	 = tableName 	  ?? "Parameters",
				PARAM_COLUMN = parameterColumn ?? "Parameter",
				VALUE_COLUMN = valueColumn 	  ?? "Value",

			// 	Получаем таблицу с параметрами (используем ? для безопасного доступа)
				ParamTable = Excel.CurrentWorkbook() {[Name=TABLE_NAME]}? [Content],

			// 	Ищем строку с нужным параметром
				ParamRow = 	if ParamTable is null 
							then null
							else Table.SelectRows(ParamTable, each Record.Field(_, PARAM_COLUMN) = parameterName),

			// 	Возвращаем значение параметра или null, если параметр не найден
				Value = if ParamRow is null or Table.IsEmpty(ParamRow) 
						then null
						else Record.Field(ParamRow{0}, VALUE_COLUMN) // Возвращаем значение параметра из колонки ValColumn
						// else Record.FieldValues(ParamRow{0}){1}   // Возвращаем значение из второго столбца
			in
				Value,
	
	GetParameter   = // Получить значение параметра из таблицы Parameters (колонки: {"Parameter", "Value"})
		( getValue as text ) =>
			let
				ParamTable = Excel.CurrentWorkbook(){[Name="Parameters"]}[Content],
				Result 	   = ParamTable{[Parameter=getValue]}?[Value]?
			in
				Result,
	
	Read.Parameter = // Получить значение параметра из таблицы данных в текущей книге
		/*
			! что то не то.
			Получить значение параметра из таблицы данных в текущей книге
			Параметры должны храниться в таблице данных с двумя столбцами (пары ключ-значение)
		*/
		(parameter as text, optional tablename as text) => 
			let
				/* 	Имя таблицы по умолчанию */
					ParameterTable = if tablename is null then "Параметры" else tablename,

				/* 	Получить значение параметра */
					Source 		= Excel.CurrentWorkbook(){[Name=ParameterTable]}[Content],
					Transposed  = Table.Transpose(Source),
					Headers 	= Table.PromoteHeaders(Transposed, [PromoteAllScalars=true])
			in
				Table.Column(Headers, parameter){0},
	
	fnGetParameter = // делает в excel умную таблицу с параметрами: Folder Path, File Path, File Name
		/* 
			For more information, Or to purchase a copy of this add-in, visit https://monkeytools.ca
			Original source can be found at the following URL:
			http://www.excelguru.ca/blog/2014/11/26/building-a-parameter-table-for-power-query/

			=fnGetParameter("your_parameter_name")

			One useful sample to return the current folder:
			Parameter Name: File Path
			Parameter Value: =LEFT(CELL("filename",A1),FIND("[",CELL("filename",A1),1)-1)
			Call as  "fnGetParamater("File Path")
		*/
		let
			fnGetParameter     = (ParameterName as text) as any =>
				let
					ParamSource = Excel.CurrentWorkbook(){[Name="XLGQuery_Parameters"]}[Content],
					ParamRow    = Table.SelectRows(ParamSource, each (Text.From([Parameter])=ParameterName)),
					Value       = 	if Table.IsEmpty(ParamRow)=true
									then null
									else Record.Field(ParamRow{0},"Value")
				in
					Value,
			
			fnDocumentation    = 
				type function (
					ParameterName as ( type any meta [	Documentation.FieldCaption = "ParameterName", Documentation.SampleValues = "{}" ] )
				)
				as text meta [
					Documentation.Name = "fnGetParameter",
					Documentation.MTVersion = 2.2,
					Documentation.LongDescription = "This function looks up the provided value in the XLGQuery_Parameters table in your workbook, and returns the matching value.<br><br>"&
						"<b>NOTE:</b> If you are planning to integrate this into an existing query, we highly recommend you edit your M code and make your fnGetParameter call the first "&
						"step in your query. This will avoid potential formula firewall conflicts later.<br><br>"&
						"To learn more about how this function works, see https://monkeytools.ca/parameter-table-and-function/"
					,
					Documentation.Examples = {
						[   Description= "Assuming you have the text <i>Folder Path</i> in the Parameter column of your table, and it shows a Value of <i>C:\MyData\Sales\</i>, you would call this function as follows:",
							Code = "=fnGetParameter(""Folder Path"")",
							Result = "C:\MyData\Sales\"
						]}
				],
			DocumentedFunction = Value.ReplaceType( fnGetParameter,fnDocumentation)
		in
			DocumentedFunction		
	
	],

FinReport = [ // особенные функции для проекта "Анализ отчетности"
	// хорошие функции для обработки таблицы
	Table.TransformContent 	= // #! замена значений в подтаблицах по условию в других столбцах // todo не понял
		/*
			Пример функций замены
				fx1 = (row) => /* ваша логика для f1
				fx2 = (row) => /* ваша логика для f2 

			Список условий замены
				replaceConditions = { {"ух", fx1}, {"ав", fx2} },

			Пример вызова функции
				Result = MyFunction(
					tbl,                // Исходная таблица
					"Column1",          // Имя колонки для замены значений
					"Column2"           // Имя колонки для проверки наличия текста
					replaceConditions,  // Условия замены
				)
			in	Result
		*/
		(tbl as table, col1Name as text, col2Name as text, replaceConditions as list) =>
		let
			// 	Получаем список имен колонок
				nms = Table.ColumnNames(tbl),

			// 	Определяем индексы колонок по их именам
				col1Index = List.PositionOf(nms, col1Name),
				col2Index = List.PositionOf(nms, col2Name),

			// 	Преобразуем таблицу в список строк
				SourceList = Table.ToRows(tbl),

			// 	Применяем трансформацию ко всем строкам списка
				TransformedList = 
					List.Transform(SourceList, each 
						let
							// 	Переменные
								row = _,
								col1 = row{col1Index},
								col2 = row{col2Index},

							// 	Применяем соответствующую функцию замены
								newCol1 = List.Accumulate(
									replaceConditions, 
									col1,
									(current, condition) =>
										let
											txt  = condition{0},
											func = condition{1}
										in
											if Text.Contains(col2, txt) 
											then func(row) 
											else current
								),

							// 	Формируем новую строку с обновленным значением и оставшимися неизменными колонками
								newRow = 
									List.Transform(
										List.Zip({nms, row}),
										each if _{0} = col1Name then newCol1 else _{1}
									)
						in	
							newRow
					),

			// 	Преобразуем список обратно в таблицу
				ResultTable = Table.FromRows(TransformedList, nms)
		in
			ResultTable,
	
	Table.AddedRows 		= // # ручное формирование таблицы из записей с типизацией столбцов
		/*  
			Описание:	ручное формирование таблицы их записей с типизацией столбцов
			Аргументы:	dataList - список записей, формирующих строки таблицы
			Ссылка:		про типизацию описание в танке по тегу "обновляем типы вручную, но пачками"
		*/
		( dataList as list ) =>
		let 
			//	список записей тела таблицы
				// dataList = {
				// 	[Company = "Нет отчета с таким кодом", 	Date = #date(2022, 12, 1)							],
				// 	[Company = "1", 						Date = #date(2023, 12, 1)							],
				// 	[Name = "Sample", 						Value = 123, 				Date = #date(2023, 8, 7)]
				// },
			
			// 	1 получение всех уникальных имен полей из всех записей в списке dataList
				columnNames = 
					List.Distinct(
						List.Combine(
							List.Transform(
								dataList, 
								(rec as record) as list =>Record.FieldNames(rec)
							)
						)
					),

			// 	2 пустая таблица с заголовками из columnNames
				tblBlank   = Table.FromColumns(List.Transform(columnNames, each {}), columnNames),
			
			// 	3 пустая таблица с заголовками из columnNames
				funcAddRow = 
					List.Transform(
						dataList, 
						(rec as record) as record =>
							Record.FromList( 
								List.Transform(columnNames, (x)=> Record.FieldOrDefault(rec, x, null) ), 
								columnNames
							)
					),
			
			//	4 формируем таблицу путем добавления строк с данными
				insertRows = Table.InsertRows(tblBlank, 0, funcAddRow),

			//	5 типизация столбцов по имени
				typedField = let
				 	nms = Table.ColumnNames(insertRows),
					lstDate   = {"Date"},
					lstNumber = {"Строка_ID", "Значение","Сумма","Value",
								 "На начало","На конец","Текущий период","Прошлый период"},

					dlst = List.Select(nms,(i)=>List.Contains(lstDate,   i, (x,y)=>Text.Contains(y,x))),
					nlst = List.Select(nms,(i)=>List.Contains(lstNumber, i, (x,y)=>Text.Contains(y,x))),
					tlst = List.Difference(nms, dlst & nlst),

					f=(x,y)=>List.Transform(x,(i)=>{i,y}),
					transflst = f(dlst, Date.Type) & 
								f(nlst, Number.Type) & 
								f(tlst, Text.Type),
					
					to = Table.TransformColumnTypes(insertRows, transflst)	
				in  to
		in 
			typedField,

	Table.SkipUp  			= // # ищем текст в  и удаляем строки выше найденной строки
		(x, txt)=>
			(y)=>
				not Text.Contains(
					Text.Combine( 
						List.Select(
							Record.ToList(Record.SelectFields(y, txt)),
							(i)=>i is text
						)
					),
				x),

	Table.SkipUp2 			= // # удаляет строки сверху, до строки, в которой находится искомый текст
		/*
			Пример		Table.Skip(TransCol, F_Torg[Table.SkipUp]("Код по СК"))
			Результат	
		*/
		(txt)=>
			(row)=> 
				List.Select( 
					Record.ToList(row), 
					(i)=>i is text and Text.Contains(i,txt)
				)={},
	
	Text.RemoveMulti  		= // удаление текста из списка в заданной КОЛОНКЕ. Проверить скорость Добавить тип
		/*
			Пример	F[Text.RemoveMulti](from,)
		*/
		(tbl as table, ColumnName as text, RemoveList as list) as table=>
			[	lst  = RemoveList,
				dict = List.Buffer(List.Zip({lst, List.Repeat({""}, List.Count(lst)) }) ),
				func = (txt)=>List.Accumulate(dict, txt, (s,c)=>Text.Replace(s, c{0}, c{1})),
				tr   = Table.TransformColumns(tbl, {ColumnName, func})
			]  [tr],

	// 1 используемые функции
	Text.ContainsAny = (str, needles) as logical => List.Count(needles),
	// 	-----------------------------------
	//	недоделанные функции
	//	-----------------------------------
	Table.TypesAllColumns = // массовая замена типов столбцов. Пока не так выходит. не так работает //! есть у МИШИ
		(tbl as table) =>
		let
            // from = #table({"a".."e"},{{123,null,12.34,#date(2023,1,1),null},{null,"мыла",null,#date(2023,2,2),#time(2,3,4)},{345,"раму",34.56,null,#time(3,4,5)}}),
            f=(x)=>List.Mode(List.Transform(List.RemoveNulls(x),Value.Type)),
			lst = List.Transform(Table.ToColumns(Table.Range(tbl,0,10)),f),
            tr  = List.Zip({Table.ColumnNames(tbl),lst}),
            to  = Table.TransformColumnTypes(tbl,tr)
        in
            to,
	fxJoinSpr =	// добавляем колонки в таблицу через объединение таблиц по ID_Форма  
			/*
				добавляем колонки в таблицу через объединение таблиц по ID_Форма
				to = fxJoinSpr(addColumns1, Справочники[Спр_ФормыОтчетности], "КодБКС", {"Название", "Report_ID"}),
			*/	
		let 	
			
			func = (tblIn as table, 		// таблица куда разворачиваем новые колонки
					columnName1 as text, 	// имя столбца, которое есть в двух таблицах (могут быть разные навания, доработать код)
					tblSpr as table, 		// таблица со справочниками
					columnName2 as text, 	// имя столбца, которое есть в двух таблицах (могут быть разные навания, доработать код)
					lstLoadColumn as list) 	//
			as table => 
			
			let Sprav  = 1, // Справочники[Спр_ФормыОтчетности],
				Join   = Table.NestedJoin(tblIn, {columnName1}, tblSpr, {columnName2},"tmp"),
				Expand = Table.ExpandTableColumn(Join, "tmp", lstLoadColumn)
			in  Expand,

			typ = type function (tblIn as table, columnName1 as text, tblSpr as table, columnName2 as text, lstLoadColumn as list) as table 
					meta [ 	Documentation.Name            = "",
							Documentation.LongDescription = "добавляем колонки в таблицу через объединение таблиц по ID_Форма" ],
			result = Value.ReplaceType(func,typ) 
		in result,
	
	//	-----------------------------------
	// возможно полезное
	//	-----------------------------------
	fxRenameColumnsByIndices = 
		(Source as table, ColumnNamesNew as list, Indices as list) =>
		let
			ColumnNamesOld = List.Transform( Indices, each Table.ColumnNames(Source){_} ), 
			ZippedList     = List.Zip( { ColumnNamesOld, ColumnNamesNew } ),
			RenamedColumns = Table.RenameColumns( Source, ZippedList )
		in
			RenamedColumns,
			
	getHEX = // декодирует текст в таблицу. Но почему то не всякий текст, проверить
		/*
			= get("bc8xSgRQDATQu/x6CckkmSR7FbFYbQVBxUb27v5qEfxFusfM5Olnfb5/fK3ruq3L+r69rSsDKoYMFsv24X75rzzpMsVRjVCi56SoWQJt5OgUYvKkIpPiqeY20f3XvDz6uk0KqCztYk8c1d4te45vh+hsnFS4QpgOxsyO9D6pjCnpHiOtM+F/s14fH1qVWCVbwXJ6nlQgKIxy5UyHzlGRbkJFRRFE1gm5eksU1Kemba+/P/8C")
			разница с декодером Table.JsonDecode в наличие там BinaryEncoding.Base64, а тут отсутствии
		*/

		(txt as text) as table =>[
			bin  = Binary.FromText(txt),
			dec  = Binary.Decompress(bin,Compression.Deflate),
			json = Json.Document(dec),
			tbl  = Table.FromRecords(json)]
		[tbl],
	findColumnByKeywords = // # возвращает имя колонки в которой найдены одновременно ключевые слова //! fine
        /*
            Использование: 
                1 ищем колонку
                    colName = F2[findColumnByKeywords](selCol,{"Государственный компонент"}),
                
                2 ссылаемся на найденную колонку (варианты):
                    GetColumnValue = (row) => Record.Field(row, colName),              //  если колонка точно есть
                    GetColumnValue = (row) => Record.Field(row, colName ?? ""),        //  если колонки нет, то возвращаем "" как аналог без ?? ""
                    GetColumnValue = (row) => Record.Field(row, colName ?? "Column1"), //  если колонка нет, то возвращаем имя любой другой колонки
                    GetColumnValue = (row) => Record.Field(row, colName ?? "колонка не найдена"), //  "колонка не найдена" чисто справочнодля информации
                
                3 используем в запросе
                    to  = Table.SelectRows(selCol, each GetColumnValue(_) <> null),    //  используем ссылку в запросе

            Описание:
                1 findColumnByKeywords:           Функция принимает таблицу и список ключевых слов.
                2 Table.TransformColumnTypes:     Все колонки приводятся к типу text, чтобы обеспечить корректный поиск по строкам.
                3 Table.UnpivotOtherColumns:      Преобразует таблицу в формат "ключ-значение", где можно искать текстовые совпадения по ключевым словам.
                4 Table.SelectRows:               Выбирает строки, содержащие все ключевые слова из списка.
                5 List.First(flt[ColumnNames]):   Получает имя первой колонки, которая содержит все ключевые слова.
                6 if colName <> null then:        Если колонка найдена, фильтруем строки по этой колонке. Если нет — возвращаем исходную таблицу без изменений.
        */
        (tbl as table, keywords as list) =>
        let
            //  Преобразуем все колонки в текст для поиска ключевых слов
                typ = Table.TransformColumnTypes(tbl, List.Transform(Table.ColumnNames(tbl), (x) => {x, type text})),

            //  Преобразуем таблицу в формат "ключ-значение"
                unp = Table.UnpivotOtherColumns(typ, {}, "ColumnNames", "Values"),

            //  Фильтруем строки, где все ключевые слова содержатся в значении
                flt = Table.SelectRows(unp, each List.AllTrue(List.Transform(keywords, (k) => Text.Contains([Values], k)))),

            //  Если колонка найдена, возвращаем ее имя, иначе возвращаем null
                colName = if Table.RowCount(flt) > 0 then List.First(flt[ColumnNames]) else null,

            //  Обработка: если колонка не найдена, возвращаем исходную таблицу
                result = if colName <> null then Table.SelectRows(tbl, each Record.Field(_, colName) <> null) else tbl
        in
            colName,
    
	fxSelectColumnsWord = // выбор столбцов по вхождению текста //? не актуальна после findColumnByKeywords
		/*
			Пример
				= F[fxSelectColumnsWord] (from,{"Запасы","Активы"})
			Улучшение
				1	функция не оптимизирована
				2 	поиск по точному соответствию, с учетом регистра
		*/
		(tbl as table, optional words as list) => 
			let from = tbl,
				lst  = if words <> null then words else {"активы","запасы"},
				typ  = Table.TransformColumnTypes(from, List.Transform(Table.ColumnNames(from), (x)=>{x,type text})),
				unp  = Table.UnpivotOtherColumns(typ, {}, "ColumnNames", "Filters"),
				flt  = Table.SelectRows(unp, each List.AnyTrue(List.Transform(lst, (x)=>Text.Contains([Filters], x)))),
				nms  = List.Sort(List.Distinct(flt[ColumnNames]), Order.Ascending),
				sel  = Table.SelectColumns(typ, nms)
			in  sel,

	fxKofPodobie 		= // коэффициентом подобия сравнивая две строки
		/*
			Пример 
				= F[fxKofPodobie]("собака", "сабака")		-> 0,83333333333333337
				= F[fxKofPodobie]([Статья], [СтатьяИмя])
				
				Добавить колонку с коэффициентом подобия		
				to = Table.AddColumn(from, "fxKofPodobie", each F[fxKofPodobie]([Статья], [СтатьяИмя]))
		*/
		(text1 as text, text2 as text) as number =>
			let text1 = Text.Upper(text1),
				text2 = Text.Upper(text2),
				matching_chars = List.Count(List.Intersect({Text.ToList(text1), Text.ToList(text2)})),
				average_length = (Text.Length(text1) + Text.Length(text2)) / 2,
				coef =  matching_chars / average_length
			in  coef,
	
	AllFieldNamesTables = // возвращает список столбцов во всех подтаблицах в колонке
		/* 
			nms = F[AllFieldNamesTables](from,"tmp"),
			exp = Table.ExpandTableColumn(from, "tmp", nms)
		*/
		(tbl, columnName) =>
			List.Distinct(
				List.Combine(
					List.Transform(
						Table.Column(tbl, columnName), 
						each Table.ColumnNames(_)
					)
				)
			),
	
	AllFieldNamesRecord = // возвращает список столбцов во всех таблицах в поле Value
		/* F[AllFieldNamesRecord](from,"tmp") */
		(tbl) =>
			List.Union(
				List.Transform(
					tbl[Value], 
					Record.FieldNames
				)
			),

	fxAddOtherRowColumn = 1// Тестовые функции	
		// получаем значения из предыдущих или последующих строк
		// По аргументам всё думаю понятно – таблица, столбец, имя нового столбца и на сколько строк сдвинуть.
			//   let
			//         tbl = Table.FromColumns({{"a".."i"},{1..9}},{"a","b"}),
				
			//         fxAddOtherRowColumn = // сдвиг 
			//             (tbl,col,newcol,index) =>
			//                 [   lst =   List.Buffer(Table.Column(tbl,col)),
			//                     add =   Table.AddIndexColumn(tbl,newcol,index,1),
			//                     f   =   if index <0 
			//                             then (x)=> if x<0 then null else lst{x}
			//                             else (x)=>lst{x}?,
			//                     to = Table.TransformColumns(add,{newcol,f})
			//                 ][to],

			//         to  = fxAddOtherRowColumn(tbl,"b","c",-1),
			//         to1 = fxAddOtherRowColumn(tbl,"b","c",-3),
			//         to2 = fxAddOtherRowColumn(tbl,"b","c",2)
			//     in
			//         to2
		,
	GetQueryValues 		= // функция для получения значений по имени из #shared, например таблиц. #sections[Section1] - не видит
		(queryName as text) as any =>
			Record.Field(#shared, queryName),
	
	AllQueryOneTable 	= 1 // все именно таблицы проекта в одном месте. Проверить
		// let
		// 	from = Record.ToTable(Record.RemoveFields(#sections[Section1],"Result")),
		// 	nms  = List.Distinct(List.Combine(List.Transform(from[Value],Table.ColumnNames))),
		// 	to   = Table.ExpandTableColumn(from,"Value",nms)
		// in
		// 	to

	], 

UTIL  	  = [ // Мои утилиты 
	readme.UTIL = "// УТИЛИТЫ",
	//  Read - чтение файлов разных форматов
	read_xlsx 	= // преобразование файлов формата XLSX (трансформация bin формата) доработать
		(folderPath as text) as table =>
        let
			from  = Folder.Files(folderPath),
			
			nms	  = {"Name","Extension", "Attributes", "Date created", "Content"} & {"Folder Path"},
			Sel	  = Table.SelectColumns(from, nms),
			Trans = Table.TransformColumns(Sel, {
				{"Date created", (x)=> DateTime.Date(x), type date},
				{"Folder Path",  (x)=> Text.AfterDelimiter(x, "\", {2, RelativePosition.FromEnd}), type text}
			}),

		// 	3. фильтруем строки
			FilteredRows 	= Table.SelectRows(Trans, each 
				(Text.Start([Extension], 5) = ".xlsx" and 	// оставляем только .xlsx
				[Attributes][Hidden] = false ) and			// убираем скрытые
				not Text.StartsWith([Name], "~$")			// убираем временные
			),

		//  4. преобразуем бинарники в таблицы и фильтруем строки в подтаблицах
			TransformBinary = Table.TransformColumns(FilteredRows,         
				{"Content", each let 
					TransBinary  = Excel.Workbook(_),
					NoPrintAreas = Table.SelectRows(TransBinary, each not Text.Contains([Name], "$")),
					OnlySheets   = Table.SelectRows(NoPrintAreas, each [Kind]="Sheet")
					in OnlySheets
				} 
			),
			
			// добавляем колонки и фильтруем таблицу
			AddTwoColumns = let 
				AddSize   = Table.AddColumn(TransformBinary, "Size", (x)=> F[fxSizeFile](x[Attributes][Size]), type text),
				AddShName = Table.AddColumn(AddSize, "SheetsName",   (x)=> Text.Combine(x[Content][Name],","), type text),
				nms	 	  = {"Name", "Content"} & {"Size"} & {"Folder Path","SheetsName"},
				SelCol	  = Table.SelectColumns(AddShName, nms)
			in  SelCol
		in  AddTwoColumns,
	
	read.word 	= // возвращает список таблиц из файла Word формата *.docx
		/*
			Описание:		см Word.TablesList 
			Пример:			= F[Word.TablesList](File.Contents("F:\Название Файла.docx"))
		*/
		(file) =>
			[	getTable = (xml)=> // функция возвращает таблицы из xml разметки
				[	f=(x)=>[a = Table.SelectRows(x,(r)=>r[Name]="tr")[Value],
							b = List.Max(List.Transform(a,Table.RowCount)),
							c = Table.FromList(a,g,b)
						]  [c],
						
					g=(x)=>List.Transform(x[Value],h),
						
					h=(x)=>Text.Combine(List.Transform(Table.SelectRows(x,(r)=>r[Name]="p")[Value],i),"#(lf)"),
						
					i=(x)=>[a = Table.SelectRows(x,(r)=>r[Name]="r")[Value],
							b = (x)=> Table.SelectRows(x,(r)=>r[Name]="t")[Value],
							c = List.Combine(List.Transform(a,b)),
							d = List.Select(c,(x)=>Value.Is(x,Text.Type)),
							f = Text.Combine(d)
						]  [f],
					to = f(xml)
				]  [to],
				
				from  = F[fxUnzip2016](file),
				xml   = Xml.Document(from{[FileName="word/document.xml"]}[Content]){[Name="document"]}[Value]{[Name="body"]}[Value],
				filtr = Table.SelectRows(xml, each ([Name] = "tbl"))[Value],
				to    = List.Transform(filtr, getTable)
			]  [to],
	Read.CSV 	= // большая функция, не разбирал и не переводил еще, из LibPQ 
		/*
			Описание	Load arbitrary CSV file with unknown number of columns (up to 1000)
						and unknown number of extra lines before the column names (first column name
						has to be known).
			Ссылка 		https://github.com/sio/LibPQ/blob/master/Modules/Read.CSV.pq
			Пример

			Note: 		If last column name starts with underscore or is empty, please specify
						it in the parameters or that column will be lost.
		*/
		(	tsv_path,
			first_column_header,
			optional encoding,
			optional delimiter as text,
			optional lastcolumn_name as text
		) =>
			let
				/* Default parameter values */
				Delimiter = if delimiter is null then "#(tab)" else delimiter,
				Encoding  = if encoding  is null then 65001    else encoding,

				/* Load CSV */
				Source = Csv.Document(
							File.Contents(tsv_path),
							[
								Delimiter	= Delimiter,
								Columns		= 1000,
								Encoding	= Encoding,
								QuoteStyle	= QuoteStyle.None
							]),
				
				Skipped 	 = 	Table.RemoveFirstN(Source,each [Column1] <> first_column_header),
				WithHeaders  = 	Table.PromoteHeaders(Skipped, [PromoteAllScalars=true]),
				ValidColumns = 	List.Reverse(
									List.Skip(
										List.Reverse(Table.ColumnNames(WithHeaders)),
										each (_ = "" or Text.StartsWith(_, "_")) and _ <> lastcolumn_name
									)
								),
				
				Result = Table.SelectColumns(WithHeaders, ValidColumns)
			in
				Result,

	read_csv 	= // преобразование файлов формата CSV (трансформация bin формата)
		/*
			Пример:		
				= Table.AddColumn(from, "tmp", (x)=> F[read_csv](x[Content]) )
			Улучшение:	
				1 Delimiter в  аргументы
			Особенности: 
				headers ?? false - Если headers не задан или равен null, используется значение false
			Справка:
				QuoteStyle.Csv, когда встречается кавычка, весь последующий текст оставляется в неизменном виде, пока не встретится следующая кавычка; сами кавычки при этом удаляются
    			QuoteStyle.None кавычки воспринимаются как один из символов и если между ними есть пробельные символы – по ним произойдет разделение
		*/
		(bin, optional headers as logical)=> 
			let
				from = Csv.Document(bin, [Delimiter = ";", Encoding = 65001, QuoteStyle = QuoteStyle.None]),
				to   = if headers ?? false then Table.PromoteHeaders(from, [PromoteAllScalars = true]) else from
			in
				to,
		
	// Load functions
	LoadF       = // загрузка функций с Гитхаба / Работает ⚡⚡ / на выходе все функции
		let GitHubPath  = "https://raw.githubusercontent.com/Medvedevav632/PQ_function/main/"
    	in  Expression.Evaluate(Text.FromBinary(Binary.Buffer(Web.Contents(GitHubPath & "F.pq"))), #shared),

	LoadGit     = // загрузка функций с Гитхаба / Работает ⚡ / новая функция 
		/*  
			= fxLoad("F") 			 возвращает весь список функций в файле F.pq
			= fxLoad("F", "LoadCSV") возвращает функцию
		*/
		(FileName as text, optional FunctionName as text) =>
			let GitHubPath  = "https://raw.githubusercontent.com/Medvedevav632/PQ_function/main/",
    			FileContent = Expression.Evaluate(Text.FromBinary(Binary.Buffer(Web.Contents(GitHubPath & FileName & ".pq"))), #shared)
			in  if   FunctionName = null 
				then FileContent 
				else Record.Field(FileContent, FunctionName),	
		
	LoadLoc   	= // загрузка запросов с локального диска
		let 
			from = 
				[ 	Folder =  {"G:\=EXCEL BI - мои проекты\2024.01 - Анализ Отчетности\2. PQ запросы\"},
					Local  = 
						[	
							Global 		= Folder{0} & "F.pq",
							Form 		= Folder{0} & "F_Form.pq",
							Calerndar 	= Folder{0} & "F_Calerndar.pq",
							CreateFunc 	= Folder{0} & "F_CreateFunc.pq"
							
						],
					Web	   =
						[	
							FinAnalys			= "https://github.com/Medvedevav632/FinAnalys/",
							PowerQueryFunction 	= "https://github.com/Medvedevav632/PowerQueryFunction/",
							Test = "https://raw.githubusercontent.com/buchlotnik/buchlotnik_functions/main/UnZip.pq"
							/* 	Web.Contents – получает информацию с сайта 
								(raw.githubusercontent.com – очень удобная штука – сразу отдает непосредственно 
								текст функции – там не требуется выцарапывать её из разметки страницы). 
								Далее Text.FromBinary переводит полученную информацию в текст, 
								а Expression.Evaluate + #shared превращают текст в код */

						]
				],
			
			// 	функция загрузки кода М:
			 	/*	из текстового файла */
				func=(x as text)=> 
					Expression.Evaluate(Text.FromBinary(File.Contents( Record.Field(from[Local], x) ) ), #shared),
			
				/*	из интернета */
				func2=(x as text)=> 	
					Expression.Evaluate(Text.FromBinary(Web.Contents( Record.Field(from[Web], x))), #shared),

			// 	типизация функции и ее аргументов
				typ = type function(
					x as (type text meta [	Documentation.FieldCaption 		= "Укажите название файла (поля) с путем к скриптам",
											Documentation.FieldDescription 	= "Номер строки начинается с единицы",
											Documentation.SampleValues 		= {"PackCalendar"},
											Documentation.AllowedValues 	= Record.FieldNames(from[Local])
											//Documentation.AllowedValues = List.Transform(Record.FieldValues(from[Local]),(x)=>Text.AfterDelimiter(x,"\", {0, RelativePosition.FromEnd})) // названия файлов
										])
					) as any meta [	Documentation.Name            = "Load",
									// Documentation.LongDescription = "<b> Грузим код М из папки </b> <br>" & Text.Combine(Record.ToList(from[Local]),"<br>"),
									Documentation.LongDescription = "<b> Грузим код М из папки </b> <br>" & from[Folder]{0},
									Documentation.Examples = {[ 
										Description = "Возвращяет запись с функциями", 
										Code 		= "=Load(""PackCalendar"")", 
										Result 		= Lines.ToText(List.Transform(Record.FieldNames(from[Local]),(x)=> """" & x & """")) // названия полей записи Local текстом, чтобы копировать их в аргумент функции
									]} ],
			
			// 	выводим результат функции
				result = Value.ReplaceType(func, typ) 
		in 	
			result,
	
	LoadLocal 	= // загрузка запросов с локального файла одной строкой 
		Expression.Evaluate(
			Text.FromBinary(
				Binary.Buffer(
					File.Contents("G:\=EXCEL BI - мои проекты\2024.01 - Анализ Отчетности\2. PQ запросы\F.pq")
				)
			), #shared
		),
	LoadGitOld 	= // загрузка функций с Гитхаба / локальной папки / оригинальная функция
		[	func = (fnName as text, optional BasePath as text) as function => // as function  к чему обязывает?!
                let
                    DefaultPath = "G:\=EXCEL PQ\PQ-function-load\",
                    GitHubPath  = "https://raw.githubusercontent.com/hohlick/pquery/master/",
                        
                    BasePath = if (BasePath <> null) then BasePath else DefaultPath,
                    Path = BasePath & (if Text.End(BasePath, 1) <> "\" then "\" else ""),
                    File = Path & fnName & ".pq",
                    
                    // если путь уже импортирован в рабочую книгу, используйте существующий путь
					// если еще не импортирован, попробуйте загрузить его из текстового файла в папке
					// если папка не найдена - взять из GitHubPath
					Function = try Expression.Evaluate(Text.Replace(fnName, ".", "_"), #shared)  
                    otherwise try  Expression.Evaluate(Text.FromBinary(Binary.Buffer(File.Contents(File))), #shared) 
                    otherwise      Expression.Evaluate(Text.FromBinary(Binary.Buffer(Web.Contents(GitHubPath & fnName & ".pq"))), #shared)
                in
                    Function
        ][func],
	
	LoadPq   	= // загрузка функций из файла. x - полный путь + имя файла с расширением
		(path)=>Expression.Evaluate(Text.FromBinary(Binary.Buffer(File.Contents(path))), #shared),
	
	// Load files
	LoadBinCSV  = // загрузка файла CSV 
		/*
			Пример:		
				= Table.AddColumn(from, "tmp", (x)=> F[LoadBinCSV](x[Content]) )
			Улучшение:	
				1 Delimiter в  аргументы
			Справка:
				QuoteStyle.Csv, когда встречается кавычка, весь последующий текст оставляется в неизменном виде, пока не встретится следующая кавычка; сами кавычки при этом удаляются
    			QuoteStyle.None кавычки воспринимаются как один из символов и если между ними есть пробельные символы – по ним произойдет разделение
		*/
		(x)=> let
			from = Csv.Document(x,[Delimiter=";", Encoding=65001, QuoteStyle=QuoteStyle.None]),
			to   = Table.PromoteHeaders(from, [PromoteAllScalars=true])
		in	to,

	LoadCSV  	= // загрузка файла CSV (путь)
		/* 	Пример:	
				= F[LoadCSV]( "G:\=EXCEL BI - мои проекты\2024.01 - Анализ Отчетности\4. CSV выгрузка\Белкоопсоюз\_v_3.csv")
		*/
		(pathFile as text)=>
			Table.PromoteHeaders(
				Csv.Document(
					File.Contents(pathFile),
					[Delimiter=";", Encoding=65001, QuoteStyle=QuoteStyle.None]
				), 
				[PromoteAllScalars=true]
			),
	LoadPath 	= // загрузка пути с листа текущей книги
			"Excel.CurrentWorkbook(){[Name=""Table1""]}[Content]{0}[Path]",				
	
	// разобрать и проверить функции
	fxFillRightOrLeft = // заполнение вправо, влево //todo новая функция
		/* 
			https://gist.github.com/m-dekorte/56b996be4f51a6eaab6132e1e46db30d
			Пример
			let
				Source = #table(
					type table [Entry = Text.Type, Category = Text.Type, SubCategory = Text.Type, Amount = Currency.Type], 
					{
						{"Expense", "Travel", null, 1500},
						{"Expense", null, "Airfare", 500},
						{"Expense", null, "Hotel", 1000},
						{"Expense", "Office Supplies", null, 300},
						{"Expense", null, "Stationery", 100},
						{"Expense", null, "Furniture", 200}
					}
				),
				FillRight = fillRightOrLeft(Source, null, 3),
				FillRightCollSelection = fillRightOrLeft(Source, {"Category", "SubCategory"}, 3),
				FillLeft = fillRightOrLeft(Source, null, null, true),
				FillLeftCollSelection = fillRightOrLeft(Source, {"Category", "SubCategory"}, 3, true),
				BreakDown = Table.AddColumn( Source, "break down", each 
					[
						recToTable = Record.ToTable(_),
						fillRight = Table.FillDown(recToTable, {"Value"}),
						fillLeft = Table.FillUp(recToTable, {"Value"})
					]
				),
				Review = BreakDown{0}[break down]
			in
				Review
		*/
		( 	tbl as table, 				 // таблица источник
			optional fillCols as list, 	 // список колонок для заполнения. Если не указан = null, то все обрабаываются колонки (allCols)
			optional topRows  as number, // сколько строк из верхней части таблицы будут заполняться. Если параметр = null, то обрабатывается вся таблица
			optional fillLeft as logical // направление заполнения. true — заполнение вверх FillUp, если false (или не задано) — заполнение вниз FillDown
		) as table => 
		
		let
			fillFunction = 
				if fillLeft ?? false 
				then Table.FillUp 
				else Table.FillDown,
			
			tableRows = if topRows = null 
				then tbl 
				else Table.FirstN(tbl, topRows),
			
			allCols = Table.ColumnNames( tbl ),
			
			// Заполнение к выбранным колонкам
			fillSideways = 
				Table.TransformRows( tableRows,
					(x)=> x & Record.FromTable(
						fillFunction( 
							Record.ToTable( 
								Record.SelectFields(x, fillCols ?? allCols, MissingField.Ignore)
							), 
							{"Value"}
						)
					)
				),
			
			// результат обрабатывается и возвращается в том же формате, что и исходная таблица, сохраняя ее тип
			result = 
				if topRows = null 
				then Value.ReplaceType( 
						Table.FromRecords( fillSideways ), 
						Value.Type(tbl)
					)
				else Value.ReplaceType( 
						Table.FromRecords( fillSideways ) & Table.Skip( tbl, topRows ), 
						Value.Type(tbl)
					)
		in
			result,

	Table.ToMCode = // превращает таблицу из запроса в таблицу в кодировке М. //? Есть лучше - CreateTable
		let
			func = (Table1 as table) =>
				let
					Table = Table1,
					ReplaceNulls 	= Table.ReplaceValue( Table, null, "", Replacer.ReplaceValue, Table.ColumnNames(Table) ),
					ListOfColumns 	= Table.ToRows( ReplaceNulls ),
					ConvertToTable 	= Table.FromList( ListOfColumns, Splitter.SplitByNothing(), null, null, ExtraValues.Error ),
					CoreString 		= Table.AddColumn( ConvertToTable, "Custom", each Text.Combine(List.Transform([Column1], each Text.From(_)), """ ,""")),
					FullString = "= #table( {"""
						& Text.Combine(Table.ColumnNames(Table), """, """)
						& """}, #(lf) { {"""
						& Text.Combine(CoreString[Custom], """}, #(lf) {""")
						& """} } ) ",
					ReplaceBlanks = Text.Replace(FullString, """""", "null")
				in
					ReplaceBlanks,
			documentation = [
				Documentation.Name = " Table.ToMCode ",
				Documentation.Description = " Transforms a  <code>Table</code>  to a string of M code that will create that table in the query editor. ",
				Documentation.LongDescription = " Transforms a  <code>Table</code>  to a string of M code that will create that table in the query editor. ",
				Documentation.Category 	= " Table ",
				Documentation.Source 	= "  ",
				Documentation.Version 	= " 1.0 ",
				Documentation.Author 	= " Imke Feldmann: www.TheBIccountant.com . ",
				Documentation.Examples 	= {[Description = "  ", Code = "  ", Result = "  "]}
			]
		in
			Value.ReplaceType(func, Value.ReplaceMetadata(Value.Type(func), documentation)),
	
	fxExportCSV   = // экспорт в формат CSV. Проверить работу. Не все получается!
		(	table_to_export as nullable table, 
			folder as text, 
			filename as text
		) as nullable table => 
		
		let
			_tbl = table_to_export, 
			
			p = [
				folder_normalized       = if Text.EndsWith(folder,"\") then folder else (folder & "\"),
				folder_web_format       = Text.Replace(folder_normalized, "\", "/"),
				filename_with_extension = if Text.EndsWith(Text.Lower(filename),".csv") then filename else filename & ".csv",
				full_filename           = folder_web_format & filename_with_extension,
				tblexport = ()=> 
					if _tbl = null 
					then #table(null,{}) 
					else _tbl
				],

			json = 
				Text.FromBinary
					(Json.FromValue(
					Table.ToRows( p[tblexport]() )
					), 
				1251
				),

			json2 =   
				Text.Replace(
					Text.FromBinary(
					Json.FromValue(
						Table.ToRows( p[tblexport]() )
					), 
					1251
					),",",";"
				),

			// objFile.WriteLine(arr.map(row => row.join(';')).join('\n'));
			
			// objFile.WriteLine(arr.join('\n'));
			// objFile.WriteLine(arr.join(';'));
			// var semicolonArr = arr.map(row => row.split(',').join(';'));
			// objFile.WriteLine(semicolonArr.join('\n'));
			// objFile.WriteLine(arr.join('\n'));
			export_csv = Web.Page("
				<script>
					var fso=new ActiveXObject('Scripting.FileSystemObject');
					var objFile=fso.OpenTextFile('" & p[full_filename] & "',2 , true);
					var arr=" & json & ";
					var arrWithSemicolon = arr.map(row => row.map(cell => cell.replace(/,/g, ';')).join(';')).join('\n');
					objFile.WriteBlankLines(0);
					objFile.Close(); 
				</script>"
				),
			
			to = 
				if export_csv=null
				then p[tblexport]() 
				else p[tblexport]() 
		in to
	],

MyPack    = [ // моя библиотека функций 🔥
	Readme = "= MyPack =",
//	UNIVERSAL LOADER 🔹 
	Folder.LoadFiles 	 = // подключаемся к папке (от 01.11.2025)	убрать проверку на input null. Хоть один аргумент всегда будет/должен быть
	// 🔥🔥 todo  разделитель сделать в шаге 5!! 
		/* 
			Описание:
				1. подключаемся к папке с файлами по имени датасета или по полному пути
				2. выбираем номер шага загрузки. По умолчанию выгружаем последний шаг
				3. чистим папку от временных и скрытых файлов, оставляем файлы .xlsx или .csv, преобразуем бинарники
				4. для csv разделитель стоит по умолчанию - ","
				5. в книгах excel оставляем только листы (Sheet), в csv после скрипта питона один лист берется, первый видимый
			
			Пример:	
				Рабочий вариант от26.10.2025
				= F[Folder.LoadFiles]([Path = "G:\=EXCEL BI - мои проекты\2000 - МИНИ проекты\2025.10 - Минское райпо\Исходники\XLSX", 
					FileExtension = "xlsx", MaskNameFile = "бал", SubFolders = false, ExpandSheets = false, SheetNames = true, Step = 5, 
					FilterFunction = (x)=>Text.Contains(x[Item], "99")] )

				Вариант 1. Путь задан, все остальное по false. "\" в конце можно пропустить, не важно
				= F[Folder.LoadFiles]([Path = "G:\=EXCEL BI\", 
				Extension = "xlsx", SubFolders = false, ExpandSheet = false, ShowSheet = false, Step = 0])
				
				Вариант 1. Путь задан, все остальное по умолчанию
					to = F[Folder.LoadFiles]( [Path = "G:\=EXCEL BI - мои проекты\"] ) 
				
				Вариант 2. Не разворачиваем подтаблицы и показывам колонку с именами листов
					to = F[Folder.LoadFiles]( [Path = "G:\=EXCEL BI - мои проекты", ShowSheet = true ])
				
				Вариант 3. Разворачиваем подтаблицы и показывам колонку с именами листов
					to = F[Folder.LoadFiles]( [Path = "G:\=EXCEL BI - мои проекты", ExpandSheet = 1, ShowSheet = 1])
			
				0  сделать параметр которыйбудет фильтровать листы внути таблиц xlsx
				1  в csv поднимать или неподнимать заголовки в Распсиание жэтого недалть не надо
			*/
		let
			func   = (input as record) => [ 	
				// 	АРГУМЕНТЫ Шаг 1. Значения по умолчанию
					defaultOptions	= [
							Path		   = "", 	 // обязательный параметр
							FileExtension  = "xlsx", // расширения файла
							FileMaskName   = "",     // маска имени файла
							SubFolders 	   = false,	 // берем файлы текущей папки, в подпапки не смотрим
							ExpandSheets   = false,	 // листы книг не раскрываем в отдельные строки // уточнить примеры
							SheetNames     = false,	 // колонку с именами листов не показываем
							Step		   = 0,		 // возвращаем последний шаг функции
							FilterFunction = null    // функция фильтрации листов // название добавить fSheetsFilter
													 // todo добавить фильтрацию по имени папки, если параметр включен
						],
					
				// 	АРГУМЕНТЫ Шаг 2. Проверка на корректность
					// 	возвращаем список неверных имен параметров
						invalidFields = List.Difference(
							if input = null then {} else Record.FieldNames(input),	// список введенных аргументов
							Record.FieldNames(defaultOptions) 						// список допустимых аргументов
						),

					//  совмещаем опции, если нет ошибок - у checkArguments (input) приоритет на перезапись 
						finalOptions = 
							if List.Count(invalidFields) > 0 
							then error 	"Неверный аргумент(ы): "   & Text.Combine(invalidFields, ", ") & 
										". Допустимые аргументы: " & Text.Combine(Record.FieldNames(defaultOptions), ", ")
							else Record.Combine({defaultOptions, input ?? defaultOptions}), // оператор ?? проверяет input на null

				//	АРГУМЕНТЫ Шаг 3. Типизация аргументов
					GetValue  	= // функция определения типа входных параметров
						// todo ВНИМАНИЕ! Значение 0 (ноль) будет считаться "невалидным" и заменяться на null. 
						// todo Это критично для числовых параметров (например, kodStart или kodEnd), где 0 — допустимое значение.
						// 	Пустая строка "" также будет меняться на null, что неверно для текстовых полей, например Extension
						(options as record, fieldName as text, typeConverter as function) =>
							let value  = Record.FieldOrDefault(options, fieldName, null)
							in	if List.Contains({null, 0, ""}, value) then null else typeConverter(value),

					FULLPATH	= GetValue(finalOptions, "Path", 			Text.From	),	// "C:\" или "C:", есть проверка
					EXTENSION 	= GetValue(finalOptions, "FileExtension",	Text.From	),	// xls, csv, xlsx, др.
					MASKNAME    = GetValue(finalOptions, "FileMaskName", 	Text.From	),  // маска имени файла "бал"
					SUBFOLDERS	= GetValue(finalOptions, "SubFolders",		Logical.From),	// обработка подпапок
					EXPANDSHEET	= GetValue(finalOptions, "ExpandSheets",   	Logical.From),	// разворачивать листы
					SHOWSHEET	= GetValue(finalOptions, "SheetNames", 		Logical.From),	// показывать колонку с листами в конце
					STEP     	= GetValue(finalOptions, "Step", 		   	Number.From	),	// номер шага 
					FUNC	    = GetValue(finalOptions, "FilterFunction", 	Function.From),
					
										
				//	1. path				формируем полный и относительный path к папке или подпапкам
					/* Описание шага:
					   FullFolderPath:	Меняем все символы / на \ в для корректного указания пути в Windows
					   FolderPath:	 	Cтавим "\" в конце строки, если его нет
					   Source:			Если SUBFOLDERS = true, то извлекаем только файлы из этой папки, false -  возвращает все содержимое папки с подкаталогами
					   ChildFolder:		Убираем из столбца "Folder Path" путь FolderPath делая относительный путь к файлам */
					FullFolderPath 	= Text.Replace(FULLPATH,"/","\"),
					FolderPath 		= if Text.EndsWith(FullFolderPath,"\") then FULLPATH else FULLPATH & "\",
					Source 			= if SUBFOLDERS = true then Folder.Files(FolderPath) else Folder.Contents(FolderPath),
					ChildFolder 	= Table.ReplaceValue(Source, FolderPath, "", Replacer.ReplaceText, {"Folder Path"}),
					
				//	2. Output			возвращаем таблицу с "Extension" в нижнем регистре если path существует
					/* Описание шага:
					   DesiredOutput	меняем все символы / на \ в столбце "Folder Path" для единообразия формата пути
					   BlankTable		создаем пустую таблицу, если в шаг DesiredOutput не удался - путь пуст или не существует
					   ActiveTable		возвращаем или таблицу с данными или пустую, если пути DesiredOutput нет
					   Output:			приводим расширения в столбце "Extension" к нижнему регистру, делая их единообразными */
					DesiredOutput 	  = Table.ReplaceValue(ChildFolder,"/","\",Replacer.ReplaceText,{"Folder Path"}),
					BlankTable 		  = Table.FromRows({},{"Content","Name","Extension","Date accessed","Date modified","Date created","Attributes","Folder Path"}),
					ActiveTable 	  = try DesiredOutput otherwise BlankTable,
					Output 			  = Table.TransformColumns(ActiveTable,{{"Extension", Text.Lower, type text}}),

				// 	3. FilteredRows		фильтруем строки: оставляем файлы нужного формата, убираем скрытые и временные файлы
					// обрезаем полный путь // TruncateNames 	= Table.TransformColumns(Output, {{"Folder Path", each Text.Start(_, 250), type text}}),
					FilteredRows 	= Table.SelectRows(Output, each 
							// Text.Length([Folder Path] & [Name]) <= 250 		// если слишком длинный путь, надо ли, проверить
							Text.AfterDelimiter([Extension], ".") = EXTENSION 	// оставляем нужные форматы файлов
							and [Attributes][Hidden] = false 				 	// убираем скрытые
							and not Text.StartsWith([Name], "~$")			 	// убираем временные
							and (try Text.Contains([Name], MASKNAME) otherwise true) // фильтруем файлы по маске имени. try при "" так как в GetValue меняем "" на null
					),
				
				//  4. Trans			фильтруем колонки + меняем формат колонок 
					nms   = {"Folder Path","Name","Extension","Content","Date accessed","Date modified","Date created","Attributes"},
					Sel	  = Table.SelectColumns(FilteredRows, nms),
					Trans = Table.TransformColumns(Sel, {
								{"Date created", (x)=> DateTime.Date(x), type date},
								{"Folder Path",  (x)=> Text.AfterDelimiter(x, "\", {2, RelativePosition.FromEnd}), type text}
							}),
				
				//  5. TransformBinary	преобразуем binary в таблицу, фильтруем строки в подтаблицах // оставляем один лист
					TransformBinary = [
						//	функции фильтровки листов в книгах XLSX в подтаблицах 
						 	fxAllSheets	= (x)=> Text.Length(x[Name]) > 1, // имя больше 1 символа
							fxBKS1		= (x)=> Text.Length(x[Name]) = 1, // имя 1 символ
							fxBKSOPO 	= (x)=> try Value.Is(Number.From(x[Name]), type number) and Number.From(x[Name]) <= 6 otherwise null, // 1-6 коды ОПО
							fxBKS15chr	= (x)=> Text.Length(x[Name]) = 15, // организации 
							fxBKSsvod 	= (x)=> x[Name] = "СВОД В РАЗРЕЗЕ",
													
						//  fXLS    подключаемся к папке (оставляем XLS, фильтруем подтаблицы по полю "Name")
							fXLS = 	Table.TransformColumns(Trans, {"Content", (x)=> 
										let Binary 	= 	Excel.Workbook(x),
											Select	= 	Table.SelectRows(Binary,  each 
															not Text.Contains([Name], "$")	// убираем именованные диапазоны
														),
											Select2	= 	Table.SelectRows(Select,  each 
														// 	фильтруем листы в файлах xlsx функцией из аргументов. Если не задана, то все листы
														// 	без Record.HasFields(input, {"FilterFunction"}) если нет в аргументах ошибка
															if Record.HasFields(input, {"FilterFunction"}) and (input[FilterFunction] <> null)
															then input[FilterFunction](_)
															else fxAllSheets(_)
														)
										in	Select2 	// [Data]{0} оставляем первый лист
									}),

						//  fXLSX   подключаемся к папке (оставляем XLSX, фильтруем подтаблицы по полю "Name")
							fXLSX = 	
								Table.TransformColumns(Trans, {"Content", (x)=> 
									let Binary 	= 	Excel.Workbook(x),
										Select	= 	Table.SelectRows(Binary,  each 
														not Text.Contains([Name], "$")	// убираем именованные диапазоны
														and [Kind]="Sheet"				// оставляем листы
													),
										Select2	= 	Table.SelectRows(Select,  each 
													// 	фильтруем листы в файлах xlsx функцией из аргументов. Если не задана, то все листы
													// 	если Record содержит поле с таким именем и значение поля не null, то 
														if Record.HasFields(input, {"FilterFunction"}) and (input[FilterFunction] <> null)
														then input[FilterFunction](_) // true или false. FilterFunction = (x)=>true
														else Text.Length(_[Name]) > 1 // true или fxAllSheets(_) или Text.Contains(_[Name], "04")
													)
									in	Select2 	// [Data]{0} оставляем первый лист
								}),
						
						//  fCSV    //! папка кажется не та Trans загрузка файлов из папки с CSV файлами (параметр Columns=... пропускаю? сеператор ",")
							fCSV =  Table.TransformColumns(Trans, 
										{"Content", (file)=>
											Table.PromoteHeaders(
												Csv.Document(file, 
													[	
														Columns     = null, 			// Количество или имена столбцов {"A","B","C"}
														Delimiter	= ";", 				// Разделитель, по умолчанию ","
														QuoteStyle	= QuoteStyle.None, 	// если QuoteStyle.Csv
														Encoding	= 65001 			// Кодировка UTF-8
													]
												)
											), type table
										}
									),
						//  fPAR    загрузка файлов из папки с .parquet файлами // нужно ли поднимать заголовки?!
							fPAR =  Table.TransformColumns(Trans, 
										{"Content", (file) =>
											try 
												let tbl = #table({"Err"}, {{"1"}})
												// let tbl = Parquet.Document(file)
												in  Table.PromoteHeaders(tbl)
											otherwise 
												#table({"Error"}, {{"Parquet not supported in this environment"}})
											, type table
										}
									),

						//  return  возвращаем результат обработки
							return = Record.FieldOrDefault(
										[ 
											xlsx = fXLSX, 
											xls  = fXLS, 
											csv  = fCSV,
											parquet  = fPAR
										], 
											Text.From(EXTENSION), "Error"
									)
					][return],
					
				// 	6. AddTwoColumns	добавляем колонки и фильтруем таблицу
					AddTwoColumns = let 
						AddSize   = Table.AddColumn(TransformBinary, "Size", (x)=> Number.Round(x[Attributes][Size]/1024,0) ),
						AddShName = Table.AddColumn(AddSize, "SheetNames",   (x)=> try Text.Combine(x[Content][Name],",") otherwise null, type text),
						SelCol	  = Table.SelectColumns(AddShName, {"Folder Path", "Name", "Content"} & {"Size","SheetNames"}),
						SelRow    = Table.SelectRows(SelCol, each ([SheetNames] <> "")) // если на предыдущем шаге фильтруя строки в подтаблицах не осталось ни одного листа
					in  SelRow,

				// 	7. SelColumns		лишний шаг наверное
					Rename 		= Table.RenameColumns(AddTwoColumns, {{"Content", "Data"}}),
					SelColumns 	= Table.SelectColumns(Rename, {"Folder Path", "Name", "Data"}),
				
				//  8. Result			готовим таблицу для вывода (параметр сделать для стиля может с условиями)
					Result 	= 	Record.Field([
							tbl  = SelColumns,
							xls  = let 
								// 	разворачиваем листы  - по умолчанию не разворачиваем (если null или не указан) //* тип табдле слетает!
									exp = 	if   not EXPANDSHEET
											then Table.AddColumn(tbl, "SheetNames", (x) => Text.Combine(x[Data]?[Name]?, ",")?? "", type text)
											else Table.ExpandTableColumn(tbl, "Data", {"Data", "Name"},{"Data", "SheetNames"}),
								
								//  показываем колонку "SheetNames" - по умолчанию не показываем
									sh = 	if  SHOWSHEET = false or SHOWSHEET = null
											then Table.RemoveColumns(exp,{"SheetNames"})
											else exp,

								//  показываем колонку "Folder Path" с относительным путем - по умолчанию не показываем
									sub = 	if SUBFOLDERS = false or SUBFOLDERS = null
											then Table.RemoveColumns(sh,{"Folder Path"})
											else sh
								in  sub,
							
							xlsx = let 
								// разворачиваем листы  - по умолчанию не разворачиваем (если null или не указан) //* тип табдле слетает!
								// 		было (x)=> try Text.Combine(x[Data][Name],",") otherwise null
								// 		x[Data]? — безопасно проверяет, существует ли поле Data в x. Если нет, возвращает null
								// 		оператор ?? избыточен, так как Text.Combine уже вернет null в случае null на входе
								// 		можно так ?? null или ?? "нет листов"
								exp = 	if EXPANDSHEET = false or EXPANDSHEET = null
										then Table.AddColumn(tbl, "SheetNames", (x) => Text.Combine(x[Data]?[Name]?, ",")?? "", type text)
										else Table.ExpandTableColumn(tbl, "Data", {"Data", "Item"},{"Data", "SheetNames"}), 
										// может вместо {"Data", "Item"} сделать {"Data", "Name"}. В xls Item нет. В xlsx всегда ли одинаковы "Item" и "Name"
								
								//  показываем колонку "SheetNames" - по умолчанию не показываем
								// todo если SheetNames=0 то EXPANDSHEET=1 выдает ошибку
								// todo Фильтрация столбцов с Table.SelectColumns вместо Table.RemoveColumns
								// sh = if SHOWSHEET ?? false then exp else Table.RemoveColumns(exp, {"SheetNames"})
								// sh = try if SHOWSHEET then exp else Table.RemoveColumns(exp, {"SheetNames"}) otherwise exp 
								// Это полезно, если SHOWSHEET может содержать неожиданные значения.
								sh = 	if SHOWSHEET = false or SHOWSHEET = null
										then Table.RemoveColumns(exp,{"SheetNames"})
										else exp,

								//  показываем колонку "Folder Path" с относительным путем - по умолчанию не показываем
								sub = 	if SUBFOLDERS = false or SUBFOLDERS = null
										then Table.RemoveColumns(sh,{"Folder Path"})
										else sh
								in  sub,
						
							csv  = 	// Table.RenameColumns(tbl, {{"Data", "Content"}})
									if SUBFOLDERS = false or SUBFOLDERS = null
									then Table.RemoveColumns(tbl,{"Folder Path"})
									else tbl,
							
							parquet  = 	if SUBFOLDERS = false or SUBFOLDERS = null
									then Table.RemoveColumns(tbl,{"Folder Path"})
									else tbl			
						], 
							EXTENSION),
				// 	9. Result2			применение функции фильтрации, если функция задана
					/*	Result2 = 
							if Record.HasFields(input, {"FilterFunction"}) and (input[FilterFunction] <> null)
							then Table.SelectRows(Result, input[FilterFunction]) // Table.SelectRows(Result, input[FilterFunction])
							else Result,*/

				// 	Return 				возвращаем результаты шагов подключения к папке
					Return = Record.FieldOrDefault(
						[	99 = finalOptions, // показываем активные опции
							1 = ChildFolder,
							2 = Output,		
							3 = FilteredRows,
							4 = Trans,
							5 = TransformBinary,
							6 = AddTwoColumns,
							7 = SelColumns,
							8 = Result
						], 	
							if   STEP = null 
							then Text.From(8) 		// последний шаг
							else Text.From(STEP)	// заданный шаг
						, 	
							"Error. Нет такого номера шага в функции LoadFolder")
				][Return],
				
			fnType = [ // прописать остальные аргументы. Если optional то еслиизменять по звездочке, то не будет ошибки
					   // При наличии AllowedValues SampleValues не нужен, этот текст не виден, так как есть список выбора
					inputType	= 
						type [	
							Path				    = (type nullable text  meta [Documentation.FieldCaption = "Путь к папке", Documentation.SampleValues = {"C:\DataFiles\SubFolder"}]),
							optional FileExtension  = (type nullable text  meta [Documentation.FieldCaption = "ТипФайла", Documentation.SampleValues = {"csv"}, Documentation.AllowedValues = { "xlsx", "csv" } ]),
							optional FileMaskName   = (type nullable text  meta [Documentation.FieldCaption = "Маска имени файла", Documentation.SampleValues = {"баланс"} ]),
							optional SubFolders     = (type logical 	   meta [Documentation.FieldCaption = "Обрабатывать подтаблицы, true / false", Documentation.SampleValues = {"true / false"}, Documentation.AllowedValues = {true,false} ]),
							optional ExpandSheets   = (type logical 	   meta [Documentation.FieldCaption = "Извлекать листы, true / false", Documentation.SampleValues = {"true / false"},Documentation.AllowedValues = {true,false} ]),
							optional SheetNames     = (type logical 	   meta [Documentation.FieldCaption = "Показывать колонку с именали листов, true / false", Documentation.SampleValues = {"true / false"}, Documentation.AllowedValues = {true,false} ]),
							optional Step		    = (type number 	       meta [Documentation.FieldCaption = "НомерШага (от 1 до 8)", Documentation.SampleValues = {"9"}, Documentation.AllowedValues = {0..9}]),
							optional FilterFunction = (type nullable function meta [Documentation.FieldCaption = "Функция фильтрации файлов", Documentation.SampleValues = {"..."}])
						],

					inputMeta	= 
						[ 	Documentation.Name = "LoadFolder",
							Documentation.LongDescription = 
							"	<b> Подключаемся к папке, получаем список файлов XLSX или CSV </b> <br>
									= F[Folder.LoadFiles]( [Path = ""G:\=EXCEL BI - мои проекты\""] ) <br>
									= F[Folder.LoadFiles]( [Path = ""G:\=EXCEL BI - мои проекты\"", FileExtension = ""xlsx""] ) <br>
									= F[Folder.LoadFiles]( [Path = ""G:\=EXCEL BI - мои проекты\"", FileExtension = ""xlsx"", SubFolders = false, ExpandSheets = false, SheetNames = true, Step = 0])
									= F[Folder.LoadFiles]( [Path = ""G:\=EXCEL BI - мои проекты\"", FileExtension = ""xlsx"", SubFolders = true, Step = 1]) - посмотреть каталоги
								",
							Documentation.Examples = {
								[	Description = "", 
									Code 		= "=F[Folder.LoadFiles]( [Path = ""G:\=EXCEL BI - мои проекты\""] )",
									Result		= "таблица с файлами xls"], 
								[	Description = "", 
									Code 		= "= F[Folder.LoadFiles]([Path = ""G:\=EXCEL BI - мои проекты\"", FileExtension = ""xlsx""])",
									Result		= "таблица"],
								[	Description = "", 
									Code 		= "= F[Folder.LoadFiles]([Path = ""G:\=EXCEL BI - мои проекты\"", FileExtension = ""xlsx"", SubFolders = false, ExpandSheets = false, SheetNames = true, Step = 0])",
									Result		= "таблица"]
							}
						],

					return 	    = type function (input as inputType) as table meta inputMeta
				][return],

			result = Value.ReplaceType(func,fnType)
		in 	result,

//	FOLDER 
	Files.SmartFolder    = // возвращает таблицу с данными о файлах в папке или SharePoint используя Folder.Files или Folder.Contents (Monky,"Приручи данные")
		/*
			For more information, Or to purchase a copy of this add-in, visit https://monkeytools.ca
		
			To use this function you must pass it the path to either a local folder or the equivalent
			path for Office 365's SharePoint url.  The easiest way to acquire this information is to place
			the following formula in a cell in the Excel Workbook:
			=IFERROR(LEFT(@CELL("filename",A1),FIND("[",@CELL("filename",A1),1)-1),"Workbook needs to be saved!")
		*/
		let 
			fnSmartFolder = (FullFolderPath as text, optional IncludeSubfolders as logical) as table =>
				let
					IncludeSubfolders = if IncludeSubfolders = null then true else IncludeSubfolders,
					BlankTable 		  = Table.FromRows({},{"Content","Name","Extension","Date accesssed","Date modified","Date created","Attributes","Folder Path"}),
					Source 		      = 
						if Text.StartsWith(FullFolderPath,"https://") 
						then
							let
								FullFolderPath  = Text.Replace(FullFolderPath,"\","/"),
								FolderPath      = 
									if Text.EndsWith(FullFolderPath,"/") 
									then Text.Start(FullFolderPath,Text.Length(FullFolderPath)-1) 
									else FullFolderPath,
								SharePointSite  = Text.BeforeDelimiter(FolderPath,"/",4),
								SharePointFiles = 
									if IncludeSubfolders = true 
									then
										let
											Source = SharePoint.Files(Text.BeforeDelimiter(FolderPath,"/",4), [ApiVersion = 15]),
											Select = Table.SelectRows(Source, each Text.StartsWith([Folder Path], FolderPath))
										in
											Select
									else
										let
											Source  = SharePoint.Contents(Text.BeforeDelimiter(FolderPath,"/",4), [ApiVersion = 15]),
											Folders = Text.Split(Text.AfterDelimiter(FolderPath,"/",4),"/"),
											NavigateToFolder = 
												List.Accumulate(
													{0..List.Count(Folders) -1 },
													Source,
													(state, current) => state{[Name=Folders{current}]}[Content]
												)
										in
											NavigateToFolder,
								
								StripRootFolder = Table.ReplaceValue(SharePointFiles,FolderPath & "/","",Replacer.ReplaceText,{"Folder Path"})
							in 
								StripRootFolder
						else
							let
								FullFolderPath = Text.Replace(FullFolderPath,"/","\"),
								
								FolderPath = 
									if   Text.EndsWith(FullFolderPath,"\") 
									then FullFolderPath 
									else FullFolderPath & "\",
								
								Source = 
									if   IncludeSubfolders = true 
									then Folder.Files(FolderPath)
									else Folder.Contents(FolderPath),

								StripRootFolder = Table.ReplaceValue(Source,FolderPath ,"",Replacer.ReplaceText,{"Folder Path"})
							in 
								StripRootFolder,

					DesiredOutput 	  = Table.ReplaceValue(Source,"/","\",Replacer.ReplaceText,{"Folder Path"}),
					ActiveTable 	  = try DesiredOutput otherwise BlankTable,
					Output 			  = Table.TransformColumns(ActiveTable,{{"Extension", Text.Lower, type text}})
				in
					Output,

			fnDocumentation = type function
				(
					FullFolderPath as (type text meta [
						Documentation.FieldCaption 		= "FullFolderPath",
						Documentation.FieldDescription 	= "Enter full path to local or SharePoint (sub)folder",
						Documentation.SampleValues 		= {"C:\DataFiles\SubFolder"}
					]),
					optional IncludeSubfolders as (type logical meta [
						Documentation.FieldCaption 		= "IncludeSubfolders",
						Documentation.FieldDescription 	= "Would you like to include files in subfolders?",
						Documentation.SampleValues 		= {"true (default), false"}
					])
				) as table meta
					[
						Documentation.Name = "fnSmartFolder",
						Documentation.MTVersion = 2.1,
						Documentation.LongDescription = "The <code>fnSmartFolder</code> function will accept a <i>full folder path</i> (local or SharePoint hosted) and display all files contained within it. It also:"
							& "<ul>"
							& "<li>-Removes the folder path from the beginning of the Folder column (to allow easier location of subfolders)</li>"
							& "<li>-Replaces all / separators with \ (to allow for filters that work when dynamically switch from local to SharePoint folders)</li>"
							& "<li>-Contains an optional <code>true</code> or <code>false</code> parameter to display files in subfolders (true) or not (false)</li>"
							& "</ul>"
							& "Technical info you may not care about: This function dynamically switches between the <code>SharePoint.Files()</code> and <code>Folder.Files()</code> connections by default, or <code>SharePoint.Contents()</code> and <code>Folder.Contents()</code> if you set the optional <code>IncludeSubfolders</code> parameter to <code>false</code>.",
						Documentation.Examples = 
							{
								[
									Description = "Working with a local file path to retrieve files in folder and subfolders (using the Folder.Files() function).",
									Code = "=fnSmartFolder(""C:\Users\<username>\<companyname>\MonkeyTools - General\Demos"",true)",
									Result = "| Content  |   Name     | Extension | Date accesssed   | Date modified    | Date created     | Attributes | Folder Path | #(lf)"
											&"------------------------------------------------------------------------------------------------------------------------- #(lf)"
											&"| [Binary] | File1.xlsx | .xlsx     | 2023-08-01 23:02 | 2023-08-01 23:02 | 2023-08-01 23:02 | [Record]   |             | #(lf)"
											&"| [Binary] | Csv1.csv   | .csv      | 2023-08-01 23:02 | 2023-08-01 23:02 | 2023-08-01 23:02 | [Record]   | CSVs\       | #(lf)"
											&"-------------------------------------------------------------------------------------------------------------------------"
								],
								[
									Description = "Working with a local file path to retrieve files in selected folder only (using the Folder.Contents() function).",
									Code = "=fnSmartFolder(""C:\Users\<username>\<companyname>\MonkeyTools - General\Demos"",false)",
									Result = "| Content  |   Name     | Extension | Date accesssed   | Date modified    | Date created     | Attributes | Folder Path | #(lf)"
											&"------------------------------------------------------------------------------------------------------------------------- #(lf)"
											&"| [Binary] | File1.xlsx | .xlsx     | 2023-08-01 23:02 | 2023-08-01 23:02 | 2023-08-01 23:02 | [Record]   |             | #(lf)"
											&"-------------------------------------------------------------------------------------------------------------------------"
								],
								[
									Description = "Working with a SharePoint file path to retrieve files in folder and subfolders (using the SharePoint.Files() function).",
									Code = "=fnSmartFolder(""https://domain.sharepoint.com/sites/MonkeyTools/Shared Documents/General/Demos/"",true)",
									Result = "| Content  |   Name     | Extension | Date accesssed   | Date modified    | Date created     | Attributes | Folder Path | #(lf)"
											&"------------------------------------------------------------------------------------------------------------------------- #(lf)"
											&"| [Binary] | File1.xlsx | .xlsx     | 2023-08-01 23:02 | 2023-08-01 23:02 | 2023-08-01 23:02 | [Record]   |             | #(lf)"
											&"| [Binary] | Csv1.csv   | .csv      | 2023-08-01 23:02 | 2023-08-01 23:02 | 2023-08-01 23:02 | [Record]   | CSVs\       | #(lf)"
											&"-------------------------------------------------------------------------------------------------------------------------"
								]
								,
								[
									Description = "Working with a SharePoint file path to retrieve files in selected folder only (using the SharePoint.Contents() function).",
									Code = "=fnSmartFolder(""https://domain.sharepoint.com/sites/MonkeyTools/Shared Documents/General/Demos/"",false)",
									Result = "| Content  |   Name     | Extension | Date accesssed   | Date modified    | Date created     | Attributes | Folder Path | #(lf)"
											&"------------------------------------------------------------------------------------------------------------------------- #(lf)"
											&"| [Binary] | File1.xlsx | .xlsx     | 2023-08-01 23:02 | 2023-08-01 23:02 | 2023-08-01 23:02 | [Record]   |             | #(lf)"
											&"-------------------------------------------------------------------------------------------------------------------------"
								]
							}
					],
			DocumentedFunction = Value.ReplaceType( fnSmartFolder, fnDocumentation )
		in
			DocumentedFunction,

	Files.SheetsInFolder = // возвращает таблицу с информацией обо ВСЕХ листах во ВСЕХ файлах Excel в папке
        /*
            Description Возвращает таблицу с информацией обо всех листах в любых файлах Excel в определенной папке.
            Usage		=F [ Files.SheetsInFolder ] ( "C:\path\to\my\folder\" )
            Result 		Таблица, содержащая содержимое двоичного файла, имена файлов, таблиц листов и названия листов для каждого листа в каждой электронной таблице в данной папке
        */

        (folderPath as text) as table =>
        let
            Source 			= Folder.Files(folderPath),
            FilteredRows 	= Table.SelectRows(Source, each Text.Start([Extension],5) = ".xlsx"),
            RemovedOtherColumns = Table.SelectColumns(FilteredRows,{"Content", "Name"}),
            NoTemps 		= Table.SelectRows(RemovedOtherColumns, each not Text.StartsWith([Name], "~$")),
            InsertedCustom 	= Table.AddColumn(NoTemps, "Sheets", each Excel.Workbook([Content])),
            Expanded 		= Table.ExpandTableColumn(InsertedCustom, "Sheets", {"Data", "Name","Kind"}, {"D","N","K"}),
            NoPrintAreas 	= Table.SelectRows(Expanded, each not Text.Contains([N], "$")),
            OnlySheets 		= Table.SelectRows(NoPrintAreas, each Text.Contains([K], "Sheet"))
        in
            OnlySheets,
	
	Folder.Latest 		 = // возвращает путь к самому новому файлу в каталоге, по критерию
		/*
			Возвращает путь к самому новому файлу в каталоге, соответствующем указанному требования. 
			Возвращайте значение null, если ни один файл или подкаталог не соответствует требованиям.

			По умолчанию возвращается самый новый подкаталог.

			Требования указаны как функция, принимающая один аргумент — строку.запись из вывода Folder.Contents. 
			Если эта функция возвращает true, файл в вопрос считается соответствующим требованиям. 
			См. реализацию DefaultFilter для примера.

			По умолчанию вывод Folder.Contents сортируется по дате изменения. 
			Вы можете использовать необязательный третий аргумент для указания другого порядка сортировки:
				- Текстовый аргумент рассматривается как имя поля;
				- Список списков рассматривается как список имен полей в паре с Order.* перечисления;
				- Также используется одна пара {field_name, order_enum} без закрывающего списка.
				приемлемый
		*/
		(directory as text, optional requirements as function, optional sort_field) =>
		let
			DefaultFilter = each [Attributes][Kind] = "Folder",
			
			Filter 	= 	if requirements is null 
						then DefaultFilter 
						else requirements,

			SortOrder =
					 if	sort_field is null then {{"Date modified", Order.Descending}}
				else if sort_field is text then {{sort_field, Order.Descending}}
				else if sort_field is list and sort_field{0} is list then sort_field
				else if	sort_field is list then {sort_field}
				else	error "unsupported argument type for sort_field",

			Candidates 	= Table.SelectRows( Folder.Contents(directory), Filter),
			Sorted 		= Table.Sort(Candidates, SortOrder),
			Chosen 		= List.First(Table.ToRecords(Sorted)),
			Return 		= if   Chosen is null
						  then null
						  else Chosen[#"Folder Path"] & Chosen[Name]
		in
			Return,
//	FILE (на входе путь к файлу)
	Files.ExtensionFile	 = // возвращает расширение файла
		(FilePath)=>Text.Lower(List.Reverse(Splitter.SplitTextByDelimiter(".")(FilePath)){0}),
	Files.ContentInFile  = // возвращает структуру файла xlsx 
		/* 
		*/
		let
			fnSmartFile = (FilePath as text) as any =>
			let
				BlankTable_Excel  = Table.FromRows( {}, { "Name", "Data", "Item", "Kind", "Hidden" } ),
				BlankTable_Access = Table.FromRows( {}, { "Name", "Data", "Schema", "Item", "Kind" } ),
				FileExtension     = Text.Lower(List.Reverse(Splitter.SplitTextByDelimiter(".")(FilePath)){0}),
				Source = 
					if Text.StartsWith( FilePath, "https://" ) 
					then 
						let FilePath = Text.Replace( Text.Replace( FilePath, "\", "/" ), " ", "%20" ),  
							Source   = Web.Contents(FilePath)
						in 	Source 
					else 
						let Source = File.Contents(FilePath) 
						in  Source,
				
				Output = 
					if Text.StartsWith(FileExtension,"xls")
					then try Excel.Workbook( Source, null, true) otherwise BlankTable_Excel
					else if FileExtension = "accdb" or FileExtension = "mdb"
					then try Access.Database( Source ) otherwise BlankTable_Access
					else Source
			in
				Output,
			fnDocumentation = type function (
				FilePath as (
					type text meta [
						Documentation.FieldCaption = "FilePath",
						Documentation.SampleValues = "{C:\DataFiles\Filename.xlsx}"
						]
					)
				)
				as any meta [
					Documentation.Name = "fnSmartFile",
					Documentation.MTVersion = 1.1,
					Documentation.LongDescription = "The <code>fnSmartFile</code> function will accept a <i>the full path</i> to a local or SharePoint hosted file and is designed to 'smart switch' between the Web and Local required connectors should the file path dynamically change.<br>"
							&"Note that the behaviour of the connector depends on the type of files you connect to:<br>"
							&"<ul>"
							&"<li>Excel: Displays a table including the standard columns found when connecting to an external Excel file.</li>"
							&"<li>Access: Excel: Displays a table including the standard columns found when connecting to an external Access database.</li>"
							&"<li>All others: Due to the fact that each file needs to be interpreted differently by Power Query, our Monkey displays the file itself. Double click the file to allow Power Query to interpret it, or right click it and tell Power Query what type of file it is that you are looking at.</li>"
							&"</ul>"
							&"To learn more about how this function works, see https://monkeytools.ca/smartfile-function/",
					Documentation.Examples =
					{
						[   Description= "Working with an Excel file",
							Code = "fnSmartFile(""C:\DataFiles\Filename.xlsx"")",
							Result = "|  Name     |  Data     |  Item     |  Kind         |  Hidden    |#(lf)"
									&"------------------------------------------------------------------#(lf)"
									&"|  Summary  |  [Table]  |  Summary  |  Sheet        |  FALSE     |#(lf)"
									&"|  Data     |  [Table]  |  Data     |  Sheet        |  FALSE     |#(lf)"
									&"|  Table1   |  [Table]  |  Table    |  Sheet        |  FALSE     |#(lf)"
									&"|  Sales    |  [Table]  |  Sales    |  Sheet        |  FALSE     |#(lf)"
									&"|  rngHome  |  [Table]  |  rngHome  |  Named Range  |  FALSE     |"
						],
						[   Description= "Working with an Access database",
							Code = "=fnSmartFile(""C:\DataFiles\Access.accdb"")",
							Result = "|  Name       |  Data     |   Schema    |  Item        |  Kind    |#(lf)"
									&"-------------------------------------------------------------------#(lf)"
									&"|  tblBudgets |  [Table]  |             |  tblBudgets  |  Table   |#(lf)"
									&"|  tblSales   |  [Table]  |             |  tblSales    |  Table   |"
						],
						[   Description= "Working with a csv, text, json or other file type",
							Code = "=fnSmartFile(""C:\DataFiles\Data.csv"")",
							Result = "Data.csv file (with logo)"
						]
					}
				],
			DocumentedFunction = Value.ReplaceType(fnSmartFile,fnDocumentation)
		in
			DocumentedFunction,
// 	ADDS_COLUMNS
	fxAddMultiColumns 	 = // создание нескольких столбцов
		/*
			? можно сразу задавать положение столбца?! проверить
			
			* одной строкой	самый короткий вариант
			fxAddMultiColumns = (tbl,lst) as table => List.Accumulate(lst, tbl, (s,c)=>Table.AddColumn(s,c{0},c{1},c{2}?))
			
			* Как вариант этой функции:
				к таблице "Имя" + "Значение", добавляет три столбца (элементов в списке), в каждом умножает 10 на Значение, 20 на значение и т.д.
				t = List.Accumulate(
						{10,20,30}, // {10,20,30,40} - если 4 столбца добавить нужно
						Источник,
						(state,cur)=>Table.AddColumn(state, "Вариант " & Text.From(cur), each cur * [Cost 2023]) // Вариант 10, Вариант 20 ...
					)
		*/
		[ 	
			func = (table as table, addedColumns as list) as table =>
				List.Accumulate(
					addedColumns, 	// список колонок вида (имя + функция + тип)
					table, 			// стартовое значение
					(s, c) => Table.AddColumn(s, c{0}, c{1}, c{2}?) // если пустые колонки, то d{2} заменть на each null
				),
			
			typ  = type function (table as table, addedColumns as list) as table 
					meta [ 	Documentation.Name            = "fxAddMultiColumns",
							Documentation.LongDescription = "функция, создающая сразу несколько столбцов. Например = fxAddMultiColumns(tbl,{'дата', each 1})",
							Documentation.Examples = {
								[	
									Description = "добавить один столбец", 
									Code 		= "=fxAddMultiColumns(#table({""a"",""b"",""c""},{}),{1,""первый""})",
									Result		= "#table({""первый"",""b"",""c""},{})"
								], 
								[	
									Description = "добавить два столбца", 
									Code 		= "=fxAddMultiColumns(#table({""a"",""b"",""c""},{}),{-1,""первый с конца""})",
									Result		= "#table({""a"",""b"",""первый с конца""},{})"
								]
							}
						],
			
			typ2 = [ 
				optionsMeta	= 
					[ 	Documentation.Name            = "fxAddMultiColumns",
						Documentation.LongDescription = "функция, создающая сразу несколько столбцов. Например = fxAddMultiColumns(tbl,{'дата', each 1})",
						Documentation.Examples 		  = {
							[	
								Description = "добавить один столбец", 
								Code 		= "=fxAddMultiColumns(#table({""a"",""b"",""c""},{}),{1,""первый""})",
								Result		= "#table({""первый"",""b"",""c""},{})"
							], 
							[	
								Description = "добавить два столбца", 
								Code 		= "=fxAddMultiColumns(#table({""a"",""b"",""c""},{}),{-1,""первый с конца""})",
								Result		= "#table({""a"",""b"",""первый с конца""},{})"
							]
						}
					],

				return 	    = type function (table as table, addedColumns as list) as table meta optionsMeta
				]  [return],

			result = Value.ReplaceType(func,typ)
		]  [result],
		
//	SKIP
	Table.SkipUp   	  	= // удаляем строки сверху до строки, в которой находится искомый текст
		/* 
			Описание:
				удаляет строки сверху, до строки, в которой находится искомый текст

			Алгоритм:
				1. Cтроки загоняем в список, отбираем их по Text.Contains и сравниваем с пустым списком
				2. Если список не пустой = False, т.е. нет совпадений, тогда удаляем
			
			Пример:	
				1. = Table.Skip(from, Table.SkipUp("Код")) 
				2. = [ 	
						g  = (txt)=>(row)=> List.Select( Record.ToList(row), (i)=>i is text and Text.Contains(i,txt))={},
						to = Table.PromoteHeaders( Table.Skip(from, g("Код"))) 
					]  [to]
			
			Рекомендуется:
				а) 	Названия колонок после сдвига вверх делить по непечатным символам (25 шт.), 
					т.к. могут быть пробелы везде, пропуски, переносы
						= List.Buffer(
							List.Transform(
								Table.ColumnNames(to), 
								(x)=>Text.Combine(Splitter.SplitTextByWhitespace()(x)," ")
							)
						)
				б) 	Отбираем нужные колонки
					= List.Select(
						Table.ColumnNames(to), 
						(str)=>	List.ContainsAny(
									{str},
									{"АК","Код","На1","На31"}, // списоко названий колонок, полностью или частично
									(txt, word) => 
										Text.Contains( 
											Text.Upper( Text.Remove(txt," ") ),
											Text.Upper( Text.Remove(word," ") )
										)
								)
					)
				в) потом отбираем колонки = Table.SelectColumns(to, nms)
		*/
			(txt)=>
				(row)=> 
					List.Select( 
						Record.ToList(row), 
						(i)=>i is text and Text.Contains(i,txt)
					)={},
	

	Skip.AllMulti 	  	= // отсечение строк сверху и снизу таблицы по ключевым словам - по всей таблице + мульти выбор, //!строка или подстрока?
		/*
		 	Описание 	Возвращает ?
			
			Пример		= 	Table.RemoveLastN(
								Table.RemoveLastN(a, 
									SkipAllMulti({"Начальник учебно-методического отдела","Специалист 1 категории"}) 
								), 
							2)
			skip = [
        		верх
					a = Table.PromoteHeaders(Table.Skip(from, fx[fxSkipAllMulti]({"Дни"}) )),
        		низ
					b = Table.RemoveLastN(Table.RemoveLastN(a, fx[fxSkipAllMulti]({"Специалист","Начальник","ПЕРЕСДАЧА"}) ), 2)
    		][b],

			Особенности
				1 Сравнивать текст без учета пробелов. Убирать двойные. Иногда ставят "Специалист 1 категории" и "Специалист  1 категории"
		*/
		(txt)=>(row)=> 
			not List.ContainsAny(
				{ Text.Combine( List.Select( Record.ToList(row), (i)=>i is text)) },
				txt,
				Text.Contains
			),
		
	Skip.RowsUpDown   	= // по колонке + одно слово
		/*
		
		*/
		(x, txt)=>(y)=>
			not Text.Contains( 
					Text.Combine( List.Select( Record.ToList( Record.SelectFields(y, txt) ), (i)=>i is text) ),
					x
				),


//	NAMES 
	listNames 			= // список уникальных имен столбцов в колонке с подтаблицами (на входе таблица). Используется для разворавичания
		(tbl as table, colName as text)=>
			List.Buffer(List.Distinct(List.Combine(List.Transform(List.RemoveNulls(Table.Column(tbl, colName)), Table.ColumnNames)))),
//	CLEAN TABLE
	// ошибки
	Table.ReplaceErr 	= // # меняем все ошибки во всей таблице на null
        /*
			Описание:
				обработка ошибок errors в таблице

			Алгоритм:
				1 Если аргумент nms не указан (т.е. равен null), то берём все колонки, иначе - по списку
				2 Заменяем ошибки в указанных колонках на null

			Использование:
				Table.ReplaceErrorsNull(myTable)
				Table.ReplaceErrorsNull(myTable, {"Column1", "Column2"})
		*/
		(tbl as table, optional nms as list) => 
			let 
				columnsToReplace = nms ?? Table.ColumnNames(tbl)
			in 	
				Table.ReplaceErrorValues(
					tbl, 
					List.Transform(columnsToReplace, (x) => {x, null})
				),
	// чиста текста
	Table.SuperTrim 	= // удаляет лишние пробелы снаружи и внутри текста
		/* 
			https://t.me/pbi_pq_from_tank/197
			Нужно реализовать функцию СЖПРОБЕЛЫ. Проблема в том, что Text.Trim, Text.TrimStart и Text.TrimEnd не удаляют лишние пробелы в середине текста, а СЖПРОБЕЛЫ – удаляет. Что ж, решим эту проблему

			Использование:
				tbl = #table({"txt"},{{"   мама   мыла     раму"},{"   мама     #(lf)     мыла   #(tab)#(tab)#(lf)  раму"}}),

				to3 = Table.TransformColumns( tbl, {"txt", f} ),
				to4 = Table.TransformColumns( tbl, {"txt", (i)=>f(i," ")} ),
				to5 = Table.TransformColumns( tbl, {"txt", (i)=>f(i,null,"#(lf)")} )
				
			superTrim = 
				let f=(txt, optional splitby,optional combby)=> try Text.Combine(List.Select(Text.SplitAny( txt, "" & (splitby??"")),(x)=> x <> "" ), combby??" ") otherwise null,
				to = Table.TransformColumns(Replace, {}, f)
				in  to
		 			
			По шагам:
			to  – преобразовываем текстовый столбец. Логика простая: 
					- 1  разделяем текст по пробелу (Text.Split), при этом получаем список, два пробела подряд также будут разделены и в список попадёт "" (пустая строка), 
					– 2! снова используем Text.SplitAny, просто в этот раз вторым аргументом передаём пустую строку – и в этой ситуации она сама прекрасно делит текст по пробельным символам и непечатным символам, что на мой вкус удобно
					- убираем пустые строки (List.Select) и 
					- собираем обратно текст через пробел (Text.Combine). 
			
			f   – 	ну и подытожим написанием условно универсальной функции. 
					Обязательный аргумент txt – обрабатываемый текст, необязательные – splitby и combby – разделители по которым
					надо делить текст и разделитель, через который надо обратно собрать текст соответственно. 
			to3 – просто используем функцию
			to4 – делим только по пробелу
			to5 – делим по пробельным и нечитаемым символам, а собираем через разрыв строки (обращаю внимание на синтаксис – второй аргумент передан как null)
		*/
		(txt, optional splitby, optional combby)=>
			Text.Combine(
				List.Select(
					Text.SplitAny(txt,"" & (splitby??"")), 
					(x)=>x<>""), 
				combby??" "
			),

	// чистка таблицы
	Table.ClearX    	= // # очистка текста о символов, пустых столбцов, пустых строк //* по умолчанию сделать, если ничего не введено из опц аргументов
		/*
			Описание:
				1 	очистка текста о символов + пустых (= null) столбцов и строк
				2	колонки: удаляются если = null. Колонки с "" не удаляются 
				3	строки:  удаляются если = или "" или null или и то и другое
				4	не удаляются двойные пробелы и символы " " в начале и конце строки

			Примеры:
				= F[Table.ClearX] (from)	
					все значения по умолчанию: 	ClearChars 	= " #(lf)#(00A0)#(tab)#(cr)", 
												ClearColumn = true, 
												ClearRows 	= true.
				
				= F[Table.ClearX] (from, [ClearChars = " #(lf)#(00A0)", ClearColumn = false, ClearRows = false]) 
					удаляем: символы, пустые колонки, пустые строки 

				= F[Table.ClearX] (from, [ClearChars = " #(lf)#(00A0)", ClearColumn = false])
					параметры ClearChars и ClearColumn будут обновлены, а 
					ClearRows останется со значением по умолчанию (true).

			Справка:
					#(lf) 	перенос строки		-	Код 10 (десятичный) или 0A (шестнадцатеричный)
					#(00A0) неразрывный пробел	-	Код U+00A0 (Unicode) или 160 (десятичный) или 00A0 (шестнадцатеричный)
					#(tab)	табуляция
					#(cr)	возврат каретки
				1	для удаления символов есть функция F[Text.RemoveSymbols]("a,b,c")
				2	непечатные символы можно делать последовательностью
				3	CharsToRemove = List.Transform({33..45,47,58..126}, each Character.FromNumber(_)) // кроме чисел
					Вместо  " #(lf)#(00A0)" сделать
							=> Text.Combine(List.Transform({33..45,47,58..126}, each Character.FromNumber(_)))
							=> !"#$%&'()*+,-/:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~
					
					замена неразрывного пробела, например имз PDF файлов
					Text.Replace(_, Character.FromNumber(10), " ")})

					См номера в колонке dex по https://autoit-script.ru/docs/appendix/ascii.htm
				4 	Таблица символов ASCII + Windows 1251 
					https://snipp.ru/handbk/table-ascii - колонка Символ, но добавить #()


			Особенности:
				1 если опциональные clearColumn и clearRows не указаны, то НЕ удаляем пустые строки и столбцы
				2 если стоит ЛЮБОЕ значение, значение <> null, то удаляем пустые строки и столбцы
			
			Улучшение:
				! 1 заменить условие наоборот, если ничего не указано, но удаляем, если указано, но не удаляем
				! 2 убрать первые и последние пробелы
			Проверка:
				let
					SourceTable = Table.FromRows({
							{"A", "B", "C", null},				// колонка 4 пустая
							{"Hello", " ", "World", null},   	// Вторая колонка пустая (с пробелом)
							{"Power", null, "Query", null}, 	// Вторая колонка содержит null
							{"", "", "", ""},             		// Полностью пустая строка
							{"", "", null, null},             	// Полностью пустая строка
							{null, null, null, null},          	// Полностью пустая строка
							{"Test", "1#(lf)а", "Data", null}, 	// Третья строка с непечатным символом #(lf)
							{null, "Value", "", null}       	// Пустые значения и null
						}, 
						{"Col1", "Col2", "Col3", "Col4"}
					),

					CleanedTable = F[Table.ClearX](SourceTable, [ClearChars = "#(lf)", ClearColumn = true, ClearRows = true])
				in
					CleanedTable

		*/
		[ 
	        func   = (tbl as table, optional options as record) => [
                // 	АРГУМЕНТЫ Шаг 0. Значения по умолчанию для options //! по умолчанию False или True ??? смотри примеры
					defaultOptions	= [ClearChars = " #(lf)#(00A0)#(tab)#(cr)", ClearColumn = true, ClearRows = true],
					finalOptions    = if options = null then defaultOptions else Record.Combine({defaultOptions, options}),

				//	АРГУМЕНТЫ Шаг 0. Список аргументов
				    GetValue  	= // функция определения типа опциональных параметров
                        (options as record, fieldName as text, typeConverter as function) =>
                            let value  = Record.FieldOrDefault(options, fieldName, null)
                            in  if List.Contains({null, 0, ""}, value) then null else typeConverter(value),

                    clearChars 	= GetValue(finalOptions, "ClearChars", 	Text.From),		// список удаляемых непечатных символов
                    clearColumn = GetValue(finalOptions, "ClearColumn",	Logical.From),	// true/false - удалить пустые столбцы //* можно убрать, тогда любой символ не null сработает
					clearRows 	= GetValue(finalOptions, "ClearRows", 	Logical.From),  // true/false - удалить пустые строки
        
				// 	0 tr	делаем все колонки текстовыми	//* 
					// если ошибки формул когда с листа Excel, тогда  tr = Table.ReplaceErrorValues(tr1, List.Transform(Table.ColumnNames(tr1),(x)=>{x,null})),
					tr = Table.TransformColumns(tbl, {}, Text.From),
							
				// 	1 p		удаляем непечатные символы		//* описать словами условие. Буферизация не нужна тут!
					p =	if clearChars is null then tr else 
						let f = (x) => 
								if x = null then x 
								else Text.Combine(List.RemoveMatchingItems(Text.SplitAny(Text.Clean(x), clearChars), {""}), " ")
						in 	Table.TransformColumns(tr, {}, f),
				
				// 	2 cl	удаляем пустые колонки 			
					// более быстрый вариант, под новые версии Excel
					cl2 = 	if clearColumn = false then p else 
								let a = List.Sort(Table.ColumnNames(p)),
									b = Table.Profile(p, {{"tmp", (x) => true, List.NonNullCount}}) [tmp],
									c = List.PositionOf(b, 0, Occurrence.All),
									d = List.Transform(c, (x) => a{x})
								in  Table.RemoveColumns(p, d),
					
					// более медленный вариант, но подходит под старыx версий Excel
					cl =	if clearColumn = false then p else 
								let tbl =	p,
									nms = 	Table.ColumnNames(tbl),
									lst = 	List.Select(nms, (colName) =>
												let	values = List.ReplaceValue(Table.Column(tbl, colName), "", null, Replacer.ReplaceValue)
												in	List.NonNullCount(values) > 0
											)
								in Table.SelectColumns(tbl, lst),

				// 	3 to	удаляем пустые строки 			//* насколько пустые?
					to = 	if clearRows = false 
							then cl 
							else Table.SelectRows(cl, 
									each not List.IsEmpty(List.RemoveMatchingItems(Record.FieldValues(_), {"", null}))
								),

				// 	4 w		удаляем двойные пробелы 		//* не использую пока, ошибка и долговато. Смотри новую Table.SuperTrim
					w = [	f = (txt) => Text.Combine(List.Select(Text.Split(txt, " "), each _ <> ""), " "),
							m = Table.TransformColumns(to, {}, f)
						]  [m]
				] [to],
			
			typ    = [ 
				optionsType	= type [ 
						// tbl			= (type 		 table   meta [Documentation.FieldCaption = "Table"]),
						ClearChars	= (type nullable text    meta [Documentation.FieldCaption = "ClearChars",	Documentation.SampleValues = {"символы # (...)"}]),
						ClearColumn = (type nullable logical meta [Documentation.FieldCaption = "ClearColumn",	Documentation.SampleValues = {"true"}]),
						ClearRows	= (type nullable logical meta [Documentation.FieldCaption = "ClearRows",	Documentation.SampleValues = {"false"}])
					],

				optionsMeta	= [ 
						Documentation.Name = "Table.ClearX",
						Documentation.LongDescription = "...",
						Documentation.Examples = {
							[Description = "", Code = "=F[Table.ClearX] (from, [ClearChars = "" #(lf)#(00A0)"", ClearColumn = true, ClearRows = true])",		Result="список файлов xls"], 
							[Description = "", Code = "=F[LoadFolder](""Homel"", 3)",	Result="список файлов xls на шаге 3"], 
							[Description = "", Code = "=F_Form[LoadFolder](""Homel"", 123)",Result="сообщение об ошибке"]
						}
					],
				return 	    = type function (tbl as table, optional options as optionsType) as table meta optionsMeta
				][return],
			
			result = Value.ReplaceType(func,typ)
		] [result],

	Table.ClearAll    	= // # очистка текста о символов + пустых столбцов и строк
		/*
			Описание:
				очистка текста о символов + пустых (= null) столбцов и строк

			Пример:
				F[Table.ClearAll](i," #(lf)#(00A0)")		-	удаляем только символы
				F[Table.ClearAll](i," #(lf)#(00A0)", 1)		-	удаляем символы + пустые столбцы
				F[Table.ClearAll](i," #(lf)#(00A0)", 1, 1)	-	удаляем символы + пустые столбцы + пустые строки

			Справка:
					#(lf) 	перенос строки		-	Код 10 (десятичный) или 0A (шестнадцатеричный)
					#(00A0) неразрывный пробел	-	Код U+00A0 (Unicode) или 160 (десятичный) или 00A0 (шестнадцатеричный)
					#(tab)	табуляция
					#(cr)	возврат каретки
				1	для удаления символов есть функция F[Text.RemoveSymbols]("a,b,c")
				2	непечатные символы можно делать последовательностью
				3	CharsToRemove = List.Transform({33..45,47,58..126}, each Character.FromNumber(_)) // кроме чисел
					См номера в колонке dex по https://autoit-script.ru/docs/appendix/ascii.htm
				4 	Таблица символов ASCII + Windows 1251 
					https://snipp.ru/handbk/table-ascii - колонка Символ, но добавить #()

			Особенности:
				1 если опциональные clearColumn и clearRows не указаны, то НЕ удаляем пустые строки и столбцы
				2 если стоит ЛЮБОЕ значение, значение <> null, то удаляем пустые строки и столбцы
			
			Улучшение:
				1 заменить условие наоборот, если ничего не указано, но удаляем, если указано, но не удаляем
		*/
		
		[func = (
			tbl, 						// таблица
			optional clearData, 		// список удаляемых непечатных символов
			optional clearColumn, 		// true/false - удалить пустые столбцы
			optional clearRows			// true/false - удалить пустые строки
		) =>

		[ 	// 	делаем все колонки текстовыми
				tr = Table.TransformColumns(tbl, {}, Text.From),
				// если олшибки формул когда с листа Excel
				// tr = Table.ReplaceErrorValues(tr1, List.Transform(Table.ColumnNames(tr1),(x)=>{x,null})),
		
			// 	удаляем непечатные символы
				p = 	if clearData is null 
						then tr 
						else [ 	k = (x) => 
									if x = null 
									then x 
									else Text.Combine( List.RemoveMatchingItems(Text.SplitAny(Text.Clean(x), clearData), {""}), " "),
								to = Table.TransformColumns(tr, {}, k)
							][to],

			// 	удаляем пустые колонки
				cl = 	if clearColumn is null 
						then p 
						else [ 	a = List.Sort(Table.ColumnNames(p)),
								b = Table.Profile(p, {{"tmp", (x) => true, List.NonNullCount}})[tmp],
								c = List.PositionOf(b, 0, Occurrence.All),
								d = List.Transform(c, (x) => a{x}),
								e = Table.RemoveColumns(p, d)
							][e],

			// 	удаляем пустые строки
				to = 	if clearRows is null 
						then cl 
						else Table.SelectRows(cl, each not List.IsEmpty(List.RemoveMatchingItems(Record.FieldValues(_), {"", null})))
		] [to],
			
		typ = type function (tbl as table, optional clearData as text, optional clearColumn as text, optional clearRows as text) as table 
				meta [  Documentation.Name              = "Table.ClearAll",
						Documentation.LongDescription   = " "],

		result = Value.ReplaceType(func,typ)
		] [result],
		
	Table.ClearAll2   	= // очистка текста от символов + пустых столбцов и строк + без аргументов!
		  	(tbl) =>
			[ 	tr = Table.TransformColumns(tbl, {}, Text.From),
				
				// удаляем символы
				ch = 
					let clearData = " #(lf)#(00A0)",
						f=(x)=>Text.Combine(List.RemoveMatchingItems(Text.SplitAny(Text.Clean(x), clearData), {""}), " ")
					in Table.TransformColumns(tr, {}, f),

				// удаляем пустые колонки
				cc = 	Table.SelectColumns(ch, 
							List.Select(
								Table.ColumnNames(ch),
								(colName) =>
									let	columnValues = List.ReplaceValue(Table.Column(ch, colName), "", null, Replacer.ReplaceValue)
									in	List.NonNullCount(columnValues) > 0
							)
						),

				// удаляем пустые строки
				rw = Table.SelectRows(ch, each not List.IsEmpty(List.RemoveMatchingItems(Record.FieldValues(_), {"", null})))
			] [ch],

	fxCleanColumnNames  = // чистка названий колонок через Text.Clean и Text.Trim
		(Source as table) as table =>
			Table.RenameColumns(Source,
				List.Zip({
					Table.ColumnNames(Source),
					List.Transform(
						Table.ColumnNames(Source), 
						each Text.Clean(Text.Trim(_)) 
					)
				})
			),
	// удаление колонок
	Table.RemoveEmptyColumns   = // удаление пустых столбцов 
			[ func = (table, optional options) =>
				let	tbl = Table.Buffer(Table.Profile(table)),
					lst = Table.SelectRows(tbl,(x)=>x[Count]=x[NullCount])[Column],
					to  = Table.RemoveColumns(table,lst)
				in  to,
			
				typ = type function (table as table, optional options as record) as table 
						meta [  Documentation.Name            = "fxTableRemoveEmptyColumns (@buchlotnik)",
								Documentation.LongDescription = "функция, удаляющая пустые столбцы из таблицы"],
				
				result = Value.ReplaceType(func,typ)
			][result],
				
	Column.RemoveToName 	   = // 1. Удаляем колонки по маске имени (начинается с ...) 
		[ 	func = 
			(
				tbl as table, 
				optional txt as text	// начальные символы имени колонки
			)=> 
			let 
				from = 	if txt = null 
						then "Column" 
						else txt,
				
				to = Table.RemoveColumns(
						tbl, 
						List.Select(
							Table.ColumnNames(tbl), 
							(x)=>Text.StartsWith(x,from)
						) 
					)
			in to,
				
			fnType = type function (tbl as table, optional txt as text) as table
				meta [ 	Documentation.Name            = "Column.RemoveNameWithColumn - fxRemoveColumnsNameColumn",
						Documentation.LongDescription = " "
				],
	
		result = Value.ReplaceType(func, fnType)
		] [result],

	Column.RemoveNull   	   = // 2. Удаляем пустые колонки (везде null) 
		(table as table, optional options) => [
			tbl = Table.Buffer(Table.Profile(table)), 
			lst = Table.SelectRows(tbl,(x)=>x[Count]=x[NullCount])[Column], 
			to  = Table.RemoveColumns(table,lst) 
		] [to],
   
	Column.RemoveEmptyColumns  = // 2. Удаляем пустые колонки (null + "") без profile
		(tbl as table) =>
		let
			// Заменяем пустые строки на null и фильтруем столбцы за один проход
			lstNonEmptyColumns = 
				List.Select(
					Table.ColumnNames(tbl),
						(colName) =>
							let	columnValues = List.ReplaceValue(Table.Column(tbl, colName), "", null, Replacer.ReplaceValue)
							in	List.NonNullCount(columnValues) > 0
				)
			// Оставляем только непустые колонки
		in  Table.SelectColumns(tbl, lstNonEmptyColumns),

	// удаление строк	
	Table.RemoveEmptyRows      = 1, // Удаление пустых строк 
	Table.EmptyRow 			   = // удаление полностью пустой строки (везде null)
		(tbl)=>
			Table.SelectRows(tbl, 
				each not List.IsEmpty(List.RemoveMatchingItems(Record.FieldValues(_), {"", null}))
			),

	Row.RemoveNull  		   = // удаление полностью пустых строк
		(tbl as table)=> 
			Table.SelectRows(tbl, each not 
				List.IsEmpty(
					List.RemoveMatchingItems(
						List.Transform(
							List.RemoveMatchingItems( Record.FieldValues(_), {"", null} ),
							each try Text.Clean( Text.Trim(_) ) otherwise _ ), {""}
					)
				)
			),

	Row.RemoveNullColumns  	   = // удаление строк, если в заданных колонках пусто или null //! одновременно?
		/* 
			= Row.RemoveNullColumns (from, {"На начало","На конец"})
		*/
		(tbl as table, lst as list)=> 
			Table.SelectRows(tbl, each not 
				List.IsEmpty(
					List.RemoveMatchingItems(
						Record.ToList(	Record.SelectFields(_, lst)	),
						{null, ""}
					)
				)
			),
					
//	ЗАМЕНА
	NumOrZero 			   = // # функция заменяет значение null нулём и приводит значение к числовому типу  
		/* 
			Описание:
				числа остаются числами, число как текст становится числом, а null превращается в ноль
			
			Пример 1:
				"числа остаются числами"           	= NumOrZero(5) 		Result = "5" 
				"число как текст становится числом" = NumOrZero("5")	Result = "5" 
				"null превращается в ноль"          = NumOrZero(null)	Result = "0"

			Пример 2:
				let
					from = Table.FromRecords({
						[A = null, B = 2,    C = 3,    D = "4"],
						[A = "5",  B = 6,    C = null, D = 8  ],
						[A = 9,    B = null, C = "10", D = 11 ]
					}),
				
					to1 = Table.TransformColumns(from, {}, NumOrZero) 			// во всех колонках
					to2 = Table.TransformColumns(from, {"A", (x)=>x}, NumOrZero) // во всех колонках кроме "А"
				in  
					to2
			Ссылка:
				В танке / Сложно о функциях 1 - Типизация 	  / #АнатомияФункций - Type.ForFunction
				В танке / Сложно о функциях 2 - Документация  / #АнатомияФункций - Type.ForFunction
		*/
		[ 	func   = (x as any)=> if x=null then 0 else Number.From(x),
			typ    = Value.Type(func),
			params = Type.FunctionParameters(typ),
			min    = Type.FunctionRequiredParameters(typ),
			ftyp   = Type.ForFunction([ReturnType = Int64.Type, Parameters = params], min),
			doc    = 
				[
					Documentation.Name            = "NumOrZero", 
					Documentation.Description     = "функция заменяет значение <i><b>null</b></i> нулём и приводит значение к числовому типу", 
					Documentation.LongDescription = "функция заменяет значение <i><b>null</b></i> нулём и приводит значение к числовому типу", 
					Documentation.Examples        = 
						{
							[Description = "числа остаются числами",            Code = "=NumOrZero(5)", 	Result = "5"], 
							[Description = "число как текст становится числом", Code = "=NumOrZero(""5"")",	Result = "5"], 
							[Description = "null превращается в ноль",          Code = "=NumOrZero(null)",	Result = "0"]
						}
				],
			ftypwithmeta = Value.ReplaceMetadata(ftyp, doc), 
			fres         = Value.ReplaceType(func, ftypwithmeta)
		]  [fres],

	Text.DeletBracket      = // удаление текста в столбце таблице внутри скобок + сами скобки (быстрее)
		/*
			Описание:	
			Пример:		= F[Text.DeletBracket](tbl,"Column1")
			Результат:	
		*/
		(tbl as table, columnName as text) =>
			let
				f=(x)=>
					let a = Text.PositionOf(x,"("),
						b = if a = -1 
							then x 
							else @f(Text.RemoveRange(x,a,Text.PositionOf(x,")")-a+1))
					in  b,
				to   = Table.TransformColumns(tbl, {columnName,f})
			in
				to,

	Text.RemoveIntoBracket = // удаление текста внутри скобок + сами скобки кроме списка слов исключений (медленнее)
		/*
			Пример:		= F[Text.RemoveIntoBracket](tbl,"Column1", {"УБ","счет","покуп"})
			Результат:	
		*/
		(tbl as table, columnName as text, optional masks as list) =>
		let
			// 	Преобразование масок в нижний регистр
				masksLower = List.Transform(masks ?? {}, Text.Lower),

			// 	Функция возвращяет список содержимого 3-х скобок. Например: (x)=>fBrackets(x[Column1])
				fBrackets = (txt as text) as list =>
					let fBetween = (x as number) as list =>
							{"(" & Text.BetweenDelimiters(txt, "(", ")", x, {0, RelativePosition.FromStart}) & ")"},
						combine = List.Combine({fBetween(0),fBetween(1),fBetween(2)}),
						remove  = List.RemoveItems(combine, {"()"})
					in  remove,

			//  Список содержимого скобок в колонке + скобки
				GetID = (x) as list => fBrackets(Record.Field(x, columnName)),
				
			//  Функция возвращяет список удаляемых или оставляемых скобок. На входе список?!
				fRemove = (x, useNot as logical) as list =>
					let	filterFunction = 
							if 	 useNot 
							then each     List.AnyTrue(List.Transform(masksLower, (y) => Text.Contains(Text.Lower(_), y)))
							else each not List.AnyTrue(List.Transform(masksLower, (y) => Text.Contains(Text.Lower(_), y))),
						resultList = List.Select(GetID(x), filterFunction)
					in 	resultList,

			// 	Функция добавляет колонку с очищенным текстом
				fAddColumns=(x)=>
					try List.Accumulate(
							fRemove(x, false),
							Record.Field(x, columnName), 
							(s,c)=>Text.Replace(s,c,"")
					) otherwise GetID,

			//  Добавляем проверочные колонки	
				AddColumn = fxAddMultiColumns(tbl, {
					{"Все скобки", GetID},
					{"Оставляем",  each fRemove(_, true )},
					{"Удаляем",    each fRemove(_, false)}
					//{"Результат1",  fAddColumns}
				}),

			// 	Функция возвращает очищенный по словарю исключений текст
				fUpdate =
					let	listAll =
							let allRows  = Table.ToRecords(Table.SelectColumns(tbl, columnName)), // колонка как запись
								extrList = List.Transform(allRows, each fRemove(_, false)), // преобразуем в список
								combine  = List.Combine(extrList) // объединяем списки
							in  combine,
						dict = List.Buffer(List.Zip({listAll, List.Repeat({""}, List.Count(listAll)) }) ),
						func = (txt)=>List.Accumulate(dict, txt, (s,c)=>Text.Replace(s, c{0}, c{1}))
					in  func,
				
			// 	Обновляем колонку с текстом, удаляя текст в скобках	
				// UpdateText2 = Table.TransformColumns(
				// 		Table.DuplicateColumn(AddColumn, columnName, "Результат2"), 
				// 		{"Результат2", fUpdate}), 
				UpdateText = Table.TransformColumns(tbl, {columnName, fUpdate} ),

			// 	Удаляем лишние колонки если они есть
				Result = try Table.RemoveColumns(UpdateText, {"Все скобки","Оставляем","Удаляем"}) 
							otherwise UpdateText
		in
			Result,
	
//	ПРОВЕРКА содержимого
	fxContainsKeyWord 	= // содержит ли таблица ключевое слово во всех столбцах в любом месте
		/*
			Описание:

			Пример:

			Датасет:


			*/
		(table as table, keyword as text) as logical =>
			let f = (x) => List.RemoveNulls(List.RemoveItems(x,{""})),
				g = (row as list) => List.ContainsAny(row, {keyword}, Text.Contains),
				b = List.Transform(Table.ToColumns(table), f),
				h = List.AnyTrue(List.Transform(b, (x)=> g(x) )) 
			in  h,
	
	Text.CompareText 	= // # возвращает true, если ли в подстроке есть символы из списка 
		/* 
			Пример: 
				1. 	Создаем нужный список (группа) ключей и проверяем таким образом и отбираем строки:
					to = Table.SelectRows(from, (x)=>Text.CompareText(Ключи1, x[Текст]) 
					to = if Text.CompareText(lst, x) = true then 
				2.  
			*/
		(keys as list, text as text) as logical =>
			List.AnyTrue( 
				List.Transform( 
					keys, 
					(key)=> Text.Contains(text, key, Comparer.OrdinalIgnoreCase)
				)
			),
		
	
	fxIsNumber 			= // является ли первый символ числом as //todo logical?
		(txt)=>List.ContainsAny ({ Text.Start(txt,1) }, {"0".."9"}, Text.Contains),
	
//	HEADERS
//	RENAME COLUMNS
	TableRenameColumnsByPositions = // переименование столбца по номеру позиции
			(table,list) =>
				[   a = List.Buffer(Table.ColumnNames(table)),
					b = List.Count(a),
					c = (x) =>{a{if x{0}>0 then x{0}-1 else b+x{0}},x{1}},
					d = if list{0} is list then List.Transform(list,c) else c(list),
					e = Table.RenameColumns(table,d)
				]  [e],
		
	fxRenameColumns 	= // переименовать все столбцы, старый список -> новый список
		(table,listOld,listNew) => 
			Table.RenameColumns(
				table, 
				List.Zip({ List.Buffer( listOld ), listNew })
			),
		
// 	REORDER COLUMNS
	Reorder.AllColumns  =  	// # перегруппировка столбцов таблицы согласно нового списка lst
		/*  
			Аргументы: 
				tbl		- 	исходная таблица 
				lst 	- 	Новый список расположения всех столбцов или отдельный столбец/столбцы
							Имена столбцов должны совпадать с исходными, меняется только последовательность.
							Если имен каких-то столбцов в новом списке не будет или ошибка в названии, 
							то Expression.Error: Столбец "..." таблицы не найден.
				offset 	- 	сдвиг относительно начала: 
							0 - без сдвига (становится столбцом 1), 
							1 - первый столбец без изменений, второй перемещаемый
			Пример: 
				1	= F[Table.ReorderSubsetOfColumns](from, {"Строка", "Код"}, 0)	// 	колонки {"Строка", "Код"}   перемещаются на позиции 0 и 1 
				2 	= F[Reorder.AllColumns](from, {"Начало", "Конец"}, 1)			// 	колонки {"Начало", "Конец"} перемещаются на позиции 2 и 3
				3 	= F[Reorder.AllColumns](from,{"a","b"}, 2)						// 	на входе 4 колонки abcd. На выходе колонки a и b поставит в конец
																						Result: {"c", "d", "a", "b"}
		*/
		[	
			func1  = // Вариант 1. Если имена столбцов tbl и lst совпадают!
				(	tbl as table, 				// таблица 
					lst as list,				// список столбцов из одного или нескольких
					optional offset as number	// сдвиг относительно первого столбца
				) => 
					let offset = if offset <> null then offset else 0
					in	Table.ReorderColumns(tbl,
							List.InsertRange(
								List.Difference(
									Table.ColumnNames(tbl),
									lst
								),
							offset, lst)
					),
			
			func2  = // Вариант 2. Если имена столбцов tbl и lst НЕ совпадают! Наверное заменяет первый!!!
				(tbl as table, lst as list, optional offset as number) =>
				let
					// 	Получение имен столбцов из таблицы
						columnNames = Table.ColumnNames(tbl),
					
					// 	Фильтрация списка lst, чтобы включить только те столбцы, которые существуют в таблице
						validColumns = List.Intersect({lst, columnNames}),
					
					// 	Установка значения offset по умолчанию, если он не задан
						offsetValue = if offset <> null then offset else 0,
					
					// 	Создание нового порядка столбцов
						reorderedColumns = 
							List.InsertRange(
								List.Difference(columnNames, validColumns),
								offsetValue, 
								validColumns
							),
					
					// 	Переупорядочивание столбцов в таблице
						result = Table.ReorderColumns(tbl, reorderedColumns)
				in	result,
					// try result otherwise tbl,

			typ    = type function (tbl as table, lst as list, optional offset as number) as table 
					meta [ 	Documentation.Name            = "Reorder.AllColumns (fxReorderAllColumns)",
							Documentation.LongDescription = "Перегруппировка всех столбцов таблицы согласно нового списка lst.
																Список новых заголовков, число и названия колонок должны совпадать. <br>
																Пример: lst = Value.Metadata(СправочникСтолбцов)[balance][Имя] <br>
																		F[Reorder.AllColumns](from,{""a"",""b""},2)"],
			result = Value.ReplaceType(func2,typ) 
		]  [result],
		
	Table.ReorderSubsetOfColumns = // # переупорядочиваение столбцов без привязки к названию других //!  аналог предыдущего AllColumns потом убрать
		/*  
			Описание 
				Переупорядочение столбцов надежным способом, без ссылок на имена других столбцов, по номеру

			Аргументы:
				tbl 			 - таблица 
				reorderedColumns - подмножество переупорядоченных имен столбцов в виде списка и 
				offset 			 - индекс (номер колонки куда вставлять полонки по списку), начинающийся с нуля
			
			Пример: 
				= F[Table.ReorderSubsetOfColumns](from, {"Строка", "Код"}, 0)
			
			Одной строкой:
				func = (tbl, lst, offset) => Table.ReorderColumns(tbl,List.InsertRange(List.Difference(Table.ColumnNames(tbl),lst),offset,lst)),
		*/
		[
			func   = (tbl as table, reorderedColumns as list, offset as number) as table =>
					Table.ReorderColumns(
						tbl,
						List.InsertRange(
							List.Difference(
								Table.ColumnNames(tbl),
								reorderedColumns
							),
							offset,
							reorderedColumns
						)
					),
		
			typ    = type function (tbl as table, reorderedColumns as list, offset as number) as table 
					meta [  Documentation.Name              = "Table.ReorderSubsetOfColumns",
							Documentation.LongDescription   = "Функция получает:
								tbl                 - таблицу, 
								reorderedColumns    - подмножество переупорядоченных имен столбцов в виде списка и 
								offset              - индекс (номер колонки куда вставлять полонки по списку), начинающийся с нуля. 
								Затем выполняется переупорядочение очень надежным способом, без ссылок на имена других столбцов"
				],
			
			result = Value.ReplaceType(func,typ)
		][result],
// 	FAQ
	Document 	= // функция документирования других функций
		/*
			Описание
				функция используется в других функциях, документируя их

			Аргументы:
				name as text					- "List.Items"
				description as text				- "Возвращает список значений по позиции элементов" 
				valueOrExample as any			- "{[Description = "Описание", Code = "= F[List.Items]({1,2,3},{1,3})", Result= "{2,6}" ]},
				optional valueIfExample as any 	- (x)=> x + 1

			Пример:
				Document(
					"List.ToText",
					"Конвертирует список в текст. Обратная функция List.From",
					{[Description = "Конвертирует текст в список", Code = "List.ToText({1,2,""abc"",1+2})", Result = """{12abc3}"""]},
					(list as list) => List.Accumulate(list, "{", (state, current) => state & Text.From(current)) & "}"
				),

		*/
		( name as text, description as text,  valueOrExample as any, optional valueIfExample as any ) =>
		let 
			value 	 = if valueIfExample is null then valueOrExample else valueIfExample,
			examples = if valueIfExample is null then {} else valueOrExample
		in
			Value.ReplaceType(value, Value.Type(value) 
				meta [	Documentation.Name = name,
						Documentation.Description = description,
						// [Description = "", Code="", Result =""]
						Documentation.Examples = examples
				]
		),
	fxSizeFile  = // возвращает форматированное значение размера файла
		(sizeInBytes as number) as text =>
			let
				// 	Определение единиц измерения и коэффициента преобразования
					SizeUnits = {"Б", "К", "М", "Гб", "Тб"},
					Byte	  = 1024.0,
				
		        //  Определение индекса единицы измерения в зависимости от размера файла (Number.Power - степень)
			        /*  аналог если
						Index1 = List.NonNullCount(
								List.Transform(
									{0..4}, 
									(i) => if sizeInBytes >= Number.Power(Byte, i) then i else null)
								) - 1,
					*/
					Index = 
						if      sizeInBytes < Byte   				then 0 
						else if sizeInBytes < Number.Power(Byte, 2) then 1	//! 1 если Кб чтобы были 
						else if sizeInBytes < Number.Power(Byte, 3) then 2 
						else if sizeInBytes < Number.Power(Byte, 4) then 3 
						else 4,
				
        		// 	Вычисление значения размера в выбранной единице измерения
					SizeValue = sizeInBytes / Number.Power(Byte, Index),
				
        		// 	Форматирование значения размера с одной десятичной цифрой
					FormattedSize = 
						Text.From(
							if   Index = 1 
								then Number.RoundDown(SizeValue, 0) // для Кб используем целое число
								else Number.Round(SizeValue, 1)		// для остального округляем до одной десятичной цифры
							// ,"en-EN"								// если вместо запятой точку надо как разделитель
							) 
							& " " 
							& SizeUnits{Index}
							// & " / " & Text.From(sizeInBytes) & " / " & Text.From(Index)
			in
				FormattedSize,

	fxFAQ 		= // справка по функциям. Например to = fxFAQ("list") 

		/*
			Описание	справка по функциям языка M
			Примеры 	= F[fxFAQ]("list") 
						= [ text   = F[fxFAQ]("text"), 
							list   = F[fxFAQ]("list"), 
							table  = F[fxFAQ]("table"), 
							record = F[fxFAQ]("record")]
			Link		по основам PQ Назаров - https://www.youtube.com/watch?v=cPT2jLrGOXE
		*/
			[func = (txt as text) =>
                let	list_1      = Record.ToTable(#shared), 
                    rows_select = Table.SelectRows( list_1, each Text.Contains(Text.Lower([Name]), txt) and Text.Contains([Name], ".") ), 
                    tab_add_col = Table.AddColumn( rows_select, "Meta", each Value.Metadata(Value.Type([Value])) ), 
                    cols_select = Table.SelectColumns(tab_add_col, {"Meta"}), 
                    col_colu_1 = 
                        Table.ExpandRecordColumn( cols_select, "Meta", 
                            {
                                "Documentation.Name", 
                                "Documentation.Description", 
                                "Documentation.LongDescription", 
                                "Documentation.Examples"
                            }, 
                            {"Name", "Description", "LongDescription", "Examples"}
                        ), 
                    col_expand_2 = 
						Table.ExpandListColumn(
							col_colu_1, 
							"Examples"
						), 
                    
                    col_expand_3 = 
                        Table.ExpandRecordColumn(
                            col_expand_2, 
                            "Examples", 
                            {"Description", "Code", "Result"}, 
                            {"Example Description", "Example Code", " Example Result"}
                        ),
                    Sort    = Table.Sort(col_expand_3,{{"Name", Order.Ascending}}),
                    Filtr   = Table.SelectRows(Sort, each ([Name] <> null))
                in 
					Filtr,
				
			// 	возвращаем запись
				rec = 
					[ 	text 	= func("text"), 
						list 	= func("list"), 
						table 	= func("table"), 
						record 	= func("record"), 
						date 	= func("date"),
						splitter= func("splitter")
					]
		] [rec],
//  ПАРСИНГ HTML
	/*  
	    Пример:
			1. ссылки на файлы xls с подачей документов БТЭУПК  
				Source = Text.FromBinary(Web.Contents("http://abiturient.i-bteu.by/priyomnaya-kampaniya/informatsiya-o-hode-priyoma/")),
				HTML   = Table.Distinct(Html.Table(Source,{ {"Ссылка", "a[href*='download']", each [Attributes][href]?} })),
		
			Встроенная функция Html.Table 
                    function (html as any, columnNameSelectorPairs as list, optional options as nullable record) as table
                    аргументы: {{НазваниеКолонки, CSS-селектор, ФункцияИзвлечения}}
                    
                    Пример: 
                        Source = Text.FromBinary(Web.Contents("http://abiturient.i-bteu.by/priyomnaya-kampaniya/informatsiya-o-hode-priyoma/")),
                        HTML   = Html.Table(              // Парсим HTML в таблицу
                            Source,                       // Исходный HTML-код
                            { {                           // Определение колонок таблицы
                                "Ссылка",                 // имя колонки
                                "a[href*='download']",    // CSS-селектор: ищем все теги <a> содержащие "download" в href [ ]
                                each [Attributes][href]?  // Функция извлечения: извлекаем URL из атрибута href
                            } },
                            [RowSelector = "a"],          // указывает, что строки таблицы должны 
                                                             формироваться на основе каждого найденного элемента <a>. 
                                                             Если опустить, то строк с null не будет!
                        )
                    */
            // 2. Парсинг HTML и извлечение в таблицу уникальных ссылок на скачивание
                // Html.Table()             - парсинг HTML и получение таблицы с ссылками
                // "a[href*='download']"    - находит все ссылки <a>, где атрибут href содержит слово "download"
                // each [Attributes][href]? - извлекает из Record значение атрибута href для каждой найденной ссылки 
                // Table.Distinct()         - удаляет дублирующиеся строки, оставляя только уникальные ссылки (их по три штуки)
	
	
	fxGetAllLinks = // функция извлечения ссылок из двоичного файла HTML страницы. Можно через Html.Table
		// fxGetAllLinks("www.Bteu.by","""")
		(URL as text, Delimiter as text) =>
			let Source  = Text.FromBinary(Web.Contents(URL)),
				GetLink = (i as number) =>
					let Link = Text.BetweenDelimiters(Source, "href=" & Delimiter, Delimiter, i)
					in  if Link = "" then {} else List.Combine({{Link}, @GetLink(i + 1)})
			in  GetLink(0),
// 	TEXT
	Text.Clear 	= // удаляем заданные символы из текстовой строки //!
		/*
			Пример
				= F[Text.Clear](txt)
			Одной строкой
				Text.Combine(List.RemoveMatchingItems(Text.SplitAny(Text.Clean(x)," #(lf)#(00A0)"),{""} )," ")

		*/
		(txt as text)=>
			let char = " #(lf)#(00A0)#(tab)",
				to 	 = 	Text.Combine( List.RemoveMatchingItems( Text.SplitAny( Text.Clean(txt), char), {""} ), " ")
			in  to,
			
	Text.Clear2 = // удаляем определяемые символы из текстовой строки 
		/*
			Пример:	Table.TransformColumns(from, {"tmp", each F[Text.Clear2](_," #(lf)#(00A0)")} )
		*/
		(x, char)=>
			Text.Combine(List.RemoveMatchingItems( Text.SplitAny( Text.Clean(x), char), {""} )," "),

	Text.ReplaceBetweenDelimiters    = // удаляет текст между разделителями + сами разделители + все вхождения
		/* 
			Пример:	
				f=(x)=> F[Text.ReplaceBetweenDelimiters](x,"()",")")
			
			Результат:
		*/
		[func = 
			(txt as text, StartDelimiter as text, EndDelimiter as text) =>
				[fnRemoveFirstTag = 
					(DELIM as text)=>
						let	OpeningTag = Text.PositionOf(DELIM, StartDelimiter),
							ClosingTag = Text.PositionOf(DELIM, EndDelimiter),
							Output 	   = if OpeningTag = -1 
											then DELIM 
											else Text.RemoveRange(DELIM, OpeningTag, ClosingTag - OpeningTag + 1)
						in Output,
								
				fnRemoveDELIM = 
					(y as text)=>
						if fnRemoveFirstTag(y) = y
						then y 
						else @fnRemoveDELIM(fnRemoveFirstTag(y)),
						
				Output = @fnRemoveDELIM(txt)
			][Output],
			
		typ = type function (txt as text, StartDelimiter as text, EndDelimiter as text) as table 
						meta [ 	Documentation.Name            = "Text.ReplaceBetweenDelimiters",
								Documentation.LongDescription = "Удаляет текст между разделителями" ],
					
		res = Value.ReplaceType(func, typ)
		][res],

	Text.ReplaceBetweenDelimitersOne = // удаляет текст между разделителями + 6 параметров + одно вхождение
		/*

		*/
		let
			fun_ReplaceTextBetweenDelimiters = 
				(   Text as text, 
					StartDelimiter as text, 
					EndDelimiter as text, 
					optional ReplaceDelimiters as nullable logical, 
					optional NewText as nullable text, 
					optional TrimResult as nullable logical, 
					optional FixDoubleSpaces as nullable logical
				) as text => 
				
			let
				// добавляем параметры по умолчанию
				Default_ReplaceDelimiters   = if ReplaceDelimiters is null then true else ReplaceDelimiters,
				Default_NewText             = if NewText is null then "" else NewText,
				Default_TrimResult          = if TrimResult is null then true else TrimResult,
				Default_FixDoubleSpaces     = if FixDoubleSpaces is null then true else FixDoubleSpaces,
				
				// работаем
				TextBetweenDelimiters       = Text.BetweenDelimiters(Text, StartDelimiter, EndDelimiter),
				TextToReplace               = if Default_ReplaceDelimiters then Text.Combine({StartDelimiter,TextBetweenDelimiters,EndDelimiter}) else TextBetweenDelimiters,
				ReplacedText                = Text.Replace(Text, TextToReplace, Default_NewText),
				
				// очищаем
				TrimmedText                 = if Default_TrimResult then Text.Trim(ReplacedText) else ReplacedText,
				FixedSpaces                 = if Default_FixDoubleSpaces then Text.Replace(TrimmedText, "  ", " ") else TrimmedText
			in
				FixedSpaces
		in
			fun_ReplaceTextBetweenDelimiters,

	Text.BetweenDelimitersOccAll     = // возвращает текст между разделителями
			/* 	Returns  all occurrances of text strings between a delimiter pair. Optional
				parameter Alternative_Dummy can be used if Dummy shall not be *+*.
			*/
			let
				func = (
					InputText as text,
					StartDelimiter as text,
					EndDelimiter as text,
					optional Alternative_Dummy as text
				) =>
				let
				// If the end delimiter contains the same characters than the start delimiter then that portion has to be replaced in the end parameter by a dummy. Otherwise the query fails.
					AlternativeDummy = Alternative_Dummy,
					Dummy            = if AlternativeDummy is null then "*+*" else AlternativeDummy,
					String           = InputText,
					ParaStart        = StartDelimiter,
					ParaEnd          = EndDelimiter,
				
				// 	If the delimiters are identical, a different logic has to be applied.
					IdenticalDelimiters = ParaEnd = ParaStart,
				
				// Start of logic for identical delimiters
					SplitText = Text.Split(String, ParaStart),
					ResultIdenticalDelimiters = List.Alternate(SplitText, 1, 1),
				
				// Start of logic for different start- and end-delimiters: Create dummy end-delimiter.
					DummyParaEnd     = Text.Replace(ParaEnd, ParaStart, Dummy),
					DummyString      = Text.Replace(String, ParaEnd, DummyParaEnd),
					SplitByParaStart = List.Skip(Text.Split(DummyString, ParaStart), 1),
					ConvertToTable   = Table.FromList(
						SplitByParaStart,
						Splitter.SplitByNothing(),
						null,
						null,
						ExtraValues.Error
					),
					ExtractBeforeParaEnd = Table.AddColumn(
						ConvertToTable,
						"Result",
						each Text.BeforeDelimiter([Column1], DummyParaEnd)
					),
					Cleanup = Table.RemoveColumns(ExtractBeforeParaEnd, {"Column1"})[Result],
					Result = 
						if Text.Contains(String, ParaStart) and Text.Contains(String, ParaEnd) 
						then (if IdenticalDelimiters then ResultIdenticalDelimiters else Cleanup)
						else error Error.Record("At least one of the delimiters is not found in the string")
				in
					Result,
				
				documentation = [
					Documentation.Name = " Text.BetweenDelimitersOccAll ",
					Documentation.Description = " Returns  all occurrances of text strings between a delimiter pair.  ",
					Documentation.LongDescription = " Returns  all occurrances of text strings between a delimiter pair. Optional parameter Alternative_Dummy can be used if Dummy shall not be *+*. ",
					Documentation.Category = " Text ",
					Documentation.Source   = " https://wp.me/p6lgsG-Y5 ",
					Documentation.Version  = " 1.0 ",
					Documentation.Author   = " Imke Feldmann: www.TheBIccountant.com: https://wp.me/p6lgsG-Y5  . ",
					Documentation.Examples = {
						[	Description = " See this blogpost: https://wp.me/p6lgsG-Y5 ",
							Code 		= " TextBetweenDelimitersOccAll(""Meanwhile I prefer *Python!* to *R!*"", ""*"", ""!*"") ",
							Result 		= " {""Python"", ""R""} " ]
					}
				]
			in
				Value.ReplaceType(func, Value.ReplaceMetadata(Value.Type(func), documentation)),

// 	TYPE 📌 
	Type.AllColumnText = // делаем все столбцы текстовыми
		/*
		 	Пример:	
				F[Type.AllColumnText](Source)
			Одной строкой:
				(tbl as table) => Table.TransformColumnTypes(tbl, List.Transform(Table.ColumnNames(tbl), (x)=>{x, type text}))
		*/
		(tbl as table) => 
			Table.TransformColumnTypes(
				tbl, 
				List.Transform(
					Table.ColumnNames(tbl), 
					(x)=>{x, type text}
				) 
			),
	Table.TypedField   = // #! типизирует столбцы по имени колонки. Хорошая функция !
		/*
			= сделать аргументы и список по типам параметром передавать
			= F[Table.TypedField](from)
		*/
		(tbl as table)=>
		let
			nms = Table.ColumnNames(tbl),
			lstDate   = {"Date"},
			lstNumber = {"Строка_ID", "Значение","Сумма","Value", "DataSet",
						 "Index",
						 "На начало","На конец",
						 "Текущий период","Прошлый период"},

			dlst = List.Select(nms,(i)=>List.Contains(lstDate,   i, (x,y)=>Text.Contains(y,x))),
			nlst = List.Select(nms,(i)=>List.Contains(lstNumber, i, (x,y)=>Text.Contains(y,x))),
			tlst = List.Difference(nms, dlst & nlst),

			f=(x,y)=>List.Transform(x,(i)=>{i,y}),

			transflst = f(dlst, DateTime.Type) & // было Date.Type, но пока не обработал ситуацию, когда data формата 31.12.2017 0:00:00
						f(nlst, Number.Type) & 
						f(tlst, Text.Type),
			
			to = Table.TransformColumnTypes(tbl, transflst)	
		in  
			to,
	
	Type.FromText2 	   = // возвращает тип данных по текстовому описанию (сокращенный вариант)
			(TypeAsText as text) =>
					 if TypeAsText = "Text.Type" 	then type text
				else if TypeAsText = "Int64.Type" 	then type number
				else if TypeAsText = "Number.Type" 	then type number
				else if TypeAsText = "Date.Type" 	then type datetime
				else if TypeAsText = "Logical.Type" then type logical
				else type any,

	Type.FromText  	   = // возвращает тип данных по текстовому описанию (полный вариант)
		/*
			Code 	= Type.FromText("type number")
			Result 	= number (as type)
		*/
		let func = (TypeAsText as text) =>
			Record.Field(
				[type null 		= Expression.Evaluate( "type null", 	[ type null = type null] ), 
				type logical 	= Expression.Evaluate( "type logical", 	[ type logical = type logical] ), 
				type decimal 	= Expression.Evaluate( "type number", 	[ type number = type number] ), 
				type time 		= Expression.Evaluate( "type time", 	[ type time = type time] ), 
				type date 		= Expression.Evaluate( "type date", 	[ type date = type date] ), 
				type datetime 	= Expression.Evaluate( "type datetime", [ type datetime = type datetime] ), 
				type datetimezone = Expression.Evaluate( "type datetimezone", [ type datetimezone = type datetimezone] ), 
				type duration 	= Expression.Evaluate( "type duration", [ type duration = type duration] ), 
				type text 		= Expression.Evaluate( "type text", 	[ type text = type text] ), 
				type binary 	= Expression.Evaluate( "type binary", 	[ type binary = type binary] ), 
				type type 		= Expression.Evaluate( "type type", 	[ type type = type type] ), 
				type list 		= Expression.Evaluate( "type list", 	[ type list = type list] ), 
				type record 	= Expression.Evaluate( "type record", 	[ type record = type record] ), 
				type table 		= Expression.Evaluate( "type table", 	[ type table = type table] ), 
				type function 	= Expression.Evaluate( "type function", [ type function = type function] ), 
				type anynonnull = Expression.Evaluate( "type anynonnull", [ type anynonnull = type anynonnull] )],
			TypeAsText) ,
				
				documentation = [
					Documentation.Name =  " Type.FromText ",
					Documentation.Description = " Returns a type from its textual representation. ",
					Documentation.LongDescription = " Returns a type from its textual representation. Only primitive types will be returned",
					Documentation.Category = " Type ",
					Documentation.Source = " www.TheBIccountant.com https://wp.me/p6lgsG-2dd .   ",
					Documentation.Version = " 2.1: Added different number types ",
					Documentation.Author = " Imke Feldmann: www.TheBIccountant.com.  ",
					Documentation.Examples = {
						[	Description =  "  ",
							Code = " Type.FromText(""type number"") ",
							Result = " number (as type) "]}
					]
			in  
				Value.ReplaceType(
					func, 
					Value.ReplaceMetadata(
						Value.Type(func),
						documentation)
				),
// 	REMOVE CHAR/TEXT
	Text.RemoveMulti  = // удаление текста из списка в заданной КОЛОНКЕ. Проверить скорость Добавить тип 
			/*  
				Пример:
					to = F[Text.RemoveMulti](RESULT, "Статья", {"всего", "Из стр"} ) 
				Особенность
					Text.Remove не подходит, т.к. работает с одельными символами, а не подстроками			
				Улучшение
					lst = lst1 & lst2 & lst3, // List.Buffer тут не нужен
					f = (x)=> List.Accumulate(lst, x, (state, remove) => Text.Replace(state, remove, "")), //!
					tr = Table.TransformColumns(typed, {"Значение", f})
			*/
			(tbl as table, ColumnName as text, RemoveList as list) as table=> 
				[	lst  = RemoveList,
					dict = List.Buffer(List.Zip({lst, List.Repeat({""}, List.Count(lst)) }) ),
					func = (txt)=>List.Accumulate(dict, txt, (state,remove)=>Text.Replace(state, remove{0}, remove{1})),
					tr   = Table.TransformColumns(tbl, {ColumnName, func})
				]  [tr],
	
// 	REPLACE + доделать для чисел: через акумулятор или словарь
	//? замена в таблице ячейку целиком
	fxRaplaceMulti = 1,// замена списком в нескольких колонках - самый простой вариант в виде обычной функции List.Accumulate
		// List.Accumulate(
		// 	{"-", "0", "Фиона"}, // если несколько списков то   List.Combine({page, {"-", "Фиона"}}), 
		// 	from, 
		// 	(state, currentValue) => Table.ReplaceValue(state, currentValue, null, Replacer.ReplaceValue, Table.ColumnNames(from))
		// ),
		
	fxReplaceValues   = // 📌 множественная замена в нескольких столбцах (Gorilla) через List.Accumulate - медленнее
		/* ----------------------- Пример -----------------------------------
			Source это ваша исходная таблица данных.
			Этот шаг ReplaceValues вызывает fxReplaceValues, передавая:
				1 Исходная таблица (Source).
				2 Список пар замены, например, {" (GDR)", ""} заменить ”(GDR)” пустой строкой.
				3 Список, определяющий столбцы, к которым следует применить эти замены (в данном случае, {"country_txt"}).

				Вариант 1. Самый простой
				to = 
					let dict = #table({"что", "начто"}, {{"а","А"}, {"я","Я"}}),
					in fxReplaceValues(from, List.Transform(Table.ToRows(dict),(x)=>{x{0},x{1}}), Table.ColumnNames(from))
				 
				
				Если на входе словарь замен в виде таблицы, то передать в dict через Table.ToRows()
                    = fxReplaceValues(Select, Table.ToRows(dict), {"Область"})

                Если колонок несколько в словаре, то выбираем номер колонок для работы
					= fxReplaceValues(
						Select, 
						List.Transform(Table.ToRows(dict), (x)=>{x{0},x{2}}), // из колонки 1 меняем на 3
						{"Область"}
					)

			Источник https://gorilla.bi/power-query/replace-multiple-substrings/
			Source = MyData,
			ReplaceValues = 
				fxReplaceValues( 
					Source, 
					{ 
						{" (GDR)",""},
						{ " (FRG)","" }, 
						{ "People's Republic of the Congo","Congo" }, 
						{ "Republic of the Congo","Congo" }, 
						{ "-"," " } 
					}, 
					{"country_txt"}   
				)
		in
			ReplaceValues 
		*/
		// --------------------Function Definition ------------------------------
		( Table as table, listOfReplacements as list, listOfColumns as list ) =>
			let
				myFunction =
					List.Accumulate (
						listOfReplacements, 
						Table, 
						( state, current ) =>
							Table.ReplaceValue ( 
								state, 
								current{0}, 
								current{1}, 
								Replacer.ReplaceText, 
								listOfColumns
							)
					)
			in
				myFunction,
	
  	fxReplaceValues2  = // множественная замена в нескольких столбцах (Gorilla) через List.Generate - быстрее
		/*
			Начинается 		с начального состояния: [ myTable = Table, Index = 0, Replacements = listOfReplacements ].
			Повторяется		до тех пор, пока [Index] число подстрок меньше [Replacements].
			Применяет 		каждую замену с использованием Table.ReplaceValue для текущего значения индекса, затем обновляет состояние путем увеличения Index.
			Возвращает		итоговую таблицу после завершения всех замен, используя List.Last(myFunction).
			
			Эта структура позволяет List.Generate выполнять замены до тех пор, пока все указанные замены не будут применены к нужным столбцам.
		*/
		( Table as table, listOfReplacements as list, listOfColumns as list ) =>
			let
				myFunction =
					List.Generate( 
						() => 
							[ 
								myTable = Table, 
								Index = 0, 
								Replacements = listOfReplacements 
							],
						each [Index] <= List.Count( [Replacements] ), 
						each 
							[ 
								myTable = 
									Table.ReplaceValue( 
									[myTable], 
									Replacements{ [Index] }{0},
									Replacements{ [Index] }{1},
									Replacer.ReplaceText, 
									listOfColumns
									), 
								Index = [Index] + 1,
								Replacements = [Replacements]
							],
						each [myTable]
					),
					Result = List.Last( myFunction )
			in
				Result,
	
	Text.MultiReplace = // меняет по словарю as record значения в одной колонке по значению другой колонки 
		/*
			Пример:
				MultiReplace =
					F[Text.MultiReplace](MultiReplace1, "Строка_ID", "Статья", 
						[	10 = "Остаток на начало",
							40 = "Скорректированный остаток",
							200 = "Остаток на конец"	]
					),

			Было так: рабочий вариант
				MultiReplace3 =
					Table.ReplaceValue(MultiReplace1,
						(x)=>x[Статья], // в каком столбце менять. И в конце. А если несколько тут надо?!
						each Record.Field([
								10 = "Остаток на начало+",
								40 = "Скорректированный остаток",
								200 = "Остаток на конец"
							], Text.From([Строка_ID])),
						Replacer.ReplaceValue,
						{"Статья"}
					)
				1	если в нескольких столбцах - columnToReplace as list и вводить как лист тогда надо будет
		*/ 
		(tbl as table, columnID as text, columnToReplace as text, replacements as record) =>
			Table.ReplaceValue(
				tbl,
				each Record.Field(_, columnToReplace), 
				each Record.Field(replacements, Text.From(Record.Field(_, columnID))),
				Replacer.ReplaceValue,
				{columnToReplace}
			)
		,
	Text.ReplaceFull  = // в таблице таблица ТЕСТ или ЧИСЛА заменяет ячейку целиком на основании словаря замен. Table.ToRows или Table.ToList
		/*
			Пример:	
				transform = let
					f=(txt)=> // значения колонки 1 словаря, заменяю на колонку 0
						let dict = Table.ToRows(F_Form[spr.REPORT][Спр_ФормыОтчетности]), // список списков
							to   = List.First(List.Select(dict, (col)=>col{1}=txt)){0}
						in 	to,
					to = Table.TransformColumns(addColumns, {"form_ID", f, type text})
				in  to,
				1	сделать номера колонок аргументами
		*/
			(tbl as table, input) =>
				List.First(
					List.Select(
						Table.ToRows(tbl), 	// переводим в список списков таблицу, т.е. колонки станут строками с номерами
						each _{0}=input)	// первая строка каждого списка - это колонка 1 таблицы
				){1},						// вторая строка таблицы замен - на что менять. Если из колонки 3 надо взять, то 2 и т.д.
		
	Text.ReplaceMulti = // замена текста В КОЛОНКЕ через словарь. Опционально сдвиг доделать (через List.Accumulate)
			/*
				Описание:
					1	меняем текст в столбце 1 на текст в столбце 2
					2	ищем часть строки, не полностью значение
				
				Пример:
					= F[Text.ReplaceMulti](tbl, "Статья", {{"(","["}, {")","]"}} )
					= F[Text.ReplaceMulti](tbl, "Статья", {{"a","б"}, {"А","Б"}} )
				
				Улучшение:
					1	изменение в нескольких колонках
						to = Table.TransformColumns(from, List.Transform({"Column1","Column2"}, each {_,f}) )
						аргумент надо вводить в {} тогда

			*/
			(tbl as table, ColumnName as text, dictionary as list) as table=> 
				[ 	dict = List.Buffer(dictionary),
					func = (txt)=> List.Accumulate(dict, txt, (s,x)=>Text.Replace(s,x{0},x{1})), // столбец 1 меняем на столбец 2
					to   = Table.TransformColumns(tbl, {ColumnName, func})
				][to],
	//? замена в текстовой подстроке 
	Text.ReplaceAll_  = // через List.Accumulate. Без лишнего, только текст на входе и список списков, что-начто
		/*
			Do multiple text replacements in one function call, passing the replacements as a list of lists
			Usage:
				Text.ReplaceAll = Load("Text.ReplaceAll"),
				Text.ReplaceAll("(test)", {
					{"(", "["},
					{")", "]"}
				})
			Result: "[test]"
			*/
		(str as text, Replacements as list) as text => 
			List.Accumulate(Replacements, str, (s, x) => Text.Replace(s, x{0}, x{1})),
		
	Text.ReplaceList  = // через рекурсию. Заменяет символы по списку. Проверить скорость
			/*  Функция : fxTextReplaceList    Отличная функция!!!
				Описание: Заменяет в любом месте тексте символы по списку, что на что
				Пример:  
					1. 	Если функция объявлена в теле запроса Text.ReplaceList = (InputText as text, ...) =>
						to = Text.ReplaceList("мама мыла раму", {"мама","мыла"}, {"папа","чистил"}), 
					
					2.	Если отдельной функцией (тут источником другой запрос - в виде текста HTML код страницы - не список и не таблица!)
						to = Text.ReplaceList(#"HTML-код_All", {"scripts","<",">"}, {"","(",")"}, null)
						to = Text.ReplaceList("мама мыла раму",{"мама","мыла","раму"},{"папа","чистил","картошку"}, 1)
					
					3. 	Если заменить надо в колонке, то через Table.TransformColumns
						f=(x)=> Text.ReplaceList(x,
								{"А","Б","В"},
								{"1","2","3"}),
						tr = Table.TransformColumns(Transform3,{"ИмяКОлонки", f})
				
				OldList и  NewList лучше сделать таблицей замен или словарем и использовать как Data[Что] и Data[НаЧто] */
			[ func = (
				InputText as text,	// текст, в котором нужно менять
				OldList   as list, 	// список символов что менять    	{...} = > {"кот","+","1"}    / Data[Column1]{1} / {Source} / Data[Column1]
				NewList   as list,	// список символов на что менять	{...} = > {"собака","-","2"}
				optional Index as nullable number	// с какого вхождения начинать
			  ) => 
			
				let	ActualRow = if Index = null then 0 else Index,
					Result    = Text.Replace(InputText, OldList{ActualRow}, NewList{ActualRow}),
					NextRow   = ActualRow + 1,
					Output    = if   NextRow > (List.Count(OldList) - 1) 
								then Result          
								else @Text.ReplaceList(Result, OldList, NewList, NextRow)
				in 	Output,

			typ = type function (InputText as text, OldList as list, NewList as list, optional Index as nullable number) as table 
					meta [ 	Documentation.Name            = "fxTextReplaceList",
							Documentation.LongDescription = "Заменяет в любом месте тексте символы по списку, что на что <br>
									Пример: <br> 
									1. 	Если функция объявлена в теле запроса Text.ReplaceList = (InputText as text, ...) => <br>
										<i> to = Text.ReplaceList(""мама мыла раму"",{""мама"",""мыла""},{""папа"",""чистил""}), </i><br>
									
									2. 	Если отдельной функцией (тут источником другой запрос - в виде текста HTML код страницы - не список и не таблица!) <br>
										to = fxTextReplaceList(#""HTML-код_All"", {""scripts"",""<"","">""}, {"",""("","")""}, null) <br>
										to = fxTextReplaceList(""мама мыла раму"",{""мама"",""мыла"",""раму""},{""папа"",""чистил"",""картошку""}, 1) <br>
									
									3. 	Если заменить надо в колонке, то через Table.TransformColumns <br>
										f=(x)=> fxTextReplaceList(x, <br>
												{""А"",""Б"",""В""}, <br>
												{""1"",""2"",""3""}), <br>
										tr = Table.TransformColumns(Transform3,{""ИмяКОлонки"", f}) <br>
									
									OldList и  NewList лучше сделать таблицей замен или словарем и использовать как Data[Что] и Data[НаЧто]",
									
							Documentation.Examples = {
								[	Description = 	"Если функция объявлена в теле запроса Text.ReplaceList = (InputText as text, ...) =>", 
									Code 		= 	"to = Text.ReplaceList(""мама мыла раму"",{""мама"",""мыла""},{""папа"",""чистил""})",
									Result		=	".."
								], 
								[	Description = "Если отдельной функцией (тут источником другой запрос - в виде текста HTML код страницы - не список и не таблица!)",
									Code 		= "to = fxTextReplaceList(#""HTML-код_All"", {""scripts"",""<"","">""}, {"",""("","")""}, null) <br> 
									               to = fxTextReplaceList(""мама мыла раму"",{""мама"",""мыла"",""раму""},{""папа"",""чистил"",""картошку""}, 1)",
									Result		=".."
								]
							}
						],
			
			res = Value.ReplaceType(func,typ)
			][res],

	Table.MultipleReplacementInMultipleColumns = // множественная замена в разных колонках (через рекурсию) //! проверить
			/*
				Проверить + примеры сделать

				Функция множественной замены в разных колонках
					to = F[fMultipleReplacementInMultipleColumns](СправочникЗамены, Источник)

				Справочник замены (таблица) выгладит так:
					--------------------------------------------
					Search Text 	Replacement Text 	Column
					--------------------------------------------	
					Ivan 			Сергей 				Имя
					Tovar 6			Товар 6 			Товар
					Homel 			Гомель 				Город
					--------------------------------------------
				
				Источник
					Обычная таблица, где есть столбцы Имя, Товар, Город и другие

				*/

			(aRepTable as table, aSource as table)=>
				let
					fRecursion= (i, Table) => 
						if 		i > Table.RowCount(aRepTable)-1 
						then 	Table 
						else	@fRecursion(i + 1,
									Table.ReplaceValue(Table,
											aRepTable{i}[Search Text],
											aRepTable{i}[Replacement Text],
											Replacer.ReplaceText,
											{aRepTable{i}[Column]}
										)
								),

					Result= fRecursion(0, aSource)
				in
					Result
	
	], // конец библиотеки MyPack

extLibrary = [
	readme._extensionLibrary = "// extensionLibrary",
	Document = // функция документирования других функций
		/*
			Пример:
				Document(
					"List.Items", 
					"Возвращает список значений по позиции элементов",
					{ [ Description = "Описание функции", Code = "= F[List.Items]({10,20,30},{1,3})", Result= "{11, 30}" ]},
					(x)=> x + 1
				),
		*/
		(name as text, description as text, valueOrExample as any, optional valueIfExample as any) =>
		let
			value    = if valueIfExample is null then valueOrExample else valueIfExample,
			examples = if valueIfExample is null then {} else valueOrExample
		in
			Value.ReplaceType(
				value, 
				Value.Type(value) meta 
					[	Documentation.Name = name, 
						Documentation.Description = description,  
						// [Description = "", Code="", Result =""]
						Documentation.Examples = examples	]
			),
	
	//======================== 
	// Load (используются часто Load(), надо ли менять?!
	//========================
    // FF = 
    //     /*
    //         F (short for function), like Load(), provides one calling interface to access functions either imported (faster) or loaded (fallback), so code could be left agnostic to whether the queries are available locally, though whether this is really necessary is left up to the user to decide. One reasonable use case would be allowing many workbooks to access a shared library of queries from their files without needing to import them to each workbook after every change.

    //         F (сокращение от function), как и Load(), предоставляет один вызывающий интерфейс для доступа к функциям, импортированным (быстрее) или загруженным (резервный), поэтому код может оставаться независимым от того, доступны ли запросы локально, хотя действительно ли это необходимо. остается на усмотрение пользователя. Одним из разумных вариантов использования было бы предоставление многим книгам доступа к общей библиотеке запросов из своих файлов без необходимости импортировать их в каждую книгу после каждого изменения.

    //         Imported or loadable functions could be referenced as any of the following:
    //             Load("Text.ReplaceAll")
    //             Load("Text_ReplaceAll")
    //             F[Text.ReplaceAll]
    //             F[Text_ReplaceAll]

    //         Intended benefits of F over Load():
    //             - shorter
    //             - may help avoiding duplicate executions of file imports (if applicable) -- needs further testing though.

    //         Record.Rename = Load("Record.Rename"),
    //         Record.Rename = Record_Rename,

    //             Record.Rename = (Rec as record, Lambda as function) as record =>
    //             let
    //                 Keys     = Record.FieldNames(Rec),
    //                 Values   = Record.FieldValues(Rec),
    //                 Renamed  = List.Transform(Keys, each Lambda(_, Record.Field(Rec, _))),
    //                 Recorded = Record.FromList(Values, Renamed)
    //             in
    //                 Recorded,

    //         cyclic reference...?
    //         SharedPeriods = Record.Rename(Shared, (k,v) => Text.Replace(k, "_", ".")),
    //     */

    //     let
    //         Shared = #shared,

    //         SharedPeriods = Record.FromList(Record.FieldValues(Shared), List.Transform(Record.FieldNames(Shared), each Text.Replace(_, "_", "."))),

    //         SharedMerged = Record.Combine({Shared, SharedPeriods}),
    //         //If I can make a wrapper function to enable profiling/persistence, wrap these as well

    //         Files  = Folder.Files(LoadPath),
    //         MFiles = Table.SelectRows(Files, each Text.Lower([Extension]) = ".m"
    //         // and [Folder Path] = LoadPath    // non-recursive
    //         ),
    //         NoExt           = Table.TransformColumns(MFiles, {"Name", each Text.Start(_, Text.Length(_)-2)}),
    //         CustomNames     = Table.Column(NoExt, "Name"),
    //         Underscored     = List.Transform(CustomNames, each Text.Replace(_, ".", "_")),
    //         CustomBoth      = List.Union({CustomNames, Underscored}),
    //         CustomLoaded    = Record.FromList(List.Transform(CustomBoth, Load), CustomBoth),
    //         SharedAndLoaded = Record.Combine({CustomLoaded, SharedMerged}),

    //         Return = SharedAndLoaded
    //     in
    //         Return,

	LoadPath 	= "", // некоторые функции требуют наличия переменной
	Load        = 
        /*
            Usage:
                loads the function Type.ToText from file 'Type.ToText.pq' in the load path
            let
                Type.ToText = Load("Type.ToText")
            in
                Type.ToText(type {number})

            Result: "list"
        */

        (fnName as text, optional BasePath as text) as function =>
        let
            //If you wish to hardcode the path to load the queries from, you can edit the following line:
            DefaultPath = "g:\=EXCEL PQ\PQ-function-load\Все функции\",
            GitHubPath  = "https://raw.githubusercontent.com/hohlick/pquery/master/",
            
            BasePath = if (BasePath <> null) then BasePath else DefaultPath,
            Path = BasePath & (if Text.End(BasePath, 1) <> "\" then "\" else ""),
            File = Path & fnName & ".pq",
            
            Function = try Expression.Evaluate(Text.Replace(fnName, ".", "_"), #shared)  //if already imported into the workbook just use the existing one
            otherwise try Expression.Evaluate(Text.FromBinary(Binary.Buffer(File.Contents(File))), #shared) //if not imported yet try loading it from the text file in the folder
            otherwise Expression.Evaluate( Text.FromBinary(Binary.Buffer(Web.Contents(GitHubPath & fnName & ".pq"))), #shared) // if folder not found - take from GitHubPath
        in
            Function,

    LoadFunctionFromGithub = 
        /*
            Allows dynamically loading an M function from a text file (extension: .pq) for use in Power Query. 
            This allows you to easily reuse a set of functions in multiple workbooks without having to sync each change to
            all files using it.

            The point here is that by separating universally useful functions from an individual workbook, 
            you will feel encouraged to use more modular code, solving each common sub-problem only once, 
            rather than remaining stuck in 'vanilla' M and resolving the same problems repeatedly.

            Moreover, coding this way will also further facilitate sharing code with other Power Query users, 
            allowing for a more collaborative environment, gradually pushing forward the Power Query community as a whole.

            Nevertheless, if the function in question has already been imported into the workbook, 
            the local copy will be used. This would allow you to either call the function locally right away, 
            or Load() the existing function again.

            Using Load() would not only allow you to use functions in their intended naming conventions 
            (i.e. Text.ReplaceAll rather than with the period replaced by an underscore), but would technically 
            also allow you to add additional wrapper functions around your code, which could be used to enable 
            persistent memoization (using say Redis) or code profiling calls... though presumably no-one has done this so far yet.

            Parameters:
                fnName: name of the text file you wish to load without the .pq extension
                optional BasePath: the file path to look in for the text file; default path hardcoded

            Usage:
                loads the function Type.ToText from file 'Type.ToText.pq' in the load path
            let
                Type.ToText = Load("Type.ToText")
            in
                Type.ToText(type {number})

            Result: "list"

            Warning: this function may triggers a Formula.Firewall error for referencing both an external query 
                (LoadPath) as well as external files.

            If you run into this, you can get around this by enabling the FastCombine option, in Power Query Options -> 
            Privacy -> Fast Combine -> 'Ignore the Privacy levels and potentially improve performance'.

            If you'd prefer not to do this however, you could also just replace the LoadPath reference below with a static
            absolute path reference.

        */

        (fnName as text, optional BasePath as text) as function =>
        let
            //If you wish to hardcode the path to load the queries from, you can edit the following line:
            DefaultPath = "C:\PQuery\",
            GitHubPath = "https://raw.githubusercontent.com/IvanBond/pquery/master/",
            
            BasePath = if (BasePath <> null) then BasePath else DefaultPath,
            Path = BasePath & (if Text.End(BasePath, 1) <> "\" then "\" else ""),
            File = Path & fnName & ".pq",
            
            Function = 
				try 	  Expression.Evaluate(Text.FromBinary(Binary.Buffer(File.Contents(File))), #shared)
            	otherwise Expression.Evaluate(Text.FromBinary(Binary.Buffer(Web.Contents(GitHubPath & fnName & ".pq"))), #shared)
        in
            Function,

    LoadPath.example = "", 
    //     // Excel.CurrentWorkbook(){[Name="Table1"]}[Content]{0}[Path]
        
    //     // Copy this file to `LoadPath.pq`, and replace its contents with your query path, like this:
    //     // "D:\pquery\"

    LoadTrace   = 
        /*
            Original made by Chris Webb:
            http://blog.crossjoin.co.uk/2014/12/11/reading-the-power-query-trace-filewith-power-query/
        */
        (Path as text) as table =>
        let
            Source   = Table.FromColumns({Lines.FromBinary(File.Contents(Path))}),
            Json     = Table.TransformColumns(Source, {{"Column1", each Json.Document(Text.Split(_, " : "){1})}}),
            Expanded = Table.ExpandRecordColumn(Json, "Column1", {"Start","Action","Duration","Exception","CommandText","ResponseFieldCount","PackageReference","ProductVersion","ActivityId","Process","Pid","Tid"}),
            Typed    = Table.TransformColumnTypes(Expanded, {{"Start", type datetime}, {"Duration", type duration}})
        in
            Typed,
    //======================== 
	// M
	//========================
	// список функций сайт https://querypower.com/2017/05/01/navigating-600-m-functions/
	Signature = 
		(placeholder as function)=>				
			let
			//Serialize type to text  
			TypeAsText = (value as any) => 
				let
					prefix = if Type.IsNullable(value) then "nullable " else ""
				in
					prefix & (
						if Type.Is(value, type binary) then "binary" else
						if Type.Is(value, type date) then "date" else
						if Type.Is(value, type datetime) then "datetime" else
						if Type.Is(value, type datetimezone) then "datetimezone" else
						if Type.Is(value, type duration) then "duration" else
						if Type.Is(value, type function) then "function" else
						if Type.Is(value, type list) then "list" else
						if Type.Is(value, type logical) then "logical" else
						if Type.Is(value, type none) then "none" else
						if Type.Is(value, type null) then "null" else
						if Type.Is(value, type number) then "number" else
						if Type.Is(value, type record) then "record" else
						if Type.Is(value, type table) then "table" else
						if Type.Is(value, type text) then "text" else
						if Type.Is(value, type time) then "time" else
						if Type.Is(value, type type) then "type" else
						if Type.Is(value, type any) then "any"
					else error "unknown"),
			
			//	if parameter is Optional set prefix
				OptionalPrefix = (_)=>if Type.IsNullable(_) then "optional " else "",
			
			//	get list of function parameters
				parameters = Type.FunctionParameters(Value.Type(placeholder)),
			
			//create a text list of parameters and associate types "[optional] paramname as type"
				parametersWithTypes = 
					List.Accumulate(
						Record.FieldNames(parameters),
						{},
						(state,cur)=>state & 
								{OptionalPrefix(Record.Field(parameters,cur)) &
								 cur & " as " & 
								 TypeAsText(Record.Field(parameters,cur))}
					)
			in 
			//merge parameter list and prefix with "function (" and suffix with function return type
			"function (" & Text.Combine(parametersWithTypes,", ") & ") as " & 
			TypeAsText(Type.FunctionReturn(Value.Type(placeholder))),
	
	NavigateShared = 
		let    
			sharedTab = Record.ToTable(#shared),
		
		//	select only functions from #shared
			functions = Table.SelectRows(sharedTab, each Type.Is(Value.Type([Value]),type function)),
		
		//	parse Module from function name
			modules = Table.AddColumn(functions, "Module", each Text.Split([Name], "."){0}, type text),
			functionNames = Table.AddColumn(modules, "FunctionName", each List.Last(Text.Split([Name], ".")), type text),
		
		//	get category from documentation
			categories = Table.AddColumn(functionNames, "Category", each 
							try Value.Metadata(Value.Type(Record.Field(#shared,[Name])))[Documentation.Category] otherwise ""),
		
		//	parse only the first code example from documentation
			examples = 
				Table.AddColumn(categories, "Examples", each 
					let 
						eg = Value.Metadata(Value.Type(Record.Field(#shared,[Name])))[Documentation.Examples]? 
					in 
						if Type.Is(Value.Type(eg),type record) then eg[Code] else eg{0}?[Code]?
				),
		
		//	get the short description from the documentation
			descriptions = Table.AddColumn(examples, "Description", each Value.Metadata(Value.Type(Record.Field(#shared,[Name])))[Documentation.Description]?),
		
		//	parse subcategories
			subcategories = Table.AddColumn(descriptions, "DotCategory", each List.Last(Text.Split([Category],"."))),
		
		//	adding the signature of the functions
			out = Table.AddColumn(subcategories, "Signature", each F[Signature](Record.Field(#shared,[Name])))
		in
			out,		
	M.library     = "", // * список функций #shared разделенный по категорям, встроенные/пользовательские (малополезная)
		//! надо копировать в проект, т.к. осюда при каждом испольхзовании функциий будут обновляться UDF таблицы из проекта
        // let
        //     Source      = 	Table.Sort(Record.ToTable(#shared),{{"Name", Order.Ascending}}),
        //     // 	ошибка при запуске через F[M.library] из проекта.
		// 		Categorized = 	Table.AddColumn(Source, "Status", each
		// 							if Record.HasFields(#sections[Section1], [Name]) 
		// 							then "User defined" 
		// 							else "Built in"
		// 						),
		// 	// 	нужно пользовательские данные, 
		// 	// 	но это устраняет циклическую ссылку, возникающую, если и F, и this относятся 
		// 	// 	ко всем пользовательским функциям (которые включают друг друга)
        //     	Filtered    = Table.SelectRows(Categorized, each [Status] = "Built in"),
		// 	//	! ошибки в Value_TypeToText. Падает Из за этого падает загрузка в PBID
		// 	// 	AddType     = Table.AddColumn(Filtered, "Type", 	 each F[Value.TypeToText]([Value]) ), 
        //     // 	AddTypeRec  = Table.AddColumn(AddType, "TypeRecurs", each F[Value.TypeToText]([Value], true) ),
		// 	AddCat = Table.AddColumn(Filtered, "Category", each
		// 		let
		// 			cut = Text.Split(Text.Replace([Name],"_","."),".")
		// 		in
		// 			(try
		// 				if   List.Contains({"Database", "Type"}, cut{1})
		// 				then cut{1}
		// 				else cut{0}
		// 			otherwise
		// 				"Custom"
		// 			)
		// 		),
        //     Return = AddCat
        // in
        //     Source,
   
	M.constants   = "", // * список констант в М 
        // // при обновлении обновляются все функции, в том числе UDF. В M.library надо UDF почистить. Недоделал
		// let
        //     Source 	  = M.library,
        //     Constants = Table.SelectRows(Source, each 
		// 					not Value.Is([Value], type type) and 
		// 					not Value.Is([Value], type function)
		// 				),
        //     Return 	  = Constants
        // in
        //     Return,

    M.UDFs        = "", // * список пользовательских функций 
        // let
        //     Source  = Record.FieldNames(#shared),
        //     UDFs    = List.Select(Source, each Record.HasFields(#sections[Section1], _)),
        //     Return  = UDFs
        // in
        //     Source,
	
    M.functions   = "", // * список функций, разделенный по категорям. Малополезная штука 
		//     let
		//         Type.ToText  = Load("Type.ToText"),
		//         Value.ToText = Load("Value.ToText"),
		//         Text.Count   = Load("Text.Count"),
		//         Source       = M.library,
				
		//         Functions    = Table.SelectRows(Source, each Value.Is([Value], type function)),

		//         AddFType    = Table.AddColumn(Functions,    "FType",        each Value.Type([Value])),
		//         AddReturn   = Table.AddColumn(AddFType,     "Returns",      each Type.FunctionReturn([FType])),
		//         AddRetTxt   = Table.AddColumn(AddReturn,    "RetText",      each Type.ToText([Returns])),
		//         AddRetRec   = Table.AddColumn(AddRetTxt,    "RetRecursive", each Type.ToText([Returns], true)),
		//         AddRetNull  = Table.AddColumn(AddRetRec,    "RetNullable",  each Type.IsNullable([Returns])),
		//         AddRetType  = Table.AddColumn(AddRetNull,   "RetType",      each let Type = Type.ToText(Type.NonNullable([Returns])) in if Type = "anynonnull" and [RetNullable] then "any" else Type),
		//         AddParams   = Table.AddColumn(AddRetType,   "Parameters",   each Type.FunctionParameters([FType])),
		//         AddNumPars  = Table.AddColumn(AddParams,    "NumParams",    each Record.FieldCount([Parameters])),
		//         AddReqd     = Table.AddColumn(AddNumPars,   "Required",     each Type.FunctionRequiredParameters([FType])),
		//         AddSig      = Table.AddColumn(AddReqd,      "Signature",    each Value.ToText([Value])), //! Value_ToText
		//         AddSigRec   = Table.AddColumn(AddSig,       "SigRecursive", each [Name] & " => " & Value.ToText([Value], true)), //! Value_ToText
		//         AddTally    = Table.AddColumn(AddSigRec,    "Times Used",   each Text.Count(Text.Queries, [Name])), //! Text_Queries
		//         GoodCols    = Table.RemoveColumns(AddTally, {"Type", "TypeRecurs"}),
		//         Return = GoodCols
		//     in
		//         Return,

    M.types       = "", // * возвращает типы функций ()
        // let
        //     Source = M.library,
        //     Types  = Table.SelectRows(Source, each Value.Is([Value], type type)),
        //     Return = Types
        // in
        //     Return,

    getUdfContent = "", // * возвращает содержимое текстового файла с UDF функцией на M (ИмяФункции.pq)
		// (fnName as text) => 
        // let
        //  	LoadPath = "",	// путь к папке с функциями
        //     Path    = LoadPath & (if Text.End(LoadPath, 1) <> "\" then "\" else ""),
        //     File    = Path & Text.Replace(fnName, "_", ".") & ".pq",
        //     AltFile = Path & fnName & ".m",  //just in case...
        //     Source  = Text.FromBinary(Binary.Buffer(
        //                 try File.Contents(File)
        //                 otherwise File.Contents(AltFile)
        //                 ))
        // in
        //     Source,

    UdfContents   = "", // * ошибка компиляции из-за M_UDFs. Все менял не выходит
        /* выдает ошибку при компиляции Используется в 2-х функциях еще*/
        // let
        //	   UdfTable     = Table.RenameColumns(Table.FromList(F[M.UDFs]), {"Column1", "Name"}),
        //     WithContents = Table.AddColumn(UdfTable, "Contents", each getUdfContent([Name]))
        // in
        //     WithContents,

	//======================== 
	// Date
	//========================
	Date.Today          = // текущая дата
        () =>
            Date.From(DateTime.FixedLocalNow()),
    
    Date.Tomorrow       = // дата завтра 
        () =>
            Date.AddDays(Date.From(DateTime.FixedLocalNow()), 1),

    Date.Yesterday      = // дата вчера
        () =>
            Date.AddDays(Date.From(DateTime.FixedLocalNow()), -1),

    Date.Calendar  	  	= // основной календарь
		Document(
			// Basic calendar
			"Date.Calendar",
			"Generate a calendar table for a given date span - can be text or proper dates. Current columns are Date, DayOfWeek, Month, MonthNum, WeekStartData, WeekStart, Year, YearMonth",
			{[ 	Description = "2016 calendar", 
				Code 		= "PBI[Date.Calendar](""1/1/2016"", ""12/31/2016""", 
				Result 		= "2016 calendar"]},

			(start as any, end as any) => 
				let
					StartDate 	= Date.From(start),
					EndDate 	= Date.From(end),
					Source 		= Date.DatesBetween(StartDate, EndDate),
					FromList 	= Table.FromList(Source, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
					Date 		= Table.RenameColumns(FromList,{{"Column1", "Date"}}),
					DayOfWeek 	= Table.AddColumn(Date, "Day of Week", each Date.DayName([Date])),
					Month 		= Table.AddColumn(DayOfWeek, "Month", each Date.MonthName([Date])),
					MonthNum 	= Table.AddColumn(Month, "MonthNumber", each Date.Month([Date])),
					WeekStartDate = Table.AddColumn(MonthNum, "WeekStartDate", each Date.StartOfWeek([Date])),
					WeekStart	= Table.AddColumn(WeekStartDate, "Week Start", each [Month] & " " & Text.From(Date.Day([WeekStartDate]))),
					Year 		= Table.AddColumn(WeekStart, "Year", each Date.Year([Date])),
					YearMonth	= Table.AddColumn(Year, "YearMonth", each Number.From(Text.From([Year]) & (if [MonthNumber] < 10 then "0" else "") & Text.From([MonthNumber]))),
					Result 		= YearMonth
			in
					Result 
		),

	Date.DatesBetween 	= // возвращает список дат между датами 
		Document(
			"Date.DatesBetween",
			"Returns a list of dates in a given span (inclusive). Start and end parameters can be any order",
			{[	Description = "Date range", 
				Code 		= "PBI[Date.DatesBetween](""1/1/2016"", ""1/3/2016"")", 
				Result		= "{""1/1/2016"", ""1/2/2016"", ""1/3/2016""}" ]},
			
			(start as any, end as any) => 
			let 
				StartDate 	= Date.From(start), 
				EndDate 	= Date.From(end),
				adjustedStart = List.Min({StartDate, EndDate}),
				adjustedEnd = List.Max({StartDate, EndDate}),
				GetDates 	= (start as date, end as date, dates as list)=> if start > end then dates else @GetDates(Date.AddDays(start, 1), end, List.Combine({dates, {start}})),
				Dates 		= GetDates(adjustedStart, adjustedEnd, {})
			in 
				Dates 
		),

	Date.DayName   	  	= // возвращает название дня недели по его номеру 
		Document(
			"Date.DayName",
			"Returns the English day of the week name for a date",
			{[ Description = "Get the day name", Code="Date.DayName(""9/9/2016"")", Result="Friday"]},
			
			(date as any) => 
				Switch(
					Date.DayOfWeek(DateTime.From(date)), 
					{0, 1, 2, 3, 4, 5, 6}, 
					{"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"}, 
					null
				)
		),

	Date.MonthName 	  	= // возвращает название месяца по его номеру 
		Document(
			"Date.MonthName",
			"Returns the English month name for a date",
			{[ Description = "Get the month name", Code="PBI[Date.MonthName](""9/9/2016"")", Result = "September" ]},
		
			(date as any) => 
				let 
					monthNumber = if date is number then date else Date.Month(DateTime.From(date))
				in 
					Switch(
						monthNumber,
						{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12}, 
						{"January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"},
						null
					)
		),

	Date.EndOfLastMonth = // дата последнего дня текущего месяца
        () =>
			Date.EndOfMonth(Date.AddMonths(Date.From(DateTime.FixedLocalNow()), -1)) ,

    Date.EpochToDate    = // преобразует дату формата SAP в нормальную
        /*
            Description:
                convert date from SAP ByDesign into normal date
                SAP JSON response shows date as "/Date(1357084800000)/"
            
            Usadge:
                Table.TransformColumns(Expand,{{"Posting Date", EpochToDate}})
        */
    
        let EpochToDateTime = (epoch as nullable text ) =>
            let res = if epoch = null then null else
                let remove_word      = Text.Replace(epoch, "Date", ""),
                    remove_slash     = Text.Replace(remove_word, "/", ""),
                    remove_left_par  = Text.Replace(remove_slash, "(", ""),
                    remove_right_par = Text.Replace(remove_left_par, ")", ""),
                    calc =  #datetime(1970, 1, 1, 0, 0, 0) + 
                            #duration(0, 0, 0, Number.FromText(Text.Start(remove_right_par,Text.Length(remove_right_par)-3)))
                in calc
            in res
        in EpochToDateTime,
    
    Date.FormatSQL      = // преобразует нормальную дату в формат SQL (2024-01-01T00:00:00)
        (DateValue as any) =>
        let  
            FormattedDate = DateTime.ToText(DateTime.From(DateValue), "yyyy-MM-ddT00:00:00", "en-US")
        in
            FormattedDate,

    Date.NDaysAgo       = // возвращает дату, отстояющую от текущей на n дней в формате (2024-07-15T11:22:22.0204864)
        /*
            return date of N days ago from Today
            usage: 	Date.NDaysAgo(3)
            Result: depends on Today 
        */

        (N as number) => 
            Date.AddDays(DateTime.FixedLocalNow(), -N),

    Date.NDaysInFuture  = // возвращает дату, после текущей на n дней в формате (2024-07-15)
        (N as number) => 
            Date.AddDays(Date.From(DateTime.FixedLocalNow()), N),

    Date.StartOfCurrentYear = // дата начала текущего года
        // Пример: F[Date.StartOfCurrentYear]()
		() =>
            Date.StartOfYear(Date.From(DateTime.FixedLocalNow())),

    Date.StartOfLastYear 	= // дата начала прошлого года
        () =>
            Date.AddYears(Date.StartOfYear(Date.From(DateTime.FixedLocalNow())), -1),
    
    Date.StartOfMonth12MAgoExcCurMonth = // дата начала месяца = 12 месяцев назад
        // 	Пример (если сейчас 15.08.2024) 
		//	= F[Date.StartOfMonth12MAgoExcCurMonth]() = "01.08.2023"
		() =>
            Date.StartOfMonth(Date.AddMonths(Date.From(DateTime.FixedLocalNow()), -12)),
    
    Date.StartOfMonth12MAgoIncCurMonth = // дата начала следующего месяца = 12 месяцев назад
        // 	Пример (если сейчас 15.08.2024) 
		//	= F[Date.StartOfMonth12MAgoIncCurMonth]() = "01.09.2023"

		() =>
            Date.StartOfMonth(Date.AddMonths(Date.From(DateTime.FixedLocalNow()), -11)),

    DateTime.FormatSQL  = // дата/время формата SQL (2024-01-01T12:00:00)
        (DateTimeValue as any) =>
            DateTime.ToText(DateTime.From(DateTimeValue), "yyyy-MM-ddThh:mm:ss", "en-US"),

    DateTime.UnixTime   = // дата/время формата Unix (20.05.2018 7:15:25)
        /*
            Convert unix timestamp into Power Query datetime formart
            Usage: DateTime_UnixTime(1526800525) = 20.05.2018 7:15:25
        */
        (unixtime as number) as datetime => 
            #datetime(1970, 01 , 01, 0, 0, 0) + #duration(0,0,0,unixtime),
	// взаимные функции (редкие)
	Date.Parse 				= // 1 заменяет текстовую дату на дату в нормальном формате 
		/*
			Описание
				1 Улучшен анализатор дат для строк, содержащих даты в неопределенном формате
				2 Есть список автозамен

			Пример		= F[Date.Parse]("январь 2017")
						= F[Date.Parse]("январь 2017 г")
						= F[Date.Parse]("январь 2017 год.")
			
			Результат	"01.01.2017"
		*/
		(datetext as text) =>
			let
			/* 	Список включенных локалей в порядке предпочтения */
				Locales = {
					null,  // system default
					"en",
					"en-US",
					"en-GB",
					"ru",
					"ru-RU",
					"ru-UA",
					"ru-BY",
					"de",
					"de-DE",
					"de-BE"
				},

			/* 	Распространенные замены, которые превращают строку в читаемую дату */
				Substitutions = {
					{"года", "г"},
					{"год", "г"}
				},

			/* 	Пробуем все замены, перечисленные выше, и возвращаем первый успешный результат */
				TryAllSubstitutions = (datetext as text, reader as function) =>
					let
						Result = List.Last(
							List.Generate(
								() => [i=-1, date=null],
								each [i] < List.Count(Substitutions),
								each [
									i = [i] + 1,
									date =
										if
											[date] is null
										then
											try reader(
													Text.Replace(
														datetext,
														Substitutions{i}{0},
														Substitutions{i}{1}
													)
												)
											otherwise null
										else
											[date]
								],
								each [date]
							)
						),
						Return =
							if   Result is null
							then error "Could not read date with substitutions: " & datetext
							else Result
					in
						Return,

			/* 	Пробуем все локали, перечисленные выше, и возвращаем первый успешный результат */
				TryAllLocales = (datetext as text) =>
					let
						Result = List.Last(
							List.Generate(
								() => [i=-1, date=null],
								each [i] < List.Count(Locales),
								each [
									i = [i] + 1,
									date =
										if
											[date] is null
										then
											try Date.FromText(datetext, Locales{i})
											otherwise null
										else
											[date]
								],
								each [date]
							)
						),
						Return =
							if   Result is null
							then error "Could not read date with locales: " & datetext
							else Result
					in
						Return,

				/* Выполняем все шаги */
				CleanDateText = Text.Lower(Text.Trim(datetext)),
				Return = TryAllSubstitutions(CleanDateText, TryAllLocales)
			in
				Return,

	Date.IntervalFromText 	= // 2 возвращает список из двух дат, соответствующих началу и концу по текстовому описанию
		/*
			Описание
				1 	по строке текста, например «январь 2024 г. – декабрь 2024 г."
					возвращает список из двух дат, соответствующие началу и концу интервала
				2 	Основывается на функции Date.Parse
			
			Особенность
				1 	месяцы можно писать: полностью, сокращенно, в падеже
				2	годы можно писать: г, г., год, года (можно изменить в Date.Parse список автозамен)
			
			Пример		= F[Date.IntervalFromText]("январь 2023 - 10 январь 2024")
			Результат	= { 01.01.2023, 10.01.2024 } тип Date

			Пример		= F[Date.IntervalFromText]("10 январь 2024 года - 30 декабря 2024 г.")
			Результат	= { 10.01.2024, 30.12.2024 } тип Date

			Пример		= F[Date.IntervalFromText]("январь 23 года - декабрь 24 г.")
			Результат	= { 01.01.2024, 31.12.2024 } тип Date

		*/

		(date_interval as text,
		optional delimiter as text,
		optional full_months as logical) =>
		
		let
			Date.Parse = try Date.Parse otherwise Date.FromText,

			/* 	Предопределенные интервалы */
				Presets = #table(
					{"interval", "start", "end"},
					{
						{"1 квартал", "январь", "март"},
						{"2 квартал", "апрель", "июнь"},
						{"3 квартал", "июль", "сентябрь"},
						{"4 квартал", "октябрь", "декабрь"},
						{"1 полугодие", "январь", "июнь"},
						{"2 полугодие", "июль", "декабрь"},
						{"9 месяцев", "январь", "сентябрь"}
					}
				),
			
			PresetFullYear = [
				trim = {",","."," ",";"},
				remove = {"г", "год"}
			],

		/* 	Значения параметров по умолчанию */
			Delimiter = if delimiter is null then " - " else delimiter,
			FullMonth = if full_months is null
						then if	 EndStrings{1} is null
							 then Date.Day(DateStart) = 1
							 else Date.Day(DateEndParsed) = 1 and Date.Day(DateStart) = 1
						else full_months,

		/* 	Проверяем, представляет ли date_interval полный год */
			YearCandidates =
				List.Transform(
					PresetFullYear[remove],
					each
						try
							Number.FromText(
								Text.Trim(
									Text.Replace(Text.Lower(date_interval), _, ""),
									PresetFullYear[trim]
								)
							)
						otherwise
							null
				),
			YearDetected = List.Select(YearCandidates, each _ <> null){0},
			YearText =
				try
					Text.From(#date(YearDetected, 1, 1)) &
					Delimiter &
					Text.From(#date(YearDetected, 12, 31))
				otherwise
					null,

		/* 	При необходимости применить настройки замены */
			SelectedPreset =
				try
					Table.ToRecords(
						Table.SelectRows(
							Table.AddColumn(
								Presets,
								"match",
								each Text.Contains(
									Text.Lower(date_interval),
									[interval]
								)
							),
							each [match] = true
						)
					){0}
				otherwise
					null,

			ApplyPreset = 
				(interval as text, preset as record) =>
					let
						input = Text.Lower(interval),
						start = Text.Replace(input, preset[interval], preset[start]),
						end   = Text.Replace(input, preset[interval], preset[end])
					in
						start & Delimiter & end,

			InputWithPresetsApplied =
				if	 SelectedPreset is null
				then date_interval
				else ApplyPreset(date_interval, SelectedPreset),

			/* Парсинг */
			EndStrings = List.Combine({
				Text.Split(
					if	YearText is null
						then InputWithPresetsApplied
						else YearText,
					Delimiter),
				{null}
			}),
			DateStart 	  = Date.Parse(EndStrings{0}),
			DateEndParsed = try Date.Parse(EndStrings{1}) otherwise null,
			DateEndGuess  =
				if	 EndStrings{1} is null
				then DateStart
				else DateEndParsed,
			
			DateEnd = 
				if FullMonth 
				then Date.EndOfMonth(DateEndGuess) 
				else DateEndGuess
		in
			{DateStart, DateEnd}
		,
	// TimeZone
	DateTimeZoneToDateTime_SwitchZone = //
		(TimeZone as number) as function =>
			(DateTimeZone as nullable datetimezone) as nullable datetime=>
			let
				SwitchedZone = DateTimeZone.SwitchZone(DateTimeZone,TimeZone),
				DateTime 	 = DateTime.Date(SwitchedZone) & DateTime.Time(SwitchedZone)
			in
				if DateTimeZone is null then null else DateTime,

	DateTimeZoneToDate_SwitchTimeZone = // ...…te_SwitchTimeZone
		(TimeZone as number) as function =>
			(DateTimeZone as nullable datetimezone) as nullable date=>
			let
				SwitchedZone = DateTimeZone.SwitchZone(DateTimeZone,TimeZone),
				Date = DateTime.Date(SwitchedZone) // & DateTime.Time(DateTimeZone)
			in
				if DateTimeZone is null then null else Date,
	
	
	//======================== 
	// List
	//========================
	// основные
	List.Flatten  		= // объединяет несколько списков, в том числе вложенных! в один
		/*
			Описание	объединяет списки в один, сохраняя другие типы данных, тут один
			Пример		= F[List.Flatten] ({1, 2, Table.FromRecords({[x=1]}), {{3,4},5} })
			Результат 	= {1, 2, Table.FromRecords({[x=1]}), 3, 4, 5}
		*/
		Document(
			"List.Flatten",
			"Recursively flattens list elements. The end result is a single list",
			{ [ Description = "Flattening nested lists into one", 
				Code 		= "List.Flatten({ 1, 2, Table.FromRecords({[x=1]}), {3, 4, 5} })", 
				Result 		= "{ 1, 2, Table.FromRecords({[x=1]}), 3, 4, 5}"] },
			
			(list as list) => 
				List.Accumulate(list, {}, (state, current) =>
					let
						currentListContent = if current is list then @List.Flatten(current) else {current}
					in
						List.Combine({state, currentListContent})
			)
		),
	List.Items    		= // # возвращает элементы списка по номеру вхождения
		/*
			Пример		F[List.Items]({10,20,30,40,50},{1,3,4})
			Результат	{10, 30, 40}
			Например	F[List.Items](Table.ColumnNames(from),{1,3,4})
		*/
		Document(
			"List.Items", 
			"Возвращает список значений по позиции элементов",
			{ [ Description = "Возвращает элементы списка по номеру вхождения", 
				Code 		= "= F[List.Items]({1,2,3,4,5,6,7,8,9,10},{1,3,4})", //  
				Result 		= "{1, 3, 4}" ]},
		
			(MyList as list, Indexes as list) =>
				List.Transform(
					List.Select(Indexes, (x)=> x>=0 and x<=List.Count(MyList) ),
					each MyList{_-1}
				)
		),

	List.From    		= // преобразует текст, разделенный запятыми в список
		/*
			F[List.From]("{A, B, C}") = {"A", "B", "C"}
		*/
		Document(
			"List.From", 
			"Преобразует текст, разделенный запятыми в список",
			{[ 	Description = "Конвертирует текст в список", 
				Code 		= "List.From(""{A, B, C}"")", 
				Result 		= "{ ""A"", ""B"", ""C"" }"	]},
		
			(simpleTextList as text) => [
				trimWhitespace 	= Text.Trim(simpleTextList),
				listToSplit 	= Text.TrimEnd(Text.TrimStart(trimWhitespace, "{"), "}"),
				Result 			= List.Transform(Text.Split(listToSplit, ","), each Text.Trim(_))
			] [Result]
		),
		
	List.ToText   		= // конвертирует список в текст. Обратная функция List.From
		/*
			Описание	Создает текстовое представление списка (без разделителей)
			Пример		F[List.ToText] ({1, 2, "abc", 1+2}   = "{12abc3}"
						F[List.ToText] ({"abc","def","hgk"}) = {abcdefhgk}
		*/
		Document(
			"List.ToText",
			"Конвертирует список в текст. Обратная функция List.From",
			{[ 	Description = "Конвертирует текст в список", 
				Code 		= "List.ToText({ 1, 2, ""abc"",1+2})", 
				Result 		= """{12abc3}"""	]},
			(list as list) => 
				List.Accumulate(list, "{", (state, current) => state & Text.From(current)) & "}"
		),	
		// or (list as list) as text => "{""" & Text.Combine(list, """, """) & """}"
		
		/* 	
			Вариант 2. Так же как и выше, но добавляет, между значениями
			функция ListAsText - через запятую
			from: https://github.com/microsoft/DataConnectors/blob/460babf2f8c44ec82d7e08d1b65b156984c6ba75/samples/UnitTesting/UnitTesting.query.pq#L210-L244
			
			Одной строкой:
				ListAsText = (x)=> "{" & List.Accumulate(x, "", (s,item) => if s="" then Text.From(item) else s & ", " & Text.From(item)) & "}"

			Пример
				let	NameList = { "moNkey", "monKEY", "MONKEY", "mONkeY" },
					Source   = Table.FromList(NameList, null,type table[Name = text],null, null),
					Results  = [
						#"Original List" 					= ListAsText(  Source[Name] ),
						#"IsDistinct? Ordinal" 				= List.IsDistinct( Source[Name], Comparer.Ordinal ),
						#"IsDistinct? OrdinalIgnoreCase" 	= List.IsDistinct( Source[Name], Comparer.OrdinalIgnoreCase ),
						#"Distinct using OrdinalIgnoreCase" = ListAsText(  List.Distinct( Source[Name], Comparer.OrdinalIgnoreCase ) ),
						#"Distinct using Ordinal" 			= ListAsText(  List.Distinct( Source[Name], Comparer.Ordinal ) )
					]
				in	Results	
		),*/
				
	List.ToRecord 		= // конвертирует список в запись с лямбда функцией преобразования
		/*  
            Конвертирует список строк в запись, используя лямбду функцию (переданные значения x)
            Встроенный Record.FromList принимает только статические списки
			В списке должен быть только текст, т.к. это имена полей

            Usage:	F[List.ToRecord]( {"a","b"}, (x)=> Text.Upper(x) )
            Result: [a="A", b="B"]

			Usage:	F[List.ToRecord]( {"1","2"}, (x)=> Number.From(x) + 1 )
			Result:	[1=2, 2=3]
		*/
		Document(
			"List.ToRecord", 
			"Конвертирует список в запись",
			{[ 	Description = "Конвертирует список в запись", 
				Code 		= "List.ToRecord({""a"",""b""}, (k) => Text.Upper(k))", 
				Result 		= "[a=""A"", b=""B""]"	]},
			
			(List as list, Lambda as function) as record =>
				let
					Transformed = List.Transform(List, Lambda)	//each Lambda(_)
				in
					Record.FromList(Transformed, List)
		),
		
	List.ToZip    		= // конвертирует пару списков в список записей, если указаны имена
		/*
			Архивирует список списков, чтобы «транспонировать» их — как записи, если указаны имена
			Если имена не указаны, то будет возвратится список списков, что аналогично List.Zip
		
			Пример		F[List.ToZip]( { {1,2,3}, {"a","b","c"} }, {"Name","Value"} )
			Результат	{ [Name=1, Value="a"], 
						  [Name=2, Value="b"], 
						  [Name=3, Value="c"] }
			
			Usage:  	List.ToZip( { {1,2,3}, {"a","b","c"} } )
			Result: 	{ {1,"a"}, {1,"b"}, {1,"c"}, }
		*/

		(listOfLists as list, optional names as list) as list =>
		let
			max 	= List.Max(List.Transform(listOfLists, each List.Count(_))),
			zipped 	= List.Skip(
				List.Generate(
					()=>[
						i = -1,
						vals = {},
						combined = {}
					],
					each [i] < max,
					each [
						i = [i] + 1,
						vals = List.Transform(listOfLists, each _{i}),
						combined = 	if names = null 
									then vals 
									else Record.FromList(vals, names)
					],
					each [combined]
				))
		in
			zipped,

	List.ReplaceErrors	= // удаляет ошибки в списке или заменяет их на значение
		/*
			Описание:	Заменяет значения ошибок в данном списке переданным значением замены (или нулем, если замена опущена)
			Пример:		= F[List.RemoveErrors] ({1,2,error "this is an error",4})
			Пример:		= F[List.RemoveErrors] ({1,2,error "this is an error",4}, "ошибка") // не проверял второй аргумент
			Результат:	= {1,2,4}
		*/
		(ListWithError as list, optional Replacement as any) as list =>
			List.Transform(
				List.Positions(ListWithError), 
				each try ListWithError{_} otherwise Replacement
			),
  
	List.RemoveErrors   = // удаляет из списка Error (с трансформацией списка в таблицу, через Table.RemoveRowsWithErrors)
        /*
            Описание:	Принимает список в качестве входных данных и возвращает тот же список, но без значений ошибок.
            Полезно:	Когда ошибки в список/столбец пришли из внешнего источника и нет возможности устранить ошибки перед использованием списка.
            Пример:		= List.RemoveErrors({1,2,error "this is an error",4})
            Результат:	= {1,2,4}
        */
		(ListWithErrors as list) as list =>
			let
				CleanList = Table.RemoveRowsWithErrors(Table.FromColumns({ListWithErrors}))[Column1]
			in
				CleanList
		/*  
            Вариант 2.
			Удаляет из списка Error (без замены, без трансформации списка в таблицу, через List.Accumulate) 
			(ListWithError as list) as list =>
					List.Accumulate(
						List.Positions(ListWithError),
						{},
						(CleanListSoFar, CurrentPosition) =>
							CleanListSoFar & 
							(   if (try ListWithError{CurrentPosition})[HasError] 
								then {} 
								else { ListWithError{CurrentPosition} }
							)
					)
				in	Source,		
			*/
		,
			
	List.RemovePositions = // удаляет из списка элементы по номеру позиции 
		/*
			При вызове этой функции мы можем удалить элементы на 2-й и 4-й позициях индекса из списка:
			Used	List.RemovePositions( { "a".."g" } , { 2, 4 } ) 
			Output	{ "a", "b", "d", "f", "g" }
		*/
		( list as list, removeIndexes as list ) as list =>
			let
				Source     = list, 
				RemoveN    = removeIndexes, 
				Indexes    = List.Positions ( Source ), 
				KeepValues = List.Difference ( Indexes, RemoveN ), 
				Result     = List.Transform ( KeepValues, each Source{_} )
			in
				Result,
	
	List.SelectPositions = // возвращает N-й элемент из списка,
		/* 
			Вызовите эту функцию fxListSelectPositions каждый раз, когда вам нужно получить N-й элемент из списка, вы можете просто написать:
			fxListSelectPositions( {"a".."z"}, {10, 15, 20 } )
		*/
		( inputList as list, positions as list ) as list =>
			let
				myList 	  = inputList,
				BufferList = List.Buffer( myList ),
				Positions  = positions,
				FetchItems = List.Transform( Positions,  each BufferList { _ } )
			in
				FetchItems,
	
	// дополнительные
	List.CrossJoin      = // возвращает перекрестное соединение двух списков в виде таблицы
        /*
            Возвращает перекрестное соединение двух аргументов (могут быть списками или таблицами)

            Usage:	List.CrossJoin({"A","B"},{1..3})
            Result: 
                #table(
                    {"A","B"},
                    {
                        {"A",1},
                        {"A",2},
                        {"A",3},
                        {"B",1},
                        {"B",2},
                        {"B",3}
                    }
                )
        */

        (A as list, B as list) as table =>
        let
            firstList        = List.RemoveNulls(A),
            secondList       = List.RemoveNulls(B),
            firstLength      = List.Count(firstList),
            secondLength     = List.Count(secondList),
            resultFirstList  = 
                List.Generate( 
                    () => 0, 
                    each _ < firstLength * secondLength, 
                    each _ + 1, 
                    each firstList{ Number.IntegerDivide(_, secondLength) }
                ),
            resultSecondList = List.Repeat( secondList, firstLength)
        in
            Table.FromColumns({resultFirstList, resultSecondList}),

    List.FlatMap        = // сопоставляет список с помощью ЛЯМБДЫ, объединяя все результаты в один список 
        /*
            Описание	Сопоставляет список с помощью лямбда функции таким образом, что все результаты снова объединяются в один список
            Пример 1	= List.FlatMap({1,2,3}, (x)=> List.Numbers(1, x))	Результат 	= {1, 1, 2, 1, 2, 3}
        */

        (lst as list, fx as function) => 
			List.Combine(List.Transform(lst, fx)),

    List.RankDense      = // ранжирует входное значение в серии. Удаляет дубликаты, чтобы ранжировать уникальные значения 
        /*
            Описание		Ранжирует входное значение в серии (по возрастанию или убыванию). 
			Особенность		Удаляет дубликаты, чтобы ранжировать только уникальные значения.
            Ссылка			http://social.technet.microsoft.com/Forums/en-US/973e9381-ff46-4756-a071-88bb4c2105e4/pushing-more-calcs-to-power-query-replacing-dax-rankx
            Пример			= F[List.RankDense] ("B",{"A","A","B","C"})
            Result			2
        */

        (inputValue as any, inputSeries as list, optional orderDescending as nullable logical) as number => 
			let
				order 			= if orderDescending or orderDescending = null then Order.Descending else Order.Ascending,
				SortedSeries    = List.Sort(inputSeries, order),
				DistinctSeries  = List.Distinct(SortedSeries),
				RankDense       = List.PositionOf(DistinctSeries,inputValue)+1
			in
				RankDense,

    List.RankEqual      = // ранжирует входное значение в серии. Не удаляет дубликаты 
        /*
            Описание 	Ранжирует входное значение в серии (по возрастанию или убыванию). Не фильтрует дубликаты.
			Ссылка		http://social.technet.microsoft.com/Forums/en-US/973e9381-ff46-4756-a071-88bb4c2105e4/pushing-more-calcs-to-power-query-replacing-dax-rankx
            Пример		= F[List.RankEqual] ("B",{"A","A","B","C"})
            Result     	3	
			Возвращает 	номер вхождения искомого элемента после сортировки

        */
        (inputValue as any, inputSeries as list, optional orderDescending as nullable logical) as number => 
			let
				order 		 = if orderDescending or orderDescending = null then Order.Descending else Order.Ascending,
				SortedSeries = List.Sort(inputSeries, order),
				RankEqual    = List.PositionOf(SortedSeries,inputValue) + 1
			in
				RankEqual,

    // даты
	List.DatesBetween   	= // создает список дат между заданными двумя датами
        /*
            Описание:
				List_DatesBetween является альтернативой функции List.Dates. 
            	Он принимает только две даты в качестве аргументов и создает список дат между заданными двумя датами
            Usage: 
                List_DatesBetween(11/17/2016, 12/19/2016)
        */

        (dateStart as date, dateFinish as date) =>
			let
				countOfDays = Number.From(dateFinish - dateStart),
				output =    if countOfDays > 0 
							then List.Dates(dateStart, countOfDays + 1, #duration(1,0,0,0))
							else "Error! Your inputs are incorrect. Check the inputs." 
			in
				output,

    List.Dates.HolidaysRU 	= 
        /*	Function gets list of non-working days (weekends and official holidays) 
			from official source "Open Data" managed by Analytical Center of Russian Federation
			
			Function has two arguments - From_Year, To_Year
			which allows to restrict period of time that you need for your data model.
			
			Usage:		List.Dates.HolidaysRU( 2015, 2016 )
			Response:	List of non-working days in Russian Federations for years 2015 and 2016
		*/

        (from_year as number, to_year as number) =>
            let
                fGetLatestURL = 
                    let
                        Source = Table.FromColumns({Lines.FromBinary(Web.Contents("http://data.gov.ru/node/19107/code-passport"))}),
                        #"Filtered Rows" = Table.SelectRows(Source, each Text.Contains([Column1], "Гиперссылка (URL) на набор")),
                        #"Get Text with URL" = #"Filtered Rows"{0}[Column1],
                        #"Position of HTTP" = Text.PositionOf(#"Get Text with URL", "http"),
                        #"Position of CSV" = Text.PositionOf( #"Get Text with URL", ".csv" ),
                        URL = Text.Range( #"Get Text with URL", #"Position of HTTP", #"Position of CSV" - #"Position of HTTP" + 4 )
                    in
                        URL,

                Source = Csv.Document(Web.Contents( fGetLatestURL ),[Delimiter=",", Columns=13, Encoding=65001, QuoteStyle=QuoteStyle.None]),		
                #"Promoted Headers" = Table.PromoteHeaders( Source ),
                #"Changed Type" = Table.TransformColumnTypes(#"Promoted Headers",{{"Год/Месяц", Int64.Type}}),
                #"Filtered Rows1" = Table.SelectRows(#"Changed Type", each [#"Год/Месяц"] >= from_year and [#"Год/Месяц"] <= to_year ),
                #"Renamed Columns1" = Table.RenameColumns(#"Filtered Rows1",{{"Январь", "1"}, {"Февраль", "2"}, {"Март", "3"}, {"Апрель", "4"}, {"Май", "5"}, {"Июнь", "6"}, {"Июль", "7"}, {"Август", "8"}, {"Сентябрь", "9"}, {"Октябрь", "10"}, {"Ноябрь", "11"}, {"Декабрь", "12"}, {"Год/Месяц", "Год"}}),
                #"Unpivoted Other Columns" = Table.UnpivotOtherColumns(#"Renamed Columns1", {"Год"}, "Attribute", "Value"),
                #"Split Column by Delimiter" = Table.SplitColumn(#"Unpivoted Other Columns","Value",Splitter.SplitTextByDelimiter(",", QuoteStyle.Csv) ),
                #"Unpivoted Other Columns1" = Table.UnpivotOtherColumns(#"Split Column by Delimiter", {"Год", "Attribute"}, "Attribute.1", "Value"),
                #"Removed Columns" = Table.RemoveColumns(#"Unpivoted Other Columns1",{"Attribute.1"}),
                #"Renamed Columns" = Table.RenameColumns(#"Removed Columns",{{"Attribute", "Месяц"}, {"Value", "День"}}),
                #"Filtered Rows" = Table.SelectRows(#"Renamed Columns", each not Text.Contains([День], "*")),
                #"Changed Type1" = Table.TransformColumnTypes(#"Filtered Rows",{{"Месяц", Int64.Type}, {"День", Int64.Type}}),
                #"Added Custom" = Table.AddColumn(#"Changed Type1", "Date", each #date( [Год], [Месяц], [День] ), type date),
                #"Removed Other Columns1" = Table.SelectColumns(#"Added Custom",{"Date"})

            in
                #"Removed Other Columns1",
    
    List.Dates.LastNDays  	= 
        (N as number) => 
            List.Dates(Date.AddDays(Date.From(DateTime.FixedLocalNow()), -N), N, #duration(1,0,0,0)),

    List.Dates.LastNYears 	= 
        (N as number) =>
            let
                start 	= Date.StartOfYear(Date.AddYears(Date.From(DateTime.FixedLocalNow()), -N)),
                end 	= Date.EndOfYear(Date.AddYears(Date.From(DateTime.FixedLocalNow()), -1)),
                result 	= List.Dates(start, Duration.Days(end - start) + 1, #duration(1,0,0,0))
            in 
                result,

    List.Dates.LastNYearsAndCurYear  = 
        // last N years and Current year
        (N as number) =>
            let
                start 	= Date.StartOfYear(Date.AddYears(Date.From(DateTime.FixedLocalNow()), -N)),
                end 	= Date.EndOfYear(Date.From(DateTime.FixedLocalNow())),
                result 	= List.Dates(start, Duration.Days(end - start) + 1, #duration(1,0,0,0))
            in 
                result,

    List.Dates.NYearsToDate          = 
        // N years to today
        (N as number) =>
            let
                start 	= Date.StartOfYear(Date.AddYears(Date.From(DateTime.FixedLocalNow()), -N)),
                end 	= Date.From(DateTime.FixedLocalNow()),
                result 	= List.Dates(start, Duration.Days(end - start) + 1, #duration(1,0,0,0))
            in 
                result,
    
    List.Dates.R12MExcCurMonth       = 
        () =>
            let
                start  = Date.StartOfMonth(Date.AddMonths(Date.From(DateTime.FixedLocalNow()), -12)),
                end    = Date.AddDays(Date.StartOfMonth(Date.From(DateTime.FixedLocalNow())), -1),
                result = List.Dates(start, Duration.Days(end - start) + 1, #duration(1,0,0,0))
            in 
                result,
    
    List.Dates.R12MIncCurMonthToDate = 
        () =>
            let
                start   = Date.StartOfMonth(Date.AddMonths(Date.From(DateTime.FixedLocalNow()), -11)),
                end     = Date.From(DateTime.FixedLocalNow()),
                result  = List.Dates(start, Duration.Days(end - start) + 1, #duration(1,0,0,0))
            in 
                result,
    
    List.Dates.YTD          = 
        () =>
            let
                start   = Date.StartOfYear(Date.From(DateTime.FixedLocalNow())),
                end     = Date.From(DateTime.FixedLocalNow()),
                result  = List.Dates(start, Duration.Days(end - start) + 1, #duration(1,0,0,0))
            in 
                result,

    List.Dates.YTDLastYear  = 
        () =>
            let
                start 	= Date.StartOfYear(Date.AddYears(Date.From(DateTime.FixedLocalNow()), -1)),
                end 	= Date.AddYears(Date.From(DateTime.FixedLocalNow()), -1),
                result  = List.Dates(start, Duration.Days(end - start) + 1, #duration(1,0,0,0))
            in 
                result,
	// разобрать
	List.TransformSaveType = // список + лямбда функция. Сохраняет типы на выходе //* Надо на примере попробовать
		/*	
			Описание
				Эти функции в основном представляют собой версии функций, созданных Microsoft. 
				Однако эти функции помогают сохранить возвращаемые типы функций, которые так легко теряются. 
				Одним из практических результатов использования этих функций в ваших запросах является то, 
				что столбцы вашей таблицы с меньшей вероятностью изменятся на какой-либо тип 

			Пример

		*/
		(list as list, transform as function)=>
		let
			listTransform = List.Transform(list, transform),
			listType      = type {Type.FunctionReturn(Value.Type(transform))}
		in
			Value.ReplaceType(listTransform,listType),
   
	
	//======================== 
	// Number
	//======================== 
	Number.Digits 	 = {0,1,2,3,4,5,6,7,8,9},
	Number.ParseText = // возвращает последовательно идущие цифры в текстовой строке слева (можно список символов исключений)
		/*
			Описание 	
				Возвращает первое число (1 + последовательные цифры) в  тексте. 
				При желании можно указать разрешенные символы, чтобы их игнорировать.
			Особенности
				начинает с первого найденной цифры, остальные игнорируются
			Аргументы
				text as text						- текст
				optional startIndex as number		- стартовый индекс
				optional allowCharacters as list	- список исключаемых символов
			Пример		
				= F[Number.ParseText]("Число 9000!", 0, {"",""}) 	= "9000"	// только числа	
				= F[Number.ParseText]("Число 9000!", 8, {"","!"}) 	= "00!"		// числа + ! начиная с 8 символа
				= F[Number.ParseText]("1 Число 9000!", 0, {"",""}) 	= "1"		// первое число слева
			Вывод		
				текстовая строка
		*/

		Document(
			"Number.ParseText",
			"Returns the first number (1+ consecutive digits) in the given text. Optionally, provide allowed characters to ignore them",
			{[ 	Description = "Allow commas", 
				Code		= "F[Number.ParseText](""Число 9,000!"", 0, {"",""})", 
				Result 		= "9000" ]},

			(text as text, optional startIndex as number, optional allowCharacters as list) => 
				let
					consider = if startIndex is null then text else Text.Range(text,startIndex), 
					_allowCharacters = if allowCharacters is null then {} else allowCharacters,
					numberSeries = 
						List.FirstN(
							List.Skip(
								Text.ToList(consider), 
								each not Text.IsNumber(_)
							), 
							each Text.IsNumber(_) or List.Contains(_allowCharacters, _)
						)
				in 
					if text is null then null else Text.FromList(numberSeries)	
		),

	Number.ToLetters = // переводит число (начиная с 1) в алфавитное представление (как заголовки столбцов в Excel, 2->B)
		Document(
			"Number.ToLetters",
			"Converts a number  (starting at 1) to an alphabet representation. Works like column headers in Excel.",
			{[ 	Description = "Column 27", 
				Code 		= "F[Number.ToLetters](27)", 
				Result 		= "AB"	]},
			
			(value as number) =>
				let
					GetLetter = (num as number) => 
						let 
							number = Number.Mod(num, 26),
							val    = if number = 0 then 26 else number,
							valid  = number < 26 and number > 0 
						in 
							if valid 
							then Text.At(Text.Alphabet, val - 1) 
							else error "Can't get letter for " & Text.From(num),
					
					func = (value as number, factor as number) =>
						let
							ThisLetter = GetLetter(Number.RoundDown(value/Number.Power(26, factor))),
							Result = 
								if value <= Number.Power(26, factor) 
								then "" 
								else @func(value, factor+1) & ThisLetter
						in
							Result
				in
					if value <= 26 
					then GetLetter(value) 
					else func(value, 1) & GetLetter(value)	
		),

	Number.Dec2Bin 	 = // 
        /*
            Description:	Function that converts number from decimal to binary notation
            Link:			https://support.office.com/en-us/article/DEC2BIN-function-0f63dd0e-5d1a-42d8-b511-5bf5c6d43838
            Usage:  		Number.Dec2Bin( 1026 )
            Result: 		10000000010
			
			в другом месте было так:
				Number.DecToBin = (num as number)=>
					List.Last(
						List.Generate(
							() =>[	reminder  = num,	
									binString = Number.ToText(Number.BitwiseAnd(reminder,1))
								 ],
							each [	reminder ] > 0,
							each [	reminder  = Number.BitwiseShiftRight([reminder],1),
								  	binString = Number.ToText(Number.BitwiseAnd(reminder,1))&[binString]
								 ],
							each [	binString ]
							))
        */

        (num as number, optional string as nullable text) =>
            let
                input_string = if string = null then "" else string,
                reminder     = Number.Mod( num, 2 ),
                result		 = Text.From( reminder ) & input_string,
                input  		 = Number.IntegerDivide( num, 2 ),
                return = if input > 0 
                         then @Number.Dec2Bin( input , result) // ! Number_Dec2Bin
                         else result
            in
                return,

	Number.HexToDec  = // 
		(hexString as text) => 
			Expression.Evaluate("0x"&hexString),

	//======================== 
	// Splitters
	//======================== 
	Splitter.SplitTextByNonAlpha = // возвращает список букв из любого текста (список символов можно менять) //! пример
		/*
			Пример	
				= F[Splitter.SplitTextByNonAlpha] ("A1B,C") = {"A","B","C"}
				Text.Alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
		*/

		Document(
			"Splitter.SplitTextByNonAlpha",
			"Splits text by characters that aren't [A-Za-z]",
			{[ 	Description = "Split text", 
				Code		= "F[Splitter.SplitTextByNonAlpha](""A1B,C"")", 
				Result 		= "{ ""A"", ""B"", ""C"" }" ]},
			
			(line as text) => 
					Splitter.SplitTextByNotIn( F[Text.Alphabet] )
		),
	
	Splitter.SplitTextByNotIn    = // разбивает текст на любые символы, которые не являются «безопасными» ? символами //! примеры
		/*
			Описание 	Разбивает текст на любые символы, которые не являются «безопасными» символами
			Пример		= F[Splitter.SplitTextByNotIn] (F[Text.Alphanumeric]) ("Power BI is #1")
			Результат	= {"Power BI is ", "1"}
			Безопасные символы = // ?
			Text.Alphanumeric  = Text.AlphabetRu & "0123456789"
		*/
		Document(
			"Splitter.SplitTextByNotIn",
			"Splits text on any characters that aren't the provided 'safe' characters",
			{[ 	Description = "Split on non-alphanumeric", 
				Code 		= "F[Splitter.SplitTextByNotIn](PBI[Text.Alphanumeric])(""Power BI is #1"")", 
				Result 		= "{""Power BI is "", ""1""}" ]},

		(safeCharacters as text) => 
			(line as nullable text) =>
				if   line is null 
				then {} 
				else
					List.Accumulate(
						Text.ToList(line), 
						{null} , 
						(state, current) => 
							let
								doSkip 	 	= not Text.Contains(safeCharacters, current),
								lastItem 	= List.Last(state),
								appendLast 	= lastItem <> null
							in
								if doSkip 
								then 	if lastItem is null 
										then state 
										else List.Combine({state, {null}})
								else if appendLast 
									 then List.Combine( { List.RemoveLastN(state, 1), {lastItem & current} } )
									 else List.Combine( { List.RemoveLastN(state, 1), {current} } )
					)
		),

	//===========================
	// Switch
	//===========================
	Switch    		= // # возвращяет парный элемент из списка списков или пары списков
		/* 	Возвращяет парный элемент из списка
			Пример:
				1. 	to = F[fxSwitch](
							3, 	// Date.Month(DateTime.From(date))
							{1,2,3,4,5,6,7,8,9,10,11,12}, 
							{"Январь","Февраль","Март","Апрель","Май","Июнь","Июль","Август","Сентябрь","Октябрь","Ноябрь","Декабрь"}, 
							null
						) // Return: Март
				2. 	to = F[fxSwitch]("B", { {"A",1}, {"B",2}, {"C",3} })			  // Return: 2
				3. 	to = F[fxSwitch]("TE", {"QB","RB","WR","TE","D/ST"}, {1,2,3,4,5}) // Return: 4
				4. 	to = F[fxSwitch](
							Date.DayOfWeek(DateTime.From("03/05/24")), // число
							{0, 1, 2, 3, 4, 5, 6}, 
							{"Воскресенье", "Понедельник", "Вторник", "Среда", "Четверг", "Пятница", "Суббота"}, 
							null
						)
				1.	Сделать пример через List.Zip
		*/
		(	value as any, 							// что искать
			casesOrPairs as list, 					// где искать, список списков или 2 списка через ",". Можно через List.Zip словарь сделать
			optional resultsOrDefault as any, 		// что возвращать
			optional default as any					// если ошибка
		) =>
		let
			hasPairs   = List.First(casesOrPairs) is list,
			usingPairs = 
				let
					targetPosition = 
						List.PositionOf(
							casesOrPairs, 
							value, 
							Occurrence.First, 
							(case, theValue) => theValue = case{0}
						)
				in
					if targetPosition = -1 
					then resultsOrDefault 
					else casesOrPairs{targetPosition}{1},
			usingCases = 
				let
					cases = casesOrPairs,
					results = resultsOrDefault
				in
					if List.IsEmpty(cases) or List.IsEmpty(results) 
					then default 
					else 	if value = List.First(cases) 
							then List.First(results) 
							else @Switch(value, List.Skip(cases, 1), List.Skip(results, 1), default)
		in
			if hasPairs then usingPairs else usingCases,
	
	Switch.Record 	= // вручную если подставлять, через Record.FieldOrDefault
        	[ func = (КодРегиона as text) => 
                Record.FieldOrDefault(
                    [1 = "Брест", 2 = "Витебск", 3 = "Гомель", 
					 4 = "Гродно", 5 = "Минск", 6 = "Могилев", 0 = "БКС"], 
                    КодРегиона, 
                    null
			    )
        	] [func],
	Switch.DAX    	= // замена значения в ячейке (вся ячейка). Аналог реализации SWITCH в DAX
		/*	
			Описание:	замена значения в ячейке (вся ячейка). Могут быть логические переменные
						Первый элемент списка - проверяемое значение, далее идут пары, последним все остальные значения
			Результат:	любое значение из таблицы подстановки
			Сайт: 		https://xxlbi.com/blog/switch-true-in-power-query/
			Пример:	1.	= Switch.DAX(
							{	2, 
								1, "A", 
								2, "B"}
							), 							=> Result = "B"
			
					2.	= Switch.DAX(
							{	"b", 
								"a", "first", 
								"b", "second", 
								"c"}
							)						=> Result = "second"
					
					3.	= Switch.DAX(
							{	true, 
								1 > 2, "first", 
								0 = 1, "second", 
								"other"}
							)						=> Result = "other"
					
					4.  = F[Switch.DAX](
							{	true, 
								List.ContainsAny(from[АКТИВЫ],{"запасы"}, Text.Contains), "Есть такое слово",
								"Нет такого"
							})
		*/
		[func = 
			(input as list) as any =>
				let
					Source         = List.Buffer(input),
					Expression     = List.First(Source),
					SkipExpression = List.Skip(Source),
					HasElse        = Number.IsEven(List.Count(Source)),
					ElseValue      = if HasElse then List.Last(Source) else null,
					ValuesResults  = List.RemoveLastN(SkipExpression, Number.From(HasElse)),
					Values         = List.Alternate(ValuesResults, 1, 1, 1),
					Results        = List.Alternate(ValuesResults, 1, 1, 0),
					FirstResult    = List.PositionOf(Values, Expression),
					FunctionResult = if FirstResult = -1 then ElseValue else Results{FirstResult}
				in
					FunctionResult,
			
			fnType = type function (input as list) as any
				meta [
					Documentation.Name = "Switch",
					Documentation.LongDescription = "Evaluates an expression against a list of values and returns one of multiple possible result expressions.",
					Documentation.Examples = {
						[Description = "Simple Switch expression", Code = "Switch({2, 1, ""A"", 2, ""B""})", Result = """B"""],
						[Description = "An equivalent of SWITCH(TRUE... in DAX", Code = "Switch({true, 1 > 2, ""A"", 1 < 2, ""B"", ""No result""})", Result = """B"""]
					}
				],
			result = Value.ReplaceType(func, fnType)
		][result],
		
	Switch.Lite   	= // надо доделать
		(input) => 
		let values = {	{"E", "Employee"}, 
						{"S", "SCYC"}, 
						{"M", "Medical"},
						{input, "Undefined"} 
					}, 
			Result = List.First(List.Select(values, (x)=> x{0}=input)){1} 
		in  Result,
	
	
	//===========================
	// Table
	//===========================
	// основные
	Table.AddBlankRow 		 = 
		// 
		(table as table) => Table.Combine({table, Table.FromRecords({[]})}),
	
	Table.DrillIntoColumn 	 = 
		/*
			Transforms a column's value into its nested value -- if it eventually finds only one. 
			Consider the following column:
				MyCol
				---------------------------------------------------------
				"a"
				{{{"b"}}}
				Table.FromRecords({[MyCol=Table.FromRecords({[col=2]})})
				{}
				---------------------------------------------------------
			
			Table.DrillColumn(table, "MyCol") will convert it to
				MyCol
				---------------------------------------------------------
				"a"
				"b"
				2
				null	
				---------------------------------------------------------
		*/
		(table as table, columnName as text) =>
		let
			FindValue = (value as any) => 
				if value is list 
				then
					if List.Count(value) = 1 
					then @FindValue(List.First(value)) 
						else if List.Count(value) = 0 
							 then null
							 else error "Couldn't find single value"
						else if value is table 
						then
							if Table.RowCount(value) = 1 
							then @FindValue(List.First(Table.ToColumns(value)))
							else if Table.RowCount(value) = 0 
								then null 
								else error "Couldn't find single value"
								else  value,
			Result = Table.TransformColumns(table, {{columnName, FindValue}})
		in
			Result,
	Table.ConcatenateRows 	 = // добавляет вправо все столбцы из таблицы B в таблицу A (со значениями) 
		/*
			Описание	Добавьте все столбцы из таблицы B в таблицу A (со значениями)
			Особенность	1 Имена столбцов не должны совпадать
						2 Строки добавляются по индексу
						3 Вместо пустых значений будет 0
			Пример		= F[Table.ConcatenateRows](table1,table2)
			Результат	
		*/
		(tableA as table, tableB as table) =>
			let
				IndexColumn = [
					A = "__IndexA__",
					B = "__IndexB__"
				],
				Indexed = [
					A = Table.AddIndexColumn(tableA, IndexColumn[A], 0, 1),
					B = Table.AddIndexColumn(tableB, IndexColumn[B], 0, 1)
				],
				
				Join = Table.Join(
					Indexed[A],
					IndexColumn[A],
					Indexed[B],
					IndexColumn[B],
					JoinKind.LeftOuter
				),
				Return = Table.RemoveColumns(Join, Record.FieldValues(IndexColumn))
			in
				Return,	
		
	Table.EnterDataFormula 	 = 
		Document(
			"Table.EnterDataFormula",
			"Convert a table into a formula that's compatible with the Enter Data UI. This function returns an expression you can copy and paste to editthe " &
				" table using Enter Data. Paste the formula, then click the gear icon next to the step name. This is an easy way to allow people to customize a table you've queried",
			{[ 
				Description = "Simple table", 
				Code 		= "Web.Page(Web.Contents(""https://en.wikipedia.org/wiki/List_of_Super_Bowl_champions"")){3}[Data]", 
				Result 		= "Table.FromRows(Json.Document(Binary.Decompress(Binary.FromText(""jVVtb9s2EP4rRD4aRqI3S9TH2Gm7ZWkb1MGGom6Aq83IhBkyoOik2a8fT6Ski6Fu+yDdWea9Pffc8du3M342P7uVzrU/jrbZs7UTQgnb+q+lfzL/nFeLxIu0ror55pglWcK8viA6J3o96vVwJksSqvNRT5Ognn2fh1yuQClo2cq8/DCvmMbCPzmmUWaLkEYyn2GkNIhFEFUQvBN1FkQexGI2uP8kXtg73SjQO3YLzkrjMEgRn/NFEmrlpL66JLmnRM+JXhC9IvWR82lxWqvQz8KypTV6a9pYJxZ5nlex1mpMg5dEp98p5OR7TWEmqaYLkgY2eQ2avbegt7LdGlbUof1dApgLz/MASQCcF0EEpH3wDuJiNkfXWUAabT9YITRbwqvHeXsIPovBZ4S5jDWl3kdZjbqHfBbKmXUkGd1iA78ae2AfJGg36ZRH46QzTqKIrtLR1Wc4IA82FzemZZe68cRv2ReQu5Bs3vO/7JOt5kixEt886d45Vp1kg8u/oN1L3Tij2Rexaw9ST3qqAj95FIGmPFC4Jhl+lPAo2ZVRT/vgKeuHoeg9pWT2MqLnhCDkO6ccROSWoJx8NFZsLn7XO48pPBklcQCV6yNmdDJKPrbJj+LIejol9UmUj1Jr0RoH7E/pQWnQc9LPXNJ7ronngEkVyFaVszHh48MDKMOWUqlJN3VCZoDAUxMY6pwkiIASCmwu1u6c3ZijRDY8tpFeHQh5nIUq0r4O3Iotw//WApxTgnm5h5fDhHW3DGdhKDtRBOuMdsNHfhZDy7vCYoEdo8dhzkghePQP0C3uT+le2WovxUOfQfqmieX8Hkeuvh8M/eEtNB5XAXbShoesk3JM93YvFewE0hPYO2g8ejHbjHaExxEkha6kXzdag5M+oG5ATRuS9nF+UukKrGeqBr9ftNuHmT3xgDs6LKZ4BaR0g1wL1xdKAUaK3w+n7+DxCbo1tjxut6CFsFNGuAXehvhslfC9YGuQejIOjslogkv4SgrfgNUebDOWk77hNh1f/OfS+RXmx+o9qK3R0zZ8jHIncA5bIdiddPCL8/VpDCv/Nh5nD/jO460mrPBSD1Hw10qJZ9Fdsf5qexmi4IOuUxzXT5uLy8HgSjhrpGM30vyP09f+PmmNfvYLQLBraI5g/9voN3NscS3fiZ/wbzG+/wM="", BinaryEncoding.Base64), Compression.Deflate)), let _t = ((type text) meta [Serialized.Text = true]) in type table [Appearances = _t, Team = _t, Wins = _t, Losses = _t, Winning percentage = _t, Season(s) = _t])"
			]},
			(table as table) =>
				let
					Encoded    = Table.JsonEncode(table),
					ColumnMeta = "[" & 
								 Text.Range(
									List.Accumulate(
										Table.ColumnNames(table), 
										"", 
										(state, current) => state & ", " & current & " = _t"),
										2) 
								 & "]",
					Text = 	"Table.FromRows(Json.Document(Binary.Decompress(Binary.FromText(""" & Encoded & """, BinaryEncoding.Base64), Compression.Deflate))," & 
							" let _t = ((type text) meta [Serialized.Text = true]) in type table " & ColumnMeta & ")"
				in
					Text
		),
	
	Table.ExpandRecordColumn = //* хорошая
		(	table as table, 
			columnName as text, 
			optional fieldNames as list, 
			optional newColumnNames as nullable list
		) => 
		
		// if fieldNames aren't specified, use the field names from the first row of the column.
		
		let
			_fieldNames = 	if fieldNames <> null 
							then fieldNames 
							else List.Buffer(Record.FieldNames(List.First(Table.Column(table, columnName)))),
			
			_newColumnNames = 	if newColumnNames <> null 
								then newColumnNames 
								else _fieldNames,
			
			Result = Table.ExpandRecordColumn(table, columnName, _fieldNames , _newColumnNames)
		in 
			Result,

	Table.FromListCrossJoin  = 
		/* 
			Perform a cross join of lists. Example usage:
			Table.FromListCrossJoin({ {ColorsTable[ColorName], "Color"}, {NumbersTable[Number], "Number"}})
			Will give me a new table with two columns, "Color" and "Number" which contains one row for each possible
			combination of colors and numbers
			Table.FromListCrossJoin({{"Red", "Blue"}, "Color"}, {{1,2,3}, "Number"}}) = 
			Table.FromRecords({[Color="Red", Number=1],[Color="Red", Number = 2],[Color="Red", Number = 3],[Color="Blue", Number=1],[Color="Blue", Number=2],[Color="Blue", Number=3]})
		*/
		(listColumnNamePairs as any) =>
			let 
				remainingPairs 	= List.Skip(listColumnNamePairs, 1),
				current 		= List.First(listColumnNamePairs),
				theList 		= List.First(current),
				columnName 		= List.First(List.Skip(current),1),
				firstTable 		= Table.FromList(theList, null, {columnName}),
				doStuff = (table as table, remainingPairs as list) =>
					if List.Count(remainingPairs) <= 0 
					then table 
					else	let 
								current = List.First(remainingPairs),
								theList = List.First(current),
								columnName = List.First(List.Skip(current), 1),
								nextTable = Table.ExpandListColumn(Table.AddColumn(table, columnName, each theList), columnName)
							in 
								@doStuff(nextTable, List.Skip(remainingPairs, 1)),
				Result = doStuff(firstTable, remainingPairs)
			in
				Result,
	
	Table.JsonEncode 		 = // # кодирует таблицу в двоичный формат (без заголовков)
		(table as table) =>
		let
			Rows 		= Table.ToRows(table),
			Json 		= Json.FromValue(Rows),
			Compressed 	= Binary.Compress(Json, Compression.Deflate),
			Encoded 	= Binary.ToText(Compressed, BinaryEncoding.Base64)
		in
			Encoded,
	Table.JsonDecode 		 = // # декодирует таблицу из двоичного формата (2 столбца)
		// 
		(encoded as text) =>
		let
			Decompressed = Binary.Decompress(Binary.FromText(encoded, BinaryEncoding.Base64), Compression.Deflate),
			Decoded 	 = Table.FromRows(Json.Document(Decompressed), 
								let _t = ( (type text) meta [Serialized.Text = true] ) 
								in 	type table [Name = _t, Number = _t])
		in
			Decoded,

	Table.JsonEncodeWithHead = // # кодирует таблицу в двоичный формат (с заголовками и типами) ⚡
		(table as table) =>
		let
			ColumnNames = Table.ColumnNames(table),
			ColumnTypes = Table.Schema(table)[TypeName], // Сохраняем типы данных как типы (текст!)
			Rows 		= Table.ToRows(table),
			DataWithTypes = List.Transform(Rows, each List.Zip({ColumnNames, _})),
			
			Json 		= Json.FromValue([ColumnNames=ColumnNames, ColumnTypes=ColumnTypes, Data=DataWithTypes]),
			Compressed 	= Binary.Compress(Json, Compression.Deflate),
			Encoded 	= Binary.ToText(Compressed, BinaryEncoding.Base64)
		in
			Encoded,
			
	Table.JsonDecodeWithHead = // # декодирует таблицу из двоичного формата (с заголовками и типами) ⚡
		(encoded as text) =>
		let
			//	Декодируем base64
				DecodedBinary = Binary.FromText(encoded, BinaryEncoding.Base64),
				Decompressed  = Binary.Decompress(DecodedBinary, Compression.Deflate),
				Json 		  = Json.Document(Decompressed),

			// 	Извлекаем названия столбцов и их типы
				ColumnNames = Json[ColumnNames],
				ColumnTypes = Json[ColumnTypes],
				DataRows 	= Json[Data],

			// 	Преобразование строковых представлений типов данных в объекты типа `type`
				// сделать больше вариантов типов или прикрутить функцию типа Value
				TypeTextToType = (typeString as text) =>
					Record.FieldOrDefault(
						[	Number.Type 	= type number,
							Text.Type 		= type text,
							Date.Type 		= type date,
							DateTime.Type 	= type datetime,
							Time.Type 	    = type time,
							Logical.Type 	= type logical,
							Duration.Type   = type duration,
							Int64.Type 		= type number
						], 
							typeString, type any
					),

			//	Список типов колонок
				ColumnTypesList = List.Transform(ColumnTypes, each TypeTextToType(_)),

			// 	Преобразование данных в записи
				ConvertRowToRecord = (row as list) =>
					Record.FromList(List.Transform(row, each _{1}), ColumnNames),

			// 	Преобразование всех данных в записи
				RecordsList = List.Transform(DataRows, each ConvertRowToRecord(_)),
				DataTable 	= Table.FromRecords(RecordsList),

			// 	Применение типов данных к столбцам
				ApplyTypes = Table.TransformColumnTypes(
								DataTable, 
								List.Zip({ColumnNames, ColumnTypesList})
							 ),
			
			// 	Функция преобразования столбца "Date" со значением типа 2020-12-31T00:00:00 
			//	в тип `date` и формат вида "ДД.ММ.ГГГГ"
			
				ConvertDateColumn = (table as table) =>
					let
						ColumnName 	 = "Date",
						ColumnExists = Table.HasColumns(table, {ColumnName}),
						UpdatedTable = if ColumnExists then
							Table.TransformColumns(table, {
								{ColumnName, each 
									try if Text.Contains(_, "T") 
										then Date.From(Date.ToText(Date.FromText(Text.BeforeDelimiter(_, "T")), "dd.MM.yyyy"))
										else _ 
									otherwise _
									, type date}
							})
						else
							table
					in
						UpdatedTable,

			// 	Применяем преобразование к таблице
				FinalTable = ConvertDateColumn(ApplyTypes)
		in
			FinalTable,

	Table.MoveColumnsToStart = // # перемещает колонку или список колонок в начало таблицы 
		// = F[Table.MoveColumnsToStart](from,{"Year"})
		// (x, y) => Table.ReorderColumns(x, y & List.RemoveItems(Table.ColumnNames(x), y)),
		(tbl as table, columnNames as list) =>
			Table.ReorderColumns(
				tbl,
				columnNames & List.RemoveItems(Table.ColumnNames(tbl), columnNames)
			),

	Table.MoveColumnsToEnd 	 = // # перемещает колонку или список колонок в конец таблицы
		// = F[Table.MoveColumnsToEnd](from,{"Year"})
		(tbl as table, columnNames as list) =>
			Table.ReorderColumns(
				tbl, 
				List.RemoveItems(Table.ColumnNames(tbl), columnNames) & columnNames
			),
	Table.NumberColumns		 = // # преобразует колонку в number тип и заменяем 0 на null
		/*
			Описание 	Преобразовывает колонку в number тип и заменяем нули null
			Преобразуйте тип выбранных столбцов в число, замените нулевые значения нулями.
		*/
		(table as table, columns as list) as table =>
		let
			NumberTypes   = List.Repeat({type number}, List.Count(columns)),
			DataWithTypes = Table.TransformColumnTypes(table, List.Zip({columns, NumberTypes})),
			NumberNotNull = (number) => if number is null then 0 else number,
			DataNoNulls   = Table.TransformColumns(
				DataWithTypes,
				List.Zip({
					columns,
					List.Repeat({NumberNotNull}, List.Count(columns)),
					NumberTypes
				})
			),
			Return = DataNoNulls
		in
			Return
		,
	Table.ReplaceValueIf	 = // Replaces a value if it matches a predicate
		
		(table as table, replaceIf as function, after as any, columnNameOrList as any) => 
		Table.ReplaceValue( table, 
			null, 
			after, 
			(text, old, new)=> 
				if replaceIf(text) 
				then new 
				else text, 
			if columnNameOrList is list 
				then columnNameOrList 
				else {columnNameOrList}
		),

	
	Table.SplitColumnNames 	 = // Splits camelCased and PascalCased column names. 	
		
		(table as table) => 
			Table.RenameColumns(
				table, 
				List.Transform(
					Table.ColumnNames(table), 
					each {_, Text.SplitCamelCase(_)}
				)
			), 
	
	Table.SplitColumnText 	 = // Splits camelCased and PascalCased text in a column. 
		(table as table, columns as list) => 
			if List.Count(columns) = 0 
			then table 
			else Table.TransformColumns(
					@Table.SplitColumnText(
							table, 
							List.Skip(columns, 1)
						),
					{{List.First(columns), Text.SplitCamelCase}}
				),

	Table.TransformColumn 	 = // * пример использования придумать
		// 
		(table as table, column as text, transform as function) => 
			Table.TransformColumns(table, {{column, transform}}),

	Table.RenameColumn 		 = // * переименование колонок ? проверить
		// Пример:	Table.RenameColumn(from,)
		(table as table, column as text, newName as text) => 
			Table.RenameColumns(table, {{column, newName}}),

	Table.RenameAndTransformColumn = 
		(table, currentName as text, newName as text, transform as function) => 
			Table.TransformColumn(
				Table.RenameColumns(table, {currentName, newName}), 
				newName, 
				transform
			),

	// дополнительные
	Table.AddScrape          = // добавляет столбец с полученными результатами, Table.AddColumn() + Web.Contents()
        /*
            Description:
                Add a column based on sequentially scraped results to a table. It's like Table.AddColumn() + Web.Contents(), except combining those directly would rape the server rather than inserting proper politeness delays.
                Добавьте в таблицу столбец на основе последовательно полученных результатов. 
                Это похоже на Table.AddColumn() + Web.Contents(), за исключением того, что их объединение 
                напрямую приведет к изнасилованию сервера, а не к вставке надлежащих задержек из вежливости.

            Usage:
                let
                    Web.AddScrape = Load("Web.AddScrape"),
                    BaseUrl = "http://example.com/?p=",
                    Pages = List.Numbers(1, 5),
                    Tbl = Table.FromList(Pages),
                in
                    Web.AddScrape(Tbl, "Value", BaseUrl)
            Result: 
                [a table with the response bodies of the URLs with the given variables added into a new column]
                [таблица с телами ответов URL-адресов с заданными переменными, добавленными в новый столбец]
        */

        (
            Tbl as table,                   //the table in question to add scrape results to
            Col as text,                    //the column of variable content to append to the base URL
            BaseUrl as text,                //the base URL
            optional newColName as text,    //the name of the new column to be added, default Content
            optional Delay as number,       //in seconds, default 1
            optional Encoding as number,    //https://msdn.microsoft.com/en-us/library/windows/desktop/dd317756(v=vs.85).aspx
            optional Options                //see options in Web.FetchSequentially
        ) as table =>
        let
            newColName = if (newColName<>null) then newColName else "Content",
            Web.FetchSequentially = Load("Web.FetchSequentially"),

            InputList     = Table.Column(Tbl, Col),
            DedupedList   = List.Distinct(InputList),
            InputUrls     = List.Transform(DedupedList, each BaseUrl & Expression.Constant(_)),
            ScrapedList   = Web.FetchSequentially(InputUrls, Delay, Encoding, Options),
            ScrapedRecord = Record.FromList(ScrapedList, DedupedList),
            Merged        = Table.AddColumn(Tbl, newColName, each Record.Field(ScrapedRecord, Record.Field(_, Col))),
            Buffered      = Table.Buffer(Merged),
            Return        = Buffered
        in
            Return,

    Table.CrossJoin          = // возвращает перекрестное соединение двух аргументов (могут быть списками или таблицами) 
        /*
            Returns the Cartesian product (i.e. crossjoin) of two arguments (can be lists or tables).
            Возвращает декартово произведение (т. е. перекрестное соединение) двух аргументов (могут быть списками или таблицами).
            
            Usage:
                Table.CrossJoin = Load("Table.CrossJoin"),
                Table.CrossJoin({"A","B"},{1..3})	//list version
                TableA = #table({"A"},{{"A"},{"B"}}),
                TableB = #table({"B"},{{1},{2},{3}}),
                Table.CrossJoin(TableA, TableB)		//table version
            
            Result: 
                #table({"A","B"},{{"A",1},{"A",2},{"A",3},{"B",1},{"B",2},{"B",3}})
        */

        (A as any, B as any) as any =>
        let
            TableA  = if A is table then A else Table.FromValue(A),
            TableB  = if B is table then B else Table.FromValue(B),
            Renamed = if Table.HasColumns(TableA, "Value")
                      then Table.RenameColumns(TableA, {"Value", "Original"})
                      else TableA,
            Merged  = Table.AddColumn(Renamed, "Table", each TableB),
            ColumnsToExpand = List.Distinct(List.Combine(List.Transform(Table.Column(Merged, "Table"), each if _ is table then Table.ColumnNames(_) else {}))),
            Expand  = Table.ExpandTableColumn(Merged, "Table", ColumnsToExpand)
        in
            Expand,

    Table.CrossJoin2         = 1// развивает Table.CrossJoin с помощью UdfContents и прочего 
        // let
        //     Table.CrossJoin = Load("Table.CrossJoin"),
        //     Tokens    = Table.RenameColumns(Table.FromList(Record.FieldNames(#shared)), {"Column1", "Token"}),
        //     AddAlts   = Table.AddColumn(Tokens, "TokenAlt", each Text.Replace([Token], "_", ".")),
        //     Crossed   = Table.CrossJoin(AddAlts, UdfContents),
        //     Contained = Table.AddColumn(Crossed, "Contains", each Text.Contains([Contents], [Token]) or Text.Contains([Contents], [TokenAlt])),
        //     Filtered  = Table.SelectRows(Contained, each [Contains]),
        //     FiltCols  = Table.SelectColumns(Filtered, {"Token", "TokenAlt", "Name"}),
        //     Return    = FiltCols
        // in
        //     Return
			,
    
    Table.CrossJoinTables    = // перекрестное объединение списка таблиц в таблицу, содержащую все комбинации строк 
        /*
            Cross-join a list of tables into one super table containing every combination of rows of its constituents
            Перекрестное объединение списка таблиц в одну супертаблицу, содержащую все комбинации строк ее составляющих.
            Usage:
                Table.CrossJoinTables = Load("Table.CrossJoinTables"),
                Table.CrossJoinTables({
                    #table({"A","B"},{{"A",1},{"B",2}}),
                    #table({"C","D"},{{"E",3},{"F",4}})
                })
            Result: 
                a cross-joined version of all the tables. beware of performance, the result could get big!
                перекрестно-соединенная версия всех таблиц. Медленно!
        */

        (   tables as list,
            optional TableNames as list,        // names to append as prefixes on clash or if desired, default {1, 2, 3, ...}
            optional AlwaysPrefix as logical    // whether to use append table names if without column name clashes
        ) as table => 
        let
            CrossJoin = List.Accumulate(
                List.Positions(tables),
                #table({},{}), 
                (state, current) => 
                    let
                        CurrentTable = tables{current}, // need check for table type?
                        CurrentNames = Table.ColumnNames(state),
                        OldNames     = Table.ColumnNames(CurrentTable),
                        Prefix = if TableNames <> null 
                                then try TableNames{current} otherwise Text.From(current+1) 
                                else Text.From(current+1),
                        NewNames = 
                            List.Transform(
                                OldNames, 
                                each if AlwaysPrefix or List.Contains(CurrentNames, _) 
                                    then Prefix & "_" & _ 
                                    else _
                            ),
                        Renamed = Table.RenameColumns(CurrentTable, List.Zip({OldNames, NewNames}))
                    in
                        Table.Join(state, {}, Renamed, {}, JoinKind.FullOuter)
                )
        in
            if List.IsEmpty(tables) 
            then #table({},{}) 
            else CrossJoin,
 
    Table.ExpandAll          = // полностью раскрывает любые вложенные записи и таблицы внутри таблицы 
        /*
            Полностью раскрывает любые вложенные записи и таблицы внутри таблицы.
            https://cwebbbi.wordpress.com/2014/05/21/expanding-all-columns-in-a-table-in-power-query/
            
            Usage:
                Table.ExpandAll = Load("Table.ExpandAll"),
                xml = Xml.Tables("<books><book><name>Book1</name><pages><page>1</page><page>2</page><page>3</page></pages></book><book><name>Book2</name><pages><page>1</page><page>2</page><page>3</page></pages></book></books>"),
                Table.ExpandAll(xml)	//, null, true
            
            Result: 
                [расширенная версия данной таблицы с вложенными записями/таблицами]
        */

        (
            TableToExpand as table,					//the table you wish to expand
            optional ColumnNumber as number,		//the column number to expand
            optional AppendParentNames as logical	//whether to use append parent column names e.g. "ul.li", or just keep "li" where possible (reverting to the qualified name in case of a colum name clash)
        ) as table =>
        let
            ColumnNumber = if (ColumnNumber=null) then 0 else ColumnNumber,
            AppendParentNames = if (AppendParentNames=null) then false else AppendParentNames
        in

        List.Last(
            List.Generate(
                ()=>[ col = ColumnNumber,
                    Tbl = TableToExpand ],
                each [col]<=(Table.ColumnCount([Tbl])-1),
                each 
                    let ColumnNames = Table.ColumnNames([Tbl]),
                        ColumnName 	= ColumnNames{[col]},
                        ColumnsToExpand = List.Distinct(List.Combine(List.Transform(Table.Column([Tbl], ColumnName),
                            each if _ is table then Table.ColumnNames(_) else {}))),
                        NewColumnNames = List.Transform(ColumnsToExpand, each if (AppendParentNames or List.Contains(ColumnNames,_)) then ColumnName & "." & _ else _),
                        CanExpandCol   = List.Count(ColumnsToExpand)>0
                    in [Tbl = 	if CanExpandCol
                                then Table.ExpandTableColumn([Tbl], ColumnName, ColumnsToExpand, NewColumnNames)
                                else [Tbl],
                        col = 	if CanExpandCol
                                then [col]
                                else [col]+1 ],
                each [Tbl]
            )
        ),

    Table.ExpandRecords      = // полностью раскрывает любые вложенные записи в таблице 
        /*
            Полностью раскрывает любые вложенные записи в таблице.
            https://cwebbbi.wordpress.com/2014/05/21/expanding-all-columns-in-a-table-in-power-query/
            
            Usage:
                tbl = Table.FromColumns({ {1}, {[c=0,d=2]} }, {"a", "b"}),
                Table.ExpandRecords(tbl)    //, null, true
            
            Result: 
                [расширенная версия данной таблицы с вложенными записями]
        */

        (   TableToExpand as table,                  // the table you wish to expand
            optional ColumnNames as list,            // the columns to expand
            optional AppendParentNames as logical    // whether to use append parent column names e.g. "ul.li", or just keep "li" where possible (reverting to the qualified name in case of a colum name clash)
                                                     // использовать ли добавление имен родительских столбцов, например. "ul.li", 
                                                     // или просто оставьте «li», где это возможно (возвращаясь к полному имени в случае конфликта имен столбцов)   
        ) as table =>                                
        let
            ColumnNames = if (ColumnNames=null) then Table.ColumnNames(TableToExpand) else ColumnNames,
            count       = List.Count(ColumnNames),
            AppendParentNames = if (AppendParentNames=null) then false else AppendParentNames
        in
            List.Accumulate(ColumnNames, TableToExpand, (tbl, col) => 
                let
                    ColumnsToExpand = 
                        List.Distinct(
                            List.Combine(
                                List.Transform(
                                    Table.Column(tbl, col),
                                    each if _ is record then Record.FieldNames(_) else {}
                                )
                            )
                        ),

                    NewColumnNames = 
                        List.Transform(
                            ColumnsToExpand, 
                            each if (AppendParentNames or List.Contains(ColumnNames,_)) then col & "." & _ else _
                        ),

                    CanExpandCol = List.Count(ColumnsToExpand) > 0
                in  
                    if CanExpandCol
                    then Table.ExpandRecordColumn(tbl, col, ColumnsToExpand, NewColumnNames)
                    else tbl
        ),

    Table.ExpandTables       = // полностью раскрывает любые вложенные таблицы внутри таблицы 
        /*
            Полностью раскрывает любые вложенные таблицы внутри таблицы.
            https://cwebbbi.wordpress.com/2014/05/21/expanding-all-columns-in-a-table-in-power-query/
           
            Usage:
                Table.ExpandTables = Load("Table.ExpandTables"),
                xml = Xml.Tables("<books><book><name>Book1</name><pages><page>1</page><page>2</page><page>3</page></pages></book><book><name>Book2</name><pages><page>1</page><page>2</page><page>3</page></pages></book></books>"),
                Table.ExpandTables(xml)    //, null, true
            
            Result: 
                [расширенная версия данной таблицы с вложенными таблицами]
        */

        (
            TableToExpand as table,                 // the table you wish to expand
            optional ColumnNames as list,           // the columns to expand
            optional AppendParentNames as logical   // whether to use append parent column names e.g. "ul.li", or just keep "li" where possible (reverting to the qualified name in case of a colum name clash)
        ) as table =>
        
        let
            ColumnNames = if (ColumnNames=null) then Table.ColumnNames(TableToExpand) else ColumnNames,
            count       = List.Count(ColumnNames),
            AppendParentNames = if (AppendParentNames=null) then false else AppendParentNames
        in
            List.Accumulate(ColumnNames, TableToExpand, (tbl, col) => 
                let
                    ColumnsToExpand = List.Distinct(List.Combine(List.Transform(Table.Column(tbl, col), each if _ is table then Table.ColumnNames(_) else {}))),
                    NewColumnNames  = List.Transform(ColumnsToExpand, each if (AppendParentNames or List.Contains(ColumnNames,_)) then col & "." & _ else _),
                    CanExpandCol    = List.Count(ColumnsToExpand) > 0
                in 
                    if CanExpandCol
                    then Table.ExpandTableColumn(tbl, col, ColumnsToExpand, NewColumnNames)
                    else tbl
            ),

    Table.ExpandTablesRecursive = // полностью раскрывает любые вложенные таблицы внутри таблицы
        /*
            Fully expands any nested tables within a table
            Полностью раскрывает любые вложенные таблицы внутри таблицы.
            
            Originally written by Chris Webb: 
            https://cwebbbi.wordpress.com/2014/05/21/expanding-all-columns-in-a-table-in-power-query/
            
            Usage:
                Table.ExpandTablesRecursive = Load("Table.ExpandTablesRecursive"),
                xml = Xml.Tables("<books><book><name>Book1</name><pages><page>1</page><page>2</page><page>3</page></pages></book><book><name>Book2</name><pages><page>1</page><page>2</page><page>3</page></pages></book></books>"),
                Table.ExpandTablesRecursive(xml)    //, null, true
            
            Result: 
                [an expanded version of the given table with nested tables]
        */

        (   TableToExpand as table,                 // the table you wish to expand
            optional ColumnNumber as number,        // the column number to expand
            optional AppendParentNames as logical   // whether to use append parent column names e.g. "ul.li", or just keep "li" where possible (reverting to the qualified name in case of a colum name clash)
        ) as table =>
        let
            ColumnNumber        = if (ColumnNumber=null) then 0 else ColumnNumber,
            AppendParentNames   = if (AppendParentNames=null) then false else AppendParentNames
        in
            List.Last(
                List.Generate(
                    ()=>[
                        col = ColumnNumber,
                        Tbl = TableToExpand
                    ],
                    each [col]<=(Table.ColumnCount([Tbl])-1),
                    each 
                        let
                            ColumnNames     = Table.ColumnNames([Tbl]),
                            ColumnName      = ColumnNames{[col]},
                            ColumnsToExpand = List.Distinct(List.Combine(List.Transform(Table.Column([Tbl], ColumnName), each if _ is table then Table.ColumnNames(_) else {}))),
                            NewColumnNames  = List.Transform(ColumnsToExpand, each if (AppendParentNames or List.Contains(ColumnNames,_)) then ColumnName & "." & _ else _),
                            CanExpandCol    = List.Count(ColumnsToExpand)>0
                        in 
                            [   Tbl = if CanExpandCol
                                    then Table.ExpandTableColumn([Tbl], ColumnName, ColumnsToExpand, NewColumnNames)
                                    else [Tbl],
                                col = if CanExpandCol
                                    then [col]
                                    else [col]+1
                            ],
                    each [Tbl]
                )
            ),

    Table.FromString         = // создает пустую таблицу с заголовками, представленными в строке с разделителями
        /* */
        (String as text, Separator as text) => 
            Table.PromoteHeaders( 
                Table.Transpose( 
                    Table.FromList( 
                        Text.Split( String, Separator ) 
                    ) 
                ) 
            ),

    Table.JoinMany           = // объединение 3+ таблиц одновременно
        /*
            Join 3+ tables at once
            Присоединяйтесь к 3+ таблицам одновременно

            Usage:
                Table.JoinMany = Load("Table.JoinMany"),
                TableA = #table({"country","language"},{{"US", "English"},{"Netherlands", "Dutch"},{"Japan", "Japanese"}}),
                TableB = #table({"country","continent"},{{"US", "Americas"},{"Netherlands", "Europe"},{"Japan", "Asia"}}),
                TableC = #table({"country","population"},{{"US", 316148990},{"Netherlands", 16770000},{"Japan", 127600000}}),
                Table.JoinMany({TableA,TableB,TableC},"country")	//,{"lang","cont","pop"}
            
            Result: 
                #table(
                    {"country","language","continent","population"},
                    {
                        {"US",          "English",  "Americas", 316148990   },
                        {"Netherlands", "Dutch",    "Europe",   16770000    },
                        {"Japan",       "Japanese", "Asia",     127600000   }
                    }
                )
        */

        (   tables as list,							//the tables you wish to join
            key as any,								//the key(s) to join them by, either as single string or as a list with 1 key per table
            //names as list,						//names of the tables used for prefixing identically named columns
            optional joinKind as nullable number	//how to join the tables: JoinKind.Inner (default), JoinKind.LeftOuter, JoinKind.RightOuter, JoinKind.FullOuter, JoinKind.LeftAnti, JoinKind.RightAnti
        ) as table =>
        let
            joinKind = if (joinKind=null) then JoinKind.Inner else joinKind,
            count    = List.Count(tables),
            Combined = List.Last(
                List.Generate(
                    ()=>[
                        i = 1,
                        Tbl = tables{0}
                    ],
                    each [i]<=count,
                    each let
                        i1 = [i]-1,		//index
                        i2 = [i],
                        n1 = "JoinCol1",	//names{i1},	//table name for prefixing
                        n2 = "JoinCol2",	//names{i2},
                        k1 = if key is list then key{i1} else key,	//column key
                        k2 = if key is list then key{i2} else key,
                        key1 = n1 & "." & k1,	//qualified key (because PQ Join doesn't allow joining tables with identical column names)
                        key2 = n2 & "." & k2,
                        t1 = [Tbl],
                        t2 = tables{i2},
                        tab1 = Table.RenameColumns(t1,{k1,key1}),
                        tab2 = Table.RenameColumns(t2,{k2,key2}),
                        Merged = Table.Join(tab1, key1, tab2, key2, joinKind),
                        AddCol = Table.AddColumn(Merged, k2, each let
                                r1 = Record.Field(_,key1),
                                r2 = Record.Field(_,key2)
                            in if r1 = null then r2 else r1),
                        Removed = Table.RemoveColumns(AddCol, {key1, key2})
                    in [
                        Tbl = Removed,
                        i = [i]+1
                    ],
                    each [Tbl]
                )
            ),
            KeyColName 		= if key is list then key{count} else key,
            MergedColNames 	= Table.ColumnNames(Combined),
            KeyToFront 		= List.Combine({{KeyColName},List.RemoveItems(MergedColNames,{KeyColName})}),
            Reordered 		= Table.ReorderColumns(Combined, KeyToFront)

        in
            Reordered,

    Table.MergeColumns       = // объединяет два столбца, беря столбец A, но возвращаясь к B, где A = null 
        /*
            Merges two columns in a table that refer to the thing, taking column A but falling back to B where A is null
            Объединяет два столбца, которые ссылаются на объект, беря столбец A, но возвращаясь к B, где A  = null
            
            Usage:
                Table.MergeColumns = Load("Table.MergeColumns"),
                Tbl = #table({"Tel.", "Phone #"},{{"234", null},{null, "123"}}),
                Table.MergeColumns(Tbl, "Tel.", "Phone #")
           
            Result: 
                #table({"Tel."},{{"234"},{"123"}})
        */

        (Source as table, aCol as text, bCol as text) as table => 
        let
            colName = "SomeCustomColName",
            InsertedCustom = Table.AddColumn(Source, colName, each if Record.Field(_,aCol)=null then Record.Field(_,bCol) else Record.Field(_,aCol) ),
            RemovedColumns = Table.RemoveColumns(InsertedCustom,{aCol, bCol}),
            RenamedColumns = Table.RenameColumns(RemovedColumns,{{colName, aCol}})
        in 
            RenamedColumns,

    Table.RemoveBlankColumns = // позволяет удалять пустые столбцы/строки из таблицы 
        /*
            Allows to remove blank (empty) columns from a table like "Remove Empty Rows" UI option. 
            Optional parameter for empty strings ("") removing (also as nulls)

            Позволяет удалять пустые столбцы из таблицы, например опцию пользовательского интерфейса «Удалить пустые строки». 
            Необязательный параметр для удаления пустых строк ("") (также в виде нулей)

            Usage:
                Table.RemoveBlankColumns = Load("Table.RemoveBlankColumns"),
                
                remove column with nulls AND empty strings:
                Table.RemoveBlankColumns(
                    Table.FromRecords({[A = null, B = 1],[A = null, B = 2],[A = "", B = 3]}), 
                    true
                )
            
            Result: 
                Table.FromRecords({[B = 1],[B = 2],[B = 3]})

                remove column with nulls only:
                Table.RemoveBlankColumns(
                    Table.FromRecords({[A = null, B = 1],[A = null, B = 2],[A = "", B = 3]})
                )
            
            Result: 
                Table.FromRecords({[A = null, B = 1],[A = null, B = 2],[A = "", B = 3]})
        */

        (   tab as table,                        // table to clean
            optional EmptStr as nullable logical // flag to remove columns which contains nulls OR empty strings - only
        ) as table =>

            let
                ToRemove      = {null} & (if EmptStr = true then {""} else {}), // list of "blank" values 
                tabDemoted    = Table.DemoteHeaders(tab),
                tabTransposed = Table.Transpose(tabDemoted),
                RowsRemoved   = Table.SelectRows(
                    tabTransposed, 
                    each not List.IsEmpty(
                        List.RemoveMatchingItems(
                            Record.FieldValues(
                                Record.RemoveFields(_, "Column1")   // after demote+transpose first column is allways with columns headers
                            ), 
                            ToRemove)
                        )
                    ),
                tabTransposedAgain = Table.Transpose(RowsRemoved)
            in
                Table.PromoteHeaders(tabTransposedAgain),

        /* 
            Alternative version (performance didn't checked between versions):

            let
                ToRemove = {null} & (if EmptStr = true then {""} else {}) // list of "blank" values 
            in
                List.Accumulate(
                    Table.ColumnNames(tab), 
                    tab, 
                    (state, current)=> 
                        if List.IsEmpty(
                            List.RemoveMatchingItems(
                                Table.Column(state, current), 
                                ToRemove)
                            ) 
                        then Table.RemoveColumns(state, current) 
                        else state
                    )
        */

    Table.RowsCombination  	 = // создает все возможные комбинации строк из Таблицы1 и Таблицы2 
        /*
            Returns the Cartesian product of rows of list of tables having same structure
            Возвращает декартово произведение строк списка таблиц, имеющих одинаковую структуру.
            
            How it was created:
            https://bondarenkoivan.wordpress.com/2016/09/20/combination-of-rows-of-tables-list-in-power-query/

            Usage:
                Table.RowsCombination( {Table1, Table2} )
                
            Result: 
                all possible combination of rows from Table1 and Table2
        */

        (tables as list)=>
        let
            tableslist      = List.Buffer( tables ),
            list_as_numbers = List.Buffer( List.Transform( tableslist, each { 1 .. Table.RowCount(_) } ) ),

        // Tycho's function
        // https://github.com/tycho01/pquery/blob/master/List.CrossJoin.m
            
            list_crossjoin = (A as list, B as list) as table =>
                let
                    firstList 	 	= List.RemoveNulls(A),
                    secondList 	 	= List.RemoveNulls(B),
                    firstLength  	= List.Count(firstList),
                    secondLength    = List.Count(secondList),
                    resultFirstList = 
                        List.Generate( () => 0, 
                            each _ < firstLength * secondLength, 
                            each _ + 1, 
                            each firstList{ Number.IntegerDivide(_, secondLength) }
                        ),

                    resultSecondList = List.Repeat( secondList, firstLength ),
                    list_to_table 	 = Table.FromColumns( {resultFirstList, resultSecondList} ),
                    // my adjustment - merge and leave only merged column
                    add_merged 		 = Table.AddColumn(list_to_table, "Merged", each Text.Combine({Text.From([Column1]), Text.From([Column2])}, ""), type text),	
                    remove_other 	 = Table.SelectColumns( add_merged,{"Merged"})
                in
                    remove_other,

        //  loop through list of numbers (each element is qty of table rows)
            generator = List.Accumulate(list_as_numbers, null, (acc, x) => if acc = null then x else Table.Column(list_crossjoin(acc, x), "Merged")),

        //  function that collects corresponding records (rows) from initial tables - loop through combination of indices
            get_tables_rows = (combination as text) => List.Last( 
                List.Generate(
                    ()=> [i=0, L={}],
                    each [i] <= List.Count( tableslist ),
                    each [i = [i]+1,
                        L = List.Combine( { [L], { tableslist{ [i] }{ Number.From( Text.Range( combination, [i], 1) )-1 } } } ) ],
                    each [L] 
                ) 
            ),

            resulting_list = List.Transform( generator, each Table.FromRecords( get_tables_rows(_) ) ),
            list_to_table  = Table.FromList(resulting_list, Splitter.SplitByNothing(), null, null, ExtraValues.Error),	
            result    	   = Table.ExpandTableColumn( list_to_table, "Column1", Table.ColumnNames( tableslist{0} ), Table.ColumnNames( tableslist{0} ) )	
        in
            result,

    Table.RowsCombination2   = // создает все возможные комбинации строк из нескольких Таблиц
        /*  tables = { Table1, Table2, Table3, Table4, Table5 } */
        (tables as list) =>
        let
            add_tables = List.Last(
                List.Generate( ()=>
                    [i = 0, T = tables{0}],
                    each [i] <= List.Count( tables ) - 1,
                    each [i = [i] + 1, T = Table.AddColumn( [T], "Custom." & Text.From( i ), each tables{ i } ) ],
                    each [T] 
                ) ),
            
            expand_tables = 
                List.Last(
                    List.Generate( ()=>
                        [i=0, T=add_tables],
                        each [i] <=List.Count( tables ) - 1,
                        each [  i = [i]+1,
                                T = Table.ExpandTableColumn( 
                                        [T], 
                                        "Custom." & Text.From( i ), 
                                        Table.ColumnNames( tables{0} ), 
                                        List.Transform( 
                                            Table.ColumnNames( tables{0} ), 
                                            each Text.From(_) & "." & Text.From( i ) 
                                        )
                                    ) 
                            ],
                        each [T] 
                    ) 
                ),

            AddedIndex     = Table.AddIndexColumn(expand_tables, "Index", 1, 1),
            UnpivotedOtherColumns  = Table.UnpivotOtherColumns(AddedIndex, {"Index"}, "Attribute", "NewValue"),
            SplitColumnbyDelimiter = Table.SplitColumn(UnpivotedOtherColumns,"Attribute",Splitter.SplitTextByEachDelimiter({"."}, QuoteStyle.Csv, false),{"Attribute.1", "Attribute.2"}),
            PivotedColumn  = Table.Pivot(SplitColumnbyDelimiter, List.Distinct(SplitColumnbyDelimiter[Attribute.1]), "Attribute.1", "NewValue"),
            RemovedColumns = Table.RemoveColumns(PivotedColumn,{"Attribute.2"})
        in
            RemovedColumns,

    Table.TranslateColumn    = // Создает «переведенный» столбец по словарю замен
        /*
            Makes a 'translated' column simultaneously executing multiple replaces on the original (using a list of lists as a 'translation sheet')
            Создает «переведенный» столбец, одновременно выполняя несколько замен оригинала (используя список списков в качестве «листа перевода»).

            Usage:
                Table.TranslateColumn = Load("Table.TranslateColumn"),
                Tbl = #table({"可能"},{{"不可"},{"可"}}),
                Table.TranslateColumn(Tbl, "可能", "Possible", {{"不可", "Nope"},{"可","Yes"}})
            
            Result: 
                #table({"Possible"},{{"Nope"},{"Yes"}})
        */

        (Tbl as table, OldCol as text, NewColName as text, TranslationList as list) as table =>

        let
            ColAdded   = Table.AddColumn(Tbl, NewColName, 
                            each List.ReplaceMatchingItems(
                                    {Record.Field(_, OldCol)}, 
                                    TranslationList
                                 )
                            ),
            Columnized = Table.ExpandListColumn(ColAdded, NewColName)
        in 
            Columnized,

    Table.UnpivotByNumbers   = // Unpivot, но строки заголовка, должны находиться в первых строках таблицы, НЕ в заголовках
        let func =  
        /* 
            The header rows to be unpivoted must sit in the first rows of your table and NOT in the header itself. 
            The header will be ignored, so if it shall be unpivoted as well, demote it first

            Строки заголовка, которые нужно отменить, должны находиться в первых строках таблицы, а НЕ в самом заголовке. 
            Заголовок будет игнорироваться, поэтому, если он также должен быть отключен, сначала понизьте его уровень.
        */

        (Table 					as table, 
        FirstNColumnsToKeep 	as number, 
        FirstNRowsToKeep 		as number) =>

        let
            Source = Table,

        //  Determine column names to keep
            FirstColumnsToKeep = List.FirstN(Table.ColumnNames(Source), FirstNColumnsToKeep),

        //  Those columns who are not to keep shall be unpivoted
            UnpivotColumns = List.Difference(Table.ColumnNames(Source), FirstColumnsToKeep),

        //  Create list of lists with one row per header row
            Headers = if FirstNRowsToKeep=0 then {UnpivotColumns} else List.Buffer(Table.ToRows(Table.FirstN(Table.SelectColumns(Source, UnpivotColumns),FirstNRowsToKeep))),

        //  This step effectively unpivots the values of every row of the table and creates one table per row with an index column indicating the values relative positions.
            ValuesRecord = Table.AddColumn(Source, "Custom", each Table.AddIndexColumn(Table.FromColumns(List.Union({Headers, {Record.FieldValues(Record.SelectFields(_, UnpivotColumns))}})), "IndexUnpivot",1,1)),
            Cleanup = Table.RemoveColumns(ValuesRecord, UnpivotColumns),

        //  Remove the first rows who hold the "to-be-unpivoted" headers.
            RemoveTopNRows = Table.Skip(Cleanup,FirstNRowsToKeep),

        //  Retrieve the column names of the unpivoted columns-table 
            ColsToExpand = List.Union(List.Transform(RemoveTopNRows[Custom], each Table.ColumnNames(_))),

        //  Expand the columns and add ".1" to now columns to avoid duplicate column names
            fnUnpivotByNumbers = Table.ExpandTableColumn(RemoveTopNRows, "Custom", ColsToExpand, List.Transform(ColsToExpand, each _&".1") )
        in
            fnUnpivotByNumbers,

        // Documentation	
            documentation = [
                Documentation.Name            = " fnTable.UnpivotByNumbers", 
                Documentation.Description     = " Unpivots a table according to the number of columns and header rows passed on in the parameters", 
                Documentation.LongDescription = " Unpivots a table according to the number of columns and header rows passed on in the parameters", 
                Documentation.Category  = " Table functions", 
                Documentation.Source    = " local", 
                Documentation.Author    = " Imke Feldmann: www.TheBIccountant.com", 
                Documentation.Examples  = {[  
                    Description =  " ", 
                    Code        = " Check this blogpost explaining how it works: http://wp.me/p6lgsG-zW", 
                    Result      = " "
                ]}
            ] 
        in 
            Value.ReplaceType(func, Value.ReplaceMetadata(Value.Type(func), documentation)),
	// разные от masterPQ
	link1 = "" /* https://github.com/camwally/Power-Query 
					https://www.dingbatdata.com/2018/04/28/retaining-column-types-in-power-query/
		*/,
	ReplaceUsingTable 		= // * нужен пример, пока ошибка
		/*
			https://github.com/camwally/Power-Query 
			https://www.dingbatdata.com/2018/04/28/retaining-column-types-in-power-query/
		*/
		(Table as table)=>
		let 
			Rec = Record.FromTable(Table.FromColumns(List.FirstN(Table.ToColumns(Table),2),{"Name","Value"}))
		in 
			(Text as text)=> if Text = null then null else Record.FieldOrDefault(Rec,Text,Text),
	
	
	Table.FromRecordOfLists = // * нужен пример, пока ошибка
		(rec as record)=>
		let
			tab2col 	  = Record.ToTable(rec),
			valuess_names = List.Reverse(Table.ToColumns(tab2col)),
			tab 		  = Function.Invoke(Table.FromColumns, valuess_names)
		in
			tab,
	
	Table.ToRecordOfLists 	= // конвертирует таблицу в запись: Name - имена столбцов, Value списки значений
		(table as table, optional buffer as nullable logical)=>
		let
			tab 	= if buffer = true then Table.Buffer(table) else table,
			Name 	= Table.ColumnNames(tab),
			Value 	= Table.ToColumns(tab),
			Record 	= Record.FromTable(Table.FromColumns({Name, Value},{"Name","Value"}))
		in
			Record,

	Table.ToMCode2 			= //? из таблицы на входе делает эту же таблицу в коде M
		(inputTable as table, optional #"table type is vertical?" as nullable logical) as text =>
		let
			vert = #"table type is vertical?" ?? false,
			source = Table.Schema(inputTable),
			sortRows = Table.Sort(source,{{"Position", Order.Ascending}}),
			simplifyTypeNameRec = 
				[#"Any.Type" = "any",
				#"Binary.Type" = "binary",
				#"Date.Type" = "date",
				#"DateTime.Type" = "datetime",
				#"DateTimeZone.Type" = "datetimezone",
				#"Duration.Type" = "duration",
				#"Function.Type" = "function",
				#"List.Type" = "list",
				#"Logical.Type" = "logical",
				#"None.Type" = "none",
				#"Null.Type" = "null",
				#"Number.Type" = "number",
				#"Record.Type" = "record",
				#"Table.Type" = "table",
				#"Text.Type" = "text",
				#"Time.Type" = "time",
				#"Type.Type" = "type"],
			simplifyTypeNames	= Table.TransformColumns(sortRows,{{"TypeName", each Record.FieldOrDefault(simplifyTypeNameRec,_,_)}}),
			selectColumns 		= Table.SelectColumns(simplifyTypeNames,{"Name", "TypeName","IsNullable"}),
			addColOfTypeNames	= 
				Table.AddColumn( selectColumns, "TypeNames", 
					each 	Expression.Identifier([Name]) 
							& " = " 
							& (if [IsNullable] then "nullable " else "") 
							& [TypeName]
				),
			tableTypeRec = "[" & Text.Combine(addColOfTypeNames[TypeNames], if vert then "#(lf)," else ", ") & "]",

			//Code above is based on a function by Chris Webb

			tableOfExpressions = Table.TransformColumns(inputTable,{},Expression.Constant),
			listOfCols = Table.ToColumns(tableOfExpressions),
			listOfColsOfPaddedText = 
				List.Transform(
						listOfCols,
					(col as list)=>
					let 
							buf = List.Buffer(col),
							maxTextLength = List.Max(List.Transform(buf,Text.Length)),
							paddedText = List.Transform(buf,each Text.PadEnd(_,maxTextLength))
						in
							paddedText
				),
				listOfRowsOfPaddedText = List.Zip(listOfColsOfPaddedText),
				bodyAsList = List.Transform(listOfRowsOfPaddedText, (row as list)=> "{"&Text.Combine(row,",")&"}"),
				bodyAsText = "{"&Text.Combine(bodyAsList,"#(lf),")&"#(lf)}",
				together =  
						"#table(type table"
					& (if vert then "#(lf)" else "")
					& tableTypeRec
					& ",#(lf)"
					& bodyAsText
					& ")"
		in
			together,
	
	Table.RunningTotal 		= // накопительный итог в новом столбце
		(table as table, colToSum as text, colAsNew as text)=>
		let
			tableB 			= Table.Buffer(table),
			listToSum 		= List.Buffer(Table.Column(tableB,colToSum)),
			listToSumCount 	= List.Count(listToSum),
			runningTotalB 	= 
				List.Buffer(
					List.Skip(
						List.Generate(
							()=> [item = 0, counter = 0],
							each [counter] <= listToSumCount,
							each [item = [item]+listToSum{[counter]}, counter = [counter]+1],
							each [item]
						),
					1)
				),
			addIndex 		= Table.AddIndexColumn(tableB,"IndexUniqueName",0,1),
			addRunningTotal = Table.AddColumn(addIndex,colAsNew,each runningTotalB{[IndexUniqueName]}, type number),
			removeIndex 	= Table.RemoveColumns(addRunningTotal,{"IndexUniqueName"})
		in
			removeIndex,
	
	Table.TransformOtherColumns = // # изменение других колонок своей функцией кроме списка исключаемых
		/*
			Статуст:	перспективная
			Пример: 	F[Table.TransformOtherColumns](from, {"Статья"}, (x)=>if x is text then x & "+" else x, type text)
			Результат: 	Значения всех текстовых колонок, кроме колонки "Статья" транформируются в x & "+"

		*/
		(	Table as table, 
			ColumnsToIgnore as list, 
			Function as function, 
			optional TypeForColumns as nullable type
		) as table =>
		let
			FunctionType 	= Value.Type(Function),
			TypeForFunction = 
				Type.ForFunction([ReturnType = TypeForColumns, Parameters = Type.FunctionParameters(FunctionType)],
				Type.FunctionRequiredParameters(FunctionType)),
		
			FunctionWithNewReturnType = 
				if TypeForColumns is null 
				then Function 
				else Value.ReplaceType(Function,TypeForFunction),  
		
			TransformOtherCols = 
				Table.TransformColumns(
					Table,
					List.Transform(
						ColumnsToIgnore,
						(ColName)=> {ColName, each _}),
				FunctionWithNewReturnType)
		in
			TransformOtherCols,

	Table.AddRandomColumn 	= // # создает дополнительный столбец со случайными числами
		/*	
			Статус:	1

			1. 	Add column of random numbers between 0 and 1:
				F[Table.AddRandomColumn](Source,"Random Number",0,1)
			
			2. 	Add column of random percentages between 0% and 100%:
				F[Table.AddRandomColumn](Source,"Random Percentage",0,1,Percentage.Type)
			
			3. 	Retrieve random item from list:
				F[Table.AddRandomColumn](
					Source,
					"Random Item",
					0,
					List.Count(ListOfItems),{each ListOfItems{Number.RoundDown(_)}, type text}
				)
					ListOfItems = List.Buffer(SomeList))
		*/
		(Table as table, 
			RandColName as text, 
			Min as number, 
			Max as number, 
			optional TransformAndTypeCriteria as any) =>
		let
			List = List.Buffer( 
					if not (TransformAndTypeCriteria is list) 
					then {TransformAndTypeCriteria} 
					else	if List.Count(TransformAndTypeCriteria)<=2 
							then TransformAndTypeCriteria 
							else error "Invalid Criteria (Too many items)"
					),
		
			TransformFunc = if List{0} is null or List{0} is type 
							then null 
							else	if List{0} is function 
									then List{0} 
									else error "Invalid Criteria (Tranform)", 

			ListLast = List.Last(List),
		
			Type = 	if	ListLast is null or ListLast is function 
					then type number 
					else  	if ListLast is type 
							then ListLast 
							else error "Invalid Criteria (Type)", 
		
			FirstName = Table.ColumnNames(Table){0},
		
			AddColumn = Table.AddColumn(Table,
										RandColName,
										each Number.RandomBetween(if Record.Field(_,FirstName)=null then Min else Min,Max),
										Type),
		
			Transform = if TransformFunc = null 
						then AddColumn 
						else Table.TransformColumns(AddColumn,{RandColName, TransformFunc})
		in
			Transform,

	Table.AddClusteredIndex = // # добавляет столбец с индексом по выбранному столбцу группировки (кластеру) //! примеры добавить
		/* 
			Описание

			Пример
				1	если годы + месяцы, то нумерует месяцы по порядку
					= F[Table.AddClusteredIndex](tbl, {"Year"}) 

		*/
		(Table as table, GroupOnCols as list) => 
		let
			Group   = Table.Group(Table, 
						GroupOnCols, 
						{"ColumnOfTables", each Table.AddIndexColumn(_, "ClustIndex", 0, 1)} 
					),
			Combine = Table.Combine(Group[ColumnOfTables])
		in
			Combine,
	
	Table.CombineJoins 		= // объединяет столбцы //! примеры добавить
		(	LeftTable as table,  LeftKey as list, 
			RightTable as table, RightKey as list, 
			ListOfJoins as list) =>
		let
			Func 		 = each Table.NestedJoin(LeftTable, LeftKey, RightTable, RightKey,"Right",_), 
			ListOfTables = List.Transform(ListOfJoins, Func),
			Combine 	 = Table.Combine(ListOfTables)
		in
			Combine,

	Table.CombineJoinsExpandCoalesce = 
		/* 
		Similar to combine joins, but also: 
			1) Preserves the order
			2) Expands right hand side table
			3) Right key is transferred to left key when left key is null, right key is then deleted 
		*/

		(	LeftTable as table, LeftKeys as list, 
			RightTable as table ,RightKeys as list,
			ListOfJoins as list
		) =>
		let
			Func = each Table.NestedJoin(LeftTable, LeftKeys, RightTable, RightKeys,"Right",_), 
			ListOfTables 	 = List.Transform(ListOfJoins, Func),
			Combine 		 = Table.Combine(ListOfTables),
			OldRightColNames = List.Buffer(Table.ColumnNames(RightTable)),
			NewRightKeys 	 = List.Buffer(List.Transform(RightKeys, each "Right." & _)),
			NewRightColNames = List.ReplaceMatchingItems(OldRightColNames,List.Zip({RightKeys,NewRightKeys})),
			//Below: Using Table.Buffer, so that order is preserved on expand
			ExpandRight 	 = Table.ExpandTableColumn(Table.Buffer(Combine), "Right", OldRightColNames, NewRightColNames),
			Coalesce = 
				List.Accumulate(
					List.Zip({LeftKeys,NewRightKeys}),
					ExpandRight, 
					(Table, Keys) =>Table.ReplaceValue(Table, null, each Record.Field(_,Keys{1}), Replacer.ReplaceValue, {Keys{0}})
				),
			
			RemoveRightKeys 	 = Table.RemoveColumns(Coalesce,NewRightKeys),
			OriginalLeftKeyTypes = List.Transform(LeftKeys, each Type.TableColumn(Value.Type(LeftTable),_)),
			ChangeTypes 		 = Table.TransformColumnTypes(RemoveRightKeys,List.Zip({LeftKeys, OriginalLeftKeyTypes}))
		in
			ChangeTypes,

	Table.NonAggPivotMultRows 	= // # Прокачанный вариант Сведено. Переворачивает строки в столбцы //!
		/*	
			https://www.dingbatdata.com/non-aggregate-pivot-with-multiple-rows-in-powerquery/
			есть xlsx пример и описание работы с каждым шагом функции
			to = PivotMultRows(FlatTable, "Vehicle", "Person")
		*/
		(	Source 			as table,
			ColToPivot 		as text,
			ColForValues 	as text
		) => 

		let
			PivotColNames = List.Buffer(List.Distinct(Table.Column(Source,ColToPivot))), 
			Pivot		  = Table.Pivot(Source, PivotColNames, ColToPivot, ColForValues, each _),

			TableFromRecordOfLists = 
				(rec as record, fieldnames as list) =>
					let	PartialRecord = Record.SelectFields(rec,fieldnames),
						RecordToList  = Record.ToList(PartialRecord),
						Table 		  = Table.FromColumns(RecordToList,fieldnames)
					in	Table,

			AddColumn 	  = Table.AddColumn(Pivot, "Values", each TableFromRecordOfLists(_,PivotColNames)),
			RemoveColumns = Table.RemoveColumns(AddColumn,PivotColNames),
			ExpandTable   = Table.ExpandTableColumn(RemoveColumns, "Values", PivotColNames)
		in
			ExpandTable,

	Table.NonAggPivotMultRows2 	= // прокачанный вариант Сведено не проверял
		/*

		*/
		(	Source as table,
			PivotCol as text,
			ValueCol as text
		)=> 
		let
			Source = Table.Buffer(Source), //As source table is referenced 3 times
			GroupClustIndex = 
				Table.Group(Source,
					List.RemoveItems(Table.ColumnNames(Source),{ValueCol}),
					{"ColOfTables", each Table.AddIndexColumn(_,"idx")}
				),

			CombineTables = Table.Combine(GroupClustIndex[ColOfTables]),
			Pivot 		  = Table.Pivot(CombineTables, List.Distinct(Table.Column(Source,PivotCol)), PivotCol, ValueCol),
			RemoveIndex   = Table.RemoveColumns(Pivot,{"idx"})
		in
			RemoveIndex,

	Table.OrderFirstOccurrence 	= // группировка множественных вхождений элементов массива, упорядоченных по первому вхождению
		/*	
			Учитывая несортированный массив с повторениями, задача состоит в том, чтобы сгруппировать 
			многократное вхождение отдельных элементов. Группировка должна происходить таким образом, 
			чтобы сохраняться порядок первого появления всех элементов.
			https://www.geeksforgeeks.org/group-multiple-occurrence-of-array-elements-ordered-by-first-occurrence 
		*/ 
		(Source as table, GroupBy as list) =>
		let
			#"Grouped Rows" 	= Table.Group(Source, GroupBy, {{"Tables", each _, type table}}),
			#"Removed Columns" 	= Table.RemoveColumns(#"Grouped Rows", GroupBy),
			#"Expanded Tables" 	= Table.ExpandTableColumn(#"Removed Columns", "Tables", Table.ColumnNames(Source)),
			RevertTypes 		= Value.ReplaceType(#"Expanded Tables", Value.Type(Source))
		in
			RevertTypes,
	
	Table.StableSortAndOrderFirstOccurrence = // 
		/*
			It's a bit like Table.Sort, but:
			1) Sorts are stable
			2) If you neglect to put a Order.Ascending or a Order.Descending then ordered by first occurrence 
		*/
		(Table as table, List as list) =>
		let
			fMakeEfficientList = (List as list) =>
				let 
					ColName 	= List.Transform(List, each _{0}),
					Order 		= List.Transform(List, each _{1}?),
					TableForm 	= Table.FromColumns({ColName,Order},{"ColName","Order"}),
					Comparer 	= (a as record, b as record) => Number.From(a[Order] is null or b[Order] is null) ,
					PartionedTable = Table.Group(TableForm, {"Order"}, {{"NestedLists", each Table.ToRows(_), type list}},GroupKind.Local, Comparer),
					PartionedList  = PartionedTable[NestedLists]
				in
					PartionedList,

			fReorder = (Table as table, List as list) =>
				let
					ListItem = List.Buffer(List{0}),
					ListItemColNames = List.Buffer(List.Zip(ListItem){0}),
					GroupedTable = Table.Group(Table, ListItemColNames, {{"NestedTables", each Table.RemoveColumns(_,ListItemColNames), type table}}),
					SortedTable  = if ListItem{0}{1} = null then GroupedTable else Table.Sort(GroupedTable,ListItem),
					fRecursion 	 = each if List.Count(List) > 1 then @fReorder(_, List.Skip(List)) else _,
					RecurseOnNestedTables = Table.Buffer(Table.TransformColumns(SortedTable, {"NestedTables", fRecursion})),
					Expand = Table.ExpandTableColumn(RecurseOnNestedTables, "NestedTables", Table.ColumnNames(RecurseOnNestedTables[NestedTables]{0}))
				in
					Expand,
			
			EfficientList 	= List.Buffer(fMakeEfficientList(List)),
			ReorderRows 	= fReorder(Table,EfficientList),
			ReclaimColOrder = Table.ReorderColumns(ReorderRows,Table.ColumnNames(Table)),
			ReclaimColTypes = Value.ReplaceType(ReclaimColOrder,Value.Type(Table))
		in
			ReclaimColTypes,
	
	Table.SyncTableTypeOfCol 	= // приписывает тип таблицы столбцу на основе первой таблицы в столбце
		/*
			Приписывает тип таблицы столбцу на основе первой таблицы в столбце как
			Table.TransformColumnTypes не работает со сложными типами
		*/
		(PreviousStep as table,ColName as text) =>
			Table.TransformColumns(
				PreviousStep, 
				{ColName, each {_}{0}, Value.Type(Table.Column(PreviousStep,ColName){0})}
			),
	
	Table.SelectRowsWeb 		= // не пробовал применить
		/*

		*/
		
		(	Table as table,
			fnFilter as function,
			optional Range as nullable list,
			optional Horizontal as nullable logical)=>

		let
			Range      	= if Range      = null then {0}   else Range,
			Horizontal 	= if Horizontal = null then false else Horizontal,
			AddIndex 	= Table.AddIndexColumn(Table, "Index", 0, 1),
			Filter 		= Table.SelectRows(AddIndex, fnFilter),
			Positions 	= List.Buffer(Filter[Index]),
			Values 		= List.Buffer(Table[Column1]),
			
			ListOfTables = 
				List.Transform(Positions, (Pos)=>  
					let  
						Len = List.Count(Range),
						Gen = List.Generate(()=>[i= 0      , Rng = Range{i}, Position = Pos+Rng,  Value = Values{Position}],
											each _[i] < Len,
											each [i= _[i]+1, Rng = Range{i}, Position = Pos+Rng,  Value = Values{Position}],
											each _[[Value],[Rng],[Position]]),
						
						Table = Table.FromRecords(Gen),
						RenameAndChangeTypes = Value.ReplaceType(Table, type table[Value = text, Range = Int64.Type, Position = Int64.Type])
					in
						RenameAndChangeTypes),
			
			Combine 	 = Table.Combine(ListOfTables),
			ValuesToRows = Table.FromRows(List.Transform(ListOfTables, each _[Value]))
		in
			if Horizontal then ValuesToRows else Combine,
	
	Table.TakeTypesAndTryApply 	= // # приписывает типы из одной таблицы и применяет их к одноименным столбцам в другой таблице
		/*
			Если в таблице появились или потеряны столбцы, вместо этого вы можете использовать эту функцию. 
			Он возьмет типы из предыдущего шага и применит их там, где имена столбцов одинаковы.
			https://www.dingbatdata.com/2018/04/28/retaining-column-types-in-power-query/
			https://blog.crossjoin.co.uk/2017/09/25/setting-data-types-on-nested-tables-in-m/
	
		*/
		(tblToAlter as table, tblGet as table) =>
			let
				typetblGet  = Value.Type(tblGet),
				NameCols 	= List.Intersect({Table.ColumnNames(tblGet), Table.ColumnNames(tblToAlter)}),
				NameFuncTypes = 
					List.Transform(
						NameCols, 
						(x) => {x, 
								each {_}{0}, 
								Type.TableColumn(typetblGet, x)}
					),
				Transform = Table.TransformColumns(tblToAlter, NameFuncTypes)
			in
				Transform,
	
	Table.SplitColsDateTime 	= // наверное правильно соединяет столбцы с датой и временем
		/*
		
		*/
		(	table as table,
			ColName as any, // Can be as list of column names or a single column name 
			optional ColNameDate as nullable text,
			optional ColNameTime as nullable text,
			optional Delimiter   as nullable text
		) as table=> 
		let
			ColNameDateD  = if ColNameDate is null then "Date" else ColNameDate, // Default values can be changed to fit  
			ColNameTimeD  = if ColNameTime is null then "Time" else ColNameTime, // your own language or table naming standards
			DelimiterD    = if Delimiter   is null then "."    else Delimiter,   // (only applicable when ColName is list)
			ColNameIsText = if ColName is text then true else
							if ColName is list then false else
							error "ColName needs to be a text value or a list of text values", 
			fnSplitColumn = 
				(State as table, CurrentColName as text) as table=>
					let
						CurrentColNamesNew = 
							if ColNameIsText 
							then {ColNameDateD, ColNameTimeD}
							else {CurrentColName & DelimiterD & ColNameDateD, CurrentColName & DelimiterD & ColNameTimeD},

						SplitColumn =  Table.SplitColumn(State, CurrentColName, each {_,_}, CurrentColNamesNew),
						
						ColumnTransType = {
							{DateTime.Date, type nullable date},
							{DateTime.Time, type nullable time}
						}, 
						
						TransformColumns = 
							Table.TransformColumns(
								SplitColumn,
								List.Zip({CurrentColNamesNew} & List.Zip(ColumnTransType))
							)
					in
						TransformColumns
		in
			List.Accumulate(
				if ColNameIsText then {ColName} else ColName,
				table,
				fnSplitColumn
			),

	Table.Others  			 = "",
	//===========================
	// Text
	//===========================
	// основные
	Text.Alphabet       = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz", // использовать: Text.ToList() или {}
	Text.AlphabetRu     = "АБВГДЕЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдежзийклмнопрстуфхцчшщъыьэюя",
	Text.AlphaNumeric   = Text.AlphabetRu & "0123456789",
	Text.ExtractDate    = // # извлекает дату из текстовой строки
		/* 
			Пример:		F[Text.ExtractDate]("Сегодня30.06.2022 число.xlsx")
			На выходе:	"30.06.2022"
		*/
		( text as text ) =>
			let
				selectChars = Text.Select ( text, { " ", "_", ".", "0" .. "9" } ),
				split       = Text.SplitAny ( selectChars, " _" ),
				filterList  = List.Select ( split, ( x ) => 
								Text.Length ( x ) = 10 and 
								Text.PositionOf ( x, ".", Occurrence.All ) = { 2, 5 }  
							  ) {0}?,
				toDate      = Date.FromText ( filterList, "RU-ru" )
			in
				toDate,
	Text.FromList       = // возвращает текст из списка 
		// 
		(list as list) => List.Accumulate(list, "", (state, current) => state & Text.From(current)),
	Text.IsUpperCase    = // проверить, что делает
		/* 
			Is text all uppercase? returns false if any non-alpha characters are present
			
			Switch(1, {1, 2, 3}, {""A"", ""B"", ""C""})" = А
		*/
		Document(
			"Text.IsUpperCase", 
			"переключает текст",
			{ 
				[ Description = "sdfvsd",   Code = "Switch(1, {1, 2, 3}, {""A"", ""B"", ""C""})",       Result = "A"],
				[ Description = "sdvsdbv",  Code = "Switch(1, {{1, ""A""}, {2, ""B""}, {3, ""C""}})",   Result = "A"]
			},
		(text as text) => 
			List.AllTrue(
				List.Transform(
					Text.ToList(text), 
					(letter)=>Text.Contains(Text.Alphabet, letter) and letter = Text.Upper(letter)
				)
			) 
		),

	Text.IsAlpha        = // является ли весь текст английским/русским (проверяет каждый символ)
		(text as text) => 
			List.MatchesAll(Text.ToList(text), each Text.Contains(Text.Alphabet, _)),
	Text.IsNumber       = //  # проверка текста на номер (true/false)
		// 
		(text as text) => try Number.FromText(text) is number otherwise false,

	Text.RemoveDubleWhitespace = // # заменяет двойные и более пробелы на одинарный по бокам и внутри текста
		(text as text) => 
			Text.Combine(Splitter.SplitTextByWhitespace()(text)," "), 

	Text.SplitCamelCase  = // # разделяем текст пробелом перед Большими буквами
		/*
			Splits camelCased and PascalCased text and separates by a space. Ex: "thisIsAColumn" -> "this Is A Column"
		*/
		(text as nullable text) => 
			if text is null then null else List.Accumulate(Text.ToList(text),"", (state, current) => 
		let
			PreviousLetter = Text.End(state, 1),
			Ignore = (text as text) => text = " " or text = "."
		in 
			state & 
			(if 
				not Text.IsUpperCase(PreviousLetter) and 
				not Ignore(PreviousLetter) and 
				not Ignore(current) and 
				Text.IsUpperCase(current) 
			then 
				" " else "" ) & 
			current),

	Text.SplitOnNotIn    = // функция разделяет строку на части, используя символы, которые не входят в validCharacters, как разделители //! нужно много примеров
		/*
			Описание	
				функция разделяет line на части, используя символы, которые не входят в validCharacters, как разделители.
				todo оставляем толькео символы которые в списке исключаемых!

			На выходе
				список слов, которых нет в 	
				если line равен null, функция вернет null
			
			Например
				если validCharacters содержит буквы латинского алфавита (A-Z, a-z), 
				то все символы, не входящие в этот набор (например, пробелы, цифры, знаки препинания), 
				будут использоваться для разделения строки
			
			Пример
				line = "Hello, World! 123"
				validCharacters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
				Result 		= Splitter.SplitTextByNotIn(validCharacters)(line)
				Результат:	= {"Hello", "World", "", "123"}
			
			Примеры	
				1	= F[Text.SplitOnNotIn]("Привет, мир! 123", "м")
					= {"м", null}

				2	= F[Text.SplitOnNotIn]("Привет, мир! 123", "абвгдежзийклмнопрстуфхцчшщъыьэюяАБВГДЕЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ")
					= {"Привет", "мир", null}
				
				3	= F[Text.SplitOnNotIn]("Привет, мир! 123", " абвгдежзийклмнопрстуфхцчшщъыьэюяАБВГДЕЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ")
					= {"Привет", "мир", "", null}
				
				4	= F[Text.SplitOnNotIn]("мама мыла раму","ма")
					= {"мама", "м", "а"," ам", null}
		*/

		(line as nullable text, validCharacters as text) => 
			Splitter.SplitTextByNotIn(validCharacters)(line),

	Text.SplitOnNonAlpha = // потестировать 
		// 
		(line as nullable text) =>
			if line is null 
			then null 
			else List.Accumulate(
					Text.ToList(line), 
					{null} , 
					(state, current) => 
						let
							doSkip 	   = not Text.Contains(Text.Alphabet, current),
							lastItem   = List.Last(state),
							appendLast = lastItem<>null
						in
							if doSkip then 
								if lastItem is null 
								then state 
								else List.Combine({state, {null}})
							else
								if appendLast 
								then List.Combine({List.RemoveLastN(state, 1), {lastItem & current}})
								else List.Combine({List.RemoveLastN(state, 1), {current}})
				),

	Text.Substring       = // # функция позволяет извлекать часть строки, начиная с указанного индекса и до заданного количества символов
		/*
			Параметры:
				text	строка, из которой будет извлекаться подстрока
				start	начальный индекс для извлечения (должен быть неотрицательным)
				count	необязательный параметр, определяющий количество символов для извлечения
			
			Проверки:
				Проверяется, что start не отрицательный. Если отрицательный, возникает ошибка
				Если count не указан, используется длина строки. Если указан, проверяется, что он не превышает длину текста
			
			Извлечение подстроки:
				Преобразует текст в список символов.
				Пропускает первые start символов и извлекает end - start символов, создавая новую строку из списка
			
			Возвращаемое значение:
				Функция возвращает извлеченную подстроку
			
			Пример:
				1	Извлечение подстроки с начала:
					= F[Text.Substring] ("Hello, World!", 0, 5)		= "Hello"

				2	Извлечение подстроки, начиная с определенного индекса:
					= F[Text.Substring] ("Hello, World!", 7, 5)		= "World"

				3	Извлечение подстроки с использованием только начального индекса:
					= F[Text.Substring] ("Hello, World!", 7)		= "World!" (извлекает до конца строки)

				4	Попытка извлечения с ошибкой:
					= F[Text.Substring] ("Hello, World!", -1, 5)	= Ошибка: "start index should be >= 0"

				5	Попытка извлечения с превышающим значением count:
					= F[Text.Substring] ("Hello, World!", 0, 20)	=  Ошибка: "count should be <= text length"

		*/
		(text as text, start as number, optional count as number) => 
			let 
				start 	 = 	if start >= 0 then start else error "start index should be >= 0",
				end 	 = 	if 	count = null 
							then Text.Length(text) 
							else 	if count <= Text.Length(text) 
									then count 
									else error "count should be <= text length",
				textList = Text.ToList(text),
				substr 	 = Text.FromList(List.FirstN(List.Skip(textList, start), end - start))
			in 
				substr,

	Text.ToList_		 = // разделение текста по каждому символу (встроенна функция)
		(txt as text)=> Text.ToList(Text.AlphabetRu),
	Text.PositionAfter   = // # функция поиска позиции после первого вхождения подстроки в строке
		/*
			Поиск существующей подстроки:
				text 		= "Hello, World!"
				substring 	= "Hello"
				Результат: 	5 (индекс сразу после "Hello")

			Поиск несуществующей подстроки:
				text 		= "Hello, World!"
				substring 	= "Goodbye"
				Результат: 	-1 (подстрока не найдена)
			
			Работа с null:
				text 		= null
				substring 	= "Hello"
				Результат: 	-1 (текст равен null)
		*/

		(text as nullable text, substring as text) => 
			let 
				firstIndex = Text.PositionOf(text, substring),
				indexAfter = if firstIndex >=0 then firstIndex + Text.Length(substring) else -1
			in
				if text is null then -1 else if indexAfter >= 0 and indexAfter < Text.Length(text) then indexAfter else -1,
	
	Text.Until         	 = // # функция извлекает подстроку из текста, начиная с заданным индексом и заканчивая перед указанным разделителем
		/*
			Описание
				функцию, которая извлекает подстроку из заданного текста, начиная с определенного индекса и заканчивая перед указанным разделителем
			
			Параметры:
				text			строка, из которой извлекается подстрока
				endDelimiter	разделитель, указывающий, где закончить извлечение
				startIndex		необязательный параметр, указывающий, с какого индекса начинать извлечение (по умолчанию 0)
			
			Определение начального индекса:
				Если startIndex равен null, устанавливается значение start равным 0
				В противном случае используется значение startIndex
			
			Извлечение текста:
				textFromStart извлекает подстроку из text, начиная с start с помощью функции Text.Substring
			
			Поиск позиции разделителя:
				delimPosition ищет позицию endDelimiter в textFromStart
				Если разделитель найден, сохраняется его позиция; если нет, используется длина textFromStart
			
			Возвращаемое значение:
				Если text равно null, функция возвращает null
				В противном случае, функция возвращает подстроку из textFromStart, начиная с 0 и до delimPosition
			
			Пример
				Извлечение подстроки:
					Result = Text.Range("Hello, World! This is a test.", " ", 7)
					Результат: "World!" (извлечение текста от индекса 7 до первого пробела после "World!")
				
				Если разделитель отсутствует:
					text = "Hello, World!"
					endDelimiter = "."
					Результат: "Hello, World!" (так как разделитель не найден, подстрока извлекается до конца)
		*/

		(text as text, endDelimiter as text, optional startIndex as number) => 
		let
			start = if startIndex = null then 0 else startIndex,
			textFromStart = Text.Substring(text, start),
			delimPosition = if Text.PositionOf(textFromStart, endDelimiter) >= 0 then Text.PositionOf(textFromStart, endDelimiter) else Text.Length(textFromStart)
		in
			if text is null then null else Text.Range(textFromStart, 0, delimPosition),
	// дополнительные
	Text.AsciiOnly     	= // возвращает не ascii символы (<= 255) в строке
        //Filters out all non-ascii characters from a string
        (s as text) as text =>
        let
            Listified   = Text.ToList(s),
            Numbered    = List.Transform(Listified, each Character.ToNumber(_)),
            Filtered    = List.Select(Numbered, each _ <= 255),
            Stringified = List.Transform(Filtered, each Character.FromNumber(_)),
            Joined      = Text.Combine(Stringified, ""),
            Return      = Joined
        in
            Return,

    Text.Between       	= // возвращает текст между разделителями
        /*
            Описание 	Возвращает текст между разделителями
            Usage		F[Text.Between]("abcdef", "bc", "f")
            Result	 	"de"
        */

        (   Text       as text, 
            After      as text, 
            Before     as text
        ) as text =>
            let
                CutAfter  = Text.Split(Text, After),
                CutBefore = Text.Split(CutAfter{1}, Before),
                Needle    = 
                    if List.Count(CutAfter) > 1
                    then (if List.Count(CutBefore) > 1 
                        then CutBefore{0} 
                        else Error.Record("Найти текст не удалось","Текст не содержит ключевых слов" & Before, Text))
                    else error Error.Record("FindTextFailed","The text did not contain the keyword " & After, Text)
            in 
                Needle,

    Text.ContainsAny   	= // содержит ли строка какое-либо слово из списка
        /*
            Описание	проверка строки на наличие любого слова из заданного списка
            Пример		= F[Text.ContainsAny] ("the cat sat on the mat", {"cat", "apple"})
            Результат	true
            Примечание	То же, что и List.ContainsAny({"мама мыла папу рядом"}, {"мапа","папу"}, Text.Contains)
        */

        (str, needles) as logical =>
        let
            count = List.Count(needles)
        in
            List.AnyTrue(
                List.Generate(
                    ()=>[i=0],
                    each [i] < count,
                    each [i=[i]+1],
                    each Text.Contains(str,needles{[i]})
                )
            ),

    Text.Count         	= // число вхождений символа в строке
        /*
            Returns the number of occurrences of a substring (needle) within another string (haystack).
            Usage:
                let
                    Text.Count = Load("Text.Count")
                in
                    Text.Count("Abba", "b")
            Result: 
                2
        */

        (Haystack as text, Needle as text) as number =>
            List.Count(Text.Split(Haystack, Needle)) - 1,

    Text.EachBetween   	= // возвращает текст между несколькими парными разделителями
        /*
            Grabs the substring between the specified 'after' and 'before' strings
            Usage:
                Text.EachBetween = Load("Text.EachBetween"),
                Text.EachBetween("a[bc][d]ef", "[", "]")
            Result: 
                {"bc", "d"}
        */

        (Haystack as text, After as text, Before as text) as list =>
        let
            CutAfter  = Text.Split(Haystack, After),
            SkipFirst = List.Skip(CutAfter),
            CutEach   = List.Transform(SkipFirst, each Text.Split(_, Before){0})
        in 
            CutEach,

    Text.EachFromTo    	= // возвращает текст между несколькими парными разделителями + разделители
        /*
            Grabs the substring between the specified 'after' and 'before' strings
            
            Usage:		F[Text.EachFromTo]("a[bc][d]ef", "[", "]")
            Result: 	{"[bc]", "[d]"}
        */

        (
            Haystack 	as text, 
            After 		as text, 
            Before 		as text
        ) =>
        
        let
            CutAfter 	= Text.Split(Haystack, After),
            SkipFirst 	= List.Skip(CutAfter),
            CutEach 	= List.Transform(SkipFirst, each After & Text.Split(_, Before){0} & Before)
        in 
            CutEach,

    Text.FromTo        	= // захватывает первую подстроку от указанной строки «От» до строки «Вверх до»
        /*
            Description:
                Grabs the first substring from the specified 'From' up to the 'UpTo' string
                Захватывает первую подстроку от указанной строки «От» до строки «Вверх до».
            
            Usage:
                Text.FromTo = Load("Text.FromTo"),
                Text.FromTo("abcdef", "bc", "f")
            
            Result: 
                "bcdef"
        */

        (Haystack as text, From as text, UpTo as text) as text =>
        let
            CutAfter  = Text.Split(Haystack, From),
            CutBefore = Text.Split(CutAfter{1}, UpTo),
            Needle = 
                if List.Count(CutAfter) > 1
                then (
                    if List.Count(CutBefore) > 1 
                    then From & CutBefore{0} & UpTo 
                    else Error.Record("FindTextFailed","The text did not contain the keyword " & UpTo, Haystack)
                    )
            else error Error.Record("FindTextFailed","The text did not contain the keyword " & From, Haystack)
        in 
            Needle,

    Text.Like          	= // позволяет выполнять нечеткие сравнения строк, аналогичные SQL LIKE
        /*
            Description:            
                Allows doing fuzzy string comparisons akin to SQL's LIKE
                Позволяет выполнять нечеткие сравнения строк, аналогичные SQL LIKE.

            Usage:
                Text.Like = Load("Text.Like"),
                Text.Like("the cat sat on the mat", "%cat%sat%mat%")
            
            Result: 
                true
        */

        //Originally written by Chris Webb: https://cwebbbi.wordpress.com/2014/05/27/implementing-a-basic-likewildcard-search-function-in-power-query/
        (Phrase as text, Pattern as text) as logical =>
        let
            PatternList  = Text.Split(Pattern, "%"),	 // Split pattern up into a list using % as a delimiter
            StartsWithWc = (List.First(PatternList)=""), // if the first character in the pattern is % then the first item in the list is an empty string
            EndsWithWc   = (List.Last(PatternList)=""),	 // if the last character in the pattern is % then the last item in the list is an empty string
            
            //if the first character is not % then we have to match the first string in the pattern with the opening characters of the phrase
            StartsTest = 
                if (StartsWithWc=false) 
                then Text.StartsWith(Phrase, List.First(PatternList)) 
                else true,
            
            //if the last item is not % then we have to match the final string in the pattern with the final characters of the phrase
            EndsText = 
                if (EndsWithWc=false) 
                then Text.EndsWith(Phrase, List.Last(PatternList)) 
                else true,
            
            //now we also need to check that each string in the pattern appears in the correct order in the phrase and to do this we need to declare a function PhraseFind
            PhraseFind = 
                (Phrase as text, SearchString as list) =>
                let
                    //does the first string in the pattern appear in the phrase?
                    StringPos = Text.PositionOf(Phrase, SearchString{0}, Occurrence.First),
                    PhraseFindOutput = 
                        if
                        
                        //if string not find then return false 
                        (StringPos=-1) 
                        then false 
                        else if
                        
                        //we have found the string in the pattern, and if this is the last string in the pattern, return true
                        List.Count(SearchString)=1
                        then true
                        else
                        
                        //if it isn't the last string in the pattern test the next string in the pattern by removing the first string from the pattern list and all text up to and including the string we have found in the phrase
                        (true and
                        @PhraseFind(
                        Text.RemoveRange(Phrase, 0, StringPos + Text.Length(SearchString{0})),
                        List.RemoveRange(SearchString, 0, 1)))
                    in
                        PhraseFindOutput,
            
            //return true if we have passed all tests    
            Output = StartsTest and EndsText and PhraseFind(Phrase, PatternList) 
        in
            Output,

    Text.MixedSort     	= // сортирует смешанную строку из текста (в буквенно-цифровом порядке) и чисел (в числовом порядке)
        /*
            Description:
                Sorts mixed list of text and numbers in a numerical order for numbers and alphanumeric for text 
                Arguments// "txt"= Text value to sort 

                Сортирует смешанный список текста и чисел в числовом порядке для чисел и в буквенно-цифровом порядке для текста. 
                Аргументы// "txt"= Текстовое значение для сортировки
            
            Author: 
                Bill Szysz in https://social.technet.microsoft.com/Forums/en-US/aed476c6-0daa-4aa2-b763-993195d4d0eb/how-to-sort-in-cell-values-with-comma-seperated-using-power-query?forum=powerquery 

            Suggested improvement: 
                Integrate option to choose order direction (ascending, descending) by function parameters 
                Интегрировать возможность выбора направления ордера (по возрастанию, убыванию) по параметрам функции
        */
       
        (txt as text) as text =>
        let 
            SplitTrim   = List.Transform(Text.Split(txt, ","), each Text.Trim(_)), 
            Transform   = List.Transform(SplitTrim, each try Number.From(_) otherwise _), 
            LstSort     = List.Sort(Transform, 0), 
            Transform2  = List.Transform(LstSort, each Text.From(_)), 
            CombineText = Text.Combine(Transform2, ", ")  	 
        in 
            CombineText,

    Text.PowerTrim     	= // удаляем двойные пробелы (опционально другой символ), а также пробелы в начале/конце строки
        /*
			Description:
				Функция удаляет двойные символы указанных символов
				По умолчанию удаляются двойные пробелы и начальные и конечные пробелы.
				Как функция TRIM в Excel
            Link:
                http://www.excelguru.ca/blog/2015/10/08/clean-whitespace-in-powerquery/
        */

        (text as text, optional char_to_trim as text) =>
            let
                char  = if char_to_trim = null 
                        then " " 
                        else char_to_trim,
                split        = Text.Split(text, char),
                removeblanks = List.Select(split, each _ <> ""),
                result       = Text.Combine(removeblanks, char)
            in
                result,

    Text.Queries       	= 1, // запросы из файлов в папке в виде текста, не проверял
        // /*
        //     Description:
        //         text user-defined queries
        //     to = Text.Combine(List.Select(Text.Split(text, char), each _ <> ""), char)
        // */
        // let
        //     LoadPath = "", // 
		// 	Files       = Folder.Files(LoadPath), // Folder.Contents
        //     AddDecode   = Table.AddColumn(Files, "Text", each Text.FromBinary([Content])),
        //     FilterCols  = Table.SelectColumns(AddDecode, {"Name", "Text"}),
        //     TextCol     = Table.Column(FilterCols, "Text"),
        //     TextMerged  = Text.Combine(TextCol),
        //     TextCleaned = TextMerged, // sorry, no regex to clean out comments!
        //     Return      = TextCleaned
        // in
        //     Return,

    Text.RemoveSymbols 	= // чистим текст от всех непечатных символов (129 символов)
        /*
			Description		Чистим текст от всех непечатных символов
            Link			https://cwebbbi.wordpress.com/2014/08/18/removing-punctuation-from-text-in-power-query/
            Usage			= F[Text.RemoveSymbols]("a,b,c") 
            Result			= "abc" -> удалил запятые
        */

        (inputtext as text) as text =>
        let
            //  get a list of lists containing the numbers of Unicode punctuation characters
                numberlists = {{0..31},{33..47},{58..64},{91..96},{123..191}},
            
            //  turn this into a single list
                combinedlist = List.Combine(numberlists),
            
            //  get a list of all the punctuation characters that these numbers represent
                punctuationlist = List.Transform(combinedlist, each Character.FromNumber(_)),
            
            //  some text to test this on
            //  inputtext = "Hello! My name is Chris, and I'm hoping that this *cool* post will help you!",
            //  the text with punctuation removed
                outputtext = Text.Remove(inputtext, punctuationlist)
        in
            outputtext,

    Text.ReplaceAll    	= // несколько замен текста, передавая замены в виде списка списков (List.Accumulate)
        /*
            Описание:
                Выполняйте несколько замен текста за один вызов функции, передавая замены в виде списка списков.
            
            Пример:	= F[Text.ReplaceAll] (
						"(test)", 
						{
							{"(", "["},
							{")", "]"}
						}
					)

            Результат: 
                "[test]"
			
			Одной строкой:
				f = (str as text, Replacements as list) as text => List.Accumulate(Replacements, str, (s, c) => Text.Replace(s, c{0}, c{1}))
        */

        (str as text, Replacements as list) as text => 
            List.Accumulate(
				Replacements, 
				str, 
				(s, c) => Text.Replace(s, c{0}, c{1})
			),
	// разобрать 
	Text.q1 = "",
	//===========================
	// Time
	//===========================
	Time.EpochToTime 	= // удаляет в текстовом времени символы "PT","S" и меняет "H","M" на ":"
        (epoch as nullable text ) =>
        let
            res = if epoch = null then null else
				let
					remove_word    = Text.Replace(epoch, "PT", ""),
					remove_letterH = Text.Replace(remove_word, "H", ":"),
					remove_letterM = Text.Replace(remove_letterH, "M", ":"),
					remove_letterS = Text.Replace(remove_letterM, "S", "")
				in 
					remove_letterS
        in
            res,
	Misc.Wait   	 	= // задержать действие на указанное количество секунд (аналог Function.InvokeAfter)
        /*
            Задержать данное действие на указанное количество секунд.
			Эта функция устарела из-за добавления Function.InvokeAfter(), см.:
        	link:	https://cwebbbi.wordpress.com/2015/04/30/using-function-invokeafter-in-power-query/

			Usage:	Misc.Wait(0.5, ()=> Web.Contents("www.bing.com"))
            Result: [whatever result of the given action, except 0.5 seconds slower]
        */

        (seconds as number, action as function) =>
        if (
            List.Count(
                List.Generate(
                    () => DateTimeZone.LocalNow() + #duration(0,0,0,seconds),
                    (x) => DateTimeZone.LocalNow() < x,
                    (x) => x
                )
            ) = 0
        )
        then null
        // this if ... then null never triggers, but its purpose is to make the function depend on the waiting loop finishing
        else action(),
    
    
    
	//===========================
	// Record
	//===========================
	Record.Rename        = // переименовывает Имя записи, используя лямбду (передаваемые значения x,y)
        /*
            Description:	Переименуйте запись, используя заданную лямбду (передаваемые значения x,y)
            Usage:			= F[Record.Rename]([A=1, B=2], (x,y)=> x & Text.From(y))
            Result: 		[A1 = 1, B2 = 2]
        */

        (Rec as record, Lambda as function) as record =>
        let
            Keys     = Record.FieldNames(Rec),
            Values   = Record.FieldValues(Rec),
            Renamed  = List.Transform(Keys, each Lambda(_, Record.Field(Rec, _))),
            Recorded = Record.FromList(Values, Renamed),
            Return   = Recorded
        in
            Return,

    Record.Transform     = // преобразовывает Значение записи, используя лямбду (передаваемые значения x,y)
        /*
            Description:	Преобразовывает VALUE записи, используя заданную лямбду (переданные значения x,y)
            Usage:          F[Record.Transform]([A=1, B=2], (x,y) => x & Text.From(y))
            Result: 		[A="A1", B="B2"]
        */

        (Rec as record, Lambda as function) as record =>
        let
            Keys        = Record.FieldNames(Rec),
            Transformed = List.Transform(Keys, each Lambda(_, Record.Field(Rec, _))),
            Recorded    = Record.FromList(Transformed, Keys),
            Return      = Recorded
        in
            Return,

    Record.TransformJoin = // возвращает строку из Имени и Значения записи (с использованием лямбды и разделителя)
        /*
            Description:	Сокращение для возврата строкового представления (с использованием заданной лямбды) записи
            Usage:			Record.TransformJoin([A=1, B=2], each _ & "=" & Text.From(Record.Field(Rec, _)))
            Result: 		"A=1, B=2"
        */

        (Rec as record, Lambda as function, optional Delimiter as text) as text =>
        let
            Delimiter   = if (Delimiter<>null) then Delimiter else ", ",
            Keys        = Record.FieldNames(Rec),
            Transformed = List.Transform(Keys, each Lambda(_, Record.Field(Rec,_))),
            Combined    = Text.Combine(Transformed, Delimiter),
            Return      = Combined
        in
            Return,

		
	//===========================
	// Value
	//===========================
	Value.TypeText 	 = 
		//
		(value as any) => 
			if value is binary then "binary" else
			if value is date then "date" else
			if value is datetime then "datetime" else
			if value is datetimezone then "datetimezone" else
			if value is duration then "duration" else
			if value is function then "function" else
			if value is list then "list" else
			if value is logical then "logical" else
			if value is none then "none" else
			if value is null then "null" else
			if value is number then "number" else
			if value is record then "record" else
			if value is table then "table" else
			if value is text then "text" else
			if value is time then "time" else
			if value is type then "type" else
			if value is any then "any"
			else error "unknown -- not a primitive type!",
	Value.ToText 	 = 
        /*
            Returns a string representation of a value, which works even on containers, unlike the built-in Text.From()
            Usage:
                Value.ToText = Load("Value.ToText"),
                Value.ToText({1,2,3})
            Result: 
                "{1, 2, 3}"
        */

        let 
            Value.ToText = (Val as any, optional RecursTypes as logical) as text =>
            let
                Record.TransformJoin = Load("Record.TransformJoin"),
                Type.ToText          = Load("Type.ToText"),
                RecursTypes          = if (RecursTypes<>null) then RecursTypes else false,
                Tried                = (try Val),
                Value                =  if Tried[HasError] 
                                        then Tried[Error] 
                                        else Tried[Value],
            /*
                DurationVals = {Duration.Days, Duration.Hours, Duration.Minutes, Duration.Seconds},
                DateVals = {Date.Year, Date.Month, Date.Day},
                TimeVals = {Time.Hour, Time.Minute, Time.Second},
                ZoneVals = {DateTimeZone.ZoneHours, DateTimeZone.ZoneMinutes},
                GetNumbers = (vals as list, obj as any) as text => Text.Combine(List.Transform(vals, each Number.ToText(Function.Invoke(_, {obj}))), ","),
            */
                CaseValues = {
                //{ (x)=> (try x)[HasError], "error " & @Value.ToText((try Value)[Error], RecursTypes) },
                { (x)=> Value.Is(x, type type), Type.ToText(Value, RecursTypes) },
                { (x)=> Value.Is(x, type function),
                    let
                        Type = Value.Type(Value),
                        Params = Type.FunctionParameters(Type),
                        Reqd = Type.FunctionRequiredParameters(Type),
                        Ret = Type.FunctionReturn(Type)
                    in
                        "function (" &
                        Record.TransformJoin(Params, (k,v) =>
                            (if List.PositionOf(Record.FieldNames(Params), k) >= Reqd then "optional " else "") &
                            k & " as " & @Value.ToText(v, RecursTypes)
                        )
                        & ") as " & @Value.ToText(Ret, RecursTypes)
                },
                { (x)=> Value.Is(x, type table), "#table(" & @Value.ToText(Table.ColumnNames(Value), RecursTypes) & ", " & @Value.ToText(Table.ToRows(Value), RecursTypes) & ")"},
                { (x)=> Value.Is(x, type record), "[" &
                    Record.TransformJoin(Value, (k,v) => k & "=" & @Value.ToText(v, RecursTypes))
                & "]" },
                { (x)=> Value.Is(x, type list), "{" & Text.Combine(List.Transform(Value, each @Value.ToText(_, RecursTypes)), ", ") & "}" },
                { (x)=> x = null, "null" },
            /*
                { (x)=> Value.Is(x, type text), """" & Value & """" },
                { (x)=> Value.Is(x, type binary), "#binary(""" & Binary.ToText(Value) & """)" },
                { (x)=> Value.Is(x, type date), "#date(" & GetNumbers(DateVals, Value) & ")" },    //alt: Date.ToText(Value)
                { (x)=> Value.Is(x, type time), "#time(" & GetNumbers(TimeVals, Value) & ")" },    //alt: Time.ToText(Value)
                { (x)=> Value.Is(x, type datetime),
                    let
                        Date = DateTime.Date(Value),
                        Time = DateTime.Time(Value)
                    in
                        "#datetime(" & GetNumbers(DateVals, Date) & ", " & GetNumbers(TimeVals, Time) & ")"
                },    //alt: DateTime.ToText(Value)
                { (x)=> Value.Is(x, type datetimezone),
                    let
                        DateTime = DateTimeZone.RemoveZone(Value),
                        Date = DateTime.Date(DateTime),
                        Time = DateTime.Time(DateTime)
                    in
                        "#datetimezone(" & GetNumbers(DateVals, Date) & ", " & GetNumbers(TimeVals, Time) & ", " & GetNumbers(ZoneVals, Value) & ")"
                },    //alt: DateTimeZone.ToText(Value)
                { (x)=> Value.Is(x, type duration), "#duration(" & GetNumbers(DurationVals, Value) & ")" },    //alt: Duration.ToText(Value)
            //    { (x)=> Value.Is(x, type logical), Logical.ToText(Value) },
            //    { (x)=> Value.Is(x, type number), Number.ToText(Value) },
                { (x)=> true, Text.From(Value) }
            */
                { (x)=> true, Expression.Constant(Value) }
                },
                Return = List.First(List.Select(CaseValues, each _{0}(Value))){1}
            in Return
        in Value.ToText,

    Value.TypeToText = 
        /*
            Returns a simple string representation of a value's type, which allows easy filtering, unlike the built-in Value.Type()
            Usage:
                let
                    Value.TypeToText = Load("Value.TypeToText")
                in
                    Value.TypeToText({1,2,3})
            Result: \
                "list"
        */

        (Value as any, optional Recurs as logical) as text =>
        let
            Recurs = if (Recurs<>null) 
                     then Recurs 
                     else false,
            
            // Type.ToText = Load("Type.ToText"),
			Type.ToText = F[Type.ToText],

            Type = Value.Type(Value),
            ToText = 
                if Value.Is(Value, type type) and Recurs 
                then "type " & 	Type.ToText(Value, Recurs)
                else 			Type.ToText(Type, Recurs),
        /*
            CaseValues = {
            { (x)=> (try x)[HasError], "error" },
            { (x)=> x = null, "null" },
            { (x)=> Value.Is(x, type type), "type"},
            { (x)=> Value.Is(x, type function), "function"},
            { (x)=> Value.Is(x, type table), "table"},
            { (x)=> Value.Is(x, type record), "record"},
            { (x)=> Value.Is(x, type list), "list"},
            { (x)=> Value.Is(x, type binary), "binary"},
            { (x)=> Value.Is(x, type logical), "logical"},
            { (x)=> Value.Is(x, type number), "number"},
            { (x)=> Value.Is(x, type text), "text"},
            { (x)=> Value.Is(x, type date), "date"},
            { (x)=> Value.Is(x, type time), "time"},
            { (x)=> Value.Is(x, type datetime), "datetime"},
            { (x)=> Value.Is(x, type datetimezone), "datetimezone"},
            { (x)=> Value.Is(x, type duration), "duration"},
            { (x)=> true, "?"}
            },
            Return = List.First(List.Select(CaseValues, each _{0}(Value))){1}
        */
            Return = ToText
        in 
            Return,

    Value.WaitFor    = 
        //author: Curt Hagenlocher
        //https://gist.github.com/CurtHagenlocher/68ac18caa0a17667c805

        (producer as function, interval as function, optional count as number) as any =>
        let
            list = List.Generate(
                //  start: first try, no result
                    () => {0, null},
                
                //  condition: stop if we have the result (try count null'd) or we've exceeded the max tries
                    (state) => state{0} <> null and (count = null or state{0} < count),
               
                //  next: stop try tally if we have our result, otherwise check again and tally a try
                    (state) =>  if state{1} <> null
                                then {null, state{1}}
                                else {  1 + state{0}, 
                                        Function.InvokeAfter(
                                            () => producer(state{0}), 
                                            interval(state{0})
                                        )},
                
                //  transformer: only return the result, not try tally
                    (state) => state{1})
        in
            List.Last(list),

	//===========================
	// Web
	//===========================
    Web.ContentsCustomRetry = 
        /*
            This is an example of how one can use custom handling of a web response based on the request's response status.
            author: Curt Hagenlocher
            https://gist.github.com/CurtHagenlocher/68ac18caa0a17667c805
        */

        (url as text, optional options as record) => 
        let
            Value.WaitFor = Load("Value.WaitFor")
        in
            Value.WaitFor(
                (i) =>
                    let
                        options2 = if options = null then [] else options,
                        options3 = options2 & (if i=0 then [] else [IsRetry=true]),
                        result   = Web.Contents(url, options3 & [ManualStatusHandling={429}]),
                        buffered = Binary.Buffer(result), // avoid risk of double request
                        status   = if buffered = null then 0 else Value.Metadata(result)[Response.Status],
                        actualResult = if status = 429 then null else buffered
                    in
                        actualResult,
                (i) => #duration(0, 0, 0, i*0.1)
            ),

    Web.Curl = 
        /*
            Get a curl command string for a given url and options (as used in Web.Contents()) for debugging purposes.
            Usage:
                Web.Curl = Load("Web.Curl"),
                Web.Curl("http://item.taobao.com/item.htm", [Query=[id="16390081398"]])
            Result: 
                'curl "http://item.taobao.com/item.htm?id=16390081398" -v'
        */

        (url as text, optional options as record) as text =>
        let
            //url = "http://item.taobao.com/item.htm?id=16390081398",
            //options = [Query=null],

            query   = options[Query],
            headers = options[Headers],
            qList   = List.Transform(Record.FieldNames(query), each _ & "=" & Record.Field(query, _)),
            hList   = List.Transform(Record.FieldNames(headers), each " -H """ & _ & ": " & Record.Field(headers, _) & """"),
            qJoined = try "?" & Text.Combine(qList, "&") otherwise "",
            hJoined = try Text.Combine(hList, "") otherwise "",
            Return  = "curl """ & url & qJoined & """" & hJoined & " -v"
        in
            Return,

    Web.FetchSequentially = 
        /*
            Sequentially scrape a given list of URLs with a given minimum delay between fetches
            Usage:
                let
                    Web.FetchSequentially = Load("Web.FetchSequentially"),
                    BaseUrl = "http://example.com/?p=",
                    Pages = List.Numbers(1, 5),
                    Urls = List.Transform(Pages, each BaseUrl & Number.ToText(_))
                in
                    Web.FetchSequentially(Urls)

            Result: 
                [a list of decoded contents for each of the input URLs]
        */

        (
            Urls as list, //type {text}
            optional Delay as number,       //in seconds, default 1
            optional Encoding as number,    //https://msdn.microsoft.com/en-us/library/windows/desktop/dd317756(v=vs.85).aspx
            optional Options                //see options below
        ) as list =>

        let
            Web.Scrape = Load("Web.Scrape"),
            Delay    = if (Delay    <> null) then Delay else 1,
            Encoding = if (Encoding <> null) then Encoding else TextEncoding.Utf8,
            Options  = if (Options  <> null) then Options else [
                //ApiKeyName = "",
                //Content = "",
                Query = [],
                Headers = []
            ],
            Count = List.Count(Urls)
        in

        List.Buffer(
            List.Skip(
                List.Generate(
                    () => [
                        i = 0,
                        Page = null
                    ],
                    each [i] <= Count,
                    each let
                        Url = Urls{[i]},
                        GetPage = (uri as text) => Text.FromBinary(
                            //Binary.Buffer(Web.Contents(uri, Options))
                            Web.Scrape(uri, Options)
                        , Encoding)
                    in [
                        i = [i] + 1,
                        Page = Function.InvokeAfter(()=>GetPage(Url), #duration(0,0,0,Delay))
                    ],
                    each [Page]
                )
            )
        ),

    Web.Scrape =
        /*
        Scrape a web page, raising an error with a curl command for debugging purposes in case the response is empty.
        Usage:
            Web.Scrape = Load("Web.Scrape"),
            Web.Scrape("http://google.com", [#"Referer"="http://google.com"])
        Result: 
            a binary representation of the Google front-page

        Загружает страницу через бинарный файл и преобразование его в Csv 
        По умолчанию кодировка 1251 - это опции Web.Contents. Вот эти Csv.Document(to,[Delimiter=",", Columns=5, Encoding=1251, QuoteStyle=QuoteStyle.None])
        */

        (url as text, optional options as record) as binary =>

        let
            Web.Curl = Load("Web.Curl"),
            Response = Web.Contents(url, options),
            Buffered = Binary.Buffer(Response),
            Meta     = try Value.Metadata(Response) otherwise null,
            Status   = if Buffered = null then 0 else Meta[Response.Status],
            Return   = if Status = 0 or Status >= 400  // Binary.Length(Buffered) = 0
                       then error Error.Record("ScrapeFailed", Web.Curl(url, options), Meta)
                       else Buffered
        in
            Return,

    Web.TimeAndDateCom.GetCountries = 
        /*
            Function returns a table with ID and Country Name used on service http://timeanddate.com
        */

        let
            Source       = Table.FromColumns({Lines.FromBinary(Web.Contents("http://www.timeanddate.com/calendar/"))}),
            FilteredRows = Table.SelectRows(Source, each Text.Contains([Column1], "select id")),
            FullText     = FilteredRows{0}[Column1],
            SelectText   = Text.Range( FullText, Text.PositionOf( FullText, "<select"), Text.PositionOf( FullText, "</select" ) - Text.PositionOf( FullText, "<select" ) ),
            TextToList   = Text.Split( SelectText, "option value="),
            RemFirstRow  = List.Skip(TextToList,1),
            ReplacedClosingTag = List.ReplaceValue(RemFirstRow,"</option><","",Replacer.ReplaceText),
            ConvertedtoTable   = Table.FromList(ReplacedClosingTag, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
            SplitIDandName     = Table.SplitColumn(ConvertedtoTable,"Column1",Splitter.SplitTextByEachDelimiter({">"}, QuoteStyle.Csv, false),{"ID", "Country"}),
            ReplacedSelected   = Table.ReplaceValue(SplitIDandName," selected","",Replacer.ReplaceText,{"ID"}),
            ReplacedLastClosingTag = Table.ReplaceValue(ReplacedSelected,"</option>","",Replacer.ReplaceText,{"Country"}),
            RemovedDuplicates  = Table.Distinct(ReplacedLastClosingTag),
            SortedRows         = Table.Sort(RemovedDuplicates,{{"Country", Order.Ascending}})
        in
            SortedRows,
	//  Other
	Function.Profile = // профилирует время, необходимое для выполнения функции для заданных параметров.
        /*
            Description:
                Profiles the time taken to execute a function for the given parameters
                Профилирует время, необходимое для выполнения функции для заданных параметров
            
            Usage:
                Text.Between = Load("Text.Between"),
                Function.Profile = Load("Function.Profile"),
                Function.Profile(Text.Between, {"abcdef", "bc", "f"})
           
           Result: 
            	"de" meta 00:00:00
        */
    
        (fn as function, params as list) as datetime =>
        let
            TimeBefore = DateTime.LocalNow(),
            evaluated = Function.Invoke(fn, params),
            TimeAfter = (try evaluated as none otherwise DateTime.LocalNow()),
        // ^ always evaluates to otherwise, just using the expression as a dummy to force getting the time only after evaluation has finished
            TimeTaken = TimeAfter - TimeBefore
        in
            evaluated meta [taken=TimeTaken],
	
	Type.ToText 	 = 
        /*
            Returns a simple string representation of a type, which allows easy filtering
            Usage:
                Type.ToText = Load("Type.ToText"),
                Type.ToText(type list)
            Result: 
                "list"
        */

        let 
            Type.ToText =
                (Type as any, optional Recurs as logical) as text =>
        let
            Record.TransformJoin = Load("Record.TransformJoin"),
            Recurs = if (Recurs<>null) then Recurs else false,

            CaseValues = {
            { (x)=> (try x)[HasError], "error" },
            { (x)=> Type.Is(x, type type), "type"},    //if Recurs then  else 
            { (x)=> Type.Is(x, type function), "function"},
            { (x)=> Type.Is(x, type table), if Recurs then "table " & @Type.ToText(Type.TableRow(NonNull), Recurs) else "table"},
            { (x)=> Type.Is(x, type record), if Recurs then
                let
                    Record = Type.RecordFields(NonNull)
                in "[" & Record.TransformJoin(Record, (k,v) =>
                    (if v[Optional] then "optional " else "") & Expression.Identifier(k) & " = " & @Type.ToText(v[Type], Recurs)
                ) & "]"
            else "record"},
            { (x)=> Type.Is(x, type list), if Recurs then "{" & @Type.ToText(Type.ListItem(NonNull), Recurs) & "}" else "list"},
            { (x)=> Type.Is(x, type binary), "binary"},
            { (x)=> Type.Is(x, type logical), "logical"},
            { (x)=> Type.Is(x, type number), "number"},
            { (x)=> Type.Is(x, type text), "text"},
            { (x)=> Type.Is(x, type date), "date"},
            { (x)=> Type.Is(x, type time), "time"},
            { (x)=> Type.Is(x, type datetime), "datetime"},
            { (x)=> Type.Is(x, type datetimezone), "datetimezone"},
            { (x)=> Type.Is(x, type duration), "duration"},
            { (x)=> Type.Is(type anynonnull, x), "anynonnull"},
            { (x)=> Type.Is(type null, x), "null"},
            { (x)=> Type.Is(None.Type, x), "none"},
        //    { (x)=> Type.Is(type any, x), "any"},
            { (x)=> true, "?"}
            },
            NonNull = Type.NonNullable(Type),
            Return = if Type.Is(type any, Type) then "any"
            else (if Type.IsNullable(Type) then "nullable " else "")
            & List.First(List.Select(CaseValues, each _{0}(NonNull))){1}
        in Return
        in Type.ToText,

    Vlookup 		 = 
        // originally created by Ken Puls
        // http://www.excelguru.ca/blog/2015/01/28/creating-a-vlookup-function-in-power-query/

        (   lookup_value as any, 
            table_array as table, 
            col_index_number as number, 
            optional approximate_match as logical 
        ) as any =>

        let
            /* Provide optional match if user didn't */
            matchtype = if approximate_match = null 
                        then true 
                        else approximate_match,

            /* Get name of return column */
            Cols            = Table.ColumnNames(table_array),
            ColTable        = Table.FromList(Cols, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
            ColName_match   = Record.Field(ColTable{0},"Column1"),
            ColName_return  = Record.Field(ColTable{col_index_number - 1},"Column1"),

            /* Find closest match */
            SortData        = Table.Sort(table_array,{{ColName_match, Order.Descending}}),
            RenameLookupCol = Table.RenameColumns(SortData,{{ColName_match, "Lookup"}}),
            RemoveExcess    = Table.SelectRows(RenameLookupCol, each [Lookup] <= lookup_value),
            ClosestMatch    =
                if Table.IsEmpty(RemoveExcess)=true
                then "#N/A"
                else Record.Field(RemoveExcess{0},"Lookup"),

            /* What should be returned in case of approximate match? */
            ClosestReturn   =
                if Table.IsEmpty(RemoveExcess)=true
                then "#N/A"
                else Record.Field(RemoveExcess{0},ColName_return),

            /* Modify result if we need an exact match */
            Return =
                if matchtype = true
                then ClosestReturn
                else if lookup_value = ClosestMatch
                     then ClosestReturn
                     else "#N/A"

        in
            Return
    	
	],  // конец библиотеки extensionLibrary

LibPQ      = [ // много функций по тестированию функций. Хорошо, но сложновато
	Link = "// https://github.com/sio/LibPQ/blob/master/Modules/Folder.Latest.pq", 
	Tests.ConcatenateRows = 
		[
			Table.ConcatenateRows = F[Table.ConcatenateRows],
			data       = {1,0,2,0,3,0,0,4,5},
			headers    = {"foo", "bar", "baz", "sid"},
			TableOneA  = Table.FromColumns({data}, {headers{0}}),
			TableOneB  = Table.FromColumns({data}, {headers{1}}),
			TableOneC  = Table.FromColumns({data}, {headers{2}}),
			TableTwo   = Table.FromColumns({data, data}, List.FirstN(headers, 2)),
			TableThree = Table.FromColumns({data, data, data}, {headers{2}, headers{0}, headers{1}}),

			testTwoOneColumnTables =
				Assert[Equal](
					Table.ConcatenateRows(TableOneA, TableOneB),
					TableTwo
				),

			testOneColumnAndTwoColumnCombined =
				Assert[Equal](
					Table.ConcatenateRows(TableOneC, TableTwo),
					TableThree
				),

			/** Import assertion functions **/
			Assert = F[UnitTest.Assert]
		] meta [LibPQ.TestSuite = 1]
		,
	
	UnitTest.Constants 	  = // Constants for LibPQ UnitTest framework
		[
			Error.Reason = "LibPQ.AssertionError",	/* Default error reason for failed tests */
			Test.Prefix = "test",					/* All tests have to be stored in fields which names start with the prefix */
			Suite.MetaField = "LibPQ.TestSuite",	/* Metadata field that indicates the record is LibPQ test suite */
			Suite.Runners = [
				// [test suite version : test runner module name]
				// 	Test runner is a function that takes one argument (test suite),
				// 	runs it and returns test results as a table structured the same as
				// 	the output of UnitTest.Run (reference test runner)
				1 = "UnitTest.Run",
				Facts = "UnitTest.Facts.Summarize"
			]
		]
		,
	UnitTest.Assert  	  = // A collection of assertion functions for LibPQ UnitTest framework
		/*
			Calling an assertion function results in one of three outcomes:
			- If assertion is not true, the function has to raise an error with reason "LibPQ.AssertionError" (test FAILED)
			- If an error occurs while calculating the assertion value, the function passes that error up unchanged (test ERROR)
			- If assertion is true, the function returns any value without raising an error. The returned value is not relevant (test PASSED)
		*/
		[
			/** Default error reason **/
				Error.Reason = F[UnitTest.Constants][Error.Reason],

			/** Basic assertion function. Check if expression is true **/
				True = (expression, optional message as nullable text, optional detail) =>
					() =>
					let
						Message = if message = null then "value is not true" else message,
						Detail = if detail = null then expression else detail,
						Return =
							if expression = true
							then expression
							else error Error.Record(Error.Reason, Message, Detail)
					in
						Return,

			/** Check if expression is false **/
				False = (expression, optional message as nullable text, optional detail) =>
					let
						Message = if message = null then "value is not false" else message,
						Detail = if detail = null then expression else detail,
						Return = True(expression = false, Message, Detail)
					in
						Return,

			/** Check if a and b are equal **/
				Equal = (a, b, optional message as nullable text, optional detail) =>
					let
						Message = if message = null then "values are not equal" else message,
						Detail = if detail = null then {a,b} else detail,
						Return = True(a = b, Message, Detail)
					in
						Return,

			/** Check if a and b are not equal **/
				NotEqual = (a, b, optional message as nullable text, optional detail) =>
					let
						Message = if message = null then "values are equal" else message,
						Detail = if detail = null then {a,b} else detail,
						Return = False(a = b, Message, Detail)
					in
						Return,

			/** Check if zero-argument function raises error **/
				Raises = (func, reason as text, optional message as nullable text, optional detail) =>
					let
						Message = if message = null then "does not raise " & reason else message,
						Detail = if detail = null then func else detail,
						Reason = try (try func())[Error][Reason] otherwise null,
						Return = True(Reason = reason, Message, Detail)
					in
						Return,

			/** Same as Raises but with argument list **/
				InvokeRaises = (func, args as nullable list, reason as text, optional message as nullable text, optional detail) =>
					Raises(() => Function.Invoke(func, args), reason, message, detail)
		]
	],

buch       = [ // библиотека Михаила https://www.youtube.com/playlist?list=PL0iH5kvb4jwTFO_XCLsZ2Frw-czEwKdac
    readme = "// Небольшая библиотека для получения данных из файлов пакета MS Office (@buchlotnik)",
	read_word 						= // возвращает список таблиц из файла Word формата *.docx
		/*
			Описание:		см Word.TablesList 
			Пример:			= F[Word.TablesList](File.Contents("F:\Название Файла.docx"))
		*/
		(file) =>
			[	getTable = (xml)=> // функция возвращает таблицы из xml разметки
				[	f=(x)=>[a = Table.SelectRows(x,(r)=>r[Name]="tr")[Value],
							b = List.Max(List.Transform(a,Table.RowCount)),
							c = Table.FromList(a,g,b)
						]  [c],
						
					g=(x)=>List.Transform(x[Value],h),
						
					h=(x)=>Text.Combine(List.Transform(Table.SelectRows(x,(r)=>r[Name]="p")[Value],i),"#(lf)"),
						
					i=(x)=>[a = Table.SelectRows(x,(r)=>r[Name]="r")[Value],
							b = (x)=> Table.SelectRows(x,(r)=>r[Name]="t")[Value],
							c = List.Combine(List.Transform(a,b)),
							d = List.Select(c,(x)=>Value.Is(x,Text.Type)),
							f = Text.Combine(d)
						]  [f],
					to = f(xml)
				]  [to],
				
				from  = fxUnzip2016(file),
				xml   = Xml.Document(from{[FileName="word/document.xml"]}[Content]){[Name="document"]}[Value]{[Name="body"]}[Value],
				filtr = Table.SelectRows(xml, each ([Name] = "tbl"))[Value],
				to    = List.Transform(filtr, getTable)
			]  [to],
		
	Word.CountListAndTable			= // возвращает количество листов в документах папки .docx (с учетом подпапок)
		/*  
			Пример		F[Word.CountListAndTable]("F:\1 РАБОТА - НИР")
			Результат 	таблица с именем файлов и колонкой с количеством листов и количеством таблиц в файле
		*/
		(pathFolder as text) =>
		let
			f=(x)=>[ a = unzip(x){[Name="docProps/app.xml"]}[Value],
					b = Number.From(Xml.Tables(a){0}[Pages])
				][b],
			
			unzip = Expression.Evaluate(Text.FromBinary(Web.Contents("https://raw.githubusercontent.com/buchlotnik/buchlotnik_functions/main/buchOfficePack")),#shared)[fxUnzip],
			from  = Folder.Files(pathFolder), // путь к папке
			filtr = Table.SelectRows(from,(r)=>r[Extension]=".docx" and not Text.Contains(r[Name],"~")),
			tbl   = Table.SelectColumns(filtr,{"Name","Content","Folder Path"}),
			tr    = Table.TransformColumns(tbl,{"Content",f}),
						    
			removeErr  = Table.ReplaceErrorValues(tr, {{"Content", null}}),
			rename     = Table.RenameColumns(removeErr,{{"Content", "Количество листов"}}),
    		addTblList = Table.AddColumn(rename,"tablelist",each F[Word.TablesList](File.Contents([Folder Path] & [Name]))),
    		countTable = Table.AddColumn(addTblList, "Количество таблиц", each List.Count([tablelist])),
    		delcol     = Table.ReorderColumns(
							Table.RemoveColumns(countTable,{"Folder Path"}),
							{"Name", "Количество листов", "Количество таблиц", "tablelist"}
						 )
		in
			delcol,
	
	Word.TablesList 			  	= // возвращает список таблиц из файла Word формата *.docx
		/*
			Описание:		Возвращает список таблиц в файле Word формата *.docx
			Пример:			F[Word.TablesList](File.Contents("F:\1 РАБОТА - НИР\_НИР Толкачева (2023)\Глава - Корпоративная отчетность (Медведев).docx"))
			Зависимость:	функция Unzip
		
			Алгоритм:		функция последовательно «матрёшкой функций» разбирает «матрешку xml»
				from  – получили содержимое файла через UnZip
				xml   – из содержимого получаем конкретно document.xml, в нем document, в нем body
				filtr – выбрали только таблицы - tbl (если вам нужны не таблицы, а текст – выбирайте p)
				to    – вытащили из xml сами таблицы функцией getTable
		
			Подробнее про getTable:
				to – итогом работы функции является применение функции f к xml-содержимому
				f  – на шаге:
					шаг a – вынимаем только теги tr – это строки таблицы, 
					шаг b – находим максимальную длину строки (шаг нужен, поскольку таблицы могут быть с объединёнными ячейками),
					шаг с – собираем таблицу с использованием вспомогательной g
				g – возвращает список, но к каждому элементу применяет h
				h – собирает текст через разрыв строки (в таблицах тоже бывают абзацы), применив к каждому абзацу функцию i
				i – докапывается до текста:
					a – берет теги "r"
					b – функция вынимания тега "t"
					c – получает из каждого элемента "t"
					d – оставляет только текстовое содержимое
					f – собирает куски в единый текст
			*/
		(file) =>
			[	getTable = (xml)=> // функция возвращает таблицы из xml разметки
				[	f=(x)=>[a = Table.SelectRows(x,(r)=>r[Name]="tr")[Value],
							b = List.Max(List.Transform(a,Table.RowCount)),
							c = Table.FromList(a,g,b)
						]  [c],
					g=(x)=>List.Transform(x[Value],h),
					h=(x)=>Text.Combine(List.Transform(Table.SelectRows(x,(r)=>r[Name]="p")[Value],i),"#(lf)"),
					i=(x)=>[a = Table.SelectRows(x,(r)=>r[Name]="r")[Value],
							b = (x)=> Table.SelectRows(x,(r)=>r[Name]="t")[Value],
							c = List.Combine(List.Transform(a,b)),
							d = List.Select(c,(x)=>Value.Is(x,Text.Type)),
							f = Text.Combine(d)
						]  [f],
					to = f(xml)
				]  [to],
				
				from  = fxUnzip2016(file),
				xml   = Xml.Document(from{[FileName="word/document.xml"]}[Content]){[Name="document"]}[Value]{[Name="body"]}[Value],
				filtr = Table.SelectRows(xml, each ([Name] = "tbl"))[Value],
				to    = List.Transform(filtr, getTable)
			]  [to],
	
	fxUnzip2016     			  	= // функция считывает содержимое zip-архива и возвращает таблицу с полями FileName и Content 
		/* 	
			Функция считывает содержимое zip-архива и возвращает таблицу с полями FileName - имя файла 
			(с путём, если он в подпапке) и Content - бинарное содержимое конкретного файла. 
			Кодировка требуется для корректного распознавания не латинских имён файлов 
			(для офисных документов указывать необязательно), по умолчанию 866 - кодировка DOS с поддержкой кириллицы 
		*/
		[   func = (ZIP, optional cp)=>
				[   ui16 = BinaryFormat.ByteOrder(BinaryFormat.UnsignedInteger16, ByteOrder.LittleEndian),
					ui32 = BinaryFormat.ByteOrder(BinaryFormat.UnsignedInteger32, ByteOrder.LittleEndian),
					b = (x) => BinaryFormat.Binary(x),
					c = if cp is null then 866 else cp,
					f = (x) => try Binary.Decompress(x, Compression.Deflate) otherwise null,
					g = (x) => BinaryFormat.Transform(b(x),f),
					h = (x) => [head = BinaryFormat.Record(
											[	a 	  = b(14), 
												size  = ui32, 
												c	  = b(4), 
												name  = ui16, 
												extra = ui16])(x),
								body = BinaryFormat.Record( 
											[ 	FileName = BinaryFormat.Text(head[name],c),
												Extras   = b(head[extra]),
												Content  = g(head[size]),
												flag  	 = true])][body],
					iftrue 	 = BinaryFormat.Choice(b(26),h),
					iffalse  = BinaryFormat.Record([flag = false]),
					getfile  = BinaryFormat.Choice(ui32, (x)=> if x = 67324752 then iftrue else iffalse, type binary),
					filelist = BinaryFormat.List(getfile, each [flag] = true)(ZIP),
					remove 	 = List.RemoveLastN(filelist,1),
					to 		 = Table.FromRecords(remove, type table [FileName = text, Content = binary])
				]  [to],
			typ = type function (
						ZIP as 			(type binary meta [Documentation.FieldCaption = "бинарное содержимое (zip,xlsx,docx,pptx и т.п.)"]),
						optional cp as 	(type number meta [Documentation.FieldCaption = "кодировка", Documentation.SampleValues = {866}])
								)           
						as table meta [ 
							Documentation.Name = "UnZip (@buchlotnik)",
							Documentation.LongDescription = "Функция считывает содержимое zip-архива и возвращает таблицу с полями FileName - имя файла (с путём, если он в подпапке) и Content - бинарное содержимое конкретного файла. Кодировка требуется для корректного распознавания <b>не латинских</b> имён файлов (для офисных документов указывать необязательно), по умолчанию 866 - кодировка DOS <b>с поддержкой кириллицы</b>"
							],
			result = Value.ReplaceType(func,typ)
		][result],

	fxUnzip 					  	= // функция считывает содержимое zip-архива (версия для Word до версии 2013 включительно) 
		[func=
			(ZIP, optional options)=>
			let encod = [ a = options[Encoding]?, b = if a = null then 866 else a][b],
				compr = (x)=> if x = 0 then Compression.None else Compression.Deflate,

				u16 = BinaryFormat.ByteOrder(BinaryFormat.UnsignedInteger16,ByteOrder.LittleEndian),
				u32 = BinaryFormat.ByteOrder(BinaryFormat.UnsignedInteger32,ByteOrder.LittleEndian),

				get = (x) => BinaryFormat.Record(
					if Binary.Range(x,0,4) = #binary({0x50,0x4b,0x03,0x04})
					then [  Name  = BinaryFormat.Text(u16(Binary.Range(x,26,2)),encod),
							Extr  = BinaryFormat.Binary(u16(Binary.Range(x,28,2))),
							Value = BinaryFormat.Transform(BinaryFormat.Binary(u32(Binary.Range(x,18,4))),(y)=>Binary.Decompress(y,compr(u16(Binary.Range(x,8,2)))))]
					else []
				),

				lst = BinaryFormat.List(BinaryFormat.Choice(BinaryFormat.Binary(30),get),(x)=>x<>[])(ZIP),
				to  = Table.FromRecords(List.RemoveLastN(lst,1),type table [Name=text,Value=binary])
			in 	to,

		typ = type function (
				ZIP as (type binary meta [ Documentation.FieldCaption="ZIP - бинарное содержимое (zip, xlsx, docx, pptx и т.д.)"]), 
				optional options as record) as table meta [
						Documentation.Name = "fxUnzip (@buchlotnik)",
						Documentation.LongDescription ="функция считывает содержимое архива и возвращает таблицу с полями:<p> <b>Name</b> - имя файла (с путём к файлу) <p><b>Value</b> - бинарное содержимое файла. <p>Необязательный аргумент <b>options</b> на текущий момент поддерживает следующие поля: <p>1) <b>Encoding</b> - требуется для корректного чтения не латинских имён файлов (по умолчанию <b>866 - кириллица</b>)"],
		result = Value.ReplaceType(func,typ)
		]  [result],
    fxParseHead   					= // сворачивание многоуровневых заголовков
		/*	Ссылка 	Танк "1С.Разбираем многоуровневую шапку /  #1C - шапка"
    		Пример 	1. 	шапка из трех строк + разделитель уровней
						=F[ParseHead](from, 3, ".")	
			*/

		[ 
			func = 	(table, num, optional delim, optional fill) =>
				[
					lst = List.Buffer(Table.ToColumns(Table.TransformColumns(Table.Range(table,0,num),{},Text.From))), 
					delim = if delim=null then " " else delim,
					f=(x,y)=>List.Accumulate(   List.Zip({x,y}),
												[i=false,j={}],
												(s,c)=>[i=s[i]=true or c{0}<>null,j=if i then s[j]&{c{0}} else s[j]&{if c{0}=null then c{1} else c{0}}]
											)[j],
					g=(x)=>if fill=null then Text.Combine(x,delim) else Text.Combine(List.ReplaceValue(x,null,fill,Replacer.ReplaceValue),delim), 
					gen = List.Generate(    ()=>[i=0,l=lst{i},o=l],
											(x)=>x[i]<List.Count(lst),
											(x)=>[i=x[i]+1,l=lst{i},o=f(l,x[o])],
											(x)=>g(x[o])
										),
					out = Table.RenameColumns(Table.Range(table,num),List.Zip({Table.ColumnNames(table),gen}))
				][out],
			typ  = 	type function 
					(
						table as (type table meta [Documentation.FieldCaption = "исходная таблица"]),
						num as (type number meta [Documentation.FieldCaption = "число строк для анализа шапки"]),
						optional delim as (type text meta [Documentation.FieldCaption = "(необязательно) разделитель для названий столбцов разных уровней"]),
						optional fill as (type text meta [Documentation.FieldCaption = "(необязательно) строковое значение, подставляемое вместо отсутствующего заголовка"])
					)           
						as table meta 
						[
							Documentation.Name = "ParsHead (@buchlotnik)", 
							Documentation.Description = "функция анализирует первые несколько строк таблицы <i><b>table</b></i>, указанных в параметре  <i><b>num</b></i>, осуществляет заполнение ячеек (по принципу ""fillrigth"") при условии, что ячейки в текущем столбце выше пусты, далее по столбцам идёт объединение текста с использованием в качестве разделителя параметра  <i><b>delim</b></i>. Опционально четвертый параметр <i><b>fill</b></i> позволяет задать строковое значение, которое будет использовано для заголовков нижних уровней в случае их отсутствия в данном столбце "
						],
			res  = Value.ReplaceType(func,typ)
		]  [res],
	
	fxExcelGetCellAttributes		= //
		[
			func = (filebin, optional options) =>[
				bin   = Binary.Buffer(filebin),
				unbin = fxUnzip(bin),
				xml   = List.Buffer(Table.SelectRows(unbin,(r)=>Text.StartsWith(r[Name],"xl/worksheets/sheet"))[Value]),
				style = List.Buffer(List.Transform(Xml.Document(unbin{[Name="xl/styles.xml"]}[Value]){0}[Value]{[Name="cellXfs"]}[Value][Attributes],Record.FromTable)),
				alignment= List.Buffer(List.Transform(Xml.Document(unbin{[Name="xl/styles.xml"]}[Value]){0}[Value]{[Name="cellXfs"]}[Value][Value],(x)=>x{[Name="alignment"]}?[Attributes]?{[Name="indent"]}?[Value]?)),
				
					wb  = Table.Group(Excel.Workbook(bin,false),"Kind",{"tmp",(x)=>x}),
					xl  = wb{[Kind="Sheet"]}[tmp],
					add = Table.AddIndexColumn(xl,"xml"),
					tr  = Table.TransformColumns(add,{"xml",(x)=>xml{x}}),
					cmb = Table.CombineColumns(tr,{"xml","Data"},(x)=>fxExcelSheetAddXmlInformation(x,[Cells=true]),"Data"),
				
				styledetails    =(x)=> Table.TransformColumns(x,{"Attributes",(y)=>[a=y[s]?,b=if a=null then [] else style{Number.From(a)}][b]}),
				alignmentdetails=(x)=> Table.TransformColumns(x,{"Attributes",(y)=>[a=y[s]?,b=if a=null then [] else alignment {Number.From(a)}][b]}),
				
					rep = 	if options[StyleDetails]?=true 
							then Table.TransformColumns(cmb,{"Data",styledetails}) 
								else if options[Indent]?=true then Table.TransformColumns(cmb,{"Data", alignmentdetails }) 
							else cmb,
					def = [a=wb{[Kind="DefinedName"]}?[tmp]?,b=if a = null then #table({},{}) else a][b],
					to  = if options[SheetsOnly]?=true then rep else rep & def
				]  [to],

			typ = type function(filebin as binary, optional options as record) as table meta [
					Documentation.Name = "fxExcelGetCellAttributes (@buchlotnik)",
					Documentation.LongDescription = "функция повторят действия функции Excel.Workbook, но к таблице каждого листа добавляет информацию об атрибутах ячейки первого столбца каждой из строк"],
			result = Value.ReplaceType(func,typ)
		]  [result],

	fxExcelGetRowsAttributes	  	= // аналог Excel.Workbook, но к таблице каждого листа добавляет атрибуты строк 
		/*
			Описание	функция повторят действия функции Excel.Workbook, но к таблице каждого листа 
						добавляет информацию об атрибутах строк
			Зависит		fxUnzip2016, fxUnzip, fxExcelSheetAddXmlInformation
			Ссылка 		https://www.youtube.com/watch?v=wfESfhIg09E
			
			Пример		G:\=EXCEL - 1C\Отчет о продажах (Михаил). Тут источник и обработчик, выгрузка отчета из 1С
			Пример		
						let	path    = "G:\=EXCEL BI - мои проекты\2024.01 - Анализ Отчетности\1. Отчетность\БКС\форма 1-п (натура, годовая) ОПО\PG1221 2021.xlsx",
							from    = File.Contents(path),
							getAtr1 = F[fxExcelGetRowsAttributes](from)						// все содержимое книги
							getAtr2 = F[fxExcelGetRowsAttributes](from,[SheetsOnly = true]) // только листы
							getAtr3 = F[fxExcelGetRowsAttributes](from,[Excel2016 = true])  // файлы Excel 2016+
						in	getAtr1
			
			Результат	таблица с содержимым файла
			
			Справочно	описание атрибутов
				r 				индекс строки, начиная с 1. Это уникальный идентификатор строки в таблице
				spans			диапазон заполненных столбцов в строке. Например spans="1:5" указывает, что в строке заполнены данными ячейки в столбцах с 1 по 5
				dyDescent		смещение для выравнивания текста ниже базовой линии шрифта (десент). Например, dyDescent="0.25", что указывает на 25% десента текста от высоты шрифта.
				ht 				высота строки в пунктах. Если атрибут не указан, то высоту строки стандартная. Например, ht="15" означает, что высота строки = 15 пунктов.
				customHeight	логический атрибут, который указывает, была ли высота строки установлена вручную. Если customHeight="1", это значит, что высота строки была изменена вручную пользователем или программно. Если атрибут отсутствует или имеет значение false (или 0), строка имеет стандартную высоту
				outlineLevel	уровень вложенности строки в структуре (число от 0 до 7). Чем больше значение, тем глубже строка вложена в структуру
			
			Еще 10 возможных атрибутов
				r (Reference)		Определяет ссылку на ячейку или строку, как упомянуто ранее. Этот атрибут присутствует как у строк, так и у ячеек, обозначая их положение на листе (например, A1 для ячейки или r="1" для строки).
				s (Style Index)		Указывает индекс стиля для ячейки. Этот атрибут ссылается на стиль из коллекции стилей (style.xml). Он позволяет применить форматирование к ячейке, включая шрифт, цвет, границы и выравнивание.
				t (Type)			Определяет тип содержимого ячейки. Возможные значения:
						t="s" — строка (string)
						t="b" — булевый тип (boolean)
						t="e" — ошибка (error)
						t="n" — число (number)
						t="inlineStr" — встроенная строка (inline string)
				cm 			Указывает уровень сжатия или сворачивания строки
				hidden		Указывает, скрыта ли строка или ячейка. Если hidden="1", это означает, что строка или ячейка скрыта
				collapsed 	Определяет, свернута ли строка в группе. Если collapsed="1", строка будет отображаться свернутой в интерфейсе Excel. Этот атрибут часто используется вместе с атрибутом outlineLevel.
				mergeAcross и mergeDown: mergeAcross="2" объединяет текущую ячейку с двумя соседними справа, а mergeDown="3" объединяет ячейку с тремя строками ниже
				h (Hidden)	Определяет, скрыта ли ячейка или строка. Значение h="1" означает, что элемент скрыт
				dataValidation	Указывает на наличие правила проверки данных для ячейки
			*/

		[func=(filebin,optional options)=>
			let sheetsonly = if options[SheetsOnly]? = true then true else false,
				fxUnzip    = if options[Excel2016]?  = true then fxUnzip2016 else fxUnzip,
				bin = Binary.Buffer(filebin),
				xml = List.Buffer(Table.SelectRows(fxUnzip(bin),(r)=>Text.StartsWith(r[Name],"xl/worksheets/sheet"))[Value]),
				wb  = Table.Group(Excel.Workbook(bin,false),"Kind",{"tmp",(x)=>x}),
				xl  = wb{[Kind="Sheet"]}[tmp],
				add = Table.AddIndexColumn(xl,"xml"),
				tr  = Table.TransformColumns(add,{"xml",(x)=>xml{x}}),
				cmb = Table.CombineColumns(tr,{"xml","Data"},fxExcelSheetAddXmlInformation,"Data"),
				to  = if sheetsonly then cmb else cmb & wb{[Kind="DefinedName"]}[tmp]
			in	to,
				
		typ = 	type function(filebin as binary, optional options as record) as table 
				meta [Documentation.Name="fxExcelGetRowsAttributes (@buchlotnik)",
					  Documentation.LongDescription="функция повторят действия функции Excel.Workbook, но к таблице каждого листа добавляет информацию об атрибутах строк"],
		result = Value.ReplaceType(func,typ)
		]  [result],
	
	fxExcelSheetAddXmlInformation 	= //? к функции fxExcelGetRowsAttributes - добавляет к таблице листа дополнительную информацию из xml-разметки 
		// вспомогательная функция, добавляющая к таблице листа дополнительную информацию из xml-разметки
		[ func=(x,optional options)=>
			let xml  = Xml.Document(x{0}){0}[Value]{[Name="sheetData"]}[Value][Attributes],
				xml1 = Xml.Document(x{0}){0}[Value]{[Name="sheetData"]}[Value][Value],
				tr   = 	if options[Cells]?=true 
						then  List.Transform(xml1,
								(x) => [a = x{0}?[Attributes]?,
										b = if a = null then [] else Record.FromTable(a)
							  	 	] [b]
							  ) 
						else List.Transform(xml,Record.FromTable),
				nms  = List.Transform(xml,(x)=>x{[Name="r"]}?[Value]?),
				dict = Record.FromList(tr,nms),
				add  = Table.AddIndexColumn(x{1},"Attributes",Number.From(nms{0})),
				tr1  = Table.TransformColumns(add,{"Attributes",(x)=>Record.FieldOrDefault(dict,Text.From(x))}),
				to   = Table.ReorderColumns(tr1,{"Attributes"}&Table.ColumnNames(x{1}))
			in  to,
		
		  typ  = type function(x as list, optional options as record) as table 
				 meta [ Documentation.Name="fxExcelSheetAddXmlInformation (@buchlotnik)",
						Documentation.LongDescription="вспомогательная функция, добавляющая к таблице листа дополнительную информацию из xml-разметки"],
		  result = Value.ReplaceType(func,typ)
		] [result],

	fxGetMCode 					  	= // получает код М из файлов .xlsx 
		(file)=>
			[ 	u32  = BinaryFormat.ByteOrder(BinaryFormat.UnsignedInteger32,ByteOrder.LittleEndian),
				f=(x)=>[a=Text.Split(x," = "),b={Text.Trim(Text.Replace(a{0},"shared","")),Text.Combine(List.Skip(a)," = ")}][b],
				from = fxUnzip(file){[Name="customXml/item1.xml"]}?[Value]?,
				bin  = Binary.FromText(Xml.Document(from){0}[Value],BinaryEncoding.Base64),
				data = BinaryFormat.Choice(BinaryFormat.Binary(8),(x)=>BinaryFormat.Binary(u32(Binary.Range(x,4,4))))(bin),
				unz  = fxUnzip(data){[Name="Formulas/Section1.m"]}[Value],
				txt  = Text.FromBinary(unz)&"#(cr,lf)",
				splt = Text.Split(txt,";#(cr,lf)"),
				lst  = List.Range(splt,1,List.Count(splt)-2),
				tbl  = Table.FromList(lst,f,{"Name","Value"}),
				to   = if from=null then #table({"Name","Value"},{{null,null}}) else tbl
			][to],
	
	Table.RemoveEmptyColumns	  	= // удаляет пустые столбцы из таблицы
		[ func = (table, optional options) =>
			let	tbl = Table.Buffer(Table.Profile(table)),
				lst = Table.SelectRows(tbl,(x)=>x[Count]=x[NullCount])[Column],
				to  = Table.RemoveColumns(table,lst)
			in  to,
		  
		  typ = type function (table as table, optional options as record) as table 
			    meta [ Documentation.Name            = "fxTableRemoveEmptyColumns (@buchlotnik)",
				  	   Documentation.LongDescription = "функция, удаляющая пустые столбцы из таблицы"],
		  result = Value.ReplaceType(func,typ)
		][result],	

	Table.RenameColumnsByPositions 	= // переименовывает столбцы таблицы по их номеру
		/* 
			Описание
				1 	Функция переименовывает столбцы таблицы по их номеру
				2 	Параметры переименования задаются в виде: 
						- списка 				{номер, новое название} 
						- либо списка списков 	{ {номер1, новое название1}, {номер2, новое название2} }
				3	Положительное значение номера задает нумерацию с начала таблицы, отрицательное - с конца
			Пример
				1	переименовать первый столбец
					rename  = TableRenameColumnsByPositions(#table({"a","b","c"},{}),{1,"первый"})
					Result	= #table({"первый","b","c"},{})
				2	перименовать первый с конца столбец"
							= TableRenameColumnsByPositions(#table({"a","b","c"},{}),{-1,"первый с конца"})
					Result	= #table({"a","b","первый с конца"},{})
				3	переименовать первый и последний столбцы
							= TableRenameColumnsByPositions(#table({"a","b","c"},{}),{{1,"первый"},{-1,"последний"}})
					Result	= #table({"первый","b","последний"},{})
			*/
		[func =(table,list) =>
			[   a = List.Buffer(Table.ColumnNames(table)),
				b = List.Count(a),
				c = (x) =>{a{if x{0}>0 then x{0}-1 else b+x{0}},x{1}},
				d = if list{0} is list then List.Transform(list,c) else c(list),
				e = Table.RenameColumns(table,d)
			]  [e],
		 
		 typ = type function (
							table as (type table meta [Documentation.FieldCaption = "исходная таблица"]),
							list as (type list meta [Documentation.FieldCaption = "параметры переименования"])
						)           
						as table 
							meta [ 	Documentation.Name = "TableRenameColumnsByPositions> (@buchlotnik)",
									Documentation.LongDescription = "Функция переименовывает столбцы таблицы  по их номеру. Параметры переименования задаются в виде списка {номер, новое название} либо списка списков {{номер1, новое название1},{номер2, новое название2}}. Положительное значение номера задает нумерацию с начала таблицы, отрицательное - с конца",
									Documentation.Examples = 
									{
										[	Description = "переименовать первый столбец", 				
											Code 		= "=TableRenameColumnsByPositions(#table({""a"",""b"",""c""},{}),{1,""первый""})",
											Result		= "#table({""первый"",""b"",""c""},{})"
										],
										[	Description = "перименовать первый с конца столбец", 		
											Code 		= "=TableRenameColumnsByPositions(#table({""a"",""b"",""c""},{}),{-1,""первый с конца""})",
											Result		= "#table({""a"",""b"",""первый с конца""},{})"
										], 
										[	Description = "переименовать первый и последний столбцы", 	
											Code 		= "=TableRenameColumnsByPositions(#table({""a"",""b"",""c""},{}),{{1,""первый""},{-1,""последний""}})",
											Result		= "#table({""первый"",""b"",""последний""},{})"
										]
									}       
								],
		 result = Value.ReplaceType(func,typ)
		][result],
	
	fxTableSetColumnTypes 			= // типизация столбцов по содержимому. Июнь 2025
		/*

		*/
		
		let 
			func = (tbl as table, optional options as record) as table => [
				// опции
				n     = if options[rows]? 	 	= null then 100  else options[rows],
				cul   = if options[culture]? 	= null then "ru" else options[culture],
				tr 	  = if options[transform]? 	= null then true else options[transform],
				f_val = if options[deep]? 		= true then g 	 else Value.Type,
				
				// функции преобразования
				f_lst = (x)=>Type.Union(List.Transform(x,f_tr)),
    			f_tr  = if tr then (x)=>f_val(Value.FromText(x,cul)) else f_val,
				
				g = (x) => 
					if x is number then if Number.Mod(x,1)=0 then Int64.Type else Number.Type
					else if x is datetime then if Date.Year(x)=1899 then Time.Type meta [f=true]
						else if Time.From(x)=#time(0,0,0) then Date.Type meta [f=true]
						else DateTime.Type
					else Value.Type(x),
				
				// превращение строк в набор типов
				set = List.Buffer(List.Transform(List.Zip(List.FirstN(Table.ToList(tbl,(x)=>x),n)),f_lst)),
				nms = List.Buffer(Table.ColumnNames(tbl)),
				zip = List.Zip({nms,set}),
				
				// проверка, все ли надо преобразовывать
				trlst = if tr then zip else List.Select(zip,(x)=>Value.Metadata(x{1})[f]?=true),
				
				// типы для итоговой таблицы
				typ   = type table 
							Type.ForRecord(
								Record.FromList(
									List.Transform(
										set, 
										(x)=> [Type = x, Optional = false]),
								nms),
							false),

				// итоговая таблица
				to  = Value.ReplaceType(Table.TransformColumnTypes(tbl,trlst,cul),typ)
				][to],

			metadata = [
				Documentation.Name="fxTableSetColumnTypes (@buchlotnik)",
				Documentation.LongDescription="функция, типизирующая столбцы таблицы на основании их значений. <p> Обязательный аргумент - <b>таблица</b> <p> Необязательный аргумент - <b>запись</b> с допустимыми полями:<p> <b>culture</b> - локаль, которую следует использовать при преобразовании типов столбцов <p> <b>rows</b> - количество строк, по которым определяется тип (по умолчанию 100), <p> <b>transform</b> - показывает, нужно ли преобразовывать значения в столбцах или констатировать текущие, по умолчанию <i> true </i>  <p> <b> deep</b> - глубокая оценка,  по умолчанию <i>false</i> (если <i>true</i> - анализирует числа на наличие целых, анализирует датывремена на наличие просто даты или просто времени)"],
			
			to = Value.ReplaceType(func, Value.Type(func) meta metadata)
		in  to,
	
	// 
	RowsOutlineMiha = //* иерархия при выгрузке из 1С! смотри комертарии к fxExcelGetRowsAttributes 
		/*
			Описание	функция таблице каждого листа добавляет информацию об атрибутах строк, в том числе у уровень иерархии
			Зависит		fxUnzip
			Ссылка 		https://www.youtube.com/watch?v=wfESfhIg09E
		*/

			let
				//	Загружаем функцию UnZip, которая будет распаковывать Excel файл
					unzip = Expression.Evaluate(Text.FromBinary(Web.Contents("https://raw.githubusercontent.com/buchlotnik/buchlotnik_functions/main/UnZip.pq")),#shared),
				
				//	Читаем файл Excel с заданного пути и сохраняет его в буфер
					bin   = Binary.Buffer(File.Contents("G:\=EXCEL - 1C\Иерархия (сложная)\Выгрузки из 1С.xlsx")),
				
				//	Обработка XML из Excel	
					//  Читаем XML-файл листа Excel (sheet1.xml), содержащий данные о строках
					//	Извлекается список 1 - val: Уровни иерархии (outlineLevel)
					//	Извлекается список 2 - nms: Индексы строк (r)
					xml   = Xml.Document(unzip(bin){[FileName="xl/worksheets/sheet1.xml"]}[Content]){0}[Value]{[Name="sheetData"]}[Value][Attributes],
					val   = List.Transform(xml,(x)=>x{[Name="outlineLevel"]}?[Value]?),
					nms   = List.Transform(xml,(x)=>x{[Name="r"]}?[Value]?),

				//  Выделение иерархии в таблице
					// 	dict:	Создаётся запись (Record), где ключи — это индексы строк, а значения — уровни иерархии. 
					//	sh:  	Извлекаются данные первого листа из Excel.
					// 	add: 	Добавляется индексный столбец "Уровень".
					// 	to:  	Заполняется уровень иерархии для каждой строки из записи dict.	
					dict = Record.FromList(val,nms),
					sh 	 = Excel.Workbook(bin,false){0}[Data],
					add  = Table.AddIndexColumn(sh, "Уровень", Number.From(nms{0}),1),
					to	 = Table.TransformColumns(add,{"Уровень",(x)=>Record.FieldOrDefault(dict,Text.From(x))}),
				
				// можно удалить не обязательно не проверял для этого примера
					add2= Table.AddColumn(to, "Пользовательский", each null),
					reo = Table.ReorderColumns(add2,{"Пользовательский", "Column1", "Column2", "Column3", "Column4", "Column5", "Column6", "Column7", "Column8", "Column9", "Column10", "Уровень"}),
					sel = Table.SelectRows(reo, each ([Column1] <> null)),
				
				// 	убираем первые строки до строки "Итог" в пятой колонке включая саму строку
					from = 	
						let 
							last = Table.LastN( sel, (r)=>r[Column5]<>"Итог"),
							head = Table.PromoteHeaders(last),
							skip = Table.Skip(head,2),
							rem  = Table.RemoveLastN(skip,1)
						in 
							rem,
					/*		
					from = 	Table.RemoveLastN(
								Table.Skip(
									Table.PromoteHeaders(
										Table.LastN( sel, (r)=>r[Column5]<>"Итог")
									),
								2),
							1),
				   */
				// разобраться что менять и как работает!!!
				/*f=(x)=> 
					List.ReplaceRange(
						{null,null,null,null,null},		//
						Number.From( List.Last(x)??0 ),	//
						1, //
						{ x{1} }	//
					) 
						& List.RemoveLastN(List.Skip(x,2),1), */

				// 	Преобразуем каждую строку таблицы в список, заменяя первые 5 элементов и удаляя последние элементы в строках. 
					/*
						List.ReplaceRange(
							list as list, 			: Исходный список, в котором нужно произвести замену
							offset as number, 		: Индекс первого элемента для замены (нумерация начинается с нуля)
							count as number, 		: Количество элементов, которые нужно заменить, начиная с позиции offset
							replacement as list		: Новый список, который заменяет указанный диапазон
						) as list
					*/
					f=(x) as list => 
						let 
							// Результатом является новый список, где один из null заменён конкретным значением
							lst1 = [
								list  = {null,null,null,null,null},     // Список, в котором заменяем элементы = сколько уровней в шапке отчета
								index = Number.From( List.Last(x)??0 ), // Индекс, начиная с которого происходит замена. Последний элемент списка = x, либо 0, если последний элемент отсутствует
								count = 1,								// Количество элементов для замены	
								repl  = {x{1}},							// Заменяется один элемент на значение из второго элемента списка x
								to    = List.ReplaceRange(list, index, count, repl)
							][to], 
							
							// 
							lst2 = List.RemoveLastN( List.Skip(x,2), 1 ), //&
							to 	 = lst1 & lst2
						in 
							to,
					
				// список списков. В каждом списке значения колонок
					lst = 
						let f=(x)=> List.ReplaceRange( {null,null,null,null,null}, Number.From(List.Last(x)??0), 1, {x{1}} ) 
									& 
									List.RemoveLastN( List.Skip(x,2), 1 ),
							to = Table.ToList( from, f )
						in  to,
				
				// собираем таблицу из списка, заполняем вниз колонки с уровнем, фыильтруем колонку с последним уровнем
					tbl		= Table.FromList(lst,(x)=>x), 
					fill	= Table.FillDown(tbl, {"Column1","Column2","Column3","Column4"}),
					result	= Table.SelectRows(fill, each [Column5] <> null ),

				// мой пример
					typ = Table.TransformColumnTypes(result,{{"Column6", type number}, {"Column7", type number}, {"Column8", type number}, {"Column9", type number}, {"Column10", type number}, {"Column11", type number}, {"Column12", type number}, {"Column13", type number}, {"Column14", type number}}),
					del = Table.RemoveColumns(typ,{"Column7", "Column8", "Column10", "Column11", "Column13", "Column14"}),
					ren = Table.RenameColumns(del,{{"Column6", "Январь"}, {"Column9", "Февраль"}, {"Column12", "Март"}}),
					unp = Table.UnpivotOtherColumns(ren, {"Column1", "Column2", "Column3", "Column4", "Column5"}, "Атрибут", "Значение")
			in
				unp

	],

Zelensky   = [ // https://github.com/hohlick/power-query-library/blob/master/library/common/Value.ToText.m
	// иконкb pdg и svg  https://github.com/hohlick/PowerBI-Icons/blob/main/SVG/Power-BI.svg
	fnBuildPath = // иерархия в справочниках, parent (есть файл с примером, есть в телеге power Bi Group) Статья с DAX https://www.daxpatterns.com/parent-child-hierarchies/
		let 
			func = (
				Children as list, 
				Parents as list, 
				Node as nullable any, 
				optional ReverseMode as nullable logical
				) as list => 
				
				let
					// Search for the parent for the current Node
					GetParent = (Child as any)=>
						let
							ChildPosition = List.PositionOf(Children, Child),
							Parent = if ChildPosition>=0 then Parents{ChildPosition} else null
						in
							if Parent = Child or Parent = null then null else Parent,
	
					// Parents Search recursion:
					PathList = 
						List.Generate(
							()=>GetParent(Node),
							each _<>null,
							each GetParent(_)
						)
				in
					if Node = null 
					then null 
					else if ReverseMode <> true 
						 then {Node} & PathList 
						 else List.Reverse({Node} & PathList),
				
				documentation = 
					[
						Documentation.Name =  " List.BuildPath ",
						Documentation.Description = " Transforms all columns of a <code>table</code>  with one <code>function</code> and one <code>type</code>. ",
						Documentation.LongDescription = "
						Takes parent/child hierachies as the <code>Children</code> and <code>Parents</code> lists of the same size (typically columns) and transforms them to the list of <code>Parents</code> for the current <code>Node</code>.
						<br>Arguments:
							<ul><li><code>Children</code> = list of ChildID
							<li><code>Parents</code> = list of ParentID
							<li><code>Node</code> = single (current) element from Children
							<li><code>ReverseMode</code> = build list from child to parents or from parent to child
							</ul>",
						Documentation.Category = " List ",
						Documentation.Version = " 1.0 ",
						Documentation.Author = " Maxim Zelensky ",
						Documentation.Examples = 
							{
								[
									Description =  "  ",
									Code = " Table.AddColumn(Typed, ""fnBuildPath"", let children = List.Buffer(Source[Child]), parents = List.Buffer(Source[Parent]) in each fnBuildPath(children, parents, [Child], true), type list)"
									//Result = "  "
								]
							}
					]
			in
				Value.ReplaceType(func, Value.ReplaceMetadata(Value.Type(func), documentation)),

	RowsOutline = // иерархию разворачивает в отчетах 1С //! не проверял
		/*
			файл 		G:\=EXCEL - 1C (Функция МаксЗеленский Иерархия(нужен 1C новый февраль) + 1C новый февраль)
			Author: 	Maxim Zelensky, info@excel-inside.pro, http://excel-inside.pro
			Updated: 	2017-08-14
			Purpose: 	Get outline levels of rows from Excel worksheets in Power Query.
			Note: 		Included copy of Mark White's UnZip function.
			Parameters:
				FullPath
					Type: text, 
					Description: full path to workbook. Mandatory
					Example: "C:\PQ\Outline\test2.xlsx"
				
				SheetNames
					Type: any
					Description: text or list of worksheet names. Optional
						If argument: 
							not provided, 
							or null,
							or empty list {}, 
							or argument type is different from text/list, 
						then all worksheets from workbook will be analyzed.
					
					Example: {"Sheet1", "Sheet3"}
					Example: "Sheet1"
					
				AddOutlinesToData
					Type: nullable logical
					Description: defines whether add outlineLevel column to the sheet [Data] table. Optional
						If null or not provided then = true
					Example: true, false, null
			*/

		// fnGetRowsOutline

		(FullPath as text, optional SheetNames as any, optional AddOutlinesToData as nullable logical) as table =>
		let
		/* Functions	*/
		// 	UnZip function copy
			fnUnZip = (ZIPFile) => 
			let
				Header = BinaryFormat.Record([
					MiscHeader = BinaryFormat.Binary(14),
					BinarySize = BinaryFormat.ByteOrder(BinaryFormat.UnsignedInteger32, ByteOrder.LittleEndian),
					FileSize   = BinaryFormat.ByteOrder(BinaryFormat.UnsignedInteger32, ByteOrder.LittleEndian),
					FileNameLen= BinaryFormat.ByteOrder(BinaryFormat.UnsignedInteger16, ByteOrder.LittleEndian),
					ExtrasLen  = BinaryFormat.ByteOrder(BinaryFormat.UnsignedInteger16, ByteOrder.LittleEndian)    
				]),

				HeaderChoice = BinaryFormat.Choice(
					BinaryFormat.ByteOrder(BinaryFormat.UnsignedInteger32, ByteOrder.LittleEndian),
					each if _ <> 67324752             // not the IsValid number? then return a dummy formatter
						then BinaryFormat.Record([IsValid = false, Filename=null, Content=null])
						else BinaryFormat.Choice(
								BinaryFormat.Binary(26),      // Header payload - 14+4+4+2+2
								each BinaryFormat.Record([
									IsValid  = true,
									Filename = BinaryFormat.Text(Header(_)[FileNameLen]), 
									Extras   = BinaryFormat.Text(Header(_)[ExtrasLen]), 
									Content  = BinaryFormat.Transform(
										BinaryFormat.Binary(Header(_)[BinarySize]),
										(x) => try Binary.Buffer(Binary.Decompress(x, Compression.Deflate)) otherwise null
									)
									]),
									type binary                   // enable streaming
							)
				),

				ZipFormat = BinaryFormat.List(HeaderChoice, each _[IsValid] = true),

				Entries = List.Transform(
					List.RemoveLastN( ZipFormat(ZIPFile), 1),
					(e) => [FileName = e[Filename], Content = e[Content] ]
				)
			in
				Table.FromRecords(Entries),

		// 	RowsOutline
			fnRowsOutline = (WSrel as text) => 
				let
					Source = UnZipped,
					Sheet1 = Source{[FileName="xl/" & WSrel]}[Content],
					XMLContent = Xml.Tables(Sheet1,null,65001),
					sheetDataTable = XMLContent{[Name="sheetData"]}[Table],
					Filtered = Table.SelectRows(sheetDataTable, each [Name] = "row"),
					rowTable = Filtered{0}[Table],
					RemovedOtherColumns = Table.SelectColumns(rowTable,{"Attribute:r", "Attribute:outlineLevel"}, MissingField.UseNull),
					RenamedColumns = Table.RenameColumns(RemovedOtherColumns,{{"Attribute:r", "RowN"}, {"Attribute:outlineLevel", "outlineLevel"}}),
					Typed = Table.TransformColumnTypes(RenamedColumns,{{"RowN", Int64.Type}, {"outlineLevel", Int64.Type}}),
					RowIndices = List.Zip( { {List.Min(Typed[RowN])..(List.Max(Typed[RowN]))} }),
					RowIndTable = Table.AddIndexColumn(#table(type table [RowNumber=Int64.Type], RowIndices), "Index"),
					ExpandMissedRows = Table.Join(RowIndTable, {"RowNumber"}, Typed, {"RowN"},JoinKind.LeftOuter),
					RemovedOtherColumns1 = Table.SelectColumns(ExpandMissedRows,{"Index", "outlineLevel"}),
					Result = if Table.IsEmpty(sheetDataTable) then #table(type table [Index = number, outlineLevel = Int64.Type],{}) else RemovedOtherColumns1
				in
					Result,
		
		//	Подключаемся
			Source = Excel.Workbook(File.Contents(FullPath), false, true),

		// 	leave sheets only
			FilteredSheets = Table.SelectRows(Source, each ([Kind] = "Sheet")),

		// 	sheets in PQ initially in appearance order, i.e. sheets index (despite visibility)
			AddSheetsIndex = Table.AddIndexColumn(FilteredSheets, "Index", 1, 1),

		// 	check SheetNames parameter
			SheetNames = if SheetNames is text then {SheetNames} else if SheetNames is list then SheetNames else null,

		// 	filter sheets by name if provided
			FilteredByNames = if SheetNames = null or List.IsEmpty(SheetNames) then AddSheetsIndex else Table.SelectRows(AddSheetsIndex, each List.Contains(SheetNames, [Name])),

		// 	UnZip file
			UnZipped = Table.Buffer(fnUnZip(File.Contents(FullPath))),
			/*
				let
					Source = Folder.Files(Folder),
					file = Source{[Name = FileName, Folder Path = Folder & "\"]}[Content],
					UnZippedFile = Table.Buffer(fnUnZip(file))
				in
					Table.Buffer(UnZippedFile),
			*/

		// 	relations id table for sheets
			workbook =
				let
					Source = UnZipped,
					Content = Source{[FileName ="xl/workbook.xml"]}[Content],
					ImportedXML = Xml.Tables(Content,null,TextEncoding.Utf8),
					sheetsTable = ImportedXML{[Name = "sheets"]}[Table],
					sheetTable = sheetsTable{[Name = "sheet"]}[Table],
					ExpandedRel = Table.ExpandTableColumn(sheetTable, "http://schemas.openxmlformats.org/officeDocument/2006/relationships", {"Attribute:id"}, {"Attribute:id"}),
					typed = Table.TransformColumnTypes(ExpandedRel,{{"Attribute:name", type text}, {"Attribute:sheetId", Int64.Type}, {"Attribute:id", type text}})
				in
					typed,

		// 	sheets relations id to XML target files
			workbook_rels = 
				let
					Source = UnZipped,
					Filtered = Table.SelectRows(Source, each [FileName]="xl/_rels/workbook.xml.rels"),
					GetXML = Table.TransformColumns(Filtered, {"Content", each Xml.Tables(_,null,65001)}),
					XMLContent = GetXML{0}[Content]{[Name="Relationship"]}[Table],
					FilteredSheetsRel = Table.SelectRows(XMLContent, each [#"Attribute:Type"] = "http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet"),
					Removed = Table.RemoveColumns(FilteredSheetsRel,{"Attribute:Type"})
				in
					Removed,

		// 	merge relations id (via sheets index)
			MergedRelationsID = Table.Join(FilteredByNames, {"Index"}, workbook, {"Attribute:sheetId"}), 

		// 	join workbook relations
			MergedRelationsTarget = Table.Join(MergedRelationsID,{"Attribute:id"},workbook_rels,{"Attribute:Id"}),

		// 	invoke RowsOutline function to get separate index+outlineLevel table
			AddOutlineTable = Table.AddColumn(MergedRelationsTarget, "RowsOutline", each fnRowsOutline([#"Attribute:Target"]), type table),
		
		// 	Clean table
			RemovedColumns = Table.RemoveColumns(AddOutlineTable,{"Index", "Attribute:Id", "Attribute:Target", "Attribute:name", "Attribute:sheetId", "Attribute:id"}),

		// join [AddOutlineTable] and [Data] by rows index
			AddedRowsOutline = Table.AddColumn(RemovedColumns, "DataWithOutline", each Table.RemoveColumns(Table.Join([RowsOutline], {"Index"}, Table.AddIndexColumn([Data],"Index"), {"Index"}),{"Index"}), type table),

		// add outlines to Data or not
			Result = if AddOutlinesToData or AddOutlinesToData = null then AddedRowsOutline else RemovedColumns
		in
			Result,

	Value.ToJson = 
		/*	-----------------------------------------------------------------------------
			GPLv3 | https://github.com/power-query/power-query-library
			-----------------------------------------------------------------------------
			Authors	: 	Max Buyers
			Function: 	Value.ToJson
			Returns	:  	Minimized JSON-object
			Example	:  	below
			Depends	:  	Value.TypeToText, Value.ToText
			Comments:
			-----------------------------------------------------------------------------
		
			Example
				__("Value.ToJson")([
					array 	 = {1, 2, 3},
					boolean  = true,
					datetime 	 = #datetime(2013,1,3,12,4,5),
					datetimezone = #datetimezone(2012, 7, 24, 14, 50, 52.9842245, -7, 0),
					null 	= null,
					number 	= 123,
					object 	= [ a = "b", c = "d", e = "f" ],
					string 	= "Hello World"])
			
			Return
				{"array":[1,2,3],"boolean":true,"datetime":"2013-01-03T12:04:05.0000000","datetimezone":"2012-07-24T14:50:52.984-07:00","number":123,"object":{"a":"b","c":"d","e":"f"},"string":"Hello World"}
		*/
		let Value.ToJson =
			( Val as any) as text =>
			let
				Value.TypeToText 	= F[Value.TypeToText],
				Value.ToText 		= F[Value.ToText],
				Type 				= Value.TypeToText(Val),
				Sq 					= "#(2032,02DD,2034,02DD,2032)",
				Dq 					= "#(0022)",
				Quote     = (i as text) => Sq & i & Sq,
				Combine   = (i as list) => Text.Combine(i,","),
				Array     = (i as text) => "[" & i & "]",
				Object    = (i as text) => "{" & i & "}",
				Rules = [
					table   = Array(Combine(
						Table.TransformRows(Val, each @Value.ToJson(_)) )),

					record  = 
						let
							Fields    = Record.FieldNames(Val),
							Values    = Record.FieldValues(Val),
							Transform = List.Transform(Fields,
							each Quote(_) & ":" &
							@Value.ToJson(Record.Field(Val, _)))
						in 
							Object(Combine(Transform)),
					
					list = 	Array(Combine(List.Transform(Val, each @Value.ToJson(_)))),
					text    = Quote(Val),
					number  = Value.ToText(Val),
					null    = "null",
					logical = Value.ToText(Val),
					date 	= Quote(Value.ToText(Val, "YYYY-MM-DD")),
					time 	= Quote(Value.ToText(Val, "hh:mm:ss.nnnnnnn")),
					datetime = Quote(Value.ToText(Val, "YYYY-MM-DDThh:mm:ss.nnnnnnn")),
					datetimezone = Quote(Value.ToText(Val, "YYYY-MM-DDThh:mm:ss.nnnZ")),
					duration = Quote(Value.ToText(Val, "PdDhHmM[:s]S")),
					type 	= Quote(Value.TypeToText(Val)),
					binary 	= Quote(Binary.ToText(Val, BinaryEncoding.Hex))
			]
			in Text.Replace(Record.Field(Rules, Type), Sq, Dq)
		in  Value.ToJson,

	Value.ToText = // что то вроде проверки типов 
		/*
			-----------------------------------------------------------------------------
			GPLv3 | https://github.com/power-query/power-query-library
			-----------------------------------------------------------------------------
			Authors: Max Buyers
			Function: Value.ToText
			Returns:  Value with normalized to string primitive values
			Example:  below
			Depends:  Value.TypeToText
			Comments:

			------------------------------------------------------------------------
			Arguments:

			+ Value
				required: yes
				type: any
				desc: primitive or structured value

			+ format:
				required: no
				type: record or text
				desc: optional common or specified format for number/date/time values
				examples:
				[f = "YYYY-MM-DDThh:mm:ssZ"]
				[f = [
					datetime = "YYYY-MM-DDThh:mm:ss.nnnnnnn"
				, datetimezone = "YYYY-MM-DDThh:mm:ssZ"
				]

			+ culture:
				required: no
				type: text
				desc: optional culture for number/date/time values
				examples: [c = "ru-RU"]
				comments:
				+ Use National Language Support (NLS) API Reference for culture codes:
					https://msdn.microsoft.com/en-us/goglobal/bb896001.aspx
			------------------------------------------------------------------------
		*/

		let
			Value.ToText =
				(Value as any, optional format as any, optional culture as text) as any => 
				let
					format    = try format  as text otherwise try format as record otherwise null,
					culture   = try culture as text otherwise "en-US",
					Recursion = (Value) => @Value.ToText(Value, format, culture),
					
					Value.TypeToText = F[Value.TypeToText],
				//
					Type  = Value.TypeToText(Value),
					Rules = [
						null          = "",
						logical       = Logical.ToText(Value),
						number        = Number.ToText(Value,       try format[number]       as text otherwise try format as text otherwise null, culture),
						time          = Time.ToText(Value,         try format[time]         as text otherwise try format as text otherwise null, culture),
						date          = Date.ToText(Value,         try format[date]         as text otherwise try format as text otherwise null, culture),
						datetime      = DateTime.ToText(Value,     try format[datetime]     as text otherwise try format as text otherwise null, culture),
						datetimezone  = DateTimeZone.ToText(Value, try format[datetimezone] as text otherwise try format as text otherwise null, culture),
						duration      = Duration.ToText(Value,     try format[duration]     as text otherwise try format as text otherwise null),
						type          = "type",
						text          = Value,
						list          = List.Transform(Value, each Recursion(_)),
						record        = 
							let
								FieldNames  = Record.FieldNames(Value),
								FieldValues = Record.FieldValues(Value),
								Transformed = List.Transform(FieldValues, each Recursion(_))
							in 
								Record.FromList(Transformed, FieldNames),

						table	= 	Table.TransformColumns(
										Value, 
										List.Transform(
											Table.ColumnNames(Value), 
											each {_, each Recursion(_)}
										)
									),
						binary  = Binary.ToText(Value)
				]
				in Record.Field(Rules, Type)
		in 
			Value.ToText

		/*
		------------------------------------------------------------------------
		Example
		------------------------------------------------------------------------
		было __("Value.ToText")(

		F[Value.ToText] (
			#table(
				type table [
				Null = null
				, Logical = logical
				, Number  = number
				, Time    = time
				, Date    = date
				, Datetime = datetime
				, Datetimezone = datetimezone
				, Duration = duration
				, Type = type
				, Text = text
				, List = list
				, Record = record
				, Table = table
				, Binary = binary
				]
			, {
				{
					null
				, true
				, 1
				, #time(20,43,12)
				, #date(2015, 1, 1)
				, #datetime(2015, 1, 1, 21, 49, 18)
				, #datetimezone(2015, 1, 1, 21, 49, 18, 3, 0)
				, #duration(0, 0, 5, -30)
				, type {type}
				, "Hello World!"
				, {null, false, 2, #time(20,43,12), "Goodbye World!"}
				, [A = 1, B = "2"]
				, #table({"x", "x^2"}, {{1,1}, {2,4}, {3,9}})
				, #binary({0x00, 0x01, 0x02, 0x03})
				}
				, {
					null
				, false
				, 2
				, #time(12,55,1)
				, #date(2035, 1, 1)
				, #datetime(2035, 5, 5, 15, 55, 55)
				, #datetimezone(2015, 1, 1, 21, 49, 18, 3, 0)
				, #duration(0, 0, 5, -30)
				, type {type}
				, "Hello World!"
				, {null, false, 2, #time(20,43,12), "Goodbye World!"}
				, [A = 1, B = "2"]
				, #table({"x", "x^2"}, {{1,1}, {2,4}, {3,9}})
				, #binary({0x00, 0x01, 0x02, 0x03})
				}
				}
			))
		------------------------------------------------------------------------
		*/
	],

Connectors = [ 
	link1 = // много коннекторов, наверное стандартных на гитхабе microsoft
		"https://github.com/microsoft/DataConnectors/blob/master/samples/ODBC/HiveSample/HiveSample.pq",
	
	OneDriveFolderFiles 	= // коннектор к OneDrive Personal 
		(url)=>
        let
            //  Функция перекодирования ссылки в понятный формат для API
                fx = (t)=> Binary.ToText( Text.ToBinary( t, TextEncoding.Utf8 ), BinaryEncoding.Base64 ),
                API_URL = "https://api.onedrive.com/v1.0/shares/",
            
            //	тащим путь из параметра с адресом к общей папке из облака Onedrive
                FolderUrl = url,
            
            //	преобразовываем ссылку для получения токена для API
                UrlToBase64 = fx( FolderUrl ),
            
            //	заменяем всякое согласно инструкции по ссылке:
            //	https://docs.microsoft.com/ru-ru/onedrive/developer/rest-api/api/shares_get?view=odsp-graph-online#encoding-sharing-urls
                Replaced = Text.Replace( Text.Replace( Text.TrimEnd( UrlToBase64, "=" ), "/", "_" ), "+", "-" ),
            
            //	формируем итоговый текстовый параметр для передачи в RelativePath
                EncodedPath = "u!" & Replaced & "/root/children",
            
            //	тащим содержимое папки из API
                Source = Json.Document(Web.Contents( API_URL, [RelativePath = EncodedPath] ) ),
            
            //  преобразовываем полученный JSON в табличку с содержимым папки
                TableFromRecords = Table.FromRecords( Source[value] )[[name],[webUrl]],
            
            //  добавляем столбец с текстовыми параметрами для передачи в RelativePath
                AddColEncodedPaths = 
					Table.AddColumn(
						TableFromRecords,
						"GetRelativePath",
						each "u!" & fx([webUrl]) & "/root/content"
           			),
            //	достаем бинарники по сформированным ссылкам, дальше по аналогии как с обычными файлами с диска
                GetBinaries = 
					Table.AddColumn(
						AddColEncodedPaths,
						"Content",
						each Web.Contents(API_URL, [RelativePath = [GetRelativePath]] ),
						Binary.Type
					)
            in
                GetBinaries,
			
	insert_clickhouse 		= // загрузка данных в Clickhouse 
		/*	
			Link: http://directprobi.ru/blogs/power-bi-etl-zagruzka-v-bazu-dannyh-postgresql-power-query-excel-clickhouse/
			Пример:
				= 	insert_clickhouse(
						#"Последний шаг таблицы Метрики", 
						"ПОЛЬЗОВАТЕЛЬ БАЗЫ ДАННЫХ", 
						"ПАРОЛЬ ПОЛЬЗОВАТЕЛЯ", 
						"СХЕМА.ТАБЛИЦА"
					)
			Алгоритм:
			Чтобы всё работало корректно, пойдём по простому пути: 
				1. 	подготовим в базе данных таблицу из нужных столбцов. (движок MergeTree) - наверное как вариант 
				2.	затем получим аналогичную таблицу из API обычным коннектором на Power Query. 
				3.	В конце применим функцию загрузки в базу к полученной таблице, чтобы прогрузить данные в БД. 
			Важно!
				1. 	Порядок и типы столбцов в Power Query полностью аналогичны кликхаусу, иначе вставка не работает. 
					Названия столбцов кликхауса и power query могут различаться - это ни на что не влияет.
				2. 	Не забудьте заменить ВАШ ХОСТ ИЛИ ДОМЕН CLICKHOUSE:ПОРТ на значения реального хоста/домена и порта.
		*/

		(pq_table,  ch_user as text, ch_pass as text, ch_table as text)=>
		let
			dateFunc = (dat)=>
				if dat = "yesterday" then Date.ToText(Date.AddDays(Date.From(DateTime.LocalNow()) , -1),"yyyy-MM-dd") 
				else if dat = "today" then Date.ToText(Date.From(DateTime.LocalNow()),"yyyy-MM-dd")
				else if (try Number.From(Text.BeforeDelimiter(dat,"daysAgo")) otherwise 0) >0 then Date.ToText(Date.AddDays(Date.From(DateTime.LocalNow()),-1*Number.From(Text.BeforeDelimiter(dat,"daysAgo"))),"yyyy-MM-dd") 
				else dat,

			added = 
				Table.AddColumn( pq_table,  "all", each  
					"(" & Text.Combine( List.Transform( Record.ToList(_), each 
						if Value.Is(_, type text) 
						then "'"&_&"'" 
						else if Value.Is(_, type date) 
							then "'"&Date.ToText(_,"yyyy-MM-dd")&"'"
							else Text.From(_) 
					),",") & ")"
				),
			
			textview = Text.Combine(added[all],","),
			
			insert 	= 
				// Csv.Document(Web.Contents("ВАШ ХОСТ ИЛИ ДОМЕН CLICKHOUSE:ПОРТ" , 
				Csv.Document(Web.Contents("localhost", 
					[	Query 	= 
							[	user 	 = ch_user, 
								password = ch_pass, 
								query 	 = "INSERT INTO " & ch_table  &" VALUES " & textview 
							],
						Content = Binary.FromText(""),
						ManualStatusHandling = {429,400,500}
					]), 
					1,
					"",
					ExtraValues.Ignore,
					65001
				)
		in 
			insert,

	insert_postgresql_Old 	= // загрузка данных в PostgreSQL 
		/*
			Пример
				= F[insert_postgresql](fromTable, "СХЕМА.ТАБЛИЦА")
				= F[insert_postgresql](to,"newtable") // имят таблицы в базе Test1 схемы public таблицы newtable
		*/
		(pq_table,  postgresql_table as text)=>
		[
			HOST 	 = "localhost",
			DBNAME   = "Test",	
			dateFunc = (dat)=>
				if dat = "yesterday" then Date.ToText(Date.AddDays(Date.From(DateTime.LocalNow()) , -1),"yyyy-MM-dd") 
				else if dat = "today" then Date.ToText(Date.From(DateTime.LocalNow()),"yyyy-MM-dd")
				else if (try Number.From(Text.BeforeDelimiter(dat,"daysAgo")) otherwise 0) >0 then Date.ToText(Date.AddDays(Date.From(DateTime.LocalNow()),-1*Number.From(Text.BeforeDelimiter(dat,"daysAgo"))),"yyyy-MM-dd") 
				else dat,
		
			added    = 
				Table.AddColumn( pq_table, "all", each  
					"(" & 
						Text.Combine( 
							List.Transform( 
								Record.ToList(_), 
								each 
									if Value.Is(_, type text) 
									then "'"&_&"'" 
									else if Value.Is(_, type date) 
										 then "'" & Date.ToText(_,"yyyy-MM-dd")&"'"
										 else Text.From(_) 
							),
						",") & 
					")" 
				),
			
			textview = Text.Combine(added[all],","),
			delete   = 	
				Value.NativeQuery(
					PostgreSQL.Database(HOST, DBNAME),
					"TRUNCATE TABLE " & postgresql_table & ";"
				),

			insert   = 
				Value.NativeQuery( 
					PostgreSQL.Database(HOST, DBNAME),
					"INSERT INTO " & postgresql_table & " VALUES " & textview 
				),
			chdelay = Function.InvokeAfter( ()=>delete & Table.FromRecords({}), #duration(0,0,0,5) ),
			final   = chdelay & insert,
			expand  = List.Accumulate(
						final[insert], 
						Table.FromRows({}), 
						(st,cr)=> 	Function.InvokeAfter(
										()=> st & (if cr=null then Table.FromRows({}) else cr), 
										#duration(0,0,0,3)
									)
					)
		][expand],
		
	insert_postgresql 		=  
		/*
			-- 	public.newtable определение
			
			-- 	Drop table
				DROP TABLE public.newtable2;
			
			-- 	DROP TABLE public.newtable;
				CREATE TABLE public.newtable (
					"Company" varchar NULL,
					"Date" date NULL
				)

			Пример
			  = F[insert_postgresql](
					_f_bal[[Company],[Date]], "public.newtable",
					"Date","Date",
					"10000daysAgo","yesterday",
					1000, 2
				)
			*/
		(	pq_table, 
			postgresql_table as text, 
			
			postgresql_column 	as text, 
			pq_column 			as text, 
									
			date1 as text, 
			date2 as text, 

			rowlimit 	as number , 
			delay 		as number )=>

		[
			HOST 	= "localhost",	// ВАШ ХОСТ
			DBNAME  = "Test",		// ВАШЕ НАЗВАНИЕ БД
			dateFunc = 
				(dat)=>
					 if dat = "yesterday" then Date.ToText(Date.AddDays(Date.From(DateTime.LocalNow()) , -1),"yyyy-MM-dd")
				else if dat = "today" then Date.ToText(Date.From(DateTime.LocalNow()),"yyyy-MM-dd")
				else if (try Number.From(Text.BeforeDelimiter(dat,"daysAgo")) otherwise 0) >0 
					 then 	Date.ToText(
								Date.AddDays( 
									Date.From( DateTime.LocalNow() ),
									-1 * Number.From( Text.BeforeDelimiter(dat,"daysAgo") )
								),
								"yyyy-MM-dd"
							)
					 else dat,

			added   = 
				Table.AddColumn( 
					Table.SelectRows(pq_table, 
						each Date.From(Record.Field(_,pq_column)) >= Date.From(dateFunc(date1)) and 
							 Date.From(Record.Field(_,pq_column)) <= Date.From(dateFunc(date2))
					), 
					"all", 
					each	
						"(" & 
						Text.Combine( 
							List.Transform( 
								Record.ToList(_), 
								each	 if Value.Is(_, type text)   then "'" & _ & "'"
									else if Value.Is(_, type date)   then "'" & Date.ToText(_,"yyyy-MM-dd") & "'"
									else if Value.Is(_, type number) then Text.Replace(Text.From(_),",",".")
									else Text.From(_)
							),
						",") 
						& ")"
				),

			index   = Table.AddIndexColumn(added, "Индекс", 0, 1, Int64.Type),
			divide  = Table.AddColumn(index, "division", each Number.IntegerDivide([Индекс], rowlimit), Int64.Type),
			groups  = Table.Group(divide, {"division"}, {{"texts", each Text.Combine([all],","), type text}}),
			
			insert  = 
				Table.AddColumn(groups, "insert", each
					Function.InvokeAfter( ()=>
						Value.NativeQuery( 
							PostgreSQL.Database(HOST, DBNAME), 
							"INSERT INTO " & postgresql_table & " VALUES " & [texts]
						), 
						#duration(0,0,0,Number.From(delay))
					)
				),
			
			// delete  = Value.NativeQuery( 
				// 				PostgreSQL.Database(HOST, DBNAME),
				// 				"DELETE FROM " 	& postgresql_table & 
				// 				" WHERE " 		& postgresql_column & 
				// 				" >= '" 		& dateFunc(date1) & 
				// 				"' AND " 		& postgresql_column & 
				// 				" <= '" 		& dateFunc(date2) & 
				// 				"' " 
				// 			),
			Query	=  	"DELETE FROM " 	& postgresql_table & 
							" WHERE " 		& postgresql_column & 
							" >= """ 		& dateFunc(date1) & 
							""" AND " 		& postgresql_column & 
							" <= """ 		& dateFunc(date2) & """;",

			delete2 =  	Value.NativeQuery(
							PostgreSQL.Database(HOST, DBNAME),
							"DELETE FROM " 	& postgresql_table & 
							" WHERE " 		& postgresql_column & 
							" >= """ 		& dateFunc(date1) & 
							""" AND " 		& postgresql_column & 
							" <= """ 		& dateFunc(date2) & """;"
						)
						,
			delete  = 	Value.NativeQuery(
							PostgreSQL.Database(HOST, DBNAME),
								"TRUNCATE TABLE " & postgresql_table & ";"
						),

			chdelay = Function.InvokeAfter( ()=>delete & Table.FromRecords({}), #duration(0,0,0,2) ),
			final   = chdelay & insert,
			expand  = List.Accumulate(
						final[insert], 
						Table.FromRows({}), 
						(st,cr)=> 	Function.InvokeAfter(
										()=> st & (if cr=null then Table.FromRows({}) else cr), 
										#duration(0,0,0,Number.From(delay))
									)
					)
		] ,

	Connect_Yandex_Disk_API = // Получение данных из Yandex Disk API
		/*
			Если ваш гугл-диск попал (или может попасть) под санкции, а шлюзы вы не любите, вам очень пригодится функция для Яндекс Диск API:)
			Как обновлять данные из локального файла в Power BI Service без шлюза? 🥹 
			1) Грузим файл на Яндекс.Диск.
			2) Обращаемся к API Яндекс.Диска с помощью функции и получаем файл в Power BI Desktop.
			3) Выгружаем отчёт с файлом в альтернативную рабочую область Power BI Service ("Моя рабочая область" не подойдёт). 
			В "Моей рабочей области" Power BI требует шлюз, так что там пользы от функции мало.
			Где это еще работает?
			Функция работает в Excel, а также в потоках данных Power BI. Можно запустить поток данных с обращением к разным файлам и использовать везде его - это довольно удобно. 
			Сложно поверить, но говорят, что даже в Report Server функция работает.
			А вот и сама функция:
		*/
		let 
			function =
				(fileLink as text, token as text )=>
				let
					headers = [
						#"Content-Type"  = "application/json", 
						#"Authorization" = "OAuth "&token, 
						#"Accept" 		 = "application/json"
					],

					querydata = [
						#"path" = Text.Replace(fileLink, "\","/")
					],

					web 	= Web.Contents(
								"https://cloud-api.yandex.net/", 
								[
									RelativePath		 = "v1/disk/resources/download", 
									Headers 			 = headers, 
									ManualStatusHandling = {404, 400}, 
									Query 				 = querydata
								]),

					result 	= Json.Document(web),
					link 	= result[href], 
					relativ = Text.Replace(result[href], "https://downloader.disk.yandex.ru/",""),
					href 	= Web.Contents(
								"https://downloader.disk.yandex.ru/", 
								[
									RelativePath = relativ, 
									Headers = headers, 
									ManualStatusHandling = {404, 400}
								])
				in 
					href,

			result = Value.ReplaceType(function, FuncType),

			FuncType = type function (

				fileLink as (type text meta [
						Documentation.FieldCaption = "Путь к файлу после C:\YandexDisk\:",
						Documentation.SampleValues = {"Мои файлы\файлик.xxx"}
					]),   

				token as (type text meta [
						Documentation.FieldCaption = "Ваш токен (ссылка на получение ниже):",
						Documentation.SampleValues = {"y0_AgAAAMfGA...rBX0d-ZpA5O"}
					])
						)
					as table meta [
						Documentation.Name = "Получаем файл с Яндекс.Диска",
						Documentation.LongDescription =    "",
					
					Documentation.Examples = {
								[
							Description = "Ссылка на получение токена:",
							Code = "https://oauth.yandex.ru/authorize?response_type=token&client_id=a363cf6712db45978a012820777fc06a",
							Result = "По ссылке вы получите токен"
									]
						}
			]

		in result


	],

Calendar   = [ 
	readme = "Библиотека календарей v 1.1",
	Calendar = 1,
	Calendar_Гришина = 
		let
		// 	Функция List.Dates возвращает список дат
			Source = List.Dates,
		// 	Активируйте List.Dates function. Здесь вы сможете настроить любые извращения календаря. Но лучше использовать базисы.
		// 	Дата начала:    # Date (YYYY,MM,DD)
		// 	Дата окончания: Duration.Days(DateTime.Date(DateTime.FixedLocalNow()) - #date(YYYY, MM, DD))+1  
		//	(It counts the number of days between today and the first date of the table and adds one day more to include today).
		// 	Для адаптации к другим таблицам используйте этот тип столбца (YYYY; MM; DD)
		// 	#duration (1,0,0,0) Добавляет в List.Date по одному дню за шаг.
			#"Invoke dates" = Source(
				#date(1910, 1, 1), 
				Duration.Days(DateTime.Date(DateTime.FixedLocalNow()) - #date(2023,01,01)) + 1,
				#duration(1, 0, 0, 0)
			),
		
		// 	Этот шаг разворачивает таблицу, желательно ставить даты одинаковые.
			#"List to table" = Table.FromList(#"Invoke dates", Splitter.SplitByNothing(), null, null, ExtraValues.Error),
		
		// 	Переименовать столбец
			Date = Table.RenameColumns(#"List to table",{{"Column1", "Date"}}),
		
		// 	Извлекаем день, где нулевые как “00”
			#"Day Added" = Table.AddColumn(Date, "Day", each Text.PadStart(Number.ToText(Date.Day([Date])),2,"0")),
		
		// 	Извлекаем день недели, начало в понедельник.
			#"Day Name Added" = Table.AddColumn(#"Day Added", "Day Name", each Date.ToText([Date],"ddd","ru-RU")),
		// 	Извлекаем месяц Номер    
			#"Month No Added" = Table.AddColumn(#"Day Name Added", "Month No", each Date.Month([Date])),
		
		// 	Извлекаем название месяца
			#"Month Name Added" = Table.AddColumn(#"Month No Added", "Month Name", each Date.ToText([Date],"MMM","ru-RU")),
		
		// 	Извлекаем номер квартала
			#"Quarter No Added" = Table.AddColumn(#"Month Name Added", "Quarter No", each Date.QuarterOfYear([Date])),
		
		// 	Извлекаем недели. ВНИМАТЕЛЬНО СМОТРИТЕ НА ТО, СКОЛЬКО НЕДЕЛЬ В ГОДУ ВАМ НАДО - ЗАВИСИТ ОТ ПОЖЕЛАНИЙ КЛИЕНТА
			#"Week No added" = Table.AddColumn(#"Quarter No Added", "WeekNo", each Text.PadStart(Number.ToText(Date.WeekOfYear([Date])-1),2,"0")),
		
		// 	Извлекаем год
			#"Year Added" = Table.AddColumn(#"Week No added", "Year", each Date.Year([Date])),
		
		// 	Объединяем в ГодМесяц
			#"Year Month Added" = Table.AddColumn(#"Year Added", "Year-Month", each Number.ToText([Year])&"-"&[Month Name]),
		
		// 	Объединяем ГодКвартал
			#"Year Quarter Added" = Table.AddColumn(#"Year Month Added", "Year-Quarter", each Number.ToText([Year]) & "Q"& Number.ToText([Quarter No],"00")),
		
		// 	Изменяем тип на текст
			#"Change type to text" = Table.TransformColumnTypes(#"Year Quarter Added",{{"Year", type text}, {"Date", type date}, {"Month No", type text}, {"Day", type text}, {"Day Name", type text}, {"Month Name", type text}, {"Quarter No", type text}, {"Year-Quarter", type text}, {"Year-Month", type text}, {"WeekNo", type text}}),
		
		// 	Делаем сортировку дней
			#"Sort Day" = Table.AddColumn(#"Change type to text", "SortDay", each Date.Day([Date])),
		
		// 	Объединяем ГодДеньНедели
			#"Sort DayName" = Table.AddColumn(#"Sort Day", "SortDayName", each Date.DayOfWeek([Date],1)),
		
		// 	Извлекаем Номер недели по Европейскому формату
			#"Sort Week No" = Table.AddColumn(#"Sort DayName", "SortWeekNo", each Date.WeekOfYear([Date])+1),
		
		// 	Делаем сортировку Недель
			#"Sort YearMonth" = Table.AddColumn(#"Sort Week No", "SortYearMonth", each [Year]&Text.PadStart([Month No],2,"0")),
		
		// 	Делаем сортировку ГодКвартал
			#"Sort YearQuarter" = Table.AddColumn(#"Sort YearMonth", "SortYearQuarter", each [Year]&Text.PadStart([Quarter No],2,"0")),
		
		// 	Изменяем тип данных сортировок на целое число
			#"Changed Type to NO" = Table.TransformColumnTypes(#"Sort YearQuarter",{{"SortYearMonth", Int64.Type}, {"SortYearQuarter", Int64.Type}, {"SortDayName", Int64.Type}, {"SortDay", Int64.Type}, {"SortWeekNo", Int64.Type}}),
			#"Вставленные первые символы" = Table.AddColumn(#"Changed Type to NO", "Месяц Буква", each Text.Start(Text.Upper([Month Name]), 1), type text),
			to = Table.TransformColumnTypes(#"Вставленные первые символы",{{"Month No", Int64.Type}})
		in
			to,

	fxMyCalendar = // Мой календарь, с которым работаю
		/*
			= F[fxMyCalendar]()
		*/
		(StartDate as date, EndDate as date, optional Culture as nullable text) as table =>
		let
			DayCount        = Duration.Days(Duration.From(EndDate - StartDate)),
			Source          = List.Dates(StartDate,DayCount,#duration(1,0,0,0)),
			TableFromList   = Table.FromList(Source, Splitter.SplitByNothing()),    
			ChangedType     = Table.TransformColumnTypes(TableFromList,{{"Column1", type date}}),
			RenamedColumns  = Table.RenameColumns(ChangedType,{{"Column1", "Date"}}),
			
			InsertYear          = Table.AddColumn(RenamedColumns, 		"Year", 			each Date.Year([Date])),
			InsertQuarter       = Table.AddColumn(InsertYear, 			"QuarterOfYear", 	each Date.QuarterOfYear([Date])),
			InsertMonth         = Table.AddColumn(InsertQuarter, 		"MonthOfYear", 		each Date.Month([Date])),
			InsertDay           = Table.AddColumn(InsertMonth, 			"DayOfMonth", 		each Date.Day([Date])),
			InsertDayInt        = Table.AddColumn(InsertDay, 			"DateInt", 			each [Year] * 10000 + [MonthOfYear] * 100 + [DayOfMonth]),
			InsertMonthName     = Table.AddColumn(InsertDayInt, 		"MonthName", 		each Date.ToText([Date], "MMMM", Culture), type text),
			InsertCalendarMonth = Table.AddColumn(InsertMonthName, 		"MonthInCalendar", 	each (try(Text.Range([MonthName],0,3)) otherwise [MonthName]) & " " & Number.ToText([Year])),
			InsertCalendarQtr   = Table.AddColumn(InsertCalendarMonth, 	"QuarterInCalendar", each "Q" & Number.ToText([QuarterOfYear]) & " " & Number.ToText([Year])),
			InsertDayWeek       = Table.AddColumn(InsertCalendarQtr, 	"DayInWeek", 		each Date.DayOfWeek([Date])),
			InsertDayName       = Table.AddColumn(InsertDayWeek, 		"DayOfWeekName", 	each Date.ToText([Date], "dddd", Culture), type text),
			InsertWeekEnding    = Table.AddColumn(InsertDayName, 		"WeekEnding", 		each Date.EndOfWeek([Date]), type date)
		in  InsertWeekEnding,

	fxCalendar1  = // Календарь Уварова
		(StartDate as date, EndDate as date, optional Culture as nullable text) as table =>
		let
			DayCount        = Duration.Days(Duration.From(EndDate - StartDate)),
			Source          = List.Dates(StartDate,DayCount,#duration(1,0,0,0)),
			TableFromList   = Table.FromList(Source, Splitter.SplitByNothing()),    
			ChangedType     = Table.TransformColumnTypes(TableFromList,{{"Column1", type date}}),
			RenamedColumns  = Table.RenameColumns(ChangedType,{{"Column1", "Date"}}),
			
			InsertYear          = Table.AddColumn(RenamedColumns, 	"Year", 			each Date.Year([Date])),
			InsertQuarter       = Table.AddColumn(InsertYear, 		"QuarterOfYear", 	each Date.QuarterOfYear([Date])),
			InsertMonth         = Table.AddColumn(InsertQuarter, 	"MonthOfYear", 		each Date.Month([Date])),
			InsertDay           = Table.AddColumn(InsertMonth, 		"DayOfMonth", 		each Date.Day([Date])),
			InsertDayInt        = Table.AddColumn(InsertDay, 		"DateInt", 			each [Year] * 10000 + [MonthOfYear] * 100 + [DayOfMonth]),
			InsertMonthName     = Table.AddColumn(InsertDayInt, 	"MonthName", 		each Date.ToText([Date], "MMMM", Culture), type text),
			InsertCalendarMonth = Table.AddColumn(InsertMonthName, 	"MonthInCalendar", 	each (try(Text.Range([MonthName],0,3)) otherwise [MonthName]) & " " & Number.ToText([Year])),
			InsertCalendarQtr   = Table.AddColumn(InsertCalendarMonth, "QuarterInCalendar", each "Q" & Number.ToText([QuarterOfYear]) & " " & Number.ToText([Year])),
			InsertDayWeek       = Table.AddColumn(InsertCalendarQtr, "DayInWeek", 		each Date.DayOfWeek([Date])),
			InsertDayName       = Table.AddColumn(InsertDayWeek, 	"DayOfWeekName", 	each Date.ToText([Date], "dddd", Culture), type text),
			InsertWeekEnding    = Table.AddColumn(InsertDayName, 	"WeekEnding", 		each Date.EndOfWeek([Date]), type date)    
		in  InsertWeekEnding,
	
	
	fxCalendar2  = // Празднки PФ
		(Год) =>
		let
			TextYearParam = Text.From(Год) & (if Год=2020 then "b" else ""),
			Source = Lines.FromBinary(Web.Contents("http://www.consultant.ru/law/ref/calendar/proizvodstvennye",[RelativePath = Text.From(TextYearParam) & "/?"])),
			#"Converted to Table" 	= Table.FromList(Source, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
			#"Filtered Rows" 		= Table.SelectRows(#"Converted to Table", each Text.StartsWith([Column1], "#(tab)#(tab)#(tab)<td class=")),
			#"Replaced Value" 		= Table.ReplaceValue(#"Filtered Rows","</tr><tr>","",Replacer.ReplaceText,{"Column1"}),
			#"Added Index" 			= Table.AddIndexColumn(#"Replaced Value", "#Month", 1, 1),
			#"Added Prefix" 		= Table.TransformColumns(#"Added Index", {{"Column1", each Text.Split(_,"</td><td class="), type text}}),
			#"Expanded Custom" 		= Table.ExpandListColumn(#"Added Prefix", "Column1"),
			#"Filtered Rows1" 		= Table.SelectRows(#"Expanded Custom", each not Text.Contains([Column1], "inactively")),
			#"Replaced Value1" 		= Table.ReplaceValue(#"Filtered Rows1","#(tab)#(tab)#(tab)<td class=","",Replacer.ReplaceText,{"Column1"}),
			#"Split Column by Delimiter" = Table.SplitColumn(#"Replaced Value1", "Column1", Splitter.SplitTextByEachDelimiter({">"}, QuoteStyle.Csv, false), {"Day type", "Day"}),
			#"Extracted Text Before Delimiter" = Table.TransformColumns(#"Split Column by Delimiter", {{"Day", each Text.BeforeDelimiter(_, "<"), type text}}),
			#"Changed Type" 		= Table.TransformColumnTypes(#"Extracted Text Before Delimiter",{{"Day", Int64.Type}}),
			#"Added Custom" 		= Table.AddColumn(#"Changed Type", "Year", each Год, Int64.Type),
			#"Added Custom1" 		= Table.AddColumn(#"Added Custom", "Date", each #date([Year],[#"#Month"],[Day]), type date),
			#"Inserted Month Name" 	= Table.AddColumn(#"Added Custom1", "Month", each Date.MonthName([Date]), type text),
			#"Inserted Day Name" 	= Table.AddColumn(#"Inserted Month Name", "Day name", each Date.DayOfWeekName([Date]), type text)
		in
			#"Inserted Day Name",
		
	fxCalendar3  = // Календарь 3
		(StartDate as date,EndDate as date) =>
		let
			Source = List.Dates,
			#"Invoked FunctionSource" = Source(StartDate, Duration.Days(DateTime.Date(DateTime.FixedLocalNow()) - EndDate) + 1, #duration(1, 0, 0, 0)),
			#"Table from List" = Table.FromList(#"Invoked FunctionSource", Splitter.SplitByNothing(), null, null, ExtraValues.Error),
			#"Changed Type1" = Table.TransformColumnTypes(#"Table from List",{{"Column1", type date}}),
			#"Renamed Columns" = Table.RenameColumns(#"Changed Type1",{{"Column1", "Дата"}}),

			// Добавление столбцов
			Год                 = Table.AddColumn(#"Renamed Columns", 	"Год", 			each Date.Year([Дата]), Int64.Type),
			#"Номер месяца"     = Table.AddColumn(Год, 					"Месяц", 		each Date.ToText([Дата],"MM"), type text),
			#"Номер дня"        = Table.AddColumn(#"Номер месяца", 		"Номер дня", 	each Date.ToText([Дата],"dd"), type text),
			#"Название дня"     = Table.AddColumn(#"Номер дня", 		"День", 		each Date.ToText([Дата],"ddd"), type text),
			#"Название месяца"  = Table.AddColumn(#"Название дня", 		"Мес", 			each Date.ToText([Дата],"MMM"), type text),
			#"Номер квартала"   = Table.AddColumn(#"Название месяца", 	"Квартал", 		each Date.QuarterOfYear([Дата]), type text),
			#"Номер недели"     = Table.AddColumn(#"Номер квартала", 	"Номер недели", each Date.WeekOfYear([Дата]), Int64.Type),
			#"Читабельная Неделя" = Table.AddColumn(#"Номер недели", 	"Неделя", 		each Date.ToText(Date.StartOfWeek([Дата]),"MM-dd")&"|"&Date.ToText(Date.EndOfWeek([Дата]),"MM-dd"), type text),

			#"Эта-прошлая" = Table.AddColumn(#"Читабельная Неделя", "Эта/прошлая неделя", 
					each if Date.IsInCurrentWeek([Дата]) = true  and Date.From([Дата]) <> Date.From(DateTime.LocalNow()) then "Эта" 
					else if Date.IsInPreviousWeek([Дата]) = true and Date.AddDays([Дата],7) < Date.From(DateTime.LocalNow()) then "Прошлая" 
					else "", type text),

			#"Номер дня недели" = Table.AddColumn(#"Эта-прошлая", "№ дня недели", 
					each Date.DayOfWeek([Дата]) + 1, Int64.Type),

			#"Этот/прошлый месяц" = Table.AddColumn(#"Номер дня недели", "Этот/прошлый месяц", 
					each if Date.IsInCurrentMonth([Дата]) = true and Date.From([Дата]) <> Date.From(DateTime.LocalNow()) then "Этот месяц" 
					else if Date.IsInPreviousMonth([Дата]) = true then "Прошлый месяц" 
					else "", type text),

			#"Эта/прошлая/позапрошлая" = Table.AddColumn(#"Этот/прошлый месяц", "Прошлая/Позапрошлая", 
					each if Date.IsInPreviousWeek([Дата]) = true  then "Прошлая" 
					else if Date.IsInPreviousWeek(Date.AddDays([Дата],7)) = true then "Позапрошлая" 
					else "", type text)
			in
				#"Эта/прошлая/позапрошлая",

	fxCalendarKill = // killerDateTableRu
		// функция killerDateTableRu создает таблицу с датами. Дополняет ее различными полезными для Time Intelligence столбцами. 
		// В случае, если четвертый аргумент принимает Дни 1, то функция добавляет столбец с выходными.
		// Оригинальная идея philbritton https://gist.github.com/philbritton/9677152
		// пример: killerDateTableRu(#date(2017, 2, 1), #date(2017, 2, 4), "RU-ru", 1)
		// ошибка в четвертом параметре. Надо не 1 а TRUE ставить или тип данных менять
		// пример: killerDateTableRu(#date(2017, 2, 1), #date(2017, 2, 4), "RU-ru", true)
		
		// Описание полей результирующей таблицы:
		// ===================================================
		// Date - дата
		// Year - год
		// QuarterOfYear - номер квартала
		// MonthOfYear - номер месяца в году
		// MonthDayNumber - номер дня в месяце
		// DateInt - дата в форме целого числа
		// YearMonthNumber - МесяцГод в форме 201701
		// MonthName - название месяца в формате Январь
		// MonthInCalendar - Месяц год в формате Янв 2017
		// QuarterInCalendar - КварталГод в формате Q1 2017
		// DayInWeek - номер дня недели
		// DayOfWeekName - название дня недели
		// WeekEnding - дата окончания недели
		// StartOfWeek - дата начала недели
		// StartOfMonth - дата начала месяца
		// WeekOfYear - номер недели в году
		// DayOfYear - номер дня от начала года
		// SequentialMonthNumber - номер месяца в таблице по порядку
		// SequentialMonthNumberReverse - номер месяца в таблице в обратном порядке
		// SequentialWeekNumber - номер недели в таблице по порядку
		// SequentialWeekNumberReverse - номер недели в таблице в обратном порядке
		// SequentialDayNumber - номер дня в таблице по порядку
		// SequentialDayNumberReverse - номер дня в таблице в обратном порядке
	
		( 
			StartDateParameter        as date, 
			EndDateParameter          as date, 
			CultureParameter          as nullable text, 
			IsRuHolidaysParameter     as nullable logical ) =>
		
		let
			MONTHS_ORDERED_BY_DEFAULT = {
				"Январь", "Февраль", "Март",
				"Апрель", "Май", "Июнь", 
				"Июль", "Август", "Сентябрь", 
				"Октябрь", "Ноябрь", "Декабрь"
			},
		
			getProductionCalendar = ( URL as text ) as nullable table =>
				let
					GetDataFromGovRu = Csv.Document(  Web.Contents( URL ), [ Delimiter  = ",", Encoding   = 65001, QuoteStyle = QuoteStyle.None ] ),
			
					#"Повышенные заголовки"      = Table.PromoteHeaders( GetDataFromGovRu ),
					#"Переименовали поле в год"  = Table.RenameColumns( #"Повышенные заголовки", { {"Год/Месяц", "Год"} }),
					#"Выбрали год и месяц"       = Table.SelectColumns( #"Переименовали поле в год",  { "Год" } & MONTHS_ORDERED_BY_DEFAULT ),
					#"Спрямили календарь"        = Table.UnpivotOtherColumns( #"Выбрали год и месяц", { "Год" }, "Месяц", "День"),
					#"Добавили номер месяца"     = Table.AddColumn( #"Спрямили календарь", "НомерМесяца", each 1 + List.PositionOf( MONTHS_ORDERED_BY_DEFAULT, [Месяц] ), type number),
					#"Преобразовали в список" 	 = Table.TransformColumns( #"Добавили номер месяца",{ { "День", each Text.Split( _, "," ) }} ),
					#"Развернули список дней"    = Table.ExpandListColumn( #"Преобразовали в список", "День" ),
					#"Добавили сокращенный день" = Table.AddColumn( #"Развернули список дней", "Сокращенный День", each Text.Contains( [День], "*" ) ),
					#"Добавили выходной день"    = Table.AddColumn( #"Добавили сокращенный день", "Выходной День", each not [Сокращенный День] ),
					#"Удалили признак сокр. дня" = Table.ReplaceValue( #"Добавили выходной день", "*", "", Replacer.ReplaceText, { "День" } ),
					#"Уточнили тип полей" 		 = Table.TransformColumnTypes( #"Удалили признак сокр. дня",{
							{ "Год", Int64.Type },
							{ "День", Int64.Type },
							{ "НомерМесяца", Int64.Type } }
						),
					#"Рассчитали дату" = Table.AddColumn( #"Уточнили тип полей", "Дата", each #date( [Год], [НомерМесяца], [День] ) )
				in
					#"Рассчитали дату",
		
		// Примечание: 
		//  источник взят отсюда: http://data.gov.ru/opendata/7708660670-proizvcalendar
		//  На момент 24.05.2018 в календаре содержатся описание праздников с 1999 года по 2025 год.
		
			PROD_СALENDAR_URL =
			"http://data.gov.ru/opendata/7708660670-proizvcalendar/data-20180410T1145-structure-20180410T1145.csv?encoding=UTF-8",
		
			ProductionCalendar = getProductionCalendar( PROD_СALENDAR_URL ),
		
			ListOfShortday = Table.SelectRows( ProductionCalendar, each [Сокращенный День] = true )[Дата],
			ListOfHoliday  = Table.SelectRows( ProductionCalendar, each [Выходной День] = true )[Дата],
			
			CheckIfThereIsShortdayList = List.Buffer( try ListOfShortday otherwise {} ),
			CheckIfThereIsHolidayList  = List.Buffer( try ListOfHoliday otherwise {} ),

			DayCount      = Duration.Days( Duration.From( EndDateParameter - StartDateParameter ) ) + 1,
			MainList      = List.Dates( StartDateParameter, DayCount, #duration( 1, 0, 0, 0 ) ),
			TableFromList = Table.FromList( MainList, Splitter.SplitByNothing(), { "Date" } ),    
			ChangedType   = Table.TransformColumnTypes( TableFromList,  { {"Date", type date } } ),
			
			InsertYear    = Table.AddColumn( ChangedType,   "Year",           each Date.Year( [Date] ), Int64.Type ),
			InsertQuarter = Table.AddColumn( InsertYear,    "QuarterOfYear",  each Date.QuarterOfYear( [Date] ),Int64.Type),
			InsertMonth   = Table.AddColumn( InsertQuarter, "MonthOfYear",    each Date.Month( [Date] ),Int64.Type),
			InsertDay     = Table.AddColumn( InsertMonth,   "MonthDayNumber", each Date.Day( [Date] ),Int64.Type),
			InsertDayInt  = Table.AddColumn( InsertDay,     "DateInt",        each [Year] * 10000 + [MonthOfYear] * 100 + [MonthDayNumber],Int64.Type),

			InsertYearMonthNumber = Table.AddColumn( InsertDayInt, "YearMonthNumber",    each [Year] * 100 + [MonthOfYear] * 1, Int64.Type),
			InsertMonthName =       Table.AddColumn( InsertYearMonthNumber, "MonthName", each Date.ToText( [Date], "MMMM", CultureParameter ), type text),
			InsertCalendarMonth =   Table.AddColumn( InsertMonthName, "MonthInCalendar", each ( try ( Text.Range( [MonthName], 0, 3 ) ) otherwise [MonthName] ) & " " & Number.ToText( [Year] ), type text),
			InsertCalendarQtr =     Table.AddColumn( InsertCalendarMonth, "QuarterInCalendar", each "Q" & Number.ToText( [QuarterOfYear] ) & " " & Number.ToText( [Year] ), type text),

			// 1Кв 22
			InsertCalendarQtrRus = Table.AddColumn( InsertCalendarQtr,     "QuarterInCalendarR", each Number.ToText( [QuarterOfYear] ) & "Кв" & " " & Number.ToText( [Year] ), type text),  
			InsertDayWeek        = Table.AddColumn( InsertCalendarQtrRus,  "DayInWeek",      each Date.DayOfWeek( [Date], Day.Monday ) + 1, Int64.Type ),
			InsertDayName        = Table.AddColumn( InsertDayWeek,         "DayOfWeekName",  each Date.ToText( [Date], "dddd", CultureParameter ), type text),
			InsertWeekEnding     = Table.AddColumn( InsertDayName,         "WeekEnding",     each Date.EndOfWeek( [Date], Day.Monday ), type date),
			InsertedStartofWeek  = Table.AddColumn( InsertWeekEnding,      "StartOfWeek",    each Date.StartOfWeek( [Date], Day.Monday ), type date),
			InsertedStartofMonth = Table.AddColumn( InsertedStartofWeek,   "StartOfMonth",   each Date.StartOfMonth( [Date] ), type date ),
			InsertWeekofYear     = Table.AddColumn( InsertedStartofMonth,  "WeekOfYear",     each Date.WeekOfYear( [Date], Day.Monday ), Int64.Type),
			InsertDayofYear      = Table.AddColumn( InsertWeekofYear,      "DayOfYear",      each Date.DayOfYear( [Date] ), Int64.Type),

			listBufferMonths 	= List.Buffer( List.Distinct( InsertDayofYear[StartOfMonth] ) ),
			
			AddedNumberOfMonth 	= Table.AddColumn( InsertDayofYear, "SequentialMonthNumber", each List.PositionOf( listBufferMonths, [StartOfMonth]) + 1, Int64.Type),
			
			SequentialMonthNumberReverse = 
				Table.AddColumn( AddedNumberOfMonth, "SequentialMonthNumberReverse", each
					List.PositionOf( List.Reverse( listBufferMonths ), [StartOfMonth]) + 1,
					Int64.Type
				),
			
			listBufferWeeks = List.Buffer( List.Distinct( SequentialMonthNumberReverse[StartOfWeek] ) ),
			
			AddedNumberOfWeeks 			= Table.AddColumn( SequentialMonthNumberReverse, "SequentialWeekNumber", each List.PositionOf( listBufferWeeks, [StartOfWeek] ) + 1, Int64.Type),
			AddedNumberOfWeeksReverse 	= Table.AddColumn( AddedNumberOfWeeks, "SequentialWeekNumberReverse", each List.PositionOf( List.Reverse( listBufferWeeks ), [StartOfWeek] ) + 1, Int64.Type),
			InsertSequentialDayNumber 	= Table.AddIndexColumn( AddedNumberOfWeeksReverse, "SequentialDayNumber", 1, 1 ),
		
			InsertSequentialDayNumberReverse =
				Table.AddIndexColumn( 
					InsertSequentialDayNumber,
					"SequentialDayNumberReverse",
					List.Max( InsertSequentialDayNumber[SequentialDayNumber] ),
					-1 
				),
		
			insertRuHolidaysColumn = 
				Table.AddColumn( InsertSequentialDayNumberReverse, "Holiday", each
					if List.Count( CheckIfThereIsHolidayList ) = 0 
						then null
						else 
					if List.Contains( CheckIfThereIsHolidayList, [Date]) 
						then true 
						else false
			),
		
			insertRuShortdaysColumn = 
				Table.AddColumn( insertRuHolidaysColumn, "Shortday", each
					if 	List.Count( CheckIfThereIsShortdayList ) = 0  then null else 
					if 	List.Contains( CheckIfThereIsShortdayList, [Date])  then true else false
			)
			
		in
			if IsRuHolidaysParameter
			then insertRuShortdaysColumn
			else InsertSequentialDayNumberReverse,


	fxComrad 	 = // + Календарь Товарища
		(StartDate as date, EndDate as date, optional Culture as nullable text) as table =>
		let
			// fxMultiAdd = (tbl as table, nms as list) as table => List.Accumulate(nms, tbl, (s, c) => Table.AddColumn(s, c{0}, c{1}, c{2}?)),
			// addColumns = fxMultiAdd(from3,{
			
			start  = StartDate, // Excel.CurrentWorkbook(){[Name = "Параметры"]}[Content]{0}[Значение]
			finish = EndDate, 	// Excel.CurrentWorkbook(){[Name = "Параметры"]}[Content]{1}[Значение]
			tab_generate = Table.FromList(
					{Number.From(start) .. Number.From(finish)}, 
					Splitter.SplitByNothing(), {"Дата"} ), 

			col_type = Table.TransformColumnTypes( tab_generate, {{"Дата", type date}} ), 
			
			tab_add_col_1 = Table.AddColumn( col_type, 		"Год", 			each Date.Year([Дата]), 					Int64.Type ), 
			tab_add_col_2 = Table.AddColumn( tab_add_col_1, "Месяц", 		each Date.Month([Дата]),					Int64.Type ), 
			tab_add_col_3 = Table.AddColumn( tab_add_col_2, "День", 		each Date.Day([Дата]), 						Int64.Type ), 
			tab_add_col_4 = Table.AddColumn( tab_add_col_3, "Квартал", 		each Date.QuarterOfYear([Дата]), 			Int64.Type ), 
			tab_add_col_5 = Table.AddColumn( tab_add_col_4, "Неделя года", 	each Date.WeekOfYear([Дата], Day.Monday), 	Int64.Type ), 
			tab_add_col_6 = Table.AddColumn( tab_add_col_5, "День недели", 	each Date.DayOfWeek([Дата], Day.Monday) + 1,Int64.Type )
		in  tab_add_col_6,

	
	fnDateTable2 = // + Календарь с сайта буржуйского
		// https://forum.enterprisedna.co/t/extended-date-table-power-query-m-function/6390
		[ 
			fnDateTable = 
				( 	StartDate as date, 
					EndDate as date, 
					optional FYStartMonthNum as number, 
					optional Holidays as list, 
					optional WDStartNum as number, 
					optional AddRelativeNetWorkdays as logical 
				) as table =>
				
				let
					FYStartMonth 	= List.Select( {1..12}, each _ = FYStartMonthNum ){0}? ?? 1,
					WDStart 		= List.Select( {0..1}, each _ = WDStartNum ){0}? ?? 0,
					CurrentDate 	= Date.From( DateTime.FixedLocalNow()),
					DayCount 		= Duration.Days( Duration.From( EndDate - StartDate)) +1,
					Source 			= List.Dates( StartDate, DayCount, #duration(1,0,0,0)),
					AddToday 		= if List.Contains(Source, CurrentDate) then Source else List.Combine( {Source, {CurrentDate}}),
					ToTable 		= Table.FromList(AddToday, Splitter.SplitByNothing(), type table [Date = Date.Type] ),
					InsertYear 		= Table.AddColumn(ToTable, "Year", each Date.Year([Date]), type number),
					InsertYearOffset = Table.AddColumn(InsertYear, "CurrYearOffset", each Date.Year([Date]) - Date.Year( Date.From(CurrentDate)), type number),
					InsertCompletedYear = Table.AddColumn(InsertYearOffset, "YearCompleted", each Date.EndOfYear([Date]) < Date.From( Date.EndOfYear(CurrentDate)), type logical),

					InsertQuarterNum		= Table.AddColumn(InsertCompletedYear, 	"Quarter Number", 	each Date.QuarterOfYear([Date]), type number),
					InsertQuarter 			= Table.AddColumn(InsertQuarterNum, 	"Quarter", 			each "Q" & Number.ToText([Quarter Number]), type text),
					InsertStartOfQuarter 	= Table.AddColumn(InsertQuarter,		"Start of Quarter", each Date.StartOfQuarter([Date]), type date),
					InsertEndOfQuarter 		= Table.AddColumn(InsertStartOfQuarter, "End of Quarter", 	each Date.EndOfQuarter([Date]), type date),
					InsertCalendarQtr 		= Table.AddColumn(InsertEndOfQuarter, 	"Quarter & Year", 	each "Q" & Number.ToText( Date.QuarterOfYear([Date])) & Date.ToText([Date], [Format = " yyyy"]), type text),
					InsertQuarternYear 		= Table.AddColumn(InsertCalendarQtr, 	"QuarternYear", 	each [Year] * 10 + [Quarter Number], type number),
					InsertQuarterOffset 	= Table.AddColumn(InsertQuarternYear, 	"CurrQuarterOffset", each ((4 * Date.Year([Date])) +  Date.QuarterOfYear([Date])) - ((4 * Date.Year(Date.From(CurrentDate))) +  Date.QuarterOfYear(Date.From(CurrentDate))), type number),
					InsertCompletedQuarter 	= Table.AddColumn(InsertQuarterOffset, 	"QuarterCompleted", each Date.EndOfQuarter([Date]) < Date.From(Date.EndOfQuarter(CurrentDate)), type logical),

					InsertMonth 		= Table.AddColumn(InsertCompletedQuarter, 	"Month", 			each Date.Month([Date]), type number),
					InsertStartOfMonth 	= Table.AddColumn(InsertMonth, 				"Start of Month", 	each Date.StartOfMonth([Date]), type date),
					InsertEndOfMonth 	= Table.AddColumn(InsertStartOfMonth, 		"End of Month", 	each Date.EndOfMonth([Date]), type date),
					InsertCalendarMonth = Table.AddColumn(InsertEndOfMonth, 		"Month & Year", 	each Text.Proper( Date.ToText([Date], [Format = "MMM yyyy"])), type text),
					InsertMonthnYear	= Table.AddColumn(InsertCalendarMonth , 	"MonthnYear", 		each [Year] * 100 + [Month], type number),
					InsertMonthOffset 	= Table.AddColumn(InsertMonthnYear, 		"CurrMonthOffset", 	each ((12 * Date.Year([Date])) +  Date.Month([Date])) - ((12 * Date.Year(Date.From(CurrentDate))) +  Date.Month(Date.From(CurrentDate))), type number),
					InsertCompletedMonth = Table.AddColumn(InsertMonthOffset, 		"MonthCompleted", 	each Date.EndOfMonth([Date]) < Date.From(Date.EndOfMonth(CurrentDate)), type logical),
					InsertMonthName 	= Table.AddColumn(InsertCompletedMonth, 	"Month Name", 		each Text.Proper( Date.ToText([Date], "MMMM")), type text),
					InsertMonthShort 	= Table.AddColumn( InsertMonthName, 		"Month Short", 		each Text.Proper( Date.ToText([Date], "MMM")), type text),
					InsertMonthInitial 	= Table.AddColumn(InsertMonthShort, 		"Month Initial", 	each Text.Start([Month Name], 1) & Text.Repeat( Character.FromNumber(8203), Date.Month([Date]) ), type text),
					InsertDayOfMonth 	= Table.AddColumn(InsertMonthInitial, 		"Day of Month", 	each Date.Day([Date]), type number),
				
					InsertWeekNumber = Table.AddColumn(InsertDayOfMonth, "Week Number", each
						if Number.RoundDown((Date.DayOfYear([Date])-(Date.DayOfWeek([Date], Day.Monday)+1)+10)/7)=0
						then Number.RoundDown((Date.DayOfYear(#date(Date.Year([Date])-1,12,31))-(Date.DayOfWeek(#date(Date.Year([Date])-1,12,31), Day.Monday)+1)+10)/7)
						else if (Number.RoundDown((Date.DayOfYear([Date])-(Date.DayOfWeek([Date], Day.Monday)+1)+10)/7)=53 and (Date.DayOfWeek(#date(Date.Year([Date]),12,31), Day.Monday)+1<4))
						then 1 else Number.RoundDown((Date.DayOfYear([Date])-(Date.DayOfWeek([Date], Day.Monday)+1)+10)/7), type number),
					InsertStartOfWeek = Table.AddColumn(InsertWeekNumber, "Start of Week", each Date.StartOfWeek([Date], Day.Monday), type date),
					InsertWeekEnding = Table.AddColumn(InsertStartOfWeek, "End of Week", each Date.EndOfWeek( [Date], Day.Monday), type date),
					InsertCalendarWk = Table.AddColumn(InsertWeekEnding, "Week & Year", each "W" & Text.PadStart( Text.From( [Week Number] ), 2, "0") & " " & Text.From(Date.Year( Date.AddDays( Date.StartOfWeek([Date], Day.Monday), 3 ))), type text ),
					InsertWeeknYear = Table.AddColumn(InsertCalendarWk, "WeeknYear", each Date.Year( Date.AddDays( Date.StartOfWeek([Date], Day.Monday), 3 )) * 100 + [Week Number],  Int64.Type),
					InsertWeekOffset = Table.AddColumn(InsertWeeknYear, "CurrWeekOffset", each (Number.From(Date.StartOfWeek([Date], Day.Monday))-Number.From(Date.StartOfWeek(CurrentDate, Day.Monday)))/7, type number),
					InsertCompletedWeek = Table.AddColumn(InsertWeekOffset, "WeekCompleted", each Date.EndOfWeek( [Date], Day.Monday) < Date.From(Date.EndOfWeek(CurrentDate, Day.Monday)), type logical),
				
					InsertDayWeek = Table.AddColumn(InsertCompletedWeek, "Day of Week Number", each Date.DayOfWeek([Date], Day.Monday) + WDStart, Int64.Type),
					InsertDayName = Table.AddColumn(InsertDayWeek, "Day of Week Name", each Text.Proper( Date.ToText([Date], "dddd" )), type text),
					InsertDayInitial = Table.AddColumn(InsertDayName, "Day of Week Initial", each Text.Proper(Text.Start([Day of Week Name], 1)) & Text.Repeat( Character.FromNumber(8203), Date.DayOfWeek([Date], Day.Monday) + WDStart ), type text),
					InsertDayOfYear = Table.AddColumn(InsertDayInitial, "Day of Year", each Date.DayOfYear([Date]), Int64.Type),
					InsertDayInt = Table.AddColumn(InsertDayOfYear, "DateInt", each [Year] * 10000 + [Month] * 100 + [Day of Month], type number),
					InsertDayOffset = Table.AddColumn(InsertDayInt, "CurrDayOffset", each Number.From([Date]) - Number.From(CurrentDate), type number),
					InsertIsAfterToday = Table.AddColumn(InsertDayOffset, "IsAfterToday", each not ([Date] <= Date.From(CurrentDate)), type logical),
					InsertIsWorkingDay = Table.AddColumn(InsertIsAfterToday, "IsWeekDay", each if Date.DayOfWeek([Date], Day.Monday) > 4 then false else true, type logical),
					InsertIsHoliday = Table.AddColumn(InsertIsWorkingDay, "IsHoliday", each if Holidays = null then "Unknown" else List.Contains( Holidays, [Date] ), if Holidays = null then type text else type logical),
					InsertIsBusinessDay = Table.AddColumn(InsertIsHoliday, "IsBusinessDay", each if [IsWeekDay] = true and [IsHoliday] <> true then true else false, type logical),
					InsertDayType = Table.AddColumn(InsertIsBusinessDay, "Day Type", each if [IsHoliday] = true then "Holiday" else if [IsWeekDay] = false then "Weekend" else if [IsWeekDay] = true then "Weekday" else null, type text),

					InsertISOYear    = Table.AddColumn( InsertDayType, 	 "ISO Year", 			each Date.Year( Date.AddDays( Date.StartOfWeek([Date], Day.Monday), 3 )), type number),
					InsertISOqNum    = Table.AddColumn(InsertISOYear, 	 "ISO Quarter Number", 	each if [Week Number] >39 then 4 else if [Week Number] >26 then 3 else if [Week Number] >13 then 2 else 1, Int64.Type),
					InsertISOqtr     = Table.AddColumn(InsertISOqNum, 	 "ISO Quarter", 		each "Q" & Number.ToText([ISO Quarter Number]), type text),
					InsertISOQuarter = Table.AddColumn(InsertISOqtr,     "ISO Quarter & Year", 	each "Q" & Number.ToText([ISO Quarter Number]) & " " & Number.ToText([ISO Year]), type text),
					InsertISOqNy     = Table.AddColumn(InsertISOQuarter, "ISO QuarternYear", 	each [ISO Year] * 10 + [ISO Quarter Number], type number),

					// BufferTable = Table.Buffer(Table.Distinct( InsertISOqNy[[ISO Year], [DateInt]])),
					// InsertISOday = Table.AddColumn(InsertISOqNy, "ISO Day of Year", (OT) => Table.RowCount( Table.SelectRows( BufferTable, (IT) => IT[DateInt] <= OT[DateInt] and IT[ISO Year] = OT[ISO Year])),  Int64.Type),
					AddFY 		= Table.AddColumn(InsertISOqNy, "Fiscal Year", each "FY" & (if [Month] >= FYStartMonth and FYStartMonth >1 then Text.From([Year] +1) else Text.From([Year])), type text),
					//AddFYs = Table.AddColumn(AddFY, "Fiscal Year short", each "FY" & (if [Month] >= FYStartMonth and FYStartMonth >1 then Text.PadEnd( Text.End( Text.From([Year] +1), 2), 2, "0") else Text.End( Text.From([Year]), 2)), type text),
					AddFQ 		= Table.AddColumn(AddFY, "Fiscal Quarter", each "FQ" & Text.From( Number.RoundUp( Date.Month( Date.AddMonths( [Date], - (FYStartMonth -1) )) / 3 )) & " " & (if [Month] >= FYStartMonth and FYStartMonth >1 then Text.From([Year] +1) else Text.From([Year])), type text),
					AddFQnYr 	= Table.AddColumn(AddFQ, "FQuarternYear", each (if [Month] >= FYStartMonth and FYStartMonth >1 then [Year] +1 else [Year]) * 10 + Number.RoundUp( Date.Month( Date.AddMonths( [Date], - (FYStartMonth -1) )) / 3 ), type number),
					AddFM 		= Table.AddColumn(AddFQnYr, "Fiscal Period Number", each if [Month] >= FYStartMonth and FYStartMonth >1 then [Month] - (FYStartMonth-1) else if [Month] >= FYStartMonth and FYStartMonth =1 then [Month] else [Month] + (12-FYStartMonth+1), type number),
					AddFP 		= Table.AddColumn(AddFM, "Fiscal Period", each "FP" & Text.PadStart( Text.From([Fiscal Period Number]), 2, "0") & " " & (if [Month] >= FYStartMonth and FYStartMonth >1 then Text.From([Year] +1) else Text.From([Year])), type text),
					AddFMnYr 	= Table.AddColumn(AddFP , "FPeriodnYear", each (if [Month] >= FYStartMonth and FYStartMonth >1 then [Year] +1 else [Year]) * 100 + [Fiscal Period Number], type number),
					FYCalendarStart = #date( Date.Year(StartDate)-1, FYStartMonth, 1 ),
					InsertFFD 	= Table.AddColumn( AddFMnYr, "FiscalFirstDay", each if [Month] >= FYStartMonth and FYStartMonth >1 then #date( Date.Year([Date])+1, FYStartMonth, 1) else #date( Date.Year([Date]), FYStartMonth, 1), type date ),

					InitTable 	= Table.FromList( List.Transform( {Number.From(FYCalendarStart) .. Number.From(EndDate)}, Date.From), Splitter.SplitByNothing(), type table [DateFW = Date.Type]),
					AddFFD 		= Table.AddColumn( InitTable, "FiscalFirstDay", each if Date.Month([DateFW]) < FYStartMonth then #date(Date.Year([DateFW]), FYStartMonth, 1) else #date(Date.Year([DateFW]) + 1, FYStartMonth, 1)),
					AddFWSD 	= Table.AddColumn( AddFFD, "FWStartDate", each Date.AddYears(Date.StartOfWeek([DateFW], Day.Monday), 1)),
					Group1 		= Table.Group( AddFWSD, {"FiscalFirstDay", "FWStartDate"}, {{"AllRows", each _, type table [DateFW = nullable date, FiscalFirstDay = date, FWStartDate = date]}}),
					Group2 		= Table.Group( Group1, {"FiscalFirstDay"}, {{"AllRows2", each _, type table [FiscalFirstDay = date, FWStartDate = date, AllRows = table]}}),
					AddIndex 	= Table.AddColumn( Group2, "Custom", each Table.AddIndexColumn([AllRows2], "Fiscal Week Number", 1, 1) )[[Custom]],
					ExpandG2 	= Table.ExpandTableColumn( AddIndex, "Custom", {"FiscalFirstDay", "FWStartDate", "AllRows", "Fiscal Week Number"}, {"FiscalFirstDay", "FWStartDate", "AllRows", "Fiscal Week Number"}), 
					ExpandG1 	= Table.ExpandTableColumn( ExpandG2, "AllRows", {"DateFW"}, {"DateFW"} )[[DateFW], [Fiscal Week Number]],
					MergeFYW 	= Table.Join( InsertFFD, {"Date"}, ExpandG1, {"DateFW"}, JoinKind.LeftOuter, JoinAlgorithm.SortMerge ),
					FWlogic 	= List.Contains( {null}, FYStartMonthNum),
					UpdateFYWeek = if FWlogic then Table.ReplaceValue(MergeFYW, each [Fiscal Week Number], each if FYStartMonth =1 then [Week Number] else [Fiscal Week Number], Replacer.ReplaceValue, {"Fiscal Week Number"}) else MergeFYW,
					AddFYW 		= Table.AddColumn( UpdateFYWeek, "Fiscal Week", each if FWlogic then "F" & [#"Week & Year"] else if FYStartMonth =1 then "FW" & Text.PadStart( Text.From([Fiscal Week Number]), 2, "0") & Date.ToText([Date], " yyyy") else if Date.Month([Date]) < FYStartMonth then "FW" & Text.PadStart( Text.From([Fiscal Week Number]), 2, "0") & Date.ToText([Date], " yyyy") else "FW" & Text.PadStart(Text.From([Fiscal Week Number]), 2, "0") & " " & Text.From( Date.Year([Date])+1), type text),
					InsertFWeeknYear = Table.AddColumn(AddFYW, "FWeeknYear", each if FWlogic then [WeeknYear] else (if FYStartMonth =1 then Date.Year([Date]) else if Date.Month([Date]) < FYStartMonth then Date.Year([Date]) else Date.Year([Date])+1) * 100 + [Fiscal Week Number],  Int64.Type),
					
					CurrentDateRecord 		= Table.SelectRows(InsertFWeeknYear, each ([Date] = CurrentDate)),
					CurrentISOyear 			= CurrentDateRecord{0}[ISO Year],
					CurrentISOqtr 			= CurrentDateRecord{0}[ISO Quarter Number],
					CurrentYear 			= CurrentDateRecord{0}[Year],
					CurrentMonth 			= CurrentDateRecord{0}[Month],
					CurrentFiscalFirstDay 	= CurrentDateRecord{0}[FiscalFirstDay],
					PrevFiscalFirstDay 		= Date.AddYears(CurrentFiscalFirstDay, -1),
					CurrentFY 				= CurrentDateRecord{0}[Fiscal Year],
					CurrentFQ 				= CurrentDateRecord{0}[FQuarternYear],
					CurrentFP 				= CurrentDateRecord{0}[FPeriodnYear],
					CurrentFW 				= CurrentDateRecord{0}[FWeeknYear],

					InsertISOYrOffset = Table.AddColumn(InsertFWeeknYear, "ISO CurrYearOffset", each [ISO Year] - CurrentISOyear, type number),
					InsertISOQtrOffset = Table.AddColumn(InsertISOYrOffset, "ISO CurrQuarterOffset", each ((4 * [ISO Year]) +  [ISO Quarter Number]) - ((4 * CurrentISOyear) + CurrentISOqtr), type number),
					InsertFYoffset = Table.AddColumn(InsertISOQtrOffset, "Fiscal CurrYearOffset", each try (if [Month] >= FYStartMonth then [Year]+1 else [Year]) - (if CurrentMonth >= FYStartMonth then CurrentYear+1 else CurrentYear) otherwise null, type number),
					InsertCurrentFY = Table.AddColumn(InsertFYoffset, "IsCurrentFY", each if [Fiscal Year] = CurrentFY then true else false, type logical),
					InsertCurrentFQ = Table.AddColumn(InsertCurrentFY, "IsCurrentFQ", each if [FQuarternYear] = CurrentFQ then true else false, type logical),
					InsertCurrentFP = Table.AddColumn(InsertCurrentFQ, "IsCurrentFP", each if [FPeriodnYear] = CurrentFP then true else false, type logical),
					InsertCurrentFW = Table.AddColumn(InsertCurrentFP, "IsCurrentFW", each if [FWeeknYear] = InsertISOYrOffset then true else false, type logical),
					InsertPYTD = Table.AddColumn(InsertCurrentFW, "IsPYTD", each if CurrentYear-1 = [Year] and [Day of Year] <= CurrentDateRecord{0}[Day of Year] then true else false, type logical),
						ListPrevFYDates = List.Buffer( Table.SelectRows( Table.ExpandTableColumn( Table.NestedJoin(
							Table.AddIndexColumn( Table.RenameColumns( Table.TransformColumnTypes( Table.FromList( List.Dates( PrevFiscalFirstDay, Number.From(CurrentFiscalFirstDay-PrevFiscalFirstDay),#duration(1,0,0,0)), Splitter.SplitByNothing()),{{"Column1", type date}}), {{"Column1", "DateFY"}}), "Index", 1, 1), {"Index"}, 
							Table.AddIndexColumn( Table.RenameColumns( Table.TransformColumnTypes( Table.FromList( List.Dates( Date.AddYears( PrevFiscalFirstDay, -1), Number.From( PrevFiscalFirstDay - Date.AddYears( PrevFiscalFirstDay, -1)),#duration(1,0,0,0)), Splitter.SplitByNothing()),{{"Column1", type date}}), {{"Column1", "DateFY"}}), "Index", 1, 1)
							, {"Index"}, "Table", JoinKind.LeftOuter), "Table", {"DateFY"}, {"PrevDateFY"}), each [DateFY] <= CurrentDate)[PrevDateFY] ),
					InsertPFYTD 		= Table.AddColumn(InsertPYTD, "IsPFYTD", each if [Fiscal CurrYearOffset] = -1 and List.Contains(ListPrevFYDates, [Date] ) then true else false, type logical),
					InsertNetWorkdays 	= if AddRelativeNetWorkdays = true then Table.AddColumn(InsertPFYTD, "Relative Networkdays", each fxNETWORKDAYS( StartDate, [Date], Holidays ), type number ) else InsertPFYTD,
					fxNETWORKDAYS 		= (StartDate, EndDate, optional Holidays as list) =>
						let
							ListOfDates 	= List.Dates( StartDate, Number.From(EndDate-StartDate)+1, Duration.From(1) ),
							DeleteHolidays 	= if Holidays = null then ListOfDates else List.Difference( ListOfDates, List.Transform(Holidays, Date.From )),
							DeleteWeekends 	= List.Select( DeleteHolidays, each Date.DayOfWeek( _, Day.Monday) < 5 ),
							CountDays 		= List.Count( DeleteWeekends)
						in
						CountDays,
					RemoveToday = Table.RemoveColumns( if EndDate < CurrentDate then Table.SelectRows(InsertNetWorkdays, each ([Date] <> CurrentDate)) else InsertNetWorkdays, {"Day of Year", "FiscalFirstDay"}), 
					ChType 		= Table.TransformColumnTypes(RemoveToday,{{"Year", Int64.Type}, {"Quarter Number", Int64.Type}, {"Month", Int64.Type}, {"Day of Month", Int64.Type}, {"DateInt", Int64.Type}, {"Day of Week Number", Int64.Type}, {"ISO CurrYearOffset", Int64.Type}, {"ISO QuarternYear", Int64.Type}, {"ISO CurrQuarterOffset", Int64.Type}, {"Week Number", Int64.Type}, {"WeeknYear", Int64.Type}, {"MonthnYear", Int64.Type}, {"QuarternYear", Int64.Type}, {"FQuarternYear", Int64.Type}, {"Fiscal Period Number", Int64.Type}, {"FPeriodnYear", Int64.Type}, {"CurrWeekOffset", Int64.Type}, {"CurrMonthOffset", Int64.Type}, {"CurrQuarterOffset", Int64.Type}, {"CurrYearOffset", Int64.Type}, {"Fiscal CurrYearOffset", Int64.Type}, {"Fiscal Week Number", Int64.Type}}),
					ReorderCols = Table.ReorderColumns(ChType,{"Date", "Year", "CurrYearOffset", "YearCompleted", "Quarter Number", "Quarter", "Start of Quarter", "End of Quarter", "Quarter & Year", "QuarternYear", "CurrQuarterOffset", "QuarterCompleted", "Month", "Start of Month", "End of Month", "Month & Year", "MonthnYear", "CurrMonthOffset", "MonthCompleted", "Month Name", "Month Short", "Month Initial", "Day of Month", "Week Number", "Start of Week", "End of Week", "Week & Year", "WeeknYear", "CurrWeekOffset", "WeekCompleted", "Day of Week Number", "Day of Week Name", "Day of Week Initial", "DateInt", "CurrDayOffset", "IsAfterToday", "IsWeekDay", "IsHoliday", "IsBusinessDay", "Day Type", "ISO Year", "ISO CurrYearOffset", "ISO Quarter Number", "ISO Quarter", "ISO Quarter & Year", "ISO QuarternYear", "ISO CurrQuarterOffset", "Fiscal Year", "Fiscal CurrYearOffset", "Fiscal Quarter", "FQuarternYear", "Fiscal Period Number", "Fiscal Period", "FPeriodnYear", "DateFW", "Fiscal Week Number", "Fiscal Week", "FWeeknYear", "IsCurrentFY", "IsCurrentFQ", "IsCurrentFP", "IsCurrentFW", "IsPYTD", "IsPFYTD"}),
					ListCols 	= if FWlogic then Table.RemoveColumns(ReorderCols,{"ISO Quarter Number", "Fiscal Year", "Fiscal Quarter", "FQuarternYear", "Fiscal Period Number", "Fiscal Period", "FPeriodnYear", "DateFW", "Fiscal Week Number", "Fiscal Week", "FWeeknYear", "Fiscal CurrYearOffset", "IsCurrentFQ", "IsCurrentFP", "IsCurrentFW"}) else Table.RemoveColumns(ReorderCols,{"Fiscal Period Number", "DateFW", "Fiscal Week Number", "ISO Quarter Number"})
				in  ListCols,
			
			Documentation = 
			[
				Documentation.Name =  			" fxCalendar", 
				Documentation.Description = 	" Date table function to create an ISO-8601 calendar", 
				Documentation.LongDescription = " Date table function to create an ISO-8601 calendar", 
				Documentation.Category = 		" Table", 
				Documentation.Version = 		" 2.02: full code review",
				Documentation.Source = 			" local", 
				Documentation.Author = 			" Melissa de Korte", 
				Documentation.Examples = { 
					[	Description =  " See: https://forum.enterprisedna.co/t/extended-date-table-power-query-m-function/6390", 
						Code = " Optional paramters: #(lf)
							(FYStartMonthNum) Month number the fiscal year starts, Januari if omitted #(lf) 
							(Holidays) Select a query (and column) that contains a list of holiday dates #(lf) 
							(WDStartNum) Switch default weekday numbering from 0-6 to 1-7 by entering a 1 #(lf)
							(AddRelativeNetWorkdays) if true adds a Relative Networkdays column to the date table #(lf)
							#(lf)
							Important to note: #(lf)
							[Fiscal Week] starts on a Monday and can contain less than 7 days in a First- and/or Last Week of a FY #(lf)
							[IsWeekDay] does not take holiday dates into account  #(lf)
							[IsBusinessDay] does take optional holiday dates into account  #(lf)
							[IsPYTD] and [IsPFYTD] compare Previous [Day of Year] with the Current [Day of Year] number, so dates don't align in leap years #(lf)
							IMPORTANT! No Fiscal columns will be added if the (FYStartMonthNum) is omitted", 
						Result = " " 
					] }
			],
				
			result = Value.ReplaceType( fnDateTable, Value.ReplaceMetadata( Value.Type( fnDateTable ), Documentation ))
		] [result],
	
	ISO Calendar = // https://gorilla.bi/power-query/create-iso-week-and-iso-year/
		let
			/*  The following Values are used for computing ISO Weeks */
			FxCurrentThursday = 
				(DateValue as date ) as date => 
					Date.AddDays( DateValue, 3 - Date.DayOfWeek( DateValue, Day.Monday)),
			
			FxFirstThursdayOfYear = 
				(DateValue as date ) as date => [ 
						CurrentThursday		= FxCurrentThursday( DateValue ),
						YearCurrThursday 	= Date.Year( CurrentThursday ),
						FirstThursdayOfYear = Date.AddDays( #date( YearCurrThursday, 1, 7), - Date.DayOfWeek( #date( YearCurrThursday, 1, 1), Day.Friday))
					][FirstThursdayOfYear],
			
			FxIsoYear 		= 
				( DateValue as date ) as number => [
					DaysDifference 	= Duration.Days( FxCurrentThursday(DateValue) - FxFirstThursdayOfYear(DateValue ) ),
					WeekNumber 		= ( DaysDifference / 7 ) + 1,
					ResultYear 		= Date.Year( Date.AddDays( DateValue, 26 - WeekNumber))
				] [ResultYear],
			CurrentIsoYear 	= FxIsoYear( Today ),
			FxIsoWeek 		= 
				( DateValue as date ) as number =>  
					Duration.Days(FxCurrentThursday(DateValue) - FxFirstThursdayOfYear( DateValue )) / 7 + 1,
			CurrentIsoWeek 	= FxIsoWeek( Today ),
			ISOStartYears 	= [ 
					StartYear 		= Date.Year( StartDate ),
					NumberOfYears 	= Date.Year( EndDate) - StartYear +1,
					Years 			=  { 0..NumberOfYears },
					Dates 			= List.Transform( Years, each #date( StartYear + _, 6, 1  ) ),
					ISOStartYears 	= List.Buffer( List.Transform( Dates, each Date.StartOfWeek( FxFirstThursdayOfYear( _ ) ) ) )
				] [ISOStartYears],
			______________________StartCalendar___________ = ISOStartYears,
			
			Today = Date.From(DateTime.LocalNow()),
			fxMultiAdd = (tbl as table, nms as list) as table => List.Accumulate(nms, tbl, (s, c) => Table.AddColumn(s, c{0}, c{1}, c{2}?)),
			
			// Sets the start date for your calendar
			// The calendar runs until the end of the current year. Change this if you need your calendar to run to another date. 
			StartDate 	= #date(2023,1,1 ),
			EndDate   	= Date.EndOfYear(Today) + #duration( 365,0,0,0),
			ListOfDates = List.Dates(StartDate, Duration.Days(EndDate - StartDate) + 1, #duration(1, 0, 0, 0)),
			MyDateTable = Table.FromList(ListOfDates, Splitter.SplitByNothing(), type table[Date = date], null, ExtraValues.Error),
			addColumns 	= fxMultiAdd(MyDateTable,{
				{ "DateAsInteger", 		each Number.From(Date.ToText([Date], "yyyyMMdd")), Int64.Type },
				{ "StartOfWeek", 		each Date.StartOfWeek([Date], Day.Monday), Date.Type },
				{ "EndOfWeek", 			each Date.EndOfWeek([Date]), Date.Type},
				/* Start ISO Calendar Fields. Some of these make use of the functions defined at the start of this query */    
				{ "ISO_Year", 			each FxIsoYear([Date]), Int64.Type},
				{ "ISO_YearLabel", 		each "ISO " & Text.From( [ISO_Year] ), Text.Type},
				{ "ISO_YearDefault", 	each if [ISO_Year] = CurrentIsoYear then "Current" else if [ISO_Year] = (CurrentIsoYear - 1) then "Previous" else [ISO_YearLabel], Text.Type},
				{ "ISO_StartOfYear", 	each Date.StartOfWeek( FxFirstThursdayOfYear([Date] ) ), Date.Type},
				{ "ISO_EndOfYear", 		(x)=> List.First( List.Select( ISOStartYears, each _ > x[ISO_StartOfYear] ) ) - #duration(1,0,0,0), Date.Type},
				{ "ISO_YearRangeLabel", each [ISO_YearLabel] & ": " & Date.ToText( [ISO_StartOfYear], "d MMM yyyy" ) & " - " & Date.ToText( [ISO_EndOfYear], "d MMM yyyy" ), type text },
				{ "ISO_Week", 			each FxIsoWeek([Date]), Int64.Type},
				{ "ISO_WeekLabel", 		each "ISO W" & Text.PadStart( Text.From( [ISO_Week] ), 2, "0" ), Text.Type},
				{ "ISO_WeekRangeLabel", each [ISO_WeekLabel] & ": " & Date.ToText( [StartOfWeek], "d MMM yyyy" ) & " - " & Date.ToText( [EndOfWeek], "d MMM yyyy" ), type text },
				{ "ISO_YearWeekLabel", 	each [ISO_YearLabel] & " W" & Text.PadStart( Text.From( [ISO_Week] ), 2, "0" ), Text.Type},
				{ "ISO_Quarter", 		each Number.RoundUp( List.Min( { [ISO_Week], 52 } ) / 13 ), Int64.Type },
				{ "ISO_QuarterLabel", 	each "ISO Q" & Text.From([ISO_Quarter]), Text.Type},
				{ "ISO_WeekOfQuarter", 	each [ISO_Week] - (( [ISO_Quarter] -1 ) * 13 ), Int64.Type },
				{ "ISO_YearQuarterLabel", each [ISO_YearLabel] & " Q" & Text.From([ISO_Quarter]), Text.Type},
				{ "ISO_YearOffset", 	each [ISO_Year] - CurrentIsoYear, Int64.Type },
				{ "ISO_QuarterOffset", 	each (([ISO_Year] - CurrentIsoYear) * 4) + ([ISO_Quarter] - Number.RoundUp( List.Min( {CurrentIsoWeek, 52} ) / 13)), Int64.Type},
				{ "ISO_TotalWeeks", 	each Number.RoundUp( Duration.Days( [ISO_EndOfYear] - [ISO_StartOfYear] ) / 7 ), Int64.Type },
				{ "ISO_StartOfQuarter", each Date.AddDays( FxFirstThursdayOfYear([Date]), ([ISO_Quarter] - 1) * 13 * 7  - 3 ), type date },
				// To make ISO end of quarter dates for years with 53 weeks show correctly, we use the ISO_EndOfYear calculation
				{ "ISO_EndOfQuarter", 	each if [ISO_Quarter] = 4 then [ISO_EndOfYear] else Date.AddDays( [ISO_StartOfQuarter], 7 * 13 -1 ), type date },
				{ "ISO_DayOfQuarter", 	each Number.From( [Date] - [ISO_StartOfQuarter]  ) +1, Int64.Type },
				{ "ISO_DayOfYear", 		each Number.From( [Date] - [ISO_StartOfYear]  ) +1, Int64.Type },
				{ "ISO_QuarterRangeLabel", each "ISO Q" & Text.From( [ISO_Quarter] ) & ": " & Date.ToText( [ISO_StartOfQuarter], "d MMM yyyy" ) & " - " & Date.ToText( [ISO_EndOfQuarter], "d MMM yyyy" ), type text }
			}),

			// Renames all columns so they have spaces between words. Also removes underscores.
			Rename = 
				Table.TransformColumnNames(addColumns, each 
				[	SplitTextByTransition 	= Splitter.SplitTextByCharacterTransition({"a".."z"}, {"A".."Z"})(_), 
					CombineValues 			= Text.Combine( SplitTextByTransition, " " ), 
					RemoveUnderscores 		= Text.Replace( CombineValues, "_", " ") 
				]  [RemoveUnderscores] )
		in
			Rename,
	myCalendarFunction = // очень интересный подход индийца (файл с триками)
		( 	myDate as date, 
			optional myColumns as nullable list, 
			optional cultureCode as nullable text, 
			optional FiscalYearEndMonth as number 
		) as record =>

        let 
            // 1 myDate = #date(2024,1,1),
			// 2 When a user does not provide any columns to return, just return everything
			// 3 Make sure the 'Date' column always returns.
			// 4 By default we use the culture code "en-US" for formatting text values
			Today 		  = Date.From( DateTime.LocalNow()) ,	
            GivenColumns  = myColumns ?? Record.FieldNames( myRecord ),	
            selectColumns = ({"Date"} & List.RemoveItems( GivenColumns, {"Date"} ) ),	
            cultureCode   = cultureCode ?? "en-US",    	

        /* The following record contains the logic that computes each column.
           Since this solutions aims to provide an easy way for users to pick columns, each field in the record receives metadata information about the 'Data Type', 'Description', some 'Examples', a 'Category' and a 'Subcategory'. 
          Later when use these values, the metadata can be used to pass additional information ot our date table */ 

        myRecord = 
            [  
                Date                    = myDate                                                                            meta [Index = 1, Data Type = "Date",            Description = "The original date value",                             Examples = "2025-01-01, 2025-02-15, 2025-12-31", Category = "Date",              Subcategory = "Date"],
                DateAsInteger           = Number.From(Date.ToText(myDate, "yyyyMMdd"))                                      meta [Index = 2, Data Type = "Whole Number",    Description = "The date as an integer in 'yyyyMMdd' format",         Examples = "20250101, 20250215, 20251231",       Category = "Date",              Subcategory = "Date"],
                DateDayFormat           = Date.ToText(myDate,  "ddd, %d MMM yy")                                            meta [Index = 3, Data Type = "Text",            Description = "The date in format of 'ddd %d MMM yy'",               Examples = "Sat, 1 Jul 24, Sat, 2 Jul 24",       Category = "Date",              Subcategory = "Date"],
                Year                    = Date.Year(myDate)                                                                 meta [Index = 4, Data Type = "Whole Number",    Description = "The year part of the date",                           Examples = "2025, 2024, 2023",                   Category = "Year",              Subcategory = "Date Component"],
                YearDefault             = (if Date.IsInCurrentYear( myDate ) then "Current" else 
                                          if Date.IsInPreviousYear( myDate ) then "Previous" else Text.From(Year))          meta [Index = 5, Data Type = "Text",            Description = "Displays 'Current' if the year is this year",         Examples = "2025, Current, Previous, 2022",      Category = "Year",              Subcategory = "Dynamic Current Period"],
                DayOfYearNumber         = Date.DayOfYear(myDate)                                                            meta [Index = 6, Data Type = "Whole Number",    Description = "The day of the year as a number",                     Examples = "1, 46, 365",                         Category = "Day",               Subcategory = "Day Indicator"],
                DayOfMonthNumber        = Date.Day(myDate)                                                                  meta [Index = 7, Data Type = "Whole Number",    Description = "The day of the month as a number",                    Examples = "1, 15, 31",                          Category = "Day",               Subcategory = "Date Component"],
                DayName                 = Date.DayOfWeekName(myDate, cultureCode)                                           meta [Index = 8, Data Type = "Text",            Description = "The full name of the day",                            Examples = "Monday, Tuesday, Wednesday",         Category = "Day",               Subcategory = "Description"],
                DayNameShort            = Date.ToText(myDate, "ddd", cultureCode)                                           meta [Index = 9, Data Type = "Text",            Description = "The abbreviated name of the day",                     Examples = "Mon, Tue, Wed",                      Category = "Day",               Subcategory = "Description"],
                DayInitial              = Text.Start(Date.DayOfWeekName(myDate, cultureCode), 1)                            meta [Index = 10, Data Type = "Text",           Description = "The first letter of the day name",                    Examples = "M, T, W",                            Category = "Day",               Subcategory = "Description"],
                DayOfWeekNumber         = Date.DayOfWeek(myDate, Day.Monday)                                                meta [Index = 11, Data Type = "Whole Number",   Description = "The day of the week as a number (Monday = 0)",        Examples = "0, 1, 2",                            Category = "Day",               Subcategory = "Day Indicator"],
                IsWeekendFlag           = (Date.DayOfWeek(myDate, Day.Monday) >= 5)                                         meta [Index = 12, Data Type = "Boolean",        Description = "Returns 'true' if the date is a weekend",             Examples = "FALSE, TRUE, TRUE",                  Category = "Day",               Subcategory = "Information"],
                IsWeekdayFlag           = (Date.DayOfWeek(myDate, Day.Monday) < 5)                                          meta [Index = 13, Data Type = "Boolean",        Description = "Returns 'true' if the date is a weekday",             Examples = "TRUE, FALSE, FALSE",                 Category = "Day",               Subcategory = "Information"],

                MonthNumber             = Date.Month(myDate)                                                                meta [Index = 14, Data Type = "Whole Number",   Description = "The month part of the date as a number",              Examples = "1, 2, 3",                            Category = "Month",             Subcategory = "Date Component"],
                MonthName               = Date.MonthName(myDate, cultureCode)                                               meta [Index = 15, Data Type = "Text",           Description = "The full name of the month",                          Examples = "January, February, March",           Category = "Month",             Subcategory = "Description"],
                MonthNameShort          = Date.ToText(myDate, "MMM", cultureCode)                                           meta [Index = 17, Data Type = "Text",           Description = "The abbreviated name of the month",                   Examples = "Jan, Feb, Mar",                      Category = "Month",             Subcategory = "Description"],
                MonthInitial            = Text.Start(Date.ToText(myDate, "MMM", cultureCode), 1)                            meta [Index = 18, Data Type = "Text",           Description = "The first letter of the month name",                  Examples = "J, F, M",                            Category = "Month",             Subcategory = "Description"],
                DaysInMonth             = Date.DaysInMonth(myDate)                                                          meta [Index = 19, Data Type = "Whole Number",   Description = "The number of days in the month",                     Examples = "31, 28, 31",                         Category = "Month",             Subcategory = "Information"],
                MonthYearShort          = Date.ToText(myDate, "MMM yyyy", cultureCode)                                      meta [Index = 20, Data Type = "Text",           Description = "Month and year in 'MMM yyyy' format",                 Examples = "Jan 2025, Feb 2025, Mar 2025",       Category = "Month",             Subcategory = "Composite Time Periods"],
                YearMonthNumber         = Date.ToText(myDate, "yyyy-MM")                                                    meta [Index = 21, Data Type = "Text",           Description = "Year and month in 'yyyy-MM' format",                  Examples = "2025-01, 2025-02, 2025-03",          Category = "Month",             Subcategory = "Composite Time Periods"],
                YearMonthShort          = Date.ToText(myDate, "yyyy MMM", cultureCode )                                     meta [Index = 22, Data Type = "Text",           Description = "Year and month in 'yyyy-MMM' format",                 Examples = "2025 Jan, 2025 Feb, 2025 Mar",       Category = "Month",             Subcategory = "Composite Time Periods"]
        ],


        /* ____________________________________________________________________________________________________________________________________
        |   The above record still needs the relevant data types. The below setup helps me define the relevant data types for each value. I have separated the logic, so I can filter on the fields that users require. 
            Later I combine both the record value and record type using the Type.ForRecord function */ 

        myRecordTypeBase =
        [
            Date =                      [ Type = Date.Type,      Optional = false ],
            DateAsInteger =             [ Type = Int64.Type,     Optional = false ],
            DateDayFormat =             [ Type = Text.Type,      Optional = false ],
            
            Year =                      [ Type = Int64.Type,     Optional = false ],
            YearDefault =               [ Type = Text.Type,      Optional = false ],
            DayOfYearNumber =           [ Type = Int64.Type,     Optional = false ],
            DayOfMonthNumber =          [ Type = Int64.Type,     Optional = false ],
            DayName =                   [ Type = Text.Type,      Optional = false ],
            DayNameShort =              [ Type = Text.Type,      Optional = false ],
            DayInitial =                [ Type = Text.Type,      Optional = false ],
            DayOfWeekNumber =           [ Type = Int64.Type,     Optional = false ],
            IsWeekendFlag =             [ Type = Logical.Type,   Optional = false ],
            IsWeekdayFlag =             [ Type = Logical.Type,   Optional = false ],
            
            MonthNumber =               [ Type = Int64.Type,     Optional = false ],
            MonthName =                 [ Type = Text.Type,      Optional = false ],
            MonthNameShort =            [ Type = Text.Type,      Optional = false ],
            MonthInitial =              [ Type = Text.Type,      Optional = false ],
            DaysInMonth =               [ Type = Int64.Type,     Optional = false ],
            MonthYearShort =            [ Type = Text.Type,      Optional = false ],
            YearMonthNumber =           [ Type = Text.Type,      Optional = false ],
            YearMonthShort =            [ Type = Text.Type,      Optional = false ]
        ], 

            // Select only the relevant fields from the record with field name definitions
            mySelectedRecordTypeFields = Record.SelectFields( myRecordTypeBase, selectColumns ),
            myRecordType = Type.ForRecord( mySelectedRecordTypeFields, false ),

            // Select only the relevant field names from the record type definition
            mySelectedRecordFields = Record.SelectFields( myRecord, selectColumns ),

            // Now set the structured data type for record with our value definitions
            myRecordAndType = Value.ReplaceType( mySelectedRecordFields, myRecordType )

        in 
            myRecordAndType,
	Заглушка = 1
	],

Camwally   = [ // https://github.com/camwally/Power-Query/blob/master
	CreateTable  = //! формирует код таблицы на M по двоичному коду Binary.FromText("jVPbas...")
		(InputTable as table) as text =>
		let 
			Source 	 = Table.Schema(InputTable),
			SortRows = Table.Sort(Source,{{"Position", Order.Ascending}}),
			SimplifyTypeNameRec = 
				[
					#"Any.Type" 	 	= "any",
					#"Binary.Type" 	 	= "binary",
					#"Date.Type" 	 	= "date",
					#"DateTime.Type" 	= "datetime",
					#"DateTimeZone.Type" = "datetimezone",
					#"Duration.Type" 	= "duration",
					#"Function.Type" 	= "function",
					#"List.Type" 	 	= "list",
					#"Logical.Type"  	= "logical",
					#"None.Type" 	 	= "none",
					#"Null.Type" 	 	= "null",
					#"Number.Type" 	 	= "number",
					#"Record.Type" 	 	= "record",
					#"Table.Type" 	 	= "table",
					#"Text.Type" 	 	= "text",
					#"Time.Type" 	 	= "time",
					#"Type.Type" 	 	= "type"
				],

			SimplifyTypeNames = 
				Table.TransformColumns(SortRows,
					{{"TypeName", each Record.FieldOrDefault(SimplifyTypeNameRec,_,_), type text}}
				),
			RemoveColumns = Table.SelectColumns(SimplifyTypeNames,{"Name", "TypeName","IsNullable"}),
			AddCustom = 
				Table.AddColumn(
					RemoveColumns, 
					"TypeNames", 
					each 
					Expression.Identifier([Name]) & " = " & (if [IsNullable] then "nullable " else "") & [TypeName]
				),
			
			TableTypeRec =  "[" & Text.Combine(AddCustom[TypeNames], ", ") & "]",

			//Code above is based on a function by Chris Webb
			ValuesToConstant = Table.TransformColumns(InputTable,{},Expression.Constant),
			ValuesToConstLen = Table.TransformColumns(ValuesToConstant,{},Text.Length),
			MaxLengthEachCol = List.Buffer(List.Transform(Table.ToColumns(ValuesToConstLen),List.Max)),
			List = 	List.Transform(
						Table.ToRows(ValuesToConstant),
						(RowAsList)=> 
							let
								Zip 	= List.Zip({RowAsList,MaxLengthEachCol}),
								PadOut 	= List.Transform(Zip,each Function.Invoke(Text.PadEnd,_)),
								CombineValues = "{" & Text.Combine(PadOut,",") & "}"
							in 
								CombineValues
					),
			Body = "{" & Text.Combine(List,",#(lf)") & "}",
			Together =	"#table(type table" 
						& TableTypeRec
						& ",#(lf)"
						& Body
						& "#(lf))"
		in	Together,
	
	CreateTable2 = // немного по другому
		(inputTable as table) as text =>
		let
			source = Table.Schema(inputTable)
			,sortRows = Table.Sort(source,{{"Position", Order.Ascending}})
			,simplifyTypeNameRec = 
					[#"Any.Type" = "any"
					,#"Binary.Type" = "binary"
					,#"Date.Type" = "date"
					,#"DateTime.Type" = "datetime"
					,#"DateTimeZone.Type" = "datetimezone"
					,#"Duration.Type" = "duration"
					,#"Function.Type" = "function"
					,#"List.Type" = "list"
					,#"Logical.Type" = "logical"
					,#"None.Type" = "none"
					,#"Null.Type" = "null"
					,#"Number.Type" = "number"
					,#"Record.Type" = "record"
					,#"Table.Type" = "table"
					,#"Text.Type" = "text"
					,#"Time.Type" = "time"
					,#"Type.Type" = "type"]
			,simplifyTypeNames = Table.TransformColumns(sortRows,{{"TypeName", each Record.FieldOrDefault(simplifyTypeNameRec,_,_)}})
			,selectColumns = Table.SelectColumns(simplifyTypeNames,{"Name", "TypeName","IsNullable"})
			,addColOfTypeNames = 
					Table.AddColumn(
						selectColumns 
					,"TypeNames" 
					,each 
							Expression.Identifier([Name]) 
						& " = " 
						& (if [IsNullable] then "nullable " else "") 
						& [TypeName]
					)
			,tableTypeRec = "[" & Text.Combine(addColOfTypeNames[TypeNames], ", ") & "]" 

			//Code above is based on a function by Chris Webb

			,tableOfExpressions = Table.TransformColumns(inputTable,{},Expression.Constant)
			,listOfCols = Table.ToColumns(tableOfExpressions)
			,listOfColsOfPaddedText = 
					List.Transform(
						listOfCols
					,(col as list)=>
							let 
								buf = List.Buffer(col),
								maxTextLength = List.Max(List.Transform(buf,Text.Length)),
								paddedText = List.Transform(buf,each Text.PadEnd(_,maxTextLength))
							in
								paddedText
					)
			,listOfRowsOfPaddedText = List.Zip(listOfColsOfPaddedText)
			,bodyAsList = List.Transform(listOfRowsOfPaddedText, (row as list)=> "{"&Text.Combine(row,",")&"}")
			,bodyAsText = "{"&Text.Combine(bodyAsList,"#(lf),")&"#(lf)}"
			,together =   "#table(type table " 
						& tableTypeRec
						& ",#(lf)"
						& bodyAsText
						& ")"
		in together,
	
	CreateTable3 = // немного по другому + аргумент второй
		(inputTable as table, optional #"table type is vertical?" as nullable logical) as text =>
		let	
			vert = #"table type is vertical?" ?? false 
			,source = Table.Schema(inputTable)
			,sortRows = Table.Sort(source,{{"Position", Order.Ascending}})
			,simplifyTypeNameRec = 
				[#"Any.Type" = "any"
				,#"Binary.Type" = "binary"
				,#"Date.Type" = "date"
				,#"DateTime.Type" = "datetime"
				,#"DateTimeZone.Type" = "datetimezone"
				,#"Duration.Type" = "duration"
				,#"Function.Type" = "function"
				,#"List.Type" = "list"
				,#"Logical.Type" = "logical"
				,#"None.Type" = "none"
				,#"Null.Type" = "null"
				,#"Number.Type" = "number"
				,#"Record.Type" = "record"
				,#"Table.Type" = "table"
				,#"Text.Type" = "text"
				,#"Time.Type" = "time"
				,#"Type.Type" = "type"]
			,simplifyTypeNames = Table.TransformColumns(sortRows,{{"TypeName", each Record.FieldOrDefault(simplifyTypeNameRec,_,_)}})
			,selectColumns = Table.SelectColumns(simplifyTypeNames,{"Name", "TypeName","IsNullable"})
			,addColOfTypeNames = 
				Table.AddColumn(
						selectColumns 
					,"TypeNames" 
					,each 
							Expression.Identifier([Name]) 
							& " = " 
							& (if [IsNullable] then "nullable " else "") 
							& [TypeName]
				)
			,tableTypeRec = "[" & Text.Combine(addColOfTypeNames[TypeNames], if vert then "#(lf)," else ", ") & "]" 

			//Code above is based on a function by Chris Webb

			,tableOfExpressions = Table.TransformColumns(inputTable,{},Expression.Constant)
			,listOfCols = Table.ToColumns(tableOfExpressions)
			,listOfColsOfPaddedText = 
				List.Transform(
						listOfCols
					,(col as list)=>
					let 
							buf = List.Buffer(col),
							maxTextLength = List.Max(List.Transform(buf,Text.Length)),
							paddedText = List.Transform(buf,each Text.PadEnd(_,maxTextLength))
						in
							paddedText
				)
				,listOfRowsOfPaddedText = List.Zip(listOfColsOfPaddedText)
				,bodyAsList = List.Transform(listOfRowsOfPaddedText, (row as list)=> "{"&Text.Combine(row,",")&"}")
				,bodyAsText = "{"&Text.Combine(bodyAsList,"#(lf),")&"#(lf)}"
				,together =  
						"#table(type table"
					& (if vert then "#(lf)" else "")
					& tableTypeRec
					& ",#(lf)"
					& bodyAsText
					& ")"
		in	together,
	
	Table.ToRecordOfLists 	= 
		(table as table, optional buffer as nullable logical)=>
			let
				tab    = if buffer = true then Table.Buffer(table) else table,
				Name   = Table.ColumnNames(tab),
				Value  = Table.ToColumns(tab),
				Record = Record.FromTable(Table.FromColumns({Name, Value},{"Name","Value"}))
			in
				Record,

	Table.FromRecordOfLists = 
		(rec as record)=>
			let
				tab2col = Record.ToTable(rec),
				valuess_names = List.Reverse(Table.ToColumns(tab2col)),
				tab = Function.Invoke(Table.FromColumns, valuess_names)
			in
				tab,

	fClusteredIndex 	= 
		(Table as table, GroupOnCols as list) => 
			let
				Group = Table.Group(
							Table, 
							GroupOnCols, 
							{"ColumnOfTables",each Table.AddIndexColumn(_, "ClustIndex", 0, 1)}
						),
				Combine = Table.Combine(Group[ColumnOfTables])
			in
				Combine,
	
	fCombineJoins 		= 
		(	LeftTable as table, 	LeftKey as list,
			RightTable as table,	RightKey as list,
			ListOfJoins as list
		) =>
			let
				Func = each Table.NestedJoin(LeftTable, LeftKey, RightTable, RightKey,"Right",_),
				ListOfTables = List.Transform(ListOfJoins, Func),
				Combine = Table.Combine(ListOfTables)
			in
				Combine,
	
	fDistinctColumns 	= 
		/* 	Эти функции в основном представляют собой версии функций, созданных Microsoft. 
			Однако эти функции помогают сохранить возвращаемые типы функций, которые так легко теряются. 
			Одним из практических результатов использования этих функций в ваших запросах является то, 
			что столбцы вашей таблицы с меньшей вероятностью изменятся на какой-либо тип  */

		(Table as table, optional MaxLength as number)=>
			let
				TableType 	= Value.Type(Table),
				ColNames 	= Table.ColumnNames(Table),
				ListOfCols 	= List.Transform(Table.ToColumns(Table), List.Distinct),
				Meta 		= List.Transform(List.Zip({ListOfCols,ColNames}), each _{0} meta [ColName = _{1}]),
				SelectList 	= List.Buffer(if MaxLength = null then Meta else List.Select(Meta, each List.Count(_)<=MaxLength)),
				NewColNames = List.Transform(SelectList, each Value.Metadata(_)[ColName]),
				NewTable 	= Table.FromColumns(SelectList,NewColNames)
			in
				NewTable,

	ReplaceUsingTable 	= // замена по словарю, но что то не то. Проверить на примерах
		/*
			функция создает механизм замены значений на основе переданной таблицы, 
			позволяя заменять значения по ключам из первого столбца таблицы

			Принимает таблицу: 
				Функция принимает параметр Table
			Создание записи:
				Table.ToColumns(Table) 	извлекает все столбцы из таблицы.
				List.FirstN(..., 2) 	берёт первые два столбца из этой таблицы.
				Table.FromColumns(...) 	создает новую таблицу из двух первых столбцов с именами "Name" и "Value".
				Record.FromTable(...) 	преобразует эту новую таблицу в запись Rec, где ключами являются значения 
										из первого столбца ("Name"), а значениями из второго столбца ("Value").
			Возвращаемая функция:
				Вложенная анонимная функция принимает строку Text в качестве параметра.
				Если Text равен null, функция возвращает null.
				В противном случае используется Record.FieldOrDefault(Rec, Text, Text) для извлечения значения 
				из записи Rec по ключу Text. Если ключ не найден, возвращается сам Text.
		*/
		
		(Table as table)=>
			let 
				Rec = Record.FromTable(
						Table.FromColumns(
							List.FirstN(Table.ToColumns(Table),2),
							{"Name","Value"})
						)
			in 
				(Text as text)=> 
					if   Text = null 
					then null 
					else Record.FieldOrDefault(Rec,Text,Text),

	MultipleCombineColumnsRecord = // изучить, интересно
		/* 
		Example Control Table
			#table(
				type table [_Name = nullable text, Value = nullable number, Flag = nullable text],
				{
					{"Temperature Min"     ,"Temperature Min"     ,"Temperature Min Flag"     },
					{"Temperature Mean"    ,"Temperature Mean"    ,"Temperature Mean Flag"    },
					{"Temperature Max"     ,"Temperature Max"     ,"Temperature Max Flag"     },
					{"Precipitation Liquid","Precipitation Liquid","Precipitation Liquid Flag"},
					{"Precipitation Solid" ,"Precipitation Solid" ,"Precipitation Solid Flag" }
				}
			)
		*/

		(table as table, controlTable as table)=>
			let
				RecType 	  = Type.TableRow(Value.Type(Table.RemoveColumns(controlTable,"_Name"))),
				RecFieldNames = List.Buffer(Record.FieldNames(Type.RecordFields(RecType))),
				ControlVals   = 
					List.Transform(
						Table.ToRows(controlTable),
						each [ColName = _{0}, OriginalRecFieldNames = List.Skip(_)]
					),

				Next = 	
					List.Accumulate(
						ControlVals,
						table,
						(tab,cv)=>
							let	RenameCols  = Table.RenameColumns(tab,List.Zip({cv[OriginalRecFieldNames],RecFieldNames})),
								CombineCols = Table.CombineColumnsToRecord(RenameCols,cv[ColName],RecFieldNames)
							in	CombineCols
					)
			in
				Next,

	MonthlyRatios 	= // в допстолбце % от общего числа дней в каждом месяце
		// в дополнительном столбце % от общего числа дней в каждом месяце (15-е число будет = 50% от числа дней)
		(start as date, end as date)=>
		let
			datesAsInt =  // список целых номеров месяцев от самого начала 
				let DateToInt = each Date.Year(_) * 12 + Date.Month(_) - 1 
				in 	{DateToInt(start)..DateToInt(end)},
			
			datesAsDate = 
				List.Buffer(
					Value.ReplaceType(
						List.Transform(
							datesAsInt, 
							each #date(Number.RoundDown(_/12), Number.Mod(_,12)+1,1)
						)
					, type {date}
					)
				),

			FracOfMonthToEnd            = (date as date) => Date.Day(date)/Date.DaysInMonth(date),
			FracOfMonthToDayBeforeStart = (date as date) => (Date.Day(date)-1)/Date.DaysInMonth(date),
			noOfDates = List.Count(datesAsDate),
			fracsOfMonths = 
				Value.ReplaceType(
					if start>end 
					then error "end date before start date" 
					else if noOfDates = 1 
							then 	{FracOfMonthToEnd(end)-FracOfMonthToDayBeforeStart(start)} 
							else 	{1-FracOfMonthToDayBeforeStart(start)}
								& List.Repeat({1},noOfDates-2)
								& {FracOfMonthToEnd(end)},
					type {Percentage.Type}
				),
			datesInTable = Table.FromColumns({datesAsDate, fracsOfMonths},{"Date","Fraction"}),
			addKey = Table.AddKey(datesInTable,{"Date"},true)
		in
			addKey,

	RunningTotal	= // функция создает новый столбец с накопительной суммой для значений в указанном столбце таблицы
		// не должно быть null в столбце
		(table as table, colToSum as text, colAsNew as text)=>
			let
				tableB 			= Table.Buffer(table),
				listToSum 		= List.Buffer(Table.Column(tableB,colToSum)),
				listToSumCount 	= List.Count(listToSum),
				runningTotalB 	= List.Buffer(List.Skip(
					List.Generate(
						()=> [item = 0, counter = 0],
						each [counter] <= listToSumCount,
						each [item    = [item]+listToSum{[counter]},
							  counter = [counter]+1],
						each [item]
					),1)),

				addIndex 		= Table.AddIndexColumn(tableB,"IndexUniqueName",0,1),
				addRunningTotal = Table.AddColumn(addIndex,colAsNew,each runningTotalB{[IndexUniqueName]}, type number),
				removeIndex 	= Table.RemoveColumns(addRunningTotal,{"IndexUniqueName"})
			in
				removeIndex,
	TextCleaner   	= // функция служит для очистки текста от лишних пробелов, оставляя только один пробел между словами
		(text as nullable text) as nullable text =>
			let
				Space = Character.FromNumber(32),
				Words = Text.Split(text,Space) as list,
				GetRidOfWhitespace = (word as text) as text => Text.Combine(Splitter.SplitTextByWhitespace()(word)),
				Combined = Text.Combine(List.Transform(Words,GetRidOfWhitespace),Space)
			in
				if text is null 
				then null 
				else Combined,

	PrefixAllColsExcept = 
		(Table as table, Prefix as text, optional IgnoreCols as any) =>   
		let
			listIgnoreCols = 
				if IgnoreCols is list then IgnoreCols else
				if IgnoreCols is text then {IgnoreCols} else
				if IgnoreCols is null then {} else
				error "Invalid IgnoreCols Argument",

			ColNamesToChange = List.RemoveItems(Table.ColumnNames(Table), listIgnoreCols),
			ListOfLists 	 = List.Transform(ColNamesToChange, each {_, Prefix & _}),
			RenameCols  	 = Table.RenameColumns(Table,ListOfLists)
		in
			RenameCols,

	PrefixCols = // установить префиксы в список колонок 
		(Table as table, Prefix as text, Cols as list) =>   
			let
				ListOfLists = List.Transform(Cols, each {_, Prefix & _}),
				RenameCols  = Table.RenameColumns(Table, ListOfLists)
			in
				RenameCols,
		
	Logical_to_Display_SQL_to_M	= //! ошибка тут 
		let
			Source = #table({},{}),	// надо Source = SQL
			#"Added custom 5" 		= Table.AddColumn(Source, "Column Display Name if change", each if [Column Logical Name] = [Column Display Name] then null else [Column Display Name], type text),
			#"Added custom" 		= Table.AddColumn(#"Added custom 5", "Column Logical Name With Name Suffix", each _[Column Logical Name]&"name", type nullable text),
			#"Self Join" 			= Table.NestedJoin(#"Added custom",{"Table Logical Name","Column Logical Name With Name Suffix"},#"Added custom",{"Table Logical Name","Column Logical Name"},"Text Col",JoinKind.LeftOuter),
			#"Expanded Text Col 1" 	= Table.ExpandTableColumn(#"Self Join", "Text Col", {"Column Display Name if change"}, {"Column Display Name of Text Version"}),
			#"Removed columns 3" 	= Table.RemoveColumns(#"Expanded Text Col 1", {"Column Logical Name With Name Suffix"}),
			#"Sorted rows 1" 		= Table.Sort(#"Removed columns 3", {{"Column Id", Order.Ascending}}),
			#"Added custom 2" 		= Table.AddColumn(#"Sorted rows 1", "Make Unique", each [Column Display Name of Text Version] & " " & Record.FieldOrDefault([#"uniqueidentifier"="GUID",#"int"="ID",#"bit"="True/False"],[Column Type Name]), type nullable text), 
			#"Removed columns 1" 	= Table.RemoveColumns(#"Added custom 2", {"Column Display Name of Text Version"}),
			#"Added custom 6" 		= Table.AddColumn(#"Removed columns 1", "Status Columns", each Record.FieldOrDefault([statecode = "Status ID",statecodename = "Status",statuscode = "Status Reason ID",statuscodename = "Status Reason"],[Column Logical Name]), type nullable text),
			#"Added custom 3" 		= Table.AddColumn(#"Added custom 6", "Project ID Names", each if [Is First Primary Key] = true then [Table Display Name] & " GUID" else if [Column Display Name] = "Name" then [Table Display Name] else null, type nullable text),
			#"Renamed columns" 		= Table.RenameColumns(#"Added custom 3", {{"Column Display Name", "Column Display Name Original"}}),
			#"Added custom 1" 		= Table.AddColumn(#"Renamed columns", "Column Display Name", each [Project ID Names] ?? [Status Columns] ?? [Make Unique] ?? [Column Display Name if change], type nullable text),
			#"Removed columns 2"   	= Table.RemoveColumns(#"Added custom 1", {"Column Display Name if change", "Make Unique", "Status Columns", "Project ID Names", "Is First Primary Key"}),
			#"Reordered columns 2" 	= Table.ReorderColumns(#"Removed columns 2", {"Table Logical Name", "Table Display Name", "Column Logical Name", "Column Display Name Original", "Column Display Name", "Column Id", "Column Type Name", "Column Max Length"}),
			ColumnType = 
				type nullable table
					[ 	
						#"Table Logical Name" = nullable text,
						#"Table Display Name" = nullable text,
						#"Column Logical Name" = nullable text,
						#"Column Display Name Original" = nullable text,
						#"Column Display Name" = nullable text,
						#"Column Id" = nullable Int64.Type,
						#"Column Type Name" = nullable text,
						#"Column Max Length" = nullable Int64.Type
					], 
			#"Grouped rows" 		= Table.Group(#"Reordered columns 2", {"Table Logical Name", "Column Display Name"}, {{"Column Display Name Count", each Table.RowCount(_), Int64.Type}, {"Table", each _, ColumnType}}),
			#"Expanded Table" 		= Table.ExpandTableColumn(#"Grouped rows", "Table", {"Table Display Name", "Column Logical Name", "Column Display Name Original", "Column Id", "Column Type Name", "Column Max Length"}, {"Table Display Name", "Column Logical Name", "Column Display Name Original", "Column Id", "Column Type Name", "Column Max Length"}),
			#"Reordered columns" 	= Table.ReorderColumns(#"Expanded Table", {"Table Logical Name", "Table Display Name", "Column Logical Name", "Column Display Name Original", "Column Display Name", "Column Id", "Column Type Name", "Column Max Length","Column Display Name Count"}),
			#"Added custom 4" 		= Table.AddColumn(#"Reordered columns", "Custom", each let val = [Column Display Name] in if val = null then null else if [Column Display Name Count] > 1 then val & " (" & [Column Logical Name] & ")" else val, type nullable text),
			#"Reordered columns 1" 	= Table.ReorderColumns(#"Added custom 4", {"Custom", "Column Display Name"}),
			#"Removed columns" 		= Table.RemoveColumns(#"Reordered columns 1", {"Column Display Name", "Column Display Name Count"}),
			#"Renamed columns 1" 	= Table.RenameColumns(#"Removed columns", {{"Custom", "Column Display Name"}}),
			#"Sorted rows" 			= Table.Sort(#"Renamed columns 1", {{"Table Logical Name", Order.Ascending}, {"Column Id", Order.Ascending}})
		in
			#"Sorted rows",

	fStableSortAndOrderFirstOccurrence = //! повтор, см по GroupKind.Local, Comparer
		/*	It's a bit like Table.Sort, but:
				1) Sorts are stable
				2) If you neglect to put a Order.Ascending or a Order.Descending then ordered by first occurrence 
		*/
				
		(Table as table, List as list) =>
			let
				fMakeEfficientList = (List as list) =>
					let 
						ColName 	= List.Transform(List, each _{0}),
						Order 		= List.Transform(List, each _{1}?),
						TableForm 	= Table.FromColumns({ColName,Order},{"ColName","Order"}),
						Comparer 	= (a as record, b as record) => Number.From(a[Order] is null or b[Order] is null),
						PartionedTable = Table.Group(TableForm, {"Order"}, {{"NestedLists", each Table.ToRows(_), type list}},GroupKind.Local, Comparer),
						PartionedList = PartionedTable[NestedLists]
					in
						PartionedList,

				fReorder = (Table as table, List as list) =>
					let
						ListItem 		 = List.Buffer(List{0}) ,
						ListItemColNames = List.Buffer(List.Zip(ListItem){0}),
						GroupedTable 	 = Table.Group(Table, ListItemColNames, {{"NestedTables", each Table.RemoveColumns(_,ListItemColNames), type table}}),
						SortedTable 	 = if ListItem{0}{1} = null then GroupedTable else Table.Sort(GroupedTable,ListItem),
						fRecursion 	 	 = each if List.Count(List) > 1 then @fReorder(_, List.Skip(List)) else _,
						RecurseOnNestedTables = Table.Buffer(Table.TransformColumns(SortedTable, {"NestedTables", fRecursion})),
						Expand = Table.ExpandTableColumn(RecurseOnNestedTables, "NestedTables", Table.ColumnNames(RecurseOnNestedTables[NestedTables]{0}))
					in
						Expand,
					
				EfficientList 	= List.Buffer(fMakeEfficientList(List)),
				ReorderRows 	= fReorder(Table,EfficientList),
				ReclaimColOrder = Table.ReorderColumns(ReorderRows,Table.ColumnNames(Table)),
				ReclaimColTypes = Value.ReplaceType(ReclaimColOrder,Value.Type(Table))
			in
				ReclaimColTypes,
		
	fSyncTableTypeOfCol = 
		/*
			Присваивает тип столбцу на основе первой таблицы в столбце как 
			Table.TransformColumnTypes, но не работает со сложными типами. Например: type table[A=text, B=number]

			https://social.technet.microsoft.com/Forums/en-US/636e9b44-6820-4ff2-ab60-5dd6a5307bd2/type-conversion-mysteries
		*/
		(PreviousStep as table, ColName as text) =>
			Table.TransformColumns(
				PreviousStep, 
				{ColName, each {_}{0}, Value.Type(Table.Column(PreviousStep, ColName){0})}
			),
		
	fTableComparerSort 	= 
		//https://www.dingbatdata.com/2018/06/07/multilevel-sorting-comparers/
		//https://www.dingbatdata.com/2018/05/31/documentationsortcomparer/
		//Works like a Table.Sort, but also allows sorting using a comparer at the column level. 
		//One use of this is for culture sensitive sorting. 

		(	Table as table,
			comparisonCriteria as any,
			optional defaultcomparisonCriteria as any) =>
		let
			fMakeSureIsList = each if _ is list then _ else {_},
			
			Default =
				let
					List = 	fMakeSureIsList(defaultcomparisonCriteria),
					Sort = 	
						if  List{0} is number then List{0} else
						if (List{0} is null or List{0} is function) then Order.Ascending else 
						error "invalid defaultcomparisonCriteria",

					Comparer = 
						if List{0} is function then List{0} else 
						if List{1}? is function then List{1} else 
						if List{1}? is null then Value.Compare else 
						error "invalid defaultcomparisonCriteria",

					Record = [Sort = Sort, Comparer = Comparer]
				in
					Record,

			compCritListRecords = 
				let
					FirstCheck = 
						if 		Value.Type(comparisonCriteria{0}?) = type text 
							and Value.Type(comparisonCriteria{1}?) = type number 
						then {comparisonCriteria} 
						else comparisonCriteria,

					List 	 =  fMakeSureIsList(FirstCheck),
					ListList = List.Transform(List, fMakeSureIsList),
					
					fSort 	 = (Order) => 
						if Order = Order.Ascending  then 1 else 
						if Order = Order.Descending then -1 else 
						error "Order must be Order.Ascending or Order.Descending",

					ListRec =  
						List.Transform(ListList,
							each 
								let 
									ColNam = _{0} as text,
									Order  = _{1}? as nullable number,
									Comp   = _{2}? as nullable function
								in 
									[	
										ColNam = ColNam,
										Order  = fSort(if Order = null then Default[Sort] else Order),
										Comp   = if Comp = null then Default[Comparer] else Comp 
									]
						)
				in
					List.Buffer(ListRec as list),
						
			fComparer = (x as record, y as record) =>
				let 
					fFullCompare = (x,y, compCrit) => 
						let 
							cC = compCrit{0},
							comparison = cC[Comp](Record.Field(x,cC[ColNam]),Record.Field(y,cC[ColNam])),
							comparisonAllCols = 
								if comparison = 0 and List.Count(compCrit)>1 
								then @fFullCompare(x,y,List.Skip(compCrit)) 
								else comparison *cC[Order]
						in
							comparisonAllCols,
					
					CompareRec = fFullCompare(x,y,compCritListRecords)
				in
					CompareRec,

				Execute = Table.Sort(Table, fComparer)        
		in
			Execute,

	fTakeTypesAndTryApply = //! Приписывает типы из одной таблицы и применяет их к одноименным столбцам в другой таблице
		// Приписывает типы из одной таблицы и применяет их к одноименным столбцам в другой таблице
		(tblToAlter as table, tblGet as table) =>
			let
				typetblGet = Value.Type(tblGet),
				NameCols   = List.Intersect(
								{
									Table.ColumnNames(tblGet) ,
									Table.ColumnNames(tblToAlter)
								}
							),
			
				NameFuncTypes = List.Transform(
									NameCols, 
									(x) => { x, each {_}{0}, Type.TableColumn(typetblGet, x) } 
								),
				
				Transform = Table.TransformColumns(tblToAlter, NameFuncTypes)
			in
				Transform,
	
	fAddRandomColumn 	= // добавляем колонку с рандомными значениями
			/*
				Add column of random numbers between 0 and 1:			fAddRandomColumn(Source,"Random Number",0,1)
				Add column of random percentages between 0% and 100%:	fAddRandomColumn(Source,"Random Percentage",0,1,Percentage.Type)
				Retrieve random item from list:							fAddRandomColumn(Source, "Random Item",
																							0,
																							List.Count(ListOfItems),
																							{each ListOfItems{Number.RoundDown(_)}, type text}
																						)
					(ListOfItems would need to be buffered into memory for it to run quickly, e.g. ListOfItems = List.Buffer(SomeList))
			*/

			(	
				Table as table, 
				RandColName as text, 
				Min as number, 
				Max as number, 
				optional TransformAndTypeCriteria as any
			) =>

			let
				List = List.Buffer( 
						if not (TransformAndTypeCriteria is list)  then {TransformAndTypeCriteria} else
						if List.Count(TransformAndTypeCriteria)<=2 then TransformAndTypeCriteria else
						error "Invalid Criteria (Too many items)" ),
				
				TransformFunc = 
					if	List{0} is null or List{0} is type then null else
					if 	List{0} is function then List{0} else
					error "Invalid Criteria (Tranform)",

				ListLast = List.Last(List),
				
				Type = 
					if ListLast is null or ListLast is function then type number else  
					if ListLast is type then ListLast else
					error "Invalid Criteria (Type)",

				FirstName = Table.ColumnNames(Table){0},
				
				AddColumn = Table.AddColumn(Table,
								RandColName,
								each Number.RandomBetween(if Record.Field(_,FirstName)=null then Min else Min, Max),
								Type),
				Transform = 
					if TransformFunc = null 
					then AddColumn 
					else Table.TransformColumns(AddColumn,{RandColName, TransformFunc})
			in
				Transform,
	Заглушка = ""
	],
Monky  	   = [ // из книги "Приручи данные"
	fnSmartFolder  = 1 // возвращает таблицу с данными о файлах в папке или SharePoint используя Folder.Files или Folder.Contents
	],
DataAnalys = [ // https://github.com/AnHerbWorm/DataAnalysis/tree/main/powerquery
	// полезного по сути мало, но инетересно оформление и применение некоторых стандартных функций Type. 
	// интересное в ClimateCanada_GetDailyWeather в части Climate.CSVSchema = type table [ - схема таблицы
	// использование Type.ForFunction интересное в List_ValueCounts, Table_AddGroupIndex
	List_ValueCounts = // возвращает из списка уникальные значения и их количество в виде таблицы, списка или записи
		/*
			* return distinct values and their count of occurrences within the source list as a table or list
			* @name List.ValueCounts
			* @categories list
			* @author https://github.com/AnHerbWorm
			* @source https://github.com/AnHerbWorm/DataAnalysis/tree/main/powerquery
			* @result table, list of lists, or list of records
		*/
		let
			Main.Func = (list as list, optional outputAs as nullable text) as any =>
				let
					ListAsTable = #table(type table [Value=any], List.Transform(list, each {_})),
					Grouped = Table.Group(ListAsTable, {"Value"}, {{"Count", Table.RowCount, Int64.Type}}),
					Results = [
						table   = Grouped,
						lists   = Table.ToList(table, each _),
						records = Table.ToRecords(table)
					],
					Format = if outputAs = null then "table" else Text.Lower(outputAs),
					Result = Record.FieldOrDefault(Results, Format, Grouped)
				in
					Result,
			Main.Type = Type.ForFunction(
				[
					ReturnType = type any,
					Parameters = [
						list = type list meta [
							Documentation.FieldCaption = "List"
						],
						outputAs = type nullable text meta [
							Documentation.FieldCaption = "Return Counts As",
							Documentation.AllowedValues = {"table", "lists", "records"}
						]
					]
				],
				1
				),
			Main.Docs = [
				Documentation.Name = "List_ValueCounts",
				Documentation.LongDescription = Text.Combine(
					{
						"Возвращает уникальные значения и их количество в виде таблицы, списка или записи<br>",
						"Counts each occurrence of distinct values in the input list.<br><br>",
						"<b>Args</b><br>",
						"<i>list</i>: Source list for value counts.<br>",
						"<i>outputAs</i>: Text representation of how to return the value counts. Options are ",
						"'lists'/'records'/'table'. Default 'table' will be applied if omitted or a non-allowed value is",
						"entered. See examples for more details.<br><br>",
						"<b>Returns</b><br>",
						"Nested list where the inner list has structure: item{0} = value and item{1} = count<br>",
						"Вложенный список, где внутренняя структура имеет вид: item{0} = значение и item{1} = количество."
					},
					""
				),
				Documentation.Examples = {
					[
						Description = "Return as table (DEFAULT)",
						Code = "List_ValueCounts({0, 0, 1, 4, 4, 4, 4, 4, 7, 8})",
						Result = Text.Combine({
							"#table(type table [Value=any, Count=number], ",
							"{ {0, 2}, {1, 1}, {4, 5}, {7, 1}, {8, 1} })"},
							"#(lf)"
						)
					],
					[
						Description = "Return as list of lists",
						Code = "List_ValueCounts({0, 0, 1, 4, 4, 4, 4, 4, 7, 8}, ""lists"")",
						Result = "{ {0, 2}, {1, 1}, {4, 5}, {7, 1}, {8, 1} }"
					],
					[
						Description = "Return as list of records",
						Code = "List_ValueCounts({0, 0, 1, 4, 4, 4, 4, 4, 7, 8}, ""records"")",
						Result = Text.Combine({
							"{ [Value=0, Count=2], [Value=1, Count=1], [Value=4, Count=5],",
							"  [Value=7, Count=1], [Value=8, Count=1] }"},
							"#(lf)"
						)
					]
				}
				]
		in
			Value.ReplaceType(Main.Func, Main.Type meta Main.Docs),

	ClimateCanada_GetDailyWeather = // импорт из CSV грамотный!!!
        /*
            * Queries climate.weather.gc.ca for daily bulk data (in csv format) for a given climate station and date range. Station
            * IDs are available from climate.weather.gc.ca google drive
            *   https://drive.google.com/drive/folders/1WJCDEU34c60IfOnG4rv5EPZ4IhhW9vZH/
            *
            * the csv schema is hard-coded within this query and will need adjusted if the format changes.
            *
            * @name ClimateCanada.GetDailyWeather
            * @categories weather
            * @license MIT (c) 2021 W Bohm
            * @author https://github.com/AnHerbWorm
            * @source https://github.com/AnHerbWorm/DataAnalysis/tree/main/powerquery
            * @result table
        */
        let
            /*
                CLIMATE FUNCTIONS
                    Functions and Types related to climate.weather.gc.ca

                Climate.CSVSchema: Table type of bulk .csv data downloads
                Climate.ApplySchema: Transform table column types to match those of Climate.CSVSchema
                Climate.MakeURL: Construct url to bulk download the entire year's daily data for a given station id
                Climate.ReadURL: Download data and clean up into a table of type Climate.CSVSchema
            */
            Climate.CSVSchema = type table [
                    #"Longitude (x)" =  number,
                    #"Latitude (y)" =  number,
                    #"Station Name" =  text,
                    #"Climate ID" = Int64.Type,
                    #"Date/Time" =  date,
                    #"Year" = Int64.Type,
                    #"Month" = Int64.Type,
                    #"Day" = Int64.Type,
                    #"Data Quality" =  text,
                    #"Max Temp (°C)" =  number,
                    #"Max Temp Flag" =  text,
                    #"Min Temp (°C)" =  number,
                    #"Min Temp Flag" =  text,
                    #"Mean Temp (°C)" =  number,
                    #"Mean Temp Flag" =  text,
                    #"Heat Deg Days (°C)" =  number,
                    #"Heat Deg Days Flag" =  text,
                    #"Cool Deg Days (°C)" =  number,
                    #"Cool Deg Days Flag" =  text,
                    #"Total Rain (mm)" =  text,
                    #"Total Rain Flag" =  text,
                    #"Total Snow (cm)" =  text,
                    #"Total Snow Flag" =  text,
                    #"Total Precip (mm)" =  number,
                    #"Total Precip Flag" =  text,
                    #"Snow on Grnd (cm)" = Int64.Type,
                    #"Snow on Grnd Flag" =  text,
                    #"Dir of Max Gust (10s deg)" = Int64.Type,
                    #"Dir of Max Gust Flag" =  text,
                    #"Spd of Max Gust (km/h)" = Int64.Type,
                    #"Spd of Max Gust Flag" =  text
                ],
            Climate.ApplySchema = (table as table) as table => 
                    Table.TransformColumnTypes(
                        table,
                        List.Transform(
                            Type.TableSchema(Climate.CSVSchema)[Name], 
                            each {_, Type.TableColumn(Climate.CSVSchema, _)}
                        )
                    ),  
            Climate.MakeURL = (stationID as number, year as number) as text => 
                Text.Combine(
                    {
                        "http://climate.weather.gc.ca/climate_data/bulk_data_e.html?format=csv&",
                        Text.Format("stationID=#[id]&Year=#[yr]", [id=stationID, yr=year]),
                        "&Month=12&Day=31&timeframe=2"
                    },
                    ""
                ),
            Climate.ReadURL = (url as text) as table => 
                let
                    Source      = Csv.Document(
                                    Web.Contents(url),
                                    [Delimiter=",", Columns=31, Encoding=65001, QuoteStyle=QuoteStyle.None]
                                  ),
                    Headers     = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
                    ApplySchema = Climate.ApplySchema(Headers)
                in
                    ApplySchema,
            /* HELPER FUNCTIONS MakeDateRange: Return table of inclusive dates between start/end. Single column is named "Date" */
            MakeDateRange = (start as date, end as date) as table => 
                #table(
                    type table [Date=date],
                    List.Generate(
                        ()=>0,
                        each _ <= Duration.TotalDays(end - start),
                        each _ + 1,
                        each {Date.AddDays(start, _)}
                    )
                ),
            /* MAIN FUNCTION */
            Main.Func = (stationID as number, startDate as date, endDate as date) as table =>
                let
                    AllDates = MakeDateRange(startDate, endDate),
                    AllYears = List.Distinct(List.Transform(AllDates[Date], Date.Year)),
                    
                    URLS = List.Transform(AllYears, each Climate.MakeURL(stationID, _)),
                    ClimateData = Table.Combine(List.Transform(URLS, Climate.ReadURL)),
                    FilterToRange = Table.Join(
                        AllDates,
                        {"Date"},
                        ClimateData,
                        {"Date/Time"}
                    ),
                    RemoveJoinColumn = Table.RemoveColumns(FilterToRange, "Date")
                in
                    RemoveJoinColumn,
            Main.Docs = [
                Documentation.Name = "ClimateCanada_GetDailyWeather",
                Documentation.LongDescription = Text.Combine(
                    {
                        "Queries climate.weather.gc.ca for daily bulk data (in csv format) for a given climate station and",
                        "date range.<br><br>",
                        
                        "<b>Args<br>------</b><br>",
                        "<i>stationID</i>: Climate Station ID. A list of all stationIDs can be found at",
                        "https://drive.google.com/drive/folders/1WJCDEU34c60IfOnG4rv5EPZ4IhhW9vZH/<br>",
                        "<i>startDate</i>: First date to include in the download (inclusive).<br>",
                        "<i>endDate</i>: Last date to include in the download (inclusive).<br><br>",

                        "<b>NOTE<br>-------</b><br>",
                        "Table schema is set within this query and must be adjusted if the bulk data format changes."
                    },
                    " "
                ),
                Documentation.Examples = {
                    [
                        Description = "First two days of 2021, Edmonton International Airport (#27793)",
                        Code = "GetDailyClimateData(27793, #date(2021, 1, 1), #date(2021, 1, 2))",
                        Result = Text.Combine({
                            "Note: Columns truncated for this example#(lf,lf)",
                            "Table.FromRecords({",
                            "#(lf)  [Date/Time = 2021/01/01, Max Temp = -4.0, Min Temp = -13.4],",
                            "#(lf)  [Date/Time = 2021/01/02, Max Temp = 4.1, Min Temp = -12.0]",
                            "#(lf)})"},
                            ""
                        )
                    ]
                }
             ],
            Main.Type = Type.ForFunction(
                [
                    ReturnType = Climate.CSVSchema,
                    Parameters = [
                        stationID = type number meta [
                            Documentation.FieldCaption = "Climate Station ID",
                            Documentation.SampleValues = {27793}
                        ],
                        startDate = type date meta [
                            Documentation.FieldCaption = "First Date to Import"
                        ],
                        endDate = type date meta [
                            Documentation.FieldCaption = "Last Date to Import"
                        ]
                    ]
                ],
                3
             )
        in
            Value.ReplaceType(Main.Func, Main.Type meta Main.Docs),

    CurrentWorkbook_NamedRange = // статистика погоды в Канаде 
        /* 
            * return the value referenced by the workbook scoped named range. The return type is inferred from the structure of
            * [Content] for the named range, and M detects the type for literals.
            *
            * support for worksheet scoped named ranges is provided through the optional 'sheet' parameter
            *
            * @name CurrentWorkbook.NamedRange
            * @categories excel, currentworkbook
            * @license MIT (c) 2021 W Bohm
            * @author https://github.com/AnHerbWorm
            * @source https://github.com/AnHerbWorm/DataAnalysis/tree/main/powerquery
            * @result literal, table, or list
        */
        let
            Param.Name.Error = (name as text) as record =>
                Error.Record(
                    "Argument Error",
                    Text.Format("'#[nm]' is not a valid named range for this workbook.",[nm = name]),
                    Text.Combine(
                        {
                            "Check that the spelling is correct, and that the named range is scoped to the",
                            "workbook. Worksheet scoped named ranges can still be accessed using the optional",
                            "sheet parameter."
                        },
                        " "
                    )
                ),

            Main.Func = (name as text, optional sheet as nullable text) as any =>
                let
                    Name = if sheet = null then name else Text.Format("#[sh]![nm]", [sh=sheet, nm=name]),
                    Content =
                        try 
                            Excel.CurrentWorkbook(){[Name=Name]}[Content]
                        otherwise
                            error Param.Name.Error(name),
                    Output =
                        if Table.ColumnNames(Content) = {"Column1"} then
                            if Table.RowCount(Content) = 1 then
                                Content{0}[Column1]
                            else
                                Content[Column1]
                        else
                            Content
                in
                    Output,
            Main.Type = Type.ForFunction(
                [
                    ReturnType = type any,
                    Parameters = [
                        name = type text meta [
                            Documentation.FieldCaption = "name: named range",
                            Documentation.AllowedValues = Excel.CurrentWorkbook()[Name]
                        ],
                        optional sheet = type nullable text meta [
                            Documentation.FieldCaption = "sheet: worksheet scope"
                        ]
                    ]
                ],
                Type.FunctionRequiredParameters(Value.Type(Main.Func))
            ),
            Main.Docs = [
                Documentation.Name = "CurrentWorkbook.NamedRange",
                Documentation.LongDescription = Text.Combine(
                    {
                        "Return the value referenced by the workbook named range.",
                        "Worksheet scoped ranges can be accessed by also providing the 'sheet' parameter.<br><br>",
                        
                        "<b>Args</b><br>-----<br>",
                        "<b>name</b> as text: named range<br>",
                        "<b>sheet</b> as nullable text: [Optional] sheet name for worksheet scoped named ranges<br><br>",
                        
                        "<b>Returns</b><br>---------<br>Values are inferred to be:<br>",
                        "+ A literal if Content is a 1x1 table with 'Column1'<br>",
                        "+ A list if Content is a 1xN table with 'Column1'<br>",
                        "+ A table if neither of the above is true<br><br>",
                        "The table return format is the default for Excel.CurrentWorkbook()[Content] records and will return a",
                        "table with no column types transformed.<br><br>",
                        
                        "<b>Raises</b><br>-------<br>",
                        "Argument Error: the named range does not exist in the workbook scope"
                    },
                    " "
                ),
                Documentation.Examples = {
                    [
                        Description = "Name refers to a single cell",
                        Code = "CurrentWorkbook_NamedRange(""TheNumberFour"")",
                        Result = "4"
                    ],
                    [
                        Description = "Name refers to a single cell, forceTable=true",
                        Code = "CurrentWorkbook_NamedRange(""TheNumberFour"", null, true)",
                        Result = "Column1#(lf)-------#(lf)4"
                    ],
                    [
                        Description = "Name refers to a range of cells",
                        Code = "CurrentWorkbook_NamedRange(""Alphabet"")",
                        Result = "{""A"",""B"",""C"",""D"", ..., ""Z""}"
                    ],
                    [
                        Description = "Name refers to a range of cells, forceTable=true",
                        Code = "CurrentWorkbook_NamedRange(""Alphabet"", null, true)",
                        Result = "Column1#(lf)-------#(lf)A#(lf)B#(lf)C#(lf)..#(lf)Z"
                    ],
                    [
                        Description = "Name refers to a table only scoped to sheet 'abc'",
                        Code = "CurrentWorkbook_NamedRange(""AlphabetWithPosition"", ""abc"")",
                        Result = Text.Combine(
                            {
                                "Pos | Letter#(lf)",
                                "------------#(lf)",
                                "  1 |  A#(lf)",
                                "  2 |  B#(lf)",
                                "  3 |  C#(lf)",
                                " .. | ..#(lf)",
                                " 26 |  Z"
                            }
                        )
                    ]
                }
            ]
        in
            Value.ReplaceType(Main.Func, Main.Type meta Main.Docs),

    Template_FuncWithDocs = // шаблон документирования функции 
        /*
            * Short, one sentence query description
            * Long query description. Should also be added to Documentation.LongDescription in the Main.Docs record.
            *
            * @name QueryName
            * @categories relevant tag, another relevant tag
            * @author https://github.com/AnHerbWorm
            * @source https://github.com/AnHerbWorm/DataAnalysis/tree/main/powerquery
            * @result result type
        */
            let
                /* Sub-Calcs Section 
                
                SubCalc.Type -> type:
                SubCalc.FuncA -> any:
                SubCalc.FuncB -> any:
                */
                SubCalc.Type = ...,
                SubCalc.FuncA = ...,
                SubCalc.FuncB = ...,

                /* Main Function
                
                Main.Func -> any: the calculations and return value for the query
                Main.Type -> type: parameter definitions used in Main.Func, along with documentation for the Query Editor
                Main.Docs -> record: meta information for Query Editor documentation
                */
                Main.Func = (p1 as any, optional p2 as any) as any =>
                    let
                        Source = ...
                    in
                        Source,
                Main.Type = Type.ForFunction(
                    [
                        ReturnType = type any,
                        Parameters = [
                            p1 = type any meta [
                                Documentation.FieldCaption = "short caption to display",
                                Documentation.SampleValues = {"list of text displayed in the entry field"},
                                Documentation.AllowedValues = {"list of values (any type) to display in dropdown"}
                            ],
                            optional p2 = type any meta [
                                Documentation.FieldCaption = "short caption to display",
                                Documentation.SampleValues = {"list of text displayed in the entry field"},
                                Documentation.AllowedValues = {"list of values (any type) to display in dropdown"}
                            ]
                        ]
                    ],
                    Type.FunctionRequiredParameters(Value.Type(Main.Func))
                ),
                Main.Docs = [
                    Documentation.Name = "short name of entire function, shows at top",
                    Documentation.LongDescription = "long description of entire function",
                    Documentation.Examples = {
                        [
                            Description = "description of the example",
                            Code = "show under ""usage"" section",
                            Result = "show under ""result"" section"
                        ]
                    }
                ]
            in
                Value.ReplaceType(Main.Func, Main.Type meta Main.Docs),

    Table_GroupWithTotals = // заточено под канаду, только для изучения кода, может применить к чему еще 
        /*
            compute and combine Table.Group() calls on subsets of sourceTable with sub/grand totals added
            
            performs initial checks on parameter values to ensure the function will complete as it can be
            expensive to find out late in the calculation sequence that a combination fails
            
            @name Table.GroupWithTotals
            @categories table
            @license MIT (c) 2021 W Bohm
            @author https://github.com/AnHerbWorm
            @source https://github.com/AnHerbWorm/DataAnalysis/tree/main/powerquery
            @result table
        */
        let
            /* 
                Subset Functions
                A subset is a non-nullable list of subtotals, where each subtotal has length > 0

                Subset.Type -> type: type definition for reference only. It is not ascribed anywhere but describes the list {record} structure
                Subset.Columns -> list: all column field values in the subset
                Subset.IsValid -> logical: column field values are distinct and all required columns are present
                Subset.ToTable -> table: sourceTable with subtotal application for each record in the subset.
                    Can return a table with 0 rows if the subtotals do not have any overlap in the results of their selector functions
                Subset.Combinations -> list: list of all combinations of subsets of length n
            */
            Subset.Type = type {[column = text, alias = text, selector = function]},
            Subset.Columns = (subset as list) as list => List.Transform(subset, each _[column]),
            Subset.IsValid = (subset as list, requiredColumns as nullable list) as logical =>
                if requiredColumns = null then
                    List.IsDistinct(Subset.Columns(subset))
                else
                    List.IsDistinct(Subset.Columns(subset))
                    and List.MatchesAll(requiredColumns, each List.Contains(Subset.Columns(subset), _)),
            Subset.ToTable = (subset as list, iter as number, tbl as table) as table =>
                let
                    Curr = subset{iter},
                    Recur = iter < List.Count(subset),
                    ContTable = Table.TransformColumns(
                        Table.SelectRows(tbl, each Curr[selector](Table.Column(_, Curr[column]))),
                        {
                            {Curr[column], each Curr[alias], type text}
                        }
                    )
                in
                    if Recur then
                        @Subset.ToTable(subset, iter + 1, ContTable)
                    else
                        tbl,
            Subset.Combinations = (s as list, n as number) as list =>
                if n = 0 then
                    {{}}
                else if List.Count(s) = 0 then
                    {}
                else
                    List.Transform(@Subset.Combinations(List.Skip(s), n - 1), each {List.First(s)} & _)
                    &
                    @Subset.Combinations(List.Skip(s), n),
            // Validation Checks
            Param.KeyColumns = (keyColumns, subtotals) =>
                let
                    NotKeys = List.Select(
                        List.Transform(subtotals, each _{0}),
                        each not List.Contains(keyColumns, _)
                    ),
                    Details = 
                        if keyColumns = null then
                            [IsNull=true]
                        else
                            [Not Keys=Text.Combine(List.Distinct(NotKeys), ", ")],
                    Err = Error.Record(
                        "Parameter Error",
                        "keyColumns cannot be null and must contain all columns listed in subtotals",
                        Details
                    ),
                    Param = 
                        if List.Count(NotKeys) = 0 then
                            keyColumns
                        else
                            error Err
                in
                    Param,
            Param.Subtotals = (subtotals, keyColumns) =>
                let
                    Columns = List.Transform(subtotals, each _{0}),
                    Aliases = List.Transform(subtotals, each _{1}),
                    AliasByColumn = List.Accumulate(
                        List.Zip({Columns, Aliases}),
                        // generating a record of each column used with an empty list value
                        // so that these lists can be populated with each alias used for duplication checking
                        Record.FromList(
                            List.Repeat({{}}, List.Count(List.Distinct(Columns))),
                            List.Distinct(Columns)
                        ),
                        (state, current) => Record.TransformFields(state, {current{0}, each _ & {current{1}}})
                    ),
                    ColumnsWithDupes = Table.SelectRows(Record.ToTable(AliasByColumn), (tb) => not List.IsDistinct(tb[Value])),
                    Err = Error.Record(
                        "Parameter Error",
                        "each distinct subtotals column cannot reuse an alias",
                        [column=ColumnsWithDupes[Name]{0}, alias="..."]
                    ),
                    Param = 
                        if Table.RowCount(ColumnsWithDupes) = 0 then
                            subtotals
                        else
                            error Err
                    in
                        Param,
            Param.TotalsOnly = (totalsOnlyColumns, subtotals) =>
                let
                    NotSubtotal = List.Select(
                        totalsOnlyColumns,
                        each not List.Contains(List.Transform(subtotals, each _{0}), _)),
                    Err = Error.Record(
                        "Parameter Error",
                        "totalsOnlyColumns must be null or only contain columns listed in subtotals",
                        [Not Subtotals=Text.Combine(List.Distinct(NotSubtotal), ", ")]
                    ),
                    Param = 
                        if totalsOnlyColumns = null or List.Count(NotSubtotal) = 0 then
                            totalsOnlyColumns
                        else
                            error Err
                in
                    Param,
            // Main Function
            Main.Func = (sourceTable as table,
                        keyColumns as list,
                        subtotals as list,
                        aggregatedColumns as list,
                        optional totalsOnlyColumns as nullable list
                        ) as table =>
                let
                    KeyColumns = Param.KeyColumns(keyColumns, subtotals),
                    Subtotals = Param.Subtotals(subtotals, keyColumns),
                    TotalsOnly = Param.TotalsOnly(totalsOnlyColumns, subtotals),
                
                    SubtotalsAsRecords = List.Transform(Subtotals, each Record.FromList(_, {"column", "alias", "selector"})),
                    // the max number of elements in a subset is equal to the number of columns where a total is applied
                    // the min number of elements in a subset is equal to the number of totalsOnlyColumns columns, 
                    // or 1 if totalsOnlyColumns is null
                    MaxSubsetSize = List.Count(List.Distinct(Subset.Columns(SubtotalsAsRecords))),
                    MinSubsetSize = List.Min({MaxSubsetSize, try List.Count(TotalsOnly) otherwise 1}),
                    AllSubsets = List.Accumulate(
                        {MinSubsetSize..MaxSubsetSize},
                        {},
                        (state, current) => state & Subset.Combinations(SubtotalsAsRecords, current)
                    ),
                    ValidSubsets = List.Buffer(List.Select(AllSubsets, each Subset.IsValid(_, TotalsOnly))),
                    BufferedSource = Table.Buffer(sourceTable),
                    CreateAndCombineSubsetTables = Table.Combine(
                        List.Transform(ValidSubsets, each Subset.ToTable(_, 0, BufferedSource))
                    ),
                    // apply standard Table.Group()
                    // in cases where TotalsOnly is null, we also need to compute measures on the base table
                    BaseMeasures = Table.Group(
                        BufferedSource,
                        KeyColumns,
                        aggregatedColumns
                    ),
                    CombinationMeasures = Table.Group(
                        CreateAndCombineSubsetTables,
                        KeyColumns,
                        aggregatedColumns
                    ),
                    OutputMeasures =
                        if TotalsOnly = null then
                            CombinationMeasures & BaseMeasures
                        else
                            CombinationMeasures
                in
                    OutputMeasures,
            
            Main.Type = Type.ForFunction(
                [
                    ReturnType = type table,
                    Parameters = [
                        sourceTable = type table meta [Documentation.FieldCaption = "table to group"],
                        keyColumns = type list meta [Documentation.FieldCaption = "list of column names to group on"],
                        subtotals = type list meta [Documentation.FieldCaption = "subtotals"],
                        aggregatedColumns = type list meta [Documentation.FieldCaption = "aggregatedColumns"],
                        optional totalsOnlyColumns = type nullable list meta [Documentation.FieldCaption = "totalsOnlyColumns"]
                    ]
                ],
                4
            ),
            Main.Docs = [
                Documentation.Name = "Table.GroupWithTotals",
                Documentation.LongDescription = Text.Combine(
                    {
                        "Create and combine the results of Table.Group() on all combinations of user-defined subsets",
                        "of the table.<br><br>",
                    
                        "<b>Args</b><br>----<br>",
                        "<code>sourceTable</code>: table to group<br>",
                        "<code>keyColumns</code>: list of column names to group on<br>",
                        "<code>subtotals</code>: nested list of 3-element lists where each inner list is the specifications",
                        "for creating a total.<br>",
                        "sublist{0} <i>column as text</i>: name of the column to base the subtotal on. Must be in keyColumns.<br>",
                        "sublist{1} <i>alias as text</i>: value that refers to the subtotal. All values in the column get",
                        "replaced by this alias after selection. An error is raised if a column attempts to use the same",
                        "alias twice.<br>",
                        "sublist{2} <i>selector as function</i>: function that returns true/false when applied to each column value.<br>",
                        "<code>aggregatedColumns</code>: see M Documentation https://docs.microsoft.com/en-us/powerquery-m/table-group.",
                        "Columns used in aggregate calculations should not also be used for subtotals. The query will likely",
                        "complete but produce error values within the final table.<br>",
                        "<code>totalsOnlyColumns</code>: [Optional] list of column names where only the subtotals will be returned,",
                        "instead of the typical behaviour of Table.Group that groups on each distinct value within keyColumns.<br>",
                        
                        "<br><b>Dependencies</b><br>----------------<br>",
                        "List.Combinations (as List_Combinations)"
                    },
                    " "
                ),
                Documentation.Examples = {
                    [
                        Description = "5 Largest Canadian Cities by Province with subtotals",
                        Code = Text.Combine({
                            "Table_GroupWithTotals(#(lf)",
                            "  Table.FromRecords({#(lf)",
                            "    [City=""Toronto"" , Province=""ON"", Pop=2.73],#(lf)",
                            "    [City=""Montreal"", Province=""QC"", Pop=1.70],#(lf)",
                            "    [City=""Calgary"" , Province=""AB"", Pop=1.24],#(lf)",
                            "    [City=""Ottawa""  , Province=""ON"", Pop=0.93],#(lf)",
                            "    [City=""Edmonton"", Province=""AB"", Pop=0.93]}#(lf)",
                            "  ),#(lf)",
                            "  {""Province""},#(lf)",
                            "  {#(lf)",
                            "    {""Province"", ""Canada"", each true},#(lf)",
                            "    {""Province"", ""West"", (prov) => List.Contains({""BC"", ""AB"", ""SK"", ""MB""}, prov)}#(lf)",
                            "  },#(lf)",
                            "  {#(lf)",
                            "    {""cities"", Table.RowCount, Int64.Type},#(lf)",
                            "    {""avg pop"", each List.Average([Pop]), type number}#(lf)",
                            "  },#(lf)",
                            "  null#(lf)",
                            ")"
                        }),
                        Result = Text.Combine({
                            "#table(#(lf)",
                            "  {""Province"", ""cities"", ""avg pop""},#(lf)",
                            "  {#(lf)",
                            "    {""Canada"", 5, ""1.506""},#(lf)",
                            "    {""West"", 2, 1.085},#(lf)",
                            "    {""ON"", ""2"", 1.83}#(lf)",
                            "    {""QC"", 1, 1.70},#(lf)",
                            "    {""AB"", 2, 1.085}#(lf)",
                            "  }#(lf)",
                            ")"
                        })
                    ],
                    [
                        Description = "5 Largest Canadian Cities by Province, subtotals only",
                        Code = Text.Combine({
                            "Table_GroupWithTotals(#(lf)",
                            "  Table.FromRecords({#(lf)",
                            "    [City=""Toronto"" , Province=""ON"", Pop=2.73],#(lf)",
                            "    [City=""Montreal"", Province=""QC"", Pop=1.70],#(lf)",
                            "    [City=""Calgary"" , Province=""AB"", Pop=1.24],#(lf)",
                            "    [City=""Ottawa""  , Province=""ON"", Pop=0.93],#(lf)",
                            "    [City=""Edmonton"", Province=""AB"", Pop=0.93]}#(lf)",
                            "  ),#(lf)",
                            "  {""Province""},#(lf)",
                            "  {#(lf)",
                            "    {""Province"", ""Canada"", each true},#(lf)",
                            "    {""Province"", ""West"", (prov) => List.Contains({""BC"", ""AB"", ""SK"", ""MB""}, prov)}#(lf)",
                            "  },#(lf)",
                            "  {#(lf)",
                            "    {""cities"", Table.RowCount, Int64.Type},#(lf)",
                            "    {""avg pop"", each List.Average([Pop]), type number}#(lf)",
                            "  },#(lf)",
                            "  {""Province""}#(lf)",
                            ")"
                        }),
                        Result = Text.Combine({
                            "#table(#(lf)",
                            "  {""Province"", ""cities"", ""avg pop""},#(lf)",
                            "  {#(lf)",
                            "    {""Canada"", 5, ""1.506""},#(lf)",
                            "    {""West"", 2, 1.085}#(lf)",
                            "  }#(lf)",
                            ")"
                        })
                    ]
                }
            ]
        in
            Value.ReplaceType(Main.Func, Main.Type meta Main.Docs)
            ,

    Table_AddGroupIndex   = // добавляет новый индексный столбец, который определяет, к какой группе принадлежит каждая строка в исходной таблице
        /* 
            * chains Table.ExpandTableColumn(Table.AddIndexColumn(Table.Group)) functions to append a new index column
            * identifying which group each row in the source table belongs to
            *
            * @name Table.AddGroupIndex
            * @categories table
            * @author https://github.com/AnHerbWorm
            * @source https://github.com/AnHerbWorm/DataAnalysis/tree/main/powerquery
            * @result table
        */
            let
                Main.Func = (table as table, key as anynonnull, newColumnName as text) as table =>
                    Table.ExpandTableColumn(
                        Table.AddIndexColumn(
                            Table.Group(table, key, {{"rows", each _, Value.Type(table)}}),
                            newColumnName
                        ),
                        "rows",
                        List.RemoveItems(
							Table.ColumnNames(table), 
							if key is list then key else {key}
						)
                ),

                Main.Type = Type.ForFunction(
                    [
                        ReturnType = type table,
                        Parameters = [
                            table 		  = type table 		meta [Documentation.FieldCaption = "source table"],
                            key 		  = type anynonnull meta [Documentation.FieldCaption = "column(s) to group on"],
                            newColumnName = type text 		meta [Documentation.FieldCaption = "column name for index"]
                        ]
                    ],
                    Type.FunctionRequiredParameters(Value.Type(Main.Func))
                ),
                Main.Docs = [
                    Documentation.Name = "Table.AddGroupIndex",
                    Documentation.LongDescription = Text.Combine(
                        {
                            "Appends <code>newColumnName</code> to <code>table</code> where each index value identifies",
                            "which group that record belongs to after grouping on <code>key</code>.",
                            "Indexes start at 0, increment by 1, and are numbered in the order observed.<br><br>",
                            
                            "<b>Args:</b><br>",
                            "<code>table</code>: table to group and index<br>",
                            "<code>key</code>: column name(s) to group on<br>",
                            "<code>newColumnName</code>: name of the index column appended<br><br>",
                            
                            "<b>Returns:</b><br>",
                            "The source table with one index column appended. The index column starts at 0, increments by 1."
                        },
                        " "
                    	),
                    Documentation.Examples = {
                        [
                            Description = "Basic example",
                            Code = 
								Text.Combine(
									{
										"Table_AddGroupIndex(#(lf)",
										"  #table(type table#(lf)",
										"    [One=text, Two=text, Val=number],#(lf)",
										"    {#(lf)",
										"      {""A"", ""A"", 1},#(lf)",
										"      {""A"", ""A"", 2},#(lf)",
										"      {""A"", ""B"", 1},#(lf)",
										"      {""B"", ""B"", 5}#(lf)",
										"    }#(lf)",
										"  ),#(lf)",
										"  {""One"", ""Two""},#(lf)",
										"  ""OneTwoKey""#(lf))"
									}
								),
                            Result = 
								Text.Combine(
									{
										"#table(type table#(lf)",
										"  [One=text, Two=text, Val=number, OneTwoKey=number],#(lf)",
										"  {#(lf)",
										"    {""A"", ""A"", 1, 0},#(lf)",
										"    {""A"", ""A"", 2, 0},#(lf)",
										"    {""A"", ""B"", 1, 1},#(lf)",
										"    {""B"", ""B"", 5, 2}#(lf)",
										"  }#(lf)",
										")"
									}
								)
                        ]
                    }
                ]
            in
                Value.ReplaceType(Main.Func, Main.Type meta Main.Docs),

    List_Combinations     = // генерирует все неповторяющиеся комбинации размером combinationSize из списка
        /*
            Сгенерировать все неповторяющиеся комбинации размером combinationSize из списка, 
			или если указано только размер, все комбинации неповторяющихся индексов от 0 до (размер - 1).
			Если предоставлен список, содержащий дубликаты, они будут включены в подмножества комбинаций.

			generate all non-repeating combinations of size 'combinationSize' from a list, or if only a size is provided,
            all combinations of non-repeating indexes from 0 to (size - 1)
            
            if a list containing duplicates is provided, they will be carried through to the subset combinations
            
            @name List_Combinations
            @categories list
            @author https://github.com/AnHerbWorm
            @source https://github.com/AnHerbWorm/DataAnalysis/tree/main/powerquery
            @result list of combinations (as lists)
        */
        let
            Main.Func = (setOrSize as anynonnull, combinationSize as number) as list =>
                let
                    SetSize = if setOrSize is number then setOrSize else List.Count(setOrSize),
                    Set = {0..SetSize-1},

                    MakeCombins = (n as number, set as list) as list =>
                        if n = 0 then
                            {{}}
                        else if List.Count(set) = 0 then
                            {}
                        else
                            List.Transform(@MakeCombins(n - 1, List.Skip(set, 1)), each {set{0}} & _)
                            &
                            @MakeCombins(n, List.Skip(set, 1)),
                    
                    Combins = MakeCombins(combinationSize, Set),
                    CombinValues = List.Transform(
                            Combins,
                            (innerList) => List.Transform(innerList, each setOrSize{_})
                        )
                in
                    if setOrSize is list then CombinValues else Combins,

            Main.Type = Type.ForFunction(
                [
                    ReturnType = type list,
                    Parameters = [
                        setOrSize = type anynonnull meta [
                            Documentation.FieldCaption = "list or size of list"
                        ],
                        combinationSize = type number meta [
                            Documentation.FieldCaption = "the size of each combination subset"
                        ]
                    ]
                ],
                2
            ),
            Main.Docs = [
                Documentation.Name = "List.Combinations",
                Documentation.LongDescription = Text.Combine(
                    {
                        "Generate a list of non-repeating combination subsets of length <code>combinationSize</code> from the",
                        "set. If <code>setOrSize</code> is an integer, a list of index positions will be generated, otherwise",
                        "combinations from the input list will be created.<br>",

                        "The function will generate nCr # of combinations, which can be calculated in Power Query as",
                        "<code>Number.Combinations(List.Count(set), combinationSize)</code><br><br>",

                        "<b>Args:</b><br>",
                        "<code>setOrSize</code>: list, or integer set size, to create combinations of",
                        "<code>combinationSize</code>: number of elements in each combination subset<br>",
                        
                        "<b>Returns:</b><br>",
                        "A list of all non-repeating combinations of length <code>combinationSize</code> from the source list",
                        "of if an integer <code>setOrSize</code> was provided, a list of all non-repeating index combinations",
                        "from 0 to <code>setOrSize - 1</code>."
                    },
                    " "
                ),
                Documentation.Examples = {
                    [
                        Description = "Subsets of 4 from ABCDE (5 choose 4)",
                        Code 		= "List_Combinations({""A"", ""B"", ""C"", ""D"", ""E""}, 4)",
                        Result 		= "{#(lf)  {""ABCD""},#(lf)  {""BCDE""}#(lf)}"
                    ],
                    [
                        Description = "Subsets of 2 from 4 possible values (4 choose 2)",
                        Code 		= "List_Combinations(4, 2)",
                        Result 		= "{#(lf)  {0,1},#(lf)  {0,2},#(lf)  {0,3},#(lf)  {1,2},#(lf)  {1,3},#(lf)  {2,3}#(lf)}"
                    ]
                }
            ]
        in
            Value.ReplaceType(Main.Func, Main.Type meta Main.Docs)
	],
Grech  	   = [ // https://github.com/SpyrosMauro/PowerQuery-Functions/blob/master - сложные и пока не знаю, где использовать
	/*
		---------------------------------------------------------------------------------------------------------------
		Function						Description
		---------------------------------------------------------------------------------------------------------------
		Table.CombineMultipleColumns	For double headers. Combine columns by any setSize in one step.
		Table.DistinctMerge				Combines two tables based on duplicate keys keeping only one item per row.
		Table.GenerateColumns			To add multiple columns based on similar functions.
										Have you thought about just unpivoting and adding one column afterwards?
		Table.InferColumnTypes			Infer column types.
										Supply a tableName to get back code as text.
		Table.ReplaceValuesFromTable	Optimised mass replace values in columns.
		Table.ToTableView				Automatically apply a Table.View function based on Table.Schema
		---------------------------------------------------------------------------------------------------------------
		*/
	// 	Table
		Table.CombineMultipleColumns = 
			let
				// Function
				TableCombineMultipleColumnsFunction = (table as table, optional skipStart as nullable number, optional skipEnd as nullable number, optional setSize as number, optional combiner as function, optional delimiter as nullable text, optional columnNameDelimiter as nullable text) as table =>
					let
						// 	Define things
							Names = List.RemoveLastN(Table.ColumnNames(table), skipEnd??0),
							groupSize = setSize??2,
							sep = delimiter??", ",
							afterN = skipStart??0,
							columnDelimiter = columnNameDelimiter??" & ",
						
						// 	Define Helper Functions
							TextCombiner = combiner??((x) => 
								let
									t = Text.AfterDelimiter( List.Accumulate(x, "", (s,c) => s & sep & (Text.From(c)??"" ) ), sep )
								in
									if t = sep then null else t),

						GetK = (k) => List.Accumulate(List.Range(Names, k, groupSize), {}, (s, c) =>  s & {c}),
						ColumnNameGenarator = 
							(l as list) as text => 
								Text.AfterDelimiter(
									List.Accumulate(l, "", (s, c) => s & columnDelimiter & c), 
									columnDelimiter
								),

						// Error Handling
						CheckValues = [
							Check = (skipEnd??0)<0 or (setSize??2) <2 or (skipStart??0)<0, 
							Error = error 
								[Reason = "Incorrect values",
								Message = "Please supply positive values for skipStart and skipEnd and a setSize >= 2",
								Detail = [#"Skip Start" = skipStart, #"Skip End" = skipEnd, #"Set Size" = setSize]]
						],
						
						// Generate a list of the columns to be combined
						CombineList = List.Generate( () => [N = GetK(afterN), k = groupSize+afterN], each [k]-groupSize<List.Count(Names), each [N = GetK([k]), k = [k] + groupSize], each [N]),

						// Recursively combine columns. If in the end they're less, they will still be combined
						CombineColumns = (table, CombineList, k) => if List.IsEmpty(CombineList) then table else @CombineColumns(Table.CombineColumns(table, CombineList{0}, TextCombiner, ColumnNameGenarator(CombineList{0})), List.RemoveFirstN(CombineList, 1), k+1),
						
						Result = if CheckValues[Check] then CheckValues[Error] else CombineColumns(table, CombineList, 0)
					in
						Result,
					

				// Documentation
				TableCombineMultipleColumnsType = 
					type function (
						table as (type table meta [
							Documentation.FieldCaption ="Target table",
							Documentation.FieldDescription = "The target table"
							]),
						optional skipStart as (type nullable number meta [
							Documentation.FieldCaption ="Skip first N",
							Documentation.FieldDescription = "Number of columns to skip from start"
							]),
						optional skipEnd as (type nullable number meta [
							Documentation.FieldCaption ="Skip last N",
							Documentation.FieldDescription = "Number of columns to skip from end"
							]),
						optional setSize as (type nullable number meta [
							Documentation.FieldCaption ="Group size",
							Documentation.FieldDescription = "Number of columns combine together"
							]),
						optional combiner as (type function meta [
							Documentation.FieldCaption ="Combiner Function",
							Documentation.FieldDescription = "Optional Combiner"
							]),
						optional delimiter as (type nullable text meta [
							Documentation.FieldCaption ="Delimiter",
							Documentation.FieldDescription = "Delimiter to use when combining columns"
							]),
						optional columnNameDelimiter as (type nullable text meta [
							Documentation.FieldCaption ="Column Delimiter",
							Documentation.FieldDescription = "Delimiter to use when combining column names"
							])
					)
					as table meta
					[
						Documentation.Name = "Table.CombineMultipleColumns",
						Documentation.Description = "Combines multiple columns at once using group size",
						Documentation.LongDescription = "Combines multiple columns at once using an optional <code>Group size</code>. Default group size is 2. If there are trailing columns less than <code>Group size</code> they will be combined in a smaller group.",
						Documentation.Category = "Table",
						Documentation.Author = "Spyros Mavroforos",
						Documentation.Source = "https://github.com/SpyrosMauro/powerquery",
						Documentation.Version = "1",
						Documentation.Examples = {[
							Description = "Combine all columns by 2",
							Code = "let
									StartingTable =
										Table.FromRecords({
											[a = 1, b = 2],
											[a = 2, b = 2],
											[a = 3, b = 4],
											[a = 4, b = 5]
										})
								in
									Table.CombineMultipleColumns( StartingTable )",
							Result = "Table.FromRecords({
									[#""a & b"" = 1, 2],
									[#""a & b"" = 2, 2],
									[#""a & b"" = 3, 4],
									[#""a & b"" = 4, 5]
								})"
							],[
								Description = "Combine all columns by 2, adding them",
								Code = "let
											StartingTable =
												Table.FromRecords({
													[a = 1, b = 2],
													[a = 2, b = 2],
													[a = 3, b = 4],
													[a = 4, b = 5]
												})
										in
											Table.CombineMultipleColumns( StartingTable, null, null, null, List.Sum )",
								Result = "Table.FromRecords({
											[#""a & b"" = 3],
											[#""a & b"" = 4],
											[#""a & b"" = 7],
											[#""a & b"" = 9]
										})"
							],[
								Description = "Combine all columns by 2, skipping first 2",
								Code = "let
											StartingTable =
												Table.FromRecords({
													[a = 1, b = 2, c = ""apple"", d=  ""banana""],
													[a = 1, b = 2, c = ""cherry"", d=  ""chocolate""],
													[a = 1, b = 2, c = ""chocolate"", d=  ""banana""],
													[a = 1, b = 2, c = """", d=  ""banana""]
												})
										in
											Table.CombineMultipleColumns( StartingTable, 2 )",
								Result = "Table.FromRecords({
										[a = 1, b = 2, #""c & d"" = ""apple, banana""],
										[a = 1, b = 2, #""c & d"" = ""cherry, chocolate""],
										[a = 1, b = 2, #""c & d"" = ""chocolate, banana""],
										[a = 1, b = 2, #""c & d"" = "", banana""]
									})"
							]}
					]

			in
				Value.ReplaceType(TableCombineMultipleColumnsFunction, TableCombineMultipleColumnsType),
		Table.DistinctMerge 	= 
			let
				// Function
				TableDistinctMergeFunction = (table1 as table, key1 as list, table2 as table, key2 as list, optional expandColumns as list, optional prefix as text, optional joinKind as number) as table =>
					let
						//Define combiner
						combiner =
						let
							fn = (x) => List.Zip( { x{0}??{}, x{1}??{} } )
						in
							if (joinKind??JoinKind.LeftOuter) = JoinKind.LeftOuter
								then (x) => List.FirstN( fn(x), x{2} )
							else if joinKind = JoinKind.RightOuter
								then (x) => List.FirstN( fn(x), x{3} )
							else if joinKind = JoinKind.Inner
								then (x) => List.FirstN( fn(x), List.Min( { x{2}, x{3} } ) )
							else if joinKind = JoinKind.LeftAnti
								then (x) => List.Select( fn(x), (y) => y{1}? = null )
							else if joinKind = JoinKind.RightAnti
								then (x) => List.Select( fn(x), (y) => y{0}? = null )
							else fn,

						table1columns = Table.ColumnNames(table1),
						table2Columns = expandColumns??Table.ColumnNames(table2),
						newTable2Columns =
							if prefix = null then
								let
									names = List.Union({List.Intersect({key1, key2}), List.Intersect({table1columns, table2Columns})}),
									fixNames = if names <> {}
										then List.ReplaceMatchingItems(table2Columns, List.Transform(names, each {_, Text.Combine({_, ".1"})}))
										else table2Columns
								in
									fixNames
							else List.Transform(table2Columns, each Text.Combine({prefix, ".", _})),
						joinKindfixed =
							if joinKind = JoinKind.LeftAnti or joinKind = null then JoinKind.LeftOuter
							else if joinKind = JoinKind.RightAnti then JoinKind.RightOuter
							else joinKind,


						GroupTable1 = Table.Group(table1, key1, {{"tableList1", Table.ToRecords, type list}, {"tableCount1", Table.RowCount, Int64.Type}}),
						GroupTable2 = Table.Group(Table.SelectColumns(table2, List.Union({table2Columns, key2})), key2, {{"tableList2", Table.ToRecords, type list}, {"tableCount2", Table.RowCount, Int64.Type}}),

						MergeTables = Table.ExpandTableColumn(Table.NestedJoin(GroupTable1, key1, GroupTable2, key2, "Data", joinKindfixed), "Data", {"tableList2", "tableCount2"}, {"tableList2", "tableCount2"}),

						MagicallyCombine = Table.CombineColumns(MergeTables,
							{"tableList1", "tableList2", "tableCount1", "tableCount2"},
							combiner,
							"Combined"),
						ExpandData =
							let
								combinedColumn = 
									let c = Table.ExpandListColumn(MagicallyCombine, "Combined")[#"Combined"]
									in if (joinKind??JoinKind.LeftOuter) <> joinKindfixed then List.RemoveNulls(c) else c,
								ExpandList = Table.FromList(combinedColumn, (x) => x, {"Table1 Data", "Table2 Data"}),
								#"Table1 Data" = Table.ExpandRecordColumn(ExpandList, "Table1 Data", table1columns, table1columns)
							in
								Table.ExpandRecordColumn(#"Table1 Data", "Table2 Data", table2Columns, newTable2Columns),

						fixTypes = 
							let
								table1type = Value.Type(table1),
								table2type = Value.Type(Table.RenameColumns(Table.SelectColumns(table2, table2Columns), List.Zip({table2Columns, newTable2Columns}))),
								table1record = Record.FromList(List.Transform(table1columns, each [ Type = Type.TableColumn(table1type, _), Optional = false ]), table1columns),
								table2record = Record.FromList(List.Transform(newTable2Columns, each [ Type = Type.TableColumn(table2type, _), Optional = false ]), newTable2Columns),

								newTableType = type table Type.ForRecord(table1record & table2record, false)
							in
								Value.ReplaceType(ExpandData, newTableType)
					in
						fixTypes,


				// Documentation
				TableDistinctMergeFromTableType = 
					type function (
						table1 as (type table meta [
							Documentation.FieldCaption ="Left side table",
							Documentation.FieldDescription = "The table on the left side of the merge"
							]),
						key1 as (type {text} meta [
							Documentation.FieldCaption ="Left side key",
							Documentation.FieldDescription = "Columns use as key on the left table."
							]),
						table2 as (type table meta [
							Documentation.FieldCaption ="Right side table",
							Documentation.FieldDescription = "The table on the left side of the merge"
							]),
						key2 as (type {text} meta [
							Documentation.FieldCaption ="Right side key",
							Documentation.FieldDescription = "Columns use as key on the right table."
							]),
						optional expandColumns as (type {text} meta [
							Documentation.FieldCaption ="Columns to expand",
							Documentation.FieldDescription = "The columns to expand after merge"
							]),
						optional prefix as (type text meta [
							Documentation.FieldCaption ="prefix",
							Documentation.FieldDescription = "prefix to be used on new column names"
							]),
						optional joinKind as (JoinKind.Type)
						)
					as table meta
					[
						Documentation.Name = "Table.DistinctMerge",
						Documentation.Description = "Combines two tables based on duplicate keys keeping only one item per row",
						Documentation.LongDescription = "To be used when trying to combine two tables where both sides have duplicates but one wouldn't like to assign more than one value to each row.<p><code>Table.DistinctMerge</code> takes each duplicate key and uses an injective function based solely on row positions:<p><i>Example:</i><p><table><tr><td>key | </td><td>table1 | </td><td>table2</td><td></td><td></td><td>=>  </td><td>key | </td><td>table1&amp;2</td></tr><tr><td>x</td><td>[...]</td><td>[...]</td><td></td><td></td><td>}  </td><td> x</td><td>[...] &amp; [...]</td></tr><tr><td>x</td><td>[...]</td><td>[...]</td><td></td><td></td><td>}  </td><td> x</td><td>[...] &amp; [...]</td></tr><tr><td>x</td><td>[...]</td><td>[...]</td><td></td><td></td><td>}  </td><td> x</td><td>[...] &amp; [...]</td></tr><tr><td>x</td><td></td><td>[...]</td><td></td><td></td><td></td><td></td><td></td></tr></table>",
						Documentation.Category = "Table",
						Documentation.Author = "Spyros Mavroforos",
						Documentation.Source = "https://github.com/SpyrosMauro/powerquery",
						Documentation.Version = "1",
						Documentation.Examples = {[
							Description = "Force a distinct merge of those two",
							Code = "let
								StartingTable =
									Table.FromRecords({
										[a = ""a"", b = 2],
										[a = ""b"", b = 2],
										[a = ""c"", b = 3],
										[a = ""d"", b = 3]
									}),

								OtherTable = 
									Table.FromRecords({
										[check = 2, ID = ""A""],
										[check = 2, ID = ""B""],
										[check = 3, ID = ""C""],
										[check = 3, ID = ""D""]
									})
							in
								Table.DistinctMerge(StartingTable, {""b""}, OtherTable, {""check""})",
											Result = "Table.FromRecords({
										[a = ""a"", b = 2, check = 2, ID = ""A""],
										[a = ""b"", b = 2, check = 2, ID = ""B""],
										[a = ""c"", b = 3, check = 3, ID = ""C""],
										[a = ""d"", b = 3, check = 3, ID = ""D""]
									})"
											]}
									]

			in
				Value.ReplaceType(TableDistinctMergeFunction, TableDistinctMergeFromTableType),
		Table.GenerateColumns 	= 
			let
				// Function
				TableGenerateColumnsFunction = (table as table, columns as list, newName as function, forEach as function, optional newColumnType as type) =>
					let
						// Helper Functions
						// functionParameterCount
						functionparameterCount = (f as function) as number => Record.FieldCount(Type.FunctionParameters(Value.Type(f))),

						nameGeneratorParameterCount = functionparameterCount(newName),
						forEachParameterCount = functionparameterCount(forEach),
						columnCount = List.Count(columns),


						newNameList =
							let newList = if nameGeneratorParameterCount = 2
								then List.Transform(List.Zip({columns, {1..columnCount}}), each newName(_{0}, _{1}))
								else List.Transform(columns, newName)
							in Value.ReplaceType(newList, type {text}),

						recordGenerator =
							if forEachParameterCount = 2 then
								(rec) =>
								Record.FromList(
									List.Transform(List.Zip({columns, {1..columnCount}}), (c) => Function.Invoke(forEach, {
										Record.Combine({rec,
											[_ = [Value = Record.Field(rec, c{0}),
											Name = c{0}]]}),
											c{1}})),
									newNameList
									)
							else (rec) =>
								Record.FromList(
									List.Transform(columns, (c) => Function.Invoke(forEach, {
										Record.Combine({rec,
											[_ = [Value = Record.Field(rec, c),
											Name = c]]})})),
									newNameList
									),

						recordType =
							if newColumnType = null then type record
							else
								let listTypes = List.Transform({1..columnCount}, each [Type = newColumnType, Optional = false])
								in Type.ForRecord(Record.FromList(listTypes, newNameList), false),


						AddRecordColumn = Table.AddColumn(table, "__New Columns__",
							recordGenerator,
							recordType
							),

						ExpandNewColumns = Table.ExpandRecordColumn(AddRecordColumn, "__New Columns__", newNameList, newNameList)

						// Some error handling
						, Check = [
							tryList = try newNameList,
							Result =
								if tryList[HasError] then error [Reason= "Error in newName function", Message = tryList[Error][Message], Detail = tryList[Error][Detail]]
								else if List.IsDistinct(tryList[Value]) 
									then [Check = try ExpandNewColumns, 
										Res =
											if Check[HasError] then
												if Text.Contains(Check[Error][Message], "already exists in the record.")
													then error [Reason = "Expression.Error", Message = "Column '" & Check[Error][Detail][Name] & "' already exists in the table.", Detail= [Table = table]]
												else error Check[Error]
											else Check[Value]][Res]
								else error [Reason= "Error in newName function", Message = "Names generated are not distinct", Detail = [#"New names" = tryList[Value]]]
						]

					in
						Check[Result],
						

				// Documentation
				TableGenerateColumnsType = 
					type function (
						table as (type table meta [
							Documentation.FieldCaption ="Target Table",
							Documentation.FieldDescription = "The target table"
							]),
						columns as (type list meta [
							Documentation.FieldCaption = "Columns",
							Documentation.FieldDescription = "Columns used to generate new columns"
						]),
						newName as ((type function( _ as any ) as any ) meta [
							Documentation.FieldCaption = "New name function",
							Documentation.FieldDescription = "Name generator"
						]),
						forEach as ((type function( _ as any ) as any ) meta [
							Documentation.FieldCaption = "New column function",
							Documentation.FieldDescription = "Column generator"
						]),
						optional newColumnType as ((type type) meta [
							Documentation.FieldCaption = "newColumnType",
							Documentation.FieldDescription = "Type of new columns"
							])
					)
					as table meta
					[
						Documentation.Name = "Table.GenerateColumns",
						Documentation.Description = "Generates multiple columns",
						Documentation.LongDescription = "Generates multiple columns using a name generator and a column generator. Use <code>[_][Value]</code> for current column value and <code>[_][Name]</code> for current column name.<p><i>Note: If a column named <code>_</code> already exists in the table it won't work.</i>",
						Documentation.Category = "Table",
						Documentation.Author = "Spyros Mavroforos",
						Documentation.Source = "https://github.com/SpyrosMauro/powerquery",
						Documentation.Version = "1",
						Documentation.Examples = {[
							Description = "Generate columns named <code>""Start of Month *""</code>",
							Code = "let
										StartingTable =
											Table.FromRecords({
												[id = 1, DateCreated = #date(2020,6,30), DateResolved = #date(2020, 6, 30)],
												[id = 1, DateCreated = #date(2020,5,25), DateResolved = #date(2020, 6, 12)],
												[id = 1, DateCreated = #date(2020,2,1), DateResolved = #date(2020, 7, 3)]
											})
									in
										Table.GenerateColumns ( StartingTable, {""DateCreated"", ""DateResolved""}, (t) => ""Start of Month"" & t, each Date.StartOfMonth([_][Value]) )",
													Result = "Table.FromRecords({
										[id = 1, DateCreated = #date(2020,6,30), DateResolved = #date(2020, 6, 30), #""Start of Month DateCreated"" = #date(2020,6,1), #""Start of Month DateResolved"" = #date(2020, 6, 1)],
										[id = 1, DateCreated = #date(2020,5,25), DateResolved = #date(2020, 6, 12), #""Start of Month DateCreated"" = #date(2020,5,1), #""Start of Month DateResolved"" = #date(2020, 6, 1)],
										[id = 1, DateCreated = #date(2020,2,1), DateResolved = #date(2020, 7, 3), #""Start of Month DateCreated"" = #date(2020,2,1), #""Start of Month DateResolved"" = #date(2020, 7, 1)]
									})"
												],[
													Description = "Generate columns based on same Column",
													Code = "let
										StartingTable = #table({""a""}, {{10}})
									in
										Table.GenerateColumns ( StartingTable, {""a"", ""a"", ""a""}, (t, k) => t & ""*"" & Text.From(k*10), (rec, k) => rec[_][Value] * k * 10 )",
													Result = "Table.FromRecords({
										[a = 10, #""a*10"" = 100, #""a*20"" = 200, #""a*30"" = 300]
									})"
												]}
											]
			in
				Value.ReplaceType(TableGenerateColumnsFunction, TableGenerateColumnsType),
		Table.InferColumnTypes 	= 
			let
				// Function
				TableInferColumnTypesFunction = (table as table, optional columns as list, optional precision as number, optional applyOnlyNormalTypes as logical, optional tableName as text) as any =>
					let
						// Helper Functions
						// typeFinder: finds the main type of a list
						typeFinder = (x as list, optional crazyMode as logical) =>
							let
								startingList = List.Select(x, each _ <> type any),
								listMode = List.Mode(startingList),
								listDistinct = List.Distinct(startingList),
								countDistinct = List.Count(listDistinct),
								removeInts = List.RemoveItems(listDistinct, {Int64.Type, Int32.Type, Int8.Type})
							in
							if countDistinct = 0 then type any
							else if countDistinct = 1 then listDistinct{0}
							// Five extra steps here for abstract types
							else if List.AllTrue(List.Transform(listDistinct, each Type.Is(_, type number))) then type number
							else if List.AllTrue(List.Transform(listDistinct, each Type.Is(_, type [...]))) then type nullable [...]
							else if List.AllTrue(List.Transform(listDistinct, each Type.Is(_, type table))) then type nullable table
							else if List.AllTrue(List.Transform(listDistinct, each Type.Is(_, type list))) then type nullable list
							else if List.AllTrue(List.Transform(listDistinct, each Type.Is(_, type function))) then type nullable function
							/* // crazyMode is just for testing. Really, it just tries to assign the type found the most in the list. Don't use that.
							else if crazyMode??false then listMode */
							else if countDistinct = 2 then
								if List.Contains(listDistinct, type text) then type text
								else if List.ContainsAll(listDistinct, {type date, type datetime}) then type datetime
								else if List.ContainsAll(listDistinct, {type date, type datetimezone}) then type datetimezone
								else if List.ContainsAll(listDistinct, {type datetime, type datetimezone}) then type datetimezone
								else if removeInts{0}? = type duration then type duration
								else type any
							else if countDistinct = 3 then
								if List.ContainsAll(listDistinct, {type datetimezone, type datetime, type date}) then type datetimezone
								else if removeInts = {} then Int64.Type
								else type any
							else  type any,

						// checkInt
						checkInt = (x as number) as type => if (Number.Mod(x, 1)??0) = 0 then Int64.Type else type number,
						// replaceWithType: custom replacer
						replaceWithType = (x,y,z) =>
							let
								// nulls were a bother. Now Completely removed.
								typ = if (x??"") = "" then type any else Value.Type(x)
							in
								if Type.Is(typ, type number) then checkInt(x)
								// next step is for excel and other sources which store time as '31/12/1899 hh:mm:ss'. Thankfully, pq also sees this as time if Time.From is used
								else if Type.Is(typ, type datetime) then if Date.From(DateTime.From(x))=#date(1899,12,31) then type time else type datetime
								else if Type.Is(typ, type text) then
									if not (try Logical.FromText(x))[HasError] then type logical
									else if not (try Number.FromText(x))[HasError] then checkInt(Number.From(x))
									else if not (try Time.FromText(x))[HasError] then type time
									else if not (try Date.FromText(x))[HasError] then type date
									else if not (try DateTime.FromText(x))[HasError] then type datetime
									else if not (try DateTimeZone.FromText(x))[HasError] then type datetimezone
									else if not (try Duration.FromText(x))[HasError] then type duration
									else type text
								else typ,

						// typeToText
						typeToText = (typ as type, optional prim as logical) => let schema = Type.TableSchema(type table [a = typ]){0} in if prim??false then schema[Kind] else schema[TypeName],

						// Not allowed types
						typeList = { type null, type function, type list, type record, type table, type type },
						excludeTypes = (t as any) as logical => List.AllTrue(List.Transform(typeList, each not Type.Is(t, _))),

						// fakeFunction: takes a type and makes a function that returns this type, to be used for non appliable types
						// when Table.TransformColumnTypes is able to ascribe these 6 types then it will be redundant
						fakeFunction = (Type as type) as function =>
							if Type.Is(Type, type null) then (x) as null => null
							else if Type.Is(Type, type function) then (x) as nullable function => x
							else if Type.Is(Type, type list) then (x) as nullable list => x
							else if Type.Is(Type, type record) then (x) as nullable record => x
							else if Type.Is(Type, type table) then (x) as nullable table => x
							else if Type.Is(Type, type type) then (x) as nullable type => x
							else (x) => x,


						// Get types
						bufferTable = Table.Buffer(table),
						rowsToGet = List.Min({Table.RowCount(bufferTable), precision??500, 1000}),
						firstN = Table.FirstN((if columns = null then bufferTable else Table.SelectColumns(bufferTable, columns)), rowsToGet),
						columnNames = columns??Table.ColumnNames(firstN),

						tableValuesToType = Table.ReplaceValue(firstN, null, null, replaceWithType, columnNames),
						FindBestType = Table.CombineColumns(
							Table.Transpose(tableValuesToType),
							List.Transform({1..rowsToGet}, each "Column"&Text.From(_)),
							typeFinder,
							"Types"
							),
						
						// Apply transformations
						allTransformations = List.Zip({columnNames, FindBestType[Types]}),
						applicableTransformations = List.Select(allTransformations,
							each excludeTypes( _{1} )),
						applySimpleTransformations = if applicableTransformations <> {} then Table.TransformColumnTypes(bufferTable, applicableTransformations) else bufferTable,
						
						applyAllList = List.Transform(List.RemoveItems(allTransformations, applicableTransformations), each {_{0}, fakeFunction(_{1}), _{1}}),
						applyOthers = if applyAllList <> {} then Table.TransformColumns(applySimpleTransformations, applyAllList) else applySimpleTransformations,

						textCode = let
							normalTypes = "Table.TransformColumnTypes( " & Expression.Identifier(tableName) & ", { "
								& Text.Combine( List.Transform( applicableTransformations, each "{ """ & _{0} & """, " & typeToText(_{1}) & " }" ), ", " )
								& " } )",
							abnormalTypes = Text.Combine( List.Transform( applyAllList, each  "{ """ & _{0} & """, (x) as nullable " & typeToText(_{2}, true) & " => x , type nullable " & typeToText(_{2}, true) & " }" ), ", " )
								& " } )"
							in if applicableTransformations <> {} and applyAllList <> {} then
									"let#(lf)#(tab)" & "normalTypes = " & normalTypes
									& ",#(lf)#(tab)abnormalTypes = Table.TransformColumns( normalTypes, { " & abnormalTypes
									& "#(lf)in#(lf)#(tab)abnormalTypes"
								else if applicableTransformations <> {} then normalTypes
								else if applyAllList <> {} then  "Table.TransformColumns( "& Expression.Identifier(tableName) &", { " & abnormalTypes
								else null,

						Result = if tableName <> null then textCode else if applyOnlyNormalTypes??false then applySimpleTransformations else applyOthers
					in
						Result,


				// Documentation
				TableInferColumnTypesType =
					type function (
						table as (type table meta [
							Documentation.FieldCaption = "Target table",
							Documentation.FieldDescription = "The table to make type replacements"
							]),
						optional columns as (type list meta [
							Documentation.FieldCaption = "Columns",
							Documentation.FieldDescription = "The columns to make type replacements"
							]),
						optional precision as (type number meta [
							Documentation.FieldCaption = "precision",
							Documentation.FieldDescription = "First <code>n</code> rows to check for best type match. Default: <code>500<c/ode>."
							]),
						optional applyOnlyNormalTypes as (type logical meta [
							Documentation.FieldCaption = "applyOnlyNormalTypes",
							Documentation.FieldDescription = "Switch to not do extra replacements for special types (e.g. type type). Default: <code>false</code>."
						]),
						optional tableName as (type text meta [
							Documentation.FieldCaption = "tableName",
							Documentation.FieldDescription = "Give a table name in case of text return."
						])
					)
					as any meta
					[
						Documentation.Name = "Table.InferColumnTypes",
						Documentation.Description = "Infers column types",
						Documentation.LongDescription = "Infers column types. Optional <code>precision</code>.<p>Supply a <code>tableName</code> to get back code as text.",
						Documentation.Category = "Table",
						Documentation.Author = "Spyros Mavroforos",
						Documentation.Source = "https://github.com/SpyrosMauro/powerquery",
						Documentation.Version = "1",
						Documentation.Examples = {[
							Description = "Infer table type",
							Code = "let
									StartTable = Table.FromRecords({
										[start = #datetime(2020,7,1,0,0,0), diff = #duration(0,15,0,0), list = {1}],
										[start = #datetime(2020,7,1,5,0,0), diff = #duration(0,16,0,0), list = null],
										[start = #datetime(2020,7,1,8,0,0), diff = #duration(1,0,0,0), list = {4}],
										[start = #datetime(2020,7,1,16,0,0), diff = #duration(0,8,0,0), list = {3,4}]
									})
								in
									Table.InferColumnTypes ( StartTable )",
												Result = "type table [
									#""start"" = DateTime.Type,
									#""diff"" = Duration.Type,
									#""list"" = List.Type
								]"
											],[
												Description = "Infer table type",
												Code = "let
									startTable = #table(
										{""n"", ""fun"", ""rec"", ""tb"", ""l"", ""bin"", ""typ""},
										{{1, (x) => x, [a = 1], #table({""a""}, {{1}}), {1..3}, #binary(""""), type text}}
										)
								in
									Table.InferColumnTypes ( StartTable )",
												Result = "type table [
									#""n"" = Int64.Type,
									#""fun"" = Function.Type,
									#""rec"" = Record.Type,
									#""tb"" = Table.Type,
									#""l"" = List.Type,
									#""bin"" = Binary.Type,
									#""typ"" = Type.Type
								]"
											],[
												Description = "get M code",
												Code = "let
									#""Start Table"" = #table(
										{""n"", ""fun"", ""rec"", ""tb"", ""l"", ""bin"", ""typ""},
										{{1, (x) => x, [a = 1], #table({""a""}, {{1}}), {1..3}, #binary(""""), type text}}
										)
								in
									Table.InferColumnTypes ( #""Start Table"" , null, null, null, ""Start Table"")",
												Result = """let
									normalTypes = Table.TransformColumnTypes( #""Start Table"", { { ""n"", Int64.Type }, { ""bin"", Binary.Type } } ),
									abnormalTypes = Table.TransformColumns( normalTypes, { { ""fun"", (x) as nullable function => x , type nullable function }, { ""rec"", (x) as nullable record => x , type nullable record }, { ""tb"", (x) as nullable table => x , type nullable table }, { ""l"", (x) as nullable list => x , type nullable list }, { ""typ"", (x) as nullable type => x , type nullable type }, { ""tb typ"", (x) as nullable type => x , type nullable type } } )
								in
									abnormalTypes"""
											]}
										]

			in 
				Value.ReplaceType(TableInferColumnTypesFunction, TableInferColumnTypesType),
		Table.ReplaceValuesFromTable = 
			let
				func = 
					(	table as table, 
						transformationTable as table, 
						optional columns as list, 
						optional specifyTransformationColumns as list, 
						optional missingField as nullable number) as table =>
					let
						// 	Buffer Transformation Table to call it only once
							BufferedTransformationTable = Table.Buffer(transformationTable),

						// 	Step to add error handling for given table & columns
							tryTransformationColumnNames = try
								let
									temp = Table.ColumnNames(BufferedTransformationTable),
									countTargetColumns = List.Count(temp),
									countSpecifiedColumns = try List.Count(specifyTransformationColumns) otherwise 0
								in
										 if countTargetColumns < 2 then error [Reason = "", Message = "The transformation table needs to have at least two columns", Detail = [TransformationColumns = temp] ]
									else if countSpecifiedColumns = 0 then {temp{0}, temp{1}}
									else if countSpecifiedColumns = 2 then
										let
											l = List.Intersect({specifyTransformationColumns, temp})
										in
											if List.Count(l) = 2 
											then l 
											else error  [Reason = "", Message = "The transformation table does not contain the 2 specified columns", Detail = [TransformationColumns = temp, SpecifiedColumns = specifyTransformationColumns] ]
									else error [Reason = "Error in specified transformation columns", Message = "Please specify exactly 2 columns", Detail = [SpecifiedColumns = specifyTransformationColumns ]],
						
							TransformationColumnNames = tryTransformationColumnNames[Value],

						// 	Define Replacer Function to trick Table.ReplaceValue
							CustomReplacer =
								(value as any, old as any, new as any) as any =>
									let
										getvalue = try
												Expression.Evaluate(
													"tbl{["
													& TransformationColumnNames{0}
													& " = t]}["
													& TransformationColumnNames{1}
													& "]",
													[ tbl = BufferedTransformationTable, t = value ]
												),
										newvalue = 
											if getvalue[HasError] then 
												if Text.Contains(getvalue[Error][Message], "The key matched more than one row in the table") then error [Reason = "An error occured in the Transformation Table", Message = "More than one replacements were found for the specified value", Detail = [ValueToReplace = value]]
												else if (missingField??1) = 0 then
													if Text.Contains(getvalue[Error][Message], "The key didn't match any rows in the table") then error [Reason = "An error occured in the Transformation Table", Message = "A replacement cannot be found for the specified value", Detail = [ValueToReplace = value]]
													else error getvalue[Error]
												else if (missingField??1) = 2 then null
												else value
											else getvalue[Value]
									in
										newvalue,

						// 	If table and columns ok, call Table.ReplaceValue
							Result = 
								if tryTransformationColumnNames[HasError] 
								then error tryTransformationColumnNames[Error] 
								else Table.ReplaceValue( table, null, null, CustomReplacer, columns??Table.ColumnNames(table) )
					in
						Result,
				types = 
					type function (
						table as (type table meta [
							Documentation.FieldCaption ="Target table",
							Documentation.FieldDescription = "The table to make replacements"
							]),
						transformationTable as (type table meta [
							Documentation.FieldCaption ="Transformation table",
							Documentation.FieldDescription = "The lookup table for replacements"
							]),
						optional columns as (type {text} meta [
							Documentation.FieldCaption ="Columns",
							Documentation.FieldDescription = "The columns in which to replace values"
							]),
						optional specifyTransformationColumns as (type {text} meta [
							Documentation.FieldCaption ="Transformation columns",
							Documentation.FieldDescription = "Columns to check on Transformation Table. If not specified, Column1 and Column2 are used."
							]),
						optional missingField as MissingField.Type
						)
					as table meta
					[
						Documentation.Name = "Table.ReplaceValuesFromTable",
						Documentation.Description = "Replaces multiple values at once using a lookup table",
						Documentation.LongDescription = "Replaces multiple values at once using a lookup table.<p>If no columns are specified for the <code>Transformation table</code>, the first column is used a a lookup and the second as a replacement. <p>If no columns are specified in the <code>Target table</code> then the default is <i>all columns</i>.",
						Documentation.Category = "Table",
						Documentation.Author = "Spyros Mavroforos",
						Documentation.Source = "https://github.com/SpyrosMauro/powerquery",
						Documentation.Version = "1",
						Documentation.Examples = {[
							Description = "Replace values on all columns",
							Code = "let
										StartingTable =
											Table.FromRecords({
												[a = 1, b = 2],
												[a = 2, b = 2],
												[a = 3, b = 4],
												[a = 4, b = 5]
											}),

										transformationTable = 
											Table.FromRecords({
												[check = 1, replace = ""A""],
												[check = 2, replace = ""B""],
												[check = 3, replace = ""C""],
												[check = 4, replace = ""D""]
											})
									in
										Table.ReplaceValuesFromTable(StartingTable, transformationTable)",
													Result = "Table.FromRecords({
												[a = ""A"", b = ""B""],
												[a = ""B"", b = ""B""],
												[a = ""C"", b = ""D""],
												[a = ""D"", b = 5]
											})"
													],[
													Description = "Replace values on column <code>a</code>",
													Code = "let
										StartingTable =
											Table.FromRecords({
												[a = 1, b = 2],
												[a = 2, b = 2],
												[a = 3, b = 4],
												[a = 4, b = 5]
											}),

										transformationTable = 
											Table.FromRecords({
												[check = 1, replace = ""A""],
												[check = 2, replace = ""B""],
												[check = 3, replace = ""C""],
												[check = 4, replace = ""D""]
											})
									in
										Table.ReplaceValuesFromTable(StartingTable, transformationTable, {""a""})",
													Result = "Table.FromRecords({
												[a = ""A"", b = 2],
												[a = ""B"", b = 2],
												[a = ""C"", b = 3],
												[a = ""D"", b = 5]
											})"
													],[
													Description = "Replace values on column <code>b</code> by using <code>Column2</code> column as lookup and <code>Column1</code> as replacement",
													Code = "let
										StartingTable =
											Table.FromRecords({
												[a = ""A"", b = ""B""],
												[a = ""B"", b = ""B""],
												[a = ""C"", b = ""D""],
												[a = ""D"", b = 5]
											}),

										transformationTable = 
											Table.FromRecords({
												[Column1 = 1, Column2 = ""A""],
												[Column1 = 2, Column2 = ""B""],
												[Column1 = 3, Column2 = ""C""],
												[Column1 = 4, Column2 = ""D""]
											})
									in
										Table.ReplaceValuesFromTable(StartingTable, transformationTable, {""b""}, {""replace"", ""check""}, MissingField.Error)",
												Result = "Table.FromRecords({
												[a = ""A"", b = 2],
												[a = ""B"", b = 2],
												[a = ""C"", b = 4],
												[a = ""D"", b = error [Reason = """", Message = ""A replacement cannot be found for the specified value"", Detail = [ValueToReplace = 5]]
											})"
												]}
											]

			in
				Value.ReplaceType(func, types),
		Table.ToTableView = 
			let
				// Function
				TableToTableViewFunction = (table as table, optional rowsToShow, optional primitive as logical, optional useOptimise as logical) as table =>
					let
						// Record with Types
						allTypes = [
							Any.Type = Any.Type,
							Binary.Type = Binary.Type,
							Byte.Type = Byte.Type,
							Character.Type = Character.Type,
							Currency.Type = Currency.Type,
							Date.Type = Date.Type,
							DateTime.Type = DateTime.Type,
							DateTimeZone.Type = DateTimeZone.Type,
							Day.Type = Day.Type,
							Decimal.Type = Decimal.Type,
							Double.Type = Double.Type,
							Duration.Type = Duration.Type,
							Function.Type = Function.Type,
							Guid.Type = Guid.Type,
							Int16.Type = Int16.Type,
							Int32.Type = Int32.Type,
							Int64.Type = Int64.Type,
							Int8.Type = Int8.Type,
							List.Type = List.Type,
							Logical.Type = Logical.Type,
							None.Type = None.Type,
							Null.Type = Null.Type,
							Number.Type = Number.Type,
							Password.Type = Password.Type,
							Percentage.Type = Percentage.Type,
							Record.Type = Record.Type,
							Single.Type = Single.Type,
							Table.Type = Table.Type,
							Text.Type = Text.Type,
							Time.Type = Time.Type,
							Type.Type = Type.Type,
							Uri.Type = Uri.Type
						],
						// addTabs: make text readable.
						addTabs = (t as text, optional tabsNumber as number) as text => Text.Replace ( t, "#(lf)", "#(lf)" & Text.Repeat("#(tab)", tabsNumber??1 ) ),

						// Not allowed types
						typeList = 
								if primitive??false then { "binary", "function", "list", "record", "table", "type" }
								else { "Binary.Type", "Function.Type", "List.Type", "Record.Type", "Table.Type", "Type.Type" },
						excludeTypes = (t as text) as logical => List.AllTrue(List.Transform(typeList, each t <> _)),

						typeToText = 
							if primitive??false then (x as list) as text => "#""" & x{0} &"""" & " = ( type " & x{1} & " )"
							else (x as list) as text => "#""" & x{0} &"""" & " = " & x{1},

						// Schema columns
						schemaColumns = if primitive??false then {"Name", "Kind"} else {"Name", "TypeName"},

						// Calculations
						fixTableName = "#""" & "" & """",

						schema = Table.SelectColumns(Table.Schema(table), schemaColumns),
						columnNames = schema[Name],

						findType = Table.SelectRows( schema, each excludeTypes( Record.Field(_, schemaColumns{1}) ) ),

						columnsToRemove = List.RemoveItems(columnNames, findType[Name]),
						removeColumns = List.Count(columnsToRemove) > 0,

						mainTableCall =
							let tbCall = 
								if removeColumns
									then "Table.RemoveColumns ( "& fixTableName & ", { " & Text.Combine(List.Transform(columnsToRemove, each """"&_&""""), ", ") & " } , MissingField.Ignore )"
								else fixTableName
							in
								if useOptimise??false then "Value.Optimize ( " & tbCall & " )" else tbCall,

						tableType =
								"type table [#(lf)#(tab)"
								& Text.Combine( Table.ToList( findType, typeToText ), ",#(lf)#(tab)" )
								& "#(lf)]",
						
						getType = "GetType = () =>#(lf)#(tab)" & addTabs(tableType),

						getRows = "GetRows = () =>#(lf)#(tab)" & addTabs(mainTableCall),
						
						onTake =
							let
								tbl = "#table (#(lf)#(tab)" & addTabs(tableType) & ",#(lf)#(tab){}#(lf))",
								countText = if rowsToShow = null then "count" else Text.From(rowsToShow),
								main =
									if rowsToShow = 0 then tbl
									else "if count = 0 then#(lf)#(tab)" & addTabs(tbl) & "#(lf)else Table.FirstN ( " & mainTableCall & ", " & countText & " )"
							in
								"OnTake = (count as number) =>#(lf)#(tab)" & addTabs(main),


						tableView =
							"Table.View (#(lf)#(tab)null,#(lf)#(tab)"
							& "[#(lf)#(tab)#(tab)" & addTabs(getType, 2)
							& ",#(lf)#(tab)#(tab)" & addTabs(getRows, 2)
							& ",#(lf)#(tab)#(tab)" & addTabs(onTake, 2) & "#(lf)#(tab)]" & "#(lf))",

						rec = 
						Record.Combine({
							[
								Table.View = Table.View,
								Table.FirstN = Table.FirstN,
								Table.RemoveColumns = Table.RemoveColumns,
								MissingField.Ignore = MissingField.Ignore,
								#"" = table
							],
							allTypes
						})
					in
					Expression.Evaluate(tableView, rec),


				// Documentation
				TableToTableViewType =
					type function (
						table as (type table meta [
							Documentation.FieldCaption = "Target table",
							Documentation.FieldDescription = "The table for which to generate <code>Table.View</code>"
							]),
						optional rowsToShow as (type number meta [
							Documentation.FieldCaption = "rowsToShow",
							Documentation.FieldDescription = "Show first n rows when asking for 1000"
							]),
						optional primitive as (type logical meta [
							Documentation.FieldCaption = "primitive",
							Documentation.FieldDescription = "Only primitive types"
							]),
						optional useOptimise as (type logical meta [
							Documentation.FieldCaption = "useOptimise",
							Documentation.FieldDescription = "Use Value.Optimize"
							])
					)
					as table meta
					[
						Documentation.Name = "Table.ToTableView",
						Documentation.Description = "Generates <code>Table.View</code> to trick model asking for evaluation",
						Documentation.LongDescription = "Executes <code>Table.View</code> to trick model asking for evaluation.<p>Creates <code>Table.View</code> based on <code>Table.Schema</code> and executes it.<p> <b>Skipping:</b> <i>Lists, Tables, Records, Binaries, Functions and Types</i>",
						Documentation.Category = "Table",
						Documentation.Author = "Spyros Mavroforos",
						Documentation.Source = "https://github.com/SpyrosMauro/powerquery",
						Documentation.Version = "1",
						Documentation.Examples = {[
							Description = "For examples of how this code is generated see:",
							Code = "Get.TableView",
							Result = "Expression.Evaluate of generated table view." ]}
					]

			in
				Value.ReplaceType(TableToTableViewFunction, TableToTableViewType),
	// 	Time Intelligence
		Duration.To 	= // перевод длительности в секунды, минуты, ... месяцы, кварталы, годы
			// DateTime Diff using Excluded Dates list and Start Time / End Time.
			let
				// Function
				DurationToFunction = (duration as nullable duration, durationTo as text) as nullable number =>
					let
						// durationTotal = Fix a Duration.TotalX function dependent on durationTo
						durationTotal = 
							let 
								d = Text.Lower(durationTo)
							in
									 if d = "seconds" 	then Duration.TotalSeconds
								else if d = "minutes" 	then Duration.TotalMinutes
								else if d = "hours" 	then Duration.TotalHours
								else if d = "days" 		then Duration.TotalDays
								else if d = "weeks" 	then (m) => Value.Divide(Duration.TotalDays(m), 7)
								else if d = "months" 	then (m) => Value.Divide(Duration.TotalDays(m), 30)
								else if d = "quarters" 	then (m) => Value.Divide(Duration.TotalDays(m), 121)
								else 						 (m) => Value.Divide(Duration.TotalDays(m), 365),

						Result = durationTotal(duration)
					in
						Result,


				// Documentation
				DurationToType =
					type function (
						duration as (type nullable duration meta [
							Documentation.FieldCaption = "duration",
							Documentation.FieldDescription = "duration to transform"
						]),
						durationTo as (type text meta [
							Documentation.FieldCaption = "Duration in",
							Documentation.FieldDescription = "Transform duration to",
							Documentation.AllowedValues = {"Seconds", "Minutes", "Hours", "Days", "Weeks", "Months", "Quarters", "Years"}
						])
					)
					as nullable number meta
					[
						Documentation.Name = "Duration.To",
						Documentation.Description = "All duration functions in one",
						Documentation.LongDescription = "Transforms a given <code>duration</code> to a given interval (<code>durationTo</code>).<p>Default values:<table>
								<tr>
									<td><i>Transformation</i></td>
									<td><i>Days</i></td>
								</tr>
								<tr>
									<td>Weeks</td>
									<td><code>7</code></td>
								</tr>
								<tr>
									<td>Months<br></td>
									<td><code>30</code></td>
								</tr>
								<tr>
									<td>Quarters</td>
									<td><code>121</code></td>
								</tr>
								<tr>
									<td>Years</td>
									<td><code>365</code></td>
								</tr>
							</table>",
						Documentation.Category = "Duration",
						Documentation.Author = "Spyros Mavroforos",
						Documentation.Source = "https://github.com/SpyrosMauro/powerquery",
						Documentation.Version = "1",
						Documentation.Examples = {[
							Description = "Duration to <code>months</code>",
							Code 		= "Duration.To(#duration(15,0,0,0), ""Months"")",
							Result 		= "0.5"
							]}
					]

			in
				Value.ReplaceType(DurationToFunction, DurationToType),
		DateTime.Diff 	= // DateTime Diff using Excluded Dates list and Start Time / End Time.
			let
				// Function
				DateTimeDiffFunction = (dateStart as nullable datetime, dateEnd as nullable datetime, optional excludedDays as list, optional timeStart as time, optional timeEnd as time) as nullable duration =>
					let
						// Helper Functions
						// dayIn: find relevant times in day
						dayIn = (timeStart, timeEnd) as list =>
							let
								times = { timeStart??#time(0,0,0) , timeEnd??#time(24,0,0) }
							in
								if times{0} >= times{1}
									then error [Reason= "Incorrect time limits", Message = "'Start time' must be smaller than 'End time'", Detail = [#"Start time" = timeStart, #"End time" = timeEnd]]
								else times,

						// dayDuration
						dayDuration = (times) as duration => ( #date(2020,1,1) & times{1} ) - ( #date(2020,1,1) & times{0} ),

						// findExcludedDuration: Find duration to exclude based on excludedDays
						findExcludedDuration = (dates as list, startDateTime as datetime, endDateTime as datetime, optional times as list) as duration =>
							let
								wholeDate = dayDuration(times),
								limitDurations = [
									check = startDate = endDate,
									start = (startDate & times{1} - startDateTime),
									end =  (endDateTime - (endDate & times{0})) ],
								result =
									if limitDurations[check] then List.Count(List.Select(dates, each _ = startDate)) * (endDateTime - startDateTime)
									else List.Accumulate(dates, #duration(0,0,0,0),
										(sum, current) =>
											if current < startDate or current > endDate then sum
											else if current = startDate then sum + limitDurations[start]
											else if current = endDate then sum + limitDurations[end]
											else sum + wholeDate )
							in
								result,
							

						// Start finding things
						// Sort datetimes and keep direction
						dateSort = List.Sort({dateStart, dateEnd}),
						direction = if (dateStart = dateSort{0}) then 1 else -1,

						// Find relevant times in day
						times = dayIn(timeStart, timeEnd),

						// Calculate date components to use
						startDate = DateTime.Date(dateSort{0}),
						endDate = DateTime.Date(dateSort{1}),

						// Truncate datetimes
						startDateTime = startDate & List.Median(times & {DateTime.Time(dateSort{0})}),
						endDateTime = endDate & List.Median(times & {DateTime.Time(dateSort{1})}),
						
						// Find duration
						calcDuration =
							let
								ExcludedDuration = findExcludedDuration(excludedDays??{}, startDateTime, endDateTime, times),
								AllDuration = endDateTime - startDateTime,
								NonWorkingDuration = Duration.Days(endDate - startDate) * (#duration(1,0,0,0) - dayDuration(times))
							in
								AllDuration - NonWorkingDuration - ExcludedDuration,
						fixDuration = calcDuration * direction,

						Result = if dateStart = null or dateEnd = null then null else fixDuration
					in
						Result,


				// Documentation
				DateTimeDiffType =
					type function (
						dateStart as (type nullable datetime meta [
							Documentation.FieldCaption = "Start date",
							Documentation.FieldDescription = "DateTime Start"
						]),
						dateEnd as (type nullable datetime meta [
							Documentation.FieldCaption = "End date",
							Documentation.FieldDescription = "DateTime End"
						]),
						optional excludedDays as (type {date} meta [
							Documentation.FieldCaption = "Excluded Dates",
							Documentation.FieldDescription = "A list of dates to exclude"
						]),
						optional timeStart as (type time meta [
							Documentation.FieldCaption = "Start time",
							Documentation.FieldDescription = "When a day starts counting"
						]),
						optional timeEnd as (type time meta [
							Documentation.FieldCaption = "End time",
							Documentation.FieldDescription = "When a day stops counting"
						])
					)
					as nullable duration meta
					[
						Documentation.Name = "DateTime.Diff",
						Documentation.Description = "Finds the difference between two datetimes",
						Documentation.LongDescription = "Finds the difference between two datetimes. Optional <code>'Excluded Dates'</code> list. Optional <code>'Start time'</code> and <code>'End time'</code>.",
						Documentation.Category = "Duration",
						Documentation.Author = "Spyros Mavroforos",
						Documentation.Source = "https://github.com/SpyrosMauro/powerquery",
						Documentation.Version = "1",
						Documentation.Examples = {[
							Description = "Diff using excluded date list",
							Code = "let
										StartingTable =
											Table.FromRecords({
												[start = #datetime(2020,7,1,0,0,0), end = #datetime(2020,7,2,15,0,0)],
												[start = #datetime(2020,7,1,5,0,0), end = #datetime(2020,7,2,19,0,0)],
												[start = #datetime(2020,7,1,8,0,0), end = #datetime(2020,7,2,16,0,0)],
												[start = #datetime(2020,7,1,16,0,0), end = #datetime(2020,7,3,7,0,0)]
											}),
										holidays = {#date(2020,7,2)}
									in
										Table.AddColumns( StartingTable, ""diff"", each DateTime.Diff( [end], [start], holidays ) )",
													Result = "Table.FromRecords({
										[start = #datetime(2020,7,1,0,0,0), end = #datetime(2020,7,2,15,0,0), diff = #duration(1,0,0,0)],
										[start = #datetime(2020,7,1,5,0,0), end = #datetime(2020,7,2,19,0,0), diff = #duration(19,0,0,0)],
										[start = #datetime(2020,7,1,8,0,0), end = #datetime(2020,7,3,16,0,0), diff = #duration(1,8,0,0)],
										[start = #datetime(2020,7,1,16,0,0), end = #datetime(2020,7,3,7,0,0), diff = #duration(0,15,0,0)]
									})"
						],[
							Description = "Diff using excluded date list and time limits",
							Code = "let
										StartingTable =
											Table.FromRecords({
												[start = #datetime(2020,7,1,0,0,0), end = #datetime(2020,7,2,15,0,0)],
												[start = #datetime(2020,7,1,5,0,0), end = #datetime(2020,7,2,19,0,0)],
												[start = #datetime(2020,7,1,8,0,0), end = #datetime(2020,7,2,16,0,0)],
												[start = #datetime(2020,7,1,16,0,0), end = #datetime(2020,7,3,7,0,0)]
											}),
										holidays = {#date(2020,7,2)}
									in
										Table.AddColumns( StartingTable, ""diff"", each DateTime.Diff( [end], [start], holidays, #time(8,0,0), #time(16,0,0) ) )",
													Result = "Table.FromRecords({
										[start = #datetime(2020,7,1,0,0,0), end = #datetime(2020,7,2,15,0,0), diff = #duration(0,8,0,0)],
										[start = #datetime(2020,7,1,5,0,0), end = #datetime(2020,7,2,19,0,0), diff = #duration(0,8,0,0)],
										[start = #datetime(2020,7,1,8,0,0), end = #datetime(2020,7,3,16,0,0), diff = #duration(0,16,0,0)],
										[start = #datetime(2020,7,1,16,0,0), end = #datetime(2020,7,3,7,0,0), diff = #duration(0,0,0,0)]
									})"
						],[
							Description = "Diff using time limits",
							Code = "
								let
									StartingTable =
										Table.FromRecords({
											[start = #datetime(2020,7,1,0,0,0), end = #datetime(2020,7,2,15,0,0)],
											[start = #datetime(2020,7,1,5,0,0), end = #datetime(2020,7,2,19,0,0)],
											[start = #datetime(2020,7,1,8,0,0), end = #datetime(2020,7,2,16,0,0)],
											[start = #datetime(2020,7,1,16,0,0), end = #datetime(2020,7,3,7,0,0)]
										})
								in
									Table.AddColumns( StartingTable, ""diff"", each DateTime.Diff( [end], [start], null, #time(8,0,0), #time(16,0,0) ) )",
												Result = "Table.FromRecords({
									[start = #datetime(2020,7,1,0,0,0), end = #datetime(2020,7,2,15,0,0), diff = #duration(0,15,0,0)],
									[start = #datetime(2020,7,1,5,0,0), end = #datetime(2020,7,2,19,0,0), diff = #duration(0,16,0,0)],
									[start = #datetime(2020,7,1,8,0,0), end = #datetime(2020,7,3,16,0,0), diff = #duration(1,0,0,0)],
									[start = #datetime(2020,7,1,16,0,0), end = #datetime(2020,7,3,7,0,0), diff = #duration(0,8,0,0)]
								})"
						]}
					]

			in
				Value.ReplaceType(DateTimeDiffFunction, DateTimeDiffType),

		Date.Diff 		= // Date Diff using Excluded Dates list.
			let
				// Function
				DateDiffFunction = (dateStart as nullable date, dateEnd as nullable date, optional excludedDays as list) as nullable duration =>
					let
						// Helper Functions
						// findExcludedDuration: Find duration to exclude based on excludedDays
						findExcludedDuration = 
							(dates as list, startDate as date, endDate as date) as duration =>
							let
								countDays = List.Count(List.Select(excludedDays??{}, each _>= startDate and _ <= endDate)),
								result = countDays * #duration(1,0,0,0)
							in
								result,
							
						// Start finding things
						// Sort dates and keep direction
						dateSort = List.Sort({dateStart, dateEnd}),
						direction = if (dateStart = dateSort{0}) then 1 else -1,

						// Calculate dates to use
						startDate = dateSort{0},
						endDate = dateSort{1},
						
						// Find duration
						calcDuration =
							let
								ExcludedDuration = findExcludedDuration(excludedDays??{}, startDate, endDate),
								AllDuration = endDate - startDate
							in
								if AllDuration = #duration(0,0,0,0) then AllDuration else AllDuration - ExcludedDuration,
						fixDuration = calcDuration * direction,

						Result = if dateStart = null or dateEnd = null then null else fixDuration
					in
						Result,


				// Documentation
				DateDiffType =
					type function (
						dateStart as (type nullable date meta [
							Documentation.FieldCaption = "Start date",
							Documentation.FieldDescription = "Date Start"
						]),
						dateEnd as (type nullable date meta [
							Documentation.FieldCaption = "End date",
							Documentation.FieldDescription = "Date End"
						]),
						optional excludedDays as (type {date} meta [
							Documentation.FieldCaption = "Excluded Dates",
							Documentation.FieldDescription = "A list of dates to exclude"
						])
					)
					as nullable duration meta
					[
						Documentation.Name = "Date.Diff",
						Documentation.Description = "Finds the difference between two dates",
						Documentation.LongDescription = "Finds the difference between two dates. Optional <code>'Excluded Dates'</code> list.",
						Documentation.Category = "Duration",
						Documentation.Author = "Spyros Mavroforos",
						Documentation.Source = "https://github.com/SpyrosMauro/powerquery",
						Documentation.Version = "1",
						Documentation.Examples = {[
							Description = "Diff using excluded date list",
							Code = "let
										StartingTable =
											Table.FromRecords({
												[start = #date(2020,7,1), end = #date(2020,7,2)],
												[start = #date(2020,7,1), end = #date(2020,7,3)],
												[start = #date(2020,7,5), end = #date(2020,7,2)]
											}),
										holidays = {#date(2020,7,2), #date(2020,7,4)}
									in
										Table.AddColumns( StartingTable, ""diff"", each DateTime.Diff( [end], [start], holidays ) )",
							Result = "Table.FromRecords({
										[start = #date(2020,7,1), end = #datetime(2020,7,2), diff = #duration(0,0,0,0)],
										[start = #date(2020,7,1), end = #datetime(2020,7,3), diff = #duration(1,0,0,0)],
										[start = #date(2020,7,5), end = #datetime(2020,7,2), diff = #duration(-1,0,0,0)]
									})"
						]}
					]

			in
				Value.ReplaceType(DateDiffFunction, DateDiffType),
	// 	Types
		Type.TableType 	= // Get text of non abstract table type.
			let
				// Function
				TypeTableTypeFunction = (table as table, optional precision as number, optional primitive as logical) as any =>
					let
					// 	addTabs: make text readable.
						addTabs = 
							(t as text, optional tabsNumber as number) as text => 
								Text.Replace ( t, "#(lf)", "#(lf)" & Text.Repeat("#(tab)", tabsNumber??1 ) ),

					// 	typeToText: format types
						typeToText = 
							if primitive ?? false 
							then (x as list) as text => if Text.StartsWith(x{1}, "type table [") then "#""" & x{0} &"""" & " = ( " & x{1} & " )" else "#""" & x{0} &"""" & " = ( type " & x{1} & " )"
							else (x as list) as text => "#""" & x{0} &"""" & " = " & x{1},

					// 	typeFinder: finds the main type of a list
						typeFinder = 
							(x as list, optional crazyMode as logical) =>
								let
									startingList  = List.Select(x, each _ <> type any),
									listMode 	  = List.Mode(startingList),
									listDistinct  = List.Distinct(startingList),
									countDistinct = List.Count(listDistinct),
									removeInts 	  = List.RemoveItems(listDistinct, {Int64.Type, Int32.Type, Int8.Type})
								in
										 if countDistinct = 0 then type any
							 		else if countDistinct = 1 then listDistinct{0}
									// Five extra steps here for abstract types
									else if List.AllTrue(List.Transform(listDistinct, each Type.Is(_, type number))) then type number
									else if List.AllTrue(List.Transform(listDistinct, each Type.Is(_, type [...]))) then type nullable [...]
									else if List.AllTrue(List.Transform(listDistinct, each Type.Is(_, type table))) then type nullable table
									else if List.AllTrue(List.Transform(listDistinct, each Type.Is(_, type list))) then type nullable list
									else if List.AllTrue(List.Transform(listDistinct, each Type.Is(_, type function))) then type nullable function
									/* // crazyMode is just for testing. Really, it just tries to assign the type found the most in the list. Don't use that.
									else if crazyMode??false then listMode */
									else if countDistinct = 2 then
											 if List.Contains(listDistinct, type text) then type text
										else if List.ContainsAll(listDistinct, {type date, type datetime}) then type datetime
										else if List.ContainsAll(listDistinct, {type date, type datetimezone}) then type datetimezone
										else if List.ContainsAll(listDistinct, {type datetime, type datetimezone}) then type datetimezone
										else if removeInts{0}? = type duration then type duration
										else type any
									else 
										if countDistinct = 3 then
										if List.ContainsAll(listDistinct, {type datetimezone, type datetime, type date}) then type datetimezone
										else if removeInts = {} then Int64.Type
										else type any
									else  type any,


					// 	Not allowed types
						typeList = 
							[
								Text =
									if primitive??false 
									then { "null", "function", "list", "record", "table", "type" }
									else { "Type.Null", "Type.Function", "Type.List", "Type.Record", "Type.Table", "Type.Type" },
								Type = { type null, type function, type list, type record, type table, type type }
							],
						excludeTypes = (t as any, textOrType as text) as logical =>
							if textOrType = "text" 
							then List.AllTrue(List.Transform(Record.Field(typeList, textOrType), each t <> _))
							else List.AllTrue(List.Transform(Record.Field(typeList, textOrType), each not Type.Is(t, _))),

					// 	fakeFunction: takes a type and makes a function that returns this type, to be used for non appliable types
					// 	when Table.TransformColumnTypes is able to ascribe these 6 types then it will be redundant
						fakeFunction = (Type as type) as function =>
								 if Type.Is(Type, type null) then (x) as null => null
							else if Type.Is(Type, type function) then (x) as nullable function => x
							else if Type.Is(Type, type list) then (x) as nullable list => x
							else if Type.Is(Type, type record) then (x) as nullable record => x
							else if Type.Is(Type, type table) then (x) as nullable table => x
							else if Type.Is(Type, type type) then (x) as nullable type => x
							else (x) => x,

					// 	checkInt
						checkInt = (x as number) as type => 
							if primitive??false 
							then type number 
							else if (Number.Mod(x, 1)??0) = 0 then Int64.Type else type number,
					// 	replaceWithType: custom replacer
						replaceWithType = (x,y,z) =>
							let
								// nulls were a bother. Now Completely removed.
								typ = if (x??"") = "" then type any else Value.Type(x)
							in
								if Type.Is(typ, type number) then checkInt(x)
								// next step is for excel and other sources which store time as '31/12/1899 hh:mm:ss'. Thankfully, pq also sees this as time if Time.From is used
								else if Type.Is(typ, type datetime) then if Date.From(DateTime.From(x))=#date(1899,12,31) then type time else type datetime
								else if Type.Is(typ, type text) then
										 if not (try Logical.FromText(x))[HasError] then type logical
									else if not (try Number.FromText(x))[HasError] then checkInt(Number.From(x))
									else if not (try Time.FromText(x))[HasError] then type time
									else if not (try Date.FromText(x))[HasError] then type date
									else if not (try DateTime.FromText(x))[HasError] then type datetime
									else if not (try DateTimeZone.FromText(x))[HasError] then type datetimezone
									else if not (try Duration.FromText(x))[HasError] then type duration
									else type text
								else typ,

						tableTypeFromSchema = (schema as table) as text =>
							"type table [#(lf)#(tab)"
							& Text.Combine( Table.ToList( schema, (t) => addTabs(typeToText(t)) ), ",#(lf)#(tab)" )
							& "#(lf)]",


					// 	Schema columns
						schemaColumns = if primitive??false then {"Name", "Kind"} else {"Name", "TypeName"},
						findType  =
							if (precision??0) > 0 then
								let
									rowsToGet 	= List.Min({Table.RowCount(table), precision??50, 1000}),
									firstN 		= Table.FirstN(table, rowsToGet),
									columnNames = Table.ColumnNames(firstN),
									tableValuesToType = Table.ReplaceValue(firstN, null, null, replaceWithType, columnNames),
									FindBestType = Table.CombineColumns(
										Table.Transpose(tableValuesToType),
										List.Transform({1..rowsToGet}, each "Column"&Text.From(_)),
										typeFinder,
										"Types"
										),
									
									allTransformations = 
										List.Zip({	
											columnNames, 
											List.Transform(FindBestType[Types], each if Type.Is(_, type null) then type any else _)
										}),

									applicableTransformations = List.Select( allTransformations, each excludeTypes(_{1}, "Type")),
									fakeTable = #table(List.Transform(allTransformations, each _{0}), {}),
									applySimpleTransformations = 
										if applicableTransformations <> {} 
										then Table.TransformColumnTypes(fakeTable, applicableTransformations) 
										else fakeTable,

									notAllowedList = 
										List.Transform(
											List.RemoveItems(allTransformations, applicableTransformations), 
											each {_{0}, fakeFunction(_{1}), _{1}}
										),
									checkExtraTypes = 
										if notAllowedList <> {} 
										then Table.TransformColumns(applySimpleTransformations, notAllowedList) 
										else applySimpleTransformations,
									schema = Table.SelectColumns(Table.Schema(checkExtraTypes), schemaColumns),
									result =
										if primitive??false
										then Table.RemoveColumns(
												Table.AddColumn(schema, "Deep Dive", each 
													if [Kind] = "table" 
													then let name = [Name] 
														 in tableTypeFromSchema(
																Table.SelectColumns(
																	Type.TableSchema(List.Select(notAllowedList, each _{0} = name){0}{2}), 
																	schemaColumns
																)
															)
													else [Kind], type text)
												,{"Kind"})
										else schema
								in
									result
							else
								Table.SelectColumns(Table.Schema(table), schemaColumns),

						tableType = tableTypeFromSchema(findType)
					in
						tableType,

				// Documentation
				TypeTableTypeType =
					type function (
						table as (type table meta [
							Documentation.FieldCaption = "Target table",
							Documentation.FieldDescription = "The table for which to generate <code>Table.View</code>"
							]),
						optional precision as (type number meta [
							Documentation.FieldCaption = "precision",
							Documentation.FieldDescription = "First <code>n</code> rows to check for best type match"
							]),
						optional primitive as (type logical meta [
							Documentation.FieldCaption = "primitive",
							Documentation.FieldDescription = "Only primitive types"
							])
					)
					as text meta
					[
						Documentation.Name = "Type.TableType",
						Documentation.Description = "Generates the text of non abstract table type",
						Documentation.LongDescription = "Generates <b>text of</b> <code>non abstract type table</code>. Optional <code>precision</code>.",
						Documentation.Category = "Type",
						Documentation.Author = "Spyros Mavroforos",
						Documentation.Source = "https://github.com/SpyrosMauro/powerquery",
						Documentation.Version = "1",
						Documentation.Examples = {[
								Description = "Table type to text",
								Code = "let
											StartTable = Table.FromRecords({
												[start = #datetime(2020,7,1,0,0,0), tb = #table(type table [a = number], {{1}}), list = {1}],
												[start = #datetime(2020,7,1,5,0,0), tb = #table(type table [a = number], {{2}}), list = null],
												[start = #datetime(2020,7,1,8,0,0), tb = #table(type table [a = number], {{3}}), list = {4}],
												[start = #datetime(2020,7,1,16,0,0), tb = null, list = {3,4}]
											})
										in
											Type.TableType ( StartTable, 10, true )",
								Result = """type table [
											#""start"" = ( type datetime ),
											#""diff"" = ( type table [
											#(tab)#(tab)#""a"" = ( type any )
											#(tab)] ),
											#""list"" = ( type list )
										]"""
							],[
								Description = "Table type to text",
								Code = "let
											startTable = #table(
												{""n"", ""fun"", ""rec"", ""tb"", ""l"", ""bin"", ""typ""},
												{{1, (x) => x, [a = 1], #table({""a""}, {{1}}), {1..3}, #binary(""), type text}}
												)
										in
											Type.TableType ( StartTable )",
								Result = """type table [
											#""n"" = Int64.Type,
											#""fun"" = Function.Type,
											#""rec"" = Record.Type,
											#""tb"" = Table.Type,
											#""l"" = List.Type,
											#""bin"" = Binary.Type,
											#""typ"" = Type.Type
										]"""
							]}
					]

			in
				Value.ReplaceType(TypeTableTypeFunction, TypeTableTypeType),
		Type.ToText 	= // Get text representation of any type.
			let
				// Function
				typeToTextFunction = (typ as type, optional primitive as logical) as text => 
					let
						schema = Type.TableSchema(type table [a = typ]){0},
						result = if primitive??false then "type " & schema[Kind] else schema[TypeName]
					in
						result,


				// Documentation
				typeToTextType =
					type function (
						typ as ((type type) meta [
							Documentation.FieldCaption = "Type",
							Documentation.FieldDescription = "Type to get as text"
							]),
						optional primitive as (type logical meta [
							Documentation.FieldCaption = "primitive",
							Documentation.FieldDescription = "Give primitive type"
							])
					)
					as text meta
					[
						Documentation.Name = "Type.ToText",
						Documentation.Description = "Gives text representation of given type",
						Documentation.LongDescription = "Gives text representation of given type. Optional <code>primitive</code> mode.",
						Documentation.Category = "Type",
						Documentation.Author = "Spyros Mavroforos",
						Documentation.Source = "https://github.com/SpyrosMauro/powerquery",
						Documentation.Version = "1",
						Documentation.Examples = {[
							Description = "<code>type text</code> to text",
							Code = "Type.ToText ( type text ) ",
							Result = """Text.Type"""
						],[
							Description = "Primitive <code>type text</code> to text",
							Code = "Type.ToText ( type text , true ) ",
							Result = """type text"""
						]}
					]

			in 
				Value.ReplaceType(typeToTextFunction, typeToTextType),
		Get.TableView 	= // Get formatted Table.View function based on Table.Schema or by infering types.
			let
				// Function
				GetTableViewFunction_ = 1,
				GetTableViewFunction = (table as table, tableName as text, optional precision as number, optional rowsToShow, optional primitive as logical, optional useOptimise as logical) as text =>
					let
						// addTabs: make text readable.
						addTabs = (t as text, optional tabsNumber as number) as text => Text.Replace ( t, "#(lf)", "#(lf)" & Text.Repeat("#(tab)", tabsNumber??1 ) ),

						// typeFinder: finds the main type of a list
						typeFinder = (x as list, optional crazyMode as logical) =>
							let
								startingList = List.Select(x, each _ <> type any),
								listMode = List.Mode(startingList),
								listDistinct = List.Distinct(startingList),
								countDistinct = List.Count(listDistinct),
								removeInts = List.RemoveItems(listDistinct, {Int64.Type, Int32.Type, Int8.Type})
							in
							if countDistinct = 0 then type any
							else if countDistinct = 1 then listDistinct{0}
							// Five extra steps here for abstract types
							else if List.AllTrue(List.Transform(listDistinct, each Type.Is(_, type number))) then type number
							else if List.AllTrue(List.Transform(listDistinct, each Type.Is(_, type [...]))) then type nullable [...]
							else if List.AllTrue(List.Transform(listDistinct, each Type.Is(_, type table))) then type nullable table
							else if List.AllTrue(List.Transform(listDistinct, each Type.Is(_, type list))) then type nullable list
							else if List.AllTrue(List.Transform(listDistinct, each Type.Is(_, type function))) then type nullable function
							/* // crazyMode is just for testing. Really, it just tries to assign the type found the most in the list. Don't use that.
							else if crazyMode??false then listMode */
							else if countDistinct = 2 then
								if List.Contains(listDistinct, type text) then type text
								else if List.ContainsAll(listDistinct, {type date, type datetime}) then type datetime
								else if List.ContainsAll(listDistinct, {type date, type datetimezone}) then type datetimezone
								else if List.ContainsAll(listDistinct, {type datetime, type datetimezone}) then type datetimezone
								else if removeInts{0}? = type duration then type duration
								else type any
							else if countDistinct = 3 then
								if List.ContainsAll(listDistinct, {type datetimezone, type datetime, type date}) then type datetimezone
								else if removeInts = {} then Int64.Type
								else type any
							else  type any,

						// checkInt
						checkInt = (x as number) as type => if (Number.Mod(x, 1)??0) = 0 then Int64.Type else type number,
						// replaceWithType: custom replacer
						replaceWithType = (x,y,z) =>
							let
								// nulls were a bother. Now Completely removed.
								typ = if (x??"") = "" then type any else Value.Type(x)
							in
								if Type.Is(typ, type number) then checkInt(x)
								// next step is for excel and other sources which store time as '31/12/1899 hh:mm:ss'. Thankfully, pq also sees this as time if Time.From is used
								else if Type.Is(typ, type datetime) then if Date.From(DateTime.From(x))=#date(1899,12,31) then type time else type datetime
								else if Type.Is(typ, type text) then
									if not (try Logical.FromText(x))[HasError] then type logical
									else if not (try Number.FromText(x))[HasError] then checkInt(Number.From(x))
									else if not (try Time.FromText(x))[HasError] then type time
									else if not (try Date.FromText(x))[HasError] then type date
									else if not (try DateTime.FromText(x))[HasError] then type datetime
									else if not (try DateTimeZone.FromText(x))[HasError] then type datetimezone
									else if not (try Duration.FromText(x))[HasError] then type duration
									else type text
								else typ,


						// Not allowed types
						typeList = 
							[
								Text =
									if primitive??false then { "binary", "function", "list", "record", "table", "type" }
								else { "Binary.Type", "Function.Type", "List.Type", "Record.Type", "Table.Type", "Type.Type" },
								Type = {type binary, type function, type list, type record, type table, type type, type [...]}
							],
						excludeTypes = (t as any, textOrType as text) as logical =>
							if textOrType = "Text" then List.AllTrue(List.Transform(Record.Field(typeList, textOrType), each t <> _))
							else List.AllTrue(List.Transform(Record.Field(typeList, textOrType), each not Type.Is(t, _))),

						// typeToText: format types to #"Name" = type
						typeToText = 
							if primitive??false then (x as list) as text => "#""" & x{0} &"""" & " = ( type " & x{1} & " )"
							else (x as list) as text => "#""" & x{0} &"""" & " = " & x{1},

						// Schema columns
						schemaColumns = if primitive??false then {"Name", "Kind"} else {"Name", "TypeName"},

						// Calculations
						fixTableName = if Text.StartsWith(tableName, "#") then tableName else "#""" & tableName & """",
						columnNames = Table.ColumnNames(table),

						findType =
							if (precision??0) > 0 then
								let
									rowsToGet = List.Min({Table.RowCount(table), precision??50, 1000}),

									tableValuesToType = Table.ReplaceValue(Table.FirstN(table, rowsToGet), null, null, replaceWithType, columnNames),
									FindBestType = Table.CombineColumns(
										Table.Transpose(tableValuesToType),
										List.Transform({1..rowsToGet}, each "Column"&Text.From(_)),
										typeFinder,
										"Types"
										),

									RemoveExtra = List.Select(
										List.Zip({columnNames, List.Transform(FindBestType[Types], each if Type.Is(_, type null) then type any else _)}),
										each excludeTypes(_{1}, "Type")),
									realFakeTables = Table.TransformColumnTypes(#table(List.Transform(RemoveExtra, each _{0}), {}), RemoveExtra),
									schema = Table.SelectColumns(Table.Schema(realFakeTables), schemaColumns)
								in
									schema
							else
								Table.SelectRows(
									Table.SelectColumns(Table.Schema(table), schemaColumns),
									each excludeTypes(Record.Field(_, schemaColumns{1}), "Text") ),

						columnsToRemove = List.RemoveItems(columnNames, findType[Name]),
						removeColumns = List.Count(columnsToRemove) > 0,

						mainTableCall =
							let tbCall = 
								if removeColumns
									then "Table.RemoveColumns ( "& fixTableName & ", { " & Text.Combine(List.Transform(columnsToRemove, each """"&_&""""), ", ") & " } , MissingField.Ignore )"
								else fixTableName
							in
								if useOptimise??false then "Value.Optimize ( " & tbCall & " )" else tbCall,

						tableType =
							"type table [#(lf)#(tab)"
							& Text.Combine(Table.ToList(findType, typeToText ), ",#(lf)#(tab)")
							& "#(lf)]",
						
						getType = "GetType = () =>#(lf)#(tab)" & addTabs(tableType),

						getRows = "GetRows = () =>#(lf)#(tab)" & addTabs(mainTableCall),
						
						onTake =
							let
								tbl = "#table (#(lf)#(tab)" & addTabs(tableType) & ",#(lf)#(tab){}#(lf))",
								countText = if rowsToShow = null then "count" else Text.From(rowsToShow),
								main =
									if rowsToShow = 0 then tbl
									else "if count = 0 then#(lf)#(tab)" & addTabs(tbl) & "#(lf)else Table.FirstN ( " & mainTableCall & ", " & countText & " )"
							in
								"OnTake = (count as number) =>#(lf)#(tab)" & addTabs(main),


						tableView =
							"= Table.View (#(lf)#(tab)null,#(lf)#(tab)"
							& "[#(lf)#(tab)#(tab)" & addTabs(getType, 2)
							& ",#(lf)#(tab)#(tab)" & addTabs(getRows, 2)
							& ",#(lf)#(tab)#(tab)" & addTabs(onTake, 2) & "#(lf)#(tab)]" & "#(lf))"
					in
						tableView,


				// Documentation
				GetTableViewType =
					type function (
						table as (type table meta [
							Documentation.FieldCaption = "Target table",
							Documentation.FieldDescription = "The table for which to generate <code>Table.View</code>"
							]),
						tableName as (type text meta [
							Documentation.FieldCaption = "Table name",
							Documentation.FieldDescription = "The name of the table in text"
							]),
						optional precision as (type number meta [
							Documentation.FieldCaption = "precision",
							Documentation.FieldDescription = "First <code>n</code> rows to check for best type match"
							]),
						optional rowsToShow as (type number meta [
							Documentation.FieldCaption = "rowsToShow",
							Documentation.FieldDescription = "Show first n rows when asking for 1000"
							]),
						optional primitive as (type logical meta [
							Documentation.FieldCaption = "primitive",
							Documentation.FieldDescription = "Only primitive types"
							]),
						optional useOptimise as (type logical meta [
							Documentation.FieldCaption = "useOptimise",
							Documentation.FieldDescription = "Use Value.Optimize"
							])
					)
					as text meta
						[
							Documentation.Name = "Get.TableView",
							Documentation.Description = "Generates <code>Table.View</code> to trick model asking for evaluation",
							Documentation.LongDescription = "Generates <code>Table.View</code> to trick model asking for evaluation. Optional <code>precision</code> and <code>rowsToShow</code>.<p> <b>Skipping:</b> <i>Lists, Tables, Records, Binaries, Functions and Types</i>",
							Documentation.Category = "Model",
							Documentation.Author = "Spyros Mavroforos",
							Documentation.Source = "https://github.com/SpyrosMauro/powerquery",
							Documentation.Version = "1",
							Documentation.Examples = {
								[
									Description = "Generate table view of last step by infering type on 4 rows",
									Code = "
										let
											StartTable = Table.FromRecords({
												[start = #datetime(2020,7,1,0,0,0), diff = #duration(0,15,0,0), list = {1}],
												[start = #datetime(2020,7,1,5,0,0), diff = #duration(0,16,0,0), list = null],
												[start = #datetime(2020,7,1,8,0,0), diff = #duration(1,0,0,0), list = {4}],
												[start = #datetime(2020,7,1,16,0,0), diff = #duration(0,8,0,0), list = {3,4}]
											})
										in
											Get.TableView ( StartTable , ""StartTable"", 4 )"
										,
									Result = 
										"
											""= Table.View (
												null,
												[
													GetType = () =>
														type table [
															#""start"" = ( type datetime ),
															#""diff"" = ( type duration )
														],
													GetRows = () =>
														Table.RemoveColumns ( #""StartTable"", { ""list"" } , MissingField.Ignore ),
													OnTake = (count as number) =>
														if count = 0 then
															#table (
																type table [
																	#""start"" = ( type datetime ),
																	#""diff"" = ( type duration )
																],
																{}
															)
														else Table.FirstN ( Table.RemoveColumns ( #""StartTable"", { ""list"" } , MissingField.Ignore ), count )
												]
											)""
										"
								],
								[
									Description = "Generate table view of last step",
									Code = 
										"
											let
												StartTable = Table.FromRecords({
													[start = #datetime(2020,7,1,0,0,0), diff = #duration(0,15,0,0), list = {1}],
													[start = #datetime(2020,7,1,5,0,0), diff = #duration(0,16,0,0), list = null],
													[start = #datetime(2020,7,1,8,0,0), diff = #duration(1,0,0,0), list = {4}],
													[start = #datetime(2020,7,1,16,0,0), diff = #duration(0,8,0,0), list = {3,4}]
												})
											in
												Get.TableView ( StartTable , ""StartTable"")
										",
									Result = 
										"
											""= Table.View (
												null,
												[
													GetType = () =>
														type table [
															#""start"" = ( type any ),
															#""diff"" = ( type any ),
															#""list"" = ( type any )
														],
													GetRows = () =>
														#""StartTable"",
													OnTake = (count as number) =>
														if count = 0 then
															#table (
																type table [
																	#""start"" = ( type any ),
																	#""diff"" = ( type any ),
																	#""list"" = ( type any )
																],
																{}
															)
														else Table.FirstN ( #""StartTable"", count )
												]
											)""
										"
								]}
						]

			in
				Value.ReplaceType(GetTableViewFunction_, GetTableViewType)
		],
World  	   = [ //* ИНТЕРЕСНО https://github.com/alendaris/power-query/blob/main/functions/ISO-3166-1.pq
	WorldDataSet = // коды стран мира. Хорошие приемы: опциональные параметры -
		let
			defaultCountries = 
					#table(
					type table [
						#"Country Code (numeric)" = Int64.Type,
						#"Country Code" = Text.Type,
						#"Country Code (alpha3)" = Text.Type,
						#"Country Name" = Text.Type
					],
					{
						{"4", "AF", "AFG", "Afghanistan"},
						{"8", "AL", "ALB", "Albania"},
						{"12", "DZ", "DZA", "Algeria"},
						{"20", "AD", "AND", "Andorra"},
						{"24", "AO", "AGO", "Angola"},
						{"28", "AG", "ATG", "Antigua and Barbuda"},
						{"32", "AR", "ARG", "Argentina"},
						{"51", "AM", "ARM", "Armenia"},
						{"36", "AU", "AUS", "Australia"},
						{"40", "AT", "AUT", "Austria"},
						{"31", "AZ", "AZE", "Azerbaijan"},
						{"44", "BS", "BHS", "Bahamas"},
						{"48", "BH", "BHR", "Bahrain"},
						{"50", "BD", "BGD", "Bangladesh"},
						{"52", "BB", "BRB", "Barbados"},
						{"112", "BY", "BLR", "Belarus"},
						{"56", "BE", "BEL", "Belgium"},
						{"84", "BZ", "BLZ", "Belize"},
						{"204", "BJ", "BEN", "Benin"},
						{"64", "BT", "BTN", "Bhutan"},
						{"68", "BO", "BOL", "Bolivia (Plurinational State of)"},
						{"70", "BA", "BIH", "Bosnia and Herzegovina"},
						{"72", "BW", "BWA", "Botswana"},
						{"76", "BR", "BRA", "Brazil"},
						{"96", "BN", "BRN", "Brunei Darussalam"},
						{"100", "BG", "BGR", "Bulgaria"},
						{"854", "BF", "BFA", "Burkina Faso"},
						{"108", "BI", "BDI", "Burundi"},
						{"132", "CV", "CPV", "Cabo Verde"},
						{"116", "KH", "KHM", "Cambodia"},
						{"120", "CM", "CMR", "Cameroon"},
						{"124", "CA", "CAN", "Canada"},
						{"140", "CF", "CAF", "Central African Republic"},
						{"148", "TD", "TCD", "Chad"},
						{"152", "CL", "CHL", "Chile"},
						{"156", "CN", "CHN", "China"},
						{"170", "CO", "COL", "Colombia"},
						{"174", "KM", "COM", "Comoros"},
						{"178", "CG", "COG", "Congo"},
						{"180", "CD", "COD", "Congo, Democratic Republic of the"},
						{"188", "CR", "CRI", "Costa Rica"},
						{"384", "CI", "CIV", "Côte d'Ivoire"},
						{"191", "HR", "HRV", "Croatia"},
						{"192", "CU", "CUB", "Cuba"},
						{"196", "CY", "CYP", "Cyprus"},
						{"203", "CZ", "CZE", "Czechia"},
						{"208", "DK", "DNK", "Denmark"},
						{"262", "DJ", "DJI", "Djibouti"},
						{"212", "DM", "DMA", "Dominica"},
						{"214", "DO", "DOM", "Dominican Republic"},
						{"218", "EC", "ECU", "Ecuador"},
						{"818", "EG", "EGY", "Egypt"},
						{"222", "SV", "SLV", "El Salvador"},
						{"226", "GQ", "GNQ", "Equatorial Guinea"},
						{"232", "ER", "ERI", "Eritrea"},
						{"233", "EE", "EST", "Estonia"},
						{"748", "SZ", "SWZ", "Eswatini"},
						{"231", "ET", "ETH", "Ethiopia"},
						{"242", "FJ", "FJI", "Fiji"},
						{"246", "FI", "FIN", "Finland"},
						{"250", "FR", "FRA", "France"},
						{"266", "GA", "GAB", "Gabon"},
						{"270", "GM", "GMB", "Gambia"},
						{"268", "GE", "GEO", "Georgia"},
						{"276", "DE", "DEU", "Germany"},
						{"288", "GH", "GHA", "Ghana"},
						{"300", "GR", "GRC", "Greece"},
						{"308", "GD", "GRD", "Grenada"},
						{"320", "GT", "GTM", "Guatemala"},
						{"324", "GN", "GIN", "Guinea"},
						{"624", "GW", "GNB", "Guinea-Bissau"},
						{"328", "GY", "GUY", "Guyana"},
						{"332", "HT", "HTI", "Haiti"},
						{"340", "HN", "HND", "Honduras"},
						{"348", "HU", "HUN", "Hungary"},
						{"352", "IS", "ISL", "Iceland"},
						{"356", "IN", "IND", "India"},
						{"360", "ID", "IDN", "Indonesia"},
						{"364", "IR", "IRN", "Iran (Islamic Republic of)"},
						{"368", "IQ", "IRQ", "Iraq"},
						{"372", "IE", "IRL", "Ireland"},
						{"376", "IL", "ISR", "Israel"},
						{"380", "IT", "ITA", "Italy"},
						{"388", "JM", "JAM", "Jamaica"},
						{"392", "JP", "JPN", "Japan"},
						{"400", "JO", "JOR", "Jordan"},
						{"398", "KZ", "KAZ", "Kazakhstan"},
						{"404", "KE", "KEN", "Kenya"},
						{"296", "KI", "KIR", "Kiribati"},
						{"408", "KP", "PRK", "Korea (Democratic People's Republic of)"},
						{"410", "KR", "KOR", "Korea, Republic of"},
						{"414", "KW", "KWT", "Kuwait"},
						{"417", "KG", "KGZ", "Kyrgyzstan"},
						{"418", "LA", "LAO", "Lao People's Democratic Republic"},
						{"428", "LV", "LVA", "Latvia"},
						{"422", "LB", "LBN", "Lebanon"},
						{"426", "LS", "LSO", "Lesotho"},
						{"430", "LR", "LBR", "Liberia"},
						{"434", "LY", "LBY", "Libya"},
						{"438", "LI", "LIE", "Liechtenstein"},
						{"440", "LT", "LTU", "Lithuania"},
						{"442", "LU", "LUX", "Luxembourg"},
						{"450", "MG", "MDG", "Madagascar"},
						{"454", "MW", "MWI", "Malawi"},
						{"458", "MY", "MYS", "Malaysia"},
						{"462", "MV", "MDV", "Maldives"},
						{"466", "ML", "MLI", "Mali"},
						{"470", "MT", "MLT", "Malta"},
						{"584", "MH", "MHL", "Marshall Islands"},
						{"478", "MR", "MRT", "Mauritania"},
						{"480", "MU", "MUS", "Mauritius"},
						{"484", "MX", "MEX", "Mexico"},
						{"583", "FM", "FSM", "Micronesia (Federated States of)"},
						{"498", "MD", "MDA", "Moldova, Republic of"},
						{"492", "MC", "MCO", "Monaco"},
						{"496", "MN", "MNG", "Mongolia"},
						{"499", "ME", "MNE", "Montenegro"},
						{"504", "MA", "MAR", "Morocco"},
						{"508", "MZ", "MOZ", "Mozambique"},
						{"104", "MM", "MMR", "Myanmar"},
						{"516", "NA", "NAM", "Namibia"},
						{"520", "NR", "NRU", "Nauru"},
						{"524", "NP", "NPL", "Nepal"},
						{"528", "NL", "NLD", "Netherlands"},
						{"554", "NZ", "NZL", "New Zealand"},
						{"558", "NI", "NIC", "Nicaragua"},
						{"562", "NE", "NER", "Niger"},
						{"566", "NG", "NGA", "Nigeria"},
						{"807", "MK", "MKD", "North Macedonia"},
						{"578", "NO", "NOR", "Norway"},
						{"512", "OM", "OMN", "Oman"},
						{"586", "PK", "PAK", "Pakistan"},
						{"585", "PW", "PLW", "Palau"},
						{"591", "PA", "PAN", "Panama"},
						{"598", "PG", "PNG", "Papua New Guinea"},
						{"600", "PY", "PRY", "Paraguay"},
						{"604", "PE", "PER", "Peru"},
						{"608", "PH", "PHL", "Philippines"},
						{"616", "PL", "POL", "Poland"},
						{"620", "PT", "PRT", "Portugal"},
						{"634", "QA", "QAT", "Qatar"},
						{"642", "RO", "ROU", "Romania"},
						{"643", "RU", "RUS", "Russian Federation"},
						{"646", "RW", "RWA", "Rwanda"},
						{"659", "KN", "KNA", "Saint Kitts and Nevis"},
						{"662", "LC", "LCA", "Saint Lucia"},
						{"670", "VC", "VCT", "Saint Vincent and the Grenadines"},
						{"882", "WS", "WSM", "Samoa"},
						{"674", "SM", "SMR", "San Marino"},
						{"678", "ST", "STP", "Sao Tome and Principe"},
						{"682", "SA", "SAU", "Saudi Arabia"},
						{"686", "SN", "SEN", "Senegal"},
						{"688", "RS", "SRB", "Serbia"},
						{"690", "SC", "SYC", "Seychelles"},
						{"694", "SL", "SLE", "Sierra Leone"},
						{"702", "SG", "SGP", "Singapore"},
						{"703", "SK", "SVK", "Slovakia"},
						{"705", "SI", "SVN", "Slovenia"},
						{"90", "SB", "SLB", "Solomon Islands"},
						{"706", "SO", "SOM", "Somalia"},
						{"710", "ZA", "ZAF", "South Africa"},
						{"728", "SS", "SSD", "South Sudan"},
						{"724", "ES", "ESP", "Spain"},
						{"144", "LK", "LKA", "Sri Lanka"},
						{"729", "SD", "SDN", "Sudan"},
						{"740", "SR", "SUR", "Suriname"},
						{"752", "SE", "SWE", "Sweden"},
						{"756", "CH", "CHE", "Switzerland"},
						{"760", "SY", "SYR", "Syrian Arab Republic"},
						{"762", "TJ", "TJK", "Tajikistan"},
						{"834", "TZ", "TZA", "Tanzania, United Republic of"},
						{"764", "TH", "THA", "Thailand"},
						{"626", "TL", "TLS", "Timor-Leste"},
						{"768", "TG", "TGO", "Togo"},
						{"776", "TO", "TON", "Tonga"},
						{"780", "TT", "TTO", "Trinidad and Tobago"},
						{"788", "TN", "TUN", "Tunisia"},
						{"792", "TR", "TUR", "Türkiye"},
						{"795", "TM", "TKM", "Turkmenistan"},
						{"798", "TV", "TUV", "Tuvalu"},
						{"800", "UG", "UGA", "Uganda"},
						{"804", "UA", "UKR", "Ukraine"},
						{"784", "AE", "ARE", "United Arab Emirates"},
						{"826", "GB", "GBR", "United Kingdom of Great Britain and Northern Ireland"},
						{"840", "US", "USA", "United States of America"},
						{"858", "UY", "URY", "Uruguay"},
						{"860", "UZ", "UZB", "Uzbekistan"},
						{"548", "VU", "VUT", "Vanuatu"},
						{"862", "VE", "VEN", "Venezuela (Bolivarian Republic of)"},
						{"704", "VN", "VNM", "Viet Nam"},
						{"887", "YE", "YEM", "Yemen"},
						{"894", "ZM", "ZMB", "Zambia"},
						{"716", "ZW", "ZWE", "Zimbabwe"}
					}
				),
			additionalDefaultCountries = 
				#table(
					type table [
						#"Country Code" = Text.Type,
						#"Country Code (alpha3)" = Text.Type,
						#"Country Name" = Text.Type,
						#"Country Code (numeric)" = Int64.Type
					],
					{
						{"AS", "ASM", "American Samoa", 16},
						{"AI", "AIA", "Anguilla", 660},
						{"AQ", "ATA", "Antarctica", 10},
						{"AW", "ABW", "Aruba", 533},
						{"BM", "BMU", "Bermuda", 60},
						{"BQ", "BES", "Bonaire, Sint Eustatius and Saba", 535},
						{"BV", "BVT", "Bouvet Island", 74},
						{"IO", "IOT", "British Indian Ocean Territory", 86},
						{"VG", "VGB", "British Virgin Islands", 92},
						{"KY", "CYM", "Cayman Islands", 136},
						{"HK", "HKG", "China, Hong Kong Special Administrative Region", 344},
						{"MO", "MAC", "China, Macao Special Administrative Region", 446},
						{"CX", "CXR", "Christmas Island", 162},
						{"CC", "CCK", "Cocos (Keeling) Islands", 166},
						{"CK", "COK", "Cook Islands", 184},
						{"CW", "CUW", "Curaçao", 531},
						{"FK", "FLK", "Falkland Islands (Malvinas)", 238},
						{"FO", "FRO", "Faroe Islands", 234},
						{"GF", "GUF", "French Guiana", 254},
						{"PF", "PYF", "French Polynesia", 258},
						{"TF", "ATF", "French Southern Territories", 260},
						{"GI", "GIB", "Gibraltar", 292},
						{"GL", "GRL", "Greenland", 304},
						{"GP", "GLP", "Guadeloupe", 312},
						{"GU", "GUM", "Guam", 316},
						{"GG", "GGY", "Guernsey", 831},
						{"HM", "HMD", "Heard Island and McDonald Islands", 334},
						{"VA", "VAT", "Holy See", 336},
						{"IM", "IMN", "Isle of Man", 833},
						{"JE", "JEY", "Jersey", 832},
						{"MQ", "MTQ", "Martinique", 474},
						{"YT", "MYT", "Mayotte", 175},
						{"MS", "MSR", "Montserrat", 500},
						{"NC", "NCL", "New Caledonia", 540},
						{"NU", "NIU", "Niue", 570},
						{"NF", "NFK", "Norfolk Island", 574},
						{"MP", "MNP", "Northern Mariana Islands", 580},
						{"PN", "PCN", "Pitcairn", 612},
						{"PR", "PRI", "Puerto Rico", 630},
						{"RE", "REU", "Réunion", 638},
						{"BL", "BLM", "Saint Barthélemy", 652},
						{"SH", "SHN", "Saint Helena", 654},
						{"MF", "MAF", "Saint Martin (French Part)", 663},
						{"PM", "SPM", "Saint Pierre and Miquelon", 666},
						{"CQ", "CRQ", "Sark", 680},
						{"SX", "SXM", "Sint Maarten (Dutch part)", 534},
						{"GS", "SGS", "South Georgia and the South Sandwich Islands", 239},
						{"PS", "PSE", "State of Palestine", 275},
						{"SJ", "SJM", "Svalbard and Jan Mayen Islands", 744},
						{"TK", "TKL", "Tokelau", 772},
						{"TC", "TCA", "Turks and Caicos Islands", 796},
						{"UM", "UMI", "United States Minor Outlying Islands", 581},
						{"VI", "VIR", "United States Virgin Islands", 850},
						{"WF", "WLF", "Wallis and Futuna Islands", 876},
						{"EH", "ESH", "Western Sahara", 732},
						{"AX", "ALA", "Åland Islands", 248}
					}
				) meta [
					QueryFolding = [
							IsFolded = false,
							HasNativeQuery = false,
							Kind = "",
							Path = ""
						]
				],
			defaultPossibleNames = 
				#table(
					type table [#"Country Code" = Text.Type, #"Possible Name" = Text.Type],
					{
						{"AF", "4"},
						{"AF", "AFG"},
						{"AF", "Afghanistan"},
						{"AF", "AF"},
						{"AL", "8"},
						{"AL", "ALB"},
						{"AL", "Albania"},
						{"AL", "AL"},
						{"DZ", "12"},
						{"DZ", "DZA"},
						{"DZ", "Algeria"},
						{"DZ", "DZ"},
						{"AD", "20"},
						{"AD", "AND"},
						{"AD", "Andorra"},
						{"AD", "AD"},
						{"AO", "24"},
						{"AO", "AGO"},
						{"AO", "Angola"},
						{"AO", "AO"},
						{"AG", "28"},
						{"AG", "ATG"},
						{"AG", "Antigua and Barbuda"},
						{"AG", "AG"},
						{"AR", "32"},
						{"AR", "ARG"},
						{"AR", "Argentina"},
						{"AR", "AR"},
						{"AM", "51"},
						{"AM", "ARM"},
						{"AM", "Armenia"},
						{"AM", "AM"},
						{"AU", "36"},
						{"AU", "AUS"},
						{"AU", "Australia"},
						{"AU", "AU"},
						{"AT", "40"},
						{"AT", "AUT"},
						{"AT", "Austria"},
						{"AT", "AT"},
						{"AZ", "31"},
						{"AZ", "AZE"},
						{"AZ", "Azerbaijan"},
						{"AZ", "AZ"},
						{"BS", "44"},
						{"BS", "BHS"},
						{"BS", "Bahamas"},
						{"BS", "BS"},
						{"BH", "48"},
						{"BH", "BHR"},
						{"BH", "Bahrain"},
						{"BH", "BH"},
						{"BD", "50"},
						{"BD", "BGD"},
						{"BD", "Bangladesh"},
						{"BD", "BD"},
						{"BB", "52"},
						{"BB", "BRB"},
						{"BB", "Barbados"},
						{"BB", "BB"},
						{"BY", "112"},
						{"BY", "BLR"},
						{"BY", "Belarus"},
						{"BY", "BY"},
						{"BE", "56"},
						{"BE", "BEL"},
						{"BE", "Belgium"},
						{"BE", "BE"},
						{"BZ", "84"},
						{"BZ", "BLZ"},
						{"BZ", "Belize"},
						{"BZ", "BZ"},
						{"BJ", "204"},
						{"BJ", "BEN"},
						{"BJ", "Benin"},
						{"BJ", "BJ"},
						{"BT", "64"},
						{"BT", "BTN"},
						{"BT", "Bhutan"},
						{"BT", "BT"},
						{"BO", "68"},
						{"BO", "BOL"},
						{"BO", "Bolivia (Plurinational State of)"},
						{"BO", "BO"},
						{"BA", "70"},
						{"BA", "BIH"},
						{"BA", "Bosnia and Herzegovina"},
						{"BA", "BA"},
						{"BW", "72"},
						{"BW", "BWA"},
						{"BW", "Botswana"},
						{"BW", "BW"},
						{"BR", "76"},
						{"BR", "BRA"},
						{"BR", "Brazil"},
						{"BR", "BR"},
						{"BN", "96"},
						{"BN", "BRN"},
						{"BN", "Brunei Darussalam"},
						{"BN", "BN"},
						{"BG", "100"},
						{"BG", "BGR"},
						{"BG", "Bulgaria"},
						{"BG", "BG"},
						{"BF", "854"},
						{"BF", "BFA"},
						{"BF", "Burkina Faso"},
						{"BF", "BF"},
						{"BI", "108"},
						{"BI", "BDI"},
						{"BI", "Burundi"},
						{"BI", "BI"},
						{"CV", "132"},
						{"CV", "CPV"},
						{"CV", "Cabo Verde"},
						{"CV", "CV"},
						{"KH", "116"},
						{"KH", "KHM"},
						{"KH", "Cambodia"},
						{"KH", "KH"},
						{"CM", "120"},
						{"CM", "CMR"},
						{"CM", "Cameroon"},
						{"CM", "CM"},
						{"CA", "124"},
						{"CA", "CAN"},
						{"CA", "Canada"},
						{"CA", "CA"},
						{"CF", "140"},
						{"CF", "CAF"},
						{"CF", "Central African Republic"},
						{"CF", "CF"},
						{"TD", "148"},
						{"TD", "TCD"},
						{"TD", "Chad"},
						{"TD", "TD"},
						{"CL", "152"},
						{"CL", "CHL"},
						{"CL", "Chile"},
						{"CL", "CL"},
						{"CN", "156"},
						{"CN", "CHN"},
						{"CN", "China"},
						{"CN", "CN"},
						{"CO", "170"},
						{"CO", "COL"},
						{"CO", "Colombia"},
						{"CO", "CO"},
						{"KM", "174"},
						{"KM", "COM"},
						{"KM", "Comoros"},
						{"KM", "KM"},
						{"CG", "178"},
						{"CG", "COG"},
						{"CG", "Congo"},
						{"CG", "CG"},
						{"CD", "180"},
						{"CD", "COD"},
						{"CD", "Congo, Democratic Republic of the"},
						{"CD", "CD"},
						{"CR", "188"},
						{"CR", "CRI"},
						{"CR", "Costa Rica"},
						{"CR", "CR"},
						{"CI", "384"},
						{"CI", "CIV"},
						{"CI", "Côte d'Ivoire"},
						{"CI", "CI"},
						{"HR", "191"},
						{"HR", "HRV"},
						{"HR", "Croatia"},
						{"HR", "HR"},
						{"CU", "192"},
						{"CU", "CUB"},
						{"CU", "Cuba"},
						{"CU", "CU"},
						{"CY", "196"},
						{"CY", "CYP"},
						{"CY", "Cyprus"},
						{"CY", "CY"},
						{"CZ", "203"},
						{"CZ", "CZE"},
						{"CZ", "Czechia"},
						{"CZ", "CZ"},
						{"DK", "208"},
						{"DK", "DNK"},
						{"DK", "Denmark"},
						{"DK", "DK"},
						{"DJ", "262"},
						{"DJ", "DJI"},
						{"DJ", "Djibouti"},
						{"DJ", "DJ"},
						{"DM", "212"},
						{"DM", "DMA"},
						{"DM", "Dominica"},
						{"DM", "DM"},
						{"DO", "214"},
						{"DO", "DOM"},
						{"DO", "Dominican Republic"},
						{"DO", "DO"},
						{"EC", "218"},
						{"EC", "ECU"},
						{"EC", "Ecuador"},
						{"EC", "EC"},
						{"EG", "818"},
						{"EG", "EGY"},
						{"EG", "Egypt"},
						{"EG", "EG"},
						{"SV", "222"},
						{"SV", "SLV"},
						{"SV", "El Salvador"},
						{"SV", "SV"},
						{"GQ", "226"},
						{"GQ", "GNQ"},
						{"GQ", "Equatorial Guinea"},
						{"GQ", "GQ"},
						{"ER", "232"},
						{"ER", "ERI"},
						{"ER", "Eritrea"},
						{"ER", "ER"},
						{"EE", "233"},
						{"EE", "EST"},
						{"EE", "Estonia"},
						{"EE", "EE"},
						{"SZ", "748"},
						{"SZ", "SWZ"},
						{"SZ", "Eswatini"},
						{"SZ", "SZ"},
						{"ET", "231"},
						{"ET", "ETH"},
						{"ET", "Ethiopia"},
						{"ET", "ET"},
						{"FJ", "242"},
						{"FJ", "FJI"},
						{"FJ", "Fiji"},
						{"FJ", "FJ"},
						{"FI", "246"},
						{"FI", "FIN"},
						{"FI", "Finland"},
						{"FI", "FI"},
						{"FR", "250"},
						{"FR", "FRA"},
						{"FR", "France"},
						{"FR", "FR"},
						{"GA", "266"},
						{"GA", "GAB"},
						{"GA", "Gabon"},
						{"GA", "GA"},
						{"GM", "270"},
						{"GM", "GMB"},
						{"GM", "Gambia"},
						{"GM", "GM"},
						{"GE", "268"},
						{"GE", "GEO"},
						{"GE", "Georgia"},
						{"GE", "GE"},
						{"DE", "276"},
						{"DE", "DEU"},
						{"DE", "Germany"},
						{"DE", "DE"},
						{"GH", "288"},
						{"GH", "GHA"},
						{"GH", "Ghana"},
						{"GH", "GH"},
						{"GR", "300"},
						{"GR", "GRC"},
						{"GR", "Greece"},
						{"GR", "GR"},
						{"GD", "308"},
						{"GD", "GRD"},
						{"GD", "Grenada"},
						{"GD", "GD"},
						{"GT", "320"},
						{"GT", "GTM"},
						{"GT", "Guatemala"},
						{"GT", "GT"},
						{"GN", "324"},
						{"GN", "GIN"},
						{"GN", "Guinea"},
						{"GN", "GN"},
						{"GW", "624"},
						{"GW", "GNB"},
						{"GW", "Guinea-Bissau"},
						{"GW", "GW"},
						{"GY", "328"},
						{"GY", "GUY"},
						{"GY", "Guyana"},
						{"GY", "GY"},
						{"HT", "332"},
						{"HT", "HTI"},
						{"HT", "Haiti"},
						{"HT", "HT"},
						{"HN", "340"},
						{"HN", "HND"},
						{"HN", "Honduras"},
						{"HN", "HN"},
						{"HU", "348"},
						{"HU", "HUN"},
						{"HU", "Hungary"},
						{"HU", "HU"},
						{"IS", "352"},
						{"IS", "ISL"},
						{"IS", "Iceland"},
						{"IS", "IS"},
						{"IN", "356"},
						{"IN", "IND"},
						{"IN", "India"},
						{"IN", "IN"},
						{"ID", "360"},
						{"ID", "IDN"},
						{"ID", "Indonesia"},
						{"ID", "ID"},
						{"IR", "364"},
						{"IR", "IRN"},
						{"IR", "Iran (Islamic Republic of)"},
						{"IR", "IR"},
						{"IQ", "368"},
						{"IQ", "IRQ"},
						{"IQ", "Iraq"},
						{"IQ", "IQ"},
						{"IE", "372"},
						{"IE", "IRL"},
						{"IE", "Ireland"},
						{"IE", "IE"},
						{"IL", "376"},
						{"IL", "ISR"},
						{"IL", "Israel"},
						{"IL", "IL"},
						{"IT", "380"},
						{"IT", "ITA"},
						{"IT", "Italy"},
						{"IT", "IT"},
						{"JM", "388"},
						{"JM", "JAM"},
						{"JM", "Jamaica"},
						{"JM", "JM"},
						{"JP", "392"},
						{"JP", "JPN"},
						{"JP", "Japan"},
						{"JP", "JP"},
						{"JO", "400"},
						{"JO", "JOR"},
						{"JO", "Jordan"},
						{"JO", "JO"},
						{"KZ", "398"},
						{"KZ", "KAZ"},
						{"KZ", "Kazakhstan"},
						{"KZ", "KZ"},
						{"KE", "404"},
						{"KE", "KEN"},
						{"KE", "Kenya"},
						{"KE", "KE"},
						{"KI", "296"},
						{"KI", "KIR"},
						{"KI", "Kiribati"},
						{"KI", "KI"},
						{"KP", "408"},
						{"KP", "PRK"},
						{"KP", "Korea (Democratic People's Republic of)"},
						{"KP", "KP"},
						{"KR", "410"},
						{"KR", "KOR"},
						{"KR", "Korea, Republic of"},
						{"KR", "KR"},
						{"KW", "414"},
						{"KW", "KWT"},
						{"KW", "Kuwait"},
						{"KW", "KW"},
						{"KG", "417"},
						{"KG", "KGZ"},
						{"KG", "Kyrgyzstan"},
						{"KG", "KG"},
						{"LA", "418"},
						{"LA", "LAO"},
						{"LA", "Lao People's Democratic Republic"},
						{"LA", "LA"},
						{"LV", "428"},
						{"LV", "LVA"},
						{"LV", "Latvia"},
						{"LV", "LV"},
						{"LB", "422"},
						{"LB", "LBN"},
						{"LB", "Lebanon"},
						{"LB", "LB"},
						{"LS", "426"},
						{"LS", "LSO"},
						{"LS", "Lesotho"},
						{"LS", "LS"},
						{"LR", "430"},
						{"LR", "LBR"},
						{"LR", "Liberia"},
						{"LR", "LR"},
						{"LY", "434"},
						{"LY", "LBY"},
						{"LY", "Libya"},
						{"LY", "LY"},
						{"LI", "438"},
						{"LI", "LIE"},
						{"LI", "Liechtenstein"},
						{"LI", "LI"},
						{"LT", "440"},
						{"LT", "LTU"},
						{"LT", "Lithuania"},
						{"LT", "LT"},
						{"LU", "442"},
						{"LU", "LUX"},
						{"LU", "Luxembourg"},
						{"LU", "LU"},
						{"MG", "450"},
						{"MG", "MDG"},
						{"MG", "Madagascar"},
						{"MG", "MG"},
						{"MW", "454"},
						{"MW", "MWI"},
						{"MW", "Malawi"},
						{"MW", "MW"},
						{"MY", "458"},
						{"MY", "MYS"},
						{"MY", "Malaysia"},
						{"MY", "MY"},
						{"MV", "462"},
						{"MV", "MDV"},
						{"MV", "Maldives"},
						{"MV", "MV"},
						{"ML", "466"},
						{"ML", "MLI"},
						{"ML", "Mali"},
						{"ML", "ML"},
						{"MT", "470"},
						{"MT", "MLT"},
						{"MT", "Malta"},
						{"MT", "MT"},
						{"MH", "584"},
						{"MH", "MHL"},
						{"MH", "Marshall Islands"},
						{"MH", "MH"},
						{"MR", "478"},
						{"MR", "MRT"},
						{"MR", "Mauritania"},
						{"MR", "MR"},
						{"MU", "480"},
						{"MU", "MUS"},
						{"MU", "Mauritius"},
						{"MU", "MU"},
						{"MX", "484"},
						{"MX", "MEX"},
						{"MX", "Mexico"},
						{"MX", "MX"},
						{"FM", "583"},
						{"FM", "FSM"},
						{"FM", "Micronesia (Federated States of)"},
						{"FM", "FM"},
						{"MD", "498"},
						{"MD", "MDA"},
						{"MD", "Moldova, Republic of"},
						{"MD", "MD"},
						{"MC", "492"},
						{"MC", "MCO"},
						{"MC", "Monaco"},
						{"MC", "MC"},
						{"MN", "496"},
						{"MN", "MNG"},
						{"MN", "Mongolia"},
						{"MN", "MN"},
						{"ME", "499"},
						{"ME", "MNE"},
						{"ME", "Montenegro"},
						{"ME", "ME"},
						{"MA", "504"},
						{"MA", "MAR"},
						{"MA", "Morocco"},
						{"MA", "MA"},
						{"MZ", "508"},
						{"MZ", "MOZ"},
						{"MZ", "Mozambique"},
						{"MZ", "MZ"},
						{"MM", "104"},
						{"MM", "MMR"},
						{"MM", "Myanmar"},
						{"MM", "MM"},
						{"NA", "516"},
						{"NA", "NAM"},
						{"NA", "Namibia"},
						{"NA", "NA"},
						{"NR", "520"},
						{"NR", "NRU"},
						{"NR", "Nauru"},
						{"NR", "NR"},
						{"NP", "524"},
						{"NP", "NPL"},
						{"NP", "Nepal"},
						{"NP", "NP"},
						{"NL", "528"},
						{"NL", "NLD"},
						{"NL", "Netherlands"},
						{"NL", "NL"},
						{"NZ", "554"},
						{"NZ", "NZL"},
						{"NZ", "New Zealand"},
						{"NZ", "NZ"},
						{"NI", "558"},
						{"NI", "NIC"},
						{"NI", "Nicaragua"},
						{"NI", "NI"},
						{"NE", "562"},
						{"NE", "NER"},
						{"NE", "Niger"},
						{"NE", "NE"},
						{"NG", "566"},
						{"NG", "NGA"},
						{"NG", "Nigeria"},
						{"NG", "NG"},
						{"MK", "807"},
						{"MK", "MKD"},
						{"MK", "North Macedonia"},
						{"MK", "MK"},
						{"NO", "578"},
						{"NO", "NOR"},
						{"NO", "Norway"},
						{"NO", "NO"},
						{"OM", "512"},
						{"OM", "OMN"},
						{"OM", "Oman"},
						{"OM", "OM"},
						{"PK", "586"},
						{"PK", "PAK"},
						{"PK", "Pakistan"},
						{"PK", "PK"},
						{"PW", "585"},
						{"PW", "PLW"},
						{"PW", "Palau"},
						{"PW", "PW"},
						{"PA", "591"},
						{"PA", "PAN"},
						{"PA", "Panama"},
						{"PA", "PA"},
						{"PG", "598"},
						{"PG", "PNG"},
						{"PG", "Papua New Guinea"},
						{"PG", "PG"},
						{"PY", "600"},
						{"PY", "PRY"},
						{"PY", "Paraguay"},
						{"PY", "PY"},
						{"PE", "604"},
						{"PE", "PER"},
						{"PE", "Peru"},
						{"PE", "PE"},
						{"PH", "608"},
						{"PH", "PHL"},
						{"PH", "Philippines"},
						{"PH", "PH"},
						{"PL", "616"},
						{"PL", "POL"},
						{"PL", "Poland"},
						{"PL", "PL"},
						{"PT", "620"},
						{"PT", "PRT"},
						{"PT", "Portugal"},
						{"PT", "PT"},
						{"QA", "634"},
						{"QA", "QAT"},
						{"QA", "Qatar"},
						{"QA", "QA"},
						{"RO", "642"},
						{"RO", "ROU"},
						{"RO", "Romania"},
						{"RO", "RO"},
						{"RU", "643"},
						{"RU", "RUS"},
						{"RU", "Russian Federation"},
						{"RU", "RU"},
						{"RW", "646"},
						{"RW", "RWA"},
						{"RW", "Rwanda"},
						{"RW", "RW"},
						{"KN", "659"},
						{"KN", "KNA"},
						{"KN", "Saint Kitts and Nevis"},
						{"KN", "KN"},
						{"LC", "662"},
						{"LC", "LCA"},
						{"LC", "Saint Lucia"},
						{"LC", "LC"},
						{"VC", "670"},
						{"VC", "VCT"},
						{"VC", "Saint Vincent and the Grenadines"},
						{"VC", "VC"},
						{"WS", "882"},
						{"WS", "WSM"},
						{"WS", "Samoa"},
						{"WS", "WS"},
						{"SM", "674"},
						{"SM", "SMR"},
						{"SM", "San Marino"},
						{"SM", "SM"},
						{"ST", "678"},
						{"ST", "STP"},
						{"ST", "Sao Tome and Principe"},
						{"ST", "ST"},
						{"SA", "682"},
						{"SA", "SAU"},
						{"SA", "Saudi Arabia"},
						{"SA", "SA"},
						{"SN", "686"},
						{"SN", "SEN"},
						{"SN", "Senegal"},
						{"SN", "SN"},
						{"RS", "688"},
						{"RS", "SRB"},
						{"RS", "Serbia"},
						{"RS", "RS"},
						{"SC", "690"},
						{"SC", "SYC"},
						{"SC", "Seychelles"},
						{"SC", "SC"},
						{"SL", "694"},
						{"SL", "SLE"},
						{"SL", "Sierra Leone"},
						{"SL", "SL"},
						{"SG", "702"},
						{"SG", "SGP"},
						{"SG", "Singapore"},
						{"SG", "SG"},
						{"SK", "703"},
						{"SK", "SVK"},
						{"SK", "Slovakia"},
						{"SK", "SK"},
						{"SI", "705"},
						{"SI", "SVN"},
						{"SI", "Slovenia"},
						{"SI", "SI"},
						{"SB", "90"},
						{"SB", "SLB"},
						{"SB", "Solomon Islands"},
						{"SB", "SB"},
						{"SO", "706"},
						{"SO", "SOM"},
						{"SO", "Somalia"},
						{"SO", "SO"},
						{"ZA", "710"},
						{"ZA", "ZAF"},
						{"ZA", "South Africa"},
						{"ZA", "ZA"},
						{"SS", "728"},
						{"SS", "SSD"},
						{"SS", "South Sudan"},
						{"SS", "SS"},
						{"ES", "724"},
						{"ES", "ESP"},
						{"ES", "Spain"},
						{"ES", "ES"},
						{"LK", "144"},
						{"LK", "LKA"},
						{"LK", "Sri Lanka"},
						{"LK", "LK"},
						{"SD", "729"},
						{"SD", "SDN"},
						{"SD", "Sudan"},
						{"SD", "SD"},
						{"SR", "740"},
						{"SR", "SUR"},
						{"SR", "Suriname"},
						{"SR", "SR"},
						{"SE", "752"},
						{"SE", "SWE"},
						{"SE", "Sweden"},
						{"SE", "SE"},
						{"CH", "756"},
						{"CH", "CHE"},
						{"CH", "Switzerland"},
						{"CH", "CH"},
						{"SY", "760"},
						{"SY", "SYR"},
						{"SY", "Syrian Arab Republic"},
						{"SY", "SY"},
						{"TJ", "762"},
						{"TJ", "TJK"},
						{"TJ", "Tajikistan"},
						{"TJ", "TJ"},
						{"TZ", "834"},
						{"TZ", "TZA"},
						{"TZ", "Tanzania, United Republic of"},
						{"TZ", "TZ"},
						{"TH", "764"},
						{"TH", "THA"},
						{"TH", "Thailand"},
						{"TH", "TH"},
						{"TL", "626"},
						{"TL", "TLS"},
						{"TL", "Timor-Leste"},
						{"TL", "TL"},
						{"TG", "768"},
						{"TG", "TGO"},
						{"TG", "Togo"},
						{"TG", "TG"},
						{"TO", "776"},
						{"TO", "TON"},
						{"TO", "Tonga"},
						{"TO", "TO"},
						{"TT", "780"},
						{"TT", "TTO"},
						{"TT", "Trinidad and Tobago"},
						{"TT", "TT"},
						{"TN", "788"},
						{"TN", "TUN"},
						{"TN", "Tunisia"},
						{"TN", "TN"},
						{"TR", "792"},
						{"TR", "TUR"},
						{"TR", "Türkiye"},
						{"TR", "TR"},
						{"TM", "795"},
						{"TM", "TKM"},
						{"TM", "Turkmenistan"},
						{"TM", "TM"},
						{"TV", "798"},
						{"TV", "TUV"},
						{"TV", "Tuvalu"},
						{"TV", "TV"},
						{"UG", "800"},
						{"UG", "UGA"},
						{"UG", "Uganda"},
						{"UG", "UG"},
						{"UA", "804"},
						{"UA", "UKR"},
						{"UA", "Ukraine"},
						{"UA", "UA"},
						{"AE", "784"},
						{"AE", "ARE"},
						{"AE", "United Arab Emirates"},
						{"AE", "AE"},
						{"GB", "826"},
						{"GB", "GBR"},
						{"GB", "United Kingdom of Great Britain and Northern Ireland"},
						{"GB", "GB"},
						{"GB", "United Kingdom"},
						{"GB", "Great Britain"},
						{"GB", "UK"},
						{"US", "840"},
						{"US", "USA"},
						{"US", "United States of America"},
						{"US", "US"},
						{"UY", "858"},
						{"UY", "URY"},
						{"UY", "Uruguay"},
						{"UY", "UY"},
						{"UZ", "860"},
						{"UZ", "UZB"},
						{"UZ", "Uzbekistan"},
						{"UZ", "UZ"},
						{"VU", "548"},
						{"VU", "VUT"},
						{"VU", "Vanuatu"},
						{"VU", "VU"},
						{"VE", "862"},
						{"VE", "VEN"},
						{"VE", "Venezuela (Bolivarian Republic of)"},
						{"VE", "VE"},
						{"VN", "704"},
						{"VN", "VNM"},
						{"VN", "Viet Nam"},
						{"VN", "VN"},
						{"YE", "887"},
						{"YE", "YEM"},
						{"YE", "Yemen"},
						{"YE", "YE"},
						{"ZM", "894"},
						{"ZM", "ZMB"},
						{"ZM", "Zambia"},
						{"ZM", "ZM"},
						{"ZW", "716"},
						{"ZW", "ZWE"},
						{"ZW", "Zimbabwe"},
						{"ZW", "ZW"}
					}
				),
			defaultContinents =
				#table(
					type table [
						#"Global Code" = Int64.Type,
						#"Global Name" = Text.Type,
						#"Region Code" = Int64.Type,
						#"Region Name" = Text.Type,
						#"Sub-region Code" = Int64.Type,
						#"Sub-region Name" = Text.Type,
						#"Intermediate Region Code" = Int64.Type,
						#"Intermediate Region Name" = Text.Type,
						#"ISO-alpha2 Code" = Text.Type
					],
					{
						{1, "World", 2, "Africa", 15, "Northern Africa", null, "", "DZ"},
						{1, "World", 2, "Africa", 15, "Northern Africa", null, "", "EG"},
						{1, "World", 2, "Africa", 15, "Northern Africa", null, "", "LY"},
						{1, "World", 2, "Africa", 15, "Northern Africa", null, "", "MA"},
						{1, "World", 2, "Africa", 15, "Northern Africa", null, "", "SD"},
						{1, "World", 2, "Africa", 15, "Northern Africa", null, "", "TN"},
						{1, "World", 2, "Africa", 15, "Northern Africa", null, "", "EH"},
						{1, "World", 2, "Africa", 202, "Sub-Saharan Africa", 14, "Eastern Africa", "IO"},
						{1, "World", 2, "Africa", 202, "Sub-Saharan Africa", 14, "Eastern Africa", "BI"},
						{1, "World", 2, "Africa", 202, "Sub-Saharan Africa", 14, "Eastern Africa", "KM"},
						{1, "World", 2, "Africa", 202, "Sub-Saharan Africa", 14, "Eastern Africa", "DJ"},
						{1, "World", 2, "Africa", 202, "Sub-Saharan Africa", 14, "Eastern Africa", "ER"},
						{1, "World", 2, "Africa", 202, "Sub-Saharan Africa", 14, "Eastern Africa", "ET"},
						{1, "World", 2, "Africa", 202, "Sub-Saharan Africa", 14, "Eastern Africa", "TF"},
						{1, "World", 2, "Africa", 202, "Sub-Saharan Africa", 14, "Eastern Africa", "KE"},
						{1, "World", 2, "Africa", 202, "Sub-Saharan Africa", 14, "Eastern Africa", "MG"},
						{1, "World", 2, "Africa", 202, "Sub-Saharan Africa", 14, "Eastern Africa", "MW"},
						{1, "World", 2, "Africa", 202, "Sub-Saharan Africa", 14, "Eastern Africa", "MU"},
						{1, "World", 2, "Africa", 202, "Sub-Saharan Africa", 14, "Eastern Africa", "YT"},
						{1, "World", 2, "Africa", 202, "Sub-Saharan Africa", 14, "Eastern Africa", "MZ"},
						{1, "World", 2, "Africa", 202, "Sub-Saharan Africa", 14, "Eastern Africa", "RE"},
						{1, "World", 2, "Africa", 202, "Sub-Saharan Africa", 14, "Eastern Africa", "RW"},
						{1, "World", 2, "Africa", 202, "Sub-Saharan Africa", 14, "Eastern Africa", "SC"},
						{1, "World", 2, "Africa", 202, "Sub-Saharan Africa", 14, "Eastern Africa", "SO"},
						{1, "World", 2, "Africa", 202, "Sub-Saharan Africa", 14, "Eastern Africa", "SS"},
						{1, "World", 2, "Africa", 202, "Sub-Saharan Africa", 14, "Eastern Africa", "UG"},
						{1, "World", 2, "Africa", 202, "Sub-Saharan Africa", 14, "Eastern Africa", "TZ"},
						{1, "World", 2, "Africa", 202, "Sub-Saharan Africa", 14, "Eastern Africa", "ZM"},
						{1, "World", 2, "Africa", 202, "Sub-Saharan Africa", 14, "Eastern Africa", "ZW"},
						{1, "World", 2, "Africa", 202, "Sub-Saharan Africa", 17, "Middle Africa", "AO"},
						{1, "World", 2, "Africa", 202, "Sub-Saharan Africa", 17, "Middle Africa", "CM"},
						{1, "World", 2, "Africa", 202, "Sub-Saharan Africa", 17, "Middle Africa", "CF"},
						{1, "World", 2, "Africa", 202, "Sub-Saharan Africa", 17, "Middle Africa", "TD"},
						{1, "World", 2, "Africa", 202, "Sub-Saharan Africa", 17, "Middle Africa", "CG"},
						{1, "World", 2, "Africa", 202, "Sub-Saharan Africa", 17, "Middle Africa", "CD"},
						{1, "World", 2, "Africa", 202, "Sub-Saharan Africa", 17, "Middle Africa", "GQ"},
						{1, "World", 2, "Africa", 202, "Sub-Saharan Africa", 17, "Middle Africa", "GA"},
						{1, "World", 2, "Africa", 202, "Sub-Saharan Africa", 17, "Middle Africa", "ST"},
						{1, "World", 2, "Africa", 202, "Sub-Saharan Africa", 18, "Southern Africa", "BW"},
						{1, "World", 2, "Africa", 202, "Sub-Saharan Africa", 18, "Southern Africa", "SZ"},
						{1, "World", 2, "Africa", 202, "Sub-Saharan Africa", 18, "Southern Africa", "LS"},
						{1, "World", 2, "Africa", 202, "Sub-Saharan Africa", 18, "Southern Africa", "NA"},
						{1, "World", 2, "Africa", 202, "Sub-Saharan Africa", 18, "Southern Africa", "ZA"},
						{1, "World", 2, "Africa", 202, "Sub-Saharan Africa", 11, "Western Africa", "BJ"},
						{1, "World", 2, "Africa", 202, "Sub-Saharan Africa", 11, "Western Africa", "BF"},
						{1, "World", 2, "Africa", 202, "Sub-Saharan Africa", 11, "Western Africa", "CV"},
						{1, "World", 2, "Africa", 202, "Sub-Saharan Africa", 11, "Western Africa", "CI"},
						{1, "World", 2, "Africa", 202, "Sub-Saharan Africa", 11, "Western Africa", "GM"},
						{1, "World", 2, "Africa", 202, "Sub-Saharan Africa", 11, "Western Africa", "GH"},
						{1, "World", 2, "Africa", 202, "Sub-Saharan Africa", 11, "Western Africa", "GN"},
						{1, "World", 2, "Africa", 202, "Sub-Saharan Africa", 11, "Western Africa", "GW"},
						{1, "World", 2, "Africa", 202, "Sub-Saharan Africa", 11, "Western Africa", "LR"},
						{1, "World", 2, "Africa", 202, "Sub-Saharan Africa", 11, "Western Africa", "ML"},
						{1, "World", 2, "Africa", 202, "Sub-Saharan Africa", 11, "Western Africa", "MR"},
						{1, "World", 2, "Africa", 202, "Sub-Saharan Africa", 11, "Western Africa", "NE"},
						{1, "World", 2, "Africa", 202, "Sub-Saharan Africa", 11, "Western Africa", "NG"},
						{1, "World", 2, "Africa", 202, "Sub-Saharan Africa", 11, "Western Africa", "SH"},
						{1, "World", 2, "Africa", 202, "Sub-Saharan Africa", 11, "Western Africa", "SN"},
						{1, "World", 2, "Africa", 202, "Sub-Saharan Africa", 11, "Western Africa", "SL"},
						{1, "World", 2, "Africa", 202, "Sub-Saharan Africa", 11, "Western Africa", "TG"},
						{1, "World", 19, "Americas", 419, "Latin America and the Caribbean", 29, "Caribbean", "AI"},
						{1, "World", 19, "Americas", 419, "Latin America and the Caribbean", 29, "Caribbean", "AG"},
						{1, "World", 19, "Americas", 419, "Latin America and the Caribbean", 29, "Caribbean", "AW"},
						{1, "World", 19, "Americas", 419, "Latin America and the Caribbean", 29, "Caribbean", "BS"},
						{1, "World", 19, "Americas", 419, "Latin America and the Caribbean", 29, "Caribbean", "BB"},
						{1, "World", 19, "Americas", 419, "Latin America and the Caribbean", 29, "Caribbean", "BQ"},
						{1, "World", 19, "Americas", 419, "Latin America and the Caribbean", 29, "Caribbean", "VG"},
						{1, "World", 19, "Americas", 419, "Latin America and the Caribbean", 29, "Caribbean", "KY"},
						{1, "World", 19, "Americas", 419, "Latin America and the Caribbean", 29, "Caribbean", "CU"},
						{1, "World", 19, "Americas", 419, "Latin America and the Caribbean", 29, "Caribbean", "CW"},
						{1, "World", 19, "Americas", 419, "Latin America and the Caribbean", 29, "Caribbean", "DM"},
						{1, "World", 19, "Americas", 419, "Latin America and the Caribbean", 29, "Caribbean", "DO"},
						{1, "World", 19, "Americas", 419, "Latin America and the Caribbean", 29, "Caribbean", "GD"},
						{1, "World", 19, "Americas", 419, "Latin America and the Caribbean", 29, "Caribbean", "GP"},
						{1, "World", 19, "Americas", 419, "Latin America and the Caribbean", 29, "Caribbean", "HT"},
						{1, "World", 19, "Americas", 419, "Latin America and the Caribbean", 29, "Caribbean", "JM"},
						{1, "World", 19, "Americas", 419, "Latin America and the Caribbean", 29, "Caribbean", "MQ"},
						{1, "World", 19, "Americas", 419, "Latin America and the Caribbean", 29, "Caribbean", "MS"},
						{1, "World", 19, "Americas", 419, "Latin America and the Caribbean", 29, "Caribbean", "PR"},
						{1, "World", 19, "Americas", 419, "Latin America and the Caribbean", 29, "Caribbean", "BL"},
						{1, "World", 19, "Americas", 419, "Latin America and the Caribbean", 29, "Caribbean", "KN"},
						{1, "World", 19, "Americas", 419, "Latin America and the Caribbean", 29, "Caribbean", "LC"},
						{1, "World", 19, "Americas", 419, "Latin America and the Caribbean", 29, "Caribbean", "MF"},
						{1, "World", 19, "Americas", 419, "Latin America and the Caribbean", 29, "Caribbean", "VC"},
						{1, "World", 19, "Americas", 419, "Latin America and the Caribbean", 29, "Caribbean", "SX"},
						{1, "World", 19, "Americas", 419, "Latin America and the Caribbean", 29, "Caribbean", "TT"},
						{1, "World", 19, "Americas", 419, "Latin America and the Caribbean", 29, "Caribbean", "TC"},
						{1, "World", 19, "Americas", 419, "Latin America and the Caribbean", 29, "Caribbean", "VI"},
						{1, "World", 19, "Americas", 419, "Latin America and the Caribbean", 13, "Central America", "BZ"},
						{1, "World", 19, "Americas", 419, "Latin America and the Caribbean", 13, "Central America", "CR"},
						{1, "World", 19, "Americas", 419, "Latin America and the Caribbean", 13, "Central America", "SV"},
						{1, "World", 19, "Americas", 419, "Latin America and the Caribbean", 13, "Central America", "GT"},
						{1, "World", 19, "Americas", 419, "Latin America and the Caribbean", 13, "Central America", "HN"},
						{1, "World", 19, "Americas", 419, "Latin America and the Caribbean", 13, "Central America", "MX"},
						{1, "World", 19, "Americas", 419, "Latin America and the Caribbean", 13, "Central America", "NI"},
						{1, "World", 19, "Americas", 419, "Latin America and the Caribbean", 13, "Central America", "PA"},
						{1, "World", 19, "Americas", 419, "Latin America and the Caribbean", 5, "South America", "AR"},
						{1, "World", 19, "Americas", 419, "Latin America and the Caribbean", 5, "South America", "BO"},
						{1, "World", 19, "Americas", 419, "Latin America and the Caribbean", 5, "South America", "BV"},
						{1, "World", 19, "Americas", 419, "Latin America and the Caribbean", 5, "South America", "BR"},
						{1, "World", 19, "Americas", 419, "Latin America and the Caribbean", 5, "South America", "CL"},
						{1, "World", 19, "Americas", 419, "Latin America and the Caribbean", 5, "South America", "CO"},
						{1, "World", 19, "Americas", 419, "Latin America and the Caribbean", 5, "South America", "EC"},
						{1, "World", 19, "Americas", 419, "Latin America and the Caribbean", 5, "South America", "FK"},
						{1, "World", 19, "Americas", 419, "Latin America and the Caribbean", 5, "South America", "GF"},
						{1, "World", 19, "Americas", 419, "Latin America and the Caribbean", 5, "South America", "GY"},
						{1, "World", 19, "Americas", 419, "Latin America and the Caribbean", 5, "South America", "PY"},
						{1, "World", 19, "Americas", 419, "Latin America and the Caribbean", 5, "South America", "PE"},
						{1, "World", 19, "Americas", 419, "Latin America and the Caribbean", 5, "South America", "GS"},
						{1, "World", 19, "Americas", 419, "Latin America and the Caribbean", 5, "South America", "SR"},
						{1, "World", 19, "Americas", 419, "Latin America and the Caribbean", 5, "South America", "UY"},
						{1, "World", 19, "Americas", 419, "Latin America and the Caribbean", 5, "South America", "VE"},
						{1, "World", 19, "Americas", 21, "Northern America", null, "", "BM"},
						{1, "World", 19, "Americas", 21, "Northern America", null, "", "CA"},
						{1, "World", 19, "Americas", 21, "Northern America", null, "", "GL"},
						{1, "World", 19, "Americas", 21, "Northern America", null, "", "PM"},
						{1, "World", 19, "Americas", 21, "Northern America", null, "", "US"},
						{1, "World", null, "", null, "", null, "", "AQ"},
						{1, "World", 142, "Asia", 143, "Central Asia", null, "", "KZ"},
						{1, "World", 142, "Asia", 143, "Central Asia", null, "", "KG"},
						{1, "World", 142, "Asia", 143, "Central Asia", null, "", "TJ"},
						{1, "World", 142, "Asia", 143, "Central Asia", null, "", "TM"},
						{1, "World", 142, "Asia", 143, "Central Asia", null, "", "UZ"},
						{1, "World", 142, "Asia", 30, "Eastern Asia", null, "", "CN"},
						{1, "World", 142, "Asia", 30, "Eastern Asia", null, "", "HK"},
						{1, "World", 142, "Asia", 30, "Eastern Asia", null, "", "MO"},
						{1, "World", 142, "Asia", 30, "Eastern Asia", null, "", "KP"},
						{1, "World", 142, "Asia", 30, "Eastern Asia", null, "", "JP"},
						{1, "World", 142, "Asia", 30, "Eastern Asia", null, "", "MN"},
						{1, "World", 142, "Asia", 30, "Eastern Asia", null, "", "KR"},
						{1, "World", 142, "Asia", 35, "South-eastern Asia", null, "", "BN"},
						{1, "World", 142, "Asia", 35, "South-eastern Asia", null, "", "KH"},
						{1, "World", 142, "Asia", 35, "South-eastern Asia", null, "", "ID"},
						{1, "World", 142, "Asia", 35, "South-eastern Asia", null, "", "LA"},
						{1, "World", 142, "Asia", 35, "South-eastern Asia", null, "", "MY"},
						{1, "World", 142, "Asia", 35, "South-eastern Asia", null, "", "MM"},
						{1, "World", 142, "Asia", 35, "South-eastern Asia", null, "", "PH"},
						{1, "World", 142, "Asia", 35, "South-eastern Asia", null, "", "SG"},
						{1, "World", 142, "Asia", 35, "South-eastern Asia", null, "", "TH"},
						{1, "World", 142, "Asia", 35, "South-eastern Asia", null, "", "TL"},
						{1, "World", 142, "Asia", 35, "South-eastern Asia", null, "", "VN"},
						{1, "World", 142, "Asia", 34, "Southern Asia", null, "", "AF"},
						{1, "World", 142, "Asia", 34, "Southern Asia", null, "", "BD"},
						{1, "World", 142, "Asia", 34, "Southern Asia", null, "", "BT"},
						{1, "World", 142, "Asia", 34, "Southern Asia", null, "", "IN"},
						{1, "World", 142, "Asia", 34, "Southern Asia", null, "", "IR"},
						{1, "World", 142, "Asia", 34, "Southern Asia", null, "", "MV"},
						{1, "World", 142, "Asia", 34, "Southern Asia", null, "", "NP"},
						{1, "World", 142, "Asia", 34, "Southern Asia", null, "", "PK"},
						{1, "World", 142, "Asia", 34, "Southern Asia", null, "", "LK"},
						{1, "World", 142, "Asia", 145, "Western Asia", null, "", "AM"},
						{1, "World", 142, "Asia", 145, "Western Asia", null, "", "AZ"},
						{1, "World", 142, "Asia", 145, "Western Asia", null, "", "BH"},
						{1, "World", 142, "Asia", 145, "Western Asia", null, "", "CY"},
						{1, "World", 142, "Asia", 145, "Western Asia", null, "", "GE"},
						{1, "World", 142, "Asia", 145, "Western Asia", null, "", "IQ"},
						{1, "World", 142, "Asia", 145, "Western Asia", null, "", "IL"},
						{1, "World", 142, "Asia", 145, "Western Asia", null, "", "JO"},
						{1, "World", 142, "Asia", 145, "Western Asia", null, "", "KW"},
						{1, "World", 142, "Asia", 145, "Western Asia", null, "", "LB"},
						{1, "World", 142, "Asia", 145, "Western Asia", null, "", "OM"},
						{1, "World", 142, "Asia", 145, "Western Asia", null, "", "QA"},
						{1, "World", 142, "Asia", 145, "Western Asia", null, "", "SA"},
						{1, "World", 142, "Asia", 145, "Western Asia", null, "", "PS"},
						{1, "World", 142, "Asia", 145, "Western Asia", null, "", "SY"},
						{1, "World", 142, "Asia", 145, "Western Asia", null, "", "TR"},
						{1, "World", 142, "Asia", 145, "Western Asia", null, "", "AE"},
						{1, "World", 142, "Asia", 145, "Western Asia", null, "", "YE"},
						{1, "World", 150, "Europe", 151, "Eastern Europe", null, "", "BY"},
						{1, "World", 150, "Europe", 151, "Eastern Europe", null, "", "BG"},
						{1, "World", 150, "Europe", 151, "Eastern Europe", null, "", "CZ"},
						{1, "World", 150, "Europe", 151, "Eastern Europe", null, "", "HU"},
						{1, "World", 150, "Europe", 151, "Eastern Europe", null, "", "PL"},
						{1, "World", 150, "Europe", 151, "Eastern Europe", null, "", "MD"},
						{1, "World", 150, "Europe", 151, "Eastern Europe", null, "", "RO"},
						{1, "World", 150, "Europe", 151, "Eastern Europe", null, "", "RU"},
						{1, "World", 150, "Europe", 151, "Eastern Europe", null, "", "SK"},
						{1, "World", 150, "Europe", 151, "Eastern Europe", null, "", "UA"},
						{1, "World", 150, "Europe", 154, "Northern Europe", null, "", "AX"},
						{1, "World", 150, "Europe", 154, "Northern Europe", 830, "Channel Islands", "GG"},
						{1, "World", 150, "Europe", 154, "Northern Europe", 830, "Channel Islands", "JE"},
						{1, "World", 150, "Europe", 154, "Northern Europe", 830, "Channel Islands", ""},
						{1, "World", 150, "Europe", 154, "Northern Europe", null, "", "DK"},
						{1, "World", 150, "Europe", 154, "Northern Europe", null, "", "EE"},
						{1, "World", 150, "Europe", 154, "Northern Europe", null, "", "FO"},
						{1, "World", 150, "Europe", 154, "Northern Europe", null, "", "FI"},
						{1, "World", 150, "Europe", 154, "Northern Europe", null, "", "IS"},
						{1, "World", 150, "Europe", 154, "Northern Europe", null, "", "IE"},
						{1, "World", 150, "Europe", 154, "Northern Europe", null, "", "IM"},
						{1, "World", 150, "Europe", 154, "Northern Europe", null, "", "LV"},
						{1, "World", 150, "Europe", 154, "Northern Europe", null, "", "LT"},
						{1, "World", 150, "Europe", 154, "Northern Europe", null, "", "NO"},
						{1, "World", 150, "Europe", 154, "Northern Europe", null, "", "SJ"},
						{1, "World", 150, "Europe", 154, "Northern Europe", null, "", "SE"},
						{1, "World", 150, "Europe", 154, "Northern Europe", null, "", "GB"},
						{1, "World", 150, "Europe", 39, "Southern Europe", null, "", "AL"},
						{1, "World", 150, "Europe", 39, "Southern Europe", null, "", "AD"},
						{1, "World", 150, "Europe", 39, "Southern Europe", null, "", "BA"},
						{1, "World", 150, "Europe", 39, "Southern Europe", null, "", "HR"},
						{1, "World", 150, "Europe", 39, "Southern Europe", null, "", "GI"},
						{1, "World", 150, "Europe", 39, "Southern Europe", null, "", "GR"},
						{1, "World", 150, "Europe", 39, "Southern Europe", null, "", "VA"},
						{1, "World", 150, "Europe", 39, "Southern Europe", null, "", "IT"},
						{1, "World", 150, "Europe", 39, "Southern Europe", null, "", "MT"},
						{1, "World", 150, "Europe", 39, "Southern Europe", null, "", "ME"},
						{1, "World", 150, "Europe", 39, "Southern Europe", null, "", "MK"},
						{1, "World", 150, "Europe", 39, "Southern Europe", null, "", "PT"},
						{1, "World", 150, "Europe", 39, "Southern Europe", null, "", "SM"},
						{1, "World", 150, "Europe", 39, "Southern Europe", null, "", "RS"},
						{1, "World", 150, "Europe", 39, "Southern Europe", null, "", "SI"},
						{1, "World", 150, "Europe", 39, "Southern Europe", null, "", "ES"},
						{1, "World", 150, "Europe", 155, "Western Europe", null, "", "AT"},
						{1, "World", 150, "Europe", 155, "Western Europe", null, "", "BE"},
						{1, "World", 150, "Europe", 155, "Western Europe", null, "", "FR"},
						{1, "World", 150, "Europe", 155, "Western Europe", null, "", "DE"},
						{1, "World", 150, "Europe", 155, "Western Europe", null, "", "LI"},
						{1, "World", 150, "Europe", 155, "Western Europe", null, "", "LU"},
						{1, "World", 150, "Europe", 155, "Western Europe", null, "", "MC"},
						{1, "World", 150, "Europe", 155, "Western Europe", null, "", "NL"},
						{1, "World", 150, "Europe", 155, "Western Europe", null, "", "CH"},
						{1, "World", 9, "Oceania", 53, "Australia and New Zealand", null, "", "AU"},
						{1, "World", 9, "Oceania", 53, "Australia and New Zealand", null, "", "CX"},
						{1, "World", 9, "Oceania", 53, "Australia and New Zealand", null, "", "CC"},
						{1, "World", 9, "Oceania", 53, "Australia and New Zealand", null, "", "HM"},
						{1, "World", 9, "Oceania", 53, "Australia and New Zealand", null, "", "NZ"},
						{1, "World", 9, "Oceania", 53, "Australia and New Zealand", null, "", "NF"},
						{1, "World", 9, "Oceania", 54, "Melanesia", null, "", "FJ"},
						{1, "World", 9, "Oceania", 54, "Melanesia", null, "", "NC"},
						{1, "World", 9, "Oceania", 54, "Melanesia", null, "", "PG"},
						{1, "World", 9, "Oceania", 54, "Melanesia", null, "", "SB"},
						{1, "World", 9, "Oceania", 54, "Melanesia", null, "", "VU"},
						{1, "World", 9, "Oceania", 57, "Micronesia", null, "", "GU"},
						{1, "World", 9, "Oceania", 57, "Micronesia", null, "", "KI"},
						{1, "World", 9, "Oceania", 57, "Micronesia", null, "", "MH"},
						{1, "World", 9, "Oceania", 57, "Micronesia", null, "", "FM"},
						{1, "World", 9, "Oceania", 57, "Micronesia", null, "", "NR"},
						{1, "World", 9, "Oceania", 57, "Micronesia", null, "", "MP"},
						{1, "World", 9, "Oceania", 57, "Micronesia", null, "", "PW"},
						{1, "World", 9, "Oceania", 57, "Micronesia", null, "", "UM"},
						{1, "World", 9, "Oceania", 61, "Polynesia", null, "", "AS"},
						{1, "World", 9, "Oceania", 61, "Polynesia", null, "", "CK"},
						{1, "World", 9, "Oceania", 61, "Polynesia", null, "", "PF"},
						{1, "World", 9, "Oceania", 61, "Polynesia", null, "", "NU"},
						{1, "World", 9, "Oceania", 61, "Polynesia", null, "", "PN"},
						{1, "World", 9, "Oceania", 61, "Polynesia", null, "", "WS"},
						{1, "World", 9, "Oceania", 61, "Polynesia", null, "", "TK"},
						{1, "World", 9, "Oceania", 61, "Polynesia", null, "", "TO"},
						{1, "World", 9, "Oceania", 61, "Polynesia", null, "", "TV"},
						{1, "World", 9, "Oceania", 61, "Polynesia", null, "", "WF"}
					}
				),
			createWorld = 
				let
					NewWorld = (world as record) => 
						[
							countryInfo = 
								let
									// Define the function type
									countryInfoType = type function (
										optional code as (type text meta [
											Documentation.FieldCaption = "Country Code",
											Documentation.FieldDescription = "The country code to lookup (e.g. US, FR, JP)",
											Documentation.SampleValues = {"US", "FR", "JP"}
										]))
										as record meta [
											Documentation.Name = "countryInfo",
											Documentation.LongDescription = "Retrieves information about a country, including its numeric code, alpha3 code, and name.",
											Documentation.Examples = {[
												Description = "Returns information about the United States of America",
												Code = "countryInfo(""US"")",
												Result = "[#" & """Country Code (numeric)" & """ = ""840""," & """Country Code""" & " = ""US""," & """Country Code (alpha3)""" & " = ""USA""," & """Country Name""" & " = ""United States of America""]"
											],[
												Description = "Returns information about France",
												Code = "countryInfo(""FR"")",
												Result = "[#" & """Country Code (numeric)" & """ = ""250""," & """Country Code""" & " = ""FR""," & """Country Code (alpha3)""" & " = ""FRA""," & """Country Name""" & " = ""France""]"
											]}
										],

									// Define the function implementation
									countryInfoImpl = (optional code as text) =>
										world[Countries]{[Country Code = code]},

									fn = Value.ReplaceType(countryInfoImpl, countryInfoType)
								in
									fn,

							findCountry = 
								let
									// Define the function type
									findCountryType = type function (
										name as (type text meta [
											Documentation.FieldCaption = "Country Name",
											Documentation.FieldDescription = "The name of the country to search for",
											Documentation.SampleValues = {"Brazil", "Japan", "Spain"}
										]))
										as (type nullable text) meta [
											Documentation.Name = "findCountry",
											Documentation.LongDescription = "<b>FOR BEST RESULTS: Add a new query that references this function within your ISO-3166 object.</b>#(cr)#(cr)Returns the ISO 3166-1 alpha-2 code for the given country name, or an error if the country is not found.",
											Documentation.Examples = {[
												Description = "Returns 'BR' for Brazil",
												Code = "findCountry(""Brazil"")",
												Result = """BR"""
											],[
												Description = "Returns 'JP' for Japan",
												Code = "findCountry(""Japan"")",
												Result = """JP"""
											]}
										],

									// Define the function implementation
									findCountryImpl = (name as text) as nullable text =>
										try world[Possible Names]{[Possible Name = Text.Proper(name)]}[Country Code] otherwise Error.Record("Country Missing","Could not find country in list of possible names",name),

									fn = Value.ReplaceType(findCountryImpl, findCountryType)
								in
									fn,

							addCountryName = 
								let
									// Define the function type
									addCountryNameType = type function (
										code as (type text meta [
											Documentation.FieldCaption = "Country Code",
											Documentation.FieldDescription = "The ISO 3166-1 alpha-2 code for the country",
											Documentation.SampleValues = {"US", "FR", "CN"}
										]),
										name as (type text meta [
											Documentation.FieldCaption = "Country Name",
											Documentation.FieldDescription = "The name of the country to add",
											Documentation.SampleValues = {"United States", "France", "China"}
										]))
										as (type any) meta [
											Documentation.Name = "addCountryName",
											Documentation.LongDescription = "Adds a country name to the internal world record, if it doesn't already exist.",
											Documentation.Examples = {[
												Description = "Adds 'United States' to the list of possible names for the US country code",
												Code 		= "addCountryName(""US"", ""United States"")",
												Result 		= "<i>Updated ISO-3166-1 object</i>"
											],[
												Description = "Attempts to add 'United States' to the list of possible names again and fails",
												Code 		= "addCountryName(""US"", ""United States"")",
												Result 		= "<i>Error</i>"
											]}
										],

									// Define the function implementation
									addCountryNameImpl = (code as text, name as text) =>
										if not List.Contains(try world[Possible Names][Possible Name] otherwise {},name) then
											@NewWorld(
												world & 
												[Possible Names = Table.AddKey(Table.FromRecords((try Table.ToRecords(world[Possible Names]) otherwise {}) & {[Country Code = Text.Upper(code), Possible Name = Text.Proper(name)]}),{"Possible Name"},true)]
											)
										else
											error "Name exists",

									fn = Value.ReplaceType(addCountryNameImpl, addCountryNameType)
								in
									fn,
							
							bulkAddCountryNames = 
								let
									// Define the function type
									bulkAddCountryNamesType = 
										type function (
											namesToAdd as (type list meta [
												Documentation.FieldCaption = "Names to add",
												Documentation.FieldDescription = "List of records to add to the world record. Each record should have 'Country Code' and 'Possible Name' fields."
											])
										) as any meta [
											Documentation.Name = "bulkAddCountryNames",
											Documentation.LongDescription = "Adds new potential country names in bulk.",
											Documentation.Examples = {[
												Description = "Adds multiple country names to the world record",
												Code 		= "bulkAddCountryNames([ [Country Code = ""US"", Possible Name = ""United States""], [Country Code = ""CA"", Possible Name = ""Canada""] ])",
												Result 		= "Table representing the updated world record"
											]}
										],

									// Define the function implementation
									bulkAddCountryNamesImpl = (namesToAdd as list) =>
										List.Accumulate(
											namesToAdd,
											@NewWorld(world),
											(state,current) => state[addCountryName](current[Country Code], current[Possible Name])
										),
									fn = Value.ReplaceType(bulkAddCountryNamesImpl, bulkAddCountryNamesType)
								in
									fn,
									
							countryDimension = 
								let
									// Define the function implementation
									countryDimensionImpl = () as table =>
										Table.RemoveColumns(
											Table.ExpandTableColumn(
												Table.NestedJoin(world[Countries],"Country Code",world[Continents],"ISO-alpha2 Code","Continent"),
												"Continent",
												Table.ColumnNames(world[Continents])
											),
											"ISO-alpha2 Code"
										),

									// Define the function type
									countryDimensionType = type function () as table 
										meta [
											Documentation.Name = "countryDimension",
											Documentation.LongDescription = "Returns a table with all countries ",
											Documentation.Examples = {[
												Description = "Returns a table with all countries and their respective regions and sub-regions",
												Code = "countryDimension()",
												Result = "#table({""Country Code (numeric)"", ""Country Code"", ""Country Code (alpha3)"", ""Country Name"", ""Global Code"", ""Global Name"", ""Region Code"", ""Region Name"", ""Sub-region Code"", ""Sub-region Name"", ""Intermediate Region Code"", ""Intermediate Region Name""}, {{44, ""BS"", ""BHS"", ""Bahamas"", 1, ""World"", 19, ""Americas"", 419, ""Latin America and the Caribbean"", 29, ""Caribbean""}, ...})"
											]}
										],
									fn = Value.ReplaceType(countryDimensionImpl, countryDimensionType)
								in
									fn,
									
							Countries = Table.SelectColumns(countryDimension(),{"Country Code", "Country Code (alpha3)", "Country Name", "Region Name", "Sub-region Name", "Intermediate Region Name"})
						] meta [
							world = world,
							New Possible Names = 
								Table.RemoveMatchingRows(
									world[Possible Names],
									world[Original Possible Names]
								)
						],
					initialState = [
						Countries 		= Table.Combine({defaultCountries,additionalDefaultCountries}),
						Possible Names 	= defaultPossibleNames,
						Continents 		= defaultContinents,
						Original Possible Names = Table.ToRecords(#"Possible Names")
					]
				in
					NewWorld(initialState)
		in
			createWorld
	],
Table      = [ // шаблоны списков, таблиц, записей
	TABLE_LIST_RECORD = "TABLE_LIST_RECORD",
	// 	LIST
		// 	месяцы
			months_list = {"январь", "февраль", "март", "апрель", "май", "июнь", "июль", "август", "сентябрь", "октябрь", "ноябрь", "декабрь"},
			
			lst1 = List.Transform({1..12}, each Text.From(_)), 							// {"1".."12"}
			lst2 = List.Transform({1..12}, each Date.ToText(#date(2024,_,1),"MMMM")), 	// {"Январь".."Декабрь"}
			lst3 = List.Transform({1..12}, each Date.MonthName(#date(2024,_,1))),		// {"Январь".."Декабрь"}
			
			month_0 = List.Transform({1..12}, (x)=> Text.Lower(Date.MonthName(#date(2024,x,1), "ru-RU"))), // {"январь".."декабрь"}
			month_1 = List.Transform({1..12}, (x)=> Date.ToText(#date(2022, x, 1), "MMM", "en-US")), // {"Jan".."Dec"}
			month_2 = List.Transform(List.Dates(#date(2024,1,1), 12, #duration(32,0,0,0)), (x)=>Text.Lower(Date.MonthName(x, "ru-RU"))), // {"январь".."декабрь"}
			month_3 = List.Generate(()=>#date(2016,1,1), (x)=>x<#date(2017,1,1), (x)=>Date.AddMonths(x,1), (x)=>Text.Lower(Date.MonthName(x, "en-US"))), // {"january".."december"}
			month_4 = List.TransformMany({1..12}, (x)=>{#date(2016,x,1)}, (x,y)=>Number.ToText(x)&" - "&Text.Lower(Date.MonthName(y))), // {"1 - январь".."12 - декабрь"}
			month_5 = List.TransformMany({2023..2024}, (x)=>{1..12}, (x,y)=>{x,y}),		// список списков {Год, Месяц}, 24 строки
			month_6 = List.TransformMany({2023..2024}, (month)=>{1..12}, (year,month)=>{year,month}), // тоже самое
		//	дни недели
			days_list   = {"понедельник","вторник","среда","четверг","пятница","суббота","воскресенье"},	// {"понедельник".."воскресенье"}
			days2 = Text.Split("понедельник|вторник|среда|четверг|пятница|суббота|воскресенье","|"),		// {"понедельник".."воскресенье"}
			days3 = List.Accumulate({1..7}, {}, (x,y)=> x & {Date.DayOfWeekName(y+1)}), 					// {"понедельник".."воскресенье"}
			days4 = List.Transform(
						List.Dates(#date(2024,1,1), 10, #duration(1,0,0,0)),
						(x)=>{x, Date.Month(x), Date.Year(x)} // список из 10 списков: Дата, Номер Месяця, Год
					), 
	
	// 	TABLE
		//  описание функций для создания таблиц
			/* 
				Рекомендации:
					Вариант с типизацией столбцов:
					= #table( type table [ID = number, Name = text], {{1, "Раздел 1"}, {2, "Раздел 2"}})
					= Table.FromList({2016..2024}, Splitter.SplitByNothing(), type table [Год = number])
					= Table.FromColumns({ List.Times( #time(0, 0, 0), 60*24, #duration(0, 0, 1, 0) ) }, type table [ Время = time ])
				
				Функции:
					#table				( columnNames as list, 	rows as list											)
					Table.FromColumns	( columns as list, 		optional columnNames as list							) as table
					Table.FromRows		( rows as list, 		optional columnNames as list							) as table
					Table.FromList		( list as list, 		optional splitter as any, 		optional columns as any	) as table
					Table.FromRecords	( records as list																) as table
				
				Примеры:
					myTable = #table({"Column1", "Column2"}, {{1, "A"}, {2, "B"}})						или Table.FromColumns({{1,2,3}}) 	или #table({},{})
					myTable = Table.FromColumns({{1, 2, 3}, {"A", "B", "C"}}, {"Column1", "Column2"}) 	или Table.FromColumns({{1,2,3}}) 	или Table.FromColumns({{}})
					myTable = Table.FromRows({{1, "Миша"}, {2, "Маша"}}, {"ID", "Name"})				или Table.FromRows({{1,2,3}})		или Table.FromRows({{}})
					myTable = Table.FromList({1, 2, 3}, Splitter.SplitByNothing(), {"Numbers"})			или Table.FromList({"1","2","3"})	или Table.FromList({})
					myTable = Table.FromRecords({[ID = 1, Name = "Миша"], [ID = 2, Name = "Маша"]})		или	Table.FromRecords({[], []})		или Table.FromRecords({})
			*/
		//	пустые таблицы 
			table1	= #table({},{}), 												// заголовков нет, строк нет
			table2  = #table({"Column1", "Column2"}, {}), 	 		    			// заголовки есть, строк нет
			table3  = #table({"Column1", "Column2"}, {{null, null},{null, null}}), 	// заголовки есть, 2 строки есть
			table4 	= #table(type table [a = text, b = number], {} ), 				// заголовки есть + тип, строк нет
			table5  = #table({{"Column1", type text}, {"Column2", type number}}, {}), 			  // заголовки есть + тип, строк нет
    		table6 	= Table.FromColumns(List.Transform({"a","b"}, each {}), {"a","b"}), 		  // заголовки есть, строк нет
			table7 	= Table.FromColumns(List.Repeat( {{""}}, List.Count({"a","b"}) ), {"a","b"}), // заголовки есть, строка есть
			table71	= Table.FromColumns({Text.ToList("abbccde")},{"a"}), 						  // заголовки есть, одна колонка, в строках буквы
			table8  = Table.FromList({1, 2, 3, 4, 5}, Splitter.SplitByNothing(), {"Numbers"} ),   // заголовки (1), строки (5), значения (1..5))
			table9  = Table.FromList(List.Repeat({null}, 10), Splitter.SplitByNothing(), {"Column1"}), // заголовки есть, 10 строк с Null
			table10	= Table.FromRecords({[Column1 = null]}), // 1 столбец, 1 строка с null
		
		//	немного заполненные
			table01	= #table(type table [Value=any], List.Transform({0, 1, 2, 3}, each {_})), // столбец 1, строк 4 + функция
			table02 = #table(type table [TestName = text],{{"A"}, {"B"}, {"C"}} ), // 1 столбец "TestName", 3 строки {"А","Б","С"}
			table03	= #table({"a".."d"},List.Repeat({{1..4}},5)), 	// 4 столбца, 5 строк: a = 1, b = 2, c = 3, d = 4
			table04 = #table({"x", "x^2"}, {{1,1}, {2,4}, {3,9}}),	// 2 столбца, 3 строки: число, квадрат числа
			table05	= #table({"что","на что"},{{"a","A"},{"aa","A"},{"aaa","A"},{"b","B"},{"c","C"}}), 	// словарь: что менять, на что менять
			table06	= Table.FromList({"мама,мыла,раму,1", "папа,ел,кашу,2", "саша,маша,миша,3"}), 		// 3 строки 4 столбца
			BlankTable 	= Table.FromRows({},{"Content","Name","Extension","Date accesssed","Date modified","Date created","Attributes","Folder Path"}),
			table07     = Table.FromRows({{"USD", 100},{"EUR", 200},{"GBP", 300}},type table [Currency=text, Amount=number]),
			table08	= 
				#table(
					type table [Entry = Text.Type, Category = Text.Type, SubCategory = Text.Type, Amount = Currency.Type], 
					{
						{"Expense", "Travel", null, 1500},
						{"Expense", null, "Airfare", 500},
						{"Expense", null, "Hotel", 1000}
					}
				),
		
		//	таблицы с датами и периодами
			table_date0	= Table.FromList({2016..2024}, Splitter.SplitByNothing(), type table [Год = number]), // с типом и названием!
			table_date2	= Table.FromList(List.Accumulate({1..7}, {}, (accum,x)=> accum & {Date.DayOfWeekName(x+1)}), null, {"ДеньНедели"}), // дни недели
			table_date3	= Table.FromList(Text.Split("понедельник|вторник|среда|четверг|пятница|суббота|воскресенье","|"), null, type table [ДеньНедели = text]),
			table_date4	= // 1 столбец со списком из 12-ти месяцев (изменяется формат написания месяца)
				Table.Combine(
					List.Transform(
						{1..12}, 
						each Table.FromValue(Date.ToText(#date(2000,_,1),"MMMM"))
					)
				),
			table_date5	= // 3 столбца Дата, Месяц, Год (изменять можно число строк и шаг)
				#table(type table
					[Date=date, Month=number, Year=number],
					List.Transform(
						List.Dates( #date(2024,1,1), 10, #duration(1,0,0,0) ),
						(x) => { x, Date.Month(x), Date.Year(x) }
					)
				),
			table_date6 = // все виды дата/время {"date", "time", "datetime", "datetimezone", "duration"}
				#table(
					{"date", "time", "datetime", "datetimezone", "duration"},
					{
						{  
							#date(2021, 9, 1) + #duration(1, 12, 0, 0),
							#time(23,58,00) + #duration(0, 0, 2, 0),
							#datetime(2021, 9, 1, 23, 58, 0) + #duration(1, 1, 2, 0),
							#datetimezone(2021, 9, 1, 23, 58, 0, 3, 0) + #duration(1, 0, 0, 0),
							#duration(1, 12, 0, 0) + #duration(0, 12, 0, 0)
						},
						{	
							#date(2021, 9, 1) - #duration(1, 12, 0, 0),
							#time(23,58,00) - #duration(0, 0, 2, 0),
							#datetime(2021, 9, 1, 23, 58, 0) - #duration(1, 1, 2, 0),
							#datetimezone(2021, 9, 1, 23, 58, 0, 3, 0) - #duration(1, 0, 0, 0),
							#duration(1, 12, 0, 0) - #duration(0, 12, 0, 0) 
						}
					}
				),
		//  таблицы с временем
			TimeMinSec  = // таблица в временем от секунды до суток
				/*
					Вариант начала:
						StartTime = #time(0, 0, 0),
						TimeList  = List.Times(StartTime, 24*60*60, #duration(0, 0, 1, 0)),
						TimeTable = Table.FromList(TimeList, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
						Rename    = Table.RenameColumns(TimeTable,{{"Column1", "Time"}}),
					
					Формат 24/12 "AM/PM" 
						{"Hour (24)",  each Time.Hour([Time])},
						{"Hour (12)",  each if [#"Hour (24)"] = 0 then 12 else if [#"Hour (24)"] > 12 then [#"Hour (24)"] - 12 else [#"Hour (24)"]},
						{"AM/PM", 	   each if [#"Hour (24)"] < 12 then "AM" else "PM"},
						{"Hour AM/PM", each Text.From([#"Hour (12)"]) & " " & [#"AM/PM"], type text},

					Добавляем столбец "СекундыСуток", который отображает секунду с начала суток - для этого время есть!
					SecondOfDay = 	Table.AddColumn(MinuteOfDay, "СекундыСуток", each 
										Time.Hour([Время]) * 3600 + Time.Minute([Время]) * 60 + Time.Second([Время])
									, Int64.Type)
				*/
				let
					fxMultiAdd = (tbl as table, nms as list) as table => List.Accumulate(nms, tbl, (s, c) => Table.AddColumn(s, c{0}, c{1}, c{2}?)),
					from1  	   = Table.FromColumns({List.Times(#time(0, 0, 0), 60, 		 #duration(0, 1, 0, 0))}, type table [Время=time] ), // часы - 24 строки
					from2  	   = Table.FromColumns({List.Times(#time(0, 0, 0), 60*24, 	 #duration(0, 0, 1, 0))}, type table [Время=time] ), // минуты - 60 строк
					from3      = Table.FromColumns({List.Times(#time(0, 0, 0), 60*60*24, #duration(0, 0, 0, 1))}, type table [Время=time] ), // секунды - 
					addColumns = fxMultiAdd(from3,{
						{"Часы",   		 each Time.Hour  ( [Время] ), Int64.Type},
						{"Минуты", 		 each Time.Minute( [Время] ), Int64.Type},
						{"МинутыСуток",  each Time.Hour  ( [Время] ) * 60 + Time.Minute([Время]), Int64.Type},
						{"Секунды", 	 each Time.Second( [Время] ), Int64.Type},
						{"СекундыСуток", each Time.Hour  ( [Время] ) * 3600 + Time.Minute([Время]) * 60 + Time.Second([Время]), Int64.Type}
					})
				in
					addColumns,
	
			table_time1 = // список минут
				Table.FromColumns(
					{ List.Times( #time(0, 0, 0), 60*24, #duration(0, 0, 1, 0) ) },
					type table [ Время = time ] 
				),

			table_time2 = 
				Table.FromColumns(
					{ List.Times( #time(0, 0, 0), 60*60*24, #duration(0, 0, 0, 1)) },
					type table [ Время = time ]
				),
		//	таблицы с данными
			table_bal0 	= // Баланс обработанный (столбцы {"Дата", "Статья", "Строка", "На начало", "На конец"})
				F[Table.JsonDecodeWithHead]("7VxLb9tGEP4rhE4poATcF7nMLWgOzSWnohfHCPQ82a7R1oegyH8PxV2G33LJ2jseq6RFH2iJ2sfMN7PzpPTv6tc/bx5u7z5vbg9/r95frT5u/jms1qsvD7mW4nTV8nRVefda75rrcWCYboapQ3PduIlfP330I8Xe3cmaf3tYt+xeq61bYnW99rT9/u2+o+3d6V293oe7b+3Lzw+328NfQ+/qJeo5m3ru1U/OZC7zt0K+VaL++CqFUdGwpQVQ7xiV3R3tqDeZG3rv3jVX3c32W/kNB+kYRVKIvB2fhue6Xjm/ruc+E4rfgKddf5wyjmXbJ8AtMACSH7SBNWyHjt4moiOp6FjDgE2zr8SFm2sBkO07FvXR0SazTkH8DDdbdXe84gDfno0XR1RTERUFF6K4/BEGCwpDkn6AcsWmJOcS9jrrUPMLgjlCnlXZv+M3Rb0dIEB3PHiFDvZBDC3s43Yo4L5NlCP5qCvNJUaZR9pogFxn8reOLPexgg+a17rqINAGpOXw8+zb/qqt60nETJF1v2JzHcHKTvUDImJrKGAeWtdYMx2khwwEImEhB+MuOmmeUET/4N+gP/PUgFdvvd7IEXErBiQgPqA9arfOonsCCJUDY1XHgj+ATr0Ujk3UELK5v3u4ueGyjps+FH7KJpLciI30s46oSwYwtX25aDjDLSC4BLIc2+7Ywe8jSj2jieIwVHEUiuPE8kgjjIo1nCj0P3uQAJyV0NskBFeJSBdk08gbEyAnBjgcyi+Ao0eSDMeLdfP2wH0UMwTsATGe5m18pP6TVp1Ca6LISqrIZGm5hOYdBOq8RYXlPTy8sb205NjecsdQTid8xHkP6oggVBny0FyPHQiBj0yEQpP9npQvkRPEIc+YYrwgJmTnI3TJZhXBugTHSHSsDiQ2BgiK/XLg2nEJ24Hv4fXVi+wNTDeAMsDmY4gt8IIi8sGZ6A9ql/glUTpkhyXKnO3wovdFtJGzBL9vI5Zlf2RrXhPRIps6lsyn2Zct5wcToZ0Wlv29USSejtGoIEh44kwdJQYEB9FZkDptR4gpAN7EONjQk30xzTA4CAzQcoHZboMtG+cgrmrgKEw06wW5AMaZ4sFhmHbNpCB7QcXmA499Cs8QabIZmUS4yUG9smXU3xAX2uqxeVR8J0DxSls9ZeTRqWqytHocokIoLkin0uuxho2lpdfTjPxfej1DIQtRjpfT7BFRzEx2HsHKTveXZs/8mz2m5DKOS6vn2a0eUeZsvmrp9ZzLnSztnvO1e1TU7qEK7TLbPfxR1Ctq93CkBXNv90iOcgPsvLR7IunQ2z1V3IyjHt7X3+4xXFgt7R6A92ztHkZXP5sOhaE7M7aC+WzAordz2FLepZvzlG6ONGzfH2CuMTyhczvpSkNBfwrcxO30iRR+LlgotojKP9ST0qAlm49cD1Qo9zoMHe6BjhKQQguisk+J7aeKrpaS4ymPrP5rPk7odSY3pAQ1is8Vhz38ySPGomMl64GMCb26goMHzZ12mn1CPTwdP00NdaqK7UEu3lOSeEwk+ZiUomL7/hozBIkYaDIG6lRmPy8GwMmjQPyRGPnTcWA1mFAb0dE0nzlCkB9Ur3braA1vX7wRgjvlI2vYjoJgvS2AggEBou/GJ3ttqj1XlWa150FWv493bK5BrzCw0g4z7EGixiajoqhWOn42hwsU7DYFzyKgO4dHlzxfO380+7odRK6Y8Y5UsHyfun2WE8u+JtJaAwjF3a5DqjSoPrPg+GrDsIYe4NZAASnr84VVg+QkVBlysZ/DYQ4jMM3KW1FHmTSs+A/uaIlkR0r5qIBYcsQ+yWArMcQoyCGG1fHPJVCLBTPNS6uKoxo97bxUFhyF0YvNS5WxbL3TmealhY0DjYlAcL68VJfnVgPgZDp5qTSsFnNJTAm/chT/FBaDCGaemKq4G8UFypKYpnsMjm/wzDoxtRyd+8tITF9AWWaembI94jTTxFScHle8/v4D"),
			table_bal1 	= // Баланс необработанный исходный 
				Table.FromRows(Json.Document(Binary.Decompress(Binary.FromText("vVjtbhNHFH2VEb+CFEX7ves+AbxA/iDewY8QJ6W0CiWBgkqDCIRK5QeVurazZHHszSvMvlHPPTP7GdssApHE3ux65n6fc+/4wYM7d3arv4e7/TsX/3h4+XgFfKLk5/6e0i/0uX6t/8D7hX6H9w/6jf6oXyp9qs/0e/1KP9cfu8L0eTnRK13omV6VxzpT5WSsM31ZTspDPEuxznUd0ZQ4kVwCz+HGe1i11ClWZWOd61Rfl0+sCNws8DzXs/JY9nuyPx7hLQmN0he6KB9B6WW1Y6avcfsJMlc6L0/wQFXSy4Mt4pXI90W+eVH6TOHjQi9V+RjCJhCd/aS+9w/0r2B2xkDl5S+4L/BkBaNh/kpiiI9z+JTDk0KWlU9ordsO/w3ck6VLSDqEP+XPFJzC1wmzUujP8JirVkjLsdqBP7m+4rK5Tu9SpteXWYjvEqzL7xVq6vHbep6vkQR1eDqnw8aK9ZICh5Ul8tyoLoq1W/shWeuGyAmdbmEftpZYK0SMPJw3gnqGRR0ha2wyCb6E1CkUo9DKA9i1MI+vIM6EwKptZz7uiH7by9KgsCVtESjCV0D1uQBe6RtdqDHWX9G26/JI3ZcdI4J3NErkEnpuizCEMc7AE6cQcvY1nPEn1NzA4QmN8iw/hCQkqZEfh0Kl+iRkLHLJO1EsF8e3BSZQBKCwuqkGJZFF2Mrf+GEq1aRzJX+ycKGLsWCTQjsgE4RLtkEB4/LXKtki9WaMqyBUwFsRaUEJHfjMqUEwztIharH+CBn/xeApV/WCA+tYIMQfJkLFvjOKKam9yJg9x79H7crn3nAjSVz1Ehp9AQO3anNX1Uy2Yg0KTB63kXeJ3Jworkktg6VkzVw0erau/cB2iHe0hsQlTk3hDkIjWSofSa0brioInJlI8A2hMO+2QVmo2zzLyikTdm3tOiqfKqanaHO0QZJkUeRPx0LMtSPLVkYga7mreJ0y6ub+SGod5s7lXiwj1YVxHc8z2WJq6zuwikfWA7dIbUVVqa/V8VVs6lVEGFRVkLHmP9Vzgsl3NSiwWn+HwpkFEqPMnka36r3IX3evKCM1en7C/xNLkOOmQBcb/ekxpFcxpJvYUvoiSwpNeqTJKIkE47EX+tXWZ6DB1/r0nr4g4kyRJZG5xnHQnc92xN9ysjdG/qd7d40fF9D9DO/vwaQvQa5Cr38J857qtzQNGmCj4rL/QK7Cxy+h9V+76RSSsRzFznId78n9G4Tcd01sF1KCKJgT5Tkens0JjHTrMqdZdnvEHDRwSgeRFjLEv14D+ZuZT+3QiQFnQQLK+fCabaTTK9/A+gILrhtWITJwk1rUCu4qmabB96QyHoHXkXshCLcV3OKq1FAwKnrH4i6X4aanYtlXkMksFvgdDe/YJtCdNrtKfvA881YzrqGqqs7X7TPAD7yIF1uKEipiZVITclYRXtNncnh9LHMeHBRgAhUCMdTuIZVJ+cqNPKZTpuBHccA5K7G6PkhjF4PWyO2IYFeSzEnvrbLTJnHmpjsf/WMNn7GrdmgrZ6usunVmTidCsgFnnYGwv8/FDrtOzIbqeqNOee9vO1JtQ+ug9rmw+ckNSeaG5z/rJYks7CIA/ZLgLw/28Ik0xKfY+slGlFiY4PfIxhJreN24f4ty0y+3BdwW416vb+jPVvN0kP8CvROOAYfMyZOmlbADt485plEtleWAQzYT019Dr+kdvvt1s/9GE0RuF8j1kXXQOBIaUDt9HsAyObVW2DTTR3nSCGq8y0w4u4eaYYeGrW51Dji3UcJ5pgWTfdlDlHhhK8QEyP72A8RQhGweVr6AkWgjRqKqxofINZK6eNk8pLV6zvoMSCI3ZEA0dTvQlmGwZePwcTDyzWEsYrOO3R/6lciNMUQ6F89TCzMSs71cyuCB98et52LJDR1Z0UuJ1AlBHfFbksBJQl5i2xjJC6khIuxNDSMUUqmt04YR0P1KRDY2BMCNmFcnnNwPLJNE/HrDD9kL/JZKmZQ5ENjvRiSSwIapNeTkUUOOOFLw7AjBGb3LrGH4hCqkRUUjFkLLtKKBvhKhNZFHflhPtZ4XtrYMpEc5EliNprlx7O8MPZIRuCOHIHJaVhPxjsS1VYY2QTzlWBiY7aLsLrXFnbDXdLW8Vc+1ffxmQuYKW6vnm9jrGw+ZUfANhB6Rh2MOC9/G6FG0mdG3MNY2To84OfmeqdwkdgZNQPusC9mZuBwik8itxvvuuSded+55+D8=", BinaryEncoding.Base64), Compression.Deflate)), let _t = ((type nullable text) meta [Serialized.Text = true]) in type table [#"А К Т И В Ы                " = _t, #"Код               стp. " = _t, #"На 31 декабря 2021 года" = _t, #"На 31 декабря 2020 года" = _t]),
			table_bal2 	= // справочник разделов баланса
				#table(type table
					[Раздел_ID = number, РазделПрефикс = text, РазделИмя = text, РазделИмяПолное = text, РазделИмяАббревиатура = text],
					{	{1,"Раздел 1","Долгосрочные активы"        ,"Раздел 1 Долгосрочные активы"        ,"ДА"},
						{2,"Раздел 2","Краткосрочные активы"       ,"Раздел 2 Краткосрочные активы"       ,"КА"},
						{3,"Раздел 3","Собственный капитал"        ,"Раздел 3 Собственный капитал"        ,"СК"},
						{4,"Раздел 4","Долгосрочные обязательства" ,"Раздел 4 Долгосрочные обязательства" ,"ДО"},
						{5,"Раздел 5","Краткосрочные обязательства","Раздел 5 Краткосрочные обязательства","КО"}
					}
				),
			table_bal3 	= // Balance key
					let Источник = Table.FromRows(Json.Document(Binary.Decompress(Binary.FromText("VdHLDcQgDEXRXlizCP6SWqL038YMBCTuCg4GPVs8T2ntKrW0+ypv/UsgpdqQbgmkpwzvHAoooQ7dQ3p9ktmn3Fujl3H2SSCFDHIoTgkSFDLIoYAS6hAmGmstc2tzOFvXTCCFDHIooIQ6NBvJ1YjPdF81F0ghgxwKCAkxE2LVQiClxseGbgmkkEEOBZRQP2VIdyighDBfrq98fw==", BinaryEncoding.Base64), Compression.Deflate)), let _t = ((type nullable text) meta [Serialized.Text = true]) in type table [Stroke_Key = _t, Parent_Stroke_Key = _t]),
						to = Table.TransformColumnTypes(Источник,{{"Stroke_Key", Int64.Type}, {"Parent_Stroke_Key", Int64.Type}})
					in  to,
			table_tab1	= // таблица ликвидности
				let
					Источник = Table.FromRows(Json.Document(Binary.Decompress(Binary.FromText("nZRfTttAEMavsrKEVCSD7N2Y0NeqfeAMKHchKeKPAmor9aEKUiEV4pkYQhNHia8wcyO+md1NoKpBspSddXZ3Zn+e+caHh0m+a+iaVlTRPf2lex7QlBY0M2KwWMI+0pJW3MfWLEmTHOMDjfLdfNvQCBuXfMzHNOMTHJ3SkgdGg1T8lc8xz5tDwf0PXeEBP4dhJXxaqLVFuCtLemkLTBsxbSMmTXgo5/kIgd/G/BExPaKNbOm+2m57Thc5HTjHOLCiCQYO8VCgHgUW4yku1HAeyA1CNqafdO3J8izLZCoy/wdWH2Xs6GYrvk7k64LvFttLeC65jxilAmlCK1oIzi3drWHCtTKtOYr1qrDYBhYIp6+vOOdTxC5f0BSexqr4/keDAFN4TFFTeZMnTxWKpxhpFJZXmtV3bImzF3HeEFktIfkIUoMPfzNbRlFrxMYdXl6hhJ1/e+BVC7Tg60Y+18wnapKCn6nQAmFlvnw6+Ozhfm+St0mZC8XYUzTXpKpa64A+owVfvNLVvkdzWskbDwPviXhujvKFwWIlPtoapSDd0PeoshCoE3VeeH21hfoYoew7UKq4ifqVmjds0QOtjN5WI43ihwp73jGNwlcu9GjgDu0g1mWtqTWAYrv3cikNI92hrqqCuSf8FfkinkcrPJrYTpH0es8=", BinaryEncoding.Base64), Compression.Deflate)), let _t = ((type nullable text) meta [Serialized.Text = true]) in type table [ID_Группа = _t, ID_KPI = _t, #"Полное название" = _t, #"Краткое название" = _t, Описание = _t, MIN = _t, #"Низкий риск" = _t, #"Средний риск" = _t, #"Высокий риск" = _t, #"Критический риск" = _t, MAX = _t]),
					
					tr = Table.TransformColumnTypes(Источник,{
						{"ID_Группа", type text}, 
						{"ID_KPI", Int64.Type}, 
						{"Полное название", type text}, 
						{"Краткое название", type text}, 
						{"Описание", type text}, 
						{"MIN", Int64.Type}, 
						{"Низкий риск", type number}, 
						{"Средний риск", type number}, 
						{"Высокий риск", type number}, 
						{"Критический риск", type number}, 
						{"MAX", Int64.Type}
					}),
					
					Unpivot = Table.UnpivotOtherColumns(tr, 
						{"ID_Группа", "ID_KPI", "Полное название", "Краткое название", "Описание"}, 
						"Атрибут", "Значение"
					)
				in
					Unpivot,
			table_Sales =
		 		Table.FromColumns(
					{
						List.Transform({1..12}, each Text.Start(Date.MonthName(#date(2014,_,1),"en-US"),3)), // список месяцев
						{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12}
					}, 
					type table [Month=text, Sales=number]
				),
		//	таблицы с типами данных
			table_type_5 = // все типы 
				#table( type table [ #"Type Name" = text, Type = type, #"Type Expression" = text ],
					{
						{ "Text", type text, "text"},
						{ "String", type text, "text"},
						{ "Number", type number, "number"},
						{ "Decimal", type number, "number"},
						{ "Decimal Number", type number, "number"},
						{ "Currency", Currency.Type, "Currency.Type"},
						{ "Int64", Int64.Type, "Int64.Type"},
						{ "Whole Number", Int64.Type, "Int64.Type"},
						{ "Percentage", Percentage.Type, "Percentage.Type"},
						{ "DateTime", type datetime, "datetime"},
						{ "Date", type date, "date"},
						{ "Time", type time, "time"},
						{ "DateTimeZone", type datetimezone, "datetimezone"},
						{ "Duration", type duration, "duration"},
						{ "Logical", type logical, "logical"},
						{ "Boolean", type logical, "logical"},
						{ "Type", type type, "type"},
						{ "", type any, "any"},
						{ null, type any, "any"},
						{ "List", type list, "list"},
						{ "Record", type record, "record"},
						{ "Guid", Guid.Type, "Guid.Type"},
						{ "Binary", type binary,"binary"},
						{ "Table", type table,"table"},
						{ "Int8", Int8.Type, "Int8.Type"},
						{ "UInt8", Byte.Type, "Byte.Type"},
						{ "Int16", Int16.Type, "Int16.Type"},
						{ "Int32", Int32.Type, "Int32.Type"},
						{ "Single", Single.Type, "Single.Type"},
						{ "Double", Double.Type, "Double.Type"}}),
			table_type_0 = // типы в одной строке
				#table(
					{"n", "fun", "rec", "tb", "l", "bin", "typ"},
					{
						{1, (x) => x, [a = 1], #table({"a"}, {{1}}), {1..3}, #binary(""), type text}
					}
				),
			table_type_1 = // все типы данных в одной колонке (через #table)
				#table(
					{"val"},
					{
						{null},
						{1.23},
						{"текст"},
						{false},
						{#date(2024,2,3)},
						{#datetime(2024,2,3,12,34,56)},
						{{1..3}},
						{[a=1]},
						{#table({},{})},
						{(x)=>x}}
				),
			table_type_2 = // все типы данных в двух строках (через #table)
				#table(
					type table [
						Null = null,
						Logical = logical,
						Number  = number,
						Time    = time,
						Date    = date,
						Datetime = datetime,
						Datetimezone = datetimezone,
						Duration = duration,
						Type = type,
						Text = text,
						List = list,
						Record = record,
						Table = table,
						Binary = binary
					], 
					{
						{
							null,
							true,
							1,
							#time(20,43,12),
							#date(2015, 1, 1),
							#datetime(2015, 1, 1, 21, 49, 18),
							#datetimezone(2015, 1, 1, 21, 49, 18, 3, 0),
							#duration(0, 0, 5, -30),
							type {type},
							"Hello World!",
							{null, false, 2, #time(20,43,12), "Goodbye World!"},
							[A = 1, B = "2"],
							#table({"x", "x^2"}, {{1,1}, {2,4}, {3,9}}),
							#binary({0x00, 0x01, 0x02, 0x03})
						},
						{
							null,
							false,
							2,
							#time(12,55,1),
							#date(2035, 1, 1),
							#datetime(2035, 5, 5, 15, 55, 55),
							#datetimezone(2015, 1, 1, 21, 49, 18, 3, 0),
							#duration(0, 0, 5, -30),
							type {type},
							"Hello World!",
							{null, false, 2, #time(20,43,12), "Goodbye World!"},
							[A = 1, B = "2"],
							#table({"x", "x^2"}, {{1,1}, {2,4}, {3,9}}),
							#binary({0x00, 0x01, 0x02, 0x03})
						}
					}
				),
			table_type_3 = // все типы данных в двух строках (через Table.FromRecords)
					Table.FromRecords( 
						{ 
							[   CustomerlD  = 1,
								JerseyNo	= 45,
								Name	    = "Rohit",
								LastName	= "Sharma",
								Phone	    = "123-4567",
								Datel	    = "1/1/2020",
								Date2	    = "1/1/2020"
							], 
							[ 	CustomerlD	= 2,
								JerseyNo	= 10,
								Name        = "Sachin",
								LastName    = "Tendulkar",
								Phone       = "123-4567",
								Datel       = "1/1/2020",
								Date2       = "1/1/2020"
							] 
						}, 
						type table 
							[   CustomerlD  = Number.Type, 
								JerseyNo    = Number.Type, 
								Name        = Text.Type, 
								LastName    = Text.Type, 
								Datel       = Date.Type, 
								Date2       = Date.Type
							]
					),
						
			table_type_4 = // таблица с пропусками и разными типами данных
					#table( {"a","b","c","d","e","f"},
						{
							{"text",null,null,null,"текст",null},
							{null,"text",null,null,null,null},
							{null,null,"Наименование","Цена","Количество","Сумма"},
							{null,null,"клавиатура",100,2,200},
							{null,null,"мышь",50,10,500}
						}
					),
			table_type_Ext = // таблица с раширениями
				// {  ".xls" ,  ".xlsm", ".xlsx", ".csv", ".zip" }
				#table( type table [ Extension = text],
					{	{ "xls" },
						{ "xlsb" },
						{ "xlsm" },
						{ "xlsx" },
						{ "csv" }
					}),
		//	таблицы с вложенными подтаблицами, списками, записями
			table_into_1 = // вложенный list во второй колонке
				#table(
					{"Name", "Record"},
					{
						{ "Item1", {#table({"Col1"}, {{1}}), "Value2"				} },
						{ "Item2", {"Value3", 				 "Value4"				} },
						{ "Item3", {5, 						 #table({"Col1"},{{2}})	} }
					}
				),
			table_into_2 = // вложенный record во второй колонке
				#table(
					{"Name", "Record"},
					{
						{"Item1", [Field1 = #table({"Col1"}, {{1}}), Field2 = "Value2"]},
						{"Item2", [Field1 = "Value3", Field3 = "Value4"]},
						{"Item3", [Field2 = 5, Field4 = #table({"Col1"}, {{2}})]}
					}
				),			
			table_into_3 = // вложенный table во второй колонке
				let Source = Table.FromRecords({
						[ID = 1, Name = "Item 1", SubTable = Table.FromRecords({[SubID = 101, Value = "A"], [SubID = 102, Value = "B"]})],
						[ID = 2, Name = "Item 2", SubTable = Table.FromRecords({[SubID = 201, Value = "C"], [SubID = 202, Value = "D"]})],
						[ID = 3, Name = "Item 3", SubTable = Table.FromRecords({[SubID = 301, Value = "E"], [SubID = 302, Value = "F"]})]
					})
				in Source,

			table_into_4 = // таблица с подтаблицами
				let	Source = #table(
						{"ID", "Name", "Data"},
						{
							{1, "Alpha", #table({"SubID", "Value", "Category"}, {{1, 100, "A"}, {2, 200, "B"}, {3, 150, "A"}})},
							{2, "Beta",  #table({"SubID", "Value", "Category"}, {{1, 300, "B"}, {2, 400, "C"}, {3, 250, "A"}})},
							{3, "Gamma", #table({"SubID", "Value", "Category"}, {{1, 500, "A"}, {2, 600, "B"}, {3, 450, "C"}})}
						}
					)
				in	Source,

		//	таблицы разные (через Binary)
			table_bin_2 = // план, факт, дата, вариант (полный год, 8 мес)
					Table.FromRows(Json.Document(Binary.Decompress(Binary.FromText("7ZRLboMwFEW3ghhHlT9A7bWg7CVJq04qla1QEqQ2KWQLzzuq/QwJler4o46qTJACue9zfa7rOhdVvsopkeaZqQYG6KBVG9VkjDCSwf5Bf4EzjHCCQb3Cp36lfxzy9arOKS2NjhVW/Qw9dGoDLZzC9EIYIaUohy9svIM2rDXD1sRqWzjrxn1cY1JdGwfJpJ136vmh3vRfwowiaBEpr8rASSnHbrSY9+xgr57UNtgn7GyLZGqrLRrUTp/ze/AZMzSaTAOMcIzUkx8LDDBGqa3Z3PIJBz3/UZsQrJcoL0gi3sWCsXi8pZU/JuAtDSkWt3i4kTIuIuGe6KRVPN0lJpjH0y1NM0FT2S7xZMoiGW6Lx2xVAttoFpNpbE+XAkllWy7Oy8W2prY1a2XCoNBrcxv1YkC2I2AypA9wTxFL+Hwt/sr57QqSo438Ju6eISy9bDFElA+IAHff7B49RQuYcCbAZyGiwJknCR4bzRDeLPg2EXMRdx58y/BLCUckfGdJLwWcqfBY8VfZEPds3LPxj7Kx/gY=", BinaryEncoding.Base64), Compression.Deflate)), let _t = ((type nullable text) meta [Serialized.Text = true]) in type table [план = _t, факт = _t, дата = _t, вариант = _t]),
		//	таблицы разные
			table_other_1 = // 10 колонок, 10 строк. Все числа. С итогами тренироваться
				let	from = 
						Table.FromColumns({
							{1, 2, 3, 4, 5, 6, 7, 8, 9, 10},  // Уровень
							{3000, 6300, 9650, 17500, 21000, 31000, 46000, 69000, 105000, 150000},  // Ветка 1
							{4500, 9450, 14775, 26250, 31500, 46500, 69000, 103500, 157500, 225000},  // Ветка 2
							{6000, 12600, 19700, 35000, 42000, 62000, 92000, 136000, 210000, 300000},  // Ветка 3
							{7500, 15750, 24625, 43750, 52500, 77500, 115000, 172500, 262500, 375000},  // Ветка 4
							{12000, 25200, 39400, 70000, 64000, 124000, 164000, 276000, 420000, 600000},  // Ветка 5
							{16500, 34650, 54175, 96250, 115500, 170500, 253000, 379500, 577500, 625000},  // Ветка 6
							{21000, 44100, 68950, 122500, 147000, 217000, 322000, 463000, 735000, 1050000},  // Ветка 7
							{25500, 53550, 83725, 146750, 176500, 263500, 391000, 566500, 692500, 1275000},  // Ветка 8
							{31500, 66150, 103425, 163750, 220500, 325500, 483000, 724500, 1102500, 1575000},  // Ветка 9
							{37500, 76750, 123125, 216750, 262500, 367500, 575000, 662500, 1312500, 1675000}   // Ветка 10
						}, 
							{"Уровень"} & List.Transform({1..10}, (x)=>"Ветка " & Number.ToText(x))	// названия столбцов
						) 
				in	from,
	// 	RECORD
		//	раз
			rec_1 = #table({},{}),
		//	два
			rec_2 = #table({},{}),
	//	заглушка
			Заглушка = #table({},{})
		],

Return     =   // возвращаем только функции
		Параметры &
		FinReport &
		MyPack &
		UTIL & 
		extLibrary & 
		LibPQ &
		buch &	
		Camwally &
		Zelensky &
		Calendar &
		Table &
		World &
		// Grech &
		// DataAnalys &
		Connectors
		
 in 
 	Return