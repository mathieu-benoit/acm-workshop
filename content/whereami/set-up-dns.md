---
title: "Set up DNS"
weight: 2
description: "Duration: 5 min | Persona: Platform Admin"
---
_{{< param description >}}_

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