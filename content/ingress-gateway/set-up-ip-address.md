---
title: "Set up IP address"
weight: 1
---
- Persona: Platform Admin
- Duration: 10 min
- Objectives:
  - FIXME

Initialize variables:
```Bash
echo "export INGRESS_GATEWAY_PUBLIC_IP_NAME=${GKE_NAME}-asm-ingressgateway" >> ~/acm-workshop-variables.sh
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

Grab the provisioned IP address:
```Bash
INGRESS_GATEWAY_PUBLIC_IP=$(gcloud compute addresses describe $INGRESS_GATEWAY_PUBLIC_IP_NAME --global --project ${GKE_PROJECT_ID} --format "value(address)")
echo ${INGRESS_GATEWAY_PUBLIC_IP}
echo "export INGRESS_GATEWAY_PUBLIC_IP=${INGRESS_GATEWAY_PUBLIC_IP}" >> ~/acm-workshop-variables.sh
```