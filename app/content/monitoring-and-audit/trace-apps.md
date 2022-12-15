---
title: "Trace apps"
weight: 4
description: "Duration: 5 min | Persona: Apps Operator"
tags: ["asm", "apps-operator", "monitoring"]
---
![Apps Operator](/images/apps-operator.png)
_{{< param description >}}_

In this section, you will trace your apps in order to follow a request through your Service Mesh, observe the network calls and profile your system end to end.

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
```

In the Google Cloud console, navigate to _Trace_ service. Click on the link displayed by the command below:
```Bash
echo -e "https://console.cloud.google.com/traces/list?project=${TENANT_PROJECT_ID}"
```

Select one of the Online Boutique's `frontend` app's requests:
![Anthos Service Mesh Monitoring overview](/images/cloud-trace.png)

From there you will have access to a lot more details about the different calls, trace logs, etc.