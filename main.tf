# TerraformがGoogle Cloud Platformへのアクセスを提供するためのプロバイダの設定
provider "google" {
  credentials           = file(var.credentials_file) // GCPにアクセスするための認証情報を指定
  project               = var.project_name           // 使用するGCPプロジェクトの名前を指定
  region                = "us-central1"              // リソースを作成するGCPリージョンを指定
  zone                  = "us-central1"              // リソースを作成するGCPゾーン(GCPのゾーン指定)
  user_project_override = true                       // 特定のプロジェクトが複数のプロジェクトにまたがるリソースの費用を負担する必要があるかどうか
  request_timeout       = "10m"                      // 全リクエストのタイムアウト(リクエストのタイムアウト)
  scopes = [
    "https://www.googleapis.com/auth/cloud-platform",
    "https://www.googleapis.com/auth/compute",
    "https://www.googleapis.com/auth/cloud-platform.googleapis.com",
    "https://www.googleapis.com/auth/pubsub",
    "https://www.googleapis.com/auth/bigquery",
    "https://www.googleapis.com/auth/bigquery.insertdata",
    "https://www.googleapis.com/auth/bigquery.data"
  ]
  billing_project = "casa-task-sql" // 課金プロジェクトの変数を使用
}

# 新しいGoogle Cloudプロジェクトを作成
resource "google_project" "project" {
  name                = var.project_name // プロジェクトの名前を指定
  project_id          = var.project_id   // プロジェクトの一意のIDを指定
  org_id              = var.org_id       // プロジェクトを所属させる組織のIDを指定
  auto_create_network = false            // プロジェクトの自動ネットワーク作成フラグを設定(自動ネットワークの作成は無効になっている)
  labels = {
    environment = "production"  // プロジェクトに"environment"というキーのラベルを追加し、値として"production"を設定
    team        = "engineering" // プロジェクトに"team"というキーのラベルを追加し、値として"engineering"を設定
  }                             // GCPプロジェクトにメタデータを付与
}

# プロジェクトに対してBigQueryサービスを有効化
resource "google_project_service" "bigquery" {
  project = google_project.project.project_id // サービスを有効化するプロジェクトのIDを指定
  service = "bigquery.googleapis.com"         // 有効化または無効化するサービスの名前を指定
}

# プロジェクトに対してCloud Storageサービスを有効化
resource "google_project_service" "cloud_storage" {
  project = google_project.project.project_id // サービスを有効化するプロジェクトのIDを指定
  service = "storage.googleapis.com"          // 有効化または無効化するサービスの名前を指定
}

#BucketのACL設定
data "google_project" "project" {
  project_id = "casa-task-sql" // プロジェクトのIDを指定
}

module "bigquery" {
  source = "./modules/bigquery"
}

module "cloud_dns" {
  source = "./modules/cloud_dns"
}

module "cloud_functions" {
  source = "./modules/cloud_functions"
}

module "cloud_iam" {
  source = "./modules/cloud_iam"
}

module "cloud_spanner" {
  source = "./modules/cloud_spanner"
}

module "cloud_sql" {
  source = "./modules/cloud_sql"
}

module "cloud_storage" {
  source = "./modules/cloud_storage"
}

module "compute_engine" {
  source = "./modules/compute_engine"
}

module "kubernetes_engine" {
  source = "./modules/kubernetes_engine"
}

module "pubsub" {
  source = "./modules/pubsub"
}

module "certificate_authority_service" {
  source = "./modules/certificate_authority_service"
}

module "cloud_composer" {
  source = "./modules/cloud_composer"
}

module "cloud_cdn" {
  source = "./modules/cloud_cdn"
}