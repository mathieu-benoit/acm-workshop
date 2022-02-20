---
title: "Set up GKE configs's Git repo"
weight: 3
---

- Persona: Platform Admin
- Duration: 10 min
- Objectives:
  - FIXME

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
_Note: The `resourceID` must be `configmanagement` if you want to use Anthos Config Management feature._

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

```Bash
GKE_CONFIGS_DIR_NAME=workshop-gke-configs-repo
cd ~
gh repo create $GKE_CONFIGS_DIR_NAME --public --clone --template https://github.com/mathieu-benoit/config-sync-template-repo
cd $GKE_CONFIGS_DIR_NAME
git pull
git checkout main
GKE_CONFIG_REPO_URL=$(gh repo view --json url --jq .url)
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
        syncRepo: ${GKE_CONFIG_REPO_URL}
    policyController:
      enabled: true
      referentialRulesEnabled: false
      logDeniesEnabled: true
      templateLibraryInstalled: true
EOF
```

{{< tabs groupId="commit">}}
{{% tab name="git commit" %}}
```Bash
cd ~/$GKE_PROJECT_DIR_NAME/
git add .
git commit -m "Set up GKE configs's Git repo"
git push
```
{{% /tab %}}
{{% tab name="kubectl apply" %}}
```Bash
cd ~/$GKE_PROJECT_DIR_NAME/
kubectl apply -f .
```
{{% /tab %}}
{{< /tabs >}}