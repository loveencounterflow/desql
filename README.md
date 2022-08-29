



# 𓃕DeSQL SQL Parser




<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [𓃕DeSQL SQL Parser](#%F0%93%83%95desql-sql-parser)
  - [Goals](#goals)
  - [DBay Trash Documentation](#dbay-trash-documentation)
    - [Trash Your DB for Fun and Profit](#trash-your-db-for-fun-and-profit)
      - [Motivation](#motivation)
      - [Properties of Trashed DBs](#properties-of-trashed-dbs)
      - [API](#api)
  - [Progress Notes](#progress-notes)
    - [2022-02-17T11:22:23+01:00](#2022-02-17t1122230100)
    - [2022-02-11T21:20:17+01:00](#2022-02-11t2120170100)
  - [To Do](#to-do)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->




# 𓃕DeSQL SQL Parser

* 𓃕DeSQL = **D**iagram to **E**xplain **S**QL (𓃕 = Holy Cow!)

🚧 Work in progress 🚧


## Goals

Perform an in-depth analysis of a given set of SQL statements—be it Data Definition, Query or Manipulation
Language (DDL, DQL, DML)—that can then be utilized to catalog and visualize which parts (fields) of which
relations (tables, views) are referenced by which other relations. Such visualizations could take on the
shape of an ER diagram, a connection matrix or other novel ways.

* SQL Parser, based on [`rhombic`](https://github.com/contiamo/rhombic)
  * parsing results as flat tables (views)
    * with tags to identify areas, roles (such as 'alias for a column in the `where` clause')
    * and source code positions

* generate simplified, dumbed-down ('trashed') copy of a given DB to
  * feed to analysis tools that might not understand the full gamut of SQL as understood by SQLite
  * or, in fact, feed to the SQLite command line tool which may be another version
  * also to take out all user-defined functions (UDFs) that are not available with the `sqlite3` CLI

* generate diagrams like / with
  * [Vega Reorderable Matrix](https://vega.github.io/vega/examples/reorderable-matrix/)
    to show *all* relations between tables and views (PKs, FKs, but also references used to build
    views, `order by` clauses, `join`s &c).

## DBay Trash Documentation

------------------------------------------------------------------------------------------------------------

### Trash Your DB for Fun and Profit

* 𓃕DeSQL is implemented in two submodules:
  * the SQL parser proper uses [`rhombic`](https://github.com/contiamo/rhombic) to turn SQL source text into
    an AST (a tree of syntax nodes); these are put into a flat table (where nesting is representing by ID
    to the parent node). This data is then annotated with tags by a series of views.
  * The `trash` submodule which extracts structural data from SQLite's system tables and pragmas. From this
    data, the `trash` module can generate a simplified version of the database.

The original documentation for the latter module, `trash`, is shown below; it has yet to be rewritten to fit
the purposes of 𓃕DeSQL.

#### Motivation

**The Problem**—you have a great SQLite3 database with all the latest features (like `strict` tables,
`generate`d columns, user-defined function calls in views and so on), and now you would like to use a tool
like [`visualize-sqlite`](https://lib.rs/crates/visualize-sqlite) or
[SchemaCrawler](https://www.schemacrawler.com/diagramming.html) to get a nice ER diagram for your many
tables. Well, now you have two problems.

Thing is, the moment you use UDFs in your DDL (as in, `create view v as select myfunction( x ) as x1 from
t;`) your `*.sqlite` file stops being viable as a stand-alone DB; because UDFs are declared on the
connection and defined in the host app's environment, they are not stored inside `*.sqlite` files, nor are
they present in an SQL dump file. Your database and your application have become an inseparable unit with a
mutual dependency on each other. But the way the common visualizers work is they require a standalone DB or
an SQL dump to generate output from, and they will choke on stuff they don't understand (even though the ER
relationships might not even be affected by the use of a user-defined function).

**The solution** to this conundrum that I've come up with is to prepare a copy of a given DB with all the
fancy stuff removed but all the essential building blocks—tables, views, primary keys, secondary keys,
uniqueness constraints—preserved.

I call this functionality `trash` which is both a pun on `dump` (as in 'dump the DB to an SQL file') and a
warning to the user that this is not a copy. You *do* trash your DB using this feature.

#### Properties of Trashed DBs

The following invariants of trashed DBs hold:

* To trash a DB, an SQL script is computed that replicates the DB's salient structural features.
* This script is either returned, written to a file, or used to produce a binary representation which is,
  again, either returned or written to a file.
* The SQL script runs in a single transaction.
* It starts by removing all relations, should they exist. This means one can always do `sqlite3 path/to/db <
  mytrasheddb.sql` even on an existing `path/to/db`.
* All fields of all relations will be present in the trashed copy.
* All trashed fields will have the same type declaration as the original DB (in the sense that they will use
  the same text used in the original DDL). However, depending on meta data as provided by SQLite3's internal
  tables and pragmas, some views may miss some type information.
* Empty type declarations and the missing type declaration of view fields will be rendered as `any` in the
  trash DDL.
* The trashed DB will contain no data (but see below).

**Discussion and Possible Enhancements**

* It is both trivial to show that, on the one hand, in a properly structured RDB, views can always be
  materialized to a table, complete with field names, data, and at least partial type information. However,
  on the other hand, it is also trivial to show that any given view (and any generated field, for that
  matter) may use arbitrarily complex computations in its definition—imagine a UDF that fetches content from
  the network as an example.
  * In SQLite, not all fields of all views have an explicit type (and even fields of tables can lack an
    explicit type or be of type `any`)
* There's somewhat of a grey zone between the two extremes of a view just being a join of two tables or an
  excerpt of a single one—something that would probably be reproducible in a trash DB with some effort
  towards SQL parsing. Whether this would be worth the effort—tackle SQL parsing with the goal to preserve
  views as views in a trash DB—is questionable. Observe that not even all built-in functions of SQLite3 are
  guaranteed to be present in a given compiled library or command line tool because those can be (and often
  are) configured to be left out; in this area there's also a certain variation across SQLite versions.
* An alternative to tackling the generally inattainable goal of leaving views as views would be to use
  user-defined prefixes for views (a view `"comedy_shows"` could be rendered as `"(view) comedy_shows"`).
  In light of the complications outlined here, this option looks vastly superior.

* The trashed DB will contain no data, but this could conceivably be changed in the future. When
  implemented, this will allow to pass around DBs 'for your information and pleasure only'. When this
  feature is implemented, a way to include/exclude specific relations will likely also be implemented.

#### API

**`trash_to_sql: ( { path: false, overwrite: false, walk: false, } ) ->`**
  * renders DB as SQL text
  * if `path` is given...
    * ... and a valid FS path, writes the SQL to that file and returns the path.
    * ... and `true`, a random path in DBay's `autolocation` will be chosen, written to, and returned.
    * ... and `false`, it will be treated as not given, see below.
  * if `path` exists, will fail unless `overwrite: true` is specified
  * if `path` is not given or `false`,
    * will return a string if `walk` is not `true`,
    * otherwise, will return an iterator over the lines of the produced SQL source.

**`trash_to_sqlite: ( { path: false, overwrite: false, } ) ->`**
  * renders DB as an SQLite3 binary representation
  * handling of `path`, `overwrite`, and the return value is done as described above for `trash_to_sql()`.
  * instead of writing or returning an SQL string, this method will write or return a `Buffer` (or a
    `TypedArray`???)

In any event, parameters that make no sense in the given combination (such as omitting `path` but specifying
`overwrite: true`) will be silently ignored.



## Progress Notes

### 2022-02-17T11:22:23+01:00

A moderately comples SQL query

```sql
create view v as select
    a,
    b,
    c,
    f( d ) as k
  from t
  join t2 using ( uuu )
  where e > 2
  order by k desc, l, m;
```

is parsed. In the `[akilsx]codes` columns the matching tags are displayed by tag category:

* `a` for **a**rea (aka 'clause' as in 'where clause', 'order-by clause'),
* `k` for SQL **k**eywords (of which in the below only `select`, `from`, and `where` are recognized),
* `i` for **i**dentifiers (`iali`: alias, `icol`: column, `ifuncn`: function, `irealn`: real name, `itbl`:
  table, so column `k` which is tagged `iali, icol`, is recognized as 'an identifier naming an alias for a
  column'),
* `l` for **l**iterals (which are not important for the purpose at hand; the single example here is `2`,
  tagged as `loth` ('other literal'), which is more than good enough),
* `s` for **s**ymbols (i.e. punctuation such as `>`, `.`, `;`),
* `x` for e**x**tras (an internal diagnostic field to prevent misspelled rule names from failing silently).

Furthermore, there's `pos1` which gives the offset (character count) of the respective production, `txt`
(the part of the query string being annotated), and `path` which traces the tree traversal akin to a path
in a file system (e.g. `-cview-q-qo-t` can be read as `/create-view/query/query-organization/terminal`, a
path shared by both `order` and `by`; names have been taken from the `rhombic` parser). All nodes end in
`-t` for `terminal` because all non-terminal nodes have been filtered out for conciseness.

![](art/Screenshot%202022-02-17%20at%2011.18.31.png)

### 2022-02-11T21:20:17+01:00

𓃕DeSQL now parses big parts of SQL sources and identifies its 'parts of speech'. We assemble
a list of nodes of the AST in table `raw_nodes`. From the position information given for the
`terminal` nodes we can infer what text has been matched. Furthermore we keep both track of what
parent each node has as well as a 'path' of the (abbreviated) type names of all ancestors:

![](art/Screenshot%202022-02-11%20at%2020.24.18.png)

Given this data, we can color code a given SQL source to indicate what parts have been matched
by which productions, allowing to differentiate between real and aliased names for columns and
tables:

![](art/Screenshot%202022-02-11%20at%2020.20.17.png)

At present the parser will skip all whitespace and comments, stop parsing
when encountering constructions deemed ungrammatical, and parse only
a single query. All these shortcomings will be addressed:

![](art/Screenshot%202022-02-11%20at%2021.40.15.png)


## To Do

* **[–]** consider to use `codemirror`'s' `lezer`
  * https://lezer-sandbox-1gurlbleb-a61.vercel.app
  * https://lezer.codemirror.net
  * https://news.ycombinator.com/item?id=31073800
* **[+]** add location information
* **[–]** fix (many) faulty location data (stop equals or precedes start line, column NR)
* **[–]** parse multiple statements
* **[–]** at present, comments and stuff the parser doesn't understand are left out of the result
  which constitues silent failure; ensure 100% source code coverage (whitespace may be left out,
  but not comments and also not unsyntactic garbage)
* **[–]** fix line, column numbers for coverage misses (whitespace and material stretches)
* **[–]** clarify relation to 𓆤DBay
* **[–]** consider to implement iterating over statements instead of lines in `trash_to_sql()`
* **[–]** consider to refactor trash into project `dbay-trash` b/c either it or (an additional module)
  will be in need of an SQL parser to provide in-depth structural insights

* **[–]** implement benchmarking / profiling tools to give users a better chance and an easier time
  with finding sopurces for bad performance:

  * in one case I noticed a particularly bad performance in a seemingly simple query `select * from t`
    which, however, referenced the last view in an entire suite of views; the row count was only ≈1,000, but
    the query took almost 3 seconds. I replaced two (simplistic) UDF calls and replaced them with a simple
    `x = ''` test; this brought the execution down by a whopping 0.5s which should mean that that function
    must have gotten called *a lot* of times. Still, with 2.5s being far too long I came up with the
    following: just iterate over all tables and views, preferrably in the order they are defined in the SQL
    source (which should somewhat match their topological sort order), and measure the timings (the original
    idea was really to do `select * from $tablename`, but it turns out `select count(*) from $tablename`
    suffices and delivers another metric, row counts):

    ```coffee
    { L, I, } = db.sql
    timings   = []
    for { name, } from db SQL"""
      with v1 as ( select row_number() over () as nr, name, type from sqlite_schema )
      select name from v1 where type in ( 'table', 'view' ) order by nr;"""
      sql   = SQL"select count(*) as count from #{I name};"
      count = time name, -> db.single_value sql±±
      dt    = TIME.toFixed 3                    ### NOTE contains time of last call to `time()` ###
      timings.push { name, count, dt, }
    H.tabulate "timings", timings
    ```

    What this does is it selects rows from `sqlite_schema` *without* filtering but adding row numbers along
    the way, in the hope that filter-less `select`ing will keep the rows in their original order; the query
    then filters for tables and views. For each relation name, a row-counting query is constructed and run
    with a stopwatch running. Relation names, row counts, and timings are then tabulated:

    ```
    ┌────────────────────────┬───────┬───────┐
    │name                    │count  │dt     │
    ├────────────────────────┼───────┼───────┤
    │mrg_datasources         │1      │0.000  │
    │mrg_mirror              │903    │0.000  │
    │mrg_raw_mirror          │903    │0.000  │
    │mrg_rwnmirror           │903    │0.001  │
    │mrg_parlnrs0            │802    │0.004  │
    │mrg_parlnrs             │97     │0.003  │ <--- good
    │mrg_parmirror           │903    │2.132  │ <--- bad!
    │mrg_pars0               │97     │2.134  │
    │mrg_pars                │97     │2.133  │
    │mrg_wspars              │198    │2.404  │
    │mrg_next_free_oln       │1      │0.000  │
    │mrg_html_atrids         │0      │0.000  │
    │mrg_html_atrs           │0      │0.001  │
    │mrg_html_typs           │7      │0.000  │
    │mrg_html_mirror         │0      │0.000  │
    │mrg_html_tags_and_html  │0      │0.000  │
    └────────────────────────┴───────┴───────┘
    ```

    One can see that—under the assumption that relations are indeed order according to their
    dependencies—that there's a 'performance cliff' between `mrg_parlnrs` and `mrg_parmirror` where
    execution time jumps from 3ms to 2,132ms, so roughly by three orders of magnitude. This could be, but in
    this case is certainly not directly caused by the latter having ten times as many rows as the former as
    is shown by comparing the timings with those from further above, where we see 800 to 900 rows being
    iterated over in a few milliseconds.

    And sure enough, inspecting the definition of `mrg_parmirror` show that the view DDL contains a
    [correlated subquery](https://www.toptal.com/sql-server/sql-database-tuning-for-developers) that will be
    run for each single row, and—much worse—that refers to several fields that are computed with window
    functions (`dense_rank()` and `row_number()`), which leads to the suspicion that the actual work of
    completing a single scan of `mrg_parmirror` (1000 rows) leads to 1,000<sup>2</sup> .. 1,000<sup>n</sup>
    table scans.

  * Query plan but with a much reduced interface:

    ```coffee
    show_query_plan = ->
      H.tabulate "query plan", db SQL"explain query plan select * from #{prefix}_wspars;"
      rows    = []
      counts  = {}
      for row from db SQL"explain query plan select * from #{prefix}_wspars;"
        continue unless /^(SCAN (?!SUBQUERY)|SEARCH)/.test row.detail
        key =  row.detail.replace /^(\S+).*$/, '$1'
        counts[ key ] = ( counts[ key ] ? 0 ) + 1
        # continue unless /^(SCAN|SEARCH)/.test row.detail
        rows.push row
      rows.sort ( a, b ) =>
        return +1 if a.detail > b.detail
        return -1 if a.detail < b.detail
        return  0
      H.tabulate "query plan", rows
      urge '^44873^', counts
      return null
    ```

* **[–]** have a look at [the `sqlglot` SQL parser](https://github.com/tobymao/sqlglot); written in Python
  but without dependencies so might be possible to include as static dependency. Notable for an article
  about[*Semantic Diff for SQL*](https://github.com/tobymao/sqlglot/blob/main/posts/sql_diff.md)

* **[–]** consider to use https://github.com/antlr/antlr4/blob/master/doc/javascript-target.md
  * also see
    * https://www.antlr.org
    * https://tomassetti.me/parsing-sql/
    * https://news.ycombinator.com/item?id=32560039
    * https://news.ycombinator.com/item?id=31107231
    * https://www.jooq.org/translate
    * https://datastation.multiprocess.io/blog/2022-04-11-sql-parsers.html
    * https://lobste.rs/s/25ewke/parsing_sql







