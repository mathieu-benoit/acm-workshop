---
title: "Deploy Whereami app"
weight: 3
description: "Duration: 10 min | Persona: Apps Operator"
---
_{{< param description >}}_

Initialize variables:
```Bash
source ~/acm-workshop-variables.sh
```

## Get upstream Kubernetes manifests

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

List the GitHub runs for the **Whereami app** repository `cd ~/$WHERE_AMI_DIR_NAME && gh run list`:
```Plaintext
STATUS  NAME            WORKFLOW  BRANCH  EVENT  ID          ELAPSED  AGE
✓       Whereami app    ci        main    push   1976257627  1m1s     2h
✓       Initial commit  ci        main    push   1975324083  1m5s     10h
```

List the Kubernetes resources managed by Config Sync in the **GKE cluster** for the **Whereami app** repository:
```Bash
gcloud alpha anthos config sync repo describe \
    --project $GKE_PROJECT_ID \
    --managed-resources all \
    --sync-name repo-sync \
    --sync-namespace $WHEREAMI_NAMESPACE
```
```Plaintext
getting 1 RepoSync and RootSync from gke-hub-membership
┌─────────────────────┬────────────────┬────────────────────┬───────────┐
│        GROUP        │      KIND      │        NAME        │ NAMESPACE │
├─────────────────────┼────────────────┼────────────────────┼───────────┤
│                     │ ServiceAccount │ whereami-ksa       │ whereami  │
│                     │ ConfigMap      │ whereami-configmap │ whereami  │
│                     │ Service        │ whereami           │ whereami  │
│ apps                │ Deployment     │ whereami           │ whereami  │
│ networking.istio.io │ VirtualService │ whereami           │ whereami  │
└─────────────────────┴────────────────┴────────────────────┴───────────┘
```