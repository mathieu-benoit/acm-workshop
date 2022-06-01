---
title: "Deploy Ingress Gateway"
weight: 4
description: "Duration: 15 min | Persona: Platform Admin"
tags: ["asm", "platform-admin", "security-tips"]
---
![Platform Admin](/images/platform-admin.png)
_{{< param description >}}_

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
mkdir ~/$GKE_CONFIGS_DIR_NAME/$INGRESS_GATEWAY_NAMESPACE
```

## Define Namespace

```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/$INGRESS_GATEWAY_NAMESPACE/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  annotations:
    mesh.cloud.google.com/proxy: {"managed":"true"}
  labels:
    name: ${INGRESS_GATEWAY_NAMESPACE}
    istio-injection: enabled
  name: ${INGRESS_GATEWAY_NAMESPACE}
EOF
```

## Define Deployment

```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/$INGRESS_GATEWAY_NAMESPACE/deployment.yaml
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
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/$INGRESS_GATEWAY_NAMESPACE/service-account.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ${INGRESS_GATEWAY_NAME}
  namespace: ${INGRESS_GATEWAY_NAMESPACE}
EOF
```

```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/$INGRESS_GATEWAY_NAMESPACE/read-secrets-role.yaml
# Set up roles to allow reading credentials for TLS
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
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/$INGRESS_GATEWAY_NAMESPACE/service-account-role-binding.yaml
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
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/$INGRESS_GATEWAY_NAMESPACE/backend-config.yaml
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
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/$INGRESS_GATEWAY_NAMESPACE/frontend-config.yaml
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
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/$INGRESS_GATEWAY_NAMESPACE/service.yaml
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
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/$INGRESS_GATEWAY_NAMESPACE/ingress.yaml
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
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/$INGRESS_GATEWAY_NAMESPACE/gateway.yaml
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
cd ~/$GKE_CONFIGS_DIR_NAME/
git add . && git commit -m "ASM Ingress Gateway in GKE cluster" && git push origin main
```

## Check deployments

List the GitHub runs for the **GKE cluster configs** repository `cd ~/$GKE_CONFIGS_DIR_NAME && gh run list`:
```Plaintext
STATUS  NAME                                                  WORKFLOW  BRANCH  EVENT  ID          ELAPSED  AGE
✓       ASM Ingress Gateway in GKE cluster                    ci        main    push   1975240395  1m14s    2m
✓       Enforce ASM/Istio Policies in GKE cluster             ci        main    push   1972244827  59s      23h
✓       ASM configs (mTLS, Sidecar, etc.) in GKE cluster      ci        main    push   1972234050  56s      23h
✓       ASM MCP for GKE cluster                               ci        main    push   1972185200  1m8s     23h
✓       Enforce Container Registries Policies in GKE cluster  ci        main    push   1972138349  55s      23h
✓       Policies for NetworkPolicy resources                  ci        main    push   1971716019  1m14s    1d
✓       Network Policies logging                              ci        main    push   1971353547  1m1s     1d
✓       Config Sync monitoring                                ci        main    push   1971296656  1m9s     1d
✓       Initial commit                                        ci        main    push   1970951731  57s      1d
```

List the Kubernetes resources managed by Config Sync in the **GKE cluster** for the **GKE cluster configs** repository:
```Bash
gcloud alpha anthos config sync repo describe \
    --project $TENANT_PROJECT_ID \
    --managed-resources all \
    --sync-name root-sync \
    --sync-namespace config-management-system
```
```Plaintext
getting 1 RepoSync and RootSync from gke-hub-membership
┌───────────────────────────┬───────────────────────────┬─────────────────────────────────┬──────────────────────────────┐
│           GROUP           │            KIND           │               NAME              │          NAMESPACE           │
├───────────────────────────┼───────────────────────────┼─────────────────────────────────┼──────────────────────────────┤
│                           │ Namespace                 │ istio-system                    │                              │
│                           │ Namespace                 │ config-management-monitoring    │                              │
│                           │ Namespace                 │ asm-ingress                     │                              │
│ constraints.gatekeeper.sh │ K8sRequiredLabels         │ deployment-required-labels      │                              │
│ constraints.gatekeeper.sh │ DestinationRuleTLSEnabled │ destination-rule-tls-enabled    │                              │
│ constraints.gatekeeper.sh │ PolicyStrictOnly          │ policy-strict-only              │                              │
│ constraints.gatekeeper.sh │ K8sRequiredLabels         │ namespace-required-labels       │                              │
│ constraints.gatekeeper.sh │ AllowedServicePortName    │ allowed-service-port-names      │                              │
│ constraints.gatekeeper.sh │ SourceNotAllAuthz         │ defined-authz-source-principals │                              │
│ constraints.gatekeeper.sh │ K8sRequiredLabels         │ automatic-sidecar-injection     │                              │
│ constraints.gatekeeper.sh │ K8sAllowedRepos           │ allowed-container-registries    │                              │
│ networking.gke.io         │ NetworkLogging            │ default                         │                              │
│ templates.gatekeeper.sh   │ ConstraintTemplate        │ allowedserviceportname          │                              │
│ templates.gatekeeper.sh   │ ConstraintTemplate        │ k8srequiredlabels               │                              │
│ templates.gatekeeper.sh   │ ConstraintTemplate        │ k8sallowedrepos                 │                              │
│ templates.gatekeeper.sh   │ ConstraintTemplate        │ policystrictonly                │                              │
│ templates.gatekeeper.sh   │ ConstraintTemplate        │ sourcenotallauthz               │                              │
│ templates.gatekeeper.sh   │ ConstraintTemplate        │ destinationruletlsenabled       │                              │
│                           │ ServiceAccount            │ asm-ingressgateway              │ asm-ingress                  │
│                           │ Service                   │ asm-ingressgateway              │ asm-ingress                  │
│ apps                      │ Deployment                │ asm-ingressgateway              │ asm-ingress                  │
│ cloud.google.com          │ BackendConfig             │ asm-ingressgateway              │ asm-ingress                  │
│ networking.gke.io         │ FrontendConfig            │ asm-ingressgateway              │ asm-ingress                  │
│ networking.istio.io       │ Gateway                   │ asm-ingressgateway              │ asm-ingress                  │
│ networking.k8s.io         │ Ingress                   │ asm-ingressgateway              │ asm-ingress                  │
│ rbac.authorization.k8s.io │ Role                      │ asm-ingressgateway              │ asm-ingress                  │
│ rbac.authorization.k8s.io │ RoleBinding               │ asm-ingressgateway              │ asm-ingress                  │
│                           │ ServiceAccount            │ default                         │ config-management-monitoring │
│                           │ ConfigMap                 │ istio-asm-managed-rapid         │ istio-system                 │
│ mesh.cloud.google.com     │ ControlPlaneRevision      │ asm-managed-rapid               │ istio-system                 │
│ security.istio.io         │ PeerAuthentication        │ default                         │ istio-system                 │
└───────────────────────────┴───────────────────────────┴─────────────────────────────────┴──────────────────────────────┘
```