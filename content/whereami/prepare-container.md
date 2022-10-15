---
title: "Prepare container"
weight: 3
description: "Duration: 5 min | Persona: Apps Operator"
tags: ["apps-operator", "security-tips", "shift-left"]
---
![Apps Operator](/images/apps-operator.png)
_{{< param description >}}_

In this section, you will copy the Whereami app container in your private Artifact Registry. You will also scan this container image.

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
WHEREAMI_VERSION=v1.2.12
PRIVATE_WHEREAMI_IMAGE_NAME=$CONTAINER_REGISTRY_REPOSITORY/whereami:$WHEREAMI_VERSION
echo "export PRIVATE_WHEREAMI_IMAGE_NAME=${PRIVATE_WHEREAMI_IMAGE_NAME}" >> ${WORK_DIR}acm-workshop-variables.sh
source ${WORK_DIR}acm-workshop-variables.sh
```

Copy the public image to your private registry:
```Bash
UPSTREAM_WHEREAMI_IMAGE_NAME=us-docker.pkg.dev/google-samples/containers/gke/whereami:$WHEREAMI_VERSION
docker pull $UPSTREAM_WHEREAMI_IMAGE_NAME
docker tag $UPSTREAM_WHEREAMI_IMAGE_NAME $PRIVATE_WHEREAMI_IMAGE_NAME
gcloud auth configure-docker $CONTAINER_REGISTRY_HOST_NAME --quiet
docker push $PRIVATE_WHEREAMI_IMAGE_NAME
```

List the container images in your private registry:
```Bash
gcloud artifacts docker images list $CONTAINER_REGISTRY_REPOSITORY \
    --include-tags
```

[Scan the `whereami` container image](https://cloud.google.com/container-analysis/docs/on-demand-scanning-howto):
```Bash
gcloud artifacts docker images scan $PRIVATE_WHEREAMI_IMAGE_NAME \
    --project ${TENANT_PROJECT_ID} \
    --format='value(response.scan)' > ${WORK_DIR}scan_id.txt
gcloud artifacts docker images list-vulnerabilities $(cat ${WORK_DIR}scan_id.txt) \
    --project ${TENANT_PROJECT_ID} \
    --format='table(vulnerability.effectiveSeverity, vulnerability.cvssScore, noteName, vulnerability.packageIssue[0].affectedPackage, vulnerability.packageIssue[0].affectedVersion.name, vulnerability.packageIssue[0].fixedVersion.name)'
```
{{% notice tip %}}
You could use this `gcloud artifacts docker images scan` command in your Continuous Integration system in order to detect as early as possible for example `Critical` or `High` vulnerabilities.
{{% /notice %}}
