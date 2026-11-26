"! <p class="shorttext synchronized" lang="EN">Clean core level of custom objects</p>
"! Derives the clean core level of custom objects from the findings of an ATC result.
INTERFACE zif_ccr_classifier PUBLIC.

  "! A custom object, named by its type and name
  TYPES: BEGIN OF object_key,
           object_type TYPE zif_ccr_level_rules=>object_type,
           object_name TYPE zif_ccr_level_rules=>object_name,
         END OF object_key.
  "! Custom objects, each once
  TYPES object_keys TYPE SORTED TABLE OF object_key WITH UNIQUE KEY object_type object_name.

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

  "! Gives every checked object its clean core level: the worst level among its clean core
  "! findings, and level A when it has no clean core finding. An ATC result does not list the
  "! objects it checked, so the caller passes them; an object that has a finding is part of the
  "! answer also when it is missing from that list.
  "!
  "! @parameter findings | Findings of one ATC result, of all checks
  "! @parameter objects  | The objects the ATC run checked
  "! @parameter result   | The checked objects and the objects of the findings, with their level
  METHODS classify
    IMPORTING findings      TYPE zif_ccr_level_rules=>findings
              objects       TYPE object_keys OPTIONAL
    RETURNING VALUE(result) TYPE object_levels.

ENDINTERFACE.
