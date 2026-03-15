# PROJECT KNOWLEDGE BASE

**Generated:** 2026-03-15T22:39:39+08:00
**Commit:** 57ef642
**Branch:** main

## OVERVIEW
GitOps infrastructure repo: Helm charts (wrapper + a few custom charts) deployed via ArgoCD (App-of-Apps) with per-environment values overlays.

## STRUCTURE
```
infra-gitops/
├── bootstrap/                # ArgoCD Applications + root App-of-Apps
├── charts/                   # Helm charts (wrapper-* + custom charts)
├── environments/{dev,prod}/  # Values overlays: *-values.yaml (deltas only)
├── docker/                   # Local dev utilities (nacos via podman-compose, flinkcdc image inputs)
├── rbac/                     # Optional RBAC manifests
├── storage/                  # Optional manual PV/PVC manifests (kind hostPath)
├── init_gitops_infra.sh      # Generator/scaffold script
├── kind-config.yaml          # Kind cluster config
└── kind-with-proxy.sh        # Inject proxy + registry config into kind node
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| Add a new service | `charts/<svc>/`, `environments/{dev,prod}/<svc>-values.yaml`, `bootstrap/argocd-apps/{env}/` | Keep overlays as deltas only. |
| Bump a chart dependency version | `charts/<svc>/Chart.yaml` | Wrapper charts are named `wrapper-<svc>` in `Chart.yaml`. |
| Change dev/prod sizing | `environments/dev/*-values.yaml`, `environments/prod/*-values.yaml` | Avoid copying full values; only overrides. |
| Fix ArgoCD sync / app wiring | `bootstrap/root-*.yaml`, `bootstrap/argocd-apps/**.yaml` | `repoURL` placeholders/TODOs can block sync. |
| Validate a change locally | `helm ... --dry-run --debug` + `kubectl describe application ...` | No CI in this repo; manual verification is expected. |
| Local registry + kind networking | `README.md` + `kind-config.yaml` | Registry is referenced as `local-registry:5000`. |
| Flink CDC job (custom chart) | `charts/flink-jobs/` | Contains FlinkDeployment templates and CDC config. |
| Manual PV/PVC for kind hostPath | `storage/*.yaml` | Uses `hostPath` (kind node filesystem). |
| Flink RBAC | `rbac/flink-rbac.yaml` | Role/RoleBinding for `ServiceAccount/flink`. |

## CONVENTIONS
- YAML is 2-space indented (especially under `charts/` and `bootstrap/`).
- ArgoCD Application naming is `{env}-{app}` (e.g. `dev-kafka`), and namespaces are environment-specific (e.g. `prod-infra`, plus some dev app namespaces like `bigdata`, `flink`, `monitoring`).
- Values layering (in ArgoCD apps): `values.yaml` then `../../environments/<env>/<app>-values.yaml` (later wins).
- Prefer changing environment-specific sizing/HA in `environments/` instead of editing large “defaults” files under charts.

## ANTI-PATTERNS (THIS PROJECT)
- Do not apply `bootstrap/` manifests before updating `repoURL` placeholders/TODOs (notably under `bootstrap/argocd-apps/prod/`).
- Do not commit secrets (e.g. `.env` files, tokens). Use templates/examples + external secrets mechanisms.
- Do not commit runtime data/logs from `docker/nacos/` (`data/`, `logs/`, `.env.nacos`).
- Avoid hardcoding production passwords in `values.yaml` (see `charts/flink-jobs/skill.md` guidance).
- Avoid editing huge upstream/vendor manifests by hand (e.g. `charts/argo/install.yaml` is enormous); prefer replacing from upstream if upgrading.

## COMMANDS
```bash
# Regenerate scaffolded structure (overwrites generated files)
bash init_gitops_infra.sh

# Helm sanity check (no cluster required)
helm template charts/<app> --values environments/dev/<app>-values.yaml

# Helm install simulation (requires kubeconfig)
helm install --dry-run --debug <app>-dry-run charts/<app> \
  --values environments/dev/<app>-values.yaml \
  --namespace <env>-infra

# Bootstrap ArgoCD App-of-Apps
kubectl apply -f bootstrap/root-app.yaml   # or root-dev.yaml / root-prod.yaml
kubectl get applications.argoproj.io -n argocd
kubectl describe application <env>-<app> -n argocd

# In-cluster connectivity probe
kubectl run netshoot --rm -it --image=local-registry:5000/nicolaka-netshoot --restart=Never -- bash
```

## NOTES
- `bootstrap/root-app.yaml` points ArgoCD at `bootstrap/argocd-apps/` with `recurse: true` (App-of-Apps).
- Several dev app manifests still include `# TODO: 修改为你的 Git 地址` even when `repoURL` is already filled; prod manifests still include placeholder URLs.
- `environments/dev/kafka-values.yaml` is intentionally empty in this snapshot; chart defaults apply.
