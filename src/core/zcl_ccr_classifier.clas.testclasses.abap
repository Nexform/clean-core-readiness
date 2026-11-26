"! Answers with the level that a test wrote into the message code of the finding, so that
"! the tests of the classifier do not depend on the rules of the SAP checks.
CLASS ltd_level_rules DEFINITION FINAL FOR TESTING.

  PUBLIC SECTION.
    INTERFACES zif_ccr_level_rules.

ENDCLASS.


CLASS ltd_level_rules IMPLEMENTATION.

  METHOD zif_ccr_level_rules~level_of.
    result = finding-code.
  ENDMETHOD.

ENDCLASS.


CLASS ltc_classifier DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zif_ccr_classifier.

    METHODS setup.

    METHODS finding_of
      IMPORTING object_type   TYPE zif_ccr_level_rules=>object_type DEFAULT 'CLAS'
                object_name   TYPE zif_ccr_level_rules=>object_name
                level         TYPE zif_ccr_level_rules=>clean_core_level
      RETURNING VALUE(result) TYPE zif_ccr_level_rules=>finding.

    METHODS when_no_findings_then_empty FOR TESTING.
    METHODS when_no_clean_core_then_a FOR TESTING.
    METHODS when_mixed_levels_then_worst FOR TESTING.
    METHODS when_findings_then_counted FOR TESTING.
    METHODS when_same_name_then_by_type FOR TESTING.

ENDCLASS.


CLASS ltc_classifier IMPLEMENTATION.

  METHOD setup.
    cut = NEW zcl_ccr_classifier( NEW ltd_level_rules( ) ).
  ENDMETHOD.


  METHOD finding_of.
    result = VALUE #( object_type = object_type
                      object_name = object_name
                      code        = level ).
  ENDMETHOD.


  METHOD when_no_findings_then_empty.
    " ACT
    DATA(object_levels) = cut->classify( VALUE #( ) ).

    " ASSERT
    cl_abap_unit_assert=>assert_initial( act = object_levels
                                         msg = `Without findings there is no object to classify` ).
  ENDMETHOD.


  METHOD when_no_clean_core_then_a.
    " ARRANGE
    DATA(findings) = VALUE zif_ccr_level_rules=>findings(
      ( finding_of( object_name = 'ZCL_CLEAN'
                    level       = zif_ccr_level_rules=>level-none ) ) ).

    " ACT
    DATA(object_levels) = cut->classify( findings ).

    " ASSERT
    cl_abap_unit_assert=>assert_equals(
      act = object_levels
      exp = VALUE zif_ccr_classifier=>object_levels( ( object_type = 'CLAS'
                                                       object_name = 'ZCL_CLEAN'
                                                       level       = zif_ccr_level_rules=>level-a ) )
      msg = `An object whose findings are all outside clean core is level A` ).
  ENDMETHOD.


  METHOD when_mixed_levels_then_worst.
    " ARRANGE
    DATA(findings) = VALUE zif_ccr_level_rules=>findings(
      ( finding_of( object_name = 'ZCL_MIXED'
                    level       = zif_ccr_level_rules=>level-b ) )
      ( finding_of( object_name = 'ZCL_MIXED'
                    level       = zif_ccr_level_rules=>level-d ) )
      ( finding_of( object_name = 'ZCL_MIXED'
                    level       = zif_ccr_level_rules=>level-c ) ) ).

    " ACT
    DATA(object_levels) = cut->classify( findings ).

    " ASSERT
    cl_abap_unit_assert=>assert_equals(
      act = object_levels[ object_type = 'CLAS' object_name = 'ZCL_MIXED' ]-level
      exp = zif_ccr_level_rules=>level-d
      msg = `An object takes the worst level among its findings, whatever their order` ).
  ENDMETHOD.


  METHOD when_findings_then_counted.
    " ARRANGE
    DATA(findings) = VALUE zif_ccr_level_rules=>findings(
      ( finding_of( object_name = 'ZCL_COUNTED'
                    level       = zif_ccr_level_rules=>level-b ) )
      ( finding_of( object_name = 'ZCL_COUNTED'
                    level       = zif_ccr_level_rules=>level-c ) )
      ( finding_of( object_name = 'ZCL_COUNTED'
                    level       = zif_ccr_level_rules=>level-b ) )
      ( finding_of( object_name = 'ZCL_COUNTED'
                    level       = zif_ccr_level_rules=>level-none ) ) ).

    " ACT
    DATA(object_levels) = cut->classify( findings ).

    " ASSERT
    cl_abap_unit_assert=>assert_equals(
      act = object_levels
      exp = VALUE zif_ccr_classifier=>object_levels( ( object_type = 'CLAS'
                                                       object_name = 'ZCL_COUNTED'
                                                       level       = zif_ccr_level_rules=>level-c
                                                       findings_b  = 2
                                                       findings_c  = 1 ) )
      msg = `The clean core findings of an object are counted per level, the others are not` ).
  ENDMETHOD.


  METHOD when_same_name_then_by_type.
    " ARRANGE
    DATA(findings) = VALUE zif_ccr_level_rules=>findings(
      ( finding_of( object_type = 'PROG'
                    object_name = 'Z_SAME_NAME'
                    level       = zif_ccr_level_rules=>level-b ) )
      ( finding_of( object_type = 'DDLS'
                    object_name = 'Z_SAME_NAME'
                    level       = zif_ccr_level_rules=>level-c ) ) ).

    " ACT
    DATA(object_levels) = cut->classify( findings ).

    " ASSERT
    cl_abap_unit_assert=>assert_equals(
      act = lines( object_levels )
      exp = 2
      msg = `Objects of different types are different objects, also with the same name` ).
  ENDMETHOD.

ENDCLASS.
