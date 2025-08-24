let 

DataAnalysis =[ // https://github.com/AnHerbWorm/DataAnalysis/blob/main/powerquery/List_Combinations.pq
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
            Climate.ApplySchema = 
                (table as table) as table => 
                    Table.TransformColumnTypes(
                        table,
                        List.Transform(
                            Type.TableSchema(Climate.CSVSchema)[Name], 
                            each {_, Type.TableColumn(Climate.CSVSchema, _)}
                        )
                    ),  
            Climate.MakeURL = 
                (stationID as number, year as number) as text => 
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
            MakeDateRange = 
                (start as date, end as date) as table => 
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

    CurrentWorkbook_NamedRange = 
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

    Template_FuncWithDocs = 
        /*
            * Short, one sentence query description
            *
            * Long query description. Should also be added to Documentation.LongDescription
            * in the Main.Docs record.
            *
            * @name QueryName
            * @categories relevant tag, another relevant tag
            * @license MIT (c) 20## W Bohm
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

    Table_GroupWithTotals = 
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

    Table_AddGroupIndex   = 
        /* 
            * chains Table.ExpandTableColumn(Table.AddIndexColumn(Table.Group)) functions to append a new index column
            * identifying which group each row in the source table belongs to
            *
            * @name Table.AddGroupIndex
            * @categories table
            * @license MIT (c) 2021 W Bohm
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
                        List.RemoveItems(Table.ColumnNames(table), if key is list then key else {key})
                ),

                Main.Type = Type.ForFunction(
                    [
                        ReturnType = type table,
                        Parameters = [
                            table = type table meta [
                                Documentation.FieldCaption = "source table"
                            ],
                            key = type anynonnull meta [
                                Documentation.FieldCaption = "column(s) to group on"
                            ],
                            newColumnName = type text meta [
                                Documentation.FieldCaption = "column name for index"
                            ]
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
                            Code = Text.Combine(
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
                            Result = Text.Combine(
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

    List_Combinations     = 
        /*
            generate all non-repeating combinations of size 'combinationSize' from a list, or if only a size is provided,
            all combinations of non-repeating indexes from 0 to (size - 1)
            
            if a list containing duplicates is provided, they will be carried through to the subset combinations
            
            @name List_Combinations
            @categories list
            @license MIT (c) 2021 W Bohm
            @author https://github.com/AnHerbWorm
            @source https://github.com/AnHerbWorm/DataAnalysis/tree/main/powerquery
            @result list of combinations (as lists)
        */
        let
            Main.Func = (setOrSize as anynonnull, combinationSize as number) as list =>
                let
                    SetSize = if setOrSize is number then setOrSize else List.Count(setOrSize),
                    Set = {0..SetSize -1},

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
                        Code = "List_Combinations({""A"", ""B"", ""C"", ""D"", ""E""}, 4)",
                        Result = "{#(lf)  {""ABCD""},#(lf)  {""BCDE""}#(lf)}"
                    ],
                    [
                        Description = "Subsets of 2 from 4 possible values (4 choose 2)",
                        Code = "List_Combinations(4, 2)",
                        Result = "{#(lf)  {0,1},#(lf)  {0,2},#(lf)  {0,3},#(lf)  {1,2},#(lf)  {1,3},#(lf)  {2,3}#(lf)}"
                    ]
                }
            ]
        in
            Value.ReplaceType(Main.Func, Main.Type meta Main.Docs)

],
IMKA = [
    LoadPath = "",
//  Date
    Date.EndOfLastMonth = 
        () =>
            Date.EndOfMonth(Date.AddMonths(Date.From(DateTime.FixedLocalNow()), -1))
        ,

    Date.EpochToDate    = 
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
    
    Date.FormatSQL      = 
        (DateValue as any) =>
        let  
            FormattedDate = DateTime.ToText(DateTime.From(DateValue), "yyyy-MM-ddT00:00:00", "en-US")
        in
            FormattedDate,

    Date.NDaysAgo       = 
        /*
            return date of N days ago from Today
            usage: 
            let
                Date.NDaysAgo = Load("Date.NDaysAgo")
            in
                Date.NDaysAgo(3)
            Result depends on Today
        */

        (N as number) => 
            Date.AddDays(DateTime.FixedLocalNow(), -N),

    Date.NDaysInFuture  = 
        (N as number) => 
            Date.AddDays(Date.From(DateTime.FixedLocalNow()), N),

    Date.StartOfCurrentYear =    
        () =>
            Date.StartOfYear(Date.From(DateTime.FixedLocalNow())),

    Date.StartOfLastYear =
        () =>
            Date.AddYears(Date.StartOfYear(Date.From(DateTime.FixedLocalNow())), -1),
    
    Date.StartOfMonth12MAgoExcCurMonth =
        () =>
            Date.StartOfMonth(Date.AddMonths(Date.From(DateTime.FixedLocalNow()), -12)),
    
    Date.StartOfMonth12MAgoIncCurMonth =
        () =>
            Date.StartOfMonth(Date.AddMonths(Date.From(DateTime.FixedLocalNow()), -11)),

    Date.Today          = 
        () =>
            Date.From(DateTime.FixedLocalNow()),
    
    Date.Tomorrow       = 
        () =>
            Date.AddDays(Date.From(DateTime.FixedLocalNow()), 1),

    Date.Yesterday      = 
        () =>
            Date.AddDays(Date.From(DateTime.FixedLocalNow()), -1),

    DateTime.FormatSQL  = 
        (DateTimeValue as any) =>
            DateTime.ToText(DateTime.From(DateTimeValue), "yyyy-MM-ddThh:mm:ss", "en-US"),

    DateTime.UnixTime   = 
        /*
            Convert unix timestamp into Power Query datetime formart
            Usage: DateTime_UnixTime(1526800525) = 20.05.2018 7:15:25
        */
        (unixtime as number) as datetime => 
            #datetime(1970, 01 , 01, 0, 0, 0) + #duration(0,0,0,unixtime),

//  Load Function
    F = 
        /*
            F (short for function), like Load(), provides one calling interface to access functions either imported (faster) or loaded (fallback), so code could be left agnostic to whether the queries are available locally, though whether this is really necessary is left up to the user to decide. One reasonable use case would be allowing many workbooks to access a shared library of queries from their files without needing to import them to each workbook after every change.

            F (сокращение от function), как и Load(), предоставляет один вызывающий интерфейс для доступа к функциям, импортированным (быстрее) или загруженным (резервный), поэтому код может оставаться независимым от того, доступны ли запросы локально, хотя действительно ли это необходимо. остается на усмотрение пользователя. Одним из разумных вариантов использования было бы предоставление многим книгам доступа к общей библиотеке запросов из своих файлов без необходимости импортировать их в каждую книгу после каждого изменения.

            Imported or loadable functions could be referenced as any of the following:
                Load("Text.ReplaceAll")
                Load("Text_ReplaceAll")
                F[Text.ReplaceAll]
                F[Text_ReplaceAll]

            Intended benefits of F over Load():
                - shorter
                - may help avoiding duplicate executions of file imports (if applicable) -- needs further testing though.

            Record.Rename = Load("Record.Rename"),
            Record.Rename = Record_Rename,

                Record.Rename = (Rec as record, Lambda as function) as record =>
                let
                    Keys     = Record.FieldNames(Rec),
                    Values   = Record.FieldValues(Rec),
                    Renamed  = List.Transform(Keys, each Lambda(_, Record.Field(Rec, _))),
                    Recorded = Record.FromList(Values, Renamed)
                in
                    Recorded,

            cyclic reference...?
            SharedPeriods = Record.Rename(Shared, (k,v) => Text.Replace(k, "_", ".")),
        */

        let
            Shared = #shared,

            SharedPeriods = Record.FromList(Record.FieldValues(Shared), List.Transform(Record.FieldNames(Shared), each Text.Replace(_, "_", "."))),

            SharedMerged = Record.Combine({Shared, SharedPeriods}),
            //If I can make a wrapper function to enable profiling/persistence, wrap these as well

            Files  = Folder.Files(LoadPath),
            MFiles = Table.SelectRows(Files, each Text.Lower([Extension]) = ".m"
            // and [Folder Path] = LoadPath    // non-recursive
            ),
            NoExt           = Table.TransformColumns(MFiles, {"Name", each Text.Start(_, Text.Length(_)-2)}),
            CustomNames     = Table.Column(NoExt, "Name"),
            Underscored     = List.Transform(CustomNames, each Text.Replace(_, ".", "_")),
            CustomBoth      = List.Union({CustomNames, Underscored}),
            CustomLoaded    = Record.FromList(List.Transform(CustomBoth, Load), CustomBoth),
            SharedAndLoaded = Record.Combine({CustomLoaded, SharedMerged}),

            Return = SharedAndLoaded
        in
            Return,

    Files.SheetsInFolder  = 
        /*
            Description:
                Create a table with info on all sheets in any Excel files in a particular folder.
                Создать таблицу с информацией обо всех листах в любых файлах Excel в определенной папке.
            
            Usage:
                Files.SheetsInFolder = Load("Files.SheetsInFolder"),
                Source = Files.SheetsInFolder("C:\path\to\my\folder\")
            
            Result: 
                [a table containing the binary file content, file names, sheet tables, and sheet names for each sheet in each spreadsheet in the given folder]
                [таблица, содержащая содержимое двоичного файла, имена файлов, таблиц листов и названия листов для каждого листа в каждой электронной таблице в данной папке]
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

    Function.Profile      = // профилирует время, необходимое для выполнения функции для заданных параметров.
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

//  List
    List.CrossJoin        = // возвращает перекрестное соединение двух списков в виде таблицы
        /*
            Returns the Cartesian product (i.e. crossjoin) of two arguments (can be lists or tables).
            Возвращает перекрестное соединение двух аргументов (могут быть списками или таблицами)

            Usage:
                List.CrossJoin = Load("List.CrossJoin"),
                List.CrossJoin({"A","B"},{1..3})
            
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

    List.Dates.HolidaysRU = 
        // Function gets list of non-working days (weekends and official holidays) 
        // from official source "Open Data" managed by Analytical Center of Russian Federation
        //
        // Function has two arguments - From_Year, To_Year
        // which allows to restrict period of time that you need for your data model.
        //
        // Usage:
        //  List.Dates.HolidaysRU( 2015, 2016 )
        // Response:
        //   List of non-working days in Russian Federations for years 2015 and 2016

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
    
    List.Dates.LastNDays  = 
        (N as number) => 
            List.Dates(Date.AddDays(Date.From(DateTime.FixedLocalNow()), -N), N, #duration(1,0,0,0)),

    List.Dates.LastNYears = 
        // last N years
        (N as number) =>
            let
                start = Date.StartOfYear(Date.AddYears(Date.From(DateTime.FixedLocalNow()), -N)),
                end = Date.EndOfYear(Date.AddYears(Date.From(DateTime.FixedLocalNow()), -1)),
                result = List.Dates(start, Duration.Days(end - start) + 1, #duration(1,0,0,0))
            in 
                result,

    List.Dates.LastNYearsAndCurYear  = 
        // last N years and Current year
        (N as number) =>
            let
                start = Date.StartOfYear(Date.AddYears(Date.From(DateTime.FixedLocalNow()), -N)),
                end = Date.EndOfYear(Date.From(DateTime.FixedLocalNow())),
                result = List.Dates(start, Duration.Days(end - start) + 1, #duration(1,0,0,0))
            in 
                result,

    List.Dates.NYearsToDate          = 
        // N years to today
        (N as number) =>
            let
                start = Date.StartOfYear(Date.AddYears(Date.From(DateTime.FixedLocalNow()), -N)),
                end = Date.From(DateTime.FixedLocalNow()),
                result = List.Dates(start, Duration.Days(end - start) + 1, #duration(1,0,0,0))
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
                start = Date.StartOfYear(Date.AddYears(Date.From(DateTime.FixedLocalNow()), -1)),
                end = Date.AddYears(Date.From(DateTime.FixedLocalNow()), -1),
                result = List.Dates(start, Duration.Days(end - start) + 1, #duration(1,0,0,0))
            in 
                result,

    List.DatesBetween   = // создает список дат между заданными двумя датами
        /*
            List_DatesBetween is an alternative for List.Dates function. It takes only two dates as arguments and creates a list of dates between given two dates. 
            List_DatesBetween является альтернативой функции List.Dates. 
            Он принимает только две даты в качестве аргументов и создает список дат между заданными двумя датами
            
            Usage: 
                List_DatesBetween(11/17/2016, 12/19/2016)
        */

        (dateStart as date, dateFinish as date) =>

        let
            countOfDays = Number.From(dateFinish - dateStart),
            output =    if countOfDays > 0 
                        then List.Dates(dateStart, countOfDays+1, #duration(1,0,0,0))
                        else "Error! Your inputs are incorrect. Check the inputs." 
        in
            output,

    List.FlatMap        = // сопоставляет список с помощью лямбды, объединяя все результаты в один список
        /*
            Maps a list using a lambda in such a way that all results are combined back into a single list
            Сопоставляет список с помощью лямбды таким образом, что все результаты снова объединяются в один список
            
            Usage:
                let
                    List.FlatMap = Load("List.FlatMap")
                in
                    List.FlatMap({1,2,3}, (_) => List.Numbers(1, _))
            Result: //? проверить
                {1, 1, 2, 1, 2, 3}
        */

        (lst as list, fn as function) => List.Combine(List.Transform(lst, fn)),

    List.RankDense      = // ранжирует входное значение в серии. Удаляет дубликаты, чтобы ранжировать уникальные значения 
        /*
            Ranks an input value in a series (ascendingly or descendingly). Removes duplicates to rank only unique values.
            Ранжирует входное значение в серии (по возрастанию или убыванию). Удаляет дубликаты, чтобы ранжировать только уникальные значения.
            
            Originally written by Colin Banfield: 
            http://social.technet.microsoft.com/Forums/en-US/973e9381-ff46-4756-a071-88bb4c2105e4/pushing-more-calcs-to-power-query-replacing-dax-rankx

            Usage:
                List.RankDense = Load("List.RankDense"),
                List.RankDense("B",{"A","A","B","C"})
            
            Result: // ? что то не то
                3
        */

        (inputValue as any, inputSeries as list, optional orderDescending as nullable logical) as number => 
        let
            order = if orderDescending or orderDescending = null 
                    then Order.Descending 
                    else Order.Ascending,
            SortedSeries    = List.Sort(inputSeries, order),
            DistinctSeries  = List.Distinct(SortedSeries),
            RankDense       = List.PositionOf(DistinctSeries,inputValue)+1
        in
            RankDense,

    List.RankEqual      = // ранжирует входное значение в серии. Не фильтрует дубликаты 
        /*
            Ranks an input value in a series (ascendingly or descendingly). Does not filter out duplicates.
            Ранжирует входное значение в серии (по возрастанию или убыванию). Не фильтрует дубликаты.

            Originally written by Colin Banfield: 
            http://social.technet.microsoft.com/Forums/en-US/973e9381-ff46-4756-a071-88bb4c2105e4/pushing-more-calcs-to-power-query-replacing-dax-rankx

            Usage:
                List.RankEqual = Load("List.RankEqual"),
                List.RankEqual("B",{"A","A","B","C"})
            Result: 
                3
        */

        (   inputValue as any, 
            inputSeries as list, 
            optional orderDescending as nullable logical
        ) as number => 
        
        let
            order = if orderDescending or orderDescending = null 
                    then Order.Descending 
                    else Order.Ascending,
            SortedSeries = List.Sort(inputSeries, order),
            RankEqual    = List.PositionOf(SortedSeries,inputValue) + 1
        in
            RankEqual,

    List.RemoveErrors   = // удаляет из списка Error (с трансформацией списка в таблицу, через Table.RemoveRowsWithErrors)
        (ListWithErrors as list) as list =>
        /*
            Takes list as input and returns the same list but without Error values.
            Useful when errors came to list/column from external source, and there are no possibility to eliminate errors before using a list

            Принимает список в качестве входных данных и возвращает тот же список, но без значений ошибок.
            Полезно, когда ошибки в список/столбец пришли из внешнего источника и нет возможности устранить ошибки перед использованием списка.
            
            Usage:
                = List.RemoveErrors({1,2,error "this is an error",4})
            
            Returns:
                {1,2,4}
        */

        let
            CleanList = Table.RemoveRowsWithErrors(Table.FromColumns({ListWithErrors}))[Column1]
        in
            CleanList,

    List.RemoveErrorsV2 = // удаляет из списка Error (без трансформации списка в таблицу, через List.Accumulate)
        /*  
            removes error values from list (without replacement) without "convert to table / remove rows"
            удаляет значения ошибок из списка (без замены) без «конвертировать в таблицу/удалять строки»

            Author: Owen Auger https://nz.linkedin.com/in/owenauger http://owenaugerblog.wordpress.com/
            Source: http://community.powerbi.com/t5/Desktop/Removing-errors-from-list-not-column-in-Power-Query-M/m-p/78765
        */

        (ListWithError as list) as list =>
        let
            Source = 
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
        in
            Source,

    List.ReplaceErrors  = // заменяет значения ошибок в списке null или переданным значением замены
        /*
            Replaces error values in given list with passed replacement value (or with null if replacement is omitted)
            Заменяет значения ошибок в данном списке переданным значением замены (или нулем, если замена опущена)
        */

        (ListWithError as list, optional Replacement as any) as list =>
        let
            Source = 
                List.Transform(
                    List.Positions(ListWithError), 
                    each try ListWithError{_} otherwise Replacement
                )
        in
            Source,
    
    List.ToRecord       = // преобразовывает список строк в запись, используя заданную лямбда функцию (переданные значения k)
        /*
            Transform a list of strings to a record using a given lambda (passed values k)
            The built-in Record.FromList only takes static lists...
            
            Преобразовать список строк в запись, используя заданную лямбду (переданные значения k)
            Встроенный Record.FromList принимает только статические списки...

            Usage:
                let
                    List.ToRecord = Load("List.ToRecord"),
                    list = {"a","b"}
                in
                    List.ToRecord(list, (k) => Text.Upper(k))
            Result: 
                [a="A", b="B"]
        */

        (List as list, Lambda as function) as record =>
        let
            Transformed = List.Transform(List, Lambda)	//each Lambda(_)
        in
            Record.FromList(Transformed, List),

    List.ToText         = // создает текстовое представление списка
        /*
            Create text representation of given List to use further in Power Query code
            Создайте текстовое представление данного списка для дальнейшего использования в коде Power Query
            
            Usage: 
                List_ToText({"abc","def","hgk"}) = {"abc","def","hgk"}
        */
    
        (list1 as list) as text =>
            "{""" & 
            Text.Combine(list1, """, """) & 
            """}",

    List.Zip            = // создает список списков, чтобы «транспонировать» их — как записи, если указаны имена
        /*
            Zip a list of lists so as to 'transpose' them -- as records if names are specified.
            
            Usage:
                List.Zip = Load("List.Zip"),
                List.Zip(
                    {   
                        {1,2,3},
                        {"a","b","c"}
                    }, 
                        {"num","let"}
                )
            
            Result: 
                {   
                    [num=1, let="a"],
                    [num=2, let="b"],
                    [num=3, let="c"]
                }
        */

        (listOfLists as list, optional names as list) as list =>
        let
            max = List.Max(List.Transform(listOfLists, each List.Count(_))),
            zipped = List.Skip(
                List.Generate( ()=> [
                    i = -1,
                    vals = {},
                    combined = {}
                ],
                each [i] < max,
                each [
                    i = [i] + 1,
                    vals = List.Transform(listOfLists, each _{i}),
                    combined = 
                        if names = null 
                        then vals 
                        else Record.FromList(vals, names)
                ],
                each [combined]
            )),
            tablized = Table.FromRecords(zipped) //Table.FromRows
        in
            tablized,

//  Load, M
    Load        = 
        /*
            Allows dynamically loading an M function from a text file (extension: .pq) in a given folder for use in Power Query. This allows you to easily reuse  a set of functions in multiple workbooks without having to sync each change to all files using it.
            The point here is that by separating universally useful functions from an individual workbook, you will feel encouraged to use more modular code,  solving each common sub-problem only once, rather than remaining stuck in 'vanilla' M and resolving the same problems repeatedly.
            Moreover, coding this way will also further facilitate sharing code with other Power Query users, allowing for a more collaborative environment, gradually pushing forward the Power Query community as a whole.
            Nevertheless, if the function in question has already been imported into the workbook, the local copy will be used. This would allow you to either call the function locally right away, or Load() the existing function again.
            Using Load() would not only allow you to use functions in their intended naming conventions (i.e. Text.ReplaceAll rather than with the period replaced by an underscore), but would technically also allow you to add additional wrapper functions around your code, which could be used to enable persistent memoization (using say Redis) or code profiling calls... though presumably no-one has done this so far yet.
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

            Warning: this function may triggers a Formula.Firewall error for referencing both an external query (LoadPath) as well as external files.

            If you run into this, you can get around this by enabling the FastCombine option, in Power Query Options -> Privacy -> Fast Combine -> 'Ignore the 
            Privacy levels and potentially improve performance'.

            If you'd prefer not to do this however, you could also just replace the LoadPath/DefaultPath reference below with a static
            absolute path reference.

        */

        (fnName as text, optional BasePath as text) as function =>
        let
            //If you wish to hardcode the path to load the queries from, you can edit the following line:
            DefaultPath = "C:\PQuery\",
            GitHubPath = "https://raw.githubusercontent.com/hohlick/pquery/master/",
            
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
            
            Function = try Expression.Evaluate(Text.FromBinary(Binary.Buffer(File.Contents(File))), #shared)
            otherwise Expression.Evaluate( Text.FromBinary(Binary.Buffer(Web.Contents(GitHubPath & fnName & ".pq"))), #shared)
        in
            Function,

    LoadPath.example = "", 
        // Excel.CurrentWorkbook(){[Name="Table1"]}[Content]{0}[Path]
        
        // Copy this file to `LoadPath.pq`, and replace its contents with your query path, like this:
        // "D:\pquery\"

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

    M.constants = 
        let
            Source = M.library,
            Constants = Table.SelectRows(Source, each not Value.Is([Value], type type) and not Value.Is([Value], type function)),
            Return = Constants
        in
            Return,

    M.functions = 
        let
            Type.ToText  = Load("Type.ToText"),
            Value.ToText = Load("Value.ToText"),
            Text.Count   = Load("Text.Count"),
            Source       = M.library,
            
            Functions    = Table.SelectRows(Source, each Value.Is([Value], type function)),

            AddFType    = Table.AddColumn(Functions,    "FType",        each Value.Type([Value])),
            AddReturn   = Table.AddColumn(AddFType,     "Returns",      each Type.FunctionReturn([FType])),
            AddRetTxt   = Table.AddColumn(AddReturn,    "RetText",      each Type.ToText([Returns])),
            AddRetRec   = Table.AddColumn(AddRetTxt,    "RetRecursive", each Type.ToText([Returns], true)),
            AddRetNull  = Table.AddColumn(AddRetRec,    "RetNullable",  each Type.IsNullable([Returns])),
            AddRetType  = Table.AddColumn(AddRetNull,   "RetType",      each let Type = Type.ToText(Type.NonNullable([Returns])) in if Type = "anynonnull" and [RetNullable] then "any" else Type),
            AddParams   = Table.AddColumn(AddRetType,   "Parameters",   each Type.FunctionParameters([FType])),
            AddNumPars  = Table.AddColumn(AddParams,    "NumParams",    each Record.FieldCount([Parameters])),
            AddReqd     = Table.AddColumn(AddNumPars,   "Required",     each Type.FunctionRequiredParameters([FType])),
            AddSig      = Table.AddColumn(AddReqd,      "Signature",    each Value.ToText([Value])), //! Value_ToText
            AddSigRec   = Table.AddColumn(AddSig,       "SigRecursive", each [Name] & " => " & Value.ToText([Value], true)), //! Value_ToText
            AddTally    = Table.AddColumn(AddSigRec,    "Times Used",   each Text.Count(Text.Queries, [Name])), //! Text_Queries
            GoodCols    = Table.RemoveColumns(AddTally, {"Type", "TypeRecurs"}),
            Return = GoodCols
        in
            Return,

    M.library   = 
        let
            Source      = Table.Sort(Record.ToTable(#shared),{{"Name", Order.Ascending}}),
            Categorized = Table.AddColumn(Source, "Status", each if Record.HasFields(#sections[Section1], [Name]) then "User defined" else "Built in"),
            // Annoying I need to filter out user defined stuff, but this resolves a cyclic reference caused if both F and this refer to all custom functions (which includes each other)
            Filtered    = Table.SelectRows(Categorized, each [Status] = "Built in"),
            AddType     = Table.AddColumn(Filtered, "Type", each Value.TypeToText([Value])), //! Value_TypeToText
            AddTypeRec  = Table.AddColumn(AddType, "TypeRecurs", each Value.TypeToText([Value], true)), //! Value_TypeToText
            AddCat      = Table.AddColumn(AddTypeRec, "Category", each
            let
                cut = Text.Split(Text.Replace([Name],"_","."),".")
            in
                (try
                    if   List.Contains({"Database", "Type"}, cut{1})
                    then cut{1}
                    else cut{0}
                otherwise
                    "Custom"
                )
            ),
            Return = AddCat
        in
            Return,

    M.types     = 
        let
            Source = M.library,
            Types  = Table.SelectRows(Source, each Value.Is([Value], type type)),
            Return = Types
        in
            Return,

    M.UDFs      = // возвращает список пользовательских функций
        let
            Source  = Record.FieldNames(#shared),
            UDFs    = List.Select(Source, each Record.HasFields(#sections[Section1], _)),
            Return  = UDFs
        in
            Return,

    Misc.Wait   = 
        // This function is now obsolete due to the addition of Function.InvokeAfter(), see:
        // https://cwebbbi.wordpress.com/2015/04/30/using-function-invokeafter-in-power-query/

        /*
            Delay the given action for the specified number of seconds
            Usage:
                Misc.Wait = Load("Misc.Wait"),
                Misc.Wait(0.5, () => Web.Contents("www.bing.com"))
            Result: 
                [whatever result of the given action, except 0.5 seconds slower]
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

    Number.Dec2Bin = 
        /*
            Description:
                Function that converts number from decimal to binary notation
            
            Link:
                Same as Excel funciton DEC2BIN
                https://support.office.com/en-us/article/DEC2BIN-function-0f63dd0e-5d1a-42d8-b511-5bf5c6d43838

            Usage:  
                Number.Dec2Bin( 1026 )
            
            Result: 
                10000000010
        */

        (num as number, optional string as nullable text) =>
            let
                input_string = if string = null then "" else string,
                reminder     = Number.Mod( num, 2 ),
                resulting_string = Text.From( reminder ) & input_string,
                input  = Number.IntegerDivide( num, 2 ),
                return = if input > 0 
                         then @Number.Dec2Bin( input , resulting_string) // ! Number_Dec2Bin
                         else resulting_string
            in
                return,
//  UdfContent
    getUdfContent = // содержимое UDF функций, но какой файл на входе?
        (fnName as text) => 
        let
         // LoadPath = "",
            Path    = LoadPath & (if Text.End(LoadPath, 1) <> "\" then "\" else ""),
            File    = Path & Text.Replace(fnName, "_", ".") & ".pq",
            AltFile = Path & fnName & ".m",  //just in case...
            Source  = Text.FromBinary(Binary.Buffer(
                        try File.Contents(File)
                        otherwise File.Contents(AltFile)
                        ))
        in
            Source,

    UdfContents   = // "", // ошибка компиляции из-за M_UDFs. Все менял не выходит
        /* выдает ошибку при компиляции Используется в 2-х функциях еще*/
        let
         // UdfTable     = Table.RenameColumns(Table.FromList({""}), {"Column1", "Name"}),
            UdfTable     = Table.RenameColumns(Table.FromList(M_UDFs), {"Colusmn1", "Name"}),
            WithContents = Table.AddColumn(UdfTable, "Contents", each getUdfContent([Name]))
        in
            WithContents,

//  Record
    Record.Rename           = // переименовывает Имя записи, используя лямбду (передаваемые значения k,v)
        /*
            Description:
                Rename a record using a given lambda (passed values k,v)
                Переименуйте запись, используя заданную лямбду (передаваемые значения k,v)

            Usage:
                let
                    Record.Rename = Load("Record.Rename"),
                    Rec = [A=1, B=2]
                in
                    Record.Rename(Rec, (k,v) => k & Text.From(v))
            
            Result: 
                [A1 = 1, B2 = 2]
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

    Record.Transform        = // преобразовывает Значение записи, используя лямбду (передаваемые значения k,v)
        /*
            Description:
                Transform a record using a given lambda (passed values k,v)
                Преобразовывает VALUE записи, используя заданную лямбду (переданные значения k,v)

            Usage:
                let
                    Record.Transform = Load("Record.Transform"),
                    alt: F[Record.Transform]
                    Rec = [A=1, B=2]
                in
                    Record.Transform(Rec, (k,v) => k & Text.From(v))
            
            Result: 
                [A = "A1", B = "B2"]
        */

        (Rec as record, Lambda as function) as record =>
        let
            Keys        = Record.FieldNames(Rec),
            Transformed = List.Transform(Keys, each Lambda(_, Record.Field(Rec, _))),
            Recorded    = Record.FromList(Transformed, Keys),
            Return      = Recorded
        in
            Return,

    Record.TransformJoin    = // возвращает строку из Имени и Значения записи (с использованием лямбды и разделителя)
        /*
            Description:
                Shorthand for returning a string representation (using a given lambda) of a record
                Сокращение для возврата строкового представления (с использованием заданной лямбды) записи
            
            Usage:
                Record.TransformJoin = Load("Record.TransformJoin"),
                Rec = [A=1, B=2],
                Record.TransformJoin(Rec, each _ & "=" & Text.From(Record.Field(Rec, _)))
            
            Result: 
                "A=1, B=2"
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

    Stat.Trend = 
        /*
            Calculates a trend according to Excel's TREND-function but without the option to define your own slope and intercept.
            Slope and intercept will be calculated according to the input data.

            Вычисляет тренд в соответствии с функцией ТРЕНД Excel, но без возможности определить собственный наклон и точку пересечения.
            Наклон и точка пересечения будут рассчитаны в соответствии с входными данными.
            
            Use: 
                Just pass the values from the past that shall be considered (YList) and the number of intervalls (NoOfIntervalls) to be calculated for the future.
                    Argument_1 YList: The set of y-values you already know in the relationship y = mx + b
                    Argument_2 NoOfIntervalls: New x-values for which you want TREND to return corresponding y-values// Suggested improvement: Completely harmonize to EXCEL-TREND: 
                        a) Options to omitt intercept ([CONST]=FALSE)
                        b) Use specific [known_x's] instead of default {0...n} 
                        c) Harmonize input parameter syntax 
        */

        (YList as list, NoOfIntervalls as number) =>
        let
            Source  = Table.FromColumns({YList}),
            xAxis   = Table.AddIndexColumn(Source, "Index", 1, 1),
            Rn      = Table.RenameColumns(xAxis,{{"Column1", "y"}, {"Index", "x"}}),
            AvgX    = List.Average(Rn[x]),
            AvgY    = List.Average(Rn[y]),
            
            x   = Table.AddColumn(Rn, "xX",  each [x] - List.Average(Rn[x])),
            y   = Table.AddColumn(x,  "yY",  each [y] - List.Average(x[y])),
            xy  = Table.AddColumn(y,  "xy",  each [xX] * [yY]),
            xXx = Table.AddColumn(xy, "xXx", each [xX] * [xX]),
            a   = List.Sum(xXx[xy]) / List.Sum(xXx[xXx]),
            b   = AvgY - ( a * AvgX ),
            
            ListIntervalls  = {List.Max(Rn[x]) + 1..List.Max(Rn[x]) + NoOfIntervalls},
            TableIntervalls = Table.FromList(ListIntervalls, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
            
            Rename  = Table.RenameColumns(TableIntervalls,{{"Column1", "x"}}),
            Values  = Table.AddColumn(Rename, "y", each [x] * a + b),
            TREND   = Table.Combine({Rn,Values})
        in
            TREND,

//  Table    
    Table.AddScrape         = // добавляет столбец с полученными результатами, Table.AddColumn() + Web.Contents()
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

    Table.CrossJoin         = // возвращает перекрестное соединение двух аргументов (могут быть списками или таблицами) 
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

    Table.CrossJoin2        = // развивает Table.CrossJoin с помощью UdfContents и прочего 
        let
            Table.CrossJoin = Load("Table.CrossJoin"),
            Tokens    = Table.RenameColumns(Table.FromList(Record.FieldNames(#shared)), {"Column1", "Token"}),
            AddAlts   = Table.AddColumn(Tokens, "TokenAlt", each Text.Replace([Token], "_", ".")),
            Crossed   = Table.CrossJoin(AddAlts, UdfContents),
            Contained = Table.AddColumn(Crossed, "Contains", each Text.Contains([Contents], [Token]) or Text.Contains([Contents], [TokenAlt])),
            Filtered  = Table.SelectRows(Contained, each [Contains]),
            FiltCols  = Table.SelectColumns(Filtered, {"Token", "TokenAlt", "Name"}),
            Return    = FiltCols
        in
            Return,
    
    Table.CrossJoinTables   = // перекрестное объединение списка таблиц в таблицу, содержащую все комбинации строк 
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
 
    Table.ExpandAll         = // полностью раскрывает любые вложенные записи и таблицы внутри таблицы 
        /*
            Fully expands any nested records and tables within a table
            Полностью раскрывает любые вложенные записи и таблицы внутри таблицы.

            Originally written by Chris Webb: 
            https://cwebbbi.wordpress.com/2014/05/21/expanding-all-columns-in-a-table-in-power-query/
            
            Usage:
                Table.ExpandAll = Load("Table.ExpandAll"),
                xml = Xml.Tables("<books><book><name>Book1</name><pages><page>1</page><page>2</page><page>3</page></pages></book><book><name>Book2</name><pages><page>1</page><page>2</page><page>3</page></pages></book></books>"),
                Table.ExpandAll(xml)	//, null, true
            
            Result: 
                [an expanded version of the given table with nested records/tables]
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

    Table.ExpandRecords     = // полностью раскрывает любые вложенные записи в таблице 
        /*
            Fully expands any nested records within a table
            Полностью раскрывает любые вложенные записи в таблице.

            Originally written by Chris Webb: 
            https://cwebbbi.wordpress.com/2014/05/21/expanding-all-columns-in-a-table-in-power-query/
            
            Usage:
                Table.ExpandRecords = Load("Table.ExpandRecords"),
                tbl = Table.FromColumns({ {1}, {[c=0,d=2]} }, {"a", "b"}),
                Table.ExpandRecords(tbl)    //, null, true
            
            Result: 
                [an expanded version of the given table with nested records]
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

    Table.ExpandTables      = // полностью раскрывает любые вложенные таблицы внутри таблицы 
        /*
            Fully expands any nested tables within a table
            Полностью раскрывает любые вложенные таблицы внутри таблицы.
            
            Originally written by Chris Webb: 
            https://cwebbbi.wordpress.com/2014/05/21/expanding-all-columns-in-a-table-in-power-query/
            
            Usage:
                Table.ExpandTables = Load("Table.ExpandTables"),
                xml = Xml.Tables("<books><book><name>Book1</name><pages><page>1</page><page>2</page><page>3</page></pages></book><book><name>Book2</name><pages><page>1</page><page>2</page><page>3</page></pages></book></books>"),
                Table.ExpandTables(xml)    //, null, true
            
            Result: 
                [an expanded version of the given table with nested tables]
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

    Table.FromString        = // создает пустую таблицу с заголовками, представленными в строке с разделителями
        /* */
        (String as text, Separator as text) => 
            Table.PromoteHeaders( 
                Table.Transpose( 
                    Table.FromList( 
                        Text.Split( String, Separator ) 
                    ) 
                ) 
            ),

    Table.JoinMany          = // объединение 3+ таблиц одновременно
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

    Table.MergeColumns      = // объединяет два столбца, беря столбец A, но возвращаясь к B, где A = null 
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

    Table.RowsCombination   = // создает все возможные комбинации строк из Таблицы1 и Таблицы2 
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

    Table.RowsCombination2  = // создает все возможные комбинации строк из нескольких Таблиц
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

    Table.TranslateColumn   = // Создает «переведенный» столбец по словарю замен
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

    Table.UnpivotByNumbers  = // Unpivot, но строки заголовка, должны находиться в первых строках таблицы, НЕ в заголовках
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
        
//  Text
    Text.AsciiOnly   = // возвращает не ascii символы (<= 255) в строке
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

    Text.Between     = // возвращает текст между разделителями
        /*
            Возвращает текст между разделителями
            Usage:
                Text.Between = Load("Text.Between"),
                Text.Between("abcdef", "bc", "f")
            Result: 
                "de"
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

    Text.ContainsAny = // содержит ли строка какое-либо слово из списка
        /*
            Проверка, содержит ли строка какое-либо слово из заданного списка.
            Пример:
                Text.ContainsAny = Load("Text.ContainsAny"),
                Text.ContainsAny("the cat sat on the mat", {"cat", "apple"})
            Результат: 
                true
            Примечание: 
                То же самое, что и = List.ContainsAny({"мама мыла папу рядом"}, {"мапа","папу"}, Text.Contains)
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

    Text.Count       = // число вхождений символа в строке
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

    Text.EachBetween = // возвращает текст между несколькими парными разделителями
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

    Text.EachFromTo  = // возвращает текст между несколькими парными разделителями + разделители
        /*
            Grabs the substring between the specified 'after' and 'before' strings
            
            Usage:
                Text.EachFromTo = Load("Text.EachFromTo"),
                Text.EachFromTo("a[bc][d]ef", "[", "]")
            
            Result: 
                {"[bc]", "[d]"}
        */

        (
            Haystack 	as text, 
            After 		as text, 
            Before 		as text
        ) as text =>
        
        let
            CutAfter 	= Text.Split(Haystack, After),
            SkipFirst 	= List.Skip(CutAfter),
            CutEach 	= List.Transform(SkipFirst, each After & Text.Split(_, Before){0} & Before)
        in 
            CutEach,

    Text.FromTo      = // захватывает первую подстроку от указанной строки «От» до строки «Вверх до»
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

    Text.Like        = // позволяет выполнять нечеткие сравнения строк, аналогичные SQL LIKE
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

    Text.MixedSort   = // сортирует смешанную строку из текста (в буквенно-цифровом порядке) и чисел (в числовом порядке)
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

    Text.PowerTrim   = // чистка текста внутри и по бокам от заданного символа
        /*
            Description:
                Function removes double presents of specified characters.
                By default remove double spaces and leading + ending spaces.
                Like TRIM function in Excel
            
            Link:
                Original is taked from Ken Puls's blog
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

    Text.Queries     = // запросы из файлов в папке в виде текста, не проверял
        /*
            Description:
                text user-defined queries
            to = Text.Combine(List.Select(Text.Split(text, char), each _ <> ""), char)
        */
        let
            Files       = Folder.Files(LoadPath), // Folder.Contents
            AddDecode   = Table.AddColumn(Files, "Text", each Text.FromBinary([Content])),
            FilterCols  = Table.SelectColumns(AddDecode, {"Name", "Text"}),
            TextCol     = Table.Column(FilterCols, "Text"),
            TextMerged  = Text.Combine(TextCol),
            TextCleaned = TextMerged, // sorry, no regex to clean out comments!
            Return      = TextCleaned
        in
            Return,

    Text.RemoveSymbols = // чистим текст от всех непечатных символов
        /*
            Description:
                Чистим текст от всех непечатных символов
            
            Link:
                Originally written by Chris Webb: 
                https://cwebbbi.wordpress.com/2014/08/18/removing-punctuation-from-text-in-power-query/
            
            Usage:
                Text.RemoveSymbols = Load("Text.RemoveSymbols"),
                newText = Text.RemoveSymbols("a,b,c")
                newText	
            
            Result: 
                newText = "abc"
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

    Text.ReplaceAll  = // несколько замен текста, передавая замены в виде списка списков
        /*
            Description:
                Do multiple text replacements in one function call, passing the replacements as a list of lists
                Выполняйте несколько замен текста за один вызов функции, передавая замены в виде списка списков.
            
            Usage:
                Text.ReplaceAll = Load("Text.ReplaceAll"),
                Text.ReplaceAll("(test)", {
                    {"(", "["},
                    {")", "]"}
                })
            Result: 
                "[test]"
        */

        (str as text, Replacements as list) as text => 
            List.Accumulate(Replacements, str, (s, x) => Text.Replace(s, x{0}, x{1})),

//  Other
    Time.EpochToTime = 
        (epoch as nullable text ) =>
        let
            res =   if epoch = null 
                    then null
                    else
            let
                remove_word    = Text.Replace(epoch, "PT", ""),
                remove_letterH = Text.Replace(remove_word, "H", ":"),
                remove_letterM = Text.Replace(remove_letterH, "M", ":"),
                remove_letterS = Text.Replace(remove_letterM, "S", "")
            in 
                remove_letterS
        in
            res,

    Type.ToText = 
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

    Value.ToText = 
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
            
            Type.ToText = Load("Type.ToText"),

            Type = Value.Type(Value),
            ToText = 
                if Value.Is(Value, type type) and Recurs 
                then "type " & Type.ToText(Value, Recurs)
                else Type.ToText(Type, Recurs),
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

    Value.WaitFor = 
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

    Vlookup = 
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
            Return,
//  Web
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
    
    Web.TimeAndDateCom.GetCountryCalendar = 
        /*
            Function returns a table with list of dates for specified years, and indicator for each day
            is it a working or non-working day in specified country.
            Argument Country requires specific ID, which can be received by another function
            https://github.com/IvanBond/pquery/blob/master/Web.TimeAndDateCom.GetCountries.m
            
            Sample Excel file:https://1drv.ms/x/s!AsARcUyPYj4LgqMAHv8GM3pe3ZE_Ug
        */

        (   Country as text,
            Year1 as number, 
            Year2 as nullable number) =>

        let

            Y2 = if Year2 = null then Year1 else Year2,

            Source = Table.FromColumns({Lines.FromBinary(Web.Contents("https://www.timeanddate.com/calendar/custom.html?mty=1&ctf=4&hol=9&typ=3&hod=7&holmark=1&display=2&cdt=1&wdf=3&mtm=2&cols=1&country=" & 
                Country & "&year=" & Text.From(Year1) & "&y2=" & Text.From(Y2) ))}),

            #"Filtered Rows" = Table.SelectRows(Source, each Text.Contains([Column1], "<div id=calarea>")),
            CalAreaText = #"Filtered Rows"{0}[Column1],
            Custom1 = Text.PositionOf( CalAreaText, "<table " ),
            Custom2 = Text.PositionOf( CalAreaText, "</table>", Occurrence.Last ),
            TableAsText = Text.Range( CalAreaText, Custom1, Custom2 - Custom1 + 8 ),
            CalTableAsList = Text.Split( TableAsText, "<tr>" ),
            #"Replaced Closing tr" = List.ReplaceValue(CalTableAsList,"</tr>","",Replacer.ReplaceText),
            #"Converted to Table" = Table.FromList(#"Replaced Closing tr", Splitter.SplitByNothing(), null, null, ExtraValues.Error),
            #"Filtered Target Rows" = Table.SelectRows(#"Converted to Table", each Text.Contains([Column1], "<td class=cn") or Text.Contains([Column1], "<td class=""cn") or Text.Contains([Column1], "<th>") ),
            #"Added Headers" = Table.AddColumn(#"Filtered Target Rows", "Titles", each if Text.Contains( [Column1], "<th>") then [Column1] else null),
            #"Added Days rows" = Table.AddColumn(#"Added Headers", "Day Rows", each if not Text.Contains( [Column1], "<th>") then [Column1] else null),
            #"Added Working Days Ind" = Table.AddColumn(#"Added Days rows", "Working Day", each if Text.Contains( [Column1], "cn  minititle") then "N" else "Y"),
            #"Added MM YYYY" = Table.AddColumn(#"Added Working Days Ind", "MM YYYY", each try Text.Range([Titles], Text.PositionOf([Titles], """>")+2, 7) otherwise null),
            #"Added Days Dirty" = Table.AddColumn(#"Added MM YYYY", "Days Dirty", each if [Day Rows] <> null then Text.Range([Day Rows], Text.PositionOf([Day Rows], ">")+1,2) else null),
            #"Clean Days Dirty" = Table.ReplaceValue(#"Added Days Dirty","<","",Replacer.ReplaceText,{"Days Dirty"}),
            #"Filled Down MM YYYY" = Table.FillDown(#"Clean Days Dirty",{"MM YYYY"}),
            #"Removed Other Columns" = Table.SelectColumns(#"Filled Down MM YYYY",{"Working Day", "MM YYYY", "Days Dirty"}),
            #"Filtered nulls" = Table.SelectRows(#"Removed Other Columns", each ([Days Dirty] <> null)),
            #"Convert to Date" = Table.AddColumn(#"Filtered nulls", "Date", each #date( Number.From(Text.End([MM YYYY],4)), Number.From(Text.Start([MM YYYY],2)), Number.From([Days Dirty]))),
            #"Removed Other Columns1" = Table.SelectColumns(#"Convert to Date",{"Date", "Working Day"}),
            #"Added Country" = Table.AddColumn(#"Removed Other Columns1", "Country", each Country),
            #"Reordered Columns" = Table.ReorderColumns(#"Added Country",{"Country", "Date", "Working Day"}),
            #"Changed Type" = Table.TransformColumnTypes(#"Reordered Columns",{{"Date", type date}, {"Working Day", type text}, {"Country", type text}}),
            #"Sorted Rows" = Table.Sort(#"Changed Type",{{"Date", Order.Ascending}})
        in
            #"Sorted Rows"
]
in 
    IMKA
