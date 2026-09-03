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

The password for each demo user is the same as its username.

| Username | Password | Groups |
| --- | --- | --- |
| `alice` | `alice` | `capsule-users`, `solar-users` |
| `bob` | `bob` | `capsule-users`, `green-users` |
| `gatsby` | `gatsby` | `capsule-users`, `wind-users` |
| `renewable` | `renewable` | `capsule-users`, `renewable-users` |
| `admin` | `admin` | `capsule-admins` |
