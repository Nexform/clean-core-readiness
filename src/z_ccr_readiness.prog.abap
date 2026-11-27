*###################################################################*
*#-----------------------------------------------------------------#*
*#      |\\/\\//\|        -----------------------------------      #*
*#      |        |       /      Report: Z_CCR_READINESS      \     #*
*#      |  (*) (*)      /                                     \    #*
*#      |       __)    /        Version: 1.3 ()                \   #*
*#     (C    _____\   /         Magic. Do not touch.            \  #*
*#       \  (__(   --{-------------------------------------------} #*
*#       |    /       \         Created By : George Drakos      /  #*
*#       /====\        \        Created On : 26/11/2026        /   #*
*#      /     o\        \       SAP Version: S4CORE 109       /    #*
*#     /       o\        \                                   /     #*
*#    /         o\        \     S4HANA ON PREMISE 2025      /      #*
*#   /           o\        \                               /       #*
*#  /             o\        -------------------------------        #*
*#-----------------------------------------------------------------#*
*###################################################################*
*&--------------------------------------------------------------------&*
*&              M O D I F I C A T I O N    L O G                      &*
*&--------------------------------------------------------------------&*
*& Description    : Clean core readiness of custom objects: level A-D *
*&                  from an ATC run, usage from SUSG, a proposal per   *
*&                  object (keep, remediate, retire). Read-only.       *
*& Author         : George Drakos                                      *
*& Date           : 26/11/2026                                         *
*& Change Request :                                                    *
*&--------------------------------------------------------------------&*
*& Description    : Value helps: ID columns with a dictionary type;    *
*&                  failure of the value help told apart from no values*
*& Author         : George Drakos                                      *
*& Date           : 26/11/2026                                         *
*& Change Request :                                                    *
*&--------------------------------------------------------------------&*
*& Description    : Pushbuttons for the steps to run ATC and a jump to *
*&                  transaction ATC; required fields checked in the    *
*&                  report, so the buttons work on an empty screen     *
*& Author         : George Drakos                                      *
*& Date           : 27/11/2026                                         *
*& Change Request :                                                    *
*&--------------------------------------------------------------------&*
*& Description    : Packages and object types are the scope: findings *
*&                  of objects outside them are left out               *
*& Author         : George Drakos                                      *
*& Date           : 27/11/2026                                         *
*& Change Request :                                                    *
*&--------------------------------------------------------------------&*
REPORT z_ccr_readiness.
*&---------------------------------------------------------------------*
*& GLOBAL DATA DECLARATION
*&---------------------------------------------------------------------*
DATA package_name TYPE devclass.
DATA object_type TYPE trobjtype.

