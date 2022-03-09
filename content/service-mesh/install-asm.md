---
title: "Install ASM"
weight: 2
---
- Persona: Platform Admin
- Duration: 10 min

Initialize variables:
```Bash
echo "export ASM_CHANNEL=rapid" >> ~/acm-workshop-variables.sh
echo "export ASM_LABEL=asm-managed" >> ~/acm-workshop-variables.sh
ASM_VERSION=$ASM_LABEL
if [ $ASM_CHANNEL = "rapid" ] || [ $ASM_CHANNEL = "stable" ] ; then ASM_VERSION=$ASM_LABEL-$ASM_CHANNEL; fi
echo "export ASM_VERSION=${ASM_VERSION}" >> ~/acm-workshop-variables.sh
source ~/acm-workshop-variables.sh
```
{{% notice note %}}
The possible values for `ASM_CHANNEL` are `regular`, `stable` or `rapid`.
{{% /notice %}}

## Define GKE ASM feature

Define the ASM [`GKEHubFeature`](https://cloud.google.com/config-connector/docs/reference/resource-docs/gkehub/gkehubfeature) resource:
```Bash
cat <<EOF > ~/$GKE_PROJECT_DIR_NAME/config-sync/gke-hub-feature-asm.yaml
apiVersion: gkehub.cnrm.cloud.google.com/v1beta1
kind: GKEHubFeature
metadata:
  name: ${GKE_NAME}-asm
  namespace: ${GKE_PROJECT_ID}
spec:
  projectRef:
    external: ${GKE_PROJECT_ID}
  location: global
  resourceID: servicemesh
EOF
```
{{% notice note %}}
The `resourceID` must be `servicemesh` if you want to use Managed Control Plane feature of Anthos Service Mesh.
{{% /notice %}}

## Deploy Kubernetes manifests

```Bash
cd ~/$GKE_PROJECT_DIR_NAME/
git add .
git commit -m "ASM MCP for GKE project"
git push
```

Check that the ASM MCP is successfuly installed with `resourceState.state: ACTIVE` and `membershipStates[].state.code: OK`:
```Bash
gcloud container hub mesh describe --project ${GKE_PROJECT_ID} --format="value(resourceState.state)"
gcloud container hub mesh describe --project ${GKE_PROJECT_ID} --format="value(membershipStates[].state.code)"
```

## Define ASM ControlPlaneRevision

Create a dedicated `istio-system` folder in the GKE configs's Git repo:
```Bash
mkdir ~/$GKE_CONFIGS_DIR_NAME/config-sync/istio-system
```

Define the `istio-system` namespace:
```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/istio-system/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: istio-system
EOF
```

Define ASM Managed Control Plane configs:
```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/istio-system/control-plane-configs.yaml
apiVersion: mesh.cloud.google.com/v1beta1
kind: ControlPlaneRevision
metadata:
  name: "${ASM_VERSION}"
  namespace: istio-system
  labels:
    mesh.cloud.google.com/managed-cni-enabled: "true"
spec:
  type: managed_service
  channel: "${ASM_CHANNEL}"
EOF
```
{{% notice tip %}}
We are using `mesh.cloud.google.com/managed-cni-enabled: "true"` in order to leverage the Istio CNI has a best practice for security and performance perspectives. It's also mandatory when using the Managed Data Plane feature of ASM.
{{% /notice %}}

## Deploy Kubernetes manifests

```Bash
cd ~/$GKE_CONFIGS_DIR_NAME/
git add .
git commit -m "ASM MCP for GKE cluster"
git push
```

Check that the ASM MCP is successfuly installed with `resourceState.state: ACTIVE` and `membershipStates[].state.code: OK`:
```Bash
gcloud container hub mesh describe --project ${GKE_PROJECT_ID} --format="value(resourceState.state)"
gcloud container hub mesh describe --project ${GKE_PROJECT_ID} --format="value(membershipStates[].state.code)"
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