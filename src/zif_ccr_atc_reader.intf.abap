"! <p class="shorttext synchronized" lang="EN">Reads ATC results for the clean core assessment</p>
"! Reads what the assessment needs from ATC: the runs of a check variant, the findings of one
"! run, and the custom objects of the packages the run checked - an ATC result does not list them.
INTERFACE zif_ccr_atc_reader PUBLIC.

  "! One complete ATC run of a check variant
  TYPES: BEGIN OF run,
           result_id    TYPE satc_d_result_id,
           title        TYPE satc_ac_resulth-title,
           run_series   TYPE satc_ac_resulth-run_series_name,
           scheduled_on TYPE satc_ac_resulth-scheduled_on_ts,
           is_central   TYPE satc_ac_resulth-is_central_run,
         END OF run.
  "! Runs, newest first
  TYPES run_list TYPE STANDARD TABLE OF run WITH EMPTY KEY.
  TYPES check_variant TYPE satc_ac_resulth-chk_profile_name.
  TYPES package_range TYPE RANGE OF devclass.
  TYPES object_type_range TYPE RANGE OF trobjtype.

  "! The complete runs of a check variant, to choose the run to assess.
  "!
  "! @parameter check_variant | Check variant of the runs, e.g. ABAP_CLEAN_CORE_DEVELOPMENT
  "! @parameter result        | Complete runs, newest first
  METHODS runs
    IMPORTING check_variant TYPE check_variant
    RETURNING VALUE(result) TYPE run_list.

  "! All findings of one run, of every check of its variant.
  "!
  "! @parameter result_id | The run, as listed by RUNS
  "! @parameter result    | Its findings
  METHODS findings
    IMPORTING result_id     TYPE satc_d_result_id
    RETURNING VALUE(result) TYPE zif_ccr_level_rules=>findings.

  "! The repository objects of the packages and of all their subpackages.
  "!
  "! @parameter packages     | The packages the ATC run checked; empty gives no object
  "! @parameter object_types | Object types to take; empty takes every type
  "! @parameter result       | The objects
  METHODS objects
    IMPORTING packages      TYPE package_range
              object_types  TYPE object_type_range OPTIONAL
    RETURNING VALUE(result) TYPE zif_ccr_classifier=>object_keys.

  "! Returns the classes of a list that are behavior pools of a RAP behavior definition.
  "!
  "! @parameter objects | Objects of any type - only classes are looked at
  "! @parameter result  | The behavior pools among them
  METHODS behavior_pools
    IMPORTING objects       TYPE zif_ccr_classifier=>object_keys
    RETURNING VALUE(result) TYPE zif_ccr_classifier=>object_keys.

ENDINTERFACE.