*&----------------------------------------------------------------------*
*&CLASS lcl_value_help DEFINITION
*&----------------------------------------------------------------------*
"! Value helps of the selection screen: the runs of the check variant and the usage data sets.
CLASS lcl_value_help DEFINITION FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    "! Offers the complete runs of the check variant on the screen and puts the chosen one there.
    CLASS-METHODS choose_run.

    "! Offers the usage data sets and puts the chosen one on the screen.
    CLASS-METHODS choose_data_set.

  PRIVATE SECTION.
    "! The value help reads its columns from the dictionary, so the ID column has a dictionary type
    TYPES hex_id TYPE sysuuid_c32.
    TYPES: BEGIN OF run_value,
             result_id    TYPE hex_id,
             title        TYPE satc_ac_resulth-title,
             run_series   TYPE satc_ac_resulth-run_series_name,
             scheduled_on TYPE satc_ac_resulth-scheduled_on_ts,
           END OF run_value.
    TYPES run_values TYPE STANDARD TABLE OF run_value WITH EMPTY KEY.
    TYPES: BEGIN OF data_set_value,
             usage_id    TYPE hex_id,
             system_id   TYPE susg_admin-sysid,
             kind        TYPE susg_admin-kind,
             date_from   TYPE susg_admin-date_from,
             date_to     TYPE susg_admin-date_to,
             description TYPE susg_admin-description,
           END OF data_set_value.
    TYPES data_set_values TYPE STANDARD TABLE OF data_set_value WITH EMPTY KEY.
    TYPES screen_values TYPE STANDARD TABLE OF dynpread WITH EMPTY KEY.

    CONSTANTS: BEGIN OF screen_field,
                 check_variant TYPE dynpread-fieldname VALUE 'P_CHKV',
                 run           TYPE dynpread-fieldname VALUE 'P_RUN',
                 data_set      TYPE dynpread-fieldname VALUE 'P_USAGE',
               END OF screen_field.
    CONSTANTS: BEGIN OF value_column,
                 run      TYPE dfies-fieldname VALUE 'RESULT_ID',
                 data_set TYPE dfies-fieldname VALUE 'USAGE_ID',
               END OF value_column.
    CONSTANTS single_value TYPE ddbool_d VALUE 'S'.

    "! The check variant as typed on the screen - a value help event does not transport it.
    CLASS-METHODS check_variant_on_screen
      RETURNING VALUE(result) TYPE zif_ccr_atc_reader=>check_variant.

    CLASS-METHODS offer
      IMPORTING value_column TYPE dfies-fieldname
                screen_field TYPE dynpread-fieldname
      CHANGING  values       TYPE STANDARD TABLE.

ENDCLASS.

*&----------------------------------------------------------------------*
*&CLASS lcl_atc_guide DEFINITION
*&----------------------------------------------------------------------*
"! Help for users without an ATC run yet: the steps to run ATC with the clean core variant, and
"! a jump to transaction ATC. The report itself starts no ATC run.
CLASS lcl_atc_guide DEFINITION FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    CONSTANTS: BEGIN OF command,
                 show_steps TYPE sy-ucomm VALUE 'ATC_STEPS',
                 open_atc   TYPE sy-ucomm VALUE 'ATC_OPEN',
               END OF command.

    "! Reacts to the pushbuttons of the selection screen; other commands are left alone.
    CLASS-METHODS on_command
      IMPORTING command TYPE sy-ucomm.

  PRIVATE SECTION.
    TYPES: BEGIN OF step,
             step TYPE i,
             text TYPE string,
           END OF step.
    TYPES steps TYPE STANDARD TABLE OF step WITH EMPTY KEY.

    CONSTANTS atc_transaction TYPE sy-tcode VALUE 'ATC'.

    "! Shows the steps in a popup list.
    CLASS-METHODS show_steps.

    CLASS-METHODS open_atc.

ENDCLASS.

*&----------------------------------------------------------------------*
*&CLASS lcl_alv DEFINITION
*&----------------------------------------------------------------------*
"! Shows the assessment as ALV list, with the ATC run and the usage period above it.
"! The ALV toolbar exports the list to a spreadsheet.
CLASS lcl_alv DEFINITION FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS display
      IMPORTING assessments TYPE zif_ccr_assessor=>assessments
                run         TYPE zif_ccr_atc_reader=>run
                data_set    TYPE zif_ccr_usage_reader=>data_set.

  PRIVATE SECTION.
    TYPES output_rows TYPE STANDARD TABLE OF zif_ccr_assessor=>assessment WITH EMPTY KEY.
    TYPES: BEGIN OF column_text,
             name TYPE lvc_fname,
             text TYPE scrtext_m,
           END OF column_text.
    TYPES column_texts TYPE STANDARD TABLE OF column_text WITH EMPTY KEY.

    "! The rows the ALV shows - they live as long as the list
    DATA rows TYPE output_rows.

    METHODS name_columns
      IMPORTING columns TYPE REF TO cl_salv_columns_table.

    METHODS list_header
      IMPORTING run           TYPE zif_ccr_atc_reader=>run
                data_set      TYPE zif_ccr_usage_reader=>data_set
      RETURNING VALUE(result) TYPE REF TO cl_salv_form_layout_grid.

