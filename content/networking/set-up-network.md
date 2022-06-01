---
title: "Set up Network"
weight: 1
description: "Duration: 5 min | Persona: Platform Admin"
tags: ["kcc", "platform-admin"]
---
![Platform Admin](/images/platform-admin.png)
_{{< param description >}}_

Initialize variables:
```Bash
source ${WORK_DIR}acm-workshop-variables.sh
echo "export GKE_LOCATION=us-east4" >> ${WORK_DIR}acm-workshop-variables.sh
echo "export GKE_NAME=gke" >> ${WORK_DIR}acm-workshop-variables.sh
source ${WORK_DIR}acm-workshop-variables.sh
```

## Define VPC and Subnet

```Bash
cat <<EOF > ${WORK_DIR}$TENANT_PROJECT_DIR_NAME/vpc.yaml
apiVersion: compute.cnrm.cloud.google.com/v1beta1
kind: ComputeNetwork
metadata:
  name: ${GKE_NAME}
  namespace: ${TENANT_PROJECT_ID}
spec:
  routingMode: REGIONAL
  autoCreateSubnetworks: false
EOF
```

```Bash
cat <<EOF > ${WORK_DIR}$TENANT_PROJECT_DIR_NAME/subnet.yaml
apiVersion: compute.cnrm.cloud.google.com/v1beta1
kind: ComputeSubnetwork
metadata:
  name: ${GKE_NAME}
  namespace: ${TENANT_PROJECT_ID}
  annotations:
    config.kubernetes.io/depends-on: compute.cnrm.cloud.google.com/namespaces/${TENANT_PROJECT_ID}/ComputeNetwork/${GKE_NAME}
spec:
  ipCidrRange: 10.2.0.0/20
  region: ${GKE_LOCATION}
  networkRef:
    name: ${GKE_NAME}
  secondaryIpRange:
  - rangeName: servicesrange
    ipCidrRange: 10.3.0.0/20
  - rangeName: clusterrange
    ipCidrRange: 10.4.0.0/20
EOF
```

## Define Cloud NAT

```Bash
cat <<EOF > ${WORK_DIR}$TENANT_PROJECT_DIR_NAME/router.yaml
apiVersion: compute.cnrm.cloud.google.com/v1beta1
kind: ComputeRouter
metadata:
  name: ${GKE_NAME}
  namespace: ${TENANT_PROJECT_ID}
  annotations:
    config.kubernetes.io/depends-on: compute.cnrm.cloud.google.com/namespaces/${TENANT_PROJECT_ID}/ComputeNetwork/${GKE_NAME}
spec:
  networkRef:
    name: ${GKE_NAME}
  region: ${GKE_LOCATION}
EOF
```

```Bash
cat <<EOF > ${WORK_DIR}$TENANT_PROJECT_DIR_NAME/router-nat.yaml
apiVersion: compute.cnrm.cloud.google.com/v1beta1
kind: ComputeRouterNAT
metadata:
  name: ${GKE_NAME}
  namespace: ${TENANT_PROJECT_ID}
  annotations:
    config.kubernetes.io/depends-on: compute.cnrm.cloud.google.com/namespaces/${TENANT_PROJECT_ID}/ComputeSubnetwork/${GKE_NAME},compute.cnrm.cloud.google.com/namespaces/${TENANT_PROJECT_ID}/ComputeRouter/${GKE_NAME}
spec:
  natIpAllocateOption: AUTO_ONLY
  region: ${GKE_LOCATION}
  routerRef:
    name: ${GKE_NAME}
  sourceSubnetworkIpRangesToNat: LIST_OF_SUBNETWORKS
  subnetwork:
  - subnetworkRef:
      name: ${GKE_NAME}
    sourceIpRangesToNat:
    - ALL_IP_RANGES
EOF
```

## Deploy Kubernetes manifests

```Bash
cd ${WORK_DIR}$TENANT_PROJECT_DIR_NAME/
git add . && git commit -m "Network for Tenant project" && git push origin main
```

## Check deployments

{{< mermaid >}}
graph TD;
  ComputeNetwork-.->Project
  ComputeSubnetwork-->ComputeNetwork
  ComputeRouterNAT-->ComputeSubnetwork
  ComputeRouterNAT-->ComputeRouter
  ComputeRouter-->ComputeNetwork
{{< /mermaid >}}

List the Kubernetes resources managed by Config Sync in **Config Controller** for the **Tenant project configs** repository:
```Bash
gcloud alpha anthos config sync repo describe \
    --project $HOST_PROJECT_ID \
    --managed-resources all \
    --sync-name repo-sync \
    --sync-namespace $TENANT_PROJECT_ID
```
Wait and re-run this command above until you see `"status": "SYNCED"` for this `RepoSync`. All the `managed_resources` listed should have `STATUS: Current` as well.

List the GitHub runs for the **Tenant project configs** repository:
```Bash
cd ${WORK_DIR}$TENANT_PROJECT_DIR_NAME && gh run list
```

List the Google Cloud resources created:
```Bash
gcloud compute networks list \
    --project $TENANT_PROJECT_ID
gcloud compute networks subnets list \
    --project $TENANT_PROJECT_ID
gcloud compute routers list \
    --project $TENANT_PROJECT_ID
gcloud compute routers nats list \
    --router $GKE_NAME \
    --region $GKE_LOCATION \
    --project $TENANT_PROJECT_ID
```