*###################################################################*
*#-----------------------------------------------------------------#*
*#      |\\/\\//\|        -----------------------------------      #*
*#      |        |       /      Report: Z_CCR_PROBE          \     #*
*#      |  (*) (*)      /                                     \    #*
*#      |       __)    /        Version: 1.1 ()                \   #*
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
*& Description    : Result key RAW(16) compared as host variable; FOR  *
*&                  variable of NOTE_CONDITION renamed, NOTE is the one*
*&                  of START-OF-SELECTION                              *
*& Author         : George Drakos                                      *
*& Date           : 26/11/2026                                         *
*& Change Request :                                                    *
*&--------------------------------------------------------------------&*
REPORT z_ccr_probe.
*&---------------------------------------------------------------------*
*& GLOBAL DATA DECLARATION
*&---------------------------------------------------------------------*
DATA note_number TYPE n LENGTH 10.

*&----------------------------------------------------------------------*
*&INTERFACE lif_probe
*&----------------------------------------------------------------------*
INTERFACE lif_probe.
  METHODS run.
ENDINTERFACE.

*&----------------------------------------------------------------------*
*&CLASS lcl_output DEFINITION
*&----------------------------------------------------------------------*
"! Collects the result lines of the probes and hands them out as ALV list and as text file.
CLASS lcl_output DEFINITION FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    CONSTANTS: BEGIN OF label,
                 failure   TYPE c LENGTH 20 VALUE 'ERROR',
                 missing   TYPE c LENGTH 20 VALUE 'NOT FOUND',
                 row_count TYPE c LENGTH 20 VALUE 'ROW COUNT',
               END OF label.

    METHODS constructor
      IMPORTING masks_users TYPE abap_bool.

    METHODS begin_section
      IMPORTING section TYPE csequence.

    METHODS add
      IMPORTING subject TYPE csequence
                item    TYPE csequence OPTIONAL
                content TYPE csequence OPTIONAL.

    "! Adds the texts of an exception and of every exception it was raised from.
    METHODS add_failure
      IMPORTING subject TYPE csequence
                failure TYPE REF TO cx_root.

    "! Adds one line per table row - the filled columns as NAME=value.
    METHODS add_rows
      IMPORTING subject  TYPE csequence
                rows     TYPE ANY TABLE
                max_rows TYPE i.

    METHODS display.

    METHODS download
      IMPORTING path TYPE string.

  PRIVATE SECTION.
    TYPES: BEGIN OF result_line,
             line_number TYPE i,
             section     TYPE c LENGTH 20,
             subject     TYPE c LENGTH 80,
             item        TYPE c LENGTH 60,
             content     TYPE string,
           END OF result_line.
    TYPES result_lines TYPE STANDARD TABLE OF result_line WITH EMPTY KEY.
    TYPES: BEGIN OF list_line,
             line_number TYPE i,
             section     TYPE c LENGTH 20,
             subject     TYPE c LENGTH 80,
             item        TYPE c LENGTH 60,
             content     TYPE c LENGTH 255,
           END OF list_line.
    TYPES list_lines TYPE STANDARD TABLE OF list_line WITH EMPTY KEY.

    CONSTANTS: BEGIN OF column_title,
                 line_number TYPE c LENGTH 10 VALUE 'Line',
                 section     TYPE c LENGTH 10 VALUE 'Section',
                 subject     TYPE c LENGTH 10 VALUE 'Subject',
                 item        TYPE c LENGTH 10 VALUE 'Item',
                 content     TYPE c LENGTH 10 VALUE 'Content',
               END OF column_title.
    CONSTANTS: BEGIN OF marker,
                 masked    TYPE c LENGTH 3 VALUE '***',
                 nested    TYPE c LENGTH 8 VALUE '<nested>',
                 shortened TYPE c LENGTH 3 VALUE '...',
               END OF marker.
    CONSTANTS max_value_length TYPE i VALUE 120.
    "! A row with up to this many columns is shown in full, initial values included.
    CONSTANTS full_row_width TYPE i VALUE 4.
    CONSTANTS user_field_pattern TYPE string VALUE `USER|UNAME|AUTHOR|OWNER|CONTACT|RESPONS|BY$`.
    CONSTANTS line_break_pattern TYPE string VALUE `[\t\r\n]`.
    CONSTANTS text_file_type TYPE c LENGTH 3 VALUE 'ASC'.
    CONSTANTS utf8_codepage TYPE c LENGTH 4 VALUE '4110'.

    DATA masks_users TYPE abap_bool.
    DATA current_section TYPE string.
    DATA collected TYPE result_lines.

    METHODS row_text
      IMPORTING row           TYPE any
      RETURNING VALUE(result) TYPE string.

    METHODS value_text
      IMPORTING name          TYPE csequence
                value         TYPE any
      RETURNING VALUE(result) TYPE string.

    METHODS title_column
      IMPORTING columns TYPE REF TO cl_salv_columns_table
                name    TYPE csequence
                title   TYPE csequence.

ENDCLASS.

