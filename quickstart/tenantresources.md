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

# Going further: tenant-owned resource distribution

A [TenantResource](https://projectcapsule.dev/docs/replications/tenant/) is namespaced and distributes resources within its own Tenant. Alice can use it without asking the administrator to create a GlobalTenantResource.

## Give replication its own identity

This release defaults tenant replication to a ServiceAccount. Alice creates a dedicated account and grants it ConfigMap and Secret permissions in both namespaces:

```shell
cat /root/capsule-quickstart/going-further/replication-rbac.yaml
kubectl-alice apply -f /root/capsule-quickstart/going-further/replication-rbac.yaml
```{{exec}}

The TenantResource's `spec.serviceAccount.name` selects this account in `solar-development`. The RoleBindings let it read the source and manage the production copy.

## Replicate a ConfigMap

Create a source ConfigMap in the test namespace:

```shell
kubectl-alice create configmap app-config -n solar-development --from-literal=message=hello-solar
kubectl-alice label configmap app-config -n solar-development distribute=solar
```{{exec}}

Select that source by label and replicate it into production:

```shell
cat /root/capsule-quickstart/going-further/tenantresource.yaml
kubectl-alice apply -f /root/capsule-quickstart/going-further/tenantresource.yaml
kubectl-alice wait --for=condition=Ready tenantresource/solar-app-config -n solar-development --timeout=120s
kubectl wait --for=create configmap/app-config -n solar-production --timeout=120s
kubectl-alice get tenantresource solar-app-config -n solar-development -o jsonpath='{.status.serviceAccount}{"\n"}'
kubectl-alice get configmap app-config -n solar-production -o yaml
```{{exec}}

The destination selector excludes the source namespace. The copy should contain `message: hello-solar`.

Update the source and wait for the copy to change:

```shell
kubectl-alice patch configmap app-config -n solar-development --type=merge -p '{"data":{"message":"updated-by-alice"}}'
kubectl-alice wait --for=jsonpath='{.data.message}'=updated-by-alice configmap/app-config -n solar-production --timeout=120s
```{{exec}}

The demo uses a short `resyncPeriod: 10s` for this exercise. Leave this ConfigMap in place to find it through Headlamp later.

## Distribute registry credentials

The same mechanism can distribute an image pull Secret. This example contains dummy credentials for `registry.example.com`; it does not contact a registry:

```shell
cat /root/capsule-quickstart/going-further/pullsecret.yaml
kubectl-alice apply -f /root/capsule-quickstart/going-further/pullsecret.yaml
cat /root/capsule-quickstart/going-further/pullsecret-replication.yaml
kubectl-alice apply -f /root/capsule-quickstart/going-further/pullsecret-replication.yaml
kubectl-alice wait --for=condition=Ready tenantresource/solar-registry-credentials -n solar-development --timeout=120s
kubectl-alice get secret registry-credentials -n solar-production -o jsonpath='{.type}{"\n"}'
```{{exec}}

Expect `kubernetes.io/dockerconfigjson`. Both replications use the dedicated ServiceAccount; its RoleBindings include the permissions for each resource type. Keep the source Secret in the development namespace and update it there when rotating credentials.

Replication makes the Secret available in production. A workload would also need to reference it in `spec.imagePullSecrets` to use those credentials for an image pull.
