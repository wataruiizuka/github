#ネットワークの作成
resource "google_compute_network" "example_network" {
  name                    = "kamiyama-network"          // ネットワークの名前を指定
  auto_create_subnetworks = false                       // サブネットワークの自動作成フラグを設定(自動サブネットワークの作成は無効になっている)
  description             = "This network is for test." // ネットワークに関する説明を追加
  routing_mode            = "REGIONAL"                  // ルーティングモードを設定
  project                 = "casa-task-sql"             // プロジェクトを指定
}

#サブネットワークの作成
resource "google_compute_subnetwork" "example_subnetwork" {
  name          = "kamiyama-subnetwork"                                     // サブネットワークの名前を指定
  ip_cidr_range = "10.0.0.0/24"                                             // サブネットワークのIPアドレスのCIDR範囲を指定
  network       = "projects/casa-task-sql/global/networks/kamiyama-network" // サブネットワークが所属するネットワークのリソースパスを指定
  region        = "us-central1"                                             // サブネットワークが存在するリージョンを指定
  description   = "This subnetwork is for test."                            // サブネットワークに関する説明
}

#インスタンスの作成
resource "google_compute_instance" "example_instance" {
  name         = "example-instance" // インスタンス名
  machine_type = "n1-standard-1"    // マシンタイプ
  zone         = "us-central1-a"    // ゾーン指定

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"  // OSイメージ
    }
  } // ブートディスク設定

  network_interface {
    network    = "projects/casa-task-sql/global/networks/kamiyama-network" // ネットワーク指定
    subnetwork = "projects/casa-task-sql/regions/us-central1/subnetworks/kamiyama-subnetwork" // サブネットワーク指定
  } // ネットワークインターフェース設定

  can_ip_forward = true // IPフォワーディング許可

  deletion_protection = true // 削除保護設定

  shielded_instance_config {
    enable_secure_boot          = true // セキュアブート設定
    enable_vtpm                 = true // vTPM有効化
    enable_integrity_monitoring = true // 完全性モニタリング設定
  } // Shielded VM設定
}

#ディスクの作成
resource "google_compute_disk" "example_disk" {
  name        = "kamiyama-disk"                                                      // ディスクの名前を指定
  size        = 100                                                                  // ディスクのサイズを指定
  type        = "pd-standard"                                                        // ディスクのタイプを指定
  zone        = "us-central1-a"                                                      // ディスクを作成するGCPゾーンを指定
  description = "This disk is for test."                                             // ディスクに関する説明
  image       = "projects/ubuntu-os-cloud/global/images/ubuntu-2004-focal-v20210603" // ディスクにイメージを指定
}

#ファイアウォールの作成
resource "google_compute_firewall" "example_firewall" {
  name    = "kamiyama-firewall"                                       // ファイアウォール名
  network = "projects/casa-task-sql/global/networks/kamiyama-network" // 適用ネットワーク

  allow {
    protocol = "tcp"  // プロトコル
    ports    = ["80", "443"]  // ポート番号
  }  // 許可ルール

  source_ranges           = ["0.0.0.0/0"]  // 全てのIPからの接続を許可
  target_service_accounts = ["terraform-gcp-dbt-casa@casa-task-sql.iam.gserviceaccount.com"] // ターゲットアカウント
}

#ルートの作成
resource "google_compute_route" "example_route" {
  name        = "kamiyama-route"                                                         // ルートの名前を指定
  network     = "projects/casa-task-sql/global/networks/kamiyama-network"                // ルートが適用されるネットワークのリソースパスを指定
  dest_range  = "10.0.0.0/16"                                                            // ルートの宛先IP範囲を指定
  next_hop_ip = google_compute_instance.example_instance.network_interface[0].network_ip // ルートの次のホップとなるIPアドレスを指定

  priority    = 100                                 //ルートの優先度を指定
  description = "Custom route for Kamiyama network" //ルートの説明や目的を記述するテキストを指定
  tags        = ["web", "frontend"]                 //ルートに関連付けるネットワークタグを指定

  next_hop_instance = google_compute_instance.example_instance.self_link //ルートの次のホップとしてインスタンスを指定
}

#グローバルアドレスの作成
resource "google_compute_global_address" "example_address" {
  name = "kamiyama-address" // グローバルアドレスの名前を指定
}

#SSL証明書の作成
resource "google_compute_ssl_certificate" "example_certificate" {
  name        = "kamiyama-certificate"                      // SSL証明書の名前を指定
  description = "Example SSL Certificate"                   // SSL証明書の説明を指定
  private_key = file("/Users/kamiyamaayane/sample_csr.pem") // SSL証明書のプライベートキーを指定
  certificate = file("/Users/kamiyamaayane/sample_key.pem") // SSL証明書の証明書を指定
}

#Google Compute Engineのhealth_checkリソースを作成
resource "google_compute_health_check" "example_health_check" {
  name                = "terraform-health-check" // ヘルスチェックの名前を指定
  check_interval_sec  = 10                       // ヘルスチェックの実行間隔を秒単位で指定
  timeout_sec         = 5                        // ヘルスチェックのタイムアウト時間を秒単位で指定
  healthy_threshold   = 2                        // ヘルスチェックが「正常」とみなされるまでの連続成功回数を指定
  unhealthy_threshold = 2                        // ヘルスチェックが「異常」とみなされるまでの連続失敗回数を指定

  tcp_health_check {
    port = 80 // TCPヘルスチェックで監視するポート番号を指定
  }           // ヘルスチェックの種類としてTCPヘルスチェックを指定
}

