---
title: "Configure mTLS for Ingress Gateway"
weight: 1
---
In this section we will configure auto `mTLS` `STRICT` for the Ingress Gateway namespace.

```Bash
cat <<EOF | kubectl apply -n $INGRESS_GATEWAY_NAMESPACE -f -
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
spec:
  mtls:
    mode: STRICT
EOF
```