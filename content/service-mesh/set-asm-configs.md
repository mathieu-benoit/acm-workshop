---
title: "Set ASM configs"
weight: 3
---
- Persona: Platform Admin
- Duration: 10 min
- Objectives:
  - FIXME

## Set ASM configs Mesh-wide

Define the optional Mesh configs (`distroless` container image for the proxy and Cloud Tracing):
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

Deploy this Kubernetes manifest via a GitOps approach:
```Bash
cd ~/$GKE_CONFIGS_DIR_NAME/
git add .
git commit -m "ASM configs in GKE cluster"
git push
```

## Set mTLS STRICT Mesh-wide

Define the mTLS `STRICT` policy Mesh-wide:
```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/istio-system/mesh-mtls.yaml
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: istio-system
spec:
  mtls:
    mode: STRICT
EOF
```

Deploy this Kubernetes manifest via a GitOps approach:
```Bash
cd ~/$GKE_CONFIGS_DIR_NAME/
git add .
git commit -m "mTLS STRICT in GKE cluster"
git push
```