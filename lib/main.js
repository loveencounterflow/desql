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
      this.db(SQL`create table raw_nodes (
    id      integer not null,
    xtra    integer not null default 1,
    upid    integer,
    type    text    not null,
    idx1    integer,
    idx2    integer,
    lnr1    integer,
    col1    integer,
    lnr2    integer,
    col2    integer,
    txt     text,
  primary key ( id, xtra ) -- ,
  -- foreign key ( upid ) references raw_nodes ( id ) DEFERRABLE INITIALLY DEFERRED
  );`);
      return null;
    }

    //---------------------------------------------------------------------------------------------------------
    _compile_sql() {
      GUY.props.hide(this, 'statements', {
        insert_regular_node: this.db.prepare(SQL`insert into raw_nodes ( id, upid, type, idx1, idx2, lnr1, col1, lnr2, col2, txt )
  values (
    ( select coalesce( max( id ), 0 ) + 1 as id from raw_nodes ),
    $upid, $type, $idx1, $idx2, $lnr1, $col1, $lnr2, $col2, $txt )
  returning *;`)
      });
      return null;
    }

    //---------------------------------------------------------------------------------------------------------
    parse(query) {
      var R, antlr, parser_cfg;
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
      this._build_tree(query, antlr, null, 0, R);
      return R;
    }

    //---------------------------------------------------------------------------------------------------------
    _build_tree(query, antlr, parent, level, tree) {
      var branch, dent, flat_node, i, len, node, position, ref, ref1, txt, type, upid;
      dent = '  '.repeat(level);
      ref = antlr.children;
      for (i = 0, len = ref.length; i < len; i++) {
        branch = ref[i];
        type = this._type_of_antler_node(branch);
        position = this._position_from_branch(branch);
        txt = null;
        if (position.idx1 != null) {
          txt = query.slice(position.idx1, +position.idx2 + 1 || 9e9);
        }
        upid = (ref1 = parent != null ? parent.id : void 0) != null ? ref1 : null;
        flat_node = {upid, type, ...position};
        flat_node.txt = txt === '' ? null : txt;
        this.db(SQL`savepoint svp_name;`);
        flat_node = this.statements.insert_regular_node.get(flat_node);
        node = {
          ...flat_node,
          nodes: []
        };
        if (branch.children != null) {
          this._build_tree(query, branch, flat_node, level + 1, node);
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
      var col1, col2, idx1, idx2, lnr1, lnr2;
      if (branch._symbol != null) {
        idx1 = branch._symbol.start;
        lnr1 = branch._symbol._line;
        col1 = branch._symbol._charPositionInLine + 1;
        idx2 = branch._symbol.stop;
        lnr2 = branch._symbol._line;
        col2 = branch._symbol._charPositionInLine + 1 + branch._symbol.stop - branch._symbol.start;
      } else {
        idx1 = null;
        lnr1 = null;
        col1 = null;
        idx2 = null;
        lnr2 = null;
        col2 = null;
      }
      return {idx1, lnr1, col1, idx2, lnr2, col2};
    }

  };

}).call(this);

//# sourceMappingURL=main.js.map