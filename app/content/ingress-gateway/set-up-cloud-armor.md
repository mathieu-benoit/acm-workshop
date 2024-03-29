---
title: "Set up Cloud Armor"
weight: 3
description: "Duration: 10 min | Persona: Platform Admin"
tags: ["kcc", "platform-admin", "security-tips"]
---
![Platform Admin](https://github.com/mathieu-benoit/my-images/raw/main/acm-workshop/platform-admin.png)
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
    description: "SQL injection level 2"
    match:
      expr:
        expression: "evaluatePreconfiguredWaf('sqli-v33-canary', {'sensitivity': 2, 'opt_out_rule_ids': ['owasp-crs-v030301-id942200-sqli', 'owasp-crs-v030301-id942260-sqli', 'owasp-crs-v030301-id942430-sqli']})"
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
  - action: deny(403)
    description: "Remote code execution"
    match:
      expr:
        expression: "evaluatePreconfiguredExpr('rce-v33-canary')"
    priority: 5000
  - action: deny(403)
    description: "Method enforcement"
    match:
      expr:
        expression: "evaluatePreconfiguredExpr('methodenforcement-v33-canary')"
    priority: 6000
  - action: deny(403)
    description: "Scanner detection"
    match:
      expr:
        expression: "evaluatePreconfiguredExpr('scannerdetection-v33-canary')"
    priority: 7000
  - action: deny(403)
    description: "Protocol attack"
    match:
      expr:
        expression: "evaluatePreconfiguredExpr('protocolattack-v33-canary')"
    priority: 8000
  - action: deny(403)
    description: "PHP injection attack"
    match:
      expr:
        expression: "evaluatePreconfiguredExpr('php-v33-canary')"
    priority: 9000
  - action: deny(403)
    description: "Session fixation attack"
    match:
      expr:
        expression: "evaluatePreconfiguredExpr('sessionfixation-v33-canary')"
    priority: 10000
  - action: deny(403)
    description: "Java attack"
    match:
      expr:
        expression: "evaluatePreconfiguredExpr('java-v33-canary')"
    priority: 11000
  - action: deny(403)
    description: "NodeJS attack"
    match:
      expr:
        expression: "evaluatePreconfiguredExpr('nodejs-v33-canary')"
    priority: 12000
EOF
```
{{% notice info %}}
Here we are leveraging the [Cloud Armor preconfigured WAF rules](https://cloud.google.com/armor/docs/waf-rules): `xss`, `sqli`, `lfi`, `rfi`, `cve`, `rce`, `methodenforcement`, `scannerdetection`, `protocolattack`, `php`, `sessionfixation`, `java` and `nodejs`. All of them in `canary` version to have the latest version and ModSecurity Core Rule Set (CRS) 3.3. For `sqli`, we are only using sensitivity level 2 and exluding some of its rules, otherwise the Bank of Anthos is not working properly.
{{% /notice %}}

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
{{< tabs groupId="cs-status-ui">}}
{{% tab name="UI" %}}
Run this command and click on this link:
```Bash
echo -e "https://console.cloud.google.com/kubernetes/config_management/packages?project=${HOST_PROJECT_ID}"
```
Wait until you see the `Sync status` column as `Synced` and the `Reconcile status` column as `Current`.
{{% /tab %}}
{{% tab name="gcloud" %}}
Run this command:
```Bash
gcloud alpha anthos config sync repo describe \
    --project $HOST_PROJECT_ID \
    --managed-resources all \
    --sync-name repo-sync \
    --sync-namespace $TENANT_PROJECT_ID
```
Wait and re-run this command above until you see `"status": "SYNCED"`. All the `managed_resources` listed should have `STATUS: Current` too.
{{% /tab %}}
{{< /tabs >}}

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
