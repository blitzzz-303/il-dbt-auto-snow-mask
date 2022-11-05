{% macro custom_masking_policy(masking_policy_name) %}
declare
  my_exception exception (-20002, 'Raised MY_EXCEPTION.');
begin

    CREATE OR REPLACE MASKING POLICY {{masking_policy_name}} AS (val string) 

    RETURNS string ->
        CASE WHEN CURRENT_ROLE() IN ('SYSAUDIT', 'DBT_TRANSFORM') THEN val
             WHEN CURRENT_ROLE() IN ('SYSADMIN', 'DATA_ENGINEERING') THEN '**custom_masked**'
        ELSE '**********'
        END;

exception
  when statement_error then
    return object_construct('Error type', 'STATEMENT_ERROR',
                            'SQLCODE', sqlcode,
                            'SQLERRM', sqlerrm,
                            'SQLSTATE', sqlstate);
  when my_exception then
    return object_construct('Error type', 'MY_EXCEPTION',
                            'SQLCODE', sqlcode,
                            'SQLERRM', sqlerrm,
                            'SQLSTATE', sqlstate);
  when other then
    return object_construct('Error type', 'Other error',
                            'SQLCODE', sqlcode,
                            'SQLERRM', sqlerrm,
                            'SQLSTATE', sqlstate);
end;

{% endmacro %}