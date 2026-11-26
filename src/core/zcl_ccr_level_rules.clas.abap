"! <p class="shorttext synchronized" lang="EN">Clean core level rules of the SAP checks</p>
"! Knows the clean core checks of SAP and the level their findings stand for. Confirmed on
"! SAP S/4HANA 2025 (SAP_BASIS 816) for the check "Usage of APIs": a note is a classic API
"! (level B), a warning an internal object (level C), an error an object that must not be
"! used (level D).
CLASS zcl_ccr_level_rules DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_ccr_level_rules.

  PRIVATE SECTION.
    "! Class of the ATC check "Usage of APIs"
    CONSTANTS api_usage_check TYPE zif_ccr_level_rules=>check_name VALUE 'CL_YCM_CC_CHECK_API_USAGE'.
    "! Codes with which the check framework reports its own problems: a syntax error in the
    "! checked object, a failed RFC connection
    CONSTANTS framework_code_pattern TYPE string VALUE `_*`.
    "! Codes of "Usage of APIs" that carry technical information and no use of an SAP object
    CONSTANTS: BEGIN OF technical_code,
                 attribute        TYPE zif_ccr_level_rules=>message_code VALUE 'ATTRIBUTE',
                 object_usage_add TYPE zif_ccr_level_rules=>message_code VALUE 'U_ADD',
                 object_usage_all TYPE zif_ccr_level_rules=>message_code VALUE 'U_ALL',
                 object_usage_std TYPE zif_ccr_level_rules=>message_code VALUE 'U_STD',
                 provider_failed  TYPE zif_ccr_level_rules=>message_code VALUE 'PRVIDR_ERR',
                 rfc_failed       TYPE zif_ccr_level_rules=>message_code VALUE 'RFC_ERROR',
                 released_unread  TYPE zif_ccr_level_rules=>message_code VALUE 'SPRVIDR_ER',
               END OF technical_code.

    METHODS is_technical
      IMPORTING code          TYPE zif_ccr_level_rules=>message_code
      RETURNING VALUE(result) TYPE abap_bool.

ENDCLASS.


CLASS zcl_ccr_level_rules IMPLEMENTATION.

  METHOD zif_ccr_level_rules~level_of.
    IF finding-check_name <> api_usage_check OR is_technical( finding-code ) = abap_true.
      result = zif_ccr_level_rules=>level-none.
      RETURN.
    ENDIF.

    result = SWITCH #( finding-kind
                       WHEN zif_ccr_level_rules=>finding_kind-note    THEN zif_ccr_level_rules=>level-b
                       WHEN zif_ccr_level_rules=>finding_kind-warning THEN zif_ccr_level_rules=>level-c
                       WHEN zif_ccr_level_rules=>finding_kind-error   THEN zif_ccr_level_rules=>level-d
                       ELSE zif_ccr_level_rules=>level-none ).
  ENDMETHOD.


  METHOD is_technical.
    CASE code.
      WHEN technical_code-attribute
        OR technical_code-object_usage_add
        OR technical_code-object_usage_all
        OR technical_code-object_usage_std
        OR technical_code-provider_failed
        OR technical_code-rfc_failed
        OR technical_code-released_unread.
        result = abap_true.
      WHEN OTHERS.
        result = xsdbool( code CP framework_code_pattern ).
    ENDCASE.
  ENDMETHOD.

ENDCLASS.
