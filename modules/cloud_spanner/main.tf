# Google Cloud SpannerのInstanceリソースを作成
resource "google_spanner_instance" "my_instance" {
  name         = "terraform-instance"
  config       = "regional-us-central1"
  num_nodes    = 1
  display_name = "terraform-sample"
}

# Google Cloud SpannerのDatabaseリソースを作成
resource "google_spanner_database" "my_database" {
  name     = "terraform-database"
  instance = google_spanner_instance.my_instance.name
}