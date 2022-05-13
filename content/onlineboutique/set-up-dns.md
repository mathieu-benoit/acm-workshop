---
title: "Set up DNS"
weight: 4
description: "Duration: 5 min | Persona: Platform Admin"
---
![Platform Admin](/images/platform-admin.png)
_{{< param description >}}_

In this section, you will provision a Cloud Endpoints DNS for your Online Boutique app. With this DNS you will configure an associated `ManagedCertificate` for the `Ingress`.

Initialize variables:
```Bash
source ${WORK_DIR}acm-workshop-variables.sh
echo "export INGRESS_GATEWAY_PUBLIC_IP=34.110.242.88" >> ${WORK_DIR}acm-workshop-variables.sh
echo "export INGRESS_GATEWAY_NAMESPACE=asm-ingress" >> ${WORK_DIR}acm-workshop-variables.sh
echo "export ONLINE_BOUTIQUE_INGRESS_GATEWAY_HOST_NAME='${ONLINEBOUTIQUE_NAMESPACE}.endpoints.${GKE_PROJECT_ID}.cloud.goog'" >> ${WORK_DIR}acm-workshop-variables.sh
source ${WORK_DIR}acm-workshop-variables.sh
```

## Create FQDN

Create an FQDN with Cloud Ednpoints for Online Boutique:
```Bash
cat <<EOF > ~/dns-spec.yaml
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
gcloud endpoints services deploy ~/dns-spec.yaml \
    --project ${GKE_PROJECT_ID}
rm ~/dns-spec.yaml
```

## Define ManagedCertificate resource

Define the `ManagedCertificate` for Online Boutique in the Ingress Gateway namespace:
```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/$INGRESS_GATEWAY_NAMESPACE/managedcertificate-${ONLINEBOUTIQUE_NAMESPACE}.yaml
apiVersion: networking.gke.io/v1
kind: ManagedCertificate
metadata:
  name: ${ONLINEBOUTIQUE_NAMESPACE}
  namespace: ${INGRESS_GATEWAY_NAMESPACE}
spec:
  domains:
    - "${ONLINE_BOUTIQUE_INGRESS_GATEWAY_HOST_NAME}"
EOF
```

## Update Ingress

Configure Online Boutique `ManagedCertificate` on the Ingress Gateway's `Ingress` resource:
```Bash
cd ~/$GKE_CONFIGS_DIR_NAME/config-sync/$INGRESS_GATEWAY_NAMESPACE
kpt fn eval . \
    -i set-annotations:v0.1 \
    --match-kind Ingress \
    -- networking.gke.io/managed-certificates=ob-team1,ob-team2,ob-team3
```
{{% notice note %}}
The annotation `networking.gke.io/managed-certificates` has 3 values.
{{% /notice %}}

## Deploy Kubernetes manifests

```Bash
cd ~/$GKE_CONFIGS_DIR_NAME/
git add .
git commit -m "ManagedCertificate for ${ONLINEBOUTIQUE_NAMESPACE}"
git push origin main
```

## Check deployments

List the GCP resources created:
```Bash
gcloud endpoints services list \
    --project $GKE_PROJECT_ID \
    | grep $ONLINEBOUTIQUE_NAMESPACE
gcloud compute ssl-certificates list \
    --project $GKE_PROJECT_ID \
    | grep $ONLINEBOUTIQUE_NAMESPACE
```
```Plaintext
ob-team1.endpoints.acm-workshop-464-gke.cloud.goog
ob-team1.endpoints.acm-workshop-464-gke.cloud.goog: PROVISIONING
```
{{% notice note %}}
This usually takes about 30 minutes for the `ManagedCertificate` to be provisioned. You can continue with the rest of the lab while it's provisioning.
{{% /notice %}}

List the GitHub runs for the **GKE cluster configs** repository `cd ~/$GKE_CONFIGS_DIR_NAME && gh run list | grep $ONLINEBOUTIQUE_NAMESPACE`:
```Plaintext
completed       success ManagedCertificate for ob-team1     ci      main    push    2317091323      1m11s   2m
```

List the Kubernetes resources managed by Config Sync in the **GKE cluster** for the **GKE cluster configs** repository:
```Bash
gcloud alpha anthos config sync repo describe \
    --project $GKE_PROJECT_ID \
    --managed-resources all \
    --sync-name root-sync \
    --sync-namespace config-management-system
```
```Plaintext
getting 1 RepoSync and RootSync from projects/acm-workshop-464-gke/locations/global/memberships/gke-hub-membership
│                           │ Namespace                 │ ob-team1                            │                              │ Current │
│ networking.gke.io         │ ManagedCertificate        │ ob-team1                            │ asm-ingress                  │ Current │
│ configsync.gke.io         │ RepoSync                  │ repo-sync                           │ ob-team1                     │ Current │
│ rbac.authorization.k8s.io │ RoleBinding               │ repo-sync                           │ ob-team1                     │ Current │
```