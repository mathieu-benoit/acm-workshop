# acm-workshop

## Developer setup

### Build and run this static web site locally

```
git clone --recurse-submodules https://github.com/mathieu-benoit/acm-workshop
cd acm-workshop/app
docker build -t acm-workshop .
docker run -d -p 8080:8080 acm-workshop
```

### Configure GitHub action

```
projectId=FIXME
gcloud config set project $projectId

# Create the Service Account
saName=container-images-builder
gcloud iam service-accounts create $saName
saId="${saName}@${projectId}.iam.gserviceaccount.com"

# Enable the IAM Credentials API
gcloud services enable iamcredentials.googleapis.com

# Create a Workload Identity Pool
poolName=container-images-builder-wi-pool
gcloud iam workload-identity-pools create $poolName \
  --location global \
  --display-name $poolName
poolId=$(gcloud iam workload-identity-pools describe $poolName \
  --location global \
  --format='get(name)')

# Create a Workload Identity Provider with GitHub actions in that pool:
attributeMappingScope=repository
gcloud iam workload-identity-pools providers create-oidc $poolName \
  --location global \
  --workload-identity-pool $poolName \
  --display-name $poolName \
  --attribute-mapping "google.subject=assertion.${attributeMappingScope},attribute.actor=assertion.actor,attribute.aud=assertion.aud,attribute.repository=assertion.repository" \
  --issuer-uri "https://token.actions.githubusercontent.com"
providerId=$(gcloud iam workload-identity-pools providers describe $poolName \
  --location global \
  --workload-identity-pool $poolName \
  --format='get(name)')

# Allow authentications from the Workload Identity Provider to impersonate the Service Account created above
gitHubRepoName="mathieu-benoit/acm-workshop"
gcloud iam service-accounts add-iam-policy-binding $saId \
  --role "roles/iam.workloadIdentityUser" \
  --member "principalSet://iam.googleapis.com/${poolId}/attribute.${attributeMappingScope}/${gitHubRepoName}"

# Allow the GSA to write container images in Artifact Registry
artifactRegistryContainersRepository=containers
artifactRegistryChartsRepository=charts
artifactRegistryLocation=northamerica-northeast1
gcloud artifacts repositories add-iam-policy-binding $artifactRegistryContainersRepository \
    --location $artifactRegistryLocation \
    --member "serviceAccount:$saId" \
    --role roles/artifactregistry.writer
gcloud artifacts repositories add-iam-policy-binding $artifactRegistryChartsRepository \
    --location $artifactRegistryLocation \
    --member "serviceAccount:$saId" \
    --role roles/artifactregistry.writer

# Allow the GSA to scan container images on-demand
gcloud services enable ondemandscanning.googleapis.com
gcloud projects add-iam-policy-binding $projectId \
    --member=serviceAccount:$saId \
    --role=roles/ondemandscanning.admin

# Setup GitHub actions variables
cd ~/acm-workshop
gh auth login --web
gh secret set CONTAINER_REGISTRY_PROJECT_ID -b"${projectId}"
gh secret set CONTAINER_REGISTRY_NAME -b"${artifactRegistryContainersRepository}"
gh secret set CHART_REGISTRY_NAME -b"${artifactRegistryChartsRepository}"
gh secret set CONTAINER_REGISTRY_HOST_NAME -b"${artifactRegistryLocation}-docker.pkg.dev"
gh secret set CONTAINER_IMAGE_BUILDER_SERVICE_ACCOUNT_ID -b"${saId}"
gh secret set WORKLOAD_IDENTITY_POOL_PROVIDER -b"${providerId}"
```
