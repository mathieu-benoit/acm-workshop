---
title: "Monitor policies violations"
weight: 8
description: "Duration: 5 min | Persona: Apps Operator"
tags: ["apps-operator", "monitoring", "security-tips"]
---
![Apps Operator](/images/apps-operator.png)
_{{< param description >}}_

In this section, in the Google Cloud Console you will monitor the Policy Controller's policies violations for the GKE cluster in the Tenant project.

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
```

Click on the link displayed by the command below:
```Bash
echo -e "https://console.cloud.google.com/kubernetes/policy_controller/dashboard?project=${TENANT_PROJECT_ID}"
```

On the default **Dashboard** tab, you will find something similar to:

![Policy Controller Dashboard UI for GKE cluster](/images/policy-controller-dashboard-ui-gke.png)

Then if you go on the **Violations** tab, you will find something similar to:

![Policy Controller Violations UI for GKE cluster](/images/policy-controller-violations-ui-gke.png)

At the end of the workshop, we have fixed all the violations, but here below is an example of how a violation shows up:

![Policy Controller Violations UI example for GKE cluster](/images/policy-controller-violations-ui-example-gke.png)