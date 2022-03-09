---
title: "Set up Authorization Policies"
weight: 8
---
- Persona: Apps Operator
- Duration: 5 min

Initialize variables:
```Bash
source ~/acm-workshop-variables.sh
```

## Define ServiceAccount resources

Define one `ServiceAccount` per app:
```Bash
cat <<EOF > ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync/serviceaccount_adservice.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: adservice
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
EOF
cat <<EOF > ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync/serviceaccount_cartservice.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: cartservice
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
EOF
cat <<EOF > ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync/serviceaccount_checkoutservice.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: checkoutservice
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
EOF
cat <<EOF > ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync/serviceaccount_currencyservice.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: currencyservice
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
EOF
cat <<EOF > ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync/serviceaccount_emailservice.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: emailservice
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
EOF
cat <<EOF > ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync/serviceaccount_frontend.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: frontend
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
EOF
cat <<EOF > ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync/serviceaccount_loadgenerator.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: loadgenerator
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
EOF
cat <<EOF > ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync/serviceaccount_paymentservice.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: paymentservice
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
EOF
cat <<EOF > ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync/serviceaccount_productcatalogservice.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: productcatalogservice
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
EOF
cat <<EOF > ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync/serviceaccount_recommendationservice.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: recommendationservice
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
EOF
cat <<EOF > ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync/serviceaccount_shippingservice.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: shippingservice
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
EOF
```

## Update ServieAccount in Kubernetes manifests

Replace the default `ServiceAccount` per app:
```Bash
services="adservice cartservice checkoutservice currencyservice emailservice frontend loadgenerator paymentservice productcatalogservice recommendationservice shippingservice"
for s in $services; do sed -i "s/serviceAccountName: default/serviceAccountName: $s/g" ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync/deployment_$s.yaml; done
```

## Define AuthorizationPolicy resources

Define fine granular `AuthorizationPolicy` resources:
```Bash
cat <<EOF > ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync/authorizationpolicy_denyall.yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: deny-all
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
spec: {}
EOF
cat <<EOF > ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync/authorizationpolicy_adservice.yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: adservice
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
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
EOF
cat <<EOF > ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync/authorizationpolicy_cartservice.yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: cartservice
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
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
        ports: ["7070"]
EOF
cat <<EOF > ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync/authorizationpolicy_checkoutservice.yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: checkoutservice
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
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
EOF
cat <<EOF > ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync/authorizationpolicy_currencyservice.yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: currencyservice
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
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
EOF
cat <<EOF > ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync/authorizationpolicy_emailservice.yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: emailservice
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
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
EOF
cat <<EOF > ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync/authorizationpolicy_frontend.yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: frontend
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
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
EOF
cat <<EOF > ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync/authorizationpolicy_paymentservice.yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: paymentservice
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
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
EOF
cat <<EOF > ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync/authorizationpolicy_productcatalogservice.yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: productcatalogservice
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
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
EOF
cat <<EOF > ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync/authorizationpolicy_recommendationservice.yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: recommendationservice
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
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
EOF
cat <<EOF > ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync/authorizationpolicy_shippingservice.yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: shippingservice
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
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

## Deploy Kubernetes manifests

```Bash
cd ~/$ONLINE_BOUTIQUE_DIR_NAME/
git add .
git commit -m "Online Boutique Authorization Policies"
git push
```

## Check deployments

Here is what you should have at this stage:

If you run:
```Bash
cd ~/$WORKSHOP_ORG_DIR_NAME && gh run list
```
You should see:
```Plaintext
FIXME
```

If you run:
```Bash
cd ~/$GKE_PROJECT_DIR_NAME && gh run list
```
You should see:
```Plaintext
FIXME
```

If you run:
```Bash
cd ~/$GKE_CONFIGS_DIR_NAME && gh run list
```
You should see:
```Plaintext
FIXME
```

If you run:
```Bash
gcloud alpha anthos config sync repo describe \
   --project $CONFIG_CONTROLLER_PROJECT_ID \
   --managed-resources all \
   --format="multi(statuses:format=none,managed_resources:format='table[box](group:sort=2,kind,name,namespace:sort=1)')"
```
You should see:
```Plaintext
FIXME
```

If you run:
```Bash
gcloud alpha anthos config sync repo describe \
   --project $GKE_PROJECT_ID \
   --managed-resources all \
   --format="multi(statuses:format=none,managed_resources:format='table[box](group:sort=2,kind,name,namespace:sort=1)')"
```
You should see:
```Plaintext
FIXME
```