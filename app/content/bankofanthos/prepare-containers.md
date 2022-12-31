---
title: "Prepare containers"
weight: 3
description: "Duration: 5 min | Persona: Apps Operator"
tags: ["apps-operator", "security-tips"]
---
![Apps Operator](/images/apps-operator.png)
_{{< param description >}}_

In this section, you will copy the Bank of Anthos apps containers in your private Artifact Registry. You will also scan one container image.

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
BANK_OF_ANTHOS_VERSION=v0.5.10
echo "export BANK_OF_ANTHOS_VERSION=${BANK_OF_ANTHOS_VERSION}" >> ${WORK_DIR}acm-workshop-variables.sh
PRIVATE_BANK_OF_ANTHOS_REGISTRY=$CONTAINER_REGISTRY_REPOSITORY/bankofanthos
echo "export PRIVATE_BANK_OF_ANTHOS_REGISTRY=${PRIVATE_BANK_OF_ANTHOS_REGISTRY}" >> ${WORK_DIR}acm-workshop-variables.sh
source ${WORK_DIR}acm-workshop-variables.sh
```

Copy the public container images to your private registry:
```Bash
UPSTREAM_BANK_OF_ANTHOS_REGISTRY=gcr.io/bank-of-anthos-ci
SERVICES="accounts-db balancereader contacts frontend ledger-db ledgerwriter loadgenerator transactionhistory userservice"
for s in $SERVICES; do crane copy $UPSTREAM_BANK_OF_ANTHOS_REGISTRY/$s:$BANK_OF_ANTHOS_VERSION $PRIVATE_BANK_OF_ANTHOS_REGISTRY/$s:$BANK_OF_ANTHOS_VERSION; done
```

List the container images in your private registry:
```Bash
gcloud artifacts docker images list $CONTAINER_REGISTRY_REPOSITORY \
    --include-tags
```

[Scan the `cartservice` container image](https://cloud.google.com/container-analysis/docs/on-demand-scanning-howto):
```Bash
gcloud artifacts docker images scan $PRIVATE_BANK_OF_ANTHOS_REGISTRY/cartservice:$BANK_OF_ANTHOS_VERSION \
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