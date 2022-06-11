---
title: "Browse ASM dashboard"
weight: 7
description: "Duration: 5 min | Persona: Apps Operator"
tags: ["asm", "apps-operator", "monitoring", "security-tips"]
---
![Apps Operator](/images/apps-operator.png)
_{{< param description >}}_

In this section, you will browse the Anthos Service Mesh dashboards in the Google Cloud console in order to get more insights for your applications in terms of topology, security, health and performance.

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
```

## Anthos Security

In the Google Cloud console, you could navigate to _Anthos > Security > Policy Audit_ and filter by the `onlineboutique` `Namespace` to see that the 3 security features _Kubernetes Network policy_, _Service access control_ and _mTLS status_ are enabled in green:

Click on the link displayed by the command below:
```Bash
echo -e "https://console.cloud.google.com/anthos/security/policy-summary?project=${TENANT_PROJECT_ID}"
```

Select the `onlineboutique` namespace on the **Policy audit** tab:
![Anthos Security view in Google Cloud console for Online Boutique](/images/onlineboutique-anthos-security-view.png)

Select the `frontend` **Workload** to open a more details view:
![Anthos Security details for Online Boutique frontend](/images/onlineboutique-frontend-anthos-security-details.png)

## ASM Monitoring

In the Google Cloud console, you could navigate to _Anthos > Service Mesh > Topology_ to see the topology graph of the Online Boutique apps:
![Anthos Service Mesh Topology view for Online Boutique](/images/onlineboutique-service-mesh-topology.png)

Click on the link displayed by the command below:
```Bash
echo -e "https://console.cloud.google.com/anthos/services?project=${TENANT_PROJECT_ID}&pageState=%28%22topologyViewToggle%22:%28%22value%22:%22graph%22%29%29"
```

Select the `frontend` app and select **--> Go to service dashboard**:
![Anthos Service Mesh Monitoring overview for Online Boutique frontend](/images/onlineboutique-frontend-service-mesh-monitoring-overview.png)

From there you will have access to a lot more monitoring features out of the box, feel free to discover these features and play with them.

One feature to call out is the **Security** tab where you could get more insights about the `AuthorizationPolicy` of the `frontend` app:
![Anthos Service Mesh Monitoring security for Online Boutique frontend](/images/onlineboutique-frontend-service-mesh-monitoring-security.png)