*&----------------------------------------------------------------------*
*&CLASS lcl_catalog DEFINITION
*&----------------------------------------------------------------------*
"! Reads the repository directory, the DDIC and RTTI metadata and data samples by name -
"! nothing it reads is referenced statically, so a name that does not exist is a result line.
CLASS lcl_catalog DEFINITION FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES name_range TYPE RANGE OF tadir-obj_name.
    TYPES type_range TYPE RANGE OF tadir-object.
    TYPES package_range TYPE RANGE OF tadir-devclass.
    TYPES: BEGIN OF object_filter,
             names        TYPE name_range,
             object_types TYPE type_range,
             packages     TYPE package_range,
           END OF object_filter.
    TYPES: BEGIN OF data_query,
             subject    TYPE string,
             source     TYPE string,
             field_list TYPE string,
             condition  TYPE string,
             sort_order TYPE string,
             max_rows   TYPE i,
           END OF data_query.
    TYPES: BEGIN OF row_filter,
             key_fields TYPE string_table,
             key_value  TYPE string,
           END OF row_filter.

    CLASS-METHODS names_like
      IMPORTING patterns      TYPE string_table
      RETURNING VALUE(result) TYPE name_range.

    CLASS-METHODS types_of
      IMPORTING object_types  TYPE string_table
      RETURNING VALUE(result) TYPE type_range.

    CLASS-METHODS packages_like
      IMPORTING patterns      TYPE string_table
      RETURNING VALUE(result) TYPE package_range.

    METHODS constructor
      IMPORTING output      TYPE REF TO lcl_output
                sample_size TYPE i.

    "! Lists the repository objects (TADIR) the filter selects.
    METHODS list_objects
      IMPORTING filter TYPE object_filter.

    METHODS object_names
      IMPORTING filter        TYPE object_filter
      RETURNING VALUE(result) TYPE string_table.

    "! Runs a dynamic SELECT and adds its rows; a failing statement becomes an error line.
    METHODS run_query
      IMPORTING query TYPE data_query.

    "! Fields, row count, newest sample rows and value distribution of a table, view or CDS entity.
    METHODS explore_source
      IMPORTING source TYPE csequence
                filter TYPE row_filter OPTIONAL.

    "! Public methods of a class or interface with their parameters and the structure of their types.
    METHODS describe_api
      IMPORTING class_name TYPE csequence.

    METHODS object_descriptor
      IMPORTING name          TYPE csequence
      RETURNING VALUE(result) TYPE REF TO cl_abap_objectdescr.

  PRIVATE SECTION.
    TYPES: BEGIN OF repository_object,
             object   TYPE tadir-object,
             obj_name TYPE tadir-obj_name,
             devclass TYPE tadir-devclass,
           END OF repository_object.
    TYPES repository_objects TYPE STANDARD TABLE OF repository_object WITH EMPTY KEY.
    TYPES type_names TYPE SORTED TABLE OF abap_abstypename WITH UNIQUE KEY table_line.

    CONSTANTS: BEGIN OF range_token,
                 including TYPE c LENGTH 1 VALUE 'I',
                 equal     TYPE c LENGTH 2 VALUE 'EQ',
                 pattern   TYPE c LENGTH 2 VALUE 'CP',
               END OF range_token.
    CONSTANTS whole_object TYPE tadir-pgmid VALUE 'R3TR'.
    CONSTANTS max_objects TYPE i VALUE 1000.
    CONSTANTS max_groups TYPE i VALUE 60.
    CONSTANTS not_selectable TYPE i VALUE -1.
    CONSTANTS all_fields TYPE string VALUE `*`.
    CONSTANTS count_column TYPE string VALUE `ROW_COUNT`.
    CONSTANTS english TYPE sylangu VALUE 'E'.
    CONSTANTS character_type TYPE c LENGTH 4 VALUE 'CHAR'.
    CONSTANTS raw_type TYPE c LENGTH 4 VALUE 'RAW'.
    CONSTANTS raw_key_length TYPE i VALUE 16.
    CONSTANTS groupable_types TYPE string VALUE `CHAR NUMC INT1 INT2 INT4`.
    CONSTANTS time_field_pattern TYPE string VALUE `_TS$|TIMESTAMP|CHANGED_ON|CREATED_ON|LAST_USED|LASTUSED`.
    CONSTANTS category_field_pattern TYPE string VALUE `TYPE|KIND|PRIO|LEVEL|STATE|STATUS`.

    DATA output TYPE REF TO lcl_output.
    DATA sample_size TYPE i.
    DATA described_types TYPE type_names.
    "! Key value of a RAW(16) key field - the dynamic conditions name it as host variable.
    DATA raw_key TYPE x LENGTH 16.

    METHODS select_objects
      IMPORTING filter        TYPE object_filter
      RETURNING VALUE(result) TYPE repository_objects.

    METHODS describe_source
      IMPORTING source        TYPE csequence
      RETURNING VALUE(result) TYPE ddfields.

    METHODS key_condition
      IMPORTING fields        TYPE ddfields
                filter        TYPE row_filter
      RETURNING VALUE(result) TYPE string.

    METHODS newest_first
      IMPORTING fields        TYPE ddfields
      RETURNING VALUE(result) TYPE string.

    METHODS count_rows
      IMPORTING query         TYPE data_query
      RETURNING VALUE(result) TYPE i.

    METHODS count_by_categories
      IMPORTING fields TYPE ddfields
                sample TYPE data_query.

    METHODS count_by_field
      IMPORTING field  TYPE csequence
                sample TYPE data_query.

    METHODS describe_parameter
      IMPORTING object_type TYPE REF TO cl_abap_objectdescr
                signature   TYPE abap_methdescr
                parameter   TYPE abap_parmdescr.

    METHODS describe_type
      IMPORTING data_type TYPE REF TO cl_abap_datadescr.

ENDCLASS.

*&----------------------------------------------------------------------*
*&CLASS lcl_release_probe DEFINITION
*&----------------------------------------------------------------------*
"! Question c: software component releases and the status of the clean core SAP Notes.
CLASS lcl_release_probe DEFINITION FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES lif_probe.

    METHODS constructor
      IMPORTING output  TYPE REF TO lcl_output
                catalog TYPE REF TO lcl_catalog
                notes   TYPE string_table.

  PRIVATE SECTION.
    CONSTANTS section_name TYPE string VALUE `C RELEASE`.
    CONSTANTS system_subject TYPE string VALUE `SYSTEM`.
    CONSTANTS max_rows TYPE i VALUE 100.

    DATA output TYPE REF TO lcl_output.
    DATA catalog TYPE REF TO lcl_catalog.
    DATA notes TYPE string_table.

    METHODS note_condition
      RETURNING VALUE(result) TYPE string.

ENDCLASS.

*&----------------------------------------------------------------------*
*&CLASS lcl_atc_probe DEFINITION
*&----------------------------------------------------------------------*
"! Question a: how the results of an ATC run are read and where the clean core level shows.
CLASS lcl_atc_probe DEFINITION FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES lif_probe.

    TYPES: BEGIN OF atc_settings,
             result_id      TYPE string,
             reads_messages TYPE abap_bool,
             sample_size    TYPE i,
           END OF atc_settings.

    METHODS constructor
      IMPORTING output   TYPE REF TO lcl_output
                catalog  TYPE REF TO lcl_catalog
                settings TYPE atc_settings.

  PRIVATE SECTION.
    TYPES: BEGIN OF check_count,
             check_id TYPE string,
             findings TYPE i,
           END OF check_count.
    TYPES check_counts TYPE SORTED TABLE OF check_count WITH UNIQUE KEY check_id.
    TYPES check_classes TYPE SORTED TABLE OF string WITH UNIQUE KEY table_line.

    CONSTANTS: BEGIN OF api,
                 factory        TYPE c LENGTH 30 VALUE 'CL_SATC_API_FACTORY',
                 create_access  TYPE c LENGTH 30 VALUE 'CREATE_RESULT_ACCESS',
                 get_findings   TYPE c LENGTH 30 VALUE 'GET_FINDINGS',
                 check_class    TYPE c LENGTH 30 VALUE 'TEST',
                 check_messages TYPE c LENGTH 30 VALUE 'SCIMESSAGES',
               END OF api.
    CONSTANTS section_name TYPE string VALUE `A ATC`.
    CONSTANTS findings_subject TYPE string VALUE `API FINDINGS`.
    CONSTANTS check_field_pattern TYPE string VALUE `^(TEST|CODE|KIND)$|PRIO|LEVEL`.
    CONSTANTS max_apis TYPE i VALUE 40.
    CONSTANTS max_dictionary_rows TYPE i VALUE 200.
    CONSTANTS max_check_classes TYPE i VALUE 12.
    CONSTANTS max_check_counts TYPE i VALUE 200.
    CONSTANTS max_messages TYPE i VALUE 80.

    DATA output TYPE REF TO lcl_output.
    DATA catalog TYPE REF TO lcl_catalog.
    DATA settings TYPE atc_settings.

    METHODS list_repository_objects.
    METHODS search_dictionary.
    METHODS describe_apis.
    METHODS explore_results.
    METHODS sample_api_findings.

    METHODS call_with_result_id
      IMPORTING target        TYPE REF TO object
                target_type   TYPE REF TO cl_abap_objectdescr
                method_name   TYPE csequence
      RETURNING VALUE(result) TYPE abap_parmbind_tab
      RAISING   cx_static_check.

    METHODS find_method
      IMPORTING target_type   TYPE REF TO cl_abap_objectdescr
                method_name   TYPE csequence
      RETURNING VALUE(result) TYPE abap_methdescr.

    METHODS binding_of
      IMPORTING target_type   TYPE REF TO cl_abap_objectdescr
                signature     TYPE abap_methdescr
                parameter     TYPE abap_parmdescr
      RETURNING VALUE(result) TYPE abap_parmbind.

    METHODS report_findings
      IMPORTING bindings TYPE abap_parmbind_tab.

    METHODS count_by_check
      IMPORTING findings TYPE ANY TABLE.

    METHODS check_id_of
      IMPORTING finding       TYPE any
      RETURNING VALUE(result) TYPE string.

    METHODS report_check_messages
      IMPORTING findings TYPE ANY TABLE.

    METHODS report_messages_of
      IMPORTING check_class TYPE csequence.

