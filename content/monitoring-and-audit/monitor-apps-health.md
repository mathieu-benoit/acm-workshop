---
title: "Monitor apps health"
weight: 4
description: "Duration: 5 min | Persona: Apps Operator"
tags: ["asm", "apps-operator", "monitoring", "security-tips"]
---
![Apps Operator](/images/apps-operator.png)
_{{< param description >}}_

In this section, you will navigate to the topology of your Service Mesh as well as monitor your apps in terms of security, health and performance.

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
```

In the Google Cloud console, navigate to _Anthos > Service Mesh > Topology_ to see the topology graph of your Service Mesh:
![Anthos Service Mesh Topology view](/images/service-mesh-topology.png)

Click on the link displayed by the command below:
```Bash
echo -e "https://console.cloud.google.com/anthos/services?project=${TENANT_PROJECT_ID}&pageState=%28%22topologyViewToggle%22:%28%22value%22:%22graph%22%29%29"
```

Select the Online Boutique's `frontend` app. On your right, click on **--> Go to service dashboard**:
![Anthos Service Mesh Monitoring overview](/images/service-mesh-monitoring-overview.png)

On the left, click the **Metrics** tab where you could get more insights about the [golden signals](https://sre.google/sre-book/monitoring-distributed-systems/#xref_monitoring_golden-signals) of the `frontend` app:
![Anthos Service Mesh Monitoring metrics](/images/service-mesh-monitoring-metrics.png)

On the left, click the **Security** tab where you could get more insights about the **Service requests** (`AuthorizationPolicy`) of the `frontend` app:
![Anthos Service Mesh Monitoring security](/images/service-mesh-monitoring-security.png)

From there you will have access to a lot more monitoring features out of the box, feel free to discover these features and play with them for the different apps in your Service Mesh.