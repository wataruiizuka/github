resource "google_pubsub_topic" "example" {
  name = "terraform-test"
}

## Google Pub/Subのトピックリソースを作成
resource "google_pubsub_topic" "my_topic" {
  name = "terraform-topic"

  message_storage_policy {
    allowed_persistence_regions = ["us-central1", "us-east1"]
  } // トピックのメッセージ保持ポリシーを設定
}

# Google Pub/Subのサブスクリプションリソースを作成
resource "google_pubsub_subscription" "my_subscription" {
  name                 = "terraform-subscription"
  topic                = google_pubsub_topic.my_topic.name
  ack_deadline_seconds = 30 // メッセージのACK待機時間（秒単位）を指定

  expiration_policy {
    ttl = "86400s" # 1日（秒単位）
  }                // サブスクリプションの有効期限ポリシーを設
}