ENDCLASS.

*&----------------------------------------------------------------------*
*&CLASS lcl_usage_probe DEFINITION
*&----------------------------------------------------------------------*
"! Question b: how the aggregated usage data of SUSG is read and at which level it is kept.
CLASS lcl_usage_probe DEFINITION FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES lif_probe.

    METHODS constructor
      IMPORTING output  TYPE REF TO lcl_output
                catalog TYPE REF TO lcl_catalog.

  PRIVATE SECTION.
    CONSTANTS section_name TYPE string VALUE `B SUSG`.
    CONSTANTS max_apis TYPE i VALUE 40.
    CONSTANTS max_function_rows TYPE i VALUE 600.

    DATA output TYPE REF TO lcl_output.
    DATA catalog TYPE REF TO lcl_catalog.

    METHODS list_repository_objects.
    METHODS describe_function_modules.
    METHODS describe_apis.
    METHODS explore_usage_data.

ENDCLASS.

*&----------------------------------------------------------------------*
*&CLASS lcl_application DEFINITION
*&----------------------------------------------------------------------*
"! Composition root of the program: wires the probes the selection screen asks for and runs them.
CLASS lcl_application DEFINITION FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES: BEGIN OF screen_selection,
             probes_release TYPE abap_bool,
             notes          TYPE string_table,
             probes_atc     TYPE abap_bool,
             result_id      TYPE string,
             reads_messages TYPE abap_bool,
             probes_usage   TYPE abap_bool,
             sample_size    TYPE i,
             masks_users    TYPE abap_bool,
             file_path      TYPE string,
           END OF screen_selection.

    CLASS-METHODS label_screen.

    CLASS-METHODS ask_file_path
      RETURNING VALUE(result) TYPE string.

    METHODS constructor
      IMPORTING selection TYPE screen_selection.

    METHODS run.

  PRIVATE SECTION.
    TYPES probes TYPE STANDARD TABLE OF REF TO lif_probe WITH EMPTY KEY.

    CONSTANTS probe_subject TYPE string VALUE `PROBE`.
    CONSTANTS default_file_name TYPE string VALUE `z_ccr_probe.txt`.
    CONSTANTS default_extension TYPE string VALUE `txt`.
    CONSTANTS default_sample_size TYPE i VALUE 20.

    DATA selection TYPE screen_selection.

    METHODS selected_probes
      IMPORTING output        TYPE REF TO lcl_output
                catalog       TYPE REF TO lcl_catalog
      RETURNING VALUE(result) TYPE probes.

ENDCLASS.

*&---------------------------------------------------------------------*
*& SELECTION SCREEN DESIGN
*&---------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK sc_batc WITH FRAME TITLE sc_tatc.
SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS p_atc AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN COMMENT 3(66) sc_catc FOR FIELD p_atc.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN COMMENT /1(70) sc_cres.
PARAMETERS p_resid TYPE c LENGTH 32.
SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS p_msgs AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN COMMENT 3(66) sc_cmsg FOR FIELD p_msgs.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN END OF BLOCK sc_batc.

SELECTION-SCREEN BEGIN OF BLOCK sc_busg WITH FRAME TITLE sc_tusg.
SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS p_susg AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN COMMENT 3(66) sc_cusg FOR FIELD p_susg.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN END OF BLOCK sc_busg.

SELECTION-SCREEN BEGIN OF BLOCK sc_brel WITH FRAME TITLE sc_trel.
SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS p_rel AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN COMMENT 3(66) sc_crel FOR FIELD p_rel.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN COMMENT /1(70) sc_cnote.
SELECT-OPTIONS s_note FOR note_number NO INTERVALS.
SELECTION-SCREEN END OF BLOCK sc_brel.

SELECTION-SCREEN BEGIN OF BLOCK sc_bout WITH FRAME TITLE sc_tout.
SELECTION-SCREEN COMMENT /1(70) sc_crows.
PARAMETERS p_rows TYPE i DEFAULT 20.
SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS p_mask AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN COMMENT 3(66) sc_cmask FOR FIELD p_mask.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN COMMENT /1(70) sc_cfile.
PARAMETERS p_file TYPE string LOWER CASE.
SELECTION-SCREEN END OF BLOCK sc_bout.

*&---------------------------------------------------------------------*
*& INITIALIZATION OF SELECTION SCREEN ELEMENTS
*&---------------------------------------------------------------------*
INITIALIZATION.
  lcl_application=>label_screen( ).

*&---------------------------------------------------------------------*
*& AT SELECTION SCREEN ON VALUE REQUESTS (F4)
*&---------------------------------------------------------------------*
AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_file.
  p_file = lcl_application=>ask_file_path( ).

*&---------------------------------------------------------------------*
*& EXECUTABLE CODE
*&---------------------------------------------------------------------*
START-OF-SELECTION.
  NEW lcl_application( VALUE #( probes_release = p_rel
                                notes          = VALUE #( FOR note IN s_note[] ( CONV #( note-low ) ) )
                                probes_atc     = p_atc
                                result_id      = p_resid
                                reads_messages = p_msgs
                                probes_usage   = p_susg
                                sample_size    = p_rows
                                masks_users    = p_mask
                                file_path      = p_file )
    )->run( ).
*&---------------------------------------------------------------------*
*& END OF EXECUTABLE CODE
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& START OF CLASS IMPLEMENTATION
*&---------------------------------------------------------------------*

