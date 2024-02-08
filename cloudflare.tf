terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

## Create the necessary CNAME so that Google can DNS authorize the certificate

resource "cloudflare_record" "certificate_root_cname" {
  zone_id = var.cloudflare_zone_id
  name    = google_certificate_manager_dns_authorization.root_domain_auth.dns_resource_record[0].name
  value   = google_certificate_manager_dns_authorization.root_domain_auth.dns_resource_record[0].data
  type    = "CNAME"
  ttl     = 60
}

resource "cloudflare_record" "wildcard_a_record" {
  zone_id = var.cloudflare_zone_id
  name    = "*"
  value   = google_compute_global_address.default.address
  type    = "A"
  proxied = true
  ttl     = 1
}

resource "cloudflare_record" "zone_apex" {
  zone_id = var.cloudflare_zone_id
  name    = "@"
  value   = google_compute_global_address.default.address
  type    = "A"
  proxied = true
  ttl     = 1
}

resource "cloudflare_record" "www_a_record" {
  zone_id = var.cloudflare_zone_id
  name    = "www"
  value   = google_compute_global_address.default.address
  type    = "A"
  proxied = true
  ttl     = 1
}

## Request CloudFlare Origin Certificate

resource "tls_private_key" "origin_private_key" {
  algorithm = "RSA"
}

resource "tls_cert_request" "origin_cert_request" {
  private_key_pem = tls_private_key.origin_private_key.private_key_pem

  subject {
    organization = "Netrunners"
  }
}

resource "cloudflare_origin_ca_certificate" "origin_certificate" {
  csr          = tls_cert_request.origin_cert_request.cert_request_pem
  hostnames    = [local.domain, "*.${local.domain}"]
  request_type = "origin-rsa"
}