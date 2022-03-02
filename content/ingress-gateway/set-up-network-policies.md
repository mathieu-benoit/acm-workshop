---
title: "Set up Network Policies"
weight: 5
---
- Persona: Platform Admin
- Duration: 5 min
- Objectives:
  - FIXME

Initialize variables:
```Bash
source ~/acm-workshop-variables.sh
```

```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/$INGRESS_GATEWAY_NAMESPACE/networkpolicy_denyall.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: denyall
  namespace: ${INGRESS_GATEWAY_NAMESPACE}
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
EOF
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/$INGRESS_GATEWAY_NAMESPACE/networkpolicy_ingress-gateway.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ${INGRESS_GATEWAY_NAME}
  namespace: ${INGRESS_GATEWAY_NAMESPACE}
spec:
  podSelector:
    matchLabels:
      app: ${INGRESS_GATEWAY_NAME}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - {}
  egress:
  - {}
EOF
```

Deploy all these Kubernetes manifests via a GitOps approach:
```Bash
cd ~/$GKE_CONFIGS_DIR_NAME/
git add .
git commit -m "Ingress Gateway Network Policies"
git push
```