*&----------------------------------------------------------------------*
*&CLASS lcl_output IMPLEMENTATION
*&----------------------------------------------------------------------*
CLASS lcl_output IMPLEMENTATION.

  METHOD constructor.
    me->masks_users = masks_users.
  ENDMETHOD.

  METHOD begin_section.
    current_section = section.
  ENDMETHOD.

  METHOD add.
    INSERT VALUE #( line_number = lines( collected ) + 1
                    section     = current_section
                    subject     = subject
                    item        = item
                    content     = content ) INTO TABLE collected.
  ENDMETHOD.

  METHOD add_failure.
    DATA(texts) = ``.
    DATA(cause) = failure.
    WHILE cause IS BOUND.
      texts = |{ texts }{ cl_abap_classdescr=>get_class_name( cause ) }: { cause->get_text( ) } \| |.
      cause = cause->previous.
    ENDWHILE.
    add( subject = subject
         item    = label-failure
         content = texts ).
  ENDMETHOD.

  METHOD add_rows.
    DATA(row_number) = 0.
    LOOP AT rows ASSIGNING FIELD-SYMBOL(<row>).
      row_number = row_number + 1.
      IF row_number > max_rows.
        EXIT.
      ENDIF.
      add( subject = subject
           item    = |row { row_number }|
           content = row_text( <row> ) ).
    ENDLOOP.
  ENDMETHOD.

  METHOD row_text.
    DATA(row_type) = cl_abap_typedescr=>describe_by_data( row ).
    IF row_type->kind <> cl_abap_typedescr=>kind_struct.
      result = value_text( name  = ``
                           value = row ).
      RETURN.
    ENDIF.

    DATA(components) = CAST cl_abap_structdescr( row_type )->components.
    LOOP AT components REFERENCE INTO DATA(component).
      ASSIGN COMPONENT component->name OF STRUCTURE row TO FIELD-SYMBOL(<value>).
      IF sy-subrc <> 0 OR ( <value> IS INITIAL AND lines( components ) > full_row_width ).
        CONTINUE.
      ENDIF.
      DATA(text) = value_text( name  = component->name
                               value = <value> ).
      result = |{ result }{ component->name }={ text } \| |.
    ENDLOOP.
  ENDMETHOD.

  METHOD value_text.
    IF masks_users = abap_true AND contains( val  = to_upper( name )
                                             pcre = user_field_pattern ).
      result = marker-masked.
      RETURN.
    ENDIF.

    IF cl_abap_typedescr=>describe_by_data( value )->kind <> cl_abap_typedescr=>kind_elem.
      " a structure, table or reference has no text of its own
      result = marker-nested.
      RETURN.
    ENDIF.

    result = |{ value }|.
    IF strlen( result ) > max_value_length.
      DATA(beginning) = substring( val = result
                                   len = max_value_length ).
      result = |{ beginning }{ marker-shortened }|.
    ENDIF.
  ENDMETHOD.

  METHOD display.
    DATA(list) = CORRESPONDING list_lines( collected ).
    TRY.
        cl_salv_table=>factory( IMPORTING r_salv_table = DATA(alv)
                                CHANGING  t_table      = list ).
        alv->get_functions( )->set_all( ).
        DATA(columns) = alv->get_columns( ).
        columns->set_optimize( ).
        DATA(titles) = CAST cl_abap_structdescr( cl_abap_typedescr=>describe_by_data( column_title ) ).
        LOOP AT titles->components REFERENCE INTO DATA(component).
          ASSIGN COMPONENT component->name OF STRUCTURE column_title TO FIELD-SYMBOL(<title>).
          IF sy-subrc = 0.
            title_column( columns = columns
                          name    = component->name
                          title   = <title> ).
          ENDIF.
        ENDLOOP.
        alv->display( ).
      CATCH cx_salv_msg INTO DATA(failure).
        MESSAGE failure TYPE 'S' DISPLAY LIKE 'E'.
    ENDTRY.
  ENDMETHOD.

  METHOD title_column.
    TRY.
        DATA(column) = columns->get_column( CONV #( name ) ).
        column->set_short_text( CONV #( title ) ).
        column->set_medium_text( CONV #( title ) ).
        column->set_long_text( CONV #( title ) ).
      CATCH cx_salv_not_found.
        " the list is shown with the technical column name
        RETURN.
    ENDTRY.
  ENDMETHOD.

  METHOD download.
    DATA(tab) = cl_abap_char_utilities=>horizontal_tab.
    DATA(file_lines) = VALUE string_table(
      FOR line IN collected
      ( |{ line-line_number }{ tab }{ line-section }{ tab }{ line-subject }{ tab }{ line-item }{ tab }| &&
        replace( val  = line-content
                 pcre = line_break_pattern
                 with = ` `
                 occ  = 0 ) ) ).

    cl_gui_frontend_services=>gui_download( EXPORTING  filename = path
                                                       filetype = CONV #( text_file_type )
                                                       codepage = CONV #( utf8_codepage )
                                            CHANGING   data_tab = file_lines
                                            EXCEPTIONS OTHERS   = 1 ).
    IF sy-subrc <> 0.
      MESSAGE |File { path } could not be written - export the list from the ALV toolbar instead| TYPE 'S'
              DISPLAY LIKE 'E'.
    ENDIF.
  ENDMETHOD.

ENDCLASS.

*&----------------------------------------------------------------------*
*&CLASS lcl_catalog IMPLEMENTATION
*&----------------------------------------------------------------------*
CLASS lcl_catalog IMPLEMENTATION.

  METHOD names_like.
    result = VALUE #( FOR pattern IN patterns
                      ( sign   = range_token-including
                        option = range_token-pattern
                        low    = pattern ) ).
  ENDMETHOD.

  METHOD types_of.
    result = VALUE #( FOR object_type IN object_types
                      ( sign   = range_token-including
                        option = range_token-equal
                        low    = object_type ) ).
  ENDMETHOD.

  METHOD packages_like.
    result = VALUE #( FOR pattern IN patterns
                      ( sign   = range_token-including
                        option = range_token-pattern
                        low    = pattern ) ).
  ENDMETHOD.

  METHOD constructor.
    me->output      = output.
    me->sample_size = sample_size.
  ENDMETHOD.

  METHOD list_objects.
    DATA(objects) = select_objects( filter ).
    LOOP AT objects REFERENCE INTO DATA(object).
      output->add( subject = |TADIR { object->object }|
                   item    = object->obj_name
                   content = |package { object->devclass }| ).
    ENDLOOP.
    IF objects IS INITIAL.
      output->add( subject = `TADIR`
                   item    = lcl_output=>label-missing ).
    ENDIF.
  ENDMETHOD.

  METHOD object_names.
    result = VALUE #( FOR object IN select_objects( filter )
                      ( CONV #( object-obj_name ) ) ).
  ENDMETHOD.

  METHOD select_objects.
    IF filter IS INITIAL.
      RETURN.
    ENDIF.

    SELECT FROM tadir
      FIELDS object, obj_name, devclass
      WHERE pgmid     = @whole_object
        AND object   IN @filter-object_types
        AND obj_name IN @filter-names
        AND devclass IN @filter-packages
      ORDER BY object, obj_name
      INTO TABLE @result
      UP TO @max_objects ROWS.
  ENDMETHOD.

  METHOD run_query.
    DATA rows TYPE REF TO data.
    FIELD-SYMBOLS <rows> TYPE STANDARD TABLE.

    DATA(max_rows) = COND i( WHEN query-max_rows > 0 THEN query-max_rows ELSE sample_size ).
    TRY.
        CREATE DATA rows TYPE STANDARD TABLE OF (query-source) WITH EMPTY KEY.
        ASSIGN rows->* TO <rows>.
        SELECT FROM (query-source)
          FIELDS (query-field_list)
          WHERE (query-condition)
          ORDER BY (query-sort_order)
          INTO CORRESPONDING FIELDS OF TABLE @<rows>
          UP TO @max_rows ROWS.
        output->add_rows( subject  = query-subject
                          rows     = <rows>
                          max_rows = max_rows ).
      CATCH cx_sy_create_data_error cx_sy_dynamic_osql_error cx_sy_open_sql_db INTO DATA(failure).
        output->add_failure( subject = query-subject
                             failure = failure ).
        IF query-sort_order IS NOT INITIAL.
          run_query( VALUE #( BASE query
                              sort_order = `` ) ).
        ENDIF.
    ENDTRY.
  ENDMETHOD.

  METHOD explore_source.
    DATA(fields) = describe_source( source ).
    IF fields IS INITIAL.
      RETURN.
    ENDIF.

    DATA(sample) = VALUE data_query( subject    = source
                                     source     = source
                                     field_list = all_fields
                                     condition  = key_condition( fields = fields
                                                                 filter = filter )
                                     sort_order = newest_first( fields ) ).
    DATA(row_count) = count_rows( sample ).
    IF row_count = 0 AND sample-condition IS NOT INITIAL.
      " the source is not keyed by the given value, or holds nothing for it: sample it as a whole
      CLEAR sample-condition.
      row_count = count_rows( sample ).
    ENDIF.
    IF row_count <= 0.
      RETURN.
    ENDIF.

    run_query( sample ).
    count_by_categories( fields = fields
                         sample = sample ).
  ENDMETHOD.

  METHOD describe_source.
    DATA source_type TYPE REF TO cl_abap_typedescr.

    cl_abap_typedescr=>describe_by_name( EXPORTING  p_name      = source
                                         RECEIVING  p_descr_ref = source_type
                                         EXCEPTIONS OTHERS      = 1 ).
    IF sy-subrc <> 0 OR source_type->kind <> cl_abap_typedescr=>kind_struct.
      output->add( subject = source
                   item    = lcl_output=>label-missing
                   content = `no structured dictionary type of this name` ).
      RETURN.
    ENDIF.

    DATA(structure) = CAST cl_abap_structdescr( source_type ).
    structure->get_ddic_field_list( EXPORTING  p_langu      = english
                                    RECEIVING  p_field_list = result
                                    EXCEPTIONS OTHERS       = 1 ).
    IF sy-subrc <> 0.
      result = VALUE #( FOR component IN structure->components
                        ( fieldname = component-name ) ).
    ENDIF.

    LOOP AT result REFERENCE INTO DATA(field).
      output->add(
        subject = source
        item    = |field { field->fieldname }|
        content = |key={ field->keyflag } element={ field->rollname } type={ field->datatype }| &&
                  |({ CONV i( field->leng ) }) text={ field->fieldtext }| ).
    ENDLOOP.
  ENDMETHOD.

  METHOD key_condition.
    IF filter-key_value IS INITIAL.
      RETURN.
    ENDIF.

    LOOP AT filter-key_fields INTO DATA(key_field).
      DATA(field) = VALUE dfies( fields[ fieldname = key_field ] OPTIONAL ).
      IF field-datatype = character_type.
        result = |{ key_field } = { cl_abap_dyn_prg=>quote( filter-key_value ) }|.
        RETURN.
      ENDIF.
      IF field-datatype = raw_type AND CONV i( field-leng ) = raw_key_length.
        " a GUID key is compared through a host variable: a text literal has no RAW type
        raw_key = filter-key_value.
        result = |{ key_field } = @RAW_KEY|.
        RETURN.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD newest_first.
    LOOP AT fields REFERENCE INTO DATA(field).
      IF contains( val  = to_upper( field->fieldname )
                   pcre = time_field_pattern ).
        result = |{ field->fieldname } DESCENDING|.
        RETURN.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD count_rows.
    TRY.
        SELECT FROM (query-source)
          FIELDS COUNT(*)
          WHERE (query-condition)
          INTO @result.
        output->add( subject = query-source
                     item    = lcl_output=>label-row_count
                     content = |{ result } rows where [{ query-condition }]| ).
      CATCH cx_sy_dynamic_osql_error cx_sy_open_sql_db INTO DATA(failure).
        result = not_selectable.
        output->add_failure( subject = query-source
                             failure = failure ).
    ENDTRY.
  ENDMETHOD.

  METHOD count_by_categories.
    LOOP AT fields REFERENCE INTO DATA(field).
      IF field->datatype IS NOT INITIAL
         AND groupable_types CS field->datatype
         AND contains( val  = to_upper( field->fieldname )
                       pcre = category_field_pattern ).
        count_by_field( field  = field->fieldname
                        sample = sample ).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD count_by_field.
    DATA counts TYPE REF TO data.
    DATA field_type TYPE REF TO cl_abap_typedescr.
    FIELD-SYMBOLS <counts> TYPE STANDARD TABLE.

    cl_abap_typedescr=>describe_by_name( EXPORTING  p_name      = |{ sample-source }-{ field }|
                                         RECEIVING  p_descr_ref = field_type
                                         EXCEPTIONS OTHERS      = 1 ).
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    DATA(subject) = |{ sample-source } by { field }|.
    DATA(field_list) = |{ field }, COUNT(*) AS { count_column }|.
    TRY.
        DATA(row_type) = cl_abap_structdescr=>create( VALUE #( ( name = field
                                                                 type = CAST #( field_type ) )
                                                               ( name = count_column
                                                                 type = cl_abap_elemdescr=>get_i( ) ) ) ).
        DATA(table_type) = cl_abap_tabledescr=>create( p_line_type = row_type
                                                       p_key_kind  = cl_abap_tabledescr=>keydefkind_empty ).
        CREATE DATA counts TYPE HANDLE table_type.
        ASSIGN counts->* TO <counts>.
        SELECT FROM (sample-source)
          FIELDS (field_list)
          WHERE (sample-condition)
          GROUP BY (field)
          ORDER BY (field)
          INTO CORRESPONDING FIELDS OF TABLE @<counts>
          UP TO @max_groups ROWS.
        output->add_rows( subject  = subject
                          rows     = <counts>
                          max_rows = max_groups ).
      CATCH cx_sy_struct_creation cx_sy_table_creation cx_sy_create_data_error cx_sy_move_cast_error
            cx_sy_dynamic_osql_error cx_sy_open_sql_db INTO DATA(failure).
        output->add_failure( subject = subject
                             failure = failure ).
    ENDTRY.
  ENDMETHOD.

  METHOD describe_api.
    DATA(object_type) = object_descriptor( class_name ).
    IF object_type IS NOT BOUND.
      output->add( subject = class_name
                   item    = lcl_output=>label-missing ).
      RETURN.
    ENDIF.

    LOOP AT object_type->methods REFERENCE INTO DATA(signature)
         WHERE visibility = cl_abap_objectdescr=>public.
      IF signature->parameters IS INITIAL.
        output->add( subject = class_name
                     item    = signature->name
                     content = `no parameters` ).
      ENDIF.
      LOOP AT signature->parameters REFERENCE INTO DATA(parameter).
        describe_parameter( object_type = object_type
                            signature   = signature->*
                            parameter   = parameter->* ).
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

  METHOD object_descriptor.
    DATA descriptor TYPE REF TO cl_abap_typedescr.

    cl_abap_typedescr=>describe_by_name( EXPORTING  p_name      = name
                                         RECEIVING  p_descr_ref = descriptor
                                         EXCEPTIONS OTHERS      = 1 ).
    IF sy-subrc = 0 AND (    descriptor->kind = cl_abap_typedescr=>kind_class
                          OR descriptor->kind = cl_abap_typedescr=>kind_intf ).
      result = CAST #( descriptor ).
    ENDIF.
  ENDMETHOD.

  METHOD describe_parameter.
    DATA parameter_type TYPE REF TO cl_abap_datadescr.

    object_type->get_method_parameter_type( EXPORTING  p_method_name    = signature-name
                                                       p_parameter_name = parameter-name
                                            RECEIVING  p_descr_ref      = parameter_type
                                            EXCEPTIONS OTHERS           = 1 ).
    IF sy-subrc <> 0 OR parameter_type IS NOT BOUND.
      output->add( subject = object_type->get_relative_name( )
                   item    = signature-name
                   content = |{ parameter-parm_kind } { parameter-name } - type not resolved| ).
      RETURN.
    ENDIF.

    output->add(
      subject = object_type->get_relative_name( )
      item    = signature-name
      content = |{ parameter-parm_kind } { parameter-name } TYPE { parameter_type->absolute_name }| &&
                | optional={ parameter-is_optional }| ).
    describe_type( parameter_type ).
  ENDMETHOD.

  METHOD describe_type.
    DATA(line_type) = data_type.
    IF line_type->kind = cl_abap_typedescr=>kind_table.
      line_type = CAST cl_abap_tabledescr( line_type )->get_table_line_type( ).
    ENDIF.
    IF line_type->kind <> cl_abap_typedescr=>kind_struct
       OR line_exists( described_types[ table_line = line_type->absolute_name ] ).
      RETURN.
    ENDIF.

    INSERT line_type->absolute_name INTO TABLE described_types.
    DATA(components) = CAST cl_abap_structdescr( line_type )->get_components( ).
    LOOP AT components REFERENCE INTO DATA(component).
      output->add( subject = line_type->absolute_name
                   item    = |component { component->name }|
                   content = |TYPE { component->type->absolute_name } include={ component->as_include }| ).
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.

