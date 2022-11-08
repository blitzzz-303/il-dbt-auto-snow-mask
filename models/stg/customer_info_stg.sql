with ci as (
    select * from {{ ref('raw_customer_info')}}
)
select * from ci limit 1000