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

#Bucketの作成と設定
resource "google_storage_bucket" "bucket" {
  name     = "kamiyama-terraform"
  location = "US"
  storage_class = "STANDARD"
  force_destroy = true

#バージョニング
  versioning {
    enabled = true
  }
}

#BucketのACL設定
data "google_project" "project" {
  project_id = "casa-task-sql"
}

resource "google_storage_bucket_acl" "bucket_acl" {
  bucket = google_storage_bucket.bucket.name
  role_entity = [
    "OWNER:user-ayane.kamiyama@casa-llc.com",
    "READER:user-shiori.tago@casa-llc.com",
  ]
}

#Bucket Policyの管理
data "google_iam_policy" "bucket_admin" {
  binding {
    role = "roles/storage.admin"
    members = [
      "user:ayane.kamiyama@casa-llc.com",
      "user:shiori.tago@casa-llc.com"
    ]
  }
}

#iam policyの設定
resource "google_storage_bucket_iam_member" "member" {
  bucket = google_storage_bucket.bucket.name
  role   = "roles/storage.objectViewer"
  member = "user:ayane.kamiyama@casa-llc.com"
}

resource "google_storage_bucket_iam_policy" "bucket_policy" {
  bucket      = google_storage_bucket.bucket.name
  policy_data = data.google_iam_policy.bucket_admin.policy_data
}

#BucketのDefault Object ACL設定
resource "google_storage_default_object_acl" "default_acl" {
  bucket = google_storage_bucket.bucket.name
  role_entity = [
    "OWNER:user-ayane.kamiyama@casa-llc.com",
    "READER:user-shiori.tago@casa-llc.com",
  ]
}

#Objectの作成と管理
resource "google_storage_bucket_object" "object" {
  name   = "test"
  bucket = google_storage_bucket.bucket.name
  source = "/Users/kamiyamaayane/Downloads/test.csv"
}

#ObjectのACL設定
resource "google_storage_object_acl" "object_acl" {
  object = google_storage_bucket_object.object.name
  bucket = google_storage_bucket.bucket.name
  role_entity = [
    "OWNER:user-ayane.kamiyama@casa-llc.com",
    "READER:user-shiori.tago@casa-llc.com",
  ]
}

#Transfer Jobの作成と管理** (GCS to GCS の例)
resource "google_storage_transfer_job" "transfer_job" {
  description = "test-transfer-job"
  project     = "casa-task-sql"

  transfer_spec {
    gcs_data_source {
      bucket_name = "kamiyama-terraform"
    }
    gcs_data_sink {
      bucket_name = "tf_gcp_dbt_bucket"
    }
    object_conditions {
      max_time_elapsed_since_last_modification = "600s"
      min_time_elapsed_since_last_modification = "60s"
    }
  }

  schedule {
    schedule_start_date {
      year  = 2023
      month = 7
      day   = 5
    }
    schedule_end_date {
      year  = 2024
      month = 7
      day   = 5
    }
    start_time_of_day {
      hours   = 0
      minutes = 30
      seconds = 0
      nanos   = 0
    }
  }
}

#google container clusterの設定
resource "google_container_cluster" "my_cluster" {
  name               = "kamiyama-gke-cluster"
  location           = "US"
  initial_node_count = 3
  min_master_version = "1.18.16-gke.302"

  node_config {
    machine_type = "n1-standard-2"
    disk_size_gb = 100

    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring"
    ]
  }
}

#google container node poolの設定
resource "google_container_node_pool" "my_node_pool" {
  name       = "kamiyama-node-pool"
  cluster    = google_container_cluster.my_cluster.name
  location   = google_container_cluster.my_cluster.location
  node_count = 3

  node_config {
    machine_type = "n1-standard-2"
    disk_size_gb = 100

    # ノードの設定など...
  }
}

#google_sql_database
resource "google_sql_database" "my_database" {
  name     = "kamiyama-database"
  instance = "kamiyama-instance"
}

#google_sql_instance(エラー修正中)
resource "google_sql_database_instance" "my_instance" {
  name             = "kamiyama-instance"
  database_version = "MYSQL_5_7"

  settings {
    tier = "db-n1-standard-1"
  }
}

resource "google_storage_notification" "notification" {
  bucket        = google_storage_bucket.bucket.name
  payload_format = "JSON_API_V1"
  topic         = google_pubsub_topic.example.id
  event_types   = ["OBJECT_FINALIZE"]
  custom_attributes = {
    key1 = "value1"
    key2 = "value2"
  }
}

resource "google_pubsub_topic" "example" {
  name = "terraform-test"
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