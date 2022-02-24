---
title: "Set up Network Policies"
weight: 5
---
- Persona: Apps Operator
- Duration: 5 min
- Objectives:
  - FIXME

```Bash
cat <<EOF > ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync/networkpolicy_denyall.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: denyall
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
EOF
cat <<EOF > ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync/networkpolicy_adservice.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: adservice
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
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
EOF
cat <<EOF > ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync/networkpolicy_cartservice.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: cartservice
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
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
EOF
cat <<EOF > ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync/networkpolicy_checkoutservice.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: checkoutservice
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
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
EOF
cat <<EOF > ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync/networkpolicy_currencyservice.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: currencyservice
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
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
EOF
cat <<EOF > ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync/networkpolicy_emailservice.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: emailservice
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
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
EOF
cat <<EOF > ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync/networkpolicy_frontend.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: frontend
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
spec:
  podSelector:
    matchLabels:
      app: frontend
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - {}
  #- from:
  #  - podSelector:
  #      matchLabels:
  #        app: loadgenerator
  #  - namespaceSelector:
  #      matchLabels:
  #        name: ${INGRESS_GATEWAY_NAMESPACE}
  #    podSelector:
  #      matchLabels:
  #        app: ${INGRESS_GATEWAY_NAME}
  #  ports:
  #   - port: 8080
  #     protocol: TCP
  egress:
  - {}
EOF
cat <<EOF > ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync/networkpolicy_loadgenerator.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: loadgenerator
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
spec:
  podSelector:
    matchLabels:
      app: loadgenerator
  policyTypes:
  - Egress
  egress:
  - {}
EOF
cat <<EOF > ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync/networkpolicy_paymentservice.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: paymentservice
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
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
EOF
cat <<EOF > ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync/networkpolicy_productcatalogservice.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: productcatalogservice
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
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
EOF
cat <<EOF > ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync/networkpolicy_recommendationservice.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: recommendationservice
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
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
EOF
cat <<EOF > ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync/networkpolicy_shippingservice.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: shippingservice
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
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

Deploy all these Kubernetes manifests via a GitOps approach:
```Bash
cd ~/$ONLINE_BOUTIQUE_DIR_NAME/
git add .
git commit -m "Online Boutique Network Policies"
git push
```