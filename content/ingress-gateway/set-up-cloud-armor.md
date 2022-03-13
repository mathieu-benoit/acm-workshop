---
title: "Set up Cloud Armor"
weight: 3
description: "Duration: 10 min | Persona: Platform Admin"
---
_{{< param description >}}_

Initialize variables:
```Bash
source ~/acm-workshop-variables.sh
SECURITY_POLICY_NAME=$GKE_NAME-asm-ingressgateway
echo "export SECURITY_POLICY_NAME=${SECURITY_POLICY_NAME}" >> ~/acm-workshop-variables.sh
echo "export SSL_POLICY_NAME=${SECURITY_POLICY_NAME}" >> ~/acm-workshop-variables.sh
source ~/acm-workshop-variables.sh
```

## Define Cloud Armor rules

https://cloud.google.com/config-connector/docs/reference/resource-docs/compute/computesecuritypolicy

Define the Ingress Gateway's Cloud Armor rules:
```Bash
cat <<EOF > ~/$GKE_PROJECT_DIR_NAME/config-sync/cloud-armor.yaml
apiVersion: compute.cnrm.cloud.google.com/v1beta1
kind: ComputeSecurityPolicy
metadata:
  name: ${SECURITY_POLICY_NAME}
  namespace: ${GKE_PROJECT_ID}
spec:
  adaptiveProtectionConfig:
    layer7DdosDefenseConfig:
      enable: true
  rule:
  - action: allow
    description: "Default rule"
    match:
      versionedExpr: SRC_IPS_V1
      config:
        srcIpRanges:
        - "*"
    priority: 2147483647
  - action: deny(403)
    description: "XSS"
    match:
      expr:
        expression: "evaluatePreconfiguredExpr('xss-stable')"
    priority: 1000
  - action: deny(403)
    description: "SQL injection levels 1 and 2"
    match:
      expr:
        expression: "evaluatePreconfiguredExpr('sqli-stable', ['owasp-crs-v030001-id942251-sqli', 'owasp-crs-v030001-id942420-sqli', 'owasp-crs-v030001-id942431-sqli', 'owasp-crs-v030001-id942460-sqli', 'owasp-crs-v030001-id942421-sqli', 'owasp-crs-v030001-id942432-sqli'])"
    priority: 2000
  - action: deny(403)
    description: "Local file inclusion"
    match:
      expr:
        expression: "evaluatePreconfiguredExpr('lfi-stable')"
    priority: 3000
  - action: deny(403)
    description: "Remote file inclusion"
    match:
      expr:
        expression: "evaluatePreconfiguredExpr('rfi-stable')"
    priority: 4000
  - action: deny(403)
    description: "CVE-2021-44228 and CVE-2021-45046"
    match:
      expr:
        expression: "evaluatePreconfiguredExpr('cve-canary')"
    priority: 12345
EOF
```

https://cloud.google.com/armor/docs/rule-tuning#preconfigured_rules

## Deploy Kubernetes manifests

```Bash
cd ~/$GKE_PROJECT_DIR_NAME/
git add .
git commit -m "Ingress Gateway's Cloud Armor rules"
git push
```

```Bash
gcloud compute security-policies update ${SECURITY_POLICY_NAME} \
  --project ${GKE_PROJECT_ID}
  --log-level=VERBOSE
```

## Define SSL policy

Not directly related to Cloud Armor, but let's define an SSL policy which will allow us to set an HTTP to HTTPS redirect on the `Ingress`.

```Bash
cat <<EOF > ~/$GKE_PROJECT_DIR_NAME/config-sync/ssl-policy.yaml
apiVersion: compute.cnrm.cloud.google.com/v1beta1
kind: ComputeSSLPolicy
metadata:
  name: ${SSL_POLICY_NAME}
  namespace: ${GKE_PROJECT_ID}
spec:
  minTlsVersion: TLS_1_0
  profile: COMPATIBLE
EOF
```

## Deploy Kubernetes manifests

```Bash
cd ~/$GKE_PROJECT_DIR_NAME/
git add .
git commit -m "Ingress Gateway's SSL policy"
git push
```

## Check deployments

List the GCP resources created:
```Bash
gcloud compute security-policies list \
    --project $GKE_PROJECT_ID
gcloud compute ssl-policies list \
    --project $GKE_PROJECT_ID
```
```Plaintext
NAME
gke-asm-ingressgateway
NAME                    PROFILE     MIN_TLS_VERSION
gke-asm-ingressgateway  COMPATIBLE  TLS_1_0
```

