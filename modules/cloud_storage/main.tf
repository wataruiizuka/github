#Bucketの作成と設定
resource "google_storage_bucket" "bucket" {
  name          = "kamiyama-terraform"
  location      = "US"
  storage_class = "STANDARD"
  force_destroy = true

  #バージョニング
  versioning {
    enabled = true
  }

  logging { //アクセスログの保存先とプレフィックスを指定
    log_bucket        = "your-log-bucket"
    log_object_prefix = "logs/"
  }

  website { //ブロックを追加して静的ウェブサイトホスティングの設定を指定
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }

  lifecycle_rule { //ファイルのライフサイクルルールを指定
    action {
      type = "Delete"
    }
    condition {
      age = 30
    }
  }
}

#iam policyの設定
resource "google_storage_bucket_iam_member" "member" {
  bucket = google_storage_bucket.bucket.name
  role   = "roles/storage.objectViewer"
  member = "user:ayane.kamiyama@casa-llc.com"

  condition {
    title       = "request-time"
    description = "Access granted only during office hours"
    expression  = "request.time < timestamp(\"2023-07-31T18:00:00Z\") && request.time > timestamp(\"2023-07-31T09:00:00Z\")"
  } // メンバーのアクセスを制御する条件を指定
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
  name          = "test"
  bucket        = google_storage_bucket.bucket.name
  source        = "/Users/kamiyamaayane/Downloads/test.csv"
  content_type  = "text/csv" // コンテンツタイプを指定
  storage_class = "COLDLINE" // ストレージクラスを指定
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
resource "google_storage_transfer_job" "example_transfer_job" {
  description = "Transfer job for GCS to GCS"

  project = "casa-task-sql"

  transfer_spec {
    gcs_data_source {
      bucket_name = "kamiyama-terraform"
    }
    gcs_data_sink {
      bucket_name = "sample-transfer"
    }
    object_conditions {
      max_time_elapsed_since_last_modification = "600s"
      min_time_elapsed_since_last_modification = "60s"
    }

    transfer_options {
      delete_objects_from_source_after_transfer  = true  //転送後にソースからオブジェクトを削除するようにな
      overwrite_objects_already_existing_in_sink = false //データを転送する際、宛先のバケットに既に存在する同じ名前のオブジェクトがある場合、それらのオブジェクトを上書きすることはない
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

resource "google_storage_bucket_acl" "bucket_acl" {
  bucket = google_storage_bucket.bucket.name
  role_entity = [
    "OWNER:user-ayane.kamiyama@casa-llc.com",
    "READER:user-shiori.tago@casa-llc.com",
  ]
}

#notificationの設定
resource "google_storage_notification" "notification" {
  bucket         = google_storage_bucket.bucket.name
  payload_format = "JSON_API_V1"
  topic          = google_pubsub_topic.example.id
  event_types    = ["OBJECT_FINALIZE"]
  custom_attributes = {
    key1 = "value1"
    key2 = "value2"
  }
}