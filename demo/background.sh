#!/bin/bash
set -Eeuo pipefail

SETUP_LOG=/tmp/scenario-setup.log
SETUP_ERROR=/tmp/scenario-setup-error.log

: > "${SETUP_LOG}"
rm -f "${SETUP_ERROR}" /tmp/failed
exec > >(tee -a "${SETUP_LOG}") 2>&1

setup_failed() {
  local status="$1"
  local line="$2"
  local command="$3"

  trap - ERR
  {
    echo "Scenario setup failed with exit code ${status}."
    echo "Line ${line}: ${command}"
  } > "${SETUP_ERROR}"
  cat "${SETUP_ERROR}" >&2
  touch /tmp/failed
  exit "${status}"
}

fail_setup() {
  setup_failed 1 "${BASH_LINENO[0]}" "$1"
}

setup_exited() {
  local status="$1"

  if [ "${status}" -ne 0 ] && [ ! -f /tmp/failed ]; then
    echo "Scenario setup exited unexpectedly with status ${status}." > "${SETUP_ERROR}"
    touch /tmp/failed
  fi
}

set -x
trap 'setup_failed "$?" "$LINENO" "$BASH_COMMAND"' ERR
trap 'setup_exited "$?"' EXIT

echo starting...

export KREW_ROOT=/root/.krew
export PATH="${KREW_ROOT}/bin:${PATH}"

# Install Krew before any kubectl plugins. Publishing the two commands in
# /usr/local/bin also makes them available in terminal sessions that were
# opened before this background script updated root's shell configuration.
if [ ! -x "${KREW_ROOT}/bin/kubectl-krew" ]; then
  krew_install_dir="$(mktemp -d)"
  krew_os="$(uname | tr '[:upper:]' '[:lower:]')"
  krew_arch="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')"
  krew_archive="krew-${krew_os}_${krew_arch}"

  curl --fail --silent --show-error --location \
    --output "${krew_install_dir}/${krew_archive}.tar.gz" \
    "https://github.com/kubernetes-sigs/krew/releases/latest/download/${krew_archive}.tar.gz"
  tar --extract --gzip \
    --file "${krew_install_dir}/${krew_archive}.tar.gz" \
    --directory "${krew_install_dir}"
  "${krew_install_dir}/${krew_archive}" install krew
  rm -r "${krew_install_dir}"
fi

krew_path_line='export PATH="/root/.krew/bin:$PATH"'
if ! grep -Fqx "${krew_path_line}" /root/.bashrc; then
  printf '\n%s\n' "${krew_path_line}" >> /root/.bashrc
fi

if [ ! -e /usr/local/bin/kubectl-krew ] && [ ! -L /usr/local/bin/kubectl-krew ]; then
  ln -s "${KREW_ROOT}/bin/kubectl-krew" /usr/local/bin/kubectl-krew
fi

if ! kubectl krew list | grep -Fxq oidc-login; then
  kubectl krew install oidc-login
fi

if [ ! -e /usr/local/bin/kubectl-oidc_login ] && [ ! -L /usr/local/bin/kubectl-oidc_login ]; then
  ln -s "${KREW_ROOT}/bin/kubectl-oidc_login" /usr/local/bin/kubectl-oidc_login
fi
kubectl oidc-login --help >/dev/null

export GANGPLANK_URL="$(sed 's/PORT/30442/g' /etc/killercoda/host)"
export PROXY_URL="$(sed 's/PORT/30443/g' /etc/killercoda/host)"
# Certificate DNS names need only the hostname, without the scheme, port, or path.
PROXY_HOST="${PROXY_URL#*://}"
export PROXY_HOST="${PROXY_HOST%%[:/?#]*}"
export HEADLAMP_URL="$(sed 's/PORT/30444/g' /etc/killercoda/host)"
export DEX_URL="$(sed 's/PORT/32556/g' /etc/killercoda/host)"

APISERVER_MANIFEST=/etc/kubernetes/manifests/kube-apiserver.yaml

# Install Flux
kubectl kustomize /root/.assets/flux/ | kubectl apply -f -

# Install Distribution
kubectl kustomize /root/.assets/distro/ \
  | envsubst '${PROXY_URL} ${PROXY_HOST} ${HEADLAMP_URL} ${GANGPLANK_URL} ${DEX_URL}' \
  | kubectl apply -f -

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
    fail_setup "Dex discovery did not advertise the expected issuer ${DEX_URL}"
  fi
  sleep 2
done

# Add the OIDC flags directly to the kubeadm-managed static Pod manifest. Dex
# is already ready, so the restarted API server can discover the issuer while
# starting. Kustomize avoids relying on the manifest's line ordering.
if grep -Fq -- "--authentication-config=" "${APISERVER_MANIFEST}"; then
  fail_setup "Cannot combine kube-apiserver OIDC flags with --authentication-config"
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
    fail_setup "Rendered API-server manifest is missing ${required_oidc_flag}"
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
    fail_setup "API server did not restart successfully with Dex OIDC enabled"
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
