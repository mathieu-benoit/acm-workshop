---
title: "Deploy AuthorizationPolicies"
weight: 6
description: "Duration: 5 min | Persona: Apps Operator"
tags: ["apps-operator", "asm", "security-tips"]
---
![Apps Operator](/images/apps-operator.png)
_{{< param description >}}_

In this section, you will see how to track the `AuthorizationPolicies` issue and then you will deploy granular and specific `ServiceAccounts` and `AuthorizationPolicies` for the Bank of Anthos namespace to fix this issue.

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
```

## See the `AuthorizationPolicies` issue

See the `AuthorizationPolicies` issue in the **GKE cluster** for the Bank of Anthos namespace, by running this command and click on this link:
```Bash
echo -e "https://console.cloud.google.com/anthos/security/workload-view/Deployment/${GKE_LOCATION}/${GKE_NAME}/${BANKOFANTHOS_NAMESPACE}/frontend?project=${TENANT_PROJECT_ID}"
```

Under the **Service requests** section on this page, you will see some **Inbound denials**. If you click on **View logs** you will be able to see via Cloud Logging the details of the errors. That's where you will the logs with `status: 403` and `response_details: "AuthzDenied"`.

Let's fix it!

## Define `ServiceAccounts`

```Bash
mkdir ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME/base/serviceaccounts
cat <<EOF > ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME/base/serviceaccounts/serviceaccount_accounts-db.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: accounts-db
EOF
cat <<EOF > ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME/base/serviceaccounts/serviceaccount_balancereader.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: balancereader
EOF
cat <<EOF > ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME/base/serviceaccounts/serviceaccount_contacts.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: contacts
EOF
cat <<EOF > ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME/base/serviceaccounts/serviceaccount_frontend.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: frontend
EOF
cat <<EOF > ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME/base/serviceaccounts/serviceaccount_ledger-db.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ledger-db
EOF
cat <<EOF > ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME/base/serviceaccounts/serviceaccount_ledgerwriter.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ledgerwriter
EOF
cat <<EOF > ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME/base/serviceaccounts/serviceaccount_loadgenerator.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: loadgenerator
EOF
cat <<EOF > ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME/base/serviceaccounts/serviceaccount_transactionhistory.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: transactionhistory
EOF
cat <<EOF > ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME/base/serviceaccounts/serviceaccount_userservice.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: userservice
EOF
cat <<EOF > ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME/base/serviceaccounts/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1alpha1
kind: Component
resources:
- serviceaccount_accounts-db.yaml
- serviceaccount_balancereader.yaml
- serviceaccount_contacts.yaml
- serviceaccount_frontend.yaml
- serviceaccount_ledger-db.yaml
- serviceaccount_ledgerwriter.yaml
- serviceaccount_loadgenerator.yaml
- serviceaccount_transactionhistory.yaml
- serviceaccount_userservice.yaml
EOF
```

## Update `ServiceAccounts` in `Deployments`

```Bash
cat <<EOF >> ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME/base/serviceaccounts/kustomization.yaml
patchesJson6902:
- target:
    kind: StatefulSet
    name: accounts-db
  patch: |-
    - op: replace
      path: /spec/template/spec/serviceAccountName
      value: accounts-db
- target:
    kind: Deployment
    name: balancereader
  patch: |-
    - op: replace
      path: /spec/template/spec/serviceAccountName
      value: balancereader
- target:
    kind: Deployment
    name: contacts
  patch: |-
    - op: replace
      path: /spec/template/spec/serviceAccountName
      value: contacts
- target:
    kind: Deployment
    name: frontend
  patch: |-
    - op: replace
      path: /spec/template/spec/serviceAccountName
      value: frontend
- target:
    kind: StatefulSet
    name: ledger-db
  patch: |-
    - op: replace
      path: /spec/template/spec/serviceAccountName
      value: ledger-db
- target:
    kind: Deployment
    name: ledgerwriter
  patch: |-
    - op: replace
      path: /spec/template/spec/serviceAccountName
      value: ledgerwriter
- target:
    kind: Deployment
    name: loadgenerator
  patch: |-
    - op: replace
      path: /spec/template/spec/serviceAccountName
      value: loadgenerator
- target:
    kind: Deployment
    name: transactionhistory
  patch: |-
    - op: replace
      path: /spec/template/spec/serviceAccountName
      value: transactionhistory
- target:
    kind: Deployment
    name: userservice
  patch: |-
    - op: replace
      path: /spec/template/spec/serviceAccountName
      value: userservice
