---
title: "Browse ASM dashboard"
weight: 7
description: "Duration: 5 min | Persona: Apps Operator"
---
![Apps Operator](/images/apps-operator.png)
_{{< param description >}}_

In this section, you will browse the Anthos Servie Mesh dashboards in the Google Cloud console in order to get more insights for your applications in terms of topology, security, health and performance.

## Anthos Security view

In the Google Cloud console, you could navigate to _Anthos > Security > Policy Audit_ and filter by the `whereami` namespace to see that the 3 security features _Kubernetes Network policy_, _Service access control_ and _mTLS status_ are enabled in green:
![Anthos Security view in Google Cloud console for Whereami](/images/whereami-anthos-security-view.png)

Click on the link displayed by the command below:
```Bash
echo -e "https://console.cloud.google.com/anthos/security/policy-summary?project=${TENANT_PROJECT_ID}"
```

## ASM Topology

In the Google Cloud console, you could navigate to _Anthos > Service Mesh > Topology_ to see the topology graph of the Whereami app:
![Anthos Service Mesh Topology view in Google Cloud console for Whereami](/images/whereami-service-mesh-topology.png)

Click on the link displayed by the command below:
```Bash
echo -e "https://console.cloud.google.com/anthos/services?project=${TENANT_PROJECT_ID}&pageState=%28%22topologyViewToggle%22:%28%22value%22:%22graph%22%29%29"
```