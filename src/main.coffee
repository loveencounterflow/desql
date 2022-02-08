
'use strict'



############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'DESQL'
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
info                      = CND.get_logger 'info',      badge
urge                      = CND.get_logger 'urge',      badge
help                      = CND.get_logger 'help',      badge
whisper                   = CND.get_logger 'whisper',   badge
echo                      = CND.echo.bind CND
#...........................................................................................................
# PATH                      = require 'path'
# FS                        = require 'fs'
types                     = new ( require 'intertype' ).Intertype
{ isa
  equals
  type_of
  validate
  validate_list_of }      = types.export()
GUY                       = require 'guy'
# { HDML }                  = require '../../../apps/hdml'
X                         = require '../../hengist/lib/helpers'
# { lets
#   freeze }                = GUY.lft
# { to_width }              = require 'to-width'
# { DBay }                  = require '../../../apps/dbay'
SQL                       = String.raw
# { SQL }                   = DBay
# { Sql }                   = require '../../../apps/dbay/lib/sql'
xrpr                      = ( x ) -> ( require 'util' ).inspect x, {
  colors: true, depth: Infinity, maxArrayLength: null, breakLength: Infinity, }
to_snake_case             = require 'just-snake-case'


#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
show_overview = ( db ) ->
  info '#############################################################################'
  X.tabulate "dbay_tables",                   db SQL"select * from dbay_tables"
  X.tabulate "dbay_unique_fields",            db SQL"select * from dbay_unique_fields"
  # X.tabulate "dbay_fields_1",                 db SQL"select * from dbay_fields_1"
  X.tabulate "dbay_fields",                   db SQL"select * from dbay_fields"
  X.tabulate "dbay_foreign_key_clauses_1",    db SQL"select * from dbay_foreign_key_clauses_1"
  X.tabulate "dbay_foreign_key_clauses_2",    db SQL"select * from dbay_foreign_key_clauses_2"
  # X.tabulate "dbay_foreign_key_clauses_3",    db SQL"select * from dbay_foreign_key_clauses_3"
  X.tabulate "dbay_foreign_key_clauses",      db SQL"select * from dbay_foreign_key_clauses"
  X.tabulate "dbay_primary_key_clauses_1",    db SQL"select * from dbay_primary_key_clauses_1"
  X.tabulate "dbay_primary_key_clauses",      db SQL"select * from dbay_primary_key_clauses"
  # X.tabulate "dbay_field_clauses_1",          db SQL"select * from dbay_field_clauses_1"
  X.tabulate "dbay_field_clauses",            db SQL"select * from dbay_field_clauses"
  # X.tabulate "dbay_create_table_clauses",     db SQL"select * from dbay_create_table_clauses"
  # X.tabulate "dbay_create_table_statements_1", db SQL"select * from dbay_create_table_statements_1"
  # X.tabulate "dbay_create_table_statements_2", db SQL"select * from dbay_create_table_statements_2"
  # X.tabulate "dbay_create_table_statements_3", db SQL"select * from dbay_create_table_statements_3"
  # X.tabulate "dbay_create_table_statements_4", db SQL"select * from dbay_create_table_statements_4"
  # X.tabulate "dbay_create_table_statements",  db SQL"select * from dbay_create_table_statements"
  # X.tabulate "dbay_create_table_statements",  db SQL"""
  #   select
  #       lnr,
  #       tail,
  #       substring( txt, 1, 100 ) as txt
  #     from dbay_create_table_statements;"""
  return null

#-----------------------------------------------------------------------------------------------------------
tabulate = ( db, query ) -> X.tabulate query, db query

#-----------------------------------------------------------------------------------------------------------
queries = [
  SQL"drop view if exists dbay_foreign_key_clauses_2;",
  SQL"""
    create view dbay_foreign_key_clauses_2 as select distinct
        fk_id                                                                     as fk_id,
        from_table_nr                                                             as from_table_nr,
        from_table_name                                                           as from_table_name,
        group_concat( std_sql_i( from_field_name ), ', ' ) over w                 as from_field_names,
        to_table_name                                                             as to_table_name,
        group_concat( std_sql_i(   to_field_name ), ', ' ) over w                 as to_field_names
      from dbay_foreign_key_clauses_1
      window w as (
        partition by from_table_name, fk_id
        order by fk_idx
        rows between unbounded preceding and unbounded following )
      order by from_table_name, fk_id, fk_idx;"""
  SQL"create table d ( x integer ) strict;"
  SQL"""create table d ( x "any" );"""
  SQL"select a from t;"
  SQL"insert into products ( nr, name ) values ( 1234, 'frob' );"
  SQL"select a, b from s join t using ( c );"
  SQL"select t1.a as alias, t2.b from s as t1 join t as t2 using ( c );"
  SQL"create view v as select a, b, c, f( d ) as k from t where e > 2;"
  SQL"create view v as select a, b, c, f( d ) as k from t join t2 using ( uuu ) where e > 2 order by k;"
  SQL"select a, b, c, f( d ) as k from t join t2 using ( uuu ) where e > 2 order by k;"
  SQL"""select
    42 as d;
    select 'helo world' as greetings;"""
  ]




