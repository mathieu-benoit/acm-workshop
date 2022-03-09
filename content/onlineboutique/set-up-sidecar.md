---
title: "Set up Sidecar"
weight: 7
description: "Duration: 5 min | Persona: Apps Operator"
---
_{{< param description >}}_

Initialize variables:
```Bash
source ~/acm-workshop-variables.sh
```

## Define Sidecar resources

```Bash
cat <<EOF > ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync/sidecar_adservice.yaml
apiVersion: networking.istio.io/v1beta1
kind: Sidecar
metadata:
  name: adservice
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
spec:
  workloadSelector:
    labels:
      app: adservice
  egress:
  - hosts:
    - "istio-system/*"
EOF
cat <<EOF > ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync/sidecar_cartservice.yaml
apiVersion: networking.istio.io/v1beta1
kind: Sidecar
metadata:
  name: cartservice
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
spec:
  workloadSelector:
    labels:
      app: cartservice
  egress:
  - hosts:
    - "istio-system/*"
EOF
cat <<EOF > ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync/sidecar_checkoutservice.yaml
apiVersion: networking.istio.io/v1beta1
kind: Sidecar
metadata:
  name: checkoutservice
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
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
EOF
cat <<EOF > ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync/sidecar_currencyservice.yaml
apiVersion: networking.istio.io/v1beta1
kind: Sidecar
metadata:
  name: currencyservice
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
spec:
  workloadSelector:
    labels:
      app: currencyservice
  egress:
  - hosts:
    - "istio-system/*"
EOF
cat <<EOF > ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync/sidecar_emailservice.yaml
apiVersion: networking.istio.io/v1beta1
kind: Sidecar
metadata:
  name: emailservice
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
spec:
  workloadSelector:
    labels:
      app: emailservice
  egress:
  - hosts:
    - "istio-system/*"
EOF
cat <<EOF > ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync/sidecar_frontend.yaml
apiVersion: networking.istio.io/v1beta1
kind: Sidecar
metadata:
  name: frontend
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
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
EOF
cat <<EOF > ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync/sidecar_loadgenerator.yaml
apiVersion: networking.istio.io/v1beta1
kind: Sidecar
metadata:
  name: loadgenerator
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
spec:
  workloadSelector:
    labels:
      app: loadgenerator
  egress:
  - hosts:
    - "istio-system/*"
    - "./frontend.${ONLINEBOUTIQUE_NAMESPACE}.svc.cluster.local"
EOF
cat <<EOF > ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync/sidecar_paymentservice.yaml
apiVersion: networking.istio.io/v1beta1
kind: Sidecar
metadata:
  name: paymentservice
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
spec:
  workloadSelector:
    labels:
      app: paymentservice
  egress:
  - hosts:
    - "istio-system/*"
EOF
cat <<EOF > ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync/sidecar_productcatalogservice.yaml
apiVersion: networking.istio.io/v1beta1
kind: Sidecar
metadata:
  name: productcatalogservice
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
spec:
  workloadSelector:
    labels:
      app: productcatalogservice
  egress:
  - hosts:
    - "istio-system/*"
EOF
cat <<EOF > ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync/sidecar_recommendationservice.yaml
apiVersion: networking.istio.io/v1beta1
kind: Sidecar
metadata:
  name: recommendationservice
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
spec:
  workloadSelector:
    labels:
      app: recommendationservice
  egress:
  - hosts:
    - "istio-system/*"
    - "./productcatalogservice.${ONLINEBOUTIQUE_NAMESPACE}.svc.cluster.local"
EOF
cat <<EOF > ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync/sidecar_shippingservice.yaml
apiVersion: networking.istio.io/v1beta1
kind: Sidecar
metadata:
  name: shippingservice
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
spec:
  workloadSelector:
    labels:
      app: shippingservice
  egress:
  - hosts:
    - "istio-system/*"
EOF
```

## Deploy Kubernetes manifests

```Bash
cd ~/$ONLINE_BOUTIQUE_DIR_NAME/
git add .
git commit -m "Online Boutique Sidecar"
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