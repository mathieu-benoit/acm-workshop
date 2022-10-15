---
title: "Monitor apps security"
weight: 2
description: "Duration: 5 min | Persona: Apps Operator"
tags: ["apps-operator", "asm", "monitoring", "security-tips"]
---
![Apps Operator](/images/apps-operator.png)
_{{< param description >}}_

In this section, you will monitor security features such as Network Policies and Service requests of your apps in the Google Cloud console.

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
```

In the Google Cloud console, navigate to [_Anthos > Security > Policy Audit_](https://cloud.google.com/anthos/docs/concepts/security-monitoring) and filter for example by `onlineboutique` `Namespace` to see that the 3 security features _Kubernetes Network policy_, _Service access control_ and _mTLS status_ are enabled in green:

Click on the link displayed by the command below:
```Bash
echo -e "https://console.cloud.google.com/anthos/security/policy-summary?project=${TENANT_PROJECT_ID}"
```

Select the `onlineboutique` `Namespace` on the **Policy audit** tab:
![Anthos Security overview for Online Boutique](/images/anthos-security-view.png)

Select the `frontend` **Workload** to open a more detailed view:
![Anthos Security details for Online Boutique](/images/anthos-security-details.png)

From this view you could gain more visibility about **Inbound denials** or **Outbound denials** for both **Network policy requests** (`NetworkPolicies`) or **Service requests** (`AuthorizationPolicies`).

You could explore the `whereami` or `asm-ingress` `Namespace` too.