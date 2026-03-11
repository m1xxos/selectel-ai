## Plan: Terragrunt → Terraform + LLM improvements

Переписать конфигурацию с Terragrunt на чистый Terraform, разделить на 3 последовательных проекта с передачей данных через `terraform_remote_state`, вынести DNS в отдельный проект, улучшить vLLM (PVC, безопасность, probes), создать AGENTS.md.

---

### Текущие проблемы
- Terragrunt генерирует `_backend.tf` и `_infisical.tf` — нужно заменить реальными файлами
- `dns.tf` в 1-argo зависит от Traefik LoadBalancer IP, но Traefik деплоится через ArgoCD **после** apply — sequential apply невозможен
- State уже в S3 (`yc-terraform-m1xxos-state`) с ключами `0-infra/terraform.tfstate` и `1-argo/terraform.tfstate`

### Целевая структура
```
terraform/
  backend.conf               # S3 credentials (gitignored)
  0-infra/
    backend.tf, providers.tf, network.tf, management.tf, k8s.tf, outputs.tf, variables.tf
  1-argo/
    backend.tf, providers.tf, data.tf, argocd.tf, variables.tf
  2-dns/                      # НОВЫЙ
    backend.tf, providers.tf, data.tf, dns.tf, variables.tf
argo/
  vllm/
    pvc.yaml                  # НОВЫЙ — PVC для кэша моделей
AGENTS.md                     # НОВЫЙ
```

Удалить: `root.hcl`, `env.hcl`, `*/terragrunt.hcl`, `*/_backend.tf`, `*/_infisical.tf`

---

### Steps

**Phase 1: Backend & Infisical (основа)**

1. Создать `terraform/backend.conf` — S3 credentials (`access_key`, `secret_key`). Добавить в `.gitignore`
2. Создать `backend.tf` в каждом проекте (0-infra, 1-argo, 2-dns) — S3 backend с теми же bucket/key что генерировал terragrunt. Credentials через `-backend-config=../backend.conf`
3. Инлайнить Infisical provider в `providers.tf` каждого проекта. Credentials через ` или `terraform.auto.tfvars` посмотри в git истории как было
4. Обновить `variables.tf` в 0-infra — добавить `infisical_client_id`, `infisical_client_secret`, `infisical_host`. В 1-argo — убрать переменную `kubeconfig`

**Phase 2: Cross-project data**

5. Создать `terraform/1-argo/data.tf` — `terraform_remote_state` читает outputs из 0-infra, получает `kubeconfig`
6. Обновить `terraform/1-argo/providers.tf` — Kubernetes/Helm providers берут kubeconfig из remote state вместо переменной
7. Удалить `terraform/1-argo/dns.tf` — DNS переезжает в 2-dns

**Phase 3: Новый проект 2-dns**

8. Создать `terraform/2-dns/` — `backend.tf`, `data.tf` (remote state → 0-infra для kubeconfig), `providers.tf` (Kubernetes, Cloudflare, Infisical), `dns.tf` (Traefik IP + Cloudflare record), `variables.tf`

**Phase 4: Улучшения vLLM**

9. Добавить `argo/vllm/pvc.yaml` — PersistentVolumeClaim 20Gi для `/root/.cache/huggingface`. Обновить `argo/vllm/deployment.yaml` — заменить `emptyDir` на PVC
10. Добавить **startupProbe** — vLLM долго грузит модель (20B). `failureThreshold: 120`, `periodSeconds: 10` = 20 минут на загрузку, чтобы liveness probe не убил pod
11. Добавить **`--api-key`** — vLLM API публично доступен без аутентификации. API key хранить в Kubernetes Secret
12. Добавить **resource requests** — CPU/memory для лучшего scheduling

**Phase 5: Очистка и миграция state**

13. Удалить файлы Terragrunt: `root.hcl`, `env.hcl`, оба `terragrunt.hcl`, все `_backend.tf`, все `_infisical.tf`
14. Миграция: `terraform init -backend-config=../backend.conf` в каждом проекте — state уже в S3 с правильными ключами, TF подхватит автоматически

**Phase 6: AGENTS.md**

15. Создать `AGENTS.md` в корне — описание проекта, стек, конвенции (чистый TF, remote state, ArgoCD для всего в k8s), структура 0-infra → 1-argo → 2-dns

---

### Relevant files

**Модифицировать:**
- `terraform/0-infra/providers.tf` — инлайнить Infisical provider
- `terraform/0-infra/variables.tf` — добавить infisical_* переменные
- `terraform/1-argo/providers.tf` — kubeconfig из remote state
- `terraform/1-argo/variables.tf` — убрать kubeconfig, добавить infisical vars
- `argo/vllm/deployment.yaml` — PVC, startup probe, API key, resources

**Создать:** `backend.conf`, `backend.tf` ×3, `1-argo/data.tf`, `2-dns/*` (5 файлов), `argo/vllm/pvc.yaml`, `AGENTS.md`

**Удалить:** `root.hcl`, `env.hcl`, `0-infra/terragrunt.hcl`, `1-argo/terragrunt.hcl`, `0-infra/_backend.tf`, `0-infra/_infisical.tf`, `1-argo/_backend.tf`, `1-argo/_infisical.tf`

---

### Verification

1. `terraform init -backend-config=../backend.conf` в 0-infra — подхватит существующий state
2. `terraform plan` в 0-infra — не должно быть изменений
3. `terraform init` + `plan` в 1-argo — покажет удаление DNS ресурсов
4. `terraform init` + `plan` в 2-dns — покажет создание DNS записи
5. ArgoCD синхронизирует vllm с новым PVC
6. `curl -H "Authorization: Bearer <key>" https://gpt.m1xxos.tech/v1/models`

---

### Decisions
- **Модель**: openai/gpt-oss-20b (подтверждена)
- **HF токен**: не нужен
- **PVC**: 50Gi для кэша моделей
- **Infisical credentials**: через `TF_VAR_` env vars или terraform.tfvars (gitignored)
- **DNS**: отдельный проект 2-dns, apply после готовности Traefik

---

### Further Considerations

1. **GPU Memory**: openai/gpt-oss-20b (20B)  добавить квантизацию q4
2. **Мониторинг**: DCGM Exporter включён, но нет Prometheus. Можно добавить `argo/kube-prometheus-stack/` для метрик GPU и vLLM (`/metrics` endpoint)
3. **ExternalDNS как альтернатива 2-dns**: можно развернуть ExternalDNS через ArgoCD с Cloudflare provider — DNS записи будут создаваться автоматически из Ingress аннотаций, и отдельный `terraform apply` не понадобится
