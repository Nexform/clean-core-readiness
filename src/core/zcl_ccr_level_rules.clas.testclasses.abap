CLASS ltc_level_rules DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zif_ccr_level_rules.

    METHODS setup.

    METHODS api_usage_finding
      IMPORTING code          TYPE zif_ccr_level_rules=>message_code
                kind          TYPE zif_ccr_level_rules=>finding_kind_code
      RETURNING VALUE(result) TYPE zif_ccr_level_rules=>finding.

    METHODS when_classic_api_then_level_b FOR TESTING.
    METHODS when_internal_api_then_level_c FOR TESTING.
    METHODS when_no_api_then_level_d FOR TESTING.
    METHODS when_other_check_then_none FOR TESTING.
    METHODS when_technical_code_then_none FOR TESTING.
    METHODS when_framework_code_then_none FOR TESTING.
    METHODS when_unknown_kind_then_none FOR TESTING.

ENDCLASS.


CLASS ltc_level_rules IMPLEMENTATION.

  METHOD setup.
    cut = NEW zcl_ccr_level_rules( ).
  ENDMETHOD.


  METHOD api_usage_finding.
    result = VALUE #( object_type = 'CLAS'
                      object_name = 'ZCL_ANY_CUSTOM_CLASS'
                      check_name  = 'CL_YCM_CC_CHECK_API_USAGE'
                      code        = code
                      kind        = kind ).
  ENDMETHOD.


  METHOD when_classic_api_then_level_b.
    " ARRANGE
    DATA(finding) = api_usage_finding( code = 'CLSSIC'
                                       kind = 'N' ).

    " ACT
    DATA(level) = cut->level_of( finding ).

    " ASSERT
    cl_abap_unit_assert=>assert_equals( act = level
                                        exp = zif_ccr_level_rules=>level-b
                                        msg = `A note of "Usage of APIs" is a classic API: level B` ).
  ENDMETHOD.


  METHOD when_internal_api_then_level_c.
    " ARRANGE
    DATA(finding) = api_usage_finding( code = 'INTRNL'
                                       kind = 'W' ).

    " ACT
    DATA(level) = cut->level_of( finding ).

    " ASSERT
    cl_abap_unit_assert=>assert_equals( act = level
                                        exp = zif_ccr_level_rules=>level-c
                                        msg = `A warning of "Usage of APIs" is an internal object: level C` ).
  ENDMETHOD.


  METHOD when_no_api_then_level_d.
    " ARRANGE
    DATA(finding) = api_usage_finding( code = 'NOAPI'
                                       kind = 'E' ).

    " ACT
    DATA(level) = cut->level_of( finding ).

    " ASSERT
    cl_abap_unit_assert=>assert_equals( act = level
                                        exp = zif_ccr_level_rules=>level-d
                                        msg = `An error of "Usage of APIs" is a forbidden object: level D` ).
  ENDMETHOD.


  METHOD when_other_check_then_none.
    " ARRANGE
    DATA(finding) = VALUE zif_ccr_level_rules=>finding( object_type = 'CLAS'
                                                        object_name = 'ZCL_ANY_CUSTOM_CLASS'
                                                        check_name  = 'CL_CI_TEST_EXTENDED_CHECK'
                                                        code        = '1700'
                                                        kind        = 'E' ).

    " ACT
    DATA(level) = cut->level_of( finding ).

    " ASSERT
    cl_abap_unit_assert=>assert_equals( act = level
                                        exp = zif_ccr_level_rules=>level-none
                                        msg = `A finding of a check outside clean core must not give a level` ).
  ENDMETHOD.


  METHOD when_technical_code_then_none.
    " ARRANGE
    DATA(finding) = api_usage_finding( code = 'ATTRIBUTE'
                                       kind = 'N' ).

    " ACT
    DATA(level) = cut->level_of( finding ).

    " ASSERT
    cl_abap_unit_assert=>assert_equals( act = level
                                        exp = zif_ccr_level_rules=>level-none
                                        msg = `A technical message of "Usage of APIs" must not give a level` ).
  ENDMETHOD.


  METHOD when_framework_code_then_none.
    " ARRANGE
    DATA(finding) = api_usage_finding( code = '_SYNERR_'
                                       kind = 'E' ).

    " ACT
    DATA(level) = cut->level_of( finding ).

    " ASSERT
    cl_abap_unit_assert=>assert_equals( act = level
                                        exp = zif_ccr_level_rules=>level-none
                                        msg = `A message of the check framework must not give a level` ).
  ENDMETHOD.


  METHOD when_unknown_kind_then_none.
    " ARRANGE
    DATA(finding) = api_usage_finding( code = 'CLSSIC'
                                       kind = 'X' ).

    " ACT
    DATA(level) = cut->level_of( finding ).

    " ASSERT
    cl_abap_unit_assert=>assert_equals( act = level
                                        exp = zif_ccr_level_rules=>level-none
                                        msg = `A kind that ATC does not know must not give a level` ).
  ENDMETHOD.

ENDCLASS.
