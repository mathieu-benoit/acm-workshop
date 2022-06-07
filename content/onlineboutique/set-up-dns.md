---
title: "Set up DNS"
weight: 1
description: "Duration: 5 min | Persona: Platform Admin"
tags: ["platform-admin"]
---
![Platform Admin](/images/platform-admin.png)
_{{< param description >}}_

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
echo "export ONLINE_BOUTIQUE_INGRESS_GATEWAY_HOST_NAME='onlineboutique.endpoints.${TENANT_PROJECT_ID}.cloud.goog'" >> ${WORK_DIR}acm-workshop-variables.sh
source ${WORK_DIR}acm-workshop-variables.sh
```

## Create FQDN

Create an FQDN with Cloud Endpoints for Online Boutique:
```Bash
cat <<EOF > ${WORK_DIR}dns-spec.yaml
swagger: "2.0"
info:
  description: "Online Boutique Cloud Endpoints DNS"
  title: "Online Boutique Cloud Endpoints DNS"
  version: "1.0.0"
paths: {}
host: "${ONLINE_BOUTIQUE_INGRESS_GATEWAY_HOST_NAME}"
x-google-endpoints:
- name: "${ONLINE_BOUTIQUE_INGRESS_GATEWAY_HOST_NAME}"
  target: "${INGRESS_GATEWAY_PUBLIC_IP}"
EOF
gcloud endpoints services deploy ${WORK_DIR}dns-spec.yaml \
    --project ${TENANT_PROJECT_ID}
rm ${WORK_DIR}dns-spec.yaml
```

## Define ManagedCertificate resource

Define the `ManagedCertificate` for Online Boutique in the Ingress Gateway namespace:
```Bash
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/$INGRESS_GATEWAY_NAMESPACE/managedcertificate-onlineboutique.yaml
apiVersion: networking.gke.io/v1
kind: ManagedCertificate
metadata:
  name: onlineboutique
  namespace: ${INGRESS_GATEWAY_NAMESPACE}
spec:
  domains:
    - "${ONLINE_BOUTIQUE_INGRESS_GATEWAY_HOST_NAME}"
EOF
```

## Update Ingress

Configure Online Boutique `ManagedCertificate` on the Ingress Gateway's `Ingress` resource:
```Bash
cd ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/$INGRESS_GATEWAY_NAMESPACE
kpt fn eval . \
    -i set-annotations:v0.1 \
    --match-kind Ingress \
    -- networking.gke.io/managed-certificates=whereami,onlineboutique
```
{{% notice note %}}
The `networking.gke.io/managed-certificates` annotation has 2 values, `whereami` configured previously and the new `onlineboutique` we are configuring with this page. Very important to keep both here.
{{% /notice %}}

## Deploy Kubernetes manifests

```Bash
cd ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/
git add . && git commit -m "Online Boutique ManagedCertificate" && git push origin main
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

List the Google Cloud resources created:
```Bash
gcloud endpoints services list \
    --project $TENANT_PROJECT_ID
gcloud compute ssl-certificates list \
    --project $TENANT_PROJECT_ID
```
{{% notice note %}}
Wait for the `ManagedCertificate` to be provisioned. This usually takes about 30 minutes.
{{% /notice %}}