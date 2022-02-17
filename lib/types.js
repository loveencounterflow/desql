(function() {
  'use strict';
  var CND, Intertype, alert, badge, debug, help, info, intertype, jr, rpr, urge, warn, whisper;

  //###########################################################################################################
  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'DESQL/TYPES';

  debug = CND.get_logger('debug', badge);

  alert = CND.get_logger('alert', badge);

  whisper = CND.get_logger('whisper', badge);

  warn = CND.get_logger('warn', badge);

  help = CND.get_logger('help', badge);

  urge = CND.get_logger('urge', badge);

  info = CND.get_logger('info', badge);

  jr = JSON.stringify;

  Intertype = (require('intertype')).Intertype;

  intertype = new Intertype(module.exports);

  //===========================================================================================================
  // TRASH
  //-----------------------------------------------------------------------------------------------------------
  this.declare('dbay_trash_to_sql_cfg', function(x) {
    return {
      "@isa.object x": function(x) {
        return this.isa.object(x);
      },
      "@type_of x.path in [ 'boolean', 'nonempty_text', ]": function(x) {
        var ref;
        return this.type_of((ref = x.path) === 'boolean' || ref === 'nonempty_text');
      },
      "@isa.boolean x.overwrite": function(x) {
        return this.isa.boolean(x.overwrite);
      },
      "@isa.boolean x.walk": function(x) {
        return this.isa.boolean(x.walk);
      },
      "@isa.boolean x._use_dot_cmds": function(x) {
        return this.isa.boolean(x._use_dot_cmds);
      }
    };
  });

  //-----------------------------------------------------------------------------------------------------------
  this.declare('dbay_trash_to_sqlite_cfg', function(x) {
    return {
      "@isa.object x": function(x) {
        return this.isa.object(x);
      },
      "@type_of x.path in [ 'boolean', 'nonempty_text', ]": function(x) {
        var ref;
        return this.type_of((ref = x.path) === 'boolean' || ref === 'nonempty_text');
      },
      "@isa.boolean x.overwrite": function(x) {
        return this.isa.boolean(x.overwrite);
      }
    };
  });

}).call(this);

//# sourceMappingURL=types.js.map