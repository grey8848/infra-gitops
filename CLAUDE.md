# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **GitOps infrastructure repository** for managing Kubernetes infrastructure using ArgoCD and Helm. The project follows a three-layer architecture with clear separation of concerns:

1. **Logic Layer** (`charts/`): Helm wrapper charts that depend on Bitnami charts
2. **Configuration Layer** (`environments/`): Environment-specific Helm values
3. **Deployment Layer** (`bootstrap/`): ArgoCD application manifests

## Key Architectural Patterns

### DRY (Don't Repeat Yourself) Principle
- Wrapper charts in `charts/` centralize logic and version management
- To update a service version (e.g., Kafka), modify only the corresponding `Chart.yaml` file
- All environments automatically inherit the version change

### App-of-Apps Pattern
- `bootstrap/root-app.yaml` is the "App of Apps" entry point
- Manages all applications defined in `bootstrap/argocd-apps/` recursively
- Enables one-command deployment: `kubectl apply -f bootstrap/root-app.yaml`

### Configuration Layering
- Base values in wrapper charts (`charts/*/values.yaml`)
- Environment overrides in `environments/{dev,prod}/*-values.yaml`
- ArgoCD merges values using `valueFiles` array in application manifests

### Environment Isolation
- Dev: Lightweight configurations (1 replica, 5Gi storage)
- Prod: High availability (3 replicas, 50-100Gi storage, monitoring enabled)
- Separate Kubernetes namespaces: `dev-infra` and `prod-infra`

## Common Development Tasks

### Initializing the Project
```bash
# Run the bootstrap script to generate the entire structure
./init_gitops_infra.sh
```

### Customizing for Your Environment
1. Update Git repository URLs in all `bootstrap/argocd-apps/*.yaml` files
2. Modify `bootstrap/root-app.yaml` with your Git URL
3. Adjust resource allocations in `environments/{dev,prod}/*-values.yaml`

### Adding a New Service
1. Add wrapper chart to `charts/{service-name}/` with `Chart.yaml` and `values.yaml`
2. Create environment-specific values in `environments/{dev,prod}/{service-name}-values.yaml`
3. Add ArgoCD application manifest to `bootstrap/argocd-apps/{env}-{service-name}.yaml`
4. The root app will automatically detect and deploy the new service

### Deploying Infrastructure
```bash
# After committing and pushing to Git repository
kubectl apply -f bootstrap/root-app.yaml
```

### Updating Service Versions
1. Edit `charts/{service-name}/Chart.yaml` to update the `version` field
2. Commit and push changes
3. ArgoCD automatically syncs the new version to all environments

## File Structure Conventions

### Helm Wrapper Charts (`charts/`)
- Naming: `wrapper-{service-name}` (e.g., `wrapper-kafka`)
- Contains: `Chart.yaml` (dependencies), `values.yaml` (empty defaults), `.helmignore`
- Dependencies point to Bitnami charts for stability and maintenance

### Environment Configurations (`environments/`)
- File naming: `{service-name}-values.yaml`
- Dev: Minimal resources for development/testing
- Prod: Production-grade configurations with HA and monitoring

### ArgoCD Application Manifests (`bootstrap/argocd-apps/`)
- File naming: `{env}-{service-name}.yaml`
- Uses `valueFiles` array to merge base + environment-specific values
- Includes finalizers and sync policies for GitOps automation

## Technology Stack

- **GitOps**: ArgoCD for continuous deployment
- **Package Management**: Helm charts
- **Infrastructure Charts**: Bitnami Helm charts
- **Container Orchestration**: Kubernetes

## Important Notes

1. **TODO Markers**: The bootstrap script generates files with TODO comments for Git URLs - these must be updated before deployment
2. **Bitnami Charts**: Default dependency for stability; can be replaced with other chart repositories if needed
3. **Namespace Creation**: ArgoCD applications have `CreateNamespace=true` to automatically create required namespaces
4. **Self-Healing**: ArgoCD sync policies include `selfHeal: true` for automatic recovery from drift
5. **Pruning**: `prune: true` removes resources deleted from Git

## Workflow Summary

1. **Initialize**: Run `./init_gitops_infra.sh`
2. **Customize**: Update Git URLs and resource configurations
3. **Commit**: Push to Git repository (single source of truth)
4. **Deploy**: Apply root app with `kubectl apply -f bootstrap/root-app.yaml`
5. **Manage**: Make changes in Git; ArgoCD automatically syncs to cluster