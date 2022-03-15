---
title: "Extras"
weight: 7
description: "Duration: 10 min"
---
_{{< param description >}}_

Do you want more optional exercises? Here you are!

Initialize variables:
```Bash
source ~/acm-workshop-variables.sh
```

## Concept of drift

Let's modify the GKE cluster via a gcloud command and see what happens.

```Bash
gcloud container clusters update $GKE_NAME \
    --zone $GKE_LOCATION \
    --update-labels test=test
```

If you describe your cluster you will see your change:
```Bash
gcloud container clusters describe $GKE_NAME \
    --zone $GKE_LOCATION
```

But if you re-run this command ~5 min later, you will see that your change is not anymore there. That's the concept of drift from Config Sync

## Update MAN for GKE cluster

Currently, you can't access the GKE cluster via `kubectl` commands because it's a private cluster, but let's update the GKE cluster resource with this snippet:

```YAML
  masterAuthorizedNetworksConfig:
    cidrBlocks:
    - cidrBlock: FIXME_YOUR_LOCAL_IP_ADDRESS/32
      displayName: local
```
As an example, you could get your local IP address by running this command: `curl ifconfig.co`.

The associated file to update manually is here: `~/$GKE_PROJECT_DIR_NAME/config-sync/gke-cluster.yaml`, and you could then run this command to actually deploy this change in Config Controller:
```Bash
kubectl apply -f ~/$GKE_PROJECT_DIR_NAME/config-sync/gke-cluster.yaml
```

We don't need that for the workshop as we are deploying all the Kubernetes resources via GitOps with Config Sync, but this could be handy if you need to debug some deployments from your local machine as an example.

You could rollback this local change if you want:
```Bash
cd ~/$GKE_PROJECT_DIR_NAME
git checkout ~/$GKE_PROJECT_DIR_NAME/config-sync/gke-cluster.yaml
kubectl apply -f ~/$GKE_PROJECT_DIR_NAME/config-sync/gke-cluster.yaml
```

## Validate Policies

Let's define a `Deployment` violating the `deployment-required-labels` `Constraint` previously created:
```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/nginx-test.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        test: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.14.2
        ports:
        - containerPort: 80
EOF
```

And now let's evaluate this `Constraint` on the current Kubernetes manifests we have locally and see the error:
```Bash
kpt fn eval ~/$GKE_CONFIGS_DIR_NAME/config-sync \
    -i gatekeeper:v0.2
```

If you change the label `test: nginx` by `app: nginx` and re-run this the above command, you will see that you don't have any error anymore.

You could rollback this local change if you want:
```Bash
rm ~/$GKE_CONFIGS_DIR_NAME/config-sync/nginx-test.yaml
```