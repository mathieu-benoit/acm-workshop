---
title: "Configure Sidecar for OnlineBoutique"
weight: 1
---
In this section you will configure `Sidecar` for the OnlineBoutique namespace.

Run this command which allows to define fine granular `Sidecar` per app:
```Bash
cat <<EOF | kubectl apply -n $ONLINEBOUTIQUE_NAMESPACE -f -
apiVersion: networking.istio.io/v1beta1
kind: Sidecar
metadata:
  name: adservice
spec:
  workloadSelector:
    labels:
      app: adservice
  egress:
  - hosts:
    - "istio-system/*"
---
apiVersion: networking.istio.io/v1beta1
kind: Sidecar
metadata:
  name: cartservice
spec:
  workloadSelector:
    labels:
      app: cartservice
  egress:
  - hosts:
    - "istio-system/*"
---
apiVersion: networking.istio.io/v1beta1
kind: Sidecar
metadata:
  name: checkoutservice
spec:
  workloadSelector:
    labels:
      app: checkoutservice
  egress:
  - hosts:
    - "istio-system/*"
    - "./cartservice.${ONLINEBOUTIQUE_NAMESPACE}.svc.cluster.local"
    - "./currencyservice.${ONLINEBOUTIQUE_NAMESPACE}.svc.cluster.local"
    - "./emailservice.${ONLINEBOUTIQUE_NAMESPACE}.svc.cluster.local"
    - "./paymentservice.${ONLINEBOUTIQUE_NAMESPACE}.svc.cluster.local"
    - "./productcatalogservice.${ONLINEBOUTIQUE_NAMESPACE}.svc.cluster.local"
    - "./shippingservice.${ONLINEBOUTIQUE_NAMESPACE}.svc.cluster.local"
---
apiVersion: networking.istio.io/v1beta1
kind: Sidecar
metadata:
  name: currencyservice
spec:
  workloadSelector:
    labels:
      app: currencyservice
  egress:
  - hosts:
    - "istio-system/*"
---
apiVersion: networking.istio.io/v1beta1
kind: Sidecar
metadata:
  name: emailservice
spec:
  workloadSelector:
    labels:
      app: emailservice
  egress:
  - hosts:
    - "istio-system/*"
---
apiVersion: networking.istio.io/v1beta1
kind: Sidecar
metadata:
  name: frontend
spec:
  workloadSelector:
    labels:
      app: frontend
  egress:
  - hosts:
    - "istio-system/*"
    - "./adservice.${ONLINEBOUTIQUE_NAMESPACE}.svc.cluster.local"
    - "./cartservice.${ONLINEBOUTIQUE_NAMESPACE}.svc.cluster.local"
    - "./checkoutservice.${ONLINEBOUTIQUE_NAMESPACE}.svc.cluster.local"
    - "./currencyservice.${ONLINEBOUTIQUE_NAMESPACE}.svc.cluster.local"
    - "./productcatalogservice.${ONLINEBOUTIQUE_NAMESPACE}.svc.cluster.local"
    - "./recommendationservice.${ONLINEBOUTIQUE_NAMESPACE}.svc.cluster.local"
    - "./shippingservice.${ONLINEBOUTIQUE_NAMESPACE}.svc.cluster.local"
---
apiVersion: networking.istio.io/v1beta1
kind: Sidecar
metadata:
  name: loadgenerator
spec:
  workloadSelector:
    labels:
      app: loadgenerator
  egress:
  - hosts:
    - "istio-system/*"
    - "./frontend.${ONLINEBOUTIQUE_NAMESPACE}.svc.cluster.local"
---
apiVersion: networking.istio.io/v1beta1
kind: Sidecar
metadata:
  name: paymentservice
spec:
  workloadSelector:
    labels:
      app: paymentservice
  egress:
  - hosts:
    - "istio-system/*"
---
apiVersion: networking.istio.io/v1beta1
kind: Sidecar
metadata:
  name: productcatalogservice
spec:
  workloadSelector:
    labels:
      app: productcatalogservice
  egress:
  - hosts:
    - "istio-system/*"
---
apiVersion: networking.istio.io/v1beta1
kind: Sidecar
metadata:
  name: recommendationservice
spec:
  workloadSelector:
    labels:
      app: recommendationservice
  egress:
  - hosts:
    - "istio-system/*"
    - "./productcatalogservice.${ONLINEBOUTIQUE_NAMESPACE}.svc.cluster.local"
---
apiVersion: networking.istio.io/v1beta1
kind: Sidecar
metadata:
  name: shippingservice
spec:
  workloadSelector:
    labels:
      app: shippingservice
  egress:
  - hosts:
    - "istio-system/*"
EOF
```