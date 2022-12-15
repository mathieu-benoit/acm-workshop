---
title: "Create IP address"
weight: 1
description: "Duration: 5 min | Persona: Platform Admin"
tags: ["kcc", "platform-admin"]
---
![Platform Admin](/images/platform-admin.png)
_{{< param description >}}_

In this section, you will create a public IP address in order to expose all your applications in your Service Mesh thanks to an Ingress Gateway you will configure.

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
echo "export INGRESS_GATEWAY_PUBLIC_IP_NAME=${GKE_NAME}-asm-ingressgateway" >> ${WORK_DIR}acm-workshop-variables.sh
source ${WORK_DIR}acm-workshop-variables.sh
```

## Define IP address

Define the Ingress Gateway's [public static IP address](https://cloud.google.com/config-connector/docs/reference/resource-docs/compute/computeaddress) resource:
```Bash
cat <<EOF > ${WORK_DIR}$TENANT_PROJECT_DIR_NAME/public-ip-address.yaml
apiVersion: compute.cnrm.cloud.google.com/v1beta1
kind: ComputeAddress
metadata:
  annotations:
    cnrm.cloud.google.com/project-id: ${TENANT_PROJECT_ID}
  name: ${INGRESS_GATEWAY_PUBLIC_IP_NAME}
  namespace: ${TENANT_PROJECT_ID}
spec:
  location: global
EOF
```

## Deploy Kubernetes manifests

```Bash
cd ${WORK_DIR}$TENANT_PROJECT_DIR_NAME/
git add . && git commit -m "Ingress Gateway's public static IP address" && git push origin main
```

## Check deployments

{{< mermaid >}}
graph TD;
  ComputeAddress-.->Project
{{< /mermaid >}}

List the Kubernetes resources managed by Config Sync in **Config Controller** for the **Tenant project configs** repository:
```Bash
gcloud alpha anthos config sync repo describe \
    --project $HOST_PROJECT_ID \
    --managed-resources all \
    --sync-name repo-sync \
    --sync-namespace $TENANT_PROJECT_ID
```
Wait and re-run this command above until you see `"status": "SYNCED"`. All the `managed_resources` listed should have `STATUS: Current` as well.

List the GitHub runs for the **Tenant project configs** repository:
```Bash
cd ${WORK_DIR}$TENANT_PROJECT_DIR_NAME && gh run list
```

List the Google Cloud resources created:
```Bash
gcloud compute addresses list \
    --project $TENANT_PROJECT_ID \
    | grep ${INGRESS_GATEWAY_PUBLIC_IP_NAME}
```
Wait and re-run this command above until you see the resources created.

## Get the provisioned IP address

```Bash
INGRESS_GATEWAY_PUBLIC_IP=$(gcloud compute addresses describe $INGRESS_GATEWAY_PUBLIC_IP_NAME --global --project ${TENANT_PROJECT_ID} --format "value(address)")
echo ${INGRESS_GATEWAY_PUBLIC_IP}
echo "export INGRESS_GATEWAY_PUBLIC_IP=${INGRESS_GATEWAY_PUBLIC_IP}" >> ${WORK_DIR}acm-workshop-variables.sh
```