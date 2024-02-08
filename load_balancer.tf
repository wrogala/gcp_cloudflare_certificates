resource "random_id" "id" {
  byte_length = 2
}

resource "google_compute_global_address" "default" {
  project = var.project_id

  provider = google-beta
  name     = format("l7-glb-static-ip-%s", random_id.id.hex)
}

resource "google_compute_global_forwarding_rule" "gcr_echo_xlb_forwarding_80" {
  project = var.project_id

  name                  = format("l7-xlb-echo-forwarding-rule-http-%s", random_id.id.hex)
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "80"
  target                = google_compute_target_http_proxy.gcr_echo_http.id
  ip_address            = google_compute_global_address.default.id
}

resource "google_compute_target_http_proxy" "gcr_echo_http" {
  project = var.project_id

  name    = format("l7-xlb-echo-target-http-proxy-%s", random_id.id.hex)
  url_map = google_compute_url_map.gcr_echo_url_map.id
}

resource "google_compute_global_forwarding_rule" "gcr_echo_xlb_forwarding_443" {
  project = var.project_id

  name                  = format("l7-xlb-echo-forwarding-rule-https-%s", random_id.id.hex)
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "443"
  target                = google_compute_target_https_proxy.gcr_echo_https.id
  ip_address            = google_compute_global_address.default.id
}

resource "google_compute_target_https_proxy" "gcr_echo_https" {
  project = var.project_id

  name             = format("l7-xlb-echo-target-https-proxy-%s", random_id.id.hex)
  quic_override    = "DISABLE"
  url_map          = google_compute_url_map.gcr_echo_url_map.id
  certificate_map = "//certificatemanager.googleapis.com/${google_certificate_manager_certificate_map.certificate_map.id}"
  #ssl_certificates = [google_compute_ssl_certificate.cloudflare_origin_wildcard.id]
}

resource "google_compute_url_map" "gcr_echo_url_map" {
  project = var.project_id

  name            = format("l7-xlb-echo-url-map-%s", random_id.id.hex)
  default_service = google_compute_backend_service.gcr_echo_backend.id

    host_rule {
    hosts = ["alpha.netrun.cloud"]
    path_matcher = "alpha"

  }
  path_matcher {
   default_service = google_compute_backend_service.gcr_echo_backend.id
   name = "alpha"

   route_rules {
    priority = 1
    
    match_rules {
      ignore_case = true
      prefix_match = "/"
    }
      route_action {
          url_rewrite {
            # This re-writes the host header to alpha.netrun.cloud
            host_rewrite = "beta.netrun.cloud"
            path_prefix_rewrite = "/"
          }
          weighted_backend_services {
            backend_service = google_compute_backend_service.gcr_echo_backend.id
            weight = 100
        }
    }
   }
  }
}