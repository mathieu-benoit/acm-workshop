---
title: "Set up Cloud Armor"
weight: 3
description: "Duration: 10 min | Persona: Platform Admin"
tags: ["kcc", "platform-admin", "security-tips"]
---
![Platform Admin](/images/platform-admin.png)
_{{< param description >}}_

In this section, you will set up Cloud Armor preconfigured WAF rules such as: SQL injection, local/remote file inclusion, etc.

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
SECURITY_POLICY_NAME=$GKE_NAME-asm-ingressgateway
echo "export SECURITY_POLICY_NAME=${SECURITY_POLICY_NAME}" >> ${WORK_DIR}acm-workshop-variables.sh
echo "export SSL_POLICY_NAME=${SECURITY_POLICY_NAME}" >> ${WORK_DIR}acm-workshop-variables.sh
source ${WORK_DIR}acm-workshop-variables.sh
```

## Define Cloud Armor rules

Define the Ingress Gateway's [Cloud Armor rules](https://cloud.google.com/config-connector/docs/reference/resource-docs/compute/computesecuritypolicy):
```Bash
cat <<EOF > ${WORK_DIR}$TENANT_PROJECT_DIR_NAME/cloud-armor.yaml
apiVersion: compute.cnrm.cloud.google.com/v1beta1
kind: ComputeSecurityPolicy
metadata:
  annotations:
    cnrm.cloud.google.com/project-id: ${TENANT_PROJECT_ID}
  name: ${SECURITY_POLICY_NAME}
  namespace: ${TENANT_PROJECT_ID}
spec:
  adaptiveProtectionConfig:
    layer7DdosDefenseConfig:
      enable: true
  advancedOptionsConfig:
    logLevel: VERBOSE
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
        expression: "evaluatePreconfiguredExpr('xss-v33-canary')"
    priority: 1000
  - action: deny(403)
    description: "SQL injection levels 1 and 2"
    match:
      expr:
        expression: "evaluatePreconfiguredExpr('sqli-v33-canary', ['owasp-crs-v030301-id942251-sqli', 'owasp-crs-v030301-id942490-sqli', 'owasp-crs-v030301-id942420-sqli', 'owasp-crs-v030301-id942431-sqli', 'owasp-crs-v030301-id942460-sqli', 'owasp-crs-v030301-id942511-sqli', 'owasp-crs-v030301-id942421-sqli', 'owasp-crs-v030301-id942432-sqli'])"
    priority: 2000
  - action: deny(403)
    description: "Local file inclusion"
    match:
      expr:
        expression: "evaluatePreconfiguredExpr('lfi-v33-canary')"
    priority: 3000
  - action: deny(403)
    description: "Remote file inclusion"
    match:
      expr:
        expression: "evaluatePreconfiguredExpr('rfi-v33-canary')"
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

## Define SSL policy

Not directly related to Cloud Armor, but let's define an [SSL policy](https://cloud.google.com/config-connector/docs/reference/resource-docs/compute/computesslpolicy) which will allow us to set an HTTP to HTTPS redirect on the `Ingress`.

```Bash
cat <<EOF > ${WORK_DIR}$TENANT_PROJECT_DIR_NAME/ssl-policy.yaml
apiVersion: compute.cnrm.cloud.google.com/v1beta1
kind: ComputeSSLPolicy
metadata:
  annotations:
    cnrm.cloud.google.com/project-id: ${TENANT_PROJECT_ID}
  name: ${SSL_POLICY_NAME}
  namespace: ${TENANT_PROJECT_ID}
spec:
  minTlsVersion: TLS_1_0
  profile: COMPATIBLE
EOF
```

## Deploy Kubernetes manifests

```Bash
cd ${WORK_DIR}$TENANT_PROJECT_DIR_NAME/
git add . && git commit -m "Ingress Gateway's Cloud Armor rules and SSL policy" && git push origin main
```

## Check deployments

{{< mermaid >}}
graph TD;
  ComputeSecurityPolicy-.->Project
  ComputeSSLPolicy-.->Project
{{< /mermaid >}}

List the Kubernetes resources managed by Config Sync in **Config Controller** for the **Tenant project configs** repository:
```Bash
gcloud alpha anthos config sync repo describe \
    --project $HOST_PROJECT_ID \
    --managed-resources all \
    --sync-name repo-sync \
    --sync-namespace $TENANT_PROJECT_ID
```
Wait and re-run this command above until you see `"status": "SYNCED"`. All the `managed_resources` listed should have `STATUS: Current` as well.

List the GitHub runs for the **Tenant project configs** repository:
```Bash
cd ${WORK_DIR}$TENANT_PROJECT_DIR_NAME && gh run list
```

List the Google Cloud resources created:
```Bash
gcloud compute security-policies list \
    --project $TENANT_PROJECT_ID
gcloud compute ssl-policies list \
    --project $TENANT_PROJECT_ID
```
Wait and re-run this command above until you see the resources created.
