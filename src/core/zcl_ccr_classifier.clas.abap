"! <p class="shorttext synchronized" lang="EN">Classifies custom objects by clean core level</p>
"! Gives every custom object the worst clean core level among its findings.
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

    METHODS count_finding
      IMPORTING level  TYPE zif_ccr_level_rules=>clean_core_level
      CHANGING  object TYPE zif_ccr_classifier=>object_level.

ENDCLASS.


CLASS zcl_ccr_classifier IMPLEMENTATION.

  METHOD constructor.
    me->rules = rules.
  ENDMETHOD.


  METHOD zif_ccr_classifier~classify.
    LOOP AT findings REFERENCE INTO DATA(finding).
      ASSIGN result[ object_type = finding->object_type
                     object_name = finding->object_name ] TO FIELD-SYMBOL(<object>).
      IF sy-subrc <> 0.
        INSERT VALUE #( object_type = finding->object_type
                        object_name = finding->object_name
                        level       = zif_ccr_level_rules=>level-a ) INTO TABLE result ASSIGNING <object>.
      ENDIF.
      count_finding( EXPORTING level  = rules->level_of( finding->* )
                     CHANGING  object = <object> ).
    ENDLOOP.
  ENDMETHOD.


  METHOD count_finding.
    CASE level.
      WHEN zif_ccr_level_rules=>level-b.
        object-findings_b += 1.
      WHEN zif_ccr_level_rules=>level-c.
        object-findings_c += 1.
      WHEN zif_ccr_level_rules=>level-d.
        object-findings_d += 1.
      WHEN OTHERS.
        " a finding outside clean core leaves the object at its level
        RETURN.
    ENDCASE.

    IF level > object-level.
      object-level = level.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
