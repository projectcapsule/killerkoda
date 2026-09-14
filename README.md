# Capsule on KillerCoda

Two independent KillerCoda scenarios are available:

| Scenario | Purpose |
| --- | --- |
| [Demo playground](demo/index.json) | The original playground, with upstream example resources and user kubeconfigs loaded during setup. |
| [Quickstart](quickstart/index.json) | A guided version of the [Capsule quickstart](https://projectcapsule.dev/docs/quickstart/), followed by [Going Further](https://projectcapsule.dev/docs/quickstart/extended/) exercises. |

Each scenario has its own setup scripts, pages, and assets. The demo playground retains its original behavior.

## Quickstart scenario

The quickstart installs its infrastructure with Flux and leaves Tenant creation to the learner. It pins Capsule to **0.14.4**, the release used by the quickstart.

| Chapters | Exercises |
| --- | --- |
| 1–5: Quickstart | Environment, Solar and Alice, namespace rules and quota, Proxy, workload QoS |
| 6–8: Policies | Pod Security Standards, Service restrictions, environment-specific permission bindings |
| 9–10: Distribution | GlobalTenantResource for LimitRanges and NetworkPolicies, TenantResource for application configuration |
| 11–12: Further exploration | ResourcePool claims, exhaustion and release, OIDC and Headlamp |

## Quickstart files

- `quickstart/index.json` defines chapter order and asset delivery. Every page, including the intro and finish, starts with a collapsible environment reference containing service links and Dex credentials.
- `quickstart/background.sh` installs the distribution and copies lesson assets to `/root/capsule-quickstart`.
- `quickstart/assets/quickstart` contains the initial Tenant, TenantOwner, namespace, and Pod examples.
- `quickstart/assets/going-further` contains policy stages and resource distribution/pool examples.
- `quickstart/assets/scripts` contains bounded reconciliation waits and Alice's certificate/kubeconfig helper.
- `quickstart/assets/distro` contains the Flux-managed services and identity configuration.

The policy stages compose as `quickstart → pod-security → services → permissions`. Each appends rules while preserving the earlier Tenant configuration. Apply the stages in chapter order. Reapplying an earlier stage rolls the Tenant back to that stage.

The walkthrough consistently uses `solar-development` (relabeled from `dev` to `test`) and `solar-production` (`prod`). It does not load the upstream playground or create unrelated Tenants. Dex's additional accounts remain available for manual exploration.

## Maintaining the quickstart examples

When updating Capsule, update the pinned chart in `quickstart/assets/distro/capsule.flux.yaml`, compare the upstream quickstart, and validate the manifests against that release's CRDs. In particular, check `TenantOwner`, `spec.rules[].enforce`, `spec.rules[].permissions.bindings`, replication settings, and ResourcePool fields.

Render all policy stages and the distribution locally:

```sh
kubectl kustomize quickstart/assets/quickstart
kubectl kustomize quickstart/assets/going-further/pod-security
kubectl kustomize quickstart/assets/going-further/services
kubectl kustomize quickstart/assets/going-further/permissions
kubectl kustomize quickstart/assets/distro
bash -n quickstart/background.sh quickstart/foreground.sh quickstart/assets/scripts/*.sh
git diff --check
```

Run the chapters in order in a fresh KillerCoda session for integration validation. Check both successful operations and expected denials, namespace counts, policy preservation, replication, claim release, and browser login. The wait helper checks observed generations as well as readiness after policy updates.

The bronze LimitRange includes a minimum memory constraint so it remains valid without defaults. The network policy example verifies resource distribution; traffic enforcement depends on the backend CNI. TenantResource uses an explicit ServiceAccount with ConfigMap permissions in both namespaces. Managed production security labels are inspected after mutation rather than expecting a rejected update.

Proxy certificate access uses the local NodePort and Proxy CA. Gangplank and Headlamp use the public endpoints, the `kubernetes` OIDC audience, and the `name` claim; keep those settings aligned with Dex and the API server.
