(function() {
  'use strict';
  var ANTLR, CND, DBay, GUY, SQL, badge, debug, echo, equals, help, info, isa, rpr, to_snake_case, type_of, types, urge, validate, validate_list_of, warn, whisper;

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

  ({DBay} = require('dbay'));

  ({SQL} = DBay);

  to_snake_case = require('just-snake-case');

  ({
    antlr: ANTLR
  } = require('rhombic'));

  //===========================================================================================================

  //-----------------------------------------------------------------------------------------------------------
  this.Desql = class Desql {
    //---------------------------------------------------------------------------------------------------------
    constructor(...P) {
      if (P.length > 0) {
        throw new Error("^345^ configuration settings not supported");
      }
      this.db = new DBay();
      this._procure_infrastructure();
      this._compile_sql();
      return void 0;
    }

    //---------------------------------------------------------------------------------------------------------
    _procure_infrastructure() {
      /* TAINT check if tables exist */
      this.db.create_stdlib();
      //.......................................................................................................
      this.db(SQL`create table queries (
    qid     integer not null primary key,
    length  integer generated always as ( length( query ) ),
    query   text    not null );`);
      //.......................................................................................................
      this.db(SQL`create table raw_nodes (
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
  );`);
      //.......................................................................................................
      this.db(SQL`create view _coverage_1 as select
    n.qid                                                 as qid,
    n.id                                                  as id,
    n.xtra                                                as xtra,
    n.pos1                                                as pos1,
    n.pos2                                                as pos2,
    substring( q.query, n.pos1, n.pos2 - n.pos1 + 1 )     as txt
  from raw_nodes as n
  join queries as q using ( qid )
  where pos1 is not null;`);
      //.......................................................................................................
      this.db(SQL`create view _coverage_holes_1 as select
    *,
    c.pos2 + 1                                                      as nxt_pos1,
    lead( c.pos1 ) over w - 1                                       as nxt_pos2
  from _coverage_1 as c
  window w as ( partition by c.qid order by pos1 );`);
      //.......................................................................................................
      this.db(SQL`create view coverage_holes as select
    c.qid                                                           as qid,
    c.id                                                            as id,
    c.xtra                                                          as xtra,
    c.nxt_pos1                                                      as pos1,
    c.nxt_pos2                                                      as pos2,
    substring( q.query, c.nxt_pos1, c.nxt_pos2 - c.nxt_pos1 + 1 )   as txt
  from _coverage_holes_1 as c
  join queries as q using ( qid )
  where c.nxt_pos1 <= c.nxt_pos2
;`);
      //.......................................................................................................
      this.db(SQL`create view coverage as select
    *
  from _coverage_1
  order by pos1;`);
      //.......................................................................................................
      return null;
    }

    //---------------------------------------------------------------------------------------------------------
    _compile_sql() {
      GUY.props.hide(this, 'statements', {
        //.....................................................................................................
        insert_query: this.db.prepare_insert({
          into: 'queries',
          exclude: ['qid'],
          returning: '*'
        }),
        //.....................................................................................................
        insert_regular_node: this.db.prepare(SQL`insert into raw_nodes ( qid, id, upid, type, pos1, pos2, lnr1, col1, lnr2, col2 )
  values (
    $qid,
    ( select coalesce( max( id ), 0 ) + 1 as id from raw_nodes ),
    $upid, $type, $pos1, $pos2, $lnr1, $col1, $lnr2, $col2 )
  returning *;`)
      });
      //.....................................................................................................
      return null;
    }

    //---------------------------------------------------------------------------------------------------------
    parse(query) {
      var R, antlr, parser_cfg, qid;
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
      ({qid} = this.statements.insert_query.get({query}));
      this._build_tree(qid, query, antlr, null, 0, R);
      return R;
    }

    //---------------------------------------------------------------------------------------------------------
    _build_tree(qid, query, antlr, parent, level, tree) {
      var branch, flat_node, i, len, node, position, ref, ref1, txt, type, upid;
      ref = antlr.children;
      for (i = 0, len = ref.length; i < len; i++) {
        branch = ref[i];
        type = this._type_of_antler_node(branch);
        position = this._position_from_branch(branch);
        txt = null;
        // txt             = query[ position.pos1 .. position.pos2 ] if position.pos1?
        // txt             = ( Array.from query )[ position.pos1 .. position.pos2 ].join '' if position.pos1?
        upid = (ref1 = parent != null ? parent.id : void 0) != null ? ref1 : null;
        flat_node = {qid, upid, type, ...position};
        // flat_node.txt   = if txt is '' then null else txt
        this.db(SQL`savepoint svp_name;`);
        flat_node = this.statements.insert_regular_node.get(flat_node);
        // dent  = '  '.repeat level; debug '^9876^', dent + rpr flat_node
        node = {
          ...flat_node,
          nodes: []
        };
        if (branch.children != null) {
          this._build_tree(qid, query, branch, flat_node, level + 1, node);
        }
        if ((node.type !== 'terminal') && (node.nodes.length === 0)) {
          this.db(SQL`rollback transaction to savepoint svp_name;`);
        } else {
          this.db(SQL`release svp_name;`);
          tree.nodes.push(node);
        }
        if (node.nodes.length === 0) {
          delete node.nodes;
        }
      }
      return null;
    }

    //---------------------------------------------------------------------------------------------------------
    _type_of_antler_node(node) {
      var R;
      R = node.constructor.name;
      R = R.replace(/(Node|Context)$/, '');
      R = to_snake_case(R);
      return R;
    }

    //---------------------------------------------------------------------------------------------------------
    _position_from_branch(branch) {
      var col1, col2, lnr1, lnr2, pos1, pos2;
      if (branch._symbol != null) {
        pos1 = branch._symbol.start + 1;
        lnr1 = branch._symbol._line;
        col1 = branch._symbol._charPositionInLine + 1;
        pos2 = branch._symbol.stop + 1;
        lnr2 = branch._symbol._line;
        col2 = branch._symbol._charPositionInLine + 1 + branch._symbol.stop - branch._symbol.start;
      } else {
        pos1 = null;
        lnr1 = null;
        col1 = null;
        pos2 = null;
        lnr2 = null;
        col2 = null;
      }
      return {pos1, lnr1, col1, pos2, lnr2, col2};
    }

  };

}).call(this);

//# sourceMappingURL=main.js.map