List the GitHub runs for the **GKE project configs** repository `cd ~/$GKE_PROJECT_DIR_NAME && gh run list`:
```Plaintext
STATUS  NAME                                                                                              WORKFLOW  BRANCH  EVENT  ID          ELAPSED  AGE
✓       Ingress Gateway's SSL policy                                                                      ci        main    push   1975187062  53s      13m
✓       Ingress Gateway's public static IP address                                                        ci        main    push   1974996579  59s      1h
✓       ASM MCP for GKE project                                                                           ci        main    push   1972180913  8m20s    23h
✓       GitOps for GKE cluster configs                                                                    ci        main    push   1970974465  53s      1d
✓       GKE cluster, primary nodepool and SA for GKE project                                              ci        main    push   1963473275  1m16s    2d
✓       Network for GKE project                                                                           ci        main    push   1961289819  1m13s    2d
✓       Initial commit                                                                                    ci        main    push   1961170391  56s      2d
```

List the Kubernetes resources managed by Config Sync in **Config Controller** for the **GKE project configs** repository:
```Bash
gcloud alpha anthos config sync repo describe \
    --project $CONFIG_CONTROLLER_PROJECT_ID \
    --managed-resources all \
    --format="multi(statuses:format=none,managed_resources:format='table[box](group:sort=2,kind,name,namespace:sort=1)')" \
    --sync-name repo-sync \
    --sync-namespace $GKE_PROJECT_ID
```
```Plaintext
getting 1 RepoSync and RootSync from krmapihost-configcontroller
┌────────────────────────────────────────┬────────────────────────────┬───────────────────────────────────────────┬──────────────────────┐
│                 GROUP                  │            KIND            │                    NAME                   │      NAMESPACE       │
├────────────────────────────────────────┼────────────────────────────┼───────────────────────────────────────────┼──────────────────────┤
│ artifactregistry.cnrm.cloud.google.com │ ArtifactRegistryRepository │ containers                                │ acm-workshop-464-gke │
│ compute.cnrm.cloud.google.com          │ ComputeSecurityPolicy      │ gke-asm-ingressgateway                    │ acm-workshop-464-gke │
│ compute.cnrm.cloud.google.com          │ ComputeRouter              │ gke                                       │ acm-workshop-464-gke │
│ compute.cnrm.cloud.google.com          │ ComputeSSLPolicy           │ gke-asm-ingressgateway                    │ acm-workshop-464-gke │
│ compute.cnrm.cloud.google.com          │ ComputeSubnetwork          │ gke                                       │ acm-workshop-464-gke │
│ compute.cnrm.cloud.google.com          │ ComputeRouterNAT           │ gke                                       │ acm-workshop-464-gke │
│ compute.cnrm.cloud.google.com          │ ComputeAddress             │ gke-asm-ingressgateway                    │ acm-workshop-464-gke │
│ compute.cnrm.cloud.google.com          │ ComputeNetwork             │ gke                                       │ acm-workshop-464-gke │
│ container.cnrm.cloud.google.com        │ ContainerNodePool          │ primary                                   │ acm-workshop-464-gke │
│ container.cnrm.cloud.google.com        │ ContainerCluster           │ gke                                       │ acm-workshop-464-gke │
│ gkehub.cnrm.cloud.google.com           │ GKEHubFeature              │ gke-acm                                   │ acm-workshop-464-gke │
│ gkehub.cnrm.cloud.google.com           │ GKEHubFeatureMembership    │ gke-acm-membership                        │ acm-workshop-464-gke │
│ gkehub.cnrm.cloud.google.com           │ GKEHubFeature              │ gke-asm                                   │ acm-workshop-464-gke │
│ gkehub.cnrm.cloud.google.com           │ GKEHubMembership           │ gke-hub-membership                        │ acm-workshop-464-gke │
│ iam.cnrm.cloud.google.com              │ IAMPartialPolicy           │ gke-primary-pool-sa-cs-monitoring-wi-user │ acm-workshop-464-gke │
│ iam.cnrm.cloud.google.com              │ IAMServiceAccount          │ gke-primary-pool                          │ acm-workshop-464-gke │
│ iam.cnrm.cloud.google.com              │ IAMPolicyMember            │ log-writer                                │ acm-workshop-464-gke │
│ iam.cnrm.cloud.google.com              │ IAMPolicyMember            │ monitoring-viewer                         │ acm-workshop-464-gke │
│ iam.cnrm.cloud.google.com              │ IAMPolicyMember            │ metric-writer                             │ acm-workshop-464-gke │
│ iam.cnrm.cloud.google.com              │ IAMPolicyMember            │ artifactregistry-reader                   │ acm-workshop-464-gke │
└────────────────────────────────────────┴────────────────────────────┴───────────────────────────────────────────┴──────────────────────┘
```