"! <p class="shorttext synchronized" lang="EN">Classifies custom objects by clean core level</p>
"! Gives every custom object the worst clean core level among its findings, level A without one.
CLASS zcl_ccr_classifier DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_ccr_classifier.

    "! @parameter rules | Says which clean core level a single finding stands for
    METHODS constructor
      IMPORTING rules TYPE REF TO zif_ccr_level_rules.

  PRIVATE SECTION.
    DATA rules TYPE REF TO zif_ccr_level_rules.

    "! The object is a row of a sorted table: its key is write-protected, so the row is handed
    "! over as a reference and never as a whole to a CHANGING parameter.
    METHODS count_finding
      IMPORTING level  TYPE zif_ccr_level_rules=>clean_core_level
                object TYPE REF TO zif_ccr_classifier=>object_level.

ENDCLASS.


CLASS zcl_ccr_classifier IMPLEMENTATION.

  METHOD constructor.
    me->rules = rules.
  ENDMETHOD.


  METHOD zif_ccr_classifier~classify.
    result = VALUE #( FOR object IN objects
                      ( object_type = object-object_type
                        object_name = object-object_name
                        level       = zif_ccr_level_rules=>level-a ) ).

    LOOP AT findings REFERENCE INTO DATA(finding).
      " a narrower scope than the run must not bring in objects from outside it
      IF objects IS NOT INITIAL
         AND NOT line_exists( objects[ object_type = finding->object_type
                                       object_name = finding->object_name ] ).
        CONTINUE.
      ENDIF.
      IF NOT line_exists( result[ object_type = finding->object_type
                                  object_name = finding->object_name ] ).
        INSERT VALUE #( object_type = finding->object_type
                        object_name = finding->object_name
                        level       = zif_ccr_level_rules=>level-a ) INTO TABLE result.
      ENDIF.
      count_finding( level  = rules->level_of( finding->* )
                     object = REF #( result[ object_type = finding->object_type
                                             object_name = finding->object_name ] ) ).
    ENDLOOP.
  ENDMETHOD.


  METHOD count_finding.
    CASE level.
      WHEN zif_ccr_level_rules=>level-b.
        object->findings_b += 1.
      WHEN zif_ccr_level_rules=>level-c.
        object->findings_c += 1.
      WHEN zif_ccr_level_rules=>level-d.
        object->findings_d += 1.
      WHEN OTHERS.
        " a finding outside clean core leaves the object at its level
        RETURN.
    ENDCASE.

    IF level > object->level.
      object->level = level.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
