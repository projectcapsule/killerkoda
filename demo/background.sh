#!/bin/bash
set -Eeuo pipefail
set -x
trap 'touch /tmp/failed' ERR

echo starting...

export GANGPLANK_URL="$(sed 's/PORT/30442/g' /etc/killercoda/host)"
export PROXY_URL="$(sed 's/PORT/30443/g' /etc/killercoda/host)"
export HEADLAMP_URL="$(sed 's/PORT/30444/g' /etc/killercoda/host)"
export DEX_URL="$(sed 's/PORT/32556/g' /etc/killercoda/host)"

APISERVER_MANIFEST=/etc/kubernetes/manifests/kube-apiserver.yaml

# Install Flux
kubectl kustomize /root/.assets/flux/ | kubectl apply -f -

# Install Distribution
kubectl kustomize /root/.assets/distro/ \
  | envsubst '${PROXY_URL} ${HEADLAMP_URL} ${GANGPLANK_URL} ${DEX_URL}' \
  | kubectl apply -f -

# Install Plugins
kubectl krew install oidc-login

# Install Flux
curl -s https://fluxcd.io/install.sh | sudo bash

# Wait for Dex before enabling it as an API-server issuer.
kubectl wait --namespace flux-system --for=condition=ready helmrelease/dex --timeout=10m

for attempt in $(seq 1 120); do
  discovery_document=""
  if discovery_document="$(curl --fail --silent --show-error "${DEX_URL}/.well-known/openid-configuration" 2>/dev/null)"; then
    compact_document="${discovery_document//[[:space:]]/}"
    if [[ "${compact_document}" == *"\"issuer\":\"${DEX_URL}\""* ]]; then
      break
    fi
  fi
  if [ "${attempt}" -eq 120 ]; then
    echo "Dex discovery did not advertise the expected issuer ${DEX_URL}" >&2
    exit 1
  fi
  sleep 2
done

# Add the OIDC flags directly to the kubeadm-managed static Pod manifest. Dex
# is already ready, so the restarted API server can discover the issuer while
# starting. Kustomize avoids relying on the manifest's line ordering.
if grep -Fq -- "--authentication-config=" "${APISERVER_MANIFEST}"; then
  echo "Cannot combine kube-apiserver OIDC flags with --authentication-config" >&2
  exit 1
fi

previous_apiserver_uid="$(kubectl get pod \
  --namespace kube-system \
  --selector component=kube-apiserver \
  --output jsonpath='{.items[0].metadata.uid}')"

apiserver_patch_dir="$(mktemp -d)"
cp "${APISERVER_MANIFEST}" "${apiserver_patch_dir}/kube-apiserver.yaml"
envsubst '${DEX_URL}' \
  < /root/.assets/apiserver/kustomization.yaml.tpl \
  > "${apiserver_patch_dir}/kustomization.yaml"

rendered_apiserver_manifest="$(mktemp /etc/kubernetes/manifests/.kube-apiserver.yaml.XXXXXX)"
kubectl kustomize "${apiserver_patch_dir}" > "${rendered_apiserver_manifest}"

required_oidc_flags=(
  "--oidc-issuer-url=${DEX_URL}"
  "--oidc-client-id=kubernetes"
  "--oidc-username-claim=name"
  "--oidc-username-prefix=-"
  "--oidc-groups-claim=groups"
  "--oidc-groups-prefix="
)
for required_oidc_flag in "${required_oidc_flags[@]}"; do
  if ! grep -Fq -- "${required_oidc_flag}" "${rendered_apiserver_manifest}"; then
    echo "Rendered API-server manifest is missing ${required_oidc_flag}" >&2
    exit 1
  fi
done

chmod --reference="${APISERVER_MANIFEST}" "${rendered_apiserver_manifest}"
chown --reference="${APISERVER_MANIFEST}" "${rendered_apiserver_manifest}"
mv "${rendered_apiserver_manifest}" "${APISERVER_MANIFEST}"
rm -r "${apiserver_patch_dir}"

for attempt in $(seq 1 180); do
  current_apiserver_uid="$(kubectl get pod \
    --namespace kube-system \
    --selector component=kube-apiserver \
    --output jsonpath='{.items[0].metadata.uid}' \
    2>/dev/null || true)"
  current_apiserver_command="$(kubectl get pod \
    --namespace kube-system \
    --selector component=kube-apiserver \
    --output jsonpath='{.items[0].spec.containers[0].command}' \
    2>/dev/null || true)"
  if [ -n "${current_apiserver_uid}" ] \
    && [ "${current_apiserver_uid}" != "${previous_apiserver_uid}" ] \
    && [[ "${current_apiserver_command}" == *"--oidc-issuer-url=${DEX_URL}"* ]] \
    && kubectl get --raw=/readyz >/dev/null 2>&1; then
    break
  fi
  if [ "${attempt}" -eq 180 ]; then
    echo "API server did not restart successfully with Dex OIDC enabled" >&2
    exit 1
  fi
  sleep 1
done

# Verify the complete distribution only after OIDC is active. In particular,
# Headlamp depends on Dex and must not be exposed as ready before login works.
kubectl wait --namespace flux-system --for=condition=ready helmrelease --all --timeout=15m

# Apply Objects (Playground)
git clone https://github.com/projectcapsule/capsule.git /root/.assets/objects
cd /root/.assets/objects/playground
make apply-platform
make apply-user

# Create Kubeconfigs
kubectl get secret capsule-proxy -n capsule-system -o jsonpath='{.data.ca\.crt}'

export ROOT_CA=$(kubectl get secret capsule-proxy -n capsule-system -o jsonpath='{.data.ca\.crt}')
mkdir -p /root/.kubconfigs && cd /root/.kubconfigs

curl -s https://raw.githubusercontent.com/projectcapsule/capsule/main/hack/create-user.sh | bash -s -- alice solar projectcapsule.dev,solar
mv alice-solar.kubeconfig alice.kubeconfig
KUBECONFIG=alice.kubeconfig kubectl config set clusters.kubernetes.certificate-authority-data ${ROOT_CA}
KUBECONFIG=alice.kubeconfig kubectl config set clusters.kubernetes.server https://127.0.0.1:9001

curl -s https://raw.githubusercontent.com/projectcapsule/capsule/main/hack/create-user.sh | bash -s -- bob wind projectcapsule.dev,wind
mv bob-wind.kubeconfig bob.kubeconfig
KUBECONFIG=bob.kubeconfig kubectl config set clusters.kubernetes.certificate-authority-data ${ROOT_CA}
KUBECONFIG=bob.kubeconfig kubectl config set clusters.kubernetes.server https://127.0.0.1:9001

curl -s https://raw.githubusercontent.com/projectcapsule/capsule/main/hack/create-user.sh | bash -s -- joe green projectcapsule.dev,green
mv joe-green.kubeconfig joe.kubeconfig
KUBECONFIG=joe.kubeconfig kubectl config set clusters.kubernetes.certificate-authority-data ${ROOT_CA}
KUBECONFIG=joe.kubeconfig kubectl config set clusters.kubernetes.server https://127.0.0.1:9001

touch /tmp/finished
