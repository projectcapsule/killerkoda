<details>
<summary><strong>Environment quick reference</strong> — services and Dex users</summary>
<p>
  <strong>Services:</strong>
  <a href="{{TRAFFIC_HOST1_30442}}"><img src="https://projectcapsule.dev/favicons/android-96x96.png" alt="" width="20" height="20"> Gangplank</a> ·
  <a href="{{TRAFFIC_HOST1_30443}}"><img src="https://projectcapsule.dev/favicons/android-96x96.png" alt="" width="20" height="20"> Capsule Proxy</a> ·
  <a href="{{TRAFFIC_HOST1_30444}}"><img src="https://headlamp.dev/img/favicon.png" alt="" width="20" height="20"> Headlamp</a> ·
  <a href="{{TRAFFIC_HOST1_32556}}"><img src="https://dexidp.io/favicons/favicon-96x96.png" alt="" width="20" height="20"> Dex</a>
</p>

**Dex login / password:**

- `alice@projectcapsule.dev`{{copy}} / `alice`{{copy}}
- `bob@projectcapsule.dev`{{copy}} / `bob`{{copy}}
- `gatsby@projectcapsule.dev`{{copy}} / `gatsby`{{copy}}
- `renewable@projectcapsule.dev`{{copy}} / `renewable`{{copy}}
- `admin@projectcapsule.dev`{{copy}} / `admin`{{copy}}

</details>

# Going further: workload priority

The environment includes three PriorityClasses: `best-effort` and `customer` for tenant workloads, and `operations-critical` for platform operations.

As administrator, inspect them and extend Solar's policy:

```shell
kubectl get priorityclasses -L consumer
cat /root/capsule-quickstart/going-further/scheduling/priority-classes.yaml
kubectl apply -k /root/capsule-quickstart/going-further/scheduling
bash /root/capsule-quickstart/scripts/wait-tenant.sh
```{{exec}}

In this release, [PriorityClass selection](https://projectcapsule.dev/docs/tenants/enforcement/#priorityclasses) is configured under `spec.priorityClasses`. The selector allows classes labeled `consumer=customer`, and `default: customer` overrides the cluster's default for Solar. This stage preserves all eight rules from the preceding chapters.

## Reject a platform-only class

The following Pod satisfies production's QoS and Pod Security requirements, but requests `operations-critical`. As Alice, expect **denial** because the class is outside Solar's selector:

```shell
cat /root/capsule-quickstart/going-further/scheduling/denied-pod.yaml
kubectl-alice apply -f /root/capsule-quickstart/going-further/scheduling/denied-pod.yaml
```{{exec}}

## Use the tenant default

The familiar production Pod omits `priorityClassName`:

```shell
kubectl-alice apply -n solar-production -f /root/capsule-quickstart/quickstart/guaranteed-pod.yaml
kubectl-alice get pod guaranteed -n solar-production -o jsonpath='{.spec.priorityClassName}{"\n"}'
```{{exec}}

Expect `customer`. Priority controls scheduling order and possible preemption; QoS describes the Pod's requests and limits. The two settings serve different purposes.

Remove the Pod before continuing to the resource distribution and pool exercises:

```shell
kubectl-alice delete pod guaranteed -n solar-production --wait=true
```{{exec}}
