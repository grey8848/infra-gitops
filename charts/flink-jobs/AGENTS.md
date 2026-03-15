# CHARTS/FLINK-JOBS — AGENTS

## OVERVIEW
Custom Helm chart that renders Flink Kubernetes Operator CRs (FlinkDeployment) plus ConfigMaps for a MySQL → StarRocks CDC pipeline.

## STRUCTURE
```
charts/flink-jobs/
├── values.yaml
├── templates/
│   ├── flink-cdc.yaml
│   ├── configmap.yaml
│   └── _pipeline.yaml
└── skill.md
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| CDC enable/connection params | `charts/flink-jobs/values.yaml` | Contains `.Values.cdc.*` used by templates. |
| FlinkDeployment template | `charts/flink-jobs/templates/flink-cdc.yaml` | Rendered only when `cdc.enabled` is true. |
| Pipeline ConfigMap template | `charts/flink-jobs/templates/configmap.yaml` + `_pipeline.yaml` | Injects `pipeline.yaml` into the cluster. |
| Usage guidance | `charts/flink-jobs/skill.md` | Includes security notes (avoid prod passwords in values). |

## CONVENTIONS
- This chart is not a wrapper chart; it owns templates and produces CRs.
- Requires Flink Kubernetes Operator installed first (see `charts/flink-operator/` and ArgoCD apps).
- The ArgoCD dev app for this chart uses only `values.yaml` (no env overlay file) today.

## ANTI-PATTERNS
- Do not hardcode production credentials in `values.yaml`; use Secrets.

## COMMANDS
```bash
# Render locally
helm template charts/flink-jobs

# Install/upgrade (manual, if not using ArgoCD)
helm upgrade --install flink-jobs charts/flink-jobs --set cdc.enabled=true
```
