# Google Cloud SpannerのInstanceリソースを作成
resource "google_spanner_instance" "my_instance" {
  name         = "terraform-instance"                                          // インスタンスの名前を指定
  config       = "projects/casa-task-sql/instanceConfigs/regional-us-central1" // インスタンスの設定（コンフィグレーション）を指定
  num_nodes    = 1                                                             // インスタンスのノード数を指定
  display_name = "terraform-sample"                                            // インスタンスの表示名を指定
}

# Google Cloud SpannerのDatabaseリソースを作成
resource "google_spanner_database" "my_database" {
  name     = "terraform-database"                     // データベースの名前を指定
  instance = google_spanner_instance.my_instance.name // データベースが関連付けられるインスタンスの名前を指定
}