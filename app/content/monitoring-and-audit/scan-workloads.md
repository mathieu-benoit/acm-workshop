---
title: "Scan workloads"
weight: 6
description: "Duration: 5 min | Persona: Apps Operator"
tags: ["apps-operator", "monitoring", "security-tips"]
---
![Apps Operator](https://github.com/mathieu-benoit/my-images/raw/main/acm-workshop/apps-operator.png)
_{{< param description >}}_

In this section, you will monitor security scanning of your GKE workloads configurations in the Google Cloud console in order to leverage these two features:
- [Scan workloads for configuration issues](https://cloud.google.com/kubernetes-engine/docs/how-to/protect-workload-configuration)
- [Scan container images for known vulnerabilities](https://cloud.google.com/kubernetes-engine/docs/how-to/security-posture-vulnerability-scanning)

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
```

In the Google Cloud console, navigate to _Kubernetes Engine > Security Posture_, click on the link displayed by the command below:
```Bash
echo -e "https://console.cloud.google.com/kubernetes/security/dashboard?project=${TENANT_PROJECT_ID}"
```

On the default **Dashboard** tab, find the **GKE Posture settings** tile. And for both features **Workload configuration audit** and **Workload vulnerability audit**, click on one of the **Seclect clusters** button, select your GKE cluster and click on the **Turn on audit** button.

![Enable GKE Security Posture](https://github.com/mathieu-benoit/my-images/raw/main/acm-workshop/gke-security-posture-enablement.png)

Then you have to wait a little bit while these features are being enabled on your GKE cluster and eventually the audit will start:

> Audit in progress. It can take up to 15 minutes to complete.

When the audit is done, you will be able to see the report of the vulnerabilities found. The **Workload configuration audit** will come first, **Workload vulnerability audit** will be generated later. 

![GKE Security Posture report](https://github.com/mathieu-benoit/my-images/raw/main/acm-workshop/gke-security-posture-report.png)

You will also be able to see in details the associated concerns:

![GKE Security Posture concerns](https://github.com/mathieu-benoit/my-images/raw/main/acm-workshop/gke-security-posture-concerns.png)