# Environment

This scenario exposes the following services. The links are generated for your
current KillerCoda environment and remain valid for the lifetime of the scenario.

| Service | Description | Link |
| --- | --- | --- |
| Gangplank | OIDC login and kubeconfig download | <a href="{{TRAFFIC_HOST1_30442}}"><img src="https://projectcapsule.dev/favicons/android-96x96.png" alt="" width="24" height="24"> Open Gangplank</a> |
| Capsule Proxy | Tenant-aware Kubernetes API endpoint | <a href="{{TRAFFIC_HOST1_30443}}"><img src="https://projectcapsule.dev/favicons/android-96x96.png" alt="" width="24" height="24"> Open Capsule Proxy</a> |
| Headlamp | Kubernetes web interface | <a href="{{TRAFFIC_HOST1_30444}}"><img src="https://headlamp.dev/img/favicon.png" alt="" width="24" height="24"> Open Headlamp</a> |
| Dex | OpenID Connect identity provider | <a href="{{TRAFFIC_HOST1_32556}}"><img src="https://dexidp.io/favicons/favicon-96x96.png" alt="" width="24" height="24"> Open Dex</a> |

You can also open any exposed port from KillerCoda's **Traffic / Ports** menu:
{{TRAFFIC_SELECTOR}}

## Dex users

Sign in with the user's email address. The password is the part before
`@projectcapsule.dev`.

| Login | Password | Groups |
| --- | --- | --- |
| `alice@projectcapsule.dev`{{copy}} | `alice`{{copy}} | `capsule-users`, `solar-users` |
| `bob@projectcapsule.dev`{{copy}} | `bob`{{copy}} | `capsule-users`, `green-users` |
| `gatsby@projectcapsule.dev`{{copy}} | `gatsby`{{copy}} | `capsule-users`, `wind-users` |
| `renewable@projectcapsule.dev`{{copy}} | `renewable`{{copy}} | `capsule-users`, `renewable-users` |
| `admin@projectcapsule.dev`{{copy}} | `admin`{{copy}} | `capsule-admins` |
