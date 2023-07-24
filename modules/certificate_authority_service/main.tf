# プライベートCA（Certificate Authority）のCAプールを作成
resource "google_privateca_ca_pool" "default" {
  name     = "ca-pool-all-fields" // プールの名前を指定
  location = "us-central1" // プールを作成する地域を指定
  tier     = "ENTERPRISE" // プールのサービス レベルを指定
  publishing_options {
    publish_ca_cert = false // CA（証明機関）証明書を公開しないように設定
    publish_crl     = true // 証明書失効リスト（CRL）を公開するように設定
  } // 公開オプションに関する設定
  labels = {
    foo = "bar" // ラベル "foo" に値 "bar" を設定
  } // プールに付与するカスタムラベルの設定
  issuance_policy {
    allowed_key_types {
      elliptic_curve {
        signature_algorithm = "ECDSA_P256"
      } // ECDSA_P256アルゴリズムの鍵を許可
    } // 許可された鍵の種類を指定
    allowed_key_types {
      rsa {
        min_modulus_size = 5
        max_modulus_size = 10
      } // RSAアルゴリズムの鍵を許可
    }
    maximum_lifetime = "50000s" // 発行される証明書の最大有効期間を指定
    allowed_issuance_modes {
      allow_csr_based_issuance    = true // CSR（Certificate Signing Request）ベースの証明書発行を許可
      allow_config_based_issuance = true // 設定に基づく証明書発行を許可
    } // 許可された発行モードに関する設定
    identity_constraints {
      allow_subject_passthrough           = true // 証明書のSubjectの情報をそのまま受け取る
      allow_subject_alt_names_passthrough = true // 証明書のSubject Alternative Names（SAN）の情報をそのまま受け取る
      cel_expression {
        expression = "subject_alt_names.all(san, san.type == DNS || san.type == EMAIL )" // 証明書のSANがDNS名またはEMAILである場合に許可
        title      = "My title" // CEL式に対するタイトルを指定
      } // 証明書発行時に使用するCEL（Common Expression Language）式に関する設定
    } // 証明書に対するID制約に関する設定
    baseline_values {
      aia_ocsp_servers = ["example.com"] // 証明書に含めるAIA (Authority Information Access) エクステンションにOCSPサーバーのURLを指定
      additional_extensions {
        critical = true // 拡張をCriticalにするかどうかの設定
        value    = "asdf" // 拡張の値を指定
        object_id {
          object_id_path = [1, 7] // OIDを表す数字の配列を指定
        } // オブジェクトID（OID）に関する設定
      } // 追加の証明書拡張に関する設定
      policy_ids {
        object_id_path = [1, 5] // OIDを表す数字の配列を指定
      }
      policy_ids {
        object_id_path = [1, 5, 7] // OIDを表す数字の配列を指定
      } // 証明書ポリシーに関する設定
      ca_options {
        is_ca                  = true // CAとしての設定を有効
        max_issuer_path_length = 10 // CAによって発行される証明書の最大パス長を指定
      } // CAオプションに関する設定
      key_usage {
        base_key_usage {
          digital_signature  = true // デジタル署名に使用することを許可
          content_commitment = true // コンテンツのコミットメントに使用することを許可
          key_encipherment   = false // 鍵の暗号化に使用しないように設定
          data_encipherment  = true // データの暗号化に使用することを許可
          key_agreement      = true // 鍵共有に使用することを許可
          cert_sign          = false // 証明書署名に使用しないように設定
          crl_sign           = true // CRL署名に使用することを許可
          decipher_only      = true // 解読のみに使用することを許可
        } // 基本キー使用法に関する設定
        extended_key_usage {
          server_auth      = true // 拡張キー使用法に関する設定
          client_auth      = false // クライアント認証に使用しないように設定
          email_protection = true // メール保護に使用することを許可
          code_signing     = true // コード署名に使用することを許可
          time_stamping    = true // タイムスタンプに使用することを許可
        } // 拡張キー使用法に関する設定
      } // 証明書のキー使用に関する設定
    } // 証明書のベースライン値に関する設定
  } // 発行ポリシーに関する設定
}

