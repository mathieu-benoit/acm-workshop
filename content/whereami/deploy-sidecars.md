---
title: "Deploy Sidecars"
weight: 6
description: "Duration: 5 min | Persona: Apps Operator"
tags: ["apps-operator", "asm"]
---
![Apps Operator](/images/apps-operator.png)
_{{< param description >}}_

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
```

Before deploying the `Sidecar`, let's see the endpoints that the `whereami` app can reach out by default:
```Bash
istioctl proxy-config clusters $(kubectl -n $WHEREAMI_NAMESPACE get pod -l app=whereami -o jsonpath={.items[0].metadata.name}) \
    -n $WHEREAMI_NAMESPACE
```
```Plaintext
SERVICE FQDN                                         PORT      SUBSET     DIRECTION     TYPE             DESTINATION RULE
                                                     8080      -          inbound       ORIGINAL_DST
BlackHoleCluster                                     -         -          -             STATIC
InboundPassthroughClusterIpv4                        -         -          -             ORIGINAL_DST
PassthroughCluster                                   -         -          -             ORIGINAL_DST
agent                                                -         -          -             STATIC
asm-ingressgateway.asm-ingress.svc.cluster.local     80        -          outbound      EDS
asm-ingressgateway.asm-ingress.svc.cluster.local     443       -          outbound      EDS
asm-ingressgateway.asm-ingress.svc.cluster.local     15021     -          outbound      EDS
prometheus_stats                                     -         -          -             STATIC
sds-grpc                                             -         -          -             STATIC
whereami.whereami.svc.cluster.local                  80        -          outbound      EDS
xds-grpc                                             -         -          -             STATIC
```

## Define Sidecar

```Bash
cat <<EOF > ${WORK_DIR}$WHERE_AMI_DIR_NAME/base/sidecar.yaml
apiVersion: networking.istio.io/v1beta1
kind: Sidecar
metadata:
  name: whereami
spec:
  workloadSelector:
    labels:
      app: whereami
  egress:
  - hosts:
    - istio-system/*
EOF
```

Update the Kustomize base overlay:
```Bash
cd ${WORK_DIR}$WHERE_AMI_DIR_NAME/base
kustomize edit add resource sidecar.yaml
```

## Deploy Kubernetes manifests

```Bash
cd ${WORK_DIR}$WHERE_AMI_DIR_NAME/
git add . && git commit -m "Whereami Sidecar" && git push origin main
```

## Check deployments

List the Kubernetes resources managed by Config Sync in **GKE cluster** for the **Whereami app** repository:
```Bash
gcloud alpha anthos config sync repo describe \
    --project $TENANT_PROJECT_ID \
    --managed-resources all \
    --sync-name repo-sync \
    --sync-namespace $WHEREAMI_NAMESPACE
```
Wait and re-run this command above until you see `"status": "SYNCED"` for this `RepoSync`. All the `managed_resources` listed should have `STATUS: Current` as well.

List the GitHub runs for the **Whereami app** repository:
```Bash
cd ${WORK_DIR}$WHERE_AMI_DIR_NAME && gh run list
```

Let's now see the endpoints that the `whereami` app can reach out after we deployed this `Sidecar`:
```Bash
istioctl proxy-config clusters $(kubectl -n $WHEREAMI_NAMESPACE get pod -l app=whereami -o jsonpath={.items[0].metadata.name}) \
    -n $WHEREAMI_NAMESPACE
```
```Plaintext
SERVICE FQDN                      PORT     SUBSET     DIRECTION     TYPE             DESTINATION RULE
                                  8080     -          inbound       ORIGINAL_DST
BlackHoleCluster                  -        -          -             STATIC
InboundPassthroughClusterIpv4     -        -          -             ORIGINAL_DST
PassthroughCluster                -        -          -             ORIGINAL_DST
agent                             -        -          -             STATIC
prometheus_stats                  -        -          -             STATIC
sds-grpc                          -        -          -             STATIC
xds-grpc                          -        -          -             STATIC
```
You could now see that you don't see anymore other endpoints that the `whereami` app is communicating with. That's great CPU/Memory resources usage optimization!

## Check the Whereami app

Navigate to the Whereami app, click on the link displayed by the command below:
```Bash
echo -e "https://${WHERE_AMI_INGRESS_GATEWAY_HOST_NAME}"
```

You should still have the Whereami app working successfully.