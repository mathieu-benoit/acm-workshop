---
title: "Browse ASM dashboard"
weight: 7
description: "Duration: 5 min | Persona: Platform Admin"
tags: ["asm", "monitoring", "platform-admin", "security-tips"]
---
![Platform Admin](/images/platform-admin.png)
_{{< param description >}}_

In this section, you will browse the Service Mesh dashboards in the Google Cloud console in order to get more insights for your applications in terms of topology, security, health and performance.

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
```

## Anthos Security view

In the Google Cloud console, you could navigate to _Anthos > Security > Policy Audit_ and filter by the `asm-ingress` `Namespace` to see that the 3 security features _Kubernetes Network policy_, _Service access control_ and _mTLS status_ are enabled in green:
![Anthos Security view in Google Cloud console for ASM Ingress Gateway](/images/asm-ingressgateway-anthos-security-view.png)

Click on the link displayed by the command below:
```Bash
echo -e "https://console.cloud.google.com/anthos/security/policy-summary?project=${TENANT_PROJECT_ID}"
```