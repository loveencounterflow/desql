
'use strict'


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'DESQL/MIXIN/TRASH'
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
info                      = CND.get_logger 'info',      badge
urge                      = CND.get_logger 'urge',      badge
help                      = CND.get_logger 'help',      badge
whisper                   = CND.get_logger 'whisper',   badge
echo                      = CND.echo.bind CND
{ freeze
  lets }                  = require 'letsfreezethat'
E                         = require './errors'
H                         = require './helpers'
{ SQL }                   = H
guy                       = require 'guy'
FS                        = require 'fs'
PATH                      = require 'path'


#-----------------------------------------------------------------------------------------------------------
@DBay_trash = ( clasz = Object ) => class extends clasz

  #---------------------------------------------------------------------------------------------------------
  _$trash_initialize: ->
    @_trash_created = false
    return null

  #---------------------------------------------------------------------------------------------------------
  trash_to_sql: ( cfg ) ->
    @types.validate.dbay_trash_to_sql_cfg ( cfg = { @constructor.C.defaults.dbay_trash_to_sql_cfg..., cfg..., } )
    @create_trashlib()
    @setv '_use_dot_cmds', cfg._use_dot_cmds
    { path
      overwrite } = cfg
    iterator      = @query @_trash_select_from_statements
    if ( not cfg.path? ) or ( cfg.path is false )
      return iterator if cfg.walk
      return ( row.txt for row from iterator ).join '\n'
    return @_trash_with_fs_open_do path, 'sql', overwrite, ( { path, fd, } ) =>
      FS.writeSync fd, row.txt + '\n' for row from iterator
      return path

  #---------------------------------------------------------------------------------------------------------
  trash_to_sqlite: ( cfg ) ->
    @types.validate.dbay_trash_to_sqlite_cfg ( cfg = { @constructor.C.defaults.dbay_trash_to_sqlite_cfg..., cfg..., } )
    ### TAINT consider to iterate over statements ###
    { path
      overwrite } = cfg
    sql           = @trash_to_sql { walk: false, path: false, _use_dot_cmds: false, }
    sqlt          = @constructor.new_bsqlt3_connection()
    sqlt.exec sql
    buffer        = sqlt.serialize()
    if ( not cfg.path? ) or ( cfg.path is false )
      return buffer
    return @_trash_with_fs_open_do path, 'sqlite', overwrite, ( { path, fd, } ) =>
      FS.writeSync fd, buffer
      return path

  #---------------------------------------------------------------------------------------------------------
  _trash_with_fs_open_do: ( path, extension, overwrite, fn ) ->
    ### TAINT implement `overwrite` ###
    path  = @_trash_get_path path, extension
    fd    = FS.openSync path, if overwrite then 'a' else 'ax'
    try ( R = fn { path, fd, } ) finally FS.closeSync fd
    return R

  #---------------------------------------------------------------------------------------------------------
  _trash_get_path: ( path, extension ) ->
    return path if ( type = @types.type_of path ) is 'text'
    unless path is true
      throw new E.DBay_internal_error '^dbay/trash@1^', "expected a text or `true`, got a #{type}"
    clasz = @constructor
    return PATH.join clasz.C.autolocation, @rnd.get_random_filename extension

  #---------------------------------------------------------------------------------------------------------
  create_trashlib: ->
    return null if @_trash_created
    add_views @
    @_trash_created = true
    return null

