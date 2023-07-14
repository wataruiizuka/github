# データセットを作成
resource "google_bigquery_dataset" "tf_gcp_dbt_dataset" {
  dataset_id    = "tf_gcp_dbt_dataset"
  friendly_name = "My Dataset"
  description   = "This is a sample description"
  location      = "US"
}

# tago2_gcp_dbt_datasetという名前のデータセットを作成
resource "google_bigquery_dataset" "tago2_gcp_dbt_dataset" {
  dataset_id    = "tago2_gcp_dbt_dataset"
  friendly_name = "My Dataset"
  description   = "This is a sample description"
  location      = "US"
}

# tago_dataset_scheduleという名前のデータセットを作成
resource "google_bigquery_dataset" "tago_dataset_schedule" {
  dataset_id    = "tago_dataset_schedule"
  friendly_name = "My Dataset"
  description   = "This is a sample description"
  location      = "US"
}

# テーブルを作成
resource "google_bigquery_table" "tf_gcp_dbt_table" {
  dataset_id = google_bigquery_dataset.tf_gcp_dbt_dataset.dataset_id
  table_id   = "tf_gcp_dbt_table"

  #パーティション設定
  time_partitioning {
    type = "DAY"
  }

  # テーブルのスキーマを指定
  schema = <<EOF
[
  {
    "name": "name",
    "type": "STRING",
    "mode": "REQUIRED"
  }
]
EOF
}

# tago2~という名前のテーブルを作成
resource "google_bigquery_table" "tago2_gcp_dbt_table" {
  dataset_id = google_bigquery_dataset.tago2_gcp_dbt_dataset.dataset_id
  table_id   = "tago2_gcp_dbt_table"

  #外部データはパーティション設定ができない

  # テーブルのスキーマを指定
  schema = <<EOF
[
  {"name": "DAY", "type": "DATE", "mode": "NULLABLE"},
  {"name": "sample1", "type": "STRING", "mode": "NULLABLE"},
  {"name": "sample2", "type": "INTEGER", "mode": "NULLABLE"},
  {"name": "sample3", "type": "INTEGER", "mode": "NULLABLE"}
]
EOF

  # アップロード元の設定（GCSのcsvファイルをアップロードする）
  external_data_configuration {
    source_format = "CSV"
    source_uris   = ["gs://terraform_tago/terraform_sample.csv"]
    autodetect    = true

    csv_options {
      skip_leading_rows = 1
      quote             = "\""
    }
  }
}

# スケジュールクエリ用のテーブルを作成
resource "google_bigquery_table" "tago_table_dwh_schedule" {
  dataset_id = google_bigquery_dataset.tago_dataset_schedule.dataset_id
  table_id   = "tago_table_dwh_schedule"

  # パーティション設定
  time_partitioning {
    type = "DAY"
  }

  # テーブルのスキーマを指定
  schema = <<EOF
[
  {"name": "DAY", "type": "DATE", "mode": "NULLABLE"},
  {"name": "sample1", "type": "STRING", "mode": "NULLABLE"}
]
EOF
}

# スケジュールクエリの設定
resource "google_bigquery_data_transfer_config" "query_config" {
  depends_on = [google_bigquery_table.tago_table_dwh_schedule]

  display_name           = "Schedule Query"
  location               = "US"
  data_source_id         = "scheduled_query"
  schedule               = "every day 06:00"
  destination_dataset_id = google_bigquery_dataset.tago_dataset_schedule.dataset_id
  params = {
    destination_table_name_template = "tago_table_dwh_schedule"
    write_disposition               = "WRITE_APPEND"
    query                           = "SELECT DAY, sample1 FROM `casa-task-sql.tago2_gcp_dbt_dataset.tago2_gcp_dbt_table`"

  }
}