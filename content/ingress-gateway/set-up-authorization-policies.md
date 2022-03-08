---
title: "Set up Authorization Policies"
weight: 6
---
- Persona: Platform Admin
- Duration: 5 min

Initialize variables:
```Bash
source ~/acm-workshop-variables.sh
```

## Define AuthorizationPolicy resources

```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/$INGRESS_GATEWAY_NAMESPACE/authorizationpolicy_denyall.yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: deny-all
  namespace: ${INGRESS_GATEWAY_NAMESPACE}
spec: {}
EOF
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/$INGRESS_GATEWAY_NAMESPACE/authorizationpolicy_ingress-gateway.yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: ${INGRESS_GATEWAY_NAME}
  namespace: ${INGRESS_GATEWAY_NAMESPACE}
spec:
  selector:
    matchLabels:
      app: ${INGRESS_GATEWAY_NAME}
  rules:
  - to:
    - operation:
        ports: ["8080"]
EOF
```

## Deploy Kubernetes manifests

```Bash
cd ~/$GKE_CONFIGS_DIR_NAME/
git add .
git commit -m "Ingress Gateway Authorization Policies"
git push
```