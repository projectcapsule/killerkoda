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

# Going further: allocate resources from a pool

[Resource Pools](https://projectcapsule.dev/docs/resource-management/resourcepools/) give administrators a shared resource budget and tenant users a namespaced claim API.

The earlier Pods have been deleted. As administrator, create a pool for Solar's namespaces:

```shell
cat /root/capsule-quickstart/going-further/resourcepool.yaml
kubectl apply -f /root/capsule-quickstart/going-further/resourcepool.yaml
kubectl wait --for=condition=Ready resourcepool/solar --timeout=120s
kubectl wait --for=create resourcequota/capsule-pool-solar -n solar-production --timeout=120s
kubectl get resourcequota capsule-pool-solar -n solar-production
```{{exec}}

The budget is one CPU and 1 GiB of memory. `spec.config.defaultsZero: true` starts each namespace's quota at zero, so a claim is required before Pods can consume resources. This quota is independent of the Tenant's two-namespace limit.

## Claim a production budget

As Alice, this otherwise valid Pod should be **denied by ResourceQuota**:

```shell
kubectl-alice apply -n solar-production -f /root/capsule-quickstart/quickstart/guaranteed-pod.yaml
```{{exec}}

Request `256m` CPU and `512Mi` memory, including both requests and limits:

```shell
cat /root/capsule-quickstart/going-further/claim.yaml
kubectl-alice apply -f /root/capsule-quickstart/going-further/claim.yaml
kubectl-alice wait --for=condition=Ready resourcepoolclaim/production-budget -n solar-production --timeout=120s
kubectl-alice get resourcequota capsule-pool-solar -n solar-production
```{{exec}}

Retry the Pod. It uses half the claim:

```shell
kubectl-alice apply -n solar-production -f /root/capsule-quickstart/quickstart/guaranteed-pod.yaml
kubectl-alice wait --for=condition=Bound resourcepoolclaim/production-budget -n solar-production --timeout=120s
kubectl-alice get resourcepoolclaims -n solar-production
```{{exec}}

Deleting this claim while its resources are in use should be **denied**:

```shell
kubectl-alice delete resourcepoolclaim production-budget -n solar-production
```{{exec}}

## Exhaustion and release

Ask for the entire pool from the other namespace:

```shell
cat /root/capsule-quickstart/going-further/queued-claim.yaml
kubectl-alice apply -f /root/capsule-quickstart/going-further/queued-claim.yaml
kubectl-alice wait --for=condition=Exhausted resourcepoolclaim/test-budget -n solar-development --timeout=120s
kubectl-alice get resourcepoolclaim test-budget -n solar-development -o yaml
```{{exec}}

The claim waits because production already holds part of the pool. Its status reports exhaustion.

Delete the Pod, wait for the production claim to become unused, and release it:

```shell
kubectl-alice delete pod guaranteed -n solar-production --wait=true
kubectl-alice wait --for=condition=Bound=false resourcepoolclaim/production-budget -n solar-production --timeout=120s
kubectl-alice delete resourcepoolclaim production-budget -n solar-production
kubectl-alice wait --for=condition=Ready resourcepoolclaim/test-budget -n solar-development --timeout=120s
kubectl-alice get resourcequota capsule-pool-solar -n solar-development
```{{exec}}

The queued claim can now allocate the full budget. No Pods use it, so release it too:

```shell
kubectl-alice delete resourcepoolclaim test-budget -n solar-development
kubectl get resourcepool solar
```{{exec}}

The pool remains installed, with namespace quotas returning to zero. Create a new claim before deploying more workloads.
