data "selectel_mks_kubeconfig_v1" "kubeconfig" {
  cluster_id = selectel_mks_cluster_v1.ai_cluster.id
  project_id = selectel_mks_cluster_v1.ai_cluster.project_id
  region     = selectel_mks_cluster_v1.ai_cluster.region
}

output "kubeconfig" {
  value = data.selectel_mks_kubeconfig_v1.kubeconfig.raw_config
  sensitive = true
}