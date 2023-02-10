---
title: "Monitor resources synced"
weight: 7
description: "Duration: 5 min | Persona: Apps Operator"
tags: ["apps-operator", "gitops-tips", "monitoring"]
---
![Apps Operator](https://github.com/mathieu-benoit/my-images/raw/main/acm-workshop/apps-operator.png)
_{{< param description >}}_

In this section, in the Google Cloud Console you will monitor the resources synced by Config Sync for both the Config Controller instance in the Host project and the GKE cluster in the Tenant project.

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
```

## Monitor the resources synced by Config Sync in the Config Controller instance in the Host project

Click on the link displayed by the command below:
```Bash
echo -e "https://console.cloud.google.com/kubernetes/config_management/dashboard?project=${HOST_PROJECT_ID}"
```

On the default **Dashboard** tab, you will find something similar to:

![Config Sync Dashboard UI for Config Controller instance](https://github.com/mathieu-benoit/my-images/raw/main/acm-workshop/config-sync-dashboard-ui-config-controller.png)

Then if you go on the **Packages** tab, you will find something similar to:

![Config Sync Packages UI for Config Controller instance](https://github.com/mathieu-benoit/my-images/raw/main/acm-workshop/config-sync-packages-ui-config-controller.png)

## Monitor the resources synced by Config Sync in the GKE cluster in the Tenant project

Click on the link displayed by the command below:
```Bash
echo -e "https://console.cloud.google.com/kubernetes/config_management/dashboard?project=${TENANT_PROJECT_ID}"
```

On the default **Dashboard** tab, you will find something similar to:

![Config Sync Dashboard UI for GKE cluster](https://github.com/mathieu-benoit/my-images/raw/main/acm-workshop/config-sync-dashboard-ui-gke.png)

Then if you go on the **Packages** tab, you will find something similar to:

![Config Sync Packages UI for GKE cluster](https://github.com/mathieu-benoit/my-images/raw/main/acm-workshop/config-sync-packages-ui-gke.png)