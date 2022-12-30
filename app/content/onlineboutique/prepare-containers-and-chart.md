---
title: "Prepare containers and chart"
weight: 4
description: "Duration: 5 min | Persona: Apps Operator"
tags: ["apps-operator", "security-tips"]
---
![Apps Operator](/images/apps-operator.png)
_{{< param description >}}_

In this section, you will copy the Online Boutique apps container images and the Helm chart in your private Artifact Registry. You will also scan one container image.

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
ONLINE_BOUTIQUE_VERSION=v0.5.0
echo "export ONLINE_BOUTIQUE_VERSION=${ONLINE_BOUTIQUE_VERSION}" >> ${WORK_DIR}acm-workshop-variables.sh
PRIVATE_ONLINE_BOUTIQUE_REGISTRY=$CONTAINER_REGISTRY_REPOSITORY/onlineboutique
echo "export PRIVATE_ONLINE_BOUTIQUE_REGISTRY=${PRIVATE_ONLINE_BOUTIQUE_REGISTRY}" >> ${WORK_DIR}acm-workshop-variables.sh
source ${WORK_DIR}acm-workshop-variables.sh
```

## Prepare the container images

Copy the public container images to your private registry:
```Bash
UPSTREAM_ONLINE_BOUTIQUE_CONTAINER_REGISTRY=gcr.io/google-samples/microservices-demo
HTTP_SERVICES="frontend loadgenerator"
TAG=$ONLINE_BOUTIQUE_VERSION
for s in $HTTP_SERVICES; do crane copy $UPSTREAM_ONLINE_BOUTIQUE_CONTAINER_REGISTRY/$s:$TAG $PRIVATE_ONLINE_BOUTIQUE_REGISTRY/$s:$TAG; done
GRPC_SERVICES="adservice cartservice checkoutservice currencyservice emailservice paymentservice productcatalogservice recommendationservice shippingservice"
TAG=$ONLINE_BOUTIQUE_VERSION-native-grpc-probes
for s in $GRPC_SERVICES; do crane copy $UPSTREAM_ONLINE_BOUTIQUE_CONTAINER_REGISTRY/$s:$TAG $PRIVATE_ONLINE_BOUTIQUE_REGISTRY/$s:$TAG; done
crane copy redis:alpine $PRIVATE_ONLINE_BOUTIQUE_REGISTRY/redis:alpine
```
{{% notice tip %}}
We are making the copy of the gRPC services supporting the native Kubernetes health probes in order to get the associated optimized images, learn more about this [here](https://medium.com/google-cloud/b5bd26253a4c).
{{% /notice %}}

List the container images in your private registry:
```Bash
gcloud artifacts docker images list $CONTAINER_REGISTRY_REPOSITORY \
    --include-tags
```

[Scan the `cartservice` container image](https://cloud.google.com/container-analysis/docs/on-demand-scanning-howto):
```Bash
gcloud artifacts docker images scan $PRIVATE_ONLINE_BOUTIQUE_REGISTRY/cartservice:$ONLINE_BOUTIQUE_VERSION \
    --project ${TENANT_PROJECT_ID} \
    --remote \
    --format='value(response.scan)' > ${WORK_DIR}scan_id.txt
gcloud artifacts docker images list-vulnerabilities $(cat ${WORK_DIR}scan_id.txt) \
    --project ${TENANT_PROJECT_ID} \
    --format='table(vulnerability.effectiveSeverity, vulnerability.cvssScore, noteName, vulnerability.packageIssue[0].affectedPackage, vulnerability.packageIssue[0].affectedVersion.name, vulnerability.packageIssue[0].fixedVersion.name)'
```
{{% notice tip %}}
You could use this `gcloud artifacts docker images scan` command in your Continuous Integration system in order to detect as early as possible for example `Critical` or `High` vulnerabilities.
{{% /notice %}}

## Prepare the Helm chart

Copy the public Helm chart to your private registry:
```Bash
UPSTREAM_ONLINE_BOUTIQUE_HELM_CHART_REGISTRY=us-docker.pkg.dev/online-boutique-ci/charts/onlineboutique
helm pull oci://${UPSTREAM_ONLINE_BOUTIQUE_HELM_CHART_REGISTRY} --version ${ONLINE_BOUTIQUE_VERSION:1}
helm push onlineboutique-${ONLINE_BOUTIQUE_VERSION:1}.tgz oci://${CHART_REGISTRY_REPOSITORY}
```

List the container images in your private registry:
```Bash
gcloud artifacts docker images list $CHART_REGISTRY_REPOSITORY \
    --include-tags
```