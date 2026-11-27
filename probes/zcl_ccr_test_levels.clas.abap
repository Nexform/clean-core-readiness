"! <p class="shorttext synchronized" lang="EN">Clean Core Readiness: test object for ATC findings</p>
"! Create it in $TMP and run ATC with the clean core check variant on it. No method is ever
"! called: each one is there only to give ATC findings of a known kind. The findings this
"! object gives on purpose (unused variables, writes to SAP tables, GENERATE) are the point.
CLASS zcl_ccr_test_levels DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! Uses a classic API: expected a note of "Usage of APIs", level B.
    METHODS classic_api.

    "! Reads an SAP table: expected a warning of "Usage of APIs", level C.
    METHODS read_sap_table.

    "! Writes to an SAP table: expected an error of "Usage of APIs", level D.
    METHODS write_sap_table.

    "! Generates a program and uses native SQL: for the check "Critical statements".
    METHODS critical_statements.

ENDCLASS.


CLASS zcl_ccr_test_levels IMPLEMENTATION.

  METHOD classic_api.
    cl_abap_browser=>show_html( html_string = `<p>clean core test</p>` ).
  ENDMETHOD.


  METHOD read_sap_table.
    SELECT SINGLE clsname FROM seoclass
      WHERE clsname = 'CL_ABAP_BROWSER'
      INTO @DATA(class_name).
  ENDMETHOD.


  METHOD write_sap_table.
    " the key does not exist: even if it ran, the statement would change nothing
    UPDATE t100 SET text = 'clean core test'
      WHERE sprsl = 'E'
        AND arbgb = 'ZZZ_NOT_THERE'
        AND msgnr = '000'.
  ENDMETHOD.


  METHOD critical_statements.
    DATA source TYPE string_table.
    DATA one TYPE i.

    GENERATE SUBROUTINE POOL source NAME DATA(program).
    EXEC SQL.
      SELECT 1 INTO :one FROM dummy
    ENDEXEC.
  ENDMETHOD.

ENDCLASS.
