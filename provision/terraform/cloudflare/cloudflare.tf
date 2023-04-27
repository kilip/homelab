# Generates a 35-character secret for the tunnel.
resource "random_id" "tunnel_secret" {
  byte_length = 35
}

# Creates a new locally-managed tunnel for the GCP VM.
resource "cloudflare_tunnel" "k8s_tunnel" {
  account_id = var.cloudflare_account_id
  name       = "k8s_tunnel"
  secret     = random_id.tunnel_secret.b64_std
}

resource "cloudflare_tunnel_config" "echo-dev" {
  account_id  = var.cloudflare_account_id
  tunnel_id = cloudflare_tunnel.k8s_tunnel.id
  config {
    #origin_request {
    #  http_host_header   = "echo-server.dev.itstoni.com"
    #  origin_server_name = "echo-server.dev.itstoni.com"
    #}

    ingress_rule {
      hostname = "k8s-dev.itstoni.com"
      path = "/"
      service = "http://echo-server.default.svc.cluster.local:8080"
    }

    ingress_rule {
      hostname = "fw-dev.itstoni.com"
      path = "/"
      service = "http://webhook-receiver.flux-system.svc.cluster.local:80"
    }

    ingress_rule {
      service = "http_status:404"
    }
  }
}

# Creates the CNAME record that routes ssh_app.${var.cloudflare_zone} to the tunnel.
resource "cloudflare_record" "k8s-dev" {
  zone_id = var.cloudflare_zone_id
  name    = "k8s-dev"
  value   = "${cloudflare_tunnel.k8s_tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "fw-dev" {
  zone_id = var.cloudflare_zone_id
  name    = "fw-dev"
  value   = "${cloudflare_tunnel.k8s_tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}
