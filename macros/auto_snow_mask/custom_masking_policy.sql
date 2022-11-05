{% macro custom_masking_policy(masking_policy_name) %}
declare
  my_exception exception (-20002, 'Raise');
begin

    CREATE MASKING POLICY {{masking_policy_name}} AS (val string) if not exists

    RETURNS string ->
        CASE WHEN CURRENT_ROLE() IN ('SYSAUDIT', 'DBT_TRANSFORM') THEN val
             WHEN CURRENT_ROLE() IN ('SYSADMIN', 'DATA_ENGINEERING') THEN '**custom_masked**'
        ELSE '**********'
        END;

exception
  when other then
    return object_construct('SQLCODE', sqlcode,
                            'SQLERRM', sqlerrm,
                            'SQLSTATE', sqlstate);
end;

{% endmacro %}