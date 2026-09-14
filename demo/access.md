# Going further: browser access and OIDC

The terminal exercises used impersonation and an Alice certificate. The environment also includes Dex, Gangplank, and Headlamp for a browser-based workflow.

## Explore with Headlamp

Open [Headlamp]({{TRAFFIC_HOST1_30444}}) and sign in through Dex using:

- Email: `alice@projectcapsule.dev`{{copy}}
- Password: `alice`{{copy}}

The API server reads Dex's `name` claim as `alice`, matching the TenantOwner you created. Headlamp sends requests through Capsule Proxy, so you can explore the Solar namespaces and the replicated `app-config` ConfigMap using Alice's permissions.

The Environment chapter lists the other demo accounts. Only Alice has been assigned ownership in this walkthrough; creating more users in an identity provider does not itself give them access to a Tenant.

## Download an OIDC kubeconfig

Open [Gangplank]({{TRAFFIC_HOST1_30442}}), sign in with the same Alice credentials, and download a kubeconfig. [Gangplank](https://projectcapsule.dev/docs/proxy/gangplank/) packages the OIDC login configuration and the Proxy endpoint for use with `kubectl`.

On the machine where you download it, use the downloaded file explicitly, substituting its actual path:

```shell
kubectl --kubeconfig ./downloaded.kubeconfig get namespaces
```

This command runs on your machine, outside the KillerCoda terminal. The public endpoints and downloaded kubeconfig depend on this temporary scenario remaining alive.

Return to the KillerCoda terminal and use plain `kubectl` to compare the cluster administrator's view with Alice's view in Headlamp.
