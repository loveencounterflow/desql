(function() {
  'use strict';
  var ANTLR, CND, GUY, SQL, X, _build_tree, antler_types, badge, build_tree, debug, echo, equals, help, info, isa, position_from_node, queries, rpr, shorten, show_overview, show_series, tabulate, to_snake_case, type_of, type_of_antler_node, types, urge, validate, validate_list_of, warn, whisper, xrpr;

  //###########################################################################################################
  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'DESQL';

  debug = CND.get_logger('debug', badge);

  warn = CND.get_logger('warn', badge);

  info = CND.get_logger('info', badge);

  urge = CND.get_logger('urge', badge);

  help = CND.get_logger('help', badge);

  whisper = CND.get_logger('whisper', badge);

  echo = CND.echo.bind(CND);

  //...........................................................................................................
  // PATH                      = require 'path'
  // FS                        = require 'fs'
  types = new (require('intertype')).Intertype();

  ({isa, equals, type_of, validate, validate_list_of} = types.export());

  GUY = require('guy');

  // { HDML }                  = require '../../../apps/hdml'
  X = require('../../hengist/lib/helpers');

  // { lets
  //   freeze }                = GUY.lft
  // { to_width }              = require 'to-width'
  // { DBay }                  = require '../../../apps/dbay'
  SQL = String.raw;

  // { SQL }                   = DBay
  // { Sql }                   = require '../../../apps/dbay/lib/sql'
  xrpr = function(x) {
    return (require('util')).inspect(x, {
      colors: true,
      depth: 2e308,
      maxArrayLength: null,
      breakLength: 2e308
    });
  };

  to_snake_case = require('just-snake-case');

  ({
    antlr: ANTLR
  } = require('rhombic'));

  //===========================================================================================================

  //-----------------------------------------------------------------------------------------------------------
  show_overview = function(db) {
    info('#############################################################################');
    X.tabulate("dbay_tables", db(SQL`select * from dbay_tables`));
    X.tabulate("dbay_unique_fields", db(SQL`select * from dbay_unique_fields`));
    // X.tabulate "dbay_fields_1",                 db SQL"select * from dbay_fields_1"
    X.tabulate("dbay_fields", db(SQL`select * from dbay_fields`));
    X.tabulate("dbay_foreign_key_clauses_1", db(SQL`select * from dbay_foreign_key_clauses_1`));
    X.tabulate("dbay_foreign_key_clauses_2", db(SQL`select * from dbay_foreign_key_clauses_2`));
    // X.tabulate "dbay_foreign_key_clauses_3",    db SQL"select * from dbay_foreign_key_clauses_3"
    X.tabulate("dbay_foreign_key_clauses", db(SQL`select * from dbay_foreign_key_clauses`));
    X.tabulate("dbay_primary_key_clauses_1", db(SQL`select * from dbay_primary_key_clauses_1`));
    X.tabulate("dbay_primary_key_clauses", db(SQL`select * from dbay_primary_key_clauses`));
    // X.tabulate "dbay_field_clauses_1",          db SQL"select * from dbay_field_clauses_1"
    X.tabulate("dbay_field_clauses", db(SQL`select * from dbay_field_clauses`));
    // X.tabulate "dbay_create_table_clauses",     db SQL"select * from dbay_create_table_clauses"
    // X.tabulate "dbay_create_table_statements_1", db SQL"select * from dbay_create_table_statements_1"
    // X.tabulate "dbay_create_table_statements_2", db SQL"select * from dbay_create_table_statements_2"
    // X.tabulate "dbay_create_table_statements_3", db SQL"select * from dbay_create_table_statements_3"
    // X.tabulate "dbay_create_table_statements_4", db SQL"select * from dbay_create_table_statements_4"
    // X.tabulate "dbay_create_table_statements",  db SQL"select * from dbay_create_table_statements"
    // X.tabulate "dbay_create_table_statements",  db SQL"""
    //   select
    //       lnr,
    //       tail,
    //       substring( txt, 1, 100 ) as txt
    //     from dbay_create_table_statements;"""
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  tabulate = function(db, query) {
    return X.tabulate(query, db(query));
  };

  //-----------------------------------------------------------------------------------------------------------
  queries = [
    SQL`drop view if exists dbay_foreign_key_clauses_2;`,
    SQL`create view dbay_foreign_key_clauses_2 as select distinct
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
  order by from_table_name, fk_id, fk_idx;`,
    SQL`create table d ( x integer ) strict;`,
    SQL`create table d ( x "any" );`,
    SQL`insert into products ( nr, name ) values ( 1234, 'frob' );`,
    SQL`select a, b from s join t using ( c );`,
    SQL`select t1.a as alias, t2.b from s as t1 join t as t2 using ( c );`,
    SQL`create view v as select a, b, c, f( d ) as k from t where e > 2;`,
    SQL`create view v as select a, b, c, f( d ) as k from t join t2 using ( uuu ) where e > 2 order by k;`,
    SQL`select a, b, c, f( d ) as k from t join t2 using ( uuu ) where e > 2 order by k;`,
    SQL`select
42 as d;
select 'helo world' as greetings;`,
    SQL`select xxxxx /* comment */ from t where "x" = $x;`
  ];

  //-----------------------------------------------------------------------------------------------------------
  this.demo_rhombic_antlr = function() {
    var CATALOG, i, len, query, ref;
    CATALOG = require('../../../jzr-old/multimix/lib/cataloguing');
    ref = [queries[queries.length - 1]];
    // q = antlr.parse "SELECT * FROM abc join users as u;", parser_cfg
    // for query in [ SQL"""select d as "d1" from a as a1;""", ]
    // for query in [ SQL"""select d + e + f( x ) as "d1" from a as a1;""", ]
    // for query in [ SQL"""select * from a left join b where k > 1 order by m limit 1;""", ]
    // for query in [ SQL"SELECT 42 as a;", ]
    // for query in [ queries[ 1 ], ]
    for (i = 0, len = ref.length; i < len; i++) {
      query = ref[i];
      echo(query);
      X.banner(query);
      build_tree(query);
    }
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  type_of_antler_node = function(node) {
    var R;
    R = node.constructor.name;
    R = R.replace(/(Node|Context)$/, '');
    R = to_snake_case(R);
    return R;
  };

  //-----------------------------------------------------------------------------------------------------------
  build_tree = function(query) {
    var R, antlr, objects_by_type, parser_cfg, series;
    parser_cfg = {
      doubleQuotedIdentifier: true
    };
    antlr = {
      children: [(ANTLR.parse(query, parser_cfg)).tree]
    };
    R = {
      type: 'query',
      nodes: []
    };
    series = [];
    objects_by_type = _build_tree(query, antlr, 0, 0, series, R);
    // types           = ( k for k of objects_by_type ).sort()
    debug('^4345^', R);
    show_series(query, series);
    return R;
  };

  //-----------------------------------------------------------------------------------------------------------
  show_series = function(query, series) {
    var i, len, node, ref, ref1, ref10, ref11, ref2, ref3, ref4, ref5, ref6, ref7, ref8, ref9, s;
    s = [];
    for (i = 0, len = series.length; i < len; i++) {
      node = series[i];
      s.push({
        id: node.id,
        upid: node.upid,
        type: node.type,
        start_idx: (ref = (ref1 = node.start) != null ? ref1.idx : void 0) != null ? ref : null,
        start_lnr: (ref2 = (ref3 = node.start) != null ? ref3.lnr : void 0) != null ? ref2 : null,
        start_col: (ref4 = (ref5 = node.start) != null ? ref5.col : void 0) != null ? ref4 : null,
        stop_idx: (ref6 = (ref7 = node.stop) != null ? ref7.idx : void 0) != null ? ref6 : null,
        stop_lnr: (ref8 = (ref9 = node.stop) != null ? ref9.lnr : void 0) != null ? ref8 : null,
        stop_col: (ref10 = (ref11 = node.stop) != null ? ref11.col : void 0) != null ? ref10 : null,
        node_count: node.node_count,
        text: node.text
      });
    }
    X.tabulate(query, s);
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  _build_tree = function(query, antlr, upid, level, series, tree) {
    var branch, dent, flat_node, i, id, len, node, position, position_txt, ref, text, type, type_entry, type_entry_type;
    dent = '  '.repeat(level);
    id = upid;
    ref = antlr.children;
    for (i = 0, len = ref.length; i < len; i++) {
      branch = ref[i];
      id++;
      type = type_of_antler_node(branch);
      type_entry = antler_types[type];
      position = position_from_node(branch);
      if (position != null) {
        position_txt = `(${position.start.lnr}:${position.start.col}–${position.stop.lnr}:${position.stop.col})`;
        text = query.slice(position.start.idx, +position.stop.idx + 1 || 9e9);
      } else {
        position_txt = '';
        text = '';
      }
      flat_node = {id, upid, type, ...position};
      flat_node.text = text === '' ? null : text;
      node = {
        ...flat_node,
        nodes: []
      };
      series.push(flat_node);
      tree.nodes.push(node);
      switch (type_entry_type = type_of(type_entry)) {
        case 'undefined':
          warn('^4656-1^' + dent + ` ${id} (${upid}) ${type} ${position_txt} ${CND.gold(rpr(shorten(text)))} `);
          break;
        case 'null':
          whisper('^4656-1^' + dent + ` ${id} (${upid}) ${type} ${position_txt} ${CND.gold(rpr(shorten(text)))} `);
          break;
        case 'function':
          whisper('^5600-14^', '------------------------------------------------------------');
          info('^4656-1^' + dent + ` ${id} (${upid}) ${type} ${position_txt} ${CND.gold(rpr(shorten(text)))} `);
          debug('^4656-1^', type_entry(branch));
          break;
        default:
          warn(CND.reverse('^4656-1^' + dent + ` ${id} (${upid}) ${type} ${position_txt} ${CND.gold(rpr(shorten(text)))} ` + ` unknown type entry type ${rpr(type_entry_type)}`));
      }
      if (branch.children != null) {
        _build_tree(query, branch, id, level + 1, series, node);
      }
      flat_node.node_count = node.nodes.length;
      if (node.nodes.length === 0) {
        delete node.nodes;
      }
    }
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  shorten = function(text) {
    if (!(text.length > 20)) {
      return text;
    }
    return text.slice(0, 10) + '...' + text.slice(text.length - 9);
  };

  //-----------------------------------------------------------------------------------------------------------
  position_from_node = function(node) {
    var start, stop;
    if (node._symbol != null) {
      start = {
        idx: node._symbol.start,
        lnr: node._symbol._line,
        col: node._symbol._charPositionInLine + 1
      };
      stop = {
        idx: node._symbol.stop,
        lnr: node._symbol._line,
        col: node._symbol._charPositionInLine + 1 + node._symbol.stop - node._symbol.start
      };
      return {start, stop};
    }
    return null;
  };

  // else if node._start?
  //   start     =
  //     idx:  node._start.start
  //     lnr:  node._start._line
  //     col:  node._start._charPositionInLine + 1
  //   stop      =
  //     idx:  node._stop.stop
  //     lnr:  node._stop._line
  //     col:  node._stop._charPositionInLine + 1

  //-----------------------------------------------------------------------------------------------------------
  antler_types = {
    //.........................................................................................................
    terminal: null,
    //.........................................................................................................
    select_clause: function(node) {
      var terminal, text, type;
      terminal = node.children[0];
      if ((type = type_of_antler_node(terminal)) !== 'terminal') {
        throw new Error(`unexpected type ${rpr(type)}`);
      }
      if (!/^select$/i.test((text = terminal.text))) {
        throw new Error(`unexpected terminal ${rpr(text)}`);
      }
      return debug('^4353^', {
        type,
        text,
        ...(position_from_node(terminal)),
        nodes: []
      });
    },
    //.........................................................................................................
    regular_query_specification: null,
    query_primary_default: null,
    query_term_default: null,
    query: null,
    statement_default: null
  };

  //###########################################################################################################
  if (module === require.main) {
    (() => {
      return this.demo_rhombic_antlr();
    })();
  }

  //   #---------------------------------------------------------------------------------------------------------
//   _walk_statements_from_path: ( sql_path ) ->
//     ### Given a path, iterate over SQL statements which are signalled by semicolons (`;`) that appear outside
//     of literals and comments (and the end of input). ###
//     ### thx to https://stackabuse.com/reading-a-file-line-by-line-in-node-js/ ###
//     ### thx to https://github.com/nacholibre/node-readlines ###
//     readlines       = new ( require 'n-readlines' ) sql_path
//     #.......................................................................................................
//     cfg           =
//       regExp: ( require 'mysql-tokenizer/lib/regexp-sql92' )
//     tokenize      = ( require 'mysql-tokenizer' ) cfg
//     collector     = null
//     # stream        = FS.createReadStream sql_path
//     #.......................................................................................................
//     flush = ->
//       R         = collector.join ''
//       collector = null
//       return R
//     #.......................................................................................................
//     while ( line = readlines.next() ) isnt false
//       for token, cur_idx in tokenize line + '\n'
//         if token is ';'
//           ( collector ?= [] ).push token
//           yield flush()
//           continue
//         # if token.startsWith '--'
//         #   continue
//         ( collector ?= [] ).push token
//     #.......................................................................................................
//     yield flush() if collector?
//     return null

}).call(this);

//# sourceMappingURL=main.js.map