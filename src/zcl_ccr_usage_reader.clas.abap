"! <p class="shorttext synchronized" lang="EN">Reads usage data from the SUSG tables</p>
"! Adapter of ZIF_CCR_USAGE_READER. Data sets come from SUSG_ADMIN, usage from the CDS view
"! SUSG_I_DATA at procedure level, summed per object - as confirmed by Z_CCR_PROBE on S/4HANA 2025.
CLASS zcl_ccr_usage_reader DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_ccr_usage_reader.

ENDCLASS.


CLASS zcl_ccr_usage_reader IMPLEMENTATION.

  METHOD zif_ccr_usage_reader~data_sets.
    SELECT FROM susg_admin
      FIELDS usgid, kind, sysid, description, date_from, date_to, days_available, days_missing
      ORDER BY date_to DESCENDING, usgid
      INTO TABLE @result.
  ENDMETHOD.


  METHOD zif_ccr_usage_reader~usages.
    " the view holds every procedure of the system: the objects restrict it in the database
    " through a join, and the database sums the procedures per object
    SELECT FROM @objects AS checked
      INNER JOIN susg_i_data AS susg
        ON  susg~obj_type = checked~object_type
        AND susg~obj_name = checked~object_name
      FIELDS susg~obj_type,
             susg~obj_name,
             SUM( susg~counter ) AS executions,
             MAX( susg~last_used ) AS last_used
      WHERE susg~usgid = @usage_id
      GROUP BY susg~obj_type, susg~obj_name
      ORDER BY susg~obj_type, susg~obj_name
      INTO TABLE @result.
  ENDMETHOD.

ENDCLASS.