*&----------------------------------------------------------------------*
*&CLASS lcl_release_probe IMPLEMENTATION
*&----------------------------------------------------------------------*
CLASS lcl_release_probe IMPLEMENTATION.

  METHOD constructor.
    me->output  = output.
    me->catalog = catalog.
    me->notes   = notes.
  ENDMETHOD.

  METHOD lif_probe~run.
    output->begin_section( section_name ).
    output->add( subject = system_subject
                 item    = `SY-SAPRL`
                 content = sy-saprl ).
    output->add( subject = system_subject
                 item    = `SY-DBSYS`
                 content = sy-dbsys ).

    catalog->run_query(
      VALUE #( subject    = `CVERS`
               source     = `CVERS`
               field_list = `COMPONENT, RELEASE, EXTRELEASE`
               condition  = `COMPONENT IN ( 'SAP_BASIS', 'SAP_ABA', 'S4CORE', 'S4FND', 'SAP_GWFND', 'SAP_UI', ` &&
                            `'ST-PI', 'ST-A/PI' )`
               sort_order = `COMPONENT`
               max_rows   = max_rows ) ).

    IF notes IS NOT INITIAL.
      " a note without a row was never implemented with SNOTE here - its correction can still be
      " part of the release or of a support package
      catalog->run_query( VALUE #( subject    = `CWBNTCUST`
                                   source     = `CWBNTCUST`
                                   field_list = `*`
                                   condition  = note_condition( )
                                   sort_order = `NUMM`
                                   max_rows   = max_rows ) ).
    ENDIF.
  ENDMETHOD.

  METHOD note_condition.
    DATA(quoted) = VALUE string_table( FOR tmp_note IN notes
                                       ( cl_abap_dyn_prg=>quote( tmp_note ) ) ).
    DATA(note_list) = concat_lines_of( table = quoted
                                       sep   = `, ` ).
    result = |NUMM IN ( { note_list } )|.
  ENDMETHOD.

