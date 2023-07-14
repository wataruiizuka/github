# IAMバインディングを作成
resource "google_project_iam_binding" "binding" {
  project = "casa-task-sql"
  role    = "roles/bigquery.dataEditor"

  # バインディングに含まれるメンバーを指定
  members = [
    "user:momoko.kawano@casa-llc.com",
  ]

  condition { //バインディングを有効化する条件を設定
    #request-timeという条件タイトルと、特定の日付までのリクエストのみバインディングを有効化する条件式を指定
    title       = "sample-time"
    description = "Request time condition"
    expression  = "request.time < timestamp(\"2024-01-01T00:00:00Z\")"
  }
}

#IAM メンバーを追加
resource "google_project_iam_member" "member" {
  project = "casa-task-sql"
  role    = "roles/viewer"
  member  = "user:momoko.kawano@casa-llc.com"
}

#IAMポリシーの設定
resource "google_project_iam_policy" "project" {
  project     = "casa-task-sql"
  policy_data = data.google_iam_policy.policy.policy_data
}

# 新しいサービスアカウントを作成
resource "google_service_account" "service_account" {
  account_id   = var.service_account_id
  display_name = "Service Account for data analysis"
  project      = google_project.project.project_id
  description  = "This service account is used for terraform test." // サービスアカウントの説明
}

#サービスアカウントキーの作成
resource "google_service_account_key" "key" {
  service_account_id = google_service_account.account.name
}

data "google_iam_policy" "policy" {
  binding {
    role = "roles/storage.objectViewer"

    members = [
      "user:momoko.kawano@casa-llc.com",
    ]
  }
}