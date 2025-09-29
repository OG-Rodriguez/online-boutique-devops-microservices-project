# Continuous Deployment Pipeline (AWS EKS + Helm + GitHub Actions)

This document explains how the CD workflow (`.github/workflows/cd.yml`) deploys the Online Boutique application to an AWS EKS cluster using Helm, aligned with AWS best practices.

## Overview
1. Trigger: Push (merge) to `main` branch (CD only runs on main).
2. Auth: GitHub OIDC assumes an AWS IAM role (`AWS_GITHUB_ROLE_ARN` secret).
3. Cluster Access: `aws eks update-kubeconfig` configures `kubectl` for the target cluster.
4. Safety: CD verifies images exist in ECR before deploying.
5. Deploy: `helm upgrade --install` with `--atomic --timeout 10m` for safe rollouts.
6. Chart: Single consolidated chart at `helm-chart/` with global `images.repository` and `images.tag`.

## Image Tagging Convention (CI → CD)
- CI pushes two tags for each service to ECR:
  - Immutable: first 12 characters of the commit SHA (e.g., `sha12`)
  - Mutable: `latest` (convenience)
- CD injects the immutable tag into Helm:
```
--set images.tag=<12-char-sha>
```

## Required GitHub Secrets
| Secret | Description |
| ------ | ----------- |
| `AWS_GITHUB_ROLE_ARN` | IAM role ARN trusted by GitHub OIDC and authorized for EKS/ECR actions. |
| `ECR_REGISTRY` | Your ECR registry, e.g., `<account-id>.dkr.ecr.us-east-2.amazonaws.com`. |

## IAM and RBAC
- IAM role permissions should include:
  - `eks:DescribeCluster`
  - `ecr:GetAuthorizationToken`, `ecr:BatchGetImage`, `ecr:DescribeRepositories`, `ecr:ListImages`, `ecr:GetDownloadUrlForLayer`
- Map the IAM role in `aws-auth` ConfigMap to a Kubernetes group with rights to create/update deployments/services (use `system:masters` initially; tighten later).

## Helm Deploy Command (as run by CD)
```
helm upgrade --install onlineboutique helm-chart \
  --namespace online-boutique --create-namespace \
  --set images.repository=$ECR_REGISTRY \
  --set images.tag=<12-char-sha> \
  --atomic --timeout 10m
```

> Tip: You can permanently change `images.repository` in `helm-chart/values.yaml`, or keep it overridden by CD.

## Pre-Deployment Image Verification
The CD workflow checks that all microservice images with the target tag are present in ECR. If any are missing, the job fails before Helm is invoked. This prevents `ImagePullBackOff` due to tag mismatch.

## Post-Deployment Smoke Test
The CD waits for rollout of core deployments:
```
kubectl rollout status deployment/frontend -n online-boutique --timeout=300s
kubectl rollout status deployment/productcatalogservice -n online-boutique --timeout=300s
kubectl rollout status deployment/cartservice -n online-boutique --timeout=300s
```

## Local Dry Run
```
helm upgrade --install onlineboutique helm-chart \
  --namespace online-boutique --create-namespace \
  --set images.repository=<account-id>.dkr.ecr.us-east-2.amazonaws.com \
  --set images.tag=$(git rev-parse --short=12 HEAD) \
  --dry-run --debug
```

## Rollback
```
helm history onlineboutique -n online-boutique
helm rollback onlineboutique <REVISION> -n online-boutique
```

## Troubleshooting
| Issue | Cause | Fix |
| ----- | ----- | --- |
| ImagePullBackOff | Tag not pushed to ECR | Ensure CI pushed `:sha12` for all services. |
| Unauthorized (kubectl) | Missing `aws-auth` mapping | Map `AWS_GITHUB_ROLE_ARN` role to cluster RBAC. |
| Helm timeout / rollback | Pods not Ready | `kubectl describe pod`, check events/logs, tune resources. |
| Wrong image repository | Repo mismatch | Set `--set images.repository=$ECR_REGISTRY` in CD. |

## Activity 3.1 Submission Checklist
- [ ] `.github/workflows/cd.yml` exists and triggers on push to `main` only.
- [ ] CD uses Helm with `helm upgrade --install` pointing to `helm-chart/`.
- [ ] CD injects the `images.tag=<12-char-sha>` value used by CI.
- [ ] CD sets `images.repository` to your ECR registry.
- [ ] CD verifies images exist in ECR prior to deployment.
- [ ] Post-deploy rollout checks succeed (frontend, productcatalogservice, cartservice).
- [ ] Evidence screenshots: CI success, CD success, `kubectl get pods -n online-boutique`, `helm history`.

---
Maintained by DevOps.