ENDCLASS.

*&----------------------------------------------------------------------*
*&CLASS lcl_atc_probe IMPLEMENTATION
*&----------------------------------------------------------------------*
CLASS lcl_atc_probe IMPLEMENTATION.

  METHOD constructor.
    me->output   = output.
    me->catalog  = catalog.
    me->settings = settings.
  ENDMETHOD.

  METHOD lif_probe~run.
    output->begin_section( section_name ).
    list_repository_objects( ).
    search_dictionary( ).
    describe_apis( ).
    explore_results( ).
    IF settings-result_id IS NOT INITIAL.
      sample_api_findings( ).
    ENDIF.
  ENDMETHOD.

  METHOD list_repository_objects.
    catalog->list_objects(
      VALUE #( names = lcl_catalog=>names_like( VALUE #( ( `CL_SATC_API*` )
                                                         ( `IF_SATC_API*` )
                                                         ( `IF_SATC_RESULT*` )
                                                         ( `CL_SATC_AC_RESULT*` )
                                                         ( `RSATC_API*` )
                                                         ( `SATC_API*` )
                                                         ( `SATC_AC_RESULT*` )
                                                         ( `SATC_AC_RSLT*` )
                                                         ( `*CLEAN_CORE*` )
                                                         ( `*CLEANCORE*` )
                                                         ( `*CLASSIC_API*` )
                                                         ( `ABAP_CLOUD_DEVELOPMENT*` )
                                                         ( `ABAP_CLOUD_READINESS*` )
                                                         ( `SYCM_ALLOWED_ENH*` ) ) ) ) ).
    " every ATC check variant and check category of the system
    catalog->list_objects( VALUE #( object_types = lcl_catalog=>types_of( VALUE #( ( `CHKV` )
                                                                            ( `CHKC` ) ) ) ) ).
    " the package SAP KBA 3781882 names as the home of ABAP_CLEAN_CORE_DEVELOPMENT
    catalog->list_objects( VALUE #( packages = lcl_catalog=>packages_like( VALUE #( ( `SYCM_3TIER*` ) ) ) ) ).
  ENDMETHOD.

  METHOD search_dictionary.
    catalog->run_query(
      VALUE #( subject    = `DD03L clean core fields`
               source     = `DD03L`
               field_list = `TABNAME, FIELDNAME, ROLLNAME, DOMNAME`
               condition  = `AS4LOCAL = 'A' AND ( FIELDNAME LIKE '%CLEAN%CORE%' OR ROLLNAME LIKE '%CLEAN%CORE%' ` &&
                            `OR FIELDNAME LIKE '%CCLEVEL%' OR FIELDNAME LIKE '%CC_LEVEL%' ` &&
                            `OR ROLLNAME LIKE '%CCLEVEL%' OR ROLLNAME LIKE '%CC_LEVEL%' )`
               sort_order = `TABNAME, FIELDNAME`
               max_rows   = max_dictionary_rows ) ).
    catalog->run_query(
      VALUE #( subject    = `DD04T clean core data elements`
               source     = `DD04T`
               field_list = `ROLLNAME, DDTEXT`
               condition  = `DDLANGUAGE = 'E' AND AS4LOCAL = 'A' AND UPPER( DDTEXT ) LIKE '%CLEAN CORE%'`
               sort_order = `ROLLNAME`
               max_rows   = max_dictionary_rows ) ).
    catalog->run_query(
      VALUE #( subject    = `DD07T clean core fixed values`
               source     = `DD07T`
               field_list = `DOMNAME, DOMVALUE_L, DDTEXT`
               condition  = `DDLANGUAGE = 'E' AND AS4LOCAL = 'A' AND ( DOMNAME LIKE '%CLEAN%CORE%' ` &&
                            `OR DOMNAME LIKE '%CCLEVEL%' OR DOMNAME LIKE '%CC_LEVEL%' ` &&
                            `OR UPPER( DDTEXT ) LIKE '%CLEAN CORE%' )`
               sort_order = `DOMNAME, DOMVALUE_L`
               max_rows   = max_dictionary_rows ) ).
  ENDMETHOD.

  METHOD describe_apis.
    DATA(class_names) = catalog->object_names(
      VALUE #( names        = lcl_catalog=>names_like( VALUE #( ( `CL_SATC_API*` )
                                                                ( `IF_SATC_API*` )
                                                                ( `IF_SATC_RESULT*` ) ) )
               object_types = lcl_catalog=>types_of( VALUE #( ( `CLAS` )
                                                              ( `INTF` ) ) ) ) ).
    LOOP AT class_names INTO DATA(class_name) TO max_apis.
      catalog->describe_api( class_name ).
    ENDLOOP.
  ENDMETHOD.

  METHOD explore_results.
    DATA(sources) = catalog->object_names(
      VALUE #( names        = lcl_catalog=>names_like( VALUE #( ( `SATC_AC_RESULT*` )
                                                                ( `SATC_AC_RSLT*` )
                                                                ( `SATC_API*` ) ) )
               object_types = lcl_catalog=>types_of( VALUE #( ( `TABL` )
                                                              ( `VIEW` )
                                                              ( `DDLS` ) ) ) ) ).
    DATA(result_filter) = VALUE lcl_catalog=>row_filter( key_fields = VALUE #( ( `DISPLAY_ID` )
                                                                               ( `RESULT_ID` )
                                                                               ( `RESULTID` ) )
                                                         key_value  = settings-result_id ).
    LOOP AT sources INTO DATA(source).
      catalog->explore_source( source = source
                               filter = result_filter ).
    ENDLOOP.
  ENDMETHOD.

  METHOD sample_api_findings.
    DATA factory TYPE REF TO object.
    DATA access TYPE REF TO object.

    DATA(factory_type) = catalog->object_descriptor( api-factory ).
    IF factory_type IS NOT BOUND.
      output->add( subject = api-factory
                   item    = lcl_output=>label-missing ).
      RETURN.
    ENDIF.

    TRY.
        CREATE OBJECT factory TYPE (api-factory).
        DATA(created) = call_with_result_id( target      = factory
                                             target_type = factory_type
                                             method_name = api-create_access ).
        DATA(returned) = created[ kind = cl_abap_objectdescr=>returning ]-value.
        ASSIGN returned->* TO FIELD-SYMBOL(<access>).
        access ?= <access>.
        DATA(reference_type) = CAST cl_abap_refdescr( cl_abap_typedescr=>describe_by_data( <access> ) ).
        report_findings( call_with_result_id(
                           target      = access
                           target_type = CAST #( reference_type->get_referenced_type( ) )
                           method_name = api-get_findings ) ).
      CATCH cx_root INTO DATA(failure).
        " whatever the API raises is a result of the probe, not an error of the program
        output->add_failure( subject = findings_subject
                             failure = failure ).
    ENDTRY.
  ENDMETHOD.

  METHOD call_with_result_id.
    DATA(signature) = find_method( target_type = target_type
                                   method_name = method_name ).
    LOOP AT signature-parameters REFERENCE INTO DATA(parameter)
         WHERE is_optional = abap_false OR parm_kind <> cl_abap_objectdescr=>importing.
      DATA(binding) = binding_of( target_type = target_type
                                  signature   = signature
                                  parameter   = parameter->* ).
      IF binding-value IS BOUND.
        INSERT binding INTO TABLE result.
      ENDIF.
    ENDLOOP.

    " a method of an interface is called through the object with its full name
    DATA(call_name) = COND string( WHEN target_type->kind = cl_abap_typedescr=>kind_intf
                                   THEN |{ target_type->get_relative_name( ) }~{ signature-name }|
                                   ELSE signature-name ).
    CALL METHOD target->(call_name) PARAMETER-TABLE result.
  ENDMETHOD.

  METHOD find_method.
    LOOP AT target_type->methods REFERENCE INTO DATA(signature).
      IF signature->name = method_name OR signature->name CP |*~{ method_name }|.
        result = signature->*.
        RETURN.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD binding_of.
    DATA parameter_type TYPE REF TO cl_abap_datadescr.

    target_type->get_method_parameter_type( EXPORTING  p_method_name    = signature-name
                                                       p_parameter_name = parameter-name
                                            RECEIVING  p_descr_ref      = parameter_type
                                            EXCEPTIONS OTHERS           = 1 ).
    IF sy-subrc <> 0 OR parameter_type IS NOT BOUND.
      RETURN.
    ENDIF.

    CREATE DATA result-value TYPE HANDLE parameter_type.
    result-name = parameter-name.
    " the binding names the kind as the caller sees it
    result-kind = SWITCH #( parameter-parm_kind
                            WHEN cl_abap_objectdescr=>importing THEN cl_abap_objectdescr=>exporting
                            WHEN cl_abap_objectdescr=>exporting THEN cl_abap_objectdescr=>importing
                            ELSE parameter-parm_kind ).

    IF parameter-parm_kind = cl_abap_objectdescr=>importing
       AND (    parameter-type_kind = cl_abap_typedescr=>typekind_char
             OR parameter-type_kind = cl_abap_typedescr=>typekind_num
             OR parameter-type_kind = cl_abap_typedescr=>typekind_hex
             OR parameter-type_kind = cl_abap_typedescr=>typekind_string ).
      ASSIGN result-value->* TO FIELD-SYMBOL(<input>).
      <input> = settings-result_id.
    ENDIF.
  ENDMETHOD.

  METHOD report_findings.
    FIELD-SYMBOLS <findings> TYPE ANY TABLE.

    LOOP AT bindings REFERENCE INTO DATA(binding) WHERE kind <> cl_abap_objectdescr=>exporting.
      ASSIGN binding->value->* TO FIELD-SYMBOL(<received>).
      DATA(received_type) = cl_abap_typedescr=>describe_by_data( <received> ).
      IF received_type->kind <> cl_abap_typedescr=>kind_table.
        CONTINUE.
      ENDIF.

      ASSIGN <received> TO <findings>.
      output->add( subject = findings_subject
                   item    = binding->name
                   content = |{ lines( <findings> ) } rows TYPE { received_type->absolute_name }| ).
      output->add_rows( subject  = findings_subject
                        rows     = <findings>
                        max_rows = settings-sample_size ).
      IF CAST cl_abap_tabledescr( received_type )->get_table_line_type( )->kind = cl_abap_typedescr=>kind_struct.
        count_by_check( <findings> ).
        report_check_messages( <findings> ).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD count_by_check.
    DATA counts TYPE check_counts.

    LOOP AT findings ASSIGNING FIELD-SYMBOL(<finding>).
      DATA(check_id) = check_id_of( <finding> ).
      ASSIGN counts[ check_id = check_id ] TO FIELD-SYMBOL(<count>).
      IF sy-subrc = 0.
        <count>-findings = <count>-findings + 1.
      ELSE.
        INSERT VALUE #( check_id = check_id
                        findings = 1 ) INTO TABLE counts.
      ENDIF.
    ENDLOOP.
    output->add_rows( subject  = |{ findings_subject } by check|
                      rows     = counts
                      max_rows = max_check_counts ).
  ENDMETHOD.

  METHOD check_id_of.
    DATA(finding_type) = CAST cl_abap_structdescr( cl_abap_typedescr=>describe_by_data( finding ) ).
    LOOP AT finding_type->components REFERENCE INTO DATA(component).
      IF NOT contains( val  = component->name
                       pcre = check_field_pattern ).
        CONTINUE.
      ENDIF.
      ASSIGN COMPONENT component->name OF STRUCTURE finding TO FIELD-SYMBOL(<value>).
      IF sy-subrc = 0 AND cl_abap_typedescr=>describe_by_data( <value> )->kind = cl_abap_typedescr=>kind_elem.
        result = |{ result }{ component->name }={ <value> } |.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD report_check_messages.
    DATA classes TYPE check_classes.

    IF settings-reads_messages = abap_false.
      RETURN.
    ENDIF.

    LOOP AT findings ASSIGNING FIELD-SYMBOL(<finding>).
      ASSIGN COMPONENT api-check_class OF STRUCTURE <finding> TO FIELD-SYMBOL(<check_class>).
      IF sy-subrc <> 0.
        RETURN.
      ENDIF.
      IF NOT line_exists( classes[ table_line = <check_class> ] ).
        INSERT CONV string( <check_class> ) INTO TABLE classes.
      ENDIF.
    ENDLOOP.

    LOOP AT classes INTO DATA(check_class) TO max_check_classes.
      report_messages_of( check_class ).
    ENDLOOP.
  ENDMETHOD.

  METHOD report_messages_of.
    DATA check_instance TYPE REF TO object.
    FIELD-SYMBOLS <messages> TYPE ANY TABLE.

    DATA(subject) = |{ check_class }->{ api-check_messages }|.
    TRY.
        CREATE OBJECT check_instance TYPE (check_class).
        ASSIGN check_instance->(api-check_messages) TO FIELD-SYMBOL(<attribute>).
        IF sy-subrc <> 0
           OR cl_abap_typedescr=>describe_by_data( <attribute> )->kind <> cl_abap_typedescr=>kind_table.
          output->add( subject = subject
                       item    = lcl_output=>label-missing ).
          RETURN.
        ENDIF.
        ASSIGN <attribute> TO <messages>.
        output->add_rows( subject  = subject
                          rows     = <messages>
                          max_rows = max_messages ).
      CATCH cx_root INTO DATA(failure).
        " a check class that cannot be created this way tells where its messages are not kept
        output->add_failure( subject = subject
                             failure = failure ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.

*&----------------------------------------------------------------------*
*&CLASS lcl_usage_probe IMPLEMENTATION
*&----------------------------------------------------------------------*
CLASS lcl_usage_probe IMPLEMENTATION.

  METHOD constructor.
    me->output  = output.
    me->catalog = catalog.
  ENDMETHOD.

  METHOD lif_probe~run.
    output->begin_section( section_name ).
    list_repository_objects( ).
    describe_function_modules( ).
    describe_apis( ).
    explore_usage_data( ).
  ENDMETHOD.

  METHOD list_repository_objects.
    catalog->list_objects( VALUE #( packages = lcl_catalog=>packages_like( VALUE #( ( `SUSG*` ) ) ) ) ).
    catalog->list_objects( VALUE #( names = lcl_catalog=>names_like( VALUE #( ( `SUSG*` )
                                                                              ( `CL_SUSG*` )
                                                                              ( `IF_SUSG*` )
                                                                              ( `CX_SUSG*` ) ) ) ) ).
  ENDMETHOD.

  METHOD describe_function_modules.
    catalog->run_query( VALUE #( subject    = `TFDIR function modules`
                                 source     = `TFDIR`
                                 field_list = `FUNCNAME, PNAME, FMODE`
                                 condition  = `FUNCNAME LIKE 'SUSG%'`
                                 sort_order = `FUNCNAME`
                                 max_rows   = max_function_rows ) ).
    catalog->run_query( VALUE #( subject    = `FUPARAREF parameters`
                                 source     = `FUPARAREF`
                                 field_list = `*`
                                 condition  = `FUNCNAME LIKE 'SUSG%'`
                                 sort_order = `FUNCNAME`
                                 max_rows   = max_function_rows ) ).
  ENDMETHOD.

  METHOD describe_apis.
    DATA(class_names) = catalog->object_names(
      VALUE #( names        = lcl_catalog=>names_like( VALUE #( ( `CL_SUSG*` )
                                                                ( `IF_SUSG*` ) ) )
               object_types = lcl_catalog=>types_of( VALUE #( ( `CLAS` )
                                                              ( `INTF` ) ) ) ) ).
    LOOP AT class_names INTO DATA(class_name) TO max_apis.
      catalog->describe_api( class_name ).
    ENDLOOP.
  ENDMETHOD.

  METHOD explore_usage_data.
    DATA(sources) = catalog->object_names(
      VALUE #( names        = lcl_catalog=>names_like( VALUE #( ( `SUSG*` ) ) )
               object_types = lcl_catalog=>types_of( VALUE #( ( `TABL` )
                                                              ( `VIEW` )
                                                              ( `DDLS` ) ) ) ) ).
    LOOP AT sources INTO DATA(source).
      catalog->explore_source( source ).
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.

