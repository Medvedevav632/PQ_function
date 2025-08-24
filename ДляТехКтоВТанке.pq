[   #ПолезныеСсылки

    Всем добра! Выпрыгнул из сумрака и привел к общему знаменателю старый пост (который удалил) чтобы источники лучше искались нашим ботом, а также добавил ссылочку на Бена нашего Грибаудо.
    PQ:
    01. Спецификация языка PowerQuery M - это фундамент, букварь, без него дальше тяжело;
    01a. M language specification - оригинал этого фундамента на английском (@buchlotnik прям настаивает на чтении этой версии);
    02. Справочник по языку формул Power Query M;
    03. finalytics.pro простым языком для начинающих;
    04. blog by Maxim Zelensky простым языком, но не для начинающих;
    05. Товарищ Excel кратко, емко;
    06. planetaexcel.ru обстоятельно и с примерами;
    07. Книга "Скульптор данных в Excel с Power Query";
    08. Кен Пульс и Мигель Эскобар. "Язык М для Power Query" русский перевод отличной книги;
    09. Приручи данные с помощью Power Query в Excel и Power BI второе издание шикарной книги на русском от Кен Пульс и Мигель Эскобар.
    10. BI блог Максима Уварова перевод статей Криса Вебба и разные коннекторы..;
    11. The BIccountant грамотный бух рассказывает про BI;
    12. Chris Webb's BI Blog Chris Webb's BI Blog Мега дядька рассказывает обо всем на свете. Просто кладезь!;
    13. The Environment concept in M for Power Query and Power BI Desktop, Part 1 Концептуальный и обстоятельный разбор с погружением;
    14. Промокоды от переводчика Александр Гинько на отличные книги;
    15. Power Query Formatter Красота спасет мир... и мои глаза.

    DAX:
    01. Основные сведения о DAX в Power BI Desktop опять фундамент;
    02. Articles - SQLBI Мега дядьки про все подряд;
    03. Patterns – DAX Patterns Мега дядьки про расчеты стандартных показателей в аналитике. ABC и вот это вот все;
    04. BI блог Антона Будуева. Разбор формул DAX по-русски;
    05. Анализ данных при помощи Microsoft Power BI и Power Pivot для Excel;
    06. Подробное руководство по DAX;
    07. Шаблоны DAX;
    08. DAX Formatter by SQLBI Красота спасет мир... и мозг тех, кто читает ваши формулы.
    ]
   
[   Комплексный обзор всех функций класса Splitter:
    
    1. Splitter.SplitByNothing – смотрим на сплиттер, который «ничего не делает» )
    2. Splitter.SplitTextByWhitespace – обсуждаем, что такое Whitespace и зачем нужен аргумент quoteStyle
    3. Splitter.SplitTextByDelimiter, Splitter.SplitTextByAnyDelimiter – обсуждаем, только ли в количестве разделителей разница (спойлер – нет)
    4. Splitter.SplitTextByEachDelimiter – разбираемся зачем он такой нужен (кто плачет по регуляркам – он нужен)
    5. Splitter.SplitTextByCharacterTransition – часто фигурирует в коде, поэтому просто закрепим как/зачем/почему
    6. Splitter.SplitTextByRepeatedLengths, Splitter.SplitTextByLengths – делим текст по длинам фрагментов
    7. Splitter.SplitTextByPositions, Splitter.SplitTextByRanges – делим текст по позициям элементов в нём
    ]
[   Splitter 1 - Splitter.SplitByNothing или сплиттер, который "ничего не делает"
    #АнатомияФункций - Splitter.SplitByNothing

    Итак, начинаем разбор (https://youtu.be/1jetvaOY6oM) с самого простого сплиттера. 
    В целом все сплиттеры представляют собой замыкания (https://t.me/pbi_pq_from_tank/41), т.е. в скобках мы передаём аргументы и на выходе получаем функцию. Чтобы эта функция заработала, ей нужно передать анализируемые данные во вторых скобках
    
        Splitter.SplitByNothing()  //просто сплиттер как функция
        Splitter.SplitByNothing()("abc")  //вызов его от аргумента "abc"
    
    Что делает данная функция? Ответ в заголовке – ничего, точнее, она ничего не делает с самим аргументом. 
    Но! Результат разделения по своему смыслу должен порождать список значений, поэтому на самом деле функция 
    превращает переданный ей аргумент в список из одного значения
    
        Splitter.SplitByNothing()("abc")    // {"abc"}
        Splitter.SplitByNothing()(123)      // {123}
        Splitter.SplitByNothing()({1,2,3})  // {{1,2,3}}
    
    И вот теперь вопрос – зачем нужен сплиттер, который не меняет исходное значение?
    В качестве примера рассмотрим задачу: в таблицу после столбца “d” нужно вставить ещё три столбца ("x","y" и "z") , заполненные нулями.
    Стандартное решение через Table.SelectColumns  выглядит как-то так: */
    
        let
            from = #table({"a".."h"},List.Repeat({{1..8}},5)),
            nms  = Table.ColumnNames(from),
            lst  = {"x","y","z"},
            tbl  = Table.SelectColumns(from,List.RemoveLastN(nms,(x)=>x<>"d")&lst&List.LastN(nms,(x)=>x<>"d"),MissingField.UseNull),
            to   = Table.TransformColumns(tbl,List.Transform(lst,(x)=>{x,(i)=>0}))
        in
            to
    
    Но ведь можно использовать и другую логику – разделить этот самый столбец "d"… просто не разделяя его:
    
        let
            from = #table({"a".."h"},List.Repeat({{1..8}},5)),
            to   = Table.SplitColumn(from,"d",Splitter.SplitByNothing(),{"d","x","y","z"},0)
        in
            to
    
    Получается сплиттер отработал, на выход был подан список из одного значения, остальные заполнены значением по умолчанию. Получилось весьма лаконично, хотя вариант через Table.SelectColumns  всё же работает быстрее. 
    Справедливости ради стоит отметить, что написать можно было и так
    
        let
            from = #table({"a".."h"},List.Repeat({{1..8}},5)),
            to   = Table.SplitColumn(from,"d",(x)=>{x},{"d","x","y","z"},0)
        in
            to
    
    Или даже так
    
        let
            from = #table({"a".."h"},List.Repeat({{1..8}},5)),
            to   = Table.SplitColumn(from,"d",(x)=>{x,0,0,0},{"d","x","y","z"})
        in
            to
            
    Т.е. вообще без сплиттера. Другое дело, что подобное решение пришло в голову только в рамках размышления о данной функции. Так что вердикт – данный сплиттер точно не бесполезен )))
    ]
[   Splitter 2 - Splitter.SplitTextByWhitespace, или сплиттер, "делящий по белому пробелу"
    
    #АнатомияФункций - Splitter.SplitTextByWhitespace
    
    Ну а как получить список из всех 25 пробельных символов, не зачитываясь стандартом Юникода, смотрите в обзоре на Ютубе (https://youtu.be/nr9CvYlSeI4)
    
        Splitter.SplitTextByWhitespace(
            optional quoteStyle as nullable number
        ) as function

    Делит строковое значение по whitespace character (пробельному символу) и имеет необязательный аргумент quoteStyle.
    Обращаю на это внимание – пробельный символ – это не просто пробел (U+0020), 
    это ещё и горизонтальная табуляция (U+0009), перенос строки (U+000A), возврат каретки (U+000D), 
    неразрывный пробел (U+00A0) – всего 25 символов (по крайней мере в соответствии со стандартом Юникода).
    Поэтому
       
        Splitter.SplitTextByWhitespace()("мама мыла раму")                      // {"мама","мыла","раму"}
        Splitter.SplitTextByWhitespace()("мама#(tab)   мыла#(tab)раму")         // {"мама","мыла","раму"}
        Splitter.SplitTextByWhitespace()("мама#(00A0)  мыла #(00A0)раму")       // {"мама","мыла","раму"}
        Splitter.SplitTextByWhitespace()("мама#(cr,lf)мыла#(lf,cr,tab)раму")    // {"мама","мыла","раму"}
    
    Важно! Во всех случаях получаем одинаковый результат, причём обратите внимание – последовательность из двух и более пробельных символов рассматривается как один разрыв.

    Теперь quoteStyle - представлен в двух вариантах: QuoteStyle.Csv и QuoteStyle.None. 
    Первый используется по умолчанию, т.е. 
        
        Splitter.SplitTextByWhitespace()
    
    Это то же самое, что
    
        Splitter.SplitTextByWhitespace(QuoteStyle.Csv)

    Рассмотрим разницу на примере:
    
        Splitter.SplitTextByWhitespace()("ООО ""Рога и копыта"" Москва")                //{"ООО","Рога и копыта","Москва"}
        Splitter.SplitTextByWhitespace(QuoteStyle.None)("ООО ""Рога и копыта"" Москва") //{"ООО","""Рога","и","копыта""","Москва"}
    
    Т.е. в случае QuoteStyle.Csv, когда встречается кавычка, весь последующий текст оставляется в неизменном виде, пока не встретится следующая кавычка; сами кавычки при этом удаляются.
    А в случае QuoteStyle.None кавычки воспринимаются просто как один из символов и если между ними есть пробельные символы – по ним произойдет разделение.

    Вот такой, на самом деле весьма полезный сплиттер, если понимать, что он делает и зачем нужен необязательный аргумент )))
    (и да, я в курсе, что можно было просто залезть в англоязычную википедию - но это скучно и без сплиттеров, вот ))))
    ]
[   Splitter 3 - Splitter.SplitTextByDelimiter, Splitter.SplitTextByAnyDelimiter или когда порядок имеет значение…
    #АнатомияФункций - Splitter.SplitTextByDelimiter, Splitter.SplitTextByAnyDelimiter
    
    А что тут к чему смотрите в обзоре на Ютубе (https://youtu.be/mnqCDDP2a-A)

        Splitter.SplitTextByDelimiter(
            delimiter as text, 
            optional quoteStyle as nullable number
        ) as function
        
        Splitter.SplitTextByAnyDelimiter(
            delimiters as list, 
            optional quoteStyle as nullable number, 
            optional startAtEnd as nullable logical
        ) as function
    
    Первый делит текс по указанному разделителю, второй – по набору разделителей.
    
        let
            from = #table({"num","txt"},{{1,"мама мыла раму"},{2,"мама  мыла раму"},{3,"мама,мыла, раму"},{4,"мамаоченьмылачастораму"}}),
            to  = Table.SplitColumn(from,"txt",Splitter.SplitTextByDelimiter(" ")),
            to1 = Table.SplitColumn(from,"txt",Splitter.SplitTextByAnyDelimiter({" "})),
            to2 = Table.SplitColumn(from,"txt",Splitter.SplitTextByAnyDelimiter({" ","  "})),
            to3 = Table.SplitColumn(from,"txt",Splitter.SplitTextByAnyDelimiter({"  "," "})),
            to4 = Table.SplitColumn(from,"txt",Splitter.SplitTextByAnyDelimiter({"  "," ",", ",","})),
            to5 = Table.SplitColumn(from,"txt",Splitter.SplitTextByAnyDelimiter({"  "," ",", ",",","очень","часто"}))
        in
            to5
    
    to, to1   - поделилось только по пробелу
    to2,to3   - сравниваем результат, выясняем, что порядок имеет значение
    to4, to5  - просто демонстрация, что набор разделителей может быть разным
    
    Что касается дополнительных аргументов, тоже есть кейс:
   
        let
            from = Excel.CurrentWorkbook(){[Name="Таблица"]}[Content],
            to1  = Table.AddColumn(from,"Номер",(x)=>List.Last(Splitter.SplitTextByDelimiter("ИИН/БИН ",QuoteStyle.None)(x[#"Наименование бенефициара / отправителя"]))),
            to2  = Table.AddColumn(from,"Номер",(x)=>List.Last(Splitter.SplitTextByAnyDelimiter({"ИИН/БИН "},null,true)(x[#"Наименование бенефициара / отправителя"])))
        in
            to1
    
    to  - решили проблему через quoteStyle, 
    to1 - через startAtEnd

    Ну и на закуску просто прикольный пример, тоже про сплиттеры )))
    
        let
            from = Excel.CurrentWorkbook(){[Name="Таблица"]}[Content],
            f=(x)=>
                Function.Invoke(
                    Record.FromList,
                    List.Zip(
                        List.Split(Splitter.SplitTextByAnyDelimiter({", "," "})(x),2)
                    )
                ),
            tr   = Table.TransformColumns(from,{"Данные",f}),
            nms  = List.Distinct(List.Combine(List.Transform(tr[Данные],Record.FieldNames))),
            to   = Table.ExpandRecordColumn(tr, "Данные",nms)
        in
            to 
    ]

[   Splitter 4 - Splitter.SplitTextByEachDelimiter или когда количество имеет значение…
    #АнатомияФункций - Splitter.SplitTextByEachDelimiter
    Демонстрацию работы вышеприведённого кода смотрите в обзоре на Ютубе  (https://youtu.be/U3oivkgXe9Y)
    
    Splitter.SplitTextByEachDelimiter(
        delimiters as list, 
        optional quoteStyle as nullable number, 
        optional startAtEnd as nullable logical
    )
    
    Набор аргументов такой же как и у Splitter.SplitTextByAnyDelimiter. 
    
    Существенная разница состоит в том, что в данном случае каждый разделитель из списка используется только один раз, 
    соответственно мы можем поделить текст только по первому или только по последнему пробелу:
    
        let
            from = Excel.CurrentWorkbook(){[Name="Таблица110"]}[Content],
            f=(x)=>Splitter.SplitTextByEachDelimiter({" "},null,true)(x){1},
            to   = Table.AddColumn(from,"new",(r)=>f(r[#"Наименование бенефициара / отправителя"]))
        in
            to
    
    Также можно задать список разделителей и делить текст по мере их нахождения в нём:
    
        let
            from = Excel.CurrentWorkbook(){[Name="Таблица5"]}[Content][сотрудник],
            to   = Table.FromList(from,Splitter.SplitTextByEachDelimiter({". "," ",", ",", ",", "}))
        in
            to 
    ]
[   Splitter 5 - Splitter.SplitTextByCharacterTransition или List vs Text
    #АнатомияФункций - Splitter.SplitTextByCharacterTransition
    … а что из этого получилось смотрите в обзоре на Ютубе (https://youtu.be/7RwYZcbFWgc) 

    Продолжаем тему сплиттеров. До этого мы делили текст по разделителю (подстроке), который удалялся в результате разделения. 
    Теперь рассматриваем варианты, когда нужно разделить, но сохранить все символы. 
    
    Splitter.SplitTextByCharacterTransition(
        before as anynonnull, 
        after as anynonnull
    ) as function
    
    Два аргумента - before  и after - определяют наборы символов по переходу с которых на которые нужно делить. Каждый аргумент может быть представлен либо списком символов, либо функцией от символа, возвращающей true/false. Ну и смотрим пример:
    
        let
            from = {"GC2SB230","OF+65HB","GC2SB250","GC2KP250S"},
            /* надо получить {"GC2SB","OF+","GC2SB","GC2KP"} 
            - т.е. удалить последний набор цифр и всё, что после него*/
            
            // to – просто делим по двум спискам символов, это самый медленный вариант – 
            // поскольку мы перечисляем большое количество символов, предшествующих цифрам
            to =    List.Transform(from,(x)=>Text.Combine(List.RemoveLastN(
                        Splitter.SplitTextByCharacterTransition( {"A".."Z","+"}, {"0".."9"} )(x),
                    1))),

            // to1 – поступаем умнее – делим по переходу с не цифр на цифры – 
            // здесь заменили один список функцией, такое разделение будет идти шустрее
            to1 =   List.Transform(from,(x)=>Text.Combine(List.RemoveLastN(
                        Splitter.SplitTextByCharacterTransition( (x)=>not List.Contains({"0".."9"},x), {"0".."9"} )(x),
                    1))),

            // to2 – вспомнили, что «..» - это оператор перечисления, и чтобы он не вычислялся большое количество раз, 
            // один раз получили список цифр и запихнули его в буфер – ещё бонус к скорости
            lst =   List.Buffer({"0".."9"}),
            to2 =   List.Transform(from,(x)=>Text.Combine(List.RemoveLastN(
                        Splitter.SplitTextByCharacterTransition( (x)=>not List.Contains(lst,x), lst )(x),
                    1))),
            
            // to3 – а кто, собственно, сказал, что проверять нужно именно список… 
            // Возьмём текст из 10 цифр и осуществим проверку на нём… 
            txt =   "0123456789",
            to3 =   List.Transform(from,
                        (x)=>Text.Combine(
                                List.RemoveLastN(
                                    Splitter.SplitTextByCharacterTransition(
                                        (x)=>not Text.Contains(txt,x),
                                        (x)=>Text.Contains(txt,x)
                                    )(x),
                                1)
                        )
                    )
        in
            to3
    
    На выходе в каждом варианте получаем {"GC2SB","OF+","GC2SB","GC2KP"}

    to – просто делим по двум спискам символов, это самый медленный вариант – поскольку мы перечисляем большое количество символов, предшествующих цифрам
    to1 – поступаем умнее – делим по переходу с не цифр на цифры – здесь заменили один список функцией, такое разделение будет идти шустрее
    to2 – вспомнили, что «..» - это оператор перечисления, и чтобы он не вычислялся большое количество раз, один раз получили список цифр и запихнули его в буфер – ещё бонус к скорости
    
    и раньше я бы на этом закончил… НО!
    
    to3 – а кто, собственно, сказал, что проверять нужно именно список… Возьмём текст из 10 цифр и осуществим проверку на нём… 
    /
    ]

[   Splitter 6 - Splitter.SplitTextByRepeatedLengths, Splitter.SplitTextByLengths или когда длина имеет значение…
        #АнатомияФункций - Splitter.SplitTextByRepeatedLengths, Splitter.SplitTextByLengths

        Splitter.SplitTextByRepeatedLengths(
            length as number, 
            optional startAtEnd as nullable logical
        )

        Splitter.SplitTextByLengths(
            lengths as list, 
            optional startAtEnd as nullable logical
        )
        Оба сплиттера вообще не ориентируются на подстроки и конкретные символы – 
        их интересует только необходимая длина подстроки.

    Смотрим примеры:

    1. приводим в божеский вид МАС-адреса (разбираем строку по 2 символа)
    
        let
            from = #table({"MAC"},{{"001A2B3C4D5E"},{"0815752B9ADC"},{"096C2ABD7534"}}),
            f=(x)=>Combiner.CombineTextByDelimiter("-")(Splitter.SplitTextByRepeatedLengths(2)(x)),
            to = Table.TransformColumns(from,{"MAC",f})
        in
            to

    2. делаем «красивое» текстовое представление чисел (обращаем внимание на второй аргумент – разбираем по тройкам с конца)
    
        let
            from = #table({"num"},{{1},{12},{123},{1234},{12345},{1234567},{12345678}}),
            f=(x)=>Text.Combine(Splitter.SplitTextByRepeatedLengths(3,true)(Text.From(x))," "),
            /*хотя можно и Number.ToText(x,"N0")*/
            to = Table.TransformColumns(from,{"num",f})
        in
            to

    3. наводим порядок в номерах телефонов (задаём нужные длины с конца, обращаем внимание, что в итоге вынимаются не все символы, а только текст заданных длин):
    
        let
            from = #table({"tel"},{{"+79871234567"},{"89876543210"}}),
            f=(x)=>[a=Splitter.SplitTextByLengths({2,2,3,3},true)(x),
                    b=Text.Format("+7 (#{0}) #{1}-#{2}-#{3}",a)][b],
            to = Table.TransformColumns(from,{"tel",f})
        in
            to
    Как-то так – функции нечасто используемые, но в отдельных случаях прям мастхев)
    ]

[   Splitter 7 - Splitter.SplitTextByPositions, Splitter.SplitTextByRanges
    
    #АнатомияФункций - Splitter.SplitTextByPositions, Splitter.SplitTextByRanges
    Как вы догадываетесь, подробное описание того, что тут к чему, смотрим  на Ютубе  (https://youtu.be/X-3DfbxU-Yc) 
    
    Splitter.SplitTextByPositions(
        positions as list,                          // Первый аргумент – список
        optional startAtEnd as nullable logical)    // Второй необязательный позволяет смотреть с конца

    Splitter.SplitTextByRanges(
        ranges as list, 
        optional startAtEnd as nullable logical)
    

    Кейс 1 – разобрать текст, не затирая теги (или по простому – поделить текст по позициям одного разделителя и по позициям следующим за другим разделителем):
    
        let
            txt  = "<info><recnumber=1 type=A date=12.04.2012><name><first>Имя1</first><last>Фамилия1</last><medium>Отчество1</medium></name><doc><type>паспорт</type><number>23465</number></doc></info><info><recnumber=2 type=D date=15.04.2012><name><first>Имя2</first><last>Фамилия2</last><medium>Отчество2</medium></name><doc><type>св-во</type><number>98745</number></doc></info>",
            pos  = Text.PositionOf(txt,"<",Occurrence.All),
            pos1 = List.Transform(Text.PositionOf(txt,">",Occurrence.All),(x)=>x+1),
            lst  = List.Sort(List.Distinct(pos&pos1)),
            splt = Splitter.SplitTextByPositions(lst)(txt),
            to   = List.Select(splt,(x)=>Text.Trim(x)<>"")
        in
            to

    Кейс 2 – пишем отсутствующий в 2016 Splitter.SplitTextByCharacterTransition:
        // На выходе преобразуем "картошка 123морковка 29свёкла 11лук 14чеснок 13" в список 
        // {"картошка 123","морковка 29","свёкла 11","лук 14","чеснок 13"}
        let
            txt = "картошка 123морковка 29свёкла 11лук 14чеснок 13",
            lst = Splitter.SplitTextByRepeatedLengths(1)(txt),
            zip = List.Zip({lst,{""}&List.RemoveLastN(lst,1)}),
            f=(x)=>Text.Contains("0123456789",x),
            g=(x)=>not f(x{0}) and f(x{1}),
            pos = List.PositionOf(zip,g,Occurrence.All,(c,v)=>v(c)),
            to  = Splitter.SplitTextByPositions(pos)(txt)
        in
            to

    Кейс 3 – делим текст по цифро-дефисовой последовательности, заканчивающейся точкой:
    
        let
            txt = "1. Текст 1-1. Текст с пробелами 1-2. текст с числами 123 2. ещё текст 3. текст. 4. а текст-то бывает разный... издевательство 5. например с числами 2.5 12. и номеров много 123. очень много 1234. прям совсем",
            f=(x)=>Text.Contains("0123456789.-",x),
            g=(x)=>Text.Contains("0123456789",x),
            lst = Splitter.SplitTextByRepeatedLengths(1)(txt),
            tbl = Table.FromList(lst,(x)=>{f(x),g(x),x="."},{"flag","num","dot"}),
            add = Table.AddIndexColumn(tbl,"ind"),
            gr  = Table.Group(add,"flag",{{"pos",(x)=>x{0}[ind]},{"dot",(x)=>List.Last(x[dot])=true},{"nums",(x)=>List.AnyTrue(x[num])}},GroupKind.Local),
            pos = Table.SelectRows(gr,(x)=>x[dot] and x[nums])[pos],
            to  = Splitter.SplitTextByPositions(pos)(txt)
        in
            to

    Кейс 4 – эту задачку мы уже разбирали – только теперь решим её по-другому и выясним, что Splitter.SplitTextByRanges никакой не сплиттер, а профессиональный «выниматель подстрок» :
    
        let
            from = Excel.CurrentWorkbook(){[Name="Таблица110"]}[Content],
            f=(x)=>[a = Splitter.SplitTextByRepeatedLengths(1)(x),
                    b = (x)=>Text.Contains("0123456789 ",x),
                    c = List.Zip({a,{""}&List.RemoveLastN(a,1)}),
                    d = Text.PositionOf(x,"бит/с",Occurrence.Last),
                    e = List.PositionOf(c,null,Occurrence.All,(c,v)=>b(c{0}) and not b(c{1})),
                    f = List.Max(e,null,(x)=>if x > d then 0 else x),
                    g = {{0,Text.Length(x)},{f,d-f-2},{d-1,6}},
                    z = Splitter.SplitTextByRanges(g)(x)][z],
            splt = Table.SplitColumn(from,"Custom",f,{"Custom","скока","чего"}),
            to   = Table.TransformColumns(splt,{"скока",Number.From})
        in
            to
    ]

[   Splitter.SplitTextByPositions или плач по регуляркам / #АнатомияФункций - //! Splitter.SplitTextByPositions
    
    Всем привет! Разберем сегодняшний сабж по разделению текста. Имеем:
        
        let
            from = Table.FromRecords({
                [name = "Вася",     txt = "1. Текст 1-1. Текст с пробелами 1-2. текст с числами 123 2. ещё текст"],
                [name = "Коля",     txt = "3. текст. 4. а текст-то бывает разный 5. например с числами 2.5"],
                [name = "Евлампий", txt = "12. и номеров много 123. очень много 1234. прям совсем"]
            }),
            tr = Table.TransformColumns(from,{"txt",SplitByAnyChars({"0".."9","-"},{"."})}),
            to = Table.ExpandListColumn(tr, "txt")
        in
            to

    Текст в табличке нужно разделить на пункты, причем: 
        1 сами номера пунктов нужно сохранить; 
        2 номер пункта – это набор цифр переменной длины (возможны подпункты через дефис) и обязательно точка в конце; 
        3 в тексте могут встречаться и цифры, и дефисы, и точки.
    Мдя, задачка для регулярок, которых в M толком и не завезли. Но как видим проблема элегантно решается вызовом функции SplitByAnyChars, только есть проблема – такой функции на самом деле нет и её нужно написать )))
    Не претендую на оптимальность, но думаю, что логика решения может оказаться небезынтересной. Поехали:
    
    SplitByAnyChars = 
        (chars as list, last as list)=>
            (txt as text)=>
        let
            lst =   Text.ToList(txt),
            tbl =   Table.FromList(
                        lst,
                        (x)=>[  a = List.Contains(chars,x),
                                b = List.Contains(last,x),
                                c = a or b,
                                d = {a,b,c}
                            ][d],
                        {"chars","last","all"}
                    ),
            index = Table.AddIndexColumn(tbl, "i", 0, 1),
            group = Table.Group(
                        index, 
                        "all", 
                            {   {"n", each List.Min([i])},
                                {"l", each List.Last([last])},
                                {"c", each List.First([chars])}
                            },
                        GroupKind.Local
                    ),
            filtr = Table.SelectRows(group, each ([l] = true) and ([c] = true)),
            to    = Splitter.SplitTextByPositions(filtr[n])(txt)
        in
            to

    Во-первых, аргументы – 
    chars – список символов, которые могут присутствовать в разделителе, 
    last  – список символов, на которые должен заканчиваться разделитель, 
    txt   – разделяемый текст (обращаю внимание, что аргументы разделены на две группы – так проще вызывать функцию и не нужно каждый раз городить (x)=>Split… Это называется замыкание и описано тут).
    
    lst   – преобразовали наш текст в список символов
    tbl   – первая изюминка решения – вместо списка символов получаем таблицу из трех столбцов: 
        «chars» - относится ли символ к тем, которые должны быть в разделителе; 
        «last»  - относится ли к конечным; 
        «all»   - относится ли к одной из этих двух категорий
    index – добавляем индексный столбец с нумерацией с нуля, как в списках
    group – вторая изюминка – таблица нам была нужна, чтобы сделать группировку по столбцу «all», причем с параметром GroupKind.Local – в этой ситуации строки будут группироваться последовательно и каждая группа символов, удовлетворяющих условию, получит свою строку. 
    
    При этом мы добавляем столбцы: 
        n – минимальный индекс, т.е. с какой позиции начинается группа; 
        l – относится ли последний символ в группе к тем, на которые должен заканчиваться разделитель; 
        с – относится ли первый символ в группе к тем, которые составляют тело разделителя.
    filtr – теперь оставляем только те строки, для которых вышеуказанные условия выполняются
    
    to – ну и вишенка – в полученной таблице в индексном столбце содержатся ровно те позиции, по которым нужно разделить текст. Позиции передаем в Splitter.SplitTextByPositions – думаю из названия понятно, что делает данная функция. Вот только у сплиттера нет аргумента, отвечающего за сам разделяемый текст, я даже от кого-то слышал, что его вообще надо использовать только в составе других функций… С другой стороны, мы же знаем про замыкания – берем и насильно передаем текст во вторых скобках… и оно работает!
    
    Как-то так. Скорость не заоблачная, но вполне терпимая.
    Надеюсь, было полезно.
    ]    

[   Folder.Files    – собираем данные из папки / #АнатомияФункций – Folder.Files

    Всем привет!
    Разберем типовую задачу по сбору данных из файлов в папке. Для этого нам предлагают на выбор Folder.Files и Folder.Contents – с первой всё немножко проще, поэтому начнём с неё, вторую прокомментирую отдельным постом.
    Я не буду сейчас усложнять жизнь запросом к файлу, функцией на основе этого запроса и т.д. Просто напишем типичный образчик кода и разберем по шагам:
    
        let
            from  = Folder.Files("C:\Users\buchlotnik\Desktop\tst"),
            filtr = Table.SelectRows(from, each [Extension] = ".xlsx" and [Attributes][Hidden] = false),
            tbl   = Table.SelectColumns(filtr,{"Name","Folder Path","Content"}),
            func=(x)=>Excel.Workbook(x){0}[Data],
            tr   = Table.TransformColumns(tbl,{"Content",func}),
            to   = Table.ExpandTableColumn(tr, "Content", {"Column1", "Column3"})
        in
            to

    from      – здесь всё просто и без изысков – вызываем Folder.Files с единственным аргументом – путём к папке, в виде текстовой строки (в общем виде настоятельно рекомендую выносить путь к папке в параметр, чтобы потом не было больно при релокации исходников). На выходе мы получаем таблицу со следующими столбцами:
    Contents  – бинарное содержимое файла,
    Name      – имя файла,
    Extension – расширение файла,
    Date Accessed, Date Modified, Date Created – даты последнего подключения, изменения, создания,
    Attributes  – атрибуты файла в виде записи, в том числе такие как Hidden, System, Content Type ,
    Folder Path – полный путь к расположению файла

    filtr – фильтруем полученную таблицу по интересующим нас атрибутам. В данном случае отфильтровываются файлы Excel (расширение xlsx), причём не скрытые – это нужно, если есть вероятость, что кто-то будет работать с папкой в момент выполнения запроса – в этом случае для открытых книг создаются временные файлы и они также будут попадать в выборку, роняя запрос ))). Соответственно на этом этапе вы можете фильтровать по любому важному признаку из названия, даты создания и т.д.

    tbl   – отбираем только нужные столбцы для последующей работы – в данном случае это имя, путь (часто нужно из пути получить дополнительную информацию, например, название подпапки) и собственно бинарное содержимое файла. Если вам нужна только «начинка» файлов – значит оставляем только Contents

    func  – функция для обработки содержимого файла – в данном случае Excel.Workbook – ее мы уже разбирали тут и тут, которая просто берет данные с первого листа (типично для выгрузок из 1С – выгружается один лист без дополнительных имён и т.п.). Но функция на самом деле может быть любой сложности и для вашего типа файла - Csv.Document, Xml.Document, Json.Document и т.д.

    tr    – ну и преобразовываем нашей функцией func столбец Contents – в данном случае вернёт данные конкретного листа в виде таблицы, да и вообще обычно здесь возвращаем таблицу, хотя от задачи это может быть запись, список, текст и т.д. Ключевое - мы не тянули файлы заново по [Folder Path]&[Name] - не знаю кто придумал эту дичь - мы сразу обрабатываем столбец Contents

    to    – остается только привести всё в божеский вид. В данном случае сделано через Table.ExpandTableColumn, чтобы на выходе получить информацию с листов, но сохранить информацию о названии файла; есть вариант через Table.Combine(tr[Contents]) – когда нужны только таблицы, ну или если ваша функция func будет возвращать запись или список – ExpandRecordColumn, ExpandListColumn и т.д. – варианты безграничны, экспериментируйте.

    Собственно, всё – изложил общий подход, его можно модифицировать, наворачивать, углублять и расширять по вкусу (но лучше под задачу).
    ]

[   Folder.Contents – собираем данные из папки, но выборочно / #АнатомияФункций - Folder.Contents

    Всем привет!
    Как-то мы уже разбирали сбор данных из папки с помощью Folder.Files. Если не читали – гляньте хоть одним глазом, потому что сейчас будем немножко развивать мысль. Folder.Files хороша тем, что позволяет собрать файлы из папки со всеми вложенными папками. Но что делать, если нам нужно не совсем это – сейчас разберем пару вариантов, когда нам может понадобиться Folder.Contents

    Вариант 0 – нужны только файлы из корневой папки
    
    Представьте себе ситуацию, когда в папке «Отчёты» у вас лежат аналитические таблицы и есть подпапки «Исходники», «Архив» с кучей промежуточных версий, кусков информации и т.д. Можно, конечно, отфильтровать, ориентируясь на [Folder path], а можно написать так:

        from  = Folder.Contents("C:\Users\buchlotnik\Desktop\tst"),
        filtr = Table.SelectRows(from, each ([Extension] <> ""))

    Фишка в том, что Folder.Contens вернёт точно такую же таблицу, как и Folder.Files, НО! Вместо того, чтобы проходить по всем подпапкам и вынимать оттуда файлы, она вернёт для каждой подпапки строку, где Extension="" и Content содержит не binary, а table – т.е. результат применения Folder.Files к подпапке но в свёрнутом виде.
    Поэтому в коде выше мы просто отфильтровали все подпапки и оставили только файлы.
    Можно и по-другому:

        from  = Folder.Contents("C:\Users\buchlotnik\Desktop\tst"),
        filtr = Table.SelectRows(from, each [Extension] = ".xlsx")

    В этой ситуации мы сразу выбрали файлы xlsx и можем быть абсолютно уверены, что это файлы строго из корневой папки и никакой дополнительный мусор к нам в таблицу не попадёт. Неплохо, правда?

    Вариант1 – нужны конкретные подпапки
    
    Обратная ситуация – есть папка, в которой лежат какие-то файлы (чьи-то сводки, аналитика и т.п.) и есть подпапки по регионам (продуктам/менеджерам/филиалам – нужное подчеркнуть), где также лежит куча файлов, а вам нужно в каждом регионе найти подпапку «Продажи» и забрать оттуда самый свежий файл...
    Ну что? Фильтр по [Folder path], группировка по нему же и потом Table.Max? Да, так можно, а можно и по-другому:

        let
            f=(x)=>[a = x{[Name="Продажи"]}[Content],
                    b = Table.SelectRows(a, each [Extension]=".xlsx"),
                    c = Table.Max(b,"Date created")[Content],
                    d = Excel.Workbook(c,true){0}[Data]][d],
            
            from  = Folder.Contents("C:\Users\ buchlotnik \Desktop\tst"),
            filtr = Table.SelectRows(from, each ([Extension] = ""))[[Name],[Content]],
            tr    = Table.TransformColumns(filtr,{"Content",f}),
            to    = Table.ExpandTableColumn(tr, "Content", {"продукт", "сумма"})
        in
            to

    from  – обратились к папке
    filtr – оставили только подпапки (Extension=””), попутно оставили только интересующие нас столбцы – Name и Content
    tr    – совершили магию над столбцом Content с помощью функции f
    to    – и раскрыли нужное нам содержимое… Всё просто )))

    Осталось только разобраться с «магией» – смотрим на функцию f:
    a – выбрали содержимое подпапки «Продажи» (поле Content содержит всю информацию о файлах, внутри неё)
    b – оставили только файлы xlsx
    с – выбрали последний с помощью Table.Max
    d – ну и обратились к нему – в данном случае взяли информацию с первого листа (вы же помните, что обращение, на самом деле, может быть любой сложности)

    Как-то так. Показал примеры, в которых реально Folder.Contents упрощает программирование и жизнь. Сказать, чтоб прям ускоряла – не могу, грамотно написанные фильтры с группировкой по скорости не проигрывают – их просто надо грамотно написать ))) Но в целом хороша, лаконична и на мой вкус незаслуженно обделена вниманием. Пользуйтесь!
    ]

[   Excel.CurrentWorkbook(){[Name=…]}[Content] или зачем нам столько скобок? / #АнатомияФункций - Excel.CurrentWorkbook

    Всем привет!
    Уже разбирали вопрос обращения к полям и элементам списка в функциях, но поскольку регулярно возвращаемся к этому в чате, стоит разобрать пару нюансов.
    Пример заявлен прямо в названии

        Excel.CurrentWorkbook(){[Name="Таблица1"]}[Content]

    Что же тут происходит?
        
        Excel.CurrentWorkbook()

    Сразу после названия функции идут круглые скобки – в них помещают аргументы. У CurrentWorkbook аргументов нет, поэтому скобки пустые.
    Далее идут фигурные скобки – это обращение к элементу списка. Но ведь CurrentWorkbook возвращает нам таблицу. Фишка в том, что таблица – это список записей вида [Name, Content]. Т.е. так написать корректно:
    
        Excel.CurrentWorkbook(){0}
    
    Это вернет нам запись с первым (вы же помните про нумерацию с нуля) именем в текущей книге.
    Другое дело, что для таблиц вместо конкретного индекса можно указать условие:
        
        Excel.CurrentWorkbook(){[Name="Таблица1"]}
    
    Это обозначает: верни элемент, у которого поле Name равно "Таблица1".
    Для этих же целей можно было использовать и Table.SelectRows, но так короче и чутка шустрее.
    Обращаю внимание – название поля пишется без кавычек, а вот строковое значение в кавычках. Бывают ситуации, когда имя поля содержит недопустимые символы (например разрыв строки), тогда его пишут в кавычках, но после решетки, поэтому такой синтаксис также корректен:
        
        Excel.CurrentWorkbook(){[#”Name”="Таблица1"]}

    И ещё одно замечание – мы можем обращаться или по индексу, или по условию, но если элемент отсутствует, закономерно вернётся ошибка. Во избежание этого пишем так:
        
        Excel.CurrentWorkbook(){[Name="Таблица1"]}?
    
    Знак вопроса указывает вернуть элемент, если он есть, и null, если его нет.
    Ну а после фигурных идут квадратные скобки:
    
        Excel.CurrentWorkbook(){[Name="Таблица1"]}[Content]
    
    Это обозначает обращение к полю записи.
    Название поля также пишем без кавычек или в кавычках, но после решётки:
    
        Excel.CurrentWorkbook(){[Name="Таблица1"]}[#"Content"]

    Ну и также, как и с элементами списка, можем использовать знак вопроса:
    
        Excel.CurrentWorkbook(){[Name="Таблица1"]}?[Content]?
    
    Собственно это обозначает: верни из текущей книги таблицу имен, конкретно строку, в которой поле Name равно Таблица1 (если такая строка есть), а конкретно поле Content из этой строки (если оно есть).
    На выходе получим либо таблицу, либо null – всяко лучше, чем просто ошибку )))

    Вот такой нехитрый пример, но реально содержащий в себе много аспектов.
    Собственно, с этого разбора я в свое время и начинал освоение синтаксиса M.
    Думаю несложно догадаться, что всё вышеизложенное можно обнаружить в спецификации.
    Ещё раз настоятельно рекомендую её к прочтению.
    ]
  
[   Excel.CurrentWorkbook() vs Excel.Workbook() или в чём же разница / #АнатомияФункций - Excel.CurrentWorkbook, Excel.Workbook

    Всем привет! Только что разбирали Excel.CurrentWorkbook, но есть ещё одна функция - Excel.Workbook. Из названий понятно, что обе функции предназначены для обращения к содержимому Excel-файлов, но есть ряд существенных отличий, которые стоит разобрать.

    Отличие 0 – аргументы
    CurrentWorkbook не имеет аргументов, поскольку обращается к текущей книге. Workbook имеет три аргумента – обязательный workbook и необязательные useHeaders и delayTypes. Первым аргументом должно быть бинарное содержимое файла – обычно его получают через Folder.Files или File.Contents, причём в качестве пути для File.Contents можно указать и ссылку на текущую книгу. Таким образом, оба кода дадут содержимое текущей книги:
    
        Excel.CurrentWorkbook()
        Excel.Workbook(File.Contents(“путь_к_текущему_файлу”))

    Необязательные аргументы разберем ниже

    Отличие 1 – возвращаемое содержимое
    CurrentWorkbook возвращает таблицу с двумя полями [Name, Content]
    Workbook – таблицу с четырьмя полями [Name, Item, Kind, Hidden]
    
    Разница в том, что для CurrentWorkbook в файле существуют только таблицы и именованные диапазоны (именно диапазоны листа, которым присвоено имя; имён с константами, формулами и т.п. это не касается), а вот с помощью Workbook можно обратиться к таблицам (Kind=”Table”), именованным диапазонам (Kind=” DefinedName”) и листам (Kind=”Sheet”).
    Здесь важное замечание – имена таблиц не могут совпадать, поэтому прописывая условия отбора для CurrentWorkbook мы указывали только имя, в то время как имена таблиц и листов совпадать могут, поэтому при обращении через Workbook лучше указать имя и тип:
    
        Excel.CurrentWorkbook(){[Name="Таблица1"]}[Content]
        Excel.Workbook(File.Contents("путь_к_текущему_файлу ")){[Name="Таблица1",Kind="Table"]}[Data]
    
    Обратите внимание, что поля с содержимым отличаются – Content и Data соответственно

    Отличие 2 – работа с листами
    Это частая задача – собрать данные со всех листов в файле, понятно что она решается только через Workbook. Дополнительно надо отметить – не просто так Workbook возвращает свойство Hidden – она получает доступ ко ВСЕМ листам в книге, просто для скрытых вернет Hidden=true (и для очень скрытых тоже, кто не знает что это – советую погуглить).
    Также обращаю внимание на второй аргумент – useHeaders, он по умолчанию false и тогда таблица листа будет с заголовками Column1, Column2 и т.д. Если же поставить useHeaders=true – первая строка таблицы будет использована в качестве заголовков – т.е. можно не прописывать PromoteHeaders отдельным шагом – когда в выгрузке один стандартный лист, это бывает удобно
    
        Excel.Workbook(File.Contents("D:\ECWEW.xlsx")){[Kind="Sheet"]}[Data]        // дефолтные заголовки
        Excel.Workbook(File.Contents("D:\ECWEW.xlsx"),true){[Kind="Sheet"]}[Data]   // заголовки из первой строки

    Отличие 3 – типизация столбцов
    Ещё одно важное отличие – CurrentWorkbook всегда возвращает столбцы таблицы нетипизированными, а Workbook – наоборот, типизированными. Последний аргумент – delayTypes – по умолчанию false, т.е. «не оставлять не типизированными», эту самую типизацию сохраняет. Когда жалуются, что с листами это не работает, советую проверить второй аргумент – если он не указан (т.е. false), у вас в первой строке текст заголовков, а потом, например, числовые значения – понятно, что такое типизируется как any, а вот так должно работать:
    
        Excel.Workbook(File.Contents("D:\ECWEW.xlsx"),true,false){[Name="Лист1",Kind="Sheet"]}[Data] 

    К чему весь этот многобуквенный спич? - Excel.CurrentWorkbook удобно мышкоклацается прямо из файла; 
    с Excel.Workbook надо повозиться – прописать путь, но зато вы реально получаете всё, в том числе скрытое, содержимое файла и бонусом пару аргументов для тонкой настройки.
    Да и в целом я сторонник разделения источника данных и его обработчика – поэтому практически всегда использую Excel.Workbook и обращаюсь к файлам с данными извне, заодно избегая проблемы с защитами/правами доступа и прочим.
    ]

[   Excel.Workbook - собираем все листы из файла //? #АнатомияФункций – Excel.Workbook, Table.Combine, Table.ExpandTableColumn

    Всем привет!
    В продолжение этой темы давайте разберем вопрос – как собрать информацию со всех листов в файле. Мы помним, что для этого нам понадобится Excel.Workbook, а вот дальше есть варианты:

    Вариант 0 – нужна только информация с листов
    
        let
            from    = Excel.Workbook(File.Contents("путь\файл.xlsx"), true),
            sheets  = Table.SelectRows(from, each [Kind]="Sheet"),
            to      = Table.Combine(sheets[Data])
        in
            to

    from    – подключение к файлу, второй аргумент true – использование первой строки в качестве заголовков
    sheets  – выбрали только листы (если вам нужны таблицы - [Kind]="Table")
    to      – ну и соединили таблицы воедино

    Вариант 1 – нужно сохранить названия листов, данные на листах типовые
    
        let
            from    = Excel.Workbook(File.Contents("путь\файл.xlsx "), true),
            sheets  = Table.SelectRows(from, each [Kind]="Sheet"),
            cols    = Table.SelectColumns(sheets,{"Name", "Data"}),
            nms     = Table.ColumnNames(cols{0}[Data]),
            to      = Table.ExpandTableColumn(cols, "Data",nms)
        in
            to
    
    первые два шага те же
        cols – выбрали столбцы с названиями листов и данными
        nms  – получили заголовки столбцов из первой таблицы
        to   – раскрыли табличный столбец

    Вариант 2 - нужно сохранить названия листов, шапки таблиц могут различаться
    
        let
            from   = Excel.Workbook(File.Contents("путь\файл.xlsx "), true),
            sheets = Table.SelectRows(from, each [Kind]="Sheet"),
            cols   = Table.SelectColumns(sheets,{"Name", "Data"}),
            nms    = List.Distinct(List.Combine(List.Transform(cols[Data], Table.ColumnNames))),
            to     = Table.ExpandTableColumn(cols, "Data",nms)
        in
            to

    меняем только шаг nms – в этой ситуации мы получаем списки заголовков со всех таблиц, собираем в один список и оставляем только уникальные

    Как бы и всё. Если таблицы не требуют дополнительных преобразований, количество кода минимально (особенно в варианте 0), а пользы приносит много.
    ]

[   Интервальный поиск в PQ / #ВсякоРазно
        
        И снова всем добра. Довольно часто граждане по работе встречаются с задачей сопоставления цен из прайса с фактической таблицей продаж, но в прайсе есть только данные за некоторые периоды, а в фактах идут сквозные даты, т.е. Table.Join нам тут совсем не товарищ. И вот пару лет назад один замечательный человек с планетыэксель Андрей VG научил меня хорошему, а я делюсь с вами. Указанная задача в Excel решается с помощью банальной ВПР в режиме интервального поиска, ну а в PQ этот поиск можно реализовать по такой схеме:
        - сначала комбайним (Table.Combine или &) таблицу фактов и справочник,
        - сортируем их по дате,
        - заполняем вниз/вверх по вкусу столбец с ценами из справочника
        - убираем не нужные строки, наводим красоту.
        Данный способ не единственный для решения такого типа задач, можно размножить строки справочника, так чтобы список дат в нем покрывал весь диапазон дат из фактов, а потом джойнить это все. Но из всех мною опробированных интервальный поиск - самый шустрый.
        З.Ы. Добавлю одно пояснение: т.к. при сортировке по полю дата порядок строк по остальным полям может меняться (разбиралось здесь) к одной из объединяемых таблиц я добавил столбец с единичками и задействовал его в сортировке.
        По ссылке есть файлик с примером.
        А здесь более сложный пример с группировкой для изоляции номенклатур друг от друга. Там же коллега показал как он изменил предложенный мной код для ещё более быстрого выполнения запроса на большом массиве.
        Удачи в обучении!😉
        
            let
                to         = Table.TransformColumnTypes(Excel.CurrentWorkbook(){[Name="Таблица_для_заполнения"]}[Content],{{"Дата", type date}}),
                from       = Table.TransformColumnTypes(Excel.CurrentWorkbook(){[Name="Таблица_источник"]}[Content],{{"Дата", type date}}),
                
                combine    = Table.AddColumn(from, "ДатаИсточник", each [Дата], Date.Type) & Table.AddColumn(to, "tab", each 1, Int64.Type),
                sorted     = Table.Sort(combine,{{"Продавец", Order.Ascending}, {"Дата", Order.Ascending}, {"tab", Order.Ascending}}),
                filledDown = Table.FillDown(sorted,{"Выручка", "ДатаИсточник"}),
                filtered   = Table.SelectRows(filledDown, each ([tab] = 1)),
                removed    = Table.RemoveColumns(filtered,{"tab"})
            in
                removed
    ]

[   Web.Contents и динамические ссылки / #НеВсеЙогуртыОдинаковоПолезны
    
    Что-то меня работой привалило малость. Но я выбрался и снова научу вас наносить добро и причинять пользу себе и окружающим.
    В моем самом втором посте я кое чего обещал, вот сдерживаю слово.
    Как формировать веб ссылку с изменяемым параметром чтобы облачная служба PBI не ругалась на динамическое содержимое:

        let
            //  ВОТ ТАК СЕРВИС БУДЕТ РУГАТЬСЯ, если ссылку формировать из динамических параметров в текстовую строку
                Source = Xml.Tables(Web.Contents( "http://www.cbr.ru/scripts/XML_daily.asp?date_req=02/03/2002" )),

            //  ВОТ ТАК ругаться не будет, если Url это константа, а не элемент списка/записи
            //  при этом в параметр Query можно пихать все что хочется, лишь бы API вас понял
                Url     = "http://www.cbr.ru/scripts/XML_daily.asp",
                Query   = [Query = [date_req="02/03/2002"]],
                Source1 = Xml.Tables(Web.Contents( Url, Query )),

            //  ВОТ ТАК тоже ругаться не будет, если Url это константа, а не элемент списка/записи
            //  но при этом оба элемента записи Query2 можно использовать как динамические параметры
                Url2   = "http://www.cbr.ru/scripts/",
                Query2 = [ 
                    RelativePath = "XML_daily.asp",
                    Query = [date_req="02/03/2002"]
                ],

                Source2 = Xml.Tables(Web.Contents( Url2, Query2 ))
        in
            Source2
    
    ]
[   Как сформировать таблицу на листе Excel с помощью формул DAX
    #ВсякоРазно
    Всем добра. И снова граждане интересуются странным, а я их учу нехорошему. Расскажу и вам.
    Сценарий такой:
    - Хочу увидеть на листе Excel таблицу из модели данных.
    - Ну, раз хотите...
    Итак, можно всегда сослаться на любую таблицу из модели, вот пример. 
    Добавляйте любые столбцы в модели данных с формулами DAX, они тут же появятся в таблице на листе. 
    Хотя таблица в модель вставлена просто из буфера и вообще не имеет внешних источников.
    Небольшой гайд как такое сделать:
    Если источником таблицы является запрос PQ, тогда просто в меню Загрузить в... кроме галочки о загрузки в модель данных, 
    нужно одновременно выбрать вариант выгрузки еще и в таблицу.
    Допустим источник - не запрос PQ,
    1. Имеем в модели данных некую таблицу, к которой хотим подключить таблицу с листа и видеть все изменения, допустим в модели она называется Продажи
    2. создаем пустой запрос с названием не совпадающим ни с одной из таблиц в модели данных, содержимое запроса не имеет значения, это может быть одна ячейка без значений.
    3. результат загружаем и в модель и в таблицу на лист
    4. тыкаем ПКМ по выгруженной таблице и выбираем пункт изменить DAX как на картинке
    5. указываем имя нужной таблицы из модели
    6. удаляем теперь не нужный запрос (он вместе с собой удалит и загруженную ненужную таблицу из модели данных)
    7. пользуемся и радуемся.
    ] 

[   FnRemoveEmptyColumns - Как удалить все пустые столбцы с сохранением названий столбцов
    
    #ВсякоРазно
    Делюсь функцией, которая удаляет все пустые столбцы в таблице, и при этом не ломает заголовки столбцов. 
    Оказывается это довольно востребованный функционал, особенно при обработке выгрузок из 1С или файлов, 
    заполняемых шаловливыми ручками. Код приведен сразу с примером применения.
        
        let
            FnRemoveEmptyColumns = 
                (tab as table) =>
                    Table.RemoveColumns(
                        tab,
                        Table.SelectRows(Table.Buffer( Table.Profile( tab ) ),
                        each [NullCount] = [Count] )[Column] 
                    ),
            Source = #table( {"a","b","c"}, {{1,1,null},{2,2,null}} ),
            Custom1 = FnRemoveEmptyColumns( Source )
        in
            Custom1
    ]

[   fnRemEmptyColumns    - Функция удаления пустых столбцов  / #АнатомияФункций - Table.Profile
    
    Делюсь решением достаточно часто возникающей задачки - а именно: на входе имеем таблицу, часть столбцов которой являются пустыми, 
    соответственно нужно их удалить. Что ж, напишем функцию:
    
    fnRemEmptyColumns = (tbl)=>
        [   a = List.Sort(Table.ColumnNames(tbl)),
            b = Table.Profile(tbl,{{"tmp", (x)=>true,List.NonNullCount}})[tmp],
            c = List.PositionOf(b,0,Occurrence.All),
            d = List.Transform(c,(x)=>a{x}),
            e = Table.RemoveColumns(tbl,d)
        ][e]

    Разберем по шагам:
    a - получаем список имён столбцов и сортируем его по алфавиту
    b - изюминка решения - используем Table.Profile(), но со вторым аргументом (более подробно про него - см. сцыль ниже). Т.е. добавляем дополнительную агрегацию "tmp" для всех столбцов ((x)=>true) с функцией List.NonNullCount. И забираем только этот столбец Table.Profile(...)[tmp]
    с - в полученном списке определяем позиции пустых столбцов (обращаю внимание на Occurence.All - мощная штука)
    d - номера позиций заменяем названиями (тоже приемчик интересный - как вытащить несколько позиций из списка)
    e - удаляем - Вуаля! Задачка решена.
    ]

[   Зачем писать (x)=> вместо each _  / #АнатомияФункций – основы, List.Transform
    Возьмём простую задачку – имеем список текста
        
        lst = {"1","2","3"} и хотим получить список чисел
    
    Решение банальное:
        
        to = List.Transform(lst, each Number.From(_))
    
    Продвинутые могут сказать, что можно проще:
        
        to = List.Transform(lst,Number.From)
    
    И будут совершенно правы, ведь справка нам говорит
        
        List.Transform(list as list, transform as function)
    
    Т.е. вторым аргументом идёт на самом деле ФУНКЦИЯ – мы её указали, и всё заработало, логично.
    В документации на язык M указано, что конструкция each _ является синтаксическим сахаром для (x)=> x; давайте попробуем:
        
        to = List.Transform(lst, (x)=>Number.From(x))
    
    Так тоже работает, но зачем нам это? А вот зачем:
    Во-первых, можно сообразить, что List.Transform хочет от нас ЛЮБУЮ функцию, которая принимает на вход один аргумент x и что-то с ним делает
        
        f=(x)=>Number.From(x)*8-11
        to = List.Transform(lst,f)
    
    т.е. пишем любую нужную нам функцию от одного аргумента, и далее просто её передаем – для отладки удобно, код более читаем.
    А во-вторых, понимаем, что таким образом можно вкладывать одну функцию в другую.
    Например задачка – из двух списков получить один (причем к элементам первого списка нужно добавить результат 
    сцепки этого элемента с каждым элементом второго), попробуем решить:
        
        let
            lst1 =  {"1".."3"},
            lst2 =  {"1".."9"},
            lst  =  List.Transform(
                        lst1,
                        (x)=>{x} & List.Transform(
                            lst2,
                            (y) => x & y
                        )
                    ),
            to = List.Combine(lst)
        in
            to

    Посмотрите на шаг lst – в функцию от (x)=> вложена функция от (y)=> . С each _ так сделать не получится 
    (потому что во вложенных each _ от _ никак нельзя отличить))), а теперь мы получили (на самом деле всегда имели, но не использовали) 
    возможность давать переменным осмысленные имена вместо _ и использовать их в нужных местах кода.
    
    В целом синтаксис (x)=> является основным (ещё раз напоминаю – от нас обычно хотят ФУНКЦИЮ преобразования и мы пишем её в явном виде) 
    и по хорошему ставит мозги на место, позволяя в конечном счёте уйти от наклацанных мышкой шагов к написанию кода на функциях.
    Ну и пытливые умы конечно скажут – а можно ли в последнем примере из шага lst сделать функцию? Конечно, мы же теперь знаем, 
    как обозначать переменные:
    
        let
            f=(x,y)=>List.Transform(
                        x,
                        (i)=>{i} & List.Transform(
                                y,
                                (j)=>i&j
                        )
                    ),
            lst1 = {"1".."3"},
            lst2 = {"1".."9"},
            lst  = f(lst1,lst2),
            to   = List.Combine(lst)
        in
            to
    Вроде не сложно, а главное прозрачно – именно поэтому я почти не использую each _ и предпочитаю (x)=>
    ]

[   #PQ, #pbi - Синхронное разворачивание списков из соседних ячеек.
    
    Дано. Получили из API некий JSON который на выходе выдал структуру со вложенными списками как в таблице tbl (см. в коде ниже). 
    Надо развернуть содержимое списков в новые строки, но если мы это сделаем стандартным мышиным способом с 
    разворачиванием списков в строки по очереди то получится декартово произведение, не такое красивое как 
    это но тоже ничего. Что же делать? А на самом деле все довольно просто: надо не разворачивать столбцы, 
    а при помощи функции Table.FromColumns собрать из них готовую таблицу в новом столбце:
        
        let
            tbl = Table.FromRecords (
                {
                    [ Company = 1, Phone = { "1".."9" }, Mail = { "1".."6", "", "8".."9" } ],
                    [ Company = 2, Phone = { "1".."5" }, Mail = { "2".."6" } ]
                }
                ),
            gentabs = Table.AddColumn(
                tbl,
                "tabs",
                each Table.FromColumns(
                    {List.Repeat({[Company]}, List.Count([Phone])),[Phone],[Mail]},
                    Table.ColumnNames(tbl)
                )
            ),
            tabs = Table.Combine(gentabs[tabs])
        in
            tabs
    
    Но может еще случиться, что столбцов с простым содержимым (не списки) будет много, и тогда использование 
    List.Repeat станет узким местом с точки зрения производительности, да и код сильно потеряет свою наглядность. 
    Но для этого случая можно применить мою любимую функцию Table.FillDown до объединения таблиц и получим точно такой же результат.

        let
            tbl = Table.FromRecords (
            {
                [ Company = 1, Phone = { "1".."9" }, Mail = { "1".."6", "", "8".."9" } ],
                [ Company = 2, Phone = { "1".."5" }, Mail = { "2".."6" } ]
            }
            ),
            gentabs = Table.AddColumn(tbl,"tabs",
                    each Table.FromColumns(
                        {{[Company]},[Phone],[Mail]},
                        Table.ColumnNames(tbl)
                    )
                ),
            filled = Table.AddColumn(gentabs, "tabs_", each Table.FillDown([tabs],{"Company"})),
            tabs = Table.Combine(filled[tabs_])
        in
            tabs
    ]

[   Зачем нужен [ ][ ] когда есть let in    / #АнатомияФункций - основы
    Возьмем абстрактный как сферический конь в вакууме запрос:
        
        let
            a = 8,
            b = 16,
            c = a*b,
            d = a/b
        In
            d

    На выходе, разумеется, получим 0,5.
    Фишка в том, что в недрах спецификации на язык написано «Выражение let можно рассматривать как синтаксический 
    сахар для неявного выражения записи».
    Давайте проверим:
    
        [   a = 8,
            b = 16,
            c = a*b,
            d = a/b ][d]
    
    Выдаст то же самое.
    Почему? Запись – это набор полей (её ещё представляют в виде строки таблицы), но кто сказал, что не бывает вычисляемых полей? Пример выше как раз и показывает, что вполне себе бывают.
    Соответственно, конструкция [ ][d] – это обращение к конкретному полю записи (аналогично in d).
    Зачем нам всё это? Ну для начала – а если мы хотим вывести и произведение, и частное:
    
        [   a = 8,
            b = 16,
            c = a*b,
            d = a/b 
        ]
            [[c],[d]]
    
    Сразу даст [c=128, d=0,5]
    На мой взгляд это несколько проще и понятнее, чем
    
        let
            a = 8,
            b = 16,
            c = a*b,
            d = a/b
        in
            [c=c, d=d]
    
    Хотя эффект будет тем же.
    А дальше – вычисления бывают разной степени сложности, иногда отдельный этап требует нескольких 
    связанных вычислений и тогда приходится, либо вкладывать let in друг в друга:
    
        let
            f=(x)=>
                let 
                    a = Text.From(x),
                    b = Text.ToList(a),
                    c = List.Distinct(b),
                    d = b = c 
                in  
                    d,
            from = List.Numbers(0,1024),
            to   = List.Select(from,f)
        in
            to

    либо можно упаковать связанные шаги в запись:
    
        let
            f=(x)=>[a=Text.From(x), b=Text.ToList(a), c=List.Distinct(b), d=b=c][d],
            from = List.Numbers(0,1024),
            to   = List.Select(from,f)
        in
            to
    
    По мне второй вариант проще, хотя это дело вкуса.
    Синтаксис через записи обычно более компактный и позволяет визуально локализовать связанные вычисления внутри [ ].
    На скорости никак не сказывается, поэтому как удобнее - решать вам.
    ]

[   List.Generate, осмысленный и пощадный   / #АнатомияФункций – List.Generate
    // Думаю несложно догадаться, что для начала отправлю читать спецификацию, ибо там сказано:
    
    List.Generate( 
        initial as function,
        condition as function,
        next as function,
        optional selector as nullable function)
    
    Итак, функция, у которой в качестве аргументов выступают четыре функции. Уже страшно.
    Для прозрачности далее буду использовать синтаксис с (x)=> (подробнее читаем тут).
    Для начала сгенерим список от 1 до 10 (если что я знаю про {1..10} но у нас тут про другое:
    
        List.Generate(  () => [i = 1],
                        (x)=> x[i] <= 10,
                        (x)=> [i = x[i] + 1],
                        (x)=> x[i])

    initial   – просто даёт нам начальное значение 1, но в более сложных случаях мы будем использовать промежуточные вычисления, там нам потребуются вычисляемые поля, поэтому сразу пишем как надо – т.е. через запись
    condition – это функция, вопрос в том от чего? Как ни странно, от текущего состояния. Таким образом, x[i] – это текущее состояние счётчика и мы проверяем не превысило ли оно 10
    next      – а эта функция говорит, что необходимо сделать с текущим состоянием. Поскольку на входе у нас была запись [i=…], на выходе тоже будет она [i=x[i]+1] – т.е. в поле i записали текущее, увеличенное на единицу
    selector  – нужен, чтобы выводить только интересующие нас поля, в данном случае x[i].

    Да, немножко громоздко, но теперь давайте выведем не просто числа от 1 до 10, а накопленную сумму (собственно, для этой задачки функция обычно и используется):
    
    List.Generate(  () => [i = 1, s = i],                   // начальные значения
                    (x)=> x[i] <= 10,                       // условие проверки текущего состояния x[i]
                    (x)=> [i = x[i] + 1, s = x[s] + i],     // что сделать с x[i], x[i] и другимие если есть
                    (x)=> x[s])                             // что выводить
    
    Теперь: initial     – это уже связанные поля [i,s], причем s вычисляется на основе i (про [ ] можно почитать тут)
            condition   – такой же
            next        – теперь в записи i вычисляется на основе предыдущего значения прибавлением единицы, а s – прибавлением i к предыдущему значению
            selector    – на выходе нас интересует именно s, так что счётчик мы используем, но не выводим.
    
    Ну и что-нибудь похожее на боевой пример:
    
        let
            tbl =   Table.FromRecords({
                        [a="Вася", b = 2],
                        [a="Коля", b = 4],
                        [a="Петя", b = 8],
                        [a="Евлампий", b = 16]
                    }),
            lst =   List.Buffer(tbl[b]),
            n   =   List.Count(lst),
            gen =   List.Generate(
                        () => [i=0, s=lst{i}],
                        (x)=> x[i]<n,
                        (x)=> [i=x[i]+1, s=x[s]+lst{i}],
                        (x)=> x[s]
                    ),
            to =    Table.FromColumns(
                        Table.ToColumns(tbl)&{gen},
                        Table.ColumnNames(tbl)&{"cusum"}
                    )
        in
            to
    
    Разбираем по шагам:

        tbl – на вход поступила таблица, допустим нам нужна накопленная сумма по столбцу b
        lst – получаем столбец в виде списка (обращаю внимание на List.Buffer – здесь оно нужно, потому как к этому списку мы будем многократно обращаться
        n   – посчитали число элементов в списке (нам же нужно ограничение для счётчика)
        gen – генерация столбца, фактически как в примере выше, но с оговорками:
        
        initial   – i=0 – потому как нумерация элементов в списке начинается с нуля, s=lst{i} – в сумму идёт i-ый элемент списка lst
        condition – здесь условие x[i]<n, потому как нумерация была с нуля и <= даст нам на один элемент больше, чем надо
        next      – увеличиваем счётчик на 1, к сумме прибавляем i-ый элемент
        selector  – нас интересует только сумма
        to        – а вот теперь нужно прилепить новый столбец к таблице, для этого :
            Table.ToColumns(tbl)&{gen}       – получаем список имеющихся столбцов и добавляем к нему сгенерированный
            Table.ColumnNames(tbl)&{"cusum"} – получаем список имен столбцов и добавляем к нему нужно е имя
            Ну и упаковываем это всё через Table.FromColumns
        
        Вуаля – столбец накопленной суммы добавлен!
    
        Я знаю, что примеры в справке попроще и написаны через each, и код выше можно было оформить проще, но в общем виде оно выглядит именно так – запись на входе, функции от текущего состояния – одна для проверки, вторая для изменения, и функция вывода (которая вообще не обязательная, но вот почему-то в реальности почти всегда используется).
    ]

[   Замыкания, или что за зверь (y)=>(x)=>… / #АнатомияФункций – // !основы
    Всем привет, с оказией хочу разобрать такую штуку, как замыкания (closure).
    Суть вот в чём. Напишем простой пример:
    let
        f=(x,y)=>x/y,
        a   = 2,
        b   = 5,
        to  = f(a,b),
    in
        to
    Очевидно, на выходе получим 0,4. Но можно написать и по-другому:
    let
        f=(x)=>(y)=>x/y,
        a   = 2,
        b   = 5,
        to  = f(a)(b)
    in
        to
    На выходе получим то же самое. Но в этой ситуации мы передали аргументы функции последовательно. И разрыв мозга наступает здесь:
    let
        f=(x)=>(y)=>x/y,
        a   = 2,
        b   = 5,
        c   = f(a),
        to  = c(b)
    in
        to
    Тоже выдаст 0,4! Теперь давайте разбираться:
    c – передали функции f только один аргумент, a подставилось вместо x и на выходе мы получили… с=(y)=>2/y, т.е. ФУНКЦИЮ
    to – этой новой функции передали b, и уже она выдала конечный результат.
    Таким образом, замыкание (кложура!) – это упаковка функции в функцию (это упрощение - да простят меня функциональные теоретики). 
    Думаю, у вас один вопрос – зачем оно надо?! А вот зачем. Разберем немного упрощенный боевой пример:
    let
        from = Table.FromRecords({  [n="Вася",a=90,b=70,c=50],
                                    [n="Коля",a=120,b=130,c=110],
                                    [n="Петя",a=75,b=80,c=130]}),
        nms= Table.ColumnNames(from),
        lst=List.Skip(nms),
        f=(y)=>(x)=>[   a = Record.Field(x,y) , 
                        b = if a < 80 
                            then "ниже предела" 
                            else    if a > 120 
                                    then "выше предела" 
                                    else "ок"][b],
        g=(x)=>"Проверка "&x,
        acc = List.Accumulate(lst,from,(s,c)=>Table.AddColumn(s,g(c),f(c))),
        to = Table.SelectColumns(acc,{nms{0}}&List.Combine(List.Transform(lst,(x)=>{x,g(x)})))
    in
        to
    from –  на вход подана таблица с несколькими столбцами числовых значений, для каждого столбца нужно добавить столбец с оценкой 
            (проверить нахождение значения в диапазоне от 80 до 120). (а самый жесткий вариант у меня был - 34 столбца и ABC-анализ)
    nms  –  получили все имена,
    lst  –  получен список имён столбцов, по которым нужна оценка
    acc  –  ну самое разумное пройтись по списку lst - List.Accumulate(lst… и добавить для каждого оценку 
            Table.AddColumn(…; только есть проблема – для функции Table.AddColumn мы должны передать 
            функцию от одного аргумента, а именно – от записи (текущей строки) в таблице. 
            А нам нужно обращаться к разным полям, вот так и возникает конструкция
    
    f=(y)=>(x)=>[  
        a = Record.Field(x,y) , 
        b = if a < 80 then "ниже предела" else    if a > 120 then "выше предела" else "ок"
    ][b],
    
    Т.е. сначала мы функции f будем передавать y – и это будет имя нужного поля записи, и на выходе получать функцию 
    для обработки именно этого поля, что мы и используем в аккумуляторе:
    (s,c)=>Table.AddColumn(s,g(c),f(c))
    
    Т.е. добавить к таблице s оценку по полю c - f(c) и назвать столбец g(c)
    Зачем надо было писать ещё и функцию g? Да просто преобразование это нужно ещё и в последнем шаге – так немножко короче. 
    Мы же хотим оценку получить рядом, а не в конце таблицы, потому-то на шаге to мы и выбираем столбцы в интересующем нас порядке.
    Собственно, всё. Замыкания встречаются нечасто, но бывают просто незаменимы.
    ]

[   Коннектор к папке OneDrive Personal     / #ВсякиеКоннекторы
    
    К новому году небольшой подарочек. С наступлением на наши компьютеры ОС Windows 10/11 все больше граждан получают 
    в свое распоряжение облачный сервис OneDrive Personal. В отличие от такого же облака для бизнеса для него 
    отсутствует встроенный в PQ коннектор подключения к папке, чтобы динамически обновлять данные из добавляемых в неё файлов. 
    Тем не менее сама возможность такого забора со стороны Microsoft предусмотрена при помощи API. 
    Ниже прилагаю код функции, которая по аналогии с функцией Folder.Files точно также показывает вам какие 
    файлы имеются в папке на облаке и позволяет работать с их содержимым. 
    
    Как использовать? 
        1 Заходим в облако, 
        2 тыкаем правой кнопкой по папке и выбираем пункт "поделиться", 
        3 в появившемся меню жмем "копировать ссылку" и уже эту ссылку скармливаем моей функции. 
    Тип авторизации выбираем анонимный. Пользуйтесь на здоровье.
    
    OneDriveFolderFiles = (url)=>
        let
            //  Функция перекодирования ссылки в понятный формат для API
                fx = (t)=> Binary.ToText( Text.ToBinary( t, TextEncoding.Utf8 ), BinaryEncoding.Base64 ),
                API_URL = "https://api.onedrive.com/v1.0/shares/",
            
            //  тащим путь из параметра с адресом к общей папке из облака Onedrive
                FolderUrl = url,
            
            //  преобразовываем ссылку для получения токена для API
                UrlToBase64 = fx( FolderUrl ),
            
            //  заменяем всякое согласно инструкции по ссылке:
            //  https://docs.microsoft.com/ru-ru/onedrive/developer/rest-api/api/shares_get?view=odsp-graph-online#encoding-sharing-urls
                Replaced = Text.Replace( Text.Replace( Text.TrimEnd( UrlToBase64, "=" ), "/", "_" ), "+", "-" ),
            
            //  формируем итоговый текстовый параметр для передачи в RelativePath
                EncodedPath = "u!" & Replaced & "/root/children",
            
            //  тащим содержимое папки из API
                Source = Json.Document(Web.Contents( API_URL, [RelativePath = EncodedPath] ) ),
            
            //  преобразовываем полученный JSON в табличку с содержимым папки
                TableFromRecords = Table.FromRecords( Source[value] )[ [name], [webUrl] ],
            
            //  добавляем столбец с текстовыми параметрами для передачи в RelativePath
                AddColEncodedPaths = 
                    Table.AddColumn(
                        TableFromRecords,
                        "GetRelativePath",
                        each "u!" & fx([webUrl]) & "/root/content"
                    ),
            //  достаем бинарники по сформированным ссылкам, дальше по аналогии как с обычными файлами с диска
                GetBinaries = 
                    Table.AddColumn(
                        AddColEncodedPaths,
                        "Content",
                        each Web.Contents(API_URL, [RelativePath = [GetRelativePath]] ),
                        Binary.Type
                    )
            in
                GetBinaries

    З.Ы. Если для работы нужны всякие дополнительные свойства файлов или еще какие-то атрибуты, то достаточно в шаге TableFromRecords удалить вот это в квадратных скобках: [[name],[webUrl]]. Тогда увидите все, что может показать API про вашу папку.
    ]    

[   Измерение скорости выполнения запросов  / #ПолезныеСсылки
    
    Имеется небольшая надстройка, предназначенная для оценки скорости выполнения запросов PQ в среде MS Excel. Вместе со справкой сложена на гитхаб:
    https://github.com/buchlotnik/Merka
    ]

[   Как объединить текстовые значения       / #АнатомияФункций – Text.Insert

    Всем привет! С наступающим!
    По этому поводу небольшая лёгкая заметка )))
    Возьмем простую задачку - есть имя и есть текст поздравления и надо их как-то объединить.
    Сразу накидаем вариантов:

        let
            name = "Евлампий",
            congratulation = "С Новым Годом !!!",
            lst = {"Акакий","Евлампий","Глафира"},

            out1  = name & ", " & congratulation,
            out2  = Text.Combine({name,congratulation},", "),
            out3  = Text.Format("#{0}, #{1}",{name,congratulation}), // #{0} = name, #{1} = congratulation
            out3a = Text.Format("Глубокоуважаемый и горячо любимый #{0}, в этот знаменательный день пишу Вам, чтобы сказать - #{1}. Желаю здоровья, счастья и успехов!",{name,congratulation}),
            out4  = Text.Insert(congratulation,0,name&", "),
            out5  = Text.ReplaceRange(congratulation,0,0,name&", "),

            fnComb = (x,y)=> Text.ReplaceRange(y,0,0,x&", "),
            out6   = fnComb(name,congratulation),
            
            fnClojureComb=(x)=>(y)=>Text.Insert(x,0,y&", "),
            out7   = List.Transform(lst,fnClojureComb(congratulation))
        in
            out7

    И разберем -
    out1 - простейший вариант через амперсанд
    out2 - то же, но через Text.Combine - полезно, когда соединяем несколько значений из списка (обращаю внимание - в список можно объединять результаты разных шагов запроса)
    out3 - не самый очевидный вариант, но бывает полезным, когда у вас есть достаточно большой текст, по которому нужно раскидать переменные - как в варианте out3a (обращаем внимание, что переменные опять же передаем списком, хотя есть и вариант передавать их записью)
    out4 - текст не обязательно комбинировать, можно же и запихнуть один в другой
    out5 - причем запихивать можно и через замену - посмотрите, просто заменяем текст нулевой длины - зачем так? да незачем - просто не бывает какого-то одного правильного варианта, их всегда несколько и вы можете выбирать наиболее удобный и понятный для себя
    fnComb - и раз уж мы про функции - любой такой шаг можно превратить в функцию, всё то же самое, просто конкретные названия шагов меняем на абстрактные переменные
    out6 - а при использовании функции передаем то, что необходимо
    fnClojureComb - ну и куда ж без замыканий - мало ли текст поздравления будет меняться, да и список может быть разным
    out7 - пример использования (особо не распространяюсь - подробности были тут)

    К чему это всё? Да просто показать, что на одну и ту же задачу можно смотреть очень по-разному, а какой путь выбрать - решение каждого.
    Поэтому в Новом Году желаю каждому найти свою функцию и успешно ее применить 😉
    ]

[   (x,y)=>x[y] или как правильно обращаться к полям в функции / //! #АнатомияФункций - Table.Column, Record.Field
    
    Всем привет!
    
    Продолжим рассмотрения вопроса написания пользовательских функций. Сегодня на повестке обращение к элементам и полям.
    Начнём с простого:
       
        let
            lst = {1,2,3,4,5},
            f   = (x,y)=>x{y},
            to  = f(lst,2)
        in
            to

    Вернёт нам 3. Здесь логика, думаю, понятна – нас интересует y-ый элемент списка x. Нумерация с нуля, поэтому 2 обозначает третий))). Зачем такое пихать в функцию? Ну например, чтобы можно было писать вот так:
        
        f = (x,y)=>x{y-1},
        to = f(lst,3)

    что также вернёт нам 3, но только в этот раз мы явно попросили третий элемент и не думали как там на самом деле идет нумерация. Так бывает удобно.
    Но что же с полями записи или таблицы?
        
        let
            rec = [a=1,b=2,c=3],
            tbl = Table.FromRecords({rec}),
            f = (x,y)=>x[y],
            to1 = f(rec,"b"),
            to2 = f(tbl,"b")
        in
            to2

    Упс…
    to1 - «поле y записи не найдено».
    to2 – «столбец y таблицы не найден»
    Делаем вывод – так не работает (хотя в спецификации на язык явно используется конструкция x[y], но там под y подразумевается именно название поля, а не некое вычисляемое значение).
    Решение есть – использовать функции, причем для записей и таблиц они разные – Record.Field и Table.Column соответственно:
        
        let
            rec = [a=1,b=2,c=3],
            tbl = Table.FromRecords({rec}),
            f   = (x,y)=>Record.Field(x,y),
            g   = (x,y)=>Table.Column(x,y),
            to1 = f(rec,"b"),
            to2 = g(tbl,"b")
        in
            to2

    И теперь всё корректно.
    Закономерный вопрос – а зачем вообще нужно запихивать обращение к полям в функции? Рассмотрим пример с группировкой таблицы:
    
        let
            tbl = Table.FromRecords(
                {   [n="Вася", a=1,b=2,c=3,d=4],
                    [n="Антон",a=1,b=3,c=5,d=7],
                    [n="Вася", a=5,b=6,c=7,d=8],
                    [n="Антон",a=2,b=4,c=6,d=8]
                }),
            group = Table.Group(tbl, {"n"}, {{"сумма по a", each List.Sum([a]), type number}})
        in
            group
    
    Так группировка, разумеется, работает. Но что если задача у нас будет найти суммы по всем столбцам, кроме первого? Ладно когда их 4, а если пара десятков? А если их список динамически меняется?
    Для начала обратим внимание на эту конструкцию -
        {"сумма по a", each List.Sum([a]), type number}
    - для каждого столбца нам нужно получить список из трёх параметров {название,функция,тип} (хотя можно обойтись только парой {название,функция})
    Далее внимательно смотрим на
        each List.Sum([a])
    , вспоминаем, что это то же самое, что и (x)=>List.Sum(x[a]) (кому не понятно - читаем тут )
    
    Осталось только сообразить, что под x в данном случае подразумевается таблица (та самая, которую вы получаете выбрав при группировке "все строки").
    Теперь мы готовы воспользоваться вышеуказанным приёмом:
        
        let
            tbl =   Table.FromRecords(
                        {   [n="Вася",a=1,b=2,c=3,d=4],
                            [n="Антон",a=1,b=3,c=5,d=7],
                            [n="Вася",a=5,b=6,c=7,d=8],
                            [n="Антон",a=2,b=4,c=6,d=8] }),
            nms =   Table.ColumnNames(tbl),
            lst =   List.Transform(
                        List.Skip(nms),
                        (x)=>{"Сумма по " & x, (y)=>List.Sum( Table.Column(y,x) ), Int64.Type}
                    ),
            group = Table.Group(tbl, nms{0}, lst)
        in
            group

    nms     – получили имена всех столбцов
    lst     – получаем список преобразований для всех столбцов, кроме первого (List.Skip), превращаем каждое название столбца в тройку {название,функция,тип}. 
    Не запутайтесь:
    
        x                                – это название исходного столбца, от него пишем исходное преобразование, 
        "Сумма по " & x                  – название столбца после группировки; 
        (y)=>List.Sum(Table.Column(y,x)) – вложенная функция, поэтому использована другая переменная y, запись означает «в таблице y возьми столбец x и найди сумму значений»
    
    group   – группируем таблицу по первому столбцу (nms{0}) используя список преобразований lst

    Собственно, всё (есть дополнение). Столбцы проанализированы пачкой. И это одна из наиболее простых и очевидных задач, решаемых подобным способом.
    ]
    
[   Как правильно обращаться к полям в функции (дополнение) / #АнатомияФункций

    Дополнение, которое не влезло в объем основного поста:
    1. для конструкций record[[ ],[ ],[ ]] и table[[ ],[ ],[ ]] используйте Record.SelectFields и Table.SelectColumns соответственно
    2. для большей прозрачности кода хорошо использовать замыкания (подробнее про них тут):
    
        let
            tbl = Table.FromRecords({   [n="Вася", a=1, b=2, c=3, d=4],
                                        [n="Антон",a=1, b=3, c=5, d=7],
                                        [n="Вася", a=5, b=6, c=7, d=8],
                                        [n="Антон",a=2, b=4, c=6, d=8]
                                    }),
            nms  = Table.ColumnNames(tbl),
            f=(x)=>(y)=>List.Sum(Table.Column(y,x)),
            lst  = List.Transform(List.Skip(nms),(x=> { "Сумма по " & x, f(x), Int64.Type }),
            to   = Table.Group(tbl, nms{0}, lst)
        in
            to
    ]

[   List.Accumulate – а надо ли? / #АнатомияФункций - List.Accumulate

    Всем привет!
    Как работает функция List.Accumulate
    По просьбам трудящихся разберем функцию List.Accumulate. Читаем справку:
        
        List.Accumulate(list as list, seed as any, accumulator as function)
        
        list – список, элементы которого мы перебираем
        seed - начальное значение
        accumulator - функция, выполняющая операцию над очередным элементом списка и накапливающая результат обработки в переменной.
            accumulator – функция от двух переменных- (state,current)=> где 
                state   - текущее накопленное значение (на первой итерации это seed), 
                current - текущий элемент списка list

    Для чего используется функция? В сети можно найти много вариантов, доказывающих «универсальность» функции. 
    
    Тут вам и сумма:
    
        List.Accumulate({1..10}, 0, (s,c)=>s+c)
    
    И преобразование списков:
    
        List.Accumulate(
            {1..10},
            {},
            (s,c)=>s & {"Column" & Text.From(c)}
        )
    
    И даже работа с таблицами:
    
        List.Accumulate(
            {1..9},
            Table.FromColumns({{1..9}},{"n"}),
            (s,c)=>Table.AddColumn(s, Text.From(c), (r)=>Record.Field(r,"n")*c)
        )
    
    Проблема в том, что сумму гораздо проще найти через List.Sum, список проще (и быстрее) преобразовать через List.Transform. Это к тому, что функцию List.Accumulate примотать можно к большому числу задач, но это не будет самым простым и быстрым решением. По случаю порылся в архивах и предлагаю пару примеров, где реально в первом приближении без Accumulate не обойтись.
    
        let
            f =(x,y)=>
                [   a = Text.Split(y,":"), 
                    b = Record.AddField(x, a{0}, a{1})
                ]  [b],
            g=(x)=>
                List.Accumulate(
                    Text.Split(x,";"),
                    [],
                    f
                ),

            from = {"название:коробка;высота:11;ширина:120;длина:54",
                    "название:бак;ширина:50;высота:120",
                    "название:ящик;длина:123;ширина:12"},
            tr = List.Transform(from,g),
            to = Table.FromRecords(tr,null,MissingField.UseNull)
        in
            to

    from – на вход подана некая выгрузка, в которой присутствуют пары «параметр:значение», разделенные через точку с запятой – а надо собрать таблицу
    tr – преобразуем список в список записей (нам же нужно сохранить информацию где поле, где значение)
    to - ну и собираем таблицу (второй аргумент null – поскольку набор полей нам заранее не известен, третий - MissingField.UseNull – если в отдельной записи поля не будет вместо ошибки выдаст null – удобно, берем на заметку)
    
    Теперь по функциям:
    g – функция от одного аргумента, потому что отвечает за преобразование элемента списка; её работа состоит в разделении текста по «;» и агрегации полученного списка в запись, поэтому в качестве seed – [ ] (пустая запись), а аккумулятор – f
    f – функция от двух аргументов (это те же state и current – но использованы x и y дабы показать, что название переменной не имеет значения!) – здесь всё просто: a – поделили текст по «:», b – добавляем к записи новое поле (можно было и через let, но я так не люблю, объяснял тут)
    
    Собственно задача решена. Мне проще было через Accumulate, есть альтернативная точка зрения – использовать рекурсию (Poohkrd оцени, эксклюзивно для тебя):
        
        let
            f=(x,y)=>[a=Text.Split(y,":"), b= Record.AddField(x,a{0},a{1})][b],
            g=(x,y)=>if Text.Contains(y,";") then @g(f(x,Text.BeforeDelimiter(y,";")),Text.AfterDelimiter(y,";")) else f(x,y),

            from = {"название:коробка;высота:11;ширина:120;длина:54",
                    "название:бак;ширина:50;высота:120",
                    "название:ящик;длина:123;ширина:12;высота:1"},
            tr = List.Transform(from,(x)=>g([],x)),
            to = Table.FromRecords(tr,null,MissingField.UseNull)
        in
            to
    
    Смотрите кому как удобнее, по скорости одинаково. Просто помните, что рекурсия – это не быстро, Accumulate выигрыша по скорости не даст, а значит использовать этот приём стоит только в тех ситуациях, когда нет прямой альтернативы или альтернативный путь тернист для написания.
    ]
[   List.Accumulate – как написать «пустой» второй аргумент / #АнатомияФункций – List.Accumulate

    Всем привет!
    Давно зрело и вот нашёлся информационный повод.
    Итак, возвращаемся к нашему List.Accumulate (помним, что медленный, но иногда удобный).
    
        List.Accumulate(list as list, seed as any, accumulator as function) as any

    Второй аргумент – seed - опорное значение, которое может быть любым, но сегодня мы его хотим сделать пустым (или нулевым, но не null чтобы всё работало).
    Допустим нужно просуммировать нечётные числа в списке:
    
        List.Accumulate(
            {1,2,3,4,5},
            0,
            (s,c)=>if Number.IsOdd(c) then s+c else s
        )
    
    Тут у нас простая арифметика, поэтому seed - 0 - просто ноль, с которым всё суммируем
    Собираем через пробел значения из списка, чья длина больше или равна трем символам
    
        List.Accumulate(
            {"лучшие","запросы","оптом","и","в","розницу"},
            "",
            (s,c)=>if Text.Length(c)>2 then Text.Combine({s,c}," ") else s
        )
    
    На выход подаём строку, поэтому seed – ""- пустая строка, с которой всё конкатенируем
    Аналогичная логика со списками – опять выбираем нечётные числа, но теперь списком:
    
        List.Accumulate(
            {1,2,3,4,5},
            {},
            (s,c)=>if Number.IsOdd(c) then s&{c} else s
        )
    
    Здесь опорное значение должно быть списком, к которому мы всё добавляем, поэтому seed – {} – пустой список (также обращаем внимание на синтаксис добавления нового элемента к существующему списку – скобочки там не просто так)

    А вот ситуация c записями (с ней сталкиваемся, например, при парсинге, когда значения нескольких полей идут как одно строковое):
    
        List.Accumulate(
            { {"длина",100},{"ширина",50},{"высота",10} },
            [],
            (s,c)=>Record.AddField(s,c{0},c{1})
        )
    
    На вход подается список списков (поле – значение), но на выходе хотим запись – значит seed – [ ] – пустая запись. Также обращаю внимание, что добавление осуществляем не через конкатенацию, а через функцию (проблема аналогично той, которую описывал ранее). Ну и помним, что при аккумулировании списка списков – c – это тоже список и можно обращаться к отдельным его элементам, как в примере.

    Ну и всё это вроде и так понятно, осталось только разобраться с таблицами. Вчера в миру был пример. Нужно получить полное декартово произведение – как это делать через джоин уже описывал Пух. Вопрос теперь в другом – а как сджойнить несколько таблиц? Смотрим код:

        let
            lst = {"Город","Год","Продукт"},
            f   = (x)=> Excel.CurrentWorkbook(){[Name=x]}[Content],
            g   = (x,y)=> Table.Join(x,{},f(y),{}),
            to  = List.Accumulate(lst,#table({},{{}}),g)
        in
            to

    По шагам:
    lst – список таблиц (можно его и запросом получить, я в курсе, но было бы не так наглядно)
    f   – вспомогательная функция – подключение к конкретной таблице (оптимизаторам молчать! можно вообще без имён, одним подключением, отфильтровав только таблицу самого запроса... ДА МОЖНО и закрыли тему)
    g   – функция для аккумулятора (мы же помним, что функции стоит выносить) – тут к таблице x (кому удобнее – пишите s или state – это не принципиально), джойнится таблица f(y) – т.е. таблица из файла с именем y
    to  – ну и сам аккумулятор – 
            смотрим на seed - #table({},{{}}) – примерно так выглядит пустая таблица – пустой список имён столбцов и пустой список списков значений строк – это не единственный вариант - мне просто нравится, когда много фигурных скобок 😉
    
    Собственно всё – к пустой таблице последовательно джойнятся все необходимые - задачка решена.
    Так что аккумулируя что-то с нуля определитесь с типом данных на выходе и выбирайте соответствующий seed - тогда всё получится.
    ]
    
[   List.Accumulate WITH recursion – а что, так можно было? / #АнатомияФункций – List.Accumulate
    Всем привет!
    Чтобы окончательно закрыть вопрос с аккумулятором и рекурсией (начали тут) давайте разберем ещё один пример. Итак, например, при парсинге сайта, вы получили некий список значений, а вам нужны уникальные. Ну ОК – элементарный код:
    let
        lst = {1,2,3,1,2,3,1,2,3},
        to = List.Distinct(lst)
    in
        to
    Но если б всё было так просто, не было бы статьи. Далеко не всегда значения идут по одному:
    let
        lst = {1,2,3,{1,4,5},2,{3,6,7},1,2,3},
        acc = List.Accumulate(lst,{},(s,c)=> s & (if Value.Is(c,List.Type) then c else {c})),
        to = List.Distinct(acc)
    in
        to
    Здесь на шаге acc мы реализуем следующую логику: «если очередной элемент – список, сделай конкатенацию списков s & c, иначе добавь к списку элемент s &{c}». Тоже вроде просто. Немного усложню код:
    let
        lst = {1,2,3,{1,4,5},2,{3,6,7},1,2,3},
        f=(x)=>List.Accumulate(x,{},(s,c)=> s & (if c is list then c else {c})),
        to = List.Distinct(f(lst))
    in
        to
    обратите внимание, что шаг запроса превращён в функцию (заодно if then записан немножко по-другому - может так кому понятнее или удобнее будет), всё остальное то же самое. Но зачем это надо? А вот зачем – кто сказал, что будут только списки, а не списки списков или списки списков списков… (чувствуете как рекурсией запахло)?
    let
        lst = {1,2,3,{1,4,{5,8}},2,{3,{6,9},7},1,2,3},
        f=(x)=>List.Accumulate(x,{},(s,c)=> s & (if c is list then @f(c) else {c})),
        to = List.Distinct(f(lst))
    in
        to
    А вот это уже гемор. И в этой ситуации, независимо от числа уровней вложенности, мы решаем поставленную задачку с помощью @f(), т.е. рекурсивного вызова нашего аккумулятора. На мой вкус очень просто и элегантно.
    ]
    
[   Нормализация таблицы с повторяющимися заголовками / #АнатомияФункций - List.Accumulate
    
    Пы.Сы. (основной пост)
    там же в архивах нашлась другая, весьма специфическая задачка, также весьма просто решаемая аккумулятором, но на мой вкус это скорее учебный пример – не надо так данные изначально организовывать:

        let
            from =  Table.FromRecords({
                        [n="Вася",#"a.1"=1,#"b.1"=2,#"c.1"=3,#"a.2"=4,#"b.2"=5,#"c.2"=6,#"a.3"=7,#"b.3"=8,#"c.3"=9],
                        [n="Петя",#"a.1"=1,#"b.1"=3,#"c.1"=5,#"a.2"=7,#"b.2"=9,#"c.2"=11,#"a.3"=13,#"b.3"=15,#"c.3"=17],
                        [n="Коля",#"a.1"=2,#"b.1"=4,#"c.1"=6,#"a.2"=8,#"b.2"=10,#"c.2"=12,#"a.3"=14,#"b.3"=16,#"c.3"=18]
                    }),
            
            lst =   Table.ColumnNames(from),
            nms =   List.Distinct(List.Transform(List.Skip(lst),(x)=>Text.BeforeDelimiter(x,"."))),
            cmb =   List.Zip({nms,List.Transform(nms, (x)=>List.Select(lst,(y)=>Text.Contains(y,x)))}),
            tbl =   Table.TransformColumnTypes(from,List.Transform(List.Skip(lst),(x)=>{x,Text.Type})),
            to  =   List.Accumulate(cmb,tbl,
                        (s,c)=>
                            Table.CombineColumns(s, c{1}, (x)=>Text.Combine(x," "), c{0})
                    )
        in
            to
    ]

[   Table.FromList vs Table.AddColumn – кто кого? / #АнатомияФункций – Table.FromList, Table.AddColumn

    Один известный вам медведь отправил меня читать таких же упоротых, как и я. Ну и подсмотрел идейку. Итак, на входе имеем таблицу с несколькими числовыми столбцами и нужно добавить по каждой строке агрегации – сумму, среднее и медиану. Делов-то:
       
        let
            from =  Table.FromRecords({
                        [n="Вася",jan=1,feb=2,mar=3,apr=4,may=5,jun=6],
                        [n="Коля",jan=1,feb=3,mar=5,apr=7,may=9,jun=9],
                        [n="Петя",jan=2,feb=4,mar=6,apr=8,may=8,jun=6]
                    }),
            tbl  = Table.Buffer(Table.Repeat(from,99999)),
            add1 = Table.AddColumn(tbl,"сумма",  (r)=>List.Sum    (List.Skip (Record.ToList(r)))),
            add2 = Table.AddColumn(tbl,"среднее",(r)=>List.Average(List.Range(Record.ToList(r),1,6))),  
            to   = Table.AddColumn(tbl,"медиана",(r)=>List.Median (List.Range(Record.ToList(r),1,6)))
        in
            to
    
    Что смущает в приведенном коде – обилие шагов, необходимость на каждом шаге вычислять требуемый диапазон для расчёта, ну и Table.Buffer - если забудете поставить, вычисляться запрос будет крайне долго, а так на моей машине потребовалось 13 секунд. Мысль с добавлением сразу всех агрегаций в виде записи с последующим Table.ExpandRecordColumn отметайте - это дорогая операция, особенно на больших таблицах – получилось вообще 17 секунд.
    Но что же делать? Чуйка подсказывает, что со списками работа шустрее, чем на записях. Что ж, пробуем:
       
        let
            f=(x)=>x &
                [a = List.Skip(x),
                 b = {List.Sum(a), List.Average(a), List.Median(a)}
                ][b],
            
            from =  Table.FromRecords({
                        [n="Вася",jan=1,feb=2,mar=3,apr=4,may=5,jun=6],
                        [n="Коля",jan=1,feb=3,mar=5,apr=7,may=9,jun=9],
                        [n="Петя",jan=2,feb=4,mar=6,apr=8,may=8,jun=6]
                    }),

            tbl = Table.Repeat(from,99999),
            lst = Table.ToRows(tbl),
            tr  = List.Transform(lst,f),
            nms = Table.ColumnNames(from) & {"сумма","среднее","медиана"},
            to  = Table.FromRows(tr,nms)
        in
            to

    Вроде выглядит неплохо: 
        lst – разбили на строки, 
        tr  – преобразовали строки списком, 
        f   - функция, добавляющая к списку его сумму, среднее и медиану, 
        nms – список столбцов новой таблицы, 
        to  - собрали таблицу из строк. 
    
    Обращаю внимание – буферить не потребовалось, НО скорость та же - 13 секунд. Мдя. 
    Собственно, с этой мыслью я и жил до вчера. Но тут напомнили, что в Table.FromList можно передавать не только Splitter:

        let
            f=(x)=>x&[a=List.Skip(x),b={List.Sum(a),List.Average(a),List.Median(a)}][b],
            
            from = Table.FromRecords({[n="Вася",jan=1,feb=2,mar=3,apr=4,may=5,jun=6],
                                      [n="Коля",jan=1,feb=3,mar=5,apr=7,may=9,jun=9],
                                      [n="Петя",jan=2,feb=4,mar=6,apr=8,may=8,jun=6]}),
            tbl = Table.Repeat(from,99999),
            lst = Table.ToRows(tbl),
            nms = Table.ColumnNames(from) & {"сумма","среднее","медиана"},
            to  = Table.FromList(lst,f,nms)
        in
            to

    Что поменялось? Да почти ничего – просто вместо двух шагов (tr и to) остался один; функция f та же, только скорость – 10 секунд! - 25% по производительности на пустом месте. Вот так, мир не рухнул – на списках всё-таки быстрее 😉
    ]

[   Запрос в одну строку или функции в отдельные шаги? / #АнатомияФункций
    
    Всем привет!
    Потянуло пофилософствовать. Итак, возьмем запрос

        let
            lst   = {1..12},
            trnsf = List.Transform(lst,(x)=>Date.ToText(#date(2022,x,1),"MMMM yyyy")),
            to    = Text.Combine(trnsf,"#(lf)")
        in
            to

    который совершенно не обязательно писать как выше, зачем вообще два раза указывать последний шаг:
    
        let
            lst   = {1..12},
            trnsf = List.Transform(lst,(x)=>Date.ToText(#date(2022,x,1),"MMMM yyyy"))
        in
            Text.Combine(trnsf,"#(lf)")

    Работает так же, некоторые считают, что так даже нагляднее (автор не разделяет данную точку зрения). В целом можно считать (упрощённо), что отдельные шаги – это просто куски кода, которым дали имя, и когда вы ссылаетесь на конкретный шаг – вместо имени этот кусок кода и подставляется. Поэтому если мы напишем просто:
    Text.Combine(List.Transform({1..12},(x)=>Date.ToText(#date(2022,x,1),"MMMM yyyy")),"#(lf)")

    это будет работать. Почему? Потому что в принципе весь запрос представляет собой одно выражение, его можно не делить на шаги и писать вот так в одну (но очень большую и совершенно нечитаемую) строку (т.е. вы можете использовать PQ как калькулятор – просто напишите 8*(127-13) и он вам выдаст результат).
    Но ведь можно задуматься и об обратном – мы для того и делим запрос на шаги, чтобы повысить его читаемость, а значит вместо вкладывания кучи функций друг в друга, можно поделить запрос на шаги, особенно если фрагмент повторяется или сложный и требует вложенных конструкций let in – выносим его в отдельный шаг с определенным именем, потом вызываем по необходимости.
    Например, код выше можно переписать так:
    
        let
            lst   = {1..12},
            f=(x) => Date.ToText(#date(2022,x,1),"MMMM yyyy"),
            trnsf = List.Transform(lst,f),
            to    = Text.Combine(trnsf,"#(lf)")
        in
            to

    получилось – f – это функция преобразования номера месяца в дату с определённым форматированием, а на шаге trnsf – мы эту функцию используем для преобразования элементов списка. По скорости оба варианта эквивалентны, но с точки зрения читаемости второй вариант на мой вкус лучше, особенно если мы говорим про сложные боевые примеры:
    
        let
            from  = Table.FromRecords(Json.Document(Binary.Decompress(Binary.FromText("rZM7EsIwDETv4jpFJPkj5ypAQQK5ARWTuzNoU5BOjmm28DyttbJ8eYd7mML1NUZh0/GrkUzXMIQ5TJyHsISplm3w4Al4Hn247O7kw1kNJ6e7JsNT9uF5RDPqdK+Gx+qMSk29ixjuHDtF9CIH3EB5GIjSJ05QVBCglJaizBhSailSOlNUMDBtak9O3MTYE2oaHvb80Byln1eaf1wW09VUTev+brCR2GeDX6Slz4Uxu9SZqeAbxc5MhO3kzlCa/xKKscGJttsH"),Compression.Deflate))),
            group = Table.Group(from, "a", {{"sum b", each List.Sum(List.FirstN(List.Sort([b],Order.Descending),3))},{"sum c",each List.Sum(List.FirstN(List.Sort([c],Order.Descending),3))}})
        in
            group

    хорошо, если столбцов два, а когда больше? А так мы выносим функцию и получаем счастье:
    
        let
            from = Table.FromRecords(Json.Document(Binary.Decompress(Binary.FromText("rZM7EsIwDETv4jpFJPkj5ypAQQK5ARWTuzNoU5BOjmm28DyttbJ8eYd7mML1NUZh0/GrkUzXMIQ5TJyHsISplm3w4Al4Hn247O7kw1kNJ6e7JsNT9uF5RDPqdK+Gx+qMSk29ixjuHDtF9CIH3EB5GIjSJ05QVBCglJaizBhSailSOlNUMDBtak9O3MTYE2oaHvb80Byln1eaf1wW09VUTev+brCR2GeDX6Slz4Uxu9SZqeAbxc5MhO3kzlCa/xKKscGJttsH"),Compression.Deflate))),
            f=(y,z)=>(x)=>[ a = Table.Column(x,y),
                            b = List.Sort(a,Order.Descending),
                            c = List.FirstN(b,z),
                            d = List.Sum(c)][d],
            group = Table.Group(from, "a", {{"sum b", f("b",3)},{"sum c",f("c",3)}})
        in
            group
    
    Обращаю внимание – на шаге f использовано замыкание – мы просто передаем функции имя столбца и число элементов, которые надо просуммировать – мало ли что поменяется; расписали по шагам – так нагляднее, но согласитесь – больше одного раза вы бы вряд ли стали это делать. Сам синтаксис через записи обсуждался тут, а как ещё сильнее сократить/упростить код – обсуждалось здесь.
    В целом этим постом я хотел сказать, что написание функций – это не какая-то запредельная задача – это просто вынесение определённых повторяющихся шагов в шаг с определенным именем для многократного и удобного использования в коде.
    ]
    
[   Table.Group – Часть 1. Третий аргумент / #АнатомияФункций – Table.Group
    
    Всем привет!
    По запросам страждущих немножко опишу работу с этой замечательной функцией.Начнём с простого:
        
        let
            from = Table.FromRecords(Json.Document(Binary.Decompress(Binary.FromText("rZM7EsIwDETv4jpFJPkj5ypAQQK5ARWTuzNoU5BOjmm28DyttbJ8eYd7mML1NUZh0/GrkUzXMIQ5TJyHsISplm3w4Al4Hn247O7kw1kNJ6e7JsNT9uF5RDPqdK+Gx+qMSk29ixjuHDtF9CIH3EB5GIjSJ05QVBCglJaizBhSailSOlNUMDBtak9O3MTYE2oaHvb80Byln1eaf1wW09VUTev+brCR2GeDX6Slz4Uxu9SZqeAbxc5MhO3kzlCa/xKKscGJttsH"),Compression.Deflate))),
            f=(x)=>List.Sum(x[b]),
            group = Table.Group(from, "a", {"sum b",f})
        in
            group
    
    Посмотрим на аргументы Table.Group:
    
        Первый аргумент – сама таблица
        
        Второй аргумент – столбец или список столбцов, по которым нужно группировать (обращаю внимание – мышкоклацанием один столбец все равно будет записан как список из одного элемента - {“c”}. Какая разница? – спросите вы – Дойдем до пятого аргумента – объясню – отвечу я )
        
        Третий аргумент – агрегация или список агрегаций, т.е. либо {«агрегирующий столбец»,функция_агрегации}, либо {{«агрегирующий столбец1»,функция_агрегации1 },{«агрегирующий столбец2»,функция_агрегации2}}
    
    И вот тут нужно разобраться. Функция агрегации вычисляет что-то на основании результата группировки, но что является этим результатом? Подставьте в запрос выше вместо функции f такое f=(x)=>x – и вы увидите, что результатом является таблица. И это самое важное знание.
    
    Разберем f=(x)=>List.Sum(x[b]) - x[b] – это обращение к столбцу таблицы, которое дает нам список значений, далее мы этот список суммируем (в варианте each List.Sum([b]) который вы получите мышкоклацанием это не очевидно – обсуждалось тут).
        
    Теперь же мы понимаем, что с таблицей можно творить всякое – допустим вам нужно не просто получить сумму, а найти суммарную разницу по двум столбцам (можно конечно допстолбец добавить или пойти через CombineColumns, но мы же не хотим ничего усложнять):
        
        let
            from = Table.FromRecords(Json.Document(Binary.Decompress(Binary.FromText("rZM7EsIwDETv4jpFJPkj5ypAQQK5ARWTuzNoU5BOjmm28DyttbJ8eYd7mML1NUZh0/GrkUzXMIQ5TJyHsISplm3w4Al4Hn247O7kw1kNJ6e7JsNT9uF5RDPqdK+Gx+qMSk29ixjuHDtF9CIH3EB5GIjSJ05QVBCglJaizBhSailSOlNUMDBtak9O3MTYE2oaHvb80Byln1eaf1wW09VUTev+brCR2GeDX6Slz4Uxu9SZqeAbxc5MhO3kzlCa/xKKscGJttsH"),Compression.Deflate))),
            f=(x)=> List.Sum(x[b])-List.Sum(x[c]),
            group = Table.Group(from, "a", {"diff b c",f})
        in
            group

    Обращаю внимание – с первого запроса поменялась только функция f (это к тому, что функцию лучше вынести, чем каждый раз лазать в дебри запроса). Как видим – с несколькими полями всё также прекрасно работает.
    Ну и раз уж аргументом является таблица, можем задействовать всю мощь табличных функций. Например, часто спрашивают как добавить нумерацию, но внутри группы:
       
        let
            from = Table.FromRecords(Json.Document(Binary.Decompress(Binary.FromText("rZM7EsIwDETv4jpFJPkj5ypAQQK5ARWTuzNoU5BOjmm28DyttbJ8eYd7mML1NUZh0/GrkUzXMIQ5TJyHsISplm3w4Al4Hn247O7kw1kNJ6e7JsNT9uF5RDPqdK+Gx+qMSk29ixjuHDtF9CIH3EB5GIjSJ05QVBCglJaizBhSailSOlNUMDBtak9O3MTYE2oaHvb80Byln1eaf1wW09VUTev+brCR2GeDX6Slz4Uxu9SZqeAbxc5MhO3kzlCa/xKKscGJttsH"),Compression.Deflate))),
            f=(x)=> Table.AddIndexColumn(x,"i",1,1),
            group = Table.Group(from, "a", {"tmp",f} ),
            to    = Table.Combine(group[tmp])
        in
            to

    Думаю, с работой функции для добавления индексного столбца сложностей не возникнет. А вот шаг to – просто обратите внимание – в столбце tmp у нас таблицы, group[tmp] – список этих таблиц, и этот список мы отдаём Table.Combine – всё, задача решена.
    Или такое – нужно получить по каждому сотруднику лучшую продажу или последнюю дату – это решается через Table.Max:
        
        let
            from = ...//взять из первого запроса,
            f=(x)=>Table.Max(x,"b"),
            group = Table.Group(from, "a", {"tmp",f}),
            to = Table.FromRecords(group[tmp])
        in
            to

    Обращаю внимание – Table.Max возвращает запись, поэтому в шаге to мы используем Table.FromRecords.
    Вот, пожалуй, и всё – если вы понимаете, что агрегируете (точнее с чем приходится работать вашей функции) задачи решаются просто и элегантно.
    ]
    
[   Table.Group – Часть 1.1 Третий элемент третьего аргумента – тип данных / #АнатомияФункций – Table.Group
    
    Всем привет!
    Продолжаем изыскания по Table.Group – надо обсудить третий элемент (это не влезло в предыдущий пост), а именно: полный синтаксис агрегации выглядит как {«агрегирующий столбец1»,функция_агрегации1, тип_данных_агрегации }
    Суть в том, что при группировке мы можем сразу определить тип столбца на выходе. Возьмем пример из прошлого поста:
        
        let
            from = Table.FromRecords(Json.Document(Binary.Decompress(Binary.FromText("rZM7EsIwDETv4jpFJPkj5ypAQQK5ARWTuzNoU5BOjmm28DyttbJ8eYd7mML1NUZh0/GrkUzXMIQ5TJyHsISplm3w4Al4Hn247O7kw1kNJ6e7JsNT9uF5RDPqdK+Gx+qMSk29ixjuHDtF9CIH3EB5GIjSJ05QVBCglJaizBhSailSOlNUMDBtak9O3MTYE2oaHvb80Byln1eaf1wW09VUTev+brCR2GeDX6Slz4Uxu9SZqeAbxc5MhO3kzlCa/xKKscGJttsH"),Compression.Deflate))),
            f=(x)=>List.Sum(x[b]),
            group = Table.Group(from, "a", {"sum b",f,Int64.Type} )
            
        in
            group

    Здесь добавлен целочисленный тип Int64.Type – мне так захотелось, поскольку столбец целочисленный. Но обращаю внимание – мышкоклацанием вы получите type number – т.е. число с плавающей точкой (судя по всему автоматически определяется только примитивный тип, независимо от того, какой столбец агрегируется), поэтому будьте внимательны и проверяйте данный момент, если группируете через интерфейс.
    Аналогично для таблицы:
        
        let
            from = Table.FromRecords(Json.Document(Binary.Decompress(Binary.FromText("rZM7EsIwDETv4jpFJPkj5ypAQQK5ARWTuzNoU5BOjmm28DyttbJ8eYd7mML1NUZh0/GrkUzXMIQ5TJyHsISplm3w4Al4Hn247O7kw1kNJ6e7JsNT9uF5RDPqdK+Gx+qMSk29ixjuHDtF9CIH3EB5GIjSJ05QVBCglJaizBhSailSOlNUMDBtak9O3MTYE2oaHvb80Byln1eaf1wW09VUTev+brCR2GeDX6Slz4Uxu9SZqeAbxc5MhO3kzlCa/xKKscGJttsH"),Compression.Deflate))),
            f=(x)=>Table.AddIndexColumn(x,"i",1,1),
            group = Table.Group(from, "a", 
                        {"tmp", f, type table [b = Int64.Type, c = Int64.Type, i = Int64.Type]}
                    ),
            to = Table.ExpandTableColumn(group, "tmp", {"b", "c", "i"})
        in
            to

    Обращаю внимание – тип в данном случае задан не только для исходных столбцов, но и для добавляемого столбца индекса "i", т.е. типизируем мы конечный результат, что удобно и не может не радовать.

    Ложка дёгтя состоит в том, что если вместо ExpandTableColumn вам нужно использовать Combine - данные о типах слетают (почему - подробно расписал Максим Зеленский тут), но это дело поправимое - просто переносим типизацию на следующий шаг:
        let
            from = Table.FromRecords(Json.Document(Binary.Decompress(Binary.FromText("rZM7EsIwDETv4jpFJPkj5ypAQQK5ARWTuzNoU5BOjmm28DyttbJ8eYd7mML1NUZh0/GrkUzXMIQ5TJyHsISplm3w4Al4Hn247O7kw1kNJ6e7JsNT9uF5RDPqdK+Gx+qMSk29ixjuHDtF9CIH3EB5GIjSJ05QVBCglJaizBhSailSOlNUMDBtak9O3MTYE2oaHvb80Byln1eaf1wW09VUTev+brCR2GeDX6Slz4Uxu9SZqeAbxc5MhO3kzlCa/xKKscGJttsH"),Compression.Deflate))),
            f=(x)=>Table.AddIndexColumn(x,"i",1,1),
            group = Table.Group(from, "a", {"tmp",f}),
            to    = Table.Combine(
                        group[tmp], 
                        type table [a = text, b = Int64.Type,c = Int64.Type,i = Int64.Type]
                    )
        in
            to
    Вуаля - все работает как надо, таблица на выходе типизирована, как мы и хотели.
    ]

[   Table.Group – Часть 2. Четвертый аргумент / #АнатомияФункций – Table.Group
    
    Всем привет!
    Закончили с агрегациями - переходим к четвертому аргументу. Здесь не буду вас долго утомлять:
    Во-первых, он есть
    Во-вторых, возможны всего лишь два варианта – GroupKind.Global и GroupKind.Local
    Если вы никогда не писали четвертый аргумент, имейте в виду, что вы пользовались GroupKind.Global
    Разница состоит в том, что Global объединяет все значения с данным ключом в одну группу, а Local – все последовательно идущие значения с ключом в одну группу.
    Когда нам это надо? Например, вы группируете по месяцам, но не хотите, чтобы январь 2021 сгруппировался с январём 2022, или идёт сменная/вахтовая работа, и вам важно понять выработку за каждую вахту:
        
        let
            from = Table.FromRecords(Json.Document(Binary.Decompress(Binary.FromText("zZe7agNBDEX/ZWsL9JjZh78jXZwigXyCK+N/t2aNiZ3CXJAKwSC2GC2n2KO9+rxMpzM3a3vlUZven6fjpKxKLH4+mI/7mQ73Bn1q6P/a3l+Ql1e0n73y322Tvf4+9Xw/Xi3XAwRsXATYIGAlXYsAdwjYSLciwAsE3EiXIsAbBNxJ5yLAglk3k7YqxJh2C6klEmuEGPNuJc0cxSFiTLyNJHNShIgh84RJModxhFgh80RIMmdFiBgyT/z0KsSAeTYyhWTOish0U8A8G6FCqsQ2BcyzkSpEixAbYJ6NWCFlkiZgno1cwVWSm2Hmzf6jrkKMmbc4dJHpZph5q3/KRYgbZt7mA64KMWSe54rUNTpEDJnnxKl7dIgYMs+TUOoiHSKGzPMklLqYRoi7XL9u"),Compression.Deflate))),
            f=(x)=>
                [   a=(y)=>Text.From(Date.From(Text.Split(y,"T"){0})),
                    b = a(List.Min(x))&" - "&a(List.Max(x))
                ]   [b],
            to = Table.Group(from, "вахта", 
                    {  
                        {"период",   (x)=>f(x[дата]), Text.Type},
                        {"выработка",(x)=>List.Sum(x[выработка]), Int64.Type}
                    },
                    GroupKind.Local)
        in
            to

    Просто сравните выполнение запроса с четвёртым параметром и без.
    Ещё обращаю внимание на шаг f – функции можно упаковывать в функции – почему бы и нет, компактно и надеюсь наглядно.
    Ну и надо сделать ещё пару замечаний - GroupKind.Global и GroupKind.Local – это НЕ функции, а константы – в чём легко убедиться выполнив Number.From(GroupKind.Global) и Number.From(GroupKind.Local) – выдаст 1 и 0 соответственно. 
    
    Т. е. если вы относитесь к людям, которые верят, что чем короче код, тем он быстрее – заменяйте громоздкое выражение на числовое (но вообще не рекомендую – значения констант быстро забываются, но помнить о них надо – на просторах интернета встречал использование числовых значений, теперь вы будете знать, что это за нолик).
    
    Ну и самое главное – сам по себе GroupKind.Local не особо интересен, вся его мощь просыпается, когда мы дополнительно пишем пятый аргумент – о нём мы и поговорим в следующей части.
    ]

[   Table.Group – Часть 3.1 Пятый аргумент - основной пример и описание / #АнатомияФункций – Table.Group, #buchlotnik
    
    Всем привет!
    Нам осталось сталось самое интересное. Мы уже разобрались тем, что агрегации при группировке могут быть любыми, их удобно делать с помощью функций, выяснили, что можно идти последовательно по строкам, используя GroupKind.Local. А теперь возникает вопрос – что если в столбце могут быть каки-то метки (разные) и мы хотим группировать по каким-то значениям из списка, или мы хотим сгруппировать записи хронологически по неделям (можно, конечно, сделать допстолбец с номером недели, но мы хотим как-то проще) или надо ориентироваться на разницу между строками – группировать только пока показатель растет и т.п. Думаю вы догадались, что так МОЖНО. Осталось только разобраться как.

    Пятый аргумент – comparer – это функция от двух аргументов, возвращающая 0 или 1. В качестве аргументов выступают значение, с которого чначинается группа и текущее значение - state и current (s и c, x и y – кому как больше нравится). 
    Важно! Соответственно, пока функция возвращает ноль – строки объединяются, как только единицу – начинается следующая группа. И это важный момент – нам нужны именно 0 и 1.
    Пример возьмем общий, в дальнейшем шаг from я не буду заново повторять и саму агрегацию возьмем самую простую {"tmp", each _ } - чтобы просто был виден результат группировки:
        
        let
            from = Table.FromRecords(Json.Document(Binary.Decompress(Binary.FromText("5ZrLboMwEEX/hXUiecZjXr/SdtG8VlF3WVX99xJDhBsaehtsC7AUWSRge8KRDWfsl8/s9aJEiy3VtRRuj7M6Y8W8VdR8so29TnJ7rrTluy13WU3tSX205cmWxl6unGadqnJqGrdfD/0Feucci9OD6jrv6rLTl+7aEW1LGgRQOr0cb+3YFmR3H6GmvuWul1sAtfqlqnECkayuzMa9l8e+gTY6ve/jaiMS7sInezHZwFltlWpu+NcGQ8OjaD4u5/PTdP64OXPgQgiY3CMYhsHopMFw7BGjYTCSNBiNgBGPYAQGY8KBYW6DWwoAn1OWgQHkSY8MQcCUHsHkMJhiFAyvmYqJTaWAqZRJD5ccAENKeSRTwmSqWZOh+7q6msLBRH6eVCgGUuEwLMYcITzV83haMLrHA6sjjVu9XvPkVSBUCo9UYG+ktIW+DDybDcDA3khpC30FgJn0uB+QgcWRxo1e1oyFVOwBA+skBfT5JZCh2GRgn6S0RZ84NhnYKWnc9Ke9Mu/dfzioeHA6LB42FdtuIFb+NLOt3iBr3AVFFjANsBjLwYbUBM15QAmXnXmnBILz0VGH0RUNbDwcME2wBDQS2EUHZGDl4fEMgVk1FoNgYY9YYN/htFMEBKXUPC4JEKw8PO8cgedXsyLySibBgsMB1/iX804G8fE5TmDN4cRTA2XstTOC1854PDeQr5pLFXvEwGtpHDAxsAAyrCI/axj2f057GwAjWzC9zmUMSz+nLf0cehPmzzyn/Un+tVFDB1T/GW35w0D4XG5unitv3w=="),Compression.Deflate))),
            group = Table.Group(from, "итог", {"tmp", each _}, GroupKind.Local, (s,c)=>if c="успешно" then 0 else 1)
        in
            group

    Обращаю внимание – просто логическое выражение, возвращающее true или false, воспринято не будет, поэтому была использована конструкция if then else. Другое дело, что чаще используют другой вариант:
        group = Table.Group(from, "итог", {"tmp", each _}, GroupKind.Local, (s,c)=>Number.From(c<>"успешно"))

    Получим то же самое. Обратите внимание, что Number.From() не является обязательной функцией, не важно как именно были получены 0 и 1, просто с ней работает немного быстрее, чем через if, но вы можете писать как вам удобнее.
    ]

[   Table.Group – Часть 3.2 Пятый аргумент - варианты использования / #АнатомияФункций – Table.Group

    Освоили базу, теперь пройдёмся по вариантам:
    1.  Группировать по любому ненулевому значению
        
        group = Table.Group(from, "цикл", {"tmp", each _},GroupKind.Local,(s,c)=>Number.From(c<>null))
    
    2.  Группировать по конкретному значению
        
        group = Table.Group(from, "итог", {"tmp", each _}, GroupKind.Local, (s,c)=>Number.From(c="сбой"))
    
    3.  Группировать по значению из списка
        
        group = Table.Group(from, "операция", {"tmp", each _},GroupKind.Local,(s,c)=>Number.From(List.Contains({"наладка","ТО"},c)))
    
    4.  Группировать по условию
        
        group = Table.Group(from, "выход", {"tmp", each _},GroupKind.Local,(s,c)=>Number.From(c<95))

    Смысл, думаю, понятен. Но что же со state-том? Мы его не используем – он, что совсем не нужен? Нужен! Ой как нужен! 
    
    5.  Группируем, когда отличается первые/последние/любые в середине символы в значении:
        
        group = Table.Group(from, "документ", {"tmp", each _}, GroupKind.Local, (s,c)=>Number.From(Text.Start(s,3)<>Text.Start(c,3)))
    
    6.  Группируем, если разница между первой и последней строкой в группе превысила определенное значение
        
        group = Table.Group(from, "выработка", {"tmp", each _},GroupKind.Local,(s,c)=>Number.From(c-s>50))

    7.  Ещё интересный момент – группировать-то можно и по нескольким столбцам:
        
        group = 
            Table.Group(from, 
                {"дата","цикл","выработка"}, 
                {"tmp", each _},
                GroupKind.Local, 
                (s,c) => Number.From( c[цикл] <> null )
            ) 
    
    В этой ситуации при группировке вы сохраните несколько столбцов, причем значения в них будут по первой строке в группе, а проверяется, по сути, только поле цикл.
    И вот тут обращаю внимание: 
    – если второй аргумент в группировке - "цикл" – то и в формуле мы просто ориентируемся на значение (пишем c<>null), 
    – а если вы намышкоклацали {"цикл"} – то (включаем логику), это список полей, а значит на выходе мы получим… запись. 
    И обращаться уже нужно c[цикл]<>null – вот так, и больше не спрашивайте, почему я обычно не пишу фигурные скобки вопреки «стандартному» виду.

    Напоследок хочется сказать, что если у вас получилась сложная функция сравнения – не стесняйтесь – дайте ей имя и поместите в отдельный шаг, как мы уже неоднократно делали:
    
        f=(x,y)=> 
            [   a =(z)=> Text.Start(z,3), 
                b = Number.From(a(x)<>a(y))
            ]  [b], 
        group = Table.Group(from, "документ", {"tmp", each _}, GroupKind.Local, f)

    На этом на сегодня, думаю, закончим.
    Главный вывод: Table.Group – это функция ПЯТИ аргументов, и хоть два последних и не обязательны, но в умелых руках бывают крайне эффективны – так что пользуйте их на благо светлого будущего человечества.
    ]

[   Table.Group – Часть 3.3 Пятый аргумент + GroupKind.Global / #АнатомияФункций – Table.Group //! Value.Compare

    Всем привет! 
    Меня тут уличили в неполноте раскрытия темы, поэтому вынужден дать развернутый комментарий.
    Итак, мы уже разбирали пятый аргумент у Table.Group и я тогда написал, что его мы используем в сочетании с GroupKind.Local. 
    Но на самом деле при большом желании можно примотать и для GroupKind.Global.
    Разберем пример:
    
        let
            tbl = #table({"Date","Num"},{{#date(2021,1,1),1},{#date(2020,1,1),2},{#date(2021,3,1),3},{#date(2020,1,12),4},{#date(2022,1,1),5}}),
            f=(x,y)=>Value.Compare(Date.Year(x),Date.Year(y)), 
            to =    Table.Group(tbl,
                        "Date",
                        {"Sum", (t)=>List.Sum(t[Num])},
                        GroupKind.Global, 
                        f
                    )
        in
            to

    tbl - имеем таблицу – дата/значение и хотим сделать группировку по годам.
    to  - собственно делаем группировку, сразу в один шаг, с использованием функции f
    f   - пятый аргумент как всегда пишем от двух аргументов. В случае GrouKind.Local мы возвращали 0 или 1 в зависимости от того, надо начинать новую  группу или нет. Но в том-то и дело, что там строки анализируются последовательно, а вот в случае глобальной группировки функция должна определить именно порядок переданных ей аргументов. Самое простое – используем Value.Compare - данная функция вернёт -1 0 или 1 когда x меньше, равен или больше y соответственно.

    Ну и действительно в таком варианте группировка будет корректной. Другое дело, что даты в столбце Date останутся датами, хотя группировка сделана именно по годам. А главное, что мы уже обсуждали в рамках пользовательской сортировки, Value.Compare – медленная функция. И с ростом объема данных «тупить» будет всё сильнее.
    Можно ли это исправить? Ну в целом да – перепишем функцию сравнения:
    
        f=(x,y)=>Date.Year(x)-Date.Year(y)

    Вместо сравнения мы рассчитываем разницу и она будет меньше, равна или больше нуля в зависимости от соотношения между x и y. В таком варианте получим прирост по скорости процентов так на 20 – 25 (замерял на таблице в 100k строк) – что, конечно, ощутимо.
    И кому-то может показаться, что это вот прям круто – группировать в один шаг, но есть маааленькое НО, из-за которого я данный подход не описывал. А состоит оно вот в чём:
        
        let
            tbl = #table({"Date","Num"},{{#date(2021,1,1),1},{#date(2020,1,1),2},{#date(2021,3,1),3},{#date(2020,1,12),4},{#date(2022,1,1),5}}),
            tr  = Table.TransformColumns(tbl,{"Date", Date.Year}),
            to  = Table.Group(tr,"Date",{"Sum",(t)=>List.Sum(t[Num])})
        in
            to

    Стандартный подход в два шага
        tr – преобразовали даты в годы
        to – сгруппировали по преобразованному столбцу
    На той же выборке работает в два раза быстрее.

    И даже если вам надо сохранить даты – добавление столбца года и последующая группировка – по-прежнему в разы быстрее, чем вот этот «финт ушами». Причина – после преобразования столбца группировка идёт по одинаковым значениям (т.е. строка попадает сразу в нужную группу), а при использовании пятого аргумента мы порождаем огромное количество попарных сравнений – хоть и выглядит всё вполне лаконично – это не показатель.

    Поэтому ещё раз обращаю внимание – сам по себе расширенный редактор сильно развязывает руки и да, у пишущего появляется много «можно». Но можно НЕ значит нужно. Дело всегда не в количестве строк кода, а в реальной вычислительной эффективности. Пробуйте, экспериментируйте, но всегда проверяйте полученный результат. В конце концов и одной строчкой кода, при должном умении, можно вызвать переполнение стека.
    ]
   
[   Table.ReverseRows и причём тут группировка? / #АнатомияФункций – Table.ReverseRows
    Всем привет!
    В продолжение темы группировки – недавно была задачка. Сложность в том, что сгруппировать надо по ключевому слову в ПОСЛЕДНЕЙ строке группы. По ссылке можно посмотреть отличное решение от Пуха – допстолбец с индексом, условный столбец, FillUp, потом группировка – в общем все логично и берите на вооружение - у такого подхода есть масса практических приложений.

    Но хочется же сделать финт ушами - иначе бы поста не было. Поэтому:

        let
            from  = Table.FromRecords(Json.Document(Binary.Decompress(Binary.FromText("5ZXBCoMwDIZfZfS8QZPGVn2VbYc59Q12Gnv3aToxMBA8JBQECY0m+eNHSq5vd3t5Appt8LMlzOcTO8DOwDaxFaGhZ1tz5Ohahx7x4mF63Hm7cGCHOj6PQqQThattEVxEkmhJCv7eTzkcNqxdkBcpSQjkr8+l8iiCc3pcO8twCFwbPmclkGgBMuwE+RAy/R9UIb8bJKiBDBYgqZiJjGogyQJkVQxIVANZWYCMB7ja0QJkKmYi9ZZNsgBZH2AiawuQTTETqbdsGgOQ4IsBqbZs1n/UBAkFXe37Fw=="),Compression.Deflate))),
            typ   = Table.TransformColumnTypes(from,{{"Дата выполнения", type date}, {"Дата создания", type date}, {"Процесс", Int64.Type}, {"Задача", type text}}),
            tbl   = Table.ReverseRows(typ),
            group = Table.Group(tbl, {"Процесс","Задача"},
                        {
                            {"Дата создания",   (x)=>List.Min(x[Дата создания]), Date.Type},
                            {"Дата выполнения", (x)=>List.Max(x[Дата выполнения]), Date.Type}
                        },
                        GroupKind.Local,
                        (s,c)=>Number.From( c[Задача]="Контроль" )
                    ),
            to    = Table.ReverseRows(group)
        in 
            to
    
    tbl   – используем Table.ReverseRows – строчки меняются с ног на голову – и нужно группировать по ключевому слову… в ПЕРВОЙ строке группы
    group – группировка, группируем по «Процесс» и «Задача» - сразу по обоим, чтобы процесс не надо было вынимать из сгруппированной таблицы, GroupKind естественно Local, ну и в функции не забыли указать, что интересует нас только поле «задача»
    to    – и снова ReverseRows, чтобы вернуть порядок строк в исходный

    Вот и всё. Редко пользуюсь реверсами, но по скорости в данной ситуации этот вариант выигрывает кратно.
    Курите стандартную библиотеку – там много интересного.
    ]

[   List.Sort 1 – пользовательская сортировка и её альтернативы / #АнатомияФункций – List.Sort, Value.Compare
    Всем привет!
    Сегодня обсудим сортировку списков. Читаем справку:

        List.Sort(list as list, optional comparisonCriteria as any) as list 
    
    Самое простое – просто сортировать )))
    
        List.Sort({8,3,4,11,6})
        List.Sort({"a","f","b","z","m"})
    
    По умолчанию сортировка идёт по возрастанию. Если нужно, порядок можно поменять вторым аргументом
    
        List.Sort({"a","f","b","z","m"},Order.Descending)
    
    Обращаю внимание - Order.Ascending и Order.Descending – это числовые константы, которые могут быть заменены на 0 и 1 соответственно.
    Ну, ОК. Второй аргумент ещё может быть функцией от одного аргумента, которая вычисляет ключ для сортировки. Зачем оно надо? Да вот сравните
    
        List.Sort({"8","3","4","11","6"})
        List.Sort({"8","3","4","11","6"},(x)=>Number.From(x))
    
    В первом случае «11» окажется на первом месте – оно же начинается с 1, во втором – список будет отсортирован по возрастанию числовых значений.
    Функция может быть дополнена порядком сортировки:
    
        List.Sort({"8","3","4","11","6"},{(x)=>Number.From(x), Order.Descending})
    
    Зачем вообще сортировать числа в текстовом формате? Да просто обычно сортируется что-то такое:
    
        List.Sort({"8 abc","3 cde","4 efg","11 ghi","6 ijk"},(x)=>Number.From(Text.BeforeDelimiter(x," ")))
    
    Как видим, функция-то может быть любой сложности.
    Пока всё достаточно просто, но теперь давайте обсудим последний вариант – вместо функции одного аргумента и порядка сортировки можно использовать функцию двух переменных, которая возвращает -1, 0 или 1 в зависимости от того, первый аргумент меньше, равен или больше второго. Для этого нам рекомендуют использовать Value.Compare. Прямой порядок сортировки будет выглядеть так
    
        List.Sort({"a","f","b","z","m"},(x,y)=>Value.Compare(x,y))
    
    Но как теперь задать обратный порядок? (я редко критикую справку, но это именно тот случай):
    
        List.Sort({"a","f","b","z","m"},(x,y)=>Value.Compare(y,x))
    
    Надеюсь, разницу не нужно комментировать. Но прокомментировать надо, что на самом деле от нас требуется не -1, 0 и 1; а отрицательное, ноль или положительное целое число.
        
        List.Sort({8,3,4,11,6},(x,y)=>x-y)
    
    Так тоже работает (разница двух чисел собственно и показывает которое из них больше), а для обратного порядка
        
        List.Sort({8,3,4,11,6},(x,y)=>y-x)
    
    С дробными код чуть напряжнее
    
        List.Sort({8.2,3.1,4.6,11.4,6.9},(x,y)=>Number.Sign(y-x))
    
    Тут мы определяем знак полученной разницы - это работает быстрее чем Value.Compare, правда медленнее чем обычный Order.Descending. Тогда зачем оно надо? Ну вот был в чате пример (здесь упрощённый):
        
        let 
            f=(x,y)=>[g=(x)=>List.Transform(Text.Split(Text.BeforeDelimiter(x," "),"."),Number.From),
                    a=g(x),
                    b=g(y),
                    c= if a{0}=b{0} then a{1}-b{1} else a{0}-b{0}
                ][c]
        in 
            List.Sort({"1.6 abc","3.3 cde","3.12 efg","11.2 ghi","1.24 ijk"},f)

    Во-первых, как уже говорилось - сложные преобразования выносим в отдельную функцию. Далее, что тут происходит - получили номер пункта, получили отдельно число до точки и после, при сортировке сравниваем числа до точки, а если они равны – числа после точки. Работает, но надо сказать, что не быстро, потому что такой подход порождает кучу вычислений (функция вызывается для сопоставления каждой пары значений). Гораздо лучше превратить всё в таблицу и отсортировать ее по двум столбцам. Но если вам всё же нужен список – сделайте это преобразование внутри функции:
    
        let 
            f=(x)=>[g=(y)=>List.Transform(Text.Split(Text.BeforeDelimiter(y," "),"."),Number.From)&{y},//функция получает на вход значение и на выход подает список {число до точки,число после точки, исходное значение}
                    a = Table.FromList(x,g,{"a","b","c"}),//собрали таблицу
                    b = Table.Sort(a,{"a", "b"})[c]//отсортировали по a и b, а на выход подали c
            ][b]
        in 
            f({"1.6 abc","3.3 cde","3.12 efg","11.2 ghi","1.24 ijk"})

    Как-то так, сортировать можно по-разному, но Value.Compare – не лучший выбор. 
    Есть достойные альтернативы, которые я и продемонстрировал.
    ]

[   List.Sort 2 - дополнение от @MaximZelensky

    Дополню примеры из поста про List.Sort вот таким:
        List.Sort(
            {
                "Алена", 
                "АЛЕНА", 
                "АЛЁНА", 
                "Алёна"
            } 
        )

    Обычно заглавные буквы старше, чем строчные, а в алфавите Е идёт перед Ё, поэтому мы ожидаем такой результат сортировки:
        {"АЛЕНА", "АЛЁНА", "Алена",  "Алёна"}

    Однако PQ считает по-другому:
        {
            "АЛЁНА",
            "АЛЕНА",
            "Алена",
            "Алёна"
        }
    Как видим, первые два слова стоят в неожиданном порядке. Причина простая - составители кодовой таблицы (где символу сопоставлен числовой код) для кириллицы сначала забыли про букву Ё, и затем в целях обратной совместимости (чтобы не порушить уже разработанное с помощью этой таблицы ПО) ее пришлось вставлять на свободные места - она должна была быть явно старше, чем строчная буква, но места между заглавными и строчными в кириллице не осталось. Поэтому заглавную "Ё" впихнули до "А", а строчную "ё" - после "я". Этой истории уже десятки лет и никто ничего исправлять не будет.
    В указанном примере такими тонкостями можно пренебречь, однако давайте отсортируем ежей, ужей и арбузы:
        
        = List.Sort( {"Арбуз", "Ёж", "ежиха", "ёжик", "ежище", "ужик", "Уж" })
    
    Результат будет уже не таким приятным:
        {
            "Ёж",
            "Арбуз",
            "Уж",
            "ежиха"
            "ежище"
            "ужик",
            "ёжик"
        }
    Попытка выполнить сортировку в правильном порядке на основании числовых кодов символов здесь возможна (кто смелый - попробуйте и поделитесь результатом), но весьма громоздка и, подозреваю, медленна (ведь Ё/ё может встретиться в любом месте строки, значит, сверку нужно будет производить посимвольно).

    Отчасти спасение лежит в стандартной функции-компараторе из библиотеки PQ: Comparer.FromCulture. Эта функция тоже имеет два аргумента, но совсем не те, что Value.Compare:

    * указание локали, в которой должно производиться сравнение в стандарте .Net Framework (например, "ru-ru")
    * логический параметр, позволяющий игнорировать регистр символов при сортировке). По умолчанию он равен false

    А результат вызова этой функции - неименованная функция-сравниватель, которая уже принимает два аргумента для сравнения (как Value.Compare или ваша кастомная функция сравнения).
    Сортировка списка с такой функцией выглядит вот так:

    = List.Sort( {"Арбуз", "Ёж", "ежиха", "ёжик", "ежище", "ужик", "Уж" }, Comparer.FromCulture("ru-ru"))

    /*
    {
    "Арбуз",
    "Ёж",
    "ёжик"
    "ежиха",
    "ежище",
    "Уж",
    "ужик"
    }
    */

    Обратите внимание:

    * в русской локали сортировка идёт по такому принципу: А, а, Б, б, .... , Е, е, Ё, ё, , ... Я, я.
    * Почему-то Ё старше, чем Е, но хотя бы младше, чем Д. (предположения и догадки по этому поводу - в комментариях)
    ]

[   LinearTrend – функция, которой нет, но очень хочется / #АнатомияФункций – статистические функции
    Всем привет!
    Очередной раз в чате был задан вопрос про статистические функции в M.
    Они есть, все в категории List: .Average, .Count, .Covariance, .Median, .Min, .Max, .Mode, .Modes и .StandardDeviation. Набор стандартный, вполне достойный, но уж больно часто спрашивают про оценку трендов – а вот её не подвезли. Я не собираюсь никого мучать линейной алгеброй и решением задачи в общем виде в матричной форме, поэтому просто приведу вариант решения для парного линейного случая:
   
        LinearTrend = 
            (x as list, y as list) as record => //предполагается y = a + b*x
            [   
                x2 = List.Transform(x,(y)=>y*y),
                y2 = List.Transform(y,(x)=>x*x),
                xy = List.Transform(List.Zip({x,y}),(x)=>x{0}*x{1}),
                    
                n     = List.Count(x),
                sumx  = List.Sum(x),
                sumy  = List.Sum(y),
                sumx2 = List.Sum(x2),
                sumy2 = List.Sum(y2),
                sumxy = List.Sum(xy),
                
                a   = if n > 2 then (sumx2*sumy-sumx*sumxy)/(n*sumx2- sumx*sumx) else y{0}, //ОТРЕЗОК()
                b   = if n > 1 then (n*sumxy-sumx*sumy)/(n*sumx2- sumx*sumx) else 0, //НАКЛОН()
                syx = if n > 2 then (sumy2-a*sumy-b*sumxy) else 0,
                sy  = sumy2 - sumy * sumy / n,
                s   = if n > 2 then Number.Sqrt(syx/(n-2)) else 0, //СТОШYX()
                R2  = 1-syx/sy, //R^2 - функции нет, на графиках есть 
                r   = Number.Sign(b) * Number.Sqrt(R2) //КОРРЕЛ()
            ]
        [[n],[a],[b],[s],[R2],[r]]

    По шагам:
    x,y – абсцисса и ордината соответственно – списками
    x2,y2,xy – для решения задачи нам требуются квадраты по обеим координатам и попарные произведения
    n   – число элементов (взято по абсциссе, в предположении, что списки одинаковой размерности)
    sumx, sumy, sumx2, sumy2, sumxy – суммы – величин, их квадратов, попарных произведений
    a,b – пересечение и наклон соответственно (в комментах к коду названия соответствующих функций в Excel)
    syx – остаточная сумма квадратов для модели
    sy  – сумма квадратов отклонений ординаты от среднего
    s   – остаточное стандартное отклонение
    R2  – коэффициент детерминации (он фигурирует на графиках, его же вычисляет ЛИНЕЙН())
    r   – коэффициент корреляции – посчитан из R2, просто чтоб было, если нужен только он – не надо пользоваться этой функцией – посчитайте ковариацию – оно проще и быстрее, поверьте

    Ну и всё – параметры получаем в виде записи. Вроде громоздко, но ничего сложного.
    Если тема актуальна – пишите в каментах, будем двигать статистику в М.
    ]
    
[   Чем заменить Table.AddColumn? – эпичный челлендж / #АнатомияФункций – Table.FromList и многие другие
    
    Всем привет!
    Мы уже разбирали, что на списках быстрее ))). Так вот, история получила продолжение. Сегодня в чате состоялся челлендж. 
    @MaximZelensky – спасибо за идею и организацию!

    Суть задачи – повторить в точности результат выполнения функции Table.AddColumn. В точности означает, что нужно не просто получить таблицу с новым столбцом, это должна быть функция, принимающая те же аргументы, что и штатная, при этом типы столбцов у возвращаемой таблицы в любой ситуации должны получиться такими же, как и при работе штатной функции. По ссылке выше можете посмотреть результаты – все (все, Карл!) участники оказались быстрее, чем штатный вариант почти в два раза! (важное дополнение - в ходе пристальных тестов выяснено, что стандартная функция работает шустрее, если её дополнительно обернуть в Table.Buffer, кастомная таких изысков не требует, что приятно).
    Ну а лучшим по скорости и точности оказался, разумеется, гибрид идей – его и разберем:
    
        (   table as table, 
            newColumnName as text, 
            columnGenerator as function, 
            optional columnType as nullable type
        ) as table =>

        [   //  кусок от buchlotnik
                rec = Table.ToRecords(table),
                gen=(x)=>Record.FieldValues(x) & {columnGenerator(x)},
                newtyp = if columnType = null 
                         then Type.FunctionReturn(Value.Type(columnGenerator)) 
                         else columnType,
            
            //  кусок от Maxim Zelensky
                TypeAsRecord =  
                    Record.AddField(
                        Type.RecordFields(Type.TableRow(Value.Type(table))), 
                        newColumnName, 
                        [Type = newtyp, Optional = false]
                    ),
                NewTableType = type table Type.ForRecord(TypeAsRecord, false),
            
            //  и итог послечелленджевого обсуждения
                to = Table.FromList(rec,gen,NewTableType)
        ] [to]

    ()=> обратите внимание на аргументы – они просто скопированы из справки - мы играем по правилам 🙂
    rec – превратили таблицу в список записей - записи важно сохранить, потому что , columnGenerator штатной функции работает с полями записи
    gen – функция генерации строки таблицы – получает на вход запись, превращает её в список значений и добавляет к нему результат выполнения columnGenerator над этой записью
    newtyp – проверяем, передан ли четвертый аргумент, если да – используем его, если нет – определяем тип данных, возвращаемых columnGenerator

    Шаги от Максима:
    TypeAsRecord – получаем типы столбцов исходной таблицы в виде записи и добавляем к ней информацию о новом столбце и его типе
    NewTableType – создаем новый тип таблицы с информацией уже обо всех столбцах
    (Максим, ещё раз спасибо, чего я там нагородил через Table.Schema и #shared – прям стыдно 😳)

    Ну и осталось немного:
    to  – генерация новой таблицы из списка записей с использованием функции Table.FromList: 
    gen - второй аргумент должен возвращать список - наша функция этому условию полностью удовлетворяет, третьим аргументом сразу передаем полученной таблице информацию о типе
    (кто забыл как такое читать - [ ][to] - вспоминаем)

    Всё! Задачка решена. Просто, элегантно, и чёрт побери, шустро!
    Курите решение, читайте спецификацию, надеюсь на следующем челлендже участников будет больше 😉
    ]

[   Table.AddColumn и типизация столбцов – Часть 1 //! #ГостевойТанк - дополнение от @MaximZelensky

    По мотивам и в дополнение к челленджу по переписыванию Table.AddColumn

    При загрузке данных из PQ в модель данных Power Pivot в Excel или в модель данных Power BI критически важно, чтобы столбцы таблиц имели правильный тип (иначе все нетипизированные столбцы будут восприняты как текстовые, вне зависимости от их содержимого).

    Ок, предположим, мы решили создать в таблице столбец с именем "new" и заполнить его единичками. Когда мы создаем новый столбец через интерфейс PQ, автоматически создается код такого вида: Table.AddColumn(TableName, "new", each 1). Новый столбец, созданный таким образом, будет иметь по умолчанию тип данных any - то есть будет нетипизирован. Так происходит потому, что функция each 1 не имеет заранее определенного типа возвращаемого значения, а априори анализировать результат расчёта для каждой строки - дорого и неэффективно.
    Но что делать, если нам важен тип данных (мы хотим загрузить этот столбец в модель)? Можно ли сразу указать, какого типа этот новый столбец? Мы же знаем его заранее (1 это явно число, других вариантов результата у нашей функции нет). Для этого нас есть несколько способов.

    Способ 0
    После создания шага применяем преобразование типа столбца через интерфейс или в коде при помощи Table.TransformColumnTypes - наиболее прямой, но расточительный способ. В этом случае, кроме собственно указания типа для столбца, происходит принудительное преобразование значений в нем к указанному нами типу, и если по какой-то причине преобразовать значение в указанный тип нельзя, появится ошибка ячейки. Замедление производительности мы увидим уже на средних объемах. Однако есть случаи (за рамками этого поста), когда такая операция необходима и чрезвычайно полезна.

    Способ 1
    Мы можем явно указать тип данных, который возвращает функция-генератор. Например перепишем функцию с единичками вот так (не через диалоговое окно, а в строке формул):
    
        (row) as number => 1
    
    Новый столбец автоматически получит тип number - потому что так сказано в определении функции ( as number). И даже более того - если мы попробуем обхитрить PQ и вместо единичек вернуть текстовое значение, такая попытка вызовет ошибку ячейки:
    
        (row) as number => "1" // Expression.Error: Не удается преобразовать значение "1" в тип Number
    
    Так что, если мы точно знаем, что результат может быть определенного типа, мы можем смело использовать такой подход, и даже отлавливать ошибки типизации.
    К сожалению, первый способ имеет ограничения – какие и как с ними бороться будет рассказано во второй части.
    ]
    
[   Table.AddColumn и типизация столбцов – Часть 2 //! #ГостевойТанк - дополнение от @MaximZelensky

    Продолжение - первая часть

    Способ 2
    К сожалению, первый способ имеет ограничения - мы можем использовать оператор назначения типа as только с примитивными типами - такими как text, number, date и т.п., либо их nullable версиями: nullable text, nullable number и т.п.
    Однако, если мы хотим указать, что единичка - не просто число, а целое число, мы не можем написать в определении функции as Int64.Type - такая попытка вызовет ошибку шага Expression.SyntaxError: Недопустимый идентификатор типа. Проблема в том, что Int64.Type - это не примитивный (базовый) тип, а так называемый фасет (подтип), с которым не хочет работать оператор as.
    В таком случае мы можем задействовать 4-й (опциональный) аргумент функции Table.AddColumn - указание типа нового столбца:
    Table.AddColumn(TableName, "new", each 1, Int64.Type)
    В этом случае вне зависимости от того, указали ли мы, какой тип данных возвращает фукнция-генератор, новый столбец получит тот тип, который указан в 4-м аргументе - целое значение.
    
    При этом очень важно отметить:
    * Проверка соответствия указанного типа реальному типу значений не будет производиться на этапе создания столбца (ни на уровне ячейки, ни на уровне шага). Мы можем написать Table.AddColumn(TableName, "new", each 1, type text), и новый столбец будет иметь тип "Текст", но преобразование 1 в "1" не будет произведено.
    * При загрузке данных в модель (как минимум в Power BI), тем не менее, будет произведена проверка соответствия типа данных столбца типу данных значений в его ячейках, и мы очень легко можем увидеть сообщение об огромном количестве ошибок при загрузке.
    Поэтому использовать 4-й аргумент нужно очень аккуратно - только будучи уверенным, что тип значений в новом столбце не будет противоречить указанному.

    У второго способа есть также одно важное преимущество - мы можем задавать там не только примитивные или фасетные типы, но и сложные составные типы.
    Например, у нас есть столбец со списком годов и мы хотим для каждого года создать списки "первых чисел месяцев", чтобы затем развернуть эти списки в новые строки:
    
        YearsTable   =  #table(type table [Year=Int64.Type], List.Zip({{2019, 2020, 2021}})),
        AddMonths    =  Table.AddColumn(YearsTable, "MonthStart", 
                            each List.Transform({1..12}, (m) as date => #date([Year], m, 1))
                        )
        ExpandMonths =  Table.ExpandListColumn(AddMonths, "MonthStart")
    
    Несмотря на то, что мы попробовали прописать as date во внутренней функции, это нам не особо помогло - после разворачивания списков новый столбец имеет тип any - такой тип у основной функции-генератора each. Если мы попробовали бы вместо each использовать (row)=> (по первому способу выше), то максимум, который нам был бы позволен - (row) as list =>. В этом случае тип нового столбца (до разворачивания) получил бы тип "список" (это будет заметно по иконке в названии столбца), но на этом и всё - после разворота, несмотря на то, что мы пытались задать тип date, новый (развернутый) столбец будет иметь тип any.

    Здесь на выручку приходит тот самый Способ 2 - использование 4-го аргумента:
    
        AddMonths = 
            Table.AddColumn(YearsTable, "MonthStart", 
                each List.Transform(
                        {1..12}, 
                        (month) as date => #date([Year], month, 1)
                ), type {date}
            )
    
    Использовав сложный составной тип type {date}, мы явно указали программе, что новый столбец содержит список дат. Теперь даже после разворачивания мы увидим, что столбец типизирован как "даты".
    ]
    
[   Table.Max – или многоликий второй аргумент / #АнатомияФункций – Table.Max

    Всем привет!
    Сегодня в чате всплыл вопрос про Table.Max – и в личке спросили зачем я ее так странно пишу. Ответ прост – многие вещи я по привычке пишу через функции. Но вот как МОЖНО писать, думаю стоит прокомментировать развернуто.
    Тестовый стенд:
        
        let
            from = Table.FromRecords(Json.Document(Binary.Decompress(Binary.FromText("fdJJisMwEIXhq4haG+MqyXLiqzS9yNTzvA25e0RZtuu5kSCLYPh4Tv56uNKBRm7oSOO+oZN+P9NI0om4ThwzNXRJDzpu0yc9ZnegW2PcTp1snGTHfnFHdMO0B4Ps2M+D0nKGJ4RRYbDOOw6zC4s7o+vV9RvXZydxedELuqAubt4zZue7Nk2qe0Ln1Q2FvTTGMrlndKJuV9gzIV7Qsbp9Yc+EeJ2dlMLbvbXDG7opvC/9vrXDO7ocfigMmhAfCGN10IT4RNf/Pxj8Q+cQX+hC9WBMiG90vnowJsQPOqkfzBriFx3XD2YN8Ue3xzs="),Compression.Deflate))),
            f = "a",
            to = Table.Max(from,f)
        in
            to

    from – исходник
    f – условие определения максимума
    to – результат Table.Max (обращаю внимание – на выход поступает запись – строка таблицы с максимумом по нашему условию)
    Далее для простоты буду менять только шаг f.

    Итак, для начала обращаю внимание в коде выше, что в отдельные шаги можно выносить не только функции, но и списки или отдельные значения, да вообще всё, что угодно (вынесение шагов обсуждалось тут).
    f = "a" – просто название столбца, на выходе получим запись с максимальным значением по данному полю, причём – последнюю запись (в примере таких несколько).
    Днём я написал по-другому:
    
        f = (x)=>x[a]
    
    т.е. написал функцию – обращаю внимание – на вход поступает строка таблицы – запись, и мы просто просим взять конкретное поле – т.е. результат будет таким же. Зачем такие сложности? Да посмотрите на столбец "e" – хотим максимальную дату, а она спрятана в текстовой строке, решение разумеется:
    
        f = (x)=> Date.From(Text.BeforeDelimiter(x[e]," "))
    
    т.е. мы уже не просто берем конкретное поле, но и осуществляем с ним дополнительное преобразование – вынимаем дату (можно конечно сначала соорудить допстолбец и потом брать максимум по нему, а можно вот так сразу)
    Ну ок, а что если нас не устраивает вынимание последней строки? Хотим максимум по "a", если несколько значений – максимум по "b" и т.д. Да пожалуйста:
    
        f = {"a","b","c"}
    
    т.е. просто передаем список имен столбцов, в том порядке, в котором определяем максимум. Это важно -
    
        f = {"a","c","b"}

    даст уже другой результат (поиграйтесь с примером).

    Ну и вернемся к функциям – а что если нужно вынуть дату из "e", а из полученных взять максимум по столбцу "c"? Да как бы тоже несложно:
        
        f = {(x)=> Date.From(Text.BeforeDelimiter(x[e]," ")),"c"}
    
    Т.е. список может состоять не только из названий столбцов, но и включать функции преобразования.

    Как-то так – если в справке про аргумент написано as any – это стоит ковырнуть и возможно упростить себе программирование или жизнь )))
    ]
    
[   TableToBinaryText, TableFromBinaryText – или туда и обратно //!!!!! #АнатомияФункций – Json, Binary и т.п.

    Всем привет!
    В серии постов про группировку появился пример исходника в виде текста странного вида: "i65Wiik1MDFJAZNGINI4VcnKUAcsbJwGFjaACIPZhqgKjbAotACTyWDSFCKuZGUMUQjVCVEINss4CaHJxAxMJilZmdTGAgA="
    Вроде что это, как и откуда уже обсудили в чате, но раз вопросы в личку продолжаются закреплю здесь.
    
    Постановка задачи
    Необходимо дополнить пост в телеграме примером таблицы в несколько столбцов и хотя бы десятком строк. Писать такое в явном виде (например, через Table.FromRecords) долго, муторно и вообще может не влезть в сообщение, а прикладывать файл-пример также не очень – у нас здесь пользователи не только, да и не столько excel, сколько pbi, плюс скачивать файлы на работе не у всех есть возможность
    
    Логика решения
    Чтобы данные не занимали кучу символов их следует сжать. PQ умеет сжимать только бинарники, значит из таблицы нужно получить бинарник. Напрямую это действие осуществить нельзя, поэтому таблицу надо сначала преобразовать в текстовый формат. Из всего имеющегося в арсенале (мы помним, что таблицу можно рассматривать как список записей) лучше всего подходит Json - текстовый формат, который поддерживает записи. После сжатия на выходе будет бинарник, а нам надо его в воткнуть в сообщение – значит последним этапом мы должны будем получить строковое представление бинарника
    Реализация

    Функция превращения таблицы в сжатый текст:
        
        TableToBinaryText = 
            (tbl as table) as text=>
            [   json  = Json.FromValue(tbl),
                bin   = Binary.From(json),
                compr = Binary.Compress(bin,Compression.Deflate),
                txt   = Binary.ToText(compr)
            ]  [txt]

    json  – преобразовали таблицу в json (размеченный текст)
    bin   – получили бинарное представление для текста
    compr – осуществили сжатие (выбрано Compression.Deflate – просто потому, что так сжимаются ZIP-ы)
    txt   – получили строковое представление сжатого бинарника

    Ну и процедура получения таблицы – это те же действия в обратном порядке:
    
    TableFromBinaryText = 
        (txt as text) as table =>
        [   bin  = Binary.FromText(txt),
            dec  = Binary.Decompress(bin,Compression.Deflate),
            json = Json.Document(dec),
            tbl  = Table.FromRecords(json)
        ]  [tbl]
    
    bin  – строку обратно в бинарник
    dec  – бинарник вернули в несжатое состояние
    json – получили из бинарника json – он отобразится как список записей
    tbl  – собрали из записей таблицу

    Вот, собственно, и всё.
    Какие практические задачи собрались решать вопрошающие не знаю. По мне так это просто пример, как можно решать свои частные задачи, используя имеющийся арсенал конкретного языка. С другой стороны, если начнете копать в сторону Binary.*, функции распаковки документов word или добывания информации о разметке в excel могут перестать быть китайской грамотой – там же всё строится на распаковке zip-архивов, коими и являются .docx и .xlsx. Так что да – частная задача может вести к изучению весьма интересных функций.
    ]

[   Как подключиться к файлам на Яндекс.Диске / #ВсякиеКоннекторы
    И снова здрасьте. На хайпе по теме импортозамещения все чаще граждане перетаскивают свои данные на отечественные облака. И далее встаёт вопрос, а как их оттуда затащить в Power Query? Решением поделился добрый человек @IlyaNazarov.
    Пока что сам я не тестировал. По результатам дополню пост собственными впечатлениями].

[   Table.FromList – //! пять аргументов счастья / #АнатомияФункций - Table.FromList

    Всем привет!
    Всё руки не доходили написать про одну из моих любимых функций.
    Сначала читаем справку:

        Table.FromList(
            list as list, 
            optional splitter as nullable function, 
            optional columns as any, 
            optional default as any, 
            optional extraValues as nullable number
        ) as table

    Важно! Таблица собирается на основе первой строки

    Обращаем внимание, что обязательным является только первый аргумент – list. Проверяем:
      
        Table.FromList({"a,b,c,1","d,e,f,2","g,h,i,3"})

    Работает, заодно узнаем, что по дефолту она ещё и текст по запятой делит, т.е. следующий код выдаст то же самое:
        
        Table.FromList({"a,b,c,1","d,e,f,2","g,h,i,3"},Splitter.SplitTextByDelimiter(","))

    Тогда зачем вообще писать splitter? Ну во-первых разделитель не всегда запятая:
       
        Table.FromList(
            {"a;b;c;1","d;e;f;2","g;h;i;3"},
            Splitter.SplitTextByDelimiter(";")
        )

    А главное вторым аргументом может быть любая другая функция, возвращающая список:
       
        Table.FromList(
            {"a;b;c;1","d;e;f;2","g;h;i;3"},
            (x)=>Text.Split(x,";")
        )
    
    или например
        
        Table.FromList({"abc1","def2","ghi3"},Text.ToList)

    Ну ОК, а вот такая ситуация

        Table.FromList({"a;b;c;1","d;e;f;2","g;h;i;3;4;5"},(x)=>Text.Split(x,";"))
    
    Даст ошибку в третьей строке. Причина - таблица собирается на основе первой строки, а в третьей столбцов оказалось больше.
    Решение - добавить третий аргумент (columns):

        Table.FromList({"a;b;c;1","d;e;f;2","g;h;i;3;4;5"},(x)=>Text.Split(x,";"),6)
    
    Т.е. в третий аргумент поместили целевое количество столбцов (в общем виде это не обязательно константа – его можно и вычислить).

    Также обращаем внимание, что отсутствующие значения были заменены на null, но если нужно что-то другое - привлекаем четвертый аргумент (default):
    
        Table.FromList(
            {"a;b;c;1","d;e;f;2","g;h;i;3;4;5"},
            (x)=>Text.Split(x,";"),
            6,
            "-"
        )

    Обратная ситуация – нам нужны только первые три столбца:
    
        Table.FromList(
            {"a;b;c;1","d;e;f;2","g;h;i;3;4;5"},
            (x)=>Text.Split(x,";"),
            3,
            "-",
            ExtraValues.Ignore
        )
    
    Т.е. пятый аргумент (extraValues) говорит, что делать с дополнительными значениями - в ситуации выше они проигнорированы, а вот в ситуации ниже – собираются в список:
    
        Table.FromList(
            {"a;b;c;1","d;e;f;2","g;h;i;3;4;5"},
            (x)=>Text.Split(x,";"),
            4,
            "-",
            ExtraValues.List
        )
    
    Это бывает удобно.

    Но что, если мы не хотим дефолтные имена столбцов - да пожалуйста:
    
        Table.FromList(
            {"a;b;c;1","d;e;f;2","g;h;i;3;4;5"},
            (x)=>Text.Split(x,";"),
            {"а","б","в","г","д","e"}
        )
    
    Т.е. можно передать список имен.

    Более того, можно передать названия и типы:
    
        Table.FromList(
            {"a;b;c;1","d;e;f;2","g;h;i;3;4;5"},
            (x)=>Text.Split(x,";"),
            type table [а=text,б=text,в=text,г=number,д=number,е=number]
        )

    Внимательные читатели обратят внимание, что типы столбцов поменялись, а вот сами значения остались текстовыми.
    Об этом нужно помнить, но поскольку функция разделения реально может быть любой, можно чутка усложнить:
    
        Table.FromList(
            {"a;b;c;1","d;e;f;2","g;h;i;3;4;5"},
            (x)=>List.Transform(
                    Text.Split(x,";"),
                    (y)=>try Number.From(y) otherwise y
                ),
            type table [а=text,б=text,в=text,г=number,д=number,е=number]
        )

    Вот так, одним шагом список в таблицу с блэк-джеком и…
    Ну а что до боевых примеров – так их есть уже на канале: эпичный челлендж, плач по регуляркам, даже в сортировке засветилась.
    Как-то так. Простая, гибкая и шустрая, мечта, а не функция! Юзайте с удовольствием.
    Надеюсь, было полезно.
    ]

[   List.Select и все все все / #АнатомияФункций – List.Select

    Всем привет! Последнее время было несколько вопросов про отбор данных по условию. По этому поводу хочу разобрать List.Select, поскольку к пониманию работы этой функции всё в общем и сводится.
    Читаем справку

        List.Select(list as list, selection as function) as list

    Всё как обычно – список (list) и функция выбора (selection). Пример даётся простой:
        
        List.Select({1..100}, each _>90)

    Сразу вспоминаем, что это можно переписать как функцию
    
        List.Select({1..100}, (x)=>x>90)
    
    где x – элемент анализируемого списка, нам это ещё пригодится.
    Как водится, функция может быть любой (главное, чтобы в результате она давала true или false).

    Например, выводим числа, кратные пяти:
        
        List.Select({1..100}, (x)=>Number.Mod(x,5)=0)

    или выводим даты только рабочих дней (с понедельника по пятницу):
        
        List.Select(List.Dates(#date(2022,1,1),365,#duration(1,0,0,0)),(x)=>Date.DayOfWeek(x,1)<5)

    Также можно комбинировать условия.
    Например, выводим числа, кратные трём ИЛИ пяти:
    
        List.Select({1..100}, (x)=>Number.Mod(x,3)=0 or Number.Mod(x,5)=0)

    А так кратные трём И кратные пяти :
        
        List.Select({1..100}, (x)=>Number.Mod(x,3)=0 and Number.Mod(x,5)

    (я знаком с математикой, можно было просто проверить делимость на пятнадцать, но это просто пример)

    Ну и важно помнить, что списки могут состоять не только из отдельных значений.
    Например, обращение к списку списков:
        
        List.Select({{1,1},{1,2},{2,1},{2,2}},(x)=>x{0}>1)
    
    В данном случае x – это список и мы проверяем его первый элемент x{0}

    Аналогично можно обращаться к списку записей:
    
        List.Select({[a=1,b=1],[a=1,b=2],[a=2,b=1],[a=2,b=2]},(x)=>x[a]>1)
    
    В этом случае x – это запись, и мы проверяем конкретное её поле – x[a].

    Остальное всё то же самое, например,комбинируем условия:

        List.Select({[a=1,b=1],[a=1,b=2],[a=2,b=1],[a=2,b=2]},(x)=>x[a]>1 or x[b]<2)

    Ничего не напоминает? Ровно так и работает Table.SelectRows:
    
        Table.SelectRows(
            Table.FromRecords({[a=1,b=1],[a=1,b=2],[a=2,b=1],[a=2,b=2]}),
            (x)=>x[a]>1 or x[b]<2
            )
    
    При выборе строк проверяется каждая из них, но строка – это запись, фактически это и есть работа со списком записей.

    Да и в случае Table.SelectColumns без List.Select бывает не обойтись:
        
        let
            from = 
                #table(
                    {"имя","a1","a2","итого a","b1","b2","b3","итого b"},
                    {
                        {"вася",1,2,3,4,5,6,15},
                        {"петя",1,3,4,5,7,9,21},
                        {"коля",2,4,6,8,10,12,30}
                    }
                ),
            lst  = List.Select(Table.ColumnNames(from),(x)=>x="имя" or Text.Contains(x,"итого")),
            to   = Table.SelectColumns(from,lst)
        in
            to

    т.е. lst - из таблицы мы получаем полный список названий столбцов и выбираем «имя» или те, которые содержат «итого».
    to - полученный список использовали в SelectColumns.

    Как-то так – определяем анализируемую структуру, чтобы понимать, от какого аргумента следует писать функцию, прописываем условие (или комбинацию условий) и получаем нужный результат. List.Select редко используется сам по себе, а вот в связке с другими функциями - весьма полезная штука.
    ]
    
[   Text.Remove, Text.Select, Text.Trim на страже чистоты текста / #АнатомияФункций – всякое про текст
    Всем привет!
    Разберем задачку, частенько возникающую при парсинге, а именно – имеется текст, а нам надо почистить его от всякого лишнего.
    Для этого в арсенале мы имеем Text.Remove, Text.Select, Text.Trim, Text.TrimStart, Text.TrimEnd и даже Text.Clean. Что ж, поехали!
    
    Сначала простенькое:
        
        Text.Remove("<мама <мыла <раму","<")

    Здесь мы наблюдаем явно лишний символ <, передаем его вторым аргументом и радуемся жизни

        Text.Remove("<мама> <мыла> <раму>",{"<",">"})

    символов уже два, поэтому второй аргумент представляет собой список.
    Список может расти:
    
        Text.Remove("<мама/> <мыла/> <раму/>",{"<",">","/"})
        Text.Remove("<-ма9ма098/> 67-.908<мыABCла/> <ра123qwerму/>",{"<",">","/",".","-","0".."9","A".."Z","a".."z"})
    
    тут вторым аргументом уже сущее безумие - отдельные символы, диапазоны символов - можно ли это как-то упростить?
    Конструкция “a”..”z” даёт нам все символы с номерами от 97 (код английской строчной a) до 122 (код строчной z). Вооружившись этим знанием можем переписать код:
    
        Text.Remove(
            "<-ма9ма098/> 67-.908<мыABCла/> <ра123qwerму/>",
            List.Transform({33..127},Character.FromNumber)
        )
    
    Здесь мы во втором аргументе генерим все числа от 33 до 127 и превращаем их в символы (32 не трогаем – это пробел и он нам нужен). Аналогично можно бороться и с непечатаемыми символами (разрыв строки, перевод каретки, табуляция и т.п.):
    
        Text.Remove(
            "<-ма9м#(lf)а098/> 67-.908<мыA#(cr)BCла/> <ра123qwerму/>",
            List.Transform({1..31,33..127},Character.FromNumber)
        )
    
    Вообще для непечатаемых символов (с 1 по 31) есть своя функция - Text.Clean, но раз уж у нас тут и так список всякого – мы их просто добавили.

    Ок, но неоднократно говорилось, что чем длиннее анализируемый список, тем медленнее всё работает. Соответственно можно поменять стратегию – не пытаться удалить всё лишнее, а только оставить всё нужное:
    
        Text.Select(
            "<-ма9м#(lf)а098/> 67-.908<мыA#(cr)BCла/> <ра123qwerму/>",
            {"А".."я"," "}
        )
    
    Вполне симпатично, но поборники чистоты кода попросят переписать:
    
        Text.Select(
            "<-ма9м#(lf)а098/> 67-.908<мыA#(cr)BCла/> <ра123qwerму/>",
            {"А".."я","Ё","ё"," "}
        )
    
    Здесь фишка в том, что Ё и ё в силу исторической несправедливости имеют свои коды, поэтому их указываем дополнительно, через запятую.

    Но вы не думайте, что с латиницей проще:
    
        Text.Select("<[mama\] [my\la\] [ra/-mu]/>",{"A".."z"," "})
    
    Неожиданный результат, не так ли? Ну просто так вышло, что [, ], \ ещё несколько символов оказались между прописными и строчными буквами латиницы, поэтому корректно писать так:
    
        Text.Select("<[mama\] [my\la\] [ra/-mu]/>",{"A".."Z","a".."z"," "})

    Это всё прекрасно, конечно, но что, если нужно удалить не все символы, а только что-то до или после нужного текста? Тут нам не обойтись без Trim:
    
        Text.TrimStart("<name = 191.168.0.0 - Михаил (buchlotnik) Музыкин/>",List.Transform({1..127},Character.FromNumber))
        Text.TrimEnd  ("<name = 191.168.0.0 - Михаил (buchlotnik) Музыкин/>",List.Transform({1..127},Character.FromNumber))
        Text.Trim     ("<name = 191.168.0.0 - Михаил (buchlotnik) Музыкин/>",List.Transform({1..127},Character.FromNumber))
    
    Идея точно такая же – передаем список символов, и функция их удаляет. Только
        TrimStart   - удаляет все символы из списка, идущие подряд с начала строки
        TrimEnd     - то же самое, но с конца строки
        Trim        - объединяет в себе работу обеих
    
    Только будьте аккуратны при формировании списков:

        Text.Trim(
            "<name = 191.168.0.0 - Михаил (buchlotnik) Музыкин/>",
            List.Transform({1..127}, Character.FromNumber) & {"М","и","н"}
        )
    
    на выходе получится "хаил (buchlotnik) Музык" - Ми в начале и ин в конце попали под раздачу, 
    поскольку эти символы содержались в списке исключаемых. 
    Это собственно, ответ на прошлогоднюю загадку )))
    Как-то так – изучайте коды символов и чистите ваши выгрузки от всякого мусора с полным осознанием дела.
    ]
    
[   Производственный календарь / #АнатомияФункций – CustomFunctions

    Подкинули повод спарсить производственный календарь с Консультанта. Тема уже поднималась Лёхой, но код не был выложен в силу громоздкости.
    Подумал, что надо бы исправить ситуацию )))

    Посему функция consultant:
    (optional year as nullable number) =>
        [   path = "http://www.consultant.ru/law/ref/calendar/proizvodstvennye/",
            yr   = year??Date.Year(DateTime.LocalNow()), 
            from = Text.FromBinary(Web.Contents(path&Text.From(yr)&(if yr = 2020 then "b" else ""))),
            splt = List.Skip(Text.Split(from,"#(tab,tab,tab)<td class=")),
            lst  = List.Zip({{1..12},splt}),
            f=(x)=>[a=Text.Split(x{1},"<td class="),
                    b=List.Select(a,(x)=>not Text.Contains(x,"inactively")),
                    c=List.Transform(b,(x)=>List.Range(Text.SplitAny(x,"><"),0,2))][c],
            g=(x,y)=>{#date(yr,x{0},Number.From(y{1})),Text.Remove(y{0},"""")},
            tr  = List.TransformMany(lst,f,g),
            tbl = Table.FromList(tr,(x)=>x,type table [Date=date,DateType=text])
        ]  [tbl]

    ()=> Обращаем внимание – функция без обязательных аргументов
    path  – откуда тащим
    yr    – год, за который нужен календарь - если аргумент не передан – берём текущий год (у кого не работает ?? меняем выражение на if year is null then Date.Year(DateTime.LocalNow()) else year)
    from  – тащим информацию с сайта. Есть нюанс – 2020 был непростым годом, поэтому тогда календарь перезаливали и он получил адресацию 2020b, что собственно здесь и учитывается. В данном случае просто получаем текст со страницы
    split – хитро делим текст – помесячные блоки отбиваются тройным табом – обращаю внимание как это записано, ну и первый кусок (до помесячных) отбрасываем
    lst   – соединяем блоки текста с номерами месяцев через List.Zip
    tr    – немножко перескочим – полученный список отправляем в List.TransformMany, для которой нам нужны две функции:
    f     – делит текстовый блок по "<td class=", оставляет фрагменты без "inactively" (у них на сайте месячные блоки стандартные 7 на 6, и так обозначены пустые), и их сплитуем по ">" и "<", оставив первые два фрагмента – статус и номер дня соответственно
    g     – собираем из полученного дату и статус даты без лишних кавычек
    tbl   – из полученного списка получаем таблицу, сразу задав типизацию
    
    Как бы всё)))

    Как этим пользоваться:
    consultant() // календарь на текущий год
    consultant(2024) //календарь на конкретный год
    Table.Combine(List.Transform({2010..2024},consultant)) //календарь за период лет
    ]

[   Table.TransformColumns – Часть 1 Функция четырёх аргументов //? #АнатомияФункций – Table.TransformColumns
    
    Всем привет!
    Нашёлся повод, поэтому разбираем Table.TransformColumns. Для начала заглянем в справку:
    
    Table.TransformColumns(
        table as table, 
        transformOperations as list, 
        optional defaultTransformation as nullable function, 
        optional missingField as nullable number
    )

        table                   – наша таблица
        transformOperations     – список преобразований
        defaultTransformation   – функция преобразования, применяемая по умолчанию (когда не требуется ставим null)
        missingField            – аргумент, отвечающий за то, что делать с отсутствующими полями

    Ну и поехали на примере - имеем таблицу, в которой некоторые числовые значения как текст, а некоторые null и мы хотим null поменять на 0, а текст превратить в целые числа:
        let
            from = Table.FromRecords({
                [A = null, B = 2, C = 3, D = "4"],
                [A = "5", B = 6, C = null, D = 8],
                [A = 9, B = null, C = "10", D = 11]
            }),
            f=(x)=> if x=null then 0 else Number.From(x),
            to = Table.TransformColumns(from, {"A", f} )
        in 
            to
    f – функция проверки на наличие null и преобразования текста в число (зачем выносить в отдельный шаг обсуждалось тут). Каждый столбец обрабатывается отдельно, поэтому пишем функцию от одного аргумента (само значение по столбцу) и ссылки на другие столбцы в этой ситуации недопустимы
    to – применение функции к столбцу А – т.е. второй аргумент – это список из названия столбца и функции преобразования. При этом на выходе мы получили числовые значения, но тип столбца не изменился.
    Дело в том, что преобразование значения и типизация столбца – это разные вещи:
    
        to = Table.TransformColumns(from,{"A", f, Int64.Type})
    
    Вот теперь и значения, и тип столбца какие нужно.

    ОК, но что если нужно менять несколько столбцов:
        
        to = Table.TransformColumns(from,{
            {"A", f, Int64.Type},
            {"B", f, Int64.Type},
            {"C", f, Int64.Type},
            {"D", f, Int64.Type}
        })
    
    Теперь второй аргумент – это список списков, где каждый отдельный элемент это {название, функция, опционально тип}
    Конструкция вышла несколько громоздкой, но мы решим эту проблему во второй части.

    Теперь зададимся вопросом – а можно применить функцию сразу ко всем столбцам? Ну, собственно, для этого и существует третий аргумент:
    
        to = Table.TransformColumns(from,{}, f)

        обращаю внимание – второй аргумент всегда должен быть списком, в данном случае это пустой список.
    
    Третий аргумент – это функция, которая будет применена ко всем столбцам, кроме указанных во втором аргументе, в данном случае – ко всем, чего мы и добивались.

    Но ведь часто один или несколько столбцов нужно пропустить, а вот к остальным применить функцию:
        
        to = Table.TransformColumns(from, {"A",(x)=>x}, f)

    в данном случае столбец A остается без изменений (надеюсь не нужно объяснять, что (x)=>x не делает ничего, просто возвращает переданный ей аргумент), а остальные столбцы изменяются.
    Недостаток подхода – можно применить функцию, но сразу обозначить ещё и тип столбца не получается (опять же – см. часть 2)

    Ну а пока рассмотрим ещё и четвертый аргумент – возможна ситуация, когда список преобразований типичный и известен заранее, а таблица передана неполная:

        to = Table.TransformColumns(
                from,
                {{"A", f, Int64.Type}, {"B", f, Int64.Type}, {"C", f, Int64.Type}, {"D", f, Int64.Type}, {"E", f, Int64.Type}},
                null,
                MissingField.Ignore
            )

    Видим, что в списке есть столбец E. При этом важно – хоть функцию по умолчанию мы в данном случае не используем, аргумент нельзя просто пропустить – поэтому мы ставим null. А последний аргумент - MissingField.Ignore, позволяет нам избежать ошибки отсутствующего столбца.
    Другое дело, если у вас, например, стандартная форма и такой столбец нужен, в этом случае:
        
        to = Table.TransformColumns(
            from,
            {{"A", f, Int64.Type},{"B", f, Int64.Type},{"C", f, Int64.Type},{"D", f, Int64.Type},{"E", f, Int64.Type}},
            null,
            MissingField.UseNull
        )
    Теперь на выходе мы получили все столбцы, даже отсутствовавшие в исходной таблице.

    Как-то так, дополнительные аргументы придуманы не просто так – они реально расширяют возможности.
    ]

[   Table.TransformColumns – Часть 2 Причём тут List.Transform  //? #АнатомияФункций – Table.TransformColumns , List.Transform

    Всем привет, продолжаем разбор Table.TransformColumns. В первой части мы столкнулись с громоздкой конструкцией для обработки всех столбцов
        
        let
            from = Table.FromRecords({
                [A = null, B = 2,    C = 3,    D = "4"],
                [A = "5",  B = 6,    C = null, D = 8],
                [A = 9,    B = null, C = "10", D = 11]
            }),
            f=(x)=> if x=null then 0 else Number.From(x),
            to = Table.TransformColumns(from,{{"A", f, Int64.Type},{"B", f, Int64.Type},{"C", f, Int64.Type},{"D", f, Int64.Type}})
        in 
            to
    
    Решение через третий аргумент было неполным, поскольку не позволило присвоить типы столбцам. 
    Как же быть? Просто вспомнить про Table.ColumnNames:
    
        let
            from = Table.FromRecords({
                [A = null, B = 2,    C = 3,    D = "4"],
                [A = "5",  B = 6,    C = null, D = 8],
                [A = 9,    B = null, C = "10", D = 11]
            }),
            f=(x)=> if x=null then 0 else Number.From(x),
            nms = Table.ColumnNames(from),
            lst = List.Transform(nms,(x)=>{x,f,Int64.Type}),    // вот тут фишка
            to  = Table.TransformColumns(from, lst)
        in 
            to

    Здесь
        nms – получили список названий всех столбцов,
        lst – преобразовали список названий в список списков, где каждый элемент – это {название, функция, тип}
        to  – успешно это применили

    Если нужно не трогать первый столбец:
        
        nms = List.Skip(Table.ColumnNames(from))

    Ну и в целом можно выбирать нужные столбцы через List.Select и далее осуществлять преобразование пачкой.
    Вроде несложно, а нервов экономит много, да и код выходит лаконичным и читаемым.
    ]

[   Сложно о функциях 1 - Типизация     / #АнатомияФункций - Type.ForFunction

    Всем привет!
    Недавно разбирали Table.TransformColumns и я там немного слукавил, сказав, что только с помощью функции нельзя передать тип столбца. На самом деле при написании функции мы можем указать тип возвращаемого значения, а также тип самого аргумента:
    
        f=(x)=>
        f=(x as any)=>
        f=(x as any) as number =>

    Явно указывать тип очень правильно – всё дело в том, что при использовании функции с объявленным типом, этот тип автоматом применяется и к столбцу. Но есть существенное НО – таким образом можно указать number, text, date и т.п.– так называемые примитивные типы. Но в упомянутом примере нам было нужно целое число (Int64.Type), а ещё часто бывают проценты (Percentage.Type), деньги в конце концов (Currency.Type). Такие типы указать уже не получится, хотя…
        
        let
            from = Table.FromRecords({
                [A = null, B = 2, C = 3, D = "4"],
                [A = "5", B = 6, C = null, D = 8],
                [A = 9, B = null, C = "10", D = 11]
            }),
            NumOrZero = [   func = (x)=> if x=null then 0 else Number.From(x),
                            ftyp = Type.ForFunction([ReturnType = Int64.Type, Parameters = [x = type any]], 1),
                            fres = Value.ReplaceType(func, ftyp)
                        ]  [fres],

            to = Table.TransformColumns(from, {}, NumOrZero)
        in
            to

    разбираем только шаг NumOrZero – это запись, причём возвращается только поле fres (зачем так – читаем тут)
    func – функция из предыдущего поста
    ftyp – а вот тут мы используем функцию Type.ForFunction, она формирует тип функции, принимая два аргумента:
    - signature – это запись из двух полей ReturnType (куда мы запишем возвращаемый тип – и здесь можно использовать Int64.Type) и Parameters (запись типов для аргументов – в данном случае один аргумент x)
    - min – минимальное число аргументов для вызова функции (в данном случае один обязательный аргумент – поэтому значение 1)
    fres – осталось только применить тип к нашей функции, для этого используем Value.ReplaceType

    Несложно убедиться, что код выше не только применяет функцию ко всем столбцам, но и меняет их тип на целочисленный

    Теперь немного усложним – хорошо и удобно, когда функция маленькая, тогда весь код выше пишется руками и один раз. Но если функция сложная, могут меняться типы аргументов, их количество. Конечно можно взять за правило сначала функцию написать, а потом задавать типизацию; но можно слегка автоматизировать процесс:

        NumOrZero = [
            func   = (x as any)=> if x=null then 0 else Number.From(x),
            typ    = Value.Type(func),
            params = Type.FunctionParameters(typ),
            min    = Type.FunctionRequiredParameters(typ),
            ftyp   = Type.ForFunction([ReturnType = Int64.Type, Parameters = params], min),
            fres   = Value.ReplaceType(func, ftyp)
        ]  [fres]

    func   – всё та же функция, но в ней указан тип для аргумента,
    typ    – получаем тип нашей функции (из чего он состоит мы только что разобрали),
    params – вытащили описание для аргументов
    min    – вытащили минимальное число аргументов для вызова 
             (FunctionRequiredParameters сама посчитает обязательные аргументы и отбросит те, для которых указано optional)
    ftyp   – а теперь пересобираем тип для функции, указав нужный ReturnType, а всё остальное в данном случае было сформировано автоматически
    fres   – ну и применяем к нашей функции сформированный тип.

    В этой ситуации, если в ходе отладки вы что-то поменяете в аргументах или в теле функции, код продолжит работу и ничего больше переписывать не придётся.
    ]

[   Сложно о функциях 2 - Документация  / #АнатомияФункций - Type.ForFunction
    Всем привет!
    Раз уж начали разбирать тему типизации функции, стоит рассмотреть ещё один, весьма важный вопрос. Все думаю знают, что при вызове встроенных функций появляется красивое диалоговое окно с её описанием, примерами использования, возможностью ввести аргументы.
    Если вам хотелось сделать подобное для собственных функций, код ниже для вас:
        
        let
            from = Table.FromRecords({
                [A = null, B = 2,    C = 3,    D = "4"],
                [A = "5",  B = 6,    C = null, D = 8  ],
                [A = 9,    B = null, C = "10", D = 11 ]
            }),
            NumOrZero = [   
                    func   = (x as any)=> if x=null then 0 else Number.From(x),
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
                                    [Description = "числа остаются числами",            Code = "=NumOrZero(5)",     Result = "5"], 
                                    [Description = "число как текст становится числом", Code = "=NumOrZero(""5"")", Result = "5"], 
                                    [Description = "null превращается в ноль",          Code = "=NumOrZero(null)",  Result = "0"]
                                }
                        ],
                    ftypwithmeta = Value.ReplaceMetadata(ftyp, doc), 
                    fres         = Value.ReplaceType(func, ftypwithmeta)
                ]  [fres],

            to = Table.TransformColumns(from, {},NumOrZero)
        in
            to

    Мы работаем всё с той же NumOrZero из предыдущего поста. Только в неё добавилось несколько шагов:
    
    doc - это запись, которая содержит элементы описания функции:

    Documentation.Name – название функции
    Documentation.Description и Documentation.LongDescription – описание функции (обратите внимание на теги – так можно навести красоту)
    Documentation.Examples – это список примеров. Каждый пример представляет собой запись из элементов [Description,Code,Result] – т.е. описание конкретного примера, собственно код и результат, который будет в этой ситуации возвращён

    Что же делать с этим описанием? Его необходимо добавить в тип нашей функции в виде метаданных

    ftypwithmeta – на этом шаге используется Value.ReplaceMetadata, которая и добавляет описание doc к типу ftyp
    fres         – ну и теперь применяем к нашей функции func тип с добавленными к нему метаданными.
    
    Теперь в редакторе, если выбрать шаг NumOrZero, вы можете увидеть полное её описание, что на мой взгляд выглядит более чем солидно.
    Конечно, я не призываю делать подобное с каждой функцией, но если вы написали что-то толковое, чем готовы поделиться с коллегами, лучше это сделать – и им будет удобнее, и вы сможете себя почувствовать «настоящим» разработчиком.
    ]

[   UnZip 1 - Общие замечания и код     / #АнатомияФункций – BinaryFormat.*

    Всем привет!
    В теме про TableToBinaryText уже поднимался вопрос о том, что docx, xlsx, pptx и прочие файлы офиса представляют собой zip-архивы. Соответственно, решение многих задач начинается с распаковки архива.

    Для начала несколько вводных замечаний:
    - zip-архив представляет собой бинарное содержимое определенной структуры
    - бинарное содержимое не имеет разметки и считывается последовательно
    - функции BinaryFormat.* аналогичны по использованию сплиттеру (сравните Text.Split(txt,” “) и Splitter.SplitTextByDelimiter(" ")(txt) – т.е. функция с её аргументами как бы пишется отдельно, а анализируемый аргумент во вторых скобках после функции
    - под двоичным форматом подразумевается порядок/характер считывания бинарной информации, фактически функция считывания

    Теперь к делу (телу))):
    (ZIP as binary) =>
    let
        ui16 = BinaryFormat.ByteOrder(BinaryFormat.UnsignedInteger16, ByteOrder.LittleEndian),
        ui32 = BinaryFormat.ByteOrder(BinaryFormat.UnsignedInteger32, ByteOrder.LittleEndian),
        f = (x) => try Binary.Decompress(x, Compression.Deflate) otherwise null,
        g = (x) => BinaryFormat.Transform(BinaryFormat.Binary(x),f),
        h = (x) => [    head = BinaryFormat.Record([a = BinaryFormat.Binary(14), size=ui32, c=ui32, name=ui16, extra=ui16])(x),
                        body = BinaryFormat.Record( [flag  = true,
                                                    Filename = BinaryFormat.Text(head[name]),
                                                    Extras   = BinaryFormat.Text(head[extra]),
                                                    Content  = g(head[size])])][body],
        iftrue = BinaryFormat.Choice(BinaryFormat.Binary(26),h),
        iffalse = BinaryFormat.Record([flag = false]),
        getfile = BinaryFormat.Choice(ui32, (x)=> if x = 67324752 then iftrue else iffalse, type binary),
        filelist = BinaryFormat.List(getfile, each [flag] = true)(ZIP),
        remove = List.RemoveLastN(filelist,1),
        to = Table.FromRecords(remove,{"Filename","Content"})
    in
        to

    Вот такая компактная и весьма шустрая функция. Можно просто скопировать и использовать. Тем же, кому интересно, как она устроена, рекомендую развернутый комментарий – всё просто не влезло в один пост.
    ]

[   UnZip 2 - Развернутый комментарий   / #АнатомияФункций – BinaryFormat.*
        Всем привет!
        Это комментарий к коду функции UnZip из предыдущего поста:
        ZIP – бинарное содержимое анализируемого файла
        ui16 и ui32 – форматы считывания байтов (2 и 4 байта соответственно, с обратным порядком байтов – так оно хранится в архиве)

        А теперь начну с конца, так будет понятнее:
        to – превратили список записей remove в таблицу
        remove – удалили последний элемент списка

        filelist – применяем BinaryFormat.List к нашему файлу ZIP. Идея простая – данная функция последовательно читает бинарное содержимое и формирует список, причем для считывания использует первый свой аргумент – getfile, а читает пока выполняется условие во втором аргументе. Проблема в том, что последний элемент, для которого условие уже не выполняется, также включается в список, потому и понадобился remove
        getfile – а вот это уже вынос мозга - BinaryFormat.Choice - первый аргумент показывает, что прочитать, а второй – что делать на основании прочитанного. В данном случае ui32 – прочитай четыре байта; если их числовое представление 67324752 (или шестнадцатеричное 04 03 4b 50 в обратном порядке, или 50 4b 03 04 в прямом, или PK\x03\x04 – сигнатура начала файла) то примени функцию iftrue иначе iffalse
        iffalse – как бы двоичный формат считывания записи, но по факту он ничего не читает просто возвращает [flag = false] и останавливает процесс
        iftrue – а вот здесь сложнее – снова BinaryFormat.Choice, только теперь считываем 26 байт (суммарно в начале файла всегда идет 30 байт информации, просто 4 мы уже считали в getfile, теперь дочитываем остаток) и применяем к ним функцию h (ещё раз напомню – функция определяет как мы будем читать последующее содержимое)
        h – функция в виде записи из двух полей; head анализирует наши 26 байтов (a - первые 14 просто прочитали, size – следующие 4, это размер файла, c – следующие 4 и по 2 байта name и extra – порядок важен, это бинарник) – т.е. мы получили информацию о длине имени файла, длине extra поля и размере самого содержимого; body – используем информацию для последующего считывания – имя, extra, содержимое – порядок также важен, причём Filename сразу читаем как текст, а вот с Content ещё нужно повозиться – мы вызываем функцию g
        g – мы не просто считываем содержимое, а осуществляем преобразование с использованием функции f
        f – ну вот и добрались – напоминаю, что мы читаем архив, а значит его содержимое надо перевести в несжатое состояние – Compression.Deflate потому что это стандарт для zip.
        Как-то так, код писать проще, чем объяснить его суть. Юзайте на здоровье!
    ]
[   UnZip 3 – Кириллические названия файлов / #АнатомияФункций – BinaryFormat.*

    Всем привет!
    Хочу логически завершить тему zip-архивов. В офисных документах все файлы имеют названия латиницей и проблемы с их чтением нет; но вот если вы откроете обычный zip, в котором названия файлов представлены кириллицей, то увидите такое: ����_����_�����.
    Дело в том, что в zip кириллица (а точнее всё, что не латиница) кодируется в DOS-кодировках. Чтобы решить проблему BinaryFormat.Text нужно передать вторым аргументом правильную кодировку, в случае кириллицы – это cp866.
    Ниже приведен код, в котором UnZip дополнена вторым аргументом, он не обязательный, а по умолчанию поддерживается кириллица.
    Ну и оформил «по-боевому» - с блекджеком, документацией и типизацией…
    [   func = (ZIP, optional cp)=>
            [   ui16 = BinaryFormat.ByteOrder(BinaryFormat.UnsignedInteger16, ByteOrder.LittleEndian),
                ui32 = BinaryFormat.ByteOrder(BinaryFormat.UnsignedInteger32, ByteOrder.LittleEndian),
                b = (x) => BinaryFormat.Binary(x),
                c = if cp is null then 866 else cp,
                f = (x) => try Binary.Decompress(x, Compression.Deflate) otherwise null,
                g = (x) => BinaryFormat.Transform(b(x),f),
                h = (x) => [head = BinaryFormat.Record([a = b(14), size=ui32, c=b(4), name=ui16, extra=ui16])(x),
                            body = BinaryFormat.Record( [ FileName = BinaryFormat.Text(head[name],c),
                                                    Extras   = b(head[extra]),
                                                    Content  = g(head[size]),
                                                    flag  = true])][body],
                iftrue = BinaryFormat.Choice(b(26),h),
                iffalse = BinaryFormat.Record([flag = false]),
                getfile = BinaryFormat.Choice(ui32, (x)=> if x = 67324752 then iftrue else iffalse, type binary),
                filelist = BinaryFormat.List(getfile, each [flag] = true)(ZIP),
                remove = List.RemoveLastN(filelist,1),
                to = Table.FromRecords(remove, type table [FileName = text, Content = binary])][to],
        typ = type function (
                    ZIP as (type binary meta [Documentation.FieldCaption = "бинарное содержимое (zip,xlsx,docx,pptx и т.п.)"]),
                    optional cp as (type number meta [Documentation.FieldCaption = "кодировка", Documentation.SampleValues = {866}])
                            )           
                    as table meta [ 
                                    Documentation.Name = "UnZip (@buchlotnik)",
                                    Documentation.LongDescription = "Функция считывает содержимое zip-архива и возвращает таблицу с полями FileName - имя файла (с путём, если он в подпапке) и Content - бинарное содержимое конкретного файла. Кодировка требуется для корректного распознавания <b>не латинских</b> имён файлов (для офисных документов указывать необязательно), по умолчанию 866 - кодировка DOS <b>с поддержкой кириллицы</b>"        
                                    ],
        result = Value.ReplaceType(func,typ)
    ][result]
    ]

[   Получаем все таблицы из файла Word /#АнатомияФункций – Xml.Document

    Всем привет!
    Захотелось рассмотреть практический аспект применения UnZip – получение всех таблиц из файла Word. По этому поводу функция:
    WordTablesList = (file)=>
        [
        getTable = (xml)=>[
            f=(x)=>[a = Table.SelectRows(x,(r)=>r[Name]="tr")[Value],
                    b = List.Max(List.Transform(a,Table.RowCount)),
                    c = Table.FromList(a,g,b)][c],
            g=(x)=>List.Transform(x[Value],h),
            h=(x)=>Text.Combine(List.Transform(Table.SelectRows(x,(r)=>r[Name]="p")[Value],i),"#(lf)"),
            i=(x)=>[a = Table.SelectRows(x,(r)=>r[Name]="r")[Value],
                    b = (x)=> Table.SelectRows(x,(r)=>r[Name]="t")[Value],
                    c = List.Combine(List.Transform(a,b)),
                    d = List.Select(c,(x)=>Value.Is(x,Text.Type)),
                    f = Text.Combine(d)][f],
            to = f(xml)][to],
        
        from = UnZip(file),
        xml = Xml.Document(from{[FileName="word/document.xml"]}[Content]){[Name="document"]}[Value]{[Name="body"]}[Value],
        filtr = Table.SelectRows(xml, each ([Name] = "tbl"))[Value],
        to = List.Transform(filtr,getTable)
        ][to]

    from – получили содержимое файла через UnZip
    xml – из содержимого получаем конкретно document.xml, в нем document, в нем body
    filtr - выбрали только таблицы - tbl (если вам нужны не таблицы, а текст – выбирайте p)
    to – вытащили из xml сами таблицы функцией getTable

    Теперь подробнее про getTable:
    to – итогом работы функции является применение функции f к xml-содержимому
    f – на шаге a вынимаем только теги tr – это строки таблицы, шаг b – находим максимальную длину строки (шаг нужен, поскольку таблицы могут быть с объединёнными ячейками), ну и на шаге с собираем таблицу с использованием вспомогательной g
    g – возвращает список, но к каждому элементу применяет h
    h – собирает текст через разрыв строки (в таблицах тоже бывают абзацы), применив к каждому абзацу функцию i
    i– докапывается до текста: a – берет теги "r", b – функция вынимания тега "t", c – получает из каждого элемента "t", d – оставляет только текстовое содержимое, f – собирает куски в единый текст.

    Как бы и всё. С непривычки код может и выглядит напряжно, но суть простая – последовательно «матрёшкой функций» разбираем «матрешку xml». Это намного эффективнее, чем мышкоклацать десятки шагов с разворачиванием столбцов, добавлением индексаций, пайвотом и прочей мутью, которые здесь совершенно не нужны.
    Так что пишите эффективно, пишите с удовольствием!
    ]
 
[   List.TransformMany или двойное преобразование / #АнатомияФункций – List.TransformMany

    Всем привет!
    В чате всплыла задачка, поэтому решил разобрать List.TransformMany.
    Читаем справку:
    List.TransformMany(list as list, collectionTransform as function, resultTransform as function) as list
    collectionTransform имеет сигнатуру (x as any) as list => ..., где x — это элемент в list. resultTransform проецирует форму результата и имеет сигнатуру (x as any, y as any) as any => ..., где x — элемент в list, а y — элемент, полученный путем применения collectionTransform к этому элементу.
    Мдя… давайте разбираться.
    Допустим имеем список {x1,x2,x3}.
    collectionTransform (cT) может просто преобразовать аргумент, а может породить список – и на выход мы получим {cT(x1) ={y1}, cT(x2)={y21,y22},cT(x3)={y31,y32,33}}.
    Далее resultTransform (rT) одновременно применяется и к исходным элементам, и к результату cT (к каждому отдельно – это самое важное), поэтому итоговый список будет выглядеть так: {rT(x1,y1),rT(x2,y21),rT(x2,y22),rT(x3,y31),rT(x3,y32),rT(x3,y33)}
    Таким образом функция принимает на вход список и возвращает список, но вот количество элементов итогового списка зависит от работы collectionTransform.

    Разберем упрощённый, но боевой пример:
        
        let
            from = Table.FromRecords({  [a="раз",b="1-1"],
                                        [a="два",b="2-1,2-2"],
                                        [a="три",b="3-1,3-2,3-3"]}),
            lst = Table.ToRows(from),
            tr = List.TransformMany(lst,(x)=>Text.Split(x{1},","),(x,y)=>{x{0}}&Text.Split(y,"-")),
            to = Table.FromRows(tr)
        in
            to

    from – на входе имеем таблицу, с проблемным столбцом b – в нём надо разделить элементы по запятой в отдельные строки, а далее каждый отдельный ещё разделить на два столбца, но уже по дефису. Обычно это делается через Table.TransformColumns, Table.ExpandList.Column, Table.SplitColumn; но сегодня мы про другое:
    lst  – превратили таблицу в список
    tr   – выкатываем List.TransformMany. collectionTransform - (x)=>Text.Split(x{1},",") – делим по запятой второй элемент в списке (это был столбец b). resultTransform - (x,y)=>{x{0}}&Text.Split(y,"-") – нам нужно получить элементы строки – это первый элемент из списка x (бывший столбец a) и результат разделения y по дефису. Таким образом, мы сразу получили список из нужного числа строк, причём для каждой строки сразу получили все элементы в ходе разделения
    to   – осталось только собрать строки обратно в таблицу
    
    Вуаля, задача решена.

    В целом функция прикольная, но весьма специфическая. Пихать её во все задачи я бы не стал – она МОЖЕТ добавить скорости, но это НЕ ОБЯЗАТЕЛЬНО - каждый раз нужно экспериментировать.
    А вот синтаксис действительно весьма лаконичный и на мой вкус прозрачный. Так что кому зайдет – юзайте на здоровье!
    ]
    
[   Self referencing query или incremental update в Excel / #АнатомияФункций – Excel.CurrentWorkbook()

    Всем привет!
    В чате всплыл вопрос, который следует разобрать.
    Итак, имеем папку с кучей файлов (стандартные выгрузки из какой-то системы), к которой мы подключаемся с целью получения аналитики. При этом в папке с определенной периодичностью появляются новые файлы и мы хотим добавлять информацию из них к нашей аналитике, а не закачивать каждый раз папку целиком. Вполне естественное желание, но в распоряжении у нас только Excel с поддержкой PQ. Решение состоит из нескольких шагов.

    Шаг 0 – исходный запрос (tst)
    
        let
            f=(x)=>Excel.Workbook(x){[Name="Таблица1"]}[Data],
            
            from = Folder.Files("D:\tst")[[Name],[Content]],
            tr   = Table.TransformColumns(from,{"Content",f}),
            tbl  = Table.ExpandTableColumn(tr, "Content", {"a".."c"})
        in
            tbl

    from – подключение к определённой папке, нас интересуют имена файлов и их бинарное содержимое
    tr  – преобразование бинарного содержимого с помощью функции f – в данном случае это просто получение данных из Таблицы1, понятно, что функция может быть любой
    tbl – ну и раскрыли столбец с содержимым, получили таблицу, порадовались и загрузили её на лист

    Шаг 1 – вспомогательный запрос (tmp)

        Excel.CurrentWorkbook(){[Name="tst"]}[Content]

    Вся суть приёма состоит в том, что при загрузке запроса tst на лист у нас появляется таблица с именем tst и мы подключаемся к ней. Т.е. с точки зрения связей tst тащит данные из папки, а tmp – какую-то таблицу из книги и эти запросы как будто не связаны

    Шаг 2 – меняем основной запрос (tst)
        
        let
            f=(x) =>Excel.Workbook(x){[Name="Таблица1"]}[Data],
            
            from  = Folder.Files("D:\tst")[[Name],[Content]],
            lst   = List.Buffer(List.Distinct(tmp[Name])),
            filtr = Table.SelectRows(from, (x)=> not List.Contains(lst,x[Name])),
            tr    = Table.TransformColumns(filtr,{"Content",f}),
            tbl   = Table.ExpandTableColumn(tr, "Content", {"a", "b", "c"}),
            cmb   = Table.Combine({tmp,tbl})
        in
            cmb

    ну и теперь колдунство – основные шаги остались те же, просто немножко добавляем:
    lst   – получили список уже загруженных файлов из tmp
    filtr – отфильтровали запрос к папке, оставив только ещё не загруженные файлы
    cmb   – объединили информацию из вновь загруженных файлов с имеющейся

    Всё! Пока в папке не появятся новые файлы, на лист будет грузиться tmp, т.е. имеющаяся информация, при появлении новых файлов – запрос обновится.
    Преимущества метода – очевидно это сильно ускоряет, особенно когда много файлов и большой скачиваемый объем. Недостаток – инфу нужно грузить на лист, файл становится большой и есть ограничение в 1 048 575 строк (про шапку не забываем). Конечно, на таких объемах стоит обсуждать что-то более цивилизованное: БД для данных, PBI для обработки… но за неимением графини, имеем горничную )))
    ]
   
[   Table.ExpandListColumn и Table.SplitColumn или как раскрыть список в столбцы / #АнатомияФункций - Table.ExpandListColumn, Table.SplitColumn

    Всем привет!
    Нашёлся инфоповод обсудить раскрытие списков в таблицах.
    Собственно, пример:

        let
            from = Table.FromRecords({  [a=1,b=2,c={{3,4},{5,6},{7,8}}],
                                        [a=9,b=8,c={{7,6},{5,4},{3,2}}],
                                        [a=1,b=3,c={{5,7},{9,8},{6,4}}]}),
            exp = Table.ExpandListColumn(from, "c"),
            splt = Table.SplitColumn(exp,"c",(x)=>x,{"c","d"})
        in
            splt

    from – таблица, в которой столбец c содержит в качестве значения список списков. Задача раскидать элементы в новые строки, а далее по столбцам
    exp  – первая часть решается легко через Table.ExpandListColumn
    splt – а вот со второй частью через мышкоклац обычно сначала извлекают значения в текст с разделителями, а потом сплитят по этому же разделителю – ТАК ДЕЛАТЬ НЕ НАДО – надо сообразить, что Table.SplitColumn ждет от нас функцию, генерящую список значений, но у нас на входе и так список значений, поэтому (x)=>x – т.е. функция просто возвращает имеющийся список, и всё, никаких лишних телодвижений. Вот.
    ]

[   Table.FromList + GroupKind.Local – шустрое подобие регулярок / #АнатомияФункций - Table.FromList, GroupKind.Local

    Всем привет!
    Опять зачастили вопросы по регуляркам, которые не подвезли. Посему хочу разобрать небольшой пример и предложить принцип решения - разбиваем текст посимвольно, а затем группируем их в соответствии с заданным условием.
    Ну поехали:
        
        let
            ld  = List.Buffer({"0".."9"}),
            ldp = List.Buffer(ld&{"(",")"," ","-"}),
            
            f=(x)=>[a = Table.FromList(Text.ToList(x),(x)=>{x,if List.Contains(ldp,x) then 0 else 1},{"y","z"}),
                    b = Table.Group(a,"z",{"i",each Text.Combine([y])},GroupKind.Local)[i],
                    c = List.Transform(b,(x)=>Text.Select(x,ld)),
                    d = List.Select(c,(x)=>x<>"")][d],
            
            lst = { " +7 (495) 617-61-16б доб. 1503",
                    "тел: +7-913-728-64-87 Владимир",
                    "(4152), доб. 23-81-47 +7962 215 17 17",
                    "8 (423) 2 60-84-84, 143(внутренний)",
                    "8 (495) 229-49-69, доб. 114",
                    "+7 (383) 286-87-08 ext.24120"},
            to = Table.FromList(lst,(x)=>{x}&f(x),4)
        in
            to

    lst – наш источник, для простоты в виде списка – задача вынуть номера телефонов
    to  – собрали из списка таблицу с использованием функции f

    Ну а теперь о функции.
    Для начала заведём два вспомогательных списка – ld и ldp
    ld  – список цифр (именно символов, кавычки не забываем) - это список символов, которые нас интересуют в конечном результате
    ldp – к списку ld добавили символы, которые могут встречаться в номере телефона – скобки, пробелы, дефис - это список символов, которые могут быть объединены в одну группу
    Обращаю внимание – списки вынесены в отдельные шаги и помещены в List.Buffer – это важно для ускорения работы

    Теперь сами шаги функции:
    a – собираем таблицу из списка символов анализируемого значения. На выход получим таблицу из двух столбцов – y это сам символ, а z – будет нулевым, если символ может содержаться в номере и единица – если не может
    b – группируем по z, локально, пятый аргумент не пишем (подробно про пятый аргумент разбиралось тут), агрегируем в текст. Таким образом все потенциальные символы из номера телефона будут сгруппированы в отдельные текстовые значения
    c – чистим полученные тексты, оставляя только символы из списка ld
    d – выбираем не пустые тексты
    Собственно, всё. Тонкую настройку работы функции можно осуществить меняя списки ld и ldp, экспериментируйте )))
    ]

[   Table.Skip – отделяем лишнее в таблице / #АнатомияФункций - Table.Skip

    Всем привет!
    По мотивам недавнего обсуждения в чате обсудим вопрос пропуска лишних строк в таблице.
    Основной пример:

        let
            from = Table.FromRecords(Json.Document(Binary.Decompress(Binary.FromText("3VO7DsIwDPwV5LlDHTuEsvIZhaEVMIUyZUL8O6qDVAeUSK0YgOXk6+Nsn+32BrurD5cBYTsE76snNSmllHJKbUrXkd6rP9CGfaiZziMySmwFjSALnuTtRuJ6+p66+AR+se+yNqjuY8fHCbmPPoHKjh9OLUPgZkSLq7nVmC8xOfbiVOE0LRT1KjYq7vRCLZRAeLN0tobRli7UIFB2gboa+YPjZTlQJi5MZCFxHvMjdfl5IpWmaZSmze8IFm4BXaJI+SqbQpX2tcrDAw=="),Compression.Deflate))),
            skip=(x)=>Table.Skip(x),
            to = skip(from)
        in
            to

    Далее будем менять только функцию skip.

    Итак, в примере выше функции Table.Skip передан только один аргумент – сама таблица, поэтому будет пропущена только первая строка. Результат не впечатляющий, пропустить нужно несколько, поэтому:
    
        skip=(x)=>Table.Skip(x,8)   
    
    Так уже лучше, но мы задали количество строк в явном виде. Но что если мы не знаем сколько строк необходимо пропустиь? Почему-то многие начинают именно вычислять число пропускаемых строк, сооружая жуткие конструкции с индексацией и прочим.

    Фишка состоит в том, что во второй аргумент можно передать условие:

        skip=(x)=>Table.Skip(x,(r)=>r[Column1]=null)

    Обращаю внимание – функцию во втором аргументе пишем от записи. Будут пропущены все строки, которые СООТВЕТСТВУЮТ условию. В данном случае пока в Column1 будет встречаться null.
    Результат не очень – давайте просто сменим столбец:
    
        skip=(x)=>Table.Skip(x,(r)=>r[Column2]=null)
    
    Теперь результат как надо.
    Понятно, что мы не знали сколько строк пропустить, но знали в каком столбце искать. Причём искать можно не только null:

        skip=(x)=>Table.Skip(x,(r)=>r[Column1]<>"заголовок")

    в данном случае поиск по Column1 закончится на строке, содержащей «заголовок».

    Но что, если мы знаем какое слово искать, но не знаем ни строки, ни столбца? Да пожалуйста:

        skip=(x)=>Table.Skip(x,(r)=>not List.Contains(Record.ToList(r),"ключ"))

    в этой ситуации каждую строку мы превращаем в список и проверяем в нём наличие конкретного значения.

    Наконец, в самом плохом случае, мы можем даже значение целиком не знать, только его фрагмент. Но тоже не проблема:
        
        skip=(x)=>Table.Skip(x,(r)=>not Text.Contains(Text.Combine(List.Select(Record.ToList(r),(x)=>x is text)),"клю"))
    
    Тут финт ушами состоит в том, что превратив строку в список, мы выбираем только текстовые значения (is text), сцепляем все в одну строку (при этом пропускаем все null) и уже её проверяем на наличие фрагмента. Выходит достаточно шустро.

    Как-то так. Простая функция, несложные приёмы, но очень лаконично можно получить нужный результат в одну строку.
    ]

[   Зачем нужны вспомогательные запросы при объединении файлов из папки? / #НеВсеЙогуртыОдинаковоПолезны
    
    Всем добра! Регулярно то тут, то там всплывает проблема по сборке данных из кучи файлов, которые сначала нужно причесать.
    Сегодня расскажу про механизм автоматической генерации запросов интерфейсом редактора.
    Итак, когда делаете запрос к папке и разворачиваете структуру бинарников как на картинке☝️, то автоматически генерится вот такая структура из запросов:
    где
    123 - это собственно запрос к папке с названием "123"
    
    Запрос "Пример файла" - это запрос, который по заданному в нем алгоритму выбирает тот единственный файл, из папки по образцу которого будет формироваться шаблонный запрос обработки и функция на его основе.
    
    Запарос "Параметр1" - это собственно параметр, значением которого является бинарное содержимое файла из запроса "Пример файла"
    
    Запрос "Преобразовать пример файла" - это шаблонный запрос, в который в качестве параметра передается бинарник из предыдущего шага и в нем же формируется алгоритм обработки единичного файла из папки перед сборкой в единый массив
    
    Функция "Преобразовать файл" - это функция, которая связана с запросом "Преобразовать пример файла", Что это значит? Это значит что код функции берется напрямую из этого запроса, т.е. если изменить запрос-шаблон, то автоматически изменится и функция. Эта самая функция как раз и вызывается для обработки бинарников в запросе "123".

    Что из вышеизложенного следует? Лезем в этот самый запрос-шаблон (он же "Преобразовать пример файла") и в нем производим причесывание по выбранному вами алгоритму, а далее, когда будем разворачивать содержимое файлов в единый массив, там уже будут все нужные вам строки и столбцы. Такая обработка всегда работает гораздо быстрее.
    Зачем все это надо? Для обеспечения юзерам возможности легкого редактирования шаблонного запроса после подключения к папке: нет мороки с написанием этого запроса вручную, с переделыванием ее в функцию, с отлавливанием багов, если ошибка скрывается именно в этой функции, и много чего еще.
    Продолжение следует...
    ]

[   Table.ReplaceErrorValues, Table.RemoveRowsWithErrors – чистим входящие данные / #АнатомияФункций - Table.ReplaceErrorValues, Table.RemoveRowsWithErrors

    Всем привет!
    Дважды за последние сутки всплывал вопрос как поступать с ошибками данных в исходнике. Имеются ввиду ошибки на листах - #ДЕЛ/0!, #ССЫЛКА!, #Н/Д и т.д. Понятное дело, что наилучшее решение – влезть в исходник и ошибки исправить. Но если у нас доступ только на чтение или, например, в файле протянуты формулы, а ячейки не все заполнены, что и вызывает ошибки – в такой ситуации приходится заниматься обработкой при загрузке.

    Здесь два варианта – заменить или удалить.
    Начнём с замены – нам в помощь Table.ReplaceErrorValues.
    Тут всё просто:
        
        Table.ReplaceErrorValues(table, {"Column2", null})
    
    Вторым аргументом – {имя столбца,на что заменить ошибку}
    Хотя если мышкоклацать, код будет выглядеть так:
    
        Table.ReplaceErrorValues(table, {{"Column2", null}})
    
    Т.е. автоматом вводится список списков - ведь за один раз можно обрабатывать более чем один столбец:
        
        Table.ReplaceErrorValues(table, {{"Column2", null},{"Column4", null}})
    
    Причём в разных столбцах значение для замены может быть разным:
    
        Table.ReplaceErrorValues(table, {{"Column2", null},{"Column4", 0}})

    Но что, если мы хотим обработать сразу все столбцы:
        
        Table.ReplaceErrorValues(table, List.Transform(Table.ColumnNames(table),(x)=>{x,null}))
    
    Т.е. получили список всех столбцов и превратили его в список списков вида {имя, null}
    Теперь с удалением строк. Тут работает Table.RemoveRowsWithErrors.
    
    Синтаксис ещё проще:
        
        Table.RemoveRowsWithErrors(table, {"Column2"})

    Но обращаю внимание – функция ищет ошибки только в указанном столбце, хотя удаляет всю строку с ошибкой. Для нескольких столбцов всё также несложно:
        
        Table.RemoveRowsWithErrors(table, {"Column1", "Column2", "Column3"})

    А как удалить строки с ошибками сразу по всем столбцам? И вот тут мы не будем сооружать ничего:
        
        Table.RemoveRowsWithErrors(table)

    Т.е. по умолчанию без второго аргумента функция обрабатывает все столбцы (обратите на это внимание – через мышкоклац второй аргумент всегда добавляется и может порождать неприятные сюрпризы).

    Как-то так – ошибки в исходных данных можно очистить, но всегда важно понимать – не повлечет ли такое удаление или замена искажения аналитики, может все-таки лучше поправить исходник.
    ]

[   UnFill или как учесть значения из предыдущих или последующих строк / #АнатомияФункций – Table.ToColumns, Table.FromColumns

    Всем привет! В чате подкинули задачку – сделать «FillDown наоборот». Сложность задачи состоит в том, что при преобразовании столбца нам необходимо учесть значения в предыдущих строках. Напрямую M так не умеет, решения через индексы – это в категорию #НеВсеЙогуртыОдинаковоПолезны; но есть приём, который и используем.
    Сразу код:

        let 
            UnFill =(tbl,col,optional up)=>
                [   a = Table.ColumnNames(tbl),
                    b = List.PositionOf(a,col),
                    c = Table.ToColumns(tbl),
                    d = c{b},
                    e = if up is null or up = 0 then {null}&List.RemoveLastN(d,1) else List.Skip(d),
                    f = List.Transform(List.Zip({d,e}),(x)=>if x{0}=x{1} then null else x{0}),
                    g = List.ReplaceRange(c,b,1,{f}),
                    h = Table.FromColumns(g,a)
                ][h],
                
            from = Table.FromRecords(Json.Document(Binary.Decompress(Binary.FromText("xdExCoAwDAXQu3R2aNJUoVdRF6tOxa2TeHcxESq4qENcPh1+8qBpV9NlS0BHOss5lqSB394EruF8KWAZIcloKq4RcEph4pQ9YAJslTaJ+uSSU9JX3VtSar6Qgp2Dw2OY/oK//POPNsTbXfGB5HWYWodpdBi987DU7w=="),1))),
            unfilldown = UnFill(from,"Данные"),
            unfillup = UnFill(from,"Данные",1),
            unfilldown2 = UnFill(from,"Данные",0) 
        in 
            unfilldown2

    Видим функцию UnFill – я немного обобщил задачу, поэтому функция принимает анализируемую таблицу, столбец для преобразования и опциональный аргумент, который отвечает за выбор FillDown или FillUp мы хотим «отменить».
    По шагам:
    a – получили список имен столбцов
    b – нашли номер интересующего нас столбца
    c – получили список списков – список, где каждый элемент – это список значений конкретного столбца
    d – взяли интересующий нас столбец
    e – а вот и начинается магия: если у нас Down – мы берем пустой элемент и добавляем к нему наш список без последнего значения, т.е. получаем список предыдущих значений; если Up – наоборот, удаляем первый элемент и получаем список последующих значений
    f – попарно объединяем элементы исходного и преобразованного списков и сравниваем их – если одинаковые – возвращаем null, иначе сохраняем элемент исходного списка
    g – теперь дело за малым – подсовываем результат наших преобразований на место исходного столбца (обратите внимание на конструкцию {f} – нам нужно передать элемент списка)
    h – ну и собираем таблицу обратно

    Всё, задача решена. unfilldown, unfillup, unfilldown2 – просто примеры корректного синтаксиса при использовании.
    Вот так, курите списки, чтобы шаманить таблицы 😉
    ]

[   Propis    - сумма прописью / #АнатомияФункций - custom

    Всем привет! Всплыл скелет из шкафа - когда-то давно писал функцию для суммы прописью, там нашлась бага. Багу исправил, выкладываю как есть, код хоть и старый но вполне годный:
        
        Propis=
            (num)=>
            [ 
                ln = { {"десять ","одиннадцать ","двенадцать ","тринадцать ","четырнадцать ","пятнадцать ","шестнадцать ","семнадцать ","восемнадцать ","девятнадцать "},
                    {"","сто ","двести ","триста ","четыреста ","пятьсот ","шетьсот ","семьсот ","восемьсот ","девятьсот "},
                    {"","","двадцать ","тридцать ","сорок ","пятьдесят ","шестьдесят ","семьдесят ","восемьдесят ","девяносто "},
                    {"","один ","два ","три ","четыре ","пять ","шесть ","семь ","восемь ","девять "},
                    {"","одна ","две ","три ","четыре ","пять ","шесть ","семь ","восемь ","девять "}
                },
                lr = { {"","миллиард ","миллиарда ","миллиарда ","миллиарда ","миллиардов "},
                    {"","миллион ","миллиона ","миллиона ","миллиона ","миллионов "},
                    {"","тысяча ","тысячи ","тысячи ","тысячи ","тысяч "},
                    {""," "," "," "," "," "}
                },
                
                fn = (n,r)=> [ 
                    t = List.Transform(Text.ToList(n), each Number.From(_)),
                    x = ln{1}{t{0}} & (if t{1}<>1 then ln{2}{t{1}} & (if r = 2 then ln{4}{t{2}} else ln{3}{t{2}}) else ln{0}{t{2}}),
                    y = lr{r}{if t{1}=1 or t{2}=0 then 5 else List.Min({t{2},5})},
                    z = if Number.From(n)=0 then "" else x&y
                ][z],
                
                t = Splitter.SplitTextByRepeatedLengths(3)(Number.ToText(num,"000000000000")),
                z = if num = 0 then "ноль" else Text.Combine(List.Transform({0..3},each fn(t{_},_)),"")
            ][z]

    Работает с целыми числами от нуля до 999 999 999 999. Кому нужны триллионы - завидую, но допиливайте самостоятельно (уговорили - допилил)😉
    ]
[   PropisRub - сумма прописью (дополнение)
    #АнатомияФункций – custom
    Всем привет!
    Начали тут. Не думал, что добавить триллионы рублей такая проблема, но раз уж надо:
       
        PropisRub=(x)=>
        [   ln = { 
                {"десять ","одиннадцать ","двенадцать ","тринадцать ","четырнадцать ","пятнадцать ","шестнадцать ","семнадцать ","восемнадцать ","девятнадцать "},
                {"","сто ","двести ","триста ","четыреста ","пятьсот ","шестьсот ","семьсот ","восемьсот ","девятьсот "},
                {"","","двадцать ","тридцать ","сорок ","пятьдесят ","шестьдесят ","семьдесят ","восемьдесят ","девяносто "},
                {"","один ","два ","три ","четыре ","пять ","шесть ","семь ","восемь ","девять "},
                {"","одна ","две ","три ","четыре ","пять ","шесть ","семь ","восемь ","девять "}
            },
        
            lr = { 
                {"","триллион ","триллиона ","триллиона ","триллиона ","триллионов "},
                {"","миллиард ","миллиарда ","миллиарда ","миллиарда ","миллиардов "},
                {"","миллион ","миллиона ","миллиона ","миллиона ","миллионов "},
                {"","тысяча ","тысячи ","тысячи ","тысячи ","тысяч "},
                {"","","","","",""}
            },
            
            lc = { 
                {"лей","ль","ля","руб"},
                {"ек","йка","йки","копе"}
            },
            
            txt=(n,r)=>[ 
                a = List.Transform(Text.ToList(n), each Number.From(_)),
                b = ln{1}{a{0}} & (if a{1}<>1 then ln{2}{a{1}} & (if r = 3 then ln{4}{a{2}} else ln{3}{a{2}}) else ln{0}{a{2}}),
                c = lr{r}{if a{1}=1 or a{2}=0 then 5 else List.Min({a{2},5})},
                d = if Number.From(n)=0 then "" else b&c
            ]  [d],

            cur=(x,y)=>[ 
                a = Number.From(x),
                b = if Number.IntegerDivide(a,10)=1 or Number.Mod(a+9,10)>3 
                    then lc{y}{0} 
                        else if Number.Mod(a,10)=1 
                             then lc{y}{1} 
                             else lc{y}{2},
                c = lc{y}{3} & b
            ]  [c],
            
            prp=(x)=>[ 
                a = Splitter.SplitTextByRepeatedLengths(3)(x),
                b = Text.Combine(List.Transform({0..4}, each txt(a{_},_)),""),
                c = if Number.From(x)=0 then "ноль " else b
            ]  [c],

            lst = Text.Split(Number.ToText(Number.Round(x,2),"000000000000000.00","en-US"),"."),
            
            res =   prp(lst{0})&
                    cur(Text.End(lst{0},2),0)
                    &" "&
                    lst{1}
                    &" "&
                    cur(lst{1},1)
        ][res]

    Расширен диапазон, рубли и копейки склоняются. Юзайте на здоровье. Багрепорты по использованию приветствуются, а вот перламутровых пуговиц с расправленными крыльями не держим.
    ]

[   Buffer 1 – List.Buffer / #АнатомияФункций – List.Buffer

    Всем привет! Что-то назрело обсуждение буферов в M. Начнем с самого, на мой взгляд, простого – List.Buffer. В качестве аргумента функция принимает список и … возвращает список. Суть в том, что список помещается в память и является стабильным (stable). Иными словами, после помещения в буфер список заново не вычисляется.
    Зачем оно надо?
    Возьмем такой пример:
    let
    from = #table({"fio"},{{"Иван ИвановичИванов"},{"Пётр ПетровичПетров"},{"Евлампий ЕвлампиевичЕвлампиев"},{"JohnSmith"}}),
    f=(x)=>Text.Combine(Splitter.SplitTextByCharacterTransition({"a".."z"}&{"а".."я"},{"A".."Z"}&{"А".."Я"})(x)," "),
    to = Table.TransformColumns(from,{"fio",f})
    in
    to
    Фамилия прилипла к имени и отчеству. Разделяем через Splitter.SplitTextByCharacterTransition и обратно собираем, но уже через пробел. Всё просто, но не совсем.
    Дело в том, что функция f будет вызываться для каждого элемента столбца. А в качестве аргументов у нас указаны последовательности ({"a".."z"} - это не сокращённая запись, это именно последовательность, которая вычисляется на основании кодов символов) – таким образом аргументы будут вычисляться при каждом вызове. И вот чтобы этого избежать пишем так:
    let
    from = #table({"fio"},{{"Иван ИвановичИванов"},{"Пётр ПетровичПетров"},{"Евлампий ЕвлампиевичЕвлампиев"},{"JohnSmith"}}),
    a = List.Buffer({"a".."z"}&{"а".."я"}),
    b = List.Buffer({"A".."Z"}&{"А".."Я"}),
    f=(x)=>Text.Combine(Splitter.SplitTextByCharacterTransition(a,b)(x)," "),
    to = Table.TransformColumns(from,{"fio",f})
    in
    to
    Собственно, всё то же самое, только списки вынесли в отдельные шаги и поместили их в буфер. Теперь аргументы нашей функции будут вычислены однократно и далее будут использоваться в обработке.
    На массиве в 50k строк добавление буфера позволило сократить обработку с 4 до 2 секунд (ну то есть в два раза).
    Вот так – следите за многократно используемыми списками (списки имен столбцов, списки дат и т.п.) и буферите их - это действительно влияет на скорость обработки.
    ]

[   ? ?? – Field Access и Coalesce – или зачем задавать вопросы в коде / #АнатомияФункций – основы

    Всем привет!
    Давайте поставим точку в вопросе знаков вопроса 😉. Уже разбирали тут, поэтому просто напомню:
    
        {1,2,3,4}{7}                                            // ошибка – элементов в перечислении недостаточно
        [a= "Вася", b= "Петя", c="Коля"][d]                     // ошибка – поле записи не найдено
        Excel.CurrentWorkbook(){[Name="Таблица124"]}[Content]   // ошибка, если нет такой таблицы

    Проблема решается путем использования ? (знак вопроса):
        
        {1,2,3,4}{7}?                                           // null
        [a= "Вася", b= "Петя", c="Коля"][d]?                    // null
        Excel.CurrentWorkbook(){[Name="Таблица124"]}?[Content]? // null

    Т.е. при обращении к элементу списка или полю таблицы, в случае их отсутствия оператор ? вернёт нам null – это лучше, чем ошибка.

    Но что если нам не нужен null? Ведь результат может использоваться далее в расчётах и нам может понадобиться 0, {}, [], "" (ноль, пустой список, пустая запись, пустая строка и т.п.) или просто служебное сообщение вроде «не найдено».
    Во тут нам на помощь и приходит оператор ?? – объединение (coalesce). В общем виде это выглядит так:
        
        x??y
        если x не null – будет возвращён x, иначе – y.

    Ну а в нашем случае:
    
        {1,2,3,4}{7}? ??0                                           // 0 – ноль
        [a= "Вася", b= "Петя", c="Коля"][d]? ?? ""                  // пустая строка
        Excel.CurrentWorkbook(){[Name="Таблица124"]}?[Content]? ??"данные не найдены"   // данные не найдены
    
    возвращается нужное значение - главное не забыть поставить пробел между ? и ?? .

    Вот так – никаких try, никаких if then else, просто знаки вопроса, поставленные в правильном месте.
    В чате можно глянуть на боевой пример – берите на вооружение.
    ]

[   (x)=>x или зачем нужна функция, которая ничего не делает? / #АнатомияФункций – общие вопросы

    Всем привет!
    В свое время мы разбирали как написать «пустой аргумент» - нам это было нужно, поскольку различные операции осуществляются с разными типами данных и важно задать правильный. Но точно так же бывают ситуации, когда в качестве аргумента мы должны передать функцию, а на самом деле никаких преобразований не требуется.
    Вот в таких ситуациях нас и выручает
        
        (x)=>x

    Это функция, принимающая аргумент x и возвращающая этот самый аргумент. Фактически мы написали функцию, которая ничего не делает (но при этом является функцией!).
    Зачем оно надо? Смотрим пример и ниже разберём по шагам:

        let
            tbl   = #table({"n","a".."f"},{{"i",1..5,{1,2,3}},{"j",2..6,{1,2}},{"k",3..7,{1}},{"i",4..8,{1,2}},{"j",5..9,{1}}}),
            group = Table.Group(tbl,"n",{"tmp",(x)=>x}),
            add   = Table.AddColumn(tbl,"tmp",(x)=>x),
            pivot = Table.Pivot(tbl[[n],[a]], {"i".."k"}, "n", "a",(x)=>x),
            comb  = Table.CombineColumns(tbl,List.Skip(Table.ColumnNames(tbl)),(x)=>x,"tmp"),
            splt  = Table.SplitColumn(tbl,"f",(x)=>x),
            from  = Table.FromList(tbl[f],(x)=>x)
        in
            from

    tbl   – входные данные
    group – мы группируем по столбцу n и хотим получить все данные, поэтому функция агрегации нам и возвращает их все. Заодно мы узнали, что при группировке получается таблица (table), т.е. если вы заранее не знаете от какого типа данных писать агрегатор – напишите (x)=>x и увидев результат, делайте выводы
    add   – добавление столбца к таблице, аналогично – функция возвращает всё, что поступило на вход – и в данном случае это запись (record). Т.е. мы выяснили, что на вход функции подается строка целиком в виде записи
    pivot – не люблю эту функцию, но сказать необходимо – при сведении данных от нас также хотят функцию агрегации, которой на вход приходит… список (list). Мышкоклацем так не сделать – если выбрать «не агрегировать» - функция будет записана без пятого аргумента и выдаст ошибку, а так всё работает.

    Все примеры выше больше направлены на понимание того, с каким типом данных мы работаем, но есть вполне прикладные таблично-списочные операции:

    comb  – хотим собрать значения из ряда столбцов в список, от нас требуют Combiner как функцию – только у нас на входе и так список значений, и теперь мы знаем что с этим делать
    split – этот пример уже разбирали - нам вроде как нужно разделить столбец, только он уже разделен, поэтому не делаем ничего
    from  – ну и для меня наиболее частый случай – сбор таблицы из списков – «почему не просто через Table.FromRows?» спросите вы – «потому что попробуйте прям на этом примере» отвечу я – FromRows требует списков одинаковой длины, а FromList – это функция пяти аргументов и с ней можно договориться, просто в данном случае её аргумент Splitter не должен делать ничего.

    Как-то так. В М крайне важно использовать/передавать/обрабатывать корректные типы данных. Функция – это тоже тип данных и сегодня мы выяснили, как её написать, чтобы она была, но «ничего не делала».
    ]
[   Date + Time = ? получаем датувремя из даты и времени / #АнатомияФункций - DateTime.From, DateTime.FromText

    Всем привет! Что-то последнее время несколько раз проскочила задачка по объединению даты и времени в датувремя. Зачем оно надо? Да просто реально частенько дата и время хранятся в отдельных столбцах, а надо анализировать периоды – т.е. разницы между строками и можно заморочиться на вычисление разницы дат и отдельно времени, а можно получить датувремя и просто считать разницу – реально удобнее.
    Ну поехали. Пример будет предельно простой:
        
        let
            date = #date(2022,8,6),
            time = #time(1,41,26),
            datetime0 = date + time, // Не удается применить оператор + к типам Date и Time
            datetime1 = DateTime.From(Number.From(date) + Number.From(time)),//06.08.2022 1:41:26
            datetime2 = DateTime.From(Text.From(date)&" "&Text.From(time)), //06.08.2022 1:41:00
            datetime3 = DateTime.From(Text.From(date)&" "&Time.ToText(time,"hh:mm:ss")),//06.08.2022 1:41:26
            datetime4 = DateTime.From(Text.From(date)&Time.ToText(time,[Format=" hh:mm:ss"])),//06.08.2022 1:41:26
            datetime5 = DateTime.From(date) + Duration.From("0."&Time.ToText(time,[Format="T"])),//06.08.2022 1:41:26
            datetime6 = DateTime.FromText("06.08.2022"&"01:41:26",[Format="dd.MM.yyyyhh:mm:ss"]),//06.08.2022 1:41:26
            datetime7 = DateTime.FromText("2022-08-06T01:41:26",[Format="yyyy-MM-ddThh:mm:ss"]),//06.08.2022 1:41:26
            datetime8 = date & time //06.08.2022 1:41:26

        in
            datetime8

    Для начала – date и time – исходные дата и время. Обращаю внимание date – это просто имя, а #date() – функция, создающая значение даты, с time аналогично – не забываем и не путаем – диез решает )))
    Теперь по шагам:
    datetime0 – самое простое и естественное, что может придумать эксельщик – попробовать сложить два значения. Но так не выйдет – здесь нет автоматического преобразования типов, а дата и время – это разные типы данных. Поэтому придется колдовать.
    datetime1 – раз нельзя просто сложить – пробуем привести типы – и дату, и время превращаем в числа, суммируем, из результата получаем датувремя – работает, прям как в Excel – и надо сказать это самый быстрый (с точки зрения производительности) способ
    datetime2 – альтернативный способ – превратить оба значения в текст, сконкатенить и получить датувремя из текста – здесь есть проблема – Text.From "съедает" секунды.
    datetime3 – решение проблемы секунд – использовать Time.ToText – в этом шаге представлен старый синтаксис, который работает в любой версии – вторым аргументом указан формат
    datetime4 – то же самое, но в новом синтаксисе – здесь вторым аргументом идёт запись, одно из полей которой – формат. Обращаю внимание, что пробел можно "загнать" в формат
    datetime5 – ещё один способ, который особенно хорош, если у вас дата и время уже на входе в виде текста – превратить дату в датувремя, а время – в длительность и сложить (этот способ быстрее, чем через конкатенацию текста, но медленнее чем через Number.From)

    Ну и обсуждая DateTime.From, нельзя не вспомнить про DateTime.FromText – специализированная функция для вынимания датывремени из текста.
    datetime6 – оказывается можно не заморачиваться с пробелами, а просто "объяснить" в каком формате данные находятся на входе. Причём формат может быть самый разный.

    datetime7 – кто получал такие значения в запросах и потом парился со строковыми преобразованиями и локалями сейчас наверное прослезились от умиления – так тоже можно.

    UPD datetime8 - так увлекся преобразованиями, что не написал главное (спасибо @sboy_ko - напомнил) - дату и время нельзя складывать, но можно конкатенировать (всё-таки и то и другое - особая форма record )

    Собственно, всё. Вроде ничего запредельного – главное помнить про типы данных и форматы. Через текст нагляднее, через числа быстрее – но всё зависит от конкретной задачи и типов данных на входе.
    ]

[   Text.Combine – собираем текст воедино / #АнатомияФункций – Text.Combine

    Всем привет! Проанализировал свои сообщения из чата – в лидерах используемых функций List.Transform (потому что на списках быстрее), далее Excel.CurrentWorkbook (без комментариев), далее Table.ColumnNames (её я не разбирал, но тут и разбирать нечего – даёт список имён столбцов таблицы), а вот четвертой оказалась Text.Combine – если честно, удивлён – но думается тут есть о чём поговорить.
    Итак, справка:

    Text.Combine(texts as list, optional separator as nullable text) as text

        texts – список текстовых значений, проверяем:
        Text.Combine({"мама","мыла","раму"}) //мамамылараму
        Text.Combine({"a".."f"}) //abcdef
        Text.Combine({"1".."5"}) //12345
        Text.Combine({1..5}) //Expression.Error: Не удается преобразовать значение 1 в тип Text
    
    Последний вариант - это одна из типичных ошибок, объединять можно только текст.
    separator – необязательный аргумент, без него объединение идет через «ничего», а точнее пустую строку:
    
        Text.Combine({"мама","мыла","раму"},"") //мамамылараму
    
    Получили то же самое, что и выше.
    Ну а если использовать не нулевую строку:

        Text.Combine({"мама","мыла","раму"}," ") // мама мыла раму
        Text.Combine({"мама","мыла","раму"},"-") // мама-мыла-раму
        Text.Combine({"мама","мыла","раму"},"-&-") // мама-&-мыла-&-раму
    
    Т.е. строка произвольной длины просто подставляется между элементами.

    Ещё одна типичная задача – собрать текстовые значения, но чтобы каждое было с новой строки:

        Text.Combine({"мама","мыла","раму"},"#(lf)")
    
    Здесь "#(lf)"- escape-последовательность для обозначения непечатаемого символа - перевода строки (кому нужна табуляция - "#(tab) " – правда Excel её не отобразит, но если вы потом копируете текст в другое место – табуляция там будет).

    Escape-последовательности можно комбинировать с обычными символами:
    
        Text.Combine({"мама","мыла","раму"},";#(lf)")

    Наконец, символ не обязательно должен быть непечатаемым:
        
        Text.Combine({"мама","мыла","раму"},"#(00A0)")
    
    Кто не узнал – это неразрывный пробел (A0 - это 160 в шестнадцатеричной системе). Т.е. пишем "#(шестнадцатеричный код Юникода) " – и подставляем любой код по вкусу. Ну а если у вас плохо с шестнадцатеричной системой, символы можно вызвать и по старинке:
        
        Text.Combine({"мама","мыла","раму"},Character.FromNumber(160))

    Character.FromNumber понимает обычное (десятичное) представление.
    Как-то так. Ничего сложного – главное всё преобразовать в текст и выяснить код нужного разделителя.
    ]

[   Table.AddIndexColumn – снова получаем значения из предыдущих или последующих строк / #АнатомияФункций – Table.AddIndexColumn, List.Buffer

    Всем привет! Сегодня в чате немножко без подготовки и с пол оборота случился челленж на тему получения значения из предыдущей строки. Мы уже решали такую задачу в ходе реализации UnFill. Сегодня же выяснилось, что во-первых, можно и через Table.Join (очень шустрый вариант от @MaximZelensky), ну а во-вторых… можно просто через Table.AddIndexColumn и список.

    Собственно код:
        
        let
            tbl = Table.FromColumns({{"a".."i"},{1..9}},{"a","b"}),
            lst = List.Buffer({null}&tbl[b]),
            add = Table.AddIndexColumn(tbl,"c",0,1),
            to  = Table.TransformColumns(add,{"c",(x)=>lst{x}})
        in
            to

    tbl – сама таблица,
    lst – список значений нужного столбца, с добавленным в начало нулевым значением (и не забываем про буфер)
    add – добавили столбец индекса
    to – трансформируем индекс в значение из списка – поскольку мы добавили в начало списка нулевое значение, по индексу мы получим значение из предыдущей строки, что и требовалось )))

    Сделаем другой вариант (он медленнее буквально на пару процентов, но интереснее):
        
        let
            tbl = Table.FromColumns({{"a".."i"},{1..9}},{"a","b"}),
            lst = List.Buffer(tbl[b]),
            add = Table.AddIndexColumn(tbl,"c",-1,1),
            to  = Table.TransformColumns(add,{"c",(x)=>if x<0 then null else lst{x}})
        in
            to

    Здесь мы просто получили список, а вот нумерацию начали с -1. Т. е. точно также сдвинули позицию на 1 назад, правда пришлось предотвратить ошибку отрицательного индекса: (x)=>if x<0 then null else lst{x}
    Зачем было усложнять? - да всё дело в том, что просто играя с третьим аргументом AddIndexColumn можно сдвигаться на любое число позиций вверх или вниз:
    
        let
            tbl = Table.FromColumns({{"a".."i"},{1..9}},{"a","b"}),
            lst = List.Buffer(tbl[b]),
            add = Table.AddIndexColumn(tbl,"c",1,1),
            to = Table.TransformColumns(add,{"c",(x)=>lst{x}?})
        in
            to

    Всё тоже самое, но сдвиг теперь вперед на 1 – так мы получаем следующую строку (ну и не забыли вопросик)

    А теперь объединяем всё в одну функцию:
        
        let
            tbl = Table.FromColumns({{"a".."i"},{1..9}},{"a","b"}),
           
            AddOtherRowColumn = 
                (tbl,col,newcol,index) =>
                    [   lst =   List.Buffer(Table.Column(tbl,col)),
                        add =   Table.AddIndexColumn(tbl,newcol,index,1),
                        f   =   if index <0 
                                then (x)=> if x<0 then null else lst{x}
                                else (x)=>lst{x}?,
                        to = Table.TransformColumns(add,{newcol,f})
                    ][to],

            to  = AddOtherRowColumn(tbl,"b","c",-1),
            to1 = AddOtherRowColumn(tbl,"b","c",-3),
            to2 = AddOtherRowColumn(tbl,"b","c",2)
        in
            to2

    По аргументам всё думаю понятно – таблица, столбец, имя нового столбца и на сколько строк сдвинуть.
    Просто, лаконично и главное шустро! Юзайте на здоровье.
    ]

[   List.Accumulate + Record.Field против Join-ов или словарь на записях / #АнатомияФункций - Record.Field, List.Accumulate

    Всем привет!
    Периодически в чате всплывает приём, по которому задают вопрос «что за магия»?
    На самом деле приём широко известен в узких кругах, бывает эффективен, поэтому разберем.
    Итак задача: есть таблица ФИО/должность, есть таблица Должность/оклад/премия, на выходе хотим таблицу ФИО/должность/оклад/премия. Понятное дело, что это решается через Join:
    
    let
        a = #table({"ФИО","Профессия"},{{"Вася","Игрок"},{"Петя","Игрок"},{"Коля","Тренер"},{"Евлампий","Врач"}}),
        b = #table({"Должность","Оклад","Премия"},{{"Игрок",1000,100},{"Тренер",2000,5000},{"Врач",100,1}}),
        c = Table.Join(a,"Профессия",b,"Должность"),
        d = Table.RemoveColumns(c,"Должность")
    in
        d
    
    Но сразу можно сказать – жульничество – там Должность, там – Профессия, где заморочки с переименованием? Где удаление лишних столбцов, которые всегда есть? И т.д. Ну ОК, тогда NestedJoin:
    
    let
        a = #table({"ФИО","Профессия"},{{"Вася","Игрок"},{"Петя","Игрок"},{"Коля","Тренер"},{"Евлампий","Врач"}}),
        b = #table({"Должность","Оклад","Премия"},{{"Игрок",1000,100},{"Тренер",2000,5000},{"Врач",100,1}}),
        c = Table.NestedJoin(a,"Профессия",b,"Должность","tmp"),
        d = Table.ExpandTableColumn(c, "tmp", {"Оклад","Премия"})
    in
        d
    
    Здесь, думаю ситуация и решение многим знакомы.

    Тогда о чём пост? Да просто хочу предложить альтернативу:
    
    let
        a = #table({"ФИО","Профессия"},{{"Вася","Игрок"},{"Петя","Игрок"},{"Коля","Тренер"},{"Евлампий","Врач"}}),
        b = #table({"Должность","Оклад","Премия"},{{"Игрок",1000,100},{"Тренер",2000,5000},{"Врач",100,1}}),
        с = List.Accumulate(Table.ToRows(b),[],(s,c)=>Record.AddField(s,c{0},List.Skip(c))),
        d = (x)=> x & Record.Field(с,x{1}),
        e = Table.FromList(Table.ToRows(a), d, {"ФИО","Профессия","Оклад","Премия"} )
    in
        e
        
    Что поменялось?
    Возник странный шаг c – с аккумулятором и пустой записью. Здесь мы таблицу соответствий разбили на строки (Table.ToRows) и аккумулируем полученные значения – первый столбец превращаем в название поля записи, остальной список – в значение данного поля. Т.е. на выходе получили запись, где поля содержат нужные значения (словарь). Зачем оно надо? Да просто при обращении к записи будет сразу выниматься значение нужного нам поля, без поиска.
   
    Далее функция d – её аргументом будет список - мы увидим это на следующем шаге – она берет сам список и добавляет к нему значение нужного поля из словаря. Т.е. к списку значений по строке добавили список значений из таблицы подстановок
    
    Ну и на шаге e – мы эту функцию подсовываем в мой любимый FromList.
    
    Как бы всё. Наверняка немножко непривычно, но так может оказаться быстрее, особенно на больших таблицах. Пробуйте )))
    ]

[   List.PositionOf – или ПОИСКПОЗ на стероидах / #АнатомияФункций - List.PositionOf

    Всем привет!
    При решении задач периодически возникает необходимость найти позицию определённого значения в списке, для этого разумно использовать List.PositionOf. И на этом можно бы было завершить пост, если бы не одно обстоятельство – это функция четырёх аргументов, а значит нас ждёт много вкусного ))) Поехали:
    
        List.PositionOf(
            list as list, 
            value as any, 
            optional occurrence as nullable number, 
            optional equationCriteria as any
        ) as any

    Обязательные аргументы:
    list – сам список
    value – искомое значение

    Необязательные аргументы:
    occurrence – «вхождение» - принимает варианты Occurrence.First, Occurrence.Last, Occurrence.All – т.е. первое, последнее или все
    equationCriteria – критерий сравнения – сюда можно написать Comparer или собственную функцию от двух аргументов (current,value)=> - обратите внимание на порядок – сначала current – проверяемый элемент списка, затем value – наше искомое значение

    Ну и пример, ниже разберем по шагам:

        let
            a = List.PositionOf({1..10},5),         //4
            b = List.PositionOf({"a".."z"},"d"),    //3 
            c = List.PositionOf({1..10},11),        //-1 - значение не найдено
            d = List.PositionOf({1,2,null,3,4,null,5},null), //2
            e = List.PositionOf({1,2,null,3,4,null,5},null,Occurrence.First),   //2
            f = List.PositionOf({1,2,null,3,4,null,5},null,Occurrence.Last),    //5
            g = List.PositionOf({1,2,null,3,4,null,5},null,Occurrence.All),     //{2,5}
            h = List.PositionOf({1,2,null,3,4,null,5},null,Occurrence.First,(c,v)=>c<>v),   //0
            i = List.PositionOf({1,2,null,3,4,null,5},null,Occurrence.Last,(c,v)=>c<>v),    //6
            j = List.PositionOf({1,2,null,3,4,null,5},null,Occurrence.All,(c,v)=>c<>v),     //{0,1,3,4,6}
            k = List.PositionOf({1..5},3,Occurrence.All,(c,v)=>c<v), //{0,1}
            l = List.PositionOf({1..5},3,Occurrence.All,(c,v)=>c>v), //{3,4}
            m = List.PositionOf({1,2,null,3,4,null,5},3,Occurrence.All,(c,v)=>if c is null then false else c>v),//{4,6}
            n = List.PositionOf({"a".."z"},"D",Occurrence.All,Comparer.OrdinalIgnoreCase) //3
        in
            n

    Шаги a -d – простое использование с двумя обязательными аргументами
    a – ищем и находим число в списке, обращаем внимание, что нумерация элементов идёт с нуля
    b – то же самое, но для текста
    c – запоминаем, что в случае, если элемент не найден, вернётся не ошибка, а значение -1
    d – искать можно и null

    Шаги e – g – добавляем Occurrence
    e – сравните с шагом d – понимаем, что по умолчанию используется Occurrence.First – т.е. ищется первое вхождение
    f – Occurrence.Last даст нам последнее вхождение
    g – Occurrence.All вернёт список всех вхождений значения

    Шаги h – n – подключаем тяжёлую артиллерию – четвертый аргумент)))
    Что делать, если мы не знаем конкретное значение, а просто ищем первый/последний непустой элемент? Смотрим шаги h – j – в списке ищем null, но с функцией (c,v)=>c<>v – т.е. не равно null
    k,l - аналогично можно искать значения меньшие или большие заданного
    m – функция может быть сложной – в данном случае в списке есть null и их невозможно сравнить с числом, поэтому для любого null возвращаем false, а остальные значения сравниваем с искомым
    n – ну и вариант с текстами – в четвертом аргументе, например, можно прописать условие игнорирования регистра

    Как-то так – очередная функция, вся мощь которой проявляется в необязательных аргументах. Экспериментируйте!
    ]

[   List.PositionOfAny или когда искомое - список вариантов / #АнатомияФункций - List.PositionOfAny

    Всем привет!
    Только что разобрали List.PositionOf и изложение было бы неполным, если не рассмотреть ещё и List.PositionOfAny.
    Смотрим справку:

        List.PositionOfAny(
            list as list, 
            values as list, 
            optional occurrence as nullable number, 
            optional equationCriteria as any
        ) as any

    Собственно, всё то же самое, только теперь второй аргумент – список. Т.е. при поиске позиции проверяется не просто искомое value, а список values – и совпадение хотя бы с одним из элементов второго аргумента даст положительный результат.

    Смотрим пример и разбираем по шагам:

        let
            a = List.PositionOfAny({1..10},{1,3,5}),//0
            b = List.PositionOfAny({1..10},{1,3,5},Occurrence.All),//{0,2,4}
            c = List.PositionOfAny({1..10},{11,13,15}),//-1
            d = List.PositionOfAny({1..10},{11,13,15},Occurrence.All),//{}
            e = List.PositionOfAny({"мама","мыла","раму"},{"ма","ра"},Occurrence.All,Text.Contains),//{0,2}
            f = List.PositionOfAny({"мама","мыла","раму"},{"МА","РА"},Occurrence.All,(c,v)=>Text.Contains(c,v,Comparer.OrdinalIgnoreCase)),//{0,2}
            g = List.PositionOfAny({"ыл","ил"},{"мама мыла раму","папа пил пиво"},Occurrence.All,Text.Contains),//{}
            h = List.PositionOfAny({"ыл","ил"},{"мама мыла раму","папа пил пиво"},Occurrence.All,(c,v)=>Text.Contains(v,c))//{0,1}
        in
            h

    a – функция вернула 0 – поскольку первый элемент содержится в списке искомого, а мы помним про нумерацию с нуля и что по умолчанию применяется Occurrence.First
    b – всё то же самое, но с Occurrence.All вернёт нам список позиций
    c,d – а вот об этом не сказал в прошлом посте – если значение не найдено, возвращается -1, НО в случае с Occurrence.All – возвращается {} – пустой список – учитывайте это при написании кода

    Ну и часто подобный поиск связан с элементами текстовых строк
    e – как видите в качестве equationCriteria можно просто использовать Text.Contains – эта запись эквивалентна (c,v)=>Text.Contains(c,v) – т.е. проверяем элементы первого списка на наличие текста из второго списка
    f – в предыдущем варианте мы не писали полный синтаксис, но здесь он необходим, поскольку нам понадобилось добавить игнорирование регистра
    g – а вот такая ошибка встречалась в чате – как мы видим в этой ситуации ни один из элементов первого списка не содержит элементов второго – ну просто потому, что они длиннее; и поиск нужен наоборот – наличие элементов первого списка в тексте элементов второго, что же делать?
    h – да просто передать аргументы в Text.Contains в обратном порядке. Вуаля, задача решена!

    Вот теперь точно всё – все варианты всё равно перебрать невозможно, но логику постарался донести.
    ]

[   Record.FieldOrDefault, Record.FromTable – немножко оптимизации в словари на записях / #АнатомияФункций - Record.FieldOrDefault, Record.FromTable

    Всем привет!
    В прошлый раз мы посмотрели, как можно реализовать подстановку данных из другой таблицы через записи.
    Возникает закономерный вопрос – а что делать, если в словаре есть не все соответствия?
    Мы знаем про вот такой синтаксис
    
        [a=1,b=2,c=3][d]? // null
    
    И даже такой:
    
        [a=1,b=2,c=3][d]? ?? "не найдено"// не найдено
    
    Но они применимы при обращении к элементам записи или списка, а вот функция Record.Field выдаст ошибку и вопросик не спасет.

    Зато спасёт другая, не менее полезная функция - Record.FieldOrDefault.
    
        Record.FieldOrDefault([a=1,b=2,c=3], "d") //null
        Record.FieldOrDefault([a=1,b=2,c=3], "d","не найдено") // не найдено
    
    Т.е. без третьего аргумента имеем эквивалент [ ]?, с третьим аргументом – эквивалент [ ]? ??
    Ну и применяем это к коду из прошлого поста:
        
        let
            a = #table({"ФИО","Профессия"},{{"Вася","Игрок"},{"Петя","Игрок"},{"Коля","Тренер"},{"Евлампий","Врач"}}),
            b = #table({"Должность","Оклад","Премия"},{{"Игрок",1000,100},{"Тренер",2000,5000}}),
            с = Record.FromTable(Table.FromList(Table.ToRows(b),(x)=>{x{0},List.Skip(x)},{"Name","Value"})),
            d = (x)=>x & Record.FieldOrDefault(с,x{1},{}),
            e = Table.FromList(Table.ToRows(a),d,{"ФИО","Профессия","Оклад","Премия"})
        in
            e

    Смотрим на шаг d – в качестве альтернативного значения указан не null, а пустой список {} – это важно, иначе будет ошибка несовпадения типов при конкатенации (ну а если нужно возвращать не null, а значение по умолчанию – также пишем список, но уже со значениями: {"не найдено","не положено"})

    Таже обращаю внимание на шаг с. В прошлый раз мы использовали Accumulate, но если таблица соответствий большая, он может замедлять работу (на тестовом словаре в 50k строк сегодня просто умер). В этой ситуации есть более элегантный способ собрать большую запись - Record.FromTable. Но есть нюанс - на вход нельзя просто подать исходную таблицу, таблица обязательно должна состоять из двух столбцов - "Name" и "Value". Ну и в примере показано как это можно сделать через Table.ToRows+Table.FromList.

    Собственно, всё - с отсутствующими совпадениями разобрались, большие таблицы в записи превратили, дело за малым – попробовать на практике. Успехов!
    ]

[   TableRenameColumnsByPositions или как переименовать столбцы по номеру / #АнатомияФункций – custom functions

    Всем привет! Сегодня очередной раз был поднят вопрос о переименовании столбцов в таблице по номеру (позиции). По этому поводу функция:

    [func =(table,list) =>
        [   a = List.Buffer(Table.ColumnNames(table)),
            b = List.Count(a),
            c = (x) =>{a{if x{0}>0 then x{0}-1 else b+x{0}},x{1}},
            d = if list{0} is list then List.Transform(list,c) else c(list),
            e = Table.RenameColumns(table,d)
        ][e],
    typ = type function (
                    table as (type table meta [Documentation.FieldCaption = "исходная таблица"]),
                    list as (type list meta [Documentation.FieldCaption = "параметры переименования"])
                            )           
                    as table meta [ 
                                    Documentation.Name = "TableRenameColumnsByPositions> (@buchlotnik)",
                                    Documentation.LongDescription = "Функция переименовывает столбцы таблицы  по их номеру. Параметры переименования задаются в виде списка {номер, новое название} либо списка списков {{номер1, новое название1},{номер2, новое название2}}. Положительное значение номера задает нумерацию с начала таблицы, отрицательное - с конца.",
                                    Documentation.Examples = {
                                        [Description = "переименовать первый столбец", Code = "=TableRenameColumnsByPositions(#table({""a"",""b"",""c""},{}),{1,""первый""})",Result="#table({""первый"",""b"",""c""},{})"], 
                                        [Description = "перименовать первый с конца столбец", Code =  "=TableRenameColumnsByPositions(#table({""a"",""b"",""c""},{}),{-1,""первый с конца""})",Result="#table({""a"",""b"",""первый с конца""},{})"], 
                                        [Description = "переименовать первый и последний столбцы", Code = "=TableRenameColumnsByPositions(#table({""a"",""b"",""c""},{}),{{1,""первый""},{-1,""последний""}})",Result="#table({""первый"",""b"",""последний""},{})"]
                                        }        
                                    ],
        result = Value.ReplaceType(func,typ)
    ][result]

    Глобально по шагам:
    func   – сама функция
    typ    – описание её типа – что-то подобное мы уже смотрели в постах про типизацию и документацию
    result – возвращаем функцию со всеми метаданными, чтоб при вызове глаз радовался)))

    Ну а теперь по функции.
    Общая идея состоит в том, что обращаться к столбцам (полям) можно только по имени, но у нас есть возможность получить список имен столбцов, а вот со списком можно прекрасно работать по номерам элементов. Поехали:
    a – получили список имен столбцов
    b – нашли их количество, нам это нужно, если нумерация идёт с конца
    c – функция преобразования, которая превращает номер в имя столбца и возвращает пару {изменяемое_имя,новое_имя}. Логика такая: если номер положительный – берем просто нужный элемент списка (там -1 поскольку нумерация с нуля), а если отрицательный – берем с конца, т.е. складываем общее число столбцов с тем, на сколько столбцов от конца нужно отступить
    d – поскольку преобразование одного столбца – это просто список, а нескольких – список списков, то проверяем, чем у нас является первый элемент переданного аргумента – если он список, то преобразованию нужно подвергать список списков с использованием List.Transform, в противном случае однократно применяем функцию преобразования c к аргументу list
    e – подсовываем список преобразования штатной Table.RenameColumns

    Собственно, всё. Немножко пришлось пошаманить для универсальности, но в целом, надеюсь, сложностей с пониманием возникнуть не должно. Юзайте на здоровье!
    ]

[   Table.SelectColumns, Table.RemoveColumns, Table.ReorderColumns – или жонглируем столбцами таблицы / #АнатомияФункций - Table.SelectColumns, Table.RemoveColumns, Table.ReorderColumns

    Всем привет!
    В М существует ряд функций для работы со столбцами, но писать по каждой отдельный пост как-то скучно, а вот если объединить – может будет информативно.
    Итак SelectColumns, RemoveColumns, ReorderColumns – имеют два обязательных и один необязательный аргумент:
    table – таблица, которую преобразуем
    columns/columnsOrder – имя столбца или список имен столбцов (выбирать или удалять можно и один столбец, а вот менять порядок – только у списка)
    missingfield – необязательный аргумент, говорящий что делать с отсутствующими столбцами – как водится имеет два варианта - MissingField.UseNull или MissingField.Ignore

    Смотрим код и ниже разбираем шаги:
        
        let 
            from = #table({"a".."h"},{{1..8}}),
            
            lst1 = Table.ColumnNames(from),
            select1 = Table.SelectColumns(from,lst1),
            remove11 = Table.RemoveColumns(from,lst1), 
            reorder1 = Table.ReorderColumns(from,lst1),

            lst2 = {List.Last(lst1),List.First(lst1)},
            select2 = Table.SelectColumns(from,lst2),
            remove2 = Table.RemoveColumns(from,lst2), 
            reorder2 = Table.ReorderColumns(from,lst2),

            lst3 = List.Reverse(List.Alternate(lst1,1,1,1)),
            select3 = Table.SelectColumns(from,lst3),
            remove3 = Table.RemoveColumns(from,lst3), 
            reorder3 = Table.ReorderColumns(from,lst3),

            lst4 = {"k","j","i"}&List.Skip(lst1),
            select41 = Table.SelectColumns(from,lst4,MissingField.Ignore),
            remove41 = Table.RemoveColumns(from,lst4,MissingField.Ignore), 
            reorder41 = Table.ReorderColumns(from,lst4,MissingField.Ignore),

            select42 = Table.SelectColumns(from,lst4,MissingField.UseNull),
            remove42 = Table.RemoveColumns(from,lst4,MissingField.UseNull), 
            reorder42 = Table.ReorderColumns(from,lst4,MissingField.UseNull)
        in 
            reorder42

    lst1 – список имён столбцов таблицы
    select1 и reorder1 – ничего не поменялось – одна функция выбрала столбцы, другая расположила столбцы в том порядке, в котором они и шли, а remove1 – вернула пустую таблицу – поскольку все столбцы пришлось удалить. Всё логично, но как-то не показательно. Другое дело, что со списком столбцов можно поиграть, и вот тут начинается интересное

    lst2 – взяли только последнее и первое имена из списка
    select2 – получили только последний и первый столбцы
    remove2 – таблица без первого и последнего столбцов
    reorder2 – таблица, в которой первый и последний столбцы поменяны местами. Обращаю внимание – Select просто берет те столбцы, которые указали, в том порядке, в котором указали, а вот Reorder – столбцы из второго аргумента берет в нужном порядке, но остальные оставляет на местах

    lst3 – более сложный пример – List.Alternate даст нам все столбцы на нечётных позициях, а Reverse – расположит их в обратном порядке (иначе не будет понятно зачем нам reorder)
    select3 – все нечётные столбцы в обратном порядке
    remove3 – все четные столбцы (нечетные были удалены)
    reorder3 – чётные столбцы на местах, нечётные – в обратном порядке

    lst4 – ну и типичный вариант при сборе из кучи файлов – надо собрать/удалить столбцы, а не во всех файлах они присутствуют – чтобы не было ошибки прописываем MissingField
    remove41, remove42 – вернулась таблица со столбцом а – остальные удалены, лишние были проигнорированы
    select41 – таблица без первого столбца, лишние проигнорированы
    reorder41 – исходная таблица (лишние проигнорированы, первый столбец был пропущен в списке и поэтому остался на месте)
    select42 – таблица со всеми столбцами из второго аргумента, отсутствующие столбцы заполнены null
    reorder42 – а вот это самое интересное – столбец a остался на месте, а далее все столбцы из второго аргумента

    Думаю понятно, что это просто небольшая демонстрация. Ключевым является правильно построить второй аргумент и понимать, как его анализирует функция. Логика у них похожая но не идентичная, экспериментируйте!
    ]

[   Table.ToList - множественные замены, словари на записях или как всё-таки быстрее? / #АнатомияФункций - Table.ToList

    Всем привет!
    В чате всплыла задачка на множественную замену значений из текста.
    Формулировка – есть текст с перечислением определённых значений через запятую, необходимо добавить ещё один столбец, с таким же перечислением, но с заменой значений на другие из таблицы соответствий. ОК.
    
    Логика решения (в моей интерпретации) – разделить текст по разделителю, в полученном списке произвести замены, собрать список обратно в текст с разделителем. Первоначально решил через List.ReplaceMatchingItems (хорошая функция, мы ее ещё разберём), но словарь на записях оказался быстрее. На этом можно было бы и завершить, НО…
    
    В названии заявлена Table.ToList – функция, которая возвращает список из строк таблицы, применив к списку значений каждой строки функцию преобразования. А мы уже выяснили, что Table.FromList работает быстрее, чем Table.FromRows. 
    Вот и возникло предположение, что и Table.ToList может оказаться быстрее Table.ToRows.
   
    Поэтому разбираем пример:
    
        let
            tbl1 =  #table({"ID","txt"},{{"1","A,B"},{"2","B,C,D"},{"3","C,D,E,F"}}),
            tbl2 =  #table({"cat","txt"},{{"A","aa"},{"B","bb"},{"C","cc"},{"D","dd"},{"E","ee"},{"F","ff"}}),
            dict =  Record.FromTable(
                        Table.RenameColumns(tbl2,{{"cat","Name"},{"txt","Value"}})
                    ),
            
            f=(x as list)=>x&{g(x{1})},
            g=(x)=> Text.Combine(
                        List.Transform(
                            Text.Split(x,","),
                            (y)=>Record.Field(dict,y)
                        ),
                        ","
                    ),
            
            to  = Table.FromList(Table.ToRows(tbl1),f,{"ID","txt","new"}),
            to1 = Table.FromRows(Table.ToList(tbl1,f),{"ID","txt","new"}),
            to2 = Table.FromList(Table.ToList(tbl1,(x)=>x),f,{"ID","txt","new"}),
            to3 = Table.FromList(Table.ToList(tbl1,f),(x)=>x,{"ID","txt","new"})
        in
            to3

    tbl1, tbl2 – исходная таблица и таблица подстановки
    dict – делаем словарь в виде записи (обращаем внимание на переименование столбцов, иначе Record.FromTable не будет работать)
    f    – функция, принимающая на вход список (значения всех столбцов строки) и добавляющая к нему дополнительный элемент – результат преобразования второго значения функцией g
    g    – логика этой функции уже описана выше – разделили текст по запятой, сделали замену по списку, собрали обратно через запятую

    А теперь начинаем собирать результирующую таблицу (скорости выполнения указаны для тестовой выборки в 100k строк):
    to  – делим таблицу через ToRows, собираем через FromList с функцией f – это мой первоначальный вариант, отработал в среднем за 1,185 секунды
    to1 – делим через ToList с функцией f, а собираем через FromRows – отработало за 1,563 секунды – чуда не случилось, FromRows – медленная
    to2 – делим через ToList с функцией (x)=>x (обсуждалась тут), а собираем через FromList с функцией f – 1,184 секунды – чуууть быстрее первоначального варианта
    to3 – "финт ушами" – разбираем через ToList с функцией f, а собираем через FromList с (x)=>x – и получаем… 1,169 секунды - прирост скорости не космический, но приятный.
    
    Проверил в нескольких вариантах на выборках разного объёма с аналогичным результатом. 
    Вывод – разбирать и собирать таблицы эффективнее через Table.ToList и Table.FromList, функцию преобразования при этом эффективнее подсовывать при разборке. Как-то так.
    ]

[   List.ReplaceMatchingItems vs Record.Field или какой транслит работает быстрее? / #АнатомияФункций - List.ReplaceMatchingItems, Record.Field

    Всем привет!
    Пока обсуждали сборку-разборку таблиц выяснили, что при малом числе вариантов замены (до 7 -8) List.ReplaceMatchingItems оказывается быстрее, чем Record.Field. Другое дело, что есть определенные ухищрения – например, использование Text.Upper/Text.Lower или Comparer.OrdinalIgnoreCase – чтобы не писать все варианты, а оставить только прописные или только строчные буквы.

    В примере решаем задачу транслитерации из русского в английский, причём результат должен быть выведен прописными буквами (все 33 буквы в пример не писал – оставил первые три, но принцип, надеюсь будет понятен):
    
        let
            from = #table({"txt"},{{"абв"},{"аБв"},{"АБВ"}}),
            fulllist = {{"А","A"},{"а","A"},{"Б","B"},{"б","B"},{"В","V"},{"в","V"}},
            partlist = {{"А","A"},{"Б","B"},{"В","V"}},
            fullrec  = [А="A",а="A",Б="B",б="B",В="V",в="V"],
            partrec  = [А="A",Б="B",В="V"],
            to1 = Table.TransformColumns(from,{"txt",(x)=>Text.Combine(List.ReplaceMatchingItems(Text.ToList(x),fulllist))}),
            to2 = Table.TransformColumns(from,{"txt",(x)=>Text.Combine(List.ReplaceMatchingItems(Text.ToList(x),partlist,Comparer.OrdinalIgnoreCase))}),
            to3 = Table.TransformColumns(from,{"txt",(x)=>Text.Combine(List.ReplaceMatchingItems(Text.ToList(Text.Upper(x)),partlist))}),
            to4 = Table.TransformColumns(from,{"txt",(x)=>Text.Combine(List.Transform(Text.ToList(x),(y)=>Record.Field(fullrec,y)))}),
            to5 = Table.TransformColumns(from,{"txt",(x)=>Text.Combine(List.Transform(Text.ToList(x),(y)=>Record.Field(partrec,Text.Upper(y))))}),
            to6 = Table.TransformColumns(from,{"txt",(x)=>Text.Combine(List.Transform(Text.ToList(Text.Upper(x)),(y)=>Record.Field(partrec,y)))})
        in
            to6

    Итак, по шагам
    from – исходная таблица, в которой транслитерируем столбец txt
    fulllist – список списков полная версия, т.е. описаны замены для букв как в нижнем, так и в верхнем регистре
    partlist – то же самое, но оставлены только буквы в верхнем регистре
    fullrec – словарь-запись, с полным перечнем возможных вариантов
    partrec – сокращённый словарь-запись только для верхнего регистра
    to1 – решение «в лоб» - разобрали текст на символы, сделали замену по списку, собрали обратно в текст
    to2 – используем сокращённый список, поэтому добавили третий аргумент - Comparer.OrdinalIgnoreCase
    to3 – а здесь текст на входе сразу перевели в верхний регистр
    to4 – решение «в лоб» с полным словарём, но на записях
    to5 – используем сокращённый словарь, при запросе поля записи переводим символ в верхний регистр
    to6 – также сокращённый словарь, но текст уже на входе перевели в верхний регистр

    Тестирование проводилось на таблице в 160k строк, разумеется с полными списками (fulllist и fullrec – по 66 элементов, partlist и partrec – по 33).

    Результаты буду выражать в процентах от времени лидера:
    to1 и to2 – 155%,т.е. сокращение словаря вдвое, но с Comparer.OrdinalIgnoreCase, выигрыша по времени не дало, и в целом с длинным списком List.ReplaceMatchingItems медленная функция
    to5 – 131% - словарь на записях, но введение текстового преобразования при каждом вызове функции реально замедляет работу
    to3 – 123% - список мы сократили вдвое, тестовое преобразование применили сразу ко всему тексту - как следствие получили достаточно быстрый результат (Пух, это ответ на твой вопрос)
    to6 – 105% - текст перевели в верхний регистр за один заход, запись сократили вдвое – но этого оказалось не достаточно для победы, немножко, но не достаточно
    to4 - 100% - как вы уже догадались – решение «в лоб» на записях оказалось самым шустрым.

    Конечно, ещё можно экспериментировать, но ряд выводов напрашивается сам собой:
    - транслитерацию делать на записях. (точка)
    - если регистр важен – стараемся использовать Text.Upper/Text.Lower и применять ко всему тексту сразу
    - словари на списках, превышающие 10 элементов, также не используем – тут записи вне конкуренции
    ]

[   & = Combine или почему конкатенация иногда слияние… / #АнатомияФункций - .Combine

    Всем привет!
    Разберем, как мне казалось, простую тему, а именно – использование & (combination operator) – да-да, я не ошибся - знак амперсанд обозначает именно комбинирование и в зависимости от ситуации оно происходит по-разному.
    Начнём с текста:
    Аперсанд объединяет два строковых значения в одно и все знают, что это называется конкатенация (сцепка, склеивание)
    
        "a" & "b"//"ab"
    
    Операндов можно использовать несколько с тем же результатом
    
        "a" & "b" & "c"//"abc"
    
    Большое количество строковых значений лучше объединять с помощью функции
        
        Text.Combine({"a".."f"})//"abcdef"

    Обращаем внимание, что функция называется Combine и всегда первым аргументом хочет от нас список комбинируемых значений – не забываем про фигурные скобки.
    Кроме того, есть второй аргумент
    
        Text.Combine({"a".."c"},",")//"a,b,c"
    
    который весьма кстати, если мы хотим получить на выходе перечисление

    Со списками всё то же самое – происходит последовательное объединение, т.е. конкатенация
        
        {1,2} & {3,4}//{1,2,3,4}

    Списки могут быть любой длины и, например, вот так выглядит добавление элемента к списку
    
        {"a","b","c"} & {"d"}//{"a","b","c","d"}
    
    т.е. добавляя что-то к списку мы конкатенируем два списка, просто второй содержит один единственный элемент.
    Аналогично со списками списков:

        {{1,2},{3,4}} & {{5,6}} //{{1,2},{3,4},{5,6}}
    
    эта ситуация возникает, когда вы добавляете столбец к таблице или генерируете строки таблицы – к списку списков надо добавлять список – фактически это конкатенация двух списков списков )))

    Как и с текстом есть соответствующая функция (обращаем внимание, что комбинируемые списки помещены в список):
    
        List.Combine({{1,2},{3,4}})//{1,2,3,4}

    Всё, что было выше – это конкатенация, тогда почему оператор называется по-другому? Да просто ещё есть записи и таблицы – и вот с ними он осуществляет другую операцию – слияние (merge).
    Разберем записи. На таком примере разница не чувствуется:
        
        [a=1,b=2] & [c=3]//[a=1,b=2,c=3]

    Из двух записей сформировалась одна, в чём тогда подвох?
    Да вот он:
    
        [a=1,b=2] & [b=3,c=4]//[a=1,b=3,c=4]

    поля в записи должны иметь уникальные имена и при слиянии двух записей с совпадающими именами полей остаётся одно значение, причём из записи справа.

    Надеюсь теперь понятно, почему Record.Combine выдаёт такой результат:
    
        Record.Combine({[a=1,b=2],[b=3,c=4],[c=5,d=6]})//[a=1,b=3,c=5,d=6]

    Ну и, наконец, таблицы. Тут вообще весело – при слиянии таблиц строки второй оказываются под строками первой, причём совпадающие имена столбцов друг под другом, а несовпадающие оказываются правее. Ещё точнее – сначала идут имена столбцов из левой таблицы, а потом не совпавшие из правой.
    Таблицы друг под другом (имена столбцов совпадают):
    
        #table({"a","b"},{{1,2},{3,4}})&#table({"a","b"},{{5,6},{7,8}})

    Таблицы друг под другом, но со сдвигом (имена столбцов не совпадают)
    
        #table({"a","b"},{{1,2},{3,4}})&#table({"c","d"},{{5,6},{7,8}})

    Таблицы с частично совпадающими именами столбцов
    
        #table({"a","b"},{{1,2},{3,4}})&#table({"c","b"},{{5,6},{7,8}})
    
    Обратите внимание, что у правой таблицы порядок столбцов поменялся.

    Ну и как водится, амперсанд благополучно заменяется функцией
        
        Table.Combine({#table({"a","b"},{{1,2},{3,4}}),#table({"c","b"},{{5,6},{7,8}})})
    
    Как вы догадались – с тем же результатом.

    Как-то так. Оператор & не просто так называется оператором комбинирования – в зависимости от типа комбинируемых данных результат определяется разными правилами. Это необходимо понять, принять и простить )))
    ]

[   Text.Split vs Splitter.SplitTextByDelimiter или когда синтаксис имеет значение / #АнатомияФункций - Text.Split, Splitter.SplitTextByDelimiter

    Всем привет!
    В разрезе недавних постов про сборку таблиц нужно разобрать вопрос о разделении текста по разделителю. Для решения этой задачи мы имеем функцию Text.Split и семейство функций Splitter. Выглядит это примерно так:
    
    Text.Split("a,b,c",",")//{"a","b","c"}
    Splitter.SplitTextByDelimiter(",")("a,b,c")//{"a","b","c"}

    Т.е функции Text.Split мы передаем сначала разделяемый текст, потом разделитель; а у Splitter единственный аргумент – это сам разделитель, а разделяемый текст мы передаём отдельно во вторых скобках – подобное мы встречали, когда обсуждали замыкания.

    На выходе получаем идентичный результат, но синтаксис у Text.Split чутка лаконичнее и прозрачнее. Только мы помним, что длина кода на скорость не влияет, тогда о чём пост? Дело в том, что задача разделения текста возникает в разных ситуациях и какую функцию выбрать – вопрос скорее вкуса, нежели каких-то объективных критериев. Но при этом существует две функции, у которых аргумент чётко заявлен как splitter as function – это Table.FromList и Table.SplitColumn. И вот в их случае выбор функции имеет принципиальное значение.

    Рассмотрим обе ситуации:

    Table.SplitColumn
    
        let
            from = #table({"txt"},{{"1,2,3"},{"4,5,6"},{"7,8,9"}}),
            to1 = Table.SplitColumn(from,"txt",(x)=>Text.Split(x,",")),
            to2 = Table.SplitColumn(from,"txt",(x)=>Splitter.SplitTextByDelimiter(",")(x)),
            to3 = Table.SplitColumn(from,"txt",Splitter.SplitTextByDelimiter(","))
        in
            to3
    
    Table.FromList
        
        let
            from = {"1,2,3","4,5,6","7,8,9"},
            to1 = Table.FromList(from,(x)=>Text.Split(x,",")),
            to2 = Table.FromList(from,(x)=>Splitter.SplitTextByDelimiter(",")(x)),
            to3 = Table.FromList(from,Splitter.SplitTextByDelimiter(","))
        in
            to3

    from – источник – таблица или список
    to1 – использована пользовательская функция на основе Text.Split
    to2 – использована пользовательская функция на основе Splitter.SplitTextByDelimiter
    to3 – напрямую использован Splitter.SplitTextByDelimiter (обращаю внимание - именно этот вариант получается мышкоклацем, так что он иногда выдает очень правильные варианты)

    Результаты, казалось бы, идентичны. НО! Вариант to1 оказывается чуть быстрее, чем to2, а вот to3 – в 1,5-2 раза быстрее двух предыдущих! Не знаю как именно построена логика у этих функций, но вердикт простой – если от нас хотят “splitter as function” и нам действительно нужен сплиттер – даже не думаем и передаем именно его, причем напрямую, а не как пользовательскую функцию – это реально быстрее.
    ]

[   List.Alternate, Table.AlternateRows – забавные «чередователи» элементов / #АнатомияФункций - List.Alternate, Table.AlternateRows

    Всем привет!
    Периодически всплывают задачи, в которых необходимо сделать выборку элементов из списка или строк таблицы – каждый второй элемент, каждая третья строка. Для решения этой задачи используются List.Alternate и Table.AlternateRows.

    Начнем с List.Alternate. У функции четыре аргумента – два обязательных и два необязательных:
    
        list – сам список
        count – число пропускаемых (удаляемых) элементов
        repeatInterval (необязательный) – число элементов, которые остаются между пропускаемыми
        offset (необязательный) – число элементов в начале списка, после которых начинаем пропускать.

    Выглядит немножко запутанно, поэтому поехали смотреть пример:
    
        let
            lst = {1..10},
            a   = List.Alternate(lst,1),//{2,3,4,5,6,7,8,9,10}
            b   = List.Alternate(lst,1,2),//{2,3,5,6,8,9}
            c   = List.Alternate(lst,1,2,3),//{1,2,3,5,6,8,9}
            d   = List.Alternate(lst,3,2,1),//{1,5,6,10}
            ListDelEachN    = (l,n)=>List.Alternate(l,1,n-1,n-1),
            ListSelectEachN = (l,n)=>List.Alternate(l,n-1,1,0),
            e = ListDelEachN(lst,3),//{1,2,4,5,7,8,10}
            f = ListSelectEachN(lst,3)//{3,6,9}
        in
            f

    и разбирать по шагам
    a – передали только обязательные аргументы, Alternate честно пропустил один элемент и вернул остальные – т.е. в таком виде это аналог List.Skip(lst,2) или List.Range(lst,2)
    b – здесь мы передали дополнительно repeatInterval – т.е указали через сколько эементов надо снова повторить операцию удаления. Логика работы – «один пропустил, два оставил, один пропустил… и т.д.»
    с – а это полный синтаксис – указали сколько эементов в начале списка оставить, сколько удалить и через сколько элементов повторить операцию удаления. Т.е. логика работы: «три в начале оставил, один пропустил, два оставил, один пропустил… и т.д.».
    Тут просто важно не запутаться и передать аргументы в правильном порядке. Например, шаг d – «один в начале оставил, три пропустил, два оставил, три пропустил и т.д.».

    В качестве упражнения напишем две функции – для удаления каждого n-ого элемента и для выбора каждого n-ого элемента.

    ListDelEachN – удаляем каждый n-ый, поэтому первые n-1 оставляем (четвертый аргумент), далее удаляем 1 (второй аргумент), теперь каждый раз пропускаем n-1 элементов (третий аргумент) и снова удаляем до конца списка l (первый аргумент)

    ListSelectEachN – оставляем каждый n-ый – это зеркальная ситуация, здесь мы начнём пропускать прямо с начала списка, поэтому четвертый аргумент нам не нужен (т.е. его можно было не писать, но он мне нужен для примеров ниже, поэтому поставил значение по умолчанию - 0), здесь мы каждый раз удаляем n-1 элементов (второй аргумент), далее оставляем 1 (это и есть нужный нам n-ый) и так до конца списка.
    e,f – применение написанных функций – можете убедиться в работоспособности

    В целом вроде несложно, надо просто привыкнуть к порядку и назначению аргументов. Но вот тут самое время сказать про Table.AlternateRows. У неё тоже четыре аргумента, правда на этот раз все обязательные, они имеют то же назначение, но идут… в другом порядке! (они ещё и называются по-другому, но это на мой взгляд уже мелочи).
    Скажем «спасибо» разработчикам и запомним – в Table.AlternateRows сначала число элементов, на которое нужно отступить (offset), потом число пропускаемых (skip), потом число элементов после которых пропускание нужно повторить (take). Ну и пример кода:

        let
            tbl = Table.FromColumns({{1..10}},{"a"}),
            TableDelEachN    =(t,n)=>Table.AlternateRows(t,n-1,1,n-1),
            TableSelectEachN =(t,n)=>Table.AlternateRows(t,0,n-1,1),
            e = TableDelEachN(tbl,3),
            f = TableSelectEachN(tbl,3)
        in
            f

    Здесь приведены функции TableDelEachN и TableSelectEachN, удаляющая или наоборот выбирающая n-ые строки таблицы. Сравните их с функциями для списков – всё то же самое, «просто» аргументы в другом порядке.

    Как-то так, функции хорошие, реально шустрые, для обозначенных задач прямо незаменимые, просто к тому, что они «немножко» разные нужно привыкнуть… )))
    ]

[   Skip, Range или Remove или читаем Спецификацию / #АнатомияФункций – Table.Skip, Table. Range, Table.RemoveFirstN, List.Skip, List. Range, List.RemoveFirstN

    Всем привет!
    Разбирал функции М в Спецификации, а конкретно функцию Table.Range:
    Синтаксис :

        Table.Range(table as table, offset as number, optional count as nullable number) as table
    
    В описании к функции: Table.Range нашел интересное сходство с отличной функцией Table.Skip
    (table as table, optional countOrCondition as any) as table

    Ну и вдогонку с функцией:

        Table.RemoveFirstN(table as table, optional countOrCondition as any) as table

    Все эти функции позволяют «избавить» таблицу от шапки с определенным количеством строк (ну или просто пропустить несколько «мусорных» строк – при парсинге сайта, или pdf, например)

    В случае с Text.Skip и Text.RemoveFirstN можно передавать как индекс (сколько строк пропустить), так и функцию (какие строки пропустить), тогда как Table.Range принимает только индекс. Казалось бы разницы особой нет, но лучше сделать текст скорости:
    Берем таблицу из 100К строк и убираем из нее шапку в 50k строк
    
        let
            from = Excel.CurrentWorkbook(){0}[Content],
            rng  = Table.Range(from,50000),
            skp  = Table.Skip(from,50000),
            rfN  = Table.RemoveFirstN(from,50000)
        in
            rfN

    Самым быстрым оказался RemoveFirstN, Range на 2% медленнее, а Skip – на почти 10% медленнее!.
    Возник вопрос: А в чем собственно дело ?
    
    В чате, маэстро @buchlotnik тут же дал ответ:
    Skip-то думает, передавать по функции или по индексу, а Range сразу откусывает нужное количество.
    Тест с List.Skip/Range/RemoveFirstN подтвердил ответ @buchlotnik в части работы Range и Skip – Skip оказалась медленнее почти на 20%.
    Вывод: хотим быстрее – юзаем Range.

    Ну и на закуску, в подтверждении мысли Михаила @buchlotnik, вишенка на торте – работа Мерки 2.1 в excel и сравнение скорости на функциях с явной передачей индексов и без них.
    Формулы для поиска значения в диапазоне с типом сопоставления (у нас используется ноль в качестве аргумента):
    =ВПР(искомое; где ищем; столбец; 0)
    =ВПР(искомое; где ищем; столбец;)
    =ПОИСКПОЗ(искомое;где ищем;0)
    =ПОИСКПОЗ(искомое;где ищем;)
    Измерения показали, что в среднем теряется 0,003 секунды – вроде не много, но каждый раз. Так что в следующий раз стоит подумать – потратить время/силы/нервы, но написать нолик или отдать это на откуп функции с ожидаемой в итоге потерей скорости.

    Резюме: если есть выбор между функцией с аргументом any и аргументом number – выбираем вторую, она быстрее, потому что не сомневается и сразу действует.
    ]

[   HEX2DEC – или чем ещё полезны Binary и BinaryFormat / #АнатомияФункций – Custom Functions

    Всем привет!
    В чате всплыла тема преобразования шестнадцатеричного представления чисел в десятичное. Не самая частая ситуация, но всё равно неприятно, когда вместо символов кириллицы получаем «C4» или какой-нибудь «FF».
    Типовое решение задачи есть, сразу его и разберем:
        
        let
            from = {"C4", "EB", "FF", "20", "F2", "E5", "F5", "2C", "20", "EA", "F2", "EE", "20", "E2", "20", "F2", "E0", "ED", "EA", "E5", "29", "29", "29"},
            f=(x)=>Expression.Evaluate("0x"&x),
            to = Text.FromBinary(Binary.FromList(List.Transform(from,f)),1251)
        in
            to

    from - на вход прилетел список символов в шестнадцатеричной кодировке (точнее текст кодов этих символов)
    f    - функция преобразования, основанная на функции Expression.Evaluate. Здесь используется тот факт, что префикс "0x" обозначает шестнадцатеричную кодировку – мы добавляем его к строковому значению и просим вычислить полученное – на выходе получаем обычное десятичное число.
    to   - далее список полученных кодов преобразовали в список чисел, получили из него бинарник и прочитали как кириллический текст (кодировка 1251)

    Всё очень лаконично, но ходят слухи, что из-за Expression.Evaluate компьютеры просто вешаются. Автор не разделяет такой точки зрения, поскольку на больших массивах время выполнения составит 200% от самого быстрого из известных мне вариантов (в два раза медленнее, но не на порядки, как обычно утверждают). Тем не менее, ускориться можно.
    Перепишем функцию f вот так:
    
        f=(x)=>[
            a = [0=0,1=1,2=2,3=3,4=4,5=5,6=6,7=7,8=8,9=9,A=10,B=11,C=12,D=13,E=14,F=15],
            b = List.Reverse(Text.ToList(x)),
            c = List.Accumulate(
                    b,
                    [i = 0, n = 0],
                    (s,c)=>[i = s[i] + 1, n = s[n] + Number.Power(16,s[i]) * Record.Field(a,c)]) [n]
            ][c]
    
    разберём её шаги –
    
    a – словарь из записи (в сети можете найти массу вариаций – на перечислении, списках списков и т.д.)
    b – преобразование текста в последовательность символов в обратном порядке
    c – ну и преобразование полученного списка в число – из записи получаем численное значение и умножаем на соответствующую степень 16 (здесь через Record.Field, в сети есть варианты через List.Positions, List.PositionOf, List.Generate и т.д.), ну и суммируем. В данном случае глобально использован List.Accumulate, но опять же в сети можете найти через List.Sum(List.Transform… и даже через рекурсию.
    
    Получилось достаточно громоздко, но по скорости – это уже 130% от самого шустрого. Т.е. мы действительно ускорили процесс, причем в полтора раза. Другое дело, что, как вы поняли, такой подход уже многократно описан и мой по скорости не сильно выигрывает, поскольку использует тот же принцип.

    Сегодня же я хочу показать совсем другой вариант, скорость которого и составляет эталонные 100%:
        
        f=(x)=>BinaryFormat.Byte(Binary.FromText(x,BinaryEncoding.Hex))
    
    вот так, в одну строчку )))
    Суть простая – мы получаем бинарник напрямую из его строкового представления (Binary.FromText) ну и читаем полученный байт (каждый символ в шестнадцатеричном представлении отвечает за 4 бита, два символа дают 8 бит или 1 байт).
    Кто-то, разумеется, возмутится – ведь это может быть и бОльшее число (т.е. более двух шестнадцатеричных знаков), функции выше с ним бы справились, а эта нет. Согласен, но в этой ситуации поступаем, например, так:
        
        f=(x)=>BinaryFormat.UnsignedInteger32(Binary.FromText(Text.PadStart(x,8,"0"),BinaryEncoding.Hex))
    
    т.е. с помощью Text.PadStart дополняем текст нулями до 8 символов и читаем не байт, а четырёхбайтное целое (или до 16 символов и тогда читаем восьмибайтное) – на скорости это практически не сказывается, зато получаем универсальную функцию и в одну строчку.

    Никаких «финтов ушами», никаких специфических приёмов – просто стандартная библиотека – любите её, в ней много интересного
    ]
[   Table.TransformColumnTypes – обновляем типы вручную, но пачками / #АнатомияФункций - //!Table.TransformColumnTypes

    Всем привет! Неоднократно поднимался вопрос и вот вчера снова напомнили – обсудим неавтоматическую типизацию столбцов. Суть проблемы в следующем – по умолчанию при загрузке таблицы добавляется шаг «Изменённый тип» и это в целом удобно. Но если подключение не разовое рано или поздно в таблице-источнике пропадает столбец, или меняется его название, или добавляются новые столбцы и шаг приходится редактировать. И вот тут, особенно если столбцов не один десяток (в особых случаях и за сотню переваливает), выясняется, что не то что корректно отредактировать – просто найти нужное наименование непросто, а если подгружается несколько таблиц и список столбцов меняется динамически – задача ручного редактирования становится не сколько невыполнимой, сколько бессмысленной.

    По этому поводу напишем немножко кода и разберем почему так:
    
        let
            from = Table.FromRecords({[Наименование="тапки",Категория="обувь",ЦенаОпт=1000,ЦенаРозн=2000,Количество=100,СуммаОпт=100000,СуммаРозн=200000,Продавец="Вася",ДатаПоступления=44562,ДатаПродажи=44835,ДатаОтгрузки=44866,Примечание="обычные тапки"]}),
            nms = Table.ColumnNames(from),
            
            dlst = List.Select(nms,(i)=>Text.Contains(i, "Дата")),
            nlst = List.Select(nms,(i)=>List.Contains({"Цена","Количество","Сумма"}, i, (x,y)=>Text.Contains(y,x))),
            tlst = List.Difference(nms, dlst & nlst),

            f=(x,y)=>List.Transform(x,(i)=>{i,y}),

            transflst = f(dlst, Date.Type) & 
                        f(nlst, Number.Type) & 
                        f(tlst, Text.Type),
            
            to = Table.TransformColumnTypes(from, transflst)
        in
            to

    from – на вход прилетела таблица, здесь не очень большая, просто чтоб пост не загромождать, но и дат может быть больше и всякие цены с НДС – короче включите фантазию
    nms – получили список имён всех столбцов
    dlst – из общего списка получаем только имена столбцов с датами
    nlst – также из общего списка получаем имена столбцов с числовыми значениями (сам приём обсуждался тут и основываясь на этом принципе вы можете адаптировать код под ваши ключевые слова)
    tlst – ну и все столбцы не с датами и не с числами мы хотим сделать текстовыми – тут нам в помощь List.Difference - из всех имён оставили только те, которые не вошли в dlst и nlst.
    Ок, теперь вспомогательная функция f – она принимает два аргумента: x – список, y – тип, и преобразует наш список в список списков вида {название,тип} (это мы тоже на самом деле уже обсуждали )
    transflst – на основе наших списков с помощью вспомогательной функции собираем списки списков преобразований и объединяем их (как работает амперсанд со списком списков обсуждали тут)
    to – применили наш список преобразований типов к таблице – и всё!

    Да, кому-то может показаться, что это несколько громоздко, но на самом деле если сравнить код выше с тем, что обычно содержится в шаге «Изменённый тип», то окажется, что написано всё более чем компактно )))

    При этом обращаю внимание – мы ни разу в коде не обратились к конкретному имени столбца, не писали фиксированного списка преобразований, всё чем оперировали – это ключевыми словами, ориентируясь на которые можно определить тип. Полученный код никак не привязан к конкретной таблице и все преобразования вычисляет и производит динамически, а поэтому гораздо более устойчив к изменениям. Поэтому если вы сталкиваетесь с большими таблицами – не поленитесь, напишите несколько строк кода – это сильно упростит жизнь в будущем.
    ]
[   List.Combine+Table.FromList vs AddIndexColumn+AddColumn+Unpivot+Pivot + что там ещё можно наклацать мышкой / #Невсейогуртыодинаковополезны

    Коллеги, всем доброго.
    Популярность М растет и вместе с тем появляется много интересных роликов на просторах интернета. Youtube в данном случае занимает лидирующее положение в этой части.
    В поисках священного грааля в части оптимизации кода на М, да и просто в поисках интересных решений, натолкнулся на один ролик, в котором разбиралась задача по нормализации таблицы.
    К автору ролика нет никаких претензий, но задачку решил разобрать.

    Исходные данные - таблица вида:

        #table({"1","2","3"},{{"01.02.22","02.02.22","03.02.22"},{100,200,300},{"04.02.22","05.02.22","06.02.22"},{500,700,900}})

    Ее требуется привести к формату:
    
        #table({"1","2"},{{"01.02.22",100},{"02.02.22",200},{"03.02.22",300},{"04.02.22",500},{"05.02.22",700},{"06.02.22",900}})

    Предложение автора ролика в коде (исходный диапазон представлен в виде таблицы excel. Ее можно самостоятельно по примеру выше составить на листе):
        
        get_data = Excel.CurrentWorkbook(){[Name="Дата"]}[Content],
        tab_idx =Table.AddIndexColumn(get_data,"Индекс",0,1, Int64.Type),
        tab_mod =Table.AddColumn(tab_idx,"Остаток от деления",each Number.Mod([Индекс], 2),type number),
        tab_row_num =Table.AddColumn(tab_mod,"row_num",each if [Остаток от деления] = 0 then [Индекс] else [Индекс] - 1),
        tab_remove_cols = Table.RemoveColumns(tab_row_num, {"Индекс"}),
        tab_unpivot = Table.UnpivotOtherColumns(tab_remove_cols,{"Остаток от деления", "row_num"},"Атрибут","Значение"),
        tab_pivot = Table.Pivot(Table.TransformColumnTypes(tab_unpivot,{{"Остаток от деления", type text}},"ru-RU"),
        List.Distinct(Table.TransformColumnTypes(tab_unpivot,{{"Остаток от деления", type text}},"ru-RU")[#"Остаток от деления"]),"Остаток от деления","Значение"),
        cols_select = Table.SelectColumns(tab_pivot,{"0", "1"})

    Подход в представленном коде: добавление столбца индекса, нахождение остатков по модулю и далее ресурсоемкие функции Pivot и Unpivot.
    Данное решение имеет право на жизнь и ни в коем случае не оспаривается.
    Есть ли альтернатива данному подходу?
    Сходу решение:
        
        from = Excel.CurrentWorkbook(){[Name="Дата"]}[Content],
        lst1 = List.Combine(Table.ToRows(Table.AlternateRows(from,1,1,1))),
        lst2 = List.Combine(Table.ToRows(Table.AlternateRows(from,0,1,1))),
        zp   = List.Zip({lst1,lst2}),
        to   = Table.FromList(zp,(x)=>x)
    
    Логика кода: Берем четные и нечетные списки по строкам таблицы, комбайн и через ZIP определяем в Table.FromList.
    Проверка скорости на Мерке показала, что альтернативное решение как минимум в 3 раза по скорости выше, чем код автора ролика на Youtube.

    Решение было показано Михаилу (@buchlotnik) и от маэстро PQ последовал ответ в виде еще одного решения:

        from = Excel.CurrentWorkbook(){[Name="Дата"]}[Content],
        to   =  Table.FromList(
                    List.Combine(
                        List.Transform(
                            List.Split( Table.ToList(from,(x)=>x), 2 ),
                            List.Zip
                        )
                    ),
                    (x)=>x
                )

    Согласитесь, лаконично, логично и красиво.

    Ожидаемо, что по скорости данное решение не оставило шансов предыдущим двум. Можете сами убедиться на 56k строк:
    Запрос       Среднее      От         До     Общее
    Buch           0,59       0,53       0,7    14,84
    CubRoot        0,93       0,86       1,09   23,27
    Youtube        2,84       2,67       3,14   71,02

    О чем этот пост: Решения через "мышку" имеют право на жизнь, но если Вы хотите ощутить в полной мере, как дрожит двигатель М, берите в руки механику – используйте расширенный редактор, читайте Спецификацию и предлагайте свои оригинальные решения.
    Вместе мы сделаем мир М чище )
    ]
[   List.TransformMany vs. Table.CombineColumns или параллельный сплит нескольких столбцов / #АнатомияФункций - List.TransformMany, Table.CombineColumns

    Всем привет! Подкинули намедни задачку по преобразованию графика отпусков в божеский вид. По этому поводу разберем вопрос сплита нескольких столбцов по разделителю.
    Сразу пример:

        let
            from = Table.FromRecords(Json.Document(Binary.Decompress(Binary.FromText("rZLBDsIwCIZfpel5aYDSWX0V9eCmvoEn47u7QeeoiXOJXn4G+6HlS/d3f7gBRxa9iHaireh5rjOKkmjvd/69aNv5Kgq+UZvOz2orvUiuCsVrz4y9aCrDdrGx11VjHsYlN84AOCFr5JIPP5yvmsBs0Q2ttAkQAwFF9xpCAdpS0gptA2SpaA4YENXhH82PDOPVtFwMz7OBdlokGV0VVpDkDyQngMjL2GBglAwRzAG2kv8NiB6ZzDcU2xIKdlVYgSL9iGJ8HBYF5emx/AFFNrZ2vnepTDssAUmuCiuAtB+AUP7yJjDAZlyc/OP4BA=="),Compression.Deflate))),
            f=(x)=>List.Zip(List.Transform(x,(i)=>if Text.Contains(i,"#(lf)") then Text.Split(i,"#(lf)") else {i})),
            cmb = Table.CombineColumns(from,{"дни","даты"},f,"tmp"),
            exp = Table.ExpandListColumn(cmb, "tmp"),
            to  = Table.SplitColumn(exp,"tmp",(x)=>x,{"дни","даты"})
        in
            to

    from – вот такая таблица на входе – столбцы «должность», «фио», «номер»; а вот столбцы «дни» и «даты» нужно разделить по разрыву строки, причём оба сразу в новые строки.

    f - поскольку сплитить будем сразу оба столбца, обрабатывать будем их как список. Сначала смотрим что происходит внутри List.Transform: (i)=>if Text.Contains(i,"#(lf)") then Text.Split(i,"#(lf)") else {i}) – если текст содержит разрыв строки делаем сплит по этим разрывам, иначе – оставляем список из одного исходного значения. Таким образом, по каждому столбцу получим список значений (с одним или несколькими элементами) и далее эти списки скармливаем List.Zip – как мы помним, она сошьет элементы построчно.

    cmb – скомбинировали столбцы с помощью нашей функции – в столбце “tmp” теперь содержится список списков (пары значений построчно)

    Что делать дальше уже разбирали тут:
    exp – развернули списки в отдельные строки
    to – развернули строки в отдельные столбцы

    Вроде просто и логично, тогда о чём пост? Да о том, что на списках быстрее )))

    Шаги from и f оставляем на месте, а вот дальше меняем стратегию:

        nms = Table.ColumnNames(from),
        lst = Table.ToList(from,(x)=>x),
        tr  = List.TransformMany(lst,(x)=>f(List.LastN(x,2)),(x,y)=>List.FirstN(x,3)&y),
        to  = Table.FromList(tr,(x)=>x,nms)

    nms – получили названия столбцов исходной таблицы

    lst – разобрали таблицу в строки (функция, которая ничего не делает)

    tr – и теперь дважды преобразуем полученный список строк:

        (x)=>f(List.LastN(x,2))   – применяем нашу функцию f к последним двум элементам (получаем список списков);
        (x,y)=>List.FirstN(x,3)&y – собираем строки из первых трёх элементов по строке и объединяем их с каждой парой из 
    
    полученного списка списков. На выходе получаем сразу все строки

    to – осталось только обратно собрать таблицу

    По сути, всё то же самое, но во втором случае мы вместо табличных преобразований применили списочные, на этом можно получить выигрыш по производительности на 15-20 %.

    Многие говорят о том, что «не видят» в своих задачах применения для List.TransformMany – данный пример должен дать пищу для размышлений.
    ]
[   Record.FieldOrDefault для GroupKind.Local или как заменить FillDown / //! #АнатомияФункций - Record.FieldOrDefault, GroupKind.Local

    Всем привет. Подогнали в чате задачку (тут последний стенд - там и мышкоклац, и моё решение на списках с последующим FillDown). Я бы решил и забыл, но Игорь (@CubRoot) попытался примотать Table.Group и даже по скорости меня обогнал (потом правда выяснилось, что тестирование было некорректным, но было поздно - я уже всё переписывал) - поэтому пришлось засучить рукава и немножко поиграть в оптимизацию. Разберем самый эффективный из полученных вариантов:

        let
            from = Table.FromColumns({{"насосы","н-1","н-2","н-3","подносы","п-1","п-2","п-3","пылесосы","п-1","п-2","п-3"}},{"категория"}),
            lst  = {"насосы","подносы","пылесосы"},
            rec  = Record.FromList(List.Repeat({1},List.Count(lst)),lst),
            f = (s,c)=>Record.FieldOrDefault(rec,c,0),
            gr   = Table.Group(from,"категория",{"товар",each List.Range([категория],1)},GroupKind.Local,f),
            to   = Table.ExpandListColumn(gr, "товар")
        in
            to

    from – вот такая таблица, в которой смешаны категории и товары
    lst  – список категорий
    rec  – изюминка решения – делаем запись, в которой названия полей – категории, а вот значения – единицы
    f    – функция для Table.Group – проверяет наличие соответствующего поля в записи – если находит – вернёт 1, иначе – 0 (т.е мы сразу получаем 0 или 1 для пятого аргумента )
    gr   – ну и группируем по единственному столбцу, агрегацию делаем по нему же, пропуская первую строку (это строка самой категории). Обращаю внимание, что использовано Range (почему – обсуждали тут ). При этом функция f нам сразу отдаёт числовое значение, поэтому обошлись без if или Number.From
    to   – осталось только раскрыть списки в строки по столбцу «товар»

    Вот так – группировка позволила нам сохранить названия категорий в отдельном столбце безо всяких фильтраций, при этом все значения собрали разом, избегая FillDown. На мой вкус приём вышел интересный и весьма шустрый. Игорь, спасибо за "пинок" - продолжай свои нестандартные эксперименты - это круто!
    ]
[   Text.AfterDelimiter, Text.BeforeDelimiter, Text.BetweenDelimiters – получаем фрагмент из текста / #АнатомияФункций - Text.AfterDelimiter, Text.BeforeDelimiter, Text.BetweenDelimiters

    Всем привет!
    Подкинули тут задачку – «вытащить из текста значение в скобках… только внутри скобок могут быть ещё скобки, а вот их надо оставить». Вроде не очень сложно, но по этому поводу разберем как работают Text.*Delimiter*.

    Сразу пример, а потом разберем по шагам:
    
    let
        txt="какой-то текст (текст в скобках (и текстом в ещё (и ещё) одих скобках) снова текст) и текст вне скобок",
        a = Text.AfterDelimiter(txt,"("), //текст в скобках (и текстом в ещё (и ещё) одих скобках) снова текст) и текст вне скобок
        b = Text.AfterDelimiter(txt,"(",1), //и текстом в ещё (и ещё) одих скобках) снова текст) и текст вне скобок
        c = Text.AfterDelimiter(txt,"(",{0,RelativePosition.FromEnd}), //и ещё) одих скобках) снова текст) и текст вне скобок
        d = Text.BeforeDelimiter(txt,")"), //какой-то текст (текст в скобках (и текстом в ещё (и ещё
        e = Text.BeforeDelimiter(txt,")",{0,RelativePosition.FromEnd}), //какой-то текст (текст в скобках (и текстом в ещё (и ещё) одих скобках) снова текст
        f = Text.BetweenDelimiters(txt,"(",")"), //текст в скобках (и текстом в ещё (и ещё
        g = Text.BetweenDelimiters(txt,"(",")",0,{0,RelativePosition.FromEnd}),//какой-то текст
        h = Text.BetweenDelimiters(txt,"(",")",0,{0,RelativePosition.FromStart}),//текст в скобках (и текстом в ещё (и ещё
        i = Text.BetweenDelimiters(txt,"(", ")",0,Text.Length(Text.Select(txt,")"))-1), //текст в скобках (и текстом в ещё (и ещё) одих скобках) снова текст
        j = Text.BetweenDelimiters(txt,"(", ")",Text.Length(Text.Select(txt,"("))-1,0),//и ещё
        k = Text.AfterDelimiter(Text.BeforeDelimiter(txt,")", {0, RelativePosition.FromEnd}),"(")//текст в скобках (и текстом в ещё (и ещё) одих скобках) снова текст
    in
        k

    a – просто получили текст после разделителя
    b – получили текст после второго вхождения разделителя (не забываем про нумерацию с нуля)
    с – получили текст после последнего вхождения разделителя (0 обозначает первый, а FromEnd – с конца, также обратите внимание на фигурные скобки)
    d – текст до разделителя (до первого вхождения)
    e – текст до последнего вхождения разделителя

    Ну, ок, вроде всё понятно – указываем разделитель, указываем при необходимости номер вхождения, но нам-то надо вынуть текст между скобок (от первой открывающей до последней закрывающей)– поэтому продолжаем:
    f – получили текст от первой открывающей скобки до первой закрывающей
    g – а вот тут не понятно, верно? Проблема в том, что позицию первого разделителя мы можем указать с начала или с конца текста, а вот для второго разделителя отсчёт идет не по тексту целиком, а от первого разделителя. Т.е. от первой открывающей скобки поиск пошёл в начало текста и получили то, что получили
    h – и если поиск развернуть – получим то же самое, что и в шаге f

    Печально, но делаем вывод – раз нельзя привязать положения обоих разделителей к исходному тексту, придётся считать.
    i – собственно решение изначальной задачи – берём первую открывающую скобку, а номер последней закрывающей определяем как Text.Length(Text.Select(txt,")"))-1 – т.е. просто оставили в тексте только закрывающие скобки и получили его длину (не забыли -1 так как нумерация с нуля)
    Ну а если бы задача стояла наоборот – получить текст из самых внутренних скобок:
    j – вычисляем последнюю открывающую скобку и берём текст до первой закрывающей

    В примере ещё маячит шаг k – и он здесь не просто так. Это к тому, что если нужен текст между разделителями, совершенно не обязательно использовать BetweenDelimiters – можно же использовать комбинацию AfterDelimiter +BeforeDelimiter – и она на данной задаче работает шустрее (причём процентов так на 10 на массиве в 10k). Почему? Да потому что для штатной функции нам потребовались дополнительные вычисления. Пишите как вам удобнее, но не забывайте про эффективность )))
    ]

[   Text.Contains, Text.Upper - Поиск ключевых слов в тексте / #АнатомияФункций - Text.Contains, Text.Upper

    Всем привет!
    Подкинули мне недавно ссылку, я покипел и успокоился, но сегодня всплыло обсуждение Text.Upper, поэтому снова накатило…

    Итак, решаем архисложную задачу – есть таблица, в ней текстовый столбец, и есть список ключевых слов – необходимо проверить наличие ключевых слов в тексте и совпавшие вывести через запятую. Дополнительно практически неразрешимой задачу делает необходимость поиска без учёта регистра…

    Что бы там ни говорили, я не противник мышкоклаца - я противник неоптимального кода. Поэтому тут не будет двадцатиминутного видео или статьи на несколько страниц, просто решим задачу:
        
        let
            tbl  = #table({"Артикул","Описание"},{{1,"деталь для Audi"},{2,"что-то для KIA или ford"},{3,"для BMW (и для audi подойдет)"}}),
            tbl1 = #table({"Марка"},{{"AUDI"},{"BMW"},{"KIA"},{"FORD"}}),
            dict = List.Buffer(tbl1[Марка]),
            f=(x)=> Text.Combine(
                        List.Select(
                            dict,
                            (i)=>Text.Contains(Text.Upper(x),i)
                        ),", "
                    )
            to   = Table.AddColumn(tbl,"New", each f([Описание]))
        in
            to

    по шагам:
    tbl     – исходная таблица, искать будем по столбцу «Описание»
    tbl1    – список ключевых слов – ну как список – таблица, взятая с листа
    dict    – первое, что делаем – превращаем таблицу в список, не забываем его забуферить – нам к нему придётся обращаться многократно
    f       – функция для поиска – принцип простой – проверяем список ключевых слов, выбираем из него встретившиеся и собираем полученные ключевые слова в текст через разделитель. Теперь посмотрим на функцию отбора – здесь у нас Text.Contains, содержащий внутри Text.Upper. Зачем? Да просто Comparer.OrdinalIgnoreCase, который обычно рекомендуют, штука медленная, а переведя текст в верхний (или в нижний) регистр мы сильно упрощаем и ускоряем обработку
    to      – использовали нашу функцию для добавления столбца

    Всё… Пять строчек кода.

    На примере с одного известного сайта этот код обошёл по скорости мышкоклацный всего-то в 6 раз (на 100k строк).
    При этом ещё 4% производительности можно получить, если написать последний шаг так:

        to = Table.FromList(
                Table.ToList(from,(x)=>x & {f(x{1})} ),
                (x)=>x,
                Table.ColumnNames(from) & {"New"}
             )
        (мы это уже обсуждали тут)

    В решении нет ни одной «хитрой» функции или какого-то специального приёма. Тот же Upper (или Lower) абсолютно аналогично используется в SQL или php, например. Поэтому перед тем, как начинать мучать мышь, предлагаю всё же задуматься – может и правда стоит уже открыть расширенный редактор и что-то там написать самостоятельно. Ну хотя бы, повторить, не подсматривая, решение выше. Немножко практики и руки сами начнут автоматом тянуться к клавиатуре – а там и до поста в танке недалеко…
    ]

[   Множественная замена в тексте / #АнатомияФункций – приёмы

    Всем привет!
    Пора закрыть тему замен в тексте. Мы уже приматывали "словарь на записях" для замены значения целиком и для посимвольных замен, но бывают ситуации, когда необходимо осуществить замену внутри текста, причём имеется ряд вариантов. Тут уже не обойтись без Text.Replace и я не знаю более шустрого варианта, чем запихнуть это в List.Accumulate. 
    Поэтому просто разберем пример:

        let
            tbl  = #table({"текст","число"},{{"мама мыла раму",1},{"отмыла мамочка рамочку",2}}),
            tb2  = #table({"что","на что"},{{"мам","пап"},{"мыла","пил"},{"рам","пив"}}),
            dict = List.Buffer(Table.ToList(tb2,(x)=>x)),
            f    = (x)=>List.Accumulate(dict,x,(s,c)=>Text.Replace(s,c{0},c{1})),
            to   = Table.TransformColumns(tbl,{"текст",f})
        in
            to

    tbl  – исходная таблица, в которой нужно преобразовать столбец текст
    tb2  – таблица для замен
    dict – преобразуем таблицу замен в список и не забываем его забуферить
    f    – функция для преобразования текста – используем List.Accumulate, в качестве первого аргумента используем список замен (список списков, если точнее), второй аргумент – сам текст, ну и функция – просто Text.Replace
    to   – применяем нашу функцию к столбцу (а можно и к столбцАМ)

    Всё… Подключились к таблицам, сделали из одной словарь, сверстали функцию в одну строку и применили её. Никаких лишних телодвижений, индексов и прочего ))) Пользуйтесь!
    ]

[   Record.From… - или варианты получения словаря на записях //todo #АнатомияФункций – приёмы. Словарь - самый быстрый

    Всем привет! Сегодня в личке узнал, что джойны работают в разы быстрее словаря на записях. Немножко расстроился, удивился, потом разобрался и по этому поводу пост )))

    Итак, напоминаю задачу – из таблицы
        
        #table({"Должность","Оклад","Премия"},{{"Игрок",1000,100},{"Тренер",2000,5000},{"Врач",100,1}})
    
    Нужно получить запись
        
        [Игрок={1000,100},Тренер={2000,5000},Врач={100,1}]
    
    Которую мы в дальнейшем используем для подстановки через Record.Field или Record.FieldOrDefault

    Все преобразования показываю в виде функций. В первоначальном посте была такая:
    
        f=(table)=>
            List.Accumulate(
                Table.ToRows(table),
                [],
                (s,c)=>Record.AddField(s,c{0},List.Skip(c))
            )
    
    которую можно немного ускорить:
    
        f=(table)=>
            List.Accumulate(
                Table.ToList( from, (x)=>{ x{0}, List.Skip(x) } ),
                [],
                (s,c)=>Record.AddField(s,c{0},c{1})
            )
    
    Оба варианта вполне рабочие, даже шустрые, но на объёмах словаря до 100 позиций. Причина – сам по себе аккумулятор работает со списком последовательно, поэтому никаких параллельных вычислений не допускает и на больших объёмах просто падает (поэтому делать словарь на 5k позиций через него не надо – это и правда в разы медленнее джойнов)

    Ок, что есть в альтернативе – пойдём через таблицы (Record.FromTable):
    
        f=(table)=>[
            nms  = Table.ColumnNames(table),
            comb = Table.CombineColumns(table,List.Skip(nms),(x)=>x,"Value"),
            res  = Record.FromTable(Table.RenameColumns(comb,{nms{0},"Name"}))
        ][res]
    
    на объемах до 100 – это вообще самый шустрый вариант, к 1000 выравнивается с вариантами ниже, ну и потом потихоньку отстаёт.
    Другой вариант я уже показывал ранее:
    
        f=(table)=>
            Record.FromTable(
                Table.FromList( 
                    Table.ToList( table, (x)=>{ x{0}, List.Skip(x) }),
                    (x)=>x,{"Name","Value"}
                )
            )
    
    Также крайне шустрый и ощутимо отстаёт от лидеров только на объёмах в 100k и более.

    Ну и последняя парочка вариантов – разумеется на списках (Record.FromList). Они самые шустрые на больших объемах (от 10k):
    
        f=(table)=>
            Record.FromList(
                Table.ToList(table,(x)=>List.Skip(x)),
                Table.Column(table,Table.ColumnNames(table){0})
            )

    здесь немножко криво получены имена полей – через обращение к первому столбцу, но поскольку пересборки таблицы не происходит – это всё равно шустро
    Но на удивление более быстрым (и чемпионом на объёмах от 1000) стал вариант:
    
        f=(table)=>
            Record.FromList(
                Table.ToList(table,(x)=>List.Skip(x)),
                Table.ToColumns(table){0}
            )
    
    взять первый столбец из списка столбцов получилось быстрее, чем взять один, но по вычисленному имени.

    В комментарии под постом сложу таблицу с промерами скоростей. Ещё раз повторюсь – все варианты рабочие, но применимость зависит от реальной задачи. Поэтому если вдруг джойны оказываются шустрее – задумайтесь, а правильно ли собран словарь )))
    ]

[   Преобразование текста во всех столбцах таблицы – Replacer, Splitter или причём тут FromList //? #АнатомияФункций - Text.Replace, Text.BeforeDelimiter, Table_ReplaceValue

    Добрый день, дамы и господа.
    Довольно частое явления в обработке данных – обработка таблиц, в которых наряду с числовыми данными могут находиться единицы измерения. Оставим за рамками данного поста высказывания в адрес составителей таблиц и посмотрим, что мы можем с этим сделать.

    Пример: 
        tbl = #table({"Товары","Январь","Февраль","Март"},{{"Товар1","1 шт.","2 шт.","3 шт."},{"Товар2","10 шт.","20 шт.","30 шт."}})

    1-ый Способ решения: Не прибегая к расширенному редактору – через «мышкоклац».

        to  = Table.ReplaceValue(tbl," шт.","",Replacer.ReplaceText,{"Январь", "Февраль", "Март"})

    Простота данного подхода сразу приносит боль, если поменяются/добавятся имена полей. Особенно если учесть, что нам потом ещё по этому же списку переводить типа столбцов в числовые.
    Перепишем в более рабочий вариант:

        let
            tbl = #table({"Товары","Январь","Февраль","Март"},{{"Товар1","1 шт.","2 шт.","3 шт."},{"Товар2","10 шт.","20 шт.","30 шт."}}),
            nms = List.Skip(Table.ColumnNames(tbl)),
            rep = Table.ReplaceValue(tbl," шт.","",Replacer.ReplaceText,nms),
            to  = Table.TransformColumnTypes(rep,List.Transform(nms,(i)=>{i,Number.Type}))
        in
            to 

    Допиленный вариант весьма шустр. Но он содержит Table.ReplaceValue, что для некоторых является красной тряпкой. Что можем противопоставить этому подходу?

    2-ой Способ решения:

    let
        tbl = #table({"Товары","Январь","Февраль","Март"},{{"Товар1","1 шт.","2 шт.","3 шт."},{"Товар2","10 шт.","20 шт.","30 шт."}}),
        f=(x) as number =>Number.From(Text.BeforeDelimiter(x," ")),
        to = Table.TransformColumns(tbl,{"Товары",(x)=>x},f)
    in
        to

    f-функция выборки текста до разделителя, в нашем случае это пробел. Она сразу преобразует значение в число и поскольку на уровне функции заявлен тип возвращаемого значения – таблица на выходе получается сразу с «правильными» числовыми столбцами.
    to – преобразование значение полей через описанную выше функцию

    Решение простое и надежное, лаконичное, НО медленное. В два раза по скорости проигрывает Table.ReplaceValue. Пакетом осуществить текстовое преобразование, а потом также пакетом преобразование типов оказывается эффективнее.
    И вот вооружившись этим знанием предложим третий способ:

    3-ий Способ решения:

        let
            tbl =   
                #table(
                    {"Товары","Январь","Февраль","Март"},
                    {
                        {"Товар1","1 шт.","2 шт.","3 шт."},
                        {"Товар2","10 шт.","20 шт.","30 шт."}
                    }
                ),
            nms =   Table.ColumnNames(tbl),
            f=(x)=>Text.Replace(x," шт.",""),
            lst =   List.Transform(Table.ToList(tbl),f),
            t   =   Table.FromList(lst,Splitter.SplitTextByDelimiter(","),nms),
            to  =   Table.TransformColumnTypes(t,
                        List.Transform(
                            List.Skip(nms),
                            (i)=>{i,Number.Type}
                        )
                    )
        in
            to

    Таблицу преобразовываем в список с последующим изменением списка через функцию замены текста и далее возвращаем список в таблицу.
    Сравнительный анализ по скорости на стенде показал неплохие результаты по третьему решению на 5K строк.

    О чем этот пост:
    Выбор решения той или иной задачи остается за пользователем. Кто-то теребит мышку и клацает решения, а кто-то через расширенный редактор вносит код руками. Если для Вас важна скорость обработки данных, а не скорость работы мышкой – рекомендую присмотреться к третьем решению по преобразованию текста в таблице. Попробуйте поэкспериментировать и сделать выводы. Если в процессе экспериментов у Вас родится еще несколько вариантов решения – будет неплохо их показать в комментарии, чтобы мы могли их сравнить и выбрать наиболее оптимальное.
    ]

[   #duration + Function.Invoke или как передать аргументы списком / #АнатомияФункций - Function.Invoke, #duration

    Пару дней назад в чате всплыла задачка, которая периодически возникает у пользователей – преобразовать время (точнее текст) вида "35:40:06" в собственно время.
    Нужно сказать, что M не позволяет подобных вольностей – #time, #date, #datetime, #datetimezone – требуют передачи аргументов в заданных диапазонах – часов не может быть больше 23, секунд и минут больше 59 и т.д. Другое дело #duration (длительность) – эта функция переваривает что угодно и выдаёт нужный формат:
        
        #duration(0,0,0,1000000) //11.13:46:40

    Т.е. миллион секунд даёт нам 11 дней 13 часов 46 минут и 40 секунд – штука удобная и часто используется при переводе Unix-времени в человеческое:
        
        #datetime(1970,1,1,0,0,0)+#duration(0,0,0,1671278969) //17.12.2022 12:09:29

    Ок, инструмент найден и теперь давайте его применять.
    Попробуем написать функцию, превращающую текст выше в длительность:
        
        f=(x)=>
            let
                h = Number.From(Text.BeforeDelimiter(x,":")),
                m = Number.From(Text.BetweenDelimiters(x,":",":")),
                s = Number.From(Text.AfterDelimiter(x,":",1))
            in
                #duration(0,h,m,s)

    Т.е. взяли текст до двоеточия, между двоеточиями и после второго двоеточия, преобразовали в числа и запихнули в #duration – так оно работает, но слишком много телодвижений (найдутся, конечно, те, кто скажет - "зато прозрачно и понятно" - но получать медленный запрос просто из-за удобства восприятия на мой взгляд сомнительно).
    ОК, как бы ускориться? Давайте просто разделим текст по разделителю:
    
        f=(x)=>[
            a = List.Transform(Text.Split(x,":"),Number.From),
            b = #duration(0,a{0},a{1},a{2})
        ][b]
    
    Такой вариант работает существенно (в разы) быстрее, поскольку мы один раз получили список чисел, а потом его элементы передали в #duration (аналогичное решение через мышкоклац – разделить столбец по разделителю, добавить вычисляемый, удалить лишнее – всё то же самое, просто медленнее раза в полтора).

    Но хочется красоты – как бы не делать два шага в функции, а вот сразу передать результат Text.Split в #duration? Дело было утром и я как-то сразу и не сообразил, но в чат стремительно ворвался @IlyaNazarov и явил миру вот это:
    
        f=(x)=>
            Function.Invoke( #duration, {0} & List.Transform(Text.Split(x,":"), Number.From) )
    
    Ну сказка, а не код! - Function.Invoke получает первым аргументом функцию (в данном случае #duration), а вторым – список передаваемых аргументов – это результат нашего Text.Split, но с добавленным в начале {0}- -потому что в тексте нет информации о количестве дней, а аргумент обязательный.
    Ну и как бы всё – на лету полученный список передан в функцию. Прирост по скорости не космический, но присутствует. Все промеры традиционно в первом комментарии под постом.

    Илья, спасибо за напоминание!
    А в целом обращаю внимание, что есть такой класс функций – Function. – и периодически они бывают полезны. Курите стандартную библиотеку – в ней много интересного )))
    ]

[   Expression.Evaluate или как импортировать код из текстового файла или с сайта? //todo #АнатомияФункций – Expression.Evaluate

    Всем привет!
    Очередной раз воспользовался одним приёмом, ну и решил о нём написать.
    Начнём издалека – с простой задачки. Вот загрузили вы файл, а там в ячейках любезно расписаны суммы "123+234+345", "1234+234" и т.д. И очень хочется превратить это в числа. Одно из решений такое:
    
        Expression.Evaluate("123+234+345") //702
    
    Т.е. функция Expression.Evaluate принимает текстовый аргумент как выражение и вычисляет его.
    Выражение может быть более сложным:
    
        Expression.Evaluate("123+234+345=702")//true
    
    Т.е. мы понимаем, что в выражении могут быть не только арифметические операторы.
    И это используется, например, когда надо текст вида "1-5,8,10-12" превратить в список последовательных элементов:
    
        Expression.Evaluate("{"&Text.Replace("1-5,8,10-12","-","..") & "}") //{1,2,3,4,5,8,19,11,12}
    
    В этой ситуации после подстановки выражение будет выглядеть как "{1..5,8,10..12}" и после вычисления даст нам искомый список.
    Достаточно удобно. И можно попытаться даже написать функцию для создания списка чисел от 1 до x:
    
        f = (x)=>Expression.Evaluate("{1..x}")
    
    Но в таком виде она не сработает – "имя x отсутствует в текущем контексте". Причина – x в тексте выражения – это лишь буква, а нам надо в явном виде заявить, что эта буква обозначает именно передаваемый аргумент:
    
        f = (x)=>Expression.Evaluate("{1..x}",[x=x])
    
    Здесь x до знака равенства – это имя в выражении, а после знака равенства – тот самый аргумент, с которым мы вызываем функцию. Как только вы осознаете этот факт, придёт понимание, что собственно в тексте могут быть и функции:
        
        f = (x)=>Expression.Evaluate("List.Sum({1..x})",[x=x,List.Sum=List.Sum])
    
    Так работает с точно такой же логикой - List.Sum до знака равенства – это просто имя из выражения, а после знака равенства – собственно функция, которую мы присваиваем данному имени.

    И вот тут мы и подходим к основной задаче поста – если у нас есть текстовый файл, содержащий текст запроса – можем ли мы его импортировать не как текст, а именно как запрос? И ответ – да, можем. Другое дело, что вот так, как выше, перечислять все функции из текста запроса утомительно и крайне не универсально. Что же делать? Да вот что:

        f = (x)=>Expression.Evaluate( "List.Sum({1..x})", #shared & [x=x] ) //! ВАЖНО 

    Здесь внутренняя переменная #shared возвращает содержимое глобальной среды – т.е. все функции, типы, константы и т.д., которые только знает M, в виде записи (record). Мы только добавили к ней ещё и x - аргумент нашей функции.
    Таким образом, использование #shared позволяет превратить текст запроса непосредственно в код, который можно выполнить.

    И теперь приём, о котором я сказал в самом начале – на GitHub у меня лежит парочка функций, и ту же UnZip я использую довольно часто. Конечно, можно просто скопировать. Но что если завтра возникнет мысль и я её перепишу на более быструю – очень не хочется переделывать все файлы, куда я её уже запихнул. Поэтому несколько более сложный вариант:
    
        Expression.Evaluate(Text.FromBinary(Web.Contents("https://raw.githubusercontent.com/buchlotnik/buchlotnik_functions/main/UnZip.pq")),#shared)
    
    Web.Contents – получает информацию с сайта (raw.githubusercontent.com – очень удобная штука – сразу отдает непосредственно текст функции – там не требуется выцарапывать её из разметки страницы). Далее Text.FromBinary переводит полученную информацию в текст, а Expression.Evaluate + #shared превращают текст в код. Это гарантирует, что файл, куда я поместил подобный запрос, работает с актуальной версией функции.

    Понятно, что совершенно не обязательно держать код на GitHub – это может быть просто текстовый файл, который вы держите на диске или в облаке. Это не обязательно должно быть функцией – возможно вы регулярно используете запрос для курсов валют или к производственному календарю. Такие запросы тоже приходится периодически корректировать – и лучше делать это один раз, нежели во всех своих файлах, ну а как – мы только что разобрали.
    ]

[   Expression.Evaluate или построчное вычисление выражений из ячейки / #АнатомияФункций - Expression.Evaluate

    Всем привет!
    В своё время мы уже разбирали функцию Expression.Evaluate и выяснили, что можно вычислять выражения вида "123+234+345", что можно написать функцию (x)=>Expression.Evaluate("…x…",[x=x]), и вообще превратили кусок текста с гитхаба в код с помощью #shared.

    Но тут в чате подкинули задачку немножко иного плана – а именно, вычислить результат выражения, записанного в ячейке, но вместо числовых значений – названия соответствующих полей.
    ОК, давайте смотреть:

        let
            from = #table(
                {"дата","текст","выражение","поле1","поле2"},
                {
                    {#date(2023,1,1),"Вася","-поле1/поле2",     11, 22},
                    {#date(2023,2,2),"Коля","поле1-поле2",      0,  33},
                    {#date(2023,3,3),"Петя","поле1*поле2-поле1",33, 44}
                }
            ),
            f=(rec)=>Expression.Evaluate(rec[выражение],rec),
            to = Table.AddColumn(from,"результат",f)
        in
            to

    И как бы весь код ))). Суть в том, что при добавлении столбца в функцию f передаётся текущая строка таблицы в виде записи (rec) и мы просим вычислить выражение из соответствующего поля (rec[выражение]), а встречающиеся имена заменить на значения из текущей записи.

    Но я бы не писал пост, если бы всё было так просто, в реальном примере у нас были null:
        
        let
            from = #table(
                {"дата","текст","выражение","поле1","поле2"},
                {
                    {#date(2023,1,1),"Вася","-поле1/поле2",11,22},
                    {#date(2023,2,2),"Коля","поле1-поле2",null,33},
                    {#date(2023,3,3),"Петя","поле1*поле2-поле1",33,44}
                }
            ),
            
            nms = List.Buffer(Table.ColumnNames(from)),
            f=(rec)=>[  a = Record.ToList(rec),
                        b = List.Transform(a,(x)=>if x=null then 0 else x),
                        c = Record.FromList(b,nms),
                        d = Expression.Evaluate(rec[выражение],c)][d],
            to = Table.AddColumn(from,"результат",f)
        in
            to

    в этой ситуации код выше не отработал бы как надо, поскольку любые арифметические операции со значением null дают null. Поэтому пришлось немножко усложнить код:
    nms – названия всех столбцов таблицы – нам это потребуется для создания записей на каждой строке – поэтому не забыли List.Buffer
        f  – функция от записи, которая делает следующее:
        a  – получили список значений всех полей,
        b  – заменили значения null на 0
        c  – заново собрали запись, но уже с нулями
        d  – отдали её в expression.Evaluate
        to – применяем вновь полученную функцию к нашей таблице и получаем корректный результат.

    Как-то так. Второй аргумент Expression.Evaluate сильно развязывает руки, надо просто передавать в него корректную запись.
    ]
[   Table.FindText – или ищем текст где-то в таблице / #АнатомияФункций - Table.FindText

    Всем привет!
    Разберем небольшой вопрос, который иногда всплывает при загрузке файлов с не очень однородным содержимым. А именно – тащим листы, на которых точно есть таблица, мы даже знаем, что должно содержаться в шапке, но к сожалению, не знаем ни сколько строк, ни сколько столбцов необходимо пропустить. По такому случаю пример:
    let
        a = #table( {"a","b","c","d","e","f"},
                    {{"text",null,null,null,"текст",null},
                    {null,"text",null,null,null,null},
                    {null,null,"Наименование","Цена","Количество","Сумма"},
                    {null,null,"клавиатура",100,2,200},
                    {null,null,"мышь",50,10,500}}),
        b = Table.AddIndexColumn(a, "i"),
        c = Table.FindText(b,"Наименование"){0}[i],
        d = Table.Range(a,c),
        e = Table.PromoteHeaders(d),
        f = Table.ColumnNames(e),
        g = List.PositionOf(f,"Наименование"),
        h = List.Range(f,g),
        k = Table.SelectColumns(e,h)
    in
        k

    Извиняюсь за многабукаф в шагах – специально расписал подробно.
    a – сама таблица – видим наличие мусора в первых двух строках, где там именно начинается шапка мы не знаем, знаем только про слово «Наименование»
    b – добавляем столбец индекса, он нам нужен для следующего шага
    c – собственно тема поста - Table.FindText ищет текст в таблице, причём работает по принципу Text.Contains -–т.е. если не уверены в регистре можно искать и «аименовани» - найдёт ))) Функция возвращает нам таблицу, состоящую из строк, содержащих данный текст. Но нам не нужна только эта строка – нам нужно найти начало шапки. Поэтому мы и добавили столбец индекса, а теперь из полученной таблицы берём первую строку {0}, а из неё номер строки [i]
    d - а теперь просто получили таблицу начиная со строки шапки (обращаю внимание – мы обратились к изначальной таблице, ДО добавления столбца индекса – он нам больше не нужен)

    ОК, лишние строки пропустили, теперь столбцы:
    e – подняли заголовки
    f – получили список заголовков
    g – нашли «Наименование» уже в именах столбцов
    h – пропустили лишние имена столбцов
    k – выбрали нужное

    Собственно, всё )))
    Если задача возникает часто – можно упаковать в функцию:
    f=(table,name)=>
        [a = Table.PromoteHeaders(Table.Range(table,Table.FindText(Table.AddIndexColumn(table, "i"),name){0}[i])),
         b = Table.ColumnNames(a),
         c = Table.SelectColumns(a,List.Range(b,List.PositionOf(b,name,Occurrence.First,Text.Contains)))][c]
    Вроде вполне симпатично и не то, чтобы сильно громоздко. Пользуйтесь!
    ]


[   Table.PositionOf – подстановка по нескольким условиям с диапазонами или когда FillDown бессилен / #АнатомияФункций - Table.PositionOf

    В чате подкинули интересную задачку – поэтому есть что обсудить.
    Сначала рассмотрим лайтовый вариант – есть таблица соответствий категорий некоторому признаку, причём подразумевается некоторый диапазон от/до. Ну и есть таблица, в которую по значению признака надо подставить категорию. Рассмотрим классический подход к решению:
        
        let
            dct = #table({"ширина","категория"},{{0,"узко"},{100,"средне"},{250,"широко"}}),
            tbl = #table({"что","ширина"},{{"стул",60},{"кресло",80},{"стол",150},{"диван",220},{"сервант",280}}),
            cmb = tbl&dct,
            srt = Table.Sort(cmb,{"ширина"}),
            fll = Table.FillDown(srt,{"категория"}),
            to  = Table.SelectRows(fll,each [что]<>null)
        in
            to

    dct – таблица с категориями, здесь для простоты оставлена только нижняя граница (т.е. ширина от…)
    tbl – таблица, куда подставляем
    cmb – объединили обе таблицы
    srt – отсортировали по нашему признаку
    fll – сделали заполнение вниз
    to – оставили только интересующие нас строки.
    Вместо ширины бывает производительность, предельное напряжение, дата производства и т.д.
    В общем поковыряйте приём – он крайне полезен.

    НО вчера было про другое – подстановка нужна по ДВУМ параметрам. И вот тут выясняется, что сортировка нам не поможет (в качестве упражнения пытливые умы могут проверить).
    Приходится искать по исходной таблице по двум параметрам. И вот тут хочу предложить воспользоваться Table.PositionOf – она аналогична List.PositionOf , просто про таблицу )))
    Поехали:

        let
            dct=#table({"длина","толщина","категория"},{{0,0,"фитинг детский"},{0,2,"фитинг"},{0,5,"фитинг усиленный"},{10,0,"патрубок учебный"},{10,2,"патрубок"},{10,8,"патрубок напорный"},{100,0,"труба китайская"},{100,5,"труба"},{100,12,"труба напорная"}}),
            tbl=#table({"что","длина","толщина"},{{"деталь1",7,1.5},{"деталь2",24,2.2},{"деталь3",80,9.9},{"деталь4",120,15},{"деталь5",140,0.8}}),
            lst=List.Buffer(dct[категория]),
            f=(x)=>lst{Table.PositionOf(dct,x,Occurrence.Last,g)},
            g=(x,y)=>x[длина]<=y[длина] and x[толщина]<=y[толщина],
            to = Table.AddColumn(tbl,"категория",f)
        in
            to

    dct, tbl – словарь и таблица соответственно
    lst – сами категории забрали в отдельный список (обращение по индексу в списке быстрее, чем к таблице)
    f – функция, обращающаяся к списку категорий по индексу. Индекс находим с помощью Table.PositionOf –берем последнюю строку, соответствующую условию (Occurrence.Last), а соответствие условию проверяем функцией g
    g – функция от двух аргументов – в данном случае это записи: x – искомая, y – запись из таблицы (т.е. конкретная строка в таблице для поиска). Само условие прописываем как сопоставление отдельных полей записей (главное не запутаться, что на первом месте - что ищем, а на втором где; ну и не забываем между условиями добавлять оператор and)
    to – а дальше просто применили нашу функцию в момент добавления столбца к таблице.

    Как-то так. Вроде вполне лаконично, а на небольших словарях – очень даже шустро. Так что пользуйтесь,
    ]

[   1C - Новая рубрика на канале / #1C - Содержание
    Дамы и господа, Вашему вниманию предлагается еще одно направление в «Танке» - обработка сохраненных файлов с отчетами из системы 1С с созданием нормализованной таблицы (таблиц).
    На скрине (см. первый комментарий) – один из примеров выгрузки данных в xlsx-формате.
    Отличительной особенностью таких отчетов в большинстве случаев является сложная иерархическая структура, которая не позволяет проводить нормальный анализ данных без предварительной обработки выгруженного файла, например: составить сводную таблицу, выгрузить информацию в модель данных для дальнейшей обработки и так далее.
    Конечно, самое простое – это попросить программиста 1С в компании – выгрузить плоскую таблицу, но не всегда это удается (то программиста нет в компании, то ума у программиста) и простой пользователь выгружает данные (зачастую несколько десятков тысяч строк) в Excel, открывает PQ и клацая мышкой создает километры шагов для того, чтобы получить более-менее нужную информацию.
    Циклом мини-статей по направлению #1C мы попробуем создать алгоритм обработки такого рода отчетов, предполагая, что правильно выстроенная последовательность операций позволит пользователю довольно быстро разобраться с выгруженными из 1С данными.
    При разборе данных будем использовать как существующие решения из Танка, так и создавать собственные.

    Планируемые мини-статьи:
    1. Анализ отчета. Убираем пустые столбцы и строки. Очищаем текст
    2. Разбираем многоуровневую шапку
    3. Разбираем категории, работаем с иерархической структурой
    4. Создаем справочники и связи
    5. Загрузка отчетов 1С из папки и обработка данных

    В финале же попробуем создать универсальную функцию, скормив которой исходный файл мы получим на выходе нормализованную таблицу.

    Прошу прокомментировать данное предложение. Имеет ли оно право на существование в Танке или же это лишнее и разбор структуры отчета из 1С не имеет никакой сложности с решением?
    ]

[   1C - Анализ отчета. Поднимаем шапку, убираем пустые столбцы и строки. Очищаем текст. / #1C - Анализ отчета.

    Всем привет. Этим постом мы начинаем серию постов по применению PQ к выгрузкам из 1C.
    Для начала мы попробуем разобрать стандартный отчет "1с". Профессионалы М, могут улыбнуться – это все им знакомо, а те, кто постигает основы – рекомендую присмотреться к данному посту )

    В большинстве случаев пользователи стараются сохранить отчеты из 1С в xls(xlsx)-формат для дальнейшей обработки данных, а не, например, в текстовый формат. Причина этого скорее всего лежит в плоскости привычки – получить сразу же на выходе какую-то таблицу в Excel.
    Что же мы получаем в таблице отчета на выходе из 1С:
    1. Шапка с фильтрами отчета (несколько строк, в которых информация чаще всего не нужна в дальнейшем)
    2. Многоуровневая шапка (разбор данного пункта будет представлен в следующей теме)
    3. Большое количество пустых столбцов
    4. Присутствие пустых строк
    5. Как бонус от 1С – частое наличие в полях непечатных символов

    Поехали, разбираться с отчетом:
    1-ый шаг: удаляем шапку отчета. Для чего воспользуемся уже готовым решением из танка:
    Table.Skip(tbl,(r)=>not Text.Contains(Text.Combine(List.Select(Record.ToList(r),(x)=>x is text)),TXT))

    tbl - таблица данных
    TXT – часть имени из шапки таблицы, до которой нужно удалить верхние строки

    2-ой шаг: удаляем непечатные символы из текста. Как вариант, воспользуемся вот таким решением:
    
        T= [txt= "#(lf)#(00A0)",k=(x)=> Text.Combine(List.RemoveMatchingItems(Text.SplitAny(Text.Clean(x), txt),{""})," "),to=Table.TransformColumns(t,{},k)][to]

    3-ий шаг: удаляем пустые столбцы. Тут так же можно воспользоваться готовым решением из танка:
        
        fnRemEmptyColumns = (tbl)=>
            [   a = List.Sort(Table.ColumnNames(tbl)),
                b = Table.Profile(tbl,{{"tmp", (x)=>true,List.NonNullCount}})[tmp],
                c = List.PositionOf(b,0,Occurrence.All),
                d = List.Transform(c,(x)=>a{x}),
                e = Table.RemoveColumns(tbl,d)
            ][e]

    Пояснение по работе кода - читаем в танке
    4-ый шаг: удаляем пустые строки. Вариант решения может быть таким:
    
        T= Table.SelectRows(cl, each not List.IsEmpty(List.RemoveMatchingItems(Record.FieldValues(_), {"", null})))
    
    Давайте попробуем объединить все вышеуказанные подходы в одну функцию:.
    
        fnClear=
            (tbl,optional shp,optional clearData, optional clearColumn, optional clearRows)=> 
            [
            tr = Table.TransformColumns(tbl,{},Text.From),
            
            t  =    if  shp is null
                    then tbl
                    else Table.Skip(tr,(r)=>not Text.Contains(Text.Combine(List.Select(Record.ToList(r),(x)=>x is text)),shp)),
            
            p  =    if clearData is null 
                    then t 
                    else [   
                        k=(x)=>if x=null then x else  Text.Combine(List.RemoveMatchingItems(Text.SplitAny(Text.Clean(x),clearData),{""})," "),
                        to = Table.TransformColumns(t,{},k)
                    ]  [to],
            
            cl =    if clearColumn is null 
                    then p 
                    else [   
                        a = List.Sort(Table.ColumnNames(p)),
                        b = Table.Profile(p,{{"tmp", (x)=>true,List.NonNullCount}})[tmp],
                        c = List.PositionOf(b,0,Occurrence.All),
                        d = List.Transform(c,(x)=>a{x}),
                        e = Table.RemoveColumns(p,d)
                    ][e],
            
            to =    if clearRows is null 
                    then cl 
                    else  Table.SelectRows(cl, each not List.IsEmpty(List.RemoveMatchingItems(Record.FieldValues(_), {"", null})))
            ][to]

    Вызов функции: 
        to=fnClear(from,"Артик","#(lf)#(00A0)",1,1) // таблица, удаление строк до указанных данных в поле, удалить непечатные, удалить пустые столбцы, удалить пустые строки
    
    Обязательным параметром является передаваемая таблица, остальные параметры – необязательные.
    К чему этот пост.
    Все решения уже так или иначе были представлены или в танке или в чате PQ. Данный пост –попытка объединить некоторые решения в одну функцию. Конечно, нюансов в выгрузках 1С большое количество, но уловив смысл построения функций – можно самостоятельно создавать решения. Попробуйте провести эксперимент и дополнить функцию опцией удаления всех полей, которые содержат в имени «Column» или же добавить опцию поднятия заголовков. Для профессионалов это все давно пройденный этап, а для нас, начинающих познавать красоту языка М, будет очередной возможностью потренироваться.
    ]

[   List.Union, List.Intersect, List.Difference или кольца Венна на списках
    ]

[   List.Union vs List.Combine / #ВесёлыеКартинки
    По итогам обсуждения вчерашней картинки - закрепляем разницу между List.Union и List.Combine, а заодно - зачем же нам List.Distinct )))
    ]

[   Text.Split vs Text.BeforeDelimiter или причём тут списки и почему на них опять быстрее / #АнатомияФункций - Text.Split, Text.BeforeDelimiter

    Всем привет!
    Небольшая зарисовка вдогонку к сегодняшнему чату.
    Итак, есть задача – вытянуть из текста фрагмент от начала до какого-то набора символов, который мы назовём «разделитель». Вроде несложно:
    
        let
            from = #table({"txt"},{{"раз"},{"раз; два"},{"раз; два; три"}}),
            f=(x)=>Text.BeforeDelimiter(x,"; "),
            to   = Table.TransformColumns(from,{"txt",f})
        in
            to

    Т.е. у нас есть специальная функция – Text.BeforeDelimiter (её мы уже разбирали тут ).
    Код вышел простой и лаконичный, обращаем внимание, что не во всех значениях встретился разделитель, и в этом случае функция вернула нам значение целиком.

    В общем всё круто, всё работает, но тогда о чём пост? Да вот, собственно, о чём:
    
        let
            from = #table({"txt"},{{"раз"},{"раз; два"},{"раз; два; три"}}),
            f=(x)=>Text.Split(x,"; "){0},
            to = Table.TransformColumns(from,{"txt",f})
        in
            to
    
    Здесь мы используем Text.Split – она возвращает список. Соответственно мы вынимаем первый элемент. Идея в том, что при наличии разделителя, первый элемент списка и будет искомым значением; а при отсутствии разделителя функция вернёт список из одного элемента (исходного значения), который мы и получим на выходе.
    Зачем такие сложности при наличии специализированной функции? Да просто так быстрее ))) Промеры будут в первом комментарии под постом – с ростом объема анализируемых данных выигрыш по скорости составляет полтора/два раза – неплохо, а?

    Предполагаю, что выигрыш возникает из-за того, что Text.BeforeDelimiter слишком умная – у неё же ещё и третий аргумент есть – требуется время на оценку, передан он или нет, наверняка ещё и счётчик вхождений вшит, а в данной конкретной ситуации нам это всё не надо – и дубовая Text.Split справляется ощутимо быстрее.
    Так что ещё раз подтверждается тезис, что не всегда специализированные функции решают задачу максимально эффективно )))
    ]

[   Table.RenameColumns – переименовываем столбцы + пачкой или зачем там ещё и третий аргумент? / #АнатомияФункций - Table.RenameColumns

    Всем привет!
    Разберём вопрос переименования столбцов – для этого у нас есть Table.RenameColumns:
    let
        from = #table({"a","b","c"},{{1,2,3}}),
        to = Table.RenameColumns(from,{"a","A"})
    in
        to
    Тут всё просто – передали список {что, на что} поменять.

    Если переименований нужно несколько – используем список списков:
    let
        from = #table({"a","b","c"},{{1,2,3}}),
        to = Table.RenameColumns(from,{{"a","A"},{"b","B"}})
    in
        to
    Тоже вроде несложно. Определённая сложность возникает, когда таких преобразований много и они у нас содержатся в отдельной таблице:
    let
        from = #table({"a","b","c"},{{1,2,3}}),
        tbl = #table({"что","на что"},{{"a","A"},{"b","B"},{"c","C"}}),
        to = Table.RenameColumns(from,Table.ToList(tbl,(x)=>x))
    in
        to
    В этой ситуации мы просто превратили таблицу в список списков через Table.ToList (да, я помню про Table.ToRows, а вы помните, что она почему-то не столь шустрая).

    Ну и наконец, зачем нам третий аргумент? Вариант первый – у вас не просто таблица переименования, а набор вариантов, которые встречаются в разных файлах:
    let
        from = #table({"a","b","c"},{{1,2,3}}),
        tbl = #table({"что","на что"},{{"a","A"},{"aa","A"},{"aaa","A"},{"b","B"},{"c","C"}}),
        to = Table.RenameColumns(from,Table.ToRows(tbl),MissingField.Ignore)
    in
        to
    Здесь мы использовали MissingField.Ignore, чтобы не вылетала ошибка на отсутствующих столбцах.
    В более специфичном варианте можно использовать MissingField.UseNull:
    let
        from = #table({"a","b","c"},{{1,2,3}}),
        tbl = #table({"что","на что"},{{"a","A"},{"b","B"},{"c","C"},{"d","D"}}),
        to = Table.RenameColumns(from,Table.ToRows(tbl),MissingField.UseNull)
    in
        to
    Здесь не просто произошло переименование, но и был добавлен недостающий столбец.

    Как-то так – третий аргумент необязателен, просто иногда упрощает программирование или жизнь )))
    ]

[   Скользящее среднее или причём тут накопленная сумма / #АнатомияФункций – приёмы

    Всем привет! Недавно в чате подняли вопрос о вычислении скользящего среднего. Исходное решение через индексы безбожно тупило, поэтому было предложено вот такое:
    
        let
            from = #table({"a"},List.Zip({{1..100000}})),
            lst  = List.Buffer(from[a]),
            m    = 10,
            n    = List.Count(lst),
            gen  = List.Generate(()=>[i=0,l={},a=List.Average(l)],
                                 (x)=>x[i]<n,
                                 (x)=>[i=x[i]+1,l=if i<m-1 then {} else List.Range(lst,i-m+1,m),a=List.Average(l)],
                                 (x)=>x[a]
                                ),
            to = Table.FromColumns(
                    Table.ToColumns(from) & {gen},
                    Table.ColumnNames(from) & {"new"}
                 )
        in
            to

    по шагам:
        from – исходная таблица
        lst  – столбец, по которому считаем среднее (не забыли про буфер)
        m    – ширина окна усреднения
        n    – число элементов в списке (засунуть в генератор можно, но так быстрее)
        gen  – генерация скользящего среднего – в записи [i – счётчик, l – список для усреднения, вычисляемый через List.Range, a – собственно среднее]
        to   – добавляем новый столбец к имеющейся таблице.

    Код логичный, отработал за приемлемое время и можно было успокоиться. Однако, спинной мозг в районе копчика напомнил, что решал я пару лет назад подобную задачу, причём совсем по-другому именно из-за проблемы быстродействия. Пришлось немножко подумать, понять, что в коде выше меня смущает практически всё и поэтому:
        
        let
            from = #table({"a"},List.Zip({{1..100000}})),
            lst  = List.Buffer(from[a]),
            m    = 10,
            n    = List.Count(lst),
            gen  = List.Generate(()=>[i=0,s=lst{i}],
                                 (x)=>x[i]<n,
                                 (x)=>[i=x[i]+1,s=x[s]+lst{i}],
                                 (x)=>x[s]),
            gen2 = List.Repeat({null},m-1)&{0}&List.RemoveLastN(gen,m),
            zip  = List.Transform(List.Zip({gen,gen2}),(x)=>(x{0}-x{1})/m),
            to   = Table.FromColumns(Table.ToColumns(from)&{zip},Table.ColumnNames(from)&{"new"})
        in
            to

    Первые четыре шага такие же
        gen  – а вот здесь не выпендриваемся и просто рассчитываем накопленную сумму – такой генератор работает существенно быстрее
        gen2 – добавляем в только что сгенерированный список null-ы и отрезаем последние m элементов
        zip  – а теперь суть – в первом генераторе мы хватали диапазон из списка и находили по нему среднее, т.е. находили сумму элементов, а потом делили на их количество, т.е. каждый элемент у нас участвовал в суммировании несколько раз. 
        Вместо этого в данном случае мы просто сдвинули накопленную сумму на m элементов вправо (или вниз – кто как воспринимает одномерные массивы), объединили исходный и полученный списки через List.Zip и нашли разницы соответствующих элементов – это и есть сумма по конкретному диапазону усреднения (М – математика))), осталось только поделить на число элементов и примотать столбец к таблице как и в первом варианте.

    Промеры в первом комментарии под постом – ускорение составляет от десятков процентов на малых объемах до порядка(!) на 100k строк. Как-то так, иногда стоит задумываться о вычислительной сложности.
    ]

[   List.Generate + Date.Add* - получаем списки дат и времён / #АнатомияФункций - List.Generate

    Всем привет!
    Сегодня в очередной раз написал в чат генератор списка времён. Видимо вопрос актуальный, поэтому разбираем:
         
        List.Generate(
            ()=>дата_начала,
            (x)=>x<=дата_окончания,
            (x)=>функция_добавления
        )
            #date(year,month,day)
            #datetime(year,month,day,hour,minute,second)
            #duration(days,hours,minutes,seconds)

        let
            y   = List.Generate(()=>#date(2021,1,1), (x)=>x<=#date(2025,12,31),(x)=>Date.AddYears(x,1)),
            q   = List.Generate(()=>#date(2021,1,11),(x)=>x<=#date(2025,12,31),(x)=>Date.AddQuarters(x,1)),
            qm  = List.Generate(()=>#date(2021,1,11),(x)=>x<=#date(2025,12,31),(x)=>Date.AddMonths(x,3)),
            m   = List.Generate(()=>#date(2021,1,1), (x)=>x<=#date(2025,12,31),(x)=>Date.AddMonths(x,1)),
            w   = List.Generate(()=>#date(2021,1,1), (x)=>x<=#date(2025,12,31),(x)=>Date.AddWeeks(x,1)),
            wd  = List.Generate(()=>#date(2021,1,1), (x)=>x<=#date(2025,12,31),(x)=>Date.AddDays(x,7)),
            d   = List.Generate(()=>#date(2021,1,1), (x)=>x<=#date(2025,12,31),(x)=>Date.AddDays(x,1)),
            d1  = List.Generate(()=>#date(2021,1,1), (x)=>x<=#date(2025,12,31),(x)=>x+#duration(1,0,0,0)),
            h   = List.Generate(()=>#datetime(2023,4,16,0,0,0),(x)=>x<=#datetime(2023,4,18,0,0,0),(x)=>x+#duration(0,1,0,0)),
            m15 = List.Generate(()=>#datetime(2023,4,16,0,0,0),(x)=>x<=#datetime(2023,4,18,0,0,0),(x)=>x+#duration(0,0,15,0))
        in
            m15

    Сначала комменты в коде – сам List.Generate мы уже разбирали тут. Принципиально ничего сложного – имеем дату/датувремя начала, на каждой итерации проверяем не превышение даты/датывремени окончания, функция добавления прибавляет к дате/датевремени нужный период.

    Сначала рассмотрим семейство Date.Add*.
        y   – Date.AddYears добавляет годы, вторым аргументом регулируем шаг в годах (мало ли, вам пятилетки нужны)
        q   – Date.AddQuarters добавляет кварталы
        qm  – Date.AddQuarters можно заменить Date.AddMonths с шагом 3 месяца
        m   – так выглядит генерация с шагом в месяц
        w   – с шагом в неделю
        wd  – Date.AddWeeks можно заменить Date.AddDays с шагом в 7 дней
        d   – ну и генерация с шагом в 1 день соответственно

    Теперь рассмотрим альтернативу:
        d1  – вместо Date.AddDays можно использовать +#duration(1,0,0,0) – т.е. добавление длительности в 1 день
    Соответственно использование #duration позволяет генерить датувремя с шагом, меньше суток:
        h   – генерим с шагом в 1 час
        m15 – шаг 15 минут

    Как видите схема генерации принципиально не меняется, главное помнить про List.Generate – он есть, и он хороший )))
    ]

[   СЧЁТЕСЛИ, СУММЕСЛИ и прочие радости на M / #АнатомияФункций – приёмы

    Всем привет! За последние пару недель уже несколько раз писал в чат один и тот же по сути код. Запрос обычно звучит «как написать СЧЁТЕСЛИ?» или «как сделать что-то вроде СУММЕСЛИ?». Ответ – «сгруппировать» как правило народ не устраивает, поскольку надо сохранить все строки. Хорошо, дадим «правильный» ответ – «сгруппировать, а потом словарь на записях» ))) Вот этот ответ и разберём:
    let
        from = #table({"A","B","C"},{{"x",1,2},{"x",3,4},{"y",5,6},{"y",7,8},{"y",9,10}}),
        f=(x)=>Table.RowCount(x),
        dict = Record.FromTable(Table.RenameColumns(Table.Group(from, "A", {"Value",f}),{"A","Name"})),
        to = Table.AddColumn(from,"New",(r)=>Record.Field(dict,r[A]))
    in
        to

    по шагам:
    from - имеем таблицу, в которой по каждой позиции из столбца А нужно получить сколько раз она встречается в таблице
    Чтобы получить агрегацию самое простое таблицу сгруппировать, поэтому
    f – пишем функцию, которая заменит СЧЁТЕСЛИ – в данном случае Table.RowCount
    и далее
    dict – осуществляем группировку, причём агрегированный столбец называем Value, а тот, по которому группировали – Name – нам это нужно, чтобы получить словарь (разбиралось тут)
    to – на последнем шаге используем словарь для добавления нового столбца

    Думаю, возник вопрос – а зачем я вообще вынес шаг f? Да мне просто лень всё переписывать целиком, у нас же тут есть варианты:
    f=(x)=>List.Sum(x[B]) // СУММЕСЛИ по столбцу В
    f=(x)=>List.Sum(x[C]) // СУММЕСЛИ по столбцу С
    f=(x)=>List.Max(x[C]) // МАКСЕСЛИ по столбцу С
    f=(x)=>List.Min(x[B]) // МИНЕСЛИ по столбцу В
    f=(x)=>List.Average(x[C]) // СРЗНАЧЕСЛИ по столбцу С
    и так далее…

    Код выходит вроде несложный, допускает доработку напильником и не только - экспериментируйте! )))
    ]

[   ЧИСТРАБДНИ на М или практическое применение List.Generate / #АнатомияФункций - List.Generate
    Всем привет!

    В продолжение прошлого поста про генерацию дат давайте обсудим вопрос генерации списка только рабочих дней, ну и соответственно реализации экселевской ЧИСТРАБДНИ (NETWORKDAYS)

    Комплексный пример выглядит так:
        
        let
            f = (ot as date, do as date, optional holidays as list) as number=>
                    [   a = List.Generate(()=>ot,(x)=>x<=do,(x)=>Date.AddDays(x,1)),
                        b = List.Select(a,(x)=>Date.DayOfWeek(x,Day.Monday)<5),
                        c = List.RemoveMatchingItems(b,holidays),
                        d = List.Count(if holidays=null then b else c)
                    ]  [d],

            hol  =  {#date(2023,2,24),#date(2023,1,2),#date(2023,1,3),#date(2023,1,4),#date(2023,1,5),#date(2023,1,6),#date(2023,1,7),#date(2023,5,8),#date(2023,2,23),#date(2023,3,8),#date(2023,5,1),#date(2023,5,9),#date(2023,6,12),#date(2023,11,6)},
            from =  #table(type table [ot=date,do=date],{{#date(2023,1,1),#date(2023,12,31)},{#date(2023,1,1),#date(2023,3,31)},{#date(2023,4,1),#date(2023,6,30)},{#date(2023,7,1),#date(2023,9,30)},{#date(2023,10,1),#date(2023,12,31)}}),
            to   =  Table.AddColumn(from,"networkdays",
                        (r) => f(r[ot], r[do], hol),
                        Int64.Type
                    )
        in
            to

    Разбираем по шагам:
        f    – функция, эквивалентная ЧИСТРАБДНИ – о ней чуть ниже
        hol  – список праздников,
        from – исходная таблица
        to   – результирующая – вроде всё прозрачно.

    Теперь сама функция f. Вводим три аргумента: 
        ot – дата начала, 
        do – дата окончания, 
        holidays – необязательный аргумент, список праздников

    Шаги внутри функции:
        a – генерация списка дней от даты начала до даты окончания – сделано через AddDays – это эффективнее, чем +#duration(1,0,0,0)
        b – выбираем только рабочие (номер дня в неделе меньше 5, считая с понедельника, напоминаю, что нумерация идёт с нуля)
        c – удаление из полученного списка праздничных дней – сделано через List.RemoveMatchingItems – это шустрее, чем List.Difference
        d – последний шаг, возвращающий число дней – обращаю внимание – идёт проверка на наличие третьего аргумента: если передан список выходных – подсчитываем список из шага c, иначе – подсчитываем список из шага b
    
    В принципе, если вам нужно именно сгенерировать список дат рабочих дней – останавливайтесь на шаге c.

    Как-то так. Код достаточно короткий и на мой вкус логичный – пользуйтесь!
    ]

[   СЖПРОБЕЛЫ, только круче, или причём тут Text.SplitAny / #АнатомияФункций - Text.SplitAny

    Всем привет!
    В продолжение сегодняшнего обсуждения в чате решим одну задачку. Итак, как видно из названия поста, нам нужно реализовать функцию СЖПРОБЕЛЫ – мы раньше уже обсуждали очистку текста , но проблема в том, что Text.Trim, Text.TrimStart и Text.TrimEnd не удаляют лишние пробелы в середине текста, а СЖПРОБЕЛЫ – удаляет. Что ж, решим эту проблему:
    let
        tbl = #table({"txt"},{{"   мама   мыла     раму"},{"   мама     #(lf)     мыла   #(tab)#(tab)#(lf)  раму"}}),
        to = Table.TransformColumns(tbl,{"txt",(x)=>Text.Combine(List.Select(Text.Split(x," "),(x)=>x<>"")," ")}),
        to1 = Table.TransformColumns(tbl,{"txt",(x)=>Text.Combine(List.Select(Text.SplitAny(x," #(00A0)#(lf)#(tab)"),(x)=>x<>"")," ")}),
        to2 = Table.TransformColumns(tbl,{"txt",(x)=>Text.Combine(List.Select(Text.SplitAny(x,""),(x)=>x<>"")," ")}),
        f = (txt,optional splitby,optional combby)=>Text.Combine(List.Select(Text.SplitAny(txt,""&(splitby??"")),(x)=>x<>""),combby??" "),
        to3 = Table.TransformColumns(tbl,{"txt",f}),
        to4 = Table.TransformColumns(tbl,{"txt",(i)=>f(i," ")}),
        to5 =Table.TransformColumns(tbl,{"txt",(i)=>f(i,null,"#(lf)")})
    in
        to5

    По шагам:
    tbl – исходная таблица с не очень чистым текстом
    to – преобразовываем текстовый столбец. Логика простая – разделяем текст по пробелу (Text.Split), при этом получаем список, два пробела подряд также будут разделены и в список попадёт "" (пустая строка), убираем пустые строки (List.Select) и собираем обратно текст через пробел (Text.Combine). Для первой строки в таблице задача решена, но вторая содержит неразрывные пробелы, табуляции, переносы строк – можно ли избавиться и от них тоже? Можно:
    to1 – просто используем Text.SplitAny, которой во втором аргументе передадим помимо пробела ещё и другие разделители
    Но сегодня выяснилось, что можно и проще:
    to2 – снова используем Text.SplitAny, просто в этот раз вторым аргументом передаём пустую строку – и в этой ситуации она сама прекрасно делит текст по пробельным символам и непечатным символам, что на мой вкус удобно
    f – ну и подытожим написанием условно универсальной функции. Обязательный аргумент txt – обрабатываемый текст, необязательные – splitby и combby – разделители по которым надо делить текст и разделитель, через который надо обратно собрать текст соответственно.
    to3 – просто используем функцию
    to4 – делим только по пробелу
    to5 – делим по пробельным и нечитаемым символам, а собираем через разрыв строки (обращаю внимание на синтаксис – второй аргумент передан как null)

    Как-то так. Вроде несложно, но пришлось пописать, зато получилась СЖПРОБЕЛЫ с блекджеком и … необязательными аргументами. Пользуйтесь!
    ]

[   ЧИСТВНДОХ на М – а почему бы и нет? / #АнатомияФункций – CustomFunctions

    Всем привет!
    В чат закинули задачку – можно ли посчитать экселевскую ЧИСТВНДОХ через PQ?
    Ну было бы нельзя, не было бы поста )))

    На вход нам подают список дат и список потоков, вычислить нужно внутреннюю ставку доходности, что в переводе на русский означает численно решить уравнение.
    Получился такой код:
    ЧИСТВНДОХ =(даты as list,потоки as list) as number =>
    [   sum=(x)=>List.Sum(List.Transform(lst,(y)=>y{1}/Number.Power(1+x,y{0}))),
        min = List.Min(даты),
        zip= List.Zip({даты,потоки}),
        lst = List.Buffer(List.Transform(zip,(x)=>{Duration.TotalDays(x{0}-min)/365,x{1}})),
        base = Number.Sign(sum(0)),
        gen=List.Generate( ()=>[i=0,a=0,b=100,p=(a+b)/2,s=sum(p),t=Number.Sign(s), f=t=base],
                            (x)=>x[i]<100 and x[b]-x[a]>0.0000001,
                            (x)=>[  i=x[i]+1,
                                    a=if x[f] then x[p] else x[a],
                                    b=if x[f] then x[b] else x[p],
                                    p=(a+b)/2,
                                    s=sum(p),
                                    t=Number.Sign(s), 
                                    f=t=base],
                            (x)=>x[p]),
        to = List.Last(gen)][to]

    Где
    sum – функция, вычисляющая сумму, которую мы должны обнулить
    min – стартовая дата
    zip, lst – получаем список для sum – по каждой дате получаем период в годах и сам поток
    base – знак исходной суммы (нам это знание нужно, чтобы ловить переход через ноль)
    gen – ну и запускаем генератор – обычный метод половинного деления (краевые значения и точность задал вручную, кому интересно может сделать параметрами или вообще вычислить)
    to – результат последней итерации и есть искомое.

    Как-то так – тут мало М, в основном численные методы.
    Кому код покажется громоздким – можно переписать на рекурсию:
    ЧИСТВНДОХ =(даты as list,потоки as list) as number =>
    [   sum=(x)=>List.Sum(List.Transform(lst,(y)=>y{1}/Number.Power(1+x,y{0}))),
        min = List.Min(даты),
        zip= List.Zip({даты,потоки}),
        lst = List.Buffer(List.Transform(zip,(x)=>{Duration.TotalDays(x{0}-min)/365,x{1}})),
        base = Number.Sign(sum(0)),
        func=(i,a,b)=> [   p=(a+b)/2, s=sum(p), t=Number.Sign(s), f=t=base,
                            out =if i<100 and (b-a)>0.0000001 
                                    then if f 
                                            then @func(i+1,p,b) 
                                            else @func(i+1,a,p) else p ][out],
        to = func(0,0,100)][to]

    Так немножко лаконичнее, суть та же, как в общем и скорость.
    Ну и пример использования:
    let
        from = #table({"Даты","Потоки"},{{#date(2019,1,1),-1090},{#date(2019,12,31),123},{#date(2020,12,31),123},{#date(2021,12,31),123},{#date(2022,12,31),123},{#date(2023,12,31),1353}}),
        to = ЧИСТВНДОХ(from[Даты],from[Потоки])
    in
        to //0.13257

    Вроде работает и даже не вешает комп, пользуйтесь!
    ]

[   ДОбыча иерархии – ковыряемся в xml через M / #АнатомияФункций – Xml.Document

    Всем привет! Несколько раз всплывал вопрос как вытащить из файла не только данные, но и уровни иерархии. Иерархия при этом может быть в виде структуры, а может быть и в виде отступов, которые непонятно как ловить (привет 1С). На самом деле нам в обоих случаях надо добраться до xml-разметки листа и получить оттуда нужную информацию. В первом комменте под постом будет пример файла (однолистовая выгрузка) с обоими вариантами, попробуем его спарсить:

    let
        unzip=Expression.Evaluate(Text.FromBinary(Web.Contents("https://raw.githubusercontent.com/buchlotnik/buchlotnik_functions/main/UnZip.pq")),#shared),
        bin = Binary.Buffer(File.Contents("C:\Users\User\Downloads\Структура Item_.xlsx")),
        sh=Excel.Workbook(bin,false){0}[Data],
        xml=Xml.Document(unzip(bin){[FileName="xl/worksheets/sheet1.xml"]}[Content]){0}[Value]{[Name="sheetData"]}[Value],
        f=(x)=>x{[Name="outlineLevel"]}?[Value]?,
        g=(x)=> x{0}[Attributes]{[Name="s"]}?[Value]?,
        tr=Table.TransformColumns(xml,{{"Attributes",f},{"Value",g}}),
        lst=List.Sort(List.Distinct(tr[Value]),(x)=>Number.From(x)),
        dict=Record.FromList(List.Positions(lst),lst),
        tr1=Table.TransformColumns(tr,{"Value",(x)=>Record.Field(dict,x)}),
        lst1=Table.ToList(tr1,(x)=>List.LastN(x,2)),
        lst2=Table.ToList(sh,(x)=>x),
        to=Table.FromList(List.Zip({lst2,lst1}),List.Combine,Table.ColumnNames(sh)&{"величина отступа","уровень иерархии"})
    in
        to

    По шагам:
    unzip – тащим функцию-разархиватор с моего гитхаба (принцип описан здесь, а если хотите держать функцию у себя – заберите её тут)
    bin – подключаемся к бинарному содержимому файла и помещаем его в буфер. Суть в том, что нам нужно обратиться к нему дважды – отдельно за данными, отдельно – за иерархией
    sh – получили данные с листа традиционным способом
    xml – получили данные о том же листе, но через разметку., конкретно sheetdata – обратите внимание, что это таблица, содержащая информацию о строках – содержимое и атрибуты.

    Теперь напишем две функции :
    f – получает информацию об outlineLevel – это и есть уровень строки в иерархии, если она определена структурой
    g – а здесь посложнее, дело в том, что 1С-ые отступы являются атрибутом не строки, а отдельной ячейки. В данном случае мы обращаемся к свойствам первого столбца конкретной строки и забираем оттуда s – величину отступа (если нужен не первый столбец заменяем {0} на другую нужную позицию)
    tr – ну и применяем, функцию f к атрибутам строки, а функцию g – к значениям строки – на выходе имеем таблицу с соответствующей построчной информацией.

    Следующие три шага не являются обязательными, но позволяют превратить величину отступа в уровень иерархии
    lst – получили список уникальных значений и отсортировали по возрастанию
    dict – собрали из него словарь
    tr1 – заменили отступы на уровни через словарь

    lst1, lst2, to - дело осталось за малым – данные и информацию об иерархии надо объединить - в данном случае сделано на списках через построчный zip

    Как-то так. Пример учебный, поэтому мы добыли сразу оба варианта, в реальной жизни вы можете оставить только нужный вам. В любом случае это очень мало несложного кода. Поэтому не бойтесь xml-разметки, к ней просто надо немножко привыкнуть, а потом заставить приносить пользу.
    ]

[   ДОбыча иерархии 2 – боремся с пустыми строками / #АнатомияФункций – Xml.Document

    Всем привет! В предыдущем посте мы рассмотрели подход к чтению интересующей нас информации из xml-разметки файла. При этом возможно 2 проблемы:
    1 – у любого листа есть его dimension (в xml этот параметр называется именно так) – область, в которой, по мнению Excel, находятся данные (в первом каменте пример – данные начинаются с D5, хотя здоровому человеку очевидно, что с D6) – при обращении к листу pq загружает именно эту область
    2 – в данных возможны пустые строки, соответственно информация о них в разметке не хранится

    Что ж, на примере вытаскивания структуры решим и эти проблемы:
    let
        unzip=Expression.Evaluate(Text.FromBinary(Web.Contents("https://raw.githubusercontent.com/buchlotnik/buchlotnik_functions/main/UnZip.pq")),#shared),
        bin = Binary.Buffer(File.Contents("C:\Users\muzyk\Desktop\Структура Item_trouble.xlsx")),
        xml=Xml.Document(unzip(bin){[FileName="xl/worksheets/sheet1.xml"]}[Content]){0}[Value]{[Name="sheetData"]}[Value][Attributes],
        val=List.Transform(xml,(x)=>x{[Name="outlineLevel"]}?[Value]?),
        nms=List.Transform(xml,(x)=>x{[Name="r"]}?[Value]?),
        dict=Record.FromList(val,nms),
        sh = Excel.Workbook(bin,false){0}[Data],
        add = Table.AddIndexColumn(sh, "Уровень", Number.From(nms{0}),1),
        to=Table.TransformColumns(add,{"Уровень",(x)=>Record.FieldOrDefault(dict,Text.From(x))})
    in
        to

    По шагам:
    unzip, bin – всё как в прошлый раз
    xml – поскольку вынимаем только структуру, сразу загружаем таблицу Attributes для каждой строки
    val – получаем для каждой строки значение её outlineLevel
    nms – получаем для каждой строки её номер (посмотрите на этот шаг при парсинге файла-примера – можете убедиться, что нумерация не сквозная)
    dict – соберем из номеров и уровней словарь на записях
    sh – как и в прошлый раз получаем данные первого листа
    add – а вот пересборку делаем по-другому – а именно – добавляем столбец индекса, но не с 1, а с первой строки в dimension
    to – подцепляем данные из словаря через Record.FieldOrDefault, поскольку не обо всех строках у нас имеется информация

    Собственно, всё. Принцип не поменялся – получаем данные и информацию из разметки, просто пришлось немного по-другому собрать их воедино.
    ]

[   Качаем отфильтрованные таблицы из файлов xlsx / #АнатомияФункций – Xml.Document

    Всем привет!
    Что-то уже несколько раз всплывал вопрос получения отфильтрованной таблицы из экселевского файла.
    Общее замечание – при обращении к файлу он читается целиком, поэтому сократить время загрузки не получится, но получить на выходе данные только из отфильтрованных строк можно, для этого мы снова полезем в xml-разметку.

    В этот раз напишем функцию для обработки файла:
    
        (bin)=>
            let
                bin = Binary.Buffer(bin),
                xml = Xml.Document(unzip(bin){[FileName="xl/worksheets/sheet1.xml"]}[Content]){0}[Value]{[Name="sheetData"]}[Value][Attributes],
                val = List.Transform(xml,(x)=>x{[Name="hidden"]}?[Value]?),
                nms = List.Transform(xml,(x)=>x{[Name="r"]}?[Value]?),
                dic = Record.FromList(val,nms),
                sh  = Excel.Workbook(bin,false){0}[Data],
                add = Table.AddIndexColumn(sh, "tmp", Number.From(nms{0}),1),
                tbl = Table.TransformColumns(add,{"tmp",(x)=>Record.FieldOrDefault(dic,Text.From(x))}),
                flt = Table.SelectRows(tbl, each ([tmp] = null)),
                to  = Table.RemoveColumns(flt,{"tmp"})
            in
                to

    Собственно, мы по большей части это разбирали тут и тут
    bin – забуферили бинарное содержимое (мы его читаем дважды)
    xml – получили данные в виде списка об атрибутах строк
    val – получили информацию о свойстве hidden
    nms – получили данные о номере строки
    dict – собрали словарь
    sh – теперь из бинарного содержимого получили данные с самого листа
    add – добавили временный столбец индекса (не забыли учесть, что нумерация может быть не с единицы)
    tbl – применили словарь к нашему столбцу индекса, т.е. заменили номера строк на информацию скрыта строка или нет
    filtr – оставили только нескрытые строки
    to – удалили временный столбец

    Применяя такую функцию к бинарному содержимому файла мы на выходе получаем только отфильтрованные данные (подразумевается, что в файле один лист).
    В первом комментарии под постом архив с сегодняшним кейсом из чата – необходимо получить отфильтрованные данные из папки с файлами и на их основании получить обновлённую таблицу. В данном случае получена новая таблица, но в общем виде можно и исходную обновить – это мы уже тоже разбирали тут.

    Как-то так. Ковыряйте xml – там много полезного, причём не только в экселевских файлах.
    ]

[   ListInterpolate – заполняем пропуски в списках с помощью List.Generate / #АнатомияФункций – CustomFunctions

    Всем привет!
    Последнее время несколько раз всплывала задача интерполяции значений: на входе имеем таблицу с пропусками по столбцу, которые необходимо заполнить, но не с помощью FillDown или замены null на среднее, а именно арифметической прогрессией, то есть вот такое:
        
        {2,null,6,8,9,null,7,null,null,1}

    должно превратиться в
        
        {2,4,6,8,9,8,7,5,3,1}

    Т.е. число пропусков может быть переменным, шаг тоже и вот «надо как-то решить».

    Начнём с интерполяции одного списка. Для этого соорудил функцию ListInterpolate:
    
        (lst)=>
            [   lst = List.Buffer(lst),
                n   = List.Count(lst),
                int = (x,y,z)=>List.Transform({1..x},(i)=>y+i*(z-y)/x),
                gen = List.Generate(
                        ()=>[i=0,l=lst{i},m=0,s=l,o={l}],
                        (x)=>x[i]<n,
                        (x)=>[  i = x[i]+1,l=lst{i},
                                m = if l=null then x[m]+1 else 0,
                                s = if l=null then x[s] else l,
                                o = if l=null then null else if x[m]>0 then int(x[m]+1,x[s],s) else {l}],
                        (x)=>x[o]),
                to  = List.Combine(List.RemoveNulls(gen))
            ]  [to]

    Функция принимает в качестве аргумента список.
    Далее разбираем по шагам:
        lst – забуферили исходный список
        n   – нашли число его элементов – это потребуется для генерации
        int – функция интерполяции, принимает три аргумента:
        x   – число генерируемых элементов,
        y   – от какого числа ,
        z   – до какого (включительно);
    
    здесь получаем элементы простой арифметикой
        gen – а вот теперь генератор. Здесь оперируем записью с пятью полями:
        i   – счётчик элементов анализируемого списка,
        l   – i-ый элемент анализируемого списка,
        m   – счётчик элементов для генерации,
        s   – последнее не null-овое числовое значение,
        o   – список, который отдаём в качестве результата генерации.

    Принцип работы: проходим по всем элементам списка, на каждой итерации проверяем, не встретился ли нам null, если встретился – запускаем счётчик m и считаем число элементов, которые надо заполнить, всё это время в качестве результата отдаём null, как только возникает очередной не null – генерим список и обнуляем счётчик

    to – очищаем полученный в ходе генерации список от null, объединяем полученные списки.

    Ну и проверяем:
        
        ListInterpolate({1,null,3,4,null,null,7,null,9}) // {1,2,3,4,5,6,7,8,9}
        ListInterpolate({1,2,null,2,null,2,1})           // {1,2,2,2,2,2,1}
        ListInterpolate({-1,null,1,null,-1})             // {-1,0,1,0,-1}

    Работает, как и задумывалось )))
    Собственно, всё. Функцию можно брать в работу, ну а если возникнут затруднения с применением – в следующий раз разберём как с её помощью пачкой заполнить несколько столбцов в таблице.
    ]

[   TableInterpolate – заполняем пропуски, но уже в таблице и пачкой / #АнатомияФункций - CustomFunctions

    Всем привет!
    В прошлый раз мы написали функцию ListInterpolate, которая позволила заполнить пропуски в списке с помощью прогрессии. Другое дело, что обычно пропуски встречаются в табличных данных (встречались данные со счётчиков электроэнергии, пробег автомобиля, вырабатываемая мощность агрегатов, даже биржевые котировки))), и требуется заполнение нескольких столбцов. По этому поводу напишем TableInterpolate:

        (tbl,lst)=>
            let
                nms = List.Buffer(Table.ColumnNames(tbl)),
                
                tr  = List.Transform(lst,(x)=>List.PositionOf(nms,x)),
                col = List.Buffer(Table.ToColumns(tbl)),
                f=(x,y)=>List.ReplaceRange(x,y,1,{ListInterpolate(x{y})}),
                acc = List.Accumulate(tr,col,f),
                
                to  = Table.FromColumns(acc,Value.Type(tbl))
            in
                to

    Функция принимает на вход два аргумента:
    tbl – исходная таблица,
    lst – список столбцов для преобразования.

    Разбираем по шагам:
    nms – получили список названий столбцов исходной таблицы,
    tr  – список названий столбцов для преобразования превращаем в список их позиций в таблице
    col – саму таблицу преобразуем в список списков по столбцам
    f   – ну и напишем функцию для аккумулятора – она заменяет конкретный элемент списка (по индексу) им же, но с применённой ListInterpolate
    acc – а теперь собираем все вышенаписанные шаги в аккумуляторе: идем по списку интересующих нас номеров столбцов и применяем к ним интерполятор
    to  – осталось только собрать таблицу обратно (обратите внимание на последний аргумент – данные о типах столбцов получаем из исходной таблицы, т.е. информация не будет потеряна).

    Ну и как это применять:
    let
        tbl = #table(type table [a=date,b=number,c=text,d=number,e=text,f=number],
            {{#date(2023,1,1),1,"мама",1,"папа",1},
            {#date(2023,1,2),null,"мыла",null,"пил",null},
            {#date(2023,1,3),null,"раму",3,"пиво",null},
            {#date(2023,1,4),3,"мама",null,"папа",null},
            {#date(2023,1,5),null,"мыла",null,"пил",3},
            {#date(2023,1,6),5,"раму",5,"пиво",5}}),
        lst = Table.ColumnsOfType(tbl,{type number}),
        to = TableInterpolate(tbl,lst)
    in 
        to
    В данном случае
    tbl – исходная таблица
    lst – нужные столбцы – здесь я просто взял все числовые; вы же можете написать список руками или, например, использовать List.Select
    to – применяем функцию

    Как-то так – пара несложных функций и решена вполне себе заковыристая задача. Пользуйтесь!
    ]

[   Table.Sort – используем второй аргумент по максимуму / #АнатомияФункций – Table.Sort

    Всем привет!
    Всплыл в чате вопрос про сортировку таблицы. Ежу понятно, что нужно использовать Table.Sort. Заглянем в справку:
    Table.Sort(table as table, comparisonCriteria as any) as table

    Второй аргумент имеет тип any, а значит нас ждёт что-то интересное.
    В целом мы уже разбирали вопрос сортировки списка и выяснили, что во второй аргумент можно запихивать функцию. Но то было про списки, а тут таблица. С другой стороны, мы разбирали Table.Max - и там тоже выясняли, как использовать функцию во втором аргументе.
    Короче, как в одном анекдоте: «у бабочек и цветочков происходит примерно то же самое»:

    let 
        from = #table(type table [t=text,d=date,n=number],{{"A-001-2023",#date(2023,1,1),80},{"B-002-2023",#date(2023,1,2),88},{"A-003-2023",#date(2023,1,1),52},{"B-001-2023",#date(2023,1,2),99},{"A-002-2023",#date(2023,1,1),88},{"B-003-2023",#date(2023,1,2),80}}),
        to0 = Table.Sort(from,"d"),
        to1 = Table.Sort(from,{"d",Order.Descending}),
        to2 = Table.Sort(from,{"d","n"}),
        to3 = Table.Sort(from,{"n","d"}), 
        to4 = Table.Sort(from,{"d",{"n",Order.Descending}}),
        to5 = Table.Sort(from,(x)=>x[t]),
        to6 = Table.Sort(from,(x)=>Number.From(Text.Split(x[t],"-"){1})),
        to7 = Table.Sort(from,{(x)=>Number.From(Text.Split(x[t],"-"){1}),"d"}),
        to8 = Table.Sort(from,{{(x)=>Number.From(Text.Split(x[t],"-"){1}),Order.Descending},"d"})
    in 
        to8

    По шагам:
    from – исходная таблица
    to0 – простая сортировка по столбцу d, порядок сортировки по умолчанию, т.е. по возрастанию
    to1 – то же самое, но по убыванию – обращаем внимание, что теперь мы передаём список {название_столбца,порядок_сортировки}
    to2 – сортировать можно по нескольким столбцам, в данном случае сначала по столбцу d, потом по столбцу n
    to3 – обращаю внимание – порядок перечисления имеет значение, в данном случае сортировка сначала по столбцу n, а потом по d
    to4 – ну и при сортировке по нескольким столбцам также можно задать порядок – в данном случае сначала по d по возрастанию, а затем по n по убыванию – не запутайтесь в фигурных скобках )))

    Ну ОК, всё вышеизложенное и так было в справке, а вот чего там нет:
    to5 – вместо названия столбца пишем функцию (мы же помним, что одно из представлений таблиц – это список записей), сортируем по полю t. Оно работает
    to6 – ну и раз работает, значит можно немножко усложнить функцию – отсортируем не по префиксу в номере документа, а по самому номеру
    to7 – функция вместо названия столбца точно также может быть скомбинирована с другими условиями сортировки
    to8 – и точно также можно заодно задать порядок сортировки, в данном случае из строкового значения в столбце t вынимается номер документа и сортировка по убыванию, а затем по столбцу d по возрастанию

    Можно, конечно, не городить огород, разбить один столбец на несколько, потом отсортировать, потом удалить лишний столбец, но с функцией оно бывает проще и изящнее. Пользуйтесь!
    ]

[   Table.SelectRows + Record.FieldOrDefault или снова словари на записях / #АнатомияФункций - Record.FieldOrDefault

    Всем привет!
    Уже несколько раз всплывал вопрос фильтрации таблицы по списку значений. Пожалуй, стоит дать развернутый комментарий. Сразу немножко кода, а потом разберём:
    let
        from = #table(type table [a=text,b=number,c=number],{{"a",1,1},{"b",2,2},{"c",3,3},{"d",4,4},{"e",5,5},{"f",6,6},{"g",7,7}}),
        lst={"a","c","e","g"},
        to = Table.SelectRows(from,(x)=>List.Contains(lst,x[a])),
        tbl = Table.FromList(lst,(x)=>{x},{"a"}), 
        to1 = Table.Join(from,"a",tbl,"a"),
        dict = Record.FromList(List.Repeat({true},List.Count(lst)),lst),
        to2 = Table.SelectRows(from,(x)=>Record.FieldOrDefault(dict,x[a],false))
    in
        to2

    Итак, имеем:
    from – фильтруемая таблица,
    lst – список искомых значений
    to – классическое решение через List.Contains, на котором можно было бы и закончить пост… НО, хорошо, если список действительно состоит из буквально нескольких значений, а встречаются варианты, когда имеется список контрагентов из нескольких десятков позиций, или список пользователей на несколько сотен или вообще одна таблица в десятки или сотни тысяч строк фильтруется по другой таблице в десятки или сотни тысяч строк – и вот тут List.Contains начинает «тупить».

    Попробуем найти альтернативу:
    tbl – соберём из списка таблицу в один столбец, причём название столбца должно совпадать с названием столбца в фильтруемой таблице (если у вас сразу на входе нужная таблица – просто радуемся, а так возможно потребуется Table.RenameColumns)
    to1 – а теперь делаем Table.Join – поскольку имена столбцов совпадали, ничего лишнего в таблицу не добавилось, пятый аргумент не указан, поэтому по умолчанию JoinKind.Inner, т.е. только совпадающие строки из обеих таблиц, короче сразу получили отфильтрованную таблицу, вообще без лишних телодвижений. В первом комментарии будут промеры – это реально шустрый вариант

    Ну а вишенкой на торте буде вариант, заявленный в теме поста – словари на записях )))
    dict – превратим наш список в запись, где интересующие нас значения – названия полей, а в самих полях напишем просто true
    to2 – ну и теперь фильтруем через Record.FieldOrDefault, где дефолтом будет false – логика простая – если в записи есть соответствующее поле – сохраняем строку, иначе – выкидываем. На больших массивах данный вариант показывает наилучшие результаты.

    Как-то так – с маленьким списком можно выбирать любой вариант по вкусу или иным эстетическим соображениям, но на больших массивах стоит задуматься об эффективности.
    ]


[   Table.ReplaceValue или самая гибкая функция / #АнатомияФункций - Table.ReplaceValue

    Всем привет!
    За последнее время несколько раз всплывал вопрос по Table.ReplaceValue.
    Редко ей пользуюсь, поскольку она немножко совсем не шустрая, и в общем-то задачи могут быть решены другими способами.
    Но, с другой стороны, функция гибкая, немножко нестандартная и может представлять интерес для любителей пользовательских функций в аргументах )))

    Итак, справка гласит:

    Table.ReplaceValue(table as table, oldValue as any, newValue as any, replacer as function, columnsToSearch as list)

    table    – в какой таблице,
    oldValue – какое значение,
    newValue – на какое значение,
    replacer – с помощью какой функции,
    columnsToSearch – в каких столбцах меняем

    Ну поехали:
    let
        from = Table.FromRecords({[a=1,b=1,c="по",d="топот",e=null],[a=2,b=null,c="го",d="загород",e="ф"],[a=3,b=null,c="да",d="дар",e=null],[a=4,b=2,c="хо",d="хорь",e=null],[a=5,b=null,c="ро",d="роща",e="ы"],[a=6,b=null,c="ша",d="шапка",e=null],[a=7,b=3,c="се",d="север",e=null],[a=8,b=null,c="год",d="годнота",e="в"],[a=9,b=null,c="ня",d="няша",e=null]}),
        to1 = Table.ReplaceValue(from,null,0,Replacer.ReplaceValue,{"b","e"}),
        to2 = Table.ReplaceValue(from,null,each if [e] is text then 0 else [a],Replacer.ReplaceValue,{"b"}),
        to3 = Table.ReplaceValue(from,"о","@",Replacer.ReplaceText,{"d"}),
        to4 = Table.ReplaceValue(from,each [c],"@",Replacer.ReplaceText,{"d"}),
        to5 = Table.ReplaceValue(from,each [a],each [b],(x,y,z)=>[x=x,y=y,z=z],{"d"}),
        to6 = Table.ReplaceValue(from,null,null,(x,y,z)=>if x is text then "здесь был текст" else x,Table.ColumnNames(from)),
        to7 = Table.ReplaceValue(from,each [b],null,(x,y,z)=>if y<>null then "-" else x,Table.ColumnNames(from)),
        to8 = Table.ReplaceValue(from,null,each [b],(x,y,z)=>if z<>null then "-" else x,Table.ColumnNames(from)),
        to9 = Table.ReplaceValue(from,each [a],each [b],(x,y,z)=>if y=z then "-" else x,Table.ColumnNames(from)),
        to10 = Table.ReplaceValue(from,(x)=>x,(x)=>x,(x,y,z)=>[x=x,y=y,z=z],Table.ColumnNames(from))
    in
        to10

    from – входные данные
    to1  – простая замена null на 0 по столбцам b и e, Replacer.ReplaceValue говорит, что меняем значение целиком
    to2  – усложняем – в newValue можно прописать условие, в данном случае меняем null на 0 только если в столбце «e» содержится текст
    to3  – другой вариант замены – Replacer.ReplaceText, т.е. замена в тексте, в данном случае меняем «о» на «@» в столбце «d»
    to4  – oldValue также не обязано быть фиксированным – в данном случае производим замену в столбце «d», но в качестве oldValue берем текст из столбца «c»

    Промежуточный итог – oldValue и newValue могут быть представлены фиксированным значением, значением из конкретного столбца и даже более сложным условием.

    А что же с Replacer-ом? И вот тут самое интересное:
    to5 – во-первых, это функция от трёх аргументов ("в каком значении", "что","на что меняем") – для наглядности вывел в виде записи передаваемые аргументы
    to6 – и собственно говоря, теперь творим всякое – в данном случае вообще не переданы oldValue и newValue, поскольку мы просто проверяем является ли значение текстом, причём сразу по всем столбцам
    to7 – а так мы ставим прочерки во всех столбцах, если столбец «b» не null
    to8 – почти то же самое, просто значение из столбца «b» передали не во второй, а в третий аргумент – я же говорил, что функция гибкая )))
    to9 – ну а вот так можно задать условие по двум столбцам, передав их значения в два аргумента
    to10 – ну и на закуску – все предыдущие варианты я написал через each, хотя внимательные читатели помнят, что это всего лишь синтаксический сахар для (x)=>x. Т.е. на самом деле и во второй, и в третий аргумент можно передать всю строку целиком в виде записи – соответственно, можно написать любую функцию от любого набора столбцов, а пятый аргумент обеспечит нас значением из конкретной ячейки и наши возможности ограничиваются только фантазией.

    Как-то так – крайне гибкая функция, но платой за гибкость является не самая высокая скорость.
    ]

[   Производственный календарь 2 / #АнатомияФункций – CustomFunctions

    Подкинули повод спарсить производственный календарь с Консультанта. Тема уже поднималась Лёхой, но код не был выложен в силу громоздкости.
    Подумал, что надо бы исправить ситуацию )))

    Посему функция consultant:
    (optional year as nullable number) =>
    [path = "http://www.consultant.ru/law/ref/calendar/proizvodstvennye/",
        yr = year??Date.Year(DateTime.LocalNow()), 
        from = Text.FromBinary(Web.Contents(path&Text.From(yr)&(if yr = 2020 then "b" else ""))),
        splt = List.Skip(Text.Split(from,"#(tab,tab,tab)<td class=")),
        lst=List.Zip({{1..12},splt}),
        f=(x)=>[a=Text.Split(x{1},"<td class="),
                b=List.Select(a,(x)=>not Text.Contains(x,"inactively")),
                c=List.Transform(b,(x)=>List.Range(Text.SplitAny(x,"><"),0,2))][c],
        g=(x,y)=>{#date(yr,x{0},Number.From(y{1})),Text.Remove(y{0},"""")},
        tr=List.TransformMany(lst,f,g),
        tbl=Table.FromList(tr,(x)=>x,type table [Date=date,DateType=text])][tbl]


    ()=> Обращаем внимание – функция без обязательных аргументов
    path – откуда тащим
    yr – год, за который нужен календарь - если аргумент не передан – берём текущий год (у кого не работает ?? меняем выражение на if year is null then Date.Year(DateTime.LocalNow()) else year)
    from – тащим информацию с сайта. Есть нюанс – 2020 был непростым годом, поэтому тогда календарь перезаливали и он получил адресацию 2020b, что собственно здесь и учитывается. В данном случае просто получаем текст со страницы
    split – хитро делим текст – помесячные блоки отбиваются тройным табом – обращаю внимание как это записано, ну и первый кусок (до помесячных) отбрасываем
    lst – соединяем блоки текста с номерами месяцев через List.Zip
    tr – немножко перескочим – полученный список отправляем в List.TransformMany, для которой нам нужны две функции:
    f – делит текстовый блок по "<td class=", оставляет фрагменты без "inactively" (у них на сайте месячные блоки стандартные 7 на 6, и так обозначены пустые), и их сплитуем по ">" и "<", оставив первые два фрагмента – статус и номер дня соответственно
    g – собираем из полученного дату и статус даты без лишних кавычек

    tbl – из полученного списка получаем таблицу, сразу задав типизацию
    Как бы всё)))

    Как этим пользоваться:
    consultant() // календарь на текущий год
    consultant(2024) //календарь на конкретный год
    Table.Combine(List.Transform({2010..2024},consultant)) //календарь за период лет
    ]

[   Table.TransformColumnTypes 1 – //! определяем типы данных в столбцах пачкой без привязки к именам / #АнатомияФункций - Table.TransformColumnTypes

    Всем привет!
    Очередной раз всплыл вопрос про типизацию столбцов. Кто не в курсе напомню суть проблемы – можно выставить в настройках, чтобы типы определялись при загрузке таблицы автоматически, можно уже после загрузки таблицы в интерфейсе нажать кнопку «Определить тип данных» - и всё будет замечательно… НО! На самом деле в ходе данной операции PQ создаёт шаг, использующий функцию Table.TransformColumnTypes и во втором аргументе оказывается фиксированный список столбцов с типами. Соответственно, если в дальнейшем в таблицу будут добавляться столбцы – они просто не будут типизироваться, а если какой-то столбец будет переименован или удалён, то вообще вылезет ошибка.

    Посему задача – уйти от фиксированного списка и соорудить всё кодом. Поехали:
        
        let
            from = #table({"a".."e"},{{123,"мама",12.34,#date(2023,1,1),#time(1,2,3)},{234,"мыла",23.45,#date(2023,2,2),#time(2,3,4)},{345,"раму",34.56,#date(2023,3,3),#time(3,4,5)}}),
            lst = List.Transform(Record.FieldValues(from{0}),Value.Type),
            tr = List.Zip({Table.ColumnNames(from),lst}),
            to = Table.TransformColumnTypes(from,tr)
        in
            to

    from – в простейшем варианте у нас красивая табличка без пропусков
    lst  – поэтому берем первую стоку, преобразуем её в список значений, определяем их типы
    tr   – соединяем названия столбцов с полученными типами через List.Zip
    to   – преобразуем столбцы

    Правда, если б всё было так просто, не было бы поста… В данных могут быть пропуски:

        let
            from = #table({"a".."e"},{{123,null,12.34,#date(2023,1,1),null},{null,"мыла",null,#date(2023,2,2),#time(2,3,4)},{345,"раму",34.56,null,#time(3,4,5)}}),
            lst=List.Transform(Table.ToColumns(Table.Range(from,0,10)),f),
            f=(x)=>List.Mode(List.Transform(List.RemoveNulls(x),Value.Type)),

            tr = List.Zip({Table.ColumnNames(from),lst}),
            to = Table.TransformColumnTypes(from,tr)
        in
            to

    from – уже менее красивая табличка
    lst  – поэтому мы не можем опираться на первую строку, а берем несколько, в данном случае 10 (стандартно интерфейс работает с первой 1000), разбиваем таблицу на списки по столбцам и к каждому полученному списку применяем функцию f
    f    – функция удаляет null-ы, определяет тип оставшихся значений и берёт наиболее часто встречающийся (List.Mode)
    tr и to – аналогично первому случаю – собрали список преобразований и применили.

    Вуаля, задача решена!

    Правда если бы она была решена полностью в названии поста не было бы номера 1…
    Потому что на самом деле у нас ещё остаются – определение целые или дробные числа у нас в столбце, датавремя или дата, даты/время/датавремя в виде текста (привет 1С) и т.п. И этим мы займемся в следующем посте )))
    ]

[   List.Generate, накопленная сумма, списки, записи и какие-то метаданные / #АнатомияФункций – List.Generate

    Всем привет!
    В своё время мы уже разбирали использование List.Generate и считали накопленную сумму.
    Стандартный расчёт выглядит так (описание работы смотрим по ссылке):
    
        let
            lst =   List.Buffer({1..250000}),
            n   =   List.Count(lst),
            gen =   List.Generate(
                        ()=>[i=0,s=lst{i}],
                        (x)=>x[i]<n,
                        (x)=>[i=x[i]+1,s=x[s]+lst{i}],
                        (x)=>x[s]
                    )
        in
            gen

    И тут был задан вопрос – а обязательно ли использовать запись (record) при вычислении?
    Ну вообще-то необязательно, давайте примотаем списки:
    
        let
            lst =   List.Buffer({1..250000}),
            n   =   List.Count(lst),
            gen =   List.Generate(
                        ()=>{0,lst{0}},
                        (x)=>x{0}<n,
                        (x)=>{x{0}+1,x{1}+lst{x{0}+1}},
                        (x)=>x{1}
                    )
        in
            gen

    т.е. вместо записи через вычисления тащим список из двух значений, приходится дважды вычислять счётчик, но в целом это работает.

    Однако, пока писал ответ, возникла другая мысль – а давайте примотаем метаданные:
    
        let lst =   List.Buffer({1..250000}),
            n   =   List.Count(lst),
            gen =   List.Generate(()=>0 meta [s=lst{0}],
                                  (x)=>x<n,
                                  (x)=>Value.ReplaceMetadata(x+1, [s = Value.Metadata(x)[s]+lst{x+1}]),
                                  (x)=>Value.Metadata(x)[s])
        in  gen

    т.е. вместо списка значений запихиваем накопленную сумму в метаданные нашего значения, при этом приходится использовать Value.Metadata и Value.ReplaceMetadata, что делает код несколько громоздким, зато см. промеры по скорости в первом комментарии под постом – это вполне себе шустро.

    Поэтому делаем выводы: накопленная сумма – это тот случай, когда НА ЗАПИСЯХ быстрее, а вариант с метаданными, пусть чуть медленнее, зато весьма экзотичен.
    Решайте задачи разными путями – это бывает интересно 😉
    ]

[   1С.Разбираем многоуровневую шапку /  #1C - шапка 
    
    Многоуровневые шапки таблиц, выгруженных из 1С никогда не добавляют счастья (Примеры таких таблиц найдете в Первом комментарии к посту.)
    Зачастую пользователь начинает «руками» исправлять шапку таблицы, чтобы привести ее в удобную форму для дальнейшей работы.
    Со своей стороны предложим несколько способов в помощь:

    1. Для простой многоуровневой шапки таблицы, когда заполнены все заголовки полей (см. Пример1 в приложении) на просторах интернета можно увидеть такое:
        
        from     = ИсточникДанных,
        t        = Table.Transpose(from),
        mergecol = Table.CombineColumns(t,{"Column1", "Column2"},Combiner.CombineTextByDelimiter(".", QuoteStyle.None),"Headers"),
        tr       = Table.Transpose(mergecol),
        to       = Table.PromoteHeaders(tr)

    Коротко про подход: 
        - транспонируем таблицу, 
        - комбайним через разделитель, 
        - снова транспонируем и поднимаем заголовки. 
        - далее таблицу можно свернуть для работы со сводной: Table.UnpivotOtherColumns ()

    2. Для шапки, в которой заполнены не все поля (см. Пример 2) можно воспользоваться следующим кодом:
        
        from = ИсточникДанных,
        lst  = Table.ToColumns(Table.Range(from,0,2)),    
        newl = Table.ToList(Table.FillDown(Table.FromList(lst,(x)=>x),{"Column1"}),(x)=>x),    
        tr   = List.Transform(newl,(x)=>Text.Combine(x,".")),    
        to   = Table.RenameColumns(Table.Range(from,2),List.Zip({Table.ColumnNames(from),tr}))

    Подход так же не сложный: 
        - «откусили» шапку, 
        - преобразовали 
        - приставили заново к телу таблицы

    Но что если уровней в таблице три и более или структура шапки похожа на таблицу в Примере 3 ?

    3. На помощь может прийти решение, которое в большинстве случаев преобразует шапку таблицы в «плоский» формат:
    
    fnParseHead=
        (table,num,optional delim,optional fill)=>
        
        [   lst   = List.Buffer(Table.ToColumns(Table.Range(table,0,num))), 
            delim = if delim=null then " " else delim,
            
            f=(x,y)=>List.Accumulate(   
                        List.Zip({x,y}),
                        [i=false,j={}],
                        (s,c)=>[ i = s[i]=true or c{0}<>null,
                                 j = if i 
                                     then s[j] & {c{0}} 
                                     else s[j] & {c{0}??c{1}}]
                     )[j],
            
            g=(x)=> if fill=null 
                    then Text.Combine(x,delim) 
                    else Text.Combine(List.ReplaceValue(x,null,fill,Replacer.ReplaceValue),delim), 

            gen =   List.Generate(
                        () => [i=0, l=lst{i}, o=l],
                        (x)=> x[i]<List.Count(lst),
                        (x)=> [i=x[i]+1, l=lst{i}, o=f(l,x[o])],
                        (x)=> g(x[o])
                    ),

            out =   Table.RenameColumns(
                        Table.Range(table,num),
                        List.Zip({Table.ColumnNames(table),gen})
                    )
        ]  [out],
        
        from = ИсточникДанных,
        to   = fnParsHead(from,3,".")

    Разберем данный код.
    Эта функция анализирует первые несколько строк таблицы table, указанных в параметре num, далее по столбцам идёт объединение текста с использованием в качестве разделителя параметра delim. Опционально четвертый параметр fill позволяет задать строковое значение, которое будет использовано для заголовков нижних уровней в случае их отсутствия в данном столбце.
        lst   - преобразуем в список строки таблицы с шапкой
        delim - опрашиваем входящий параметр-разделитель и при его отсутствии устанавливаем пробел
        g     - проверка параметра fill и если оно ненулевое, то добавляем к значению поля параметр, переданный в функцию fnParshead.
        f     - на вход подаем два списка, связываем попарно и обрабатываем.
        gen   - генератор, который собирает список для будущего заголовка таблицы в комплексе с функциями f и g.

    Попробуйте на приложенных примерах разобрать каждый подход. И если что-то окажется полезным – значит все было не зря.

    В большей степени пост предназначен для начинающих и продолжающих изучать функциональное программирование, хотя и профессионалы, надеюсь, смогут найти тут для себя что-то интересное.
    Примеры, представленные выше показывают, как через редактор можно решить насущную задачу по разбору многоуровневой шапки. Так же предлагаю попробовать решить приложенные примеры, не прибегая к коду:
    (мышкоклацем) – что получится?
    ]

[   Table.CombineColumns или где окажется результирующий столбец? / #АнатомияФункций - Table.CombineColumns

    Всем привет!
    Пилил небольшую задачку и вспомнил один приём, которым и хочу поделиться.
    Итак, имеем таблицу, в которой несколько столбцов нужно объединить – в примере просто нужно найти сумму и запихнуть её в столбец "sum". Собственно, ничего сложного – пишем код:
        
        let
            from = #table({"a".."f"},{{1..6},{2..7},{3..8}}),
            to  = Table.CombineColumns(from,{"a","c","e"},List.Sum,"sum"),//{"b","d","sum","f"}
            to1 = Table.CombineColumns(from,{"a","e","c"},List.Sum,"sum"),//{"b","sum","d","f"}
            to2 = Table.CombineColumns(from,{"c","e","a"},List.Sum,"sum")//{"sum","b","d","f"}
        in
            to2

    from – таблица,
    to   – объединяем столбцы {"a","c","e"} и на выходе получаем таблицу со следующим порядком столбцов - {"b","d","sum","f"} – и внимательный читатель заметит, что сумма оказалась на месте столбца "e", т.е. последнего в нашем списке.
    
    Интересно, давайте поэкспериментируем:
    to1  – поставили последним столбец "c" и теперь результат оказался на его месте
    to2  – а теперь результат вообще вначале, на месте столбца "a", поскольку именно его мы указали последним.

    Как-то так – для CombineColumns важен порядок имён в списке объединяемых столбцов – так мы можем сразу регулировать, где окажется результат.
    ]

[   buchOfficePack – fxUnzip – часть 1 ядро / #АнатомияФункций - buchOfficePack

    Всем привет!
    Ну что ж – началось – пилим библиотеку на камеру.
    Видос уже на Ютубе
    Код для страждущих тут:
    (ZIP)=>
        [
        u16 =BinaryFormat.ByteOrder(BinaryFormat.UnsignedInteger16,ByteOrder.LittleEndian),
        u32 =BinaryFormat.ByteOrder(BinaryFormat.UnsignedInteger32,ByteOrder.LittleEndian),
        get=(x)=>BinaryFormat.Record(
            if Binary.Range(x,0,4)=#binary({0x50,0x4b,0x03,0x04})
            then [  Name=BinaryFormat.Text(u16(Binary.Range(x,26,2))),
                    Extr=BinaryFormat.Binary(u16(Binary.Range(x,28,2))),
                    Value=BinaryFormat.Transform(BinaryFormat.Binary(u32(Binary.Range(x,18,4))),(x)=>Binary.Decompress(x,Compression.Deflate)),
                    flag=true]
            else [flag=false]
        ),
        lst = BinaryFormat.List(BinaryFormat.Choice(BinaryFormat.Binary(30),get),(x)=>x[flag]=true)(ZIP),
    to = Table.FromRecords(List.RemoveLastN(lst,1),type table [Name=text,Value=binary])][to]
    ]

[   buchOfficePack – fxUnzip – часть 2 обвес/ #АнатомияФункций - buchOfficePack

    Всем привет!
    Продолжаем пилить библиотеку. Видос уже на Ютубе

    Добавили всё по красоте – параметры, справку и залили на гитхаб.
    Итоговый код ниже, все мои комментарии в видосе.

    fxUnzip=[func=(ZIP, optional options)=>
        [
        encod = [a=options[Encoding]?,b=if a = null then 866 else a][b],
        compr = (x)=> if x =0 then Compression.None else Compression.Deflate,

        u16 =BinaryFormat.ByteOrder(BinaryFormat.UnsignedInteger16,ByteOrder.LittleEndian),
        u32 =BinaryFormat.ByteOrder(BinaryFormat.UnsignedInteger32,ByteOrder.LittleEndian),

        get=(x)=>BinaryFormat.Record(
            if Binary.Range(x,0,4)=#binary({0x50,0x4b,0x03,0x04})
            then [  Name=BinaryFormat.Text(u16(Binary.Range(x,26,2)),encod),
                    Extr=BinaryFormat.Binary(u16(Binary.Range(x,28,2))),
                    Value=BinaryFormat.Transform(BinaryFormat.Binary(u32(Binary.Range(x,18,4))),(y)=>Binary.Decompress(y,compr(u16(Binary.Range(x,8,2)))))]
            else []
        ),

        lst = BinaryFormat.List(BinaryFormat.Choice(BinaryFormat.Binary(30),get),(x)=>x<>[])(ZIP),
        to = Table.FromRecords(List.RemoveLastN(lst,1),type table [Name=text,Value=binary])][to],

    typ =type function (ZIP as (type binary meta [Documentation.FieldCaption="ZIP - бинароное содержимое (zip, xlsx, docx, pptx и т.д.)"]), optional options as record) as table meta 
                [Documentation.Name = "fxUnzip (@buchlotnik)",
                Documentation.LongDescription ="функция считывает содержимое архива и возвращает таблицу с полями:<p> <b>Name</b> - имя файла (с путём к файлу) <p><b>Value</b> - бинарное содержимое файла. <p>Необязательный аргумент <b>options</b> на текущий момент поддерживает следующие поля: <p>1) <b>Encoding</b> - требуется для корректного чтения не латинских имён файлов (по умолчанию <b>866 - кириллица</b>)"],

    result = Value.ReplaceType(func,typ)][result]
    ]

[   buchOfficePack - fxExcelGetRowsAttributes - часть 1 - ядро / #АнатомияФункций - buchOfficePack
    ]

[   buchOfficePack - fxExcelGetRowsAttributes - часть 2 - обвес и не только / #АнатомияФункций - buchOfficePack
    ]

[   buchOfficePack - fxTableRemoveEmptyColumns – удаляем пустые столбцы в таблице / #АнатомияФункций - buchOfficePack

    Само решение уже было на канале, но поскольку надо обеспечить совместимость с 2016 пришлось отказаться от второго аргумента в Table.Profile. В итоге получилось решение в три строчки )))
    
        fxTableRemoveEmptyColumns = [
            func = (table, optional options)=>
                [   tbl = Table.Buffer(Table.Profile(table)),
                    lst = Table.SelectRows(tbl,(r)=>r[Count]=r[NullCount])[Column],
                    to  = Table.RemoveColumns(table,lst)
                ]  [to],
            
            typ = type function (table as table, optional options as record) as table meta 
                [   Documentation.Name            = "fxTableRemoveEmptyColumns (@buchlotnik)",
                    Documentation.LongDescription = "функция, удаляющая пустые столбцы из таблицы"],
            
            result = Value.ReplaceType(func,typ)
        ]  [result]
    ]

[   fxGetMCode   – получаем код М, используя М / #АнатомияФункций – buchOfficePack

    Всем привет!
    Дошли руки до вынимания кода запросов из файлов. В целом, после fxUnZip это уже не должно быть особо сложным. Просто надо ещё немножко почитать спецификацию.
    А там, как всегда, всё написано и по этому поводу функция (она является частью библиотеки, поэтому убедитесь, что fxUnZip у вас имеется в наличии):
    fxGetMCode=(file)=>
        [u32 = BinaryFormat.ByteOrder(BinaryFormat.UnsignedInteger32,ByteOrder.LittleEndian),
        f=(x)=>[a=Text.Split(x," = "),b={Text.Trim(Text.Replace(a{0},"shared","")),Text.Combine(List.Skip(a)," = ")}][b],
        from = fxUnzip(file){[Name="customXml/item1.xml"]}?[Value]?,
        bin = Binary.FromText(Xml.Document(from){0}[Value],BinaryEncoding.Base64),
        data = BinaryFormat.Choice(BinaryFormat.Binary(8),(x)=>BinaryFormat.Binary(u32(Binary.Range(x,4,4))))(bin),
        unz = fxUnzip(data){[Name="Formulas/Section1.m"]}[Value],
        txt = Text.FromBinary(unz)&"#(cr,lf)",
        splt = Text.Split(txt,";#(cr,lf)"),
        lst = List.Range(splt,1,List.Count(splt)-2),
        tbl = Table.FromList(lst,f,{"Name","Value"}),
        to = if from=null then #table({"Name","Value"},{{null,null}}) else tbl][to]

    По шагам
    u32     – вспомогательная функция для чтения 4-байтного беззнакового целого (размер массива)
    f       – ещё одна вспомогательная – отрезает название запроса от собственно кода запроса

    А теперь основное тело
    from    – открываем файл как архив и вынимаем customXml/item1.xml – код хранится там
    bin     – внутри этого xml лежит в виде текста сжатый бинарник (DataMashup) – возвращаем ему первозданный бинарный вид
    data    – из полученного бинарника пропускаем первые 4 байта, а вторые 4 указывают на размер массива, содержащего код - читаем
    unz     – и поскольку этот массив ещё и сжатый – снова используем fxUnZip и вынимаем Formulas/Section1.m – файл с кодом
    txt     – превращаем бинарку в текст и дописываем в конце перевод каретки с разрывом строки (там просто запросы отделены точкой с запятой с последующим переводом каретки, но в самом конце идёт просто точка с запятой – короче добиваемся единообразия)
    splt    – теперь делим общий текст на отдельные запросы
    lst     – отбрасываем лишние первый и последний фрагменты
    tbl     – собираем в табличку, параллельно отделяя название запроса от его кода
    to      – ну и на выход подаём либо табличку, либо пустую табличку, когда запросов в файле не оказалось.

    Как обычно, код короче своего описания ))) Видос с более подробным разбором будет, но уже в новом году. Пользуйтесь!
    ]

[   fxDistribute – немножко решения задач оптимизации на М / #АнатомияФункций – custom

    Всем привет!
    Я упорно не пытаюсь решать задачи оптимизации на М, но они упорно возникают в чате. Поэтому, раз уж поддержали пост, решаем задачу:
    на вход подаётся список из N позиций с указанием их «веса», список нужно разделить на M равных (почти равных если целочисленное деление невозможно) групп с максимально равной суммой весов. Ок, у меня вышло примерно так:
       
    (lst,num)=>
        let
            n    = Number.RoundUp(List.Count(lst)/num)*num,
            sort = List.Sort(lst&List.Repeat({0},n-List.Count(lst))),
            av   = List.Average(sort),
            tr   = List.Transform(sort,(x)=>x-av),
            zip  = List.Zip(List.Split(tr,num)),
            
            f=(base)=>
                [   tst  = List.Buffer(List.Sort(base,(x)=>List.Sum(x))),
                    last = List.Last(tst),
                    sum1 = Number.Abs(List.Sum(tst{0})),
                    sum2 = Number.Abs(List.Sum(last)),
                    lst1 = if sum2>sum1 then tst{0} else last,
                    lst2 = if sum2>sum1 then last else tst{0},
                    cr   = List.Sum(lst2),
                    lst  = List.TransformMany(lst2,(x)=>lst1,(x,y)=>{x,y,cr-x+y}),
                    slct =  if cr <0 
                            then List.Max(List.Select(lst,(x)=>x{2}<0),null,(x)=>x{2})
                            else List.Min(List.Select(lst,(x)=>x{2}>0),null,(x)=>x{2}),
                    f=(x,y,z)=>List.ReplaceRange(x,List.PositionOf(x,y),1,{z}),
                    new = {f(lst2,slct{0},slct{1})}&List.Range(tst,1,num-2)&{f(lst1,slct{1},slct{0})}
                ]  [new],
        
            gen =   List.Generate(
                        () => [ i  = 0,
                                l  = zip,
                                s  = List.Sum(List.Transform(l,(x)=>Number.Abs(List.Sum(x)))),
                                fl = true
                              ],
                        (x)=> x[fl],
                        (x)=> [ i  = x[i]+1,
                                l  = f(x[l]),
                                s  = List.Sum(List.Transform(l,(x)=>Number.Abs(List.Sum(x)))),
                                fl = s<x[s]
                              ],
                        (x)=> x[l]
                    ),
            tbl = Table.FromColumns(List.Last(gen)),
            to  = Table.TransformColumns(tbl,{},(x)=>x+av)
        in
            to

    По шагам:
        n    – определяем общую длину списка, чтобы делилось поровну
        sort – дополняем список до нужной длины нулями и сортируем
        av   – находим среднее по списку
        tr   – преобразуем фактические веса в величину отклонения от среднего
        zip  – нарезаем список по N элементов и получаем M достаточно одинаковых групп – опорный план

    теперь немножко перескочим
        gen – итеративно применяем к полученным спискам функцию f и следим за остаточной суммой отклонений – продолжаем пока она уменьшается
        tbl – результат последней итерации превращаем в таблицу
        to  – возвращаем «весам» их первозданный вид

    Теперь по функции 
        f   – реализованный алгоритм ищет локальный минимум – это важно, потому как решил не усложнять жизнь ни себе, ни оперативе.
        tst, last, sum1, sum2,l st1, lst2 – находим группы с наибольшей (положительной) и наименьшей (отрицательной) суммами
        cr, lst – находим все сочетания элементов этих двух групп и как их обмен повлияет на общий результат
        slct – выбираем наиболее подходящую пару
        new  – осуществляем обмен элементами между группами

    Как-то так. Поиск локального минимума не всегда оптимален, зато работает шустро и пишется просто )))
    ]

[   fxColNumFromText – номер столбца по адресу ячейки / #АнатомияФункций – custom

    В этот раз решаем частную задачу – определить номер столбца по его буквенному обозначению. Собственно, нужно просто вспомнить про то, что у каждого символа есть его числовой код, ну и как устроены позиционные системы исчисления. Код вышел весьма лаконичный:
        f=(x)=>[
            a = List.Transform(
                    List.Reverse(Text.ToList(Text.SplitAny(x,"0123456789"){0})),
                    (x)=>Character.ToNumber(x)-64
                ),
            b = List.Sum(
                    List.Transform(
                        List.Zip({a,List.Positions(a)}),
                        (x)=> x{0} * Number.Power(26,x{1})
                    )
                )
        ][b]
    ]

[   fxGetMCode   – получаем код М, используя М / #АнатомияФункций – buchOfficePack / #АнатомияФункций – custom

    Получаем код всех запросов из всех файлов из папки
    
    Всем привет!
    На текущий момент на канале есть fxUnzip, есть fxGetMCode и есть пост про Folder.Files.
    Мне казалось, что этого достаточно, чтобы самостоятельно собрать адекватное подключение к папке и получить код запросов из всех файлов внутри неё. Но оказалось, что я просто пишу нерабочий код и всё вышеизложенное «не взлетает». ОК, напишем код целиком:
        
        let
            lst = {"QueryName","Value"},
            
            //функция
            func= (file)=>
            [   u16 = BinaryFormat.ByteOrder(BinaryFormat.UnsignedInteger16,ByteOrder.LittleEndian),
                u32 = BinaryFormat.ByteOrder(BinaryFormat.UnsignedInteger32,ByteOrder.LittleEndian),
                
                f=(x)=>[
                    a = Text.Split(x," = "),
                    b = {Text.Trim(Text.Replace(a{0},"shared","")),Text.Combine(List.Skip(a)," = ")}
                ]  [b],
            
                fxUnzip=(ZIP)=>
                    [   get=(x)=>BinaryFormat.Record(if Binary.Range(x,0,4)=#binary({0x50,0x4b,0x03,0x04})
                            then [  Name  = BinaryFormat.Text(u16(Binary.Range(x,26,2))),
                                    Extr  = BinaryFormat.Binary(u16(Binary.Range(x,28,2))),
                                    Value = BinaryFormat.Transform(BinaryFormat.Binary(u32(Binary.Range(x,18,4))),(y)=>Binary.Decompress(y,Compression.Deflate))]
                            else []),
                        lst = BinaryFormat.List(BinaryFormat.Choice(BinaryFormat.Binary(30),get),(x)=>x<>[])(ZIP),
                        to  = Table.FromRecords(List.RemoveLastN(lst,1),type table [Name=text,Value=binary])
                    ]  [to],
            
                from = fxUnzip(file){[Name="customXml/item1.xml"]}?[Value]?,
                bin  = Binary.FromText(Xml.Document(from){0}[Value],BinaryEncoding.Base64),
                data = BinaryFormat.Choice(BinaryFormat.Binary(8),(x)=>BinaryFormat.Binary(u32(Binary.Range(x,4,4))))(bin),
                unz  = fxUnzip(data){[Name="Formulas/Section1.m"]}[Value],
                splt = Text.Split(Text.FromBinary(unz)&"#(cr,lf)",";#(cr,lf)"),
                tbl  = Table.FromList(List.Range(splt,1,List.Count(splt)-2),f,lst),
                to   =  if from = null 
                        then #table(lst,{{null,null}}) 
                        else tbl
            ][to],
            
            //собственно подключение к папке
            from = Folder.Files("ПУТЬ К ПАПКЕ ВВЕСТИ САМОСТОЯТЕЛЬНО"),
            filtr = Table.SelectRows(from, (r)=> (r[Extension] = ".xlsm" or r[Extension] = ".xlsx")),
            rem = Table.SelectColumns(filtr,{"Name", "Content"}),
            tr  = Table.TransformColumns(rem,{"Content",func}),
            to  = Table.ExpandTableColumn(tr,"Content",lst)
        in
            to

    где
    func – собственно функция для вынимания кода запросов (fxUnzip интегрирована внутрь «во избежание»)
    from – подключение к папке (увы, я заранее не знаю путь к конкретной папке – его придётся исправить на свой, ручками – если даже это станет проблемой – мои полномочия всё)
    filtr, rem – оставили только эксельки и только нужные столбцы
    tr,to – преобразовали бинарки файлов в таблицы и развернули их

    И всё. Кто найдёт в коде выше File.Contents, без которой якобы не работает – пусть первым бросит в меня камень. Большая просьба думать перед тем, как писать, что что-то «не работает».
    ]

[   Раскидываем иерархию через List.Generate / #АнатомияФункций – List.Generate

    Несколько раз вопрос всплывал в чате и я уже давал образчики кода, но захотелось записать видос – как всегда, на Ютубе.
    https://www.youtube.com/watch?v=PW2-jc9oslc
    
    ! Нужен столбец с номером уровня 

    Код вышел несложный, складываю сюда, чтобы можно было поиском находить
        
        let
            from = Excel.CurrentWorkbook(){[Name="Источник"]}[Content],
            lst  = List.Buffer(Table.ToList(from,(x)=>x)),
            max  = List.Max(from[уровень]),
            n    = List.Count(lst),
            
            gen  = List.Generate(
                    ()=>[i=0,j=lst{i},l=List.ReplaceRange(List.Repeat({null},max),j{0}-1,1,{j{1}})&List.Skip(j,2)],
                    (x)=>x[i]<n,
                    (x)=>[i=x[i]+1,j=lst{i},l=List.FirstN(x[l],j{0}-1)&{j{1}}&List.Repeat({null},max-j{0})&List.Skip(j,2)],
                    (x)=>if (lst{x[i]+1}?{0}? ?? 0)>x[j]{0} then null else x[l]
                ),

            nms =   List.Transform({1..max},
                        (x)=>"заголовок " & Text.From(x)
                    ) & 
                    List.Skip(Table.ColumnNames(from),2),

            to  =   Table.FromList(
                        List.RemoveNulls(gen),
                        (x)=>x,nms
                    )
        in
            to
    ]

[   Получаем несколько элементов списка по их номерам //? #АнатомияФункций – List.Transform

    Всем привет!
    Уже неоднократно поднимался вопрос о том, как получить несколько элементов списка по их номерам. Смотрим код:
    let
        from = {"a".."z"},
        /*to = from{1,4,8} - так не работает!*/
        to = List.Transform({1,4,8},(x)=>from{x-1})
    in
    to

    Всё просто – НЕЛЬЗЯ писать через запятую в фигурных скобках – так нас не понимают.
    А вот через List.Transform – всё очень даже работает. Главное, помнить, что нумерация позиций начинается с нуля, а не с единицы.
    ]

[   Раскидываем столбец в строки таблицы / #АнатомияФункций – List.Split

    Подогнали мне на днях ссылку на одно видео… Горит до сих пор так, что аж записал видео. Речь идёт об архисложном коде:
        let
            from =  Excel.CurrentWorkbook(){[Name="Источник2"]}[Content][Сделки],
            to   =  Table.FromList(
                        List.Split(from,9),
                        (x)=>List.FirstN(x,6)
                    )
        in
            to

    Как вы понимаете – это как НАДО делать, а как не надо я даже публиковать тут не буду. Общая мысль – изучать М нужно, чтобы иметь возможность написать ровно то, что надо сделать для решения задачи. Без изысков и подвыпердов.
    ]

[   Получаем атрибуты документов Word из папки / #АнатомияФункций - Folder.Files, fxUnzip

    Всем привет!
    Подкинули недавно задачку – вытащить количество страниц из документов .docx в папке.
    Что ж – это повод воспользоваться buchOfficePack.
    Код для поиска тут:
        
        let
            f=(x)=>[ 
                a = unzip(x){[Name="docProps/app.xml"]}[Value],
                b = Number.From(Xml.Tables(a){0}[Pages])
            ]  [b],
            
            unzip = Expression.Evaluate(Text.FromBinary(Web.Contents("https://raw.githubusercontent.com/buchlotnik/buchlotnik_functions/main/buchOfficePack")),#shared)[fxUnzip],
            from  = Folder.Files("путь к папке"),
            filtr = Table.SelectRows(from,(r)=>r[Extension]=".docx" and not Text.Contains(r[Name],"~")),
            tbl   = Table.SelectColumns(filtr,{"Name","Content"}),
            tr    = Table.TransformColumns(tbl,{"Content",f})
        in
            tr
    ]

[   #sections – собираем результаты всех запросов / #АнатомияФункций – синтаксис

    Всем привет!

    В очередной раз в чат пришли с вопросом – как собрать результаты всех запросов в одну табличку? Как правило, ситуация осложняется тем фактом, что число запросов может изменяться (чаще добавляются новые).
    Что ж – это несложно. Код складываю тут:

        let
            from = Record.ToTable(Record.RemoveFields(#sections[Section1],"Result")),
            nms  = List.Distinct(List.Combine(List.Transform(from[Value],Table.ColumnNames))),
            to   = Table.ExpandTableColumn(from,"Value",nms)
        in
            to
    ]

[   ЕЧИСЛО, ЕТЕКСТ и прочие радости с оператором is / #АнатомияФункций - основы

    Всем привет!
    Вроде несколько раз обсуждали этот вопрос – и тем не менее продолжают возникать затруднения с определением того, принадлежит ли значение к определенному типу (если быть точным – совместим ли тип значения с определённым типом).
    По этому поводу код:
        
        let
            from = #table({"val"},{{null},{1.23},{"текст"},{false},{#date(2024,2,3)},{#datetime(2024,2,3,12,34,56)},{{1..3}},{[a=1]},{#table({},{})},{(x)=>x}}),
            lst  = {
                {"ЕПУСТО",      (x)=>x = null}, //можно и x is null
                {"ЕЧИСЛО",      (x)=>x is number},
                {"ЕТЕКСТ",      (x)=>x is text},
                {"ЕЛОГИЧ",      (x)=>x is logical},
                {"ЕДАТА",       (x)=>x is date},
                {"ЕДАТАВРЕМЯ",  (x)=>x is datetime},
                {"ЕСПИСОК",     (x)=>x is list},
                {"ЕЗАПИСЬ",     (x)=>x is record},
                {"ЕТАБЛИЦА",    (x)=>x is table},
                {"ЕФУНКЦИЯ",    (x)=>x is function},
                {"ЕЧТОУГОДНО",  (x)=>x is any},
                {"ЕВООБЩЕНИЧЕГО",(x)=>x is none}
            },
            to = List.Accumulate(lst,from,(s,c)=>Table.AddColumn(s,c{0},(r)=>c{1}(Record.Field(r,"val"))))
        in
            to

    Собственно, кроме кода тут и говорить почти нечего – оператор is позволяет осуществить проверку, совместим ли тип значения с соответствующим примитивом, т.е. грубо говоря, позволяет проверить является ли значение числом, текстом, таблицей или функцией. За техническими деталями, без обид, отправляю в справку. А здесь, чисто для иллюстрации, прошу обратить внимание на два последних столбца – все значения совместимы с any (все они чем-то да являются) и ни одно не совместимо с none (т.е. даже null больше, чем просто ничего).

    Как-то так – сугубо технический пост, чтобы было на что давать ссылку)))
    ]

[   Table.Group + GroupKind.Local – локально по нескольким столбцам с агрегацией пачкой / #АнатомияФункций - Table.Group
    
    # мой пример
    
    Всем привет!
    В чат закинули простую, но комплексную задачку на группировку. https://www.youtube.com/watch?v=m1GciRxnl1o
    Поэтому поводу складываю сюда код:
        let
            from =  Excel.CurrentWorkbook(){[Name="Таблица1"]}[Content],
            nms  =  List.Transform(
                        List.Skip(Table.ColumnNames(from),2),
                        (x)=>{x, (t)=>Text.Combine(Table.Column(t,x)," "), type text}
                    ),
            gr   =  Table.Group(from,
                        {"Индекс","Index"},
                        nms,
                        GroupKind.Local,
                        (s,c)=>Number.From(c[Index] = 4)
                    )
        in  
            gr
    ]

[   Замена null на ноль пачкой по всем столбцам / #АнатомияФункций - Table.ReplaceValue, Table.TransformColumns

    Всем привет!
    Вроде тысячу раз уже обсуждали, но всплывает вопрос в комментах – как массово заменить нуллы на нули во всех столбцах таблицы.
    Есть варианты:
    
    Вариант 1
        
        let
            from = Excel.CurrentWorkbook(){[Name="Таблица1"]}[Content],
            to   = Table.ReplaceValue(from,null,null,(x,y,z)=>if x=null then 0 else x,Table.ColumnNames(from))
        in
            to

    Вариант 2

        let
            from = Excel.CurrentWorkbook(){[Name="Таблица1"]}[Content],
            f=(x)=>if x=null then 0 else x,
            nms = List.Transform(Table.ColumnNames(from),(x)=>{x,f}),
            to  = Table.TransformColumns(from,nms)
        in
            to

    Вариант 3

        let
            from = Excel.CurrentWorkbook(){[Name="Таблица1"]}[Content],
            to   = Table.TransformColumns(from,{},(x)=>if x=null then 0 else x)
        in
            to

    Мне больше всего нравится последний, но это дело вкуса.
    ]

[   Table.ColumnNames + Record.SelectFields - вынимаем нужные поля построчно / #АнатомияФункций - Record.SelectFields

    Всем привет!
    Подкинули несложную задачку по выниманию полей с ценами и нахождению максимума среди них.
    Есть код попроще

        let
            from = Excel.CurrentWorkbook(){[Name="Обычная"]}[Content],
            f=(x)=>List.Max(List.Alternate(List.Skip(Record.ToList(x),4),2,1)),
            to   = Table.AddColumn(from,"max",f)
        in
            to

    А есть посложнее, но железобетоннее:
    
        let
            from = Excel.CurrentWorkbook(){[Name="АД"]}[Content],
            lst  = List.Buffer(List.Select(Table.ColumnNames(from),(x)=>Text.Contains(x,"Цена"))),
            f=(x)=>List.Max(Record.ToList(Record.SelectFields(x,lst))),
            to   = Table.AddColumn(from,"max",f)
        in
            to

    Что тут к чему рассказывается в видео на Ютубе
    ]

[   List.Split + List.Zip + List.Combine = таблица / #АнатомияФункций – List

    Всем привет!

    В чат принесли прикольную задачку на превращение странного куска данных в осмысленную таблицу.
    Пришлось резать, крутить, шить и вообще делать всякое. Кода вышло немного:
        let
            f=(x)=>[a = Number.From(Text.Split(x{0}[Column1]," "){4}),
                    b = List.Combine(Table.ToList(Table.Skip(x,2),(x)=>List.Split(x,2))),
                    c = List.Transform(b,(x)=>{a}&x)][c],
            
            from = Excel.CurrentWorkbook(){[Name="TData"]}[Content],
            gr   = Table.Group(from,"Column2",{"tmp",f},GroupKind.Local,(s,c)=>Number.From(c=null)),
            to   = Table.FromList(List.Zip(gr[tmp]),List.Combine)
        in
            to
    ]

[   Table.Group + List.Generate = сложная пользовательская агрегация / #АнатомияФункций – Table.Group

    Всем привет!

    Записал очередной разбор задачки из чата – получилось немножко долго, потому как задачка комплексная, но должно быть небезынтересно. Код тут:
    
        let
            f=(x)=>[a   = List.Transform(nms2,(i)=>List.Sum(Table.Column(x,i))),
                    b   = List.Min(x[Период с]),
                    c   = List.Max(x[Период по]),
                    gen = List.Generate(() => b,
                                        (x)=> x < Date.EndOfMonth(c),
                                        (x)=> Date.AddMonths(x,1),
                                        (x)=> { Date.StartOfMonth(x),
                                                Date.EndOfMonth(x),
                                                Date.StartOfMonth(x) }
                                        ),
                    n   = List.Count(gen)-1,
                    tr  = List.ReplaceRange(gen,n,1,{{gen{n}{0},c,gen{n}{0}}}),
                    tr1 = List.ReplaceRange(tr,0,1,{{b,tr{0}{1},tr{0}{2}}&a})][tr1],
            
            from = Excel.CurrentWorkbook(){[Name="М3"]}[Content],
            nms1 = {"Период с","Период по","Пеирод месяц"},
            nms2 = {"Сумма с НДС","Сумма без НДС","Сумма НДС"},
            gr   =  Table.Group(from,"Контрагент",{
                        {"Площадка", (t)=>Text.Combine(List.Distinct(t[Площадка]),", ")},
                        {"tmp",f}
                    }),
            sort = Table.Sort(gr,"Контрагент"),
            exp  = Table.ExpandListColumn(sort,"tmp"),
            splt = Table.SplitColumn(exp,"tmp",(x)=>x,nms1&nms2),
            to   =  Table.TransformColumnTypes(splt,
                        List.Transform(nms1,(x)=>{x,type date  }) & 
                        List.Transform(nms2,(x)=>{x,type number})
                    )
        in
            to
    ]

[   List.Accumulate vs List.Zip - или нестандартная замена в тексте / #АнатомияФункций – List.Accumulate

    Всем привет!
    В чат принесли задачку по замене в тексте последовательности из нескольких длинных тире на слеш. Поскольку обычные тримы с реплейсами в этой ситуации не работают, пришлось поколдовать. По этому поводу вариант просто на функциях:
        
        let
            f=(x)=>[
                lst = Text.ToList(x),
                zip = Text.Replace(Text.Combine(List.Transform(List.Select(List.Zip({lst,List.Skip(lst)}),(x)=>x<>{"—","—"}),(x)=>x{0})),"—","/")
            ][zip],
            
            from = Excel.CurrentWorkbook(){[Name="Таблица1"]}[Content],
            to   = Table.TransformColumns(from,{"txt",f})
        in
            to

    Вариант с if then else:
        
        let
            f=(x)=>[
                lst =   Text.ToList(x),
                zip =   Text.Combine(
                            List.Transform(
                                List.Zip({ lst, List.Skip(lst) }),
                                (x)=>   if   x{0}<>"—" 
                                        then x{0} 
                                        else    if x{1}="—" 
                                                then "" 
                                                else "/"
                            )
                        )
            ][zip],
            
            from = Excel.CurrentWorkbook(){[Name="Таблица1"]}[Content],
            to   = Table.TransformColumns(from,{"txt",f})
        in
            to

    И вариант с аккумулятором:
        
        let
            f=(x)=>
                List.Accumulate(
                    Text.ToList(x),
                    "",
                    (s,c)=> if   c<>"—" 
                            then s&c 
                            else if   Text.EndsWith(s,"/") 
                                 then s 
                                 else s & "/"
                ),
            
            from = Excel.CurrentWorkbook(){[Name="Таблица1"]}[Content],
            to   = Table.TransformColumns(from,{"txt",f})
        in
            to

    Ну а о том, насколько медленный аккумулятор или короче=быстрее, рассказывается, как обычно, рассказывается на Ютубе
    ]

[   Table.Group, ListAnyTrue и прочие Splitter.SplitTextByCharacterTransition / #АнатомияФункций - ютуб

    Всем привет!
    Подкинули прикольную задачку в чат - группировка, словари, текстовые преобразования – получил удовольствие, записал рабор.
    Код складываю тут:
        
        let
            lst = List.Buffer({"0".."9"}),
            
            dict = Record.FromTable(Excel.CurrentWorkbook(){[Name="спрСубъекты2"]}[Content]),
            
            f=(x)=> if List.AnyTrue(List.Transform({"R","UA","UB","UC", "UD", "UE", "UF", "UG", "UH", "UI"},(y)=>Text.StartsWith(x,y)))
                    then Record.Field(dict,Text.Start(Splitter.SplitTextByCharacterTransition((i)=>not List.Contains(lst,i),lst)(x){1},2))
                    else null,

            g=(x)=> if x{0}[reg]=null 
                    then Table.AddColumn(x,"Область",(r)=>null)
                    else Table.TransformColumns(Table.AddIndexColumn(Table.Sort(x,{"Date","Time"}),"Область",1),{"Область",(x)=>if x=1 then 1 else 0}),


            from = Excel.CurrentWorkbook(){[Name="Таблица"]}[Content],
            add  = Table.AddColumn(from,"reg",(r)=>f(r[HisCall])),
            gr   = Table.Group(add,{"MyCall","Band","reg"},{"tmp",g}),
            tbl  = Table.Combine(gr[tmp]),
            to   = Table.RemoveColumns(tbl,"reg")
        in
            to
    ]

[   List.Skip, List.FirstN, List.Positions – прикольное упражнение на списки / #АнатомияФункций - List.Skip, List.FirstN, List.Positions

    Всем привет!
    Подкинули задачку на сборку таблицы из списка букв русского алфавита.
    Решил восстановить справедливость - добавил Ё, ну и написал всё по-хулигански:
    
    [ a =   List.Buffer({"А".."Е","Ё","Ж".."Я"}),
      b =   Table.FromList(
                List.Positions(a),
                (b)=>List.Skip(a,b) & List.FirstN(a,b) & {a{b} },
                {" "} & a
            )
    ][b]

    Ну а что тут к чему, как обычно, рассказывается на Ютубе
    ]

[   Number.Mod, List.Positions или реализуем код Вижинера / #АнатомияФункций - Number.Mod, List.Positions

    Всем привет!
    Вчера решали задачу по построению таблицы со сдвигами, но выяснилось, что это требовалось для кодирования информации. Так вот – для кодирования таблица вообще не нужна, нужны только номера, остатки и всякое такое. Поэтому вот код:
    (tbl,key,cr)=>
    let
        lst=List.Buffer({"А".."Е","Ё","Ж".."Я","а".."е","ё","ж".."я","A".."Z","a".."z","0".."9"," ",",",".",":","-"}),
        c=if cr=0 then 1 else -1,

        d=Record.FromList(List.Positions(lst),lst),
        e=List.Buffer(List.Transform(Text.ToList(key),(x)=>Record.Field(d,x))),
        n=List.Count(lst),

        f=(x)=>if x is text then [a=Text.ToList(x),b=Text.Combine(List.Transform(List.Zip({a,List.Positions(a)}),g))][b] else x,
        g=(x)=>lst{Number.Mod(n+Record.Field(d,x{0})+c*(e{Number.Mod(x{1},List.Count(e))}+1),n)},
        
        to=Table.TransformColumns(tbl,{},f)
    in
        to
    Важно – поменял в коде проверку условия – проверяем не null, а именно наличие текста.
    ]

[   Рекурсия, if then else или нестандартная задачка / #АнатомияФункций – рекурсия

    Всем привет!
    Записал разбор очередной задачки из чата – на этот раз мучаем рекурсивный вызов.
    Код:
    let
        a = PP_титульник[tol],
        b = Table.ToList(PostgreSQL_блоки,(x)=>x),
        c = List.Count(a),
        d = List.Buffer({List.Repeat({null},Table.ColumnCount(PostgreSQL_блоки))&{"fail"}}),
        f=(x,y,z,w)=>[k=a{x},l=b{x+y},m=b{x+y+1}?,
                    n = if x = c then z
                    else if w then @f(x+1,y,z&d,w)
                    else if k = l{0} then @f(x+1,y,z&{l&{"no"}},w)
                    else if k = m{0}? then @f(x+1,y+1,z&{m&{"yes: "&l{0}}},w)
                    else @f(x+1,y,z&d,true)][n],

        e = Table.FromList(f(0,0,{},false),(x)=>x)
    in
    ]

[   Рекурсия, Folder.Contents или побеждаем слишком длинные имена файлов / #АнатомияФункций - Folder.Contents

    Всем привет!

    Продолжаем тему рекурсии. Сегодня побеждаем слишком длинные имена файлов, а для этого вместо Folder.Files используем Folder.Contents и пишем рекурсивный обход содержимого.
        
        let
            from = Folder.Contents("C:\Users\muzyk\Desktop\папка1"),
            f=(x)=>[
                a = Table.SelectRows(x,(r)=>r[Extension]<>""),
                b = Table.SelectRows(x,(r)=>r[Extension]="")[Content],
                c = if b={} 
                    then x 
                    else @f (List.Accumulate(
                                b,a,
                                (s,c)=>[a = try Table.RowCount(c) otherwise 0,
                                        b = if a=0 then s else s&c
                                        ][b])
                            )
            ][c],
            to = f(from)
        in
            to
    ]

[   MCMLXXXVIII=1988 или преобразуем римскую запись числа в нормальную / #АнатомияФункций - List.Zip
    
    Решил разобрать задачку на преобразование римской записи числа в современную. С точки зрения практического смысла занятие сомнительное, но вообще это неплохое упражнение на списки.
    Поэтому код:
        
        let
            unroman=(txt)=>[
                dct = [I=1,V=5,X=10,L=50,C=100,D=500,M=1000],
                lst = Text.ToList(txt),
                tr  = List.Transform(lst,(x)=>Record.Field(dct,x)),
                zip = List.Zip({tr,List.Skip(tr)&{0}}),
                tr2 = List.Transform(zip,(x)=>if x{0}<x{1} then -x{0} else x{0}),
                to  = List.Sum(tr2)
                ][to],
            
            from = Excel.CurrentWorkbook(){[Name="Таблица1"]}[Content],
            to   = Table.AddColumn(from,"arab",(r)=>unroman(r[r]))
        in
            to

    // Table.ReplaceRows и слияние записей – или нестандартное преобразование при группировке
    #АнатомияФункций - Table.ReplaceRows

    Подкинули интересную задачку на группировку – ничего сложного, просто преобразование по условию и разное для первой и последующих строк. Чего-то накатило сделать через Table.ReplaceRows. По этому поводу код:
    
        let
            from = Excel.CurrentWorkbook(){[Name="headcount"]}[Content],
            f=(x)=>[a = Table.Sort(x,{"headcount_Ставки, ед изм",Order.Descending}),
                    b = Table.TransformColumns(a,{"Ставки_Основное место",(x)=>"нет,внешний"}),
                    c = Table.ReplaceRows(b,0,1,{b{0}&[Ставки_Основное место="да,внешний"]}),
                    d = if List.Contains(x[Ставки_Основное место],"да") then x else c][d],
            gr = Table.Group(from,{"Ставки_Позиция","Период_int","Горизонт_маркер"},{"tmp",f}),
            to = Table.Combine(gr[tmp])
        in
            to
    ]
    
[   Record.HasFields или проверка наличия защиты листов книги / #АнатомияФункций - Record.HasFields
    
    Поскольку мне уже неоднократно задали этот вопрос пишу разбор. Итак задача: надо проверить на всех ли листах в файлах папки стоит «правильная» защита. Правильность в себя включает наличие пароля и возможности сортировки и фильтрации данных. Соответственно, если где-то это не так – нужно вывести список негодников.
    Ну ОК, вот код:

        let
            f=(x)=>[
                file = Binary.Buffer(x),
                book = Table.SelectRows(Excel.Workbook(file,false),(r)=>r[Kind]="Sheet"),
                xml  = Table.SelectRows(fxUnzip(file),(r)=>Text.Contains(r[Name],"xl/worksheets/sheet"))[Value],
                f=(x)=>Record.HasFields(Xml.Tables(x){[Name="sheetProtection"]}?[Table]?{0}? ?? [],{"Attribute:hashValue","Attribute:sheet","Attribute:sort","Attribute:autoFilter"}),
                lst  = List.Transform(xml,f),
                tbl  = Table.FromColumns(Table.ToColumns(book)&{lst},Table.ColumnNames(book)&{"protection"})
            ][tbl],
            
            folder = Folder.Files("путь к папке")[[Folder Path],[Name],[Content]],
            tr  = Table.TransformColumns(folder,{"Content",f}),
            exp = Table.ExpandTableColumn(tr,"Content",{"Item","protection"}),
            to  = Table.SelectRows(exp,(r)=>r[protection]=false)
        in
            to
    ]

[   Словари на записях против Table.Buffer / #АнатомияФункций – приёмы

        Всем привет!
        Мне опять попалось на глаза странное видео. Ещё раз убедился, что не зря не приветствую рекламу ютуб-каналов в чате.
        Пока у меня пригорало записал видос.
        Интересующиеся найдут там про Table.Buffer, яркий пример про (x)=> вместо each _ и даже про DateTime.ToText вместо даже не буду говорить чего.
        А вообще задачка про на словари на записях (неожиданно, правда?).
        Свой код привожу:

            let
                tbl  = Excel.CurrentWorkbook(){[Name="даты"]}[Content],
                tr   = Table.TransformColumns(tbl,{"month",(x) as text=>DateTime.ToText(x,"yyyy MMMM")}),
                f=(x)=>List.Transform({0..Duration.Days(x{2}-x{1})},(y)=>Text.From(Date.From(Number.From(x{1})+y))),
                cmb  = Table.CombineColumns(tr,List.Skip(Table.ColumnNames(tr)),f,"tmp"),
                exp  = Table.ExpandListColumn(cmb,"tmp"),
                dict = Record.FromList(exp[month],exp[tmp]),
                from = Excel.CurrentWorkbook(){[Name="база"]}[Content],
                to   = Table.AddColumn(from,"month",(x)=>Record.Field(dict,Text.From(Date.From(x[Дата]))))
            in
                to
    ]

[   #АнатомияФункций – приёмы / Splitter-ы 

    В чате уже заметили, что я решил помучить себя и окружающих темой Splitter-ов.
    По этому поводу демонстрационный видос. Вот код:
    
        let
            lst=List.Buffer({"0".."9"," "}),
            from = Excel.CurrentWorkbook(){[Name="Таблица1"]}[Content][Custom],
            f=(x)=>[a = Splitter.SplitTextByEachDelimiter({"/"},null,true)(x),
                    b = Splitter.SplitTextByEachDelimiter({" "},null,true)(a{0}),
                    c = Splitter.SplitTextByCharacterTransition((x)=>not List.Contains(lst,x),lst)(b{0}),
                    d = Combiner.CombineTextByDelimiter("")(Splitter.SplitTextByDelimiter(" ")(List.Last(c))),
                    z = {x, b{1} & "/c", Number.From(d)}][z],
            to = Table.FromList(from,f)
        in
            to
    ]

[   List.TransformMany или как ускорить запрос / #АнатомияФункций - List.TransformMany

    Всем привет!
    Решил записать разбор по поводу сегодняшнего обсуждения в чате - пилим полное декартово через List.TransformMany и разбираемся, почему исходный запрос "тупит" - вышло немножко долго, но на мой взгляд небезынтересно.
    Итоговая версия кода:
    
        let
            from = Excel.CurrentWorkbook(){[Name="input"]}[Content],
            f=(x)=>[a=Text.SplitAny(x{0},"()"),
                    aa=Text.Split(a{1},", "),
                    b=Text.SplitAny(x{1},"()"),
                    c=a{0},
                    d=List.Last(b),            
                    f=(x)=>Text.Split(b{1},"/"),
                    g=(x,y)=>[a=c&x&" "&y,b={a,a&" "&d}][b],
                    e=List.TransformMany(aa,f,g)][e],
            to = Table.FromList(List.Combine(Table.ToList(from,f)),(x)=>x,{"Номенклатура","ИД"})
        in

    to
    А всяческие телодвижения, сравнения и комментарии – смотрим в 17:00 на Ютубе (https://youtu.be/uEj494D0_R4)
 ]

[   LocalNow vs FixedLocalNow или который час? / #АнатомияФункций - DateTime.LocalNow, DateTime.FixedLocalNow, DateTimeZone.UtcNow, DateTimeZone.FixedUtcNow , DateTimeZone.LocalNow, DateTimeZone.FixedLocalNow

    Всем привет!

    В каментах просили разобрать разницу между функциями получения текущих даты и времени. Базово функций три:
    DateTime.LocalNow       – возвращает системные дату и время;
    DateTimeZone.LocalNow   – возвращает системные дату, время и часовой пояс
    DateTimeZone.UtcNow     – возвращает всемирное координированное время

    При этом у каждой есть её фиксированный вариант - DateTime.FixedLocalNow, DateTimeZone.FixedLocalNow, DateTimeZone.FixedUtcNow.
    Идея фиксации состоит в том, что в ходе запроса функция вычисляется ровно один раз и уже не меняет своё значение при множественных вызовах. 

    Давайте сравним:

        let
            tr  = List.Count(List.Distinct(List.Transform({1..100000},(x)=>DateTime.LocalNow()))),//<>1
            tbl = Table.RowCount(Table.Distinct(Table.FromList({1..100000},(x)=>{DateTime.LocalNow()}))),//<>1
            acc = List.Count(List.Distinct(List.Accumulate({1..1000},{},(x,y)=>x&{DateTime.LocalNow()})))//<>1
        in

    acc
    На каждом шаге запроса вы сможете увидеть значение, отличающееся от единицы – происходит множественный вызов функции, соответственно значения отличаются (вообще они отличаются в долях секунды, поэтому если вас интересует только текущая дата – это ни разу не принципиально)

    Но при этом фиксированные варианты дадут:
    
        let
            tr  = List.Count(List.Distinct(List.Transform({1..100000},(x)=>DateTime.FixedLocalNow()))),//1
            tbl = Table.RowCount(Table.Distinct(Table.FromList({1..100000},(x)=>{DateTime.FixedLocalNow()}))),//1
            acc = List.Count(List.Distinct(List.Accumulate({1..1000},{},(x,y)=>x&{DateTime.FixedLocalNow()})))//1
        in
            acc
    
    Т.е. видим, что действительно на каждом шаге ровно одно уникальное датавремя.

    Если кому-то принципиальны доли секунды и он уже побежал переписывать все свои запросы – остановитесь! И посмотрите следующий код:
    
        let
            now = DateTime.LocalNow(),
            tr  = List.Count(List.Distinct(List.Transform({1..100000},(x)=>now))),//1
            tbl = Table.RowCount(Table.Distinct(Table.FromList({1..100000},(x)=>{now}))),//1
            acc = List.Count(List.Distinct(List.Accumulate({1..1000},{},(x,y)=>x&{now})))//1
        in
            acc

    Т.е. если вы, как и я, являетесь противниками множественных вызовов и используете переменные (в данном случае now), то проблемы у вас нет – функция вызывается один раз при вычислении переменной. Заодно это немного (процентов на 5%) ускоряет вычисления – мелочь, а приятно.

    Ну и раз уж нас интересует прям точное время, то нельзя не вспомнить, что, например, в командировке у вас может измениться часовой пояс и могут «поехать» вычисления. В этой ситуации целесообразно это учитывать и в переменную засовывать функции, учитывающие часовой пояс, результат выполнения которых можно пересчитать на интересующий. В примере ниже в переменных оказывается Питерское время, даже если я в Шанхае:
    
        let
            now  = DateTime.From(DateTimeZone.SwitchZone(DateTimeZone.UtcNow(),3)),
            now1 = DateTime.From(DateTimeZone.SwitchZone(DateTimeZone.LocalNow(),3)),
            now2 = DateTime.From(DateTimeZone.SwitchZone(DateTimeZone.FixedUtcNow(),3)),
            now3 = DateTime.From(DateTimeZone.SwitchZone(DateTimeZone.FixedLocalNow(),3))
        in
            now3

    Как-то так. Нет «правильных» или «неправильных» функций, есть вполне конкретное их поведение, которое нужно учитывать при написании кода )))

    Ну а разбор всего этого безобразия смотрите, как всегда, на Ютубе  (https://youtu.be/XMUfmXSjmB0)
 ]

[   Xml.Tables, Xml.Document - Получаем форматы для ячеек - жирный шрифт, жёлтая заливка и т.д. / #АнатомияФункций - Xml.Tables, Xml.Document

    Всем привет!
    Пришло время ответить на вопрос - можно ли получить данные только из ячеек, залитых жёлтым, или с красным шрифтом, или жирным и т.п. Глобально – можно., но…
    Получилось долго, потому как там всё непросто - так что решайте сами, надо ли вам оно )))
    Вот код:
        let
            file  = File.Contents("путь/файл.xlsx"),
            unz   = fxUnzip(file),
            book  = Table.SelectRows(Excel.Workbook(file,false),(r)=>r[Kind]="Sheet"),
            style = Xml.Tables(unz{[Name="xl/styles.xml"]}[Value]),
            cellstyle = Table.Buffer(style{[Name="cellXfs"]}[Table]{0}[xf]),
            font = style{[Name="fonts"]}[Table]{0}[font],
            fill = style{[Name="fills"]}[Table]{0}[fill],
            n=1,
            sheet = book{n-1}[Data],
            sheetdata = Xml.Document(unz{[Name="xl/worksheets/sheet"&Text.From(n)&".xml"]}[Value]){0}[Value]{[Name="sheetData"]}[Value],
            f=(x)=>Number.From(x{0}[Attributes]{[Name="s"]}?[Value]?),
            tr   = Table.TransformColumns(sheetdata,{{"Attributes",(x)=>x{[Name="r"]}[Value]},{"Value",f}}),
            dict = Record.FromList(tr[Value],tr[Attributes]),
            min  = List.Min(List.Transform(tr[Attributes],Number.From)),
            add  = Table.AddIndexColumn(sheet,"row",min),

            tr1  = Table.TransformColumns(add,{"row",(x)=>Record.FieldOrDefault(dict,Text.From(x))}),
            tr2  = Table.TransformColumns(tr1,{"row",(x)=>if x=null then null else cellstyle{x}}),
            tr3  = Table.TransformColumns(tr2,{"row",(x)=>[a=Number.From(x[#"Attribute:fontId"]?),b=if a=null then null else font{a}[b]][b]}),
            skip = Table.PromoteHeaders(Table.Skip(tr3,(r)=>r[Column7]=null)),
            to   = Table.SelectRows(skip, each ([Column8] = ""))
            /*цвет шрифта - tr3=Table.TransformColumns(tr2,{"row",(x)=>[a=Number.From(x[#"Attribute:fontId"]?),b=if a=null then null else font{a}[color]{0}[#"Attribute:rgb"]?][b]}) 
            цвет заливки - tr3=Table.TransformColumns(tr2,{"row",(x)=>[a=Number.From(x[#"Attribute:fillId"]?),b=if a=null then null else fill{a}[patternFill][fgColor]?{0}?{0}?[#"Attribute:rgb"]?][b]})*/
        in
            to
    ]
[   Xml.Document vs Xml.Tables, рекурсивный обход и слетевшая кодировка / #АнатомияФункций - Xml.Document

    Всем привет!
    В чат подкинули задачку про сбор данных из xml. Вроде всё просто, но пришлось повозиться с именами файлов, осуществить рекурсивный обход и оформить пару функций. По этому поводу код:
    
    let
        f=(x)=>Text.FromBinary(Text.ToBinary(x,866)),
        g=(x)=>[a = Table.Buffer(x[[Name],[Value]]),
                b = Table.SelectRows(a,(r)=>r[Value] is table),
                c = Table.SelectRows(a,(r)=>not (r[Value] is table)),
                d = if Table.RowCount(b)=0 then a else c & @g(Table.Combine(Table.ToList(b,h)))][d],
        h=(x)=>Table.TransformColumns(x{1},{"Name",(r)=>x{0}&"/"&r}),
        
        from = Folder.Files("C:\Users\muzyk\Desktop\XML_файлы")[[Name],[Content]],
        tr   = Table.TransformColumns(from,{{"Name",f},{"Content",(x)=>Record.FromTable(g(Xml.Document(x)))}}),
        nms  = List.Distinct(List.Combine(List.Transform(tr[Content],Record.FieldNames))),
        to   = Table.ExpandRecordColumn(tr,"Content",nms)
    in
        to

    Ну а что тут к чему смотрите, как всегда, на Ютубе  (https://youtu.be/OsfOCQZvBRM)
 ]
    
[   Удаление пустых строк (а на списках точно быстрее?) / #АнатомияФункций – List.RemoveMatchingItems, List.RemoveNulls, List.Repeat, Record.FromList

    Всем привет!
    В чате задали вопрос про удаление пустых строк, а именно: является ли мышкоклацный код слишком навороченным:
    
        let
            laiyuan = Excel.CurrentWorkbook(){[Name="biao"]}[Content],
            jieguo  = Table.SelectRows(laiyuan, each not List.IsEmpty(List.RemoveMatchingItems(Record.FieldValues(_), {"", null})))
        in
            jieguo
    
    Ответ – нет, вполне прозрачный и логичный код, достаточно универсальный.
    Но вот если в таблице пустые строки содержат только null (а именно так было у автора вопроса), то действительно, можно и подсократить:
    
        let
            laiyuan = Excel.CurrentWorkbook(){[Name="biao"]}[Content],
            jieguo  = Table.SelectRows(laiyuan,(j)=>List.RemoveNulls(Record.ToList(j))<>{})
        in
            jieguo
    
    А сократив, стоит задуматься о вычислительной эффективности и, например, переписать так:
    
        let
            laiyuan = Excel.CurrentWorkbook(){[Name="biao"]}[Content],
            liebiao = List.Buffer(List.Repeat({null},Table.ColumnCount(laiyuan))),
            jieguo  = Table.SelectRows(laiyuan,(j)=> Record.ToList(j)<> liebiao)
        in
            jieguo
    
    А ещё лучше так:
        
        let
            laiyuan = Excel.CurrentWorkbook(){[Name="biao"]}[Content],
            jilu    = Record.FromList(List.Repeat({null},Table.ColumnCount(laiyuan)),Table.ColumnNames(laiyuan)),
            jieguo  = Table.SelectRows(laiyuan,(j)=>j<>jilu)
        in
            jieguo

    Ну а насколько лучше получился код и вообще, что тут к чему смотрите , как всегда, на Ютубе (https://youtu.be/22cDyrsKUNE) 
 ]

[   Удаляем текст в скобках (без регулярок и СМС) / #АнатомияФункций – приёмы

    Всем привет! 
    Сегодня разбираем задачку «Как можно в столбце удалить все значения в скобках?».

    Для начала решим «строго по условию»:
    
        let
            f=(x)=>[
                a = List.Transform(
                        List.Split({-1} & List.RemoveLastN(Text.PositionOfAny(x,{"(",")"},Occurrence.All),1), 2),
                        (x)=>{ x{0}+1, x{1}-x{0}-1}
                    ),
                b = Text.Combine(Splitter.SplitTextByRanges(a)(x))
            ][b],
            
            from = Excel.CurrentWorkbook(){[Name="Таблица2"]}[Content],
            to   = Table.TransformColumns(from,{"Столбец1",f})
        in
            to

    Делим строго по скобкам… но как-то сложно и медленно. 
    ОК, что насчёт рекурсии?
    //  удаляем все что в скобках вместе со скобками!
        let
            f=(x)=>[ 
                a = Text.PositionOf(x,"("),
                b = if a = -1 then x else @f(Text.RemoveRange(x,a,Text.PositionOf(x,")")-a+1))
            ][b],
            
            from = Excel.CurrentWorkbook(){[Name="Таблица2"]}[Content],
            to   = Table.TransformColumns(from,{"Столбец1",f})
        in
            to

    Так, как минимум, быстрее, да и поприкольнее. 

    Вот только надо ли оно всё? 
    Если больше не к чему привязаться – надо, а в конкретном случае (в примере) можно:
        let
            f=(x)=>Text.Combine(List.Transform(Text.Split(x,", "),(x)=>Text.Split(x,"("){0}),", "), // до запятой удаляет
            from = Excel.CurrentWorkbook(){[Name="Таблица2"]}[Content],
            to   = Table.TransformColumns(from,{"Столбец1",f})
        in
            to
    
        let
            f=(x)=>Text.Combine(List.Select(Text.SplitAny(x,"(,"),(x)=>not Text.Contains(x,")")),","),  // оставляет если внутри запятые и точки
            from = Excel.CurrentWorkbook(){[Name="Таблица2"]}[Content],
            to   = Table.TransformColumns(from,{"Столбец1",f})
        in
            to
    
        let
            f=(x)=>Text.Combine(List.Alternate(Text.SplitAny(x,"(,"),1,1,1),", "), // плохо удаляет, после первой запятой
            from = Excel.CurrentWorkbook(){[Name="Таблица2"]}[Content],
            to   = Table.TransformColumns(from,{"Столбец1",f})
        in
            to

    Бонус на формулах и объяснение того, что тут к чему, как всегда, смотрим на Ютубе  (https://youtu.be/nnDq_FgV2jo)
 ]

[   Приматываем РЕГУЛЯРКИ (RegExp) / #АнатомияФункций – приёмы

    Всем привет!
    В продолжение прошлого поста – решаем ту же задачу, но через регулярные выражения.
        
        let
            f=(x)=>Web.Page("<script>document.write('"&x&"'.replace(/\([^()]+\)/g,''))</script>"){0}[Data]{0}[Children]{1}[Children]{0}[Text],

            from = Excel.CurrentWorkbook(){[Name="Таблица2"]}[Content],
            to   = Table.TransformColumns(from,{"Столбец1",f})
        in
            to

    Код ни разу не громоздкий, через регулярки… 
    Так почему я назвал это костылями? 
    А потому что на них бегать неудобно. И на самом деле код должен выглядеть как-то так:
    
        let
            f=(x)=>Web.Page("<script>document.write('"&x&"'.replace(/\([^()]+\)/g,''))</script>"){0}[Data]{0}[Children]{1}[Children]{0}[Text],

            from = Excel.CurrentWorkbook(){[Name="Таблица2"]}[Content],
            lst  = List.Buffer(Text.Split(f(Text.Combine(from[Столбец1],"@")),"@")),
            add  = Table.AddIndexColumn(from,"i"),
            to   = Table.CombineColumns(add,{"i","Столбец1"},(x)=>lst{x{0}},"Столбец1")
        in
            to

    Ну а почему и зачем так – смотрите на Ютубе  (https://youtu.be/4D4H3uP5QMo)
 ]