ENDCLASS.

*&----------------------------------------------------------------------*
*&CLASS lcl_application DEFINITION
*&----------------------------------------------------------------------*
"! Composition root: reads the ATC run and the usage data, classifies and assesses the objects.
CLASS lcl_application DEFINITION FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES: BEGIN OF screen_selection,
             check_variant TYPE zif_ccr_atc_reader=>check_variant,
             run_id        TYPE sysuuid_c32,
             packages      TYPE zif_ccr_atc_reader=>package_range,
             object_types  TYPE zif_ccr_atc_reader=>object_type_range,
             usage_id      TYPE sysuuid_c32,
           END OF screen_selection.

    METHODS constructor
      IMPORTING selection TYPE screen_selection.

    METHODS run.

  PRIVATE SECTION.
    DATA selection TYPE screen_selection.
    DATA atc_reader TYPE REF TO zif_ccr_atc_reader.
    DATA usage_reader TYPE REF TO zif_ccr_usage_reader.

    "! The chosen run, if it is a complete run of the check variant; initial otherwise.
    METHODS chosen_run
      RETURNING VALUE(result) TYPE zif_ccr_atc_reader=>run.

    "! The chosen usage data set; initial if it does not exist.
    METHODS chosen_data_set
      RETURNING VALUE(result) TYPE zif_ccr_usage_reader=>data_set.

    "! Findings and objects of the run, classified, then assessed with their usage.
    METHODS assess
      IMPORTING result_id     TYPE satc_d_result_id
                usage_id      TYPE susg_admin-usgid
      RETURNING VALUE(result) TYPE zif_ccr_assessor=>assessments.

ENDCLASS.

*&---------------------------------------------------------------------*
*& SELECTION SCREEN DESIGN
*&---------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b03 WITH FRAME TITLE TEXT-b03.
SELECTION-SCREEN PUSHBUTTON /1(30) sc_steps USER-COMMAND atc_steps.
SELECTION-SCREEN PUSHBUTTON 33(30) sc_atc USER-COMMAND atc_open.
SELECTION-SCREEN END OF BLOCK b03.

" no field is OBLIGATORY: a pushbutton would then only work once every field is filled in,
" and the ATC help is needed before there is a run to enter
SELECTION-SCREEN BEGIN OF BLOCK b01 WITH FRAME TITLE TEXT-b01.
PARAMETERS p_chkv TYPE satc_ac_resulth-chk_profile_name DEFAULT 'ABAP_CLEAN_CORE_DEVELOPMENT'.
PARAMETERS p_run TYPE sysuuid_c32.
SELECT-OPTIONS s_pack FOR package_name.
SELECT-OPTIONS s_type FOR object_type.
SELECTION-SCREEN END OF BLOCK b01.

SELECTION-SCREEN BEGIN OF BLOCK b02 WITH FRAME TITLE TEXT-b02.
PARAMETERS p_usage TYPE sysuuid_c32.
SELECTION-SCREEN END OF BLOCK b02.

*&---------------------------------------------------------------------*
*& INITIALIZATION OF SELECTION SCREEN ELEMENTS
*&---------------------------------------------------------------------*
INITIALIZATION.
  sc_steps = TEXT-p01.
  sc_atc  = TEXT-p02.
  " object types that carry code; other types have no clean core finding and would all be level A
  s_type[] = VALUE #( sign   = 'I'
                      option = 'EQ'
                      ( low = 'CLAS' )
                      ( low = 'INTF' )
                      ( low = 'PROG' )
                      ( low = 'FUGR' )
                      ( low = 'DDLS' )
                      ( low = 'BDEF' )
                      ( low = 'ENHO' ) ).

*&---------------------------------------------------------------------*
*& AT SELECTION SCREEN
*&---------------------------------------------------------------------*
AT SELECTION-SCREEN.
  lcl_atc_guide=>on_command( sy-ucomm ).

