# acm-workshop

## Developer setup

### Build and run this static web site locally

```
git clone --recurse-submodules https://github.com/mathieu-benoit/acm-workshop
cd acm-workshop
docker build -t acm-workshop .
docker run -d -p 8080:8080 acm-workshop
```

### Configure GitHub action

```
projectId=FIXME
gcloud config set project $projectId

# Setup Service account
saName=acm-workshop-gha-cr-push
saId=$saName@$projectId.iam.gserviceaccount.com
gcloud iam service-accounts create $saName \
    --display-name=$saName
gcloud iam service-accounts keys create ~/tmp/$saName.json \
    --iam-account $saId

# Setup Artifact Registry
artifactRegistryName=FIXME
artifactRegistryLocation=FIXME
gcloud artifacts repositories add-iam-policy-binding $artifactRegistryName \
    --project $projectId \
    --location $artifactRegistryLocation \
    --member "serviceAccount:$saId" \
    --role roles/artifactregistry.writer
gcloud projects add-iam-policy-binding $projectId \
    --member=serviceAccount:$saId \
    --role=roles/ondemandscanning.admin

# Setup GitHub actions variables
gh auth login --web
gh secret set CONTAINER_REGISTRY_PUSH_PRIVATE_KEY < ~/tmp/$saName.json
rm ~/tmp/$saName.json
gh secret set CONTAINER_REGISTRY_PROJECT_ID -b"${projectId}"
gh secret set CONTAINER_REGISTRY_NAME -b"${artifactRegistryName}"
gh secret set CONTAINER_REGISTRY_HOST_NAME -b"${artifactRegistryLocation}-docker.pkg.dev"
```