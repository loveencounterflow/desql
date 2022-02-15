
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

  @C: GUY.lft.freeze
    pathsep:  '-'

  #---------------------------------------------------------------------------------------------------------
  constructor: ( P... ) ->
    throw new Error "^345^ configuration settings not supported" if P.length > 0
    @db = new DBay()
    @_procure_infrastructure()
    @_procure_infradata()
    @_compile_sql()
    return undefined

  #---------------------------------------------------------------------------------------------------------
  _procure_infradata: ->
    @db SQL"""
      insert into ntypes ( name, short ) values
        -- .................................................................................................
        ( 'spc',                                'spc'       ),
        ( 'miss',                               'miss'      ),
        ( 'start',                              'start'     ),
        ( 'stop',                               'stop'      ),
        -- .................................................................................................
        ( 'ansi_non_reserved',                  'ansinr'    ),
        ( 'arithmetic_binary',                  'arthbin'   ),
        ( 'aliased_query',                      'aq'        ),
        ( 'column_reference',                   'cref'      ),
        ( 'col_type_list',                      'cltl'      ),
        ( 'col_type',                           'clt'       ),
        ( 'constant',                           'c'         ),
        ( 'comparison',                         'cmp'       ),
        ( 'comparison_operator',                'cmpop'     ),
        ( 'create_table',                       'ctable'    ),
        ( 'create_table_header',                'ctableh'   ),
        ( 'create_view',                        'cview'     ),
        ( 'dereference',                        'dref'      ),
        ( 'dml_statement',                      'dml'       ),
        ( 'drop_view',                          'dropv'     ),
        ( 'error_capturing_identifier',         'eci'       ),
        ( 'expression',                         'e'         ),
        ( 'frame_bound',                        'fb'        ),
        ( 'from_clause',                        'from'      ),
        ( 'function_call',                      'fc'        ),
        ( 'function_name',                      'fn'        ),
        ( 'identifier',                         'i'         ),
        ( 'insert_into_table',                  'iit'       ),
        ( 'join_relation',                      'jr'        ),
        ( 'join_criteria_on',                   'jco'       ),
        ( 'join_criteria_using',                'jcu'       ),
        ( 'identifier_list',                    'il'        ),
        ( 'identifier_seq',                     'is'        ),
        ( 'inline_table',                       'it'        ),
        ( 'inline_table_default1',              'itd1'      ),
        ( 'multipart_identifier',               'mi'        ),
        ( 'named_expression',                   'ne'        ),
        ( 'named_expression_seq',               'nes'       ),
        ( 'named_window',                       'nw'        ),
        ( 'numeric_literal',                    'nl'        ),
        ( 'integer_literal',                    'int'       ),
        ( 'parenthesized_expression',           'pe'        ),
        ( 'predicated',                         'pd'        ),
        ( 'primitive_data_type',                'pdt'       ),
        ( 'qualified_name',                     'qn'        ),
        ( 'query',                              'q'         ),
        ( 'query_organization',                 'qo'        ),
        ( 'query_primary',                      'qp'        ),
        ( 'query_term',                         'qt'        ),
        ( 'quoted_identifier',                  'qi'        ),
        ( 'quoted_identifier_alternative',      'qia'       ),
        ( 'regular_query_specification',        'rqs'       ),
        ( 'relation',                           'r'         ),
        ( 'row_constructor',                    'roco'      ),
        ( 'searched_case',                      'case'      ),
        ( 'select_clause',                      'select'    ),
        ( 'set_quantifier',                     'sq'        ),
        ( 'single_insert_query',                'siq'       ),
        ( 'sort_item',                          'si'        ),
        ( 'string_literal',                     'str'       ),
        ( 'statement',                          's'         ),
        ( 'table_alias',                        'ta'        ),
        ( 'table_name',                         'tn'        ),
        ( 'terminal',                           't'         ),
        ( 'unquoted_identifier',                'ui'        ),
        ( 'value_expression',                   've'        ),
        ( 'when_clause',                        'when'      ),
        ( 'where_clause',                       'where'     ),
        ( 'window_clause',                      'window'    ),
        ( 'window_def',                         'wd'        ),
        ( 'window_frame',                       'wf'        ),
        ( 'window_ref',                         'wr'        );"""
    #.......................................................................................................
    for name in [
        #...................................................................................................
        ### areas ###
        'a create view'
        'a select'
        'a from'
        #...................................................................................................
        ### identifiers ###
        'i function name'
        # 'i join on col name'
        # 'i join on tbl alias'
        # 'i join on tbl name'
        # 'i order by col name'
        # 'i order by tbl name'
        # 'i other'
        # 'i from col alias'
        # 'i from col name'
        # 'i from'±±

        'i col'
        'i tbl'
        'i alias'
        'i real name'

        #...................................................................................................
        ### keywords ###
        'k generated always as'
        'k generated always'
        'k generated'
        'k insert into'
        'k insert'
        'k join on'
        'k join using'
        'k join'
        'k order by ascending'
        'k order by descending'
        'k order by'
        'k order'
        'k from'
        'k select'
        'k where'
        'k window as'
        'k window'
        'k with'
        'l other'
        #...................................................................................................
        ### symbols (punctuation) ###
        's bracket round left'
        's bracket round right'
        's colon'
        's comma'
        's dot'
        's o-perator'
        's semi-colon'
        's spc' ]
      { code, name, } = @_code_and_name_from_tcat_name name
      try
        @db SQL"insert into tcats ( code, name ) values ( $code, $name )", { code, name, }
      catch error
        debug error.name
        throw error unless error.code in [ 'SQLITE_CONSTRAINT_UNIQUE', 'SQLITE_CONSTRAINT_PRIMARYKEY', ]
        throw new Error "^desql/_procure_infradata@1^ tcat code: #{rpr code} (name: #{rpr name}) is not unique"
    #.......................................................................................................
    for [ name, matcher, ] in [
      #.....................................................................................................
      [ 'a create view',    '-cview-',                          ]
      [ 'a from',           '-from-',                           ]
      [ 'a select',         '-select-',                         ]
      #.....................................................................................................
      [ 'i alias',          '-tn-ta-[uq]i-t',                   ]
      [ 'i col',            '-ve-cref-i-[uq]i-t$',              ]
      [ 'i col',            '-dref-i-[uq]i-t$',                 ]
      [ 'i col',            '-ne-eci-i-[uq]i-t$',                 ]
      [ 'i alias',          '-ne-eci-i-[uq]i-t$',                 ]
      [ 'i real name',      '-ve-cref-i-[uq]i-t$',              ]
      [ 'i function name',  '-fc-fn-qn-i-[uq]i-t$'              ]
      [ 'i real name',      '-cview-mi-eci-i-[uq]i-t$',         ]
      [ 'i real name',      '-tn-.*-i-[uq]i-t$',                ]
      [ 'i real name',      '-ve-dref-i-[uq]i-t$',                ]
      [ 'i tbl',            '-cview-mi-eci-i-[uq]i-t$',         ]
      [ 'i tbl',            '-tn-.*-i-[uq]i-t$',                ]
      [ 'i tbl',            '-tn-ta-[uq]i-t',                   ]
      [ 'i tbl',            '-dref-cref-i-[uq]i-t',             ]
      # [ 'i other',        '-[uq]i-t$',                        ]
      #.....................................................................................................
      [ 'k from',           '-from-t$',                         ]
      [ 'k select',         '-select-t$',                       ]
      [ 'k where',          '-where-t$',                       ]
      #.....................................................................................................
      [ 'l other',          '-c-.*-t$',                         ]
      #.....................................................................................................
      [ 's dot',            '-ve-dref-t$',                      ]
      #.....................................................................................................
      ]

      # [ 'view name',                                '-cv-mi-eci-i-[uq]i-t$'                     ]
      # [ 'tbl name in fqn (`t.col`)',              '-dref-cref-i-[uq]i-t$'                     ]
      # [ 'col name in fqn (`t.col`)',                '-dref-i-[uq]i-t$'                          ]
      # [ 'col name in fqn (`t.col`) (also SQL kw)',  '-dref-i-[uq]i-ansinr-t$'                   ]
      # [ 'col name in select',                       '-select-nes-ne-e-pd-ve.*-cref-i-[uq]i-t$'  ]
      # [ 'create tbl name',                        '-ctable-ctableh-mi-eci-i-[uq]i-t$'         ]
      # [ 'create view name',                         '-cview-mi-eci-i-[uq]i-t$'                  ]
      # [ 'tbl alias',                              '-tn-ta-[uq]i-t$'                           ]
      # [ 'col alias',                                '-nes-ne-eci-i-[uq]i-t$'                    ]
      # [ 'col alias (also SQL kw)',                  '-nes-ne-eci-i-[uq]i-ansinr-t$'             ]
      # [ 'col in order by',                          '-qo-si-e-pd-ve-cref-i-[uq]i-t$'            ]
      # [ 'id in join criteria',                      '-jc[ou]-.*-i-[uq]i-t$'                     ]
      #.....................................................................................................
      { code, name, } = @_code_and_name_from_tcat_name name
      if ( @db.single_value SQL"select count(*) from tcats where code = $code", { code, } ) is 0
        code  = "X#{code}"
        name  = "X #{name}"
        @db SQL"insert into tcats ( code, name ) values ( $code, $name )", { code, name, }
      @db SQL"insert into tcat_rules ( code, matcher ) values ( $code, $matcher );", { code, matcher, }
    #.......................................................................................................
    return null

  #---------------------------------------------------------------------------------------------------------
  _code_and_name_from_tcat_name: ( cname ) ->
    code  = cname.replace /-/g, ' '
    name  = cname.replace /-/g, ''
    switch code[ 0 ]
      when 'xxx'
        # group letter + initials of following words
        code  = code.replace /(?:^|\s+)(.)\S*/g, '$1'
      else
        # group letter + up to four letters of word 1 but no trailing vowel + initials of words 2 and on
        head  = code.replace /^(\S+)\s+(\S{1,3}[^aeiou\s]?).*$/, '$1$2'
        tail  = code.replace /^\S+\s+\S+\s*/, ''
        tail  = tail.replace /(?:^|\s+)(.)\S*/g, '$1'
        code  = head + tail
    return { code, name, }

  #---------------------------------------------------------------------------------------------------------
  _procure_infrastructure: ->
    ### TAINT check if tables exist ###
    @db.create_stdlib()
    pathsep_lit = @db.sql.L @constructor.C.pathsep
    #.......................................................................................................
    @db SQL"""
      create table ntypes ( -- node types
          name    text not null primary key,
          short   text not null unique );"""
    #.......................................................................................................
    @db SQL"""
      create table tcats ( -- terminal category codes
          code    text not null primary key,
          name    text not null unique );"""
    #.......................................................................................................
    @db SQL"""
      create table tcat_rules (
          id      integer not null primary key,
          code    text not null references tcats,
          type    text not null default 're',
          matcher text not null,
        check ( type = 're' ) );"""
    #.......................................................................................................
    @db SQL"""
      create view tcat_matches as select
          nd.qid    as qid,
          nd.id     as id,
          nd.xtra   as xtra,
          tc.code   as code,
          tc.name   as name,
          -- tr.id     as rid,
          nd.path   as path,
          nd.pos1   as pos1,
          nd.pos2   as pos2,
          nd.txt    as txt
        from nodes      as nd
        join tcat_rules as tr on ( std_re_is_match( nd.path, tr.matcher ) )
        join tcats      as tc using ( code )
        order by nd.qid, nd.pos1
        ;"""
    #.......................................................................................................
    @db SQL"""
      create table queries (
          qid     integer not null primary key,
          length  integer generated always as ( length( query ) ),
          query   text    not null );"""
    #.......................................................................................................
    @db SQL"""
      create table raw_nodes (
          qid     integer not null,
          id      integer not null,
          xtra    integer not null default 1,
          upid    integer,
          type    text    not null,
          path    text    not null,
          pos1    integer,
          pos2    integer,
          lnr1    integer,
          col1    integer,
          lnr2    integer,
          col2    integer,
        primary key ( qid, id, xtra ),
        foreign key ( qid ) references queries
        -- foreign key ( upid ) references raw_nodes ( id ) DEFERRABLE INITIALLY DEFERRED
        );"""
    #.......................................................................................................
    @db SQL"""
      create view _coverage_1 as select
          n.qid                                                           as qid,
          n.id                                                            as id,
          n.xtra                                                          as xtra,
          n.upid                                                          as upid,
          n.type                                                          as type,
          n.path                                                          as path,
          n.pos1                                                          as pos1,
          n.pos2                                                          as pos2,
          n.lnr1                                                          as lnr1,
          n.col1                                                          as col1,
          n.lnr2                                                          as lnr2,
          n.col2                                                          as col2,
          substring( q.query, n.pos1, n.pos2 - n.pos1 + 1 )               as txt
        from raw_nodes as n
        join queries as q using ( qid )
        where pos1 is not null;"""
    #.......................................................................................................
    @db SQL"""
      create view _coverage_holes_1 as select
          c.qid                                                           as qid,
          c.id                                                            as id,
          c.xtra                                                          as prv_xtra,
          c.upid                                                          as prv_upid,
          c.type                                                          as prv_type,
          c.path                                                          as prv_path,
          c.pos1                                                          as pos1,
          c.pos2                                                          as pos2,
          c.pos2 + 1                                                      as nxt_pos1,
          lead( c.pos1 ) over w - 1                                       as nxt_pos2,
          -- ### TAINT the line and column numbers of coverage holes are those from the
          -- preceding recognized terminal, not those of the added space & solid material.
          -- As such, these numbers are out of sync with the `pos1`, `pos2` fields.
          -- This should be fixed in a future iteration.
          c.lnr1                                                          as lnr1,
          c.col1                                                          as col1,
          c.lnr2                                                          as lnr2,
          c.col2                                                          as col2,
          c.txt                                                           as txt
        from _coverage_1 as c
        window w as ( partition by qid order by pos1 );"""
    #.......................................................................................................
    @db SQL"""
      create view _coverage_holes_2 as select
          c.qid                                                           as qid,
          c.id                                                            as id,
          c.prv_xtra                                                      as prv_xtra,
          c.prv_upid                                                      as prv_upid,
          c.prv_type                                                      as prv_type,
          c.prv_path                                                      as prv_path,
          c.nxt_pos1                                                      as pos1,
          c.nxt_pos2                                                      as pos2,
          c.lnr1                                                          as lnr1,
          c.col1                                                          as col1,
          c.lnr2                                                          as lnr2,
          c.col2                                                          as col2,
          substring( q.query, c.nxt_pos1, c.nxt_pos2 - c.nxt_pos1 + 1 )   as txt
        from _coverage_holes_1  as c
        join queries            as q using ( qid )
        where c.nxt_pos1 <= c.nxt_pos2;"""
    #.......................................................................................................
    @db SQL"""
      create view _coverage_holes as select
          c.qid                                                           as qid,
          c.id                                                            as id,
          2                                                               as xtra,
          c.prv_upid                                                      as upid,
          r.type                                                          as type,
          c.prv_path || #{pathsep_lit} || r.type                          as path,
          c.pos1                                                          as pos1,
          c.pos2                                                          as pos2,
          c.lnr1                                                          as lnr1,
          c.col1                                                          as col1,
          c.lnr2                                                          as lnr2,
          c.col2                                                          as col2,
          c.txt                                                           as txt
        from _coverage_holes_2  as c
        join ( select
            qid,
            id,
            case when std_str_is_blank( txt ) then 'spc'
              else 'miss' end                                             as type
          from _coverage_holes_2 ) as r using ( qid, id );"""
    #.......................................................................................................
    @db SQL"""
      create view coverage as select
          *
        from _coverage_1
        where txt != ''
      union all select
          *
        from _coverage_holes
        order by qid, pos1;"""
    #.......................................................................................................
    @db SQL"""
      create view nodes as select
          *,
          null as txt
        from raw_nodes
        where pos1 is null
      union all select
          *
        from coverage
        order by qid, id, xtra;"""
    #.......................................................................................................
    return null

  #---------------------------------------------------------------------------------------------------------
  _compile_sql: ->
    pathsep_lit = @db.sql.L @constructor.C.pathsep
    GUY.props.hide @, 'statements',
      #.....................................................................................................
      insert_query: @db.prepare_insert
        into:         'queries'
        exclude:      [ 'qid', ]
        returning:    '*'
      #.....................................................................................................
      insert_special_node: @db.prepare_insert
        into:         'raw_nodes'
        returning:    '*'
      #.....................................................................................................
      insert_regular_node: @db.prepare SQL"""
        insert into raw_nodes ( qid, id, upid, type, path, pos1, pos2, lnr1, col1, lnr2, col2 )
          with
            t as ( select *                 from ntypes      where name = $type ),
            r as ( select *, count(*) as _  from raw_nodes  where qid = $qid and id = $upid and xtra = 1 )
          select
              $qid,
              ( select coalesce( max( id ), 0 ) + 1 as id from raw_nodes ),
              $upid,
              $type,
              coalesce( r.path, '' ) || #{pathsep_lit} || t.short,
              $pos1, $pos2, $lnr1, $col1, $lnr2, $col2
            from t, r
            where true
          returning *;"""
      #.....................................................................................................
      insert_start_node: @db.prepare SQL"""
        insert into raw_nodes ( qid, id, xtra, upid, type, path, pos1, pos2, lnr1, col1, lnr2, col2 )
          values (
            $qid, 1, 1, null, 'start', 'start', 1, 0, 0, 0, 0, 0 )
          returning *;"""
      #.....................................................................................................
      insert_stop_node: @db.prepare SQL"""
        insert into raw_nodes ( qid, id, xtra, upid, type, path, pos1, pos2, lnr1, col1, lnr2, col2 )
          values (
            $qid,
            ( select coalesce( max( id ), 0 ) + 1 as id from raw_nodes ),
            1, null, 'stop', 'stop',
            -- ### TAINT would use CET but fails with "no such column: v.length"
            ( select length + 1 from queries where qid = $qid ),
            ( select length     from queries where qid = $qid ),
            0, 0, 0, 0 )
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
    R.nodes.push @statements.insert_start_node.get { qid, }
    @_build_tree qid, query, antlr, null, R
    R.nodes.push @statements.insert_stop_node.get { qid, }
    return R

  #---------------------------------------------------------------------------------------------------------
  _build_tree: ( qid, query, antlr, parent, tree ) ->
    pathsep = @constructor.C.pathsep
    for branch in antlr.children
      type            = @_type_of_antler_node branch
      position        = @_position_from_branch branch
      txt             = null
      upid            = parent?.id ? null
      flat_node       = { qid, upid, type, position..., }
      @db SQL"savepoint svp_name;"
      flat_node       = @statements.insert_regular_node.get flat_node
      node            = { flat_node..., nodes: [], }
      if branch.children?
        @_build_tree qid, query, branch, flat_node, node
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
    R = R.replace /(Node|(Default)?Context)$/, ''
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
