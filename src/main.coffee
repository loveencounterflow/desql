
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
{ DBay }                  = require 'dbay'
{ SQL }                   = DBay
to_snake_case             = require 'just-snake-case'
{ antlr: ANTLR          } = require 'rhombic'


#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
class @Desql

  #---------------------------------------------------------------------------------------------------------
  constructor: ( P... ) ->
    throw new Error "^345^ configuration settings not supported" if P.length > 0
    @db = new DBay()
    @_procure_infrastructure()
    @_compile_sql()
    return undefined

  #---------------------------------------------------------------------------------------------------------
  _procure_infrastructure: ->
    ### TAINT check if tables exist ###
    @db.create_stdlib()
    @db SQL"""
      create table queries (
          qid     integer not null primary key,
          length  integer generated always as ( length( query ) ),
          query   text    not null );
      create table raw_nodes (
          qid     integer not null,
          id      integer not null,
          xtra    integer not null default 1,
          upid    integer,
          type    text    not null,
          pos1    integer,
          pos2    integer,
          lnr1    integer,
          col1    integer,
          lnr2    integer,
          col2    integer,
          txt     text,
        primary key ( qid, id, xtra ),
        foreign key ( qid ) references queries
        -- foreign key ( upid ) references raw_nodes ( id ) DEFERRABLE INITIALLY DEFERRED
        );"""
    @db SQL"""
      create view _coverage_1 as select
          n.qid                                                 as qid,
          n.id                                                  as id,
          n.xtra                                                as xtra,
          n.pos1                                                as pos1,
          n.pos2                                                as pos2,
          substring( q.query, n.pos1, n.pos2 - n.pos1 + 1 )     as txt
        from raw_nodes as n
        join queries as q using ( qid )
        where pos1 is not null;"""
    @db SQL"""
      create view coverage_holes_1 as select
          *,
          substring( q.query, n.value, 1 ) as chr
        from
          queries as q,
          std_generate_series( 1, q.length ) as n
        where not exists (
          select 1 from _coverage_1 as c
          where c.qid = q.qid and n.value between c.pos1 and c.pos2
          /* and not std_re_is_match( substring( q.query, n.value, 1 ), '\s' ) */ )
      ;"""
    @db SQL"""
      create view coverage as select
          *
        from _coverage_1
        order by pos1;"""
    return null

  #---------------------------------------------------------------------------------------------------------
  _compile_sql: ->
    GUY.props.hide @, 'statements',
      #.....................................................................................................
      insert_query: @db.prepare_insert
        into:         'queries'
        exclude:      [ 'qid', ]
        returning:    '*'
      #.....................................................................................................
      insert_regular_node: @db.prepare SQL"""
        insert into raw_nodes ( qid, id, upid, type, pos1, pos2, lnr1, col1, lnr2, col2 )
          values (
            $qid,
            ( select coalesce( max( id ), 0 ) + 1 as id from raw_nodes ),
            $upid, $type, $pos1, $pos2, $lnr1, $col1, $lnr2, $col2 )
          returning *;"""
      #.....................................................................................................
    return null

  #---------------------------------------------------------------------------------------------------------
  parse: ( query ) ->
    parser_cfg      =
      doubleQuotedIdentifier: true
    antlr           = { children: [ ( ANTLR.parse query, parser_cfg ).tree, ], }
    R               = { type: 'query', nodes: [], }
    { qid, }        = @statements.insert_query.get { query, }
    @_build_tree qid, query, antlr, null, 0, R
    return R

  #---------------------------------------------------------------------------------------------------------
  _build_tree: ( qid, query, antlr, parent, level, tree ) ->
    for branch in antlr.children
      type            = @_type_of_antler_node branch
      position        = @_position_from_branch branch
      txt             = null
      # txt             = query[ position.pos1 .. position.pos2 ] if position.pos1?
      # txt             = ( Array.from query )[ position.pos1 .. position.pos2 ].join '' if position.pos1?
      upid            = parent?.id ? null
      flat_node       = { qid, upid, type, position..., }
      # flat_node.txt   = if txt is '' then null else txt
      @db SQL"savepoint svp_name;"
      flat_node       = @statements.insert_regular_node.get flat_node
      # dent  = '  '.repeat level; debug '^9876^', dent + rpr flat_node
      node            = { flat_node..., nodes: [], }
      if branch.children?
        @_build_tree qid, query, branch, flat_node, level + 1, node
      if ( node.type isnt 'terminal' ) and ( node.nodes.length is 0 )
        @db SQL"rollback transaction to savepoint svp_name;" # , { svp_name, }
      else
        @db SQL"release svp_name;"
        tree.nodes.push node
      delete node.nodes if node.nodes.length is 0
    return null

  #---------------------------------------------------------------------------------------------------------
  _type_of_antler_node: ( node ) ->
    R = node.constructor.name
    R = R.replace /(Node|Context)$/, ''
    R = to_snake_case R
    return R

  #---------------------------------------------------------------------------------------------------------
  _position_from_branch: ( branch ) ->
    if branch._symbol?
      pos1  = branch._symbol.start + 1
      lnr1  = branch._symbol._line
      col1  = branch._symbol._charPositionInLine + 1
      pos2  = branch._symbol.stop  + 1
      lnr2  = branch._symbol._line
      col2  = branch._symbol._charPositionInLine + 1 + branch._symbol.stop - branch._symbol.start
    else
      pos1  = null
      lnr1  = null
      col1  = null
      pos2  = null
      lnr2  = null
      col2  = null
    return { pos1, lnr1, col1, pos2, lnr2, col2, }

