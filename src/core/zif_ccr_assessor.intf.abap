"! <p class="shorttext synchronized" lang="EN">Proposal for custom objects: keep, remediate, retire</p>
"! Joins the clean core level of custom objects with their usage and proposes what to do
"! with each of them.
INTERFACE zif_ccr_assessor PUBLIC.

  "! How often the code of an object ran in the period the usage data covers
  TYPES execution_count TYPE p LENGTH 16 DECIMALS 0.
  "! State of the usage of an object: one of the values of USAGE_STATE
  TYPES usage_state_code TYPE c LENGTH 8.
  "! What to do with an object: one of the values of PROPOSAL
  TYPES proposal_code TYPE c LENGTH 16.

  "! Usage of one object, summed over its procedures
  TYPES: BEGIN OF object_usage,
           object_type TYPE zif_ccr_level_rules=>object_type,
           object_name TYPE zif_ccr_level_rules=>object_name,
           executions  TYPE execution_count,
           last_used   TYPE d,
         END OF object_usage.
  "! One row per object that ran
  TYPES object_usages TYPE SORTED TABLE OF object_usage WITH UNIQUE KEY object_type object_name.

  "! A custom object with its level, its usage and the proposal that follows from both
  TYPES: BEGIN OF assessment,
           object_type TYPE zif_ccr_level_rules=>object_type,
           object_name TYPE zif_ccr_level_rules=>object_name,
           level       TYPE zif_ccr_level_rules=>clean_core_level,
           findings_b  TYPE i,
           findings_c  TYPE i,
           findings_d  TYPE i,
           usage_state TYPE usage_state_code,
           executions  TYPE execution_count,
           last_used   TYPE d,
           proposal    TYPE proposal_code,
         END OF assessment.
  "! One row per custom object
  TYPES assessments TYPE SORTED TABLE OF assessment WITH UNIQUE KEY object_type object_name.

  "! Number of objects of one level, by usage state
  TYPES: BEGIN OF summary_line,
           level    TYPE zif_ccr_level_rules=>clean_core_level,
           used     TYPE i,
           unknown  TYPE i,
           not_used TYPE i,
           total    TYPE i,
         END OF summary_line.
  "! One line per level, A to D
  TYPES summary TYPE STANDARD TABLE OF summary_line WITH EMPTY KEY.

  "! UNKNOWN is the state of an object whose usage cannot be measured: usage data exists for
  "! classes, function groups and programs only.
  CONSTANTS: BEGIN OF usage_state,
               used     TYPE usage_state_code VALUE 'USED',
               not_used TYPE usage_state_code VALUE 'NOT USED',
               unknown  TYPE usage_state_code VALUE 'UNKNOWN',
             END OF usage_state.

  "! RETIRE marks a candidate: the owner of the object decides, nothing is deleted.
  "! RETIRE WITH BDEF is a behavior pool that did not run: it cannot go without its behavior
  "! definition, so the two are retired together or not at all.
  CONSTANTS: BEGIN OF proposal,
               keep             TYPE proposal_code VALUE 'KEEP',
               remediate        TYPE proposal_code VALUE 'REMEDIATE',
               remediate_first  TYPE proposal_code VALUE 'REMEDIATE FIRST',
               retire           TYPE proposal_code VALUE 'RETIRE',
               retire_with_bdef TYPE proposal_code VALUE 'RETIRE WITH BDEF',
             END OF proposal.

  "! Proposes for every object: RETIRE when it can be measured and did not run; otherwise
  "! KEEP at level A or B, REMEDIATE at level C, REMEDIATE FIRST at level D. An object whose
  "! usage is unknown is never proposed for retirement. A behavior pool that did not run is
  "! proposed RETIRE WITH BDEF instead of RETIRE.
  "!
  "! @parameter object_levels  | Custom objects with their clean core level
  "! @parameter usages         | Usage of the objects that ran - other objects have no row
  "! @parameter behavior_pools | Classes of OBJECT_LEVELS that are behavior pools
  "! @parameter result         | The objects of OBJECT_LEVELS with usage and proposal
  METHODS assess
    IMPORTING object_levels  TYPE zif_ccr_classifier=>object_levels
              usages         TYPE object_usages
              behavior_pools TYPE zif_ccr_classifier=>object_keys OPTIONAL
    RETURNING VALUE(result)  TYPE assessments.

  "! Counts the assessed objects per level and usage state: how much custom code there is
  "! on each level, and how much of it is in use.
  "!
  "! @parameter assessments | Assessed objects
  "! @parameter result      | One line for each level A to D, also for a level without objects
  METHODS summarize
    IMPORTING assessments   TYPE assessments
    RETURNING VALUE(result) TYPE summary.

ENDINTERFACE.
