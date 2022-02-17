---
title: "Setup Ingress Gateway"
weight: 3
---


```Bash
cat <<EOF | kubectl apply -n $INGRESS_GATEWAY_NAMESPACE -f -
apiVersion: v1
kind: Service
metadata:
  name: ${INGRESS_GATEWAY_NAME}
  annotations:
    cloud.google.com/neg: '{"ingress": true}'
    cloud.google.com/backend-config: '{"default": "${INGRESS_GATEWAY_NAME}"}'
  labels:
    ${INGRESS_GATEWAY_LABEL}
spec:
  ports:
  - name: status-port
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
---
apiVersion: cloud.google.com/v1
kind: BackendConfig
metadata:
  name: ${INGRESS_GATEWAY_NAME}
spec:
  healthCheck:
    requestPath: /healthz/ready
    port: 15021
    type: HTTP
  securityPolicy:
    name: ${SECURITY_POLICY_NAME}
---
apiVersion: networking.gke.io/v1beta1
kind: FrontendConfig
metadata:
  name: ${INGRESS_GATEWAY_NAME}
spec:
  sslPolicy: ${SSL_POLICY_NAME}
  redirectToHttps:
    enabled: true
    responseCodeName: MOVED_PERMANENTLY_DEFAULT
---
apiVersion: networking.gke.io/v1
kind: ManagedCertificate
metadata:
  name: ${INGRESS_GATEWAY_NAME}
spec:
  domains:
    - "${INGRESS_GATEWAY_HOST_NAME}"
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ${INGRESS_GATEWAY_NAME}
  annotations:
    kubernetes.io/ingress.global-static-ip-name: "${INGRESS_GATEWAY_PUBLIC_IP_NAME}"
    networking.gke.io/managed-certificates: "${INGRESS_GATEWAY_NAME}"
    kubernetes.io/ingress.class: "gce"
spec:
  defaultBackend:
    service:
      name: ${INGRESS_GATEWAY_NAME}
      port:
        number: 443
  rules:
  - http:
      paths:
      - path: /*
        pathType: ImplementationSpecific
        backend:
          service:
            name: ${INGRESS_GATEWAY_NAME}
            port:
              number: 443
EOF
```

```Bash
kubectl get managedcertificate ${INGRESS_GATEWAY_NAME} -ojsonpath='{.status.certificateStatus}' -n $INGRESS_GATEWAY_NAMESPACE
```

FIXME - add a section with unprivileged deployment too + Rk about PSC/Internal LB.