*&---------------------------------------------------------------------*
*& AT SELECTION SCREEN ON VALUE REQUESTS (F4)
*&---------------------------------------------------------------------*
AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_run.
  lcl_value_help=>choose_run( ).

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_usage.
  lcl_value_help=>choose_data_set( ).

*&---------------------------------------------------------------------*
*& EXECUTABLE CODE
*&---------------------------------------------------------------------*
START-OF-SELECTION.
  NEW lcl_application( VALUE #( check_variant = p_chkv
                                run_id        = p_run
                                packages      = s_pack[]
                                object_types  = s_type[]
                                usage_id      = p_usage ) )->run( ).
*&---------------------------------------------------------------------*
*& END OF EXECUTABLE CODE
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& START OF CLASS IMPLEMENTATION
*&---------------------------------------------------------------------*

*&----------------------------------------------------------------------*
*&CLASS lcl_value_help IMPLEMENTATION
*&----------------------------------------------------------------------*
CLASS lcl_value_help IMPLEMENTATION.

  METHOD choose_run.
    DATA(atc_reader) = CAST zif_ccr_atc_reader( NEW zcl_ccr_atc_reader( ) ).
    DATA(values) = VALUE run_values( FOR run IN atc_reader->runs( check_variant_on_screen( ) )
                                     ( result_id    = |{ run-result_id }|
                                       title        = run-title
                                       run_series   = run-run_series
                                       scheduled_on = run-scheduled_on ) ).
    offer( EXPORTING value_column = value_column-run
                     screen_field = screen_field-run
           CHANGING  values       = values ).
  ENDMETHOD.


  METHOD choose_data_set.
    DATA(usage_reader) = CAST zif_ccr_usage_reader( NEW zcl_ccr_usage_reader( ) ).
    DATA(values) = VALUE data_set_values( FOR data_set IN usage_reader->data_sets( )
                                          ( usage_id    = |{ data_set-usage_id }|
                                            system_id   = data_set-system_id
                                            kind        = data_set-kind
                                            date_from   = data_set-date_from
                                            date_to     = data_set-date_to
                                            description = data_set-description ) ).
    offer( EXPORTING value_column = value_column-data_set
                     screen_field = screen_field-data_set
           CHANGING  values       = values ).
  ENDMETHOD.


  METHOD check_variant_on_screen.
    DATA(fields) = VALUE screen_values( ( fieldname = screen_field-check_variant ) ).

    CALL FUNCTION 'DYNP_VALUES_READ'
      EXPORTING
        dyname     = sy-repid
        dynumb     = sy-dynnr
      TABLES
        dynpfields = fields
      EXCEPTIONS
        OTHERS     = 1.
    IF sy-subrc = 0 AND fields IS NOT INITIAL.
      result = to_upper( fields[ 1 ]-fieldvalue ).
    ENDIF.
  ENDMETHOD.


  METHOD offer.
    CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
      EXPORTING
        retfield        = value_column
        dynpprog        = sy-repid
        dynpnr          = sy-dynnr
        dynprofield     = screen_field
        value_org       = single_value
      TABLES
        value_tab       = values
      EXCEPTIONS
        parameter_error = 1
        no_values_found = 2
        OTHERS          = 3.
    CASE sy-subrc.
      WHEN 0.
        RETURN.
      WHEN 2.
        MESSAGE TEXT-e04 TYPE 'S' DISPLAY LIKE 'E'.
      WHEN OTHERS.
        MESSAGE |{ TEXT-e05 } { sy-subrc }| TYPE 'S' DISPLAY LIKE 'E'.
    ENDCASE.
  ENDMETHOD.

ENDCLASS.

