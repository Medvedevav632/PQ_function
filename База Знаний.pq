    https://clickhouse.com/docs/ru
    https://osipenkov.ru/connect-database-clickhouse-dbeaver/   - установка и работа

//  База знаний по PSQL    
    https://metanit.com/sql/postgresql/1.1.php

//  ИЗМЕНЕНИЕ ПАРОЛЯ POSTGRES
    https://qna.habr.com/q/1060600 -* помогло

    Полезные ссылки:
    1. http://profhelp.com.ua/articles/postgresql-%D0%BA%D0%B0%D0%BA-%D1%81%D0%B1%D1%80%D0%BE%D1%81%D0%B8%D1%82%D1%8C-%D0%BF%D0%B0%D1%80%D0%BE%D0%BB%D1%8C-%D1%81%D1%83%D0%BF%D0%B5%D1%80%D0%BF%D0%BE%D0%BB%D1%8C%D0%B7%D0%BE%D0%B2%D0%B0%D1%82%D0%B5%D0%BB%D1%8F
    2. https://stackoverflow.com/questions/37234940/centos-locate-command-doesnt-work
    3. https://stackoverflow.com/questions/19674456/run-postgresql-queries-from-the-command-line
    
    Может произойти так, что ты забыл пароль от пользователя postgres.
    Но не беда, его можно восстановить, для этого:
    1. Открой файл: pg_hba.conf
        Не знаешь где он лежит? Воспользуйся командой: locate pg_hba.conf - 
            
            c:\Program Files\PostgreSQL\15\data

        Не работает команда? Установи ее командами: yum install mlocate и updatedb
    
    2. Измени в файле строку: 
        local all postgres md5
        на
        local all postgres trust

    3. Перезапусти сервис: systemctl restart postgresql-9.3.service
    4. Зайди в командную строку psql командой: psql -U postgres
    5. Введи команду: alter user postgres with  password 'newpasswod';
    6. Нажми "Enter"
    7. Для выхода из командной строки нажми набери \q + Enter
    8. Проверь, что теперь ты можешь авторизоваться в БД под пользователем postgres и с указанным тобою паролем
    9. Все получилось? 
        Измени строку в файле снова на: local all postgres md5
    10. Перезапусти сервис: systemctl restart postgresql-9.3.service
    11. Profit!

//  Ссылки на ресурсы с кодом PQ
    https://www.thebiccountant.com

//  1

//  Создать темы https://themes.powerbi.tips
    https://themes.powerbi.tips/themes/wireframes

//  Примеры DAX метрик от пользователей  https://community.fabric.microsoft.com
    https://community.fabric.microsoft.com/t5/Quick-Measures-Gallery/bd-p/QuickMeasuresGallery/page/2

//  База функций https://powerquery.io (MustHave - переключить на русский язык)
    https://powerquery.io
    https://powerquery.how

//  Полный анализ каждой страницы https://pbix.info/
    https://pbix.info/

//  Много примеров отчетов, тем и прочего. https://github.com/microsoft
    https://github.com/microsoft/powerbi-desktop-samples/tree/main/Sample%20Reports

//  help.zebrabi.com - много хорошего по PQ, DAX, PBI с анимацией и файлами для скачивания!
    Например:
        про схема звезда    https://help.zebrabi.com/kb/power-bi/star-schema/
        динамические меры   https://help.zebrabi.com/kb/power-bi/dynamic-measure-switch/


//  Статьи на хабре по PQ_ru
    1   Power Query: как перестать бояться функционального программирования и начать работать в расширенном редакторе запросов
        https://habr.com/ru/articles/311600/ 
    
    2   Как с применением Power BI создавалась система анализа ФХД предприятий России и зачем
        https://habr.com/ru/articles/581030/
    
    3   Калькуляция затрат для сбора факта Бюджета доходов и расходов (выгрузка из 1C)
        https://habr.com/ru/articles/801707/

//  лучшие практики по очисткуе данных - советы
    https://aw.club/global/ru/blog/best-practices-for-data-modeling-and-data-cleaning

