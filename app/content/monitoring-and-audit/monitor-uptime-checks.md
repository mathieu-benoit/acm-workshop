---
title: "Monitor uptime checks"
weight: 9
description: "Duration: 5 min | Persona: Platform Admin"
tags: ["monitoring", "platform-admin"]
---
![Platform Admin](/images/platform-admin.png)
_{{< param description >}}_

In this section, you will monitor the [uptime checks](https://cloud.google.com/monitoring/uptime-checks/introduction) defined earlier in this workshop.

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
```

In the Google Cloud console, navigate to _Monitoring > Uptime checks_ service. Click on the link displayed by the command below:
```Bash
echo -e "https://console.cloud.google.com/monitoring/uptime?project=${TENANT_PROJECT_ID}"
```

![Uptime checks overview](/images/uptime-checks-overview.png)

Then, you could select one of the uptime checks config to get more insights:

![Uptime checks for Bank of Anthos](/images/uptime-checks-bankofanthos.png)