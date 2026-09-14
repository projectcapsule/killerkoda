#!/usr/bin/env bash
set -euo pipefail
umask 077

# Run with administrator credentials. The output authenticates only Alice.
output_dir=/root/capsule-quickstart
work_dir="$(mktemp -d)"
trap 'rm -rf "${work_dir}"' EXIT
mkdir -p "${output_dir}"

openssl req -new -newkey rsa:2048 -nodes \
  -keyout "${work_dir}/alice.key" -out "${work_dir}/alice.csr" \
  -subj '/CN=alice/O=projectcapsule.dev'
request="$(base64 < "${work_dir}/alice.csr" | tr -d '\n')"
kubectl delete csr capsule-demo-alice --ignore-not-found
kubectl apply -f - <<EOF
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: capsule-demo-alice
spec:
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 86400
  request: ${request}
  usages:
    - client auth
EOF
kubectl certificate approve capsule-demo-alice
kubectl wait --for=jsonpath='{.status.certificate}' csr/capsule-demo-alice --timeout=120s
kubectl get csr capsule-demo-alice -o jsonpath='{.status.certificate}' \
  | base64 --decode > "${work_dir}/alice.crt"
kubectl get secret capsule-proxy -n capsule-system -o jsonpath='{.data.ca\.crt}' \
  | base64 --decode > "${work_dir}/proxy-ca.crt"
test -s "${work_dir}/alice.crt"
test -s "${work_dir}/proxy-ca.crt"

config="${work_dir}/alice.kubeconfig"
kubectl --kubeconfig "${config}" config set-cluster capsule-proxy \
  --server=https://127.0.0.1:30443 \
  --certificate-authority="${work_dir}/proxy-ca.crt" --embed-certs=true
kubectl --kubeconfig "${config}" config set-credentials alice \
  --client-certificate="${work_dir}/alice.crt" \
  --client-key="${work_dir}/alice.key" --embed-certs=true
kubectl --kubeconfig "${config}" config set-context alice-solar \
  --cluster=capsule-proxy --user=alice --namespace=solar-development
kubectl --kubeconfig "${config}" config use-context alice-solar
cp "${config}" "${output_dir}/alice.kubeconfig"
chmod 600 "${output_dir}/alice.kubeconfig"
echo "Alice's kubeconfig: ${output_dir}/alice.kubeconfig"
