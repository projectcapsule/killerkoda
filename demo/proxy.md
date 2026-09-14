# List resources through Capsule Proxy

Alice can work in her namespaces, but Kubernetes does not provide a tenant-filtered namespace list. This direct API request should be **Forbidden**:

```shell
kubectl-alice get namespaces
```{{exec}}

[Capsule Proxy](https://projectcapsule.dev/docs/proxy/) provides the filtered view. As administrator, create a certificate and kubeconfig for Alice:

```shell
bash /root/capsule-demo/scripts/create-alice-kubeconfig.sh
alias kubectl-alice-proxy='kubectl --kubeconfig /root/capsule-demo/alice.kubeconfig'
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
