---
title: "Deploy Ingress Gateway"
weight: 1
---
In this section, you will deploy the Ingress Gateway in its own namespace as you will do for any other workload.

Init variables:
```Bash
export INGRESS_GATEWAY_NAMESPACE=asm-ingress
export INGRESS_GATEWAY_NAME=asm-ingressgateway
export INGRESS_GATEWAY_LABEL="asm: ingressgateway"
```

Deploy the Ingress Gateway in its own namespace exposed (for now) with public IP address (L4 load balancer):
```Bash
cat <<EOF | kubectl apply -n $INGRESS_GATEWAY_NAMESPACE -f -
apiVersion: v1
kind: Namespace
metadata:
  name: ${INGRESS_GATEWAY_NAMESPACE}
  annotations:
    mesh.cloud.google.com/proxy: '{"managed": true}'
  labels:
    name: ${INGRESS_GATEWAY_NAMESPACE}
    istio.io/rev: ${ASM_VERSION}
---
apiVersion: v1
kind: Service
metadata:
  name: ${INGRESS_GATEWAY_NAME}
spec:
  type: LoadBalancer
  selector:
    ${INGRESS_GATEWAY_LABEL}
  ports:
  - port: 80
    name: http
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${INGRESS_GATEWAY_NAME}
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
        ${INGRESS_GATEWAY_LABEL}
        app: ${INGRESS_GATEWAY_NAME}
    spec:
      containers:
      - name: istio-proxy
        image: auto # The image will automatically update each time the pod starts.
      serviceAccountName: ${INGRESS_GATEWAY_NAME}
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ${INGRESS_GATEWAY_NAME}
---
# Set up roles to allow reading credentials for TLS
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: ${INGRESS_GATEWAY_NAME}
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "watch", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ${INGRESS_GATEWAY_NAME}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: ${INGRESS_GATEWAY_NAME}
subjects:
- kind: ServiceAccount
  name: ${INGRESS_GATEWAY_NAME}
EOF
```

Ensure that all deployments are up and running:
```Bash
kubectl wait --for=condition=available --timeout=600s deployment --all -n $INGRESS_GATEWAY_NAMESPACE
until kubectl get svc $INGRESS_GATEWAY_NAME -n $INGRESS_GATEWAY_NAMESPACE -o jsonpath='{.status.loadBalancer}' | grep "ingress"; do : ; done
export INGRESS_GATEWAY_PUBLIC_IP=$(kubectl get svc $INGRESS_GATEWAY_NAME -n $INGRESS_GATEWAY_NAMESPACE -o jsonpath="{.status.loadBalancer.ingress[*].ip}")
```

Create a [shared `Gateway`](https://istio.io/latest/docs/setup/additional-setup/gateway/#shared-gateway) resource in the Ingress Gateway namespace. Gateways are generally owned by the platform admins or network admins team. Therefore, the `Gateway` resource is created in the Ingress Gateway namespace owned by the platform admin and could be use in other namespaces via their own `VirtualService` entries.
```Bash
cat <<EOF | kubectl apply -n $INGRESS_GATEWAY_NAMESPACE -f -
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
    name: ${INGRESS_GATEWAY_NAME}
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

Get the version of the ASM `proxy`:
```Bash
kubectl describe pod -n $INGRESS_GATEWAY_NAMESPACE | grep "proxyv2:"
```

Resources:
- [Istio - Installing Gateways](https://istio.io/latest/docs/setup/additional-setup/gateway)
- [Docs - ASM Installing and upgrading gateways](https://cloud.google.com/service-mesh/docs/gateways)