# TerraformがGoogle Cloud Platformへのアクセスを提供するためのプロバイダの設定
provider "google" {
  credentials = file(var.credentials_file)
  project     = var.project_name
  region      = "us-central1"
}

# 新しいGoogle Cloudプロジェクトを作成
resource "google_project" "project" {
  name       = var.project_name
  project_id = var.project_id
  org_id     = var.org_id
}

# プロジェクトに対してBigQueryサービスを有効化
resource "google_project_service" "bigquery" {
  project = google_project.project.project_id
  service = "bigquery.googleapis.com"
}

# プロジェクトに対してCloud Storageサービスを有効化
resource "google_project_service" "cloud_storage" {
  project = google_project.project.project_id
  service = "storage.googleapis.com"
}

# 新しいサービスアカウントを作成
resource "google_service_account" "service_account" {
  account_id   = var.service_account_id
  display_name = "Service Account for data analysis"
  project      = google_project.project.project_id
}

# IAMバインディングを作成
resource "google_project_iam_binding" "binding" {
  project = google_project.project.project_id
  role    = "roles/bigquery.dataEditor"

# バインディングに含まれるメンバーを指定
  members = [
    "serviceAccount:${google_service_account.service_account.email}",
  ]
}

## Google Pub/Subのトピックリソースを作成
resource "google_pubsub_topic" "my_topic" {
  name = "terraform-topic"
}

# Google Pub/Subのサブスクリプションリソースを作成
resource "google_pubsub_subscription" "my_subscription" {
  name  = "terraform-subscription"
  topic = google_pubsub_topic.my_topic.name
}

# Google Cloud DNSのManaged Zoneリソースを作成
resource "google_dns_managed_zone" "my_zone" {
  name        = "terraform-zone"
  dns_name    = "terraform.example.com."  # ドメイン名を指定
  description = "terraform DNS Zone" #任意の説明
}

# Google Cloud DNSのRecord Setリソースを作成
resource "google_dns_record_set" "my_record_set" {
  name    = "terraform.example.com."  # レコード名を指定
  type    = "A"                 # レコードタイプを指定
  ttl     = 300                 # TTL（Time To Live）を指定
  rrdatas = ["192.0.2.1"]       # レコードデータを指定

  managed_zone = google_dns_managed_zone.my_zone.name
}

# Google Cloud SpannerのInstanceリソースを作成
resource "google_spanner_instance" "my_instance" {
  name        = "terraform-instance"
  config      = "regional-us-central1"
  num_nodes   = 1
  display_name = "terraform-sample"
}

# Google Cloud SpannerのDatabaseリソースを作成
resource "google_spanner_database" "my_database" {
  name     = "terraform-database"
  instance = google_spanner_instance.my_instance.name
}

# データセットを作成
resource "google_bigquery_dataset" "tf_gcp_dbt_dataset" {
  dataset_id                  = "tf_gcp_dbt_dataset"
  friendly_name               = "My Dataset"
  description                 = "This is a sample description"
  location                    = "US"
}

# tago2_gcp_dbt_datasetという名前のデータセットを作成
resource "google_bigquery_dataset" "tago2_gcp_dbt_dataset" {
  dataset_id      = "tago2_gcp_dbt_dataset"
  friendly_name   = "My Dataset"
  description     = "This is a sample description"
  location        = "US"
}

# tago_dataset_scheduleという名前のデータセットを作成
resource "google_bigquery_dataset" "tago_dataset_schedule" {
  dataset_id      = "tago_dataset_schedule"
  friendly_name   = "My Dataset"
  description     = "This is a sample description"
  location        = "US"
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
    autodetect = true

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
