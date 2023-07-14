#データベースの作成
resource "google_sql_database" "my_database" {
  name      = "kamiyama-database"
  instance  = "kamiyama-instance"
  charset   = "utf8"            // 文字セットの設定
  collation = "utf8_general_ci" // 照合順序の設定
}

#データベースインスタンスの作成
resource "google_sql_database_instance" "my_instance" {
  name             = "kamiyama-instance"
  database_version = "MYSQL_5_7"

  settings {
    tier = "db-n1-standard-1"
  } // インスタンスを作成するリージョンを指定
}

#データベースユーザーの作成
resource "google_sql_user" "example_user" {
  name     = "test-kamiyama"
  instance = google_sql_database_instance.my_instance.id
  password = "20230711"
  project  = "casa-task-sql" // プロジェクトを指定
}