---
title: "Troubleshoot Istio/ASM"
weight: 2
---

_Note: Managed ASM doesn't support `istioctl proxy-status`._

```Bash
kubectl get events
```

```Bash
istioctl analyze -A
```

```Bash
NAMESPACE=your-namespace
DEPLOYMENT_NAME=your-deployment-name
kubectl logs deployment/$DEPLOYMENT_NAME -c istio-proxy -n $NAMESPACE
```

```Bash
NAMESPACE=your-namespace
DEPLOYMENT_NAME=your-deployment-name
APP_LABEL=your-pod-app-label
istioctl proxy-config log $(kubectl -n $NAMESPACE get pod -l app=$APP_LABEL -o jsonpath={.items..metadata.name}) \
    --level debug \
    -n $NAMESPACE
kubectl logs deployment/$DEPLOYMENT_NAME -c istio-proxy -n $NAMESPACE
```

```Bash
NAMESPACE=your-namespace
APP_LABEL=your-pod-app-label
istioctl proxy-config clusters $(kubectl -n $NAMESPACE get pod -l app=$APP_LABEL -o jsonpath={.items..metadata.name}) \
    -n $NAMESPACE
```

```Bash
NAMESPACE=your-namespace
APP_LABEL=your-pod-app-label
istioctl proxy-config listeners $(kubectl -n $NAMESPACE get pod -l app=$APP_LABEL -o jsonpath={.items..metadata.name}) \
    -n $NAMESPACE
```

```Bash
kubectl describe configmap -n istio-system
```

Resources:
- [Resolving managed Anthos Service Mesh issues](https://cloud.google.com/service-mesh/docs/managed/troubleshoot)
- [Troubleshooting ASM](https://cloud.google.com/service-mesh/docs/troubleshooting/troubleshoot-intro)
- [Managed Anthos Service Mesh supported features](https://cloud.google.com/service-mesh/docs/managed/supported-features-mcp)
- [Accessing logs in Cloud Logging](https://cloud.google.com/service-mesh/docs/observability/accessing-logs)