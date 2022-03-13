---
title: "Set up Network Policies"
weight: 4
description: "Duration: 5 min | Persona: Apps Operator"
---
_{{< param description >}}_

Initialize variables:
```Bash
source ~/acm-workshop-variables.sh
```

## Define NetworkPolicy resources

Define fine granular `NetworkPolicy` resources:
```Bash
cat <<EOF > ~/$WHERE_AMI_DIR_NAME/config-sync/networkpolicy_denyall.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: denyall
  namespace: ${WHEREAMI_NAMESPACE}
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
EOF
cat <<EOF > ~/$WHERE_AMI_DIR_NAME/config-sync/networkpolicy_whereami.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: whereami
  namespace: ${WHEREAMI_NAMESPACE}
spec:
  podSelector:
    matchLabels:
      app: whereami
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ${INGRESS_GATEWAY_NAMESPACE}
      podSelector:
        matchLabels:
          app: ${INGRESS_GATEWAY_NAME}
    ports:
    - port: 8080
      protocol: TCP
  egress:
  - {}
EOF
```

## Deploy Kubernetes manifests

```Bash
cd ~/$WHERE_AMI_DIR_NAME/
git add .
git commit -m "Whereami Network Policies"
git push
```

## Check deployments

List the GitHub runs for the **Whereami app** repository `cd ~/$WHERE_AMI_DIR_NAME && gh run list`:
```Plaintext
STATUS  NAME                       WORKFLOW  BRANCH  EVENT  ID          ELAPSED  AGE
✓       Whereami Network Policies  ci        main    push   1976593659  1m1s     1m
✓       Whereami app               ci        main    push   1976257627  1m1s     2h
✓       Initial commit             ci        main    push   1975324083  1m5s     10h
```

List the Kubernetes resources managed by Config Sync in the **GKE cluster** for the **Whereami app** repository:
```Bash
gcloud alpha anthos config sync repo describe \
    --project $GKE_PROJECT_ID \
    --managed-resources all \
    --format="multi(statuses:format=none,managed_resources:format='table[box](group:sort=2,kind,name,namespace:sort=1)')" \
    --sync-name repo-sync \
    --sync-namespace $WHEREAMI_NAMESPACE
```
```Plaintext
getting 1 RepoSync and RootSync from gke-hub-membership
┌─────────────────────┬────────────────┬────────────────────┬───────────┐
│        GROUP        │      KIND      │        NAME        │ NAMESPACE │
├─────────────────────┼────────────────┼────────────────────┼───────────┤
│                     │ ConfigMap      │ whereami-configmap │ whereami  │
│                     │ ServiceAccount │ whereami-ksa       │ whereami  │
│                     │ Service        │ whereami           │ whereami  │
│ apps                │ Deployment     │ whereami           │ whereami  │
│ networking.istio.io │ VirtualService │ whereami           │ whereami  │
│ networking.k8s.io   │ NetworkPolicy  │ whereami           │ whereami  │
│ networking.k8s.io   │ NetworkPolicy  │ denyall            │ whereami  │
└─────────────────────┴────────────────┴────────────────────┴───────────┘
```