data "selectel_mks_kube_versions_v1" "versions" {
  project_id = var.project_id
  region     = "ru-9"
}

resource "selectel_mks_cluster_v1" "ai_cluster" {
  name                              = "ai-cluster"
  project_id                        = var.project_id
  region                            = var.region
  kube_version                      = data.selectel_mks_kube_versions_v1.versions.latest_version
  zonal                             = true
  enable_patch_version_auto_upgrade = false
  network_id                        = openstack_networking_network_v2.ai_network.id
  subnet_id                         = openstack_networking_subnet_v2.ai_subnet.id
  maintenance_window_start          = "00:00:00"
}

resource "selectel_mks_nodegroup_v1" "gpu_spot" {
  cluster_id                   = selectel_mks_cluster_v1.ai_cluster.id
  project_id                   = selectel_mks_cluster_v1.ai_cluster.project_id
  region                       = selectel_mks_cluster_v1.ai_cluster.region
  availability_zone            = var.region
  flavor_id                    = "3031" # GL3.4-32768-0-1GPU
  nodes_count                  = 1
  install_nvidia_device_plugin = false
  preemptible                  = true
  labels = {
    "gpu" : "true",
    "spot" : "true",
    "accelerator" : "nvidia-tesla-t4"
  }
}
