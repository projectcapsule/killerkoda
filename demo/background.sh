#!/bin/bash
set -Eeuo pipefail
set -x
trap 'touch /tmp/failed' ERR

echo starting...

export GANGPLANK_URL="$(sed 's/PORT/30442/g' /etc/killercoda/host)"
export PROXY_URL="$(sed 's/PORT/30443/g' /etc/killercoda/host)"
export HEADLAMP_URL="$(sed 's/PORT/30444/g' /etc/killercoda/host)"
export DEX_URL="$(sed 's/PORT/32556/g' /etc/killercoda/host)"

OIDC_AUTH_CONFIG=/etc/kubernetes/pki/demo-authentication-config.yaml
APISERVER_MANIFEST=/etc/kubernetes/manifests/kube-apiserver.yaml

wait_for_authentication_config() {
  local expected_hash="$1"
  local failure_message="$2"

  for attempt in $(seq 1 120); do
    if kubectl get --raw=/metrics 2>/dev/null \
      | grep -E "^apiserver_authentication_config_controller_last_config_info\\{[^}]*hash=\"sha256:${expected_hash}\"[^}]*\\} 1$" \
        >/dev/null; then
      return 0
    fi
    sleep 1
  done

  echo "${failure_message}" >&2
  return 1
}

# Start the API server with an empty, reloadable JWT configuration. Dex is not
# available yet, so configuring the issuer directly during bootstrap would
# create a dependency cycle between the API server and Dex.
oidc_auth_tmp="$(mktemp "${OIDC_AUTH_CONFIG}.XXXXXX")"
cat > "${oidc_auth_tmp}" <<'EOF'
apiVersion: apiserver.config.k8s.io/v1
kind: AuthenticationConfiguration
jwt: []
EOF
chmod 0600 "${oidc_auth_tmp}"
mv "${oidc_auth_tmp}" "${OIDC_AUTH_CONFIG}"

if ! grep -Fq -- "--authentication-config=${OIDC_AUTH_CONFIG}" "${APISERVER_MANIFEST}"; then
  sed -i "/^[[:space:]]*- kube-apiserver$/a\\    - --authentication-config=${OIDC_AUTH_CONFIG}" "${APISERVER_MANIFEST}"
fi

initial_auth_hash="$(sha256sum "${OIDC_AUTH_CONFIG}" | awk '{print $1}')"
wait_for_authentication_config \
  "${initial_auth_hash}" \
  "API server did not start with the reloadable authentication configuration"

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

# Atomically enable Dex authentication. The API server automatically reloads
# this file without restarting.
oidc_auth_tmp="$(mktemp "${OIDC_AUTH_CONFIG}.XXXXXX")"
cat > "${oidc_auth_tmp}" <<EOF
apiVersion: apiserver.config.k8s.io/v1
kind: AuthenticationConfiguration
jwt:
  - issuer:
      url: "${DEX_URL}"
      audiences:
        - kubernetes
    claimMappings:
      username:
        claim: name
        prefix: ""
      groups:
        claim: groups
        prefix: ""
EOF
chmod 0600 "${oidc_auth_tmp}"
mv "${oidc_auth_tmp}" "${OIDC_AUTH_CONFIG}"

expected_auth_hash="$(sha256sum "${OIDC_AUTH_CONFIG}" | awk '{print $1}')"
wait_for_authentication_config \
  "${expected_auth_hash}" \
  "API server did not load the Dex authentication configuration"

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
