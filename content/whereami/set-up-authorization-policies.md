---
title: "Set up Authorization Policies"
weight: 6
---
- Persona: Apps Operator
- Duration: 5 min
- Objectives:
  - FIXME

Initialize variables:
```Bash
source ~/acm-workshop-variables.sh
```

Define fine granular `AuthorizationPolicy` resources:
```Bash
cat <<EOF > ~/$WHERE_AMI_DIR_NAME/config-sync/authorizationpolicy_denyall.yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: deny-all
  namespace: ${WHEREAMI_NAMESPACE}
spec: {}
EOF
cat <<EOF > ~/$WHERE_AMI_DIR_NAME/config-sync/authorizationpolicy_whereami.yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: whereami
  namespace: ${WHEREAMI_NAMESPACE}
spec:
  selector:
    matchLabels:
      app: whereami
  rules:
  - from:
    - source:
        principals: ["cluster.local/ns/${INGRESS_GATEWAY_NAMESPACE}/sa/${INGRESS_GATEWAY_NAME}"]
    to:
    - operation:
        ports: ["8080"]
        methods: ["GET"]
EOF
```

Deploy all these Kubernetes manifests via a GitOps approach:
```Bash
cd ~/$WHERE_AMI_DIR_NAME/
git add .
git commit -m "Whereami Authorization Policies"
git push
```