*&----------------------------------------------------------------------*
*&CLASS lcl_application IMPLEMENTATION
*&----------------------------------------------------------------------*
CLASS lcl_application IMPLEMENTATION.

  METHOD label_screen.
    sc_trel  = 'C - Release and SAP Notes'.
    sc_crel  = 'Read component releases and the status of the SAP Notes below'.
    sc_cnote = 'SAP Notes to look up in CWBNTCUST (S_NOTE):'.
    sc_tatc  = 'A - ATC results'.
    sc_catc  = 'Read ATC objects, APIs and result tables'.
    sc_cres  = 'DISPLAY_ID of a clean core ATC run (P_RESID) - empty: newest runs'.
    sc_cmsg  = 'Create the check classes of that run to read their message catalog'.
    sc_tusg  = 'B - SUSG usage data'.
    sc_cusg  = 'Read SUSG objects, APIs and aggregated usage tables'.
    sc_tout  = 'Output'.
    sc_crows = 'Sample rows per table (P_ROWS):'.
    sc_cmask = 'Mask user names in sample rows'.
    sc_cfile = 'Write the result to this text file as well, F4 to choose (P_FILE):'.

    " 3565942 clean core ATC checks, 3627152 their Note Analyzer files, 3679781 modification check,
    " 3568611 mass API for language version and release state, 3605376 findings for key user items
    s_note[] = VALUE #( sign   = 'I'
                        option = 'EQ'
                        ( low = '3565942' )
                        ( low = '3627152' )
                        ( low = '3679781' )
                        ( low = '3568611' )
                        ( low = '3605376' ) ).
  ENDMETHOD.

  METHOD ask_file_path.
    DATA file_name TYPE string.
    DATA directory TYPE string.
    DATA user_action TYPE i.

    cl_gui_frontend_services=>file_save_dialog( EXPORTING  default_extension = default_extension
                                                           default_file_name = default_file_name
                                                CHANGING   filename          = file_name
                                                           path              = directory
                                                           fullpath          = result
                                                           user_action       = user_action
                                                EXCEPTIONS OTHERS            = 1 ).
    IF sy-subrc <> 0 OR user_action = cl_gui_frontend_services=>action_cancel.
      CLEAR result.
    ENDIF.
  ENDMETHOD.

  METHOD constructor.
    me->selection = selection.
    IF me->selection-sample_size <= 0.
      " UP TO 0 ROWS would read a table as a whole
      me->selection-sample_size = default_sample_size.
    ENDIF.
  ENDMETHOD.

  METHOD run.
    DATA(output) = NEW lcl_output( selection-masks_users ).
    DATA(catalog) = NEW lcl_catalog( output      = output
                                     sample_size = selection-sample_size ).

    LOOP AT selected_probes( output  = output
                             catalog = catalog ) INTO DATA(probe).
      TRY.
          probe->run( ).
        CATCH cx_root INTO DATA(failure).
          " one failing probe must not cost the results of the others
          output->add_failure( subject = probe_subject
                               failure = failure ).
      ENDTRY.
    ENDLOOP.

    IF selection-file_path IS NOT INITIAL.
      output->download( selection-file_path ).
    ENDIF.
    output->display( ).
  ENDMETHOD.

  METHOD selected_probes.
    IF selection-probes_release = abap_true.
      INSERT CAST lif_probe( NEW lcl_release_probe( output  = output
                                                    catalog = catalog
                                                    notes   = selection-notes ) ) INTO TABLE result.
    ENDIF.
    IF selection-probes_atc = abap_true.
      DATA(atc_settings) = VALUE lcl_atc_probe=>atc_settings( result_id      = selection-result_id
                                                              reads_messages = selection-reads_messages
                                                              sample_size    = selection-sample_size ).
      INSERT CAST lif_probe( NEW lcl_atc_probe( output   = output
                                                catalog  = catalog
                                                settings = atc_settings ) ) INTO TABLE result.
    ENDIF.
    IF selection-probes_usage = abap_true.
      INSERT CAST lif_probe( NEW lcl_usage_probe( output  = output
                                                  catalog = catalog ) ) INTO TABLE result.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
