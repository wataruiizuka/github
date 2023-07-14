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