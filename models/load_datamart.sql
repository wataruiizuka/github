{{
    config(
        materialized='table',
        destination_dataset='datamart_dataset',
        destination_table='datamart_data'
    )
}}

SELECT
    -- Your aggregation logic here. For example:
    COUNT(column1) as column1_count,
    AVG(column2) as column2_avg,
    ...
FROM
    `{{ var('project_id') }}.dwh_dataset.dwh_data`