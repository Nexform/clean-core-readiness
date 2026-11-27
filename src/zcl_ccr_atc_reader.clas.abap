"! <p class="shorttext synchronized" lang="EN">Reads ATC results through the classic ATC API</p>
"! Adapter of ZIF_CCR_ATC_READER. Runs come from the result header table SATC_AC_RESULTH,
"! findings from CL_SATC_API_FACTORY, their attributes and check titles from
"! CL_SATC_API_MAPPINGS, objects from TADIR, class categories from SEOCLASSDF - as confirmed
"! by Z_CCR_PROBE on S/4HANA 2025. Keeps the findings of the run it read last, so the details
"! of one object are read only when asked for.
CLASS zcl_ccr_atc_reader DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_ccr_atc_reader.

  PRIVATE SECTION.
    TYPES package_names TYPE SORTED TABLE OF devclass WITH UNIQUE KEY table_line.
    TYPES: BEGIN OF package_link,
             parent TYPE devclass,
             child  TYPE devclass,
           END OF package_link.
    TYPES package_links TYPE SORTED TABLE OF package_link WITH NON-UNIQUE KEY parent.
    TYPES: BEGIN OF check_title,
             check TYPE sci_chk,
             title TYPE string,
           END OF check_title.
    TYPES check_titles TYPE HASHED TABLE OF check_title WITH UNIQUE KEY check.

    "! Names of the finding attributes, as CL_SATC_API_MAPPINGS gives them (probe 1.3)
    CONSTANTS: BEGIN OF attribute,
                 ref_object_type TYPE string VALUE `REF_OBJ_TYPE`,
                 ref_object_name TYPE string VALUE `REF_OBJ_NAME`,
                 successor       TYPE string VALUE `ADD_INFO`,
               END OF attribute.

    "! The findings of the run FINDINGS read last
    DATA last_findings TYPE scit_rest.
    DATA mappings TYPE REF TO cl_satc_api_mappings.
    "! Titles of the checks asked for so far
    DATA titles TYPE check_titles.

    CONSTANTS whole_object TYPE tadir-pgmid VALUE 'R3TR'.
    "! Generation flag of an object that was not generated (domain GENFLAG). X (generated,
    "! preserved in the upgrade) and T (generated, can be deleted in the upgrade) are not
    "! custom code, e.g. the /1BCDWB/* and CLR_* classes in $TMP, so they are not assessed
    CONSTANTS not_generated TYPE tadir-genflag VALUE space.
    CONSTANTS class_type TYPE zif_ccr_level_rules=>object_type VALUE 'CLAS'.
    "! Active version of a class in SEOCLASSDF
    CONSTANTS active_version TYPE seoclassdf-version VALUE '1'.
    "! Category of a behavior pool in SEOCLASSDF: the BPCL classes of probe 1.4 have it
    CONSTANTS behavior_pool_category TYPE seoclassdf-category VALUE '06'.

    "! The title of a check, read once per check.
    METHODS title_of
      IMPORTING check         TYPE sci_chk
      RETURNING VALUE(result) TYPE string.

    "! The packages of the range and, level by level, all packages below them.
    METHODS with_subpackages
      IMPORTING packages      TYPE zif_ccr_atc_reader=>package_range
      RETURNING VALUE(result) TYPE package_names.

    "! The children of the parents that are not known yet.
    "!
    "! @parameter known  | Packages found so far - a package seen before is not followed again
    "! @parameter result | The new children
    METHODS children_of
      IMPORTING parents       TYPE package_names
                links         TYPE package_links
                known         TYPE package_names
      RETURNING VALUE(result) TYPE package_names.

ENDCLASS.


