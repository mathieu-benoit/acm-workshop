---
title: "Exercises"
weight: 7
---
- Duration: 10 min

Do you want more optional exercises? Here you are!

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
As an example, you could grab your local IP address by running this command: `curl ifconfig.co`.

The associated file to update manually is here: `~/$GKE_PROJECT_DIR_NAME/config-sync/gke-cluster.yaml`, and you could then run this command to actually deploy this change in Config Controller:
```Bash
kubectl apply -f ~/$GKE_PROJECT_DIR_NAME/config-sync/gke-cluster.yaml
```

We don't need that for the workshop as we are deploying all the Kubernetes resources via GitOps with Config Sync, but this could be handy if you need to debug some deployments from your local machine as an example ;)

You could rollback this local change if you want:
```Bash
cd ~/$GKE_PROJECT_DIR_NAME
git checkout ~/$GKE_PROJECT_DIR_NAME/config-sync/gke-cluster.yaml
kubectl apply -f ~/$GKE_PROJECT_DIR_NAME/config-sync/gke-cluster.yaml
```