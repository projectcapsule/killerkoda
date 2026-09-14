# Going further: tenant-owned resource distribution

A [TenantResource](https://projectcapsule.dev/docs/replications/tenant/) is namespaced and distributes resources within its own Tenant. Alice can use it without asking the administrator to create a GlobalTenantResource.

## Give replication its own identity

This release defaults tenant replication to a ServiceAccount. Alice creates a dedicated account and grants it ConfigMap permissions in both namespaces:

```shell
cat /root/capsule-demo/going-further/replication-rbac.yaml
kubectl-alice apply -f /root/capsule-demo/going-further/replication-rbac.yaml
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
cat /root/capsule-demo/going-further/tenantresource.yaml
kubectl-alice apply -f /root/capsule-demo/going-further/tenantresource.yaml
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

The demo uses a short `resyncPeriod: 10s` for this exercise. In a real platform, the same mechanism can distribute application settings or registry credentials within a tenant. Leave this ConfigMap in place to find it through Headlamp later.
