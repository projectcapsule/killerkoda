#!/usr/bin/env bash
set -euo pipefail
umask 077

# Run with administrator credentials. The output contains only the selected demo user's credentials.
subject="${1:-alice}"
case "${subject}" in
  alice) default_namespace=solar-development ;;
  bob) default_namespace=solar-production ;;
  *) echo "Usage: $0 [alice|bob]" >&2; exit 1 ;;
esac

output_dir=/root/capsule-quickstart
work_dir="$(mktemp -d)"
trap 'rm -rf "${work_dir}"' EXIT
mkdir -p "${output_dir}"

openssl req -new -newkey rsa:2048 -nodes \
  -keyout "${work_dir}/${subject}.key" -out "${work_dir}/${subject}.csr" \
  -subj "/CN=${subject}/O=projectcapsule.dev"
request="$(base64 < "${work_dir}/${subject}.csr" | tr -d '\n')"
kubectl delete csr "capsule-quickstart-${subject}" --ignore-not-found
kubectl apply -f - <<EOF
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: capsule-quickstart-${subject}
spec:
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 86400
  request: ${request}
  usages:
    - client auth
EOF
kubectl certificate approve "capsule-quickstart-${subject}"
kubectl wait --for=jsonpath='{.status.certificate}' "csr/capsule-quickstart-${subject}" --timeout=120s
kubectl get csr "capsule-quickstart-${subject}" -o jsonpath='{.status.certificate}' \
  | base64 --decode > "${work_dir}/${subject}.crt"
kubectl get secret capsule-proxy -n capsule-system -o jsonpath='{.data.ca\.crt}' \
  | base64 --decode > "${work_dir}/proxy-ca.crt"
test -s "${work_dir}/${subject}.crt"
test -s "${work_dir}/proxy-ca.crt"

config="${work_dir}/${subject}.kubeconfig"
kubectl --kubeconfig "${config}" config set-cluster capsule-proxy \
  --server=https://127.0.0.1:30443 \
  --certificate-authority="${work_dir}/proxy-ca.crt" --embed-certs=true
kubectl --kubeconfig "${config}" config set-credentials "${subject}" \
  --client-certificate="${work_dir}/${subject}.crt" \
  --client-key="${work_dir}/${subject}.key" --embed-certs=true
kubectl --kubeconfig "${config}" config set-context "${subject}-tenants" \
  --cluster=capsule-proxy --user="${subject}" --namespace="${default_namespace}"
kubectl --kubeconfig "${config}" config use-context "${subject}-tenants"
cp "${config}" "${output_dir}/${subject}.kubeconfig"
chmod 600 "${output_dir}/${subject}.kubeconfig"
echo "${subject}'s kubeconfig: ${output_dir}/${subject}.kubeconfig"
