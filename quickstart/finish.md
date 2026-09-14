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

# Continue exploring Capsule

You created Tenants and TenantOwners, enforced namespace names and labels, checked quotas, and listed resources through Capsule Proxy. The later chapters added workload priority, security rules, environment-specific permissions, ConfigMap and registry-secret distribution, and a resource pool. You also compared group ownership, access across tenants, and Bob's production observer permissions.

Continue experimenting with the two Solar namespaces and the minimal Lunar Tenant. Solar's pool requires a new ResourcePoolClaim before you deploy more Pods there. The ProxySetting, GlobalProxySettings, and Bob's RoleBinding remain available for further exploration.

Useful next steps:

- [Quickstart and Going Further](https://projectcapsule.dev/docs/quickstart/)
- [Rules](https://projectcapsule.dev/docs/rules/)
- [Tenant permissions](https://projectcapsule.dev/docs/tenants/permissions/)
- [Proxy settings](https://projectcapsule.dev/docs/proxy/proxysettings/)
- [RoleBinding reflection](https://projectcapsule.dev/docs/proxy/reflection/)
- [Resource Pools](https://projectcapsule.dev/docs/resource-management/resourcepools/)
- [Custom Quotas](https://projectcapsule.dev/docs/resource-management/customquotas/)
- [Capsule source and community](https://github.com/projectcapsule/capsule)

The environment and its login endpoints are temporary. Save any examples you want to keep before ending the scenario.