*&----------------------------------------------------------------------*
*&CLASS lcl_atc_guide IMPLEMENTATION
*&----------------------------------------------------------------------*
CLASS lcl_atc_guide IMPLEMENTATION.

  METHOD on_command.
    CASE command.
      WHEN lcl_atc_guide=>command-show_steps.
        show_steps( ).
      WHEN lcl_atc_guide=>command-open_atc.
        open_atc( ).
      WHEN OTHERS.
        RETURN.
    ENDCASE.
  ENDMETHOD.


  METHOD show_steps.
    DATA(steps) = VALUE steps( ( step = 1 text = TEXT-s01 )
                               ( step = 2 text = TEXT-s02 )
                               ( step = 3 text = TEXT-s03 )
                               ( step = 4 text = TEXT-s04 )
                               ( step = 5 text = TEXT-s05 )
                               ( step = 6 text = TEXT-s06 )
                               ( step = 7 text = TEXT-s07 )
                               ( step = 8 text = TEXT-s08 ) ).
    TRY.
        cl_salv_table=>factory( IMPORTING r_salv_table = DATA(alv)
                                CHANGING  t_table      = steps ).
        alv->get_display_settings( )->set_list_header( CONV #( TEXT-t01 ) ).
        alv->get_columns( )->set_optimize( ).
        alv->get_columns( )->get_column( 'STEP' )->set_medium_text( CONV #( TEXT-c11 ) ).
        alv->get_columns( )->get_column( 'TEXT' )->set_medium_text( CONV #( TEXT-c12 ) ).
        alv->set_screen_popup( start_column = 5
                               end_column   = 150
                               start_line   = 3
                               end_line     = 14 ).
        alv->display( ).
      CATCH cx_salv_msg cx_salv_not_found INTO DATA(failure).
        MESSAGE failure TYPE 'S' DISPLAY LIKE 'E'.
    ENDTRY.
  ENDMETHOD.


  METHOD open_atc.
    TRY.
        CALL TRANSACTION atc_transaction WITH AUTHORITY-CHECK.
      CATCH cx_sy_authorization_error.
        MESSAGE TEXT-e07 TYPE 'S' DISPLAY LIKE 'E'.
    ENDTRY.
  ENDMETHOD.

ENDCLASS.

*&----------------------------------------------------------------------*
*&CLASS lcl_alv IMPLEMENTATION
*&----------------------------------------------------------------------*
CLASS lcl_alv IMPLEMENTATION.

  METHOD display.
    rows = assessments.
    TRY.
        cl_salv_table=>factory( IMPORTING r_salv_table = DATA(alv)
                                CHANGING  t_table      = rows ).
        alv->get_functions( )->set_all( ).
        alv->get_columns( )->set_optimize( ).
        name_columns( alv->get_columns( ) ).
        alv->set_top_of_list( list_header( run      = run
                                           data_set = data_set ) ).
        alv->display( ).
      CATCH cx_salv_msg INTO DATA(failure).
        MESSAGE failure TYPE 'S' DISPLAY LIKE 'E'.
    ENDTRY.
  ENDMETHOD.


  METHOD name_columns.
    " the assessment has own types without dictionary texts, so every column is named here
    DATA(texts) = VALUE column_texts( ( name = 'OBJECT_TYPE' text = TEXT-c01 )
                                      ( name = 'OBJECT_NAME' text = TEXT-c02 )
                                      ( name = 'LEVEL'       text = TEXT-c03 )
                                      ( name = 'FINDINGS_B'  text = TEXT-c04 )
                                      ( name = 'FINDINGS_C'  text = TEXT-c05 )
                                      ( name = 'FINDINGS_D'  text = TEXT-c06 )
                                      ( name = 'USAGE_STATE' text = TEXT-c07 )
                                      ( name = 'EXECUTIONS'  text = TEXT-c08 )
                                      ( name = 'LAST_USED'   text = TEXT-c09 )
                                      ( name = 'PROPOSAL'    text = TEXT-c10 ) ).
    LOOP AT texts INTO DATA(text).
      TRY.
          DATA(column) = columns->get_column( text-name ).
          column->set_short_text( CONV #( text-text ) ).
          column->set_medium_text( text-text ).
          column->set_long_text( CONV #( text-text ) ).
        CATCH cx_salv_not_found.
          " a column that is not in the list needs no name
          CONTINUE.
      ENDTRY.
    ENDLOOP.
  ENDMETHOD.


  METHOD list_header.
    result = NEW cl_salv_form_layout_grid( ).
    result->create_label( row    = 1
                          column = 1
                          text   = TEXT-h01 ).
    result->create_text( row    = 1
                         column = 2
                         text   = |{ run-title } ({ run-run_series } { run-result_id })| ).
    result->create_label( row    = 2
                          column = 1
                          text   = TEXT-h02 ).
    result->create_text( row    = 2
                         column = 2
                         text   = |{ data_set-description }: { data_set-date_from DATE = USER } - |
                               && |{ data_set-date_to DATE = USER }, { data_set-days_available } days| ).
  ENDMETHOD.

ENDCLASS.

*&----------------------------------------------------------------------*
*&CLASS lcl_application IMPLEMENTATION
*&----------------------------------------------------------------------*
CLASS lcl_application IMPLEMENTATION.

  METHOD constructor.
    me->selection = selection.
    atc_reader    = NEW zcl_ccr_atc_reader( ).
    usage_reader  = NEW zcl_ccr_usage_reader( ).
  ENDMETHOD.


  METHOD run.
    IF selection-run_id IS INITIAL OR selection-packages IS INITIAL OR selection-usage_id IS INITIAL.
      MESSAGE TEXT-e06 TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    DATA(atc_run) = chosen_run( ).
    IF atc_run IS INITIAL.
      MESSAGE TEXT-e01 TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    DATA(data_set) = chosen_data_set( ).
    IF data_set IS INITIAL.
      MESSAGE TEXT-e02 TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    DATA(assessments) = assess( result_id = atc_run-result_id
                                usage_id  = data_set-usage_id ).
    IF assessments IS INITIAL.
      MESSAGE TEXT-e03 TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    NEW lcl_alv( )->display( assessments = assessments
                             run         = atc_run
                             data_set    = data_set ).
  ENDMETHOD.


  METHOD chosen_run.
    DATA result_id TYPE satc_d_result_id.

    " the screen holds the ID as 32 hex characters
    result_id = selection-run_id.
    DATA(runs) = atc_reader->runs( selection-check_variant ).
    result = VALUE #( runs[ result_id = result_id ] OPTIONAL ).
  ENDMETHOD.


  METHOD chosen_data_set.
    DATA usage_id TYPE susg_admin-usgid.

    usage_id = selection-usage_id.
    DATA(data_sets) = usage_reader->data_sets( ).
    result = VALUE #( data_sets[ usage_id = usage_id ] OPTIONAL ).
  ENDMETHOD.


  METHOD assess.
    " the packages and object types on the screen are the scope; the classifier leaves out
    " findings of objects outside it, and without objects there is nothing to assess
    DATA(objects) = atc_reader->objects( packages     = selection-packages
                                         object_types = selection-object_types ).
    IF objects IS INITIAL.
      RETURN.
    ENDIF.
    DATA(findings) = atc_reader->findings( result_id ).

    DATA(classifier) = CAST zif_ccr_classifier( NEW zcl_ccr_classifier( NEW zcl_ccr_level_rules( ) ) ).
    DATA(object_levels) = classifier->classify( findings = findings
                                                objects  = objects ).

    " usage is read for every classified object: one missing here would count as not used
    DATA(assessor) = CAST zif_ccr_assessor( NEW zcl_ccr_assessor( ) ).
    result = assessor->assess( object_levels = object_levels
                               usages        = usage_reader->usages( usage_id = usage_id
                                                                     objects  = CORRESPONDING #( object_levels ) ) ).
  ENDMETHOD.

ENDCLASS.
