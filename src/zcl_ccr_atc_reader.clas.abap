"! <p class="shorttext synchronized" lang="EN">Reads ATC results through the classic ATC API</p>
"! Adapter of ZIF_CCR_ATC_READER. Runs come from the result header table SATC_AC_RESULTH,
"! findings from CL_SATC_API_FACTORY, objects from TADIR, class categories from SEOCLASSDF -
"! as confirmed by Z_CCR_PROBE on S/4HANA 2025.
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

    CONSTANTS whole_object TYPE tadir-pgmid VALUE 'R3TR'.
    "! Generation flag of an object the system generated (e.g. /1BCDWB/* classes in $TMP):
    "! not custom code, so not assessed
    CONSTANTS generated TYPE tadir-genflag VALUE 'X'.
    CONSTANTS class_type TYPE zif_ccr_level_rules=>object_type VALUE 'CLAS'.
    "! Active version of a class in SEOCLASSDF
    CONSTANTS active_version TYPE seoclassdf-version VALUE '1'.
    "! Category of a behavior pool in SEOCLASSDF: the BPCL classes of probe 1.4 have it
    CONSTANTS behavior_pool_category TYPE seoclassdf-category VALUE '06'.

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

    result = VALUE #( FOR atc_finding IN atc_findings
                      ( object_type = atc_finding-objtype
                        object_name = atc_finding-objname
                        check_name  = atc_finding-test
                        code        = atc_finding-code
                        kind        = atc_finding-kind ) ).
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
        AND genflag  <> @generated
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