# Google Compute Engineのinstance_groupリソースを作成
resource "google_compute_instance_group" "example_instance_group" {
  name        = "terraform-instance-group"                                // インスタンスグループの名前を指定
  description = "terraform instance group"                                // インスタンスグループの説明を任意で指定
  zone        = "us-central1-a"                                           // インスタンスグループが所属するゾーンを指定
  network     = "projects/casa-task-sql/global/networks/kamiyama-network" // インスタンスグループが所属するネットワークを指定
}

# Google Compute Engineのcompute_backend_serviceリソースを作成
resource "google_compute_backend_service" "example_backend_service" {
  name = "terraform-backend-service" // バックエンドサービスの名前を指定
  backend {
    group = google_compute_instance_group.example_instance_group.self_link     // バックエンドサービスに関連付けるインスタンスグループのセルフリンク（リソースの識別子）を指定
  }                                                                            // バックエンドの設定
  health_checks = [google_compute_health_check.example_health_check.self_link] // バックエンドサービスに関連付けるヘルスチェックのセルフリンクを指定
}

# Google Compute Engineのgoogle_compute_url_mapリソースを作成
resource "google_compute_url_map" "example_url_map" {
  name        = "terraform-url-map" // URLマップの名前を指定
  description = "terraform URL Map" // URLマップの説明

  default_service = google_compute_backend_service.example_backend_service.self_link // デフォルトのサービスとして関連付けるバックエンドサービスのセルフリンクを指定
}

# Google Compute Engineのgoogle_compute_forwarding_ruleリソースを作成
resource "google_compute_forwarding_rule" "example_forwarding_rule" {
  name        = "terraform-forwarding-rule"                      // フォワーディングルールの名前を指定
  description = "terraform Forwarding Rule"                      // フォワーディングルールの説明
  target      = google_compute_url_map.example_url_map.self_link // フォワーディングルールのターゲットとして関連付けるURLマップのセルフリンクを指定
  port_range  = "80"                                             // フォワーディングルールが使用するポート範囲を指定
}

# Google Compute Engineのgoogle_compute_instance_templateリソースを作成
resource "google_compute_instance_template" "example_instance_template" {
  name         = "terraform-instance-template" // インスタンステンプレートの名前を指定
  machine_type = "n1-standard-1"               // インスタンスのマシンタイプ（仮想マシンのサイズとリソースの割り当て）を指定

  network_interface {
    network    = "projects/casa-task-sql/global/networks/kamiyama-network"                    // インスタンスが接続されるネットワークを指定
    subnetwork = "projects/casa-task-sql/regions/us-central1/subnetworks/kamiyama-subnetwork" // インスタンスが所属するサブネットワークを指定
  }                                                                                           // ネットワークインターフェースの設定

  disk {
    source_image = "projects/ubuntu-os-cloud/global/images/ubuntu-2004-focal-v20211006" // インスタンスのディスクに使用するソースイメージを指定
  }                                                                                     // ディスクの設定
}

# Google Compute Engineのgoogle_compute_instance_group_managerリソースを作成
resource "google_compute_instance_group_manager" "example_instance_group_manager" {
  name               = "terraform-instance-group-manager" // インスタンスグループマネージャの名前を指定
  base_instance_name = "terraform-instance"               // インスタンスグループ内の各インスタンスのベース名を指定

  version {
    instance_template = google_compute_instance_template.example_instance_template.self_link // バージョンに関連付けるインスタンステンプレートのセルフリンクを指定
  }                                                                                          // インスタンスグループマネージャのバージョン設定
}

# Google Compute Engineのgoogle_compute_autoscalerリソースを作成
resource "google_compute_autoscaler" "example_autoscaler" {
  name   = "terraform-autoscaler"                                                         // オートスケーラの名前を指定
  target = google_compute_instance_group_manager.example_instance_group_manager.self_link // オートスケーラが対象とするインスタンスグループマネージャのセルフリンクを指定
  autoscaling_policy {
    min_replicas = 1  // オートスケーラが維持する最小インスタンス数を指定
    max_replicas = 10 // オートスケーラが増やすことができる最大インスタンス数を指定
  }                   // オートスケーラのスケーリングポリシー設定
}

#VPNゲートウェイの作成
resource "google_compute_vpn_gateway" "example_gateway" {
  name        = "kamiyama-gateway"                                        // VPNゲートウェイの名前を指定
  network     = "projects/casa-task-sql/global/networks/kamiyama-network" // PNゲートウェイが接続されるネットワークを指定
  region      = "us-central1"                                             // VPNゲートウェイが所属するリージョンを指定
  description = "Example VPN Gateway"                                     // VPNゲートウェイの説明
}

#ルーターの作成
resource "google_compute_router" "example_router" {
  name    = "kamiyama-router"                                         // ルータの名前を指定
  network = "projects/casa-task-sql/global/networks/kamiyama-network" // ルータが接続されるネットワークを指定
  bgp {
    asn            = 65001    // ルータのASN（自動システム番号）を指定
    advertise_mode = "CUSTOM" // BGPの広告モードを指定
  }                           // BGP（Border Gateway Protocol）の設定
}