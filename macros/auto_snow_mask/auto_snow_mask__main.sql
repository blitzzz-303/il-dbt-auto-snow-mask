{% macro apply_masking_policy(limit = 55, threshold = 0.55) %}
    {{ auto_snow_mask.run(limit, threshold) }}
{% endmacro %}

{% macro run(limit, threshold, PII_FUNC_CUSTOM = 'pii_custom') %}
    {% if execute %}
        {% set mp_map = auto_snow_mask.get_mp_map(limit, threshold, PII_FUNC_CUSTOM)%}
        {% do auto_snow_mask.create_and_apply_mp(mp_map, PII_FUNC_CUSTOM) %}
    {% endif %}
{% endmacro %}


{% macro get_mp_map(limit, threshold, PII_FUNC_CUSTOM, PII_TYPE_TAG = 'pii')%}
    {% set meta_fld_obj = auto_snow_mask.get_meta_objs(model.unique_id, PII_TYPE_TAG) %}
    {% set meta_pii_custom_obj = auto_snow_mask.get_meta_objs(model.unique_id, PII_FUNC_CUSTOM) %}
    {% set mp_map_stm = auto_snow_mask.get_mp_stm(model, limit, meta_fld_obj, meta_pii_custom_obj, threshold) %}
    {% set mp_map = dbt_utils.get_query_results_as_dict(mp_map_stm) %}
    {{ return(mp_map) }}
{% endmacro %}


{% macro create_and_apply_mp(mp_map, PII_FUNC_CUSTOM, PII_INGORE_TAG = 'IGNORE') %}
    {% for n in range(mp_map.FLD | length) if mp_map.SEMANTIC_CATEGORY[n] != PII_INGORE_TAG %}
        {% set mp_stm = auto_snow_mask.create_mp(model, mp_map, n, PII_FUNC_CUSTOM) %}
        {% set mp_name = run_query(mp_stm).columns[0].values()[0] %}
        {% set apply_mt_stm = auto_snow_mask.get_apply_mp_stm(model, mp_map.FLD[n], mp_name)%}
        {% do run_query(apply_mt_stm) %}
    {% endfor %}
{% endmacro %}