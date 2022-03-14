---
title: "Set up Sidecar"
weight: 5
description: "Duration: 5 min | Persona: Apps Operator"
---
_{{< param description >}}_

Initialize variables:
```Bash
source ~/acm-workshop-variables.sh
```

## Define Sidecar resource

```Bash
cat <<EOF > ~/$WHERE_AMI_DIR_NAME/config-sync/sidecar.yaml
apiVersion: networking.istio.io/v1beta1
kind: Sidecar
metadata:
  name: whereami
  namespace: ${WHEREAMI_NAMESPACE}
spec:
  workloadSelector:
    labels:
      app: whereami
  egress:
  - hosts:
    - istio-system/*
EOF
```

## Deploy Kubernetes manifests

```Bash
cd ~/$WHERE_AMI_DIR_NAME/
git add .
git commit -m "Whereami Sidecar"
git push origin main
```

## Check deployments

List the GitHub runs for the **Whereami app** repository `cd ~/$WHERE_AMI_DIR_NAME && gh run list`:
```Plaintext
STATUS  NAME                       WORKFLOW  BRANCH  EVENT  ID          ELAPSED  AGE
✓       Whereami Sidecar           ci        main    push   1976601129  1m3s     5m
✓       Whereami Network Policies  ci        main    push   1976593659  1m1s     1m
✓       Whereami app               ci        main    push   1976257627  1m1s     2h
✓       Initial commit             ci        main    push   1975324083  1m5s     10h
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
┌─────────────────────┬─────────────────────┬────────────────────┬───────────┐
│        GROUP        │         KIND        │        NAME        │ NAMESPACE │
├─────────────────────┼─────────────────────┼────────────────────┼───────────┤
│                     │ ServiceAccount      │ whereami-ksa       │ whereami  │
│                     │ Service             │ whereami           │ whereami  │
│                     │ ConfigMap           │ whereami-configmap │ whereami  │
│ apps                │ Deployment          │ whereami           │ whereami  │
│ networking.istio.io │ Sidecar             │ whereami           │ whereami  │
│ networking.istio.io │ VirtualService      │ whereami           │ whereami  │
│ networking.k8s.io   │ NetworkPolicy       │ denyall            │ whereami  │
│ networking.k8s.io   │ NetworkPolicy       │ whereami           │ whereami  │
└─────────────────────┴─────────────────────┴────────────────────┴───────────┘
```