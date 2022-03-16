---
title: "Deploy Whereami app"
weight: 3
description: "Duration: 10 min | Persona: Apps Operator"
---
_{{< param description >}}_

Initialize variables:
```Bash
source ~/acm-workshop-variables.sh
```

## Get upstream Kubernetes manifests

Get the upstream Kubernetes manifests:
```Bash
cd ~/$WHERE_AMI_DIR_NAME
kpt pkg get https://github.com/GoogleCloudPlatform/kubernetes-engine-samples/whereami/k8s
mv k8s upstream
```

## Create base overlay

Create Kustomize base overlay files:
```Bash
mkdir ~/$WHERE_AMI_DIR_NAME/base
cd ~/$WHERE_AMI_DIR_NAME/base
kustomize create --resources ../upstream
cat <<EOF >> ~/$WHERE_AMI_DIR_NAME/base/kustomization.yaml
configMapGenerator:
- name: whereami-configmap
  behavior: merge
  literals:
  - TRACE_SAMPLING_RATIO="0"
patchesJson6902:
- target:
    kind: Service
    name: whereami
  patch: |-
    - op: replace
      path: /spec/type
      value: ClusterIP
EOF
```

## Define VirtualService

Define the `VirtualService` resource in order to establish the Ingress Gateway routing to the Whereami app:
```Bash
cat <<EOF > ~/$WHERE_AMI_DIR_NAME/base/virtualservice.yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: whereami
spec:
  hosts:
  - "*"
  gateways:
  - ${INGRESS_GATEWAY_NAMESPACE}/${INGRESS_GATEWAY_NAME}
  http:
  - route:
    - destination:
        host: whereami
        port:
          number: 80
EOF
```

Update the Kustomize base overlay:
```Bash
cd ~/$WHERE_AMI_DIR_NAME/base
kustomize edit add resource virtualservice.yaml
```

## Define Staging namespace overlay

```Bash
cd ~/$WHERE_AMI_DIR_NAME/staging
kustomize edit add resource ../base
kustomize edit set namespace $WHEREAMI_NAMESPACE
```
{{% notice note %}}
The `kustomization.yaml` file was already existing from the [GitHub repository template](https://github.com/mathieu-benoit/config-sync-app-template-repo/blob/main/staging/kustomization.yaml) used when we created the `Whereami` app repository.
{{% /notice %}}

Update the Kustomize base overlay:
```Bash
cat <<EOF >> ~/$WHERE_AMI_DIR_NAME/staging/kustomization.yaml
patchesJson6902:
- target:
    kind: VirtualService
    name: whereami
  patch: |-
    - op: replace
      path: /spec/hosts
      value:
        - ${WHERE_AMI_INGRESS_GATEWAY_HOST_NAME}
EOF
```

## Deploy Kubernetes manifests

```Bash
cd ~/$WHERE_AMI_DIR_NAME/
git add .
git commit -m "Whereami app"
git push origin main
```

## Check deployments

List the GitHub runs for the **Whereami app** repository `cd ~/$WHERE_AMI_DIR_NAME && gh run list`:
```Plaintext
STATUS  NAME            WORKFLOW  BRANCH  EVENT  ID          ELAPSED  AGE
✓       Whereami app    ci        main    push   1976257627  1m1s     2h
✓       Initial commit  ci        main    push   1975324083  1m5s     10h
```

List the Kubernetes resources managed by Config Sync in the **GKE cluster** for the **Whereami app** repository:
```Bash
gcloud alpha anthos config sync repo describe \
    --project $GKE_PROJECT_ID \
    --managed-resources all \
    --sync-name repo-sync \
    --sync-namespace $WHEREAMI_NAMESPACE
```
```Plaintext
getting 1 RepoSync and RootSync from gke-hub-membership
┌─────────────────────┬────────────────┬────────────────────┬───────────┐
│        GROUP        │      KIND      │        NAME        │ NAMESPACE │
├─────────────────────┼────────────────┼────────────────────┼───────────┤
│                     │ ServiceAccount │ whereami-ksa       │ whereami  │
│                     │ ConfigMap      │ whereami-configmap │ whereami  │
│                     │ Service        │ whereami           │ whereami  │
│ apps                │ Deployment     │ whereami           │ whereami  │
│ networking.istio.io │ VirtualService │ whereami           │ whereami  │
└─────────────────────┴────────────────┴────────────────────┴───────────┘
```