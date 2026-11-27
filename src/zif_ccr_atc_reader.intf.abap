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
  "! One finding of an object with what its remediation needs: where it is and which SAP
  "! object it uses, with the successor of that object if SAP names one
  TYPES: BEGIN OF finding_detail,
           check_name      TYPE zif_ccr_level_rules=>check_name,
           check_title     TYPE string,
           code            TYPE zif_ccr_level_rules=>message_code,
           message         TYPE string,
           kind            TYPE zif_ccr_level_rules=>finding_kind_code,
           sub_object      TYPE string,
           line            TYPE i,
           ref_object_type TYPE string,
           ref_object_name TYPE string,
           successor       TYPE string,
         END OF finding_detail.
  TYPES finding_detail_list TYPE STANDARD TABLE OF finding_detail WITH EMPTY KEY.
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

  "! The repository objects of the packages and of all their subpackages, without the objects
  "! the system generated.
  "!
  "! @parameter packages     | The packages the ATC run checked; empty gives no object
  "! @parameter object_types | Object types to take; empty takes every type
  "! @parameter result       | The objects
  METHODS objects
    IMPORTING packages      TYPE package_range
              object_types  TYPE object_type_range OPTIONAL
    RETURNING VALUE(result) TYPE zif_ccr_classifier=>object_keys.

  "! The findings of one object in the run that FINDINGS read last, with their details.
  "!
  "! @parameter object_type | Type of the object, e.g. CLAS
  "! @parameter object_name | Name of the object
  "! @parameter result      | Its findings of every check; empty when FINDINGS was not called
  METHODS finding_details
    IMPORTING object_type   TYPE zif_ccr_level_rules=>object_type
              object_name   TYPE zif_ccr_level_rules=>object_name
    RETURNING VALUE(result) TYPE finding_detail_list.

  "! Returns the classes of a list that are behavior pools of a RAP behavior definition.
  "!
  "! @parameter objects | Objects of any type - only classes are looked at
  "! @parameter result  | The behavior pools among them
  METHODS behavior_pools
    IMPORTING objects       TYPE zif_ccr_classifier=>object_keys
    RETURNING VALUE(result) TYPE zif_ccr_classifier=>object_keys.

ENDINTERFACE.
