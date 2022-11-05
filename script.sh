#!/bin/sh
dbt seed --profiles-dir ./.dbt/
dbt run --profiles-dir ./.dbt/ --vars 'run_mode: APPLY'
