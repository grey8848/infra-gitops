# BOOTSTRAP (ARGOCD) — AGENTS

## OVERVIEW
ArgoCD “App-of-Apps” manifests. Root Applications point ArgoCD at `bootstrap/argocd-apps/**` (with recursion) which defines per-service Applications.

## STRUCTURE
```
bootstrap/
├── root-app.yaml           # watches bootstrap/argocd-apps (all envs)
├── root-dev.yaml           # watches bootstrap/argocd-apps/dev
├── root-prod.yaml          # watches bootstrap/argocd-apps/prod
├── argocd-apps/
│   ├── dev/                # dev Applications (kafka/mysql/flink-operator/flink-jobs/...) 
│   └── prod/               # prod Applications (kafka/mysql/flink/...)
└── archive/                # legacy/unused manifests (do not build new work here)
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| Bootstrap everything | `bootstrap/root-app.yaml` | Recursively syncs all apps under `bootstrap/argocd-apps/`. |
| Bootstrap only dev/prod | `bootstrap/root-dev.yaml` / `bootstrap/root-prod.yaml` | Points to env-specific subdir. |
| Add a new service Application | `bootstrap/argocd-apps/<env>/<env>-<app>.yaml` | `metadata.name` convention: `<env>-<app>`. |
| Configure Helm layering | `spec.source.helm.valueFiles` | Usually `values.yaml` + `../../environments/<env>/<app>-values.yaml`. |
| Fix sync options / drift | `spec.syncPolicy.*` | Most apps use `prune: true`, `selfHeal: true`, `CreateNamespace=true`. |

## CONVENTIONS
- Application name and filename are `{env}-{app}` (e.g. `dev-kafka`, `prod-mysql`).
- Root Application name is `root-infra-app` across `root-*.yaml`.
- Destination namespaces vary by env: prod tends to use `prod-infra`; dev includes `bigdata`, `flink`, `monitoring`.

## ANTI-PATTERNS
- Do not apply prod manifests with placeholder `repoURL` values (`YOUR_USERNAME`) — ArgoCD will not sync.
- Avoid putting environment-specific sizing here; keep it in `environments/<env>/*-values.yaml`.
- Avoid editing `bootstrap/archive/` for active work.

## COMMANDS
```bash
# Apply a root Application (requires ArgoCD installed in-cluster)
kubectl apply -f bootstrap/root-app.yaml

# Inspect sync status
kubectl get applications.argoproj.io -n argocd
kubectl describe application dev-kafka -n argocd
```
