---
title: "Set up Config Sync Monitoring"
weight: 6
description: "Duration: 5 min | Persona: Platform Admin"
tags: ["platform-admin"]
---
![Platform Admin](/images/platform-admin.png)
_{{< param description >}}_

Define variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
```

## Define Config Sync Monitoring

https://cloud.google.com/anthos-config-management/docs/how-to/monitoring-multi-repo

```Bash
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/config-sync-monitoring.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: default
  namespace: config-management-monitoring
  annotations:
    iam.gke.io/gcp-service-account: $GKE_SA@$TENANT_PROJECT_ID.iam.gserviceaccount.com
EOF
```

## Deploy Kubernetes manifests

```Bash
cd ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/
git add . && git commit -m "Config Sync monitoring" && git push origin main
```

## Check deployments

List the Kubernetes resources managed by Config Sync in **GKE cluster** for the **GKE cluster configs** repository:
```Bash
gcloud alpha anthos config sync repo describe \
    --project $TENANT_PROJECT_ID \
    --managed-resources all \
    --sync-name root-sync \
    --sync-namespace config-management-system
```
Wait and re-run this command above until you see `"status": "SYNCED"` for this `RepoSync`. All the `managed_resources` listed should have `STATUS: Current` as well.

List the GitHub runs for the **GKE cluster configs** repository:
```Bash
cd ${WORK_DIR}$GKE_CONFIGS_DIR_NAME && gh run list
```