resource "random_id" "tf_prefix" {
  byte_length = 4
}

resource "google_project_service" "certificatemanager_svc" {
  service            = "certificatemanager.googleapis.com"
  project   = var.project_id
  disable_on_destroy = false
}

## Create a wildcard certificate in GCP with DNS authorization

resource "google_certificate_manager_dns_authorization" "root_domain_auth" {
  name        = "${local.name}-dnsauth-${random_id.tf_prefix.hex}"
  description = "GCP DNS authorization"
  domain      = local.domain 
  project   = var.project_id
  labels = {
    "terraform" : true
  }
}

## Create a managed certificate from DNS authorization

resource "google_certificate_manager_certificate" "root_cert" {
  name        = "${local.name}-rootcert-${random_id.tf_prefix.hex}"
  description = "Root and wildcard SSL certificate"
  project   = var.project_id
  managed {
    domains = [
      "*.${local.domain}",
      local.domain
    ]
    dns_authorizations = [
      google_certificate_manager_dns_authorization.root_domain_auth.id,
    ]
  }
  labels = {
    "terraform" : true
  }
}

resource "google_certificate_manager_certificate_map" "certificate_map" {
  name        = "${local.name}-certmap-${random_id.tf_prefix.hex}"
  description = "${local.domain} certificate map"
  project   = var.project_id

  labels = {
    "terraform" : true
  }
}

resource "google_certificate_manager_certificate_map_entry" "first_entry" {
  name        = "${local.name}-first-entry-${random_id.tf_prefix.hex}"
  description = "${local.name} certificate map entry 1"
  project   = var.project_id
  map         = google_certificate_manager_certificate_map.certificate_map.name
  labels = {
    "terraform" : true
  }
  certificates = [google_certificate_manager_certificate.root_cert.id]
  hostname     = "*.${local.domain}"
}

resource "google_certificate_manager_certificate_map_entry" "second_entry" {
  name        = "${local.name}-second-entry-${random_id.tf_prefix.hex}"
  description = "${local.name} certificate map entry 2"
  project   = var.project_id
  map         = google_certificate_manager_certificate_map.certificate_map.name
  labels = {
    "terraform" : true
  }
  certificates = [google_certificate_manager_certificate.root_cert.id]
  matcher = "PRIMARY"
}


# Create a CloudFlare origin certificate in GCP from CloudFlare

resource "google_compute_ssl_certificate" "cloudflare_origin_wildcard" {
  name_prefix = "${local.name}-cf-origin-cert"
  private_key = tls_private_key.origin_private_key.private_key_pem
  certificate = cloudflare_origin_ca_certificate.origin_certificate.certificate
  project   = var.project_id
  lifecycle {
    create_before_destroy = true
  }
}