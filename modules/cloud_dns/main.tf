# Google Cloud DNSのManaged Zoneリソースを作成
resource "google_dns_managed_zone" "my_zone" {
  name        = "terraform-zone"         // 管理ゾーンの名前を指定
  dns_name    = "terraform.example.com." // 管理ゾーンに関連付けられるドメイン名を指定
  description = "terraform DNS Zone"     // 管理ゾーンの説明
  visibility  = "public"                 // 管理ゾーンの可視性を指定
}

# Google Cloud DNSのRecord Setリソースを作成
resource "google_dns_record_set" "my_record_set" {
  name    = "terraform.example.com." // レコードの名前を指定
  type    = "A"                      // レコードのタイプを指定
  ttl     = 300                      // TTL（Time To Live）を指定
  rrdatas = ["192.0.2.1"]            // レコードのデータを指定

  managed_zone = google_dns_managed_zone.my_zone.name // レコードセットが関連付けられる管理ゾーンの名前を指定

  project = "casa-task-sql" // レコードセットが作成されるプロジェクトのIDを指定
}

# ランダムなIDを生成
resource "random_id" "bucket_prefix" {
  byte_length = 8 // 生成するランダムなIDのバイト長を指定
}

# Cloud Storageバケットを作成
resource "google_storage_bucket" "default" {
  name                        = "${random_id.bucket_prefix.hex}-my-bucket" // バケットの名前を指定
  location                    = "us-east1" // バケットが作成されるリージョンを指定
  uniform_bucket_level_access = true // ユニフォームバケットレベルアクセスを有効にするかどうかを指定
  storage_class               = "STANDARD" // バケットのストレージクラスを指定
  force_destroy = true // バケットが削除されたときにその中身も同時に削除するかどうかを指定

  website {
    main_page_suffix = "index.html" // ファイルのサフィックス（接尾辞）を指定
    not_found_page   = "404.html" // ウェブサイトで404エラーが発生した場合に表示されるエラーページのファイル名を指定
  } // バケットをウェブサイトのホスティングに使用するための設定
}

# バケットに対して、特定のIAMメンバーに roles/storage.objectViewer ロールを付与する
resource "google_storage_bucket_iam_member" "default" {
  bucket = google_storage_bucket.default.name // メンバーを追加するGCSバケットの名前を指定
  role   = "roles/storage.objectViewer" // 付与するロールを指定
  member = "allUsers" // ロールを付与するIAMメンバーを指定
}

# 新しいオブジェクト（ファイル）を作成
resource "google_storage_bucket_object" "index_page" {
  name    = "index-page" // オブジェクトの名前を指定
  bucket  = google_storage_bucket.default.name // オブジェクトを作成するGCSバケットの名前を指定
  content = <<-EOT
    <html><body>
    <h1>Congratulations on setting up Google Cloud CDN with Storage backend!</h1>
    </body></html>
  EOT
} // オブジェクトの中身を指定

# 新しいオブジェクト（ファイル）を作成
resource "google_storage_bucket_object" "error_page" {
  name    = "404-page" // オブジェクトの名前を指定
  bucket  = google_storage_bucket.default.name // オブジェクトを作成するGCSバケットの名前を指定
  content = <<-EOT
    <html><body>
    <h1>404 Error: Object you are looking for is no longer available!</h1>
    </body></html>
  EOT
} // オブジェクトの中身を指定

# 新しいオブジェクト（ファイル）を作成
resource "google_storage_bucket_object" "test_image" {
  name = "test-object" // オブジェクトの名前を指定
  content      = "Data as string to be uploaded" // オブジェクトの中身を指定
  content_type = "text/plain" // オブジェクトのコンテンツのMIMEタイプを指定

  bucket = google_storage_bucket.default.name // オブジェクトを作成するGCSバケットの名前を指定
}

# グローバルIPアドレスを予約
resource "google_compute_global_address" "default" {
  name = "example-ip" // グローバルIPアドレスの名前を指定
}

# グローバルなTCPロードバランシング用のフォワーディングルールを作成
resource "google_compute_global_forwarding_rule" "default" {
  name                  = "http-lb-forwarding-rule" // フォワーディングルールの名前を指定
  ip_protocol           = "TCP" // フォワーディングルールのトラフィックプロトコルを指定
  load_balancing_scheme = "EXTERNAL" // ロードバランシングのスキームを指定
  port_range            = "80" // ロードバランシングするポート範囲を指定
  target                = google_compute_target_http_proxy.default.id // フォワーディングルールのターゲットを指定
  ip_address            = google_compute_global_address.default.id // フォワーディングルールに関連付けるグローバルIPアドレスのIDを指定
}

# HTTPターゲットプロキシを作成
resource "google_compute_target_http_proxy" "default" {
  name    = "http-lb-proxy" // ターゲットプロキシの名前を指定
  url_map = google_compute_url_map.default.id // ターゲットプロキシに関連付けるURLマップのIDを指定
}

# URLマップを作成
resource "google_compute_url_map" "default" {
  name            = "http-lb" // URLマップの名前を指定
  default_service = google_compute_backend_bucket.default.id // URLマップのデフォルトサービス（デフォルトのバックエンドサービス）を指定
}

# バックエンドバケットを作成
resource "google_compute_backend_bucket" "default" {
  name        = "cat-backend-bucket" // バックエンドバケットの名前を指定
  description = "Contains beautiful images" // バックエンドバケットの説明を指定
  bucket_name = google_storage_bucket.default.name // Cloud Storageバケットの名前を指定
  enable_cdn  = true // バックエンドバケットでCDN（Content Delivery Network）を有効にするかどうかを指定
  cdn_policy {
    cache_mode        = "CACHE_ALL_STATIC" // キャッシュモードを指定
    client_ttl        = 3600 // クライアント（ブラウザ）のキャッシュの有効期間を秒単位で指定
    default_ttl       = 3600 // デフォルトのキャッシュの有効期間を秒単位で指定
    max_ttl           = 86400 // 最大のキャッシュの有効期間を秒単位で指定
    negative_caching  = true // 負のキャッシュ（404などのエラー応答）をキャッシュするかどうかを指定
    serve_while_stale = 86400 // データのステール（古いキャッシュ）が発生した場合に、ステールなデータを提供し続ける時間を秒単位で指定
  } // CDNポリシーを定義
}