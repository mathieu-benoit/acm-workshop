---
title: "Configure the public IP and DNS"
weight: 2
---


```Bash
export INGRESS_GATEWAY_HOST_NAME="frontend.endpoints.${PROJECT_ID}.cloud.goog"
export INGRESS_GATEWAY_PUBLIC_IP_NAME=$GKE_NAME-asm-ingressgateway
gcloud compute addresses create $INGRESS_GATEWAY_PUBLIC_IP_NAME \
    --global
export INGRESS_GATEWAY_PUBLIC_IP=$(gcloud compute addresses describe $INGRESS_GATEWAY_PUBLIC_IP_NAME --global --format "value(address)")
echo ${INGRESS_GATEWAY_PUBLIC_IP}
```

```Bash
cat <<EOF > dns-spec.yaml
swagger: "2.0"
info:
  description: "Cloud Endpoints DNS"
  title: "Cloud Endpoints DNS"
  version: "1.0.0"
paths: {}
host: "${INGRESS_GATEWAY_HOST_NAME}"
x-google-endpoints:
- name: "${INGRESS_GATEWAY_HOST_NAME}"
  target: "${INGRESS_GATEWAY_PUBLIC_IP}"
EOF
gcloud endpoints services deploy dns-spec.yaml
```