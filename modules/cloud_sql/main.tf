#データベースの作成
resource "google_sql_database" "my_database" {
  name      = "kamiyama-database" // データベースの名前を指定
  instance  = "kamiyama-instance" // データベースが所属するCloud SQLインスタンスの名前を指定
  charset   = "utf8"              // 文字セットの設定
  collation = "utf8_general_ci"   // 照合順序の設定
}

#データベースインスタンスの作成
resource "google_sql_database_instance" "my_instance" {
  name             = "kamiyama-instance" // インスタンスの名前を指定
  database_version = "MYSQL_5_7"         // インスタンスのデータベースバージョンを指定

  settings {
    tier = "db-n1-standard-1" // インスタンスのパフォーマンスレベルを示すティア（階層）を指定
  }                           // インスタンスの設定
}

#データベースユーザーの作成
resource "google_sql_user" "example_user" {
  name     = "test-kamiyama"                             // ユーザーの名前を指定
  instance = google_sql_database_instance.my_instance.id // ユーザーが所属するCloud SQLデータベースインスタンスのIDを指定
  password = "20230711"                                  // ユーザーのパスワードを指定
  project  = "casa-task-sql"                             // プロジェクトを指定
}