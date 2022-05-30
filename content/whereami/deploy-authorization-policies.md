---
title: "Deploy AuthorizationPolicies"
weight: 4
description: "Duration: 5 min | Persona: Apps Operator"
tags: ["apps-operator", "asm", "security-tips"]
---
![Apps Operator](/images/apps-operator.png)
_{{< param description >}}_

Initialize variables:
```Bash
source ${WORK_DIR}acm-workshop-variables.sh
```

## Define AuthorizationPolicy

Define fine granular `AuthorizationPolicy` resource:
```Bash
cat <<EOF > ~/$WHERE_AMI_DIR_NAME/base/authorizationpolicy_whereami.yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: whereami
spec:
  selector:
    matchLabels:
      app: whereami
  rules:
  - from:
    - source:
        principals:
        - cluster.local/ns/${INGRESS_GATEWAY_NAMESPACE}/sa/${INGRESS_GATEWAY_NAME}
    to:
    - operation:
        ports:
        - "8080"
        methods:
        - GET
EOF
```

Update the Kustomize base overlay:
```Bash
cd ~/$WHERE_AMI_DIR_NAME/base
kustomize edit add resource authorizationpolicy_whereami.yaml
```

## Deploy Kubernetes manifests

```Bash
cd ~/$WHERE_AMI_DIR_NAME/
git add .
git commit -m "Whereami Authorization Policy"
git push origin main
```

## Check deployments

List the GitHub runs for the **Whereami app** repository `cd ~/$WHERE_AMI_DIR_NAME && gh run list`:
```Plaintext
STATUS  NAME                             WORKFLOW  BRANCH  EVENT  ID          ELAPSED  AGE
✓       Whereami Authorization Policy    ci        main    push   1976612253  1m9s     2m
✓       Whereami Sidecar                 ci        main    push   1976601129  1m3s     5m
✓       Whereami Network Policies        ci        main    push   1976593659  1m1s     1m
✓       Whereami app                     ci        main    push   1976257627  1m1s     2h
✓       Initial commit                   ci        main    push   1975324083  1m5s     10h
```

List the Kubernetes resources managed by Config Sync in the **GKE cluster** for the **Whereami app** repository:
```Bash
gcloud alpha anthos config sync repo describe \
    --project $TENANT_PROJECT_ID \
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
│ security.istio.io   │ AuthorizationPolicy │ whereami           │ whereami  │
└─────────────────────┴─────────────────────┴────────────────────┴───────────┘
```

## Check the Whereami app

Navigate to the Whereami app, click on the link displayed by the command below:
```Bash
echo -e "https://${WHERE_AMI_INGRESS_GATEWAY_HOST_NAME}"
```

You should now have the Whereami app working successfully.