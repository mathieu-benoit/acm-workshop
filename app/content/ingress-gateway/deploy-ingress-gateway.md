---
title: "Deploy Ingress Gateway"
weight: 4
description: "Duration: 15 min | Persona: Platform Admin"
tags: ["asm", "gke", "platform-admin", "security-tips"]
---
![Platform Admin](https://github.com/mathieu-benoit/my-images/raw/main/acm-workshop/platform-admin.png)
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
  labels:
    istio-injection: enabled
    pod-security.kubernetes.io/enforce: restricted
  name: ${INGRESS_GATEWAY_NAMESPACE}
EOF
```
{{% notice note %}}
In addition to the `istio-injection` to include this `Namespace` into our Service Mesh, we are also adding the `pod-security.kubernetes.io/enforce` label as the `restricted` [Pod Security Standards policy](https://kubernetes.io/docs/concepts/security/pod-security-standards/).
{{% /notice %}}

## Define Deployment

```Bash
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/$INGRESS_GATEWAY_NAMESPACE/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${INGRESS_GATEWAY_NAME}
  namespace: ${INGRESS_GATEWAY_NAMESPACE}
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
            - ALL
          privileged: false
          readOnlyRootFilesystem: true
      securityContext:
        fsGroup: 1337
        runAsGroup: 1337
        runAsNonRoot: true
        runAsUser: 1337
        seccompProfile:
          type: RuntimeDefault
      serviceAccountName: ${INGRESS_GATEWAY_NAME}
EOF
```

```Bash
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/$INGRESS_GATEWAY_NAMESPACE/hpa.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: ${INGRESS_GATEWAY_NAME}
  namespace: ${INGRESS_GATEWAY_NAMESPACE}
spec:
  maxReplicas: 5
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 80
  minReplicas: 3
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: ${INGRESS_GATEWAY_NAME}
EOF
```
{{% notice tip %}}
Note that we are configuring the `replicas` in the `HorizontalPodAutoscaler` and not via the `Deployment` itself, this is a best practice to avoid any conflict with the dynamic value of the `Deployment` `replicas` actually in the Kubernetes cluster managed by the `HorizontalPodAutoscaler` resource.
{{% /notice %}}

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
  - name: tcp-status
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
    --sync-name root-sync \
    --sync-namespace config-management-system
```
Wait and re-run this command above until you see `"status": "SYNCED"`.
{{% /tab %}}
{{< /tabs >}}