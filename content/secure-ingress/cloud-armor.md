---
title: "Configure Cloud Armor"
weight: 1
---

```Bash
export SECURITY_POLICY_NAME=$GKE_NAME-asm-ingressgateway
gcloud compute security-policies create $SECURITY_POLICY_NAME \
    --description "Block XSS attacks"
gcloud compute security-policies rules create 1000 \
    --security-policy $SECURITY_POLICY_NAME \
    --expression "evaluatePreconfiguredExpr('xss-stable')" \
    --action "deny-403" \
    --description "XSS attack filtering"
gcloud compute security-policies rules create 12345 \
    --security-policy $SECURITY_POLICY_NAME \
    --expression "evaluatePreconfiguredExpr('cve-canary')" \
    --action "deny-403" \
    --description "CVE-2021-44228 and CVE-2021-45046"
gcloud compute security-policies update $SECURITY_POLICY_NAME \
    --enable-layer7-ddos-defense
gcloud compute security-policies update $SECURITY_POLICY_NAME \
    --log-level=VERBOSE
export SSL_POLICY_NAME=$SECURITY_POLICY_NAME
gcloud compute ssl-policies create $SSL_POLICY_NAME \
    --profile COMPATIBLE  \
    --min-tls-version 1.0
```

Resources:
- [Google Cloud Armor WAF rule to help mitigate Apache Log4j vulnerability](https://cloud.google.com/blog/products/identity-security/cloud-armor-waf-rule-to-help-address-apache-log4j-vulnerability)