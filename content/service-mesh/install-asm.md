---
title: "Install ASM"
weight: 2
---
- Persona: Platform Admin
- Duration: 10 min
- Objectives:
  - FIXME

## Enable the GKE ASM feature

Define the GKE Hub ASM feature resource:
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
_Note: The `resourceID` must be `servicemesh` if you want to use Managed Control Plane feature of Anthos Service Mesh._

Let's deploy the GKE Hub ASM feature resource via a GitOps approach:
```Bash
cd ~/$GKE_PROJECT_DIR_NAME/
git add .
git commit -m "Enable ASM MCP for project ${GKE_PROJECT_ID}."
git push
```

Check that the ASM MCP is successfuly installed with `state: ACTIVE`:
```Bash
gcloud container hub mesh describe --project ${GKE_PROJECT_ID}
```

## Install ASM MCP

Initialize variables:
```Bash
export ASM_CHANNEL=rapid # or regular or stable
export ASM_LABEL=asm-managed
export ASM_VERSION=$ASM_LABEL
if [ $ASM_CHANNEL = "rapid" ] || [ $ASM_CHANNEL = "stable" ] ; then ASM_VERSION=$ASM_LABEL-$ASM_CHANNEL; fi
```

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

Define optional Mesh configs (`distroless` container image for the proxy and Cloud Tracing):
```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/istio-system/mesh-configs.yaml
apiVersion: v1
data:
  mesh: |-
    enableTracing: true
    defaultConfig:
      image:
        imageType: distroless
      tracing:
        stackdriver:{}
kind: ConfigMap
metadata:
  name: istio-${ASM_VERSION}
  namespace: istio-system
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
spec:
  type: managed_service
  channel: "${ASM_CHANNEL}"
EOF
```

Let's deploy them via a GitOps approach by commiting them in the GKE configs repository:
```Bash
cd ~/$GKE_CONFIGS_DIR_NAME/
git add .
git commit -m "Install ASM in GKE cluster."
git push
```