*************************************************************************************	
// Источники мудроты. #ПолезныеСсылки 
// Всем добра! Выпрыгнул из сумрака и привел к общему знаменателю старый пост (который удалил) чтобы 
// источники лучше искались нашим ботом, а также добавил ссылочку на Бена нашего Грибаудо.
PQ:
  01. Спецификация языка PowerQuery M (https://docs.microsoft.com/ru-ru/powerquery-m/power-query-m-language-specification) - это фундамент, букварь, без него дальше тяжело;
  02. Справочник по языку формул Power Query M (https://docs.microsoft.com/ru-ru/powerquery-m/);  
  03. finalytics.pro (http://finalytics.pro/inform/m-for-powerquery/) простым языком для начинающих;
  04. blog by Maxim Zelensky (http://excel-inside.pro/ru/) простым языком, но не для начинающих;
  05. Товарищ Excel (https://comrade-xl.ru/category/power-query/) кратко, емко;
  06. planetaexcel.ru (https://www.planetaexcel.ru/techniques/24/) обстоятельно и с примерами;
  07. Книга "Скульптор данных в Excel с Power Query" (https://www.planetaexcel.ru/books/sd-book.php);
  08. Кен Пульс и Мигель Эскобар. "Язык М для Power Query" (https://baguzin.ru/wp/ken-puls-i-migel-eskobar-yazyk-m-dlya-power-query/) русский перевод отличной книги;
  09. BI блог Максима Уварова (https://needfordata.ru/blog) перевод статей Криса Вебба и разные коннекторы..;
  10. The BIccountant (https://www.thebiccountant.com/) грамотный бух рассказывает про BI;
  11. Chris Webb's BI Blog Chris Webb's BI Blog (https://blog.crossjoin.co.uk/) Мега дядька рассказывает обо всем на свете. Просто кладезь!;
  12. The Environment concept in M for Power Query and Power BI Desktop, Part 1 (https://ssbi-blog.de/blog/technical-topics-english/the-environment-concept-in-m-for-power-query-and-power-bi-desktop-part-1/)  Концептуальный и обстоятельный разбор с погружением;
  13. Power Query Formatter (https://www.powerqueryformatter.com/)  Красота спасет мир... и мои глаза.

DAX:
  01. Основные сведения о DAX в Power BI Desktop (https://docs.microsoft.com/ru-ru/power-bi/transform-model/desktop-quickstart-learn-dax-basics) опять фундамент;
  02. Articles - SQLBI (https://www.sqlbi.com/articles/) Мега дядьки про все подряд;
  03. Patterns – DAX Patterns (https://www.daxpatterns.com/patterns/) Мега дядьки про расчеты стандартных показателей в аналитике. ABC и вот это вот все;
  04. BI блог Антона Будуева (https://biprosto.ru/power-bi). Разбор формул DAX по-русски;  
  05. Анализ данных при помощи Microsoft Power BI и Power Pivot для Excel (https://dmkpress.com/catalog/computer/data/978-5-97060-858-6/);
  06. Подробное руководство по DAX (https://dmkpress.com/catalog/computer/data/978-5-97060-859-3/);
  07. Шаблоны DAX (https://dmkpress.com/catalog/computer/data/978-5-97060-909-5/);
  08. DAX Formatter by SQLBI (https://www.daxformatter.com/) Красота спасет мир... и мозг тех, кто читает ваши формулы.
*************************************************************************************	
// на взоде таблица в один столбец Хлеб, дата,дата,дата, Молоко, дата,дата,дата,
// надо сгруппировать даты по продуктам.
	to = Table.Group(from,"Column1",
			{"Дата", (x)=>List.Skip(x[Column1])},
			GroupKind.Local,
			(x,y)=>Number.From(y is text) // проверка столбца на текстовые значения
		)

// 	Собрать шапку из 2-х строк
	to = List.Transform(
			Table.ToColumns(Table.FirstN(from,2)),
			(x)=>Text.Combine(x,"@")
		 )

// 	разбить по большим буквам ПОЛЕЗНЫЕ ФИШКИ
//  Пример разделения текста на слова. Обрати внимание на последние два шага, List.Transform + Table.TransformColumnTypes
	let	Source 		   = #table(type table[Enum = text],{{"EnumNumberOne"},{"EnumTwo"}}),
		Splitted 	   = Table.TransformColumns(Source, {{"Enum", each Splitter.SplitTextByPositions(Text.PositionOfAny(_,{"A".."Z"},Occurrence.All))(_)}}),
		Tabled         = Table.TransformColumns(Splitted,{{"Enum", each Table.FromColumns(List.Zip({_}))}}),
		ColumnNames    = Table.ColumnNames(Table.Combine(Tabled[Enum])),
		NewColumnNames = List.Transform(ColumnNames, each "Enum."&Text.Middle(_,6)),
		ExpandedEnum   = Table.ExpandTableColumn(Tabled, "Enum", ColumnNames, NewColumnNames),
		TransformList  = List.Transform(NewColumnNames, each {_,type text}),
		Typed          = Table.TransformColumnTypes(ExpandedEnum, TransformList)
	in	Typed

// 	как можно проверять функции - последний шаг
	let
		FirstAndLastDayOfTheMonth = (date) => 
			 let
				dated         = Date.FromText(date),
				year          = Date.Year(dated),
				month         = Date.Month(dated),
				FirstDateText = Text.From(year)&"-"&Text.From(month)&"-01",
				FirstDate     = Date.FromText(FirstDateText),
				daysInMonth   = Date.DaysInMonth(dated),
				LastDateText  = Text.From(year)&"-"&Text.From(month)&"-"&Text.From(daysInMonth),
				LastDate      = Date.FromText(LastDateText),
				record        = Record.AddField([],"First Date of Month",FirstDate),
				resultset     = Record.AddField(record,"Last Date of Month",LastDate)
			 in
				resultset
	in
		FirstAndLastDayOfTheMonth("30/07/2015")
	
// 	подключение скриптов из внешних файлов. Правка в VSC
	to = Expression.Evaluate(Text.FromBinary(File.Contents("...")), #shared)

let from = 
	[	Local 	= {	"G:\=EXCEL BI - мои проекты\2024.01 - Анализ Отчетности\2. PQ запросы\fxPackGlobal.pq",
					"G:\=EXCEL BI - мои проекты\2024.01 - Анализ Отчетности\2. PQ запросы\fxСправочники.pq",
					"G:\=EXCEL PQ\PQ-коннекторы (ИЗУЧИТЬ)\Яндекс метрика, супер!.pq" },
		Web		= {	"https://github.com/Medvedevav632/FinAnalys/",
					"https://github.com/Medvedevav632/PowerQueryFunction/"}
    ],
	
	func = (x as number)=> Expression.Evaluate(Text.FromBinary(File.Contents(from[Local]{x-1})), #shared),
	
	typ = type function(
		x as (type number meta [Documentation.FieldCaption = "Укажи номер строки с путем к скриптам",
								Documentation.FieldDescription = "Номер строки начинается с единицы",
								Documentation.SampleValues = {1, 2}])
		) as any meta [	Documentation.Name            = "Load",
						Documentation.LongDescription = "<b> Грузим из папки код запросов </b> <br>" & Text.Combine(from[Local],"<br>"),
						Documentation.Examples = {[ Description = "Возвращяет запись с функциями", 
													Code = "Load(1)", 
													Result = "запись со списком функций" ]} ],
	result = Value.ReplaceType(func, typ) 
in 	result
	
*************************************************************************************	
// Важно!
   AddColumn делать через table buffer!!!

// да-да, конечно - Table.Group ты юзаешь для получения заданного набора столбцов с уникальными строками. 
	= 	Table.Group(
			from ,
			{"Клиент","Город"},
			{}
		)
	

====================================================================================================
	ЗАГОТОВКИ ТАБЛИЦ для примеров 												            * #table
====================================================================================================
// 	создание пустой таблицы
	from = #table(type table [Product=text, Month=text, Sales=number], {} )

// 	создание таблицы с колонками от "a" до "d" и 5 строк заполненными цифрами
	from = #table({"a".."d"},List.Repeat({{1..4}},5))

// 	создание таблицы с 3 колонками
	from = #table( {"a","b","c"}, {{1,1,null},{2,2,null}} ),
	
// 	таблица одной колонкой (где null = Splitter.SplitByNothing() = разделитель по умолчанию_
	lst  = List.Accumulate({1..6}, {}, (accum,x)=> accum & {Date.DayOfWeekName(x+1)}),
	from = Table.FromList(lst, null, {"ДеньНедели"})

// 	таблица с одной колонкой 1
	lst = Text.Split("понедельник|вторник|среда|четверг|пятница|суббота|воскресенье","|"),
    to  = Table.FromList(lst, null, {"ДеньНедели"}),

// 	таблица с одной колонкой 2
	to = Table.FromList(Text.Split("9:00/10:50/12:55/14:40/16:25/18:30/20:15/12:00","/"), null, {"Начало пар"})
	
// 	таблица с двумя колонками
	from = Table.FromList({"1,понедельник", "2,вторник", "3,среда"}, null, {"Номер", "День"} )

// 	таблица с 3-мя колонками
	let DateList   = List.Dates(#date(2024,1,1), 10, #duration(1,0,0,0)), 					// создаем список из 10 дат с шагом 1 день
		AddColumns = List.Transform( DateList,(x)=>{x, Date.Month(x), Date.Year(x)} ), 		// формируем список списков с 3-х значений
		DateTable   = #table(type table[Date=date, Month=number, Year=number], AddColumns) 	// разворачиваем в таблицу
	in  DateTable
	 
	// или одним шагом
	DateTable = #table(
        type table [ Date = date, Month = number, Year = number ],
        List.Transform( 
            List.Dates( #date( 2024,1,1 ), 10, #duration( 1,0,0,0 ) ),
            (x) => { x, Date.Month(x), Date.Year(x) }
        )
    )
	
//  Три колонки- Дата, Месяц, Год = 730 строк
	DateTable = 
		#table(
			type table [ Date = date, Month = number, Year = number ],
			List.Transform(
				List.Dates(#date(2023,1,1), 730, #duration(1,0,0,0)),
				(x)=>{x, Date.Month(x), Date.Year(x)}
			)
		)
	
//  Таблица 2 текстовые колонки Ключ-Значение (текст)
	from = Table.FromRecords( { [Key="B", T1="#"], [Key="C", T1="@"],
								[Key="D", T1="="], [Key="E", T1="$"] }, type table[Key=Text.Type, T1=Text.Type] )

//  Таблица 2 текстовые колонки Ключ-Значение (число)
	from = Table.FromRecords( { [Key="A", T2=10],  [Key="B", T2=15],
	from = Table.FromRecords( { [Key="A", T2=10],  [Key="B", T2=15],
								[Key="C", T2=20],  [Key="F", T2=60]  }, type table[Key=Text.Type, T2=Int64.Type] )
	
//  таблица с днями неделями и началами пар
	let ВремяНачалаПар = Table.FromRows(Json.Document(Binary.Decompress(Binary.FromText(
						"PczBDUAhCAPQXTh7AL4Y6SrG/df4gMZb89J2LXIwUyNhfEa7rUxWotArCrOUjs5HKoUMyO2MbIfM/CuZkOr4W/l5VoGG7B8=", 
						BinaryEncoding.Base64), Compression.Deflate)), 
						let _t = ((type nullable text) meta [Serialized.Text = true]) 
						in type table [Начало = _t, Окончание = _t]),
	in typed = Table.TransformColumnTypes(Запрос2,{{"Начало", type time}, {"Окончание", type time}})						

	let from   = Table.FromList(List.Accumulate({1..7}, {}, (accum,x)=> accum & {Date.DayOfWeekName(x+1)})),
		addCol = Table.AddColumn(from, "Время", each ВремяНачалаПар[Начало]),
		expand = Table.ExpandListColumn(addCol, "Время")
	in  expand

//  вариант 1
	from = Table.FromRecords({
			[A = null, 	B = 2, 	  C = 3, 	D = "4"],
			[A = "5", 	B = 6, 	  C = null, D = 8],
			[A = 9, 	B = null, C = "10", D = 11]
		})

//  Таблица периодов с одной колонкой с числовым списком лет. Второй аргумент - список!
	to = #table(type table [Год = number], List.Zip( {{2017..2021}} ))
	to = #table({"Город"}, 		 List.Zip( {{"Брест","Минск","Гомель"}} ))          // 1 колонка Город
	to = #table(2,        		 List.Zip( {{1..3}, {"Брест","Минск","Гомель"}} ))  // 2 колонки Column1 + Column2
	to = #table({"Кол1","Кол2"}, List.Zip( {{1..3}, {"Брест","Минск","Гомель"}} ))  // 2 колонки Кол1 + Кол1

//  через Table.FromColumns
	tbl = Table.FromColumns({{1..31}},{"День месяца"})
	
//  3 колонки 4 строки
	to = Table.FromColumns(
	  {
		{"Миша", "Маша", "Оля", "Галя"},   // колонка 1
		{1, 2, 3, 4},                      // колонка 2
		{15, 20, 25, 11}                   // колонка 3
	  },
		{"Игрок", "Номер", "Счет"})        // названия колокок

// 	1
	Source = Table.FromRows(Json.Document(Binary.Decompress(Binary.FromText("TY5NC4JAGIT/yrBnD2Yfdg3qIBRYHgrMw4u+6OK6hrtS/vtWQdjrPM8Mk+ci5cH0eiMCkUDJlpFOtum1KIKVRY49GaNZGUhXeHjG1hnZ/Qov2rnoNsEydXPTIPvQ0CKA8zxt77TLr2QFUgq2YXxp8vhh+dWQZZxPLw/E8z6kQUe1LD1wXBpVr99jGEaxXX6TdselrkVR/AE=", BinaryEncoding.Base64), Compression.Deflate)), let _t = ((type nullable text) meta [Serialized.Text = true]) in type table [Respondent = _t, Text = _t]),

// 	
    Source = Table.FromRows(Json.Document(Binary.Decompress(Binary.FromText("i45WurDrwr6LTUo6Shc2XthwYS8IgzizQKIXGy/svrAPKBCrE60E5OwDq9l1YQNQBVC2G8jcBOYYwVRAlAP1b77YcLH5YgdYFmTYhf0XdlzsB6qLBQA=", BinaryEncoding.Base64), Compression.Deflate)), let _t = ((type nullable text) meta [Serialized.Text = true]) in type table [Column1 = _t, Column2 = _t, Column3 = _t]),

// 	Интересно задание типа type = type. Это колонка с типом данных "type". Как использовать?
	DataFormat = #table(
		type table [ eng = text, rus = text, type = type ], {
			{ "AdFormat", 		"Формат объявления", 			Text.Type 	},
			{ "AdGroupId", 		"ID группы объявлений", 		Int64.Type 	},
			{ "Age", 			"Возрастная группа", 			Text.Type 	},
			{ "Cost", 			"Рекламный бюджет", 			Number.Type }
		}
	)

// таблица с типизазией столбцов
let
    from = #table(
		type table [ НомерПары = Int64.Type, Начало пары = time, Окончание пары = time, Начало перемены = time, type = type], {
			{ 1, "9:00",    "10:35",    "9:50",  Time.Type},
			{ 2, "10:50", 	"12:25",    "11:40", Time.Type},
			{ 3, "12:55", 	"14:30",    "13:45", Time.Type},
			{ 4, "14:40",	"16:15",    "15:30", Time.Type},
			{ 5, "16:25", 	"18:00",    "17:15", Time.Type},
			{ 6, "18:30", 	"20:05",    "19:20", Time.Type},
			{ 7, "20:15", 	"21:40",    "21:00", Time.Type},
            { 8, "12:00", 	"12:55",       null, Time.Type}
		}
	),
    typed = Table.TransformColumnTypes(from,{{"Начало пары", type time},{"Окончание пары", type time}, {"Начало перемены", type time}}),
    addColumn = Table.AddColumn(typed, "Время", each Text.From([Начало пары]) & "-" & Text.From([Окончание пары]), type text)
in
    addColumn

--------------------------------------------
// на выходе таблица
let func = () as table =>
        #table(
				{"Name",       "Key",  "Data", "ItemKind", "ItemName", "IsLeaf"},
			{
				{"Nested A",   "n1",   "AAA", "Table",    "Table",    false},
				{"Nested B",   "n2",   "BBB", "Table",    "Table",    false},
				{"Nested C",   "n3",   "CCC", "Table",    "Table",    false}
			}
		),
    to = func()
in  to

--------------------------------------------
// Создание таблицы через функцию с одним параметром
// Выхов: CreateNavTable("значение")
	(message as text) as table => 
		let objects = #table(
			{"Name",  "Key",   "Data", "ItemKind", "ItemName", "IsLeaf"},
			{
				{"Item1", "item1", #table({"Column1"}, {{message}}), "Table",    "Table",    true},
				{"Item2", "item2", #table({"Column2"}, {{message}}), "Table",    "Table",    true}
			})
		in  objects

====================================================================================================
	АККУМУЛЯТОР 				 												   * List.Accumulate
====================================================================================================
// Обзор функции от Гориллы https://gorilla.bi/power-query/list-accumulate/

// 	Returns the result of 1 * 1 * 2 * 3 * 4 * 5 = 120
	to = List.Accumulate( 
			{ 1, 2, 3, 4, 5 },                 		// входящий список
			1,                                   	// стартовое значение
			( state, current ) => state * current 	// функция
		 ) 
	
//  Returns the result of 10000 / 10 / 5 / 2 = 100
	to = List.Accumulate( 
			{10, 5, 2},
			10000,
			( state, current ) => state / current 
		 ) 

//  Returns "a5c%100"
	to = List.Accumulate( 
			{"a", 5, "c", "%", 100},
			"",
			(s,c)=>Text.Combine( {s} & {Text.From(c)} )
		 ) 

//  Returns a,5,c,%,100 // returns current value on first iteration (when result is null)
	to = List.Accumulate( 
			{ "a", 5, "c", "%", 100 },
            null,
            ( state, current ) => state & ","& Text.From( current )?? current
		 )

//  Combines each value and returns "a, 5, c, %, 100"
//  The if statements prevents the list from starting with {, "a", "5"... }
	to = List.Accumulate( 
			{ "a", 5, "c", "%", 100 }, 
			"", 
			( state, current ) => state & ( if state = "" then "" else ", " ) & Text.From( current ) 
		 )

// 	Returns a list with only even numbers
	to  = List.Accumulate( { 1..100 }, "",            
			( state, current ) =>
			  if state = "" 
				 then ( if Number.IsEven( current ) then {current} else state )
				 else ( if Number.IsEven( current ) then state & {current} else state )
		   )

//  На выходе таблица со списком дней недель с Понед по Воскр
	to = Table.FromList(
			List.Accumulate( {1..7}, {}, (accum,x)=> accum & {Date.DayOfWeekName(x+1)} ),
			null,
			{"ДеньНедели"}
		)

// 	трансформация в нескольких колонках
	to = List.Accumulate( 
			{ "Entity", "Product", "Channel" }, 
			from,
			( state, current ) => Table.TransformColumns( state, { current, each Text.Split( _, "," ) } )
		 )

// 	Returns the record [ min = -400, max = 150 ]
	to = List.Accumulate( 
			{ 1, 49, - 400, 150, 60 }, 
			[ min = 0, max = 0 ],     // starting record with min and max = 0
			( state, current ) =>     // logic for calculating the new min and max
				[
					min = if state[min] > current then current else state[min],
					max = if state[max] < current then current else state[max]
				] 
		) 
// Применить функцию к нескольким столбцам
	to = List.Accumulate(
			{ "РазделПрефикс", "РазделИмя"}, 
			Источник,
			(state,current) => Table.TransformColumns( state, { current, each Text.Split(_, " " ) } 
		 )

====================================================================================================
	# Выбор из списка 														           * List.Select
====================================================================================================
//	2 аргумента: список, функция

	to = List.Select(src, (x)=>x is list) // Отбираем данные типа list
	to = List.Select(Table.ColumnNames(from), (x)=>Text.Contains(x,"Дата")) // выборка имен столбцов содержащих "Дата"
	to = List.Select(Text.SplitAny(x,""), (x)=>x<>"") // оставляем в списке непустые значения
	to = List.Select(ColNames, (i)=>Text.Contains(i,"Дата"))
    to = List.Select(ColNames, (i)=>List.Contains({"Сумма","Код"}, i, (x,y)=>Text.Contains(y,x)))
    to = List.Select(ColNames, (i)=>List.Contains({"Сумма","Код"}, i, (x,y)=>Text.Contains(y,x)))

====================================================================================================
	ПОВТОРЕНИЕ СПИСКА 														           * List.Repeat
====================================================================================================

//  колонка список с последовательностью 1,2,3,4,5,1,2,3,4,5,1,2,3,4,5
	to = List.Sort(List.Repeat({1..5}, Table.RowCount(from) / 5)) // всего 30 строк

//  вставить индекс серией по 5 номеров: 1,1,1,1,1, 2,2,2,2,2, 3,3,3,3,3 ...
	to = Table.AddColumn(AddIndex, "Тема", each Number.RoundDown(([Индекс] - 1) / 5) + 1, Int64.Type)	


====================================================================================================
	ТРАНСФОРМАЦИЯ СПИСКА 1 														* List.TransformMany
====================================================================================================
//  список списков. Год+месяц. Типа календаря месяцев
	to = List.TransformMany( {2021..2023}, (x)=>{1..12}, (x,y)=>{x,y} )
	
====================================================================================================
	ТРАНСФОРМАЦИЯ СПИСКА 2	 													    * List.Transform
====================================================================================================

// 	список столбцов
	to = List.Transform({"1".."5"}, (x) => "Столбец " & x) 

// 	получить список названий месяцев, с заменой локали.
	to = List.Transform({1..12}, (x)=> Date.ToText(#date(2022, x, 1), "MMM", " en-US"))
	
//  из названия месяцев убрать посленюю букву "й" или "ь" и добавить "е". Будет "Сумма послуплений в мае" ...июне и т.д.
	to = List.Buffer( {null} & List.Transform(
				{1..12},
				(x)=>"Сумма поступлений в " & Text.Lower( Text.TrimEnd( Date.MonthName(#date(2023,x,1)),{"ь","й"}) & "е")
			)
		 )

//  список специальных символов по коду, напримед для удаления (https://www.excel-vba.ru/chto-umeet-excel/ostavit-cifry-ili-tekst-pri-pomoshhi-powerquery/)
	CharsToRemove = List.Transform({0..45,47,58..2000}, each Character.FromNumber(_))
	
//  извлечение даты из текста не разбирался как но работает
	Get_date = 
		Table.AddColumn(from, "Date", each 
			try	List.Transform(
					List.Select( 
						Text.Split([Column1], " "), 
						each List.Count( Text.SplitAny(_, "-.")) = 3
					), 
					each Date.FromText(_) 
				) {0}
			otherwise null
			, type date
		)

//  чисто синтаксис, сложно показать что оно делает
	f=(x)=> List.Zip(List.Transform(x, (x)=>Text.Split(x??"","#(lf)")))

//  Переименовываем таблицу. 
//  List.Transform - делаем список названий. Имя собираем из двух строк, второй (1) и третьей (2) строки 
//  from{1} = записть - 1 строка. Record.ToList(from{1}) = список - вся первая строка/ То же что и Table.ToList(from,(x)=>x){1}

	let from = 	Excel.CurrentWorkbook(){[Name="Так_есть"]}[Content],
		lst  = 	List.Transform(
					List.Zip({
						Record.ToList(from{1}),
						Record.ToList(from{2})
					}),  // вот тут интересно. Склеиваем две строки
					Text.Combine // функия склейки
				),
		to   = 	Table.RenameColumns(
					Table.Skip( from, 3 ),
					List.Zip( {Table.ColumnNames(from), lst} )
				)
	in  to

//  Список колонок из подтаблиц, кроме тех, у которых в названии Column
	to = List.Select(List.Distinct(List.Combine(List.Transform(transf[Data],each Table.ColumnNames(_)))), each not Text.Contains(_,"Column"))
	
	to = 	List.Select(
				List.Distinct(
					List.Combine(
						List.Transform( transf[Data], each Table.ColumnNames(_) )
					)
				), each not Text.Contains(_,"Column")
			)

====================================================================================================
	LIST - рекомендован List.Buffer(										                  * List..
====================================================================================================
//  выборка имен столюцов содержащих "Дата"
	nms = List.Select(Table.ColumnNames(from),(x)=>Text.Contains(x,"Дата"))
	
// 	добавить к каждому элементы такой же, но с ".руб." в конце
// 	List.Transform - список списков на выходе, который объединяем через List.Combine
	to  = List.Combine(List.Transform(nms, (x)=>{x, x & ".руб."} ))

====================================================================================================
	Двойные пробелы
	tag столбцы
====================================================================================================
// 	один из вариантов удаления двойных пробелов (других непечатных символов). Наверное лучший. 
//  	- делим каждый заголовок на буквы по непечатным символам и собираем заново через разделитель
// 		- можно добавить Trim и Clean, если лишниче непечатные символы есть в конце или в начале названия
	(x)=>Text.Combine(Splitter.SplitTextByWhitespace()(x)," "))
	
// 	Пример: 
// 1. Чистим - удаляем из названия столбцов двойные пробелы.
	nms = List.Transform(
			Table.ColumnNames(to), 
			(x)=>Text.Combine( Splitter.SplitTextByWhitespace() (Text.Trim(x) ), " ")
		  )
// 2. Отбираем ружные названия столбцов
	nms2 = List.Select(
			Table.ColumnNames(to), 
			(i)=> List.ContainsAny(
					{i},
					{"АК","Код","На1","На31","31"}, 
					(txt,word)=>Text.Contains( 
						Text.Upper( Text.Remove(txt," ") ),
						Text.Upper( Text.Remove(word," ") )
				  )
		 )
	)
// 3. Оставляем нужные столбцы
	to = Table.SelectColumns(from, nms2)
====================================================================================================
	ГРУППИРОВКА 																       * Table.Group
====================================================================================================
/* 	5 аргументов: 3 обязательные, 2 нет
	Пятый аргумент – comparer – это функция от двух аргументов, возвращающая 0 или 1. 
	В качестве аргументов выступают значение, с которого начинается группа и текущее 
	значение - state и current (s и c, x и y – кому как больше нравится). 
	Соответственно, пока функция возвращает ноль – строки объединяются, как только единицу – начинается следующая группа. 
	И это важный момент – нам нужны именно 0 и 1. */

----------------------------------------------------------------------------------------------------
//  соеднинение текста	
	grouped = Table.Group(
		types,
		{"Date", "Voc_Id", "Category"},
		{{"Name", each Text.Combine([Name], ";#(lf)"), type text}}
	)
----------------------------------------------------------------------------------------------------
//	Шапка в 1С
	to = Table.Group( 
			del, 
			{"Index"}, 
            {{"tab", each Table.FromRows( {List.Transform( Table.ToColumns(_), 
                     each if List.Count(List.RemoveNulls(_)) < 2  then _{0} else Text.Combine(_,"|") )}, Table.ColumnNames(del)), 
                     type table}}, 
            GroupKind.Local, 
            (s,c) => Number.From( c[Index] <> null) 
        )

// еще один пример с пятым параметром
// оно же третий параметр {"Тип", (x)=> Text.Combine(List.Skip(x[Тип]), " ")},
= Table.Group(
            Source,
            { "Дата и время" },
            {"Тип",( x ) => [listSkip = List.Skip( x[ Тип ] ),textCombine = Text.Combine( listSkip, " " )][ textCombine ]},
            GroupKind.Local,
            ( s, c ) => Number.From( c[ #"Дата и время" ] <> null )
        )
----------------------------------------------------------------------------------------------------
// Мой пример в танк с итогом конкурса - https://www.youtube.com/watch?v=m1GciRxnl1o
let
    from = Excel.CurrentWorkbook(){[Name="Таблица1"]}[Content],
    nms  = 	List.Transform(
				List.Skip(Table.ColumnNames(from),2),
				(x)=>{x,										 // 1-й элемент списка - имя колонки
					  (t)=>Text.Combine(Table.Column(t,x)," "),  // 2-й элемент списка - функция агрегации в этой колонке, объединяем строки
					  type text}								 // 3-й элемент списка - тип данных
			), // на выходе список списков где имя колонки + тип функция + тип данных
    
	gr   =  Table.Group(					   // !!! группируем строки по колонке Index между 4. Если в начале нет 4, то не будет, остается
				from,
				{"Индекс","Index"},			   // группируем по двум столбцам
				nms,						   // вот тут сложно. тут несколько аггегаций моджет быть с тремя аргументами.
				GroupKind.Local,			   // =0, в зависимости от значения в столбце идем.Если локал, то пишем 5 аргумент о 2-х аргументах! 
				(s,c)=>Number.From(c[Index]=4) // первый аргумент тут не используется. Группируем по колонке 2. Т.к. у нас => 2 колонки.
			)
in  gr

// 	сгруппировать по двум колонкам и в третьей объединить строки (расписание пар например)	
//  4 и 5 аргумент тут не нужны
	nms = List.Transform( 
                List.Skip(Table.ColumnNames(filter),2),
				(x)=>{x, (t)=>Text.Combine(Table.Column(t,x)," "), type text}
			)
// nms отдельно, если по нескольким столбцам 
// если по одному столбцу группировка то {"Column2", (t)=>Text.Combine(Table.Column(t,"Column2")," "), type text},
// или списком { {"период",(x)=>f(x[дата]), Text.Type}, {"выработка",(x)=>List.Sum(x[выработка]), Int64.Type} }


// Группировка
// https://www.planetaexcel.ru/forum/index.php?PAGE_NAME=message&FID=1&TID=115886&TITLE_SEO=115886-razlozhit-period-dat-na-posledovatelnost-v-power-query-ili-power-pivot&MID=1226731&tags=&q=power+query+%D0%BC%D0%B5%D1%81%D1%8F%D1%86+%D0%BE%D0%BA%D0%BE%D0%BD%D1%87%D0%B0%D0%BD%D0%B8%D0%B5&FORUM_ID%5B0%5D=0&DATE_CHANGE=0&order=relevance&s=%D0%9D%D0%B0%D0%B9%D1%82%D0%B8#message1226731
let Source = Excel.CurrentWorkbook(){[Name="Таблица1"]}[Content],
    a = Table.UnpivotOtherColumns(Source, {"Столбец1"}, "q", "w"), // q - дата, w - текстовое значение
    b = Table.Group(a, {"Столбец1", "w"}, 
			{
				{"w1", (x)=> List.Min(x[q])}, 	// столбец с датой
				{"w2", (x)=> List.Max(x[q])}	// столбец с датой
			}, 
			GroupKind.Local, 
			(x,y)=>Number.From(x[w]<>y[w])
		),
    c = Table.Group(b, {"Столбец1", "w"}, 
			{
				{"start", (x)=> Text.Combine(x[w1], "#(lf)")}, // сцепляем несколько дат с переносом
				{"end",   (x)=> Text.Combine(x[w2], "#(lf)")}
			}
		)
in  c
----------------------------------------------------------------------------------------------------
//  пример Гомельского троллейбусный маршрута
//  https://www.planetaexcel.ru/forum/index.php?PAGE_NAME=message&FID=5&TID=158107&TITLE_SEO=158107-gruppirovka-po-stolbtsam-s-dopolnitelnymi-usloviyami-v-powerquery&MID=1254573&tags=&q=%D0%B3%D1%80%D1%83%D0%BF%D0%BF%D0%B8%D1%80%D0%BE%D0%B2%D0%BA%D0%B0+%D0%BF%D0%BE+%D1%87%D0%B0%D1%81%D0%B0%D0%BC+&FORUM_ID%5B0%5D=0&DATE_CHANGE=0&order=relevance&s=%D0%9D%D0%B0%D0%B9%D1%82%D0%B8#message1254573
//  Файл в примерах ПРИМЕРЫ/Группировка - Троллейбусные мартштуры Гомель +++.xlsx
	let group  = 
			Table.Group( sorted, {"Дата", "Время", "Остановочный пункт"}, 
				{
					{"начало", 	   each List.Min([Время])}, 
					{"окончание",  each List.Max([Время])},
					{"кол-во", 	   each Table.RowCount(_)},
					{"маршруты",   each Text.Combine(List.Distinct([маршрут]), ", ")},
					{"таб номера", each Text.Combine(List.Distinct([таб]), ", ")}
				},
				GroupKind.Local, 
				(s, c) => 
					Number.From(
						((c[Время] - s[Время]) > #duration(0, 3, 0, 0)) or
						(s[Дата] <> c[Дата]) or 
						(s[Остановочный пункт] <> c[Остановочный пункт])
					)
			),
		out = Table.RemoveColumns(group,{"Время"})
	in  out	

----------------------------------------------------------------------------------------------------
//  простая с добавлением трех колонок
	let
		Source = Table.FromRows(Json.Document(Binary.Decompress(Binary.FromText("i45W8krMU9JRciwoyEktBjIMDZRidWCi/kWJeelgYWMTJGH3osQCsKipKVjULTUJ2QhjZFGEEWYGSMJwI6CKfROLkjOQDTExQBFHGGOKKoEwCCgeCwA=", BinaryEncoding.Base64), Compression.Deflate)), let _t = ((type nullable text) meta [Serialized.Text = true]) in type table [Month = _t, Product = _t, Sales = _t]),
		SumTableColumn = 
				(t as table, columnName as text) as number => // сумма
				let TempSource = Table.TransformColumnTypes(t,{{columnName, type number}}),
					Result = List.Sum(Table.Column(TempSource, columnName)) 
				in  Result,
		GroupedRows = 
			Table.Group(Source, {"Month"}, 
				{ {"Count", 
					each _, 
					type table [Month=nullable text, Product=nullable text, Sales=nullable number]} 
				}
			),
		AddedCustom1 = Table.AddColumn(GroupedRows, "SQLrowcount", each Table.RowCount([Count])),
		AddedCustom2 = Table.AddColumn(AddedCustom1, "ToList", each [Count][Sales]),
		AddedCustom3 = Table.AddColumn(AddedCustom2, "Totals", each SumTableColumn([Count], "Sales") as number)
	in  AddedCustom3
----------------------------------------------------------------------------------------------------
//  Зеленский. Лучше и гораздо быстрее на вашем объеме данных - через джойн (слияние) с группировкой. 
//  Группировки и джойн в PQ оптимизированы, и выполняется быстрее, чем группировка и разворачивание.
	to = Table.Join(Источник, 
			{"Код", "Товар"}, 
			Table.Group(Источник, 
					{"Код", "Товар"}, 
					{ {"Сумма Продаж по товару 2", each List.Sum([Продажи])} }
				),
			{"Код", "Товар"}
		)
/*  Правила работы от Зеленского!
	Совет 1: изучайте правила построения аналитической модели данных. Неправильная модель данных приводит к тормозам и неудобству и сложности
	Совет 2: делайте прототип модели данных, готовьте исходные таблицы в PQ, анализируте данные в DAX. 
			 Некоторые вычисления можно и нужно делать в PQ (группировки, например), 
			 но большая часть вычислений быстрее делается в DAX. В общем, задача PQ - подготовить модель данных, а анализ - DAX
	Совет 3: Поменьше расчетных доп.столбцов (в 90% случаев нужен не столбец, а мера).		
*/

====================================================================================================
	Таблицу в список списков  											           	  * Table.ToList
====================================================================================================

// 
	to = Table.ToList(from,(x)=>x)
	
// пример
	let tbl = #table(type table [Статья = text, Строка = number, Примечание = text], {{"Товар",10,"а"}, {"Деньги",20,"б"}} ),
	    t   = Table.ToList(tbl, (x)=>x),					// Список списков без преобразования
	    to  = Table.FromList(t, (x)=>x, Value.Type(tbl) )	// Разворачиваем обратно таблицу из списков с сохранением типов
	in  to


====================================================================================================
	Record.FromList 													           * Record.FromList
====================================================================================================
//  всю строку делаем List, которые построчно заносим в record с столбцом номера и собранной строкой 
//  все? колонки должы быть текстовыми
	to = Record.FromList(
			Table.ToList(typed, (x)=>List.Skip(x)), 
			Table.ToColumns(typed){0}
		 )

-----------------------------------------------------------------------------------------------------
// 	оставляем текст из списка в строке
	to = let seek=(txt)=> List.Select(lst, (x)=> Text.Contains(txt, x)){0}?,
             lst = List.Buffer({"студент","магистрант","выпускник","курсант"}),
             add = Table.AddColumn(fillDown, "Статус", (x)=> seek(x[Сведено]) , type text)
         in  add


====================================================================================================
	Обращение к столбцу													              * Record.Field
====================================================================================================
 // Обращение к КОЛОНКЕ по имени

// cортировка по имени колонки, а не [полю]
	nms = List.Buffer(Table.ColumnNames(from)),
	f =(x)=> not List.ContainsAny({x}, {"0".."9"}, Text.Contains), // условие фильтрации 1
	g =(x)=> x <> null,											   // условие фильтрации 2
	to = Table.SelectRows (from, (row)=> f(Record.Field(row, nms{0}) ) )

====================================================================================================
	Добавление поля													           	   * Record.AddField
====================================================================================================

	to = Record.AddField([],"First Date of Month", FirstDate)	//	пустое + новое поле
	to = Record.AddField([Раз = 1],"First Date of Month", FirstDate) // одна запись есть

====================================================================================================
	Рекурсия
====================================================================================================
	let
		Value =
		[
			AddOne = (x) => if x > 0 then 1 + @AddOne(x - 1) else 0,
			AddOneThreeTimes = AddOne(3)
		]
	in
		Value[AddOneThreeTimes] // возвращает 3
	// Здесь на шаге Value определяется запись из двух полей с именами [AddOne, AddOneThreeTimes]. 
	// Первое поле содержит рекурсивную функцию, второе поле – вызов этой функции с параметром 3.
====================================================================================================
	Нечеткое слияние таблиц													 * Table.FuzzyNestedJoin
====================================================================================================

// 	fxKofPodobie - коэффициентом подобия 
	(text1 as text, text2 as text) as number =>
	let text1 = Text.Upper(text1),
		text2 = Text.Upper(text2),
		matching_chars = List.Count(List.Intersect({Text.ToList(text1), Text.ToList(text2)})),
		average_length = (Text.Length(text1) + Text.Length(text2)) / 2,
		coef =  matching_chars / average_length
	in  coef

// 	Добавить колонку с коэффициентом подобия		
	to = Table.AddColumn(#"Строки с примененным фильтром1", "fxKofPodobie", each fxKofPodobie([Сведено], [NaimVuzIm]))

// 	Добавить колонку с коэффициентом подобия		
	to = Table.FuzzyNestedJoin(from, 
			{"Сведено"}, УниверситетыБаза, 		// исходная
			{"NaimVuzIm"}, "УниверситетыБаза", 	// справочник
			JoinKind.LeftOuter, [IgnoreCase=true, IgnoreSpace=true, Threshold=0.9]
		 )

====================================================================================================
	ФИЛЬТРАЦИЯ КОЛОНОК  													   * Table.SelectColumns
====================================================================================================

//  оставить первые четыре колонки
	t = Table.SelectColumns(
			clear, 
			List.Transform(
				{1..4}, 
				(x)=>Table.ColumnNames(clear){x-1}
			)
		)
	
//  убираем пустые столбцы	
	RemCols = Table.SelectColumns(from, 
				List.Select(Table.ColumnNames(from), 
							each List.NonNullCount(List.Transform(Table.Column(from, _), 
								each try if Text.Clean(Text.Trim(_)) = "" then null else _ otherwise _ )) > 0 ) )

//  убираем пустые столбцы. Вариант 2, не проверял.
(tbl) =>
	let Headers = Table.ColumnNames(tbl),
		Result  = Table.SelectColumns(tbl, List.Select(Headers, each List.MatchesAny(Table.Column(tbl, _), each _ <> null)))
	in  Result
	
====================================================================================================
	ФИЛЬТРАЦИЯ СТРОК  															  * Table.SelectRows
====================================================================================================

//  удаляем пустые строки (во всех ячейках null)
	RemRows = Table.SelectRows(from, each List.NonNullCount(Record.FieldValues(_)) > 0)

//  удаляем пустые строки
	RemRows = Table.SelectRows(from, 
				each not List.IsEmpty(List.RemoveMatchingItems(List.Transform(List.RemoveMatchingItems(Record.FieldValues(_), {"", null}), 
					each try Text.Clean(Text.Trim(_)) otherwise _ ),{""}))),


//  фильтрация строк по отдельному списку
    lst = СписокГруппы[Фамилия],
    to  = Table.SelectRows(from, (tbl)=> List.ContainsAny({tbl[Полное имя пользователя]}, lst, Text.Contains) )

// 	оставляем те, где есть эти слова
    to  = Table.SelectRows(from, each not List.ContainsAny( 
							{ [Специальность] },
							{"факультет","Факультет","институт","Институт","Специальность"},
							Text.Contains)
					),
					
//  первое слово равно любому из списка
	to = Table.SelectRows(from, 
		(x)=> List.ContainsAny( 
			{Text.BeforeDelimiter(x[Сведено], " ")}, 
			{"учреждение","филиал","Академия","Белорусский","Витебский","Гомельский","Минский","частное","межгосударственное","государственное"},
			Text.Contains
		)
	)

//  обрабатываем колонку в которой есть null !! Третий агрумент смотри!
	(x)=> List.ContainsAny({x[Дни]}, {"среда"}, (x)=>Text.Contains) // ошибка 
	(x)=> List.ContainsAny({x[Дни]}, {"среда"}, (x)=>Text.Contains(x, "Дни")) // норм

//  оставляем строки с текстом в заданной колонке, которая не содержит цифр
	to  = Table.SelectRows(from, (x)=> List.ContainsAny({x[Сведено]},{"0".."9"}, Text.Contains))

//  возвращяет только те строки, где первые буквы слов, начинаются на эти буквы
	to = Table.SelectRows(from, 
			each Text.PositionOfAny([Сведено], { "у","ф","ч","м","г","А","Б","Г","М","В" },Occurrence.First) 
		 )

//  Оставить строки только с текстом, без любых чисел - не проверял
	to = Table.SelectRows(from, 
			each (Text.Length(Text.From([Столбец1])) = Text.Length(Text.Remove(Text.From([Столбец1]),{"0".."9"})))
		 )
		 
//  3 варианта фильтрация строк (List.Contains, Table.Join, Record.FieldOrDefault)
	let from = #table(type table [a=text,b=number,c=number],{{"a",1,1},{"b",2,2},{"c",3,3},{"d",4,4},{"e",5,5},{"f",6,6},{"g",7,7}}),
		lst  = {"a","c","e","g"},
		
		to   = Table.SelectRows(from, (x)=> List.Contains(lst, x[a]) ),
		to0  = Table.SelectRows(from, (x)=> List.Contains({1,3}, x[b]) ),
		
		tbl  = Table.FromList(lst,(x)=>{x},{"a"}), 
		to1  = Table.Join(from,"a",tbl,"a"),
		
		dict = Record.FromList(List.Repeat( {true}, List.Count(lst) ), lst),
		to2  = Table.SelectRows(from, (x)=> Record.FieldOrDefault(dict, x[a], false) )
	in  to2	
-------------------------------------------------------------------------------------------------
		 
===[ Функция выбора столбцов по вхождению текста ]===
//	выбор столбцов по вхождению текста

(tbl as table, optional words as list) => 
    let from   = tbl,
        types  = Table.TransformColumnTypes(from, List.Transform(Table.ColumnNames(from), (x)=>{x,type text})),
        unpiv  = Table.UnpivotOtherColumns(types, {}, "ColumnNames", "Filters"),
        lst    = if words <> null then words else {"Секция","вася"},
        fltr   = Table.SelectRows(unpiv, each List.AnyTrue(List.Transform(lst, (x)=>Text.Contains([Filters], x)))),
        nms    = List.Sort(List.Distinct(fltr[ColumnNames]), Order.Ascending),
        selCol = Table.SelectColumns(types, nms)
    in  selCol

		
====================================================================================================
	УДАЛЕНИЕ КОЛОНОК  														   * Table.RemoveColumns
====================================================================================================
//	удалить пустые колонки - вариант 1 (новые версии PQ)
	to  = Table.RemoveColumns(x[Data], Table.SelectRows(Table.Buffer(Table.Profile(x[Data])), each [NullCount]=[Count])[Column]),
  
//	удалить пустые колонки - вариант 2 (старые версии PQ) проверить надо несколько раз
	to  = 	Table.SelectColumns(Source, 
				List.Select(
					Table.ColumnNames(Source), 
					(x)=> List.NonNullCount(Table.Column(Source, x)) > 0  // наверное несколько провериок надо сделать На 0, ошибку и др.
				)
			)

//	удалить колонки по их порядковому номеру (с номерами 2, 3, 41)
	nms = List.Buffer(Table.ColumnNames(from)),
	del = Table.RemoveColumns(from, List.Transform({2,3,41}, (x)=>nms{x} ) )
	
//	удалить все колонки имя которых начинается с "Column"
	del = Table.RemoveColumns(from, List.Select(Table.ColumnNames(from), (x)=>Text.StartsWith(x,"Column") ) )

====================================================================================================
	Формирование словарей 														   	* dictionary
====================================================================================================
http://excel-inside.pro/blog/2023/01/15/power-query-record-as-dictionary-part-1/
http://excel-inside.pro/blog/2023/01/15/power-query-record-as-dictionary-part-2/

let 
    TargetTable = #table( 
        {"Name", "Occupation"}, 
        { 
          {"John", "Player"}, 
          {"Pete", "Player"}, 
          {"Nick", "Coach"}, 
          {"Aristotle", "Medic"} 
          } 
      ), 
 
    LookupTable = #table( 
      {"Position", "Salary", "Bonus"}, 
      { 
        {"Player", 1000, 100}, 
        {"Coach", 2000, 5000} 
        } 
      ), 
 
    Dict = Record.FromTable( 
      Table.FromList( 
        Table.ToRows(LookupTable), 
        (row) => {row{0}, List.Skip(row)}, 
        {"Name", "Value"} 
        ) 
      ), 
 
    Generator = (RowValues as list) as list => Record.FieldOrDefault(Dict, RowValues{1}, {}), 
 
    Result = Table.FromList( 
      Table.ToRows(TargetTable), 
      Generator, 
      {"Name", "Occupation", "Salary", "Bonus"} 
      ) 
in 
    Result

	// пример1blank
	dic = Record.FromTable(
			Table.Group(
				Table.CombineColumns(tp, {"Товар", "Область"} ,Combiner.CombineTextByDelimiter("*", QuoteStyle.None), "Name"), 
				"Name", 
				{"Value", (x)=>List.Zip( {x[цена], x[Дата]}) })
		),
		
	// пример2
	dic = Record.FromTable(
			Table.CombineColumns(
				Table.Group(t2, lst, {"Value",(t)=>List.Sum(t[ОБЪЕМ])} ),
				lst,
				Text.Combine,
				"Name"
			)
		),
	
	// пример3 (пример из танка)
	// передача поля desс в функцию через (x)=>Record.Field(x, desc) <> null
	let    
    f_spr=(table, desc)=>
        [ a = Table.Distinct(
                  Table.SelectRows(
                    table, 
                    (x)=>Record.Field(x, desc) <> null
                  ), desc
              ),
          b = Record.FromList(Table.ToList(a, (x)=>List.Skip(x)), Table.ToColumns(a){0})
        ][b],

    from_spr = Excel.CurrentWorkbook(){[Name="СПР"]}[Content],    
    prmt_spr = Table.Buffer(Table.PromoteHeaders(from_spr, [PromoteAllScalars=true])),
    hdr_spr  = Table.ColumnNames(prmt_spr ),
    SPR1     = f_spr(Table.SelectColumns(prmt_spr, List.FirstN(hdr_spr, 4)), "Статья"),    
    SPR2     = f_spr(Table.SelectColumns(prmt_spr, List.FirstN(List.Skip(hdr_spr, 5),4)), "Подотдел")
in  SPR2
	
	
	// пример4

=============================================================================================
	Таблица из списка 										 		  * Excel.CurrentWorkbook
=============================================================================================
//  подключение к таблице
	f=(x)=> Excel.CurrentWorkbook(){[Name=x]}[Content]
	to = f("Таблица1")

//  или более сложно, но сразу меняемтип отдельно взятой колонки из одной из таблиц 
	f=(x)=> Table.TransformColumnTypes(Excel.CurrentWorkbook(){[Name=x]}[Content], {"месяц",Text.Type})
	to = f("Таблица1") // исходная таблица с колонкой "месяц" типа текст


=============================================================================================
	Таблица из списка 													     * Table.FromList
=============================================================================================

//  преобразуем в таблицу список колонок
	to = Table.FromList(Table.ColumnNames(DataTable))

// 	разворачиваем список списков с сохранением типа данных
	to = Table.FromList(tr, (x)=>x, Value.Type(from))

// Пример 1 в Танке "Мне нужно соединить последние три колонки в одну с разделителем, но чтобы сами колонки остались на месте."
let
    from = Excel.CurrentWorkbook(){[Name="спр_Статьи"]}[Content],
    
	f=(x)=> { Text.Combine(									 // формируем первую колонку + & добавляем исходную таблицу без первой
				List.Transform( List.LastN(x,3), Text.From)  // объединяю значение последних трех колонок через "."
			 ,".")
			} 
			& 
			List.Skip(x), // сколько исходных колонок вывожу (тут без первой колонки с номером, т.к. она заменяется на новую через точку
    nms = {"Номер"} & List.Skip(Table.ColumnNames(from)),
	row = Table.ToRows(from),
    to  = Table.FromList(row, f, nms)
in
    to

// Есть список списков - 5 строк в котоых через запятую разное количество чисел.
// Надо сделать таблицу с названиями колонок по порядку
= Table.FromList(
        lst, // список со строками в которых числа через зяпятую
        Splitter.SplitTextByDelimiter(", "),
        List.Transform({"1".."5"}, (x) => "Столбец " & x) // формируем названия столбцов
    )
	
	
=============================================================================================	
	Добавить строку 												       * Table.InsertRows
=============================================================================================
// 	Способ 1 - cоздание дополнительной строки с итогами в конце таблицы (2 колонки, имя и значение)
	let from = #table( {"a", "b"}, {{"v1",11}, {"v2", 14}} ),
		to   =  from & Table.FromRecords({ [a = "Итого", b = List.Sum(from[b])] })
	in  to

//  Способ 2 - Топ10 - добавить строку с итогами в таблице из двух столбцов в строку 10
	to = 	Table.InsertRows(top10, 10, {
				[
					Производители = "(остальные)", 
					Показатель = List.Sum(Source[Показатель]) - List.Sum(top10[Показатель]) 
				]}
			)
	
//	Вариант 1. Создание Итоговой строки. Через записи. Работает!
	let
		
	// 	Расчет итоговой строки
		Source =  Table.FromColumns({
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
		}, {"Уровень"} & List.Transform({1..10}, (x)=>"Ветка " & Number.ToText(x))),

	// 	Расчет итоговой строки
		TotalRow = Record.FromList(
			List.Transform(
				Table.ColumnNames(Source),
				each if _ = "Уровень" 
					 then null 
					 else List.Sum(Table.Column(Source, _))
			),
			Table.ColumnNames(Source)
		),
		
	// 	Замена имени поля 
		TotalRowWithLevel = Record.TransformFields(TotalRow, {{"Уровень", each "ИТОГО"}}),
	
	// 	Создание строки с итогами и добавление её в таблицу
		AddedTotalRow = Table.InsertRows(Source, Table.RowCount(Source), {TotalRowWithLevel})
	in
		AddedTotalRow
	

// Создание только одной итогой строки 
	let 
		Source  = Excel.CurrentWorkbook(){[Name="Table1"]}[Content],
		Unpivot = Table.UnpivotOtherColumns(Source, {}, "Attribute", "Value"),
		Pivoted = Table.Pivot(Unpivot, List.Distinct(Unpivot[Attribute]), "Attribute", "Value", List.Sum)
	in
		Pivoted
	
//	если колонок много. Например таблица колонка Имя и 10 колонок со значениями

//  Вариант 1. Через List.Zip + List.Transform. Проще
	let
		Source = Excel.CurrentWorkbook(){[Name="Table1"]}[Content],
		nms    = Table.ColumnNames(Source),
		group  = Table.Group(Source, {}, 
					List.Zip({
						nms, 
						{ each "Total"} & List.Transform(List.Skip(nms), (x)=>each List.Sum(Table.Column(_,x)))
					})
				),
		append = Table.Combine({Source, group})
	in
		append

//	Ваиант 2. Через List.TransformMany. Сложнее
	let
		Source = Excel.CurrentWorkbook(){[Name="Table1"]}[Content],
		group = Table.Group(Source, {}, 
					List.TransformMany(
						Table.ColumnNames(Source),
						(x)=>{each 	if x = "letter" 
									then "Total" 
									else List.Sum(Table.Column(_,x)) },
					(x,y)=>{x,y})
					),
		append = Table.Combine({Source, group})
	in
		append		

=============================================================================================
	РАЗДЕЛЕНИЕ КОЛОНОК 													  * Table.SplitColumn
	tag.Развернуть список
=============================================================================================
!!! Эта функция работает с таблицей, в которой списки
     а аналогичная функция = Table.FromList(to_list, (x) => x, Table.ColumnNames(Source)) 
	 работает со списком списков. Результат аналогичный

/*  Функция имеет 6 аргументов (3 + 3):
	function (	table as table, 		=> на входе таблица!!!
				sourcecolumn as text, 
				splitter as function, 
				optional columnNamesOrNumber as any, 
				optional default as any, 
				optional extraColumns as any
	) as table */

//	делим колонку со списками (list) на несколько
	to = Table.SplitColumn(from, "tmp", (x)=>x, {"дата","значение"})

//	разворачиваем список из двух строк (list) в колонке "tmp" в две колонки "дни", "даты"!
	to = Table.SplitColumn(from, "tmp", (x)=>x,{"дни","даты"})
	to = Table.SplitColumn(from, "tmp", (x)=>Text.Split(x,"/"), {"месяц","маркет"})
	
//	добавляем три колонки после колонки "b" и добавляем значения. Можно (x)=>{x} - по умолчанию тогда - null
	to = Table.SplitColumn(from, "b", (x)=>{x,null,0,null}, {"b","x","y","z"})

//	оборотная ведомость. Разбивает колонку по номерам позиций + сразу переименовывает
	to = Table.SplitColumn(from, Table.ColumnNames(from){0}, Splitter.SplitTextByPositions(Positions), ColNames)

//	расписание. Делим колонку с именем файла по разделителю и оставляем только вторую и третью колонку
    // Splitter возвращает список.Скобки после него аргумент, который по умолчанию ()
	// На входе "G-31_ФЭУ_стабильное.xlsx". Из списка из 4 значений оставляем диапазон из 2-х значений после первого
    splitColumn = Table.SplitColumn(rename, "Name", (x)=>List.Range(Splitter.SplitTextByAnyDelimiter({"_", "."})(x),1,2), {"Факультет", "Вид"}),
	
//  другие варианты 
	to = Table.SplitColumn(from, "Название", Splitter.SplitTextByAnyDelimiter({"_", "."}), {"Группа","Факультет","Вид"})
	to = Table.SplitColumn(gr[[SKU],[tmp]],"tmp",(x)=>x,lst)
---------------------------------------------------------------------------------------------
// Полный пример
let from = Table.FromRecords(Json.Document(Binary.Decompress(Binary.FromText("rZLBDsIwCIZfpel5aYDSWX0V9eCmvoEn47u7QeeoiXOJXn4G+6HlS/d3f7gBRxa9iHaireh5rjOKkmjvd/69aNv5Kgq+UZvOz2orvUiuCsVrz4y9aCrDdrGx11VjHsYlN84AOCFr5JIPP5yvmsBs0Q2ttAkQAwFF9xpCAdpS0gptA2SpaA4YENXhH82PDOPVtFwMz7OBdlokGV0VVpDkDyQngMjL2GBglAwRzAG2kv8NiB6ZzDcU2xIKdlVYgSL9iGJ8HBYF5emx/AFFNrZ2vnepTDssAUmuCiuAtB+AUP7yJjDAZlyc/OP4BA=="),Compression.Deflate))),
    f=(x)=>List.Zip(List.Transform(x,(i)=>if Text.Contains(i,"#(lf)") then Text.Split(i,"#(lf)") else {i})),
    cmb = Table.CombineColumns(from,{"дни","даты"},f,"tmp"),
    exp = Table.ExpandListColumn(cmb, "tmp"),
    to  = Table.SplitColumn(exp, "tmp", (x)=>x, {"дни","даты"})
in  to

---------------------------------------------------------------------------------------------
// В строке два List. Надо их раскрыть в этих же колонках - не оптимальный способ, для другого примера выложен был. Но надо разобраться
let f = (x)=>List.Zip(List.Transform(x,(y)=> List.RemoveItems(y,{""}))),
    from    = #table({"lst_01", "lst_02"}, {{{1, 2}, {3, 4, 5}}}),
    nms     = Table.ColumnNames(from),
    EdStlb  = Table.CombineColumns(from, nms, f, "tmp"),
    TuStr   = Table.ExpandListColumn(EdStlb,"tmp"),
    TuStolb = Table.SplitColumn(TuStr,"tmp",(x)=>x,nms)
in  TuStolb  
---------------------------------------------------------------------------------------------


=============================================================================================
	РАЗВОРАЧИВАНИЕ КОЛОНОК 											* Table.ExpandTableColumn
=============================================================================================

// 	получаем список колонок в подтаблицах и разворачиваем тольно нужные столбцы
	list   = List.Select(List.Distinct(List.Combine(List.Transform(transf[Data],each Table.ColumnNames(_)))), each not Text.Contains(_,"Column")),
	expand = Table.ExpandTableColumn(transf, "Data", list),
	
==============================================================================================
	ЧИСТКА ТЕКСТА в колонке 									  * Table.TransformColumnNames
==============================================================================================
 /* функция получает таблицу и функцию генератора имен в качестве основных аргументов. 
	Функция генератора имен должна получать один текстовый аргумент (имя столбца) и возвращать 
	текст (преобразованное имя столбца). Это может быть встроенная функция, такая как 
	replacer.ReplaceText и Text.Proper, или любая созданная вами пользовательская функция 
*/

//  удаляет из названия колонки "_" меняя его на пробел / делает названия прописными
	to = Table.TransformColumnNames(from, каждый replacer.ReplaceText(_,"_", " "))
	to = Table.TransformColumnNames(from, Text.Proper)
	to = Table.TransformColumnNames(from, FnSplitCamelCase)

==============================================================================================
	ТРАНСФОРМАЦИЯ столбца  									  	      * Table.TransformColumns
==============================================================================================
//  Сделать потом Table.ReplaceValue
	https://gorilla.bi/sitemap/
	https://gorilla.bi/power-query/text-functions/#transform-text
	https://gorilla.bi/power-query/wildcards/ - сложные преобразования

//  1. Одна колонка 
	to = Table.TransformColumns(from, {"Название", f} )
	to = Table.TransformColumns(from, {"Название", f, type text} )
	to = Table.TransformColumns(from, {"Название", each _}, f)
	to = Table.TransformColumns(from, { tbl{1}, f, Int64.Type})

//  2. Несколько колонок (можно через lst = {"Column1","Column2"})
	to = Table.TransformColumns(from, List.Transform( {"Column1","Column2"}, each {_, f} ) )
	to = Table.TransformColumns(from, List.Transform( {"Column1","Column2"}, each {_, each Text.Split(_,", "), type list} ) )
	// или 
	to = List.Accumulate(
			{ "Column1", "Column1"}, 
			from,
			(state,current) => Table.TransformColumns(state, {current, each Text.Split(_, " " ) } // список слов в ячейке
		 )


// 	2. Несколько со сдвигом	(первые 2 не брать) + изменением типа
	to = Table.TransformColumns(from, List.Transform(List.Skip(Table.ColumnNames(from), 2), (x)=>{x, f, type text}) )

// 	делает все столбцы текстовые, кроме первых.
	(Source as table, Сдвиг)=>
		Table.TransformColumnTypes(Source, 
			let n = Table.ColumnNames(Source)
            in  { {n{0}, type number} } & List.Transform(List.Skip(n,Сдвиг), each {_, type text}))

in
    Пользовательская1

//  3. Все колонки
	to = Table.TransformColumns(from, {}, f)						// применяем условную функцию
	to = Table.TransformColumns(from, {}, Text.From) 				// делаем все колонки текстовыми
	to = Table.TransformColumns(from, {}, (x)=>Text.Split(x,",") 	// 
	
--------------------------------------------------------------------------------------------
// 	Пример текста "А 6-05-0611-04 Электронная экономика.xlsx"
// 	Как оставитьпервый символ и перед расирением
//  Удалить после . справа НО может нре удалять, а найти позиции нужных,Range + выбрать и оставить только их через Text Комбайн
	f=(x)=> 
	
// стандартные функции
	(x)=> Text.Clean						// type text проверить
	(x)=> Text.Trim(x, {" ", "!"})			// type text
	(x)=> Text.Remove(x, {"≛", "★"})		// type text
    (x)=> Date.FromText(Text.End(x, 10))	// type date
	(x)=> Number.FromText(x, "en_US")		// type number
	(x)=> "http://" & x						// type text
	(x)=> Text.From(x + 1), type text}		// type text к значению + 1

//  поменять во всех колонках "  " на null
	to = Table.TransformColumns(from,{},(x)=>if x=" " then null else x)

//  сравниваю столбец типа Time со списком типа Time. Третий аргумент не нужен
	to = Table.TransformColumns(TransformColumns,
        {"Время", (x)=> if List.ContainsAny({x}, Время[Начало]) = true then x else null}
    )
	
// 	Убрать нули в начале кода. 040 = 40 или 001 = 1
	f=(x)=> try Number.From(x) otherwise x

// 	убдать их текста все цифры, Text.ToList(x) - список всех символов
	f=(x)=>Text.Combine(List.RemoveItems(Text.ToList(x),{"0".."9"}),""),

// 	Убрать символы буквы из текста например из "100 руб" сделать "100"
	f=(x)=>Text.Trim(_,{"a".."я","А".."Я"," "})

//  удаляем из текста все непечатные символы
	lst = List.Buffer({#(lf)#(00A0)#(tab)}), 
	f=(x)=>Text.Combine( List.RemoveMatchingItems(Text.SplitAny(Text.Clean(x), clearData), {""}), " "),

//  удаляем из текста двойные пробелы (повтороящиеся)
	(x)=>Text.Combine(List.Select(Text.SplitAny(x,""),(x)=>x<>"")," ")

// 	Оставляем только буквы (англ+рус), пробелы и цифры. Можно еще Text.Upper(txt) сделать
	f=(txt as text) as any =>
		Text.Combine(
			List.RemoveItems(
				Text.Split(
					Text.Select(txt, (List.Transform({32, 48..57, 64..90, 1040..1071}, Character.FromNumber))), " "),{""})," ")

//  оставить только слова начинающиеся с большой буквы - универсальная функция!
	lst = List.Buffer({"А".."Я"}),
	f=(x)=>Text.Combine(List.Select(Text.Split(x," "),(x)=>List.Contains(lst,Text.Start(x,1)))," ")
		
// 	замена формата даты с проверкой значения на типа дата (например "март 23")
	f=(x)=> if   Value.Is(x,type date)
            then Date.ToText(x, "MMMM yy", "ru-RU")
            else x,

// 	оставляем в ячейке строки, НЕначинающиеся с цифры, остальные строки = Null. Если с большой буквы то Text.Proper
    f=(x)=> if List.ContainsAny ({ Text.Start(x,1) },{"0".."9"},Text.Contains) = true then null else x
	
//	удалить все символы в колонке из списка (один пробел убирается, т.к. по нему делается сплит)
	let tbl = #table({"адрес"}, {{"г. Гомель"},{"пос. Бобовичи"},{"Минская гор."}}),
		lst = List.Buffer({"г.","гор.","пос.","город"}), 
		f=(x)=>Text.Combine(List.RemoveItems(Text.Split(x," "),lst)," "),
		to = Table.TransformColumns(tbl,{"адрес",f})
	in  to
	
// 	Вытягиваем название из Параметра "Файл_источник" = полный путь. Пример прикрепить!
	f=(x)=>Text.AfterDelimiter(x, "\",  {0, RelativePosition.FromEnd}), 

//  проверить
	to = Table.TransformColumns(slc,{"b",(x)=>Text.Combine(List.Transform(x,Text.From),",")})
	to = Table.TransformColumns(slc,{"b",(x)=>Text.Combine(List.Transform(x,Text.From),",")})

// 	проверить если код строки в колонке Column3 (Код строки) - число 
    f=(x)=> try Value.Is(Number.From(x), type number) = true otherwise null
	// можно заменить обычным
	f=(x)=> try Number.From(x) otherwise null
		
//  Условия
	f=(x)=> try Number.From(x) otherwise null,
	f=(x)=> if x > 1000 then 1000 else x
			
// 	Викинги. Перевод Англ формата числа в обычное. 1,25 K или 32,4 В в целое число
// 	Поменять на число значение без одного последнего знака заменив предварительно "." на ","
	f=(x)=> if Text.End(x, 1) = "K" 
			then 1000 * Number.From(Text.Replace(Text.Start(x,Text.Length(x)-1),".",",")) 
			else Number.From(Text.Replace(x,".",","))

// 	пробел перед большими буквами в строке + супертрим надо
	f=(x)=> Text.Combine( List.Transform( Text.ToList(x), each if Text.Upper(_) = _ then " " & _ else _) )
	
// 	формат номера телефона - на входе 79019922332
	to = Table.TransformColumns(#"Inserted Month", {"телефон 1", (x) => Number.ToText(x, "+0 (000) 000-0000")})


--------------------------------------------------------------------------------------------
//  Чистка текса: убрать буквы из текста например 100 руб сделать 100
	{"Цена", each Text.Trim(_,{"a".."я","А".."Я"," "}, type text)}  // возможно еще to = Table.TransformColumns(tbl, {} , "en-US")

--------------------------------------------------------------------------------------------
//	сохраняем только буквы (англ+рус), пробелы и цифры. Они представлены ASCII-кодами
/*	TextCleaner = (txt as text) as any =>
		Text.Combine(List.RemoveItems(Text.Split(Text.Select(txt, (List.Transform({32, 48..57, 64..90, 1040..1071}, Character.FromNumber))), " "),{""})," ")
*/
	TextCleaner = (txt as text) as any =>
		Text.Combine(
			List.RemoveItems(
				Text.Split(
					Text.Select( // выбираем символы удовлетворязие условию
						txt, 
						(List.Transform({32, 48..57, 64..90, 1040..1071}, Character.FromNumber))
					)," "
				),{""}
			)," "
		)
	to = Table.TransformColumns(from, {"Грузополучатель", TextCleaner})

--------------------------------------------------------------------------------------------
// Проверка значения на дату и замена на например "март 23"
	f = (x) =>  if   Value.Is(x,type date)
                then Date.ToText(x, "MMMM yy", "ru-RU")
                else x,
    to = Table.TransformColumns(AddPotok, {"Срок", f} )

--------------------------------------------------------------------------------------------
//  ПРЕОБРАЗОВАНИЕ бинарного файла (в списке файлов в папке) в таблицу: Binary => Table
	to = Table.TransformColumns(tbl, {"Content", (x)=>Excel.Workbook(x)} )
	to = Table.TransformColumns(tbl, {"Cur_Code", each try Number.From(_) otherwise _})  // убрать нули в начале кода. 040 = 40,001 = 1

// ---------------------------------------------------------------------------------
	[ 	a = "_laze", 
		b = Text.PositionOf( a, "_"  ),			// находит позицию
		c = Text.RemoveRange( [Words], b, 1 ),  // удаляет символ из этой позиции
		d = Text.Remove( a, "_" ),				// удаляет символ из исходной позиции	
    ][d] 

// ----------------------------------------------------------------------------------
// Далее мы используем List.Transform для возврата значения null для каждого значения, 
// равного одной из позиций '_' (replaceWnull). Затем мы удаляем нулевые значения из 
// списка (cleanedList) и снова объединяем символы (finaltext). Мы удаляем все 
// подчеркивания из искомого значения (cleanSearchValue) и сравниваем его с преобразованным 
// значением (результатом). Теперь вы получите все символы, соответствующие вашему запросу.

	= Table.SelectRows (Source, each [
		searchvalue  = "B_a_e",
		charList     = Text.ToList ( [Words] ),
		_positions   = Text.PositionOf ( searchvalue, "_", Occurrence.All ),
		retrieveList = List.Difference( {0..Text.Length(searchvalue) }, _positions ),
		extract      = List.Transform( retrieveList, each charList{_}? ),
		result       = Text.Remove( searchvalue, {"_"}) = Text.Combine( extract )
		][result]
	)
	
	= Table.SelectRows ( Source, each [
		searchvalue      = "B_a_e", 
		positions        = Text.PositionOf ( searchvalue, "_", Occurrence.All ), 
		charList         = Text.ToList ( [Words] ), 
		zippedlist       = List.Zip ( { charList, List.Positions ( charList ) } ), 
		replaceWnull     = List.Transform (zippedlist, each if List.Contains ( positions, _{1} ) then null else _{0} ), 
		cleanedList      = List.RemoveNulls ( replaceWnull ), 
		finalText        = Text.Combine ( cleanedList ), 
		cleanSearchValue = Text.Remove ( searchvalue, "_" ), 
		result           = finalText = cleanSearchValue
	  ][result]
	),
	
	= Table.SelectRows (Source, each [
		search         = "Bla[dzf]e", 
		searchposition = Text.PositionOf ( search, "[" ), 
		searchText     = Text.BetweenDelimiters ( search, "[", "]" ), 
		searchList     = Text.ToList ( searchText ), 
		cleanSearch    = Text.RemoveRange ( search, searchposition, Text.Length ( searchText ) + 2 ), 
		cleanWords     = Text.RemoveRange ( [Words], searchposition, 1 ), 
		wildcardChar   = Text.Range ( [Words], searchposition, 1 ), 
		wildcardMatch  = List.Contains ( searchList, wildcardChar, Comparer.OrdinalIgnoreCase ), 
		result         = cleanWords = cleanSearch and wildcardMatch
	  ][result]
	),
	
	= Table.SelectRows (Source, each [
		search         = "Bla[^zf]e", 
		searchposition = Text.PositionOf ( search, "[" ), 
		searchText     = Text.BetweenDelimiters ( search, "[^", "]" ), 
		searchList     = Text.ToList ( searchText ), 
		cleanSearch    = Text.RemoveRange ( search, searchposition, Text.Length ( searchText ) + 3 ), 
		cleanWords     = Text.RemoveRange ( [Words], searchposition, 1 ), 
		wildcardChar   = Text.Range ( [Words], searchposition, 1 ), 
		wildcardMatch  = not List.Contains ( searchList, wildcardChar, Comparer.OrdinalIgnoreCase ), 
		result         = cleanWords = cleanSearch and wildcardMatch
	  ][result]
	)

// ------------------------------------------------------------------------	
	= Text.Trim( "- -gorilla- - ", { "-", " " } ) // Returns "gorilla"
	= Text.Length( "Rick" )      // Returns 4

	= Text.Split( "06-18-18-22", "1" )    // Returns { "06-", "8-", "8-22" }
	= Text.Split( "06-18-18-22", "-" )    // Returns { "06", "18", "18", "22" }
	= Text.SplitAny( "06-18-18-22", "-" ) // Returns { "06", "18", "18", "22" }
	= Text.SplitAny( "6|8|8-2", "-|" )     // Returns { "6", "8", "8", "2" } // multiple separators, Text.SplitAny does not require a list.
	= Text.SplitAny( "RickDeGroot", "er" ) // Returns { "RickD", "G", "oot" }
	
	= Text.ToList( "Rick" ) // Returns { "R", "i", "c", "k" }
	
	= Text.Replace( "I enjoy sunny days", "enjoy", "love" ) // Returns "I love sunny days"
	= Text.Replace( "my friend sees my show", "my", "his" ) // "his friend sees his show"
	= Text.ReplaceRange( "RickVanGroot", 4, 3, "De" ) // Returns "RickDeGroot"
	= Text.ReplaceRange( "RickVanGroot", 4, 3, "" )   // Returns "RickGroot"

	= Text.Contains( "Red roses", "Red" )                             // Returns true
	= Text.Contains( "Red roses", "red" )                             // Returns false
	= Text.Contains( "Red roses", "red", Comparer.Ordinal )           // Returns false
	= Text.Contains( "Red roses", "red", Comparer.OrdinalIgnoreCase ) // Returns true

	= Text.StartsWith( "I got the Power", "I got" )                             // true
	= Text.StartsWith( "I got the Power", "i got" )                             // false
	= Text.StartsWith( "I got the Power", "i got", Comparer.Ordinal )           // false
	= Text.StartsWith( "I got the Power", "i got", Comparer.OrdinalIgnoreCase ) // true
	 
	= Text.EndsWith( "Biking to home", "home" )                             // true
	= Text.EndsWith( "Biking to home", "HOME" )                             // false
	= Text.EndsWith( "Biking to home", "HOME", Comparer.Ordinal)            // false
	= Text.EndsWith( "Biking to home", "HOME", Comparer.OrdinalIgnoreCase ) // true
	
	= Text.PositionOf( "We all want pasta", "a" ) 					// Returns 3
	= Text.PositionOf( "We all want pasta", "a", Occurrence.First ) // Returns 3
	= Text.PositionOf( "We all want pasta", "a", 0 ) 				// Returns 3
	= Text.PositionOf( "We all want pasta", "a", Occurrence.Last ) 	// Returns 16
	= Text.PositionOf( "We all want pasta", "a", 1 ) 				// Returns 16
	= Text.PositionOf( "We all want pasta", "a", Occurrence.All ) 	// returns { 3, 8, 13, 16 }
	= Text.PositionOf( "We all want pasta", "a", 2) 				// returns { 3, 8, 13, 16 }
	= Text.PositionOf( "We all want pasta", "a", Occurrence.All ) {1}  	// returns 8
	= Text.PositionOf( "We all Want pasta", "w", 1 ) 					// returns -1
	= Text.PositionOf( "We all Want pasta", "w", 1, Comparer.OrdinalIgnoreCase ) // returns 7
	
	= Text.PositionOfAny( "You like guacemole", { "e" } )      // Returns 7
	= Text.PositionOfAny( "You like guacemole", { "e", "u" } ) // Returns 2
	= Text.PositionOfAny( "You like guacemole", { "e", "u" }, Occurrence.First ) // 2
	= Text.PositionOfAny( "You like guacemole", { "e", "u" }, Occurrence.Last )  // 17
	= Text.PositionOfAny( "You like guacemole", { "e", "u" }, Occurrence.All )   // Returns { 2, 7, 10, 13, 17 }
	
	= Character.ToNumber( "!" )  // Returns 33
	= Character.FromNumber( 33 ) // Returns "!"
	= Character.FromNumber( 35 ) // Returns "#" // You can return the unicode characters representing 33-35:
	= { "!" .. "#" } // Returns = { "!", """", "#" }
	

============================================================================================
	ТИПИЗАЦИЯ столбцов 											* Table.TransformColumnTypes
============================================================================================

// 	Проверить!!!
	to = Table.TransformColumnTypes(Source, {"Назначение платежа", Text.Type})

//  cтандартный способ
	to = Table.TransformColumnTypes(Источник,{
            {ColNames{0}, type text}, 
            {ColNames{1}, Int64.Type}
		 })

// столбцы по списку
	cols = {"t1","t2","t3","t4"}
	to = Table.TransformColumnTypes(from, List.Transform(cols, each {_, Int64.Type}))
		
//  все столбцы
	to = Table.TransformColumnTypes(from, List.Transform(Table.ColumnNames(from), (x)=>{x,type text}) )
	to = Table.TransformColumnTypes(from, List.Transform(Table.ColumnNames(skip), each {_,type text}) )    
	                                       

// 	Делаем всем колонками после девятой числовой тип
	to = Table.TransformColumnTypes(from, List.Transform(List.Skip(Table.ColumnNames(from), 9), (x)=>{x,Int64.Type} )),

// 	Два столбца текстовые, остальные числовые. Проверить скип
	nms  = Table.ColumnNames(from), 
	Skip = 3
	to   = Table.TransformColumnTypes(from, 
			{ {nms{0}, type text}, {nms{1}, type text} } 
			& 
			List.Transform( List.Skip(nms, Skip), each {_, type number} 
		  )
 

// 	Типизация данных по маске названия колонки
    TransformColumnTypes = 
        let dlst = List.Select(ColNames, (i)=>Text.Contains(i,"Дата")),
            nlst = List.Select(ColNames, (i)=>List.Contains({"Сумма","Код"}, i, (x,y)=>Text.Contains(y,x))),
            tlst = List.Difference(ColNames, dlst & nlst),
            f=(x,y)=>List.Transform(x, (i)=>{i,y}),
            slst = f(dlst, Date.Type) & f(nlst, Number.Type) & f(tlst, Text.Type),
            to   = Table.TransformColumnTypes(from, slst)
        in  to,

// 	часть столбцов одним типом, часть другим
	to = Table.TransformColumnTypes(from,
			List.Transform(datlst,(i)=>{i,Date.Type}) &
			List.Transform(txtlst,(i)=>{i,Text.Type})
		 )

============================================================================================
// ПРЕОБРАЗОВАНИЕ бинарного файла (в списке файлов в папке) в таблицу: Binary => Table
	// Table.TransformColumns
	// Преобразование в нескольких столбцах. 
	// Подробнее: https://bondarenkoivan.wordpress.com/2017/11/15/transform-columns-with-list-zip/#more-1531
	let
		Source = population_by_0,
		f = each if Text.Contains(_, "район") then Text.Upper(_) else _ , // если в значениях есть эти символы / слово то меняем а на А
		result = Table.TransformColumns(
					Source,
					List.Transform( {"region", "name"}, each { _, f } ) 	// вот тут особенность
			)
	in result
	//вариант 2
		result = Table.TransformColumns(Source, {"region", each _ },f ) // если одна колонка

=== Столбец по номеру ======================================================================
// 	номер стобцца - 1, т.к. с нуля нумерация
	to = Table.SelectRows (Source, each Record.FieldValues(_){3-1} <> "null" // фильтруем столбец №2 независимо от его имени

// 	или функция 
	f=(x)=>Record.FieldValues(x){3-1} <> "null"

// по имени столбца
	let
		tbl = Excel.CurrentWorkbook(){[Name="Таблица1"]}[Content],
		x = List.PositionOf(Table.ColumnNames(tbl),"НужныйСтолбец"),
		addClmn = Table.AddColumn(tbl,"НовыйСтолбец", each Record.FieldValues(_){x-2})
	in
		addClmn

===[ Значние в списке перед заданным словом ]=================================================

// 	return {"123","28.01","321.1","Анализ"},
	let lst = {"123","Анализ","abc","28.01","Анализ","321.1","Анализ","QWERTY"},
		to = List.Transform(List.PositionOf(lst,"Анализ",Occurrence.All),(x)=>lst{x-1})
	in  to 
	
===[ Перегруппировка столбцов в заданном порядке ]============================================

//  {1,2,3,4,5,6} - порядо столбцов. Если столбцов меньше, то они и не выводятся
	to = Table.SelectColumns(from, List.Transform({1,2	,3,4,5,6}, (x)=>Table.ColumnNames(from){x-1}) )


=== Способ загрузки таблицы с листа ============================================================
let
    f=(x)=>Excel.CurrentWorkbook(){[Name=x]}[Content],
    from = f("Анкеты"),
in  from

=== Аналоги ВПР ============================================================
// Варианты подстановки значений из другой таблицы
// 1. Join - подставляет все столбцы (если только название не одинкаовое и там и там, пока не понял почему так и какс сделать 1 колонку при РАЗНЫх названиях)
// 2. Record.Field - справочник+поле, нка подстановки
to1 = Table.Join(Record, "Товар", dProduct, "Product")	 // все столбцы добавляются из справочника 
to2 = Table.Join(Record, "Product", dProduct, "Product") // только один столбец

to = Table.AddColumn(from, "Price1", each Record.Field(dProduct{ [Product = [Товар] ] }, "Price"), type number)
to = Table.AddColumn(from, "Price2", each dProduct{[Product=[Товар]]}[Price], type number)

// подстановка размера скидки из таблицы скидок по диапазонам
let
    Source  = fSales,
    tblDisc = Table.Buffer(dDiscount),	// таблица скидок
    Start   = tblDisc[Discount]{0},		// начальная строка в таблице скидок
    Count   = Table.RowCount(tblDiscount)-1,	// всего строк в таблице скидок
    
    To = Table.AddColumn(Source, "Discount", each 
        List.Accumulate(
            {0..Count},
            Start,
            (Discount,index) => 
                if [Units] >= tblDisc[Units]{index} 
                then tblDisc[Discount]{index} 
                else Discount
        )
    )

in To

=== Правильная сортировка списка с столбце =================================
// В столбце есть оглавление такого типа: 1, 2.1, 1.2.3, 2.3.4 и т.п
// чтобы оно правильно ипоследовательно нумеровалось надо короче всего вот так
// https://www.planetaexcel.ru/forum/index.php?PAGE_NAME=read&FID=1&TID=118488
// идея https://social.technet.microsoft.com/Forums/en-US/0d7620e1-46a3-4b6e-8ccd-b01d86aa9b07/dynamicly-renumber-heirarchal-numerical-titles
// Суть. Преобразует текстовое значение посимвольно в двоичный код и его уже сортирует
// [Дано] - колонка со списком, [а] - колонка с двоичным представлением
let
    Source = Excel.CurrentWorkbook(){[Name="Таблица1"]}[Content],
    GetHex = Table.AddColumn(Source, "a",(_)=>Binary.ToText(#binary(Expression.Evaluate(Text.Replace("({"&[Дано]&"})",".",","))),1)),
    Sorted = Table.RemoveColumns(Table.Sort(GetHex,{{"a", Order.Ascending}}),{"a"})
in  Sorted
	
=== Функция замены Jan на 1 =================================================
//  Функция замены Краткого названия месяца на номер
	dict = Record.FromList({1..12},List.Transform({1..12},(x)=>Text.Start(Date.MonthName(#date(2023,x,1),"en"),3))),
	f=(x)=>Record.Field(dict,x)

=== Трансформация =================================
let
    Источник  = Excel.Workbook(File.Contents(Path), null, true){[Item="Sheet1",Kind="Sheet"]}[Data],
    Headers   = Table.PromoteHeaders(Источник, [PromoteAllScalars=true]),
    Transform = Table.TransformColumns(
        Headers,{
            {"Тип", Text.From, type text},
            {"ДТ",  Text.From, type text},
            {"КТ",  Text.From, type text},
            {"Дата отчёта",     Date.From, type date},
            {"Номер отчёта",    Number.From, Int64.Type},
            {"Дата документа",  Date.From, type date},
            {"Номер документа", Text.From, type text},
            {"Контрагент",      Text.From, type text},
            {"Сумма",           Number.From, type number}
        })
in Transform
	
------------------------------------------------
=== Фильтрация =================================
------------------------------------------------
// Все строки где первая знак <> числам от 0 до 9
// Номер столбца определяется через Record.Field
let   
    a = Excel.CurrentWorkbook(){[Name="Таблица1"]}[Content],
    b = List.Buffer(Table.ColumnNames(a)),
    f =(x)=> not List.ContainsAny({x}, {"0".."9"}, Text.Contains),
    c = Table.SelectRows ( a, ( r ) => f ( Record.Field ( r, b{0} ) ) )  // b{0} = столбец 1 сиз списка всех столбцов
in
    c

=== ФИО с инициалами =================================
// Вариант 1 - Ф + И + О
	to = Table.AddColumn(#"Измененный тип1", "ФамилияИО", 
		each let splitФИО = Splitter.SplitTextByDelimiter(" ", QuoteStyle.None)([ФИО]) 
			 in Text.Combine(
				{splitФИО{0}?, 
				" ", 
				Text.Start(List.RemoveLastN(List.RemoveFirstN(splitФИО, 1), 1){0}?, 1), ".", Text.Start(List.Last(splitФИО), 1), "."}), type text)
// Вариант 2 - если И + О + Ф
	to = Table.AddColumn(from, 
			"ФамилияИО", each 
				let SplitFIO = Splitter.SplitTextByDelimiter(" ", QuoteStyle.None)([ФИО]) 
				in  Text.Combine({
						Text.Proper(List.Last(SplitFIO)), " ", 
						Text.Combine(
							List.Transform(
								{SplitFIO{0}?,List.RemoveLastN(List.RemoveFirstN(SplitFIO, 1), 1){0}?}, each Text.Start(_, 1)), "."), "."
								{SplitFIO{0}?,List.RemoveLastN(List.RemoveFirstN(SplitFIO, 1), 1){0}?}, each Text.Start(_, 1)), "."), "."
					}), 
			type text)
					
=== МНОЖЕственнаЯ Замена  Михаила =================================

Пора закрыть тему замен в тексте. Мы уже приматывали "словарь на записях" 
для замены значения целиком (https://t.me/pbi_pq_from_tank/131)  и 
для посимвольных замен (https://t.me/pbi_pq_from_tank/149), но бывают 
ситуации, когда необходимо осуществить замену внутри текста, причём имеется ряд вариантов. 
Тут уже не обойтись без Text.Replace и я не знаю более шустрого варианта, чем запихнуть это в List.Accumulate. Поэтому просто разберем пример:

// 	Вариант 1. ЛУЧШЕЕ и понятное решение "замена по словарю"!!! РАБОТАЕТ
	let
		tbl  = Excel.CurrentWorkbook(){[Name="Конструкция"]}[Content], 	// таблица со списком замен ЧтоМенять/НаЧтоМенять
		dict = Record.FromList(tbl[НаЧтоМенять],tbl[ЧтоМенять]),		// делаем из нее словарь. Вначале НаЧто, потом Что!!!	
		from = Excel.CurrentWorkbook(){[Name="Таблица"]}[Content],		// исходная таблица
		f=(x)=>Record.Field(dict,x),									// функция замены
		to   = Table.TransformColumns(from,{"Format",f})				// меняем в колонке - не целиком ячейку, только "СОВПАДЕНИЯ" символов
	in
		to

// Вариант 2. Замена в тексте. Сверить с предыдущим вариантом можно РАБОТАЕТ. Быстро! 
    MultiReplace = 
        let 
			dict = List.Buffer({{"АРТЕМ","+"},{"о","-"}}),
            f=(x)=>List.Accumulate(dict, x, (s,c)=>Text.Replace(s,c{0},c{1})),
            to   = Table.TransformColumns(Transform,{"Ответ",f})
        in  
			to,

// Вариант 2+. Исходник по другому
	let
		tbl  = #table({"текст","число"},{{"мама мыла раму",1},{"отмыла мамочка рамочку",2}}),
		tb2  = #table({"что","на что"},{{"мам","пап"},{"мыла","пил"},{"рам","пив"}}),
		dict = List.Buffer(Table.ToList(tb2,(x)=>x)),
		f=(x)=>List.Accumulate(dict,x,(s,c)=>Text.Replace(s,c{0},c{1})),
		to   = Table.TransformColumns(tbl,{"текст",f})
	in
		to

// Вариант 3. Замена по словарю используя Table.ReplaceValue
// https://www.planetaexcel.ru/forum/index.php?PAGE_NAME=message&FID=1&TID=126656&TITLE_SEO=126656-power-query-zamena-dannykh-v-massive-na-osnove-spravochnika&MID=1045914&tags=&q=power+query+%D0%B4%D0%B0%D1%82%D0%B0+%D1%84%D0%B5%D0%B2%D1%80%D0%B0%D0%BB%D1%8F&FORUM_ID%5B0%5D=0&DATE_CHANGE=0&order=relevance&s=%D0%9D%D0%B0%D0%B9%D1%82%D0%B8#message1045914
	let graphs = Excel.CurrentWorkbook(){[Name="График"]}[Content],
		dict   = Excel.CurrentWorkbook(){[Name="Справочник"]}[Content], // 2 колонки, что(наименование) + начто (количество)
		nms    = List.Skip(Table.ColumnNames(graphs), 1), // в каких колонках менять
		result = Table.ReplaceValue(graphs, null, null, (s, o, n) => dict{[Наименование=s]}?[Количество]?, nms)
	in  result
	
=== Замена в нескольких колонках =================================

let
    Источник = Excel.CurrentWorkbook(){[Name="Страны_по_группам"]}[Content],
    replace_nulls = Table.ReplaceValue(
		Источник, 
		null, 
		0, 
		Replacer.ReplaceValue, // функция замены: (curValue, olValue, newValue) => if curValue = 1 then newValue else "Прочие",
		List.Skip(Table.ColumnNames(Источник))	// вот тут список столбцов. Так можно задавать несколько"
	),


=== Замена в колонке =================================

	to = Table.ReplaceValue(Тип1, 
			each [Тип], 
			each Record.FieldOrDefault(
					[1 = "Пехота",2 = "Кавалерия",3 = "Стрелки", 4 = "Убийцы", 5 = "Осадные", 6 = "Шпионы"], 
					Text.From([Тип]	 ), 
			[Тип]),
			Replacer.ReplaceValue, 
			{"Тип"}	
	),

============================================================================================
	Замена по справочнику							  * Table.ReplaceValue разными способами 
============================================================================================

	let
		from = Table.PromoteHeaders(Excel.Workbook(File.Contents("C:\Users\muzyk\Desktop\Тест\Справочник.xlsx"), null, true){0}[Data]),
		to = Record.FromList(
			Table.ToList(from,List.Skip),				
			List.Transform(from[Название],Text.From)	// список числовой делаем тектовым
		)
	in to
	// на выходе запись 1,2,3,4 где значениями являептся списки (в данном случае даты - начало и окончание)
	
	
=== Функция преобразования числа в месяц =================================

	f=(x)=>Text.Lower(Date.MonthName(#date(2022,x,1),"en-US"))
	
	// Единственное, о чём следует позаботиться — о том, чтобы функция возвращала не просто значение, 
	// а значение, являющееся элементом массива:

	f=(x)=>{Text.Lower(Date.MonthName(#date(2016,x,1),"en-US"))}

============================================================================================
	ЧИСТКА строк ДО / ПОСЛЕ 										* Before Row + After Row
============================================================================================
//  #АнатомияФункций - Table.FindText – или ищем текст где-то в таблице 

	source = Content{[Item="1",Kind="Sheet"]}[Data],

//  функция поиска строки с хаданным текстом
    f=(x)=>(y)=>not Text.Contains(Text.Combine(List.Select(Record.ToList(y),(i)=>i is text)),x),

//  удаляем строки ДО строки с текстом    
	skip    = Table.Skip(source,f("Наименование статей")),
    promote = Table.PromoteHeaders(skip),

// 	удаляем строки ПОСЛЕ строки с текстом
    to = Table.RemoveLastN(promote, f("Тара под товарами и порожняя ")),

// ФУНКЦИЯ (сокращение того, что ниже)
// Ищет слово и удаляет то что ниже и то что слева делая эту строку заголовком!!
	f=(table,name)=>
		[a = Table.PromoteHeaders(Table.Range(table,Table.FindText(Table.AddIndexColumn(table, "i"),name){0}[i])),
		b = Table.ColumnNames(a),
		c = Table.SelectColumns(a,List.Range(b,List.PositionOf(b,name,Occurrence.First,Text.Contains)))][c]
	
// Рабочий код!!!!***************
// обработка без верах и низа
	del = Table.SelectColumns(Content,{"Name", "Data"}),  // столбец Data с сожержимым Table (это содержимое отчетов)
    
    g=(x)=>(y)=>List.Select(Record.ToList(y),(i)=>i is text and Text.Contains(i,x))={}, // функция удаления строк ДО
    
	f=(x)=>[ a = Excel.Workbook(x){0}[Data],  				// если надо обработать файлы Binary, еще не преобразованные в Table
             b = Table.Skip(x, g("Наименование статей") ), 	// удаляем все строки ДО строки с таким текстом
             c = Table.PromoteHeaders(b),					// поднимаем заголовки
             d = Table.Range(c,1),							// получили таблицу начиная со найденной строки и вниз
             e = Table.RemoveLastN(d,g("Итого")),			// удаляем все строки после строки с этим текстом
             f = Table.RemoveLastN(e,1)						// если надо убрать и найденную строку
		   ][e],
        
    from2 = del[Data],				  // СПИСОК - получили список файлов с содержимым Table
    tr    = List.Transform(from2, f), // СПИСОК - именно тут - ПРЕОБРАЗОВАЛИ СОДЕРДЖИМОЕ, отфильтровав строки До и ПОСЛЕ
    tbl   = Table.Combine(tr),        // раскрыли все в одну таблицу (вместе Expand!)
    nms   = List.Select(			  // получили список столбцов, в которых нет столбцуов с текстом в имени	
				Table.ColumnNames(tbl),
				(i)=>not List.ContainsAny({i},{"Column","Столбец","Номер"},Text.Contains)
			),
    to    = Table.SelectColumns(tbl,nms)  // выбрали только нужные столбцы, без лишних

==============================================================================
	FAQ 
==============================================================================
	https://learn.microsoft.com/ru-ru/powerquery-m/m-spec-lexical-structure

//  определяем функцию используемую в функции, в которой есть итератор над элементами
	fn = (x) => Record.FieldCount(x),

//  в данном случае AddColumn выполняет итерацию по строкам (записям record) и ждёт функцию с одним аргументом типа record
	result1 = Table.AddColumn(Source, "field count", fn),

// 	а можно и неявной функцией итерации у которой аргумент _
	result2 = Table.AddColumn(Source, "field count", each Record.FieldCount(_)),

// 	а можно указать функцию анонимно без определения имени
	result3 = Table.AddColumn(Source, "field count", (x) => Record.FieldCount(x))

==================================================================
// Важно
// добавил в Table.Combine параметр Value.Type ( typed ) (typed - это имя шага с изначальной таблицей),
// чтобы сохранялись типы всех столбцов, и комментарии к каждому шагу.
//https://www.planetaexcel.ru/forum/index.php?PAGE_NAME=read&FID=1&TID=145177&TITLE_SEO=145177-power-query-gruppirovka-pri-peremennom-kolichestve-gruppiruemykh-stolbtsov
	let
	  src        = Excel.CurrentWorkbook(){[ Name = "data" ]}[Content],
	  clmnNames  = List.Buffer ( Table.ColumnNames ( src ) ), 
	  groupClmns = { "Код", "Артикул" }, 
	  group = Table.Group (
		src, 
		groupClmns, 
		{ { "tmp", ( x ) => Table.FromColumns ( List.Transform ( Table.ToColumns ( x ), ( y ) => { List.Max ( y ) } ), clmnNames ) } }
	  ), 
	  // Все таблицы (которые сформировались по каждой группировке) из столбца [tmp] объединяем: 
	  // добавил в Table.Combine параметр Value.Type ( typed ) (typed - это имя шага с изначальной таблицей), !!!
	  // чтобы сохранялись типы всех столбцов, и комментарии к каждому шагу. 
	  combine = Table.Combine ( group[tmp], Value.Type ( from ) )
	in
	  combine

================================================
===[ ПОЛЕЗНОСТИ ]=========================================================================================
// Важно!		пример бы сделать исходных данных

// Новый способ обращения к таблице Name=x это f("Таблица2") 
// Источник: чат для тех кто в танке
let
    f=(x)=>Excel.CurrentWorkbook(){[Name=x]}[Content],
    g=(x)=>Number.From(Record.FieldOrDefault(dict,x[ФИО водителя],[])=x),
    dict=[a=f("Таблица1"),b=Record.FromList(Table.ToRecords(a),a[ФИО водителя])][b],
    to=Table.AddColumn(f("Таблица2"),"Статус",g)
in
    to
		
----------------------------------------------------------------------------------------------------------
// 	Хороший пример использования переменной x. Запихиваем в функцию имя колонки
//  to = Excel.CurrentWorkbook(){[Name="Яблоки"]}[Content]
	f=(x)=>Excel.CurrentWorkbook(){[Name=x]}[Content],  
	to = Table.SelectRows( f("Яблоки"), (tbl)=> g(tbl[Столбец1]) ) 		
		
============================================================================================
//  ВЫБИРАЕМ КОЛОНКИ (надо получить колонкцу с макссуммой в колонках в суммой (есть колонки название, цена, количество, сумма и много таких)
	// 	Вариант 1: Отбираем колонки, в которых находится слово
		to = List.Select(Table.ColumnNames(src), (x)=>Text.Contains(x, "сумма"))

	//	Отбираем строки данные в которых имеют вид список
		to = List.Select(src, (x)=>x is list)

	// 	Допколонка с Максимальной сумма по столбцам с "Сумма" в названии
		Sum = Table.AddColumn(src, "max2", (r)=>List.Max(Record.FieldValues(Record.SelectFields(r, nms))))
	
	// 	Вариант 2: Получаем список номеров колонок, в которых есть "Сумма" в названии
		to  = List.Buffer(List.PositionOf(TCN, "сумма", Occurrence.All, (v, x)=>Text.Range(v,0,5)=x)) // 5 - число знаков в "Сумма"
		Sum = Table.FromList(Table.ToRows(Source), (row)=>row & {List.Max(List.Transform(Pos, (position)=>row{position}))}, TCN & {"Max"})
	
============================================================================================
 // ЗАГРУЗКА 
 
  // 1. Файл из интернета (как файл, в оперативку, при каждом обновлении грузит его)
  from = Pdf.Tables(Web.Contents("https://epfr.gov.by/file/107728/content"), [Implementation="1.3"])

	// Загрузка таблицы по условию Колонка=Значение
	from = Source{[Item="IncomeStatementLayout",Kind="Table"]}[Data]


============================================================================================
	// Table.TransformColumns
	// Преобразование в нескольких столбцах. 
	// Подробнее: https://bondarenkoivan.wordpress.com/2017/11/15/transform-columns-with-list-zip/#more-1531
	let
		Source = population_by_0,
		f = each if Text.Contains(_, "район") then Text.Upper(_) else _ , // если в значениях есть эти символы / слово то меняем а на А
		result = Table.TransformColumns(
					Source,
					List.Transform( {"region", "name"}, each { _, f } ) 	// вот тут особенность
			)
	in result
	//вариант 2
		result = Table.TransformColumns(Source, {"region", each _ },f ) // если одна колонка
	
============================================================================================
// ОБРАБОТКА подтаблиц
	
	// обработка второй строки (листа 2) внутри файла в колонке с Table
	f=(x)=>[ a0 = x{1} [Data],				// лист 2 в книге где несколько листов
			 a1 = Table.Skip(a0, 34),
			 a2 = Table.SelectColumns(a2, {"Column1", "Column3"})
		   ][a2],
  
    tr = Table.TransformColumns(tbl,{"Content",f})

	// обработка листа в зависимости от имени файла!!!
    f1=(x)=> Table.Skip(x, 20),
    f2=(x)=> Table.Skip(x, 2),
    
    to = Table.AddColumn(from, "NewColumn", 
            each if [Id] = "Page001" 
            then Table.Skip([Data], 20) // или f1( [Data] )
            else let a = Table.Skip([Data], 7)
                 in Table.SelectRows(a, each [Column3] = "450") // или через [ a= ..., b = ...] [b]
    )
in
    to

//  оставить в подтаблице только листы, название которых имеет числовой тип
	f=(x)=>Table.SelectRows(x, each try Value.Is( Number.From([Name]), type number) = true otherwise null)
	tr = Table.TransformColumns(Date,{"Content", f})

============================================================================================
	// Фильтрация в подтаблице с добавлением индекса!!!
    TransformColumns = Table.TransformColumns(Источник,
        {"Data", each Table.SelectRows(
                        Table.AddIndexColumn(_,"Index",1,1),            // добаляем колонку индекса
                        each List.Contains({13..89,93..116}, [Index])   // фильтруем по колонке Index
                      ) [[Index],[Column1],[Column2],[Column3]]         // оставляем посте фильтрации нужные колонки
        }
    ),

============================================================================================
	// ******************************** очень полезный прием ***
	// Изменения в САМОЙ колонке!!!! 
	// ***************************** 
	// если цифра первыя то ноль иначе значение
	f  = (x)=> if List.ContainsAny ( { Text.Start(x,1) },{"0".."9"},Text.Contains) = true then null else x,
    tr = Table.TransformColumns(from, { "Колонка1", f, type text} )  // если в одной колонке. Если к нескольких обернуть еще раз { }
	
	// Изменения ВНУТРИ таблицы функцией f
    f=(x)=>
        [ f2 =(x)=> List.ContainsAny ( { Text.Start(x[Column1],1) },{"0".."9"},Text.Contains),    // Фильтр - первый знак число
          a = Table.SelectRows(x, f2),                             // трансформируем вложенную таблицу 
          b = Head & a,                                            // объединяем шапку и тело таблицы
          c = Table.PromoteHeaders(b, [PromoteAllScalars=true] )   // повышаем заголовки
        ] [c],

	to = Table.TransformColumns(AddColumn,{"Page", f})
	
/*  ТАК НЕ РАБОТАЕТ. Трансформом внутри таблицы действует. Только черех добавление новой колонки!
    to = Table.TransformColumns(AddColumn, {"new", each if [Id] = "Table001" 
                                                then Table.TransformColumns(AddColumn, {"new", fn1})
                                                else Table.TransformColumns(AddColumn, {"new", fn2}) }
*/	
===========================================================================================
	// СИНТАКСИС List.Intersect(Text.ToList([Номер]),[Название][Номер]) 
	    
    fn = (x)=>  if each x[Id] = "Table1"
                then 
                    let a   = Table.AddColumn(x, 
                        b   = Table.AddColumn(a, 
                    in  b
                else 
                    let 
                        a  = Table.AddColumn(x, 
                        b  = Table.AddIndexColumn(a, 
                    in  b,
	
===========================================================================================
	// НОВАЯ КОЛОНКА.  Там где есть слова из списка - будет пусто
    AddColumn   =	Table.AddColumn(PromoteHeaders, 
						"Факультет", 
                        each if List.ContainsAny( 
                                    { [Специальность] }, 
                                    { "факультет","институт","Факультет","Институт" }, 
                                    Text.Contains ) = true 
                        then [Специальность] 
                        else null),
						

==== Замена типа данных ====================================================================

to = Table.TransformColumnTypes(from, 
			List.Transform(cols, each {_, Int64.Type})
		)    
	// Все колонки текстовые 
	to = Table.TransformColumnTypes(from, 
			List.Transform( Table.ColumnNames(from), (x)=>{x,type text} ) 
		 ),
		 
	
	// Делаем всем колонками после девятой числовой тип. Второй аргумент у Table.TransformColumnTypes - 
	Transform2 	= Table.TransformColumnTypes(Expand2, 
                    let n = Table.ColumnNames(Expand2), 
						Skip = 9
                    in  List.Transform(List.Skip(n, Skip), (x)=> {x, Int64.Type} )),
			    или 
					первые два столбца текстовые, остальные числовые
					in  { {n{0}, type text}, {n{1}, type text} } & List.Transform( List.Skip(n, Skip), each {_, type number} )
					
---------------------------------------------------------------------------------------------
	// Транформация списков (в функциях, где в качестве аргумента функция. x = например строка или столбец
		= List.Transform(List.Skip(n, Skip), (x)=> {x,null})) // {имя, null}
		
=============================================================================================
	Переименование столбцов												* Table.RenameColumns
=============================================================================================
//	базовый вариант	
	to = Table.RenameColumns(from, {"Column1","Names"} )
	
---------------------------------------------------------------------------------------------
// переименование по номеру колонки
   to = Table.RenameColumns(from, { Table.ColumnNames(Data){3}, "НовоеНазваниеСтолбца4" } )
---------------------------------------------------------------------------------------------		
// 	переименование столбцов с помощью заранее заготовленной таблицы RENAMING_TABLE
/* 	где таблица RENAMING_TABLE выглядит так (заголовки могут быть любыми)
		СтароеИмя 	НовоеИмя
		Нов			Новосибирск
		Питер		Санкт-Петербург	*/
	to = Table.RenameColumns(from, Table.ToColumns(Table.Transpose(RENAMING_TABLE)), MissingField.Ignore) 

---------------------------------------------------------------------------------------------							 
// 	переменование столбцов из справочника (нужные названия в столбце)
	to = Table.RenameColumns(from, List.Zip({ Table.ColumnNames(from), Справочники[Раздел4][Название] }))
	to = Table.RenameColumns(
			Table.Skip(from,2), 
			List.Zip({Table.ColumnNames(from), NewListColumnName})
		 )
---------------------------------------------------------------------------------------------							 
// 	переменование ВСЕХ столбцов (самый простой вариант)
	RenameColumns = Table.RenameColumns(from, List.Zip({ 
						Table.ColumnNames(from), 
						{"Номер","Название","Значение"} })
					),

---------------------------------------------------------------------------------------------							 
	// переменование столбцов (подробно)
    Renam0      = Table.RenameColumns( Transform2, 
                    let Name_Col  = Table.ColumnNames(Transform2), 		// список имен столбцов таблицы
						List_Old  = List.Buffer(Name_Col),         		// выбираем нужные Name_Col - все, { Name_Col{1},Name_Col{2} } 2 и 3
                        List_New  = {"Номер", "Название","Значение"},   // список новых имен (должно совпадать число строк в списках)
                        List_Comb = List.Zip({List_Old, List_New})      // комбинируем списки
                    in  List_Comb),

-------------------------------------------------------------------------------------------   
   // переименование колонок в ПОДТАБЛИЦЕ по порядку
   to = Table.TransformColumns (dlvr,
			{"Data", each Table.RenameColumns(_, List.Zip({ 
								Table.ColumnNames(_), 
								{"1"..Number.ToText(Table.ColumnCount(_))} }
							)}
		)
	
=============================================================================================
	Reorder 													       * Table.ReorderColumns
=============================================================================================
	// обычная форма
	to = Table.ReorderColumns(from, {"Статья", "Строка", "1", "2", "3"} )
	
	// ПЕРЕДВИГАЕМ колонку "Content" в конец, делаем ее предпоследней, чтобы удобно сравнивать было было-стало.
    Reorder 	= Table.ReorderColumns(AddColumn1,
					let nms = Table.ColumnNames(AddColumn1), 
						lst = {"Дата", "Индекс"}, 
						col = 6	// 0 - если в начало
					in  List.InsertRange(List.Difference(nms, lst), col, lst) ),
		
	// двигаем колонку в начало = 0 (порядковый номер колонки)
	to = Table.ReorderColumns(from, List.InsertRange(List.Difference(Table.ColumnNames(from), {"ДатаОперации"}), 0, {"ДатаОперации"}) )
	

=============================================================================================
	Замена 																 * Table.ReplaceValue
=============================================================================================

	// ЗАМЕНА. Делаем отступы в строке баланса
	Отступ 	=	Table.ReplaceValue(
					RenameColumns2, 
					each [Статья], 
					each if Number.Mod([ID_Строка], 10) <> 0  
						 then "    " & [Статья] 
						 else [Статья], 
					Replacer.ReplaceValue,{"Статья"}
				)

===========================================================================================
// fxRemoveEmptyColumns - ФУНКЦИЯ удаления пустых колонок (сохраняет названия всех столбцов)

let
   fxRemoveEmptyColumns = (tab as table) =>
	   Table.RemoveColumns(
		   tab,
		   Table.SelectRows(
			   Table.Buffer( Table.Profile( tab ) ),
			   each [NullCount] = [Count] )[Column] ),
   
   Source = #table( {"a","b","c"}, {{1,1,null},{2,2,null}} ),
   Custom1 = fxRemoveEmptyColumns( Source )
in Custom1
   
===========================================================================================
	// ФУНКЦИЯ замены по тексту
	fxRazdel = (НомерРаздела as text) => Record.FieldOrDefault([1 = 1, 2 = 2, 4 = 3, 5 = 4, 6 = 5, 0 = 0], НомерРаздела, null),
	
	AddCol   = Table.AddColumn(AddColTir, "tmp", each fxRazdel(Text.Start(Text.From([Строка]),1)), Int64.Type)
	
	// еще один пример
    AddShards = 
        let f=(x)=>Record.FieldOrDefault([1 = 0.001, 2 = 0.002, 3 = 0.004, 4 = 0.007, 5 = 0.012, 6 = 0.018, 7 = 0.03, 8 = 0.08], Text.From(x), null),
    		add = Table.AddColumn(AddColTir, "Осколков", (x)=> f(x[Тир]) * x[КоличествоВсего], Int64.Type)
        in  add,

=== fxAddMultiColumns =======================================================================
	// ФУНКЦИЯ добавить несколько колонок
	  fxAddMultiColumns = (table as table, addedColumns as list) as table =>
			List.Accumulate(addedColumns, table, (t, d) => Table.AddColumn(t, d{0}, d{1}, d{2}?)),
			
		* пример
		AddedColumns = fxAddMultiColumns(Источник , {
				{ "ID_Раздел", each fxRazdel(Text.Start(Text.From([Строка]),1)), Int64.Type},
				{ "ID_Группа", each if List.Contains ({"А".."Я","A".."Z"}, Text.Start([Статья],1)) = true then 1 else 2, Int64.Type}
			}),
			
============================================================================================
// Викинги. Функция перевода Англ формата числа в обычное. 1,25 K или 32,4 В в целое число
// Поменять на число значение без одного последнего знака заменив предварительно "." на ","
()=>
let 
	MyFunction = if Text.End(_, 1)="K" then 1000       * Number.From(Text.Replace(Text.Start(_,Text.Length(_)-1),".",",")) else
                 if Text.End(_, 1)="M" then 1000000    * Number.From(Text.Replace(Text.Start(_,Text.Length(_)-1),".",",")) else
                 if Text.End(_, 1)="B" then 1000000000 * Number.From(Text.Replace(Text.Start(_,Text.Length(_)-1),".",",")) else
                 Number.From(Text.Replace(_,".",","))
in MyFunction

============================================================================================
// ссылка на другой запрос

	// Вариант 1. Через Record.
	// Если Запрос1 не выводите в модель/лист, но вам нужно иметь возможность обратиться к конечному результату и промежуточному:
	
	let
	  a = 1,
	  b = a + 1,
	  c = b + 2
	in
	  [ result = c, midRes = b ]

	// Вариант 2. Используйте метаданные - meta
	
	let
	  a      = 1,
	  b      = a + 1,
	  c      = b + 2,
	  result = c meta [ midRes = b ]
	in
	  result
	----------------------------------------------------------------------------------------
	// Фиксация метки. Метка ставится на ЗНАЧЕНИЕ! Meta (метка) это Record!
		to = RemoveCol meta [Step = AddColumn] // зафиксировали метаданные на шаге AddColumn		
			in 
		result
	// Чтение метки 
		from = Value.Metadata(Запрос1)[midRes]    
	----------------------------------------------------------------------------------------
	// Вариант 2. Возвращается "я"
	ЗаписьМетки  = Источник meta [ Кто = "я", Куда = "туда", Откуда ="отсюда" ]
	Чтение метки = Value.Metadata(addMeta)[Кто]	
	----------------------------------------------------------------------------------------
	// Еще. Последние изыскания
	let from = #table( type table[ Date = date, Month = number, Year = number ],
					List.Transform( List.Dates(#date(2024,1,1), 10, #duration(1,0,0,0)),
							(x)=>{x, Date.Month(x), Date.Year(x)})),	// обычная таблица с тремя столбцами данных
		addMeta  = from meta [ from = Table.Column(from, "Date") ],		// добавляем столбец с датами в метаданные списком
		readMeta = Value.Metadata(addMeta)								// считываем мету. Мета это Запись (Record)!
		to       = readMeta[from]{0}									// возваращаем первый элемент
	in	to

	/* В метаданные модно запихнуть список ошибок сервера		from 	 = x meta [ Кто = "я", Куда = "туда", Откуда ="отсюда"]
	   Прочитать отдельным шагом 								metadata = Value.Metadata(from)
	   Потом по ним обрабатыват результат и строить условия 	to 		 = if metadata[Response.Status] = 200 then
	*/
		
====================================================================================================
	Генерация 																		 * List.Generate 
====================================================================================================
// 	самый короткий вариант создания списка значений {1,2,..., 10}
	to = List.Generate( ()=>1, (x)=> x<=10, (x)=> x+1, (x)=> x )

// 	самый короткий вариант создания списка значений {Column1, Column2, ... , Column10}
	to = List.Generate(()=> 1, (x)=> x <=10, (x)=> x + 1, (x)=> "Column" & Text.From(x) )
	
//  функция 
	f=(last)=> List.Generate(()=> 1, (x)=> x <=last, (x)=> x + 1, (x)=> "Column" & Text.From(x) ),
	
//  Список 1, Список 2, ...Список 10
	let	txt = "Список",
		source = List.Generate(
			()=> [index = 1],
			each [index] <= 10,
			each [index = [index] + 1],
			each [page = txt & " " & Text.From([index])] [page]
		)
	in 	source
   	
//  Генерация списка 1,2,3...10
	let
	   txt 	 = "Список",
	   value = 1,        // [значение]
	   q     = 10,       // [количество]
	   source = List.Generate(                     // создаем запись с итератором, для получения условия выхода из цикла
				()=> [i = 1, a = value],           // значение первого элемент в будущем списке 
				each [i] <= q,                     // проверка условия выхода из цикла 
				each [i = [i] + 1, a = [a] + 1 ],  // увеличиваем итератор на 1 и генерируем следующий элемент списка по формуле
				each [a]                           // показываем что именно выводить в будущий список
			)
	in source

// Есть таблица: Атрибут, Начало периода, конец периода.
// Надо сделать список начала месяцев
// на выходе Колонка со списками в которых первые числа каждого месяйца в диапазоне
	to = Table.AddColumn (typed, "Months", 
		(r)=>	List.Generate ( 
					() => Date.StartOfMonth ( r[Дата начала] ), 
					each _ <= r[Дата окончания], 
					each Date.AddMonths ( _, 1 ) 
				), 
		type {date}
	)
  
//  Начало месяца в списке дат от и до какого - второй вариант предыдущего поста ПО МЕСЯЦАМ
	AddedCustom = Table.AddColumn(#"Вычисленное начало месяца1", "Даты", each 
	let start = [Дата подписки],
        end   = [Дата отказа]
    in	List.Generate(
                ()=> [day=start],
                each [day]<=end,
                each [day=Date.AddMonths([day], 1)],
                each [day]
            )),  
			
// По ДНЯМ
    AddedCustom = 
		Table.AddColumn(#"Changed Type1", "Дата", each 
			List.Dates(
				[Дата подписки], 
				Duration.Days( Duration.From([Дата отказа]-[Дата подписки]) )+1, 
				#duration(1, 0, 0, 0)
			)
		)
  
******************************************************************************************************************************
	РЕШЕНИЯ      
******************************************************************************************************************************
// В Таблице со списком городо убрать текст по списку
// Tag: ЧИСТКА ТЕКСТА
	г. Гомель
	пос. Бобовичи
	Минская гор.

//  Вариант 1
	let from = Excel.CurrentWorkbook(){[Name="Таблица1"]}[Content],
		f=(x)=>Text.Combine(List.RemoveItems(Text.Split(x," "),{"г.","гор.","город"})," "),  // убирает в колонке таблицы эти символы
		to=Table.TransformColumns(from,{"Города",f})
	in  to

//  Вариант 2. Михаила. Оставить только слова начинающиеся с большой буквы
	let
		from = Excel.CurrentWorkbook(){[Name="Таблица1"]}[Content],
		lst  = List.Buffer({"А".."Я"}),
		f=(x)=>Text.Combine(List.Select(Text.Split(x," "),(x)=>List.Contains(lst,Text.Start(x,1)))," "), // универсальная функция!
		to  = Table.TransformColumns(from,{"Города",f})
	in  to

---------------------------------------------------------------------------------
// ЗАМЕНА значений в разных столбцах по разным условиям исходного столбца
	let	tbl = #table(type table [Статья = text, Строка = number, Примечание = text],
				{ {"Товар", 10, "а"}, {"Деньги",20, "б"} }
			  ),
		f=(row)=> if row{1}=10 then {row{0},       11} 	// если к колонке 2 10 то меняем всю строку: Товар   - 11 - null (т.к. нет значения)
			 else if row{1}=20 then {row{0} & "+", 21}  // если к колонке 2 20 то меняем всю строку: Деньги+ - 21 - null (т.к. нет значения)
			 else row,									// в остальных колонках как было           : Долг    - 30 - в 

	   t =  Table.ToList(tbl,f),						// Список списков
	   to = Table.FromList(t, (x)=>x, Value.Type(tbl) )	// Таблица их списков
	in to



==========================================================================================
	ДАТА+
==========================================================================================

//  список дней между датами начала и конец
	to = Table.AddColumn(from, "СписокДат", each 
			List.Dates([dateStart], Duration.Days(Duration.From([dateEnd]-[dateStart]))+1, #duration(1, 0, 0, 0))
		 )

// 	Разница между сегодня и колонко в датой
	to = Table.AddColumn(Add, "Разница", each Number.From( Date.From(DateTime.FixedLocalNow())  - [Начало периода]))


//  Добавить название файла загружаемого соло в отдельную колонку
	f=(x)=> Text.AfterDelimiter(x, "\",  {0, RelativePosition.FromEnd}), // вытягиваем название из Параметра "Файл_источник" = полный путь
	to = Table.TransformColumns(
			Table.AddColumn(from, "Файл_источник", each #"Файл_источник"), // добавляем колонку
			{"Файл_источник", f}										   // оставляем название
		)
------------------------------------------------------	
//
	let
		tbl = Excel.CurrentWorkbook(){[Name="source"]}[Content],
		cmb = Table.FromList(Table.ToRows(tbl),List.Sort,{"a","b"}),
		gr = Table.Buffer(Table.Group(cmb,"a",{"c",(t)=>t[b]})),

		f=(x,y)=>   if y={} then x 
					else [  a = List.Combine(List.Transform(y,(i)=>gr{[a=i]}?[c]? ??{})),
							b = List.Distinct(x&y&a),
							c = @f(x&y,List.Difference(b,x&y))][c],
		add = Table.AddColumn(gr[[a]],"b",each List.Sort(f({[a]},gr{[a=[a]]}[c])))[[a],[b]],
		lst = List.Buffer(add[b]),
		g=(x)=>List.IsEmpty(List.Select(lst,(y)=>List.ContainsAll(y,x) and (List.Count(y)>List.Count(x)))),
		slc = Table.SelectRows(add,(r)=>g(r[b])),
		to = Table.TransformColumns(slc,{"b",(i)=>Text.Combine(List.Transform(i,Text.From),",")})
	in
		to
------------------------------------------------------	
// 
	a = List.Combine(
			List.Transform(y,
				(i)=> gr{[a=i]}?[c]? ??{}
			)
		),
		
		
		let
    get = (txt as text) as table =>[
        bin = Binary.FromText(txt),
        dec = Binary.Decompress(bin,Compression.Deflate),
        json = Json.Document(dec),
        tbl = Table.FromRecords(json)]
    [tbl],

    src = get("bc8xSgRQDATQu/x6CckkmSR7FbFYbQVBxUb27v5qEfxFusfM5Olnfb5/fK3ruq3L+r69rSsDKoYMFsv24X75rzzpMsVRjVCi56SoWQJt5OgUYvKkIpPiqeY20f3XvDz6uk0KqCztYk8c1d4te45vh+hsnFS4QpgOxsyO9D6pjCnpHiOtM+F/s14fH1qVWCVbwXJ6nlQgKIxy5UyHzlGRbkJFRRFE1gm5eksU1Kemba+/P/8C"),
	
-------------------------------------------------------
	// убраить
	
	/*/ трансформируем столбцы с указанием типа / После разворота типы спадут! Только трансформа внутри этой функции
        // {"Цена", each try Text.Split(_, Character.FromNumber(10)) otherwise {Text.From(_)} , type text }
        // вместо функции [s1 = x, s2 = if s1 = "1" then "1+" else "" & s1] [s2]
        Transform = Table.TransformColumns(
            ClearData,{ 
                { ColNames{0}, (x)=> x, type text},
                { ColNames{1}, (x)=> try Number.From(x) otherwise null , Int64.Type},
                { ColNames{2}, (x)=> if Number.From(x) = 0 then null else Number.From(x), Int64.Type},
                { ColNames{3}, (x)=> if Number.From(x) = 0 then null else Number.From(x), Int64.Type}
            } ),
*/


============================================\
// бутончик

Словарь
let
    f=(x)=>Excel.CurrentWorkbook(){[Name=x]}[Content],
    g=(x)=>List.AllTrue(List.Transform(Text.Split(Text.Lower(x)," "),h)),
    h=(x)=>Record.FieldOrDefault(dict,x,true),
    
    dict = 
        [
            a = List.Transform(f("Слова")[Слова],Text.Lower),
            b = Record.FromList(List.Repeat({false},List.Count(a)),a)
        ]  
            [b],

    to = Table.SelectRows(
            f("Яблоки"),
            (x)=>g(x[Столбец1])
    ) 
in
    to
	
	
	iVar = 1,
    crit = if Var =1 then 
        f=(x)=>Excel.Workbook(x){0}[Data]
    else
        f=(x)=>Excel.Workbook(x){1}[Data],
		
		
***
Замена = List.Transform( trans, each if Text.Contains(_, "Код") then "Строка" else _),
	
	
	
*** ЗАМЕНА МНОЖЕСТВЕННАЯ ***
// аналог функции select case

(input) =>
let
    txt1 = "Ускорение, нед",
    txt2 = "Энергия Героя, млн",
    txt3 = "Сила Шамана, млн",
    
    values  = {
          {"Ускорение, 1 час", txt1},
          {"Ускорение, 3 часа", txt1},          
          {"Ускорение, 8 часов", txt1},
         
          {input, input}
    },
    
    Result = List.First(List.Select(values, (x)=>x{0}=input)){1}
in
   Result

/// Мнолжественная замена по значения в другом столбце
(inputBonus, inputValue) =>
let
    ЧасыНеделя = 168,
    ЧислоМлн = 1000000,
    values  = {
          {"Ускорение, 1 час", (inputValue * 1) / ЧасыНеделя},
          {"Энергия Героя, 5000", (inputValue * 5000) / ЧислоМлн},
          {"Сила Шамана, 5000", (inputValue * 5000) / ЧислоМлн},
          {inputBonus, inputValue}
    },
    
    Result = List.First(List.Select(values, each _{0}=inputBonus)){1}
in  Result

let
    switch= (c) => 
     if c= "A" then "add_One_A" else 
     if c="a" then "add_One_a" else 
     "add_nOne_a"

in 
    switch
//пример с днями недели
/*
(week_day) =>
let
    source = {
        {"понедельник", 4},
        {"вторник", 3},
        {"среда", 2},
        {"четверг", 1},
        {"пятница", 0}
    },
    Result = List.First(List.Select(source, each _{0} = week_day)){1}
in
    Result
*/	

=============================================================================================
	Table.ExpandTableColumn										/* Table.ExpandTableColumn */
=============================================================================================
// Как правильно разворачивать
 Expand = Table.ExpandTableColumn(old_step, "Data", 
			Table.ColumnNames(old_step{0}[Data]), 
			Table.ColumnNames(old_step{0}[Data])
		  ) 

// Развернуть из вложенной таблицы только столбцы из специального списка
// в качестве списка берем столбец Attribute из таблицы INPUT_TABLE
// в качестве списка берем столбец Attribute из таблицы INPUT_TABLE
	fields = List.Buffer( InputTable[Attribute] ),
	ExpandedNewColumn = Table.ExpandTableColumn( buffer, "NewColumn",
		List.Intersect( { List.Difference! Table.ColumnNames( buffer[NewColumn]{0}), Table.ColumnNames( buffer)), fields }),
		List.Intersect( { List.Difference! Table.ColumnNames( buffer[NewColumn]{0}), Table.ColumnNames( buffer)), fields })
	)

// Развернуть столбцы из спец списка и переименовать их в процессе
	fields = List.Buffer( InputTable[Attribute] ),
	ExpandedNewColumn = Table.ExpandTableColumn( buffer, "NewColumn",
		List.Intersect) {Table.ColumnNames) buffer[NewColumn]{0}), fields }),
		// добавляем приставку Parent к имени каждого разворачиваемого столбца
		// переименование по таблице RENAME_TABLE путём подмены элементов списка
		List.Transform( 
			List.ReplaceMatchingItems(List.Intersect( {Table.ColumnNames) buffer[NewColumn]{0}), fields }),
			Table.ToColumns( Table.Transpose(RENAME_TABLE)) ),
			each "Parent" &_)
	),





******************************************************************************************************************
    // осавляем строки, если код строки в колонке Column3 (Код строки) - число 
    Clear = 
        let f=(x)=> Table.SelectRows(x, each try Value.Is( Number.From([Column3]), type number) = true otherwise null) , 
            g=(x)=> Table.RemoveColumns(x, {"Column1"}),    
            h=(x)=> let lstOld = List.Buffer(Table.ColumnNames(x[Data]{0})),
						lstNew = {"Статья", "Строка", "1", "2", "3", "4", "5", "6"}
					in  rename = Table.RenameColumns(Remove, List.Zip( {lstold,lstNew} )),
            Select = Table.TransformColumns(Expand,{"Data", f}),    // оставляем строки с номером
            Remove = Table.TransformColumns(Select,{"Data", g}),    // убираем первую колонку с нумерацией статей
            Rename = Table.TransformColumns(Select,{"Data", h})    // список имен столбцов подтаблиц (все одинаковые)
		in  Rename
	
------------------------------------------------------------------------------------------------
// добавляем раздел 1 в отдельный массив
// Из стат отчета БКС3 выносим все строки каждого раздела в отдельный столбец
    AddR1 = 
        let f=(x)=> Table.SelectRows(x[Data], each List.Contains ({10100..11700}, [Строка]))
        in Table.AddColumn(Clear, "Раздел1", f),
		
------------------------------------------------------------------------------------------------
// Все функции List
let
   list_1       = Record.ToTable(#shared), 
   rows_select  = Table.SelectRows( list_1, each Text.Contains(Text.Lower([Name]), "list") and Text.Contains([Name], ".") ), 
   tab_add_col  = Table.AddColumn( rows_select, "Meta", each Value.Metadata(Value.Type([Value])) ), 
   cols_select  = Table.SelectColumns(tab_add_col, {"Meta"}), 
   col_expand_1 = Table.ExpandRecordColumn(cols_select, "Meta", 
      {  "Documentation.Name", 
         "Documentation.Description", 
         "Documentation.LongDescription", 
         "Documentation.Examples" }, 
      {"Name", "Description", "LongDescription", "Examples"}
   ), 
   col_expand_2 = Table.ExpandListColumn(col_expand_1, "Examples"), 
   col_expand_3 = Table.ExpandRecordColumn( col_expand_2, "Examples", 
      {"Description", "Code", "Result"}, 
      {"Example Description", "Example Code", " Example Result"}
   ),
    #"Сортированные строки" = Table.Sort(col_expand_3,{{"Name", Order.Ascending}})
in  #"Сортированные строки"
   
------------------------------------------------------------------------------------------------

let a = List.PositionOfAny({1..10},{1,3,5}),//0
    b = List.PositionOfAny({1..10},{1,3,5},Occurrence.All),//{0,2,4}
    c = List.PositionOfAny({1..10},{11,13,15}),//-1
    d = List.PositionOfAny({1..10},{11,13,15},Occurrence.All),//{}
    e = List.PositionOfAny({"http://stat.priem.bntu.by/view_.php?kf=1&forob=1&budj=1"},{"=","&"},Occurrence.All,Text.Contains),//{0,2}
    f = List.PositionOfAny({"мама","мыла","раму"},{"МА","РА"},Occurrence.All,(c,v)=>Text.Contains(c,v,Comparer.OrdinalIgnoreCase)),//{0,2}
    g = List.PositionOfAny({"ыл","ил"},{"мама мыла раму","папа пил пиво"},Occurrence.All,Text.Contains),//{}
    h = List.PositionOfAny({"ыл","ил"},{"мама мыла раму","папа пил пиво"},Occurrence.All,(c,v)=>Text.Contains(v,c))//{0,1}
in  h

let a = List.PositionOf({1..10},5), //4
    b = List.PositionOf({"a".."z"},"d"), //3 
    c = List.PositionOf({1..10},11), //-1 - значение не найдено
    d = List.PositionOf({1,2,null,3,4,null,5},null), //2
    e = List.PositionOf({1,2,null,3,4,null,5},null,Occurrence.First),//2
    f = List.PositionOf({1,2,null,3,4,null,5},null,Occurrence.Last), //5
    g = List.PositionOf({1,2,null,3,4,null,5},null,Occurrence.All), //{2,5}
    h = List.PositionOf({1,2,null,3,4,null,5},null,Occurrence.First,(c,v)=>c<>v),//0
    i = List.PositionOf({1,2,null,3,4,null,5},null,Occurrence.Last,(c,v)=>c<>v),//6
    j = List.PositionOf({1,2,null,3,4,null,5},null,Occurrence.All,(c,v)=>c<>v),//{0,1,3,4,6}
    k = List.PositionOf({1..5},3,Occurrence.All,(c,v)=>c<v), //{0,1}
    l = List.PositionOf({1..5},3,Occurrence.All,(c,v)=>c>v), //{3,4}
    m = List.PositionOf({1,2,null,3,4,null,5},3,Occurrence.All,(c,v)=>if c is null then false else c>v),//{4,6}
    n = List.PositionOf({"a".."z"},"D",Occurrence.All,Comparer.OrdinalIgnoreCase) //3
in  n
	
------------------------------------------------------------------------------------------------
	
/* Поскольку каждый из них представляет собой сахарный синтаксис для безымянной переменной, 
// в полном синтаксисе мы ввели переменную с именем X. Поскольку переменная X вводится два раза, 
// у нас есть X перед всеми столбцами внутри внутренней итерации ( Table.SelectRows( ) функция). 
Внутри внутренней среды ( функция Table.SelectRows() ) X ссылается на таблицу Promotions, 
которая является первым аргументом функции Table.SelectRows() . В таблице «Промоакции» нет столбца «Дата». 
В ошибке указано именно это.

Если мы используем полный синтаксис, мы можем ввести две разные переменные: одну с названием S 
(внешняя переменная, S означает «Продажи») и P (внутренняя переменная, P означает «Промоакции»).
	
#"Added Custom" =
Table.AddColumn(Sales, "Promo",
               (S)=>  Table.SelectRows(Promotions,
                                      (P)=> P[Brand]= S[Brand] and S[Date]>= P[DateFrom] and S[Date]<P[DateUntil]
                                      )
                )

Используя полный синтаксис каждого ключевого слова, мы ввели две разные переменные, относящиеся к двум разным средам. 
Таким образом, для каждой строки таблицы «Продажи» мы получаем вложенные таблицы с соответствующими строками из таблицы «Промоакции». 
Когда мы расширяем столбец «Промоакция», мы получаем правильный конечный результат:	
*/

=== Группировка времени  =================================
// https://www.planetaexcel.ru/forum/index.php?PAGE_NAME=read&FID=1&TID=111939&TITLE_SEO=111939-gruppirovka-diapazonov-vremeni

let Source  = Excel.CurrentWorkbook(){[Name="Таблица1"]}[Content],
    Typed   = Table.TransformColumnTypes(Source,{{"День", Int64.Type}, {"Начало", type time}, {"Оконч", type time}}),
    Sorted  = Table.Sort(Typed,{{"День", Order.Ascending}, {"Начало", Order.Ascending}}),
    grouped = Table.Group(Sorted, {"День"}, {"temp", (sub) =>
		let base = List.Buffer(Table.ToRecords(sub[[Начало], [Оконч]])),
			listCount = List.Count(base),
			maker = List.Generate(
						() => [i = 0, prev = base{i}, Начало = prev[Начало], Оконч = prev[Оконч]],
						each [i] < listCount,
						each [i = [i] + 1, prev = base{i}, Начало = (if prev[Начало] <= [Оконч] then [Начало] else prev[Начало]), Оконч = (if prev[Оконч] > [Оконч] then prev[Оконч] else [Оконч])],
						each [[Начало], [Оконч]]
					),
			stat = Table.Group(Table.FromRecords(maker), {"Начало"}, {"Оконч", each List.Max([Оконч])})
		in  stat
		}),
    #"Expanded {0}" = Table.ExpandTableColumn(grouped, "temp", {"Начало", "Оконч"}, {"Начало", "Оконч"})
in  #"Expanded {0}"
	


=== Группировка по диапазонам  =================================	
// https://www.planetaexcel.ru/forum/index.php?PAGE_NAME=read&FID=1&TID=128979&TITLE_SEO=128979-gruppirovka-summ-po-diapazonu-power-query
let from = Excel.CurrentWorkbook(){[Name="Исходная"]}[Content],
    lst  = List.Transform(List.Numbers(1,5,500),each if _ < 2000 then {_,"От "& Text.PadStart(Text.From(_),4," ")& " до " & Text.From(_+499)} else {_,"Свыше 2000"}),
    f=(n)=>lst{List.PositionOf(lst,n,Occurrence.Last,(x,y)=>x{0}<y)}{1},
    tbl  = Table.AddColumn(from,"Диапазон сумм",each f([#"Сумма закупок"])),
    to   = Table.Pivot(tbl, List.Distinct(tbl[Товар]), "Товар", "Сумма закупок", List.Count)
in  to
	
		
	
 // Новый столбец с номером группы !!! -= Долго обновляет
        КолонкаГруппа = Table.AddColumn(#"Добавлен пользовательский объект3", "Группа", 
            each if List.Contains(Группа1, [Фамилия]) = true then "Б4" else if 
                    List.Contains(Группа2, [Фамилия]) = true then "Бс3" else "нет"),
	
	
to = Table.AddColumn(#"Переупорядоченные столбцы", "Сутки", each if 
		[Время] >= #time(6, 0, 0) and [Время] <= #time(12, 0, 0) then "Утро" else if 
		[Время] >= #time(12, 0, 0) and [Время] <= #time(18, 0, 0) then "День" else if 
		[Время] >= #time(18, 0, 0) and [Время] <= #time(24, 0, 0) then "Вечер" else "Ночь")



=== Интересный код Duration =================================
// Есть файл в приемах в PQ
// https://www.planetaexcel.ru/forum/index.php?PAGE_NAME=message&FID=1&TID=159731&TITLE_SEO=159731-podschet-chistogo-vremeni-v-opredelennye-daty-s-usloviem&MID=1265788&tags=&q=duration&FORUM_ID%5B0%5D=0&DATE_CHANGE=0&order=relevance&s=%D0%9D%D0%B0%D0%B9%D1%82%D0%B8#message1265788
let
    // worklog => minutes
    worklog_tbl = Excel.CurrentWorkbook(){[Name="Table2"]}[Content],
    worklog_column = 
        Table.AddColumn(
            worklog_tbl, "ticks", each
            List.DateTimes(
                [Дата] + Duration.From([#"Начало(чч:мм)"]),
                Number.Round([#"Продолжительность(чч:мм)"] * 24 * 60, 0),
                #duration(0, 0, 1, 0)
            )
        ),
    worklog_list = List.Buffer(List.Distinct(List.Combine(worklog_column[ticks]))),
    dates = List.Distinct(worklog_tbl[Дата]),
    // criteria
    criteria_tbl = Excel.CurrentWorkbook(){[Name="Table1"]}[Content],
    criteria = 
        Table.AddColumn(
            criteria_tbl, "drn", 
            each (if [Критерий] = "Ночь" then 1 else 0) + [to] - [from]
        ),
    c_dates = Table.AddColumn(criteria, "date", each dates),
    expand_dates = Table.ExpandListColumn(c_dates, "date"),
    dt_from = Table.AddColumn(expand_dates, "dt_from", each [date] + Duration.From([from])),
    dt_to = Table.AddColumn(dt_from, "dt_to", each [dt_from] + Duration.From([drn])),
    // time per period
    work_time = 
        Table.AddColumn(
            dt_to, "time", 
            (r) => 
                List.Count(
                    List.Select(worklog_list, (x) => x >= r[dt_from] and x <= r[dt_to])
                ) / (60 * 24)
        ),
    #"Removed Other Columns" = Table.SelectColumns(work_time,{"Критерий", "date", "time"}),
    #"Pivoted Column" = Table.Pivot(#"Removed Other Columns", List.Distinct(#"Removed Other Columns"[Критерий]), "Критерий", "time", List.Sum)
in
    #"Pivoted Column"
	
--------------------------------------------------------------------------------------------

	
	
			AddColumn = Table.AddColumn(FillDown, 
            "Индекс", 
                each if List.ContainsAny( 
                                    { [Время] }, 
                                    { "9.00", "10.50","12.55","14.40","16.25","18.30","20.15"}, 
                                    Text.Contains ) = true 
                        then 1
                        else 2),
    types2 = Table.TransformColumnTypes(RenameColumns,{{"Индекс", Int64.Type}}),
    AddIndexColumn = Table.AddIndexColumn(Источник2, "Индекс1", 1, 1, Int64.Type),
    ind = Table.AddIndexColumn(AddIndexColumn, "Индекс2", 0, 1, Int64.Type),
    #"Условный столбец добавлен" = Table.AddColumn(ind, "Пользовательский", each if ind[Индекс]{[Индекс1]} = 2 then [Предмет] & " " & ind[Предмет]{[Индекс2]+1} else [Предмет] ),
    #"Строки с примененным фильтром" = Table.SelectRows(#"Условный столбец добавлен", each ([Индекс] = 1)),
    #"Удаленные столбцы" = Table.RemoveColumns(#"Строки с примененным фильтром",{"Предмет", "Индекс", "Индекс1", "Индекс2"}),
    #"Извлеченный текст перед разделителем" = Table.TransformColumns(#"Удаленные столбцы", {{"Время", each Text.BeforeDelimiter(_, "-"), type text}}),
    #"Замененное значение" = Table.ReplaceValue(#"Извлеченный текст перед разделителем",".",":",Replacer.ReplaceText,{"Время"}),
    #"Измененный тип" = Table.TransformColumnTypes(#"Замененное значение",{{"Время", type time}})
in
    #"Измененный тип"
	
=====================
// обработка БАЛАНСА
    // добавляем подтаблицы 3 (можно через функцию: each f([Step1])),
    AddColTable = Table.AddColumn(from, "Step2", (x)=>
        let 
            a = x[Content],										// столбец с подтаблицами
            b = {"Column1", "Column2", "Column3", "Column4"},	// список нужных колонок (статья, номер статьи, на начало, на конец)
            c = Table.SelectColumns(a, b),						// фильтруем колонки в подтаблице 
            d = fxClear(c, " #(lf)#(00A0)", true, true), 		// чистим текст во всей таблице (" ", двойные пробелы, табуляцию,)
            e = Table.ColumnNames(d),							// список имен колонок подтаблицы
		    f1= (x)=> try Number.From(x) otherwise null,
			g = Table.TransformColumns(d,{{ e{1}, f1, Int64.Type}} ),	// меняем тип данных для дальнейшей фильтрации
		    f2= (x)=> x<>null and x>100 and x<1000,
            h = Table.SelectRows (g, (row)=>f2(Record.Field (row, e{1}))), // фильтруем строки с НомеромСтатьи ПО ИМЕНИ колонки
            l = Table.RenameColumns(h, List.Zip({List.Buffer(e), List.Skip( lstNewColNаmes, 1 )}))	// меняем названия колонок кроме первой
        in  l
    ),	


===[ При выгрузке базы собираем заголовки в одну таблицу ]=============================

let path   = "G:\=EXCEL BI - мои проекты\2024.01 - Анализ Отчетности\Экспорт Гомель.xlsx",
	source = Excel.Workbook(File.Contents(path), null, true),
    from   = Table.SelectRows(source, each ([Kind] = "Sheet")),
    selrow = Table.SelectRows(from, (x)=> List.ContainsAny( {Text.Start(x[Name], 2)}, {"0".."9"}, Text.Contains)),
    selcol = Table.SelectColumns(selrow,{"Name", "Data"}),
    tr     = Table.TransformColumns(selcol, {"Data", (x)=> Table.FirstN(x, 1)} ),
    exp    = Table.ExpandTableColumn(tr, "Data", Table.ColumnNames(tr{0}[Data]),Table.ColumnNames(tr{0}[Data])),
    head   = Table.PromoteHeaders(Table.Transpose(exp), [PromoteAllScalars=true]),
    to     = Table.TransformColumnTypes(head, List.Transform(Table.ColumnNames(head), (x)=>{x,type text}) )
in  to

===[ Удаление из таблицы пустых ячеек ]=== !
//  Сворачиваение влево, через лист 
//  https://www.planetaexcel.ru/forum/index.php?PAGE_NAME=read&FID=1&TID=162396&TITLE_SEO=162396-udalenie-pustykh-yacheek-po-diagonali-v-power-query
	let fr  = Excel.CurrentWorkbook(){[Name="Таблица1"]}[Content],
		nms = List.Buffer(List.Skip(Table.ColumnNames(fr))), 						// список столбцов без первого
		a   = List.Transform(nm, (x)=> List.RemoveItems(Table.Column(fr,x), {""})), // удаляем все пустые "ячейки" (значения списка) из каждой колонки x
		a1  = Table.FromColumns(a,nms)												// разворачиваем лист с колонками nm
	in  a1
	
===[ xml ]==============================
// 
	(bin)=>
	let bin  = Binary.Buffer(bin),
		xml  = Xml.Document(unzip(bin){[FileName="xl/worksheets/sheet1.xml"]}[Content]){0}[Value]{[Name="sheetData"]}[Value][Attributes],
		val  = List.Transform(xml,(x)=>x{[Name="hidden"]}?[Value]?),
		nms  = List.Transform(xml,(x)=>x{[Name="r"]}?[Value]?),
		dict = Record.FromList(val,nms),
		sh   = Excel.Workbook(bin,false){0}[Data],
		add  = Table.AddIndexColumn(sh, "tmp", Number.From(nms{0}),1),
		tbl  = Table.TransformColumns(add,{"tmp",(x)=>Record.FieldOrDefault(dict,Text.From(x))}),
		filtr= Table.SelectRows(tbl, each ([tmp] = null)),
		to   = Table.RemoveColumns(filtr,{"tmp"})
	in  to
	
	
---[ Студенты в колонки ]-------------------------------------------------------------------
//  на входе колонка 1 = номер группы + колонка 2 фио студента
// 	на выходе: группы в колонках, студенты в строках
	gr = Table.Group(from, "ГРУППА", {"tmp", (x)=>List.Sort(x[ФИО])}),  // группирую список студентов по группам как List
    to = Table.FromColumns(gr[tmp],gr[ГРУППА])							// разворачиваю: gr[tmp] - list в колокни, gr[группа] - заголовки

//  раскрытие одной колонки в list
	to = Table.ExpandListColumn(cmb, "Пробег")
	
==========================================================================================	
	Выбор колонок 													 * Table.SelectColumns
==========================================================================================
// 	оставляем первые 4 колонки


// 	оставляем колонки, имя заголовков которые содержат
	ColumnsToSelect = List.Select(Table.ColumnNames(Source), each Text.Contains(_, "glu") or Text.Contains(_, "pep")),
	SelectColumns   = Table.SelectColumns(Source, ColumnsToSelect)    
	
==========================================================================================
// fxRegExpExtract
https://www.planetaexcel.ru/forum/index.php?PAGE_NAME=message&FID=1&TID=131471&TITLE_SEO=131471-kak-polzovatelskoy-funktsii-regexp-otdat-srazu-neskolko-argumentov-spi&MID=1076496&tags=&q=%D0%BF%D1%80%D0%BE%D0%B2%D0%B5%D1%80%D0%BA%D0%B0+%D0%BD%D0%B0%D0%BB%D0%B8%D1%87%D0%B8%D1%8F+%D0%B2+%D1%82%D0%B0%D0%B1%D0%BB%D0%B8%D1%86%D0%B5+%D0%B7%D0%BD%D0%B0%D1%87%D0%B5%D0%BD%D0%B8%D1%8F+power+query&FORUM_ID%5B0%5D=0&DATE_CHANGE=0&order=relevance&s=%D0%9D%D0%B0%D0%B9%D1%82%D0%B8#message1076496

//	Примеры
	to = RegExpExtract( a2 ; ".*/")	//	Убрать весь текст после "."

// верно
let
    rexExpContains = (string, pattern, замена) =>
    Web.Page(
        "<script>
            var regExp = /" & pattern & "/i;
            document.write(regExp.replace('" & string & "', '" & замена & "'));
        </script>")[Data]{0}[Children]{0}[Children]{1}[Text]{0}
in
    rexExpContains
	
// Стандартная функция, но не проверял
let   fx=(txt as text, regex as text, delim as text)=>
		Web.Page(
			"<script>
				var x = '" & txt & "';
				var delim = '" & delim & "';
				var pattern = /" & regex & "/gi;
				var result = x.match(pattern).join(delim);
				document.write(result);
			</script>")[Data]{0}[Children]{0}[Children]{1}[Text]{0}
in	fx	

	
=== fxRegExp =================================================================
// Функция fxRegExp
// https://www.planetaexcel.ru/techniques/7/4844/
// https://www.planetaexcel.ru/techniques/7/13310
// = fxRegExp("выпускникмагистратуры", "выпускник", "")  // выпускник
let   
    fx=(txt as text, regex as text, delim as text)=>
        Web.Page(
            "<script>
                var x = '" & txt & "';
                var pattern = /" & regex & "/gi;
				var delim = '" & delim & "';
                var result = x.match(pattern).join(delim);
                document.write(result);
            </script>")
        [Data]{0}[Children]{0}[Children]{1}[Text]{0}
in fx	


==========================================================================================
// удаление пустых колонок - не проверял
==========================================================================================

	to =	Table.SelectColumns(from,
				List.Select(Table.ColumnNames(from), each
					List.NonNullCount(
						List.Transform(
							Table.Column(from, _),
							each try if Text.Clean(Text.Trim(_)) = "" then null else otherwise _ 
						)
					)
				> 0)
			)

==========================================================================================
// Ожиганов. Power Query и язык M: Фильтрация пустых и почти пустых строк
// tag: работа со строками, Ожиганов
==========================================================================================
--- SelectRows

	// (+) удаляем пустые строки 
	to = Table.SelectRows(from, each List.NonNullCount(Record.FieldValues(_)) > 0)
	
	// (+) оставляем строки если НЕПУСТЫЕ в колонке 1
	to = Table.SelectRows(Add, each not List.IsEmpty(List.RemoveMatchingItems(Record.ToList(Record.SelectFields(_, {"Column1"})),{null,""})))
	
	// (+) оставляем строки, в которых ПУСТЫЕ колонки 1 и 2 
	to = Table.SelectRows(Add, each 
			List.IsEmpty(
				List.RemoveMatchingItems(
					Record.ToList(Record.SelectFields(_, {"Col1","Col2"}))
					,{null,""}
				)
			)
		 )
	
	// (+) оставляем строки, в которых колонка2 заполнена,а остальные ПУСТЫЕ
	lst = List.RemoveItems(Table.ColumnNames(Add),{"Column2"}) 	// список колонок без значения "Column2"
	to  = Table.SelectRows(clear, each List.IsEmpty(List.RemoveMatchingItems(
			Record.ToList(Record.SelectFields(_, nms))
			, {null,""}
		  )))
	
	// в которой колонки кроме заланной непустые (заполненные)
	to = Table.SelectRows(from, 
			each not List.IsEmpty(List.RemoveMatchingItems(
					Record.ToList(
						Record.SelectFields(
							_, 
							List.RemoveItems(Table.ColumnNames(from), {"СтатьяСтрока"}) )
						)
			, {null,""}
		  )))
	

//  Оставляем строки, в которых хотя бы одно не пустое
	Record.ToList(_) <> List.RemoveMatchingItems(Record.ToList(_),{null,""})

//  Оставляем строки, в которых ВСЕ значения заполнены
	Record.ToList(_) = List.RemoveMatchingItems(Record.ToList(_),{null,""})
	
//  Оставляем строки, в которых ВСЕ значения заполнены (кроме первых двух столбцов) - List.RemoveFirstN
	List.RemoveFirstN(Record.ToList(_), 2) = List.RemoveMatchingItems(List.RemoveFirstN(Record.ToList(_), 2), {null,""} )

--- AddColumn
// https://www.youtube.com/watch?v=uzPsN5z3FbE  - отжиганов
= Table.AddColumn(from, "col1", each _) 				// значение всех колонок - Record на выходе
= Table.AddColumn(from, "col1", each Record.ToList(_)) 	// значение всех колонок - List на выходе
= Table.AddColumn(from, "NonC", each List.NonNullCount(Record.ToList(_))) // количество ЗАПОЛНЕННЫХ колонок в строке
= Table.AddColumn(from, "col1", each List.NonNullCount(Record.ToList(_))=0)
= Table.AddColumn(from, "col1", each List.RemoveMatchingItems(Record.ToList(_),{null,""})) // только заполненые ячейки без null и пустоты

//  Добавляем колонку в которой (после each должно идти):
// 	возвращяется список значений!
	Record.ToList(_) или Record.FieldValues(_)			 // список значений ВСЕХ полей записи -> List
	
	List.RemoveMatchingItems(Record.ToList(_),{null,""}) // список значений в строке БЕЗ пустых значений -> List
	List.RemoveMatchingItems(Record.FieldValues(from{1}),{"",null}))	// вторая строка 
	
	List.Buffer(List.RemoveMatchingItems(Record.FieldValues(from{2}),{"",null,"по"}))  // третья строка в которой нет
	
	List.RemoveFirstN(Record.ToList(_), 2)				// список значений всех полей записи, КРОМЕ первых двух 
	List.RemoveLastN(Record.ToList(_), 3)				// список значений всех полей записи, КРОМЕ последних трёх
	
	Record.SelectFields(_, nms)  						// поля записи ИЗ СПИСКА столбцов nms 			-> Record
	Record.ToList(Record.SelectFields(_, nms))  		// список значений полей ИЗ СПИСКА столбцов nms -> List
	
	
// 	непустые в колонках
	= Table.SelectRows(from, each List.IsEmpty(List.RemoveMatchingItems(Record.ToList(Record.SelectFields(_, {"Column2","Column3"})),{null,""}))) 

	= 	Table.SelectRows(selr, each 
			not List.IsEmpty(
				List.RemoveMatchingItems(
					Record.ToList(
						Record.SelectFields(_, {"Column2","Column3"})
					)
				, {null,""})
			)
		)
	
		 
================================================
    ListOfLengths = {5,32,14,31,55,6,7,8,9},
    ListPosition  = List.Positions(ListOfLengths),
    Positions     = {0} & List.Transform(ListPosition, (x)=>List.Sum(List.FirstN(ListOfLengths, x+1)) ),
    ColNames      = {"Номер","Автор","Категория","Руководитель","Работа","Балл","Апробация","Рецензия","ВОзврат"},    
	
	
==== Предыдущая строка =============================================
// Функция: fxAddOtherRowColumn
// добавляем/меняем колонку со значением и смещением - предыдущие и или последующие строки
(tbl as table, col as text, newcol as text, index) =>
    let lst = List.Buffer(Table.Column(tbl,col)),
        add = Table.AddIndexColumn(tbl,newcol,index,1),
        f1  = if index<0 then (x)=> if x<0  then null else lst{x} else (x)=>lst{x}?,
        f2  = if index<0 then (x)=> if x<0  then null else lst{x} else (x)=>lst{x}? & " " & lst{x+1}?,  // + следстрока
        to  = Table.TransformColumns(add,{newcol,f2})
    in to
	
// или через шаги 	
let tbl = Table.FromColumns({{"a".."i"}},{"a"}),	// таблица
    lst = List.Buffer(tbl[a]),						// колонка с данными
    add = Table.AddIndexColumn(tbl,"index",1,1),	// добавляем столбец с индексом
    to  = Table.TransformColumns(add,{"index", (x)=>lst{x}? & " + " & lst{x+1}?})	// меняем колонку с индексами на значение из исходной колонки
in  to

// Товарищ - добавляем в колонку список из строки +3 ниже разделенный "|" - это шапка
// https://comrade-xl.ru/2019/09/03/nerazmechenniy-tekst/
	to = Table.AddColumn(from, "Заголовки0", each 
			if   Text.Contains([Column1], "Code") 
			then  Text.Split(from[Column1] {[Индекс] + 3}, "|")
			else null
		)

============================================================
// ищем значение в таблице и координаты ячейки заносим в Record 
let
    Source = Table.FromRows(Json.Document(Binary.Decompress(Binary.FromText("i45WurDrwr6LTUo6Shc2XthwYS8IgzizQKIXGy/svrAPKBCrE60E5OwDq9l1YQNQBVC2G8jcBOYYwVRAlAP1b77YcLH5YgdYFmTYhf0XdlzsB6qLBQA=", BinaryEncoding.Base64), Compression.Deflate)), let _t = ((type nullable text) meta [Serialized.Text = true]) in type table [Column1 = _t, Column2 = _t, Column3 = _t]),
    func = (word) =>
		[ r = Table.AddIndexColumn(Source, "row", 1, 1),
          c = Table.AddIndexColumn(Table.Transpose(Source), "col", 1, 1),
          coordinates = [ row = Table.FindText(r, word)[row]{0}, 
			  			  col = Table.FindText(c, word)[col]{0} ]
        ][coordinates],
    search = func("2")	// искомое значение
in  search

----------------------------------------------------------------------------------
// оставляем в строке только слова из списка
let
    Source 		 = Table.FromRows(Json.Document(Binary.Decompress(Binary.FromText("TY5NC4JAGIT/yrBnD2Yfdg3qIBRYHgrMw4u+6OK6hrtS/vtWQdjrPM8Mk+ci5cH0eiMCkUDJlpFOtum1KIKVRY49GaNZGUhXeHjG1hnZ/Qov2rnoNsEydXPTIPvQ0CKA8zxt77TLr2QFUgq2YXxp8vhh+dWQZZxPLw/E8z6kQUe1LD1wXBpVr99jGEaxXX6TdselrkVR/AE=", BinaryEncoding.Base64), Compression.Deflate)), let _t = ((type nullable text) meta [Serialized.Text = true]) in type table [Respondent = _t, Text = _t]),
    LanguageList = {"Python","R","SQL","Spark","DAX","M"},
    Trim         = Table.AddColumn(Source, "Trim", each Text.Trim([Text]), type text),
    Clean        = Table.TransformColumns(Trim,{{"Trim", Text.Clean, type text}}),
    #"Renamed Columns" = Table.RenameColumns(Clean,{{"Trim", "Trim & Clean"}}),
    Split        = Table.AddColumn(#"Renamed Columns", "Split Into List", each Text.Split([#"Trim & Clean"], " ")),
    #"Added Custom1" = Table.AddColumn(Split, "Extract Languages", each List.Intersect({[Split Into List],List.Buffer(LanguageList)})),
    ListToTable  = Table.AddColumn(#"Added Custom1", "List To Table", each Table.FromList([Extract Languages])),
    #"Expanded List To Table" = Table.ExpandTableColumn(ListToTable, "List To Table", {"Column1"}, {"Languages"}),
    #"Removed Other Columns" = Table.SelectColumns(#"Expanded List To Table",{"Respondent", "Text", "Languages"}),
    #"Removed Columns" = Table.RemoveColumns(#"Removed Other Columns",{"Text"}),
    Final = Table.TransformColumnTypes(#"Removed Columns",{{"Languages", type text}})
in
    Final
	
=========================
// с какой позици начинать каждый элемент списка с 1 10 и 40
= Combiner.CombineTextByPositions({1, 10, 40})({"1234", "567", "89"})	




/* Рекурсивные функции
   Рекурсивной называется функция, которая вызывает себя в теле своего собственного определения. 
   Чтобы избежать попадания в бесконечный цикл, нужно задать условия выхода из цикла. 
   Ниже приведен пример функции, которая принимает один параметр, и если он больше или равен 100, 
   то функция возвращает значение параметра, а если он меньше 100, функция вызывается 
   рекурсивно с исходным значением параметра, умноженным на 2.
  Для вызова рекурсивно используется оператор @ перед именем функции.
*/

let
    DoubleToOneHundred = (x) =>	//Определение рекурсивной функции с одним параметром
        if x > 100				//Если параметр более 100, возвращается значение параметра
        then x					//Если параметр не более 100, он умножается на два и функция вызывается повторно
        else @DoubleToOneHundred(x*2)
in
    DoubleToOneHundred


// разбить по большим буквам
// Пример разделения текста на слова. Обрати внимание на последние два шага, List.Transform + Table.TransformColumnTypes
let
    Source 		   = #table(type table[Enum = text],{{"EnumNumberOne"},{"EnumTwo"}}),
    Splitted 	   = Table.TransformColumns(Source, {{"Enum", each Splitter.SplitTextByPositions(Text.PositionOfAny(_,{"A".."Z"},Occurrence.All))(_)}}),
    Tabled         = Table.TransformColumns(Splitted,{{"Enum", each Table.FromColumns(List.Zip({_}))}}),
    ColumnNames    = Table.ColumnNames(Table.Combine(Tabled[Enum])),
    NewColumnNames = List.Transform(ColumnNames, each "Enum."&Text.Middle(_,6)),
    ExpandedEnum   = Table.ExpandTableColumn(Tabled, "Enum", ColumnNames, NewColumnNames),
    TransformList  = List.Transform(NewColumnNames, each {_,type text}),
    Typed          = Table.TransformColumnTypes(ExpandedEnum, TransformList)
in
    Typed
	

	
*----------------------------*

// В нём сравниваются столбцы из GetSourceData и ExpectedColumns, после чего выводится список добавленных/удалённых столбцов.

let ExcelSource 	= Excel.CurrentWorkbook(){[Name="Columns"]}[Content],	// Соединимся с таблицей Excel, содержащей ожидаемые заголовки
    ExpectedColumns = Table.Column(ExcelSource, "ColumnName"),			   	// Получаем список ожидаемых заголовков
    CSVColumns 		= Table.ColumnNames(GetSourceData),						// Список заголовков файла csv
    MissingColumns 	= List.Difference(ExpectedColumns, CSVColumns),			// Ищем отсутствующие столбцы
    AddedColumns 	= List.Difference(CSVColumns, ExpectedColumns),			// Ищем добавленные столбцы
    //Все изменения
    OutputMissing = if List.Count(MissingColumns)=0 
					then "No columns missing" 
					else "Missing columns: " & Text.Combine(MissingColumns, ","),
    OutputAdded = 	if List.Count(AddedColumns) = 0 
					then "No columns added" 
					else "Added columns: " & Text.Combine(AddedColumns, ","),
    Output = OutputMissing & "   " & OutputAdded
in  Output
	
*----------------------------*
/* 
	Проверка наличия столбцов в источнике данных Power Query
	Иногда требуется простая проверка наличия всех необходимых столбцов в источнике данных. 
	В этом нам поможет функция Table.HasColumns().
	Проверим наш csv-файл на присутствие трёх столбцов Product, Month и Sales. 
	Следующий запрос возвращает ИСТИНА, если в источнике данных есть все столбцы и ЛОЖЬ в противном случае:
*/

let Source 			= Csv.Document(File.Contents("C:\MissingColumnDemo.csv"),[Delimiter=",",Encoding=1252]),
    PromotedHeaders = Table.PromoteHeaders(Source),
    CheckColumns 	= Table.HasColumns(PromotedHeaders, {"Product", "Month", "Sales"})
in  CheckColumns


---------------------------------------------------------------------------------
// Список столбцов в подколонках
	to = 
		let add = Table.AddColumn(from, "Колонки", each Table.ColumnNames([Data2]), type list),
            lst = List.Distinct(List.Combine(add[Колонки]))
        in  lst
---------------------------------------------------------------------------------		
// классная статья на хабре, почему не надо бояться - https://habr.com/ru/articles/311600/

//  дни недели по порядку
	to = List.Accumulate({1..7}, {}, (accum,x)=> accum & {Date.DayOfWeekName(x+1)})
	to = List.Accumulate({1..7}, {}, (accum,x)=> accum & {Date.DayOfWeekName(#date(2024,1,x))}) // в 2024 г пн = 1 число января

//  месяцы по порядку
	to = List.Accumulate({1..12}, {}, (accum,x)=> accum & {Date.DayOfWeekName(#date(2024,x,1))})	
	
//  по дню делени возвращает номер дня
	(x)=> List.PositionOf({"понедельник", "вторник", "среда", "четверг", "пятница", "суббота", "воскресенье"}, Text.Lower(x)) + 1
	f=(x)=>(List.PositionOf({"понедельник", "вторник", "среда", "четверг", "пятница", "суббота", "воскресенье"}, _) + 1)
	
// доделать
	List.Positions(Text.Split("понедельник|вторник|среда|четверг|пятница|суббота|воскресенье","|"))
	
ЗАМЕНА+
// замена всех слов из списка
	lst = List.Buffer({"ст.преп", "доц."}), 
	f=(x)=> Text.Combine(List.RemoveItems(Text.Split(x," "), "ст.преп", "доц.")," "),
    tr  = Table.TransformColumns(transform1, {"Предмет", f, type text})	
	
------------------------
// Словарь	 dict

= List.Buffer(Table.FromValue({ 
            {"Основы машинного обучения", "ОМО"},
            {"потребительской кооперации", "ПК"} 
            }) [Value])
			
-----------------------------------------------

= (x)=> List.PositionOf({"понедельник", "вторник", "среда", "четверг", "пятница", "суббота", "воскресенье"}, Text.Lower(x)) + 1

			
 // предыдущая строка убрать потом
 AddColumn = Table.AddColumn(FillDown, 
            "Индекс", 
                each if List.ContainsAny( 
                                    { [Время] }, 
                                    { #time(9, 0, 0), #time(10, 50, 0),#time(12, 55, 00),#time(14, 40, 0),#time(16, 25, 0),#time(18, 30, 0),#time(20, 15, 0)}) = true                                     
                        then 1
                        else 2, Int64.Type),
    AddIndexCol1 = Table.AddIndexColumn(AddColumn, "Index1", 1, 1, Int64.Type),
    AddIndexCol2 = Table.AddIndexColumn(AddIndexCol1, "Index2", 0, 1, Int64.Type),

// пример оформления кода
replaceRepDelimiters = 
	Table.TransformColumns ( replace,
		{
		  "Column1",
		  (x)=>
			[ replaceStartDelimiter = List.Accumulate ( startDelimitersLst, x, ( s, c ) => Text.Replace ( s, c, ">" ) ),
			  splitByStartDelimiter = Text.Split ( replaceStartDelimiter, ">" ),
			  alternateLst          = List.Alternate ( splitByStartDelimiter, 1, 1, 1 ),
			  combineText           = Text.Combine ( alternateLst )
			][combineText]
		}
	),
// интересный код от Лящука, парсинг страницы
let
    Source = List.Buffer(Lines.FromBinary(Web.Contents("https://www.rotowire.com/basketball/player.php?id=2502"))),
    fn = (src, tag, class, fn_)=> 
		let
			pos = List.PositionOf(src, class, 3, (a,b)=>Text.Contains(a,b)),
			fx = (s,tag) => List.Count(Text.Split(s,"<"&tag))-List.Count(Text.Split(s,"</"&tag&">")),
			gen = 
				List.Transform(
					pos,
					each List.Generate(
						()=>[i=_,j=0,d=fx(src{i},tag)],
						each [d]>0 or [j]=0,
						each [i=[i]+1,j=[j]+1,d=[d]+fx(src{i},tag)], 
						each src{[i]}
					)
				),
			ret = List.Transform(gen,each fn_(Web.Page(Text.Combine(_))[Data]{0}[Children]{0}{[Name="BODY"]}[Children]{0}))
		in ret,
    
	init = 
        [
            headers = {"Status","News","Analysis"}, 
            enities = {
                [tag="div",class="news-update__playerhead",callback=each [Children]{0}[Children]{0}[Text]],
                [tag="div",class="news-update__news",callback=each [Children]{0}[Text]],
                [tag="div",class="news-update__analysis",callback=
                    each let Prepared=Table.ReplaceValue([Children],null,each [Children]{0}[Text],Replacer.ReplaceValue,{"Text"})[Text] 
						  in Text.Combine(List.Skip(Prepared,2))
                ]
            }
        ],
    Result = Table.FromColumns(List.Transform(init[enities], each fn(Source, [tag], [class], [callback])),init[headers])
in  Result


// Решение.
// Есть 2 колонки.фрукты и числа как + и отрицательные. Нужно посчитать количество подряд идущших отрицательных знапчений

let // Шаг 1: Исходный набор данных
    ИсходнаяТаблица = Excel.CurrentWorkbook(){[Name="Table1"]}[Content],

    // Шаг 2: Добавление индексного столбца
    ДобавитьИндекс = Table.AddIndexColumn(ИсходнаяТаблица, "Индекс", 0, 1, Int64.Type),

    // Шаг 3: Создание столбца-счетчика
    ДобавитьСчетчик = Table.AddColumn(ДобавитьИндекс, "Счетчик", each 
        List.Accumulate({0..[Индекс]}, 0, (state, current) => 
            if ДобавитьИндекс[данные]{current} < 0 then state + 1 else 0
        )
    ),
  
  rem = Table.RemoveColumns(ДобавитьСчетчик,{"Индекс"})
in  rem

 
  (x)=>fxPowerTrim(x,"—")
  = Table.TransformColumns(trans, {"Z -21", (x)=> Text.Combine(List.Select(Text.Split(x, "—"), (t)=> t <> ""), "/") } )
  
 
 // Решение. Удаление подряд идущих символов в текстовой строке
 // вариант 1 - пордяд идущий символ "—" не в начале и не в конце строки!
 let
    from    = "мама мыла раму ——————————— папа кушал сало",
    split   = Text.Split(from,"—"), // делим по разделителю "—". Разделитель удаляется!
    select  = List.Select(split,(x)=>x <> ""), // выбираем непустые значения. Пустоты появлятся если разделители идут подряд
    combine = Text.Combine(select,"/") // соединяем значения обратно через нужный разделитель "/"
in  combine
// на выходе: "мама мыла раму / папа кушал сало"

// вариант 2 - пордяд идущий символ "—" может быть в начале и не в конце строки!
 let
    from      = "————— мама мыла раму ——————————— папа кушал сало ——————————————",
    split     = Text.Split(from,"——"), // делим по разделителю "—". Разделитель удаляется!
    select    = List.Select(split,(x)=>x <> ""), // выбираем непустые значения. Пустоты появлятся если разделители идут подряд
    transform = List.Transform(select,(x)=>Text.Replace(x,"—","/")), // меняем "—" на "/"
    combine   = Text.Combine(transform,"") // соединяем значения без разделителя
in  combine
// на выходе: "/ мама мыла раму / папа кушал сало /"    

(x)=>List.Transform(List.RemoveItems(Text.Split(x,"—"),{""," "}),Text.Trim) } )
(x)=> Text.Combine(List.Transform(List.Select(Text.Split(from,"——"),(x)=>x<>""),(x)=>Text.Replace(x,"—","/")),"") 

// Решение. Словарь на записях (на примере моего примера №14 пол замене подряд идущих символов)
let    
	rec = 	Record.FromList(
				List.Transform({1..20}, (x)=>"/" ), 
				List.Transform({1..20}, (x)=>Text.Repeat("—", x) )
			),
    f=(x)=> Text.Combine(
				List.Transform(
					Text.SplitAny(x, " "), 
					(x)=>Record.FieldOrDefault(rec, x, x )
				)," "
			),
	
	from = Table.FromRows(Json.Document(Binary.Decompress(Binary.FromText("i45WetQwBY4ULuy5sAGEgYyL3Rd2AxkXG0AiF5sVkNWBle4HSuwHKd11sfliB5CzW+FiI4i6sA9dMRApxepEK9HYeFp4hZruJmQWfr2xAA==", BinaryEncoding.Base64), Compression.Deflate)), let _t = ((type nullable text) meta [Serialized.Text = true]) in type table [txt = _t]),
    to = Table.AddColumn(from, "to", (x)=>f(x[txt]))
in  to


// Решение
// На входе таблица ихз двух столбцов. ФИО  + дата примема (3 года)
// надо сгруппировать количество принятых в разрезе месяцев кажлого года, но!!! вместо пусто должен стоять 0
let
    from = Excel.CurrentWorkbook(){[Name="Data"]}[Content],
    nms  = {"Год","Месяц"},
    lst  = List.TransformMany({2020..2023}, (x)=>{1..12}, (x,y)=>{x,y}), // список списком год + месяц
    tbl  = Table.FromList(List.Transform(from[Дата приема],(i)=>{Date.Year(i),Date.Month(i)}) & lst, (x)=>x, nms), // список по факту
    gr   = Table.Group(tbl, dts, {"Количество ТУ", each Table.RowCount(_)-1}),
    to   = Table.Sort(gr,dts)
in  to


// функция проверки наличия ключевого слова с таблице/ 3 ВАРИАНТА СИНТАКСИСА
// 1. Таблицу загоняем в список значений, где каждый столбец отдельный список
// 2. Убираем null из каждого списка значений в списке столбцов
// 3. применяем функцию в каждому списку

    fxContainsKeyword = (table as table, keyword as text) as logical =>
        let // Преобразуем все столбцы таблицы в список значений
            columnChecks = Table.ToColumns(table),
            
            // убираем нули в списке значение, иначе будет ошибка
            listRemoveNulls = List.Transform(columnChecks, List.RemoveNulls),
            
            // функция для проверки наличия ключевого слова в столбце
            checkColumn = (column as list) => List.ContainsAny(column, {keyword}, Text.Contains),
            
            // Применяем функцию к каждому столбцу таблицы
            columnResults = List.Transform(listRemoveNulls, (x)=>checkColumn(x) ),
        
            // Если хотя бы один столбец содержит ключевое слово, результат - true
            result = List.AnyTrue(columnResults)
        in  result 

// тоже самое но укороченное		
        fxContainsKeyWord = (table as table, keyword as text) as logical =>
            let a = Table.ToColumns(table), // преобразуем все столбцы в список значений
                b = List.Transform(a, List.RemoveNulls), // убираем нули в списке значений, иначе ошибка
                f = (row as list) => List.ContainsAny(row, {keyword}, Text.Contains), // проверяем наличия ключевого слова
                g = List.Transform(b, (x)=> f(x) ), // применяем функцию к каждому столбцу (значения в list)
                h = List.AnyTrue(columnResults) // если хотя бы один столбец содержит ключевое слово, результат - true
            in  h,

// тоже самое но укороченное		
	fxContainsKeyWord = (table as table, keyword as text) as logical =>
		List.AnyTrue(
			List.Transform(
				List.Transform(Table.ToColumns(table), List.RemoveNulls),
				(x as list) => List.ContainsAny(x, {keyword}, Text.Contains) )
			),			
			
			
// список трансформирует и сделает вместо чисел порядковый номер, могут быть нули межу цифрами
let f=(x)=>if x =null then 0 else x,
    from = Excel.CurrentWorkbook(){[Name="Таблица1"]}[Content],
    lst = List.Buffer(from[Сумма]),
    gen = List.Generate(()=>[i=0,j=lst{i},k=i+1],
                        (x)=>x[i]<List.Count(lst),
                        (x)=>[i=x[i]+1,j=lst{i},k=if f(j)>0 then x[k]+1 else x[k]],
                        (x)=>if f(x[j])>0 then {x[k]} else {null}),
    nms = Table.ColumnNames(from)&{"new"},
    to = Table.FromList(List.Zip({Table.ToList(from,(x)=>x),gen}),List.Combine,nms)
in  to			

// Итак можно?! )
// https://www.planetaexcel.ru/forum/index.php?PAGE_NAME=read&FID=1&TID=139390&TITLE_SEO=139390-pq-textsplit-bez-dobavleniya-novogo-stolbtsa
= Table.TransformColumns(
        Источник, 
        List.Transform( 
            Table.ColumnNames(Источник), 
            each {_,(t)=>try Text.Split(t,";") otherwise {t}, type list}) )
			
====================================================================================================
																				* Table.ReplaceValue
====================================================================================================

// в танке "Точно не тыква. Уже сильные изменения благодаря Вашим видеоразборам и подсказкам в чате"
	to = Table.ReplaceValue(
			FROM,
			null,
			"EMPT",
			Replacer.ReplaceValue,
			List.Select(Table.ColumnNames(FROM),(x)=>Text.Contains(x, "Вид")) // колонки с "Вид" в названии
		)
		
// выбор в избранных колонках и подсчет непустых 
let from = Excel.CurrentWorkbook(){[Name="Таблица3"]}[Content],
    nms  = Table.ColumnNames(from),
    lst  = List.Buffer(List.Select(nms,(x)=>Text.Contains(x,"Элемент"))),
    tr   = Table.TransformColumns(from,{},(x)=>if x=" " then null else x),
    gr   = Table.Group(tr,"Наименование товара",{
				{"tmp",(x)=>x},
				{"U",  (x)=>[ a = Table.RowCount(Table.Distinct(Table.SelectColumns(x,lst))),
							  b = if a =1 then "нет" else "да"][b]}
			}),
    exp=Table.ExpandTableColumn(Table.RemoveColumns(gr,{"Наименование товара"}),"tmp",nms),
    
	// вот тут интеерсный код. просматривает построчно все колонки по макске имени
	to=Table.AddColumn(exp,"T",(x)=>[
		a=List.RemoveNulls(Record.ToList(Record.SelectFields(x,lst))),
		b=if a={}then "нет" else "да"
	][b])
in  to


// 	Михаил разрыв PDF	
let from  = Excel.CurrentWorkbook(){[Name="Таблица1"]}[Content],
    filtr = Table.SelectRows(from, each ([Факт нарушения] <> null and [Факт нарушения] <> "Факт нарушения")),
    lst   = List.Buffer(List.Transform(List.Skip(Table.ColumnNames(from)),(x)=>{x,(y)=>Text.Combine(Table.Column(y,x)," ")})),
    to    = Table.Group(filtr, "№ п/п",lst,GroupKind.Local,(s,c)=>Number.From(c<>null))
in  to
	
	to = 	List.Transform(
				List.Skip(Table.ColumnNames(from)),
				(x)=>{
						x,
						(y)=>Text.Combine(Table.Column(y,x)," ")
					})
			
====================================================================================================
	#1C 															
====================================================================================================
// файлы смотри в папке по 1С на лиске Хранилище

//	обработка журнала проводок в 1С (вариант 1) - разбираем журнал по колонкам
let Source = Excel.CurrentWorkbook(){[Name="dataBody"]}[Content],
    Header = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    RemCol = Table.RemoveColumns(Header, List.Select(Table.ColumnNames(Header), (x)=>Text.StartsWith(x,"Column") ) ),
    Group  = Table.Group(RemCol, 
        {"Дата"}, 
        {{"tab", (x)=> // обрабатываем каждую колонку. Если непустых строк 0 или 1, то выводим первое, иначе соединяем
			[ lst = List.Transform(
						Table.ToColumns(x), 
						(i)=> if List.Count(List.RemoveNulls(i)) < 2 then i{0} else Text.Combine(i,"|") 
					),
			  to  = Table.FromRows({lst}, Table.ColumnNames(RemCol))
            ][to], type table}},
        GroupKind.Local, 
        (s,c) => Number.From( c[Дата] <> null) )
	to = Table.Combine(Group[tab])
in  to Lis
in  to 

//	оформление одной строкой если 
	{{"tab", each Table.FromRows({List.Transform( Table.ToColumns(_), 
			 each if List.Count(List.RemoveNulls(_)) < 2  then _{0} else Text.Combine(_,"|") )}, Table.ColumnNames(del)), 
			 type table}},
			 
//	обработка журнала проводок в 1С (вариант 2) - разбираем журнал построчно
//  	1. соединяем каждые три строки относящиеся к одной проводке в одну подтаблицу (Table.ToRows)
// 		2. соединяем (List.Combine) три строки в один длинный список
//		3. делаем из каждого длиного списка таблицу (Table.FromRows)
let from 		= Excel.CurrentWorkbook(){[Name="Таблица1"]}[Content],
    AddedIndex  = Table.AddIndexColumn(from, "Индекс", 0, 1),
    AddedGroup  = Table.AddColumn(AddedIndex, "группа", each Number.IntegerDivide([Индекс], 3), Int64.Type),
    GroupedRows = Table.Group(AddedGroup, {"группа"}, {{"таб", each Table.FromRows( {List.Combine( Table.ToRows( _ ) )} ), type table}}),
    Custom1 	= Table.Combine( GroupedRows[таб] ),
    Headers 	= Table.PromoteHeaders(Custom1, [PromoteAllScalars=true]),
    SelectCol   = Table.SelectColumns(Headers, List.Select(Table.ColumnNames(Headers), each not Text.Contains(_,"Column") ) )
in  SelectCol


====================================================================================================
	# Table.FromList – пять аргументов счастья 						АнатомияФункций - Table.FromList
====================================================================================================
ВАЖНО - работает со списоком СПИСКОМ СПИСКОВ, а не таблицей со списками
// Всё руки не доходили написать про одну из моих любимых функций.
// Сначала читаем справку:
	Table.FromList(
		list as list, 
		optional splitter as nullable function, 
		optional columns as any, 
		optional default as any, 
		optional extraValues as nullable number
	) as table

//  Обращаем внимание, что обязательным является только первый аргумент – list. Проверяем:
	to = Table.FromList({"a,b,c,1","d,e,f,2","g,h,i,3"})

//  Работает, заодно узнаем, что по дефолту она ещё и текст по запятой делит, т.е. следующий код выдаст то же самое:
	to = Table.FromList({"a,b,c,1","d,e,f,2","g,h,i,3"},Splitter.SplitTextByDelimiter(","))

//  Тогда зачем вообще писать splitter? Ну во-первых разделитель не всегда запятая:
	to = Table.FromList({"a;b;c;1","d;e;f;2","g;h;i;3"},Splitter.SplitTextByDelimiter(";"))

//  А главное вторым аргументом может быть любая другая функция, возвращающая СПИСОК:
	to = Table.FromList({"a;b;c;1","d;e;f;2","g;h;i;3"},(x)=>Text.Split(x,";"))
	to = Table.FromList({"abc1","def2","ghi3"},Text.ToList)

//  Ну ОК, а вот такая ситуация
	to =  Table.FromList({"a;b;c;1","d;e;f;2","g;h;i;3;4;5"},(x)=>Text.Split(x,";"))
	// Даст ошибку в третьей строке. Причина  - таблица собирается на основе первой строки, а в третьей столбцов оказалось больше. 
	// Решение - добавить третий аргумент (columns):
	
	to = Table.FromList({"a;b;c;1","d;e;f;2","g;h;i;3;4;5"},(x)=>Text.Split(x,";"),6)
	//Т.е. в третий аргумент поместили целевое количество столбцов (в общем виде это не обязательно константа – его можно и вычислить (https://t.me/PQ_ru/24316)). 

//	Также обращаем внимание, что отсутствующие значения были заменены на null, но если нужно что-то другое  - привлекаем четвертый аргумент (default):
	to = Table.FromList({"a;b;c;1","d;e;f;2","g;h;i;3;4;5"},(x)=>Text.Split(x,";"),6,"-")

//	Обратная ситуация – нам нужны только первые три столбца:
	to = Table.FromList({"a;b;c;1","d;e;f;2","g;h;i;3;4;5"},(x)=>Text.Split(x,";"),3,"-",ExtraValues.Ignore)
	
	// Т.е. пятый аргумент (extraValues) говорит, что делать с дополнительными значениями - в ситуации выше они проигнорированы, а вот в ситуации ниже – собираются в список:
	to = Table.FromList({"a;b;c;1","d;e;f;2","g;h;i;3;4;5"},(x)=>Text.Split(x,";"),4,"-",ExtraValues.List)
	// Это бывает удобно. 

//	Но что, если мы не хотим дефолтные имена столбцов - да пожалуйста:
	to = Table.FromList({"a;b;c;1","d;e;f;2","g;h;i;3;4;5"},(x)=>Text.Split(x,";"),{"а","б","в","г","д","e"})
	// Т.е. можно передать список имен. 

//	Более того, можно передать названия и типы:
	to = Table.FromList(
			{"a;b;c;1","d;e;f;2","g;h;i;3;4;5"},
			(x)=>Text.Split(x,";"),
			type table [а=text,б=text,в=text,г=number,д=number,е=number]
		 )

//  Внимательные читатели обратят внимание, что типы столбцов поменялись, а вот сами значения остались текстовыми. 
//	Об этом нужно помнить, но поскольку функция разделения реально может быть любой, можно чутка усложнить:
	to = Table.FromList(
			{"a;b;c;1","d;e;f;2","g;h;i;3;4;5"},
			(x)=>List.Transform(
					Text.Split(x,";"), 
					(y)=>try Number.From(y) otherwise y
				 ),
			type table [а=text,б=text,в=text,г=number,д=number,е=number]
		 )

/* 	Вот так, одним шагом список в таблицу с блэк-джеком и… 
	Ну а что до боевых примеров – так их есть уже на канале: эпичный челлендж (https://t.me/pbi_pq_from_tank/79), плач по регуляркам (https://t.me/pbi_pq_from_tank/66), даже в сортировке (https://t.me/pbi_pq_from_tank/80) засветилась.
	Как-то так. Простая, гибкая и шустрая (https://t.me/pbi_pq_from_tank/65), мечта, а  не функция! Юзайте с удовольствием.
	Надеюсь, было полезно */
			
			
			
tableColumnNames = Table.ColumnNames( tableSrc ),
listSelect = List.Select( tableColumnNames, ( x ) => Text.Contains( x, "пример...." ) ),
tableSelectColumns = Table.SelectColumns( tableSrc, listSelect )

List.Select( ... )&{"ID проверки"}


= Table.Group(from,"ID",{{"tmp",(t1)=> Table.AddIndexColumn(Table.Sort(t1,{"Дата выписки", Order.Ascending}),"№ п/п_gr",1)}})


================================
	# fnSWITCH
================================
//  использование функции, которая по первой букве выбирает из списка слово и выдает  результат
	to = Table.AddColumn(from, "tmp", each fnSWITCH(Text.Upper(Text.Range([BillingCode],8,1))))

(input) => 
	let values = {	{"E", "Employee"}, 
					{"S", "SCYC"}, 
					{"M", "Medical"}
					{input, "Undefined"} 
				 }, 
		Result = List.First(List.Select(values, (x)=> x{0}=input)){1} 
	in  Result
	
	
=======================================
	# Сравенение
=======================================
// сравнение по двум столбцам,аналог И или ИЛИ
 OR  = if List.AnyTrue({[Столбец1]="Иванов",[Столбец2]="Миша"})then "Есть такой!"else "Нет такого"
 AND = if List.AllTrue({[Столбец1]="Иванов",[Столбец2]="Миша"})then "Есть такой!"else "Нет такого"
 
 
=======================================
// Разобрать
=======================================


=== Можно и Duration =================================
 lst = List.Buffer(sort[Дата и время попадания на стадию] & {DateTime.LocalNow()} ),
 
=== Можно и Duration =================================
// https://www.planetaexcel.ru/forum/index.php?PAGE_NAME=message&FID=1&TID=127168&TITLE_SEO=127168-power-query-kak-ustranit-oshibku-pri-preobrazovanii-tekstovykh-znachen&MID=1048101&tags=&q=duration&FORUM_ID%5B0%5D=0&DATE_CHANGE=0&order=relevance&s=%D0%9D%D0%B0%D0%B9%D1%82%D0%B8#message1048101

	(x)=> 	if x = null then null else let t = List.Transform(Text.Split(x, ":"),Number.From) in #duration( 0, 0, t{0}, t{1} )
	
	(x)=> 	if x = null 
			then null 
			else let t = List.Transform(Text.Split(x, ":"),Number.From) 
				 in  #duration( 0, 0, t{0}, t{1} )


=== List_Transform =================================
	
	// Пример 1
	to = List.Transform({1..15}, each "Тема " & Text.From(_))	// Тема 1, Тема 2 ...
	
	// Пример 2
	f = (Source as table, Indices as list, ColumnNamesNew as list) =>
        let ColumnNamesOld = List.Transform( Indices, each Table.ColumnNames(Reorder){_} ), 
            ZippedList     = List.Zip( { ColumnNamesOld, ColumnNamesNew } ),
            RenamedColumns = Table.RenameColumns( Reorder, ZippedList )
        in  RenamedColumns,
    
	Result = f(Reorder, {2..16}, List.Transform({1..15}, each "Тема " & Text.From(_))),
	
=== Path =================================
// https://community.fabric.microsoft.com/t5/Power-Query/Power-Query-M-Path-Depth/td-p/2441991
// две колонки превращает в парент чилд
/* Table1
Target	Step_Pre
R	Hb
T	De
Table2

Step	Step_Previous
Cc	Ac
Db	Ac
Db	Ba
Eb	Bb
...
*/

let
    Source1 = Excel.CurrentWorkbook(){[Name="Table1"]}[Content],
    Source2 = Excel.CurrentWorkbook(){[Name="Table2"]}[Content],
    RefTbl=Table.Buffer(#table(Table.ColumnNames(Source1),Table.ToRows(Source2))&Source1),
    fx=(s,r)=>
        let
            a=Table.ToRows(Table.SelectRows(RefTbl,each [Step]=s)),
            ffx=(m,n)=>if m=null then n else List.Sort({m,n},each List.Count(Text.Split(_,"|"))){0},
            b=List.Accumulate(a,r,(x,y)=>@fx(y{1},Record.TransformFields(x,{y{1},each ffx(_,Record.FieldOrDefault(x,y{0},y{0})&"|"&y{1})},2)))
        in if a={} then r else b,
    Custom1 = #table(Table.ColumnNames(Source2)&{"Path","Depth"},List.TransformMany(Table.ToRows(Source2),each Table.ToRows(Record.ToTable(fx(_{0},[]))),(x,y)=>{x{0}}&y&{List.Count(Text.Split(y{1},"|"))-1}))
in
    Custom1
	
// Преобразование текуoих слолбцов из списка без добавления нового
    lst = {"500 м", "1000 м", "1500 м", "3000 м", "5000 м", "10000 м"},
    Вывод = 
		Table.TransformColumns(
			from, 
			List.Transform( 
				lst,
				each {_, (t)=> if (t) <>"" then "00:00:" & (t) else ""}
			) 
		)
in Вывод 


// преобразование 
// у  меня в столбце данные идут вот так М22092017, а мне нужно чтобы в соседнем столбце получилось 22.09.2017
let f=(txt as text) as date =>let txtLen = Text.Length(txt),
								  toISO = Text.End(txt, 4) & "-" & Text.Range(txt, txtLen - 6, 2) & "-" & Text.Range(txt, txtLen - 8, 2)
							   in  Date.From(toISO),
    test = ToDate("M23092017")
in  test
 
  
// Расчет амортизации  
f=(P,i,n)=>

let	
	Payment = P*((i/12)*Number.Power(1+(i/12),n))/(Number.Power(1+(i/12),n)-1),
	Payments =
		Table.FromList(
			List.Generate(
				()=>[Counter=0],
				each [Counter]<n,
				each [Counter=[Counter]+1],
				each P*(Number.Power(1+(i/12),n)-Number.Power(1+(i/12),[Counter]+1))/(Number.Power(1+(i/12),n)-1)
			)
		,Splitter.SplitByNothing(), {"Balance"}, null, ExtraValues.Error),

	MonthlyInterest  = Table.AddColumn(Payments,"Monthly Interest",each (i/12)*[Balance]),
	MonthlyPrincipal = Table.AddColumn(MonthlyInterest,"Monthly Principal",each Payment-[Monthly Interest]),
	MonthlyPayment   = Table.AddColumn(MonthlyPrincipal,"Monthly Payment",each Payment),
	PMTNumber        = Table.AddIndexColumn(MonthlyPayment, "Payment Number", 1, 1)		
in  PMTNumber



// fDistinctColumns.pq
(Table as table, optional MaxLength as number)=>
let
    TableType   = Value.Type(Table),
	ColNames    = Table.ColumnNames(Table),
    ListOfCols  = List.Transform(Table.ToColumns(Table), List.Distinct),
    Meta        = List.Transform(List.Zip({ListOfCols,ColNames}), each _{0} meta [ColName = _{1}]),
    SelectList  = List.Buffer(if MaxLength = null then Meta else List.Select(Meta, each List.Count(_)<=MaxLength)),
    NewColNames = List.Transform(SelectList, each Value.Metadata(_)[ColName]),
    NewTable    = Table.FromColumns(SelectList,NewColNames)
in
    NewTable
	
/*Эти функции в основном представляют собой версии функций, созданных Microsoft. Однако эти функции помогают сохранить возвращаемые типы функций, которые так легко теряются. Одним из практических результатов использования этих функций в ваших запросах является то, что столбцы вашей таблицы с меньшей вероятностью изменятся на какой-либо тип.*/

// FunctionAlternatives/List.Transform
(list as list, transform as function)=>
	let	listTransform = List.Transform(list, transform),
		listType      = type {Type.FunctionReturn(Value.Type(transform))}
	in	Value.ReplaceType(listTransform,listType)	

// PrefixColumnFunctions/PrefixCols.pq	
(Table as table, Prefix as text, Cols as list) =>   
	let ListOfLists = List.Transform(Cols, each {_,Prefix&_}),
		RenameCols  = Table.RenameColumns(Table,ListOfLists)
	in  RenameCols
	
/* 2 функции TableListFunctions */

// TableListFunctions/TableFromRecordOfLists
(rec as record)=>
let tab2col = Record.ToTable(rec),
    valuess_names = List.Reverse(Table.ToColumns(tab2col)),
    tab = Function.Invoke(Table.FromColumns,Valuess_Names)
in  tab
	
// TableListFunctions/TableToRecordOfLists
(table as table, optional buffer as nullable logical)=>
let tab    = if buffer = true then Table.Buffer(table) else table,
    Name   = Table.ColumnNames(tab),
    Value  = Table.ToColumns(tab),
    Record = Record.FromTable(Table.FromColumns({Name, Value},{"Name","Value"}))
in  Record	


// TextRemoveSymbols
TextRemoveSymbols = (inputtext as text) as text =>
let numberlists     = {{0..31},{33..47},{58..64},{91..96},{123..191}},	//get a list of lists containing the numbers of Unicode punctuation characters
    combinedlist    = List.Combine(numberlists),	//turn this into a single list
    punctuationlist = List.Transform(combinedlist, each Character.FromNumber(_)),	//get a list of all the punctuation characters that these numbers represent
    outputtext = Text.Remove(inputtext, punctuationlist) //inputtext = "Hello! My name is Chris, and I'm hoping that this *cool* post will help you!",the text with punctuation removed
in  outputtext


// CleanColumnNames
(Source as table) as table =>
	Table.RenameColumns(Source,
		List.Zip({
			Table.ColumnNames(Source),
			List.Transform(Table.ColumnNames(Source), each Text.Clean(Text.Trim(_)) 
			)
		})
	)
	
//record	
= Table.AddColumn(unpiv, "Пользовательский", 
	(x)=> Record.SelectFields(x,List.Skip(Table.ColumnNames(unpiv),2))
)
// list
= Table.CombineColumns(unpiv,List.Skip(Table.ColumnNames(unpiv),2), (x)=>List.Transform(x,(i)=>i),"tmp")
= Table.CombineColumns(unpiv,List.Skip(Table.ColumnNames(unpiv),2), (x)=>x,"tmp")



= Table.TransformColumns(Список,{"tmp", (x)=>
    List.Transform(x,
          (i)=>if fWordUpper(i,4)>0 then {1,2,3} else i
     )
})




	let
		Source  = Table.FromColumns( {{"а","а","б","б"},{1,2,3,7},{4,5,6,9}}),
		Grouped = 
			Table.Group(
				Source, {"Column1"}, 
				{
					{
						"таб", each 
						Table.FromRows(Table.ToRows(_) & 
							{
								{[Column1]{0} & " итог", List.Sum([Column2]), List.Sum([Column3])}
							}
						)
					, type table 
					}
				}
			),
		
		Out = Table.Combine(Grouped[таб])
	in
		Out
	
	

//  Список номеров строк в которых находится искомый текст
	to = Table.FindText(Table.AddIndexColumn(to, "index"), "дата")[index]
	
	
	
	
	
