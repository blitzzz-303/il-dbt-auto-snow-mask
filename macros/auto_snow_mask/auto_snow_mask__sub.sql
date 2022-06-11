{% macro create_mp(model, mp_map, n, PII_FUNC_CUSTOM, DEFAULT_TAG = 'default') %}
     {% set mp = model.database + '.' + model.schema + '.' + model.unique_id | replace('.', '__') + '__' + mp_map.FLD[n] %}
     
     {% if mp_map.PII_CUSTOM[n] != DEFAULT_TAG %}
          {% set call_masking_policy_macro = context[mp_map.PII_CUSTOM[n]]  %}
          {% do run_query(call_masking_policy_macro(mp)) %}
     {% elif model.meta | length != 0 %}
          {% for k, v in model.meta.items() if k == PII_FUNC_CUSTOM %}
               {% set call_masking_policy_macro = context[v]  %}
               {% do run_query(call_masking_policy_macro(mp)) %}
          {% endfor %}
     {% else %}
          CREATE OR REPLACE MASKING POLICY {{mp}} AS (val string) 
          RETURNS string ->
               CASE WHEN CURRENT_ROLE() IN ('AUDIT') THEN val
                    WHEN CURRENT_ROLE() IN ('SYSADMIN', 'DATA_ENGINEERING') THEN 
                    {% if mp_map.SEMANTIC_CATEGORY[n] == 'EMAIL' %}
                         regexp_replace(val,'.+\@','*****@')
                    {% else %}
                         SHA2(val)
                    {% endif %}
               ELSE '**********'
               END;
     {% endif %}
     select '{{mp}}' mp_name;
{% endmacro %}


{% macro get_apply_mp_stm(model, fld, mp_name) %}
          alter {{model.config.get("materialized")}}  {{model.database}}.{{model.schema}}.{{model.alias}}
          modify column {{fld}} 
          unset masking policy;

          alter {{model.config.get("materialized")}}  {{model.database}}.{{model.schema}}.{{model.alias}}
          modify column {{fld}} 
          set masking policy {{mp_name}};
{% endmacro %}


{% macro get_meta_objs(node_unique_id, meta_key,node_resource_type="model") %}
	{% if execute %}

        {% set meta_objs = {} %}
        {% if node_resource_type == "source" %} 
            {% set columns = graph.sources[node_unique_id]['columns']  %}
        {% else %}
            {% set columns = graph.nodes[node_unique_id]['columns']  %}
        {% endif %}

        {% if meta_key is not none %}
            {% if node_resource_type == "source" %} 
                {% for column in columns if graph.sources[node_unique_id]['columns'][column]['meta'][meta_key] | length > 0 %}
                    {% set meta_dict = graph.sources[node_unique_id]['columns'][column]['meta'] %}
                    {% for key, value in meta_dict.items() if key == meta_key %}
                        {% do meta_objs.update({column: value}) %}
                    {% endfor %}
                {% endfor %}
            {% else %}
                {% for column in columns if graph.nodes[node_unique_id]['columns'][column]['meta'][meta_key] | length > 0 %}
                    {% set meta_dict = graph.nodes[node_unique_id]['columns'][column]['meta'] %}
                    {% for key, value in meta_dict.items() if key == meta_key %}
                         {% do meta_objs.update({column: value}) %}
                    {% endfor %}
                {% endfor %}
            {% endif %}
        {% endif %}

        {{ return(meta_objs) }}

    {% endif %}
{% endmacro %}


{% macro get_mp_stm(model, limit, meta_fld_obj, meta_pii_custom_obj, threshold) %}
     show columns in table {{model.relation_name}};
     with 
     meta_fld_conf as(
          select 
               lower(key) fld,
               value semantic_category
          from table(flatten(input => parse_json('{{meta_fld_obj | replace("\'","\"")}}'))) f
     ),
     meta_pii_custom as (
          select 
               lower(key) fld,
               value pii_custom
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
               f.value:"privacy_catgory"::varchar privacy_category,
               f.value:"semantic_category"::varchar semantic_category,
               f.value:"extra_info":"probability"::numeric probability
          from
          TABLE (flatten(extract_semantic_categories('{{model.relation_name}}', {{limit}})::variant)) as f
          where probability >= {{threshold}})
     select 
          fld,
          coalesce(mfc.semantic_category, s.semantic_category) semantic_category,
          coalesce(mpc.pii_custom, 'default') pii_custom
     from tbl_info
     left join semantic s using (fld)
     left join meta_fld_conf mfc using (fld)
     left join meta_pii_custom mpc using (fld)
     where (data_type = 'TEXT' and semantic_category is not null) or mfc.semantic_category is not null;
{% endmacro %}