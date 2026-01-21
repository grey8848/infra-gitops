# Repository Guidelines

## Project Structure & Module Organization
- `charts/<app>/` contains wrapper Helm charts that mirror Bitnami dependencies; each chart is named `wrapper-<app>` and keeps its own `values.yaml`.
- `environments/{dev,prod}` holds `<app>-values.yaml` overrides—only items that differ from the defaults should live here.
- `bootstrap/` stores ArgoCD manifests: `argocd-apps/{env}-{app}.yaml` targets the corresponding chart and values file, and `root-app.yaml` wires the App-of-Apps.
- Run `bash init_gitops_infra.sh` to regenerate the charts, values, and ArgoCD manifests when you add services or change repo metadata; the script echoes next steps too.

## Build, Test, and Development Commands
- `bash init_gitops_infra.sh` regenerates charts, environments, and ArgoCD files after structural changes; finish by pointing the generated manifests at your repo.
- Connect the local registry to Kind (`docker network connect kind local-registry`) and curl `local-registry:5000/v2/_catalog` after identifying the container via `docker ps | grep registry`.
- `kubectl apply -f bootstrap/root-app.yaml` triggers the App-of-Apps sync once ArgoCD is running; monitor with `kubectl get applications.argoproj.io -n argocd`.
- `kubectl run netshoot --rm -it --image=local-registry:5000/nicolaka-netshoot --restart=Never -- bash` offers a quick in-cluster connectivity check.

## Coding Style & Naming Conventions
- YAML in `charts/` and `bootstrap/` uses two-space indentation and explicit `metadata.name` values such as `dev-kafka`.
- Helm wrapper charts keep the `wrapper-` prefix and defer overrides to the environment-specific files under `environments/{env}/{app}-values.yaml`.
- Keep shell snippets simple and echo-driven (as in `init_gitops_infra.sh`); document manual steps only when new scripts arrive.

## Testing Guidelines
- No automated CI tests exist yet; use `helm install --dry-run --debug charts/<app> --values environments/dev/<app>-values.yaml` before applying.
- After syncing, confirm `kubectl get pods -n <env>-infra` and `kubectl describe application <env>-<app> -n argocd` to be sure the app reconciles.
- Document your verification steps in the PR whenever you touch bootstrap or environment manifests.

## Commit & Pull Request Guidelines
- Keep commit subjects short and service-specific (e.g., `flink: adjust prod replicas`) to match the existing history.
- Add a short body only when the change is complex or requires manual verification notes.
- PRs should state the target environment(s), list the affected charts/values, and summarize any local verification.

## Deployment & Configuration Tips
- Use `kind-config.yaml` (or `kind-with-proxy.sh` when using proxies) to mirror production networking in a local Kind cluster.
- Update every ArgoCD manifest’s `repoURL` to your repo/branch before running `kubectl apply -f bootstrap/root-app.yaml`.
- When adding a new service: create a wrapper chart, add per-env overrides, and reference them from `bootstrap/argocd-apps`.
