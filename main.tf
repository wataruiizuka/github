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

#ネットワークの作成
resource "google_compute_network" "example_network" {
  name                    = "kamiyama-network"
  auto_create_subnetworks = false
  description             = "This network is for test." // ネットワークに関する説明を追加
  routing_mode            = "REGIONAL"                  // ルーティングモードを設定
  project                 = "casa-task-sql"             // プロジェクトを指定
}

#サブネットワークの作成
resource "google_compute_subnetwork" "example_subnetwork" {
  name          = "kamiyama-subnetwork"
  ip_cidr_range = "10.0.0.0/24"
  network       = "projects/casa-task-sql/global/networks/kamiyama-network"
  region        = "us-central1"
  description   = "This subnetwork is for test." // サブネットワークに関する説明
}

#インスタンスの作成
resource "google_compute_instance" "example_instance" {
  name         = "example-instance"
  machine_type = "n1-standard-1"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
    }
  }

  network_interface {
    network    = "projects/casa-task-sql/global/networks/kamiyama-network"
    subnetwork = "projects/casa-task-sql/regions/us-central1/subnetworks/kamiyama-subnetwork"
  }

  can_ip_forward = true //インスタンスがIPフォワーディングを許可するかどうかを指定

  deletion_protection = true //インスタンスが削除保護されているかどうかを指定

  shielded_instance_config { //インスタンスに対するShielded VMの設定を指定
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }
}

#ディスクの作成
resource "google_compute_disk" "example_disk" {
  name        = "kamiyama-disk"
  size        = 100
  type        = "pd-standard"
  zone        = "us-central1-a"
  description = "This disk is for test."                                             // ディスクに関する説明
  image       = "projects/ubuntu-os-cloud/global/images/ubuntu-2004-focal-v20210603" // ディスクにイメージを指定
}

#ファイアウォールの作成
resource "google_compute_firewall" "example_firewall" {
  name    = "kamiyama-firewall"
  network = "projects/casa-task-sql/global/networks/kamiyama-network"

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges           = ["0.0.0.0/0"]
  target_service_accounts = ["terraform-gcp-dbt-casa@casa-task-sql.iam.gserviceaccount.com"] // サービスアカウントを指定
}

#ルートの作成
resource "google_compute_route" "example_route" {
  name        = "kamiyama-route"
  network     = "projects/casa-task-sql/global/networks/kamiyama-network"
  dest_range  = "10.0.0.0/16"
  next_hop_ip = google_compute_instance.example_instance.network_interface[0].network_ip

  priority    = 100                                 //ルートの優先度を指定
  description = "Custom route for Kamiyama network" //ルートの説明や目的を記述するテキストを指定
  tags        = ["web", "frontend"]                 //ルートに関連付けるネットワークタグを指定

  next_hop_instance = google_compute_instance.example_instance.self_link //ルートの次のホップとしてインスタンスを指定
}

#グローバルアドレスの作成
resource "google_compute_global_address" "example_address" {
  name = "kamiyama-address"
}

#SSL証明書の作成
resource "google_compute_ssl_certificate" "example_certificate" {
  name         = "kamiyama-certificate"
  description  = "Example SSL Certificate"
  private_key  = file("/Users/kamiyamaayane/sample_csr.pem")
  certificate  = file("/Users/kamiyamaayane/sample_key.pem")
  address_type = "EXTERNAL"     //グローバルアドレスのタイプを指定
  purpose      = "GCE_ENDPOINT" //グローバルアドレスの目的を指定
}

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

#コンテナ クラスターの作成
resource "google_container_cluster" "my_cluster" {
  name               = "kamiyama-gke-cluster"
  location           = "US"
  initial_node_count = 3
  min_master_version = "1.18.16-gke.302"

  network = "projects/casa-task-sql/global/networks/kamiyama-network" // クラスタが使用するVPCネットワークを指定

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

#コンテナ ノード プールの作成
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

  autoscaling {
    min_node_count = 1
    max_node_count = 10
  } // 自動スケーリングの設定を指定

  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  } // ノードのアップグレード戦略を指定
}

#データベースの作成
resource "google_sql_database" "my_database" {
  name      = "kamiyama-database"
  instance  = "kamiyama-instance"
  charset   = "utf8"            // 文字セットの設定
  collation = "utf8_general_ci" // 照合順序の設定
}

#データベースインスタンスの作成
resource "google_sql_database_instance" "my_instance" {
  name             = "kamiyama-instance"
  database_version = "MYSQL_5_7"

  settings {
    tier = "db-n1-standard-1"
  } // インスタンスを作成するリージョンを指定
}

