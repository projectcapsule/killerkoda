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

# Create your first Tenant

Follow the [Capsule quickstart](https://projectcapsule.dev/docs/quickstart/#create-your-first-tenant) as the **cluster administrator**. A Tenant defines the namespaces Alice may create and the policies those namespaces must follow.

Review the two resources:

```shell
cat /root/capsule-quickstart/quickstart/solar.yaml
cat /root/capsule-quickstart/quickstart/alice.yaml
```{{exec}}

The Tenant gives `alice` ownership, allows **two namespaces**, and requires the `solar-` prefix. Its `spec.rules` require an `environment` label with values `dev`, `test`, or `prod`; omitted labels default to `dev`. Production accepts only `Guaranteed` Pods, while dev and test accept all three QoS classes.

The `TenantOwner` registers Alice as a Capsule user. Its `projectcapsule.dev/tenant: solar` label associates it with the Tenant. Registration does not create a login credential; we use impersonation first and issue a certificate in the Proxy chapter.

```shell
kubectl apply -k /root/capsule-quickstart/quickstart
kubectl wait --for=condition=Ready tenantowner/alice --timeout=120s
bash /root/capsule-quickstart/scripts/wait-tenant.sh
```{{exec}}

Inspect the reconciled ownership and registered users:

```shell
kubectl get tenant solar
kubectl get tenant solar -o jsonpath='{.status.owners}' | jq
kubectl get capsuleconfiguration default -o jsonpath='{.status.users}' | jq
```{{exec}}

Expect an active Tenant with Alice in `.status.owners` and no namespaces yet. The administrator manages the Tenant; Alice manages resources inside its namespaces.