# プライベートCAを作成
resource "google_privateca_certificate_authority" "default" {
  pool                     = "my-pool" // 作成するCAのプール名を指定
  certificate_authority_id = "my-certificate-authority-hashicorp" // CAのIDを指定
  location                 = "us-central1" // CAを作成する地域を指定
  deletion_protection      = false // リソースの削除保護を設定
  config {
    subject_config {
      subject {
        organization = "HashiCorp" // 組織名を"HashiCorp"に設定
        common_name  = "my-certificate-authority" // 証明書のCommon Name（一般名）を"my-certificate-authority"に設定
      } // 証明書のSubjectに関する設定
      subject_alt_name {
        dns_names = ["hashicorp.com"] // DNS名が"hashicorp.com"として設定
      } // 証明書のSubject Alternative Name（SAN）に関する設定
    } // 証明書のSubject情報に関する設定
    x509_config {
      ca_options {
        is_ca                  = true // CAとしての設定を有効にする
        max_issuer_path_length = 10 // CAによって発行される証明書の最大パス長を指定
      } // CAオプションに関する設定
      key_usage {
        base_key_usage {
          digital_signature  = true // デジタル署名に使用することを許可
          content_commitment = true // コンテンツのコミットメントに使用することを許可
          key_encipherment   = false // 鍵の暗号化に使用しないように設定
          data_encipherment  = true // データの暗号化に使用することを許可
          key_agreement      = true // 鍵共有に使用することを許可
          cert_sign          = true // 証明書署名に使用することを許可
          crl_sign           = true // CRL署名に使用することを許可
          decipher_only      = true // 解読のみに使用することを許可
        } // 基本キー使用法に関する設定
        extended_key_usage {
          server_auth      = true // サーバー認証に使用することを許可
          client_auth      = false // クライアント認証に使用しないように設定
          email_protection = true // メール保護に使用することを許可
          code_signing     = true // コード署名に使用することを許可
          time_stamping    = true // タイムスタンプに使用することを許可
        } // 拡張キー使用法に関する設定
      } // 証明書のキー使用に関する設定
    } // X.509証明書の設定
  } // CAの設定
  lifetime = "86400s" // 発行される証明書の最大有効期間を指定
  key_spec {
    algorithm = "RSA_PKCS1_4096_SHA256" // RSAアルゴリズムによる4096ビットのキーを使用することを指定
  } // CAのキーの仕様に関する設定
}

# プライベートCAを作成
resource "google_project_service_identity" "privateca_sa" {
  provider = google-beta // google-betaプロバイダーを使用してリソースを作成
  service  = "privateca.googleapis.com" // Private CAサービスのService Identityを作成
}

# Crypto KeyにIAM（Identity and Access Management）ポリシーをバインドするためのリソース定義
resource "google_kms_crypto_key_iam_binding" "privateca_sa_keyuser_signerverifier" {
  crypto_key_id = "projects/keys-project/locations/us-central1/keyRings/key-ring/cryptoKeys/crypto-key" // Crypto KeyのIDを指定
  role          = "roles/cloudkms.signerVerifier" // サービスアカウントに付与するIAMロールを指定

  members = [
    "serviceAccount:${google_project_service_identity.privateca_sa.email}",
  ] // バインドするサービスアカウントのメールアドレスを指定
}

# Crypto KeyにIAM（Identity and Access Management）ポリシーをバインドするためのリソース定義
resource "google_kms_crypto_key_iam_binding" "privateca_sa_keyuser_viewer" {
  crypto_key_id = "projects/keys-project/locations/us-central1/keyRings/key-ring/cryptoKeys/crypto-key" // Crypto KeyのIDを指定
  role          = "roles/viewer" // サービスアカウントに付与するIAMロールを指定
  members = [
    "serviceAccount:${google_project_service_identity.privateca_sa.email}",
  ] // バインドするサービスアカウントのメールアドレスを指定
}