#データベースユーザーの作成
resource "google_sql_user" "example_user" {
  name     = "test-kamiyama"
  instance = google_sql_database_instance.my_instance.id
  password = "20230711"
  project  = "casa-task-sql" // プロジェクトを指定
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

resource "google_pubsub_topic" "example" {
  name = "terraform-test"
}

# 新しいサービスアカウントを作成
resource "google_service_account" "service_account" {
  account_id   = var.service_account_id
  display_name = "Service Account for data analysis"
  project      = google_project.project.project_id
  description  = "This service account is used for terraform test." // サービスアカウントの説明
}

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

# Google Cloud DNSのManaged Zoneリソースを作成
resource "google_dns_managed_zone" "my_zone" {
  name        = "terraform-zone"
  dns_name    = "terraform.example.com." # ドメイン名を指定
  description = "terraform DNS Zone"     #任意の説明
  visibility  = "public"                 # 可視性を指定
}

# Google Cloud DNSのRecord Setリソースを作成
resource "google_dns_record_set" "my_record_set" {
  name    = "terraform.example.com." # レコード名を指定
  type    = "A"                      # レコードタイプを指定
  ttl     = 300                      # TTL（Time To Live）を指定
  rrdatas = ["192.0.2.1"]            # レコードデータを指定

  managed_zone = google_dns_managed_zone.my_zone.name

  project = "casa-task-sql" # プロジェクトIDを指定
}

# Google Cloud SpannerのInstanceリソースを作成
resource "google_spanner_instance" "my_instance" {
  name         = "terraform-instance"
  config       = "regional-us-central1"
  num_nodes    = 1
  display_name = "terraform-sample"
}

# Google Cloud SpannerのDatabaseリソースを作成
resource "google_spanner_database" "my_database" {
  name     = "terraform-database"
  instance = google_spanner_instance.my_instance.name
}

# Google Cloud FunctionsのFunctionリソースを作成
resource "google_cloudfunctions_function" "my_function" {
  name                  = "terraform-function"
  description           = "terraform Cloud Function"
  runtime               = "nodejs16"
  available_memory_mb   = 256
  timeout               = 60
  entry_point           = "helloHttp"
  source_archive_bucket = "terraform_tago"
  source_archive_object = "function-source.zip"
  trigger_http          = true
}

#Google Compute Engineのhealth_checkリソースを作成
resource "google_compute_health_check" "example_health_check" {
  name                = "terraform-health-check"
  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 2

  tcp_health_check {
    port = 80
  }
}

# Google Compute Engineのinstance_groupリソースを作成
resource "google_compute_instance_group" "example_instance_group" {
  name        = "terraform-instance-group"
  description = "terraform instance group"
  zone        = "us-central1-a"
  network     = "projects/casa-task-sql/global/networks/kamiyama-network"
}

# Google Compute Engineのcompute_backend_serviceリソースを作成
resource "google_compute_backend_service" "example_backend_service" {
  name = "terraform-backend-service"
  backend {
    group = google_compute_instance_group.example_instance_group.self_link
  }
  health_checks = [google_compute_health_check.example_health_check.self_link]
}

# Google Compute Engineのgoogle_compute_url_mapリソースを作成
resource "google_compute_url_map" "example_url_map" {
  name        = "terraform-url-map"
  description = "terraform URL Map"

  default_service = google_compute_backend_service.example_backend_service.self_link
}

# Google Compute Engineのgoogle_compute_forwarding_ruleリソースを作成
resource "google_compute_forwarding_rule" "example_forwarding_rule" {
  name        = "terraform-forwarding-rule"
  description = "terraform Forwarding Rule"
  target      = google_compute_url_map.example_url_map.self_link
  port_range  = "80"
}

# Google Compute Engineのgoogle_compute_instance_templateリソースを作成
resource "google_compute_instance_template" "example_instance_template" {
  name         = "terraform-instance-template"
  machine_type = "n1-standard-1"

  network_interface {
    network    = "projects/casa-task-sql/global/networks/kamiyama-network"
    subnetwork = "projects/casa-task-sql/regions/us-central1/subnetworks/kamiyama-subnetwork"
  }

  disk {
    source_image = "projects/ubuntu-os-cloud/global/images/ubuntu-2004-focal-v20211006"
  }

}

# Google Compute Engineのgoogle_compute_instance_group_managerリソースを作成
resource "google_compute_instance_group_manager" "example_instance_group_manager" {
  name               = "terraform-instance-group-manager"
  base_instance_name = "terraform-instance"

  version {
    instance_template = google_compute_instance_template.example_instance_template.self_link
  }
}

# Google Compute Engineのgoogle_compute_autoscalerリソースを作成
resource "google_compute_autoscaler" "example_autoscaler" {
  name   = "terraform-autoscaler"
  target = google_compute_instance_group_manager.example_instance_group_manager.self_link
  autoscaling_policy {
    min_replicas = 1
    max_replicas = 10
  }
}

#VPNゲートウェイの作成
resource "google_compute_vpn_gateway" "example_gateway" {
  name        = "kamiyama-gateway"
  network     = "projects/casa-task-sql/global/networks/kamiyama-network"
  region      = "us-central1"
  description = "Example VPN Gateway"
}

#ルーターの作成
resource "google_compute_router" "example_router" {
  name    = "kamiyama-router"
  network = "projects/casa-task-sql/global/networks/kamiyama-network"
  bgp {
    asn            = 65001 # ASN（自動システム番号）
    advertise_mode = "CUSTOM"
  }
}

# データセットを作成
resource "google_bigquery_dataset" "tf_gcp_dbt_dataset" {
  dataset_id    = "tf_gcp_dbt_dataset"
  friendly_name = "My Dataset"
  description   = "This is a sample description"
  location      = "US"
}

# tago2_gcp_dbt_datasetという名前のデータセットを作成
resource "google_bigquery_dataset" "tago2_gcp_dbt_dataset" {
  dataset_id    = "tago2_gcp_dbt_dataset"
  friendly_name = "My Dataset"
  description   = "This is a sample description"
  location      = "US"
}

# tago_dataset_scheduleという名前のデータセットを作成
resource "google_bigquery_dataset" "tago_dataset_schedule" {
  dataset_id    = "tago_dataset_schedule"
  friendly_name = "My Dataset"
  description   = "This is a sample description"
  location      = "US"
}

# テーブルを作成
resource "google_bigquery_table" "tf_gcp_dbt_table" {
  dataset_id = google_bigquery_dataset.tf_gcp_dbt_dataset.dataset_id
  table_id   = "tf_gcp_dbt_table"

  #パーティション設定
  time_partitioning {
    type = "DAY"
  }

  # テーブルのスキーマを指定
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

# tago2~という名前のテーブルを作成
resource "google_bigquery_table" "tago2_gcp_dbt_table" {
  dataset_id = google_bigquery_dataset.tago2_gcp_dbt_dataset.dataset_id
  table_id   = "tago2_gcp_dbt_table"

  #外部データはパーティション設定ができない

  # テーブルのスキーマを指定
  schema = <<EOF
[
  {"name": "DAY", "type": "DATE", "mode": "NULLABLE"},
  {"name": "sample1", "type": "STRING", "mode": "NULLABLE"},
  {"name": "sample2", "type": "INTEGER", "mode": "NULLABLE"},
  {"name": "sample3", "type": "INTEGER", "mode": "NULLABLE"}
]
EOF

  # アップロード元の設定（GCSのcsvファイルをアップロードする）
  external_data_configuration {
    source_format = "CSV"
    source_uris   = ["gs://terraform_tago/terraform_sample.csv"]
    autodetect    = true

    csv_options {
      skip_leading_rows = 1
      quote             = "\""
    }
  }
}

# スケジュールクエリ用のテーブルを作成
resource "google_bigquery_table" "tago_table_dwh_schedule" {
  dataset_id = google_bigquery_dataset.tago_dataset_schedule.dataset_id
  table_id   = "tago_table_dwh_schedule"

  # パーティション設定
  time_partitioning {
    type = "DAY"
  }

  # テーブルのスキーマを指定
  schema = <<EOF
[
  {"name": "DAY", "type": "DATE", "mode": "NULLABLE"},
  {"name": "sample1", "type": "STRING", "mode": "NULLABLE"}
]
EOF
}

# スケジュールクエリの設定
resource "google_bigquery_data_transfer_config" "query_config" {
  depends_on = [google_bigquery_table.tago_table_dwh_schedule]

  display_name           = "Schedule Query"
  location               = "US"
  data_source_id         = "scheduled_query"
  schedule               = "every day 06:00"
  destination_dataset_id = google_bigquery_dataset.tago_dataset_schedule.dataset_id
  params = {
    destination_table_name_template = "tago_table_dwh_schedule"
    write_disposition               = "WRITE_APPEND"
    query                           = "SELECT DAY, sample1 FROM `casa-task-sql.tago2_gcp_dbt_dataset.tago2_gcp_dbt_table`"

  }
}

#IAM メンバーを追加
resource "google_project_iam_member" "member" {
  project = "casa-task-sql"
  role    = "roles/viewer"
  member  = "user:momoko.kawano@casa-llc.com"
}

data "google_iam_policy" "policy" {
  binding {
    role = "roles/storage.objectViewer"

    members = [
      "user:momoko.kawano@casa-llc.com",
    ]
  }
}

#IAMポリシーの設定
resource "google_project_iam_policy" "project" {
  project     = "casa-task-sql"
  policy_data = data.google_iam_policy.policy.policy_data
}

#サービスアカウントの作成
resource "google_service_account" "account" {
  account_id   = "momoko-sample"
  display_name = "My Service Account"
  project      = "casa-task-sql"
  description  = "This service account is used for momoko." // サービスアカウントの説明
}

#サービスアカウントキーの作成
resource "google_service_account_key" "key" {
  service_account_id = google_service_account.account.name
}