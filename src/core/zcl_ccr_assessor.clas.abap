"! <p class="shorttext synchronized" lang="EN">Joins level and usage of custom objects to a proposal</p>
"! Proposes what to do with a custom object from its clean core level and its usage.
"! Confirmed on SAP S/4HANA 2025 (SAP_BASIS 816): the usage data of SUSG has rows for
"! classes, function groups and programs only.
CLASS zcl_ccr_assessor DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_ccr_assessor.

  PRIVATE SECTION.
    "! Object types whose usage can be measured
    CONSTANTS: BEGIN OF measured_type,
                 class          TYPE zif_ccr_level_rules=>object_type VALUE 'CLAS',
                 function_group TYPE zif_ccr_level_rules=>object_type VALUE 'FUGR',
                 program        TYPE zif_ccr_level_rules=>object_type VALUE 'PROG',
               END OF measured_type.

    METHODS usage_state_of
      IMPORTING object_type   TYPE zif_ccr_level_rules=>object_type
                executions    TYPE zif_ccr_assessor=>execution_count
      RETURNING VALUE(result) TYPE zif_ccr_assessor=>usage_state_code.

    METHODS proposal_for
      IMPORTING level         TYPE zif_ccr_level_rules=>clean_core_level
                usage_state   TYPE zif_ccr_assessor=>usage_state_code
                behavior_pool TYPE abap_bool
      RETURNING VALUE(result) TYPE zif_ccr_assessor=>proposal_code.

ENDCLASS.


CLASS zcl_ccr_assessor IMPLEMENTATION.

  METHOD zif_ccr_assessor~assess.
    LOOP AT object_levels REFERENCE INTO DATA(object_level).
      DATA(usage) = VALUE zif_ccr_assessor=>object_usage(
        usages[ object_type = object_level->object_type
                object_name = object_level->object_name ] OPTIONAL ).
      DATA(assessment) = CORRESPONDING zif_ccr_assessor=>assessment( object_level->* ).
      assessment-executions  = usage-executions.
      assessment-last_used   = usage-last_used.
      assessment-usage_state = usage_state_of( object_type = object_level->object_type
                                               executions  = usage-executions ).
      DATA(behavior_pool) = xsdbool( line_exists( behavior_pools[ object_type = object_level->object_type
                                                                  object_name = object_level->object_name ] ) ).
      assessment-proposal    = proposal_for( level         = object_level->level
                                             usage_state   = assessment-usage_state
                                             behavior_pool = behavior_pool ).
      INSERT assessment INTO TABLE result.
    ENDLOOP.
  ENDMETHOD.


  METHOD zif_ccr_assessor~summarize.
    result = VALUE #( ( level = zif_ccr_level_rules=>level-a )
                      ( level = zif_ccr_level_rules=>level-b )
                      ( level = zif_ccr_level_rules=>level-c )
                      ( level = zif_ccr_level_rules=>level-d ) ).

    LOOP AT assessments REFERENCE INTO DATA(assessment).
      IF NOT line_exists( result[ level = assessment->level ] ).
        CONTINUE.
      ENDIF.
      DATA(line) = REF #( result[ level = assessment->level ] ).
      CASE assessment->usage_state.
        WHEN zif_ccr_assessor=>usage_state-used.
          line->used += 1.
        WHEN zif_ccr_assessor=>usage_state-not_used.
          line->not_used += 1.
        WHEN OTHERS.
          line->unknown += 1.
      ENDCASE.
      line->total += 1.
    ENDLOOP.
  ENDMETHOD.


  METHOD usage_state_of.
    CASE object_type.
      WHEN measured_type-class
        OR measured_type-function_group
        OR measured_type-program.
        result = COND #( WHEN executions > 0
                         THEN zif_ccr_assessor=>usage_state-used
                         ELSE zif_ccr_assessor=>usage_state-not_used ).
      WHEN OTHERS.
        result = zif_ccr_assessor=>usage_state-unknown.
    ENDCASE.
  ENDMETHOD.


  METHOD proposal_for.
    IF usage_state = zif_ccr_assessor=>usage_state-not_used.
      result = COND #( WHEN behavior_pool = abap_true
                       THEN zif_ccr_assessor=>proposal-retire_with_bdef
                       ELSE zif_ccr_assessor=>proposal-retire ).
      RETURN.
    ENDIF.

    result = SWITCH #( level
                       WHEN zif_ccr_level_rules=>level-c THEN zif_ccr_assessor=>proposal-remediate
                       WHEN zif_ccr_level_rules=>level-d THEN zif_ccr_assessor=>proposal-remediate_first
                       ELSE zif_ccr_assessor=>proposal-keep ).
  ENDMETHOD.

ENDCLASS.
