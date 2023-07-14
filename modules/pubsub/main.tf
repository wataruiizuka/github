resource "google_pubsub_topic" "example" {
  name = "terraform-test" // トピックの名前を指定
}

## Google Pub/Subのトピックリソースを作成
resource "google_pubsub_topic" "my_topic" {
  name = "terraform-topic" // トピックの名前を指定

  message_storage_policy {
    allowed_persistence_regions = ["us-central1", "us-east1"] // メッセージの保持が許可されるリージョンを指定
  }                                                           // トピックのメッセージ保持ポリシーを設定
}

# Google Pub/Subのサブスクリプションリソースを作成
resource "google_pubsub_subscription" "my_subscription" {
  name                 = "terraform-subscription"          // サブスクリプションの名前を指定
  topic                = google_pubsub_topic.my_topic.name // サブスクリプションが関連付けられるトピックを指定
  ack_deadline_seconds = 30                                // メッセージのACK（確認受信）待機時間を秒単位で指定

  expiration_policy {
    ttl = "86400s" // メッセージの有効期間を秒単位で指定
  }                // サブスクリプションの有効期限ポリシーを設定
}