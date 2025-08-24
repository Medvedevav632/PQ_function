/*  
    Table.InsertRows
    
    В таблице (2 колонки) оставляем 10 позиций + добавляем строку остальные в после строки 10
    Имя поля можно через #"Показатель"
*/

let
    Source = Excel.CurrentWorkbook(){[Name="Таблица1"]}[Content],
    sorted = Table.Sort(Source,{{"Значение", Order.Descending}}),
    top10  = Table.FirstN(sorted, 10),
    insert = Table.InsertRows(top10, 10, {
				[   
                    Название = "(остальные)", 
					Значение = List.Sum(Source[Значение]) - List.Sum(top10[Значение])
                ]
			 })
in  insert

