// TO DO / Задачи       📝 🚧 🔜 🔄 ⏳ 🔹
// Ошибки / Проблемы    ❗  ❌ ⚠️ 🕳️ 🛠️ 🔥
// Статусы / Завершено  🎯 🏁 🔄 👍 🏗️ ✅
// Поиск / Анализ       🔍 🧐 🕵️ 📊 💡 📌
// Файлы / Проекты      📂 📁 🏗️ 🏷️ 📎
// Оптимизация          🚀 🔧 🎨 🕒 🏆 ⚡

//  во всех таблицах поднять заголовки
    let from = Excel.Workbook(File.Contents("....\Исходник.xlsx")),
        sel  = Table.SelectRows(from, (x)=>x[Item]="Покупатели" and x[Kind]="Sheet")[Data],
        to   = Table.Combine(List.Transform(sel,Table.PromoteHeaders))
    in  to

//  как обозначить колонки, от которых зависит фильтрация в таблице, чтобы обращаться к ним не напрямую (как это на примере ниже), а через список (lst), который содержит имена этих колонок (колонок может быть и больше). Если возможно, то несколько вариантов подскажите пожалуйста.
    lst = {"ТЗ1", "ТЗ2", "ТЗ3"},
    отбор = Table.SelectRows(Источник, each List.NonNullCount({[ТЗ1], [ТЗ2], [ТЗ3]}) > 0)

    let
        Source = #table(
            {"id", "b", "c", "d", "e"}, 
            {
                {1, null, null, null, null},
                {2, null, 4, null, null},
                {3, null, null, null, 5}
            }
        ), 
        lst = {"c", "d", "e"},
        nulls = List.Buffer(List.Repeat({null}, List.Count(lst))),
        rec_nulls = Record.FromList(nulls, lst),
        sel01 = Table.SelectRows(Source, each Record.ToList(Record.SelectFields(_, lst)) <> nulls),
        sel02 = Table.SelectRows(Source, each List.NonNullCount(Record.ToList(Record.SelectFields(_, lst))) > 0),
        sel03 = Table.SelectRows(Source, each List.Distinct(Record.ToList(Record.SelectFields(_, lst))) <> {null}),
        sel04 = Table.SelectRows(Source, each not List.IsEmpty(List.Skip(Record.ToList(Record.SelectFields(_, lst)), each _ is null))),
        sel05 = Table.SelectRows(Source, each not List.IsEmpty(List.RemoveNulls(Record.ToList(Record.SelectFields(_, lst))))), 
        sel06 = Table.SelectRows(Source, each Record.SelectFields(_, lst) <> rec_nulls),
        sel07 = Table.RemoveMatchingRows(Source, {rec_nulls}, lst)
    in
        sel07


//  функция генерации списка дат! Работает
    let
        fxListDatesCustom = (startDate as date, n as number, dur as duration) as list => List.Dates(startDate, n, dur),
        DocumentationMetaData = [
            Documentation.Name          = "fxListDatesCustom",
            Documentation.Description   = "This function generates a list of dates starting with a specified start date going for n number of dur periods.",
            Documentation.Examples      = {
                [ 
                    Description = "Generate a list of continuous dates from 06.04.2025 to 10.04.2025.",
                    Code        = "fxLoistDatesCustom(#date(2025, 4, 6), 5, #duration(1, 0, 0, 0)",
                    Result      = "06.04.2025#(lf)07.04.2025#(lf)08.04.2025#(lf)09.04.2025#(lf)10.04.2025"
                ]
            }
        ]
    in
        Value.ReplaceType(
            fxListDatesCustom, 
            Value.ReplaceMetadata(
                Value.Type(fxListDatesCustom), 
                DocumentationMetaData
            )
        )

//  функция в аргументами Meta // ХОРОШО
    let 
        Func = (input as record) => 
            let 
                one = input[Server], 
                two = input[Timeout], 
                tre = input[CutOff]
            in  
                {one,two,tre},

        NewType = type function ( input as [   
                Server           = (type text   meta [Documentation.SampleValues = { "localhost"}]), 
                optional Timeout = (type number meta [Documentation.FieldCaption = "Time Out [in seconds]",Documentation.AllowedValues = { 10, 60, 360 }]), 
                optional CutOff  = (type text   meta [Documentation.SampleValues = { "test"}])
            ]) as any, 

        Ascribed = Value.ReplaceType(Func, NewType) 
    in 
        Ascribed
        

//  Отлов неверного аргумента в функции!
    let 
        f = (input as record) =>
        let 
            //  Значения по умолчанию
                defaultOptions = [
                    Path = "",              // обязательный параметр
                    FileExtension = "xlsx", // расширение файла
                    SubFolders = false      // берем файлы текущей папки, в подпапки не смотрим
                ],

            //  Список допустимых имен аргументов
                validArguments = Record.FieldNames(defaultOptions),

            //  Проверка входного рекорда на недопустимые поля
                inputFields   = if input <> null then Record.FieldNames(input) else {},
                invalidFields = List.Difference(inputFields, validArguments),

            //  Выброс ошибки, если есть недопустимые поля
                checkArguments = 
                    if List.Count(invalidFields) > 0 
                    then error "Invalid argument(s): " & Text.Combine(invalidFields, ", ") & ". Valid arguments are: " & Text.Combine(validArguments, ", ")
                    else input,

            //  Совмещаем опции, если нет ошибок
                finalOptions =  if checkArguments = null 
                                then defaultOptions 
                                else Record.Combine({defaultOptions, checkArguments})
        in 
                finalOptions,

        // Тестовый вызов
        result = f([Path1 = "D:\1"]) // Должна быть ошибка
    in 
        result

//  метаданные
    https://baguzin.ru/wp/yazyk-m-power-query-metadannye/
    GetPage = (url as text) as table =>
        let
            Response = Json.Document(Web.Contents(url)),
            Table    = Table.FromRecords(Response[Data])
        in
            Table meta [NextLink = Response[Next]],

//  Иерархия. Интересный код
        let
            from = Table.FromRows(
            {
                {"Citizens Bank-Operating" ,"Total Company Cash" ,"Total Current Assets" ,"Total Assets" },
                {"Bill.com Money Out Clearing" ,"Total Company Cash" ,"Total Current Assets" ,"Total Assets" },
                {"Small Business Line (0026) - 3" ,"Total Company Cash" ,"Total Current Assets" ,"Total Assets" },

                {"Undeposited Funds" ,"Total Company Cash" ,"Total Current Assets" ,"Total Assets" },
                {"Accounts Receivable (A/R)" ,"Total Accounts Receivable" ,"Total Current Assets" ,"Total Assets" },
                {"Office furniture & Equipment" ,"Total Fixed Assets" ,"Total Fixed Assets" ,"Total Assets" },
                {"Software" ,"Total Fixed Assets" ,"Total Fixed Assets" ,"Total Assets" },

                {"Uncategorized Asset" ,"Total Other Assets" ,"Total Other Assets" ,"Total Assets" },
                {"Accounts Payable (A/P)" ,"Total Accounts Payable" ,"Total Current Liabilities" ,"Total Liabilities & Equity" },


                {"Chase Card-1916" ,"Credit Card" ,"Total Current Liabilities" ,"Total Liabilities & Equity" },
                {"Chase Card-4331" ,"Credit Card" ,"Total Current Liabilities" ,"Total Liabilities & Equity" },
                {"Chase Card-8512" ,"Credit Card" ,"Total Current Liabilities" ,"Total Liabilities & Equity" },


                {"Accrued 401K Employee Contribution" ,"Accured Expenses" ,"Total Current Liabilities" ,"Total Liabilities & Equity" },
                {"Accrued Expenses" ,"Accured Expenses" ,"Total Current Liabilities" ,"Total Liabilities & Equity" },
                {"Accrued Owner's Salary" ,"Accured Expenses" ,"Total Current Liabilities" ,"Total Liabilities & Equity" },
                {"Accrued Payroll" ,"Accured Expenses" ,"Total Current Liabilities" ,"Total Liabilities & Equity" },

                {"Balboa Capital Loan" ,"Accured Expenses" ,"Total Current Liabilities" ,"Total Liabilities & Equity" },
                {"Barclay Card" ,"Accured Expenses" ,"Total Current Liabilities" ,"Total Liabilities & Equity" },
                {"Chase - United" ,"Accured Expenses" ,"Total Current Liabilities" ,"Total Liabilities & Equity" },
                {"Chase Card-Mariott" ,"Accured Expenses" ,"Total Current Liabilities" ,"Total Liabilities & Equity" },
                {"Citizens- 0026" ,"Accured Expenses" ,"Total Current Liabilities" ,"Total Liabilities & Equity" },
                {"Shareholder Loan" ,"Accured Expenses" ,"Total Current Liabilities" ,"Total Liabilities & Equity" },

                {"Net Income" ,"Company Retained Earnings" ,"Total Company Equity" ,"Total Liabilities & Equity" },
                {"Retained Earnings" ,"Company Retained Earnings" ,"Total Company Equity" ,"Total Liabilities & Equity" },
                {"Owner's Pay & Personal Expenses" ,"Company Retained Earnings" ,"Total Company Equity" ,"Total Liabilities & Equity" },
                {"Shareholder Distributions" ,"Company Retained Earnings" ,"Total Company Equity" ,"Total Liabilities & Equity" },
                {"Total Stocks" ,"Total Stocks" ,"Total Company Equity" ,"Total Liabilities & Equity" },
                {"Total Common Stocks" ,"Total Common Stocks" ,"Total Company Equity" ,"Total Liabilities & Equity" }

            }, 
            type table [Name = text, BS_lvl_2 = text, BS_lvl_3 = text, BS_lvl_4 = text]
        ), 

            f=(x,y)=>
                let z = Table.Column(x,y),
                    a = List.Buffer(List.Distinct(z)),
                    f = (r)=>List.PositionOf(a,Record.Field(r,y))
                in  Table.AddColumn(x, y & "_Ind", f),
            
            nms = Table.ColumnNames(from),
            acc = List.Accumulate(nms,from,f)
        in
            acc

//  Иерархия2. Интересный код
        let
    src = Table.FromRows(
        {
            {"Citizens Bank-Operating" ,"Total Company Cash" ,"Total Current Assets" ,"Total Assets" },
            {"Bill.com Money Out Clearing" ,"Total Company Cash" ,"Total Current Assets" ,"Total Assets" },
            {"Small Business Line (0026) - 3" ,"Total Company Cash" ,"Total Current Assets" ,"Total Assets" },

            {"Undeposited Funds" ,"Total Company Cash" ,"Total Current Assets" ,"Total Assets" },
            {"Accounts Receivable (A/R)" ,"Total Accounts Receivable" ,"Total Current Assets" ,"Total Assets" },
            {"Office furniture & Equipment" ,"Total Fixed Assets" ,"Total Fixed Assets" ,"Total Assets" },
            {"Software" ,"Total Fixed Assets" ,"Total Fixed Assets" ,"Total Assets" },

            {"Uncategorized Asset" ,"Total Other Assets" ,"Total Other Assets" ,"Total Assets" },
            {"Accounts Payable (A/P)" ,"Total Accounts Payable" ,"Total Current Liabilities" ,"Total Liabilities & Equity" },


            {"Chase Card-1916" ,"Credit Card" ,"Total Current Liabilities" ,"Total Liabilities & Equity" },
            {"Chase Card-4331" ,"Credit Card" ,"Total Current Liabilities" ,"Total Liabilities & Equity" },
            {"Chase Card-8512" ,"Credit Card" ,"Total Current Liabilities" ,"Total Liabilities & Equity" },


            {"Accrued 401K Employee Contribution" ,"Accured Expenses" ,"Total Current Liabilities" ,"Total Liabilities & Equity" },
            {"Accrued Expenses" ,"Accured Expenses" ,"Total Current Liabilities" ,"Total Liabilities & Equity" },
            {"Accrued Owner's Salary" ,"Accured Expenses" ,"Total Current Liabilities" ,"Total Liabilities & Equity" },
            {"Accrued Payroll" ,"Accured Expenses" ,"Total Current Liabilities" ,"Total Liabilities & Equity" },

            {"Balboa Capital Loan" ,"Accured Expenses" ,"Total Current Liabilities" ,"Total Liabilities & Equity" },
            {"Barclay Card" ,"Accured Expenses" ,"Total Current Liabilities" ,"Total Liabilities & Equity" },
            {"Chase - United" ,"Accured Expenses" ,"Total Current Liabilities" ,"Total Liabilities & Equity" },
            {"Chase Card-Mariott" ,"Accured Expenses" ,"Total Current Liabilities" ,"Total Liabilities & Equity" },
            {"Citizens- 0026" ,"Accured Expenses" ,"Total Current Liabilities" ,"Total Liabilities & Equity" },
            {"Shareholder Loan" ,"Accured Expenses" ,"Total Current Liabilities" ,"Total Liabilities & Equity" },

            {"Net Income" ,"Company Retained Earnings" ,"Total Company Equity" ,"Total Liabilities & Equity" },
            {"Retained Earnings" ,"Company Retained Earnings" ,"Total Company Equity" ,"Total Liabilities & Equity" },
            {"Owner's Pay & Personal Expenses" ,"Company Retained Earnings" ,"Total Company Equity" ,"Total Liabilities & Equity" },
            {"Shareholder Distributions" ,"Company Retained Earnings" ,"Total Company Equity" ,"Total Liabilities & Equity" },
            {"Total Stocks" ,"Total Stocks" ,"Total Company Equity" ,"Total Liabilities & Equity" },
            {"Total Common Stocks" ,"Total Common Stocks" ,"Total Company Equity" ,"Total Liabilities & Equity" }

                }, 
                type table [Name = text, BS_lvl_2 = text, BS_lvl_3 = text, BS_lvl_4 = text]
            ), 

            addSort = List.Accumulate(Table.ColumnNames(src), src, 
                (s, c) => Table.AddColumn(s, 
                    c & "_Ind", 
                    (r) => List.PositionOf(Table.Column(src, c), Record.Field(r, c)), 
                    Int64.Type
                )
            )
            in
                addSort

//  развернуть списки + развернуть таблицы 
    let
        // Исходная таблица с четырьмя колонками, содержащими списки
        Source = 
            Table.FromRows(
                {
                    {{1, 2, 3}, {4, 5, 6}, {7, 8, 9}, {10, 11, 12}}
                }, 
                {"Column1", "Column2", "Column3", "Column4"}
            ),
        
        // Преобразуем каждую колонку, содержащую списки, в отдельные строки
        ExpandedTable = Table.FromColumns(
            List.Transform(Table.ToColumns(Source), each _{0}), // Извлекаем списки из ячеек
            List.Transform({1..Table.ColumnCount(Source)}, each "x" & Text.From(_)) // Генерация названий колонок: x1, x2, x3, x4
        )
    in
        ExpandedTable

    // ЕСЛИ ТАБЛИТЦЫ ТО 
        ExpandedTable = Table.FromColumns(
            List.Transform(Table.ToColumns(Source), each _{0} [Название колонки]),
            List.Transform({1..Table.ColumnCount(Source)}, each "x" & Text.From(_))
        )

//  возвращает только таблицы из списка
    = List.Select(
        Record.FieldValues(Tables), 
        each Value.Is(_, type table) // только так работает проверка таблицы
    )

//  todo ПРАВИЛЬНЫЙ СЛОВАРЬ
//  Поэтому вот так стоит писать на М!! От Михаила
        let
            base = Excel.CurrentWorkbook(){[Name="dimCost2"]}[Content], // словарь
            from = Excel.CurrentWorkbook(){[Name="Sales2"]}[Content],   // исходник

            dict =  Record.FromList(
                        base[Cost], 
                        List.Transform(base[Service ID],Text.From)
                    ),
            
            to   =  Table.AddColumn(from,"Cost", 
                        (x)=> Record.FieldOrDefault(dict, Text.From(x[Service ID]), 0)
                    )
        in
            to


