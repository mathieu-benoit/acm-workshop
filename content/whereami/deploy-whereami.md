---
title: "Deploy Whereami app"
weight: 3
description: "Duration: 5 min | Persona: Apps Operator"
---
Initialize variables:
```Bash
source ~/acm-workshop-variables.sh
```

## Grab upstream Kubernetes manifests

Create a dedicated folder for the Whereami sample app in the GKE configs's Git repo:
```Bash
cd ~/$WHERE_AMI_DIR_NAME/config-sync
kpt pkg get https://github.com/GoogleCloudPlatform/kubernetes-engine-samples/whereami/k8s
```

## Update Kubernetes manifests

Cleanup and update the upstream files:
```Bash
mv k8s/* .
rm -r k8s/
rm Kptfile
rm kustomization.yaml
kpt fn eval . \
  -i set-namespace:v0.2 \
  -- namespace=$WHEREAMI_NAMESPACE
sed -i "s/LoadBalancer/ClusterIP/g" ~/$WHERE_AMI_DIR_NAME/config-sync/service.yaml
sed -i "s/TRACE_SAMPLING_RATIO: \"0.10\"/TRACE_SAMPLING_RATIO: \"0\"/g" ~/$WHERE_AMI_DIR_NAME/config-sync/configmap.yaml
```

## Define VirtualService

```Bash
cat <<EOF > ~/$WHERE_AMI_DIR_NAME/config-sync/virtualservice.yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: whereami
  namespace: ${WHEREAMI_NAMESPACE}
spec:
  hosts:
  - ${WHERE_AMI_INGRESS_GATEWAY_HOST_NAME}
  gateways:
  - ${INGRESS_GATEWAY_NAMESPACE}/${INGRESS_GATEWAY_NAME}
  http:
  - route:
    - destination:
        host: whereami
        port:
          number: 80
EOF
```

## Setup WorkloadIdentity

```Bash
# FIXME: TMP, to replace by KCC equivalent:
ksaName=whereami-ksa
gsaName=whereami-gsa
gsaAccountName=$gsaName@$GKE_PROJECT_ID.iam.gserviceaccount.com
gcloud iam service-accounts create $gsaName \
  --project $GKE_PROJECT_ID
gcloud iam service-accounts add-iam-policy-binding \
  --project $GKE_PROJECT_ID \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:$GKE_PROJECT_ID.svc.id.goog[$WHEREAMI_NAMESPACE/$ksaName]" \
  $gsaAccountName
kubectl annotate serviceaccount \
  $ksaName \
  iam.gke.io/gcp-service-account=$gsaAccountName
gcloud projects add-iam-policy-binding $GKE_PROJECT_ID \
  --member "serviceAccount:$gsaAccountName" \
  --role roles/cloudtrace.agent
```

## Deploy Kubernetes manifests

```Bash
cd ~/$WHERE_AMI_DIR_NAME/
git add .
git commit -m "Whereami app"
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