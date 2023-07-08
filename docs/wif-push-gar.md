### Configure GitHub action

The required WIF setup could be found here: https://medium.com/p/3932dce678b8.

In addition to that:
```bash
CHART_REGISTRY_NAME=charts
gcloud artifacts repositories add-iam-policy-binding ${CHART_REGISTRY_NAME} \
    --location ${CHART_REGISTRY_NAME} \
    --member "serviceAccount:${GSA_ID}" \
    --role roles/artifactregistry.writer

# Setup GitHub actions variables
gh secret set CHART_REGISTRY_NAME -b"${CHART_REGISTRY_NAME}"
```
