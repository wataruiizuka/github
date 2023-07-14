#Bucketの作成と設定
resource "google_storage_bucket" "bucket" {
  name          = "kamiyama-terraform" // ストレージバケットの名前を指定
  location      = "US"                 // ストレージバケットの場所を指定
  storage_class = "STANDARD"           // ストレージバケットのストレージクラスを指定
  force_destroy = true                 // バケットを削除する際に中に含まれているオブジェクトを強制的に削除するかどうかを指定

  #バージョニング
  versioning {
    enabled = true
  } // バージョニングを有効にするかどうかを指定

  logging {
    log_bucket        = "your-log-bucket"
    log_object_prefix = "logs/"
  } //アクセスログの保存先とプレフィックスを指定

  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  } //ブロックを追加して静的ウェブサイトホスティングの設定を指定

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 30
    }
  } //ファイルのライフサイクルルールを指定
}

#iam policyの設定
resource "google_storage_bucket_iam_member" "member" {
  bucket = google_storage_bucket.bucket.name  // メンバーを追加するバケットの名前を指定
  role   = "roles/storage.objectViewer"       // メンバーに割り当てるロールを指定
  member = "user:ayane.kamiyama@casa-llc.com" // ロールに割り当てるメンバーを指定

  condition {
    title       = "request-time"
    description = "Access granted only during office hours"
    expression  = "request.time < timestamp(\"2023-07-31T18:00:00Z\") && request.time > timestamp(\"2023-07-31T09:00:00Z\")"
  } // メンバーのアクセスを制御する条件を指定
}

resource "google_storage_bucket_iam_policy" "bucket_policy" {
  bucket      = google_storage_bucket.bucket.name               // IAMポリシーを設定するバケットの名前を指定
  policy_data = data.google_iam_policy.bucket_admin.policy_data // バケットのIAMポリシーのデータを指定
}

#BucketのDefault Object ACL設定
resource "google_storage_default_object_acl" "default_acl" {
  bucket = google_storage_bucket.bucket.name // デフォルトACLを設定するバケットの名前を指定
  role_entity = [
    "OWNER:user-ayane.kamiyama@casa-llc.com",
    "READER:user-shiori.tago@casa-llc.com",
  ] // バケットのデフォルトACLに含まれるロールとエンティティのペアを指定
}

#Objectの作成と管理
resource "google_storage_bucket_object" "object" {
  name          = "test"                                    // アップロードされるオブジェクトの名前を指定
  bucket        = google_storage_bucket.bucket.name         // オブジェクトをアップロードするバケットの名前を指定
  source        = "/Users/kamiyamaayane/Downloads/test.csv" // アップロードするオブジェクトのソースファイルのパスを指定
  content_type  = "text/csv"                                // コンテンツタイプを指定
  storage_class = "COLDLINE"                                // ストレージクラスを指定
}

#ObjectのACL設定
resource "google_storage_object_acl" "object_acl" {
  object = google_storage_bucket_object.object.name // アクセス制御リストを設定するオブジェクトの名前を指定
  bucket = google_storage_bucket.bucket.name        // アクセス制御リストを設定するバケットの名前を指定
  role_entity = [
    "OWNER:user-ayane.kamiyama@casa-llc.com",
    "READER:user-shiori.tago@casa-llc.com",
  ] // バケットオブジェクトのアクセス制御リストに含まれるロールとエンティティのペアを指定
}

#Transfer Jobの作成と管理** (GCS to GCS の例)
resource "google_storage_transfer_job" "example_transfer_job" {
  description = "Transfer job for GCS to GCS" //  転送ジョブの説明を指定

  project = "casa-task-sql" // 転送ジョブを作成するプロジェクトのIDを指定

  transfer_spec {
    gcs_data_source {
      bucket_name = "kamiyama-terraform"
    } // 転送元のGoogle Cloud Storageバケットを指定
    gcs_data_sink {
      bucket_name = "sample-transfer"
    } //  転送先のGoogle Cloud Storageバケットを指定
    object_conditions {
      max_time_elapsed_since_last_modification = "600s" // 最後の変更から経過した最大時間
      min_time_elapsed_since_last_modification = "60s"  // 最後の変更から経過した最小時間
    }                                                   // オブジェクトの条件を指定

    transfer_options {
      delete_objects_from_source_after_transfer  = true  //　転送後にソースからオブジェクトを削除する設定
      overwrite_objects_already_existing_in_sink = false //　既に宛先に存在するオブジェクトを上書きしない設定
    }                                                    // 転送オプションを指定
  }

  schedule {
    schedule_start_date {
      year  = 2023
      month = 7
      day   = 5
    } // 転送の開始日
    schedule_end_date {
      year  = 2024
      month = 7
      day   = 5
    } // 転送の終了日
    start_time_of_day {
      hours   = 0
      minutes = 30
      seconds = 0
      nanos   = 0
    } // 転送の開始時刻
  }   // 転送ジョブのスケジュールを指定
}

resource "google_storage_bucket_acl" "bucket_acl" {
  bucket = google_storage_bucket.bucket.name // アクセス制御リストを設定するバケットの名前を指定
  role_entity = [
    "OWNER:user-ayane.kamiyama@casa-llc.com",
    "READER:user-shiori.tago@casa-llc.com",
  ] // バケットのアクセス制御リストに含まれるロールとエンティティのペアを指定
}

#notificationの設定
resource "google_storage_notification" "notification" {
  bucket         = google_storage_bucket.bucket.name // 通知を設定する対象のCloud Storageバケットの名前を指定
  payload_format = "JSON_API_V1"                     // 通知メッセージのペイロード形式を指定
  topic          = google_pubsub_topic.example.id    // 通知を受信するGoogle Cloud Pub/SubトピックのIDを指定
  event_types    = ["OBJECT_FINALIZE"]               // 通知をトリガーするイベントタイプを指定
  custom_attributes = {
    key1 = "value1"
    key2 = "value2"
  } // カスタム属性を指定(キーと値のペアで指定)
}