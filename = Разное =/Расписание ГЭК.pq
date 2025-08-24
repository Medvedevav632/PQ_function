// (x)=>
let 
   from = Table.SelectRows(Raspisanie_, each ([Name]="Ес-3з_ФЭУз_ГЭК.xlsx"))[Data]{0},
    // from = x,
    
    fx = [
        fxSkipAllMulti    = (x)=>(y)=>not List.ContainsAny({Text.Combine( List.Select( Record.ToList(y), (i)=>i is text))}, x, Text.Contains), // по всей таблице + мульти выбор
        fxSkipRowsUpDown  = (x, txt)=>(y)=>not Text.Contains( Text.Combine( List.Select( Record.ToList(Record.SelectFields(y, txt)), (i)=>i is text)), x), // по колонке + одно слово
        fxTextReplace     = (dictionary as list, row) => List.Accumulate(dictionary, row, (s,c)=>Text.Replace(s,c{0},c{1})),
        fxAddMultiCol     = (tbl as table, col as list) as table => List.Accumulate(col, tbl, (t, d) => Table.AddColumn(t, d{0}, d{1}, d{2}?)),
        fxAllColumnText   = (tbl as table) => Table.TransformColumnTypes(tbl, List.Transform(Table.ColumnNames(tbl), (x)=>{x,type text}) ),
        fxReorderСolumns  = (tbl as table, nms as list, offset as number) as table => Table.ReorderColumns(tbl, List.InsertRange( List.Difference( Table.ColumnNames(tbl), nms), offset, nms )),
        fxRemoveNullCols  = (tbl as table)=> Table.RemoveColumns(tbl, List.Select(Table.ColumnNames(tbl), (x)=>Text.StartsWith(x,"Column")) ),
        fxRemoveNullCols2 = (table, optional options) => let tbl = Table.Buffer(Table.Profile(table)), lst = Table.SelectRows(tbl,(x)=>x[Count]=x[NullCount])[Column], to  = Table.RemoveColumns(table,lst) in  to,
        fxRemoveNullRows  = (tbl as table)=> Table.SelectRows(tbl, each not List.IsEmpty(List.RemoveMatchingItems(List.Transform(List.RemoveMatchingItems(Record.FieldValues(_), {"", null}), each try Text.Clean(Text.Trim(_)) otherwise _ ),{""})))
    ],

    // чистим строки сверху и снизу найденных ключевых слов
    skip = [
        a = Table.PromoteHeaders(Table.Skip(from, fx[fxSkipAllMulti]({"Дни"}) )), // верх
        b = Table.RemoveLastN(Table.RemoveLastN(a, fx[fxSkipAllMulti]({"Специалист","Начальник"}) ), 2) // низ
    ][b],

    // 1. удаляем остатки лишних строк. Например может второй раз появиться заголовок Дни/Время/Предмет, 
    // если длинное расписание, например для заочников
    // если в столбце есть null то будет ошибка, поэтму надо :
    //  - либо обработать - не Text.Contains, a через (x)=>Text.Contains(x, "Дни"))!!!
    //  - либо заменить null на "".
    delOtherRows = [
	    a = Table.ReplaceValue(skip, null, "", Replacer.ReplaceValue, {"Дни"}),
        f = (x)=> List.ContainsAny({x[Дни]}, {"среда"}, (x)=>Text.Contains(x, "Дни")),
		b = Table.SelectRows(skip, f) // особенность
    ][b],
			
    // 2. трансформируем столбец "Дни" в подтаблицах для заполнения вниз
    // чистим колонку "Дни" исходя из типа расписания: стационар, заочники
	// 	f - функция возвращяет true, если первый символ является числом
	// 	    f=true  - если стационар или магистратура, то оставляем дни недели (строчные), а даты убираем
	// 	    f=false - если заочники или ФПК, то оставляем даты, а дни недели убираем
	//  с - могут быть ячейки с null => ?! проверить
    transformColumns = Table.TransformColumns(delOtherRows,{ 
        {"Дни", (x)=> [
		            fxIsNumber = List.ContainsAny ({ Text.Start(x,1) }, {"0".."9"}, Text.Contains), 
                    fxTip2=(x)=>if fxIsNumber = false then null else x,                                
                    a = fxTip2(x),
                    c = try if Text.Length(a)>0 then a else null otherwise null
                ][c], type text},
                
        // трансформируем столбец "Время"
        //  a = типизируем столбец как время
        //  b = если значение не входит в список времени начала пар, тогда null
        {"Время", (x)=>[
                    a = try Time.From(Text.Replace(Text.BeforeDelimiter(x, "-"),".",":")) otherwise null,
                    b = if List.ContainsAny({a}, СпрВремяПары[Начало]) then a else null
                  ][b], type time}
    }) ,
        
    // чистим все колонки начиная с третьей и дальше
    transformColumns2 = [
        f=(x)=> [   a = Text.Combine(List.RemoveMatchingItems( Text.SplitAny( Text.Clean(x), "#(lf)#(00A0)#(tab) "), {""}), " "),
                    b = List.Accumulate(Text.ToList(a),"",(s,c)=> if c<>"—" then s&c else if Text.EndsWith(s,"/") then s else s&"/"),             
                    c = try if Text.Length(b) > 0 then b else null otherwise null
                ]  [c],
        // делаем колонки 3+: чистыми, текстовыми, с заменой "---" на "/"
        to = Table.TransformColumns(
                    transformColumns,
                    List.Transform(List.Skip(Table.ColumnNames(transformColumns), 2),(x)=>{x, f, type text})
            )
    ][to],

    // удаляем пустые строки и столбцы
    remRowsCols = [
        a = fx[fxRemoveNullRows](transformColumns2),
        b = fx[fxRemoveNullCols2](a) // пустые столбцы по содержанию
    ][b],
    
    // добавляем колонку с количеством непустых ячеек в строке начиная с третье колонки и дальше
    add = [
        f=(x)=> List.Count(List.RemoveMatchingItems(List.RemoveFirstN(Record.ToList(x),2),{null,""})),
        a = Table.AddColumn(remRowsCols, "Count", f),
        b = Table.TransformColumnTypes(a, {"Count", type text})
    ][b],
    
    // число заполненных ячеек без первых двух колонок - это шапка талицы внутри расписания подгруппами
    max = Text.From(List.Max(add[Count])),

    // функция группировки двух и более строк в одну строку при заволненных колонках Дни и Время
    fxGroup = (tbl as table)=>[ 
        from  = tbl,
        nms   = List.Transform( 
                    List.Skip(Table.ColumnNames(from), 2), // не трогаем 2 колонки справа, Дни и Время
                    (x)=>{x, (t)=>Text.Combine(Table.Column(t,x)," "), type text} // функция с 3 элементами
                ),
        lst   = List.FirstN(Table.ColumnNames(from), 2),
        group = Table.Group(from, lst, nms)
    ][group],

    // преобразуем таблицу в ордну или две, исходя их того, сколько подгрупп идет на экзамен
    trans = if Number.From(max) = 1
        then 
            // если группа одна, то с одного захода чистим и сворачиваем список
            let b  = Table.RemoveColumns(add, List.LastN(Table.ColumnNames(add), 1)), // удаляем последлнюю колонку
                c  = Table.FillDown(b, {"Дни", "Время"}),
                d  = fx[fxRemoveNullCols2](c),
                gr = fxGroup(d),
                unp= Table.UnpivotOtherColumns(gr, {"Дни", "Время"}, "Атрибут", "Значение")
            in  unp
        else
            // если групп больше одной, то делим таблицу на верхнюю и нижнюю часть, потом объединяем
            let part1  = [ // верхняя часть - обзорные лекции
                    a  = Table.RemoveLastN(Table.RemoveLastN(add, fx[fxSkipRowsUpDown](max,"Count")), 1), // удаляем строки НИЖЕ
                    b  = Table.RemoveColumns(a, List.LastN(Table.ColumnNames(a), 1)),
                    c  = Table.FillDown(b, {"Дни", "Время"}),
                    d  = fx[fxRemoveNullCols2](c),
                    gr = fxGroup(d),
                    unp= Table.UnpivotOtherColumns(gr, {"Дни", "Время"}, "Атрибут", "Значение")
                ][unp],
                
                part2 = [ // нижняя часть - консультации + экзамены + еще может быть защита отчетов
                    a  = Table.PromoteHeaders(Table.Skip(add, fx[fxSkipRowsUpDown](max,"Count") )), // удаляем строки ВЫШЕ
                    b  = Table.RemoveColumns(a, List.LastN(Table.ColumnNames(a),1)), // удаляем последнюю колонку с ключевыми числами
                    c  = Table.RenameColumns(b,{{"Column1", "Дни"}, {"Column2", "Время"}}), // переименовываем первые две, так как перх удаллили
                    d  = Table.FillDown(c, {"Дни", "Время"}),    // заволняем вниз
                    gr = fxGroup(d),    // сворачиваем все в одну строку
                    e  = Table.UnpivotOtherColumns(gr, {"Дни", "Время"}, "Атрибут", "Значение"), // разворачиваем
                    g  = Table.SelectRows(e, each ([Значение] <> "")) // убираем пустые строки
                ][g],
                
                Combine = Table.Combine({part1, part2})
            in  Combine
in
    trans