SelectRow_  = //todo версия с аргументами новыми от 30.01.2025 #3.1 фильтруем строки в подтаблицах по "Статья_ID" в rep.BAL3 и др на шаге Load (для отчетов которые имеют номер строки)
            LoadFolder_ = // #1 подключаемся к ПАПКЕ, получаем список файлов XLSX с подпапками, чистим (ФОРМИРУЕМ ИСТОЧНИК)
                    /* 
                        Описание:
                            1. подключаемся к папке с файлами по имени датасета или по полному пути
                            2. выбираем номер шага загрузки. По умолчанию выгружаем последний шаг
                            3. чистим папку от временных и скрытых файлов, оставляем файлы .xlsx, преобразуем бинарники
                            4. в книгах excel оставляем только листы (Sheet)
                        
                        Аргументы:
                            optional options as record
                                Например [ДатаCетИмя = "Homel", НомерШага = null]
                        
                        Пример:	
                            = R[func][LoadFolder_]
                                ([ДатаCет = "BKS", Расширение = "xlsx", НомерШага = 5, Путь = null])
                                
                            = F[LoadFolder_]
                                ([ДатаCетИмя = "Homel"])					// возвращается последний шаг
                                ([ДатаCетИмя = "Homel", НомерШага = null])	// возвращается последний шаг
                                ([ДатаCетИмя = "Homel", НомерШага = 3])		// возвращается третий шаг
                                ([ДатаCетИмя = "Homel", НомерШага = 123])	// возвращается надпись об ошибке
                        
                        Улучшения:
                            1 //! Folder.Contents – собираем данные из папки, но выборочно
                            1. Если датасет не выбран, то меняем например на Homel 
                            2. Сделать макеты таблиц всех отчетов для замены, если ничего нет или не выбрано.
                            3. Макеты таблиц с данными по Условной организации. Ее надо создать
                            4. Это могут быть данные из одного файла XlSX с данными всех отчетов
                            5. Данные разных организаций можно совместить, чтобы заполнить базу и визуализации
                        */
                    [
                        func   = (optional options as record) => [ 	
                            // 	АРГУМЕНТЫ Шаг 1. Значения по умолчанию
                                GetValue        = // функция определения типа опциональных параметров
                                    (options as record, fieldName as text, typeConverter as function) =>
                                        let value = Record.FieldOrDefault(options, fieldName, null)
                                        in  if List.Contains({null,0,""},value) then null else typeConverter(value),

                                defaultOptions	= // значения по умолчанию - пустая запись ([?]) или заполненная?
                                    [   DATASET     = "", // что с жтим делать?
                                        STEP        = null, 
                                        EXTENSION   = "xlsx",
                                        SUBFOLDERS 	= true, 
                                        PATH        = "D:\" 
                                    ],
                                
                                finalOptions    = // объединяем опции
                                    if options = null
                                    then defaultOptions 
                                    else Record.Combine({defaultOptions, options}),
                                                        
                            //  АРГУМЕНТЫ Шаг 2. Формируем список аргументов (+ в описании функции)
                                DATASET   = GetValue(finalOptions, "Датаcет",    Text.From),   // "BKS"
                                EXTENSION = GetValue(finalOptions, "Расширение", Text.From),   // "xlsx"/ Списком?
                                STEP      = GetValue(finalOptions, "НомерШага",  Number.From), // 1
                                SUBFOLDERS	= GetValue(finalOptions, "SubFolders",	Logical.From),	// обработка подпапок
                                PATH      = GetValue(finalOptions, "Путь",       Text.From),   // "1"
                            //  ПЕРЕМЕННЫЕ Шаг 3. Формируем динамические переменные этой функции
                                parameters	= 
                                    [   path =  // path к ПАПКЕ (не файлу!) с файлами XLSX //? датасет имя 
                                            if  PATH <> null 
                                            then    PATH
                                            else    
                                                "G:\=EXCEL BI - мои проекты\2025.01 - Бытковская\Исходник\Форма 11,3 (БКС, 9 месяцев)\"
                                                // Text.BeforeDelimiter(R[func][GetParameter]("Форма 3"),"\", {0, 1}) 
                                    ],
                            
                            // 	1. подключаемся к папке + фильтруем колонки + немного меняем формат колонок
                                from  = Folder.Files( parameters[path] ),
                                nms	  = {"Name","Extension", "Attributes", "Date created", "Content"} & {"Folder Path"},
                                sel	  = Table.SelectColumns(from, nms),
                                trans = Table.TransformColumns(sel, {
                                            {"Date created", (x)=> DateTime.Date(x), type date},
                                            {"Folder Path",  (x)=> Text.AfterDelimiter(x, "\", {2, RelativePosition.FromEnd}), type text}
                                        }),

                            // 	2. фильтруем файлы в папке //! могут быть ошибки в строках - убрать слишком длинная >260
                                FilteredRows 	= Table.SelectRows(trans, each 
                                    Text.AfterDelimiter([Extension], ".", {0, 1}) = EXTENSION  	// оставляем только .xlsx
                                    and [Attributes][Hidden] = false 		// убираем скрытые
                                    and not Text.StartsWith([Name], "~$")   // убираем временные
                                ),
                            //  3. преобразуем бинарники в таблицы + в подтаблицах оставляем только листы
                                TransformBinary = Table.TransformColumns(FilteredRows,         
                                    {"Content", each let 
                                        TransBinary  = Excel.Workbook(_),
                                        NoPrintAreas = Table.SelectRows(TransBinary, each not Text.Contains([Name], "$")),
                                        OnlySheets   = Table.SelectRows(NoPrintAreas, each [Kind]="Sheet")
                                        in OnlySheets
                                    } 
                                ),
                                
                            //  4. добавляем колонки и фильтруем таблицу //* R[func][fxSizeFile] надо убрать
                                AddTwoColumns = let                      //* и заменить на Record.ToList(_){3} в Table.AddColumn из свойств
                                    tbl       = TransformBinary,
                                    AddSize   = Table.AddColumn(tbl, "Size", (x)=> R[func][fxSizeFile](x[Attributes][Size]), type text),
                                    AddShName = Table.AddColumn(AddSize, "SheetsName", (x)=> Text.Combine(x[Content][Name],","), type text),
                                    nms	 	  = {"Name", "Content"} & {"Folder Path"} & {"Size", "SheetsName"},
                                    SelCol	  = Table.SelectColumns(AddShName, nms)
                                in  SelCol,

                            //  5. фильтруем колонки
                                SelColumns = 
                                    Table.SelectColumns(AddTwoColumns, 
                                        {"Name", "Content"} & {"Folder Path"} & {"Size"}
                                    ),

                            // 	возвращаем разные этапы подключения к папке
                                Return = Record.FieldOrDefault(
                                    [	1 = trans, 			 // ...
                                        2 = FilteredRows, 	 // ...
                                        3 = TransformBinary, // ...
                                        4 = AddTwoColumns,   // ...
                                        5 = SelColumns		 // ...
                                    ], 	
                                        if   STEP = null 
                                        then Text.From(5) 		// последний шаг
                                        else Text.From(STEP)	// заданный шаг
                                    , 	
                                        "Error. Нет такого номера шага в функции LoadFolder")
                            ][Return],
                            
                        fnType = [ 
                                optionsType	= 
                                    type [	
                                        ДатаCет	    = (type nullable text meta   [Documentation.FieldCaption = "ДатаCетИмя",Documentation.SampleValues = {"Homel"}]),
                                        Расширение	= (type nullable text meta   [Documentation.FieldCaption = "Расширение",Documentation.SampleValues = {"xlsx"}]),
                                        НомерШага 	= (type number meta [Documentation.FieldCaption = "НомерШага (от 1 до 5)",Documentation.SampleValues = {"1"}]),
                                        Путь	    = (type nullable text meta   [Documentation.FieldCaption = "Путь",Documentation.SampleValues = {"D:\"}])
                                    ],

                                optionsMeta	= 
                                    [ 	Documentation.Name = "LoadFolder",
                                        Documentation.LongDescription = "
                                            подключаемся к папке, получаем список файлов XLSX с подпапками, чистим список. Шагов - 5. Аргументов - 4
                                            ",
                                        Documentation.Examples = {
                                            [Description = "", Code = "=F_Form[LoadFolder](""Homel"")",		Result="список файлов xls"], 
                                            [Description = "", Code = "=F_Form[LoadFolder](""Homel"", 3)",	Result="список файлов xls на шаге 3"], 
                                            [Description = "", Code = "=F_Form[LoadFolder](""Homel"", 123)",Result="сообщение об ошибке"]
                                        }
                                    ],

                                return 	    = type function (optional options as optionsType) as table meta optionsMeta
                            ][return],

                        result = Value.ReplaceType(func,fnType)
                    ]  [result],

                Connect_    = // #2 подключаемся к файлам, чистим внутрянку, добавляем 4 техколонки

                    [	
                        func   = (optional options as record) => [ 	
                            //	0  cписок аргументов функции //? сделать обязательные аргументы + по умолчанию, если они не введены
                                DATASET_NAME = let value = Record.FieldOrDefault(options, "ДатаCетИмя", null) 		in if value = null then null else Text.From(value),
                                REPORT_NAME  = let value = Record.FieldOrDefault(options, "ОтчетИмя", null) 		in if List.Contains({null, 0, ""}, value) then null else Text.From(value),
                                FOLDER_MASK  = let value = Record.FieldOrDefault(options, "МаскаИмениПапки", null) 	in if List.Contains({null, 0, ""}, value) then null else Text.From(value),
                                SHEET_FILTER = let value = Record.FieldOrDefault(options, "boolfilterSheet", null) 	in if value = null then null else Logical.From(value),
                                STEP         = let value = Record.FieldOrDefault(options, "НомерШага", null) 		in if List.Contains({null, 0, ""}, value) then null else Number.From(value),

                            //	#1 loadFile     подключаемся к папке с файлами //* через LoadFolder_
                                loadFile = R[func][LoadFolder_]([ДатаCетИмя = DATASET_NAME]),
                            
                            //	#2 transform    обрабатываем файлы и готовим их к анализу //* DATASET_NAME 
                                // transform = Record.FieldOrDefault([ Homel = Homel ], DATASET_NAME, null),
                                transform   = 	
                                    Record.FieldOrDefault(
                                        [
                                            BKS   = BKS
                                        ],  
                                        DATASET_NAME, null),

                            //	#3 filter       фильтруем файлы по form_ID //* REPORT_NAME = колонка [form_ID]
                                filter = [
                                    nms = {"Company","DataSet","form_ID","Date"} & {"Content"},
                                    col = Table.SelectColumns(transform, nms),
                                    row = Table.SelectRows(col, each [form_ID] = REPORT_NAME),
                                    to  = try row otherwise "отчета """ & REPORT_NAME & """ в папке c маской """ & FOLDER_MASK & """ нет"
                                ][to],
                                
                            //	#r mode         выгружаем с учетом параметров функции. Идет последним шагом! 
                                mode = 
                                    if REPORT_NAME = null 		// СЕТ +, ОТЧЕТ -, ШАГ -
                                    then transform				// то #2 -> выводим ВСЕ файлы после трансформации + можно шаг Connect
                                    else if  STEP = null 		// СЕТ +, ОТЧЕТ +, ШАГ -
                                        then filter				// то #3 -> выводим отфильтрованные файлы
                                        else transform,			// то #2 -> выводим ВСЕ файлы после трансформации + можно шаг Connect
                            
                            //	1  nms          список названий выходных столбцов этой функции 
                                nms  = 	{"Company", "DataSet", "form_ID"} & 
                                        {"Date"} & 
                                        {"Content"} & 
                                        {"Folder Path"},

                            //  2  BKS          список датасетов (с индивидуально) //? тут шаги - 5, для каждого датасета могут быть разные
                                BKS   = [ 
                                    // 	1 подключаемся к папке
                                        // loadFile = F_Form[LoadFolder]("Drog"),

                                    // 	2 фильтруем файлы в папке по маске имени папки: "" - оставляем все файлы по всех подпапках
                                        selectFiles = [
                                            name = Text.Lower(FOLDER_MASK),
                                            lst  = if name = null then {""} else {name},
                                            f 	 = each List.ContainsAny( {Text.Lower([Folder Path])}, lst, Text.Contains),
                                            sel  = Table.SelectRows(loadFile, f) // таблицу шага #1 фильтруем по Папке
                                        ] [sel],

                                    // 	3 фильтруем листы в подтаблицах (перенести шаг позднее)
                                        // todo по умолчанию оставляем листы с цифрами в названии
                                        selectSheet = [
                                            fxSheetDigit = each try Value.Is(Number.From([Name]), type number) otherwise null,
                                            fxSheetTotal = each [Name] = "СВОД В РАЗРЕЗЕ",
                                            
                                            to = Table.TransformColumns(selectFiles, {"Content", (x)=> 
                                                    Table.SelectRows(x, 
                                                        if   SHEET_FILTER = null // если опциональный параметр не указан
                                                        then fxSheetDigit // оставляем листы с номерами в названии, это коды организаций
                                                        else fxSheetTotal // сводный лист
                                                    )	
                                                })
                                        ] [to],

                                    // 	4 добавляем колонки с допинформацией
                                        addColumns =
                                            let
                                            // 	вытягиваем дату из ячейки А1 первого листа с номером в названии первого файла отчета
                                                // 	fxDate    	=(x)=> Date.From(x[Content][Data]{0}[Column1]{0}),  // дата из отчета
                                                    fxDate    =(x)=> 
                                                        // конец года, чтобы везде одинаково было
                                                        try Date.EndOfYear(Date.From(x[Content][Data]{0}[Column1]{0}))
                                                        otherwise null, // ошибка если даты нет в отчете
                                                                                    
                                                    fxCompany =(x)=> "BKS",
                                                    fxDataSet =(x)=> 3,
                                            
                                                //	fxReport	формируем reportName для новой колонки по первым символам названия файла //! важный шаг
                                                    fxReport  =(x)=> Record.FieldOrDefault([
                                                        02 	= "f_02",
                                                        03 	= "v_03",
                                                        11 	= "v_11"
                                                    ],  Text.Start(x[Name],2), null),

                                                //  переключение режима откуда брать сделать в самой функции!!! а не через var дальше
                                                    to  =
                                                       R[func][fxAddMultiColumns](selectSheet, {
                                                            { "Date",    	fxDate, 	type date},
                                                            { "DataSet", 	fxDataSet , Int64.Type},
                                                            { "Company", 	fxCompany, 	type text},
                                                            { "form_ID",  	fxReport, 	type text}
                                                        })
                                            in to,

                                    // 	5 перегруппируем листы и фильтруем колонки
                                        reorder 	= Table.ReorderColumns(addColumns, nms),
                                        selectRows	= Table.SelectRows(reorder, each [form_ID] <> null),
                                        selectCol 	= Table.SelectColumns(selectRows, nms),
                                        remove  	= Table.RemoveColumns(selectCol, {"Folder Path"}), 
                                        sort	    = Table.Sort(remove, {
                                                        {"Date", 	Order.Ascending}, 
                                                        {"form_ID",	Order.Ascending}
                                                    }),
                                    
                                    //	  возвращаем данные конкретного шага - max 5	
                                        return = Record.FieldOrDefault([
                                                1 = loadFile, 
                                                2 = selectFiles, 
                                                3 = selectSheet,
                                                4 = addColumns,
                                                5 = sort
                                            ], 
                                                if   STEP = null
                                                then Text.From(5) 
                                                else Text.From(STEP)
                                            ,
                                                "нет такого шага")
                                    ] [return]			
                            ] [mode],

                        fnType = [ 
                                optionsType	= 
                                    type [	
                                        ДатаCетИмя 		= (type nullable text meta [
                                            Documentation.FieldCaption 	= "ДатаCетИмя (Имя датасета)", 
                                            Documentation.SampleValues 	= {"""Homel+"""},
                                            Documentation.Description 	= "Имя набора данных для обработки"
                                            ]),
                                        ОтчетИмя 		= (type nullable text meta [
                                            Documentation.FieldCaption = "ОтчетИмя (ID отчета)", 	 
                                            Documentation.SampleValues = {"""bal"""},
                                            Documentation.Description = "Идентификатор отчета"
                                            ]),
                                        МаскаИмениПапки = (type nullable text meta [
                                            Documentation.FieldCaption = "МаскаИмениПапки (Маска имени папки)", 
                                            Documentation.SampleValues = {"""стат"""},
                                            Documentation.Description = "Маска для имени папки"
                                            ]),
                                        boolfilterSheet = (type nullable logical meta [
                                            Documentation.FieldCaption = "boolfilterSheet (Фильтр листов)", 
                                            Documentation.SampleValues = {true},
                                            Documentation.Description = "Применить ли фильтр к листам"
                                            ]),
                                        НомерШага 		= (type nullable number meta [
                                            Documentation.FieldCaption = "НомерШага (Номер шага запроса: Homel 1-5)", 
                                            Documentation.SampleValues = {"1"},
                                            Documentation.Description = "Номер шага выполнения запроса"
                                            ])
                                    ],

                                optionsMeta	= 
                                    [ 	
                                        Documentation.Name = "Connect",
                                        Documentation.LongDescription = 
                                            "	<b>Подключаемся к файлам, чистим внутрянку, добавляем 4 техколонки </b> <br>
                                                = F[Connect]( [ДатаCетИмя = ""Homel""] ) <br>
                                                = F[Connect]( [ДатаCетИмя = ""Homel"", ОтчетИмя = ""opu""] ) <br>
                                                = F[Connect]( [ДатаCетИмя = ""Homel"", ОтчетИмя = ""opu"", НомерШага = 1]) <br>
                                                = F[Connect]( [ДатаCетИмя = ""Homel"", ОтчетИмя = null,    НомерШага = null, МаскаИмениПапки = ""бух"", boolfilterSheet = null)]
                                            ",
                                        Documentation.Examples = 
                                            {
                                                [
                                                    Description = "", 
                                                    Code 		= "=F_Form[Connect](""Homel"")()",
                                                    Result		= "все обработанные файлы в папке"
                                                ], 
                                                [	Description = "", 
                                                    Code 		= "=F_Form[Connect](""Homel"",""bal"")()",
                                                    Result		= "все отчеты с ID = bal в папке"
                                                ], 
                                                [	Description = "", 
                                                    Code 		= "=F_Form[Connect](""Homel"",""null"",""стат"")",
                                                    Result		= "все обработанные файлы в папке + маска имени подпапки"
                                                ], 
                                                [	Description = "", 
                                                    Code 		= "=F_Form[Connect](""Homel"")(1)",
                                                    Result		= "все отчеты в папке после общей чистки, шаг 1 (макс 5)"
                                                ]
                                            }       
                                    ],

                                return 	    = type function (optional options as optionsType) as table meta optionsMeta // можно без "meta optionsMeta"
                            ]  [return],
                        
                        result = Value.ReplaceType(func, fnType)
                    ]  [result],
                        
     
            //	РАБОТА С XLSX и CSV 
                LoadFolder = // #1 подключаемся к папке, получаем список файлов XLSX с подпапками, чистим  (ФОРМИРУЕМ ИСТОЧНИК  )
                    /* 
                        Описание:
                            0. "Homel" - это значение параметра ДатаCетИмя (DataSetName в param)
                            1. подключаемся к папке с файлами по имени датасета или по полному пути
                            2. выбираем номер шага загрузки. По умолчанию выгружаем последний шаг
                            3. чистим папку от временных и скрытых файлов, оставляем файлы .xlsx или .csv, преобразуем бинарники
                            4. в книгах excel оставляем только листы (Sheet), в csv после скрипта потона один лист берется, первый видимый
                        
                        Пример:	
                            = R[func][LoadFolder] ([ДатаCетИмя = "Homel", ТипФайла = "csv", НомерШага = 7])
                            Варианты:
                                ([ДатаCетИмя = "Homel"])					// возвращается последний шаг ошибка еще из за ТипФайла
                                ([ДатаCетИмя = "Homel", НомерШага = null])	// возвращается последний шаг
                                ([ДатаCетИмя = "Homel", НомерШага = 3])		// возвращается третий шаг
                                ([ДатаCетИмя = "Homel", НомерШага = 123])	// возвращается надпись об ошибке
                        
                        Улучшения:
                            1. Если датасет не выбран, то меняем например на Homel 
                            2. Сделать макеты таблиц всех отчетов для замены, если ничего нет или не выбрано.
                            3. Макеты таблиц с данными по Условной организации. Ее надо создать
                            4. Это могут быть данные из одного файла XlSX с данными всех отчетов
                            5. Данные разных организаций можно совместить, чтобы заполнить базу и визуализации
                        */
                    [
                        func   = (optional options as record) => [ 	
                            //	0. формируем список аргументов //? ДатаCетИмя - имя датасета из параметров!
                                GetValue  = // функция определения типа опциональных параметров
                                    (options as record, fieldName as text, typeConverter as function) =>
                                        let value  = Record.FieldOrDefault(options, fieldName, null),
                                            result = if List.Contains({null, 0, ""}, value) then null else typeConverter(value)
                                        in  result,

                                DataSetName = GetValue(options, "ДатаCетИмя", Text.From),
                                FileType    = GetValue(options, "ТипФайла", Text.From),
                                STEP     	= GetValue(options, "НомерШага", Number.From),

                            //	1. path				формируем path к папке с файлами XLSX или CSV (из учебные планы взять способ указания путей, с таблицей)
                                path = 
                                        if FileType = "csv"  then Value.Metadata(param) [BKS] [pathCSV]
                                    else if FileType = "xlsx" then Value.Metadata(param) [BKS] [pathXLSX]
                                    else Value.Metadata(param) [BKS] [pathXLSX],

                                pathFolder =  "G:\=EXCEL BI - мои проекты\2025.01 - Бытковская\Исходник\Форма 11,3 (БКС, 9 месяцев)",
                                    // Record.FieldOrDefault(
                                    // 		path, // [ Homel = path ], 
                                    // 		DataSetName, 
                                    // 		if  Text.Contains(DataSetName,"\")	  	  // если имя содержит "\" (как часть пути к папке) что то не то
                                    // 			then DataSetName					  // то это путь к папке (для датасетов не из параметров)
                                    // 			else "Error. Ошибка в имени датасета" // то ошибка 	
                                    // 	),
                            
                            // 	2. from				подключаемся к папке 
                                from  = Folder.Files(pathFolder),
                            
                            //  3. Trans			фильтруем колонки: меняем формат колонок 
                                nms	  = {"Name","Extension", "Attributes", "Date created", "Content"} & {"Folder Path"},
                                Sel	  = Table.SelectColumns(from, nms),
                                Trans = Table.TransformColumns(Sel, {
                                            {"Date created", (x)=> DateTime.Date(x), type date},
                                            {"Folder Path",  (x)=> Text.AfterDelimiter(x, "\", {2, RelativePosition.FromEnd}), type text}
                                        }),

                            // 	4. FilteredRows		фильтруем строки : оставляем файлы нужного формата, убираем скрытые и временные файлы
                                FilteredRows 	= Table.SelectRows(Trans, each 
                                        Text.AfterDelimiter([Extension], ".") = FileType // оставляем только .xlsx
                                        and [Attributes][Hidden] = false 				 // убираем скрытые
                                        and not Text.StartsWith([Name], "~$")			 // убираем временные
                                ),

                            //  5. TransformBinary	преобразуем бинарники в таблицы, фильтруем строки в подтаблицах, оставляем один лист
                                TransformBinary = [
                                    //  fXLS    подлючаемся к папке (оставляем XLS, фильтруем, оставляем только листы, оставляем лист в котором отчет)
                                        fXLS = 	[ files  = 	
                                                    Table.TransformColumns(FilteredRows, {"Content", (x)=> 
                                                                let Binary 	= 	Excel.Workbook(x),
                                                                    Select	= 	Table.SelectRows(Binary,  each 
                                                                                    not Text.Contains([Name], "$")	// нет диапазоны
                                                                                    and [Kind]="Sheet"				// только листы
                                                                                    and Text.Length([Name]) = 15	// в имени 15 знаков = код организации
                                                                                )
                                                                in	Select 	// [Data]{0} оставляем первый лист
                                                            })
                                                ][files],
                                    
                                    //  fCSV    загрузка файлов из папки с CSV файлами (параметр Columns=... пропускаю? сеператор ",")
                                        fCSV =  [ files	= 	Table.TransformColumns(FilteredRows, 
                                                                {"Content", each Csv.Document(_, [Delimiter=";", Encoding=65001, QuoteStyle=QuoteStyle.Csv]), type table}
                                                            )
                                                ][files],

                                    //  return  возвращаем результат обработки
                                        return = Record.FieldOrDefault([
                                                    xlsx = fXLS, 
                                                    csv  = fCSV
                                                ], Text.From(FileType), "Error")
                                ][return],
                                
                            // 	6. AddTwoColumns	добавляем колонки и фильтруем таблицу
                                AddTwoColumns = let 
                                    AddSize   = Table.AddColumn(TransformBinary, "Size", (x)=> R[func][fxSizeFile] (x[Attributes][Size]), type text),
                                    AddShName = Table.AddColumn(AddSize, "SheetsName",   (x)=> try Text.Combine(x[Content][Name],",") otherwise null, type text),
                                    SelCol	  = Table.SelectColumns(AddShName, {"Name", "Content"} & {"Size"} & {"Folder Path","SheetsName"})
                                in  SelCol,

                            // 	7. ExpandColumn		разворачиваем листы в подтаблицах (xlsx) или оставляем как есть (csv)
                                ExpandColumn  =	
                                        if FileType = "xlsx" then Table.ExpandTableColumn(AddTwoColumns, "Content", {"Data"}) // переименовалсась колонка в Data
                                    else if FileType = "csv"  then Table.RenameColumns(AddTwoColumns, {"Content", "Data"})
                                    else "нет такого типа файла",
                                SelColumns 	  = Table.SelectColumns(ExpandColumn, {"Folder Path", "Name", "Data"}),

                            // 	возвращаем результаты шагов подключения к папке
                                Return = Record.FieldOrDefault(
                                    [	1 = pathFolder, 	
                                        2 = from, 			
                                        3 = Trans, 			
                                        4 = FilteredRows, 	
                                        5 = TransformBinary,
                                        6 = AddTwoColumns,	
                                        7 = SelColumns
                                    ], 	
                                        if   STEP = null 
                                        then Text.From(7) 		// последний шаг
                                        else Text.From(STEP)	// заданный шаг
                                    , 	
                                        "Error. Нет такого номера шага в функции LoadFolder")
                            ][Return],
                            
                        fnType = [ 
                                optionsType	= 
                                    type [	
                                        ДатаCет		= (type nullable text meta [Documentation.FieldCaption = "ДатаCетИмя",Documentation.SampleValues = {"Homel"}]),
                                        ТипФайла	= (type nullable text meta [Documentation.FieldCaption = "ТипФайла",Documentation.SampleValues = {"csv"}]),
                                        НомерШага	= (type nullable number meta [Documentation.FieldCaption = "НомерШага (от 1 до 9)",Documentation.SampleValues = {"1"}])
                                    ],

                                optionsMeta	= 
                                    [ 	Documentation.Name = "LoadFolder",
                                        Documentation.LongDescription = "подключаемся к папке, получаем список файлов XLSX с подпапками, чистим список",
                                        Documentation.Examples = {
                                            [Description = "", Code = "=F_Form[LoadFolder](""Homel"")",Result="список файлов xls"], 
                                            [Description = "", Code = "=F_Form[LoadFolder](""Homel"", 3)",Result="список файлов xls на шаге 3"], 
                                            [Description = "", Code = "=F_Form[LoadFolder](""Homel"", 123)",Result="сообщение об ошибке"]
                                        }
                                    ],

                                return 	    = type function (optional options as optionsType) as table meta optionsMeta
                            ][return],

                        result = Value.ReplaceType(func,fnType)
                    ]  [result],

                Connect    = // #2 подключаемся к файлам, чистим внутрянку, добавляем 4 техколонки
                    // = Connect( [ДатаCетИмя = "Homel", ОтчетИмя = null, МаскаИмениПапки = "стат", НомерШага = null, boolfilterSheet = null])
                    // = Connect( [ДатаCетИмя = "Homel", ОтчетИмя = "opu", НомерШага = null])
                    [	
                        func   = (optional options as record) => [ 	
                                //	0  формируем cписок аргументов 
                                    DATASET_NAME = let value = Record.FieldOrDefault(options, "ДатаCетИмя", null) 		in if value = null then null else Text.From(value),
                                    REPORT_NAME  = let value = Record.FieldOrDefault(options, "ОтчетИмя", null) 		in if List.Contains({null, 0, ""}, value) then null else Text.From(value),
                                    FOLDER_MASK  = let value = Record.FieldOrDefault(options, "МаскаИмениПапки", null) 	in if List.Contains({null, 0, ""}, value) then null else Text.From(value),
                                    SHEET_FILTER = let value = Record.FieldOrDefault(options, "boolfilterSheet", null) 	in if value = null then null else Logical.From(value),
                                    STEP         = let value = Record.FieldOrDefault(options, "НомерШага", null) 		in if value = null then null else Number.From(value),

                                //	#1 подключаемся к папке с файлами 
                                    loadFile = LoadFolder([ДатаCетИмя = DATASET_NAME]),
                                
                                //	#2 обрабатываем файлы и готовим их к анализу 
                                    transform = Record.FieldOrDefault([ Homel = Homel ], DATASET_NAME, null),

                                //	#3 фильтруем файлы
                                    filter = [
                                        nms = {"Company","DataSet","form_ID","Date"} & {"Content"},
                                        col = Table.SelectColumns(transform, nms),
                                        row = Table.SelectRows(col, each [form_ID] = REPORT_NAME),
                                        to  = try row otherwise "отчета """ & REPORT_NAME & """ в папке c маской """ & FOLDER_MASK & """ нет"
                                    ][to],
                                    
                                //	#r выгружаем с учетом параметров функции. Идет последним шагом! 
                                    mode = 
                                        if REPORT_NAME = null 		// СЕТ +, ОТЧЕТ -, ШАГ -
                                        then transform				// то #2 -> выводим ВСЕ файлы после трансформации + можно шаг Connect
                                        else if  STEP = null 		// СЕТ +, ОТЧЕТ +, ШАГ -
                                            then filter				// то #3 -> выводим отфильтрованные файлы
                                            else transform,			// то #2 -> выводим ВСЕ файлы после трансформации + можно шаг Connect
                                
                                //	1  список названий выходных столбцов этой функции 
                                    nms  = 	{"Company", "DataSet", "form_ID"} & {"Date"} & {"Content"} & {"Folder Path"},

                                //  2  список датасетов (с каждым работать индивидуально)
                                    Homel = [ 
                                        // 	1 получаем список файлов в папке с учетом всех вложенностей
                                            // loadFile = F_Form[LoadFolder]("Homel", null),
                                        
                                        // 	2 фильтруем файлы в подтаблицах
                                            selectFiles = [
                                                lst = if   Text.Lower(FOLDER_MASK) = null
                                                    then {""}
                                                    else {FOLDER_MASK},
                                                f = each List.ContainsAny( { Text.Lower([Folder Path]) }, lst, Text.Contains),
                                                sel = Table.SelectRows(loadFile, f)
                                            ] [sel],

                                        // 	3 фильтруем листы в подтаблицах
                                            // а если несколько листов попадает в такую выборку?!
                                            selectSheet =
                                                Table.TransformColumns(selectFiles,{"Content", (x)=>
                                                    let sheet = Table.SelectRows(x, each Text.Length([Name]) = 15) 	// оставляем листы с длиной названия = 15 знаков - код организации
                                                    in	sheet{0}[Data] 												// данные первого листа, //! Но... может быть несколько листов!
                                                }),

                                        // 	4 добавляем колонки с допинформацией о файле/отчете. Источник - данные из файла
                                            // 	в .xls дата = 01.16, в .xlsx = 01.12.2016 => возникает ошибка => обрабатываем ее через try/otherwise
                                            addColumns =
                                                let
                                                    fxDate =(x)=> // ячейка [A1] - дата отчета
                                                        try 	  Date.From("01.01.20" & Text.End(x[Content][Column1]{0},2))  // если xls  => 2 end знака зачения в ячейке с датой (в .xls дата = 01.16)
                                                        otherwise Date.From(x[Content][Column1]{0} + #duration(30, 0, 0, 0)), // если xlsx => + 30 дней (в .xlsx = 01.12.2016 => возникает ошибка => обрабатываем ее через try/otherwise)
                                                    fxCompany =(x)=> "Homel", 	//Text.From (x[Content][Column1]{2}), // ячейка [A1] - организация - ГОМЕЛЬСКОЕ РАЙПО / ГОМЕЛЬСКИЙ ФИЛИАЛ
                                                    fxDataSet =(x)=> 2, 		// ячейка [A1] - код предприятия - тут не надо - Text.From (x[Content][Column1]{1})
                                                    fxReport  =(x)=> Text.Start(x[Content][Column2]{0}, 4), // 4 первые знака = код отчета, например "0112"
                                                    
                                                    var = false, // true - берем данные с листа, false - руками заполняем
                                                    
                                                    // переключение режима откуда брать сделать в самой функции!!! а не через var дальше
                                                    to  =
                                                        fxAddMultiColumns(selectSheet,
                                                            {
                                                                { "Date",    	if var then fxDate 	  else fxDate, 			type date},
                                                                { "DataSet", 	if var then fxDataSet else each 2, 			Int64.Type},
                                                                { "Company", 	fxCompany, 	type text},
                                                                { "form_ID",  	if var then fxReport  else fxReport, 		type text}
                                                            }
                                                        )
                                                in to,

                                        // 	5 меняем код отчета по нормам БКС на код отчета из моего справочника форм отчетности
                                            //	выбираем из справочника нужное название ЕСЛИ ФАЙЛОВ МНОГО (или берем с листа, если отчет один или руками ставим)
                                            transform = [
                                                f=(txt)=> // значения колонки 1 словаря, заменяю на колонку 0
                                                    let dict = Table.ToRows(spr[spr.ALL][Спр_ФормыОтчетности]), // список списков
                                                        to   = List.First(List.Select(dict, (col)=>col{1}=txt)){0}
                                                    in 	to,
                                                to = Table.TransformColumns(addColumns, {"form_ID", f, type text})
                                            ][to],

                                        // 	6 перегруппируем листы и фильтруем колонки
                                            reorder	= Table.ReorderColumns(transform, nms),
                                            select  = Table.SelectColumns(reorder, nms),
                                            remove  = Table.RemoveColumns(select, {"Folder Path"}), 
                                            sort	= Table.Sort(remove, {{"form_ID", Order.Ascending}, {"Date", Order.Ascending}} ),

                                        //	  возвращаем данные конкретного шага	
                                            Return = Record.FieldOrDefault([
                                                    1 = loadFile, 
                                                    2 = selectFiles, 
                                                    3 = selectSheet,
                                                    4 = addColumns,
                                                    5 = sort
                                                ], 
                                                    if   STEP = null
                                                    then Text.From(5) 
                                                    else Text.From(STEP)
                                                ,
                                                    "нет такого шага")
                                        ] [Return]					
                            ] [mode],

                        // вариант 1 с отдельным шагом type
                        optionsType1 = 
                            type [
                                ДатаCетИмя 		= (type nullable text meta [
                                    Documentation.FieldCaption = "Имя датасета", 
                                    Documentation.SampleValues = {"""Homel"""},
                                    Documentation.Description = "Имя набора данных для обработки"
                                    ]),
                                ОтчетИмя 		= (type nullable text meta [
                                    Documentation.FieldCaption = "ID отчета", 
                                    Documentation.SampleValues = {"""bal"""},
                                    Documentation.Description = "Идентификатор отчета"
                                    ]),
                                МаскаИмениПапки = (type nullable text meta [
                                    Documentation.FieldCaption = "Маска имени папки", 
                                    Documentation.SampleValues = {"""стат"""},
                                    Documentation.Description = "Маска для имени папки"
                                    ]),
                                boolfilterSheet = (type nullable logical meta [
                                    Documentation.FieldCaption = "Фильтр листов", 
                                    Documentation.SampleValues = {true},
                                    Documentation.Description = "Применить ли фильтр к листам"
                                    ])
                            ],
                        result1 = Value.ReplaceType(func, type function (optional options as optionsType1) as table),
                        // вариант 2 рабочий
                        fnType2 = 	type function (
                                        optional options as (
                                            type 
                                            [
                                                ДатаCетИмя 		= (type nullable text meta [Documentation.FieldCaption = "ДатаCетИмя (Имя датасета)", Documentation.SampleValues = {"""Homel+"""}]),
                                                ОтчетИмя 		= (type nullable text meta [Documentation.FieldCaption = "ОтчетИмя (ID отчета)", 	 Documentation.SampleValues = {"""bal"""}]),
                                                МаскаИмениПапки = (type nullable text meta [Documentation.FieldCaption = "МаскаИмениПапки (Маска имени папки)", Documentation.SampleValues = {"""стат"""}]),
                                                boolfilterSheet = (type nullable logical meta [Documentation.FieldCaption = "boolfilterSheet (Фильтр листов)", Documentation.SampleValues = {true}]),
                                                НомерШага 		= (type nullable logical meta [Documentation.FieldCaption = "НомерШага (Номер шага запроса: Homel 1-5)", Documentation.SampleValues = {"1"}])
                                            ]
                                        )
                                    ) as table 
                                        meta [ 	Documentation.Name = "Connect",
                                            Documentation.LongDescription = 
                                            " <b>Подключаемся к файлам, чистим внутрянку, добавляем 4 техколонки </b> <br>
                                                = F[Connect]( [ДатаCетИмя = ""Homel""] ) <br>
                                                = F[Connect]( [ДатаCетИмя = ""Homel"", ОтчетИмя = ""opu""] ) <br>
                                                = F[Connect]( [ДатаCетИмя = ""Homel"", ОтчетИмя = ""opu"", НомерШага = 1]) <br>
                                                = F_Form[Connect](""Homel"")()			- все файлы в папке	после общей чистки <br> 
                                                = F_Form[Connect](""Homel"")(1)			- все файлы в папке после общей чистки, шаг 1 из 5 <br>
                                                = F_Form[Connect](""Homel"",""bal"")()	- все отчеты данного вида в папке	<br>
                                                = F_Form[Connect](""Homel"", null)(1)	- то же, аналог F_Form[LoadFolder](""Homel"") <br>
                                                = F_Form[Connect](""Homel"",""bal"")(1)	- то же <br>
                                                = F_Form[Connect](""Homel"", null, ""стат"")() - все обработанные файлы в папке + маска имени подпапки <br>
                                            "
                                            // , Documentation.Examples = 
                                            // {
                                            // 	[Description = "", Code = "=F_Form[Connect](""Homel"")()",Result="все обработанные файлы в папке"], 
                                            // 	[Description = "", Code = "=F_Form[Connect](""Homel"",""bal"")()",Result="все отчеты с ID = bal в папке"], 
                                            // 	[Description = "", Code = "=F_Form[Connect](""Homel"",""null"",""стат"")",Result="все обработанные файлы в папке + маска имени подпапки"], 
                                            // 	[Description = "", Code = "=F_Form[Connect](""Homel"")(1)",Result="все отчеты в папке после общей чистки, шаг 1 (макс 5)"]
                                            // }       
                                            ],
                        result2 = 	Value.ReplaceType(func, fnType2)
                    ][result2],

			//	старые ------------------------------------------------------------------------------
			    SelectRow  = // #3 фильтруем строки в подтаблицах по "Статья_ID" на шаге Load (для отчетов которые имеют номер строки) . Надо документировать функцию 
				/* 
					Описание:
						Функция добавляет колонку с отфильтрованными подтаблицами
					Пример:
						= 	F_Form[form.SelectRowsID](
								STEP1_Connect,
								{"Column1","Column2","Column3","Column4"},
								{"Статья", "Строка_ID", "На начало", "На конец"},
								"Строка_ID",
								10,
								1000
							)
					Улучшение:
						сделать проверку соответствия длин списков nmsOld и nmsNew
				*/
				[
					func   = (options as record) as table => [ 	
						// 1 формируем список аргументов 
							tbl  	 = let value = Record.FieldOrDefault(options, "tbl", null)     in if value is table then value else null,
							nmsOld	 = let value = Record.FieldOrDefault(options, "nmsOld", null)  in if value is list then value else {} ,
							nmsNew	 = let value = Record.FieldOrDefault(options, "nmsNew", null)  in if value is list then value else {} ,
							colName  = let value = Record.FieldOrDefault(options, "colName", null) in if List.Contains({null, 0, ""}, value) then null else Text.From(value),
							kodStart = let value = Record.FieldOrDefault(options, "kodStart", null)  in if List.Contains({null, 0, ""}, value) then null else Number.From(value),
							kodEnd	 = let value = Record.FieldOrDefault(options, "kodEnd", null)    in if List.Contains({null, 0, ""}, value) then null else Number.From(value),
					
						// 2 добавляем новую колонку в таблицу с подтаблицами, в которой будут отфильтрованые строки отчета
							from =	Table.AddColumn(tbl, "Step2", (x)=> [
								//	проверяю наличие колонки. В одних отчетах подтаблицы в "Content", в других, как в БКС "Data" после разворота листов с предприятиями
									//!  сделать вариант, если грузить надо с листа один отчет, там нет колонки дата и контент
									selCol  = 	if   Table.HasColumns(tbl, "Content")
												then Table.SelectColumns(x[Content], nmsOld)
												else Table.SelectColumns(x[Data], nmsOld),

									rename  = Table.RenameColumns(selCol, List.Zip({nmsOld, nmsNew} )),
									clear   = Table.ClearAll(rename," #(lf)#(00A0)", false, false),

								//	делаем колонку числовой, если там не число и возникает ошибка то меняем на null
									tr      = Table.TransformColumns(clear, {colName, try Number.From otherwise null, type number}),

								// 	удаляем errors, который иногда появляется, когда там текст или еще чего
									err     = Table.RemoveRowsWithErrors(tr, {colName}),
									lst     = {null, kodStart, kodEnd},
									f=(x)=> x>=lst{1} and x<=lst{2},

								//	оставляем строки в диапазоне номеров в колонке "Статья_ID"
									selRow  = Table.SelectRows(err, (row)=> f(Record.Field(row, colName) ) )
								]  [selRow]),

						// 3 удаляем или ту или ту колонку, в зависимости от наличия их на входе
							to	= Table.RemoveColumns(from, {"Content","Data"}, MissingField.Ignore)
						][to],
					fnType = [ 
							optionsType	= 
								type [	
									tbl	     = (type table meta [Documentation.FieldCaption = "tbl (таблица), table",Documentation.SampleValues = {"Source"}]),
									nmsOld 	 = (type list meta [ // если type list, то можно дет выбрать из списка и поставить галочки
													Documentation.FieldCaption 		= "nmsOld (список старых имен колонок)",
													Documentation.FieldDescription 	= "Выберите допустимые поля ", // как можно увидеть этот текст?
													Documentation.SampleValues 		= {"{""Column1"",""Column2""}"},
													Documentation.AllowedValues 	= {10,110} // как сделать при этом произволльный ввод?
												]),
									nmsNew 	 = (type any meta [Documentation.FieldCaption = "nmsNew (список новых имен колонок)",Documentation.SampleValues = {"{""Column1"",""Column2""}"}]),
									colName	 = (type nullable text meta [Documentation.FieldCaption = "colName (имя колонки)",Documentation.SampleValues = {"""Column1"""}]),
									kodStart = (type nullable number meta [Documentation.FieldCaption = "kodStart (начальная строка)",Documentation.SampleValues = {10}]),
									kodEnd 	 = (type nullable number meta [Documentation.FieldCaption = "kodEnd (конечная строка)",Documentation.SampleValues = {1000}])
								],

							optionsMeta	= 
								[ 	Documentation.Name = "SelectRow",
									Documentation.LongDescription = "...",
									Documentation.Examples = {
										[Description = "", Code = "=...",Result="..."], 
										[Description = "", Code = "=...",Result="..."]
									}
								],

							return 	    = type function (options as optionsType) as table meta optionsMeta
						][return],

					result = Value.ReplaceType(func,fnType)
				]  
					[result],
	

                //  надо так: 	1 LoadFolder - подключаемся к папке и чистим только файлы и все, что с ними связано!!!
                // 				2 Connect	 - чистим содержимое файлов (но иногда их файлов надо вытягивать инфу для таблицы...)



//  Итоговая сумма по столбцам, TotalSum 🔥
    // самая простая + Можно через List.Select выбирать из списка разные строки
    fxTotal1 = each List.Sum(List.Skip(Record.ToList(_))),
    
    // вариант 2, такой же, также можно через List.Select выбирать отдельные столбцы по именам полей
    fxTotal2 = each List.Sum(Record.ToList(Record.SelectFields(_, List.RemoveFirstN(Table.ColumnNames(from), 1)))),

//  Отключение в свойсках Excel автоширина столбца
    Sub dis_autocolumn()
        Dim wsh As Worksheet
        Dim lobj As ListObject
        For Each wsh In ThisWorkbook.Worksheets
            For Each lobj In wsh.ListObjects
            If lobj.SourceType = xlSrcQuery Then lobj.QueryTable.AdjustColumnWidth = False
            Next lobj
        Next wsh
        MsgBox "Автоширина отключена."
    End Sub

//	Ранг 📌
	Provide the argument as record: [ RankKind = RankKind.Ordinal ]
		RankKind.Competition
		RankKind.Dense
		RankKind.Ordinal
	https://powerquery.how/table-addrankcolumn/

	Table.AddRankColumn(
		<table>,
		<new column name>,
		<comparison criteria>,
		[<options>}
	)
	
	= Table.AddRankColumn(from,"Rank",{"Sales"})

	Table.AddRankColumn( 
		Source,
		"Revenue Asc",
		{ "Revenue", Order.Ascending },   // Sort column in Ascending order
		[ RankKind = RankKind.Competition ]
	)
	
	Table.AddRankColumn( 
		Source,
		"Revenue Asc",
		{ { "Revenue", Order.Descending }, {"CustomerID", Order.Ascending } },
		[ RankKind = RankKind.Competition ]
	)

//  Локальная группировка GroupKind.Local. Продвинутый вариант от Михаила в "Power Query Ru"
    /*
        Помогите-подскажите, чем можете.
        Огромная таблица, в которой в столбце "Время" есть значения и есть nullы. Нужно данные из столбца "Категория" собрать в 2 столбца:
        1. если во "Время" не пусто, то пишем в "Категория";
        2. если во "Время" пусто, то всё, что до следующего непустого, собираем в столбец "Название".
        Проблема у меня в том, что количество непустых ячеек может быть различным: может быть 0, 1, 2, 3...
        Если ни одной пустой ячейки после "Время", то в "Название" ничего не идёт.
        Решаемо?
    */
    
    //  Вариант 4, итоговый
        let
            from = Excel.CurrentWorkbook(){[Name="Исходник"]}[Content],
            nms  = Table.ColumnNames(from),
            f=(x)=>(y)=>  Text.Combine(List.Skip(Table.Column(y,x))," "),
            g=(x)=>(y,z)=>Number.From(Record.Field(z,x)<>null),
            to = Table.Group( from, nms, {"Название", f("Категория")}, GroupKind.Local, g("Сумма") )
        in
            to

    // История работы мысли
        //  Вариант 3
            let from =  Excel.CurrentWorkbook(){[Name="Исходник"]}[Content],
                to   =  Table.Group(from,    
                            Table.ColumnNames(from),
                            {"Название",(x)=>Text.Combine(List.Skip(x[Категория])," ")},
                            GroupKind.Local,
                            (s,c)=>Number.From(c[Сумма]<>null)
                        )
            in  to
        
        //  Вариант 2
            let from =  Excel.CurrentWorkbook(){[Name="Исходник"]}[Content],
                nms  =  Table.ColumnNames(from),
                nm   =  "Категория",
                to   =  Table.Group(from,
                            List.RemoveItems(nms,{nm}),
                            {nm,(x)=>Text.Combine(List.Skip(Table.Column(x,nm))," ")},
                            GroupKind.Local,
                            (s,c)=>Number.From(c[Сумма]<>null)
                        )
            in  to
        //  Вариант 2
            to =    Table.Group(from, 
                        {"Дата", "Время"}, 
                        {
                            {"Категория",   each [Категория]{0}},
                            {"Название",    each Text.Combine(List.Skip([Категория])," ")},
                            {"Сумма",       each [Сумма]{0}}},
                            GroupKind.Local,
                            (x,y)=>Number.From(y[Время]<>null)
                        )


//  разделить слипшийся текст по большим буквам (например имена  колонок) MonthNameShort -> в Month Name Short
    Table.TransformColumnNames(CreateTable, each [
            SplitTextByTransition = Splitter.SplitTextByCharacterTransition({"a".."z"}, {"A".."Z"})(_), 
            CombineValues         = Text.Combine( SplitTextByTransition, " " ), 
            RemoveUnderscores     = Text.Replace( CombineValues, "_", " ") 
        ][RemoveUnderscores] 
    )

//  Нарастающий итог
    // на входе таблица Month+Sales
        =   Table.FromRecords(
                List.Accumulate(
                    Table.ToRecords(Source), 
                    [List = {}, RT = 0], 
                    (state, current) =>
                        [   
                            List = state[List] & {current & [Running Total = RT]}, 
                            RT = state[RT] + current[Sales]
                        ]
                )[List], 
                Value.Type(
                    Source & #table( type table [Running Total=number], {} )
                )
            )
//  разбор строки на числа и текст в отдельные колонки // функция возврат числа и букв
    let
        Источник = Excel.CurrentWorkbook(){[Name="Таблица1"]}[Content],
        fxDigits = each Text.Combine(
                            List.RemoveNulls(
                                List.Transform(
                                    Text.ToList([column]),
                                    each if Value.Is(Value.FromText(_), type number) then _ else null
                                )
                            )
                        ),
        fxText   = each Text.Combine(List.RemoveNulls(List.Transform(Text.ToList([column]),each if Value.Is(Value.FromText(_), type text) then _ else null)))
        AddedDigits = Table.AddColumn(Источник, "digits", fxDigits),
        AddedText   = Table.AddColumn(AddedDigits, "text", fxText)
    in
        AddedText

//  поключение к stackoverflow.com // Web scraping questions on Stack Overflow - Html.Table scraping
        let
            Url = "https://stackoverflow.com/questions/tagged/powerquery",
            Response = Web.Contents( Url ),
            /*
            The 3rd argument in "columnNameSelectorPairs" is the transformation function.
            by default it uses:

                    each _[TextContent]
            */
            HeaderAsElement = Html.Table(
                Response,
                {
                    { "Link", "a.question-hyperlink", each _ }

                }
            ),

            ElementRecord = Table.ExpandRecordColumn(HeaderAsElement, "Link", {"TextContent", "Attributes"}, {"TextContent", "Attributes"}),
            ExpandedAttributes = Table.ExpandRecordColumn(ElementRecord, "Attributes", {"class", "href"}, {"Class", "Url"})
        in
            ExpandedAttributes

//  пример кода с рекурсией и прочим, неплохо, изучить
        let
            TextFromRecurse = (object as any) as text =>
                let
                    scalar = if object is list
                        then "{ " & Text.Combine(
                                List.Transform(
                                    object,
                                    // each "Item,"
                                    each @TextFromRecurse(_)
                                ),
                                ", "
                            ) & "} "
                        else object,

                    output = Text.From(scalar)
                in
                    output,

            CombineVararg =
                Function.From(
                    type function() as list,
                    each TextFromRecurse(_)
                ),

            results = [
                basic = CombineVararg("a", "b", 3, TextEncoding.Utf16),
                nested = CombineVararg("a", "b", 3, {3..6}),
                nested2 = CombineVararg(
                    "a", "b",
                    DateTime.LocalNow(),
                    3, {3..6}
                )

            ]
        in
            results,
//  пример какого то кода // много интересного кода, записи, добавление и др.
		let
			// toggles hiding extra columns
			UseMinimal = false,         // simplify final table output
			UseFastTest = true,         // skip most tests to quickly test the connection?
										// slow might need a sleep delay/waitfor pattern to play nice
			/*  
                todo:
                    - add delay testing: <https://httpstat.us/200?sleep=2000>
                    - retry pattern: <https://docs.microsoft.com/en-us/power-query/waitretry>
                    - Uri split query string
                    - <https://docs.microsoft.com/en-us/power-query/helperfunctions#urifromparts>
                    - <https://docs.microsoft.com/en-us/power-query/helperfunctions#retrieving-data>
			*/
            
			// every code supported by <https://httpstat.us/>
			ErrorCodes_https_supported      = {100..103} & {200..206} & {300..308} & {400..429} & {431, 451} & {500..507} & {511, 520, 522, 524},
			ErrorCodes_default              = {400..405} & {429,500,503},
			ErrorCodes_ManualStatusHandling = ErrorCodes_default,               // {400,401,403,404,429,500,503},
			ErrorCodes_StatusList           = ErrorCodes_ManualStatusHandling,  // ErrorCodes_ManualStatusHandling
			RequestOptions =  [
				// Timeout = // as duration: default is 100ms
				// IsRetry = true, // true: means ignore cached response
				// ManualStatusHandling =
				ManualStatusHandling = ErrorCodes_ManualStatusHandling

			],
			
            static_UrlList = {
				// test TLS errors
				"https://wrong.host.badssl.com/",
				"https://expired.badssl.com/",
				// non-existing domain
				"http://www.somefakenamedoesnotexist.com",

				// a couple specific HTTP statuses
				"https://httpbin.org/",
				"https://httpstat.us/200",
				"https://httpstat.us/404",
				"https://httpstat.us/403",
				"https://httpstat.us/405"
			},

			dynamic_UrlList =
				List.Transform(
					ErrorCodes_https_supported,
					(_ as any) as text =>
						"https://httpstat.us/" & Text.From( _ )
				),


			urlList =
				if UseFastTest then static_UrlList
				else static_UrlList & dynamic_UrlList,

			responseList = List.Transform(
				urlList,
				(url as text) as any =>
					Web.Contents(
						url,
						RequestOptions
					)
			),


			// Get metadata for a Web.Contents call
			WebRequest_ToRecord = (response as binary) as record  =>
				let
					metaData = Value.Metadata( response ),
					maybeErr = try metaData[Content.Type],

					/*
					Careful:
						Binary.Length( Web.Contents( ...a 403 response ) )

					will throw
						"Expression.Error: Access to the resource if forbidden"

					Note:
						- No error occurs on Value.Metadata() but it will on value calls
						- Exception is high level
							even a 'try' or 'let' block cannot capture it.
							an error record isn't returned if you use a "try"

					403 returns status code null

					*/
					contentLength =
						if ( metaData[Response.Status] = 403 or metaData[Response.Status] = null) 
                        then null
						else Binary.Length( response ),

					r1 = Record.AddField(metaData, "Binary", response, null ),
					r2 = Record.AddField(r1, "Content.Length", contentLength, null ),
					r3 = Record.AddField(r2, "Response.Error", if maybeErr[HasError] then maybeErr[Error] else null, null),
					r4 = Record.AddField(r3, "Url", metaData[Content.Uri]() ),
					r5 = Record.RemoveFields( r4, {"Content.Uri"}, MissingField.UseNull)
				in
					r5,

			metaDataList = List.Transform(
				responseList,
				each WebRequest_ToRecord(_)
			),

			WebRequestList_ToTable = 
                (source as list, optional minimal as nullable logical) as table =>
                        let
                            WebRequest_Table.Type = type table[
                                Url = text,
                                Response.Status = number, // always?
                                Content.Type = text,
                                Content.Length = Int64.Type,
                                Response.Error = record,
                                // Content.Uri = Function.Type, it returns the url, nothing else? or re-invoke original?
                                Content.Name = text, // probably base url
                                Headers = record,
                                Request.Options = record,
                                Binary = binary
                        ],

                        t1 = Table.FromRecords( metaDataList, WebRequest_Table.Type, MissingField.Error),
                        Final = Table.ExpandRecordColumn( t1, "Response.Error", {"Reason", "Message", "Detail"}, {"Error.Reason", "Error.Message", "Error.Detail"}),
                        FinalMinimal = Table.SelectColumns( Final, {"Url", "Response.Status", "Error.Reason", "Error.Message", "Error.Detail"}),
                        result = if minimal then FinalMinimal else Final inresult,

                    FinalTable = WebRequestList_ToTable( responseList, UseMinimal )
                in
                    FinalTable
            ,

//  АРГУМЕНТЫ   Шаг 0. Список аргументов //? в базу функцию GetValue для аргументов
        (optional options as record) =>
            let
                //	АРГУМЕНТЫ   Шаг 0. Список аргументов //? в базу функцию GetValue для аргументов
				    GetValue  = // функция определения типа опциональных параметров
                        (options as record, fieldName as text, typeConverter as function) =>
                            let value  = Record.FieldOrDefault(options, fieldName, null),
                                result = if List.Contains({null, 0, ""}, value) then null else typeConverter(value)
                            in  result,

                    FILE_TYPE = GetValue(options, "ТипФайла", Text.From),
                    VID       = GetValue(options, "Вид", Text.From),
                    STEP      = GetValue(options, "НомерШага", Number.From),

//  ИНДУС, разворот обычой таблицы, 3 по 3 колонки
    // https://bajxwr.clicks.mlsend.com/tb/c/eyJ2Ijoie1wiYVwiOjQyMTQyNSxcImxcIjoxNDExNTAyOTM2MzgyNTE4ODksXCJyXCI6MTQxMTUwMzE5NDkxOTQyMzQ4fSIsInMiOiJmZTZjZDczNmJiOTgxOWUxIn0
    let
        Source = 
            #table( 
                {"Column1", "Column2", "Column3", "Column4", "Column5", "Column6", "Column7", "Column8", "Column9"}, 
                { {"India" ,null ,null ,"USA" ,null ,null ,"Aus" ,null ,null}, 
                {"Product" ,"Value" ,"Sh%" ,"Product" ,"Value" ,"Sh%" ,"Product" ,"Value" ,"Sh%"}, 
                {"A" ,"17" ,"0.6" ,"A" ,"19" ,"0.2" ,"A" ,"15" ,"0.48"}, 
                {"B" ,"10" ,"0.1" ,"B" ,"15" ,"0.53" ,"B" ,"15" ,"0.54"}, 
                {"C" ,"17" ,"0.36" ,"C" ,"20" ,"0.24" ,"C" ,"19" ,"0.07"}, 
                {"D" ,"19" ,"0.08" ,"D" ,"20" ,"0.55" ,"D" ,"18" ,"0.66"}, 
                {"E" ,"13" ,"0.49" ,"E" ,"14" ,"0.22" ,"E" ,"18" ,"0.66"} } 
            ), 

  
        // Source =    Excel.CurrentWorkbook(){[Name="Data"]}[Content],
        
        Tables =    List.Transform(
                        List.Split(Table.ToColumns(Table.Skip(Source, 1)), 3),
                        each Table.PromoteHeaders(Table.FromColumns(_))
                    ),
        FirstRow =  Table.FromList(
                        List.RemoveNulls(Record.ToList(Source{0})), 
                        null, 
                        {"Country"}
                    ),
        TWIndex =   Table.AddIndexColumn(FirstRow, "Index", 0, 1, Int64.Type),
        Collapsed = Table.TransformColumns(
                        TWIndex,
                        {"Index", each Tables{_}}   // тут фишка/ Вместо индекса подставляет таблицы из шага Tables
                    ),
        Expanded =  Table.ExpandTableColumn(Collapsed, "Index", Table.ColumnNames(Tables{0}) )
    in
        Expanded

//  джойн нескольких таблиц
        // в танке тема "List.Accumulate – как написать «пустой» второй аргумент". тут файл есть с примером http://www.excelworld.ru/forum/2-49290-1 
        let
            f=(x)=> Excel.CurrentWorkbook(){[Name=x]}[Content],
            tbl = Table.Join(f("Город"),{},f("Год"),{}),    // соединяем две таблицы
            to  = Table.Join(tbl,{},f("Продукт"),{})        // потом третью
        in
            to

        // хотя если параметров много соединяем сразу все
        let
            f=(x)=> Excel.CurrentWorkbook(){[Name=x]}[Content], // функция для подключения
            g=(x,y)=>Table.Join(x,{},f(y),{}),                  // функция для аккумулятора
            lst = {"Город","Год","Продукт"},                    // список имён таблиц (по сути имена запросов). Таблица Имя + Индекс
            to  = List.Accumulate(lst,#table({},{{}}),g)        // ... и собираем все таблицы вместе
        in
            to

        // вариант Михаила
        let
            f=(x)=>Table.SelectRows(Table.SelectColumns(from,x),(y)=>Record.Field(y,x)<>null),
            from = Excel.CurrentWorkbook(){[Name="Table1"]}[Content],
            nms  = Table.ColumnNames(from),
            to   = List.Accumulate(nms,#table({},{{}}),(s,c)=>Table.Join(s,{},f(c),{}))
        in
            to

//  как создать параметр в функции опциональный, Михаил //! Важно
    // см функцию fxExcelGetRowsAttributes с примером
        func=(filebin, optional options)=> ...
	
    //  в коде
        let sheetsonly = if options[SheetsOnly]?=true then true else false,
            fxUnzip    = if options[Excel2016]?=true then fxUnzip2016 else fxUnzip,

            to  = if sheetsonly then cmb else cmb & wb{[Kind="DefinedName"]}[tmp]

    //  синтаксис в примере
        to = F[Функция](from, [SheetsOnly = true])

    //  Пример:
            loadFilesInSite = 
                (optional options) =>
                    filter = 
                        Table.SelectRows(sort2, 
                            if options[AfterDate]? = null                    // если = F2[loadFilesInSite]([AfterDate = null]) 
                            then each true                                   // ничего не фильтруем
                            else each [Дата изменения] > options[AfterDate], // фильтруем по дате
                        )
//! --- Варианты - GroupKind.Local ---
// 	на вxоде таблица в один столбец - Хлеб, дата,дата,дата, Молоко, дата,дата,дата / надо сгруппировать даты по продуктам
	to = Table.Group(from,
			"Column1",
			{"Дата", (x)=>List.Skip(x[Column1])},
			GroupKind.Local,
			(x,y)=>Number.From(y is text) // проверка столбца на текстовые значения
		)

//!  LoadReport2 = 
		/*
			обрабатываем каждый файл исходя из вида отчета и датасета
		*/
		// (reportName as text, optional datasetName_ as nullable text) =>
		(options as record)  =>
		[
			// 	аргументы
				DATASET_NAME = let value = Record.FieldOrDefault(options, "ДатаCет", null) 	in if value = null then null else Text.From(value),
				REPORT_NAME  = let value = Record.FieldOrDefault(options, "Отчет", null)   	in if List.Contains({null, 0, ""}, value) then null else Text.From(value),

			// 	functionMap	- карта функций
				functionMap = [
					Homel   = F_Form[rep.BAL] ("Homel"),
					BKS 	= F_Form[rep.BAL] ("BKS")
				],
			
			//	from		- отфильтрованная таблица с нужными отчетами по заданному датасету
				from = 	F_Form[Connect_] ([ДатаCетИмя = DATASET_NAME, ОтчетИмя = REPORT_NAME]),
			
			// 	проверку сделать по виду отчета! т.к. обрабатывает любое содержимое
				to   = 	Table.AddColumn(from, "DataCombine", each 
								 if REPORT_NAME = "bal" then F_Form[rep.BAL3] (_[Content], DATASET_NAME)
							else if REPORT_NAME = "opu" then 1
							else 2
							// let func = Record.FieldOrDefault(functionMap, [Company], (_)=>_)
							// in  func([Content])
						),
			//	удаляем столбец с исходниками + фильтруем по имени отчета // ? может пораньше делать это, до обработки
				del = Table.RemoveColumns(to, {"Content"}),
				// sel = Table.SelectRows(to, each ([form_ID] = REPORT_NAME)),
			
			// 	раскрывать таблицы надо сгруппировав их по виду отчетов
				exp = Table.ExpandTableColumn(del, "Step2", Table.ColumnNames(del[Step2]{0}))
		]  [to],


//?  Запись с функциями для каждой подтаблицы

    Return = 
        // это (x)=> Record.FieldOrDefault(functionMap, x[Name], (x)=>x) - возвращает функцию functionMap по Name, 
        // которая принимает как аргумент ( [Step2] )
        Table.AddColumn(tbl, "Data", each
            let func = Record.FieldOrDefault(functionMap, [Name], (_)=>_)	// это функция, [Name] - это field
            in  func([Content2])	// применение функции к столбцу с подтаблицами в зависимости от [Name]
        )


        functionMap = [
            БКС    = fxBKS,
            Гомель = fxHomel
        ],
        
        //  Применение функций к подтаблицам
        Return = 
            Table.AddColumn(tbl, "Data+", 
                (x)=> Record.FieldOrDefault(functionMap, x[Name], (x)=>x) (x[Step2])
                // это (x)=> Record.FieldOrDefault(functionMap, x[Name], (x)=>x) - возвращает функцию functionMap по Name, 
                // которая принимает как аргумент ( [Step2] )
            )

    //  Применение функций к подтаблицам
        /*
            Описание	возвращает функцию из записи functionMap по значению в колонке [columnName]
            Источник	each Record.FieldOrDefault(functionMap, [Name],     (_)=>_) ([Step2]    )
            Пример		= F[fxFunctionMap] (funcMap, "Name", "Step2")
        */
        fxFunctionMap = 
            (functionMap as record, sName as text, sTable as text) =>
                Table.AddColumn(tbl, "Data+", 
                    each Record.FieldOrDefault( functionMap, Record.Field(_, sName), (_)=>_ ) (Record.Field(_, sTable))
                    
                ),

//  ! обращение к столбцу по имени
    f(Record.Field(row, nms{0})
    
    1.  Извлечение столбца как списка
        
        Table.Column(Источник, "ИмяСтолбца")
    
    2.  Динамическое обращение к столбцу
        
        Table.Column(Источник, ПеременнаяСИмяСтолбца)
        each Record.Field(_, ПеременнаяСИмяСтолбца)

//  fxAddMultiColumns с функцией столбца, чтобы не повторять
    add = F[fxAddMultiColumns](ren,
        let f=(x)=> each Record.Field(_, x) & " " & [Наименование]
        in {
            {"1_Группа_Наим",       f("1_Группа")},
            {"2_Класс_Наим",        f("2_Класс")},
            {"3_Категория_Наим",    f("3_Категория")},
            {"4_Подкатегория_Наим", f("4_Подкатегория")}
        }
    )
//  🔹 Здравствуйте. Возможно ли ускорить обработку запроса по сбору данных из файлов? Файлов может быть хоть 100 и весят по 2-4 Мб. В которых ~10к строк и столбцов ~50.
    Вычленять ничего из файлов не нужно, а собрать в 1 большой источник.
    Динамичные заголовки могут быть, потому приходится вытаскивать.
    И нужно сохранить название файла.
    //  Ответ Михаила!
        let
            from = Folder.Files("C:\путь\Новая папка")[[Name],[Content]],
            f=(x)=>Table.AddColumn(Excel.Workbook(x{1}, true)[Data]{0},"Name",(i)=>x{0}),
            to = Table.Combine(Table.ToList(from,f))
        in
            to

    //  Ответ Зеленского
        let
            from = Folder.Files("C:\Собрать данные\Новая папка")[[Name],[Content]],
            to   = Table.FromPartitions("Name", Table.ToList(from, (x)=>{x{0},Excel.Workbook(x{1},true){0}[Data]}))
        in
            to
        

//  Как с помощью PQ из текстовой строки вида : « бла бла бла 04-10-2024 18:30 бла бла »  извлечь дату и время ?
    //  полный вариант    
        f=(x)=>((a)=>DateTime.From(Text.Range(x,a,Text.PositionOf(x,":")-a+3)))(Text.PositionOf(x,"-")-2)

    //  если нет лишних пробелов в самой записи датывремени - можно просто
        f=(x)=> DateTime.From(Text.Range(x,Text.PositionOf(x,"-")-2,16))

//  В приемы! Имя колонки определяем функцией //*!
    f=(x)=>Excel.CurrentWorkbook(){[Name=x]}[Content],  
    to = Table.SelectRows( f("Яблоки"), (x)=>... )

//  Таблицу в запись и обратно. 
    let
        from =  Excel.CurrentWorkbook(){[Name="Таблица3"]}[Content],
        lst  =  from[Date],
        to   =  Table.FromRecords({
                    [Наименование = "период", от = List.Min(lst), до = List.Max(lst)]
                })
    in
        to

//  В приемы!!! List.PositionOf. Находим в тексте слова и оставляем только их (выделяем месяцы)
    в танке вопрос "Забыла сказать, что нужно выбрать только те периоды, которые указаны на странице "Параметры" в таблице "Период""
    let
        //  список месяцев
            lst = List.Buffer(List.Transform({1..12},(x)=>Text.Upper(Date.MonthName(#date(2024,x,1))))), 
        
        //  в тексте находим имя месяца и возвращаем его имя по позиции в списке месяцев "РАЗМЕЩЕНИЕ . ОКТЯБРЬ СТОИМОСТЬ NET, РУБЛИ"
            f=(x)=> lst{
                        List.PositionOf( lst, x, null, (c,v)=>Text.Contains(v,c) )
                    }, 
            
        from =  Excel.CurrentWorkbook(){[Name="Таблица1"]}[Content],
        tr   =  Table.TransformColumns(from,{"Наименование",f}),
        nms  =  List.Transform(
                    List.Skip(Table.ColumnNames(tr)),
                    (x)=>{x,(y)=>List.Sum(Table.Column(y,x))}   // список списков с колонка/функция
                ),
        to   =  Table.Group(tr,"Наименование",nms) // группируем первую колонку по месяцам
    in
        to


//  В Power Query есть несколько способов удалить пустые элементы из списка. Вот несколько вариантов: //? Важно

    //  Вариант 1: Использование List.RemoveNulls
        Функция List.RemoveNulls удаляет все null значения из списка, но не удаляет пустые строки.
            let
                SourceList   = {"a", "", "b", null, "c"},
                FilteredList = List.RemoveNulls(SourceList)
            in
                FilteredList
        
        Примечание: Этот метод удаляет только null, но оставляет пустые строки.

    //  Вариант 2: Фильтрация через List.RemoveMatchingItems
        Можно вручную указать элементы, которые нужно удалить, включая пустые строки.
        
        let
            SourceList   = {"a", "", "b", null, "c"},
            FilteredList = List.RemoveMatchingItems(SourceList, {null, ""})
        in
            FilteredList

        Преимущество: Позволяет явно указать, какие элементы нужно удалить.

    //  Вариант 3: Использование List.Select с Text.HasValue
        Если нужно удалить только пустые строки и null, но сохранить элементы с непустыми значениями, можно использовать Text.HasValue.
        
        let
            SourceList   = {"a", "", "b", null, "c"},
            FilteredList = List.Select(SourceList, each Text.HasValue(_))
        in
            FilteredList
        
        Преимущество: Удобно для работы с текстовыми данными, удаляет и null, и пустые строки.

    //  Вариант 4: Использование List.RemoveItems //! Мне понравился. Использую
        Если нужно удалить конкретные элементы, такие как пустые строки или другие специфические значения, можно использовать List.RemoveItems.
        
            let
                SourceList   = {"a", "", "b", null, "c"},
                FilteredList = List.RemoveItems(SourceList, {null, ""})
            in
                FilteredList

        Преимущество: Гибкость удаления специфических значений.

    //  Вариант 5: Использование комбинации List.Distinct и List.RemoveNulls
        Если вам нужно удалить дубликаты, пустые строки и null значения одновременно, можно использовать комбинацию функций.

            let
                SourceList   = {"a", "", "b", null, "c", "", null, "a"},
                DistinctList = List.Distinct(SourceList),
                FilteredList = List.RemoveMatchingItems(DistinctList, {null, ""})
            in
                FilteredList

        Преимущество: Удаляет дубликаты, null и пустые строки.
    
    //! Вот краткое резюме:
        List.RemoveNulls        — простой и быстрый вариант для удаления только null значений.
        List.Select с условиями — более гибкий вариант для удаления как null, так и пустых строк.


//  сдвиг строк в одной колонке относительно другой fxAddOtherRowColumn

    let
        tbl = Table.FromColumns({{"a".."i"},{1..9}},{"a","b"}),
        
        AddOtherRowColumn = 
            (tbl,col,newcol,index) =>
                [   lst = List.Buffer(Table.Column(tbl,col)),
                    add = Table.AddIndexColumn(tbl,newcol,index,1),
                    f   =   if index <0 
                            then (x)=>  if x <0  
                                        then null 
                                        else lst{x}
                            else (x)=>lst{x}?,
                    to = Table.TransformColumns(add,{newcol,f})
                ][to],
         
        to  = AddOtherRowColumn(tbl,"b","c",-1),
        to1 = AddOtherRowColumn(tbl,"b","c",-3),
        to2 = AddOtherRowColumn(tbl,"b","c",2)
    in
        to2

//  Разделяем колонку Аналитика Дт на 3 через перенос строки. 1С
    G:\=EXCEL - 1C\ Решени уровни аналитики
    
    let
        from =  Excel.CurrentWorkbook(){[Name="Исходная"]}[Content],
        gr   =  Table.Group(from, 
                    {"Период", "Дебет", "Кредит", "Сумма"}, 
                    {
                        {"Аналитика Дт", (x)=>x[Аналитика Дт]},
                        {"Аналитика Кт", (x)=>x[Аналитика Кт]}
                    }
                ),
        f=(x,y)=>
            Table.SplitColumn(
                x,
                y,
                (x)=>x, List.Max(
                            List.Transform(
                                Table.Column(x,y),
                                List.Count
                            )
                        )
            ),
        
        to = f(f(gr,"Аналитика Дт"),"Аналитика Кт") // интересный прием
    in
        to

//  Журнал операций 1С
    G:\=EXCEL - 1C\Пример PQ.xlsx
    let
        Source = Excel.CurrentWorkbook(){[Name="dataBody"]}[Content],
        PromotedHeaders   = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
        Пользовательский1 = Table.RenameColumns(PromotedHeaders, { {"Column7","КоличествоДт"},{"Column9","КоличествоКт"}}),
        excludeColumns    = Table.RemoveColumns(Пользовательский1, List.Select(Table.ColumnNames(Пользовательский1), (x)=>Text.StartsWith(x,"Column") )),
        GroupedRows = Table.Group(
            excludeColumns, 
            {"Дата"}, 
            {
                {   "tab", 
                        let names = Table.ColumnNames( excludeColumns ) 
                        in each 
                            Table.FromRows( 
                                {   List.Transform( Table.ToColumns(_),
                                        each if List.Count(List.RemoveNulls(_)) < 2
                                            then _{0}
                                            else Text.Combine(_,"|")
                                    )
                                },
                                names
                            ),
                    type table}
            }, 
            0, 
            (a,b) => Number.From( b[Дата] <> null) ),

        to = Table.Combine(GroupedRows[tab])
    in
        to

//  получение атрибутиов уровня в документах со структурой
        let
            unzip = Expression.Evaluate(Text.FromBinary(Web.Contents("https://raw.githubusercontent.com/buchlotnik/buchlotnik_functions/main/UnZip.pq")),#shared),
            bin   = Binary.Buffer(File.Contents("G:\=EXCEL - 1C\Отчет о продажах (Михаил)\Выгрузка отчета 1С о продажах - решение Михаила.xlsx")),

            xml   = Xml.Document(unzip(bin){[FileName="xl/worksheets/sheet1.xml"]}[Content]){0}[Value]{[Name="sheetData"]}[Value][Attributes],

            val = List.Transform(xml,(x)=>x{[Name="outlineLevel"]}?[Value]?),   // уровень
            nms = List.Transform(xml,(x)=>x{[Name="r"]}?[Value]?),              //  строка

            dict = Record.FromList(val,nms),    // строка - уровень
            sh   = Excel.Workbook(bin,false){0}[Data], // данные листа
            add  = Table.AddIndexColumn(sh, "Уровень", Number.From(nms{0}),1),
            to   = Table.TransformColumns(add,{"Уровень",(x)=>Record.FieldOrDefault(dict,Text.From(x))}),
            
            from   = Table.RemoveLastN(Table.Skip(Table.PromoteHeaders(Table.LastN(to,(r)=>r[Column3]<>"ТО ЧТО ЕСТЬ ")),2),1),
            f =(x)=> List.ReplaceRange({null,null,null},Number.From(List.Last(x)??0),1,{x{1}})&List.RemoveLastN(List.Skip(x,2),2),
            tbl    = Table.FromList(Table.ToList(from,f),(x)=>x),
            fill   = Table.FillDown(tbl,{"Column1","Column2"}),
            result = Table.SelectRows(fill,(r)=>r[Column3]<>null)
        in
            result

//  параметры задать путь в папке и имя файла - управление параметрами
    ПутьКПапке
        "G:\=EXCEL - 1C" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true]
    Имя файла
        "Оборотно-сальдовая ведомость.xlsx" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true]
//  Как чистить ошибки 
    ==============================================================================
    Table.ReplaceErrorValues, Table.RemoveRowsWithErrors – чистим входящие данные

    Дважды за последние сутки всплывал вопрос как поступать с ошибками данных в исходнике. 
    Имеются ввиду ошибки на листах - #ДЕЛ/0!, #ССЫЛКА!, #Н/Д и т.д. 
    Понятное дело, что наилучшее решение – влезть в исходник и ошибки исправить. 
    Но если у нас доступ только на чтение или, например, в файле протянуты формулы, 
    а ячейки не все заполнены, что и вызывает ошибки – в такой ситуации приходится заниматься обработкой при загрузке.

    // 1. Замена - Table.ReplaceErrorValues.

    Table.ReplaceErrorValues(table, {"Column2", null})						// Вторым аргументом – {имя столбца,на что заменить ошибку}
    Table.ReplaceErrorValues(table, {{"Column2", null}})
    Table.ReplaceErrorValues(table, {{"Column2", null},{"Column4", null}})
    Table.ReplaceErrorValues(table, {{"Column2", null},{"Column4", 0}})		// Причём в разных столбцах значение для замены может быть разным:
    Table.ReplaceErrorValues(table, List.Transform(Table.ColumnNames(table),(x)=>{x,null}))  // все столбцы: Т.е. получили список всех столбцов и превратили его в список списков вида {имя, null}

    // 2. Удаление - Table.RemoveRowsWithErrors.

    Table.RemoveRowsWithErrors(table, {"Column2"})	//	хотя удаляет всю строку с ошибкой.
    Table.RemoveRowsWithErrors(table, {"Column1", "Column2", "Column3"})	//	Для нескольких столбцов всё также несложно:
    Table.RemoveRowsWithErrors(table)	// удалить строки с ошибками сразу по всем столбцам? Т.е. по умолчанию без второго аргумента функция обрабатывает все столбцы 
    ==============================================================================
    ? ?? – Field Access и Coalesce – или зачем задавать вопросы в коде
    
    Вот так – никаких try, никаких if then else, просто знаки вопроса, поставленные в правильном месте.

        {1,2,3,4}{7} 											//ошибка – элементов в перечислении недостаточно
        [a= "Вася", b= "Петя", c="Коля"][d]						//ошибка – поле записи не найдено
        Excel.CurrentWorkbook(){[Name="Таблица124"]}[Content]	//ошибка, если нет такой таблицы

    Проблема решается путем использования ? (знак вопроса):

        {1,2,3,4}{7}? 											//null
        [a = "Вася", b = "Петя", c = "Коля"][d]? 				//null
        Excel.CurrentWorkbook(){[Name="Таблица124"]}?[Content]? //null

    Т.е. при обращении к элементу списка или полю таблицы, в случае их отсутствия оператор ? вернёт нам null – это лучше, чем ошибка.

    Но что если нам не нужен null? Ведь результат может использоваться далее в расчётах и нам может понадобиться 0, {}, [], "" 
    (ноль, пустой список, пустая запись, пустая строка и т.п.) или просто служебное сообщение вроде «не найдено».
    Во тут нам на помощь и приходит оператор ?? – объединение (coalesce). В общем виде это выглядит так:
    x??y    если x не null – будет возвращён x, иначе – y.    Ну а в нашем случае:

        {1,2,3,4}{7}? ??0 																//0 – ноль
        [a= "Вася", b= "Петя", c="Коля"][d]? ?? ""										//пустая строка
        Excel.CurrentWorkbook(){[Name="Таблица124"]}?[Content]? ??"данные не найдены"	// данные не найдены
    
    возвращается нужное значение - главное не забыть поставить пробел между ? и ?? .

//  Группировка разделов баланса Table.Group + GroupKind.Local + List.ContainsAny
    на выходе получаются таблица из колонки с пяпью разделами и содержанием этих разделов
    без первой строки (оформление баланса). Последние включатся в последний раздел
    =   Table.Skip(
            Table.Group(flt, {"Column1"}, 
                {"tmp", each _},
                GroupKind.Local,
                (s,c)=> Number.From( 
                            List.ContainsAny(
                                {Text.Split(c[Column1]," "){0}}, // сравнение compare по первому вхождению до пробела
                                {"I","II","III","IV","V"}, 
                                Text.Contains
                            )
                        )
            )
        )

//  Список номеров строк в которых находится искомый текст
    = Table.FindText(Table.AddIndexColumn(from, "index"), "активы")[index]
// 	ТАБЛИЦУ В ЗАПИСЬ   
    to = Record.FromList(
			Table.ToList(typed, (x)=>List.Skip(x)), // value - список значений (без первой колонки)
			Table.ToColumns(typed){0}				// key   - список уникальных полей (первая колонка) или другая 
		 )

//  Блок конвертации по кода 383, 384 ... статья по анализу организаций по РОССИИ
    #"Финальный вид таблицы" = Table.TransformColumns(#"Вид таблицы с добавленным годом", 
        {
			{"okved", each Text.Insert( (_), 0, (if #"Год" <= 2016 then "ОКВЭД: "else "ОКВЭД2: ") ),type text}
		}
	),

    lst1 = List.Skip(Table.ColumnNames(#"Финальный вид таблицы" ), 8), 
	lst  = List.Range(lst1,0,58),
	f=(x,y)=>List.Accumulate(lst,x,(s,c)=>Record.TransformFields(s,{c,(x)=>Number.From(x)*y})),
	g=(x)=> f(x,Number.Power(10, (Number.FromText(x[#"measure"])-383)*3)),
	
	tbl = Table.ToRecords(#"Финальный вид таблицы"),
	tr  = List.Transform(tbl,g),
	to  = Table.FromRecords(trnsf),
	

// 	= Table.FromList(toList, (x)=>x, Value.Type(Load2) )
    Table.TransformContent = рабоатет
		/*
		
		*/
			(tbl as table, NameColumn as text, Mask as text) =>
		[
			// tbl = selectFiles,
			// NameColumn = "Folder Path",
			// Mask = "ух",
		
			//  Превращаем таблицу в список списков 
				from = Table.ToRows(tbl),

			//  Определяем индексы для столбцов 'Content' и 'Folder Path'
				nms          = Table.ColumnNames(tbl),
				PathIndex    = List.PositionOf(nms, NameColumn),
				ContentIndex = List.PositionOf(nms, "Content"),

			//  Применяем трансформацию ко всем строкам списка
				TransformedList = 
					List.Transform(from, (x)=>
						let
							path    = x{PathIndex},
							content = x{ContentIndex},
							filteredTable = 
								if   Text.Contains(path, Mask)
								then Table.SelectRows(content, each [Name] = "СВОД")
								else content
						in
							List.Transform(
								nms, 
								(col) => if col = "Content" 
										then filteredTable
										else x{List.PositionOf(nms, col)}
							)
					),
			// 	Преобразуем список обратно в таблицу
				ResultTable = Table.FromRows(TransformedList, nms)
		]  [ResultTable],

	
//  ! замена Table в одном столбце по условию в другом
    Table.TransformContent = 
        (tbl as table, NameColumn as text, Mask as text) =>
    [
        // tbl = selectFiles,
        // NameColumn = "Folder Path",
        // Mask = "ух",
    
        //  Превращаем таблицу в список списков 
            from = Table.ToRows(tbl),

        //  Определяем индексы для столбцов 'Content' и 'Folder Path'
            nms          = Table.ColumnNames(tbl),
            PathIndex    = List.PositionOf(nms, nameColumn),
            ContentIndex = List.PositionOf(nms, "Content"),

        //  Применяем трансформацию ко всем строкам списка
            TransformedList = 
                List.Transform(from, (x)=>
                    let
                        path    = x{PathIndex},
                        content = x{ContentIndex},
                        filteredTable = 
                            if   Text.Contains(path, Mask)
                            then Table.SelectRows(content, each [Name] = "СВОД")
                            else content
                    in
                        List.Transform(
                            nms, 
                            (col) => if col = "Content" 
                                    then filteredTable
                                    else x{List.PositionOf(nms, col)}
                        )
                ),
        // 	Преобразуем список обратно в таблицу
            ResultTable = Table.FromRows(TransformedList, nms)
    ]  [ResultTable],


//      фиксированное колическтво столбцов
    to  = Table.FromRows(
        List.Transform(
            Table.ToRows(tbl),
            each 
                {   _{0}, 
                    if Text.Contains(_{2}, "ух") 
                    then Table.SelectRows(_{1}, each [Item] = "СВОД") 
                    else _{1},
                    _{2},
                    _{3}
                }
        ),
        Table.ColumnNames(tbl)
    )
//      динамическое колическтво столбцов
    let
        // Пример исходной таблицы
        Load = Table.FromRecords({
            [ID="1", Name="01_1222 Баланс.xlsx", Content=Table.FromRecords({[Item="1", Value=100], [Item="2", Value=200]})],
            [ID="2", Name="02_1223 Баланс.xlsx", Content=Table.FromRecords({[Item="1", Value=300], [Item="2", Value=400]})]
        }),

        from = Table.ToRows(Load),

        //  Определяем индексы для столбцов 'Name' и 'Content'
            nms          = Table.ColumnNames(Load),
            NameIndex    = List.PositionOf(nms, "Name"),
            PathIndex    = List.PositionOf(nms, "Folder Path"),
            ContentIndex = List.PositionOf(nms, "Content"),

        //  Применяем трансформацию ко всем строкам списка
            TransformedList = 
                List.Transform(SourceList, each 
                    let
                        name    = _{NameIndex},
                        path    = _{PathIndex},
                        content = _{ContentIndex},
                        filteredTable = 
                            if   Text.Contains(path, "ух")  // name = "01_1222 Баланс.xlsx"
                            then Table.SelectRows(content, each [Item] = "1")
                            else content
                    in
                        List.Transform(
                            nms, 
                            (col) => if col = "Content" 
                                     then filteredTable
                                     else _{List.PositionOf(nms, col)}
                        )
                ),
        ResultTable = Table.FromRows(TransformedList, nms)
    in
        ResultTable
        
//  интересно запись со списками с = List.Accumulate(Table.ToRows(b),[],(s,c)=>Record.AddField(s,c{0},List.Skip(c))),
    let
        a = #table({"ФИО","Профессия"},{{"Вася","Игрок"},{"Петя","Игрок"},{"Коля","Тренер"},{"Евлампий","Врач"}}),
        b = #table({"Должность","Оклад","Премия"},{{"Игрок",1000,100},{"Тренер",2000,5000},{"Врач",100,1}}),
        с = List.Accumulate(
                Table.ToRows(b),
                [],
                (s,c)=>Record.AddField(s, c{0}, List.Skip(c))
            ),
        d = (x)=> x & Record.Field(с,x{1}),
        e = Table.FromList(Table.ToRows(a),d,{"ФИО","Профессия","Оклад","Премия"})
    in
        e

//  List.Generate описангие примеры //! ПОЛЕЗНО
    = List.Generate(()=> 1, (x)=> x <=10, (x)=> x + 1, (x)=> "Column" & Text.From(x) )
    
    = List.Generate(
        () => 1, 
        (x)=> x <=10, 
        (x)=> x + 1, 
        (x)=> "Column" & Text.From(x) 
    )
    
    = List.Generate(
        () => [index = 1],
        each [index] <= 10,
        each [index = [index] + 1],
        each [page = txt & " " & Text.From([index])][page]
    )

    let
        txt = "Список",
        value = 1,      // [значение]
        q = 10,         // [количество],
        source = 
            List.Generate(                          // создаем запись с итератором, для получения условия выхода из цикла
                ()=> [i = 1, a = value],            // первого элемента в будущем списке 
                each [i] <= q,                      // проверка условия выхода из цикла 
                each [i = [i] + 1, a = [a] + 1 ],   // увеличиваем итератор на 1 и генерируем следующий элемент списка по формуле
                each [a]                            // показываем что именно выводить в будущий список
            )
    in
        source

//  ⚡ Итоговая строка //todo важно, полезно, как работает
    //  ВАРИАНТ 1. Через Table.InsertRows + разные примеры. Работает!!!
        let
            from =  
                Table.Buffer(
                    Table.FromColumns(
                            {
                                {1, 2, 3, 4, 5, 6, 7, 8, 9, 10},  // Уровень
                                {3000,  6300,  9650,    17500,  21000,  31000,  46000,  69000,  105000,  150000},  // Ветка 1
                                {4500,  9450,  14775,   26250,  31500,  46500,  69000, 103500,  157500,  225000},  // Ветка 2
                                {6000,  12600, 19700,   35000,  42000,  62000,  92000, 136000,  210000,  300000},  // Ветка 3
                                {7500,  15750, 24625,   43750,  52500,  77500, 115000, 172500,  262500,  375000},  // Ветка 4
                                {12000, 25200, 39400,   70000,  64000, 124000, 164000, 276000,  420000,  600000},  // Ветка 5
                                {16500, 34650, 54175,   96250, 115500, 170500, 253000, 379500,  577500,  625000},  // Ветка 6
                                {21000, 44100, 68950,  122500, 147000, 217000, 322000, 463000,  735000, 1050000},  // Ветка 7
                                {25500, 53550, 83725,  146750, 176500, 263500, 391000, 566500,  692500, 1275000},  // Ветка 8
                                {31500, 66150, 103425, 163750, 220500, 325500, 483000, 724500, 1102500, 1575000},  // Ветка 9
                                {37500, 76750, 123125, 216750, 262500, 367500, 575000, 662500, 1312500, 1675000}   // Ветка 10
                            }, 
                                {"Уровень"} & List.Transform({1..10}, (x)=>"Ветка" & Number.ToText(x))
                    )
                ),
            nms = Table.ColumnNames(from),
            
            //  вариант 1
                lst = List.Transform(
                        nms,
                        (x)=> if x="Уровень" then null else List.Sum(Table.Column(from, x))
                    ),

                TotalRow1 = 
                    let TotalRow = Record.FromList(lst, nms),
                    in  Record.TransformFields(TotalRow, {{"Уровень", each "Итого"}}),

            // вариант 1
                TotalRow2 = 
                    [
                        Уровень = "Итого", 
                        Ветка1 = List.Sum(Table.Column(from, "Ветка1")),
                        Ветка2 = List.Sum(Table.Column(from, "Ветка2")),
                        Ветка3 = "",
                        Ветка4 = "",
                        Ветка5 = "",
                        Ветка6 = "",
                        Ветка7 = "",
                        Ветка8 = "",
                        Ветка9 = "",
                        Ветка10 = 10
                    ],

            //  Создание итоговой строки с использованием функции//todo этот понравился
                TotalRow3 = 
                    Record.FromList(
                        List.Transform(nms, (x)=>
                                if x = "Уровень" then "Total"
                            else if x = "Ветка1" then List.Sum(Table.Column(from, "Ветка1"))
                            else if x = "Ветка2" then List.Count(Table.Column(from, "Ветка2"))
                            else if x = "Ветка9" then List.Max(Table.Column(from, "Ветка9"))
                            else ""
                        ),
                        nms
                    ),
            //  Добавляем строку: таблица, позиция, строка
                to = Table.InsertRows( from, Table.RowCount(from), {TotalRow4} )
        in
            to


    //  Вариант 2. Через List.Zip + List.Transform. Проще
        let
            Source =  Table.FromColumns(
                {
                    {1, 2, 3, 4, 5, 6, 7, 8, 9, 10},  // Уровень
                    {3000,  6300,  9650,    17500,  21000,  31000,  46000,  69000,  105000,  150000},  // Ветка 1
                    {4500,  9450,  14775,   26250,  31500,  46500,  69000, 103500,  157500,  225000},  // Ветка 2
                    {6000,  12600, 19700,   35000,  42000,  62000,  92000, 136000,  210000,  300000},  // Ветка 3
                    {7500,  15750, 24625,   43750,  52500,  77500, 115000, 172500,  262500,  375000},  // Ветка 4
                    {12000, 25200, 39400,   70000,  64000, 124000, 164000, 276000,  420000,  600000},  // Ветка 5
                    {16500, 34650, 54175,   96250, 115500, 170500, 253000, 379500,  577500,  625000},  // Ветка 6
                    {21000, 44100, 68950,  122500, 147000, 217000, 322000, 463000,  735000, 1050000},  // Ветка 7
                    {25500, 53550, 83725,  146750, 176500, 263500, 391000, 566500,  692500, 1275000},  // Ветка 8
                    {31500, 66150, 103425, 163750, 220500, 325500, 483000, 724500, 1102500, 1575000},  // Ветка 9
                    {37500, 76750, 123125, 216750, 262500, 367500, 575000, 662500, 1312500, 1675000}   // Ветка 10
                }, 
                    {"Уровень"} & List.Transform({1..10}, (x)=>"Ветка " & Number.ToText(x))),

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

    //	Вариант 3. Через List.TransformMany. Сложнее
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
    //  Вариант 4. Чат GPT
        to = Table.InsertRows(Source, Table.RowCount(Source),
            { Record.FromList(
                    List.Combine({
                        {"ИТОГО",""},
                        List.Transform(
                            List.Skip(Table.ColumnNames(Source), 2),
                            (col) => List.Sum(Table.Column(Source, col))
                        )
                    }),
                    Table.ColumnNames(Source)
                )
            }
        )
//  номер вхождения элемента списка по имени    
    index = List.PositionOf(Table.ColumnNames(tbl), "Строка_ID"),
//  DS_CountRows - объединение запросов по имени запроса + значение поля // Использование List.Select + List.Transform +Expression.Evaluate
    let
        queryNames = List.Select(Record.FieldNames(#shared), each Text.Contains(_, "DataSet_")),
        columnName = "СountRows",
        
        getColumnValues = (queryName as text) =>
            let
                queryTable = Expression.Evaluate(queryName, #shared),
                columnValues = try Table.Column(queryTable, columnName) otherwise null
            in
                columnValues,
        
        columnValuesList = 
            List.Transform(
                queryNames, 
                each [QueryName = _, Values = getColumnValues(_)]
            ),
        
        resultTable = Table.FromRecords(columnValuesList),
        
        to = Table.TransformColumns(resultTable, {"Values", each List.Sum(_), type text})
    in
        to

//  параметр as nullable 
    Если у вас есть параметр функции в Power Query, определенный 
    как optional n as nullable number, это означает, что параметр 
    может быть пропущен или задан как null. Когда аргумент не указан, 
    он будет иметь значение null.

//  группировка значений по диапазону с шагом
    let from  = tbl,
        Range = Table.AddColumn(from, "Category", each 
                    let value      = [На начало],
                        step       = 1000
                        rangeStart = Number.RoundDown((value - 1) / step) * step + 1,
                        rangeEnd   = rangeStart + (step - 1)
                    in  Text.From(rangeStart) & "-" & Text.From(rangeEnd)
                ),

        Sort =  Table.AddColumn(Range, "Sort", each 
                    Number.RoundDown(([На начало] - 1) / 1000) + 1
                ),
        
        group = Table.Group(Sort, {"Category", "Sort"}, 
                    {
                        {"Count",   each Table.RowCount(_), Int64.Type},
                        {"Sum",     each List.Sum([На начало])}
                    }
                )
    in  group

//  "Attributes" - (x)=> F[fxSizeFile] (Record.Field(x,"Size"))
    {"Attributes", 	 (x)=> F[fxSizeFile] (Record.Field(x,"Size")), type text},

//  подключаемся к папке - path = Value.Metadata(F_Form[Parameters]) [Mart] [pathXLSX],
    1
//  LoadFolderXLSX = // возвращает очищенный список файлов CSV  в папке с учетом подпапок
    LoadFolderXLSX = // возвращает очищенный список файлов CSV  в папке с учетом подпапок
		/*
			Пример:	= 
		*/
		(path as text) =>
		let
			from = Folder.Files(path),
			
			// фильтруем колонки и строки в списке файлов
			FilteredRows 		= Table.SelectRows(from, each Text.Start([Extension], 5) = ".xlsx" and [Attributes][Hidden] = false),
			NoTemps   			= Table.SelectRows(FilteredRows, each not Text.StartsWith([Name], "~$")),
			RemovedOtherColumns	= Table.SelectColumns(NoTemps, {"Name", "Content"} & {"Folder Path"}),
						
			// преобразуем бинарники в таблицы и фильтруем строки в подтаблицах
			TransformBinary   	= Table.TransformColumns(NoTemps,         {"Content", (x)=>Excel.Workbook(x)} ),
			NoPrintAreas 		= Table.TransformColumns(TransformBinary, {"Content", (x)=>Table.SelectRows(x, each not Text.Contains([Name], "$"))} ),
			OnlySheets		   	= Table.TransformColumns(NoPrintAreas,    {"Content", (x)=>Table.SelectRows(x, each [Kind]="Sheet")} ),

			// дополнительные колонки
			AddColSheetsName	= Table.AddColumn(OnlySheets, "SheetsName", (x)=>Text.Combine(x[Content][Name], ",") ), // список листов через ","
			
			// выводим последние 2 уровня названия папки
			NameFolder  		= Table.TransformColumns(AddColSheetsName, {
										{"Folder Path", each Text.AfterDelimiter(_, "\", {2, RelativePosition.FromEnd}), type text}}),
			
			SelectColumns		= Table.SelectColumns(NameFolder,{"Name", "Content"} & {"Folder Path"})
		in
			SelectColumns,

//  LoadFolderAll  = // *возвращает НЕочищенный список файлов в папке с учетом подпапок
	LoadFolderAll  = // *возвращает НЕочищенный список файлов в папке с учетом подпапок
		/*
			Пример:	= 
		*/
		(path as text) =>
		let
			from = Folder.Files(path),
			
			// фильтруем колонки и строки в списке файлов
			flt = Table.SelectRows(from, each Text.Start([Extension], 5) = ".xlsx" and [Attributes][Hidden] = false),
			sel	= Table.SelectRows(flt, each not Text.StartsWith([Name], "~$")),
			lst = {"Name","Extension", "Date created", "Content"} & {"Folder Path"},
			rem	= Table.SelectColumns(sel, lst),
			f=(x)=>Text.AfterDelimiter(x, "\", {2, RelativePosition.FromEnd}), // 2 уровня справа в названии папки
			tr	= Table.TransformColumns(rem, {{"Folder Path", f, type text}})
		in
			tr,
//  Полезный вариант замены если //! Через List.Transform
    // Определение индекса единицы измерения в зависимости от размера файла (Number.Power - степень)
    // это 
        Index1 = List.NonNullCount(
                    List.Transform(
                        {0..4}, 
                        (i) => if sizeInBytes >= Number.Power(Byte, i) then i else null)
                    ) - 1,

    //  равно этому 
        Index = 
            if      sizeInBytes < Byte   				then 0 
            else if sizeInBytes < Number.Power(Byte, 2) then 1 
            else if sizeInBytes < Number.Power(Byte, 3) then 2 
            else if sizeInBytes < Number.Power(Byte, 4) then 3 
            else 4,

//  Record.FieldOrDefault
    f=(x)=>Record.FieldOrDefault([1 = "Брест", 2 = "Витебск", 3 = "Гомель"], КодРегиона, null),
//  GetPathXLSX = // путь к источнику данных нактивного датасепта на основе метаданных Parameters
    GetPathXLSX = // путь к источнику данных нактивного датасепта на основе метаданных Parameters
		/* 
			Описание:
				Получаем метаданных Parameters значение отдельного параметра.
				Это связано с тем, что в Parameters возвращают только параметры активного датасета
			
			Результат:
				путь к источнику данных
		*/
		(Key as text) as text =>
		let
			from 	  = Parameters,
			Param	  = "pathXLSX",
			Metadata  = Value.Metadata(from),
			RecordVal = Record.FieldOrDefault(Metadata, Key, null),
			PathXLSX  = 
				if 	 RecordVal <> null and Record.HasFields(RecordVal, Param) 
				then RecordVal[pathXLSX] 
				else null
		in
			PathXLSX,
//  проверка функции если она полями образована
    let 
        [   [tblShema], [param], [nms], [path], [load], [reorder], [shema], [result] ]
//  Добавить строку
    addColOther = Table.InsertRows(addColumn, 61, {[ID_Строка = 800, СтатьяИмя = "Прочие", СтрокаСтатья = "800 Прочие"]} )
//  TORG.Query - ПОДКЛЮЧЕНИЕ (не сделал еще и надо ли?!//!)
	TORG.Query   = (tbl as table) => Expression.Evaluate( "F_Form[TORG][TORG.Body](tbl)", #shared & [tbl=tbl]),
// 	ДЛЯ КОПИРОВАНИЯ В ПРОЕКТ
	// DataSets  = // 1 создаем базу данных моих отчетов
	// 	let
	// 		sect = Record.ToTable(#shared),
	// 		from = Table.SelectRows(sect, each Text.StartsWith([Name], "DataSet_")),
	// 		SplitColumns = Table.RemoveColumns(Table.SplitColumn(from, "Name", Splitter.SplitTextByDelimiter("_", QuoteStyle.Csv), {"Name.1", "Атрибут", "Company"}),{"Name.1"}),
	// 		AddColumn = Table.AddColumn(SplitColumns, "Index", each Record.FieldOrDefault(
	// 						[Mart = 1, Homel = 2, BKS = 3, Drog = 4], 
	// 						[Company], null)),
	// 		Reorder = Table.ReorderColumns(AddColumn,{"Index","Company", "Атрибут", "Value"}),
	// 		TextLower = Table.TransformColumns(Reorder,{{"Атрибут", Text.Lower, type text}})
	// 	in
	// 		TextLower,
	
	// DataShema = // 2 создаем схемы таблиц отчетов по маске. На выходе запись: Name (вид отчета) + Value (таблица со схемой)
	// 	let
	// 		sect = Record.ToTable(#shared),
	// 		from = Table.SelectRows(sect, each Text.StartsWith([Name], "DataSet_XLS")),
	// 	    tr   = Table.TransformColumns(from, {"Value",each Record.ToTable(_)}),
	// 		exp  = Table.ExpandTableColumn(tr, "Value", {"Name", "Value"}, {"Имя", "Значение"}),
	// 		grp  = Table.Group(exp, {"Имя"}, {{"Value", (x)=> F[fxShema](x[Значение] {0} )}}), // первое вхождение
	// 		rec  = Record.FromTable(Table.RenameColumns(grp,{{"Имя", "Name"}}))
	// 	in
	// 		rec,

//  fxLoadReport = // версия в файле 40 до изменнения
    fxLoadReport = // Важная функция
		(REPORT_NAME as text, optional DATASET as number )  =>

		let 
				dataSet_Nomer1 = Number.From(Text.Split(prm_DataSet," "){0}),
				dataSet_Vid   = prm_LoadVar,
				TBL           = DataSets,
				TBL_SHEMA 	  = DataShema,
				// DATASET		  = 1,	//"Homel"
				
				dataSet_Nomer =   
					if   DATASET = null
				 	then dataSet_Nomer1
				 	else DATASET,

			// 	Проверка 1. Проверяем наличие отчета во всех датасетах (для обработки ошибки ввода имени отчета)
				fxCheckReport = 
					(list as list, txt as text) as logical => 
						List.Contains(allReport, txt),
    			allReport = List.Distinct(List.Combine(List.Transform(TBL[Value], each[Name]))),
				IsReport  = fxCheckReport(allReport,REPORT_NAME),

			//	если отчет есть, то возвращаем список полей отчета, если нет, то пустой список
				reportField = 	
					if IsReport
					then Record.Field(TBL_SHEMA, REPORT_NAME)[Header]
					else {},

			// 	Проверка 2. проверяем наличие отчета в одном датасете (есть даные по отчету или нет)
					fxCheckData = (inputTable as table, targetName as text) as logical =>
						let
							// Фильтрация исходной таблицы по колонкам Vid и Index
							filteredTable = 
								Table.SelectRows(inputTable, each 
									[Index] = dataSet_Nomer and
									[Vid]   = dataSet_Vid
								),

							// Функция для проверки наличия targetName в подтаблице
							CheckSubTable = (subTable as table) as logical =>
								List.Contains(Table.Column(subTable, "Name"), targetName),

							// Получаем список всех подтаблиц из отфильтрованной таблицы
							nestedTables = Table.Column(filteredTable, "Value"),

							// Применяем функцию CheckSubTable к каждой подтаблице и проверяем наличие targetName
							result = List.AnyTrue(List.Transform(nestedTables, CheckSubTable))
						in
							result,

				// проверка
					IsData = fxCheckData(TBL, REPORT_NAME),

			//	Вариант 1: таблица с данными отчета (фильтруем датасет и возвращаем содержимое ее первой подстроки или null
				tableReport = 
					let from = Table.SelectRows(TBL, each [Index]= dataSet_Nomer and [Vid]=dataSet_Vid),
						data = from [Value] {0}, // в колонке "Value" первая строка
						to   =  Table.SelectRows(data, each [Name]= REPORT_NAME)[Value]{0}
					in  try to otherwise null,
					 
			//	Вариант 2: возвращаем пустую таблицу + несколько заполненных строк
				// tableBlank = F_Form[form.BlankTable](REPORT_NAME),
				tableBlank = F_Form[form.BlankTable](TBL_SHEMA, REPORT_NAME),

			//	Выгружаем таблицы
				res =   if   IsReport = true and IsData = true // если найден отчет с такими параметрами в DataSets
						then tableReport
				 		else tableBlank
	
        in  
            res
       

//  Про shared 

    let
        // Получение всех элементов из глобальной среды
        AllQueries = Record.FieldNames(#shared),
        
        // Фильтрация имен, которые начинаются с "data"
        FilteredNames = List.Select(AllQueries, each Text.StartsWith(_, "DataSet_")),
        
        // Преобразование списка имен в таблицу
        NameTable = Table.FromList(FilteredNames, Splitter.SplitByNothing(), {"Name"}),
        add  = Table.AddColumn(NameTable, "w", each Expression.Evaluate([Name],#shared & [_=_])),
        exp = let 
            exp1 = Table.ExpandTableColumn(add, "w", {"ID", "Value"}, {"ID", "Value"}),
            exp2 = Table.ExpandTableColumn(exp1, "Value", {"Name"}, {"Name.1"}),
            sel  = Table.SelectColumns(exp2,{"ID"})
        in sel,
        Пользовательский1 = List.Distinct(exp[ID])
    in
        Пользовательский1

    = Expression.Evaluate("DataSet_1",#shared & [DataSet_1=DataSet_1]) // так работает
    = List.Distinct(List.Combine(List.Transform(Пользовательский1[Value], each [ID])))


    Я проверял не в сервисе, а в десктопе - там работает.
    А вот про цикличность упустил, поэтому чуть напряжнее:
    let
        from = Table.SelectRows(Record.ToTable(#shared),each [Name]<>"Евлампий" and Value.Is([Value],Table.Type))[Name],
        lst = List.Transform(from,(z)=>Expression.Evaluate("#(#)""" & z & """",#shared)),
        to = Table.Combine(lst)
    in
        to

    // зеленский
        Евлампий = 
        let
            from = Table.SelectRows(Record.ToTable(#shared),each [Name]<>"Евлампий" and Value.Is([Value],Table.Type))[Value],
            to = Table.Combine(from)
        in
            to
    Хотя по идее не должен.

    еще пример когда много много запросов обрабатывать надо

    TableAddColumn=(tbl,name,func, optional typ)=>
        [
            rec = Table.ToRecords(tbl),
            nms = Table.ColumnNames(tbl)&{name},
            g=(x)=>Record.FieldValues(x)&{func(x)},
            newtyp = if typ=null then Type.FunctionReturn(Value.Type(func)) else typ,
            newtbl = Table.FromList(rec,g,nms),
            lst  = {Text.Combine(List.Transform(Table.ToRows(Table.Schema(from)[[Name],[TypeName]]),(x)=>Text.Format("#{0}=#{1}, ",x))),name,Table.Schema(#table(type table [n=newtyp],{})){0}[TypeName]},
            txt  = Text.Format("type table[ #{0} #{1} = #{2}]",lst),
            ascr = Expression.Evaluate( txt, #shared),
            to   = Value.ReplaceType(newtbl,ascr)
        ][to]


//  для примера
    DataSet_1 = 
    Table.FromRecords({
            [ID = 1, NestedTable = Table.FromRecords({[Name = "Alice"], [Name = "Bob"]})],
            [ID = 2, NestedTable = Table.FromRecords({[Name = "Charlie"], [Name = "Alice"]})],
            [ID = 3, NestedTable = Table.FromRecords({[Name = "David"], [Name = "Eve"]})]
        })

    DS = 
    let
        from = Table.SelectRows(Record.ToTable(#shared), each Text.StartsWith([Name], "DataSet_")),
        sel  = Table.SelectRows(from, each ([Name] = "DataSet_XLS_Bob")),
        Пользовательский1 = Table.TransformColumns(sel, {"Value", each _ as table, type table}),
        Value = Пользовательский1{0}[Value]
    in
        Value

//  IsReport     = // проверка наличия отчета. Разобрать, не использовал
	IsReport     = //* 
		let 
			IsRep = (tableNames as list )=>
				let
					// Функция для безопасного извлечения таблицы по имени
					GetTable = (tableName as text) as table => 
						try Expression.Evaluate(tableName, #shared) otherwise null,

					// Создание записи с проверенными значениями таблиц
					rec = Record.FromList(
						List.Transform(tableNames, each GetTable(_)),
						List.Transform({1..List.Count(tableNames)}, each Text.From(_))
					)
				in rec
		in
			IsRep({"opu"}),
//  добавление строк в имеющуюся таблицу !
    Вот оптимизированная версия кода для добавления строк в уже существующую таблицу:

        let
            // Предположим, что у нас уже есть существующая таблица existingTable
            existingTable = ...,

            // Функция для получения значения поля или null, если поле не существует
            getFieldOrDefault = 
                (rec as record, field as text) as any =>
                    if Record.HasFields(rec, field) then Record.Field(rec, field) else null,

            // Создание списка новых записей
            newRecords = List.Transform(dataList, (rec as record) =>
                Record.FromList(
                    List.Transform(nms, each getFieldOrDefault(rec, _)), 
                    nms
                )
            ),
            
            // Добавление новых строк к существующей таблице
            tableAddedRows = Table.Combine({existingTable, Table.FromRecords(newRecords, nms)})
        in
            tableAddedRows

    Оптимизации, внесенные в код:
    Сохранение существующей таблицы: Переменная existingTable представляет уже существующую таблицу.
    Создание новых записей: newRecords создается из dataList с помощью List.Transform и функции getFieldOrDefault.
    Объединение таблиц: Используем Table.Combine для объединения существующей таблицы existingTable и новой таблицы, созданной из newRecords.
    Этот код позволяет добавлять новые строки к уже существующей таблице, обеспечивая при этом оптимизированное и профессиональное решение.

//  создать пустую таблицу с новыми строками
        // Функция для получения значения поля или null, если поле не существует
			getFieldOrDefault = 
                (rec as record, field as text) as any =>
					if Record.HasFields(rec, field) then Record.Field(rec, field) else null,

		// Создание таблицы с данными
            tableAddedRows2 = Table.FromRecords(
                List.Transform(
                    dataList2, 
                    (rec as record) =>
                        Record.FromList(
                            List.Transform(nms, (x)=> getFieldOrDefault(rec, x)), 
                            nms
                        )
                ),
                nms
            ),
        1 Использование getFieldOrDefault: Ввели вспомогательную функцию getFieldOrDefault, чтобы избежать повторного вызова Record.FieldOrDefault в List.Transform. Это улучшает читаемость и немного ускоряет выполнение.
        
        2 Замена Table.InsertRows на Table.FromRecords: Создание таблицы с помощью Table.FromRecords и сразу заполнение её данными вместо создания пустой таблицы и последующего заполнения. 

// 	form.BlankTable = // 4 создаем пустую таблицу по имени отчета, чтобы связи с календарем не пропадала
	form.BlankTable = // 4 создаем пустую таблицу по имени отчета, чтобы связи с календарем не пропадала
		(	tblShema as record, 	// Запись! со схемами таблиц отчетов tableShema
			REPORT_NAME as text		// имя отчета
		) =>
			let
				//  REPORT_NAME = "odds",
				//  tbl = tableShema,
					from = tblShema,

				//	имена столбцов ... если схема всех отчетных таблиц представлена Record
					nms  = Record.Field(from, REPORT_NAME)[Header],
				
				//	имена столбцов? На выходе же таблица ... если схема всех отчетных таблиц представлена Table
					nms2  = Table.Column(
								Table.SelectRows(from, each [Атрибут] = REPORT_NAME)
								{0}[Количество], 	// первая строка колонки [Количество] в основной таблице 
								"Name" 				// имя колонки с названиями колонок в подтаблице
							),

				//	
					ПустыеКолонки1 = List.Transform(nms, each {}),              // пустая таблица - строк нет
					ПустыеКолонки2 = List.Repeat( {{""}}, List.Count(nms) ),    // пустая таблица - строка одна пустая
					
					CreatedTable = Table.FromColumns(ПустыеКолонки1, nms),      // создаем таблицу
				
				// 	добавляем строку с датой, чтобы не рушилась связь с календарем
					Данные = 
						{
							Record.FromList( 
								List.Transform(nms, each if _ = "Date" then #date(2023, 12, 1) else null ), 
								nms) 
						},

				// 	берем первые 5 колонок
					fromOneRows  = Table.InsertRows(CreatedTable, 0, Данные),
					from5Columns = Table.SelectColumns(fromOneRows, List.FirstN(Table.ColumnNames(fromOneRows), 5)),
				
				//	новая таблица из четырех колонок. Минус - сбивается группировка полей!
					NewTable = 
						let create = 
								Table.FromRecords({[
									Date = #date(2024, 7, 9),  
									Company = null,
									DataSet = null,
									Report_ID = null
								]}),
							TypedTable = Table.TransformColumnTypes(create, {{"Date", type date}})
						in TypedTable,
				
				// 	типизируем столбцы
					// typed = F[form.SetType](fromOneRows, from, REPORT_NAME)
					typed = form.SetType2(fromOneRows, from, REPORT_NAME)	// ??? номер 2
			in
				try typed 			//	
				otherwise NewTable,	//
//  form.BlankTable2 = // вставляем новую таблицу, со значениями строк или пустую (не добавление в имеющуюся)
	form.BlankTable2 = // вставляем новую таблицу, со значениями строк или пустую (не добавление в имеющуюся)
		(	TBL_SHEMA   as record,	// таблица с типами колонок всех отчетов
			REPORT_NAME as text
		)=>
			let 
				// 	имена колонок отчета
					nms  = Record.Field(TBL_SHEMA, REPORT_NAME)[Header],
				
				// 	значения строк. Если полей с такими названиями нет, ошибки не будет, данные просто не будут добавлены
					Запись1 = [Date = #date(2022, 6, 1), Строка_ID = 104, На начало = 354],
					Запись2 = [
						Date        = #date(2023, 6, 1), 
						Строка_ID   = 104, 
						Значение    = 256, 
						Атрибут     = "Просроченная"
					],
				
				// 	список записей = списку строк
					lst = {Запись1, Запись2},
					lst2 = {},
				
				//	применение функции к каждой записи
					tableAddedRows = 
						Table.InsertRows(
							Table.FromColumns(List.Transform(nms, each {}),  nms),
							0, 
							List.Transform(lst, 
								(rec as record) as record =>
									Record.FromList( 
										List.Transform( nms, (x)=> Record.FieldOrDefault(rec, x, null)), 
										nms
									)
							)
						),
				
				// 	меняем тип всех колонок таблицы по шаблону - таблица "tableShema"
					typedTable = F[form.SetType2](tableAddedRows, TBL_SHEMA, REPORT_NAME)
			in
				try typedTable 
				otherwise {},	// если в названии отчета ошибка
//  обработка ошибкок через ?? 
    nms = Record.FieldOrDefault(TBL_SHEMA, REPORT_NAME, null)[Header]? ?? {},
//  tableShemaCSV = // схема всех отчетов путем импорта из csv //* Перестать пользоваться
    tableShemaCSV = // схема всех отчетов путем импорта из csv //* Перестать пользоваться
		let	
			from = F[LoadCSV]( Value.Metadata(Parameters)[Homel][pathCSV] & "\tableSchema.csv" ),
			repl = Table.ReplaceValue(from,"balanc","bal",Replacer.ReplaceText,{"Name"}),
			rec  = Record.FromTable( Table.Group(repl, {"Name"}, {{"Value", (x)=>x}}) )
		in	
			rec,
//  DataSetsMidl = //* датасет, в записях вместо таблиц ставим 1 	
    DataSetsMidl = //* датасет, в записях вместо таблиц ставим 1 	
		let
			from = Table.SelectRows(Record.ToTable(#sections[Section1]), each Text.StartsWith([Name], "DataSet_")),
			fxRec = 
				let
					// Функция для проверки типа данных
					CheckType = (value as any) as number =>
						if Type.Is(Value.Type(value), type table) 
						then 1
						else 0,

					// Функция для обработки записей
					ProcessRecord = (rec as record) as record =>
						let
							fields = Record.FieldNames(rec),
							newFields = List.Transform(fields, each {_, CheckType(Record.Field(rec, _))}),
							transformedRecord = Record.FromList(List.Transform(newFields, each _{1}), fields)
						in
							transformedRecord
				in
					ProcessRecord,
//  fxRec2=()=>
			fxRec2=()=>
				let
					// Функция для проверки типа данных
					CheckType = (value as any) as number =>
						if Type.Is(Value.Type(value), type table) 
						then 1
						else 0,

					// Функция для обработки записей
					ProcessRecord = (rec as record) as record =>
						let
							fields = Record.FieldNames(rec),
							newFields = List.Transform(fields, each {_, CheckType(Record.Field(rec, _))}),
							transformedRecord = Record.FromList(List.Transform(newFields, each _{1}), fields)
						in
							transformedRecord
				in
					ProcessRecord,

			Пользовательский1 = Table.TransformColumns(from, {"Value", each fxRec2(_)}),
			
			// Получение всех имен полей!!!
			AllFieldNames = List.Buffer(List.Union(List.Transform(Пользовательский1[Value], Record.FieldNames))),

			exp = Table.ExpandRecordColumn(Пользовательский1,"Value", AllFieldNames),
			Unpivot = Table.UnpivotOtherColumns(exp, {"Name"}, "Атрибут", "Значение"),
			
			del = let 
				s = Table.SplitColumn(Unpivot, "Name", Splitter.SplitTextByDelimiter("_", QuoteStyle.Csv), {"Name.1", "Вид", "Company"}),
				a = Table.RemoveColumns(s,{"Name.1"}),
				b = Table.ReorderColumns(a,{"Company", "Вид", "Атрибут", "Значение"}),
				c = Table.ReplaceErrorValues(b, {{"Значение", -1}}),
				d = Table.TransformColumns(c,{{"Вид", Text.Lower, type text}})
			in  d
		in
			del,
	DataSetsOld  = //* не использую. Заменил на #sections[Section1]
		let
			// создаем таблицу с датасетами всех организаций. Если их нет, то null
			// через #sections1 не видит тип данных Record в PBI в режиме представление таблицы, поэтому не может грузить данные в модель. В Excel все нормально.

			from = #table( type table[Index = number, Name = text, xls = any, csv = any], {
				// {1, "Mart",  DataSet_XLS_Mart,  DataSet_CSV_Mart},
				// {2, "Homel", DataSet_XLS_Homel, DataSet_CSV_Homel},
				// {3, "BKS",   null,   null},
				// {4, "Drog",  DataSet_XLS_Drog,  DataSet_CSV_Drog}
			} ),

			unpivot = Table.UnpivotOtherColumns(from, {"Index", "Name"}, "Атрибут", "Значение")
		in
			unpivot,

	
//  form.BlankTable = // 4 создаем пустую таблицу по имени отчета, чтобы связи с календарем не пропадала
    form.BlankTable = // 4 создаем пустую таблицу по имени отчета, чтобы связи с календарем не пропадала
		(	tblShema as record, 	// Запись! со схемами таблиц отчетов tableShema
			REPORT_NAME as text		// имя отчета
		) =>
			let
				//  REPORT_NAME = "odds",
				//  tbl = tableShema,
					from = tblShema,

				//	имена столбцов ... если схема всех отчетных таблиц представлена Record
					nms  = Record.Field(from, REPORT_NAME)[Header],
				
				//	имена столбцов? На выходе же таблица ... если схема всех отчетных таблиц представлена Table
					nms2  = Table.Column(
								Table.SelectRows(from, each [Атрибут] = REPORT_NAME)
								{0}[Количество], 	// первая строка колонки [Количество] в основной таблице 
								"Name" 				// имя колонки с названиями колонок в подтаблице
							),

				//	
					ПустыеКолонки1 = List.Transform(nms, each {}),              // пустая таблица - строк нет
					ПустыеКолонки2 = List.Repeat( {{""}}, List.Count(nms) ),    // пустая таблица - строка одна пустая
					
					CreatedTable = Table.FromColumns(ПустыеКолонки1, nms),      // создаем таблицу
				
				// 	добавляем строку с датой, чтобы не рушилась связь с календарем
					Данные = 
						{
							Record.FromList( 
								List.Transform(nms, each if _ = "Date" then #date(2023, 12, 1) else null ), 
								nms) 
						},

				// 	берем первые 5 колонок
					fromOneRows  = Table.InsertRows(CreatedTable, 0, Данные),
					from5Columns = Table.SelectColumns(fromOneRows, List.FirstN(Table.ColumnNames(fromOneRows), 5)),
				
				//	новая таблица из четырех колонок. Минус - сбивается группировка полей!
					NewTable = 
						let create = 
								Table.FromRecords({[
									Date = #date(2024, 7, 9),  
									Company = null,
									DataSet = null,
									Report_ID = null
								]}),
							TypedTable = Table.TransformColumnTypes(create, {{"Date", type date}})
						in TypedTable,
				
				// 	типизируем столбцы
					// typed = F[form.SetType](fromOneRows, from, REPORT_NAME)
					typed = form.SetType2(fromOneRows, from, REPORT_NAME)	// ??? номер 2
			in
				try typed 			//	
				otherwise NewTable,	//

//  fxLoadReport = // Важная функция
    fxLoadReport = // Важная функция
		/*
			Логика: = если отчет в базе есть, то выводим его, если нет, то пустую таблицу с заполненной датой и возможно другими тестовыми данными
			Пример: = fxLoadReport(DataSets,"bal",null)
		*/
		/*
			// res = if to2 <> null then to2 else fxAddBlankTable(reportName)
			// try res otherwise fxAddBlankTable(reportName)
			(reportName as text, optional dataSetNomer as number) =>
			let 
				rec =   if prm_LoadVar ="csv" 
						then DS_CSV 
						else DS_XLS,
				
				// если номер указан, то его, если нет, то берем из параметров
				dataSet =   if   dataSetNomer = null
							then Parameters[DataSetNomer]
							else dataSetNomer,

				// очищаем запись от ошибок в имени поля, если его не существует (нет такого запроса)
				cleanRec = 
					Record.FromList(
						List.Transform(
							Record.FieldNames(rec), 
							(x)=> try Record.Field(rec, x) otherwise null
						),
						Record.FieldNames(rec)
					),
						
				// возвращаем значение поля (это таблица) по ключу (имя датасета)
				to1 = Record.FieldOrDefault( cleanRec, reportName, null),
				to2 = Record.FieldOrDefault( to1, Text.From(dataSet), null),
				res =   if   to2 = null 
						then fxAddBlankTable(reportName)
						else to2 
				// res2 = try res otherwise fxAddBlankTable(reportName)
			in 
				res
			*/

		(	tbl as table, 					// 	ТАБЛИЦА с датасетами		tbl = DataSets,
			reportName as text, 			//	текстовое имя отчета		reportName ="bal",
			optional dataSetNomer as number	//	номер датасета				dataSetNomer = Parameters[DataSetNomer],		
		) as table =>
		let 
			//		
				// tbl = F1[DataSets],

			// 	если номер датасета указан, то грузим его, если нет, то берем из параметров
				dataSet =   if   dataSetNomer = null
							then Parameters[DataSetNomer]
							else dataSetNomer,

			//	уа	сделать  две строки //!Вот тут что то dataSet поменял на prm_DataSet
				to =    try Record.Field(
								Table.SelectRows(tbl, each [Index]=prm_DataSet and [Атрибут]=prm_LoadVar ) [Value] {0},
								reportName
							)
						otherwise null,

			//	пустая таблица
				tableZero = F[form.BlankTable](F_Form[tableShema],reportName),
			
			//	уа
				res =   if   to = null // что значит? если отчет пустой?!
						then tableZero
						else to // если имя отчета найдено, наверное так
		in 
			res,
//  Добавляем строку в таблицу и колонку по условию
    =   Table.InsertRows(
            Источник,
            0,  // номер строки, куда будет добавление
            {   // добавляем одну строку со значением колонке "Date". Через "," если надо несколько
                Record.FromList(
                    List.Transform(
                        Table.ColumnNames(Источник),
                        each if _ = "Date" then #date(2023, 12, 1) else null ),
                    Table.ColumnNames(Источник),
                    
                )
            }
        )

//  достаем таблицу из записи с записями, т.е. есть в колонке запись и в не вложены ещезаписи
    =   Record.Field(
            Table.SelectRows(TextLower, each [Index]=2 and [Атрибут]=prm_LoadVar ) [Value]{0}, // пересечение колонки и строки
            "bal"
        )
//  все имена полей во всех Record и table. //!Интересно! СПИСОК ВСЕХ КОЛОНОК ВО ВСЕХ ТАБЛИЦАХ
    AllFieldNamesRecord = List.Union(List.Transform(from[Value], Record.FieldNames)),

    AllFieldNamesTables = List.Distinct(List.Combine(List.Transform(TBL[Value], each[Name]))),
    nms = List.Distinct(List.Combine(List.Transform(Table.Column(from, "TableColumn"), each Table.ColumnNames(_))))



//  DataSet_CSV_Mart
        let
            load    = (fileName as text)=>                  F[LoadCSV](Value.Metadata(Parameters)[Mart][pathCSV] & fileName),
            reorder = (tbl as table, reportName as text)=>  F[Reorder.AllColumns](tbl, Record.Field(tableShema, reportName)[Header]),
            shema   = (tbl as table, reportName as text)=>  F_PackForm[fxSetType2](tbl, tableShema, reportName),
            
            from = 
                [   
                    bal  = let name = "bal",  l = load("\f_bal.csv"),  r = reorder(l,name), s = shema(r,name) in s,
                    opu  = let name = "opu",  l = load("\f_opu.csv"),  r = reorder(l,name), s = shema(r,name) in s,
                    odds = let name = "odds", l = load("\f_odds.csv"), r = reorder(l,name), s = shema(r,name) in s
                ]
        in
            from

//  DataSet_XLS_Mart
        let
            loadFolderXLSX = F_PackForm[Connect][Mart],
            from = [
                bal  = F_PackForm[Balans][Balance.Query](loadFolderXLSX),
                opu  = F_PackForm[OPU][OPU.Query](loadFolderXLSX),
                odds = F_PackForm[ODDS][ODDS.Query](loadFolderXLSX)
            ]
        in
            from

//  dataset load
    (reportName as text, optional dataSetNomer as number) =>
    let 
        // если номер указан, то его, если нет, то берем из параметров
        dataSet =   if   dataSetNomer = null
                    then Parameters[DataSetNomer]
                    else dataSetNomer,


        to = try Record.Field(Table.SelectRows(DS6, each ([Name] = dataSet) and ([Var] = "xls"))[Значение]{0}, reportName) otherwise null,
        
        res =   if   to = null 
                then fxAddBlankTable(reportName)
                else to
    in 
        res

//  dataset load
    let
        Q = (queryName as text) as any =>
            let
                queryList = #sections[Section1],
                queryExists = Record.HasFields(queryList, queryName)
            in
                if queryExists then Record.Field(queryList, queryName) else null,

        Источник = #table(
            type table[Index = number, Name = text, xls = any, csv = any],
            {
                {1, "Mart",  null,  null },
                {2, "Homel", DataSet_XLS_Homel, DataSet_CSV_Homel},
                {3, "Drog",  DataSet_XLS_Drog,  DataSet_CSV_Drog}
            }
        )
    in
        Источник


//  Table.FromColumns
    = let
                    a = (a) => 
                        List.Transform(
                            Excel.CurrentWorkbook(){[Name = a]}[Content][Столбец1], 
                            Text.From
                        )
                in
                    Table.FromColumns({a("Таблица4"), a("Таблица5")})
                  

//  заполнение таблицы в нуля
    let 
        // имена колонок
        nms  = Record.Field(tableShema,"osr")[Header],
        
        // значения
        Запись1 = [
            Date        = #date(2022, 6, 1), 
            Строка_ID   = 104, 
            Значение    = 354, 
            Атрибут     = "Просроченная"
        ],
        
        Запись2 = [
            Date        = #date(2022, 6, 1), 
            Строка_ID   = 104, 
            Значение    = 256, 
            Атрибут     = "Просроченная"
        ],
        
        // список записей
        lst = {Запись1, Запись2},
        
        // Применение функции к каждой записи
        ЗаполненнаяТаблица = 
            Table.InsertRows(
                Table.FromColumns(List.Transform(nms, each {}),  nms), 
                0, 
                List.Transform(lst, 
                    (rec as record) as record => Record.FromList( List.Transform( nms, (x)=> Record.FieldOrDefault(rec, x, null)), nms)
                )
            )
    in
        ЗаполненнаяТаблица

//  wqef
    = (tbl as table, tblShema as table, txt as text)=>
        Table.TransformColumnTypes(tbl, 
            List.Transform(
                Table.ToRecords(Table.SelectRows(tblShema, (x)=> x[Name] = "txt")[[Header],[TypeName]]),
                each { [Header], F[Type.FromText2]([TypeName]) }
            )
        )
        
    let
        Источник = Value.Metadata(PathFolder)[List],
        #"Преобразовано в таблицу" = Table.FromList(Источник, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
        #"Добавлен индекс" = Table.AddIndexColumn(#"Преобразовано в таблицу", "DataSet", 1, 1, Int64.Type),
        #"Строки с примененным фильтром" = Table.SelectRows(#"Добавлен индекс", each [DataSet] = DataSetNomer),
        #"Переименованные столбцы" = Table.RenameColumns(#"Строки с примененным фильтром",{{"Column1", "DataSetPath"}, {"DataSet", "DataSetN"}})
    in
        #"Переименованные столбцы"
    let
        f4 = (tableNames as list )=>
        let
            // Функция для безопасного извлечения таблицы по имени
            GetTable = (tableName as text) as table => 
                try Expression.Evaluate(tableName, #shared) otherwise null,

            // Создание записи с проверенными значениями таблиц
            rec = Record.FromList(
                List.Transform(tableNames, each GetTable(_)),
                List.Transform({1..List.Count(tableNames)}, each Text.From(_))
            )
        in rec,

        Источник = f4({"f1_Баланс", "f2_Баланс"})
    in
        Источник
//  fxLoadReport1
    fxLoadReport1 = 
    (rec as record, dataSetNomer)=>
    let
        // Пример записи с балансами, где в поле 3 может быть ошибка
        // rec = [
        //     1 = а1_Баланс, 
        //     2 = a2_Баланс, 
        //     3 = error,
        //     4 = a4_Баланс 
        // ],
        
        // Список полей, которые содержат ошибки
        fieldsWithErrors = List.Select(
            Record.FieldNames(rec), 
            each Record.HasFields(rec, _) and (try Record.Field(rec, _) otherwise null) = null),

        // Удаление полей с ошибками из записи
        cleanRec = Record.RemoveFields(rec, fieldsWithErrors),

        to = Record.FieldOrDefault( cleanRec, Text.From(dataSetNomer), null)
    in
        to

//  f3
    f3= ( tableNames as list )=>
    let
        // Список имен таблиц
        // tableNames = {"f1_Баланс", "f1_Баланс2"},

        // Функция для безопасного извлечения таблицы по имени
        GetTable = (tableName as text) as table =>
            let
                table = try Expression.Evaluate(tableName, #shared) otherwise null
            in
                table,

        // Создание записи с проверенными значениями таблиц
        balances = Record.FromList(
            List.Transform(tableNames, each GetTable(_)),
            List.Transform({1..List.Count(tableNames)}, each Text.From(_))
        )
    in
        balances

    let
        rec = Record.HasFields([ 1 = f1_ОПУ, 2 = a2_Баланс, 4 = a4_О21ПУ],1),
        
        // очищаем запись от ошибок в имени поля, если его не существует (нет такого запроса)
        cleanRec = 
            Record.FromList(
                List.Transform(
                    Record.FieldNames(rec), 
                    (x)=> try Record.Field(rec, x) otherwise null
                ),
                Record.FieldNames(rec)
            ),
        
        // возвращаем значение поля (это таблица) по ключу (номер)
        to = Record.FieldOrDefault( 
                cleanRec, 
                Text.From(1), 
                null
            )
    in
    to



//  https://gorilla.bi/power-query/records/
    // Output: "The Gorilla wants a Banana"
        Text.Format( 
            "The #[Subject] wants a #[Food].", 
            [ Subject = "Gorilla", Food = "Banana" ] 
        )

// 	проверка функции - последний шаг
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
        
//  заменить в таблице в первой колонке номер строки на сборный ключ из 3 колонок в конце (статотчет)
    let
        //  4 колонки: номер строки - Статья - ID1 - ID2 - ID3
            from = Excel.CurrentWorkbook(){[Name="спр_Статьи"]}[Content], 
        
        //  всю таблицу собираем построчно: первая колонка (как ID1.ID2.ID3) & все остальные колонки без первой колонки
            f=(x)=>{Text.Combine(List.Transform(List.LastN(x,3),Text.From),".")} & List.Skip(x), 
        
        //  имя новой первой колонки + имена колонок кроме первой
            nms = {"Номер"} & List.Skip(Table.ColumnNames(from)), 
        
        //  собираем колонки вместе
            to = Table.FromList(Table.ToRows(from),f, nms)
    in
    to

//  подход Михаила через списки!!!
    let
        from = Excel.CurrentWorkbook(){[Name="Таблица1"]}[Content],
        f=(x)=> // функция преобразования таблицы
            {   x{0},
                Text.Combine(List.RemoveItems(Text.Split(x{1},";"),{x{0}}),";")
            },
        to  = Table.ToList(from,f), // формирумем список списков из таблицы по функции построчно
        tbl = Table.FromList( // разворачиваем список списков в таблицу
                to,         // колонка с списками. Каждый список отдельная строка исзходной таблицы после применения функции
                (x)=>x,     // без преобразований
                {"a","b"}   // имена колонок
            ) 
    in
    tbl

//  Регулярные выражения (RegExp) в Power Query

    Позволю себе дополнить к части статьи к использованию регулярных выражений в Power Query через javascript.
    Перед тем как передавать текст для x, delim в функцию следует, чтобы избежать ошибок выполнить замены в тексте:
    Самым первым символ \ заменить на \\
    с учётом применённых кавычек для текста в js ' на \'
        #(lf) на \n
        #(cr) на \r
        #(tab) на \t
    Или всё сразу функцией
    
    let
        getJsSafeText = (pqText) => 
            List.Accumulate(
                {
                    {"\", "\\"}, 
                    {"'", "\'"}, 
                    {"#(tab)", "\t"}, 
                    {"#(lf)", "\n"}, 
                    {"#(cr)", "\r"}
                },
                pqText, 
                (acc, pair) => Text.Replace(acc, pair{0}, pair{1})
            ),
        example = getJsSafeText("'В кавычках'#(lf)перехос#(cr)и табуляция#(tab)\текст\")
    in
        example


//  "!" переименование в столбце, танк, "обычный словарь..."
    let
        tbl  =  Excel.CurrentWorkbook(){[Name="Конструкция"]}[Content],
        from =  Excel.CurrentWorkbook(){[Name="Таблица"]}[Content],

        dict =  Record.FromList(
                    tbl[Тип конструкции],
                    tbl[Формат]
                ),
        
        f=(x)=>Record.Field(dict,x),
        to   = Table.TransformColumns(from, {"Format",f})
    in
        to

//  не знаю
    AddedColumns = 
            F[fxAddMultiColumns](Join, {
                { "Quarter",         each "Q" & Number.ToText(Date.QuarterOfYear([Year])) & "-" & Text.End(Text.From(Date.Year([Year])),2) },
                { "СтатьяКод",       each [Код] & " " & [Показатель] },
                { "Уровень",         each try List.Count(List.Select(Text.ToList([Код]), (t)=>t=".")) otherwise 3},
                { "КлассКод",        each Text.From([Класс]) & " " & [Показатель], type text},
                { "ГруппаКод",       each Text.From([Группа]) & " " & [Показатель], type text},
                { "КатегорияКод",    each Text.From([Категория]) & " " & [Показатель], type text},
                { "ПодкатегорияКод", each Text.From([Подкатегория]) & " " & [Показатель], type text}
            }),
        typed = Table.TransformColumnTypes(AddedColumns,{{"Значение", type number}, {"Уровень", Int64.Type}}),

//  нарастающий убрать
    let
        Source = Table.Skip(Excel.CurrentWorkbook(){[Name="Таблица4"]}[Content], 2),
        f = (lst) => List.Generate(
            () => [i = 0, r = lst{0} ?? 0, rt = r],
            (x) => x[i] <= 3,
            (x) => [i = x[i] + 1, r = if lst{i} = null then 0 else lst{i} - x[rt], rt = x[rt] + r],
            (x) => x[r]
        ),
        to_list = Table.ToList(
            Source,
            (x) => {x{0}} & List.Combine(List.Transform(List.Split(List.Skip(x), 4), f))
        ),
        to_table = Table.FromList(to_list, (x) => x, Table.ColumnNames(Source))
    in
        to_table

//?  ------- ИЕРАРХИЯ -------
//  что то там про иерархию
    let
        Source = Excel.CurrentWorkbook(){[Name="Table3"]}[Content],
        #"Added Index" = Table.AddIndexColumn(Source, "Index", 0, 1),
        #"Pivoted Column" = Table.Pivot(Table.TransformColumnTypes(#"Added Index", {{"Level", type text}}, "en-US"), List.Distinct(Table.TransformColumnTypes(#"Added Index", {{"Level", type text}}, "en-US")[Level]), "Level", "Part Number", List.Sum),
        Lookup = Table.FillDown(#"Pivoted Column",{"0", "1", "2", "3", "4", "5", "6", "7", "8", "9"}),
        #"Added Custom1" = Table.AddColumn(#"Added Index", "Custom1", each Table.Column(Lookup, Text.From([Level]-1)){[Index]}),
        #"Added Custom2" = Table.AddColumn(#"Added Custom1", "Custom2", each Table.Column(Lookup, Text.From([Level]-2)){[Index]}),
        #"Added Custom3" = Table.AddColumn(#"Added Custom2", "Custom3", each Table.Column(Lookup, Text.From([Level]-3)){[Index]}),
        #"Added Custom4" = Table.AddColumn(#"Added Custom3", "Custom4", each Table.Column(Lookup, Text.From([Level]-4)){[Index]}),
        #"Added Custom5" = Table.AddColumn(#"Added Custom4", "Custom5", each Table.Column(Lookup, Text.From([Level]-5)){[Index]}),
        #"Added Custom6" = Table.AddColumn(#"Added Custom5", "Custom6", each Table.Column(Lookup, Text.From([Level]-6)){[Index]}),
        #"Added Custom7" = Table.AddColumn(#"Added Custom6", "Custom7", each Table.Column(Lookup, Text.From([Level]-7)){[Index]}),
        #"Added Custom8" = Table.AddColumn(#"Added Custom7", "Custom8", each Table.Column(Lookup, Text.From([Level]-8)){[Index]}),
        #"Added Custom9" = Table.AddColumn(#"Added Custom8", "Custom9", each Table.Column(Lookup, Text.From([Level]-9)){[Index]}),
        #"Removed Columns" = Table.RemoveColumns(#"Added Custom9",{"Index"})
    in #"Removed Columns"


//  NF самая статья про иерархию на дакс
    https://www.daxpatterns.com/parent-child-hierarchies/

    https://www.linkedin.com/pulse/rolling-up-hierarchical-data-three-different-ways-ferry-van-der-vorst/

    Using Calculated Columns (DAX)
    Using calculated columns are much simpler to implement, but unlike Power Query, the values are not transferred to tables when the table is copied, but the data is copied in the table where the calculated column resides. It could potentially make referencing the value in other table more complex than when using Power Query (as in Power Query, the data is already available in the table).
    In order for the data to be retrieved, we first need to have a calculated column that defines the hierarchy of the data - in this case the column is called Path:
    Path = PATH('Work Items'[ID],'Work Items'[Parent])
    When creating this, the value on each row would look something similar to this: 10001|1001|103|4, where the left most value before the first | indicates the top level ID and the number furthest to the right the ID of the item itself. The IDs in between make up the structure, so form lowest level (current item) to the top, the structure is based on IDs: 
    4 => 103 => 1001 => 10001, which in this case is Task 4 => Story 3 => Feature 1 => Epic 1 when looking at the titles.
    The structure for retrieval of the data in the calculated column is pretty much the same for all the columns below:
    Identify the ID for the item you want to populate, stored in variable "pid". We don't need to use SELECTEDVALUE as it is assessed against the row in the table.
    Identify the child items that contain the item you want to populate (via PATHCONTAINS in the FILTER as all child items contain the ID of the parent, grandparent, etc in the PATH)
    Find the totals of the effort (using SUM), minimum Start Date (using MIN) or latest End Date (using MAX) 
    So the Calculated Columns are as follows here:
    Effort Calculated Column
    Column - Effort = 
    VAR pid = 'Work Items'[ID] RETURN
    SUMX(FILTER('Work Items',PATHCONTAINS([Path],pid)),[Effort]) 
    Start Date Calculated Column
    Column - Start Date = 
    VAR pid = 'Work Items'[ID] RETURN
    MINX(FILTER('Work Items',PATHCONTAINS([Path],pid)),[Start Date])
    End Date Calculated Column
    Column - End Date = 
    VAR pid = 'Work Items'[ID] RETURN
    MAXX(FILTER('Work Items',PATHCONTAINS([Path],pid)),[End Date])
    Using Measures (DAX)
    Using measures are also simpler to implement, but unlike Power Query, the values are not stored in the tables and the data will be context sensitive against which the data is plotted. So it can be more difficult to validate that the data is correct.
    Similar to Calculated Columns, we also need to have a calculated column that defines the hierarchy of the data (here: Path). 
    The structure for retrieval of the data in the measures is pretty much the same for all the measures below:
    Identify the ID for the item you want to populate, stored in variable "pid"
    Identify the child items that contain the item you want to populate (via PATHCONTAINS as all child items contain the ID of the parent, grandparent, etc in the PATH)
    Find the totals of the effort (using SUM), minimum Start Date (using MIN) or latest End Date (using MAX) 
    ALLSELECTED is used to ensure the data s calculated over all rows and columns
    So the measures for the Effort, Start Date and End Date are as follows:
    Effort Measure
    Measure - Effort =
        VAR pid = SELECTEDVALUE ( 'Work Items'[ID] )
    
    RETURN
        CALCULATE (
            SUM ( 'Work Items'[Effort] ),
            ALLSELECTED ( 'Work Items' ),
            PATHCONTAINS ( 'Work Items'[Path], pid )
        ) 
    Start Date Measure
    Measure - Start Date =
    VAR pid = SELECTEDVALUE ( 'Work Items'[ID] )
    RETURN
        CALCULATE (
            MIN ( 'Work Items'[Start Date] ),
            ALLSELECTED ( 'Work Items' ),
            PATHCONTAINS ( 'Work Items'[Path], pid )
        ) 
    End Date Measure
    Measure - End Date =
    VAR pid = SELECTEDVALUE ( 'Work Items'[ID] )
    RETURN
        CALCULATE (
            MAX ( 'Work Items'[End Date] ),
            ALLSELECTED ( 'Work Items' ),
            PATHCONTAINS ( 'Work Items'[Path], pid )
        ) 


//  иерархия Миша
    let
        from = Excel.CurrentWorkbook(){[Name="Таблица1"]}[Content],
        add = Table.AddIndexColumn(from, "Index", 0, 1),
        nms = Table.ColumnNames(add)&{"Desire"},
        f=(x)=>[a=Table.ToColumns(x),
                b=List.Buffer(List.Zip({a{1},a{2}})),
                c=Table.RowCount(x),
                d=(x,y)=>[i=x+1,j=List.FirstN(y,b{x}{0}-1)&{b{x}{1}}],
                e=List.Generate(()=>d(0,List.Repeat({null},6)),
                                (x)=>x[i]<=c,
                                (x)=>d(x[i],x[j]),
                                (x)=>Text.Combine(x[j],".")),
                f=Table.FromColumns(a&{e},nms)][f],
        gr = Table.Group(add, "Category", {"tmp", each f(Table.Sort(_,"Index"))}),
        to = Table.Sort(Table.Combine(gr[tmp]),"Index")
    in
        to

//  level
    Level = [
        name = "Уровень",
        a = Table.DuplicateColumn(addColumns, "Код", name),
        b = Table.ReorderColumns(a, {"Код", name, "Наименование", "Секция", "Группа", "Класс", "Категория", "Подкатегория", "Вид", "Подвид", "ГруппаТоваров"}),
        c = Table.ReplaceValue(b,".","",Replacer.ReplaceText,{name}),
        d = Table.TransformColumns(c,{{name, Text.Length, Int64.Type}}),
        e = Table.TransformColumns(d, {{name, each _ - 1, type number}}),
        g = Table.RenameColumns(e,{{name, "Level"}})
    ][g]

//  Иерархия
    let
        src      = Source,
        maxLvl   = List.Max ( src[Level] ),
        recs     = List.Buffer ( Table.ToRecords ( src ) ),
        generate = List.Generate (
            () =>  [ i = 0,
                lvlValues = List.ReplaceRange ( List.Repeat ( { { null, null } }, maxLvl ), recs{i}[Level] - 1, 1, { { recs{i}[RowNR], recs{i}[RowNAme] } } )
            ],
            each [i] < List.Count ( recs ),
            each [
                i = [i] + 1,
                lvlValues = List.FirstN ( [lvlValues], recs{i}[Level] - 1 )
                    & { { recs{i}[RowNR], recs{i}[RowNAme] } }
                    & List.Repeat ( { { null, null } }, maxLvl - recs{i}[Level] )
            ],
            each if try recs{[i]}[Level] >= recs{[i] + 1}[Level] otherwise true 
                then List.Combine ( [lvlValues] ) 
                else null
        ),
        toTable = Table.FromRows (
            List.RemoveNulls ( generate ),
            List.Accumulate ( { 1 .. maxLvl }, {}, ( s, c ) => s & { "lvl_" & Text.From ( c ) & "_RowNR", "lvl_" & Text.From ( c ) & "_RowNAme" } )
        )
    in
        toTable

 
//  ! -------------------------------------------------------------------------------------
    a = Record.FieldValues(Source2{x}), //* получаем значения текущей строки
        b = Table.ColumnNames(Source2), //? получаем названия столбцов таблицы
        c = #table(2,List.Zip({b,a})),  //! создаем таблицу

    = Table.FromList(
                        Table.ToRows(КолонкуВначало),
                        (x)=>{Text.Combine(List.Transform(List.LastN(x,3),Text.From),".")} & List.Skip(x), 
                        // лучше отдельным шагом через f=(x)=>{Text.Combine...
                        {"Номер"} & List.Skip(Table.ColumnNames(КолонкуВначало))
                )

    = Table.ReplaceValue(#"Измененный тип", 
                        null, // b
                        null, // c
                        (a, b, c) => if List.Contains("в т.ч.", a) = true then "" else a,
                        {"Товар"})

    = Table.TransformColumns(
        #"Измененный тип", 
            {{"Товар", 
                    each List.ReplaceMatchingItems(
                            {_}, 
                            List.Buffer(List.Zip({ {"в т.ч","130"},{"+++","190"} }))
                    ){0}}} 
        )
//  ! fxCamelCaseHeaders -------------------------------------------------------------------------------------
    fxCamelCaseHeaders =[
        // Функция fxCamelCaseHeaders - поставить пробел перед каждой большой буквой
        // https://datachant-com.translate.goog/2018/02/14/split-camelcase-headers-m/?_x_tr_sl=auto&_x_tr_tl=ru&_x_tr_hl=ru
        // модно использовать для заголовков или самого текста
        (Source)=>
            let to_list = List.Buffer(Text.ToList(Source)),
                Transform = List.Transform(to_list, each if Text.Lower(_) = _ then _ else " " & _),
                Reassemble = Text.Combine(Transform)
            in  Reassemble	
        ]
//  ! fxSplitCamelCase
    fxSplitCamelCase = 
        // если не нужны пробелы когда аббревиатура, то функция другая
        // to = Table.TransformColumnNames(#"Previous Step", fxSplitCamelCase)
        // Функция - fxSplitCamelCase
        (Source) =>
        let    
            res = List.Accumulate(
                Text.ToList(Source),
                [result="", index=0, source=Source],
                fnAccumulator
            ),

        IsUpper = (txt) => txt <> "" and txt = Text.Upper(txt) and txt <> Text.Lower(txt),

        fnAccumulator =
            (state as record, current as text) as record =>
            let
                prevCharacter  = if state[index]=0 then "" else Text.At(state[source], state[index] - 1),
                prevCharacter2 = if state[index]<=1 then "" else Text.At(state[source], state[index] - 2),
                nextCharacter  = if state[index]= Text.Length(state[source]) - 1 then "" else Text.At(state[source], state[index] + 1),
            aggregatedResult = if state[index]=0 or current = "" then current
                    else
                        if  IsUpper(current) and
                            (not IsUpper(prevCharacter) or 
                            (IsUpper(prevCharacter2) and not IsUpper(nextCharacter))) then
                        state[result] & " " & current
                    else
                        state[result] & current,
                
                resultRecord = [result = aggregatedResult, index = state[index]+1, source = state[source]]

            in
                resultRecord
        in
            res[result]
	
//  Функция - fxSplitCamelCase вариант2
    // Shared by Sergey Lossev
    (Source) =>
        let
            to_list     = Text.ToList(Source),
            accum_chars = List.Accumulate(to_list, "", (sum, x) => sum & (if x = Text.Upper(x) then " " & x else x)),
            split 		= Text.Split(Text.Trim(accum_chars), " "),
            accum_words = List.Accumulate(split, "", (sum, x) => sum & (if Text.Length(x) = 1 then x else " " & x & " ")),
            replace 	= Text.Trim(Text.Replace(accum_words, "  ", " "))
        in
            replace
	
//  Finally
    /*  FnSplitCamelCase is a very handly custom function. It can also help you to handle CamelCase values in 
	columns – not just headers. For example, if you have CamelCase values in Column1, 
	you can click fx after Previous Step in Applied Steps, and paste the following formula:*/
	to = Table.TransformColumns(#"Previous Step",{{"Column1", fxSplitCamelCase, type text}})


	// ---------------------------------------------------------------------------------------	
	// Table_TransformColumnTypes - изменение типа всех столбцов (Чисто, Дата, Текст все остальные)
		let
			from = Table.FromRecords({[Наименование="тапки",Категория="обувь",ЦенаОпт=1000,ЦенаРозн=2000,Количество=100,СуммаОпт=100000,СуммаРозн=200000,Продавец="Вася",ДатаПоступления=44562,ДатаПродажи=44835,ДатаОтгрузки=44866,Примечание="обычные тапки"]}),
			nms  = Table.ColumnNames(from),
			dlst = List.Select(nms,(i)=>Text.Contains(i,"Дата")),
			nlst = List.Select(nms,(i)=>List.Contains({"Цена","Количество","Сумма"},i,(x,y)=>Text.Contains(y,x))),
			tlst = List.Difference(nms,dlst&nlst),
			f=(x,y)=>List.Transform(x,(i)=>{i,y}),
			transflst = f(dlst,Date.Type)&f(nlst,Number.Type)&f(tlst,Text.Type),
			to = Table.TransformColumnTypes(from,transflst)
		in
			to

//  Телеграмм. Чат по PQ
    // Файл Якушев (есть в папке PQ)
    // Ключевые слова: видимо не проще... типа того (доработка напильником на совести заказчика):
        let from = Excel.Workbook(File.Contents("C:\Users\muzyk\Desktop\якушев.xlsx"), null, true){0}[Data],
            nms1 = List.Buffer(List.RemoveMatchingItems(Record.FieldValues(from{1}),{"",null})),
            nms2 = List.Buffer(Record.FieldValues(from{2})),
            pos  = List.PositionOf(nms2,"Артикул",Occurrence.All),
            st   = pos{0},
            len  = pos{1}-pos{0},
            num  = len*List.Count(pos),
            nms3 = List.ReplaceRange(nms2,st,num,{"код"}&List.Transform(List.Range(nms2,pos{0},pos{1}-pos{0}),(x)=>"new_"&x)),
            g=(x)=>[a = List.ReplaceMatchingItems(List.Range(x,st,num),{{"",null}}),
                    d = Number.RoundDown(List.PositionOf(a,null,Occurrence.First,(x,y)=>x<>y)/len),
                    b = if d>=0 then {nms1{d}}&List.Range(a,d*len,len) else List.Repeat({null},len+1), 
                    c = List.ReplaceRange(x,st,num,b) ][c],
            lst = Table.ToList(Table.Range(from,3),g),
            to  = Table.FromList(lst,(x)=>x,nms3)
        in  to,
    
//  функцияЗамены
    функцияЗамены = [
        let func =   
        (
        TableWithTextColumn as table, 
        ColumnNameTextToReplace as text, 
        ReplacementsTable as table, 
        ColumnNameWordToReplace as text, 
        ColumnNameReplaceWith as text
        ) => 
        let
            Source = ReplacementsTable,
            CreateListOfLists = Table.AddColumn(
                Source, 
                "Liste", 
                each ({Record.Field(_, ColumnNameWordToReplace), Record.Field(_, ColumnNameReplaceWith)})
            ),
            Text = TableWithTextColumn,
            TurnTextToList = Table.AddColumn(
                Text, 
                "Custom", 
                each Text.Split(Record.Field(_, ColumnNameTextToReplace), " ")
            ),
            Replacements = Table.AddColumn(
                TurnTextToList, 
                "Changed Text Expected", 
                each Text.Combine(List.ReplaceMatchingItems([Custom], CreateListOfLists[Liste]), " ")
            ),
            Cleanup = Table.RemoveColumns(Replacements, {"Custom"})
        in
            Cleanup ,
        documentation = [
        Documentation.Name =  " Table.ReplaceMultiple.pq ",
        Documentation.Description = " Replaces multiple values at a time in a table column without recursion. ",
        Documentation.LongDescription = "  Replaces multiple values at a time in a table column without recursion: http://www.thebiccountant.com/2016/05/22/multiple-replacements-in-power-bi-and-power-query/ The <code>ReplacementsTable </code> must have the values to be replaced in the 1st column and the new value in the 2nd. ",
        Documentation.Category = " Table.ColumnOperations ",
        Documentation.Source = " http://www.thebiccountant.com/2016/05/22/multiple-replacements-in-power-bi-and-power-query/ . ",
        Documentation.Version = " 2.0 ",
        Documentation.Author = " Imke Feldmann ",
        Documentation.Examples = {[Description =  "  ",
        Code = " let 
            TableWithText = #table( {""Text""}, List.Zip( { {""the cat sat on the mat"" ,""the cat sat next to the dog"" ,""the dog chased the cat"" ,""the dog sat on the mat"" ,""the catamaran sails through the air""} } ) ), 
            ReplacementsTable = #table( {""Word To Replace"", ""Replace With""}, List.Zip( { {""cat"" ,""mat"" ,""dog"" ,""the"" ,""air""}, {""bear"" ,""chair"" ,""dragon"" ,""THE"" ,""water""} } ) ),
        // The query containing the function has to be called ""fnTable_ReplaceMultiple_pq""
            Result = fnTable_ReplaceMultiple_pq ( TableWithText , ""Text"", ReplacementsTable, ""Word To Replace"", ""Replace With"" ) 
        in 
            Result ",
        Result = " Changed Text Expected
        ———————
        THE bear sat on THE chair
        THE bear sat next to THE dragon
        THE dragon chased THE bear
        THE dragon sat on THE chair
        THE catamaran sails through THE water "]}]
        
        in  
        Value.ReplaceType(func, Value.ReplaceMetadata(Value.Type(func), documentation)) 
    ],
    test = [ // замены https://www.thebiccountant.com/2016/05/22/multiple-replacements-in-power-bi-and-power-query/
                let
                //Get table of word replacements
                Replacements = Excel.CurrentWorkbook(){[Name="Replacements"]}[Content],
                
                //Get table containing text to change
                TextToChange = Excel.CurrentWorkbook(){[Name="Text"]}[Content],
                
                //Get list of words to replace
                WordsToReplace = List.Buffer(Replacements[Word To Replace]),
                
                //Get list of words to replace them with
                WordsToReplaceWith = List.Buffer(Replacements[Replace With]),
                
                //A non-recursive function to do the replacements
                ReplacementFunction = (InputText)=> 
                let
                //Use List.Generate() to do the replacements
                DoReplacement = List.Generate(
                                    ()=> [Counter=0, MyText=InputText], 
                                    each [Counter]<=List.Count(WordsToReplaceWith), 
                                    each [Counter=[Counter]+1, 
                                            MyText=Text.Replace(
                                                    [MyText], 
                                                    WordsToReplace{[Counter]}, 
                                                    WordsToReplaceWith{[Counter]})], 
                                    each [MyText]),
                //Return the last item in the list that
                //List.Generate() returns
                GetLastValue = List.Last(DoReplacement)
                in
                GetLastValue,
                //Add a calculated column to call the function on every row in the table
                //containing the text to change
                Output = Table.AddColumn(TextToChange, "Changed Text List.Generate", each ReplacementFunction([Text])),
                #"Removed Columns" = Table.RemoveColumns(Output,{"Text"})
            in
                #"Removed Columns"
    ]		
//  отчет мясной отдел 1С
    let
        pack = Expression.Evaluate(Text.FromBinary(Web.Contents("https://raw.githubusercontent.com/buchlotnik/buchlotnik_functions/main/buchOfficePack")),#shared),
        file = File.Contents(Excel.CurrentWorkbook(){[Name="adres"]}[Content]{0}[Column1]),
        add = pack[fxExcelGetRowsAttributes](file){[Name="TDSheet"]}[Data],
        tr = Table.ReplaceValue(add,(x)=>x[Attributes],(x)=>if x[Attributes][outlineLevel]?="1" then null else x[Column1],Replacer.ReplaceValue,{"Attributes"}),

        unzip=Expression.Evaluate(Text.FromBinary(Web.Contents("https://raw.githubusercontent.com/buchlotnik/buchlotnik_functions/main/UnZip.pq")),#shared),
        bin = Binary.Buffer(File.Contents( pathToFile )),
        xml=Xml.Document(unzip(bin){[FileName="xl/worksheets/sheet1.xml"]}[Content]){0}[Value]{[Name="sheetData"]}[Value][Attributes],
        val=List.Transform(xml,(x)=>x{[Name="ht"]}?[Value]?),
        nms=List.Transform(xml,(x)=>x{[Name="r"]}?[Value]?),
        dict=Record.FromList(val,nms),
        sh = Excel.Workbook(bin,false){0}[Data],
        add = Table.AddIndexColumn(sh, "Уровень", Number.From(nms{0}),1),
        to =
            Table.AddColumn(
                add,
                "Группа",
                ( x ) => if Record.FieldOrDefault( dict, Text.From( x[ Уровень ] ) ) = "12.95" then x[ Column1 ] else null,
                type text
            ),

//  проба пера. Отчетность из интернета
    let
        // полдключение к отчетности на сайте (Конта спа за 2022 г.)
        URL    = "https://epfr.gov.by/file/111430/content",
        Source = Pdf.Tables(Web.Contents(URL), [Implementation="1.3"]),
        Filter = Table.SelectRows(Source, each ([Kind] = "Page"))[[Id],[Data]],
        
        // Функция очистки БАЛАНСА
        f1=(x)=> let 
                    // фильтуруем строки по значению колонки4 - первый знак цифра
                    f=(y)=> try List.ContainsAny ( { Text.Start(y[Column4],1) },{"0".."9"},Text.Contains) otherwise null,
                    a = Table.SelectRows(x, f),
                    // чистим таблицу загруженной функцией
                    b = Load("fxClear")(a, "", true, true),
                    c = Table.RenameColumns(b, List.Zip({ Table.ColumnNames(b), {"Статья","Строка","На начало","На конец"} })),
                    d = Table.SelectRows(c, each Text.Length([Строка]) = 3),
                    // меняет тип данных в колонках 2 и дальше на числовые
                    n = Table.ColumnNames(d), Skip = 1,
                    t = Table.TransformColumnTypes(d, 
                            { {n{0}, type text} } & List.Transform(List.Skip(n, Skip), (x)=> {x, Int64.Type})),
                    // убираем ошибки в колонках 2+
                    w = Table.ReplaceErrorValues(t, 
                            List.Transform(List.Skip(n, Skip), (x)=> {x,null})) // {имя, null}
                in w ,
                            
        f2=(x)=> Table.Skip(x, 2),
        
        // колонка 6
        f3=(x)=> let f=(y)=> try List.ContainsAny ( { Text.Start(y[Column6],1) },{"0".."9"},Text.Contains) and y[Column4] <> "2" otherwise null
                in  Load("fxClear")(Table.SelectRows(x, f),"",1, 1),
        
        to = Table.AddColumn(Filter, "NewColumn", each 
                    if [Id] = "Page001" then f2( [Data] ) // Баланс стр 1
                else if [Id] = "Page002" then f2( [Data] ) // Баланс стр 2
                else if [Id] = "Page003" then f3( [Data] ) // Отчет о прибылях
                else [Data]
        )
    in
        to

//  !!! Сохранение таблиц Power BI в локальную базу данных с поддержкой инкрементального обновления Назаров
    // обновление запросов и копирование в БВ
    https://github.com/meta110/powerbi/blob/master/sqliteproxy/pbi2sqlite.m
    let
        // Новая версия файла находится здесь https://github.com/meta110/powerbi/blob/master/sqliteproxy/pbi2sqlite.m

        // Таблица преобразований типов колонок в SQLite и обратно
        // например, даты можно хранить в виде целочисленного таймштампа или текстом
        // допустимые типы https://www.sqlite.org/datatype3.html#storage_classes_and_datatypes
        typeConversion = #table( 
            type table [ Name = text, Type = type, Value = text, Transform = function, Revert = function ], {
            { "Percentage.Type",Percentage.Type,"REAL",   Number.From,    each Percentage.From( _, LOCALE ) },
            { "Int64.Type",     Int64.Type,     "INTEGER",Int64.From,     each Int64.From( _, LOCALE ) },
            { "Date.Type",      Date.Type,      "INTEGER",DateTime2Timestamp, each Date.From( Timestamp2DateTimeZone( _ ) ) },
            { "DateTime.Type",  DateTime.Type,  "INTEGER",DateTime2Timestamp, each DateTime.From( Timestamp2DateTimeZone( _ ) ) },
            { "Text.Type",      Text.Type,      "TEXT",   each _,         each _ },
            { "Duration.Type",  Duration.Type,  "TEXT",   Text.From,      Duration.From },
            { "Currency.Type",  Currency.Type,  "REAL",   Number.From,    each Currency.From( _, LOCALE ) },
            { "List.Type",      List.Type,      "TEXT",   Value.ToText,   Json.Document },
            { "Number.Type",    Number.Type,    "REAL",   Number.From,    each Number.From( _, LOCALE ) },
            { "Any.Type",       Text.Type,      "TEXT",   each _,         each _}
            } ),

        PyScript = "    #(cr)#(lf)import os#(cr)#(lf)import json#(cr)#(lf)import sqlite3#(cr)#(lf)#(cr)#(lf)def test_path(paths):#(cr)#(lf)    try:#(cr)#(lf)        paths = json.loads( paths )#(cr)#(lf)        for path in paths:#(cr)#(lf)            abspath = os.path.abspath( path )#(cr)#(lf)            dirname = os.path.dirname( abspath )#(cr)#(lf)            if ( os.path.exists( dirname ) ):#(cr)#(lf)                return abspath#(cr)#(lf)    except: return False#(cr)#(lf)#(cr)#(lf)class Config(object):#(cr)#(lf)    def __init__(self,df): #df is a pd.DataFrame#(cr)#(lf)        df = df.set_index('Name',drop=True,inplace=False)#(cr)#(lf)        self.abspath = test_path( df.loc['db_path']['Value'] )#(cr)#(lf)        self.cwd = os.getcwd()#(cr)#(lf)        self.table_name = df.loc['table_name']['Value']#(cr)#(lf)        self.schema_name = self.table_name + '_schema'#(cr)#(lf)        try:#(cr)#(lf)            self.key_columns = json.loads(df.loc['key_columns']['Value'])#(cr)#(lf)        except:#(cr)#(lf)            self.key_columns = ''         #(cr)#(lf)        self.raise_error = df.loc['raise_error']['Value'] == 'True'#(cr)#(lf)#(cr)#(lf)#test = Config(config)#(cr)#(lf)#%%#(cr)#(lf)    #(cr)#(lf)def is_table_exists(table):#(cr)#(lf)    '''Проверяю через мастер-таблицу, что нужная таблица есть в БД'''#(cr)#(lf)    with con:#(cr)#(lf)        test = con.execute(f""SELECT * FROM sqlite_master WHERE type='table' AND name='{table}';"").fetchall()#(cr)#(lf)    return len(test) > 0#(cr)#(lf)#(cr)#(lf)#(cr)#(lf)def create_table( table_name, df, table_key ):#(cr)#(lf)    '''Создаю таблицу и настраиваю поля'''#(cr)#(lf)    tmpl = '''#(cr)#(lf)        DROP TABLE IF EXISTS ""{table_name}"";    #(cr)#(lf)        CREATE TABLE ""{table_name}"" (#(cr)#(lf)            {fields},#(cr)#(lf)            {key}#(cr)#(lf)        );#(cr)#(lf)    '''#(cr)#(lf)    column_tmpl = '""{name}"" {type}'#(cr)#(lf)    key_tmpl = 'PRIMARY KEY ({table_key})'#(cr)#(lf)    # заполняю шаблон для колонок#(cr)#(lf)    column_statements = [#(cr)#(lf)        column_tmpl.format( name = key, type = value )#(cr)#(lf)        for key, value in schema[['Name','Value']].values #(cr)#(lf)    ] #(cr)#(lf)    # закавычиваю ключевые колонки#(cr)#(lf)    key_statement = key_tmpl.format(#(cr)#(lf)        table_key = ', '.join( [ '""' + key + '""' for key in table_key ] ) )#(cr)#(lf)    #(cr)#(lf)    # заполняю запрос#(cr)#(lf)    query = tmpl.format(#(cr)#(lf)        table_name = table_name,#(cr)#(lf)        fields     = ',\n            '.join( sorted( column_statements ) ),#(cr)#(lf)        key        = key_statement#(cr)#(lf)    )#(cr)#(lf)    with con:#(cr)#(lf)        con.executescript(query)#(cr)#(lf)    con.commit()#(cr)#(lf)    #(cr)#(lf)    return query#(cr)#(lf)#(cr)#(lf)#(cr)#(lf)def read_df(table):#(cr)#(lf)    ''' Забирает таблицу из БД в датафрейм '''#(cr)#(lf)    with con:#(cr)#(lf)        return pandas.read_sql( f'SELECT * FROM ""{table}""', con )#(cr)#(lf)#(cr)#(lf)#(cr)#(lf)def write_df(table,data):#(cr)#(lf)    ''' Записывает датафрейм в БД '''#(cr)#(lf)    with con:#(cr)#(lf)        return data.to_sql(table,con,index=False, if_exists='replace')#(cr)#(lf)#(cr)#(lf)#(cr)#(lf)def upsert(table,df_columns,keycolumn):#(cr)#(lf)    '''Строит UPSERT запрос'''#(cr)#(lf)    #df_columns = list(df) #list(map(get_ch_field_name, fields)) #(cr)#(lf)    values = 'VALUES({})'.format(','.join(['?' for col in df_columns]))#(cr)#(lf)    columns = ','.join([ '""' + column + '""' for column in df_columns ])#(cr)#(lf)#(cr)#(lf)    for key in keycolumn:    #(cr)#(lf)        df_columns.remove(key) # модифицирует сам список, поэтому возвращает None#(cr)#(lf)    #(cr)#(lf)    update_list = ['""{}"" = EXCLUDED.""{}""'.format(col, col) for col in df_columns]#(cr)#(lf)    update_str = ','.join(update_list)#(cr)#(lf)    insert_stmt = 'INSERT INTO ""{}"" ({}) {} ON CONFLICT ({}) DO UPDATE SET {}'.format(#(cr)#(lf)        table, columns, values, ','.join([ '""' + column + '""' for column in keycolumn]), update_str)#(cr)#(lf)#(cr)#(lf)    return insert_stmt#(cr)#(lf)#(cr)#(lf)#(cr)#(lf)def upload(table, df, keycolumn):#(cr)#(lf)    '''Загружает данные в SQLite'''#(cr)#(lf)    insert_stmt = upsert(table,list(df),keycolumn)#(cr)#(lf)    with con:#(cr)#(lf)        con.executemany(insert_stmt, df.values.tolist())#(cr)#(lf)    #(cr)#(lf)    con.commit()        #(cr)#(lf)#(cr)#(lf)#(cr)#(lf)class Schema(object):#(cr)#(lf)    def __init__(self,df):#(cr)#(lf)        self.exists = not df.empty#(cr)#(lf)        self.schema = df#(cr)#(lf)        self.should_init_db = False#(cr)#(lf)        self.incompatible_fields = False#(cr)#(lf)        if ( self.exists ):#(cr)#(lf)            self.cleaned = df.drop(columns='Position').sort_values('Name').reset_index(drop=True)#(cr)#(lf)#(cr)#(lf)#(cr)#(lf)def update_schema( one: Schema, another: Schema ):#(cr)#(lf)    if ( another.exists and one.exists ):#(cr)#(lf)        if one.cleaned.equals( another.cleaned ):#(cr)#(lf)            one.schema = another.schema#(cr)#(lf)            one.difference = ''#(cr)#(lf)        else:#(cr)#(lf)            one.incompatible_fields = True#(cr)#(lf)            diff = pandas.concat( [ one.cleaned, another.cleaned ] ).drop_duplicates( keep = False )#(cr)#(lf)            one.difference = diff[['Name', 'TypeName']]#(cr)#(lf)    elif ( another.exists ):#(cr)#(lf)        one.schema = another.schema#(cr)#(lf)        one.exists = True#(cr)#(lf)        one.should_init_db = True#(cr)#(lf)#(cr)#(lf)#(cr)#(lf)def prepare_db(table_name, df, key_columns, #(cr)#(lf)             schema_name, schema, raise_error):#(cr)#(lf)    #(cr)#(lf)    existing_schema = read_df( schema_name ) if is_table_exists( schema_name ) else pandas.DataFrame([])#(cr)#(lf)    existing_schema = Schema(existing_schema)#(cr)#(lf)    pretending_schema = Schema(schema)#(cr)#(lf)    update_schema( existing_schema, pretending_schema)#(cr)#(lf)#(cr)#(lf)    if not( existing_schema.exists ):#(cr)#(lf)        raise Exception(f'Данные для загрузки отсутствуют. Таблица {table_name} не существует и не может быть создана из-за отсутствия данных. Укажите другую таблицу или передайте данные для загрузки.')#(cr)#(lf)  #(cr)#(lf)    if ( existing_schema.incompatible_fields ):#(cr)#(lf)        if ( raise_error ):#(cr)#(lf)            raise Exception('Таблица ""{}"" существует в БД, её колонки отличаются от новых. Обнаружены отличия названий колонок/типов: ""\n{}"". Укажите другую таблицу или отключите проверку, чтобы пересоздать таблицу с новыми данными.'.format(#(cr)#(lf)                table_name, #(cr)#(lf)                existing_schema.difference.to_csv(index=False,sep=' ',line_terminator='\n',header=False)#(cr)#(lf)                ))#(cr)#(lf)        else:#(cr)#(lf)            existing_schema = pretending_schema#(cr)#(lf)            existing_schema.should_init_db = True#(cr)#(lf)            #(cr)#(lf)    if ( existing_schema.should_init_db ):#(cr)#(lf)        create_table( table_name, df, key_columns )#(cr)#(lf)        write_df( schema_name, schema )#(cr)#(lf)        #(cr)#(lf)    return existing_schema.schema#(cr)#(lf)    #(cr)#(lf)#%%#(cr)#(lf)  #(cr)#(lf)config = Config(config)  #(cr)#(lf)#(cr)#(lf)if not( config.abspath  ):#(cr)#(lf)    raise Exception( 'Указан путь к несуществующей папке. Файл БД не может быть создан или прочитан.' )#(cr)#(lf)#(cr)#(lf)try:#(cr)#(lf)    con = sqlite3.connect( config.abspath )#(cr)#(lf)except:#(cr)#(lf)    raise Exception(f'{config.abspath=}')#(cr)#(lf)#(cr)#(lf)#raise Exception('schema {}'.format(schema))#(cr)#(lf)#(cr)#(lf)schema = prepare_db( config.table_name, df1, config.key_columns, #(cr)#(lf)             config.schema_name, schema, config.raise_error )#(cr)#(lf)     #(cr)#(lf)#(#)(schema.sort_values('Name').reset_index(drop=True).equals(existing_schema.sort_values('Name').reset_index(drop=True))):#(cr)#(lf)if not( df1.empty ):#(cr)#(lf)    upload(config.table_name, df1, config.key_columns)#(cr)#(lf)#(cr)#(lf)result = read_df( config.table_name ) #pandas.DataFrame([ 'Данные загружены в БД' ])#(cr)#(lf)#(cr)#(lf)con.close()#(cr)#(lf)#(cr)#(lf)config = pandas.DataFrame.from_dict(vars(config),orient='index').reset_index(level=0)",

        // Вспомогательные переменные
        LOCALE = "en-US",
        EMPTY_TABLE = #table(1,{}),
        UNIX = #datetimezone( 1970, 1, 1, 0, 0, 0, 0, 0 ),

        // Функция преобразования объекта PQ в текст
        Value.ToText = each Text.FromBinary( Json.FromValue( _ ) ),
        
        // Функции преобразования дат в timestamp и обратно
        DateTime2Timestamp = each Duration.TotalSeconds( DateTimeZone.From(_) - UNIX ),
        Timestamp2DateTimeZone = each UNIX + #duration(0,0,0, Int64.From( _, LOCALE ) ),

    cache = ( 
            DataBasePath as text,
            TableName as text,
            optional Data as nullable table,
            optional KeyColumns as list,
            optional RaiseError as logical
        ) => let
        
        // Подготовка конфигурации БД
        db_path = List.Transform( Text.Split( DataBasePath, "," ), Text.Trim ),
        
        config = [
            db_path    = Value.ToText( db_path ),
            table_name = TableName,
            key_columns = Value.ToText( KeyColumns ),
            raise_error = Text.Proper( Text.From( RaiseError ?? true ) ) 
            ],

        // Подготавливаю таблицу преобразований
        combineColumns = Table.CombineColumnsToRecord( 
            typeConversion,
            "Value",
            List.RemoveItems( Table.ColumnNames(typeConversion), {"Name"} ) 
            ),

        asRecord = Record.FromTable(combineColumns),

        // Генерирую тип колонок
        recordType = Type.ForRecord( 
            Record.RemoveFields( 
                Type.RecordFields( Type.TableRow( Value.Type( typeConversion ) ) ), 
                {"Name"} 
            ), false ),
        
        // строки с ошибками
        errRows = Table.SelectRowsWithErrors( Table.AddIndexColumn( Data, "Indx", 1 ) ),

        // Подготовка схемы таблицы
        Source = Table.Schema( Data ),

        #"Added Custom" = Table.AddColumn(Source, "SQLType", 
            each Record.Field( asRecord, [TypeName] ), recordType ),
        #"Expanded SQLType" = Table.ExpandRecordColumn(#"Added Custom", "SQLType", {"Value", "Transform"}, {"Value", "Transform"}),
        dataTransformations = Table.ToRows( Table.SelectColumns( #"Expanded SQLType", {"Name", "Transform"} ) ),
        // в индексах не должно быть null, заменяю их на 0 - это не всегда корректно. Лучше проверять индексные колонки на null и возбуждать ошибку при их наличии
        //fix_null = Table.ReplaceValue( Data, null, 0, Replacer.ReplaceValue, KeyColumns ),
        data = Table.TransformColumns( Data, dataTransformations ),
        schema = Table.SelectColumns(#"Expanded SQLType",{"Name", "Position", "TypeName", "Value"}),

        PyParams = [
            df1     =   if Data = null then EMPTY_TABLE else data, 
            schema  =   if Data = null then EMPTY_TABLE else schema, 
            config  =   Record.ToTable(config)
        ],
        
        // Запуск Python
        #"Run Python script" = Python.Execute(PyScript,PyParams),
        
        // Поиск ошибок выполнения
        run = try #"Run Python script",
        result = if run[HasError] then error run[Error] else run[Value],

        // Разбираю схему данных
        loadedSchema = result{[Name="schema"]}[Value],
        #"Sorted Rows" = Table.Sort(loadedSchema,{{"Position", Order.Ascending}}),
        #"Added Custom1" = Table.AddColumn(#"Sorted Rows", "Values", 
            each Record.Field( asRecord, [TypeName] ), recordType ),
        #"Expanded Values" = Table.ExpandRecordColumn(#"Added Custom1", "Values", {"Revert", "Type"}, {"Revert", "Type"}),
        #"Removed Columns" = Table.RemoveColumns(#"Expanded Values",{"Value", "TypeName", "Position"}),
        fix_empty = Table.TransformColumns( #"Removed Columns", { "Revert", each (t) => if ( t = null or t = "" ) then null else _(t) } ),
        transformations = Table.ToRows( fix_empty ),
        
        // Преобразование загруженной таблицы к исходному виду
        loadedTable = result{[Name="result"]}[Value],
        transform = Table.TransformColumns(loadedTable,transformations),
        return = Table.ReorderColumns(transform,#"Sorted Rows"[Name])

        in 	//Source /*
            if Data <> null and KeyColumns = null then error "Укажите ключевые колонки"
            else if Data <> null and not List.ContainsAll( Table.ColumnNames( Data ), KeyColumns ) 
                then error "Названия ключевых колонок должны совпадать с колонками таблицы"
            else if Data <> null and not Table.IsEmpty( errRows ) then error "Устраните ошибки в исходной таблице. Номера строк, содержащих ошибки: " & Text.Combine( List.Transform( errRows[Indx], Text.From ), "," )
            else return meta ( config ) //*/
    in
        cache        
//  функция pqVLOOKUP
    [   функция pqVLOOKUP
        /* Пример использования */
        /* = pqVLOOKUP(2, Head1, 2, null) */

        let pqVLOOKUP = 
            (   lookup_value as any, 
                table_array as table, 
                col_index_number as number, 
                optional approximate_match as logical ) as any =>
            let
                /*Provide optional match if user didn't */
                matchtype = if approximate_match = null
                            then true
                            else approximate_match,

                /*Get name of return column */
                Cols            = Table.ColumnNames(table_array),
                ColTable        = Table.FromList(Cols, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
                ColName_match   = Record.Field(ColTable{0},"Column1"),
                ColName_return  = Record.Field(ColTable{col_index_number - 1},"Column1"),

                /*Find closest match */
                SortData        = Table.Sort(table_array,{{ColName_match, Order.Descending}}),
                RenameLookupCol = Table.RenameColumns(SortData,{{ColName_match, "Lookup"}}),
                RemoveExcess    = Table.SelectRows(RenameLookupCol, each [Lookup] <= lookup_value),
                ClosestMatch    =   if Table.IsEmpty(RemoveExcess)=true 
                                    then "#N/A" 
                                    else Record.Field(RemoveExcess{0},"Lookup"),

                /*What should be returned in case of approximate match? */
                ClosestReturn   =   if Table.IsEmpty(RemoveExcess)=true 
                                    then "#N/A" 
                                    else Record.Field(RemoveExcess{0},ColName_return),

                /*Modify result if we need an exact match */
                Return = 
                    if matchtype=true
                    then ClosestReturn
                    else
                        if lookup_value = ClosestMatch
                        then ClosestReturn
                        else "#N/A"
            in Return
        in pqVLOOKUP
        ]

//  функция fxReplaceDictReWrite
    [   функция fxReplaceDictReWrite
            // Замена значений в колонке по справочнику с перезаписью столбца
            // Источник = fxReplaceDictReWrite(Производство, "Предприятия", "Код_предприятия", "Название_исходное", "Предприятие")

            (   Источник as table, 
                Справочник as text, 
                СпрКолонкаЧто as text, 
                СпрКолонкаНаЧто as text, 
                ИмяКолонкиИсточника as text)=>

            let
                // Таблица замены: Имя, Колонка "Что", Колонка "НаЧто" 
                Dict     = Excel.CurrentWorkbook(){[Name=Справочник]}[Content],
                BadName  = List.Buffer(Table.ToColumns(Table.SelectColumns(Dict,{СпрКолонкаЧто}))){0},
                GoodName = List.Buffer(Table.ToColumns(Table.SelectColumns(Dict,{СпрКолонкаНаЧто}))){0},

                // Результат замены
                Result = 
                    Table.TransformColumns(
                        Источник, 
                        {
                            {ИмяКолонкиИсточника, each try GoodName{List.PositionOf(BadName, _)} otherwise _}
                        }
                    )
            in 
                Result
        ]

//  функция - fxReplaceDictNewCol
    [   функция - fxReplaceDictNewCol

        // функция замены значений в колонке таблице по справочнику
        // Источник - таблица где менять какойто столбец
        // Словарь - имя таблицы с указанием колонками "Что" и "НаЧто" менять.
        // Пример использования:

        (   Источник as table, 
            ИмяСправочника as text, 
            ИмяКолонкиИсточника as text, 
            ИмяНовойКолонки as text
        )=>
            let
                //  Таблица замены. Из нее нужны только 2 столбца - Что и НаЧто заменить
                    Dict = Excel.CurrentWorkbook(){[Name=ИмяСправочника]}[Content],
                    ColNames = Table.ColumnNames(Dict),

                //  Удаляем колонки кроме двух: Что менять + На что менять. Иначе будет ошибка в функции List.ReplaceMatchingItems
                    DelColumn  = Table.SelectColumns(Dict, {ColNames{0}, ColNames{1}}),

                //  Формируем список замены и буферизируем его для ускорения
                    Lookup = List.Buffer(List.Zip(Table.ToColumns(DelColumn))),
                    
                //  Формируем список (ID показателя), которыq надо заменить на правильное название
                    Corrected = 
                        List.ReplaceMatchingItems(
                            Table.ToColumns(
                                Table.SelectColumns(Источник, {ИмяКолонкиИсточника} )
                            ){0}, 
                            Lookup
                        ),
                //  Результат
                    Result = 
                        Table.FromColumns(
                            Table.ToColumns(Источник) & {Corrected}, 
                            Table.ColumnNames(Источник) & {ИмяНовойКолонки}
                    )
            in Result
        ]

//  #"04-EM-Table.Join" - аналоги ВПР
    let
        Source = fSales,
        #"Changed Type" = Table.TransformColumnTypes(Source,{{"Date", type date}, {"Товар", type text}, {"Units", Int64.Type}}),
        #"04-EM-Table.Join"                 = Table.Join(#"Changed Type","Товар",dProduct,"Product"),
        #"01-EM-Record.Field-RowColumn"     = Table.AddColumn(#"04-EM-Table.Join", "Price1",                    each Record.Field(dProduct{[Product=[Товар]]},"Price"), type number),
        #"02-EM-List.PositionOf-ColumnRow"  = Table.AddColumn(#"01-EM-Record.Field-RowColumn", "Price2",        each dProduct[Price]{List.PositionOf(dProduct[Product],[Товар])},type number),
        #"03-EM-AllSytax-RowColumn"         = Table.AddColumn(#"02-EM-List.PositionOf-ColumnRow", "Price3",     each dProduct{[Product=[Товар]]}[Price],type number),
        #"05-AM-Table.SelectRows-RowColumn" = Table.AddColumn(#"03-EM-AllSytax-RowColumn", "Discount1",         each List.Last(Table.SelectRows(dDiscount, (IT) => IT[Units] <= [Units])[Discount]), type number),
        #"06-AM-List.Select-ColumnRow"      = Table.AddColumn(#"05-AM-Table.SelectRows-RowColumn", "Discount2", each dDiscount[Discount]{List.Count(let U = [Units] in List.Select(dDiscount[Units], each _ <= U))-1}, type number)
    in
        #"06-AM-List.Select-ColumnRow"

//  создаем пустую таблицу по имени отчета, чтобы связи с календарем не пропадала
    form.BlankTable   = 
		(	tbl as table, 			// таблица со схемами таблиц отчетов
			REPORT_NAME as text		// имя отчета
		) =>
			let
				//  REPORT_NAME = "odds",
				
				//	если схема всех отчетных таблиц представлена Record
					nms  = Record.Field(tbl, REPORT_NAME)[Header],
				
				//	если схема всех отчетных таблиц представлена Table
					nms2  = Table.Column(
								Table.SelectRows(tbl, each [Атрибут] = REPORT_NAME)
								{0}[Количество], 	// первая строка колонки [Количество] в основной таблице 
								"Name" 				// имя колонки с названиями колонок в подтаблице
							),

				ПустыеКолонки1 = List.Transform(nms, each {}),              // пустая таблица - строк нет
				ПустыеКолонки2 = List.Repeat( {{""}}, List.Count(nms) ),    // пустая таблица - строка одна пустая
				
				from = Table.FromColumns(ПустыеКолонки1, nms),              // создаем таблицу
				
				// добавляем строку с датой, чтобы не рушилась связь с календарем
				Данные = {Record.FromList( 
							List.Transform(nms, 
								each if _ = "Date" 
									then #date(2023, 12, 1) 
									else null 
							), 
						nms) },

				fromOneRows = Table.InsertRows(from, 0, Данные),
				
				from5Columns = Table.SelectColumns(
								fromOneRows, 
								List.FirstN(Table.ColumnNames(fromOneRows),5) // берем первые 5 колонок
							),
				
				NewTable = 
					let create = 
							Table.FromRecords({[
								Date = #date(2024, 7, 9),  
								Company = null,
								DataSet = null,
								Report_ID = null
							]}),
						TypedTable = Table.TransformColumnTypes(create, {{"Date", type date}})
					in TypedTable,

				form.SetType      = // добавление таблицы после импорта, типизация столбца по схеме в таблице
					(tbl as table, tblShema as record, reportName as text)=>
						let 
							f=(x)=>
								List.Transform(
									Table.ToRecords( // список Record-ов
										Record.Field(tblShema, reportName) 
											[ [Header], [TypeName] ] // таблица из содержимого Record с двумя полями
									),
									each { [Header], F[form.TypeFromText]([TypeName]) }
								),
							to = Table.TransformColumnTypes(fromOneRows, f)
						in to,

				// типизируем столбцы
				typed = form.SetType(fromOneRows, tbl, REPORT_NAME)
			in
				// try typed 
				// otherwise NewTable
				typed,        