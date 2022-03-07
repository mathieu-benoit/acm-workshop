---
title: "Set up IP address and DNS"
weight: 1
---
- Persona: Platform Admin
- Duration: 10 min
- Objectives:
  - FIXME

Initialize variables:
```Bash
echo "export INGRESS_GATEWAY_PUBLIC_IP_NAME=${GKE_NAME}-asm-ingressgateway" >> ~/acm-workshop-variables.sh
echo "export WHERE_AMI_INGRESS_GATEWAY_HOST_NAME='whereami.endpoints.${GKE_PROJECT_ID}.cloud.goog'" >> ~/acm-workshop-variables.sh
echo "export ONLINE_BOUTIQUE_INGRESS_GATEWAY_HOST_NAME='onlineboutique.endpoints.${GKE_PROJECT_ID}.cloud.goog'" >> ~/acm-workshop-variables.sh
echo "export BANK_OF_ANTHOS_INGRESS_GATEWAY_HOST_NAME='bankofanthos.endpoints.${GKE_PROJECT_ID}.cloud.goog'" >> ~/acm-workshop-variables.sh
source ~/acm-workshop-variables.sh
```

Define the Ingress Gateway's public static IP address resource:
```Bash
cat <<EOF > ~/$GKE_PROJECT_DIR_NAME/config-sync/public-ip-address.yaml
apiVersion: compute.cnrm.cloud.google.com/v1beta1
kind: ComputeAddress
metadata:
  name: ${INGRESS_GATEWAY_PUBLIC_IP_NAME}
  namespace: ${GKE_PROJECT_ID}
spec:
  location: global
EOF
```

Deploy this public static IP address resource via a GitOps approach:
```Bash
cd ~/$GKE_PROJECT_DIR_NAME/
git add .
git commit -m "Ingress Gateway's public static IP address"
git push
```

```Bash
INGRESS_GATEWAY_PUBLIC_IP=$(gcloud compute addresses describe $INGRESS_GATEWAY_PUBLIC_IP_NAME --global --project ${GKE_PROJECT_ID} --format "value(address)")
echo ${INGRESS_GATEWAY_PUBLIC_IP}
```

```Bash
cat <<EOF > ~/dns-spec.yaml
swagger: "2.0"
info:
  description: "Cloud Endpoints DNS"
  title: "Cloud Endpoints DNS"
  version: "1.0.0"
paths: {}
host: "${WHERE_AMI_INGRESS_GATEWAY_HOST_NAME}"
x-google-endpoints:
- name: "${WHERE_AMI_INGRESS_GATEWAY_HOST_NAME}"
  target: "${INGRESS_GATEWAY_PUBLIC_IP}"
EOF
gcloud endpoints services deploy ~/dns-spec.yaml --project ${GKE_PROJECT_ID}
rm ~/dns-spec.yaml
```

```Bash
cat <<EOF > ~/dns-spec.yaml
swagger: "2.0"
info:
  description: "Cloud Endpoints DNS"
  title: "Cloud Endpoints DNS"
  version: "1.0.0"
paths: {}
host: "${ONLINE_BOUTIQUE_INGRESS_GATEWAY_HOST_NAME}"
x-google-endpoints:
- name: "${ONLINE_BOUTIQUE_INGRESS_GATEWAY_HOST_NAME}"
  target: "${INGRESS_GATEWAY_PUBLIC_IP}"
EOF
gcloud endpoints services deploy ~/dns-spec.yaml --project ${GKE_PROJECT_ID}
rm ~/dns-spec.yaml
```

```Bash
cat <<EOF > ~/dns-spec.yaml
swagger: "2.0"
info:
  description: "Cloud Endpoints DNS"
  title: "Cloud Endpoints DNS"
  version: "1.0.0"
paths: {}
host: "${BANK_OF_ANTHOS_INGRESS_GATEWAY_HOST_NAME}"
x-google-endpoints:
- name: "${BANK_OF_ANTHOS_INGRESS_GATEWAY_HOST_NAME}"
  target: "${INGRESS_GATEWAY_PUBLIC_IP}"
EOF
gcloud endpoints services deploy ~/dns-spec.yaml --project ${GKE_PROJECT_ID}
rm ~/dns-spec.yaml
```