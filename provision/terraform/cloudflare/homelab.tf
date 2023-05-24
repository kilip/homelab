# Generates a 35-character secret for the tunnel.
resource "random_id" "homelab_secret" {
  byte_length = 35
}

# Creates a new locally-managed tunnel for the GCP VM.
resource "cloudflare_tunnel" "homelab_tunnel" {
  account_id = var.cloudflare_account_id
  name       = "homelab_tunnel"
  secret     = random_id.homelab_secret.b64_std
}

resource "cloudflare_tunnel_config" "homelab" {
  account_id  = var.cloudflare_account_id
  tunnel_id = cloudflare_tunnel.homelab_tunnel.id
  config {

    origin_request {
      connect_timeout          = "1m0s"
      tls_timeout              = "1m0s"
      tcp_keep_alive           = "1m0s"
      no_happy_eyeballs        = false
      keep_alive_connections   = 1024
      keep_alive_timeout       = "1m0s"
      http_host_header         = "${var.cloudflare_zone}"
      origin_server_name       = "${var.cloudflare_zone}"
      no_tls_verify            = true
    }

    ingress_rule {
      hostname = "hestia.itstoni.com"
      path = "/"
      service = "https://hass.itstoni.com"
    }

    ingress_rule {
      service = "http_status:404"
    }
  }
}

resource "cloudflare_record" "hestia" {
  allow_overwrite = true
  zone_id = var.cloudflare_zone_id
  name    = "hestia"
  value   = "${cloudflare_tunnel.homelab_tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}

resource "local_file" "homelab_tunnel_json" {
  content = <<-DOC
    {
      "AccountTag":"${var.cloudflare_account_id}",
      "TunnelSecret":"${random_id.k8s_secret.b64_std}",
      "TunnelID":"${cloudflare_tunnel.k8s_tunnel.id}"
    }
    DOC
  filename = "./homelab_tunnel.json"
}
