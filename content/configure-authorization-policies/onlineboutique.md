---
title: "Configure AuthorizationPolicy for OnlineBoutique"
weight: 2
---
In this section we will configure `AuthorizationPolicy` for the OnlineBoutique namespace.

Create Kubernetes `ServiceAccount` per app:
```Bash
cat <<EOF | kubectl apply -n $ONLINEBOUTIQUE_NAMESPACE -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: adservice
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: cartservice
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: checkoutservice
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: currencyservice
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: emailservice
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: frontend
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: loadgenerator
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: paymentservice
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: productcatalogservice
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: recommendationservice
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: shippingservice
EOF
```

Replace the `default` `ServiceAccount` per app:
```Bash
services="adservice cartservice checkoutservice currencyservice emailservice frontend loadgenerator paymentservice productcatalogservice recommendationservice shippingservice"
for s in $services; do sed -i "s/serviceAccountName: default/serviceAccountName: $s/g" ~/$WORKING_DIRECTORY/$ONLINEBOUTIQUE_NAMESPACE/deployment_$s.yaml; done
```

Re-deploy the updated Kubernetes manifests updated:
```Bash
kubectl apply -f ~/$WORKING_DIRECTORY/$ONLINEBOUTIQUE_NAMESPACE/ -n $ONLINEBOUTIQUE_NAMESPACE
```

Ensure that all deployments are still up and running:
```Bash
kubectl wait --for=condition=available --timeout=600s deployment --all -n $ONLINEBOUTIQUE_NAMESPACE
curl -s http://${INGRESS_GATEWAY_PUBLIC_IP}
```

Deploy fine granular `AuthorizationPolicy` per app:
```Bash
cat <<EOF | kubectl apply -n $ONLINEBOUTIQUE_NAMESPACE -f -
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
  name: adservice
spec:
  selector:
    matchLabels:
      app: adservice
  rules:
  - from:
    - source:
        principals: ["cluster.local/ns/${ONLINEBOUTIQUE_NAMESPACE}/sa/frontend"]
    to:
      - operation:
          paths: ["/hipstershop.AdService/GetAds"]
          methods: ["POST"]
          ports: ["9555"]
---
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: cartservice
spec:
  selector:
    matchLabels:
      app: cartservice
  rules:
  - from:
    - source:
        principals: ["cluster.local/ns/${ONLINEBOUTIQUE_NAMESPACE}/sa/frontend", "cluster.local/ns/${ONLINEBOUTIQUE_NAMESPACE}/sa/checkoutservice"]
    to:
      - operation:
          paths: ["/hipstershop.CartService/AddItem", "/hipstershop.CartService/GetCart", "/hipstershop.CartService/EmptyCart"]
          methods: ["POST"]
---
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: checkoutservice
spec:
  selector:
    matchLabels:
      app: checkoutservice
  rules:
  - from:
    - source:
        principals: ["cluster.local/ns/${ONLINEBOUTIQUE_NAMESPACE}/sa/frontend"]
    to:
      - operation:
          paths: ["/hipstershop.CheckoutService/PlaceOrder"]
          methods: ["POST"]
          ports: ["5050"]
---
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: currencyservice
spec:
  selector:
    matchLabels:
      app: currencyservice
  rules:
  - from:
    - source:
        principals: ["cluster.local/ns/${ONLINEBOUTIQUE_NAMESPACE}/sa/frontend", "cluster.local/ns/${ONLINEBOUTIQUE_NAMESPACE}/sa/checkoutservice"]
    to:
      - operation:
          paths: ["/hipstershop.CurrencyService/Convert", "/hipstershop.CurrencyService/GetSupportedCurrencies"]
          methods: ["POST"]
          ports: ["7000"]
---
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: emailservice
spec:
  selector:
    matchLabels:
      app: emailservice
  rules:
  - from:
    - source:
        principals: ["cluster.local/ns/${ONLINEBOUTIQUE_NAMESPACE}/sa/checkoutservice"]
    to:
      - operation:
          paths: ["/hipstershop.EmailService/SendOrderConfirmation"]
          methods: ["POST"]
          ports: ["8080"]
---
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: frontend
spec:
  selector:
    matchLabels:
      app: frontend
  rules:
  - from:
    - source:
        principals: ["cluster.local/ns/${ONLINEBOUTIQUE_NAMESPACE}/sa/loadgenerator", "cluster.local/ns/${INGRESS_GATEWAY_NAMESPACE}/sa/${INGRESS_GATEWAY_NAME}"]
    to:
      - operation:
          ports: ["8080"]
          methods: ["GET", "POST"]
---
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: paymentservice
spec:
  selector:
    matchLabels:
      app: paymentservice
  rules:
  - from:
    - source:
        principals: ["cluster.local/ns/${ONLINEBOUTIQUE_NAMESPACE}/sa/checkoutservice"]
    to:
      - operation:
          paths: ["/hipstershop.PaymentService/Charge"]
          methods: ["POST"]
          ports: ["50051"]
---
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: productcatalogservice
spec:
  selector:
    matchLabels:
      app: productcatalogservice
  rules:
  - from:
    - source:
        principals: ["cluster.local/ns/${ONLINEBOUTIQUE_NAMESPACE}/sa/frontend", "cluster.local/ns/${ONLINEBOUTIQUE_NAMESPACE}/sa/checkoutservice", "cluster.local/ns/${ONLINEBOUTIQUE_NAMESPACE}/sa/recommendationservice"]
    to:
      - operation:
          paths: ["/hipstershop.ProductCatalogService/GetProduct", "/hipstershop.ProductCatalogService/ListProducts"]
          methods: ["POST"]
          ports: ["3550"]
---
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: recommendationservice
spec:
  selector:
    matchLabels:
      app: recommendationservice
  rules:
  - from:
    - source:
        principals: ["cluster.local/ns/${ONLINEBOUTIQUE_NAMESPACE}/sa/frontend"]
    to:
      - operation:
          paths: ["/hipstershop.RecommendationService/ListRecommendations"]
          methods: ["POST"]
          ports: ["8080"]
---
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: shippingservice
spec:
  selector:
    matchLabels:
      app: shippingservice
  rules:
  - from:
    - source:
        principals: ["cluster.local/ns/${ONLINEBOUTIQUE_NAMESPACE}/sa/frontend", "cluster.local/ns/${ONLINEBOUTIQUE_NAMESPACE}/sa/checkoutservice"]
    to:
      - operation:
          paths: ["/hipstershop.ShippingService/GetQuote", "/hipstershop.ShippingService/ShipOrder"]
          methods: ["POST"]
          ports: ["50051"]
EOF
```

Test that the solution is still working properly:
```Bash
curl -s http://${INGRESS_GATEWAY_PUBLIC_IP}
```

Go to the GCP Console and see that your OnlineBoutique namespace has its _Service access control_ green:

![OnlineBoutique - Service access control view in GCP Console](/images/onlineboutique-authz.png)