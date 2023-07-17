{{
    config(
        materialized='table',
        destination_dataset='dwh_dataset',
        destination_table='dwh_data'
    )
}}

SELECT
    -- Your transformation logic here. For example:
    CAST(column1 AS STRING) as column1,
    FORMAT_TIMESTAMP('%Y-%m-%d', timestamp_column) as timestamp_column,
    ...
FROM
    `{{ var('project_id') }}.raw_dataset.raw_data`