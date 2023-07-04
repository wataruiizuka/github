provider "google" {
  credentials = file(var.credentials_file)
  project     = var.project_name
  region      = "us-central1"
}

resource "google_project" "project" {
  name       = var.project_name
  project_id = var.project_id
  org_id     = var.org_id
}

resource "google_project_service" "bigquery" {
  project = google_project.project.project_id
  service = "bigquery.googleapis.com"
}

resource "google_project_service" "cloud_storage" {
  project = google_project.project.project_id
  service = "storage.googleapis.com"
}

resource "google_service_account" "service_account" {
  account_id   = var.service_account_id
  display_name = "Service Account for data analysis"
  project      = google_project.project.project_id
}

resource "google_project_iam_binding" "binding" {
  project = google_project.project.project_id
  role    = "roles/bigquery.dataEditor"

  members = [
    "serviceAccount:${google_service_account.service_account.email}",
  ]
}

resource "google_bigquery_dataset" "tf_gcp_dbt_dataset" {
  dataset_id                  = "tf_gcp_dbt_dataset"
  friendly_name               = "My Dataset"
  description                 = "This is a sample description"
  location                    = "US"
}

resource "google_bigquery_table" "tf_gcp_dbt_table" {
  dataset_id = google_bigquery_dataset.tf_gcp_dbt_dataset.dataset_id
  table_id   = "tf_gcp_dbt_table"

  time_partitioning {
    type = "DAY"
  }

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