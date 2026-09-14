# Work as Alice

Use the same identity as the [quickstart](https://projectcapsule.dev/docs/quickstart/#as-a-tenant-owner). This alias uses the administrator's impersonation permission to simulate Alice:

```shell
alias kubectl-alice='kubectl --as alice --as-group projectcapsule.dev'
```{{exec}}

Commands named `kubectl-alice` run as the tenant owner; plain `kubectl` remains the cluster administrator. Recreate the alias if you open another terminal.

## Naming and default metadata

This command should be **denied** because the name lacks the tenant prefix:

```shell
kubectl-alice create namespace development
```{{exec}}

Use the correct prefix:

```shell
kubectl-alice create namespace solar-development -o yaml
bash /root/capsule-demo/scripts/wait-tenant.sh
```{{exec}}

The result includes `capsule.clastix.io/tenant: solar` and the default `environment: dev` label.

## Allowed label values

`staging` is outside the allowed set, so this update should be **denied**:

```shell
kubectl-alice label namespace solar-development environment=staging --overwrite
```{{exec}}

`test` is allowed:

```shell
kubectl-alice label namespace solar-development environment=test --overwrite
kubectl-alice get namespace solar-development --show-labels
```{{exec}}

Keep this namespace labeled `test` for the later LimitRange example; its name stays `solar-development`.

## Namespace quota

Create the second namespace with `environment: prod`:

```shell
cat /root/capsule-demo/quickstart/production.yaml
kubectl-alice apply -f /root/capsule-demo/quickstart/production.yaml
bash /root/capsule-demo/scripts/wait-tenant.sh
```{{exec}}

A third namespace should be **denied** because the quota is two:

```shell
kubectl-alice create namespace solar-staging
```{{exec}}

The administrator can see the resulting namespace count:

```shell
kubectl get tenant solar
kubectl get namespaces -l capsule.clastix.io/tenant=solar -L environment
```{{exec}}

Keep both namespaces. Every following chapter builds on them.
