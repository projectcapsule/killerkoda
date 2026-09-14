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

# Going further: groups and multiple tenants

The earlier chapters used one user and one Tenant. Extend that model with a group owner and a second Tenant. [Tenant ownership](https://projectcapsule.dev/docs/tenants/permissions/) can come from several subjects at once.

## Give a team ownership

As administrator, register the `solar-users` group with a TenantOwner:

```shell
cat /root/capsule-quickstart/going-further/ownership/solar-group.yaml
kubectl apply -f /root/capsule-quickstart/going-further/ownership/solar-group.yaml
kubectl wait --for=condition=Ready tenantowner/solar-team --timeout=120s
kubectl wait --for=jsonpath='{.status.tenants[0]}'=solar tenantowner/solar-team --timeout=120s
bash /root/capsule-quickstart/scripts/wait-tenant.sh
kubectl get tenant solar -o jsonpath='{.status.owners}' | jq
```{{exec}}

Solar now has Alice and the group as owners. Its quota and policies still apply to their shared namespaces.

Simulate another group member, Charlie, and inspect the application configuration:

```shell
alias kubectl-teammate='kubectl --as charlie --as-group projectcapsule.dev --as-group solar-users'
kubectl-teammate get configmap app-config -n solar-production
```{{exec}}

Charlie is an impersonated example identity; no Dex account or certificate is created for him.

## Give Alice another Tenant

As administrator, create `lunar`. It has Alice as its owner, a one-namespace quota, and its own prefix requirement:

```shell
cat /root/capsule-quickstart/going-further/ownership/lunar.yaml
kubectl apply -f /root/capsule-quickstart/going-further/ownership/lunar.yaml
bash /root/capsule-quickstart/scripts/wait-tenant.sh lunar
```{{exec}}

A namespace whose prefix matches neither Tenant should be **denied**:

```shell
kubectl-alice create namespace shared-development
```{{exec}}

With prefix enforcement, Capsule can choose the Tenant from the name. An explicit `capsule.clastix.io/tenant` label also makes the intended placement clear:

```shell
cat /root/capsule-quickstart/going-further/ownership/namespace.yaml
kubectl-alice apply -f /root/capsule-quickstart/going-further/ownership/namespace.yaml
bash /root/capsule-quickstart/scripts/wait-tenant.sh lunar
kubectl get tenants
```{{exec}}

Solar still has two namespaces; Lunar has one. Lunar's policy and resource budget are independent of Solar's.

## See all owned namespaces through the Proxy

Alice's existing certificate works for both Tenants:

```shell
kubectl-alice-proxy get namespaces -L capsule.clastix.io/tenant
```{{exec}}

Expect `solar-development`, `solar-production`, and `lunar-development`. Charlie's group only owns Solar, so this request should be **Forbidden**:

```shell
kubectl-teammate get configmaps -n lunar-development
```{{exec}}

Keep Lunar for the final browser exercise. It is a minimal Tenant for demonstrating placement; Solar's security rules and pool do not apply to it.
