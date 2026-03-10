terraform {
  required_providers {
    selectel = {
      source  = "selectel/selectel"
      version = "7.5.4"
    }
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "2.1.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.8.1"
    }
    infisical = {
      source  = "infisical/infisical"
      version = "~> 0.13"
    }
  }
}

ephemeral "infisical_secret" "selectel_username" {
  name         = "selectel_username"
  env_slug     = local.infisical_env_slug
  folder_path  = local.infisical_folder_path
  workspace_id = local.infisical_workspace_id
}

ephemeral "infisical_secret" "selectel_password" {
  name         = "selectel_password"
  env_slug     = local.infisical_env_slug
  folder_path  = local.infisical_folder_path
  workspace_id = local.infisical_workspace_id
}

ephemeral "infisical_secret" "selectel_domain_name" {
  name         = "selectel_domain_name"
  env_slug     = local.infisical_env_slug
  folder_path  = local.infisical_folder_path
  workspace_id = local.infisical_workspace_id
}

provider "selectel" {
  auth_region = "ru-9"
  auth_url    = "https://cloud.api.selcloud.ru/identity/v3/"
  username    = ephemeral.infisical_secret.selectel_username.value
  password    = ephemeral.infisical_secret.selectel_password.value
  domain_name = ephemeral.infisical_secret.selectel_domain_name.value
}

provider "openstack" {
  auth_url  = "https://cloud.api.selcloud.ru/identity/v3"
  tenant_id = var.project_id
  user_name = selectel_iam_serviceuser_v1.ai_sa.name
  password  = selectel_iam_serviceuser_v1.ai_sa.password
  region    = "ru-9"
}
