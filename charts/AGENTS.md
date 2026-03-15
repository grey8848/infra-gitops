# CHARTS — AGENTS

## OVERVIEW
Helm charts layer (logic). Most entries under `charts/` are wrapper charts (`wrapper-<app>`) that pin an upstream dependency and keep cluster-agnostic defaults.

## STRUCTURE
```
charts/
├── <app>/                     # wrapper chart dir name (no wrapper- prefix)
│   ├── Chart.yaml              # name: wrapper-<app> + dependency version
│   └── values.yaml             # base defaults (env deltas live in environments/)
└── flink-jobs/                    # custom chart (templates FlinkDeployment CRs)
    ├── Chart.yaml
    ├── values.yaml
    └── templates/
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| Change upstream chart version | `charts/<app>/Chart.yaml` | Wrapper charts pin dependency versions here. |
| Adjust default images/tags | `charts/<app>/values.yaml` | This repo commonly uses `local-registry:5000` images. |
| Environment-only sizing/HA | `environments/{dev,prod}/<app>-values.yaml` | Keep overlays as deltas only. |
| Custom Flink CDC job resources | `charts/flink-jobs/templates/*` | Generates FlinkDeployment + ConfigMap from values. |
| Upstream/vendor giant manifests | `charts/argo/install.yaml` | Treat as upstream-synced; replace wholesale on upgrades. |

## CONVENTIONS
- Wrapper chart `Chart.yaml` names start with `wrapper-` (e.g. `wrapper-kafka`), but directory names do not.
- Values keys typically match dependency names (e.g. `kafka:` in `charts/kafka/values.yaml`).
- Prefer environment overlays for replica/storage/HA changes; avoid copying full upstream defaults files.

## ANTI-PATTERNS
- Avoid hand-editing huge upstream files (notably `charts/argo/install.yaml`). Upgrade by replacing from upstream.
- Avoid hardcoding prod secrets in `values.yaml`; use secrets mechanisms and env overlays.

## COMMANDS
```bash
# Render chart with environment overrides (no cluster required)
helm template charts/<app> --values environments/dev/<app>-values.yaml

# Dry-run simulate install (requires kubeconfig)
helm install --dry-run --debug <app>-dry-run charts/<app> \
  --values environments/dev/<app>-values.yaml \
  --namespace dev-infra
```
