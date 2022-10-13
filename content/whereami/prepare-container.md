---
title: "Prepare container"
weight: 4
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
WHEREAMI_VERSION=v1.2.10
PRIVATE_WHEREAMI_IMAGE_NAME=$CONTAINER_REGISTRY_REPOSITORY/whereami:$WHEREAMI_VERSION
echo "export PRIVATE_WHEREAMI_IMAGE_NAME=${PRIVATE_WHEREAMI_IMAGE_NAME}" >> ${WORK_DIR}acm-workshop-variables.sh
source ${WORK_DIR}acm-workshop-variables.sh
```

Create the GitHub actions definition:
```Bash
cd ${WORK_DIR}$WHERE_AMI_DIR_NAME
cat <<EOF > ${WORK_DIR}$WHERE_AMI_DIR_NAME/.github/workflows/copy-container.yaml
name: copy-container
permissions:
  id-token: write
  contents: read
env:
  SEVERITY: CRITICAL
  WHEREAMI_APP_NAME: whereami
  WHEREAMI_VERSION: 1.2.10
  UPSTREAM_WHEREAMI_IMAGE_NAME: us-docker.pkg.dev/google-samples/containers/gke/whereami
jobs:
  job:
    runs-on: ubuntu-22.04
    steps:
      - uses: actions/checkout@v3.0.2
        with:
          submodules: true
      - uses: google-github-actions/auth@v0.8.1
        with:
          workload_identity_provider: '${{ secrets.WORKLOAD_IDENTITY_POOL_PROVIDER }}'
          service_account: '${{ secrets.CONTAINER_IMAGE_BUILDER_SERVICE_ACCOUNT_ID }}'
          token_format: 'access_token'
      - uses: google-github-actions/setup-gcloud@v0.6.0
        with:
          version: latest
      - name: copy the container
        run: |
          docker pull ${UPSTREAM_WHEREAMI_IMAGE_NAME}:${WHEREAMI_VERSION}
          imageName=${{ secrets.CONTAINER_REGISTRY_HOST_NAME }}/${{ secrets.CONTAINER_REGISTRY_PROJECT_ID }}/${{ secrets.CONTAINER_REGISTRY_NAME }}/${WHEREAMI_APP_NAME}
          echo "PRIVATE_WHEREAMI_IMAGE_NAME=$imageName" >> $GITHUB_ENV
          docker tag ${UPSTREAM_WHEREAMI_IMAGE_NAME}:${WHEREAMI_VERSION} ${PRIVATE_WHEREAMI_IMAGE_NAME}:${WHEREAMI_VERSION}
          docker push ${PRIVATE_WHEREAMI_IMAGE_NAME}:${WHEREAMI_VERSION}
      - name: scan the container
        run: |
          gcloud components install local-extract --quiet
          gcloud artifacts docker images scan ${PRIVATE_WHEREAMI_IMAGE_NAME}:${WHEREAMI_VERSION} --format='value(response.scan)' > scan_id.txt
          gcloud artifacts docker images list-vulnerabilities $(cat scan_id.txt) --format='table(vulnerability.effectiveSeverity, vulnerability.cvssScore, noteName, vulnerability.packageIssue[0].affectedPackage, vulnerability.packageIssue[0].affectedVersion.name, vulnerability.packageIssue[0].fixedVersion.name)'
          gcloud artifacts docker images list-vulnerabilities $(cat scan_id.txt) --format='value(vulnerability.effectiveSeverity)' | if grep -Fxq ${{ env.SEVERITY }}; then echo 'Failed vulnerability check' && exit 1; else exit 0; fi
EOF
```
{{% notice tip %}}
You could see that we scan the container image as part of the Continuous Integration pipeline and generate an error if any `Critical` vulnerabilities is found.
{{% /notice %}}

Set GitHub actions secrets:
```Bash
gh secret set CONTAINER_REGISTRY_PROJECT_ID -b"${projectId}"
gh secret set CONTAINER_REGISTRY_NAME -b"${artifactRegistryName}"
gh secret set CONTAINER_REGISTRY_HOST_NAME -b"${artifactRegistryLocation}-docker.pkg.dev"
gh secret set CONTAINER_IMAGE_BUILDER_SERVICE_ACCOUNT_ID -b"${saId}"
gh secret set WORKLOAD_IDENTITY_POOL_PROVIDER -b"${providerId}"
```

Commit the file:
```Bash

```

Manually trigger the GitHub actions run:
```Bash

```



List the container images in your private registry:
```Bash
gcloud artifacts docker images list $CONTAINER_REGISTRY_REPOSITORY \
    --include-tags
```