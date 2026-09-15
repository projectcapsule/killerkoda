# Capsule on KillerCoda

Two independent KillerCoda scenarios are available:

| Scenario | Purpose |
| --- | --- |
| [Demo playground](demo/index.json) | An environment overview for free exploration, with upstream example resources and user kubeconfigs loaded during setup. |
| [Quickstart](quickstart/index.json) | A guided version of the [Capsule quickstart](https://projectcapsule.dev/docs/quickstart/), followed by [Going Further](https://projectcapsule.dev/docs/quickstart/extended/) exercises. |

Each scenario has its own setup scripts and assets. The demo has a single Environment step and retains its original overview and setup, including the foreground script. All guided lessons live in the quickstart.

## Quickstart scenario

The quickstart installs its infrastructure with Flux and leaves Tenant creation to the learner. It pins Capsule to **0.14.4**, the release used by the quickstart.

| Chapters | Exercises |
| --- | --- |
| 1–5: Quickstart | Environment, Solar and Alice, namespace rules and quota, Proxy, workload QoS |
| 6–9: Policies | Pod Security Standards, Service restrictions, environment-specific permission bindings, PriorityClass selection and defaults |
| 10–11: Distribution | GlobalTenantResource for LimitRanges and NetworkPolicies, TenantResource for application configuration and registry credentials |
| 12: Resource pools | ResourcePool claims, exhaustion and release |
| 13–15: Ownership and access | Group owners, a second Tenant, Bob's observer access, ProxySetting and GlobalProxySettings, OIDC and Headlamp |

The former demo lessons are covered by these quickstart pages:

| Demo topic | Quickstart pages |
| --- | --- |
| Tenant ownership and namespace placement | [First Tenant](quickstart/main.md), [namespaces](quickstart/namespaces.md), [groups and multiple tenants](quickstart/ownership.md) |
| PriorityClass enforcement | [Workload priority](quickstart/scheduling.md) |
| NetworkPolicy and pull Secret replication | [Platform resources](quickstart/replications.md), [Tenant resources](quickstart/tenantresources.md) |
| Resource pools | [Resource pools](quickstart/resourcepools.md) |
| Proxy listing, personas, settings, and browser integration | [Proxy basics](quickstart/proxy.md), [Proxy access](quickstart/proxy-access.md), [browser access](quickstart/access.md) |

## Quickstart files

- `quickstart/index.json` defines chapter order and asset delivery. Every page, including the intro and finish, starts with a collapsible environment reference containing service links and Dex credentials.
- `quickstart/background.sh` installs the distribution and copies lesson assets to `/root/capsule-quickstart`.
- `quickstart/assets/quickstart` contains the initial Tenant, TenantOwner, namespace, and Pod examples.
- `quickstart/assets/going-further` contains policy stages, resource distribution/pool examples, ownership resources, and Proxy settings.
- `quickstart/assets/scripts` contains bounded reconciliation waits and a certificate/kubeconfig helper for Alice and Bob.
- `quickstart/assets/distro` contains the Flux-managed services and identity configuration.

The policy stages compose as `quickstart → pod-security → services → permissions → scheduling`. The first stages append rules; scheduling adds PriorityClass selection while preserving all eight rules. Apply the stages in chapter order. Reapplying an earlier stage rolls the Tenant back to that stage.

The walkthrough uses `solar-development` (relabeled from `dev` to `test`) and `solar-production` (`prod`). A later chapter adds the minimal `lunar` Tenant and `lunar-development` to demonstrate Alice's access across tenants. Solar's policies and pool remain scoped to Solar. The quickstart does not load the upstream playground.

The permissions chapter impersonates Bob with a synthetic `solar:operators` group. The later Proxy and browser exercises use Bob's actual certificate or Dex identity and a production-only `view` RoleBinding. A separate impersonated group member, Charlie, demonstrates group ownership without adding a Dex account.

## Maintaining the quickstart examples

When updating Capsule, update the pinned chart in `quickstart/assets/distro/capsule.flux.yaml`, compare the upstream quickstart, and validate the manifests against that release's CRDs. In particular, check `TenantOwner`, `spec.rules[].enforce`, `spec.rules[].permissions.bindings`, replication settings, and ResourcePool fields.

Render all policy stages and the distribution locally:

```sh
kubectl kustomize quickstart/assets/quickstart
kubectl kustomize quickstart/assets/going-further/pod-security
kubectl kustomize quickstart/assets/going-further/services
kubectl kustomize quickstart/assets/going-further/permissions
kubectl kustomize quickstart/assets/going-further/scheduling
kubectl kustomize quickstart/assets/distro
bash -n quickstart/background.sh quickstart/foreground.sh quickstart/assets/scripts/*.sh
git diff --check
```

Run the chapters in order in a fresh KillerCoda session for integration validation. Check both successful operations and expected denials, namespace counts, policy preservation, replication, claim release, and browser login. The wait helper checks observed generations as well as readiness after policy updates.

The bronze LimitRange includes a minimum memory constraint so it remains valid without defaults. The network policy example verifies resource distribution; traffic enforcement depends on the backend CNI. TenantResource uses an explicit ServiceAccount with ConfigMap and Secret permissions in both namespaces. The registry example uses dummy credentials. Managed production security labels are inspected after mutation rather than expecting a rejected update.

Proxy certificate access uses the local NodePort and Proxy CA. Gangplank and Headlamp use the public endpoints, the `kubernetes` OIDC audience, and the `name` claim; keep those settings aligned with Dex and the API server.

The advanced Proxy examples use `clusterResources` with API group names and plural resource names. They select installed PriorityClasses and the Solar ResourcePool. Bob's namespace discovery uses the enabled RoleBinding reflector, which needs no special label for that operation. His ConfigMap reads explicitly select production. The binding omits the collection-reflection label: Proxy 0.14.1 resolves those reflected collection reads to tenant selectors, which would also include Solar's development resources.
