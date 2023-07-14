#コンテナ クラスターの作成
resource "google_container_cluster" "my_cluster" {
  name               = "kamiyama-gke-cluster" // クラスタの名前を指定
  location           = "US"                   // クラスタの場所を指定
  initial_node_count = 3                      // クラスタの初期ノード数を指定
  min_master_version = "1.18.16-gke.302"      // クラスタの最小マスターバージョンを指定

  network = "projects/casa-task-sql/global/networks/kamiyama-network" // クラスタが使用するVPCネットワークを指定

  node_config {
    machine_type = "n1-standard-2" // ノードのマシンタイプを指定
    disk_size_gb = 100             // ノードのディスクサイズを指定

    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring"
    ] // ノードに割り当てられるOAuthスコープを指定
  }   // クラスタのノードの設定
}

#コンテナ ノード プールの作成
resource "google_container_node_pool" "my_node_pool" {
  name       = "kamiyama-node-pool"                         // ノードプールの名前を指定
  cluster    = google_container_cluster.my_cluster.name     // ノードプールが所属するGKEクラスタの名前を指定
  location   = google_container_cluster.my_cluster.location // ノードプールの場所を指定
  node_count = 3                                            // ノードプールの初期ノード数を指定

  node_config {
    machine_type = "n1-standard-2" // ノードのマシンタイプを指定
    disk_size_gb = 100             // ノードのディスクサイズをGB単位で指定

    # ノードの設定など...
  } // ノードプールのノードの設定

  autoscaling {
    min_node_count = 1  // 自動スケーリング時の最小ノード数を指定
    max_node_count = 10 // 自動スケーリング時の最大ノード数を指定
  }                     // 自動スケーリングの設定を指定

  upgrade_settings {
    max_surge       = 1 // ノードのアップグレード時に許容される同時追加ノード数を指定
    max_unavailable = 0 // ノードのアップグレード時に許容される同時非稼働ノード数を指定
  }                     // ノードのアップグレード戦略を指定
}