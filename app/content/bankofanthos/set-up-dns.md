---
title: "Set up DNS"
weight: 1
description: "Duration: 5 min | Persona: Platform Admin"
tags: ["platform-admin"]
---
![Platform Admin](https://github.com/mathieu-benoit/my-images/raw/main/acm-workshop/platform-admin.png)
_{{< param description >}}_

In this section, you will set up a dedicated DNS with Cloud Endpoints you will use later for the Bank of Anthos app.

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
echo "export BANK_OF_ANTHOS_INGRESS_GATEWAY_HOST_NAME='bankofanthos.endpoints.${TENANT_PROJECT_ID}.cloud.goog'" >> ${WORK_DIR}acm-workshop-variables.sh
source ${WORK_DIR}acm-workshop-variables.sh
```

## Create FQDN

Create an FQDN with Cloud Endpoints for Bank of Anthos:
```Bash
cat <<EOF > ${WORK_DIR}dns-spec.yaml
swagger: "2.0"
info:
  description: "Bank of Anthos Cloud Endpoints DNS"
  title: "Bank of Anthos Cloud Endpoints DNS"
  version: "1.0.0"
paths: {}
host: "${BANK_OF_ANTHOS_INGRESS_GATEWAY_HOST_NAME}"
x-google-endpoints:
- name: "${BANK_OF_ANTHOS_INGRESS_GATEWAY_HOST_NAME}"
  target: "${INGRESS_GATEWAY_PUBLIC_IP}"
EOF
gcloud endpoints services deploy ${WORK_DIR}dns-spec.yaml \
    --project ${TENANT_PROJECT_ID}
rm ${WORK_DIR}dns-spec.yaml
```

## Define ManagedCertificate resource

Define the `ManagedCertificate` for Bank of Anthos in the Ingress Gateway namespace:
```Bash
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/$INGRESS_GATEWAY_NAMESPACE/managedcertificate-bankofanthos.yaml
apiVersion: networking.gke.io/v1
kind: ManagedCertificate
metadata:
  name: bankofanthos
  namespace: ${INGRESS_GATEWAY_NAMESPACE}
spec:
  domains:
    - "${BANK_OF_ANTHOS_INGRESS_GATEWAY_HOST_NAME}"
EOF
```

## Update Ingress

Configure Bank of Anthos `ManagedCertificate` on the Ingress Gateway's `Ingress` resource:
```Bash
cd ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/$INGRESS_GATEWAY_NAMESPACE
kpt fn eval . \
    -i set-annotations:v0.1 \
    --match-kind Ingress \
    -- networking.gke.io/managed-certificates=whereami,onlineboutique,bankofanthos
```
{{% notice note %}}
The `networking.gke.io/managed-certificates` annotation has 3 values, `whereami` and `onlineboutique` configured previously and the new `bankofanthos` we are configuring with this page. Very important to keep the three here.
{{% /notice %}}

## Deploy Kubernetes manifests

```Bash
cd ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/
git add . && git commit -m "Bank of Anthos ManagedCertificate" && git push origin main
```

## Check deployments

List the Kubernetes resources managed by Config Sync in **GKE cluster** for the **GKE cluster configs** repository:
{{< tabs groupId="cs-status-ui">}}
{{% tab name="UI" %}}
Run this command and click on this link:
```Bash
echo -e "https://console.cloud.google.com/kubernetes/config_management/packages?project=${TENANT_PROJECT_ID}"
```
Wait until you see the `Sync status` column as `Synced` and the `Reconcile status` column as `Current`.
{{% /tab %}}
{{% tab name="gcloud" %}}
Run this command:
```Bash
gcloud alpha anthos config sync repo describe \
    --project $TENANT_PROJECT_ID \
    --managed-resources all \
    --sync-name root-sync \
    --sync-namespace config-management-system
```
Wait and re-run this command above until you see `"status": "SYNCED"`.
{{% /tab %}}
{{< /tabs >}}

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