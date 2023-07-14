# Google Cloud FunctionsのFunctionリソースを作成
resource "google_cloudfunctions_function" "my_function" {
  name                  = "terraform-function"
  description           = "terraform Cloud Function"
  runtime               = "nodejs16"
  available_memory_mb   = 256
  timeout               = 60
  entry_point           = "helloHttp"
  source_archive_bucket = "terraform_tago"
  source_archive_object = "function-source.zip"
  trigger_http          = true
}