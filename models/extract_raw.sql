{{
    config(
        materialized='table',
        destination_dataset='raw_dataset',
        destination_table='raw_data'
    )
}}

SELECT
    *
FROM
    `{{ var('project_id') }}.my-storage-bucket.my_csv_file`