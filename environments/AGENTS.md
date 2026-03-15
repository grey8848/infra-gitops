# ENVIRONMENTS (VALUES OVERLAYS) — AGENTS

## OVERVIEW
Environment-specific Helm values overlays. These files are deltas layered on top of `charts/<app>/values.yaml` via ArgoCD `valueFiles`.

## STRUCTURE
```
environments/
├── dev/
│   └── <app>-values.yaml
└── prod/
    └── <app>-values.yaml
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| Change dev sizing | `environments/dev/*-values.yaml` | Prefer minimal overrides (replicas/storage/HA toggles). |
| Change prod sizing/HA | `environments/prod/*-values.yaml` | Keep only deltas from chart defaults. |
| Confirm merge order | `bootstrap/argocd-apps/**.yaml` → `spec.source.helm.valueFiles` | Later valueFiles override earlier ones. |

## CONVENTIONS
- Overlays are deltas only. Do not copy full upstream default values files into `environments/`.
- Keys must match chart expectations (e.g. `kafka.replicaCount`, not a top-level `replicaCount`).
- Empty files are allowed (e.g. dev kafka overlay can be intentionally empty to use chart defaults).

## COMMON PITFALLS
- Wrong key path: Helm renders fine but settings do nothing.
- Duplicating full config: makes dev vs prod differences hard to review.
- Secrets in overlays: avoid committing real passwords/tokens; use secrets mechanisms.

## COMMANDS
```bash
# Render chart with an overlay (no cluster required)
helm template charts/<app> --values environments/dev/<app>-values.yaml

# Dry-run simulate install (requires kubeconfig)
helm install --dry-run --debug <app>-dry-run charts/<app> \
  --values environments/prod/<app>-values.yaml \
  --namespace prod-infra
```
