---
title: "Install ASM"
weight: 2
---

Enable the required APIs for ASM:
```Bash
gcloud services enable mesh.googleapis.com
```

Enable Managed ASM on your current project:
```Bash
gcloud container hub mesh enable
```

Define bash variables:
```Bash
ASM_CHANNEL=rapid # or regular or stable
ASM_LABEL=asm-managed
if [ $ASM_CHANNEL = "rapid" ] || [ $ASM_CHANNEL = "stable" ] ; then ASM_VERSION=$ASM_LABEL-$ASM_CHANNEL; else ASM_VERSION=$ASM_LABEL; fi
```

Create the `istio-system` namespace and apply the following optional Mesh configs (`distroless` container image for the proxy and Cloud Tracing):
```Bash
cat <<EOF | kubectl apply -n istio-system -f -
apiVersion: v1
kind: Namespace
metadata:
  name: istio-system
---
apiVersion: v1
data:
  mesh: |-
    enableTracing: true
    defaultConfig:
      image:
        imageType: distroless
      tracing:
        stackdriver:{}
kind: ConfigMap
metadata:
  name: istio-${ASM_VERSION}
EOF
```

{{< tabs >}}
{{% tab name="asmcli" %}}
Download `asmcli`:
```Bash
curl https://storage.googleapis.com/csm-artifacts/asm/asmcli_1.12 > ~/$WORKING_DIRECTORY/asmcli
chmod +x ~/$WORKING_DIRECTORY/asmcli
```

Run the `asmcli install` command:
```Bash
~/$WORKING_DIRECTORY/asmcli install \
  --project_id $PROJECT_ID \
  --cluster_name $GKE_NAME \
  --cluster_location $ZONE \
  --enable-all \
  --managed \
  --channel $ASM_CHANNEL \
  --use_managed_cni
```
{{% /tab %}}
{{% tab name="fleet" %}}
Apply the `mesh_id` label on the GKE cluster:
```Bash
gcloud container clusters update $GKE_NAME \
  --zone $ZONE \
  --update-labels mesh_id=proj-$PROJECT_NUMBER
```

Enable automatic control plane management:
```Bash
gcloud alpha container hub mesh update \
     --control-plane automatic \
     --membership $GKE_NAME
```
{{% /tab %}}
{{% tab name="krm" %}}
```Bash
cat <<EOF | kubectl apply -n istio-system -f -
apiVersion: mesh.cloud.google.com/v1beta1
kind: ControlPlaneRevision
metadata:
  name: ${ASM_VERSION}
spec:
  type: managed_service
  channel: ${ASM_CHANNEL}

EOF
```
{{% /tab %}}
{{< /tabs >}}

Ensure that all deployments are up and running:
```Bash
gcloud alpha container hub mesh describe
kubectl get controlplanerevision -n istio-system
kubectl get dataplanecontrols
kubectl get daemonset istio-cni-node -n kube-system
kubectl wait --for=condition=available --timeout=600s deployment --all -n asm-system
```

To get the version of the ASM Control Plane, you can get them via the [Cloud Monitoring's Metrics Explorer feature](https://cloud.google.com/service-mesh/docs/managed/service-mesh#verify_control_plane_metrics).

Resources:
- [ASM Release Notes](https://cloud.google.com/service-mesh/docs/release-notes)
- [Configure Managed Anthos Service Mesh](https://cloud.google.com/service-mesh/docs/managed/service-mesh)
- [Managed ASM Release Channel](https://cloud.google.com/service-mesh/docs/managed/release-channels)