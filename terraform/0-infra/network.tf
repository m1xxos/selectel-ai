resource "yandex_vpc_network" "ai-network" {
  name   = "ai-network"
  labels = var.default_labels
}

resource "yandex_vpc_security_group" "ai-default" {
  name       = "ai-default-sg"
  network_id = yandex_vpc_network.ai-network.id
  labels     = var.default_labels
  egress {
    description    = "Permit ANY"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}
