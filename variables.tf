variable "cloudflare_api_token" {}

variable "project_id" {
  type = string
}

variable "cloudflare_zone_id"{
    type = string
}

variable "regions" {
  type    = list(string)
  default = ["us-central1"]
}
