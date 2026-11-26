"! <p class="shorttext synchronized" lang="EN">Clean core level of an ATC finding</p>
"! Says which clean core level a single finding of an ATC result stands for.
INTERFACE zif_ccr_level_rules PUBLIC.

  "! Type of a repository object as the object directory has it: CLAS, PROG, DDLS ...
  TYPES object_type TYPE c LENGTH 4.
  "! Name of a repository object as the object directory has it
  TYPES object_name TYPE c LENGTH 40.
  "! Name of the class that implements an ATC check
  TYPES check_name TYPE c LENGTH 30.
  "! Message code of a finding within its check
  TYPES message_code TYPE c LENGTH 25.
  "! Kind of a finding: one of the values of FINDING_KIND
  TYPES finding_kind_code TYPE c LENGTH 1.
  "! Clean core level: one of the values of LEVEL
  TYPES clean_core_level TYPE c LENGTH 1.

  "! One finding of an ATC result, reduced to what the classification needs
  TYPES: BEGIN OF finding,
           object_type TYPE object_type,
           object_name TYPE object_name,
           check_name  TYPE check_name,
           code        TYPE message_code,
           kind        TYPE finding_kind_code,
         END OF finding.
  "! The findings of an ATC result, in any order
  TYPES findings TYPE STANDARD TABLE OF finding WITH EMPTY KEY.

  "! Kinds of a finding as ATC reports them
  CONSTANTS: BEGIN OF finding_kind,
               error   TYPE finding_kind_code VALUE 'E',
               warning TYPE finding_kind_code VALUE 'W',
               note    TYPE finding_kind_code VALUE 'N',
             END OF finding_kind.

  "! Clean core levels. A is the best level and D the worst, and they compare as characters:
  "! the later letter is the worse level. NONE is the answer for a finding that says nothing
  "! about the level; it is lower than every level.
  CONSTANTS: BEGIN OF level,
               none TYPE clean_core_level VALUE IS INITIAL,
               a    TYPE clean_core_level VALUE 'A',
               b    TYPE clean_core_level VALUE 'B',
               c    TYPE clean_core_level VALUE 'C',
               d    TYPE clean_core_level VALUE 'D',
             END OF level.

  "! Returns the clean core level a finding stands for.
  "!
  "! @parameter finding | Finding of an ATC result
  "! @parameter result  | Level B, C or D - NONE when the finding is not a clean core finding
  METHODS level_of
    IMPORTING finding       TYPE finding
    RETURNING VALUE(result) TYPE clean_core_level.

ENDINTERFACE.
