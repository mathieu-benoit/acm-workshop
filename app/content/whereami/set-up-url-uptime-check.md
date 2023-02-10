---
title: "Set up URL uptime check"
weight: 2
description: "Duration: 10 min | Persona: Platform Admin"
tags: ["kcc", "monitoring", "platform-admin"]
---
![Platform Admin](https://github.com/mathieu-benoit/my-images/raw/main/acm-workshop/platform-admin.png)
_{{< param description >}}_

In this section, you will set up an uptime check on the Whereami URL.

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
```

```Bash
mkdir ${WORK_DIR}$TENANT_PROJECT_DIR_NAME/$WHEREAMI_NAMESPACE
```

## Define Uptime check config

Define the [MonitoringUptimeCheckConfig](https://cloud.google.com/config-connector/docs/reference/resource-docs/monitoring/monitoringuptimecheckconfig):
```Bash
cat <<EOF > ${WORK_DIR}$TENANT_PROJECT_DIR_NAME/$WHEREAMI_NAMESPACE/uptime-check-config.yaml
apiVersion: monitoring.cnrm.cloud.google.com/v1beta1
kind: MonitoringUptimeCheckConfig
metadata:
  name: uptimecheckconfig-${WHEREAMI_NAMESPACE}
spec:
  projectRef:
    name: ${TENANT_PROJECT_ID}
  displayName: ${WHEREAMI_NAMESPACE}
  period: 900s
  timeout: 5s
  monitoredResource:
    type: "uptime_url"
    filterLabels:
      host: ${WHERE_AMI_INGRESS_GATEWAY_HOST_NAME}
      project_id: ${TENANT_PROJECT_ID}
  httpCheck:
    port: 443
    requestMethod: GET
    useSsl: true
    validateSsl: true
EOF
```

## Deploy Kubernetes manifests

```Bash
cd ${WORK_DIR}$TENANT_PROJECT_DIR_NAME/
git add . && git commit -m "URL uptime check for Whereami" && git push origin main
```

## Check deployments

{{< mermaid >}}
graph TD;
  MonitoringUptimeCheckConfig-.->Project
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