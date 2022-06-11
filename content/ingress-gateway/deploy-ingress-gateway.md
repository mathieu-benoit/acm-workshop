---
title: "Deploy Ingress Gateway"
weight: 4
description: "Duration: 15 min | Persona: Platform Admin"
tags: ["asm", "gke", "platform-admin", "security-tips", "shift-left"]
---
![Platform Admin](/images/platform-admin.png)
_{{< param description >}}_

In this section, you will deploy a secured Ingress Gateway (unprivileged container, managed certificates, Cloud Armor, etc.) in its dedicated namespace in the GKE cluster.

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
echo "export INGRESS_GATEWAY_NAME=asm-ingressgateway" >> ${WORK_DIR}acm-workshop-variables.sh
echo "export INGRESS_GATEWAY_LABEL='asm: ingressgateway'" >> ${WORK_DIR}acm-workshop-variables.sh
source ${WORK_DIR}acm-workshop-variables.sh
```

Create a dedicated folder for the ASM Ingress Gateway in the GKE configs's Git repo:
```Bash
mkdir ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/$INGRESS_GATEWAY_NAMESPACE
```

## Define Namespace

```Bash
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/$INGRESS_GATEWAY_NAMESPACE/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  annotations:
    mesh.cloud.google.com/proxy: '{"managed": true}'
  labels:
    name: ${INGRESS_GATEWAY_NAMESPACE}
    istio-injection: enabled
  name: ${INGRESS_GATEWAY_NAMESPACE}
EOF
```

## Define Deployment

```Bash
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/$INGRESS_GATEWAY_NAMESPACE/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${INGRESS_GATEWAY_NAME}
  namespace: ${INGRESS_GATEWAY_NAMESPACE}
  annotations:
    config.kubernetes.io/depends-on: mesh.cloud.google.com/namespaces/istio-system/ControlPlaneRevision/${ASM_VERSION}
spec:
  selector:
    matchLabels:
      ${INGRESS_GATEWAY_LABEL}
      app: ${INGRESS_GATEWAY_NAME}
  template:
    metadata:
      annotations:
        # This is required to tell Anthos Service Mesh to inject the gateway with the required configuration.
        inject.istio.io/templates: gateway
      labels:
        app: ${INGRESS_GATEWAY_NAME}
        ${INGRESS_GATEWAY_LABEL}
    spec:
      containers:
      - name: istio-proxy
        image: auto # The image will automatically update each time the pod starts.
        env:
        - name: ISTIO_META_UNPRIVILEGED_POD
          value: "true"
        ports:
        - containerPort: 15021
          protocol: TCP
        - containerPort: 8080
          protocol: TCP
        - containerPort: 8443
          protocol: TCP
        resources:
          limits:
            cpu: 2000m
            memory: 1024Mi
          requests:
            cpu: 100m
            memory: 128Mi
        securityContext:
          allowPrivilegeEscalation: false
          capabilities:
            drop:
            - all
          privileged: false
          readOnlyRootFilesystem: true
      securityContext:
        fsGroup: 1337
        runAsGroup: 1337
        runAsNonRoot: true
        runAsUser: 1337
      serviceAccountName: ${INGRESS_GATEWAY_NAME}
EOF
```

```Bash
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/$INGRESS_GATEWAY_NAMESPACE/service-account.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ${INGRESS_GATEWAY_NAME}
  namespace: ${INGRESS_GATEWAY_NAMESPACE}
EOF
```

```Bash
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/$INGRESS_GATEWAY_NAMESPACE/read-secrets-role.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: ${INGRESS_GATEWAY_NAME}
  namespace: ${INGRESS_GATEWAY_NAMESPACE}
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "watch", "list"]
EOF
```

```Bash
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/$INGRESS_GATEWAY_NAMESPACE/service-account-role-binding.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ${INGRESS_GATEWAY_NAME}
  namespace: ${INGRESS_GATEWAY_NAMESPACE}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: ${INGRESS_GATEWAY_NAME}
subjects:
- kind: ServiceAccount
  name: ${INGRESS_GATEWAY_NAME}
EOF
```

## Define Service and Ingress

```Bash
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/$INGRESS_GATEWAY_NAMESPACE/backend-config.yaml
apiVersion: cloud.google.com/v1
kind: BackendConfig
metadata:
  name: ${INGRESS_GATEWAY_NAME}
  namespace: ${INGRESS_GATEWAY_NAMESPACE}
spec:
  healthCheck:
    requestPath: /healthz/ready
    port: 15021
    type: HTTP
  securityPolicy:
    name: ${SECURITY_POLICY_NAME}
EOF
```

```Bash
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/$INGRESS_GATEWAY_NAMESPACE/frontend-config.yaml
apiVersion: networking.gke.io/v1beta1
kind: FrontendConfig
metadata:
  name: ${INGRESS_GATEWAY_NAME}
  namespace: ${INGRESS_GATEWAY_NAMESPACE}
spec:
  sslPolicy: ${SSL_POLICY_NAME}
  redirectToHttps:
    enabled: true
    responseCodeName: MOVED_PERMANENTLY_DEFAULT
EOF
```

```Bash
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/$INGRESS_GATEWAY_NAMESPACE/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: ${INGRESS_GATEWAY_NAME}
  namespace: ${INGRESS_GATEWAY_NAMESPACE}
  annotations:
    cloud.google.com/neg: '{"ingress": true}'
    cloud.google.com/backend-config: '{"default": "${INGRESS_GATEWAY_NAME}"}'
    cloud.google.com/app-protocols: '{"http2":"HTTP"}'
  labels:
    ${INGRESS_GATEWAY_LABEL}
