---
title: "Deploy NetworkPolicies"
weight: 3
description: "Duration: 5 min | Persona: Apps Operator"
tags: ["apps-operator", "security-tips"]
---
![Apps Operator](/images/apps-operator.png)
_{{< param description >}}_

In this section, you will deploy granular and specific `NetworkPolicies` for the Bank of Anthos namespace. This will fix the policies violation you faced earlier.

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
```

## Create base overlay

Create Kustomize base overlay files:
```Bash
mkdir ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME/base
cd ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME/base
kustomize create
```

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

## Define Staging namespace overlay

```Bash
cd ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME/staging
kustomize edit add resource ../base
kustomize edit set namespace $BANKOFANTHOS_NAMESPACE
```
{{% notice info %}}
The `kustomization.yaml` file was already existing from the [GitHub repository template](https://github.com/mathieu-benoit/config-sync-app-template-repo/blob/main/staging/kustomization.yaml) used when we created the **Bank of Anthos app** repository.
{{% /notice %}}

## Deploy Kubernetes manifests

```Bash
cd ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME/
git add . && git commit -m "Bank of Anthos NetworkPolicies" && git push origin main
```

## Check deployments

List the Kubernetes resources managed by Config Sync in **GKE cluster** for the **Bank of Anthos apps** repository:
{{< tabs groupId="cs-status-ui">}}
{{% tab name="gcloud" %}}
```Bash
gcloud alpha anthos config sync repo describe \
    --project $TENANT_PROJECT_ID \
    --managed-resources all \
    --sync-name repo-sync \
    --sync-namespace $BANKOFANTHOS_NAMESPACE
```
Wait and re-run this command above until you see `"status": "SYNCED"`.
{{% /tab %}}
{{% tab name="UI" %}}
Alternatively, you could also see this from within the Cloud Console, by clicking on this link:
```Bash
echo -e "https://console.cloud.google.com/kubernetes/config_management/status?clusterName=${GKE_NAME}&id=${GKE_NAME}&project=${TENANT_PROJECT_ID}"
```
Wait until you see the `Sync status` column as `SYNCED`. And then you can also click on `View resources` to see the details.
{{% /tab %}}
{{< /tabs >}}

The `namespaces-required-networkpolicies` `Constraint` shouldn't complain anymore. Click on the link displayed by the command below:
```Bash
echo -e "https://console.cloud.google.com/kubernetes/object/constraints.gatekeeper.sh/k8srequirenamespacenetworkpolicies/${GKE_LOCATION}/${GKE_NAME}/namespaces-required-networkpolicies?apiVersion=v1beta1&project=${TENANT_PROJECT_ID}"
```

At the very bottom of the object's description you should now see:
```Plaintext
...
totalViolations: 0
```

List the GitHub runs for the **Bank of Anthos apps** repository:
```Bash
cd ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME && gh run list
```