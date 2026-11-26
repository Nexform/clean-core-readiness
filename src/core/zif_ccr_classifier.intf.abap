"! <p class="shorttext synchronized" lang="EN">Clean core level of custom objects</p>
"! Derives the clean core level of custom objects from the findings of an ATC result.
INTERFACE zif_ccr_classifier PUBLIC.

  "! A custom object with its clean core level and the number of findings behind each level
  TYPES: BEGIN OF object_level,
           object_type TYPE zif_ccr_level_rules=>object_type,
           object_name TYPE zif_ccr_level_rules=>object_name,
           level       TYPE zif_ccr_level_rules=>clean_core_level,
           findings_b  TYPE i,
           findings_c  TYPE i,
           findings_d  TYPE i,
         END OF object_level.
  "! One row per custom object
  TYPES object_levels TYPE SORTED TABLE OF object_level WITH UNIQUE KEY object_type object_name.

  "! Gives every object that has a finding its clean core level: the worst level among its
  "! clean core findings, and level A when none of its findings is a clean core finding.
  "! An object without any finding is not part of an ATC result and so not of the answer.
  "!
  "! @parameter findings | Findings of one ATC result, of all checks
  "! @parameter result   | The objects of the findings with their level
  METHODS classify
    IMPORTING findings      TYPE zif_ccr_level_rules=>findings
    RETURNING VALUE(result) TYPE object_levels.

ENDINTERFACE.
