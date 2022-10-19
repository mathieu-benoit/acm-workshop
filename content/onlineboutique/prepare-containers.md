---
title: "Prepare containers"
weight: 4
description: "Duration: 5 min | Persona: Apps Operator"
tags: ["apps-operator", "security-tips", "shift-left"]
---
![Apps Operator](/images/apps-operator.png)
_{{< param description >}}_

In this section, you will copy the Online Boutique apps containers in your private Artifact Registry. You will also scan one container image.

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
ONLINE_BOUTIQUE_VERSION=$(curl -s https://api.github.com/repos/GoogleCloudPlatform/microservices-demo/releases | jq -r '[.[]] | .[0].tag_name')
echo "export ONLINE_BOUTIQUE_VERSION=${ONLINE_BOUTIQUE_VERSION}" >> ${WORK_DIR}acm-workshop-variables.sh
PRIVATE_ONLINE_BOUTIQUE_REGISTRY=$CONTAINER_REGISTRY_REPOSITORY/onlineboutique
echo "export PRIVATE_ONLINE_BOUTIQUE_REGISTRY=${PRIVATE_ONLINE_BOUTIQUE_REGISTRY}" >> ${WORK_DIR}acm-workshop-variables.sh
source ${WORK_DIR}acm-workshop-variables.sh
```

Copy the public container images to your private registry:
```Bash
UPSTREAM_ONLINE_BOUTIQUE_REGISTRY=gcr.io/google-samples/microservices-demo
SERVICES="adservice cartservice checkoutservice currencyservice emailservice frontend loadgenerator paymentservice productcatalogservice recommendationservice shippingservice"
for s in $SERVICES; do crane copy $UPSTREAM_ONLINE_BOUTIQUE_REGISTRY/$s:$ONLINE_BOUTIQUE_VERSION $PRIVATE_ONLINE_BOUTIQUE_REGISTRY/$s:$ONLINE_BOUTIQUE_VERSION; done
crane copy redis:alpine $PRIVATE_ONLINE_BOUTIQUE_REGISTRY/redis:alpine
crane copy busybox:latest $PRIVATE_ONLINE_BOUTIQUE_REGISTRY/busybox:latest
```

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