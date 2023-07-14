# TerraformがGoogle Cloud Platformへのアクセスを提供するためのプロバイダの設定
provider "google" {
  credentials           = file(var.credentials_file)
  project               = var.project_name
  region                = "us-central1"
  zone                  = "us-central1" // リソースを作成するGCPゾーン(GCPのゾーン指定)
  user_project_override = true          // リソースを作成するGCPゾーン(GCPのゾーン指定)
  request_timeout       = "10m"         // 全リクエストのタイムアウト(リクエストのタイムアウト)
  scopes = [                            //OAuth 2.0スコープのリスト
    "https://www.googleapis.com/auth/cloud-platform",
    "https://www.googleapis.com/auth/compute",
    "https://www.googleapis.com/auth/cloud-platform.read-only",
    "https://www.googleapis.com/auth/cloud-platform.googleapis.com",
    "https://www.googleapis.com/auth/bigquery",
    "https://www.googleapis.com/auth/pubsub"
  ]
  billing_project = "casa-task-sql" //APIリクエストの課金先(課金プロジェクト指定)
}

# 新しいGoogle Cloudプロジェクトを作成
resource "google_project" "project" {
  name                = var.project_name
  project_id          = var.project_id
  org_id              = var.org_id
  auto_create_network = false
  labels = {
    environment = "production"  // プロジェクトに"environment"というキーのラベルを追加し、値として"production"を設定
    team        = "engineering" // プロジェクトに"team"というキーのラベルを追加し、値として"engineering"を設定
  }
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

#BucketのACL設定
data "google_project" "project" {
  project_id = "casa-task-sql"
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