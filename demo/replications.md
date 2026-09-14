# Going further: distribute platform resources

A [GlobalTenantResource](https://projectcapsule.dev/docs/replications/global/) lets the administrator distribute resources into matching tenant namespaces. These examples select Solar's namespaces explicitly.

## Resource defaults per environment

Review and apply the LimitRange distribution:

```shell
cat /root/capsule-demo/going-further/limitranges.yaml
kubectl apply -f /root/capsule-demo/going-further/limitranges.yaml
kubectl wait --for=create limitrange/service-level-silver -n solar-development --timeout=120s
kubectl wait --for=create limitrange/service-level-gold -n solar-production --timeout=120s
```{{exec}}

The `test` namespace receives silver defaults; production receives gold defaults. Bronze covers `dev` namespaces if you add one later or change an environment label. Its minimum memory constraint keeps the LimitRange valid without assigning defaults.

Inspect the generated resources:

```shell
kubectl-alice get limitrange service-level-silver -n solar-development -o yaml
kubectl-alice get limitrange service-level-gold -n solar-production -o yaml
```{{exec}}

Revisit the Pod that had no resources. Production now receives matching CPU and memory requests and limits from its LimitRange, satisfying the existing `Guaranteed` rule:

```shell
kubectl-alice apply -n solar-production -f /root/capsule-demo/quickstart/pod.yaml
kubectl-alice wait --for=jsonpath='{.status.qosClass}'=Guaranteed pod/hello -n solar-production --timeout=120s
kubectl-alice get pod hello -n solar-production -o jsonpath='{.spec.containers[0].resources}{"\n"}{.status.qosClass}{"\n"}'
```{{exec}}

Expect CPU `128m`, memory `256Mi`, and `Guaranteed`. Clean up before the resource pool chapter:

```shell
kubectl-alice delete pod hello -n solar-production --wait=true
```{{exec}}

## Network policies

Distribute a policy that allows traffic between Solar namespaces and DNS queries to CoreDNS. Other ingress and egress are not allowed by this policy:

```shell
cat /root/capsule-demo/going-further/networkpolicies.yaml
kubectl apply -f /root/capsule-demo/going-further/networkpolicies.yaml
kubectl wait --for=create networkpolicy/tenant-isolation -n solar-development --timeout=120s
kubectl wait --for=create networkpolicy/tenant-isolation -n solar-production --timeout=120s
kubectl-alice get networkpolicy tenant-isolation -n solar-production -o yaml
```{{exec}}

Capsule distributes the objects; the cluster's network plugin enforces them. Kubernetes NetworkPolicies are additive, so another policy can allow additional traffic. This exercise verifies distribution; connectivity testing also depends on the backend's CNI and any other policies.

The next chapter lets Alice distribute application configuration herself.
