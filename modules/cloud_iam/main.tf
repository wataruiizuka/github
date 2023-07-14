# IAMバインディングを作成
resource "google_project_iam_binding" "binding" {
  project = "casa-task-sql"             // バインディングを追加する対象のプロジェクトIDを指定
  role    = "roles/bigquery.dataEditor" // バインディングに割り当てる役割（ロール）を指定

  members = [
    "user:momoko.kawano@casa-llc.com",
  ] // バインディングに含まれるメンバーを指定

  condition {
    title       = "sample-time"                                        // 条件タイトル
    description = "Request time condition"                             // 条件の説明
    expression  = "request.time < timestamp(\"2024-01-01T00:00:00Z\")" // リクエストの時間が特定の日付よりも前である場合にバインディングを有効化する条件式
  }                                                                    //バインディングを有効化する条件を設定
}

#IAM メンバーを追加
resource "google_project_iam_member" "member" {
  project = "casa-task-sql"                   // IAMメンバーシップを設定するプロジェクトを指定
  role    = "roles/viewer"                    // メンバーシップに割り当てるロールを指定
  member  = "user:momoko.kawano@casa-llc.com" // メンバーシップの対象となるユーザーを指定
}

#IAMポリシーの設定
resource "google_project_iam_policy" "project" {
  project     = "casa-task-sql"                           //  IAMポリシーを設定するプロジェクトを指定
  policy_data = data.google_iam_policy.policy.policy_data // 設定するIAMポリシーのデータを指定
}

# 新しいサービスアカウントを作成
resource "google_service_account" "service_account" {
  account_id   = "momoko-sample"                            // サービスアカウントのIDを指定
  display_name = "My Service Account"                       // サービスアカウントの表示名を指定
  project      = "casa-task-sql"                            // サービスアカウントを作成するプロジェクトを指定
  description  = "This service account is used for momoko." // サービスアカウントの説明
}

#サービスアカウントキーの作成
resource "google_service_account_key" "key" {
  service_account_id = google_service_account.account.name // 作成したサービスアカウントの名前を指定
}

data "google_iam_policy" "policy" {
  binding {
    role = "roles/storage.objectViewer" // バインディングに割り当てるロールを指定

    members = [
      "user:momoko.kawano@casa-llc.com", // バインディングのメンバーを指定
    ]
  } // ポリシー内のバインディングを指定
}