
resource "tls_private_key" "webhook_ca" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P521"
}

resource "tls_self_signed_cert" "webhook_ca" {
  private_key_pem       = tls_private_key.webhook_ca.private_key_pem
  is_ca_certificate     = true
  validity_period_hours = 8766 # 1 year
  early_renewal_hours   = 8766 / 2
  subject {
    common_name = "value"
  }
  allowed_uses = [
    "cert_signing",
    "key_encipherment",
    "digital_signature",
  ]
}

resource "tls_private_key" "webhook_cert" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P521"
}

resource "tls_cert_request" "webhook_cert" {
  private_key_pem = tls_private_key.webhook_cert.private_key_pem

  dns_names = ["value"]
  subject {
    common_name  = "value"
  }
}

resource "tls_locally_signed_cert" "webhook_cert" {
  cert_request_pem = tls_cert_request.webhook_cert.cert_request_pem

  ca_private_key_pem = tls_private_key.webhook_ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.webhook_ca.cert_pem

  validity_period_hours = 8766 # 1 year
  early_renewal_hours   = 8766 / 2
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
  ]
}

# the alb controller takes pem format without headers or linebreaks
# tf produces certs and keys in rfc1421 pem format including headers and linebreaks
locals {
  webhook_ca_crt = replace(
    replace(
      tls_self_signed_cert.webhook_ca.cert_pem,
      "/-----.*-----/",
      ""
    ),
    "/\\s/",
    ""
  )

  webhook_tls_crt = replace(
    replace(
      tls_locally_signed_cert.webhook_cert.cert_pem,
      "/-----.*-----/",
      ""
    ),
    "/\\s/",
    ""
  )
  webhook_tls_key = replace(
    replace(
      tls_private_key.webhook_cert.private_key_pem,
      "/-----.*-----/",
      ""
    ),
    "/\\s/",
    ""
  )
}

resource "kubernetes_secret" "alb_controller_webhook_tls" {
  metadata {
    name      = "aws-load-balancer-tls"
    namespace = "default"
    labels = {
      "app.kubernetes.io/instance"   = "aws-load-balancer-controller"
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/name"       = "aws-load-balancer-controller"
    }
  }
  type = "kubernetes.io/tls"
  data = {
    "ca.crt"  = local.webhook_ca_crt
    "tls.crt" = local.webhook_tls_crt
    "tls.key" = local.webhook_tls_key
  }
}
