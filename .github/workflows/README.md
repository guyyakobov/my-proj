## CI/CD Architecture

![CI/CD Architecture](../../diagrams/ci-cd.png)

This repository uses GitHub Actions to build, test, scan, deploy, and promote services across development, staging, and production environments. The workflows are split into reusable pipelines for Node services, Python services, and Helm chart validation.

## Workflow overview

### 1. Service workflows

The service entrypoints are:

- [reusable-workflow-node.yml](reusable-workflow-node.yml) for Node.js services
- [reusable-workflow-python.yml](reusable-workflow-python.yml) for Python services

Both workflows are reusable and are designed to run when a pull request is opened, synchronized, reopened, or closed. They perform the following stages:

1. Static analysis
   - SonarQube scan via [reusable-sonar.yml](reusable-sonar.yml)
2. Language-specific checks
   - Node lint and unit tests via [reusable-node.yml](reusable-node.yml)
   - Python lint and unit tests via [reusable-python.yml](reusable-python.yml)
3. Container build and security scan
   - Docker image build and push via [reusable-build.yml](reusable-build.yml)
   - Trivy image scan via [reusable-trivy.yml](reusable-trivy.yml)
4. Preview environments
   - Preview deployment and cleanup via [reusable-preview.yml](reusable-preview.yml)
5. Promotion and sync
   - Promote images to dev, staging, and prod via [reusable-promote.yml](reusable-promote.yml)
   - Sync Argo CD applications via [reusable-sync.yml](reusable-sync.yml)

### 2. Helm workflow

[workflow-helm.yml](workflow-helm.yml) handles Helm chart validation for changes under the Helm chart directory. It:

- detects changed chart files on pull requests
- builds a matrix of affected services and environments
- runs Helm linting and Kubernetes manifest validation with kubeconform
- triggers Argo CD sync after a merge to the main branch

## Typical CI/CD lifecycle

### Pull request lifecycle

When a pull request is opened or updated:

- code quality checks run
- tests execute for the affected service
- a container image is built and pushed to ECR
- a Trivy scan is executed
- a preview environment is deployed when preview mode is enabled

When the pull request is closed and merged:

- the image is promoted through the environment chain
- Helm values are updated for the target environment
- Argo CD sync is triggered for the corresponding application

## Required repository configuration

These workflows depend on repository variables and secrets being configured in GitHub Actions.

### Variables

- AWS_ROLE_ARN
- AWS_ECR_REGION
- ECR_REGISTRY
- AWS_REGION
- EKS_CLUSTER_NAME
- EKS_NAMESPACE
- HELM_VERSION
- KUBECTL_VERSION
- ARGOCD_SERVER
- ARGOCD_VERSION
- SONAR_HOST_URL

### Secrets

- ARGOCD_AUTH_TOKEN
- SONAR_TOKEN

## How to use a reusable workflow

A simple example is already provided in [workflow-example.yml](workflow-example.yml). It shows how to call the reusable Node workflow for a service:

```yaml
jobs:
  ci:
    uses: ./.github/workflows/reusable-workflow-node.yml
    with:
      service: example
      preview-strategy: isolated-dev
    secrets: inherit
```

The Node and Python entrypoints also accept optional inputs such as build arguments and preview strategy.

## Notes

- Preview deployment behavior is controlled by the preview-strategy input.
- Supported preview strategies are shared-dev, isolated-dev, and disabled.
- Helm validation is scoped to chart changes to keep PR feedback focused and fast.
- The pipeline is intended to evolve toward richer quality gates: integration tests can be added with Testcontainers before image building, and smoke and end-to-end tests can be run against the environments as release confidence checks.
- Rollback should be handled as an operational step by re-promoting a known-good image tag or reverting the relevant Helm values when a release needs to be undone.
- The promote jobs for staging and production are tied to GitHub environment protections, so approval is required before those promotions proceed to the next deployment stage.

