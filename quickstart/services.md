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

# Going further: service restrictions

Restrict [Service types and ExternalName destinations](https://projectcapsule.dev/docs/rules/enforcement/services/) as administrator:

```shell
cat /root/capsule-quickstart/going-further/services/rules.yaml
kubectl apply -k /root/capsule-quickstart/going-further/services
bash /root/capsule-quickstart/scripts/wait-tenant.sh
```{{exec}}

The appended rule allows `ClusterIP` and `ExternalName`. External names must end in `.solar.svc.company.com`.

As Alice, create an allowed internal Service:

```shell
kubectl-alice create service clusterip internal -n solar-development --tcp=80:8080
```{{exec}}

Creating a `NodePort` should be **denied**. The rule also excludes `LoadBalancer`:

```shell
kubectl-alice create service nodeport public -n solar-development --tcp=80:8080
```{{exec}}

An external name outside the permitted domain should be **denied**:

```shell
kubectl-alice create service externalname outside -n solar-development --external-name=example.com
```{{exec}}

An allowed name succeeds:

```shell
kubectl-alice create service externalname database -n solar-development --external-name=db.solar.svc.company.com
kubectl-alice get services -n solar-development
```{{exec}}

These exercises check Service admission; no database or backing application is deployed. Remove the accepted Services:

```shell
kubectl-alice delete service internal database -n solar-development
```{{exec}}
