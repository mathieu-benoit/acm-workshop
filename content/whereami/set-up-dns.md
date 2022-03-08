---
title: "Set up DNS"
weight: 2
---
- Persona: Platform Admin
- Duration: 5 min

Initialize variables:
```Bash
source ~/acm-workshop-variables.sh
echo "export WHERE_AMI_INGRESS_GATEWAY_HOST_NAME='whereami.endpoints.${GKE_PROJECT_ID}.cloud.goog'" >> ~/acm-workshop-variables.sh
```

## Create FQDN

Create an FQDN with Cloud Ednpoints for Whereami:
```Bash
cat <<EOF > ~/dns-spec.yaml
swagger: "2.0"
info:
  description: "Whereami Cloud Endpoints DNS"
  title: "Whereami Cloud Endpoints DNS"
  version: "1.0.0"
paths: {}
host: "${WHERE_AMI_INGRESS_GATEWAY_HOST_NAME}"
x-google-endpoints:
- name: "${WHERE_AMI_INGRESS_GATEWAY_HOST_NAME}"
  target: "${INGRESS_GATEWAY_PUBLIC_IP}"
EOF
gcloud endpoints services deploy ~/dns-spec.yaml \
    --project ${GKE_PROJECT_ID}
rm ~/dns-spec.yaml
```

## Define ManagedCertificate

Define the `ManagedCertificate` for Whereami in the Ingress Gateway namespace:
```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/$INGRESS_GATEWAY_NAMESPACE/managedcertificate-whereami.yaml
apiVersion: networking.gke.io/v1
kind: ManagedCertificate
metadata:
  name: whereami
  namespace: ${INGRESS_GATEWAY_NAMESPACE}
spec:
  domains:
    - "${WHERE_AMI_INGRESS_GATEWAY_HOST_NAME}"
EOF
```

## Update Ingress

Configure Whereami `ManagedCertificate` on the Ingress Gateway's `Ingress` resource:
```Bash
cd ~/$GKE_CONFIGS_DIR_NAME/config-sync/$INGRESS_GATEWAY_NAMESPACE
kpt fn eval . \
    -i set-annotations:v0.1 \
    --match-kind Ingress \
    -- networking.gke.io/managed-certificates=whereami
```

## Deploy Kubernetes manifests

```Bash
cd ~/$GKE_CONFIGS_DIR_NAME/
git add .
git commit -m "Whereami ManagedCertificate"
git push
```