EOF
```

## Define `AuthorizationPolicies`

```Bash
mkdir ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME/base/authorizationpolicies
cat <<EOF > ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME/base/authorizationpolicies/authorizationpolicy_accounts-db.yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: accounts-db
spec:
  rules:
  - from:
    - source:
        principals:
        - cluster.local/ns/${BANKOFANTHOS_NAMESPACE}/sa/contacts
        - cluster.local/ns/${BANKOFANTHOS_NAMESPACE}/sa/userservice
    to:
    - operation:
        ports:
        - "5432"
  selector:
    matchLabels:
      app: accounts-db
EOF
cat <<EOF > ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME/base/authorizationpolicies/authorizationpolicy_balancereader.yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: balancereader
spec:
  rules:
  - from:
    - source:
        principals:
        - cluster.local/ns/${BANKOFANTHOS_NAMESPACE}/sa/frontend
        - cluster.local/ns/${BANKOFANTHOS_NAMESPACE}/sa/ledgerwriter
    to:
    - operation:
        methods:
        - GET
        paths:
        - /balances/*
        ports:
        - "8080"
  selector:
    matchLabels:
      app: balancereader
EOF
cat <<EOF > ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME/base/authorizationpolicies/authorizationpolicy_contacts.yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: contacts
spec:
  rules:
  - from:
    - source:
        principals:
        - cluster.local/ns/${BANKOFANTHOS_NAMESPACE}/sa/frontend
    to:
    - operation:
        methods:
        - GET
        - POST
        paths:
        - /contacts/*
        ports:
        - "8080"
  selector:
    matchLabels:
      app: contacts
EOF
cat <<EOF > ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME/base/authorizationpolicies/authorizationpolicy_frontend.yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: frontend
spec:
  rules:
  - from:
    - source:
        principals:
        - cluster.local/ns/${BANKOFANTHOS_NAMESPACE}/sa/loadgenerator
        - cluster.local/ns/${INGRESS_GATEWAY_NAMESPACE}/sa/${INGRESS_GATEWAY_NAME}
    to:
    - operation:
        methods:
        - GET
        - POST
        ports:
        - "8080"
  selector:
    matchLabels:
      app: frontend
EOF
cat <<EOF > ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME/base/authorizationpolicies/authorizationpolicy_ledger-db.yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: ledger-db
spec:
  rules:
  - from:
    - source:
        principals:
        - cluster.local/ns/${BANKOFANTHOS_NAMESPACE}/sa/balancereader
        - cluster.local/ns/${BANKOFANTHOS_NAMESPACE}/sa/transactionhistory
        - cluster.local/ns/${BANKOFANTHOS_NAMESPACE}/sa/ledgerwriter
    to:
    - operation:
        ports:
        - "5432"
  selector:
    matchLabels:
      app: ledger-db
EOF
cat <<EOF > ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME/base/authorizationpolicies/authorizationpolicy_ledgerwriter.yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: ledgerwriter
spec:
  rules:
  - from:
    - source:
        principals:
        - cluster.local/ns/${BANKOFANTHOS_NAMESPACE}/sa/frontend
    to:
    - operation:
        methods:
        - POST
        paths:
        - /transactions
        - /transactions/*
        ports:
        - "8080"
  selector:
    matchLabels:
      app: ledgerwriter
EOF
cat <<EOF > ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME/base/authorizationpolicies/authorizationpolicy_transactionhistory.yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: transactionhistory
spec:
  rules:
  - from:
    - source:
        principals:
        - cluster.local/ns/${BANKOFANTHOS_NAMESPACE}/sa/frontend
    to:
    - operation:
        methods:
        - GET
        paths:
        - /transactions/*
        ports:
        - "8080"
  selector:
    matchLabels:
      app: transactionhistory
EOF
cat <<EOF > ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME/base/authorizationpolicies/authorizationpolicy_userservice.yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: userservice
spec:
  rules:
  - from:
    - source:
        principals:
        - cluster.local/ns/${BANKOFANTHOS_NAMESPACE}/sa/frontend
    to:
    - operation:
        methods:
        - GET
        - POST
        paths:
        - /users
        - /login
        ports:
        - "8080"
  selector:
    matchLabels:
      app: userservice
EOF
cd ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME/base/authorizationpolicies
kustomize create --autodetect
```

## Update the Kustomize base overlay

```Bash
cd ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME/base
kustomize edit add component serviceaccounts
kustomize edit add resource authorizationpolicies
```

## Deploy Kubernetes manifests

```Bash
cd ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME/
git add . && git commit -m "Bank of Anthos AuthorizationPolicies" && git push origin main
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

List the GitHub runs for the **Bank of Anthos apps** repository:
```Bash
cd ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME && gh run list
```

## Check the Bank of Anthos website

Navigate to the Bank of Anthos website, click on the link displayed by the command below:
```Bash
echo -e "https://${BANK_OF_ANTHOS_INGRESS_GATEWAY_HOST_NAME}"
```

You should now have the Bank of Anthos website working successfully. Congrats!
