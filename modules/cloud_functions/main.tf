# Google Cloud FunctionsのFunctionリソースを作成
resource "google_cloudfunctions_function" "my_function" {
  name                  = "terraform-function"       // 関数の名前を指定
  description           = "terraform Cloud Function" // 関数の説明を任意で指定
  runtime               = "nodejs16"                 // 関数のランタイム（実行環境）を指定
  available_memory_mb   = 256                        // 関数の使用可能なメモリ量をメガバイト単位で指定
  timeout               = 60                         // 関数のタイムアウト時間を秒単位で指定
  entry_point           = "helloHttp"                // 関数のエントリーポイント（実行される関数の名前）を指定
  source_archive_bucket = "terraform_tago"           // 関数のソースコードが格納されているバケットの名前を指定
  source_archive_object = "function-source.zip"      // 関数のソースコードが格納されているオブジェクト（ZIPファイルなど）の名前を指定
  trigger_http          = true                       // 関数をHTTPトリガーとして有効にするかどうかを指定
}