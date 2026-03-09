resource "openstack_networking_network_v2" "ai_network" {
  name           = "ai-private-network"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "ai_subnet" {
  name            = "ai-private-subnet"
  network_id      = openstack_networking_network_v2.ai_network.id
  cidr            = "192.168.199.0/24"
  dns_nameservers = ["188.93.16.19", "188.93.17.19"]
  enable_dhcp     = false
}

data "openstack_networking_network_v2" "ai_external_network" {
  external = true
}

resource "openstack_networking_router_v2" "ai_router" {
  name                = "ai-router"
  external_network_id = data.openstack_networking_network_v2.ai_external_network.id
}

resource "openstack_networking_router_interface_v2" "ai_router_interface" {
  router_id = openstack_networking_router_v2.ai_router.id
  subnet_id = openstack_networking_subnet_v2.ai_subnet.id
}

resource "openstack_networking_secgroup_v2" "ai_secgroup" {
  name        = "ai-security-group"
  description = "Security group for AI Kubernetes cluster"
}

resource "openstack_networking_secgroup_rule_v2" "ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.ai_secgroup.id
}

resource "openstack_networking_secgroup_rule_v2" "k8s_api" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 6443
  port_range_max    = 6443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.ai_secgroup.id
}

resource "openstack_networking_secgroup_rule_v2" "http" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.ai_secgroup.id
}

resource "openstack_networking_secgroup_rule_v2" "https" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 443
  port_range_max    = 443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.ai_secgroup.id
}

resource "openstack_networking_secgroup_rule_v2" "nodeports" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 30000
  port_range_max    = 32767
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.ai_secgroup.id
}

resource "openstack_networking_secgroup_rule_v2" "internal" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = ""
  remote_ip_prefix  = openstack_networking_subnet_v2.ai_subnet.cidr
  security_group_id = openstack_networking_secgroup_v2.ai_secgroup.id
}
