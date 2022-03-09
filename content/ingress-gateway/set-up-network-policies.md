---
title: "Set up Network Policies"
weight: 5
description: "Duration: 5 min | Persona: Platform Admin"
---
Initialize variables:
```Bash
source ~/acm-workshop-variables.sh
```

## Define NetworkPolicy resources

```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/$INGRESS_GATEWAY_NAMESPACE/networkpolicy_denyall.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: denyall
  namespace: ${INGRESS_GATEWAY_NAMESPACE}
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
EOF
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/$INGRESS_GATEWAY_NAMESPACE/networkpolicy_ingress-gateway.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ${INGRESS_GATEWAY_NAME}
  namespace: ${INGRESS_GATEWAY_NAMESPACE}
spec:
  podSelector:
    matchLabels:
      app: ${INGRESS_GATEWAY_NAME}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - {}
  egress:
  - {}
EOF
```

## Deploy Kubernetes manifests

```Bash
cd ~/$GKE_CONFIGS_DIR_NAME/
git add .
git commit -m "Ingress Gateway Network Policies"
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