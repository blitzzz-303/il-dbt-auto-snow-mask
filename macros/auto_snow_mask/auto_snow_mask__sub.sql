{% macro create_mp(model, mp_map, PII_FUNC_CUSTOM, DEFAULT_TAG = 'default') %}
     {% set mp = model.database + '.' + model.schema + '.GENERIC_' + mp_map.SEMANTIC_CATEGORY %}
     {% if mp_map.PII_CUSTOM != DEFAULT_TAG %}
          {% set call_masking_policy_macro = context[mp_map.PII_CUSTOM]  %}
          {{ call_masking_policy_macro(mp_map, mp) }}
     {% else %}
          {% set custom_generic_mp = context["custom_generic_masking_policy"]  %}
          {% if custom_generic_mp is defined %}
               {{ custom_generic_mp(mp_map, mp) }}
          {% else %}
               {{ auto_snow_mask.default_generic_masking_policy(mp_map, mp) }}
          {% endif %}
     {% endif %}
     select '{{mp}}' mp_name;
{% endmacro %}

{% macro get_apply_mp_stm(model, fld, mp_name, OPERATION_TYPE) %}
     {% if OPERATION_TYPE == 'UNAPPLY' %}
          alter {{model.config.get("materialized")}}  {{model.database}}.{{model.schema}}.{{model.alias}}
          modify column {{fld}} 
          unset masking policy;
     {% endif %}
     {% if OPERATION_TYPE == 'APPLY' %}
          alter {{model.config.get("materialized")}}  {{model.database}}.{{model.schema}}.{{model.alias}}
          modify column {{fld}} 
          set masking policy {{mp_name}};
     {% endif %}
{% endmacro %}


{% macro get_meta_objs(node_unique_id, meta_key) %}
     {% set meta_objs = {} %}
     {% if meta_key %}
          {% for table in graph.nodes[node_unique_id]['config']['tables'] %}
               {% for column in table['columns'] if column['meta'][meta_key] %}
                    {% do meta_objs.update({column['name']: column['meta'][meta_key]}) %}
               {% endfor %}
          {% endfor %}
     {% endif %}
     {{ return(meta_objs) }}
{% endmacro %}


{% macro get_query_results_as_obj(stm) %}
     {% set d = dbt_utils.get_query_results_as_dict(stm) %}
     {% set output_objs = [] %}
     {% set n_items = [] %}
     {% for k, v in d.items() if n_items|length == 0 %}
          {% do n_items.append(v|length) %}
     {% endfor %}
     {% for n in range(n_items[0])%}
          {% set tmp_obj = {} %}
          {% for k, v in d.items() %}
               {% do tmp_obj.update({k : v[n]}) %}
          {% endfor %}
          {% do output_objs.append(tmp_obj) %}
     {% endfor %}
     {{ return(output_objs) }}
{% endmacro %}


{% macro get_mp_stm(model, limit, meta_fld_obj, meta_pii_custom_obj, threshold) %}
     show columns in table {{model.relation_name}};
     with 
     meta_fld_conf as(
          select 
               lower(key) fld,
               value semantic_category,
               'MANUAL' masking_task
          from table(flatten(input => parse_json('{{meta_fld_obj | replace("\'","\"")}}'))) f
     ),
     meta_pii_custom as (
          select 
               lower(key) fld,
               value pii_custom,
               'MANUAL' masking_task
          from table(flatten(input => parse_json('{{meta_pii_custom_obj | replace("\'","\"")}}'))) f
     ),
     tbl_info as(
          select
               lower("column_name") fld,
               parse_json("data_type"):type::string data_type
          from table(result_scan(last_query_id()))
     ),
     semantic as (
          select
               lower(KEY) fld,
               '[AUTO]' masking_task,
               coalesce(f.value:"semantic_category",
                        f.value:"extra_info":"alternates"[0]:semantic_category)::varchar semantic_category,
               coalesce(f.value:"extra_info":"probability",
                        f.value:"extra_info":"alternates"[0]:probability)::double probability
          from
          TABLE (flatten(extract_semantic_categories('{{model.relation_name}}', {{limit}})::variant)) as f
          where probability >= {{threshold}})
     select 
          fld,
          data_type,
          coalesce(mfc.semantic_category, s.semantic_category) semantic_category,
          coalesce(mpc.pii_custom, 'default') pii_custom,
          coalesce(s.masking_task, mfc.masking_task, mpc.masking_task) masking_task
     from tbl_info
     left join semantic s using (fld)
     left join meta_fld_conf mfc using (fld)
     left join meta_pii_custom mpc using (fld)
     where coalesce(s.semantic_category, mfc.semantic_category) is not null;
{% endmacro %}