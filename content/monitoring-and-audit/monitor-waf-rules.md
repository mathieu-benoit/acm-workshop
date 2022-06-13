---
title: "Monitor WAF rules"
weight: 6
description: "Duration: 5 min | Persona: Platform Admin"
tags: ["monitoring", "platform-admin", "security-tips"]
---
![Platform Admin](/images/platform-admin.png)
_{{< param description >}}_

In this section, you will [monitor Cloud Armor security policies logs](https://cloud.google.com/armor/docs/request-logging) (WAF rules).

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
```

Using logging, you can view every request evaluated by a Google Cloud Armor security policy and the outcome or action taken.

In the Google Cloud console, navigate to _Network Security > Cloud Armor_ service. Click on the link displayed by the command below:
```Bash
echo -e "https://pantheon.corp.google.com/net-security/securitypolicies/details/${SECURITY_POLICY_NAME}?project=${TENANT_PROJECT_ID}"
```

Select the **Logs** tab and click on **View policy logs**. From here, change _Last 1 hour_ by **Last 7 days** (top left) and enable the **Show query** toggle (top right):

![Cloud Armor logging](/images/cloud-armor-logging.png)

In the **Query** field you could add a new ligne with `jsonPayload.enforcedSecurityPolicy.outcome="DENY"` for example in order to see all the requests denied by the WAF rules you set up earlier in this workshop.

You could also leverage the `gcloud` command below to get such insights.

Run this command in Cloud Shell:
```Bash
filter="resource.type=\"http_load_balancer\" "\
"jsonPayload.enforcedSecurityPolicy.name=\"${SECURITY_POLICY_NAME}\" "\
"jsonPayload.enforcedSecurityPolicy.outcome=\"DENY\""

gcloud logging read --project $TENANT_PROJECT_ID "$filter"
```