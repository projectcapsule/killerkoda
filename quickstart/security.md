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

# Going further: Pod Security Standards

Use [metadata rules](https://projectcapsule.dev/docs/rules/enforcement/metadata/) to control Kubernetes Pod Security Admission. Dev and test may select `restricted` or `baseline`, defaulting to `restricted`; production gets a managed `restricted` label.

As administrator, review and apply the next policy stage:

```shell
cat /root/capsule-quickstart/going-further/pod-security/rules.yaml
kubectl apply -k /root/capsule-quickstart/going-further/pod-security
bash /root/capsule-quickstart/scripts/wait-tenant.sh
```{{exec}}

Each stage uses Kustomize to append rules to the preceding stage. The complete Tenant still contains its owners, namespace quota, prefix requirement, environment labels, and QoS rules.

## Defaults and allowed values

Defaults are applied on admission. Update the existing test namespace as Alice to exercise the new default:

```shell
kubectl-alice annotate namespace solar-development demo.projectcapsule.dev/security=enabled --overwrite
kubectl-alice get namespace solar-development -L pod-security.kubernetes.io/enforce
```{{exec}}

Expect `restricted`. Alice can select `baseline` in this environment:

```shell
kubectl-alice label namespace solar-development pod-security.kubernetes.io/enforce=baseline --overwrite
```{{exec}}

Trying `privileged` should be **denied**:

```shell
kubectl-alice label namespace solar-development pod-security.kubernetes.io/enforce=privileged --overwrite
```{{exec}}

## Managed production metadata

Try weakening production's label, then inspect what was stored:

```shell
kubectl-alice label namespace solar-production pod-security.kubernetes.io/enforce=privileged --overwrite
kubectl-alice get namespace solar-production -L pod-security.kubernetes.io/enforce
```{{exec}}

Expect `restricted`: Capsule's mutating webhook restores the managed value even when the update command succeeds. Kubernetes Pod Security Admission uses that label to enforce the security standard. The Pod examples already include the non-root user, seccomp profile, and container security settings needed for `restricted`.
