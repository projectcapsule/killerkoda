apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - kube-apiserver.yaml
patches:
  - target:
      group: ""
      version: v1
      kind: Pod
      name: kube-apiserver
    patch: |-
      - op: add
        path: /spec/containers/0/command/-
        value: --oidc-issuer-url=${DEX_URL}
      - op: add
        path: /spec/containers/0/command/-
        value: --oidc-client-id=kubernetes
      - op: add
        path: /spec/containers/0/command/-
        value: --oidc-username-claim=name
      - op: add
        path: /spec/containers/0/command/-
        value: --oidc-username-prefix=-
      - op: add
        path: /spec/containers/0/command/-
        value: --oidc-groups-claim=groups
      - op: add
        path: /spec/containers/0/command/-
        value: --oidc-groups-prefix=
