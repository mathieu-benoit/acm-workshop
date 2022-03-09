---
title: "Set up GKE configs's Git repo"
weight: 4
description: "Duration: 10 min | Persona: Platform Admin"
---
_{{< param description >}}_

Define variables:
```Bash
echo "export export GKE_CONFIGS_DIR_NAME=acm-workshop-gke-configs-repo" >> ~/acm-workshop-variables.sh
source ~/acm-workshop-variables.sh
```

Define the ACM [`GKEHubFeature`](https://cloud.google.com/config-connector/docs/reference/resource-docs/gkehub/gkehubfeature) resource:
```Bash
cat <<EOF > ~/$GKE_PROJECT_DIR_NAME/config-sync/gke-hub-feature-acm.yaml
apiVersion: gkehub.cnrm.cloud.google.com/v1beta1
kind: GKEHubFeature
metadata:
  name: ${GKE_NAME}-acm
  namespace: ${GKE_PROJECT_ID}
spec:
  projectRef:
    external: ${GKE_PROJECT_ID}
  location: global
  resourceID: configmanagement
EOF
```
{{% notice note %}}
The `resourceID` must be `configmanagement` if you want to use Anthos Config Management feature.
{{% /notice %}}

```Bash
cat <<EOF > ~/$GKE_PROJECT_DIR_NAME/config-sync/gke-hub-membership.yaml
apiVersion: gkehub.cnrm.cloud.google.com/v1beta1
kind: GKEHubMembership
metadata:
  name: ${GKE_NAME}-hub-membership
  namespace: ${GKE_PROJECT_ID}
spec:
  location: global
  authority:
    issuer: https://container.googleapis.com/v1/projects/${GKE_PROJECT_ID}/locations/${GKE_LOCATION}/clusters/${GKE_NAME}
  endpoint:
    gkeCluster:
      resourceRef:
        name: ${GKE_NAME}
EOF
```

Create a dedicated GitHub repository where we will commit all the configs, policies, etc. we want to deploy in this GKE cluster:
```Bash
gh repo create $GKE_CONFIGS_DIR_NAME --public --clone --template https://github.com/mathieu-benoit/config-sync-template-repo
cd ~/$GKE_CONFIGS_DIR_NAME
GKE_CONFIGS_REPO_URL=$(gh repo view --json url --jq .url)
```

```Bash
cat <<EOF > ~/$GKE_PROJECT_DIR_NAME/config-sync/gke-acm-membership.yaml
apiVersion: gkehub.cnrm.cloud.google.com/v1beta1
kind: GKEHubFeatureMembership
metadata:
  name: ${GKE_NAME}-acm-membership
  namespace: ${GKE_PROJECT_ID}
spec:
  projectRef:
    external: ${GKE_PROJECT_ID}
  location: global
  membershipRef:
    name: ${GKE_NAME}-hub-membership
  featureRef:
    name: ${GKE_NAME}-acm
  configmanagement:
    configSync:
      sourceFormat: unstructured
      git:
        policyDir: config-sync
        secretType: none
        syncBranch: main
        syncRepo: ${GKE_CONFIGS_REPO_URL}
    policyController:
      enabled: true
      referentialRulesEnabled: true
      logDeniesEnabled: true
      templateLibraryInstalled: false
    version: "1.10.2"
EOF
```
{{% notice tip %}}
We explicitly set the Config Management's `version` field with the current version. It's a best practice to do this, as you are responsible to manually upgrade this component as [new versions are coming](https://cloud.google.com/anthos-config-management/docs/release-notes). So you will be able to update this file accordingly in order to trigger the upgrade of Config Management with the new version.
{{% /notice %}}

{{% notice info %}}
We explicitly set the Policy Controller's `templateLibraryInstalled` field to `false`. Throughout this workshop, we will create our own `ConstraintTemplate` resources when needed. It will have two main benefits: first you will learn about how to create your own `ConstraintTemplate` (with OPA rego) and second, you we will be able to validate our Kubernetes resources against this . But be aware of this [default library of `ConstraintTemplate` resources](https://cloud.google.com/anthos-config-management/docs/reference/constraint-template-library) you could leverage as-is if you set this field to `true`.
{{% /notice %}}

## Deploy Kubernetes manifests

```Bash
cd ~/$GKE_PROJECT_DIR_NAME/
git add .
git commit -m "GitOps for GKE cluster configs"
git push
```

## Check deployments

Here is what you should have at this stage:

If you run:
```Bash
cd ~/$WORKSHOP_ORG_DIR_NAME && gh run list
```
You should see:
```Plaintext
FIXME
```

If you run:
```Bash
cd ~/$GKE_PROJECT_DIR_NAME && gh run list
```
You should see:
```Plaintext
FIXME
```

If you run:
```Bash
cd ~/$GKE_CONFIGS_DIR_NAME && gh run list
```
You should see:
```Plaintext
FIXME
```

If you run:
```Bash
gcloud alpha anthos config sync repo describe \
   --project $CONFIG_CONTROLLER_PROJECT_ID \
   --managed-resources all \
   --format="multi(statuses:format=none,managed_resources:format='table[box](group:sort=2,kind,name,namespace:sort=1)')"
```
You should see:
```Plaintext
FIXME
```

If you run:
```Bash
gcloud alpha anthos config sync repo describe \
   --project $GKE_PROJECT_ID \
   --managed-resources all \
   --format="multi(statuses:format=none,managed_resources:format='table[box](group:sort=2,kind,name,namespace:sort=1)')"
```
You should see:
```Plaintext
FIXME
```