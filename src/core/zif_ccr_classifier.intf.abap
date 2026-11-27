"! <p class="shorttext synchronized" lang="EN">Clean core level of custom objects</p>
"! Derives the clean core level of custom objects from the findings of an ATC result.
INTERFACE zif_ccr_classifier PUBLIC.

  "! A custom object, named by its type and name
  "! Package of a repository object as the object directory has it
  TYPES package_name TYPE c LENGTH 30.
  "! A custom object; its package is there to show it, the object is known by type and name
  TYPES: BEGIN OF object_key,
           object_type TYPE zif_ccr_level_rules=>object_type,
           object_name TYPE zif_ccr_level_rules=>object_name,
           package     TYPE package_name,
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
  "! objects it checked, so the caller passes them. The list is the scope: findings of objects
  "! outside it are left out. Without a list, every object of the findings is classified.
  "!
  "! @parameter findings | Findings of one ATC result, of all checks
  "! @parameter objects  | The objects to assess, e.g. those of the packages the ATC run checked
  "! @parameter result   | The objects of the list, or without a list those of the findings,
  "!                        with their level
  METHODS classify
    IMPORTING findings      TYPE zif_ccr_level_rules=>findings
              objects       TYPE object_keys OPTIONAL
    RETURNING VALUE(result) TYPE object_levels.

ENDINTERFACE.