//  оптимизация PBI

    // русский 
   
        Аспекты скорости/производительности

        Это сборник советов, как повысить производительность ваших M-запросов. Он будет постоянно обновляться.
        
        1 Отключить фоновое обновление

            Я вообще это отключаю. Это значительно замедляет выполнение многих запросов. Как видите, я также отключаю почти всё остальное, так как большинство из них тоже может негативно сказаться на производительности.

        Более подробную информацию см. в сообщении Криса Уэббса: https://blog.crossjoin.co.uk/2016/12/05/power-query-power-bi-and-the-allow-data-preview-to-download-in- опция-фона/
        Не используйте агрегаты при повороте

        Если вы хотите, чтобы ваши сводные операции выполнялись быстро, НИКОГДА не используйте в них агрегаты. Вместо этого сначала агрегируйте групповую операцию:  https://www.thebiccountant.com/2020/05/17/ Performance-tip-speed-up-slow-pivot-in-power-query/
        Не используйте агрегаты после соединений

        Пользовательский интерфейс предлагает вам агрегировать ваши данные после операций соединения. Это очень медленно, но есть обходные пути:  https://www.thebiccountant.com/2019/10/28/  Performance-tip-for-aggregations-after-joins-in-power-query-and-power-bi/
        Разделите таблицу для вертикальных операций, где это возможно.

        Если вы выполняете вычисления в вертикальном направлении (например, суммируете несколько значений из одного столбца) для каждой строки, производительность может резко ухудшиться. Если эти расчеты должны выполняться только в пределах определенной подгруппы, вы можете значительно ускорить процесс, сначала сгруппировав их, чтобы вертикальное сканирование охватывало только подмножества таблицы:  https://www.thebiccountant.com /2017/05/29/ Performance-tip-partition-tables-crossjoins-possible-powerquery-powerbi/ Также проверьте в этих случаях, будет ли мера DAX еще лучшим решением здесь:  https://exceleratorbi.com. au/calculated-columns-vs-measures-dax/
        Используйте Table.Buffer или List.Buffer.

        где это уместно. Это немного проб и ошибок, но, вообще говоря: используйте его, когда на вашу таблицу или список будут ссылаться несколько раз (например, в List.Generate).

        Также используйте его ВНУТРИ List.Generate ( в «следующей» функции, как описано здесь )

        Дополнительную информацию см. в сообщении Криса Уэбба: https://blog.crossjoin.co.uk/2015/05/05/improving-power-query-calculation- Performance -with-list-buffer/

        Проверьте, загружаются ли ваши источники несколько раз, чтобы узнать, где буфер может быть полезен:  https://blog.crossjoin.co.uk/2018/07/16/process-monitor-power-query/

        Двоичный.Буфер

        может помочь, если вы подключаетесь к нескольким нескладным источникам: https://www.thebiccountant.com/speed Performance-aspects/
        Увеличьте скорость запросов на этапе проектирования.

        Используйте переключатель фильтров, чтобы одновременно отключить или активировать несколько фильтров в ваших таблицах: http://www.thebiccountant.com/2016/11/08/speed-powerbi-power-query-design-process/
        Ваши SQL-запросы медленные?

        Проверьте, происходит ли свертывание запроса, и если вы фильтруете данные, отличные от SQL, возможно, вам придется скорректировать свои запросы: http://www.thebiccountant.com/2017/07/20/sql-query-folding-bug- еще жив-сосущий-powerbi-powerquery-excel/
        Группировка по смежным данным?

        Измените четвертый параметр в Table.Group на «GroupKind.Local». Это необязательный параметр, который не будет присутствовать при создании таблицы групп через пользовательский интерфейс. Поэтому вам придется вручную вставить этот параметр следующим образом:

        Table.Group(#"Sorted Rows", {"StartDate"}, {{"All", each _, type table}}, GroupKind.Local)

        В документации сказано: «Локальная группа формируется из последовательной последовательности строк входной таблицы с одинаковым значением ключа. Глобальная группа формируется из всех строк входной таблицы с одинаковым значением ключа».
        Проверьте свои источники

        Если у вас есть выбор между импортом из CSV или Excel, выбирайте CSV, так как это тоже будет намного быстрее. Файлы Excel имеют гораздо более сложный формат, хранят гораздо больше (фоновой/мета) информации и поэтому читаются медленнее.
        Отключить настройки конфиденциальности

        Если это возможно в вашей организации, вы также можете отключить настройки конфиденциальности, чтобы повысить производительность. Более подробную информацию можно прочитать здесь: http://datapigtechnologies.com/blog/index.php/four-must-know-power-query-options/.
        Добавьте ключ в таблицу поиска

        Вы можете ускорить операции слияния, если добавите ключ в одно из полей соединения, если это возможно: https://blog.crossjoin.co.uk/2018/03/16/improving-the- Performance-of-aggregation- после-слияния-в-мощности-би-и-превосходства-мощности-запрос-получитьтрансформацию/
        Типы задержки – опция для импорта книг Excel

        Крис Уэбб описывает здесь, как опция DelayTypes помогает ускорить импорт книг Excel.
        Тест лучших операторов поиска и индексации

        Если вы хотите выбрать определенное поле из таблицы, имеет смысл проверить порядок ваших операторов поиска и индексирования для достижения наилучшей производительности, как описывает здесь Крис Уэбб .
        Получение максимальных или минимальных значений из столбца

        Крис Уэбб описывает здесь ошибки производительности .
        Храните вещи в «табличном пространстве»

        Если вы хотите получить выгоду от потенциальной оптимизации, вам следует хранить логику запросов в табличном пространстве. Говорит Курт Хагенлохер в комментариях к этой теме.
        Ссылка на предыдущие или последующие строки?

        Ссылка на предыдущие или следующие строки в Power Query будет работать быстро только в больших наборах данных, если вы используете метод «смещенного индекса», который я описал здесь:  Быстрый и простой способ ссылки на предыдущие или следующие строки в Power Query или Power BI. Бухгалтер
        Ссылочные веб-запросы

        Если вы извлекаете данные из Интернета и ссылаетесь на промежуточные таблицы, отключение параллельной загрузки таблиц может ускорить ваши запросы:  https://blog.crossjoin.co.uk/2019/10/13/why-does-power-bi -query-my-data-source-more-than-one-one/
        Не группируйте вложенные объекты

        Сначала разверните их.
        Преобразование нескольких столбцов одновременно со ссылкой на существующий столбец

        Преобразование нескольких столбцов одновременно со ссылкой на существующий столбец в Power Query (thebiccountant.com)
        Нанять эксперта

        Если ни одно из вышеперечисленных действий вам не подходит или вы не хотите пробовать все это самостоятельно, я могу предложить свои консультационные услуги. Свяжитесь со мной: информация на сайте thebiccountant dot com.


    английский 
        Speed/Performance aspects

        This is a collection of tips how to improve performance of your M-queries. It will be updated continuously.
        Disable background refresh

        I turn this off in general. It slows down many queries considerably. As you see, I’m also disabling almost everything else, as most if it can also have a negative impact on performance.

        See Chris Webbs post for more details: https://blog.crossjoin.co.uk/2016/12/05/power-query-power-bi-and-the-allow-data-preview-to-download-in-the-background-option/
        Don’t use aggregations in when pivoting

        When you want your pivot-operations to run fast, NEVER use aggregations in them. Instead aggregate with a group-operation first: https://www.thebiccountant.com/2020/05/17/performance-tip-speed-up-slow-pivot-in-power-query/
        Don’t use aggregations after joins

        The UI offers you to aggregate your data after join-operations. This is extremely slow, but there are workarounds: https://www.thebiccountant.com/2019/10/28/performance-tip-for-aggregations-after-joins-in-power-query-and-power-bi/ 
        Partition your table for vertical operations where possible

        If you do calculations in the vertical direction (like summing up multiple values from one column) for each row, performance can degrade drastically. If these calculations shall only be made within a certain sub-group, you can speed up the process significantly by grouping first, so that the vertical scan only has to go over the subsets of the table: https://www.thebiccountant.com/2017/05/29/performance-tip-partition-tables-crossjoins-possible-powerquery-powerbi/ Also check in these cases, if a DAX measure would be an even the better solution here: https://exceleratorbi.com.au/calculated-columns-vs-measures-dax/
        Use Table.Buffer or List.Buffer

        where appropriate. This is a bit of trial and error, but generally speaking: Use it when your table or list will be referenced multiple times (like in List.Generate).

        Also use it WITHIN List.Generate (in the “next”-function like described here)

        See again a post from Chris Webb for more details: https://blog.crossjoin.co.uk/2015/05/05/improving-power-query-calculation-performance-with-list-buffer/

        Check if your sources are loaded multiple times to find out where a buffer might be useful: https://blog.crossjoin.co.uk/2018/07/16/process-monitor-power-query/

        Binary.Buffer

        might help if you’re connecting to multiple non-folding sources: https://www.thebiccountant.com/speedperformance-aspects/
        Improve query speed during design-phase

        Use a filter-toggle to de-/activate multiple filters in your tables at once: http://www.thebiccountant.com/2016/11/08/speed-powerbi-power-query-design-process/
        Your SQL-queries are slow?

        Check if query-folding happens and if you are filtering with non-SQL-data, you might have to adjust your queries: http://www.thebiccountant.com/2017/07/20/sql-query-folding-bug-still-alive-sucking-powerbi-powerquery-excel/
        Grouping on contiguous data?

        Change the fourth parameter in Table.Group to “GroupKind.Local”. This is an optional parameter will not be present when you create your group-table via the UI. So you have to manually insert that parameter like so:

        Table.Group(#"Sorted Rows", {"StartDate"}, {{"All", each _, type table}}, GroupKind.Local)

        Documentation says: ” A local group is formed from a consecutive sequence of rows from an input table with the same key value. A global group is formed from all rows in an input table with the same key value.”
        Check your sources

        If you have the choice between an import from csv or Excel, take the csv, as it will also be much faster. Excel files have a much more complex format, store much more (background/meta) information and are therefore slower to read.
        Disable privacy settings

        If this is feasible in your organisation, you can also disable privacy settings to improve performance. Please read more details here: http://datapigtechnologies.com/blog/index.php/four-must-know-power-query-options/
        Add a key to your lookup table

        You can speed up your merge operations if you add a key to one of the join-fields if possible: https://blog.crossjoin.co.uk/2018/03/16/improving-the-performance-of-aggregation-after-a-merge-in-power-bi-and-excel-power-query-gettransform/
        Delaying types – option for importing Excel-Workbooks

        Chris Webb describes here how the delayTypes-option helps to speed up import of Excel-Workbooks.
        Test for the best lookup and indexer operators

        If you want to select a specific field from a table, it makes sense to test out the order of your lookup- and indexer operators for best performance like Chris Webb describes here.
        Getting Max or Min values from a column

        Chris Webb describes performance gotchas here.
        Keep things in “table space”

        If you want to benefit from potential optimisation, you should keep your query logic in table space. Says Curt Hagenlocher in the comments to this thread.
        Referencing previous or next rows?

        Referencing previous or next rows in Power Query will only work fast on large datasets if you use the “shifted index”-method that I’ve described here: Fast and easy way to reference previous or next rows in Power Query or Power BI – The BIccountant
        Referenced web queries

        If you’re pulling data from the internet and reference staging tables, disabling parallel loading of tables might speed up your queries: https://blog.crossjoin.co.uk/2019/10/13/why-does-power-bi-query-my-data-source-more-than-once/
        Don’t group on nested objects

        Expand them first.
        Transform multiple columns at once with reference to an existing column

        Transforming multiple columns at once with reference to existing column in Power Query (thebiccountant.com)
        Hire an expert

        If none of the above actions work for you or you don’t want to try it all out by yourself, I can offer my consulting services. Contact me: info at thebiccountant dot com
