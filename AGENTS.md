# AGENTS.md

## Project Overview

AI inference platform on Selectel GPU Kubernetes (MKS) with GitOps deployment via ArgoCD.

**Domain**: `gpt.m1xxos.tech`
**Model**: openai/gpt-oss-20b served by vLLM
**GPU**: NVIDIA Tesla T4 (1x, preemptible/spot instances)

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Cloud | Selectel (OpenStack API) |
| IaC | Terraform (pure, no Terragrunt) |
| State | S3 backend (Yandex Cloud Storage) |
| Secrets | Infisical (self-hosted at `infisical.home.m1xxos.tech`) |
| Kubernetes | Selectel MKS (Managed Kubernetes) |
| GitOps | ArgoCD with ApplicationSet (syncs `argo/*` directories) |
| Ingress | Traefik (LoadBalancer) |
| TLS | cert-manager + Let's Encrypt |
| DNS | Cloudflare |
| GPU | NVIDIA GPU Operator |
| Inference | vLLM (OpenAI-compatible API) |

## Project Structure

```
terraform/
  backend.conf                    # S3 credentials (gitignored)
  0-infra/                        # Network, K8s cluster, service accounts
  1-argo/                         # ArgoCD + ApplicationSet
  2-dns/                          # Cloudflare DNS records
argo/
  cert-manager/                   # TLS certificate management
  traefik/                        # Ingress controller
  nvidia-gpu-operator/            # GPU drivers & runtime
  vllm/                           # LLM inference server
```

## Conventions

### Terraform
- **Pure Terraform** — no Terragrunt, no wrappers
- **Sequential projects**: `0-infra` → `1-argo` → `2-dns` (run `terraform apply` in order)
- **Cross-project data**: use `terraform_remote_state` to read outputs from upstream projects
- **Backend**: S3 on Yandex Cloud Storage, credentials via `-backend-config=../backend.conf`
- **Secrets**: Infisical provider with `infisical_id`/`infisical_secret` variables (passed via `terraform.auto.tfvars`, gitignored)
- **Init command**: `terraform init -backend-config=../backend.conf`
- **State keys**: `{project-dir}/terraform.tfstate` (e.g., `0-infra/terraform.tfstate`)
- **Provider versions**: pin exact versions for cloud providers, use `~>` for utilities

### Kubernetes / ArgoCD
- **Everything in Kubernetes goes through ArgoCD** — do not use Terraform Kubernetes/Helm providers for app workloads
- **ArgoCD ApplicationSet** scans `argo/*` directories: each subdirectory becomes an ArgoCD Application
- **Namespace** = directory name (e.g., `argo/vllm/` → namespace `vllm`)
- **Helm charts**: wrap upstream charts as umbrella charts in `argo/{name}/` with `Chart.yaml` + `values.yaml`
- **Raw manifests**: for non-Helm apps (like vLLM), place YAML files directly in `argo/{name}/`
- **Sync policy**: automated with pruning and self-heal enabled

### Git
- Sensitive files are gitignored: `*.tfvars`, `backend.conf`, `.terraform/`
- Repository: `https://github.com/m1xxos/selectel-ai.git`

## Deployment Flow

1. `cd terraform/0-infra && terraform init -backend-config=../backend.conf && terraform apply`
   → Creates network, service account, GPU Kubernetes cluster
2. `cd terraform/1-argo && terraform init -backend-config=../backend.conf && terraform apply`
   → Deploys ArgoCD, which auto-syncs all `argo/*` apps (cert-manager, traefik, gpu-operator, vllm)
3. Wait for Traefik LoadBalancer to get an external IP
4. `cd terraform/2-dns && terraform init -backend-config=../backend.conf && terraform apply`
   → Creates Cloudflare DNS record pointing to Traefik IP

## Key Details

- **GPU node flavor**: `3031` (GL3.4-32768-0-1GPU: 4 vCPU, 32GB RAM, 1x T4)
- **Node labels**: `gpu=true`, `spot=true`, `accelerator=nvidia-tesla-t4`
- **vLLM API** is protected with `--api-key-file` (secret `vllm-api-key` in namespace `vllm`)
- **Model cache** persists on a PVC (20Gi) at `/root/.cache/huggingface`
- **Quantization**: FP8 (`--quantization fp8`) to fit 20B model into T4 16GB VRAM
