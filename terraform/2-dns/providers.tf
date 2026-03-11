terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.36"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
    infisical = {
      source  = "infisical/infisical"
      version = "~> 0.13"
    }
  }
}

locals {
  infisical_env_slug     = "prod"
  infisical_folder_path  = "/"
  infisical_workspace_id = "cc160c9f-8470-482f-a8da-350d68337f48"

  kubeconfig = yamldecode(data.terraform_remote_state.infra.outputs.kubeconfig)
  cluster    = local.kubeconfig.clusters[0].cluster
  user       = local.kubeconfig.users[0].user
}

provider "infisical" {
  host = "https://infisical.home.m1xxos.tech"
  auth = {
    universal = {
      client_id     = var.infisical_id
      client_secret = var.infisical_secret
    }
  }
}

provider "kubernetes" {
  host                   = local.cluster.server
  cluster_ca_certificate = base64decode(local.cluster["certificate-authority-data"])
  client_certificate     = base64decode(local.user["client-certificate-data"])
  client_key             = base64decode(local.user["client-key-data"])
}

ephemeral "infisical_secret" "cloudflare_api_token" {
  name         = "cloudflare_api_token"
  env_slug     = local.infisical_env_slug
  folder_path  = local.infisical_folder_path
  workspace_id = local.infisical_workspace_id
}

data "infisical_secrets" "main" {
  env_slug     = local.infisical_env_slug
  folder_path  = local.infisical_folder_path
  workspace_id = local.infisical_workspace_id
}

provider "cloudflare" {
  api_token = ephemeral.infisical_secret.cloudflare_api_token.value
}
