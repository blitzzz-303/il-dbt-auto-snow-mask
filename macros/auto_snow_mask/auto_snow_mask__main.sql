{% macro apply_masking_policy(OPERATION_TYPE = 'APPLY', limit = 55, threshold = 0.4) %}
    {{ auto_snow_mask.run(OPERATION_TYPE, limit, threshold) }}
{% endmacro %}

{% macro run(OPERATION_TYPE, limit, threshold, PII_FUNC_CUSTOM = 'pii_custom') %}
    {% if execute %}
        {% set mp_map_objs = auto_snow_mask.get_mp_map(limit, threshold, PII_FUNC_CUSTOM)%}
        {% do auto_snow_mask.create_and_apply_mp(mp_map_objs, OPERATION_TYPE, PII_FUNC_CUSTOM) %}
    {% endif %}
{% endmacro %}


{% macro get_mp_map(limit, threshold, PII_FUNC_CUSTOM, PII_TYPE_TAG = 'pii')%}
    {% set meta_fld_obj = auto_snow_mask.get_meta_objs(model.unique_id, PII_TYPE_TAG) %}
    {% set meta_pii_custom_obj = auto_snow_mask.get_meta_objs(model.unique_id, PII_FUNC_CUSTOM) %}
    {% set mp_map_stm = auto_snow_mask.get_mp_stm(model, limit, meta_fld_obj, meta_pii_custom_obj, threshold) %}
    {% set mp_map_objs = auto_snow_mask.get_query_results_as_obj(mp_map_stm) %}
    {{ return(mp_map_objs) }}
{% endmacro %}


{% macro create_and_apply_mp(mp_map_objs, OPERATION_TYPE, PII_FUNC_CUSTOM, PII_INGORE_TAG = 'IGNORE') %}

    {% for mp_map_obj in mp_map_objs if mp_map_obj.SEMANTIC_CATEGORY != PII_INGORE_TAG %}
        {% set mp_stm = auto_snow_mask.create_mp(model, mp_map_obj, PII_FUNC_CUSTOM) %}
        {% set mp_name = run_query(mp_stm).columns[0].values()[0] %}

        {% if OPERATION_TYPE != 'SCAN' %}
            {% set apply_mt_stm = auto_snow_mask.get_apply_mp_stm(model, mp_map_obj.FLD, mp_name, OPERATION_TYPE)%}

            {% do run_query(apply_mt_stm) %}
            {{ log(modules.datetime.datetime.now().strftime("%H:%M:%S") ~ " | " 
                ~ OPERATION_TYPE ~ " masking policy : model [" ~ mp_name 
                ~ "] -> field [" ~ mp_map_obj.FLD ~ "]", info=True) }}
        {% else %}
            {{ log(modules.datetime.datetime.now().strftime("%H:%M:%S") ~ " | " 
                ~ OPERATION_TYPE ~ " mode found PII related field ["
                ~ model.database ~ "." ~ model.schema ~ "." ~ model.alias ~ "." ~ mp_map_obj.FLD ~ "]", info=True) }}
        {% endif %}

    {% endfor %}
{% endmacro %}