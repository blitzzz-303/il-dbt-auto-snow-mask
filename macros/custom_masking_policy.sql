{% macro custom_generic_masking_policy(mp_map, masking_policy_name) %}
        {% if mp_map.DATA_TYPE != 'TEXT' %}
                {{ custom_generic_number_masking_policy(mp_map, masking_policy_name) }}
        {% else %}
                {{ custom_generic_text_masking_policy(mp_map, masking_policy_name) }}
        {% endif %}
{% endmacro %}

{% macro custom_generic_text_masking_policy(mp_map, masking_policy_name) %}

    CREATE MASKING POLICY IF NOT EXISTS {{masking_policy_name}} AS (val string) 
    RETURNS string ->
        CASE 
                WHEN CURRENT_ROLE() IN ('SYSAUDIT', 'PROD_DBT_TRANSFORM', 'DEV_DBT_TRANSFORM') THEN 
                        val
                WHEN CURRENT_ROLE() IN ('SYSADMIN', 'DATA_ENGINEERING', 'HT_DEV_PII_RW') THEN
                {% if mp_map.SEMANTIC_CATEGORY == 'EMAIL' %}
                        regexp_replace(val, '.+\@', SHA2(split(val, '@')[0]) || '@')
                {% else %}
                        SHA2(val)
                {% endif %}
        ELSE '***MASKED***'
        END;

{% endmacro %}

{% macro custom_generic_number_masking_policy(mp_map, masking_policy_name) %}

    CREATE MASKING POLICY IF NOT EXISTS {{masking_policy_name}} AS (val number) 
    RETURNS number ->
        CASE 
                WHEN CURRENT_ROLE() IN ('SYSAUDIT', 'PROD_DBT_TRANSFORM', 'DEV_DBT_TRANSFORM', 'SYSADMIN', 'DATA_ENGINEERING', 'HT_DEV_PII_RW') THEN 
                        val
        ELSE hash(val)
        END;

{% endmacro %}