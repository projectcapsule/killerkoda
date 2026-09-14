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

# Going further: permissions by environment

Alice is still the Tenant owner. Give a separate operations group `edit` access in dev and test, and `view` access in production through [rule permission bindings](https://projectcapsule.dev/docs/tenants/permissions/).

As administrator:

```shell
cat /root/capsule-quickstart/going-further/permissions/rules.yaml
kubectl apply -k /root/capsule-quickstart/going-further/permissions
bash /root/capsule-quickstart/scripts/wait-tenant.sh
```{{exec}}

Capsule maintains the RoleBindings in matching namespaces:

```shell
kubectl get rolebindings -n solar-development
kubectl get rolebindings -n solar-production
```{{exec}}

Simulate Bob as a member of `solar:operators`. This alias supplies the groups explicitly; it does not change Bob's Dex login:

```shell
alias kubectl-operator='kubectl --as bob --as-group projectcapsule.dev --as-group solar:operators'
kubectl-operator auth can-i create configmaps -n solar-development
kubectl-operator auth can-i create configmaps -n solar-production
kubectl-operator auth can-i get pods -n solar-production
```{{exec}}

Expect **yes**, **no**, **yes**. If RBAC is still updating, repeat the checks after the bindings appear.

Exercise the permissions with actual writes. The first command succeeds:

```shell
kubectl-operator create configmap operator-note -n solar-development --from-literal=message=hello
```{{exec}}

The same operation in production should be **Forbidden**:

```shell
kubectl-operator create configmap operator-note -n solar-production --from-literal=message=hello
```{{exec}}

Clean up the test object:

```shell
kubectl-operator delete configmap operator-note -n solar-development
```{{exec}}

Permission bindings give operators access within namespaces. They do not make the group a Tenant owner or grant it the right to create more tenant namespaces.
