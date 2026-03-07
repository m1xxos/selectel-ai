data "selectel_mks_kube_versions_v1" "versions" {
  project_id = var.project_id
  region     = "ru-9"
}

resource "selectel_mks_cluster_v1" "ai_cluster" {
  name                              = "ai-cluster"
  project_id                        = var.project_id
  region                            = "ru-9"
  kube_version                      = data.selectel_mks_kube_versions_v1.versions.latest_version
  zonal                             = true
  enable_patch_version_auto_upgrade = false
  network_id                        = openstack_networking_network_v2.ai_network.id
  subnet_id                         = openstack_networking_subnet_v2.ai_subnet.id
  maintenance_window_start          = "00:00:00"
}

resource "selectel_mks_nodegroup_v1" "nodegroup_1" {
  cluster_id                   = selectel_mks_cluster_v1.ai_cluster.id
  project_id                   = selectel_mks_cluster_v1.ai_cluster.project_id
  region                       = selectel_mks_cluster_v1.ai_cluster.region
  availability_zone            = "ru-9a"
  nodes_count                  = "2"
  cpus                         = 2
  ram_mb                       = 4096
  volume_gb                    = 32
  volume_type                  = "fast.ru-9a"
  install_nvidia_device_plugin = false
  labels                       = {
    "label-key0": "label-value0",
    "label-key1": "label-value1",
    "label-key2": "label-value2",
  }
}
