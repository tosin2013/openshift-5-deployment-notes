#!/usr/bin/env bash
# Read-only snapshot of the cluster these notes are being written against.
set -euo pipefail

echo "== oc whoami =="
oc whoami
echo
echo "== versions =="
oc version
echo
echo "== clusterversion =="
oc get clusterversion version
echo
echo "== history =="
oc get clusterversion version -o jsonpath='{range .status.history[*]}{.state}{" "}{.version}{" "}{.startedTime}{"\n"}{end}'
echo
echo "== infrastructure =="
oc get infrastructure cluster -o jsonpath='platform={.status.platform} topology={.status.infrastructureTopology} api={.status.apiServerURL}{"\n"}'
oc get ingress.config.openshift.io cluster -o jsonpath='apps={.spec.domain}{"\n"}'
echo
echo "== nodes =="
oc get nodes -o wide
echo
echo "== machine config pools =="
oc get mcp
echo
echo "== storage classes =="
oc get sc
echo
echo "== identity providers =="
oc get oauth cluster -o jsonpath='{range .spec.identityProviders[*]}{.name}{" "}{.type}{"\n"}{end}'
echo
echo "== operators not fully available =="
oc get co --no-headers | awk '$3 != "True" || $4 != "False" || $5 != "False" { print }'
echo "(no lines above means every ClusterOperator is Available, not Progressing, not Degraded)"
echo
echo "== installed CSVs =="
oc get csv -A --no-headers
echo
echo "== notable feature gates =="
oc get featuregate cluster -o json | python3 -c '
import json, sys
want = {
    "OSStreams", "NewOLM", "OLMLifecycleAndCompatibility", "GatewayAPIWithoutOLM",
    "BootcNodeManagement", "ClusterAPIInstall", "KarpenterOperator",
    "IngressControllerMultipleHAProxyVersions", "MutatingAdmissionPolicy",
    "UserNamespacesSupport", "OpenShiftPodSecurityAdmission",
    "NetworkObservabilityInstall", "MachineAPIMigration",
}
data = json.load(sys.stdin)
enabled, disabled = set(), set()
for block in data["status"]["featureGates"]:
    enabled.update(item["name"] for item in block.get("enabled", []))
    disabled.update(item["name"] for item in block.get("disabled", []))
for name in sorted(want):
    if name in enabled:
        print(f"enabled  {name}")
    elif name in disabled:
        print(f"disabled {name}")
    else:
        print(f"absent   {name}")
'