spec:
  ports:
  - name: http-status
    port: 15021
    protocol: TCP
    targetPort: 15021
  - name: http2
    port: 80
    targetPort: 8080
  - name: https
    port: 443
    targetPort: 8443
  selector:
    ${INGRESS_GATEWAY_LABEL}
  type: ClusterIP
EOF
```

```Bash
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/$INGRESS_GATEWAY_NAMESPACE/ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ${INGRESS_GATEWAY_NAME}
  namespace: ${INGRESS_GATEWAY_NAMESPACE}
  annotations:
    kubernetes.io/ingress.global-static-ip-name: "${INGRESS_GATEWAY_PUBLIC_IP_NAME}"
    kubernetes.io/ingress.class: "gce"
    networking.gke.io/v1beta1.FrontendConfig: ${INGRESS_GATEWAY_NAME}
spec:
  defaultBackend:
    service:
      name: ${INGRESS_GATEWAY_NAME}
      port:
        number: 80
  rules:
  - http:
      paths:
      - path: /*
        pathType: ImplementationSpecific
        backend:
          service:
            name: ${INGRESS_GATEWAY_NAME}
            port:
              number: 80
EOF
```

## Define Gateway

```Bash
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/$INGRESS_GATEWAY_NAMESPACE/gateway.yaml
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: ${INGRESS_GATEWAY_NAME}
  namespace: ${INGRESS_GATEWAY_NAMESPACE}
spec:
  selector:
    ${INGRESS_GATEWAY_LABEL}
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - '*'
EOF
```
{{% notice tip %}}
We define a [shared `Gateway`](https://istio.io/latest/docs/setup/additional-setup/gateway/#shared-gateway) resource. Gateways are generally owned by the platform admins or network admins team. Therefore, the `Gateway` resource is created in the Ingress Gateway namespace owned by the platform admin and could be use in other namespaces via their own `VirtualService` entries.
{{% /notice %}}

## Deploy Kubernetes manifests

```Bash
cd ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/
git add . && git commit -m "ASM Ingress Gateway in GKE cluster" && git push origin main
```

## Check deployments

List the Kubernetes resources managed by Config Sync in **GKE cluster** for the **GKE cluster configs** repository:
```Bash
gcloud alpha anthos config sync repo describe \
    --project $TENANT_PROJECT_ID \
    --managed-resources all \
    --sync-name root-sync \
    --sync-namespace config-management-system
```
Wait and re-run this command above until you see `"status": "SYNCED"` for this `RepoSync`.  All the `managed_resources` listed should have `STATUS: Current` as well.

At this stage, the `namespaces-required-networkpolicies` `Constraint` should silently (`dryrun`) complain because we haven't yet deployed any `NetworkPolicies` in the `asm-ingress` `Namespace`. There is different ways to see the detail of the violation. Here, we will navigate to the **Object browser** feature of GKE from within the Google Cloud Console. Click on the link displayed by the command below:
```Bash
echo -e "https://console.cloud.google.com/kubernetes/object/constraints.gatekeeper.sh/k8srequirenamespacenetworkpolicies/${GKE_LOCATION}/${GKE_NAME}/namespaces-required-networkpolicies?apiVersion=v1beta1&project=${TENANT_PROJECT_ID}"
```

At the very bottom of the object's description you should see:
```Plaintext
...
totalViolations: 1
  violations:
  - enforcementAction: dryrun
    kind: Namespace
    message: Namespace <asm-ingress> does not have a NetworkPolicy
    name: asm-ingress
```

## Shift-left Policies evaluation

Another way to see the `Constraints` violations is to evaluate as early as possible the `Constraints` against the Kubernetes manifests before they are actually applied in the Kubernetes cluster. When you created the GitHub repository for GKE cluster configs, you used a predefined template containing a GitHub actions workflow running Continuous Integration checks for every commit. See the content of this file by running this command:
```Bash
cat ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/.github/workflows/ci.yml
```
{{% notice info %}}
We are leveraging the [Kpt's `gatekeeper` function](https://catalog.kpt.dev/gatekeeper/v0.2/) in order to accomplish this. Another way to do that could be to leverage the [`gator test`](https://open-policy-agent.github.io/gatekeeper/website/docs/gator/#the-gator-test-subcommand) command too.
{{% /notice %}}

See the details of the last GitHub actions run:
```Bash
cd ${WORK_DIR}$GKE_CONFIGS_DIR_NAME
gh run view $(gh run list -L 1 --json databaseId --jq .[].databaseId) --log | grep violatedConstraint
```
The output contains the details of the error:
```Plaintext
build   gatekeeper      2022-06-11T02:24:28.5280656Z     [info] v1/Namespace/asm-ingress: Namespace <asm-ingress> does not have a NetworkPolicy violatedConstraint: namespaces-required-networkpolicies
```
{{% notice tip %}}
In the context of this workshop, we are doing direct commits in the `main` branch but it's highly encouraged that you follow the Git flow process by creating branches and opening pull requests. With this process in place and this GitHub actions definition, your pull requests will be blocked if there is any `Constraint` violations and won't be merged into `main` branch. This will avoid any issues when actually deploying the Kubernetes manifests in the Kubernetes cluster.
{{% /notice %}}

The next section will deploy the `NetworkPolicies` in the `asm-ingress` `Namespace` in order to fix this issue.