#-----------------------------------------------------------------------------------------------------------
@demo_rhombic_antlr = ->
  CATALOG = require '../../../jzr-old/multimix/lib/cataloguing'
  { antlr  } = require 'rhombic'
  parser_cfg =
    doubleQuotedIdentifier: true
  lineage_cfg =
    positionalRefsEnabled: true
  # q = antlr.parse "SELECT * FROM abc join users as u;", parser_cfg
  # for query in [ SQL"""select d as "d1" from a as a1;""", ]
  # for query in [ SQL"""select d + e + f( x ) as "d1" from a as a1;""", ]
  # for query in [ SQL"""select * from a left join b where k > 1 order by m limit 1;""", ]
  # for query in [ SQL"SELECT 42 as a;", ]
  for query in [ queries[ queries.length - 1 ], ]
    echo query
    X.banner query
    q = antlr.parse query, parser_cfg
    debug CATALOG.all_keys_of q
    show_antler_tree q.tree
    # debug type_of q
    # info q.getUsedTables()
  return null

#-----------------------------------------------------------------------------------------------------------
type_of_antler_node = ( node ) ->
  R = node.constructor.name
  R = R.replace /(Node|Context)$/, ''
  R = to_snake_case R
  return R

#-----------------------------------------------------------------------------------------------------------
show_antler_tree = ( tree ) ->
  objects_by_type = _show_antler_tree { children: [ tree, ], }, 0, {}
  types           = ( k for k of objects_by_type ).sort()
  # for type in types
  #   d     = objects_by_type[ type ]
  #   keys  = ( k for k of d when not k.startsWith '_' ).sort()
  #   urge type, keys
    # if d._line?
    #   debug '^5600-1^', ( type_of d._line ), Object.keys d._line
  return null

#-----------------------------------------------------------------------------------------------------------
_show_antler_tree = ( tree, level, R ) ->
  dent  = '  '.repeat level
  # debug '^4656-1^' + dent + ( type_of tree ) + ' ' + rpr tree.text
  for node in tree.children
    #.......................................................................................................
    # do =>
    #   for k, v of node
    #     continue unless v?
    #     help '^5600-3^', k, ( type_of v ), ( Object.keys v )
    #   if node._start?
    #     info '^5600-4^', "node._start?.index", node._start?.index
    #     info '^5600-5^', "node._start?._line", node._start?._line
    #     info '^5600-6^', "node._start?._charPositionInLine", node._start?._charPositionInLine
    #     info '^5600-7^', "node._stop?._line", node._stop?._line
    #     info '^5600-8^', "node._stop?._charPositionInLine", node._stop?._charPositionInLine
    #   if node._symbol?
    #     info '^5600-9^', "type_of node._symbol.start", type_of node._symbol.start
    #     info '^5600-9^', "node._symbol.start", node._symbol.start
    #     info '^5600-9^', "node._symbol.stop", node._symbol.stop
    #     info '^5600-9^', "node._symbol.line", node._symbol.line
    #     info '^5600-9^', "node._symbol._charPositionInLine", node._symbol._charPositionInLine
    #.......................................................................................................
    type        = type_of_antler_node node
    R[ type ]  ?= node
    type_entry  = antler_types[ type ]
    switch type_entry_type = type_of type_entry
      when 'undefined'
        warn '^4656-1^' + dent + type + ' ' + ( CND.gold rpr node.text )
      when 'null'
        whisper '^4656-1^' + dent + type + ' ' + ( rpr node.text )
      when 'function'
        whisper '^5600-2^', '------------------------------------------------------------'
        info '^4656-1^' + dent + type + ' ' + ( CND.gold rpr node.text )
        debug '^4656-1^', type_entry node
      else
        warn CND.reverse '^4656-1^' + dent + type + ' ' + ( CND.gold rpr node.text ) + " unknown type entry type #{rpr type_entry_type}"
    if node.children?
      _show_antler_tree node, level + 1, R
  return R

#-----------------------------------------------------------------------------------------------------------
antler_types =
  #.........................................................................................................
  terminal: null
  #.........................................................................................................
  select_clause: ( node ) ->
    terminal  = node.children[ 0 ]
    idx1      = terminal._symbol.start
    idx2      = terminal._symbol.stop
    lnr       = terminal._symbol._line
    col       = terminal._symbol._charPositionInLine + 1
    unless ( type = type_of_antler_node terminal ) is 'terminal'
      throw new Error "unexpected type #{rpr type}"
    unless ( /^select$/i  ).test ( text = terminal.text )
      throw new Error "unexpected terminal #{rpr text}"
    debug '^4353^', { type, text, idx1, idx2, lnr, col, subs: [], }
  #.........................................................................................................
  regular_query_specification:  null
  query_primary_default:        null
  query_term_default:           null
  query:                        null
  statement_default:            null




############################################################################################################
if module is require.main then do =>
  @demo_rhombic_antlr()


#   #---------------------------------------------------------------------------------------------------------
#   _walk_statements_from_path: ( sql_path ) ->
#     ### Given a path, iterate over SQL statements which are signalled by semicolons (`;`) that appear outside
#     of literals and comments (and the end of input). ###
#     ### thx to https://stackabuse.com/reading-a-file-line-by-line-in-node-js/ ###
#     ### thx to https://github.com/nacholibre/node-readlines ###
#     readlines       = new ( require 'n-readlines' ) sql_path
#     #.......................................................................................................
#     cfg           =
#       regExp: ( require 'mysql-tokenizer/lib/regexp-sql92' )
#     tokenize      = ( require 'mysql-tokenizer' ) cfg
#     collector     = null
#     # stream        = FS.createReadStream sql_path
#     #.......................................................................................................
#     flush = ->
#       R         = collector.join ''
#       collector = null
#       return R
#     #.......................................................................................................
#     while ( line = readlines.next() ) isnt false
#       for token, cur_idx in tokenize line + '\n'
#         if token is ';'
#           ( collector ?= [] ).push token
#           yield flush()
#           continue
#         # if token.startsWith '--'
#         #   continue
#         ( collector ?= [] ).push token
#     #.......................................................................................................
#     yield flush() if collector?
#     return null

