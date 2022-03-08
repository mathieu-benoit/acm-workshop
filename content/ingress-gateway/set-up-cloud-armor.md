---
title: "Set up Cloud Armor"
weight: 3
---
- Persona: Platform Admin
- Duration: 10 min
- Objectives:
  - FIXME

Initialize variables:
```Bash
echo "export SECURITY_POLICY_NAME=${GKE_NAME}-asm-ingressgateway" >> ~/acm-workshop-variables.sh
echo "export SSL_POLICY_NAME=${SECURITY_POLICY_NAME}" >> ~/acm-workshop-variables.sh
source ~/acm-workshop-variables.sh
```

## Cloud Armor

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

Deploy this Cloud Armor rules resource via a GitOps approach:
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

## SSL policy

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

Deploy this SSL policy resource via a GitOps approach:
```Bash
cd ~/$GKE_PROJECT_DIR_NAME/
git add .
git commit -m "Ingress Gateway's SSL policy"
git push
```