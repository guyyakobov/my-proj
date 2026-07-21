add trivy to docker build job
add dedicated sonarcube job

and helm-lint job and workflow
and helm-sync job with matrix that syncs all differnet services in one pipeline.

pr open: sonarcube - (lint|unit) - build - trivy - preview-env 
pr close+merge - tag image-dev #argocd auto-sync  - tag image-staging - argocd sync job - tag image-prod - argocd sync job  that requires approval