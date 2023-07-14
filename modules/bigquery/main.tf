# データセットを作成
resource "google_bigquery_dataset" "tf_gcp_dbt_dataset" {
  dataset_id    = "tf_gcp_dbt_dataset"           // データセットのIDを指定
  friendly_name = "My Dataset"                   // データセットのフレンドリー名を指定
  description   = "This is a sample description" // データセットの説明
  location      = "US"                           // データセットの場所（ロケーション）を指定
}

# tago2_gcp_dbt_datasetという名前のデータセットを作成
resource "google_bigquery_dataset" "tago2_gcp_dbt_dataset" {
  dataset_id    = "tago2_gcp_dbt_dataset"        // データセットのIDを指定
  friendly_name = "My Dataset"                   // データセットのフレンドリー名を指定
  description   = "This is a sample description" // データセットの説明
  location      = "US"                           // データセットの場所（ロケーション）を指定
}

# tago_dataset_scheduleという名前のデータセットを作成
resource "google_bigquery_dataset" "tago_dataset_schedule" {
  dataset_id    = "tago_dataset_schedule"        // データセットのIDを指定
  friendly_name = "My Dataset"                   // データセットのフレンドリー名を指定
  description   = "This is a sample description" // データセットの説明
  location      = "US"                           // データセットの場所（ロケーション）を指定
}

# テーブルを作成
resource "google_bigquery_table" "tf_gcp_dbt_table" {
  dataset_id = google_bigquery_dataset.tf_gcp_dbt_dataset.dataset_id // テーブルが所属するデータセットのIDを指定
  table_id   = "tf_gcp_dbt_table"                                    // テーブルのIDを指定

  #パーティション設定
  time_partitioning {
    type = "DAY" // パーティショニングのタイプを指定
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
  dataset_id = google_bigquery_dataset.tago2_gcp_dbt_dataset.dataset_id // テーブルが所属するデータセットのIDを指定
  table_id   = "tago2_gcp_dbt_table"                                    // テーブルのIDを指定

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
    source_uris = ["gs://terraform_tago/terraform_sample.csv"] // データ源のURI
    source_format = "CSV" // データ形式
    autodetect = true // スキーマ自動検出

    csv_options {
      skip_leading_rows = 1 // ヘッダースキップ
      quote = "\"" // クォート設定
    }
  }
}

# スケジュールクエリ用のテーブルを作成
resource "google_bigquery_table" "tago_table_dwh_schedule" {
  dataset_id = google_bigquery_dataset.tago_dataset_schedule.dataset_id // テーブルが所属するデータセットのIDを指定
  table_id   = "tago_table_dwh_schedule"                                // テーブルのIDを指定

  # パーティション設定
  time_partitioning {
    type = "DAY" // パーティショニングのタイプを指定
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
  depends_on = [google_bigquery_table.tago_table_dwh_schedule] // リソースの依存関係を設定

  display_name           = "Schedule Query"                                         // データ転送設定の表示名を指定
  location               = "US"                                                     // データ転送設定の場所（ロケーション）を指定
  data_source_id         = "scheduled_query"                                        // データソースのIDを指定
  schedule               = "every day 06:00"                                        // データ転送のスケジュールを指定
  destination_dataset_id = google_bigquery_dataset.tago_dataset_schedule.dataset_id // データ転送先のデータセットのIDを指定
  params = {
    destination_table_name_template = "tago_table_dwh_schedule"                                                            // データ転送先のテーブル名テンプレートを指定
    write_disposition               = "WRITE_APPEND"                                                                       // 書き込み処理の設定を指定
    query                           = "SELECT DAY, sample1 FROM `casa-task-sql.tago2_gcp_dbt_dataset.tago2_gcp_dbt_table`" // 実行するクエリを指定
  }                                                                                                                        // データ転送のパラメータを指定
}