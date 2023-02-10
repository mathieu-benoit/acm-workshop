---
title: "Set up Monitoring"
weight: 5
description: "Duration: 5 min | Persona: Platform Admin"
tags: ["kcc", "monitoring", "platform-admin"]
---
![Platform Admin](https://github.com/mathieu-benoit/my-images/raw/main/acm-workshop/platform-admin.png)
_{{< param description >}}_

In this section, you will set up an monitoring notification channel with you email and a generic alert policy on URLs uptime checks for the Tenant project.

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
```

Define variables for this page:
```Bash
export NOTIFICATION_CHANNEL_EMAIL_ADDRESS=FIXME
export NOTIFICATION_CHANNEL_NAME=monitoringnotificationchannel-email
```
{{% notice tip %}}
Set your own email address for the `NOTIFICATION_CHANNEL_EMAIL_ADDRESS` variable, this will be used when defining the monitoring notification channel below.
{{% /notice %}}

## Define the monitoring notification channel with your email

Define the [VPC](https://cloud.google.com/config-connector/docs/reference/resource-docs/monitoring/monitoringnotificationchannel):
```Bash
cat <<EOF > ${WORK_DIR}$TENANT_PROJECT_DIR_NAME/monitoring-notification-channel-email.yaml
apiVersion: monitoring.cnrm.cloud.google.com/v1beta1
kind: MonitoringNotificationChannel
metadata:
  annotations:
    cnrm.cloud.google.com/project-id: ${TENANT_PROJECT_ID}
  name: ${NOTIFICATION_CHANNEL_NAME}
spec:
  type: email
  labels:
    email_address: ${NOTIFICATION_CHANNEL_EMAIL_ADDRESS}
  enabled: true
EOF
```

## Define the Alert policy based on the uptime checks

Define the [MonitoringAlertPolicy](https://cloud.google.com/config-connector/docs/reference/resource-docs/monitoring/monitoringalertpolicy):
```Bash
cat <<EOF > ${WORK_DIR}$TENANT_PROJECT_DIR_NAME/monitoring-alert-policy-uptime-checks.yaml
apiVersion: monitoring.cnrm.cloud.google.com/v1beta1
kind: MonitoringAlertPolicy
metadata:
  annotations:
    cnrm.cloud.google.com/project-id: ${TENANT_PROJECT_ID}
  name: monitoring-alert-policy-uptime-checks
spec:
  displayName: Failure of uptime checks
  enabled: true
  notificationChannels:
    - name: ${NOTIFICATION_CHANNEL_NAME}
  combiner: OR
  conditions:
  - displayName: Failure of uptime checks
    conditionThreshold:
      filter: metric.type="monitoring.googleapis.com/uptime_check/check_passed" AND resource.type="uptime_url"
      aggregations:
      - perSeriesAligner: ALIGN_NEXT_OLDER
        alignmentPeriod: 1200s
        crossSeriesReducer: REDUCE_COUNT_FALSE
        groupByFields:
        - resource.label.*
      comparison: COMPARISON_GT
      thresholdValue: 1
      duration: 60s
      trigger:
        count: 1
EOF
```

## Deploy Kubernetes manifests

```Bash
cd ${WORK_DIR}$TENANT_PROJECT_DIR_NAME/
git add . && git commit -m "Monitoring features for Tenant project" && git push origin main
```

## Check deployments

{{< mermaid >}}
graph TD;
  MonitoringAlertPolicy-.->Project
  MonitoringNotificationChannel-.->Project
  MonitoringAlertPolicy-->MonitoringNotificationChannel
{{< /mermaid >}}

List the Kubernetes resources managed by Config Sync in **Config Controller** for the **Tenant project configs** repository:
{{< tabs groupId="cs-status-ui">}}
{{% tab name="UI" %}}
Run this command and click on this link:
```Bash
echo -e "https://console.cloud.google.com/kubernetes/config_management/packages?project=${HOST_PROJECT_ID}"
```
Wait until you see the `Sync status` column as `Synced` and the `Reconcile status` column as `Current`.
{{% /tab %}}
{{% tab name="gcloud" %}}
Run this command:
```Bash
gcloud alpha anthos config sync repo describe \
    --project $HOST_PROJECT_ID \
    --managed-resources all \
    --sync-name repo-sync \
    --sync-namespace $TENANT_PROJECT_ID
```
Wait and re-run this command above until you see `"status": "SYNCED"`. All the `managed_resources` listed should have `STATUS: Current` too.
{{% /tab %}}
{{< /tabs >}}

List the GitHub runs for the **Tenant project configs** repository:
```Bash
cd ${WORK_DIR}$TENANT_PROJECT_DIR_NAME && gh run list
```