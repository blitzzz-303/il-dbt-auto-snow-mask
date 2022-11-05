# Dbt Auto Mask POC

POC demo for https://github.com/hung-il/il-dbt-auto-snow-mask package

# Overview

The dbt-auto-snow-mask macro can help you to protect your customer data in the Snowflake data warehouse by using the Snowflake masking policy feature and EXTRACT_SEMANTIC_CATEGORIES.

## What is Snowflake masking policy?

It is a feature from Snowflake to allow users to anonymize their data with conditions, without affecting to the original data.

Though this feature does not alter your source data, it can affect to other data sources that are fed on the anonymized sources.

## What is EXTRACT_SEMANTIC_CATEGORIES function?

For me, it looks like a pre-built ML model that analyses and classifies your table data.

For example, if I want this function to analyze my table, I use the below command


```
select
    KEY,
    f.value:"privacy_catgory"::varchar privacy_category,
    f.value:"semantic_category"::varchar semantic_category,
    f.value:"extra_info":"probability"::numeric probability,
    f.*
from
TABLE (flatten(extract_semantic_categories('ht_DEV.dbt_ht.RAW_CUSTOMER_INFO', 10)::variant)) as f
```

Add the following code to your packages.yml file.

  - git: https://github.com/hung-il/il-dbt-auto-snow-mask.git
    warn-unpinned: false

This package uses dbt_utils package. When using auto_dbt_snow_mask in your project, please install dbt_utils as well. You will get an error if you attempt to use this package without installing auto_dbt_snow_mask

Then use below commands to download the package

`dbt deps`

# Basic usage

To use the package, simply add the post hook action to your model file

```
models:
  pii_project:
    materialized: view
    int:
      materialized: table
      +tags: "main"
      post-hook: 
        - "{{ auto_snow_mask.apply_masking_policy() }}"
```


The macro will automatically scan the folder and apply the masking rules.


You can also set the ignore tag manually if you don’t want to apply masking policies for quasi-identifiers.

```
version: 2

models:
  - name: customer_info
    columns:
      - name: City
        meta:
          pii: TEXT
      - name: Gender
        meta:
          pii: IGNORE
```


to specify my custom masking policy for the model and the Email field.

```
version: 2

models:
  - name: customer_info
    columns:
      - name: Email
        meta:
          pii: Email
          pii_custom: custom_masking_policy_email
    meta:
      pii: TEXT
      pii_custom: custom_masking_policy
```





