---
title: "Deploy Ingress Gateway"
weight: 4
---
- Persona: Platform Admin
- Duration: 15 min
- Objectives:
  - FIXME

Define variables:
```Bash
export INGRESS_GATEWAY_NAMESPACE=asm-ingress
export INGRESS_GATEWAY_NAME=asm-ingressgateway
export INGRESS_GATEWAY_LABEL="asm: ingressgateway"
```

Create a dedicated folder for the ASM Ingress Gateway in the GKE configs's Git repo:
```Bash
mkdir ~/$GKE_CONFIGS_DIR_NAME/config-sync/$INGRESS_GATEWAY_NAMESPACE
```

```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/$INGRESS_GATEWAY_NAMESPACE/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: ${INGRESS_GATEWAY_NAMESPACE}
  annotations:
    mesh.cloud.google.com/proxy: '{"managed": true}'
  labels:
    name: ${INGRESS_GATEWAY_NAMESPACE}
    istio.io/rev: ${ASM_VERSION}
EOF
```

```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/$INGRESS_GATEWAY_NAMESPACE/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${INGRESS_GATEWAY_NAME}
  namespace: ${INGRESS_GATEWAY_NAMESPACE}
spec:
  selector:
    matchLabels:
      ${INGRESS_GATEWAY_LABEL}
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
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/$INGRESS_GATEWAY_NAMESPACE/service-account.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ${INGRESS_GATEWAY_NAME}
  namespace: ${INGRESS_GATEWAY_NAMESPACE}
EOF
```

```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/$INGRESS_GATEWAY_NAMESPACE/read-secrets-role.yaml
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
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/$INGRESS_GATEWAY_NAMESPACE/service-account-role-binding.yaml
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

```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/$INGRESS_GATEWAY_NAMESPACE/backend-config.yaml
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
EOF
```

```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/$INGRESS_GATEWAY_NAMESPACE/service.yaml
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
    targetPort: 8081
  - name: https
    port: 443
    targetPort: 8443
  selector:
    ${INGRESS_GATEWAY_LABEL}
  type: ClusterIP
EOF
```

```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/$INGRESS_GATEWAY_NAMESPACE/managedcertificate-onlineboutique.yaml
apiVersion: networking.gke.io/v1
kind: ManagedCertificate
metadata:
  name: onlineboutique
  namespace: ${INGRESS_GATEWAY_NAMESPACE}
spec:
  domains:
    - "${ONLINE_BOUTIQUE_INGRESS_GATEWAY_HOST_NAME}"
EOF
```

```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/$INGRESS_GATEWAY_NAMESPACE/managedcertificate-bankofanthos.yaml
apiVersion: networking.gke.io/v1
kind: ManagedCertificate
metadata:
  name: bankofanthos
  namespace: ${INGRESS_GATEWAY_NAMESPACE}
spec:
  domains:
    - "${BANK_OF_ANTHOS_INGRESS_GATEWAY_HOST_NAME}"
EOF
```

```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/$INGRESS_GATEWAY_NAMESPACE/ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ${INGRESS_GATEWAY_NAME}
  namespace: ${INGRESS_GATEWAY_NAMESPACE}
  annotations:
    kubernetes.io/ingress.global-static-ip-name: "${INGRESS_GATEWAY_PUBLIC_IP_NAME}"
    networking.gke.io/managed-certificates: "onlineboutique,bankofanthos"
    kubernetes.io/ingress.class: "gce"
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

```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/$INGRESS_GATEWAY_NAMESPACE/gateway.yaml
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

Let's deploy them via a GitOps approach by commiting them in the GKE configs repository:
```Bash
cd ~/$GKE_CONFIGS_DIR_NAME/
git add .
git commit -m "Deploy the ASM Ingress Gateway in GKE cluster."
git push
```