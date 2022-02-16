



# 𓃕DeSQL SQL Parser




<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [𓃕DeSQL SQL Parser](#%F0%93%83%95desql-sql-parser)
  - [Goal](#goal)
  - [2022-02-11T21:20:17+01:00](#2022-02-11t2120170100)
  - [To Do](#to-do)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->




# 𓃕DeSQL SQL Parser

* 𓃕DeSQL = **D**iagram to **E**xplain **S**QL (𓃕 = Holy Cow!)

🚧 Work in progress 🚧


Goals and components:

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

## Goal

Provide a tool that can deliver an in-depth analysis of a given set of SQL
statements—be it Data Definition, Query or Manipulation Language (DDL, DQL,
DML)—that can then be utilized to catalog and visualize which parts (fields)
of which relations (tables, views) are referenced by which other relations.
Such visualizations could take on the shape of an ER diagram, a connection
matrix or other novel ways.


## 2022-02-11T21:20:17+01:00

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

* **[+]** add location information
* **[–]** fix (many) faulty location data (stop equals or precedes start line, column NR)
* **[–]** parse multiple statements
* **[–]** at present, comments and stuff the parser doesn't understand are left out of the result
  which constitues silent failure; ensure 100% source code coverage (whitespace may be left out,
  but not comments and also not unsyntactic garbage)
* **[–]** fix line, column numbers for coverage misses (whitespace and material stretches)
* **[–]** clarify relation to 𓆤DBay