# ルート証明書を作成
resource "google_privateca_certificate_authority" "root_ca" {
  pool                                   = "my-pool" // 作成するCAのプール名を指定
  certificate_authority_id               = "my-certificate-authority-root" // CAのIDを指定
  location                               = "us-central1" // CAを作成する地域を指定
  deletion_protection                    = false // リソースの削除保護を設定
  ignore_active_certificates_on_deletion = true // 削除時にアクティブな証明書を無視するように設定
  config {
    subject_config {
      subject {
        organization = "HashiCorp" // 組織名を"HashiCorp"に設定
        common_name  = "my-certificate-authority" // 証明書のCommon Name（一般名）を"my-certificate-authority"に設定
      } // 証明書のSubjectに関する設定
      subject_alt_name {
        dns_names = ["hashicorp.com"]
      }
    } // 証明書のSubject情報に関する設定
    x509_config {
      ca_options {
        # is_ca *MUST* be true for certificate authorities
        is_ca = true // CAとしての設定を有効にする
      } // CAオプションに関する設定
      key_usage {
        base_key_usage {
          # cert_sign and crl_sign *MUST* be true for certificate authorities
          cert_sign = true // 証明書署名に使用することを許可
          crl_sign  = true // CRL署名に使用することを許可
        }
        extended_key_usage {
          server_auth = false // サーバー認証に使用することを許可しない
        } // 拡張キー使用法に関する設定
      } // 証明書のキー使用に関する設定
    } // X.509証明書の設定
  } // CAの設定
  key_spec {
    algorithm = "RSA_PKCS1_4096_SHA256" // RSAアルゴリズムによる4096ビットのキーを使用することを指定
  } // CAのキーの仕様に関する設定
}

# プライベートCAと証明書を作成
resource "google_privateca_certificate_authority" "test_ca" {
  certificate_authority_id               = "my-example-certificate-authority" // CAのIDを指定
  location                               = "us-central1" // CAを作成する地域を指定
  pool                                   = "my-pool" // 作成するCAのプール名を指定
  ignore_active_certificates_on_deletion = true // 削除時にアクティブな証明書を無視するように設定
  deletion_protection                    = false // リソースの削除保護を設定
  config {
    subject_config {
      subject {
        organization = "HashiCorp" // 組織名を"HashiCorp"に設定
        common_name  = "my-certificate-authority" // 証明書のCommon Name（一般名）を"my-certificate-authority"に設定
      } // 証明書のSubjectに関する設定
      subject_alt_name {
        dns_names = ["hashicorp.com"] // DNS名（ドメイン名）を設定
      }
    } // 証明書のSubject情報に関する設定
    x509_config {
      ca_options {
        is_ca = true // CAとしての設定を有効にする
      } // CAオプションに関する設定
      key_usage {
        base_key_usage {
          cert_sign = true // 証明書署名に使用することを許可
          crl_sign  = true // CRL署名に使用することを許可
        }
        extended_key_usage {
          server_auth = true // 証明書をサーバー認証に使用できるように許可
        } // 証明書の拡張キー使用法（Extended Key Usage、EKU）に関する設定
      } // 証明書のキー使用に関する設定
    } // X.509証明書の設定
  } // CAの設定
  key_spec {
    algorithm = "RSA_PKCS1_4096_SHA256" // RSAアルゴリズムによる4096ビットのキーを使用することを指定
  } // CAのキーの仕様に関する設定
}

