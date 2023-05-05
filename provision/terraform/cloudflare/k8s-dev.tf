# Generates a 35-character secret for the tunnel.
resource "random_id" "tunnel_secret" {
  byte_length = 35
}

# Creates a new locally-managed tunnel for the GCP VM.
resource "cloudflare_tunnel" "k8s_dev_tunnel" {
  account_id = var.cloudflare_account_id
  name       = "k8s_dev_tunnel"
  secret     = random_id.tunnel_secret.b64_std
}

resource "cloudflare_tunnel_config" "echo-dev" {
  account_id  = var.cloudflare_account_id
  tunnel_id = cloudflare_tunnel.k8s_dev_tunnel.id
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
      hostname = "k8s-dev.itstoni.com"
      path = "/"
      service = "http://echo-server.default.svc.cluster.local:8080"
    }

    ingress_rule {
      service = "http_status:404"
    }
  }
}

# Creates the CNAME record that routes ssh_app.${var.cloudflare_zone} to the tunnel.
resource "cloudflare_record" "k8s-dev" {
  allow_overwrite = true
  zone_id = var.cloudflare_zone_id
  name    = "k8s-dev"
  value   = "${cloudflare_tunnel.k8s_dev_tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "fw-dev" {
  allow_overwrite = true
  zone_id = var.cloudflare_zone_id
  name    = "fw-dev"
  value   = "${cloudflare_tunnel.k8s_dev_tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "emqx-dev" {
  allow_overwrite = true
  zone_id = var.cloudflare_zone_id
  name    = "emqx-dev"
  value   = "${cloudflare_tunnel.k8s_dev_tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}

#resource "local_file" "tf_ansible_vars_file" {
#  content = <<-DOC
#    # Ansible vars_file containing variable values from Terraform.
#    tunnel_id: ${cloudflare_tunnel.k8s_dev_tunnel.id}
#    account: ${var.cloudflare_account_id}
#    tunnel_name: ${cloudflare_tunnel.k8s_dev_tunnel.name}
#    secret: ${random_id.tunnel_secret.b64_std}
#    zone: ${var.cloudflare_zone}
#    DOC
#
#  filename = "./k8s-dev-tunnel.json"
#}

resource "local_file" "tf_tunnel" {
  content = <<-DOC
    {
      "AccountTag":"${var.cloudflare_account_id}",
      "TunnelSecret":"${random_id.tunnel_secret.b64_std}",
      "TunnelID":"${cloudflare_tunnel.k8s_dev_tunnel.id}"
    }
    DOC
  filename = "./k8s-dev-tunnel.json"
}
