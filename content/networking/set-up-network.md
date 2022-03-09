---
title: "Set up Network"
weight: 1
---
- Persona: Platform Admin
- Duration: 15 min

Initialize variables:
```Bash
echo "export GKE_LOCATION=us-east4" >> ~/acm-workshop-variables.sh
echo "export GKE_NAME=gke" >> ~/acm-workshop-variables.sh
source ~/acm-workshop-variables.sh
```

## Define VPC and Subnet

```Bash
cat <<EOF > ~/$GKE_PROJECT_DIR_NAME/config-sync/vpc.yaml
apiVersion: compute.cnrm.cloud.google.com/v1beta1
kind: ComputeNetwork
metadata:
  name: ${GKE_NAME}
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
  name: ${GKE_NAME}
  namespace: ${GKE_PROJECT_ID}
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
cat <<EOF > ~/$GKE_PROJECT_DIR_NAME/config-sync/router.yaml
apiVersion: compute.cnrm.cloud.google.com/v1beta1
kind: ComputeRouter
metadata:
  name: ${GKE_NAME}
  namespace: ${GKE_PROJECT_ID}
spec:
  networkRef:
    name: ${GKE_NAME}
  region: ${GKE_LOCATION}
EOF
```

```Bash
cat <<EOF > ~/$GKE_PROJECT_DIR_NAME/config-sync/router-nat.yaml
apiVersion: compute.cnrm.cloud.google.com/v1beta1
kind: ComputeRouterNAT
metadata:
  name: ${GKE_NAME}
  namespace: ${GKE_PROJECT_ID}
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
cd ~/$GKE_PROJECT_DIR_NAME/
git add .
git commit -m "Network for GKE project"
git push
```

## Check deployments

Here is what you should have at this stage:

If you run:
```Bash
cd ~/$WORKSHOP_ORG_DIR_NAME && gh run list
```
You should see:
```Plaintext
FIXME
```

If you run:
```Bash
cd ~/$GKE_PROJECT_DIR_NAME && gh run list
```
You should see:
```Plaintext
FIXME
```

If you run:
```Bash
cd ~/$GKE_CONFIGS_DIR_NAME && gh run list
```
You should see:
```Plaintext
FIXME
```

If you run:
```Bash
gcloud alpha anthos config sync repo describe \
   --project $CONFIG_CONTROLLER_PROJECT_ID \
   --managed-resources all \
   --format="multi(statuses:format=none,managed_resources:format='table[box](group:sort=2,kind,name,namespace:sort=1)')"
```
You should see:
```Plaintext
FIXME
```

If you run:
```Bash
gcloud alpha anthos config sync repo describe \
   --project $GKE_PROJECT_ID \
   --managed-resources all \
   --format="multi(statuses:format=none,managed_resources:format='table[box](group:sort=2,kind,name,namespace:sort=1)')"
```
You should see:
```Plaintext
FIXME
```