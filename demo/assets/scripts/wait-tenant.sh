#!/usr/bin/env bash
set -euo pipefail

# Ready alone can refer to the previous revision immediately after apply.
wait_revision() {
  local generation
  generation="$(kubectl get "$@" -o jsonpath='{.metadata.generation}')"
  kubectl wait "$@" --for="jsonpath={.status.observedGeneration}=${generation}" --timeout=120s
  kubectl wait "$@" --for=condition=Ready --timeout=120s
}

wait_revision tenant/solar
namespaces="$(kubectl get namespaces -l capsule.clastix.io/tenant=solar -o jsonpath='{.items[*].metadata.name}')"
for namespace in ${namespaces}; do
  kubectl wait --for=create rulestatus/capsule-managed-rules -n "${namespace}" --timeout=120s
  wait_revision rulestatus/capsule-managed-rules -n "${namespace}"
done
