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