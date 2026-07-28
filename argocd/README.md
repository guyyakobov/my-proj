# Argo CD deployment layout

This directory contains the Argo CD bootstrap application and three
`ApplicationSet` examples. The ApplicationSets discover Helm charts and
generate Argo CD `Application` resources for either:

- a shared cluster that hosts `dev`, `staging`, and `prod`; or
- multiple production clusters selected by region.

## Shared-cluster versions at a glance

The two shared-cluster ApplicationSets solve the same problem with different
priorities:

| | V1: explicit | V2: accurate |
| --- | --- | --- |
| How it works | Every chart × an explicit `dev`, `staging`, `prod` list | One Application per `values-<environment>.yaml` file |
| Main advantage | Simple and self-explanatory generator | Generates only the environments intended for each chart |
| Main disadvantage | May try to deploy a chart to staging or prod without environment-specific values | Environment discovery via the generator and Go templates are less explicit |
| Best fit | Every chart should run in all three environments | Each chart may target a different set of environments |

V1 optimizes for **explicitness**: the git folder generator is the more obvious use case, rather than extracting the application to deploy by the presence of a values file.

V2 optimizes for **deployment accuracy**: the presence of a values file is the
deployment declaration. If a chart has only `values-dev.yaml`, it is generated
only for dev.

The ApplicationSets expect Helm charts in:

```text
helm/charts/<service>/
├── Chart.yaml
├── values.yaml
├── values-dev.yaml
├── values-staging.yaml
├── values-prod.yaml
└── templates/
```

## Prod-only multi-region

`appset-prod-multi-region.yaml` deploys production applications across
registered Argo CD prod clusters. It combines:

- every chart containing `helm/charts/<service>/values-prod.yaml`; and
- every cluster labeled `environment=prod` with a `region` label.

For a service named `api` and clusters in `eu-west-1` and `us-east-1`, it
creates:

```text
api-prod-eu-west-1
api-prod-us-east-1
```

The chart can contain production and optional region-specific values:

```text
helm/charts/api/
├── values.yaml
├── values-prod.yaml
├── values-prod-eu-west-1.yaml  # optional override
└── values-prod-us-east-1.yaml  # optional override
```

Global values follow the same pattern:

```text
helm/global-values/
├── values.yaml
├── values-prod.yaml
├── values-prod-eu-west-1.yaml
└── values-prod-us-east-1.yaml
```

> **Important:** a region-specific values file is not required for deployment
> to that region. Because `ignoreMissingValueFiles: true` is enabled, every
> chart with `values-prod.yaml` is deployed to every selected prod cluster.
> A `values-prod-<region>.yaml` file only overrides values for that region.

## Sync behavior

- Shared cluster: dev syncs automatically; staging and prod are manual.
- Prod multi-region: all generated production Applications require manual sync.
- Deployment and StatefulSet replica differences are ignored.
- ApplicationSets create and update Applications without deleting them.
