---
title: "Configure AuthorizationPolicy for Ingress Gateway"
weight: 1
---
In this section we will configure `AuthorizationPolicy` for the Ingress Gateway namespace.

Deploy fine granular `AuthorizationPolicy` per app:
```Bash
cat <<EOF | kubectl apply -n $INGRESS_GATEWAY_NAMESPACE -f -
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: deny-all
spec:
  {}
---
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: ${INGRESS_GATEWAY_NAME}
spec:
  selector:
    matchLabels:
      app: ${INGRESS_GATEWAY_NAME}
  rules:
  - to:
      - operation:
          ports: ["80"]
EOF
```

Go to the GCP Console and see that your Ingress Gateway namespace has its _Service access control_ green:

![Ingress Gateway - Service access control view in GCP Console](/images/ingressgateway-authz.png)