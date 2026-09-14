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

# List resources through Capsule Proxy

Alice can work in her namespaces, but Kubernetes does not provide a tenant-filtered namespace list. This direct API request should be **Forbidden**:

```shell
kubectl-alice get namespaces
```{{exec}}

[Capsule Proxy](https://projectcapsule.dev/docs/proxy/) provides the filtered view. As administrator, create a certificate and kubeconfig for Alice:

```shell
bash /root/capsule-quickstart/scripts/create-user-kubeconfig.sh alice
alias kubectl-alice-proxy='kubectl --kubeconfig /root/capsule-quickstart/alice.kubeconfig'
```{{exec}}

The helper uses a Kubernetes CertificateSigningRequest for `alice` in group `projectcapsule.dev`. It configures the Proxy's CA and local NodePort endpoint `https://127.0.0.1:30443`. This replaces the quickstart's KinD port mapping in KillerCoda.

List namespaces using Alice's actual credentials:

```shell
kubectl-alice-proxy get namespaces
```{{exec}}

Expect only `solar-development` and `solar-production`. System namespaces such as `kube-system` are absent.

The same filtering supports listing namespaced resources across the tenant:

```shell
kubectl-alice-proxy get pods -A
kubectl-alice-proxy get configmaps -A
```{{exec}}

There are no demo Pods yet. Keep using plain `kubectl` for administrator actions and `kubectl-alice` for tenant actions in the following chapters. The separate kubeconfig leaves your administrator context available. Later, the browser access chapter introduces Dex, Gangplank, and Headlamp.
