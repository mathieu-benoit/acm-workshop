---
title: "Configure Config Sync Monitoring"
weight: 5
description: "Duration: 5 min | Persona: Platform Admin"
---
_{{< param description >}}_

Define variables:
```Bash
source ~/acm-workshop-variables.sh
```

## Define Config Sync Monitoring

https://cloud.google.com/anthos-config-management/docs/how-to/monitoring-multi-repo

```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/config-sync-monitoring.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: default
  namespace: config-management-monitoring
  annotations:
    iam.gke.io/gcp-service-account: $GKE_SA@$GKE_PROJECT_ID.iam.gserviceaccount.com
EOF
```

## Deploy Kubernetes manifests

```Bash
cd ~/$GKE_CONFIGS_DIR_NAME/
git add .
git commit -m "Config Sync monitoring"
git push
```

## Check deployments

List the GitHub runs for the **GKE cluster configs** repository `cd ~/$GKE_CONFIGS_DIR_NAME && gh run list`:
```Plaintext
STATUS  NAME                    WORKFLOW  BRANCH  EVENT  ID          ELAPSED  AGE
✓       Config Sync monitoring  ci        main    push   1971296656  1m9s     16m
✓       Initial commit          ci        main    push   1970951731  57s      1h
```

List the Kubernetes resources managed by Config Sync in the **GKE cluster**:
```Bash
gcloud alpha anthos config sync repo describe \
    --project $GKE_PROJECT_ID \
    --managed-resources all \
    --format="multi(statuses:format=none,managed_resources:format='table[box](group:sort=2,kind,name,namespace:sort=1)')"
```
```Plaintext
getting 1 RepoSync and RootSync from gke-hub-membership
┌───────┬────────────────┬──────────────────────────────┬──────────────────────────────┐
│ GROUP │      KIND      │             NAME             │          NAMESPACE           │
├───────┼────────────────┼──────────────────────────────┼──────────────────────────────┤
│       │ Namespace      │ config-management-monitoring │                              │
│       │ ServiceAccount │ default                      │ config-management-monitoring │
└───────┴────────────────┴──────────────────────────────┴──────────────────────────────┘
```