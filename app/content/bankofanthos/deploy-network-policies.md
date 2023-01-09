---
title: "Deploy NetworkPolicies"
weight: 7
description: "Duration: 5 min | Persona: Apps Operator"
tags: ["apps-operator", "policies", "security-tips"]
---
![Apps Operator](/images/apps-operator.png)
_{{< param description >}}_

In this section, you will see the Policy Controller violation regarding to the missing `NetworkPolicies` in the Bank of Anthos namespace. Then, you will fix this violation by deploying the associated resources.

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
```

## See the Policy Controller violations

See the Policy Controller violations in the **GKE cluster**, by running this command and click on this link:
```Bash
echo -e "https://console.cloud.google.com/kubernetes/policy_controller/dashboard?project=${TENANT_PROJECT_ID}"
```

You will see that the `K8sRequireNamespaceNetworkPolicies` `Constraint` has this violation: `Namespace <bankofanthos> does not have a NetworkPolicy`.

Let's fix it!

## Define NetworkPolicies for the Bank of Anthos apps

Define a fine granular `NetworkPolicy`:
```Bash
mkdir ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME/base/networkpolicies
cat <<EOF > ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME/base/networkpolicies/networkpolicy_deny-all.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
EOF
cat <<EOF > ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME/base/networkpolicies/networkpolicy_accounts-db.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: accounts-db
spec:
  egress:
  - {}
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: contacts
    - podSelector:
        matchLabels:
          app: userservice
    ports:
    - port: 5432
      protocol: TCP
  podSelector:
    matchLabels:
      app: accounts-db
  policyTypes:
  - Ingress
  - Egress
EOF
cat <<EOF > ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME/base/networkpolicies/networkpolicy_balancereader.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: balancereader
spec:
  egress:
  - {}
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    - podSelector:
        matchLabels:
          app: ledgerwriter
    ports:
    - port: 8080
      protocol: TCP
  podSelector:
    matchLabels:
      app: balancereader
  policyTypes:
  - Ingress
  - Egress
EOF
cat <<EOF > ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME/base/networkpolicies/networkpolicy_contacts.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: contacts
spec:
  egress:
  - {}
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - port: 8080
      protocol: TCP
  podSelector:
    matchLabels:
      app: contacts
  policyTypes:
  - Ingress
  - Egress
EOF
cat <<EOF > ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME/base/networkpolicies/networkpolicy_frontend.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: frontend
spec:
  egress:
  - {}
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: loadgenerator
    - namespaceSelector:
        matchLabels:
          name: ${INGRESS_GATEWAY_NAMESPACE}
      podSelector:
        matchLabels:
          app: ${INGRESS_GATEWAY_NAME}
    ports:
    - port: 8080
      protocol: TCP
  podSelector:
    matchLabels:
      app: frontend
  policyTypes:
  - Ingress
  - Egress
EOF
cat <<EOF > ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME/base/networkpolicies/networkpolicy_ledger-db.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ledger-db
spec:
  egress:
  - {}
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: ledgerwriter
    - podSelector:
        matchLabels:
          app: balancereader
    - podSelector:
        matchLabels:
          app: transactionhistory
    ports:
    - port: 5432
      protocol: TCP
  podSelector:
    matchLabels:
      app: ledger-db
  policyTypes:
  - Ingress
  - Egress
EOF
cat <<EOF > ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME/base/networkpolicies/networkpolicy_ledgerwriter.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ledgerwriter
spec:
  egress:
  - {}
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - port: 8080
      protocol: TCP
  podSelector:
    matchLabels:
      app: ledgerwriter
  policyTypes:
  - Ingress
  - Egress
EOF
cat <<EOF > ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME/base/networkpolicies/networkpolicy_loadgenerator.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: loadgenerator
spec:
  egress:
  - {}
  podSelector:
    matchLabels:
      app: loadgenerator
  policyTypes:
  - Egress
EOF
cat <<EOF > ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME/base/networkpolicies/networkpolicy_transactionhistory.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: transactionhistory
spec:
  egress:
  - {}
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - port: 8080
      protocol: TCP
  podSelector:
    matchLabels:
      app: transactionhistory
  policyTypes:
  - Ingress
  - Egress
EOF
cat <<EOF > ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME/base/networkpolicies/networkpolicy_userservice.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: userservice
spec:
  egress:
  - {}
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - port: 8080
      protocol: TCP
  podSelector:
    matchLabels:
      app: userservice
  policyTypes:
  - Ingress
  - Egress
EOF
```

Update the Kustomize base overlay:
```Bash
cd ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME/base/networkpolicies
kustomize create --autodetect
cd ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME/base
kustomize edit add resource networkpolicies
```

## Deploy Kubernetes manifests

```Bash
cd ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME/
git add . && git commit -m "Bank of Anthos NetworkPolicies" && git push origin main
```

## Check deployments

List the Kubernetes resources managed by Config Sync in **GKE cluster** for the **Bank of Anthos apps** repository:
{{< tabs groupId="cs-status-ui">}}
{{% tab name="UI" %}}
Run this command and click on this link:
```Bash
echo -e "https://console.cloud.google.com/kubernetes/config_management/packages?project=${TENANT_PROJECT_ID}"
```
Wait until you see the `Sync status` column as `Synced` and the `Reconcile status` column as `Current`.
{{% /tab %}}
{{% tab name="gcloud" %}}
Run this command:
```Bash
gcloud alpha anthos config sync repo describe \
    --project $TENANT_PROJECT_ID \
    --managed-resources all \
    --sync-name repo-sync \
    --sync-namespace $BANKOFANTHOS_NAMESPACE
```
Wait and re-run this command above until you see `"status": "SYNCED"`.
{{% /tab %}}
{{< /tabs >}}

See the Policy Controller `Constraints` without any violations in the **GKE cluster**, by running this command and click on this link:
```Bash
echo -e "https://console.cloud.google.com/kubernetes/policy_controller/dashboard?project=${TENANT_PROJECT_ID}"
```

List the GitHub runs for the **Bank of Anthos apps** repository:
```Bash
cd ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME && gh run list
```

## Check the Bank of Anthos website

Navigate to the Bank of Anthos website, click on the link displayed by the command below:
```Bash
echo -e "https://${BANK_OF_ANTHOS_INGRESS_GATEWAY_HOST_NAME}"
```

You should still have the Bank of Anthos website working successfully.