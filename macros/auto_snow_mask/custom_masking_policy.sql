{% macro custom_masking_policy(masking_policy_name) %}

    CREATE OR REPLACE MASKING POLICY {{masking_policy_name}} AS (val string) 

    RETURNS string ->
        CASE WHEN CURRENT_ROLE() IN ('AUDIT') THEN val
             WHEN CURRENT_ROLE() IN ('SYSADMIN', 'DATA_ENGINEERING') THEN '**custom_masked**'
        ELSE '**********'
        END;

{% endmacro %}