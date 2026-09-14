# Create your first Tenant

Follow the [Capsule quickstart](https://projectcapsule.dev/docs/quickstart/#create-your-first-tenant) as the **cluster administrator**. A Tenant defines the namespaces Alice may create and the policies those namespaces must follow.

Review the two resources:

```shell
cat /root/capsule-demo/quickstart/solar.yaml
cat /root/capsule-demo/quickstart/alice.yaml
```{{exec}}

The Tenant gives `alice` ownership, allows **two namespaces**, and requires the `solar-` prefix. Its `spec.rules` require an `environment` label with values `dev`, `test`, or `prod`; omitted labels default to `dev`. Production accepts only `Guaranteed` Pods, while dev and test accept all three QoS classes.

The `TenantOwner` registers Alice as a Capsule user. Its `projectcapsule.dev/tenant: solar` label associates it with the Tenant. Registration does not create a login credential; we use impersonation first and issue a certificate in the Proxy chapter.

```shell
kubectl apply -k /root/capsule-demo/quickstart
kubectl wait --for=condition=Ready tenantowner/alice --timeout=120s
bash /root/capsule-demo/scripts/wait-tenant.sh
```{{exec}}

Inspect the reconciled ownership and registered users:

```shell
kubectl get tenant solar
kubectl get tenant solar -o jsonpath='{.status.owners}' | jq
kubectl get capsuleconfiguration default -o jsonpath='{.status.users}' | jq
```{{exec}}

Expect an active Tenant with Alice in `.status.owners` and no namespaces yet. The administrator manages the Tenant; Alice manages resources inside its namespaces.