#-----------------------------------------------------------------------------------------------------------
add_views = ( db ) ->
  db.create_stdlib()
  db.setv '_use_dot_cmds', true
  #---------------------------------------------------------------------------------------------------------
  db SQL"""
    -- ### NOTE this is a best-effort approach to recover the correct ordering for DDL statements
    -- from the data provided by SQLite. It is not quite clear whether the ordering in
    -- `sqlite_schema` can be relied upon and whether it is safe to assume that adding `row_number()`
    -- to the query will not accidentally change the ordering in absence of an `order by` clause.
    -- To attain a modicum of reliability the filtering has been separated from the raw numbering
    -- to keep that aspect from juggling around rows.
    -- ### TAINT replace existing `select from pragma_table_list` by `select from dbay_tables`
    -- ### TAINT consider to always list `table_nr` along with `table_name` or to omit it where not needed (?)
    drop view if exists dbay_tables;
    create view dbay_tables as with v1 as ( select
        row_number() over ()                                                      as table_nr,
        type                                                                      as type,
        name                                                                      as table_name
      from sqlite_schema )
    select
        row_number() over ()                                                      as table_nr,
        type                                                                      as type,
        table_name                                                                as table_name
      from v1
      where true
        and ( type in ( 'table', 'view' ) )
        and ( table_name not like 'sqlite_%' )
        and ( table_name not like 'dbay_%' )
        and ( table_name not like '_dbay_%' )
      order by table_nr;"""
  #---------------------------------------------------------------------------------------------------------
  db SQL"""
    drop view if exists dbay_unique_fields;
    create view dbay_unique_fields as select
        tb.table_name                                                             as table_name,
        ii.name                                                                   as field_name,
        il.seq                                                                    as index_idx,
        il.name                                                                   as index_name
      from dbay_tables as tb
      join pragma_index_list( tb.table_name ) as il on ( true )
      join pragma_index_info( il.name ) as ii on ( true )
      where true
        and ( il.origin = 'u' )
        and ( il."unique" )
      ;"""
  #---------------------------------------------------------------------------------------------------------
  db SQL"""
    drop view if exists _dbay_fields_1;
    create view _dbay_fields_1 as select
        tb.table_nr                                                               as table_nr,
        ti.cid + 1                                                                as field_nr,
        tb.table_name                                                             as table_name,
        tb.type                                                                   as table_type,
        ti.name                                                                   as field_name,
        case ti.type when '' then 'any' else lower( ti.type ) end                 as field_type,
        not ti."notnull"                                                          as nullable,
        ti.dflt_value                                                             as fallback,
        case ti.pk when 0 then null else ti.pk end                                as pk_nr,
        ti.hidden                                                                 as hidden
      from dbay_tables as tb
      join pragma_table_xinfo( tb.table_name ) as ti on ( true )
      order by table_nr, field_nr;"""
  #---------------------------------------------------------------------------------------------------------
  db SQL"""
    drop view if exists _dbay_fields_2;
    create view _dbay_fields_2 as select
        fd.*,
        case when uf.field_name is null then 0 else 1 end                         as is_unique
      from _dbay_fields_1 as fd
      left join dbay_unique_fields as uf using ( table_name, field_name )
      order by table_nr, field_nr;"""
  #---------------------------------------------------------------------------------------------------------
  db SQL"""
    drop view if exists dbay_fields;
    create view dbay_fields as select
        table_nr                                                                  as table_nr,
        field_nr                                                                  as field_nr,
        count() over w - field_nr + 1                                             as field_rnr,
        table_name                                                                as table_name,
        table_type                                                                as table_type,
        field_name                                                                as field_name,
        field_type                                                                as field_type,
        nullable                                                                  as nullable,
        fallback                                                                  as fallback,
        pk_nr                                                                     as pk_nr,
        hidden                                                                    as hidden,
        is_unique                                                                 as is_unique
      from _dbay_fields_2
      window w as ( partition by table_name )
      order by table_nr, field_nr;"""
  #---------------------------------------------------------------------------------------------------------
  db SQL"""
    drop view if exists _dbay_foreign_key_clauses_1;
    create view _dbay_foreign_key_clauses_1 as select
        fk.id                                                                     as fk_id,
        fk.seq                                                                    as fk_idx,
        tb.table_nr                                                               as from_table_nr,
        tb.table_name                                                             as from_table_name,
        fk."from"                                                                 as from_field_name,
        fk."table"                                                                as to_table_name,
        coalesce( fk."to", fk."from" )                                            as to_field_name
      from dbay_tables as tb
      join pragma_foreign_key_list( tb.table_name ) as fk
      order by from_table_name, fk_id, fk_idx;"""
  #---------------------------------------------------------------------------------------------------------
  db SQL"""
    drop view if exists _dbay_foreign_key_clauses_2;
    create view _dbay_foreign_key_clauses_2 as select distinct
        fk_id                                                                     as fk_id,
        from_table_nr                                                             as from_table_nr,
        from_table_name                                                           as from_table_name,
        group_concat( std_sql_i( from_field_name ), ', ' ) over w                 as from_field_names,
        to_table_name                                                             as to_table_name,
        group_concat( std_sql_i(   to_field_name ), ', ' ) over w                 as to_field_names
      from _dbay_foreign_key_clauses_1
      window w as (
        partition by from_table_name, fk_id
        order by fk_idx
        rows between unbounded preceding and unbounded following )
      order by from_table_name, fk_id, fk_idx;"""
  #---------------------------------------------------------------------------------------------------------
  db SQL"""
    drop view if exists _dbay_foreign_key_clauses_3;
    create view _dbay_foreign_key_clauses_3 as select
        *,
        count(*) over w                                                           as line_count
      from _dbay_foreign_key_clauses_2
      window w as (
        partition by from_table_name );"""
  #---------------------------------------------------------------------------------------------------------
  db SQL"""
    drop view if exists dbay_foreign_key_clauses;
    create view dbay_foreign_key_clauses as select
        from_table_nr                                                             as table_nr,
        from_table_name                                                           as table_name,
        row_number() over w                                                       as fk_nr,
        '  foreign key ( ' || from_field_names || ' ) references '
          || std_sql_i( to_table_name )
          || ' ( ' || to_field_names || ' )'
          || case when row_number() over w = line_count then '' else ',' end      as fk_clause
      from _dbay_foreign_key_clauses_3
      window w as (
        partition by from_table_name
        order by fk_id desc
        rows between unbounded preceding and unbounded following )
      order by from_table_name, fk_nr;"""
  #---------------------------------------------------------------------------------------------------------
  db SQL"""
    drop view if exists _dbay_primary_key_clauses_1;
    create view _dbay_primary_key_clauses_1 as select distinct
        table_nr                                                                  as table_nr,
        table_name                                                                as table_name,
        group_concat( std_sql_i( field_name ), ', ' ) over w                      as field_names
      from dbay_fields
      where pk_nr is not null
      window w as (
        partition by table_name
        order by pk_nr
        rows between unbounded preceding and unbounded following )
      order by table_name;"""
  #---------------------------------------------------------------------------------------------------------
  db SQL"""
    drop view if exists dbay_primary_key_clauses;
    create view dbay_primary_key_clauses as select distinct
        p1.table_nr                                                               as table_nr,
        p1.table_name                                                             as table_name,
        '  primary key ( ' || p1.field_names || ' )'
          || case when fc.fk_clause is null then '' else ',' end                  as pk_clause
      from _dbay_primary_key_clauses_1     as p1
      left join dbay_foreign_key_clauses  as fc on ( p1.table_name = fc.table_name and fc.fk_nr = 1 )
      order by p1.table_nr;"""
  #---------------------------------------------------------------------------------------------------------
  db SQL"""
    drop view if exists _dbay_field_clauses_1;
    create view _dbay_field_clauses_1 as select
        table_nr                                                                  as table_nr,
        field_nr                                                                  as field_nr,
        field_rnr                                                                 as field_rnr,
        table_name                                                                as table_name,
        field_name                                                                as field_name,
        '    ' || std_sql_i( field_name ) || ' ' || field_type                    as fc_name_type,
        case when not nullable         then ' not null'             else '' end   as fc_null,
        case when is_unique            then ' unique'               else '' end   as fc_unique,
        case when fallback is not null then ' default ' || fallback else '' end   as fc_default
      from dbay_fields
      order by table_nr, field_nr;"""
  #---------------------------------------------------------------------------------------------------------
  db SQL"""
    drop view if exists dbay_field_clauses;
    create view dbay_field_clauses as select
        f1.table_nr                                                               as table_nr,
        f1.field_nr                                                               as field_nr,
        f1.table_name                                                             as table_name,
        f1.field_name                                                             as field_name,
        f1.fc_name_type || f1.fc_null || f1.fc_unique || f1.fc_default
          || case when f1.field_rnr > 1 then ','
             else case when fc.fk_clause is null and pc.pk_clause is null then ''
             else ',' end end                                                     as field_clause
      from _dbay_field_clauses_1           as f1
      left join dbay_foreign_key_clauses  as fc on ( f1.table_name = fc.table_name and fc.fk_nr = 1 )
      left join dbay_primary_key_clauses  as pc on ( f1.table_name = pc.table_name )
      order by f1.table_nr, f1.field_nr;"""
  #---------------------------------------------------------------------------------------------------------
  db SQL"""
    drop view if exists dbay_create_table_clauses;
    create view dbay_create_table_clauses as select
        table_nr                                                                  as table_nr,
        table_name                                                                as table_name,
        'create table ' || std_sql_i( table_name ) || ' ('                        as create_start,
        ' );'                                                                     as create_end
      from dbay_tables;"""
  #---------------------------------------------------------------------------------------------------------
  db SQL"""
    drop view if exists dbay_drop_table_clauses;
    create view dbay_drop_table_clauses as select
        table_nr                                                                  as table_nr,
        table_name                                                                as table_name,
        'drop table if exists ' || std_sql_i( table_name ) || ';'                 as txt
      from dbay_tables;"""
  #---------------------------------------------------------------------------------------------------------
  db SQL"""
    drop view if exists _dbay_create_table_statements_1;
    create view _dbay_create_table_statements_1 as
      with x as ( select * from dbay_create_table_clauses )
      -- ...................................................................................................
      select
        null                                                                      as section_nr,
        null                                                                      as table_nr,
        null                                                                      as part_nr,
        null                                                                      as lnr,
        null                                                                      as table_name,
        null                                                                      as txt
      where false
      -- ...................................................................................................
      union all select distinct 10, null, 10, 1, null, '-- autogenerated'                     from x
      union all select distinct 10, null, 10, 2, null, '\b simplified\n-- schema'             from x
      union all select distinct 10, null, 10, 3, null,
        case when std_getv( '_use_dot_cmds' ) then '.bail on' else '' end                     from x
      union all select distinct 10, null, 10, 4, null, 'pragma foreign_keys = false;'         from x
      union all select distinct 10, null, 10, 5, null, 'begin transaction;'                   from x
      union all select distinct 90, null, 10, 1, null, 'commit;'                              from x
      union all select distinct 90, null, 10, 2, null, 'pragma foreign_keys = true;'          from x
      -- ...................................................................................................
      union all select
        15                                                                        as section_nr,
        table_nr                                                                  as table_nr,
        null                                                                      as part_nr,
        1                                                                         as lnr,
        table_name                                                                as table_name,
        txt                                                                       as txt
      from dbay_drop_table_clauses
      -- ...................................................................................................
      union all select
        20                                                                        as section_nr,
        table_nr                                                                  as table_nr,
        20                                                                        as part_nr,
        1                                                                         as lnr,
        table_name                                                                as table_name,
        create_start                                                              as txt
      from dbay_create_table_clauses as ct
      -- ...................................................................................................
      union all select
        20                                                                        as section_nr,
        table_nr                                                                  as table_nr,
        30                                                                        as part_nr,
        field_nr                                                                  as lnr,
        table_name                                                                as table_name,
        field_clause                                                              as txt
      from dbay_field_clauses
      -- ...................................................................................................
      union all select
        20                                                                        as section_nr,
        table_nr                                                                  as table_nr,
        40                                                                        as part_nr,
        1                                                                         as lnr,
        table_name                                                                as table_name,
        pk_clause                                                                 as txt
      from dbay_primary_key_clauses
      -- ...................................................................................................
      union all select
        20                                                                        as section_nr,
        table_nr                                                                  as table_nr,
        50                                                                        as part_nr,
        1                                                                         as lnr,
        table_name                                                                as table_name,
        fk_clause                                                                 as txt
      from dbay_foreign_key_clauses
      -- ...................................................................................................
      union all select
        20                                                                        as section_nr,
        table_nr                                                                  as table_nr,
        90                                                                        as part_nr,
        1                                                                         as lnr,
        table_name                                                                as table_name,
        create_end                                                                as txt
      from dbay_create_table_clauses as ct
      -- ...................................................................................................
      order by section_nr, table_nr, part_nr, lnr;"""
  #---------------------------------------------------------------------------------------------------------
  db SQL"""
    drop view if exists _dbay_create_table_statements_2;
    create view _dbay_create_table_statements_2 as select
        row_number() over ()                                                      as lnr,
        1                                                                         as tail,
        txt                                                                       as txt
      from _dbay_create_table_statements_1 as r1
      order by section_nr, table_nr, part_nr, r1.lnr;"""
  #---------------------------------------------------------------------------------------------------------
  db SQL"""
    drop view if exists _dbay_create_table_statements_3;
    create view _dbay_create_table_statements_3 as select
        r1.lnr                                                                    as lnr,
        r2.lnr                                                                    as tail,
        r2.part                                                                   as txt
      from _dbay_create_table_statements_2 as r1,
      std_str_split( r1.txt, '\n' )       as r2
      order by lnr, tail;"""
  #---------------------------------------------------------------------------------------------------------
  db SQL"""
    drop view if exists _dbay_create_table_statements_4;
    create view _dbay_create_table_statements_4 as select
        r1.lnr                                                                    as lnr,
        r1.tail                                                                   as tail,
        lead( r1.txt ) over ()                                                    as nxt_txt,
        r1.txt                                                                    as txt
      from _dbay_create_table_statements_3 as r1
      order by lnr, tail;"""
  #---------------------------------------------------------------------------------------------------------
  do =>
    skip = false
    db.create_table_function
      name:         'dbay_trash_merge_lines'
      parameters:   [ 'line', 'nxt_line', ]
      columns:      [ 'vnr2', 'txt', ]
      rows: ( line, nxt_line ) ->
        # debug [ line, nxt_line, ]
        if skip
          skip = false
        else if nxt_line.startsWith '\b'
          skip = true
          yield [ 1, line + nxt_line[ 1 .. ], ]
        else
          yield [ 1, line, ]
        return null
  #---------------------------------------------------------------------------------------------------------
  db SQL"""
    drop view if exists dbay_create_table_statements;
    create view dbay_create_table_statements as select
        row_number() over ( order by r1.lnr, r1.tail, r2.vnr2 )                   as lnr,
        r2.txt                                                                    as txt
      from _dbay_create_table_statements_4     as r1,
      dbay_trash_merge_lines( r1.txt, nxt_txt )  as r2
      order by r1.lnr, r1.tail, r2.vnr2;"""
  #-------------------------------------------------------------------------------------------------------
  guy.props.hide db, '_trash_select_from_statements', SQL"select * from dbay_create_table_statements;"
  return db

