CLASS ltc_assessor DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zif_ccr_assessor.

    METHODS setup.

    "! Assesses one object and hands back its row.
    METHODS assessment_of
      IMPORTING object_type   TYPE zif_ccr_level_rules=>object_type
                level         TYPE zif_ccr_level_rules=>clean_core_level
                executions    TYPE zif_ccr_assessor=>execution_count
      RETURNING VALUE(result) TYPE zif_ccr_assessor=>assessment.

    METHODS when_used_level_b_then_keep FOR TESTING.
    METHODS when_used_level_c_then_remed FOR TESTING.
    METHODS when_used_level_d_then_first FOR TESTING.
    METHODS when_not_used_then_retire FOR TESTING.
    METHODS when_cds_view_then_no_retire FOR TESTING.
    METHODS when_used_then_usage_shown FOR TESTING.

ENDCLASS.


CLASS ltc_assessor IMPLEMENTATION.

  METHOD setup.
    cut = NEW zcl_ccr_assessor( ).
  ENDMETHOD.


  METHOD assessment_of.
    DATA(object_levels) = VALUE zif_ccr_classifier=>object_levels( ( object_type = object_type
                                                                     object_name = 'Z_ANY_OBJECT'
                                                                     level       = level ) ).
    DATA(usages) = COND zif_ccr_assessor=>object_usages(
      WHEN executions > 0
      THEN VALUE #( ( object_type = object_type
                      object_name = 'Z_ANY_OBJECT'
                      executions  = executions
                      last_used   = '20261125' ) ) ).

    DATA(assessments) = cut->assess( object_levels = object_levels
                                     usages        = usages ).

    result = assessments[ object_type = object_type
                          object_name = 'Z_ANY_OBJECT' ].
  ENDMETHOD.


  METHOD when_used_level_b_then_keep.
    " ACT
    DATA(assessment) = assessment_of( object_type = 'CLAS'
                                      level       = zif_ccr_level_rules=>level-b
                                      executions  = 12 ).

    " ASSERT
    cl_abap_unit_assert=>assert_equals( act = assessment-proposal
                                        exp = zif_ccr_assessor=>proposal-keep
                                        msg = `A used object at level B stays as it is` ).
  ENDMETHOD.


  METHOD when_used_level_c_then_remed.
    " ACT
    DATA(assessment) = assessment_of( object_type = 'PROG'
                                      level       = zif_ccr_level_rules=>level-c
                                      executions  = 1 ).

    " ASSERT
    cl_abap_unit_assert=>assert_equals( act = assessment-proposal
                                        exp = zif_ccr_assessor=>proposal-remediate
                                        msg = `A used object at level C is to be remediated` ).
  ENDMETHOD.


  METHOD when_used_level_d_then_first.
    " ACT
    DATA(assessment) = assessment_of( object_type = 'FUGR'
                                      level       = zif_ccr_level_rules=>level-d
                                      executions  = 3 ).

    " ASSERT
    cl_abap_unit_assert=>assert_equals( act = assessment-proposal
                                        exp = zif_ccr_assessor=>proposal-remediate_first
                                        msg = `A used object at level D is to be remediated first` ).
  ENDMETHOD.


  METHOD when_not_used_then_retire.
    " ACT
    DATA(assessment) = assessment_of( object_type = 'CLAS'
                                      level       = zif_ccr_level_rules=>level-d
                                      executions  = 0 ).

    " ASSERT
    cl_abap_unit_assert=>assert_equals( act = assessment-usage_state
                                        exp = zif_ccr_assessor=>usage_state-not_used
                                        msg = `A class without usage data did not run` ).
    cl_abap_unit_assert=>assert_equals( act = assessment-proposal
                                        exp = zif_ccr_assessor=>proposal-retire
                                        msg = `An object that did not run is retired, not remediated` ).
  ENDMETHOD.


  METHOD when_cds_view_then_no_retire.
    " ACT
    DATA(assessment) = assessment_of( object_type = 'DDLS'
                                      level       = zif_ccr_level_rules=>level-c
                                      executions  = 0 ).

    " ASSERT
    cl_abap_unit_assert=>assert_equals( act = assessment-usage_state
                                        exp = zif_ccr_assessor=>usage_state-unknown
                                        msg = `The usage of a CDS view cannot be measured` ).
    cl_abap_unit_assert=>assert_equals( act = assessment-proposal
                                        exp = zif_ccr_assessor=>proposal-remediate
                                        msg = `An object of unknown usage follows its level and is never retired` ).
  ENDMETHOD.


  METHOD when_used_then_usage_shown.
    " ACT
    DATA(assessment) = assessment_of( object_type = 'CLAS'
                                      level       = zif_ccr_level_rules=>level-a
                                      executions  = 250 ).

    " ASSERT
    cl_abap_unit_assert=>assert_equals( act = assessment-usage_state
                                        exp = zif_ccr_assessor=>usage_state-used
                                        msg = `A class with executions is used` ).
    cl_abap_unit_assert=>assert_equals( act = assessment-executions
                                        exp = CONV zif_ccr_assessor=>execution_count( 250 )
                                        msg = `The row shows how often the object ran` ).
    cl_abap_unit_assert=>assert_equals( act = assessment-last_used
                                        exp = CONV d( '20261125' )
                                        msg = `The row shows when the object ran last` ).
  ENDMETHOD.

ENDCLASS.
