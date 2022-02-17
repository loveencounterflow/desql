


'use strict'


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'DESQL/TYPES'
debug                     = CND.get_logger 'debug',     badge
alert                     = CND.get_logger 'alert',     badge
whisper                   = CND.get_logger 'whisper',   badge
warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
info                      = CND.get_logger 'info',      badge
jr                        = JSON.stringify
Intertype                 = ( require 'intertype' ).Intertype
intertype                 = new Intertype module.exports



#===========================================================================================================
# TRASH
#-----------------------------------------------------------------------------------------------------------
@declare 'dbay_trash_to_sql_cfg', ( x ) ->
  "@isa.object x":                                      ( x ) -> @isa.object x
  "@type_of x.path in [ 'boolean', 'nonempty_text', ]": ( x ) -> \
    @type_of x.path in [ 'boolean', 'nonempty_text', ]
  "@isa.boolean x.overwrite":                           ( x ) -> @isa.boolean x.overwrite
  "@isa.boolean x.walk":                                ( x ) -> @isa.boolean x.walk
  "@isa.boolean x._use_dot_cmds":                       ( x ) -> @isa.boolean x._use_dot_cmds

#-----------------------------------------------------------------------------------------------------------
@declare 'dbay_trash_to_sqlite_cfg', ( x ) ->
  "@isa.object x":                                      ( x ) -> @isa.object x
  "@type_of x.path in [ 'boolean', 'nonempty_text', ]": ( x ) -> \
    @type_of x.path in [ 'boolean', 'nonempty_text', ]
  "@isa.boolean x.overwrite":                           ( x ) -> @isa.boolean x.overwrite



