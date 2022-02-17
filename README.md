# asm-workshop

## About the content of this lab

Put this https://alwaysupalwayson.com/asm-security as a workshop.

1. [X] Create a GKE cluster
1. [X] Install ASM
1. [X] Ingress Gateway
1. [ ] Egress Gateway
1. [X] Install OnlineBoutique
1. [X] mTLS
1. [X] Sidecar
1. [X] AuthorizationPolicies
1. [ ] NetworkPolicies
1. [ ] Policy Controller
1. [ ] Config Sync
1. [ ] Monitoring: Topology, SLOs, Traces, etc.
1. [ ] Misc: any Istio's features about traffic management, etc.

Further considerations:
- Do the same with BankOfAnthos?
- What about Kubernetes RBAC where we could distinguish sec, dev, ops folks/authz and which resource kinds or namespaces they could touch?
- Multi-cluster?
- MCP (control/data plane)?
- Integrate CRfA in there? Or do another similar crfa-workshop?
- Do a Neos tutorial based on this? Qwiklabs or Codelabs?

## Developer setup

### Build and run this static web site locally

```
git clone --recurse-submodules https://github.com/mathieu-benoit/asm-workshop
cd asm-workshop
docker build -t asm-workshop .
docker run -d -p 8080:8080 asm-workshop
```

### Configure GitHub action

```
projectId=FIXME
gcloud config set project $projectId

# Setup Service account
saName=asm-workshop-gha-cr-push
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