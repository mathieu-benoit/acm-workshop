---
title: "Set up ASM configs"
weight: 3
description: "Duration: 5 min | Persona: Platform Admin"
---
Initialize variables:
```Bash
source ~/acm-workshop-variables.sh
```

## Define ASM configs Mesh-wide

Define the optional Mesh configs (`distroless` container image for the proxy):
```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/istio-system/mesh-configs.yaml
apiVersion: v1
data:
  mesh: |-
    defaultConfig:
      image:
        imageType: distroless
kind: ConfigMap
metadata:
  name: istio-${ASM_VERSION}
  namespace: istio-system
EOF
```

## Deploy Kubernetes manifests

```Bash
cd ~/$GKE_CONFIGS_DIR_NAME/
git add .
git commit -m "ASM configs in GKE cluster"
git push
```

## Define mTLS STRICT Mesh-wide

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

## Deploy Kubernetes manifests

```Bash
cd ~/$GKE_CONFIGS_DIR_NAME/
git add .
git commit -m "mTLS STRICT in GKE cluster"
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