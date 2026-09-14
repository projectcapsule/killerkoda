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

# Capsule: from quickstart to platform policies

Build a multi-tenant Kubernetes environment with [Capsule](https://projectcapsule.dev/docs/quickstart/).

Start as the cluster administrator, create the `solar` Tenant, then work as its owner `alice`. You will test namespace boundaries, list resources through Capsule Proxy, and run workloads under environment-specific rules.

The later chapters follow [Going Further](https://projectcapsule.dev/docs/quickstart/extended/): Pod Security Standards, Service restrictions, permissions, resource distribution, and resource pools. Finish by exploring OIDC login and Headlamp.

The cluster, Capsule, Proxy, and browser services are installed automatically. Wait for **Ready to Play!** before starting; installation can take several minutes. The Tenant and example workloads are created by you during the chapters.

Complete the chapters in order. Commands marked as expected denials are part of the exercises.
