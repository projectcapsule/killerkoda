# Your environment

KillerCoda provides a Kubernetes cluster with Capsule **0.14.4**, matching the [quickstart](https://projectcapsule.dev/docs/quickstart/). Flux installs Capsule, Capsule Proxy, cert-manager, Dex, Gangplank, and Headlamp.

The quickstart's KinD and Helm installation steps have already been handled by the scenario. Once the terminal displays **Ready to Play!**, verify the installation:

```shell
kubectl get pods -n capsule-system
kubectl get helmreleases -n flux-system
kubectl get tenants
```{{exec}}

Expect no Tenants yet. You will create Solar in the next chapter.

## Working through the chapters

The terminal starts as **cluster administrator**. Later, `kubectl-alice` impersonates the Tenant owner and `kubectl-alice-proxy` uses Alice's own certificate through the Proxy. Plain `kubectl` continues to run as administrator.

Example files are in `/root/capsule-demo`. Each policy stage builds on the previous one; keep the namespaces and labels created in earlier chapters.

If installation fails, inspect the setup log:

```shell
tail -n 100 /tmp/scenario-setup.log
```{{exec}}

## Browser services

| Service | Purpose | Link |
| --- | --- | --- |
| Gangplank | OIDC login and kubeconfig download | [Open Gangplank]({{TRAFFIC_HOST1_30442}}) |
| Capsule Proxy | Tenant-aware Kubernetes API | [Proxy endpoint]({{TRAFFIC_HOST1_30443}}) |
| Headlamp | Kubernetes web interface | [Open Headlamp]({{TRAFFIC_HOST1_30444}}) |
| Dex | OpenID Connect identity provider | [Open Dex]({{TRAFFIC_HOST1_32556}}) |

The Proxy endpoint is an API, not a login page. Use Headlamp or Gangplank for browser login. You can also open exposed ports from KillerCoda's **Traffic / Ports** menu: {{TRAFFIC_SELECTOR}}

## Dex accounts

| Login | Password | Groups |
| --- | --- | --- |
| `alice@projectcapsule.dev`{{copy}} | `alice`{{copy}} | `capsule-users`, `solar-users` |
| `bob@projectcapsule.dev`{{copy}} | `bob`{{copy}} | `capsule-users`, `green-users` |
| `gatsby@projectcapsule.dev`{{copy}} | `gatsby`{{copy}} | `capsule-users`, `wind-users` |
| `renewable@projectcapsule.dev`{{copy}} | `renewable`{{copy}} | `capsule-users`, `renewable-users` |
| `admin@projectcapsule.dev`{{copy}} | `admin`{{copy}} | `capsule-admins` |

These are disposable demo credentials. Alice receives Solar ownership in the next chapter; the other non-admin accounts remain available for your own experiments.
