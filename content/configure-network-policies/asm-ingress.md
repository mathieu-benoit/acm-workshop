---
title: "Configure NetworkPolicy for Ingress Gateway"
weight: 1
---
In this section we will configure `NetworkPolicy` for the Ingress Gateway namespace.

Deploy fine granular `NetworkPolicy` per app:
```Bash
cat <<EOF | kubectl apply -n $INGRESS_GATEWAY_NAMESPACE -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: denyall
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ${INGRESS_GATEWAY_NAME}
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
```

FIXME - Image in GCP Console