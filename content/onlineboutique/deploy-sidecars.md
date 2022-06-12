---
title: "Deploy Sidecars"
weight: 5
description: "Duration: 5 min | Persona: Apps Operator"
tags: ["asm", "apps-operator"]
---
![Apps Operator](/images/apps-operator.png)
_{{< param description >}}_

In this section, you will deploy a fine granular `Sidecar` in order to optimize the resources (CPU/Memory) usage of the Online Boutique apps's sidecar proxies. At the end of this section you will still have the policies violation you faced earlier, but no worries, you will fix it in the next section.

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
```

By default, each application in the `onlineboutique` `Namespace` can reach to all the endpoints in the mesh. The list of these endpoints with could be listed by the command `istioctl proxy-config clusters`. Here is the output if you would have run this command for the `cartservice` app:
```Plaintext
SERVICE FQDN                                               PORT      SUBSET     DIRECTION     TYPE             DESTINATION RULE
                                                           7070      -          inbound       ORIGINAL_DST
BlackHoleCluster                                           -         -          -             STATIC
InboundPassthroughClusterIpv4                              -         -          -             ORIGINAL_DST
PassthroughCluster                                         -         -          -             ORIGINAL_DST
adservice.onlineboutique.svc.cluster.local                 9555      -          outbound      EDS
agent                                                      -         -          -             STATIC
cartservice.onlineboutique.svc.cluster.local               7070      -          outbound      EDS
checkoutservice.onlineboutique.svc.cluster.local           5050      -          outbound      EDS
currencyservice.onlineboutique.svc.cluster.local           7000      -          outbound      EDS
emailservice.onlineboutique.svc.cluster.local              5000      -          outbound      EDS
frontend.onlineboutique.svc.cluster.local                  80        -          outbound      EDS
paymentservice.onlineboutique.svc.cluster.local            50051     -          outbound      EDS
productcatalogservice.onlineboutique.svc.cluster.local     3550      -          outbound      EDS
prometheus_stats                                           -         -          -             STATIC
recommendationservice.onlineboutique.svc.cluster.local     8080      -          outbound      EDS
redis-cart.onlineboutique.svc.cluster.local                6379      -          outbound      EDS
sds-grpc                                                   -         -          -             STATIC
shippingservice.onlineboutique.svc.cluster.local           50051     -          outbound      EDS
xds-grpc                                                   -         -          -             STATIC
```

## Prepare upstream Kubernetes manifests

Prepare the upstream Kubernetes manifests:
```Bash
cd ${WORK_DIR}$ONLINE_BOUTIQUE_DIR_NAME/upstream
kpt pkg get https://github.com/GoogleCloudPlatform/anthos-service-mesh-samples.git/docs/online-boutique-asm-manifests/sidecars@main
```

## Update the Kustomize base overlay

```Bash
cd ${WORK_DIR}$ONLINE_BOUTIQUE_DIR_NAME/base
kustomize edit add component ../upstream/sidecars/all
```

## Update Staging namespace overlay

```Bash
cd ${WORK_DIR}$ONLINE_BOUTIQUE_DIR_NAME/staging
mkdir sidecars
cp -r ../upstream/sidecars/for-namespace/ sidecars/.
sed -i "s/ONLINEBOUTIQUE_NAMESPACE/${ONLINEBOUTIQUE_NAMESPACE}/g" sidecars/for-namespace/kustomization.yaml
kustomize edit add component sidecars/for-namespace
```

## Deploy Kubernetes manifests

```Bash
cd ${WORK_DIR}$ONLINE_BOUTIQUE_DIR_NAME/
git add . && git commit -m "Online Boutique Sidecars" && git push origin main
```

## Check deployments

List the Kubernetes resources managed by Config Sync in **GKE cluster** for the **Online Boutique apps** repository:
```Bash
gcloud alpha anthos config sync repo describe \
    --project $TENANT_PROJECT_ID \
    --managed-resources all \
    --sync-name repo-sync \
    --sync-namespace $ONLINEBOUTIQUE_NAMESPACE
```
Wait and re-run this command above until you see `"status": "SYNCED"` for this `RepoSync`. All the `managed_resources` listed should have `STATUS: Current` as well.

List the GitHub runs for the **Online Boutique apps** repository:
```Bash
cd ${WORK_DIR}$ONLINE_BOUTIQUE_DIR_NAME && gh run list
```

The endpoints that the `cartservice` app can reach is now reduced:
```Plaintext
SERVICE FQDN                                    PORT     SUBSET     DIRECTION     TYPE             DESTINATION RULE
                                                7070     -          inbound       ORIGINAL_DST
BlackHoleCluster                                -        -          -             STATIC
InboundPassthroughClusterIpv4                   -        -          -             ORIGINAL_DST
PassthroughCluster                              -        -          -             ORIGINAL_DST
agent                                           -        -          -             STATIC
prometheus_stats                                -        -          -             STATIC
redis-cart.onlineboutique.svc.cluster.local     6379     -          outbound      EDS
sds-grpc                                        -        -          -             STATIC
xds-grpc                                        -        -          -             STATIC
```
You could now see that you don't see anymore other endpoints that the `cartservice` app is communicating with. That's a great CPU/Memory resources usage optimization!

## Check the Online Boutique apps

We still have the issue previously described with the Online Boutique website, let's fix the `NetworkPolicies` with the next section.