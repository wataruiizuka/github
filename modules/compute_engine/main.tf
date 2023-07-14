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