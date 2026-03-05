resource "openstack_networking_network_v2" "ai_network" {
  name           = "ai-private-network"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "ai_subnet_1" {
  name            = "ai-private-subnet"
  network_id      = openstack_networking_network_v2.ai_network.id
  cidr            = "192.168.199.0/24"
  dns_nameservers = ["188.93.16.19", "188.93.17.19"]
  enable_dhcp     = false
}