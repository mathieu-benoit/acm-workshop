---
title: "Create GKE cluster"
weight: 2
---

Set the name of the GKE cluster a a variable:
```Bash
export GKE_NAME=$PROJECT_NAME
```

Create a least privilege Service Account for the default node pool:
```Bash
GKE_SA_NAME=$GKE_NAME-sa
GKE_SA_ID=$GKE_SA_NAME@$PROJECT_ID.iam.gserviceaccount.com
gcloud iam service-accounts create $GKE_SA_NAME \
  --display-name=$GKE_SA_NAME
GKE_ROLES="roles/logging.logWriter roles/monitoring.metricWriter roles/monitoring.viewer"
for r in $GKE_ROLES; do gcloud projects add-iam-policy-binding $PROJECT_ID --member "serviceAccount:$GKE_SA_ID" --role $r; done
```

Create the GKE cluster:
```Bash
gcloud container clusters create $GKE_NAME \
    --service-account $GKE_SA_ID \
    --workload-pool=$PROJECT_ID.svc.id.goog \
    --zone $ZONE \
    --machine-type n2d-standard-4 \
    --image-type cos_containerd \
    --enable-dataplane-v2 \
    --addons NodeLocalDNS,HttpLoadBalancing \
    --enable-ip-alias \
    --logging=SYSTEM,WORKLOAD \
    --monitoring=SYSTEM
```

Wait and check that the GKE cluster has been provisioned properly:
```Bash
kubectl get nodes
```

Register the GKE cluster as an Anthos fleet:
```Bash
gcloud container hub memberships register $GKE_NAME \
    --gke-cluster $ZONE/$GKE_NAME \
    --enable-workload-identity
```