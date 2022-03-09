---
title: "Set up Sidecar"
weight: 5
---
- Persona: Apps Operator
- Duration: 5 min

Initialize variables:
```Bash
source ~/acm-workshop-variables.sh
```

## Define Sidecar resource

```Bash
cat <<EOF > ~/$WHERE_AMI_DIR_NAME/config-sync/sidecar.yaml
apiVersion: networking.istio.io/v1beta1
kind: Sidecar
metadata:
  name: whereami
  namespace: ${WHEREAMI_NAMESPACE}
spec:
  workloadSelector:
    labels:
      app: whereami
  egress:
  - hosts:
    - "istio-system/*"
EOF
```

## Deploy Kubernetes manifests

```Bash
cd ~/$WHERE_AMI_DIR_NAME/
git add .
git commit -m "Whereami Sidecar"
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