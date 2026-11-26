"! <p class="shorttext synchronized" lang="EN">Reads usage data (SUSG) for the clean core assessment</p>
"! Reads what the assessment needs from the aggregated usage data of transaction SUSG: the usage
"! data sets with the period they cover, and the executions of the custom objects in one of them.
INTERFACE zif_ccr_usage_reader PUBLIC.

  "! One usage data set: the local data of this system or data imported from another system
  TYPES: BEGIN OF data_set,
           usage_id       TYPE susg_admin-usgid,
           kind           TYPE susg_admin-kind,
           system_id      TYPE susg_admin-sysid,
           description    TYPE susg_admin-description,
           date_from      TYPE susg_admin-date_from,
           date_to        TYPE susg_admin-date_to,
           days_available TYPE susg_admin-days_available,
           days_missing   TYPE susg_admin-days_missing,
         END OF data_set.
  "! Usage data sets, the one with the latest data first
  TYPES data_set_list TYPE STANDARD TABLE OF data_set WITH EMPTY KEY.

  "! The usage data sets of this system, to choose the one to assess with.
  "!
  "! @parameter result | Data sets, the one with the latest data first
  METHODS data_sets
    RETURNING VALUE(result) TYPE data_set_list.

  "! Executions and last use of the objects in one usage data set, summed over all their
  "! procedures. Usage is measured for classes, function groups and programs only. An object that
  "! did not run in the period of the data set has no row.
  "!
  "! @parameter usage_id | The data set, as listed by DATA_SETS
  "! @parameter objects  | The objects to read usage for; empty gives no usage
  "! @parameter result   | One row per object that ran
  METHODS usages
    IMPORTING usage_id      TYPE susg_admin-usgid
              objects       TYPE zif_ccr_classifier=>object_keys
    RETURNING VALUE(result) TYPE zif_ccr_assessor=>object_usages.

ENDINTERFACE.
