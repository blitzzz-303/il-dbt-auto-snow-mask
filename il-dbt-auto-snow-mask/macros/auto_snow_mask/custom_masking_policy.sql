{% macro custom_masking_policy(masking_policy_name) %}

    CREATE MASKING POLICY IF NOT EXISTS {{masking_policy_name}} AS (val string) 
    RETURNS string ->
        CASE 
                WHEN CURRENT_ROLE() IN ('SYSAUDIT', 'PROD_DBT_TRANSFORM', 'DEV_DBT_TRANSFORM') THEN 
                        val
                WHEN CURRENT_ROLE() IN ('SYSADMIN', 'DATA_ENGINEERING') THEN

                {% if mp_map.SEMANTIC_CATEGORY == 'EMAIL' %}
                        regexp_replace(val, '.+\@', SHA2(split(val, '@')[0]) || '@')
                {% else %}
                        SHA2(val)
                {% endif %}

        ELSE '***MASKED***'
        END;

{% endmacro %}