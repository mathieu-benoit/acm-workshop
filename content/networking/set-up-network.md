---
title: "Set up Network"
weight: 1
---
- Persona: Platform Admin
- Duration: 15 min
- Objectives:
  - FIXME

```Bash
GKE_LOCATION=us-east4
cat <<EOF > ~/$GKE_PROJECT_DIR_NAME/config-sync/vpc.yaml
apiVersion: compute.cnrm.cloud.google.com/v1beta1
kind: ComputeNetwork
metadata:
  name: gke
  namespace: ${GKE_PROJECT_ID}
spec:
  routingMode: REGIONAL
  autoCreateSubnetworks: false
EOF
```

```Bash
cat <<EOF > ~/$GKE_PROJECT_DIR_NAME/config-sync/subnet.yaml
apiVersion: compute.cnrm.cloud.google.com/v1beta1
kind: ComputeSubnetwork
metadata:
  name: gke
  namespace: ${GKE_PROJECT_ID}
spec:
  ipCidrRange: 10.2.0.0/20
  region: ${GKE_LOCATION}
  networkRef:
    name: gke
  secondaryIpRange:
  - rangeName: servicesrange
    ipCidrRange: 10.3.0.0/20
  - rangeName: clusterrange
    ipCidrRange: 10.4.0.0/20
EOF
```

```Bash
cat <<EOF > ~/$GKE_PROJECT_DIR_NAME/config-sync/router.yaml
apiVersion: compute.cnrm.cloud.google.com/v1beta1
kind: ComputeRouter
metadata:
  name: gke
  namespace: ${GKE_PROJECT_ID}
spec:
  networkRef:
    name: gke
  region: ${GKE_LOCATION}
EOF
```

```Bash
cat <<EOF > ~/$GKE_PROJECT_DIR_NAME/config-sync/router-nat.yaml
apiVersion: compute.cnrm.cloud.google.com/v1beta1
kind: ComputeRouterNAT
metadata:
  name: gke
  namespace: ${GKE_PROJECT_ID}
spec:
  natIpAllocateOption: AUTO_ONLY
  region: ${GKE_LOCATION}
  routerRef:
    name: gke
  sourceSubnetworkIpRangesToNat: LIST_OF_SUBNETWORKS
  subnetwork:
  - subnetworkRef:
      name: gke
    sourceIpRangesToNat:
    - ALL_IP_RANGES
EOF
```

{{< tabs groupId="commit">}}
{{% tab name="git commit" %}}
Let's deploy them via a GitOps approach:
```Bash
cd ~/$GKE_PROJECT_DIR_NAME/
git add .
git commit -m "Setting up network for ${GKE_PROJECT_ID}."
git push
```
{{% /tab %}}
{{% tab name="kubectl apply" %}}
Alternatively, you could directly apply them via the Config Controller's Kubernetes Server API:
```Bash
cd ~/$GKE_PROJECT_DIR_NAME/
kubectl apply -f .
```
{{% /tab %}}
{{< /tabs >}}