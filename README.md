## This repository provisions a Cloud Run echo container, GCP GLB fronted by Cloudflare along with a managed GCP certificate and also a Cloudflare origin certificate 

### Traffic flow  - Client -> Cloudflare -> GLB -> CloudRun Nginx echo container

## Requirements to run this

1. GCP project - project_id
2. Cloudflare API token with proper permissions - cloudflare_api_token
3. Cloudflare DNS zone ID - cloudflare_zone_id
4. A domain that has been pointed at cloudflare - change that in locals.tf

You can pass the above variables in during terraform apply or use environment variables

By default, the GLB will use the Google managed certificate via certificate map, you can change this by adding the ssl_certificates option to the google_compute_target_https_proxy resource (load_balancer.tf)

After deployment you will get a 403 from CloudRun untill you turn on IAP for the back-end

DNS Authorization for Google managed wildcard certificate can take about ~15 minutes 

Some code borrowed from https://github.com/r-teller/gcp_service_extension_waf
