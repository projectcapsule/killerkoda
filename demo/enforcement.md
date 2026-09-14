# Workload QoS by environment

The quickstart Tenant already includes [workload rules](https://projectcapsule.dev/docs/rules/enforcement/workloads/). Test them before adding further policies.

This Pod has no CPU or memory requests or limits. Kubernetes classifies it as `BestEffort`:

```shell
cat /root/capsule-demo/quickstart/pod.yaml
kubectl-alice apply -n solar-development -f /root/capsule-demo/quickstart/pod.yaml
kubectl-alice wait --for=jsonpath='{.status.qosClass}'=BestEffort pod/hello -n solar-development --timeout=120s
kubectl-alice get pod hello -n solar-development -o jsonpath='{.status.qosClass}{"\n"}'
```{{exec}}

The same Pod in production should be **denied** by the Tenant's `Guaranteed`-only rule:

```shell
kubectl-alice apply -n solar-production -f /root/capsule-demo/quickstart/pod.yaml
```{{exec}}

For `Guaranteed` QoS, every container needs matching CPU and memory requests and limits:

```shell
cat /root/capsule-demo/quickstart/guaranteed-pod.yaml
kubectl-alice apply -n solar-production -f /root/capsule-demo/quickstart/guaranteed-pod.yaml
kubectl-alice wait --for=jsonpath='{.status.qosClass}'=Guaranteed pod/guaranteed -n solar-production --timeout=120s
kubectl-alice get pod guaranteed -n solar-production -o jsonpath='{.status.qosClass}{"\n"}'
```{{exec}}

Expect `Guaranteed`. This checks admission and resource settings; the Pod does not need to finish starting to inspect its QoS.

Remove both accepted Pods before continuing, so the later resource pool starts without workload consumption:

```shell
kubectl-alice delete pod hello -n solar-development --wait=true
kubectl-alice delete pod guaranteed -n solar-production --wait=true
```{{exec}}

You have completed the core quickstart. The remaining chapters extend this same Tenant using the [Going Further guide](https://projectcapsule.dev/docs/quickstart/extended/).
