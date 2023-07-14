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