resource "google_privateca_certificate" "default" {
  pool                  = "my-pool" // 作成する証明書のプール名を指定
  location              = "us-central1" // 証明書を作成する地域を指定
  certificate_authority = google_privateca_certificate_authority.test_ca.certificate_authority_id // 作成する証明書が属するプライベートCAのIDを指定
  lifetime              = "860s" // 発行される証明書の有効期間を指定
  name                  = "my-example-certificate" // 証明書の名前を指定
  config {
    subject_config {
      subject {
        common_name         = "san1.example.com" // 証明書のCommon Name（一般名）を"san1.example.com"に設定
        country_code        = "us"
        organization        = "google"
        organizational_unit = "enterprise"
        locality            = "mountain view"
        province            = "california"
        street_address      = "1600 amphitheatre parkway"
      } // 証明書のSubjectに関する設定
      subject_alt_name {
        email_addresses = ["email@example.com"] // メールアドレスが追加される
        ip_addresses    = ["127.0.0.1"] // IPアドレスが追加される
        uris            = ["http://www.ietf.org/rfc/rfc3986.txt"] // URIが追加される
      } // Subject Alternative Name（SAN）に関する設定
    } // 証明書のSubject情報に関する設定
    x509_config {
      ca_options {
        is_ca = false // CAとしての設定を無効にする
      } // CAオプションに関する設定
      key_usage {
        base_key_usage {
          crl_sign      = false // CRL署名に使用しないように設定
          decipher_only = false // 証明書のキーがデータの複号にのみ使用されることを許可しない
        } // 証明書の基本的なキー使用法（Key Usage）に関する設定
        extended_key_usage {
          server_auth = false // 証明書をサーバー認証に使用できるように許可
        } // 証明書の拡張キー使用法（Extended Key Usage、EKU）に関する設定
      } // 証明書のキー使用に関する設定
    } // X.509証明書の設定
    public_key {
      format = "PEM" // 公開鍵のフォーマットを指定
      key    = base64encode(data.tls_public_key.example.public_key_pem) // 実際の公開鍵の値をBase64エンコード
    } // 公開鍵に関する設定
  } // 証明書の設定
}

# TLSプライベートキーを作成
resource "tls_private_key" "example" {
  algorithm = "RSA" // RSAアルゴリズムを使用してTLSプライベートキーを作成
}

# TLSプライベートキーから公開鍵を取得する
data "tls_public_key" "example" {
  private_key_pem = tls_private_key.example.private_key_pem // TLSプライベートキーのPEM形式の値を指定
}

# TLS証明書リクエストを作成
resource "tls_cert_request" "example" {
  private_key_pem = tls_private_key.example.private_key_pem // TLSプライベートキーのPEM形式の値を指定

  subject {
    common_name  = "example.com" // 証明書のCommon Name（一般名）を指定
    organization = "ACME Examples, Inc" // 証明書の組織名を指定
  } // 証明書のサブジェクト情報に関する設定
}

resource "google_privateca_certificate_authority" "authority" {
  // This example assumes this pool already exists.
  // Pools cannot be deleted in normal test circumstances, so we depend on static pools
  pool                     = "my-pool"
  certificate_authority_id = "my-sample-certificate-authority"
  location                 = "us-central1"
  deletion_protection      = false # set to true to prevent destruction of the resource
  config {
    subject_config {
      subject {
        organization = "HashiCorp"
        common_name  = "my-certificate-authority"
      }
      subject_alt_name {
        dns_names = ["hashicorp.com"]
      }
    }
    x509_config {
      ca_options {
        is_ca = true
      }
      key_usage {
        base_key_usage {
          digital_signature = true
          cert_sign         = true
          crl_sign          = true
        }
        extended_key_usage {
          server_auth = true
        }
      }
    }
  }
  lifetime = "86400s"
  key_spec {
    algorithm = "RSA_PKCS1_4096_SHA256"
  }
}

# Cloud Private Certificate Authority（Private CA）のAPIを有効化する
resource "google_project_service" "privateca_api" {
  service            = "privateca.googleapis.com" // 有効化するGCPサービスの名前を指定
  disable_on_destroy = false // リソースが削除された際にサービスを無効化するかどうかを指定
}