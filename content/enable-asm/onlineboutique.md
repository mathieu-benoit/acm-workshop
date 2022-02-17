---
title: "Enable ASM for OnlineBoutique"
weight: 1
---
In this section, you will enable ASM for OnlineBoutique.

Inject the Istio/ASM proxy within the OnlineBoutique namespace:
```Bash
cat <<EOF | kubectl apply -n $ONLINEBOUTIQUE_NAMESPACE -f -
apiVersion: v1
kind: Namespace
metadata:
  name: ${ONLINEBOUTIQUE_NAMESPACE}
  annotations:
    mesh.cloud.google.com/proxy: '{"managed": true}'
  labels:
    name: ${ONLINEBOUTIQUE_NAMESPACE}
    istio.io/rev: ${ASM_VERSION}
EOF
kubectl rollout restart deployments -n $ONLINEBOUTIQUE_NAMESPACE
```

Ensure that all deployments are up and running:
```Bash
kubectl wait --for=condition=available --timeout=600s deployment --all -n $ONLINEBOUTIQUE_NAMESPACE
curl -s http://${ONLINEBOUTIQUE_PUBLIC_IP}
```

{{% notice note %}}
When running `kubectl get pods -n $ONLINEBOUTIQUE_NAMESPACE` you should see `2/2` on the `READY` column for all the pods in the OnlineBoutique namespace.
{{% /notice %}}

Get the version of the ASM `proxy`:
```Bash
kubectl describe pod -n $INGRESS_GATEWAY_NAMESPACE | grep "proxyv2:"
```
You could also get the version of the ASM Control Plane and all the proxies via the [Cloud Monitoring's Metrics Explorer feature](https://cloud.google.com/service-mesh/docs/managed/service-mesh#verify_control_plane_metrics).

Route traffic to the OnlineBoutique's `frontend` app through the Ingress Gateway:
```Bash
cat <<EOF | kubectl apply -n $ONLINEBOUTIQUE_NAMESPACE -f -
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: frontend
spec:
  hosts:
  - '*'
  gateways:
  - ${INGRESS_GATEWAY_NAMESPACE}/${INGRESS_GATEWAY_NAME}
  http:
  - route:
    - destination:
        host: frontend
        port:
          number: 80
EOF
```

Ensure that the OnlineBoutique solution is now working from the Ingress Gateway public endpoint:
```Bash
curl -s http://${INGRESS_GATEWAY_PUBLIC_IP}
```

From here, you could now remove the `LoadBalancer` service `frontend-external` deployed earlier in this workshop:
```Bash
kubectl delete service frontend-external -n $ONLINEBOUTIQUE_NAMESPACE
rm ~/$WORKING_DIRECTORY/$ONLINEBOUTIQUE_NAMESPACE/service_frontend-external.yaml
```

FIXME - Image in GCP Console - Topology

Resources:
- [ASM - Injecting sidecar proxies](https://cloud.google.com/service-mesh/docs/proxy-injection)