---
title: "Deploy Sidecars"
weight: 8
description: "Duration: 5 min | Persona: Apps Operator"
tags: ["asm", "apps-operator"]
---
![Apps Operator](/images/apps-operator.png)
_{{< param description >}}_

In this section, you will deploy fine granular `Sidecars` in order to optimize the resources (CPU/Memory) usage of the Bank of Anthos apps's sidecar proxies. By default, each application in the `bankofanthos` `Namespace` can reach to all the endpoints in the mesh. The `Sidecar` resource allows to reduce that list to the strict minimum of which endpoints it needs to communicate with.

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
```

## Define `Sidecars`

```Bash
mkdir ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME/base/sidecars
cat <<EOF > ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME/base/sidecars/sidecar_accounts-db.yaml
apiVersion: networking.istio.io/v1beta1
kind: Sidecar
metadata:
  name: accounts-db
spec:
  egress:
  - hosts:
    - istio-system/*
  workloadSelector:
    labels:
      app: accounts-db
EOF
cat <<EOF > ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME/base/sidecars/sidecar_balancereader.yaml
apiVersion: networking.istio.io/v1beta1
kind: Sidecar
metadata:
  name: balancereader
spec:
  egress:
  - hosts:
    - istio-system/*
    - ./ledger-db.${BANKOFANTHOS_NAMESPACE}.svc.cluster.local
  workloadSelector:
    labels:
      app: balancereader
EOF
cat <<EOF > ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME/base/sidecars/sidecar_contacts.yaml
apiVersion: networking.istio.io/v1beta1
kind: Sidecar
metadata:
  name: contacts
spec:
  egress:
  - hosts:
    - istio-system/*
    - ./accounts-db.${BANKOFANTHOS_NAMESPACE}.svc.cluster.local
  workloadSelector:
    labels:
      app: contacts
EOF
cat <<EOF > ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME/base/sidecars/sidecar_frontend.yaml
apiVersion: networking.istio.io/v1beta1
kind: Sidecar
metadata:
  name: frontend
spec:
  egress:
  - hosts:
    - istio-system/*
    - ./balancereader.${BANKOFANTHOS_NAMESPACE}.svc.cluster.local
    - ./contacts.${BANKOFANTHOS_NAMESPACE}.svc.cluster.local
    - ./ledgerwriter.${BANKOFANTHOS_NAMESPACE}.svc.cluster.local
    - ./transactionhistory.${BANKOFANTHOS_NAMESPACE}.svc.cluster.local
    - ./userservice.${BANKOFANTHOS_NAMESPACE}.svc.cluster.local
  workloadSelector:
    labels:
      app: frontend
EOF
cat <<EOF > ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME/base/sidecars/sidecar_ledger-db.yaml
apiVersion: networking.istio.io/v1beta1
kind: Sidecar
metadata:
  name: ledger-db
spec:
  egress:
  - hosts:
    - istio-system/*
  workloadSelector:
    labels:
      app: ledger-db
EOF
cat <<EOF > ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME/base/sidecars/sidecar_ledgerwriter.yaml
apiVersion: networking.istio.io/v1beta1
kind: Sidecar
metadata:
  name: ledgerwriter
spec:
  egress:
  - hosts:
    - istio-system/*
    - ./balancereader.${BANKOFANTHOS_NAMESPACE}.svc.cluster.local
    - ./ledger-db.${BANKOFANTHOS_NAMESPACE}.svc.cluster.local
  workloadSelector:
    labels:
      app: ledgerwriter
EOF
cat <<EOF > ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME/base/sidecars/sidecar_loadgenerator.yaml
apiVersion: networking.istio.io/v1beta1
kind: Sidecar
metadata:
  name: loadgenerator
spec:
  egress:
  - hosts:
    - istio-system/*
    - ./frontend.${BANKOFANTHOS_NAMESPACE}.svc.cluster.local
  workloadSelector:
    labels:
      app: loadgenerator
EOF
cat <<EOF > ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME/base/sidecars/sidecar_transactionhistory.yaml
apiVersion: networking.istio.io/v1beta1
kind: Sidecar
metadata:
  name: transactionhistory
spec:
  egress:
  - hosts:
    - istio-system/*
    - ./ledger-db.${BANKOFANTHOS_NAMESPACE}.svc.cluster.local
  workloadSelector:
    labels:
      app: transactionhistory
EOF
cat <<EOF > ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME/base/sidecars/sidecar_userservice.yaml
apiVersion: networking.istio.io/v1beta1
kind: Sidecar
metadata:
  name: userservice
spec:
  egress:
  - hosts:
    - istio-system/*
    - ./accounts-db.${BANKOFANTHOS_NAMESPACE}.svc.cluster.local
  workloadSelector:
    labels:
      app: userservice
EOF
cd ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME/base/sidecars
kustomize create --autodetect
```

## Update the Kustomize base overlay

```Bash
cd ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME/base
kustomize edit add resource sidecars
```

## Deploy Kubernetes manifests

```Bash
cd ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME/
git add . && git commit -m "Bank of Anthos Sidecars" && git push origin main
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

## Check the Bank of Anthos apps

Navigate to the Bank of Anthos website, click on the link displayed by the command below:
```Bash
echo -e "https://${BANK_OF_ANTHOS_INGRESS_GATEWAY_HOST_NAME}"
```

You should still have the Bank of Anthos website working successfully.
