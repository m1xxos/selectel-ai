data "kubernetes_service_v1" "traefik" {
  metadata {
    name      = "traefik"
    namespace = "traefik"
  }

  depends_on = [kubectl_manifest.appset]
}

resource "cloudflare_dns_record" "gpt" {
  zone_id = var.cloudflare_zone_id
  name    = "gpt.m1xxos.tech"
  type    = "A"
  content = data.kubernetes_service_v1.traefik.status[0].load_balancer[0].ingress[0].ip
  proxied = false
  ttl     = 300
}
