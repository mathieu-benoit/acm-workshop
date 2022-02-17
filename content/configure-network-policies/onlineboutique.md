---
title: "Configure NetworkPolicy for OnlineBoutique"
weight: 2
---
In this section we will configure `NetworkPolicy` for the OnlineBoutique namespace.

Deploy fine granular `NetworkPolicy` per app:
```Bash
cat <<EOF | kubectl apply -n $ONLINEBOUTIQUE_NAMESPACE -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: adservice
spec:
  podSelector:
    matchLabels:
      app: adservice
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
     - port: 9555
       protocol: TCP
  egress:
  - {}
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: cartservice
spec:
  podSelector:
    matchLabels:
      app: cartservice
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    - podSelector:
        matchLabels:
          app: checkoutservice
    ports:
     - port: 7070
       protocol: TCP
  egress:
  - {}
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: checkoutservice
spec:
  podSelector:
    matchLabels:
      app: checkoutservice
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
     - port: 5050
       protocol: TCP
  egress:
  - {}
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: currencyservice
spec:
  podSelector:
    matchLabels:
      app: currencyservice
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    - podSelector:
        matchLabels:
          app: checkoutservice
    ports:
     - port: 7000
       protocol: TCP
  egress:
  - {}
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: emailservice
spec:
  podSelector:
    matchLabels:
      app: emailservice
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: checkoutservice
    ports:
     - port: 8080
       protocol: TCP
  egress:
  - {}
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: frontend
spec:
  podSelector:
    matchLabels:
      app: frontend
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: loadgenerator
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
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: loadgenerator
spec:
  podSelector:
    matchLabels:
      app: loadgenerator
  policyTypes:
  - Egress
  egress:
  - {}
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: paymentservice
spec:
  podSelector:
    matchLabels:
      app: paymentservice
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: checkoutservice
    ports:
     - port: 50051
       protocol: TCP
  egress:
  - {}
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: productcatalogservice
spec:
  podSelector:
    matchLabels:
      app: productcatalogservice
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    - podSelector:
        matchLabels:
          app: checkoutservice
    - podSelector:
        matchLabels:
          app: recommendationservice
    ports:
     - port: 3550
       protocol: TCP
  egress:
  - {}
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: recommendationservice
spec:
  podSelector:
    matchLabels:
      app: recommendationservice
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
     - port: 8080
       protocol: TCP
  egress:
  - {}
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: shippingservice
spec:
  podSelector:
    matchLabels:
      app: shippingservice
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    - podSelector:
        matchLabels:
          app: checkoutservice
    ports:
     - port: 50051
       protocol: TCP
  egress:
  - {}
EOF
```

FIXME - Image in GCP Console