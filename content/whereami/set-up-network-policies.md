---
title: "Set up Network Policies"
weight: 4
---
- Persona: Apps Operator
- Duration: 5 min
- Objectives:
  - FIXME

Initialize variables:
```Bash
source ~/acm-workshop-variables.sh
```

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

Deploy all these Kubernetes manifests via a GitOps approach:
```Bash
cd ~/$WHERE_AMI_DIR_NAME/
git add .
git commit -m "Whereami Network Policies"
git push
```