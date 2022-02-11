



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

<!-- clarify relation to 𓆤DBay -->

🚧 Work in progress 🚧

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



