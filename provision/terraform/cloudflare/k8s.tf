# Generates a 35-character secret for the tunnel.
resource "random_id" "k8s_secret" {
  byte_length = 35
}

# Creates a new locally-managed tunnel for the GCP VM.
resource "cloudflare_tunnel" "k8s_tunnel" {
  account_id = var.cloudflare_account_id
  name       = "k8s_tunnel"
  secret     = random_id.k8s_secret.b64_std
}

resource "cloudflare_tunnel_config" "echo" {
  account_id  = var.cloudflare_account_id
  tunnel_id = cloudflare_tunnel.k8s_tunnel.id
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
    }

    ingress_rule {
      hostname = "k8s.itstoni.com"
      path = "/"
      service = "http://echo-server.default.svc.cluster.local:8080"
    }

    ingress_rule {

      hostname = "fw.itstoni.com"
      path = "/"
      service = "http://webhook-receiver.flux-system.svc.cluster.local:80"
    }

    ingress_rule {
      service = "http_status:404"
    }
  }
}

# Creates the CNAME record that routes ssh_app.${var.cloudflare_zone} to the tunnel.
resource "cloudflare_record" "k8s" {
  zone_id = var.cloudflare_zone_id
  name    = "k8s"
  value   = "${cloudflare_tunnel.k8s_tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "flux-webhook" {
  zone_id = var.cloudflare_zone_id
  name    = "fw"
  value   = "${cloudflare_tunnel.k8s_tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}

resource "local_file" "k8s_tunnel_json" {
  content = <<-DOC
    {
      "AccountTag":"${var.cloudflare_account_id}",
      "TunnelSecret":"${random_id.k8s_secret.b64_std}",
      "TunnelID":"${cloudflare_tunnel.k8s_tunnel.id}"
    }
    DOC
  filename = "./k8s-tunnel.json"
}
