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

# Going further: Proxy access and personas

The Proxy can expose selected cluster resources and help people who have namespace permissions without owning a Tenant. This chapter uses the existing Solar resources and the `ProxyClusterScoped` feature enabled during installation.

## Let Bob observe production

As administrator, give Bob the Kubernetes `view` role in production and issue his own certificate:

```shell
cat /root/capsule-quickstart/going-further/proxy/bob-observer.yaml
kubectl apply -f /root/capsule-quickstart/going-further/proxy/bob-observer.yaml
bash /root/capsule-quickstart/scripts/create-user-kubeconfig.sh bob
alias kubectl-bob-proxy='kubectl --kubeconfig /root/capsule-quickstart/bob.kubeconfig'
```{{exec}}

The certificate identifies `bob` in group `projectcapsule.dev`. It does not include the synthetic `solar:operators` group used in the permissions chapter.

[RoleBinding reflection](https://projectcapsule.dev/docs/proxy/reflection/#namespaces) lets Bob discover the namespace where he has access. Namespace discovery needs no special RoleBinding label. Read its ConfigMaps by naming the namespace:

```shell
kubectl-bob-proxy get namespaces
kubectl-bob-proxy get configmaps -n solar-production
```{{exec}}

Expect the namespace list to contain only `solar-production`, followed by its ConfigMaps. If the reflector is still catching up, repeat the reads after a few seconds.

Reading the development namespace should be **Forbidden**:

```shell
kubectl-bob-proxy get configmaps -n solar-development
```{{exec}}

The `view` role excludes Secret access, so this should be **Forbidden**:

```shell
kubectl-bob-proxy get secrets -n solar-production
```{{exec}}

It also excludes writes:

```shell
kubectl-bob-proxy create configmap observer-write -n solar-production --from-literal=message=blocked
```{{exec}}

Bob can browse production without owning Solar or managing its workloads.

## Tenant-scoped Proxy settings

As administrator, create a namespaced `ProxySetting` for Alice. It selects the same customer PriorityClasses used in the scheduling chapter:

```shell
cat /root/capsule-quickstart/going-further/proxy/tenant-settings.yaml
kubectl apply -f /root/capsule-quickstart/going-further/proxy/tenant-settings.yaml
kubectl wait --for=condition=Ready proxysetting/solar-priority-classes -n solar-production --timeout=120s
kubectl-alice-proxy get priorityclasses
```{{exec}}

Expect `best-effort` and `customer`, with `operations-critical` absent. The resource uses `spec.subjects[].clusterResources`, including API group names, plural resource names, operations, and label selectors.

A direct API request should still be **Forbidden**:

```shell
kubectl-alice get priorityclasses
```{{exec}}

## Global Proxy settings

[GlobalProxySettings](https://projectcapsule.dev/docs/proxy/proxysettings/#globalproxysettings) are cluster-scoped and can grant selected users access independently of tenant ownership.

The pool created earlier carries `projectcapsule.dev/tenant: solar`. Allow Alice to read matching pools:

```shell
cat /root/capsule-quickstart/going-further/proxy/global-settings.yaml
kubectl apply -f /root/capsule-quickstart/going-further/proxy/global-settings.yaml
kubectl wait --for=condition=Ready globalproxysettings/solar-resource-pools --timeout=120s
kubectl-alice-proxy get resourcepools
kubectl-alice-proxy get resourcepool solar
```{{exec}}

The result includes the Solar pool. Both `List` and `Get` are granted through the Proxy; the rule does not grant writes or native Kubernetes cluster permissions. This direct request should remain **Forbidden**:

```shell
kubectl-alice get resourcepools
```{{exec}}

Keep these settings and Bob's RoleBinding for the browser chapter, where you can compare their views in Headlamp.