CLASS zcl_ccr_atc_reader IMPLEMENTATION.

  METHOD zif_ccr_atc_reader~runs.
    SELECT FROM satc_ac_resulth
      FIELDS display_id, title, run_series_name, scheduled_on_ts, is_central_run
      WHERE chk_profile_name = @check_variant
        AND is_complete      = @abap_true
      ORDER BY scheduled_on_ts DESCENDING
      INTO TABLE @result.
  ENDMETHOD.


  METHOD zif_ccr_atc_reader~findings.
    DATA access TYPE REF TO if_satc_result_access.
    DATA atc_findings TYPE scit_rest.

    access ?= NEW cl_satc_api_factory( )->create_result_access( result_id ).
    access->get_findings( IMPORTING e_findings = atc_findings ).
    last_findings = atc_findings.

    result = VALUE #( FOR atc_finding IN atc_findings
                      ( object_type = atc_finding-objtype
                        object_name = atc_finding-objname
                        check_name  = atc_finding-test
                        code        = atc_finding-code
                        kind        = atc_finding-kind ) ).
  ENDMETHOD.


  METHOD zif_ccr_atc_reader~finding_details.
    IF mappings IS NOT BOUND.
      mappings = NEW #( ).
    ENDIF.

    LOOP AT last_findings REFERENCE INTO DATA(finding)
         WHERE objtype = object_type AND objname = object_name.
      " the attributes are packed in the finding; unpacking them takes a moment, so only here
      DATA(attributes) = mappings->extract_attributes( finding->* ).
      INSERT VALUE #( check_name      = finding->test
                      check_title     = title_of( finding->test )
                      code            = finding->code
                      kind            = finding->kind
                      sub_object      = finding->sobjname
                      line            = finding->line
                      ref_object_type = VALUE #( attributes[ name = attribute-ref_object_type ]-value OPTIONAL )
                      ref_object_name = VALUE #( attributes[ name = attribute-ref_object_name ]-value OPTIONAL )
                      successor       = VALUE #( attributes[ name = attribute-successor ]-value OPTIONAL ) )
             INTO TABLE result.
    ENDLOOP.
  ENDMETHOD.


  METHOD title_of.
    IF NOT line_exists( titles[ check = check ] ).
      INSERT VALUE #( check = check
                      title = mappings->get_check_title( check ) ) INTO TABLE titles.
    ENDIF.
    result = titles[ check = check ]-title.
  ENDMETHOD.


  METHOD zif_ccr_atc_reader~behavior_pools.
    IF objects IS INITIAL.
      RETURN.
    ENDIF.

    SELECT FROM @objects AS checked INNER JOIN seoclassdf AS class
        ON class~clsname = checked~object_name
      FIELDS checked~object_type, checked~object_name
      WHERE checked~object_type = @class_type
        AND class~version       = @active_version
        AND class~category      = @behavior_pool_category
      ORDER BY checked~object_type, checked~object_name
      INTO TABLE @result.
  ENDMETHOD.


  METHOD zif_ccr_atc_reader~objects.
    " an empty range would select the packages of the whole system
    IF packages IS INITIAL.
      RETURN.
    ENDIF.

    DATA(package_range) = VALUE zif_ccr_atc_reader=>package_range(
                                  FOR package_name IN with_subpackages( packages )
                                  ( sign   = 'I'
                                    option = 'EQ'
                                    low    = package_name ) ).
    IF package_range IS INITIAL.
      RETURN.
    ENDIF.

    SELECT FROM tadir
      FIELDS object, obj_name
      WHERE pgmid     = @whole_object
        AND object   IN @object_types
        AND devclass IN @package_range
        AND delflag   = @abap_false
        AND genflag   = @not_generated
      ORDER BY object, obj_name
      INTO TABLE @result.
  ENDMETHOD.


  METHOD with_subpackages.
    DATA links TYPE package_links.

    SELECT FROM tdevc
      FIELDS devclass
      WHERE devclass IN @packages
      ORDER BY devclass
      INTO TABLE @result.
    IF result IS INITIAL.
      RETURN.
    ENDIF.

    " the package tree is read once and walked in memory, level by level
    SELECT FROM tdevc
      FIELDS parentcl, devclass
      WHERE parentcl <> @space
      ORDER BY parentcl, devclass
      INTO TABLE @links.

    DATA(parents) = result.
    WHILE parents IS NOT INITIAL.
      parents = children_of( parents = parents
                             links   = links
                             known   = result ).
      INSERT LINES OF parents INTO TABLE result.
    ENDWHILE.
  ENDMETHOD.


  METHOD children_of.
    LOOP AT parents INTO DATA(parent).
      LOOP AT links INTO DATA(link) WHERE parent = parent.
        IF NOT line_exists( known[ table_line = link-child ] ).
          INSERT link-child INTO TABLE result.
        ENDIF.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
