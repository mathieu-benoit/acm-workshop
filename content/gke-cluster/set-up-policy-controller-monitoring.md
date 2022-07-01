---
title: "Set up Policy Controller Monitoring"
weight: 6
description: "Duration: 5 min | Persona: Platform Admin"
tags: ["platform-admin"]
---
![Platform Admin](/images/platform-admin.png)
_{{< param description >}}_

In this section, you will finalize the setup for the Policy Controller's monitoring.

Define variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
```

## Define Policy Controller Monitoring

https://cloud.google.com/anthos-config-management/docs/how-to/monitoring-policy-controller#monitor_with

```Bash
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/policy-controller-monitoring-sa.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: gatekeeper-admin
  namespace: gatekeeper-system
  annotations:
    iam.gke.io/gcp-service-account: $GKE_SA@$TENANT_PROJECT_ID.iam.gserviceaccount.com
EOF
```

## Deploy Kubernetes manifests

```Bash
cd ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/
git add . && git commit -m "Policy Controller monitoring" && git push origin main
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

## Create a sample Policy Controller dashboard

Create a Policy Controller dashboard based on a predefined template:
```Bash
curl -o ${WORK_DIR}PolicyController-Dashboard.json https://raw.githubusercontent.com/GoogleCloudPlatform/monitoring-dashboard-samples/master/dashboards/anthos-config-management/ACM-PolicyController.json
gcloud monitoring dashboards create \
    --config-from-file=${WORK_DIR}PolicyController-Dashboard.json \
    --project ${TENANT_PROJECT_ID}
```

Navigate to the list of your Cloud Monitoring dashboards. Click on the link displayed by the command below:
```Bash
echo -e "https://console.cloud.google.com/monitoring/dashboards?project=${TENANT_PROJECT_ID}"
```

Open the **Policy Controller** dashboard just created. 

You won't have yet any data as we haven't yet synchronized any resources yet in the GKE cluster. You could come back to this dashboard as we are moving forward with this workshop.