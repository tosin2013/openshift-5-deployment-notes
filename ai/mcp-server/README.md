# MCP server for OpenShift

The MCP server lets an assistant (Cursor, Claude Code, VS Code, or Lightspeed) call OpenShift APIs through a fixed set of tools. It is a Technology Preview image, not a ClusterOperator. Putting it behind authentication and per-tool policy is a separate install, recorded in [gateway.md](gateway.md).

On 9 November 2026 `cluster-84wvf` (`5.0.0-rc.7`) was already running it. Namespace `openshift-mcp`, deployment `openshift-mcp-server`, image `registry.redhat.io/openshift-mcp-tech-preview/openshift-mcp-server-rhel9:0.3`. The route is `https://mcp-server.apps.cluster-84wvf.dyn.redhatworkshops.io/mcp`. Lightspeed calls the in-cluster address `http://openshift-mcp-server.openshift-mcp.svc.cluster.local:8080/mcp`. ConfigMap `mcp-config` sets toolsets `core`, `config`, `metrics`, `netedge`, `openshift`, and `ossm`, with `read_only` off and `cluster_auth_mode` `passthrough`. OpenShift GitOps Application `openshift-mcp-server` manages it and self-heals. The [lab index](https://showroom-showroom-84wvf-1.apps.cluster-84wvf.dyn.redhatworkshops.io/?t=Terminal&p=index) also names an ACS MCP server. That showroom page is not one of the three modules, and these notes do not cover it. A search for Advanced Cluster Security 5.0 returned the [5.0 release notes](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_security_for_kubernetes/5.0/html/release_notes/release-notes-50) and did not return an ACS MCP chapter.

Chart `openshift-helm-charts/redhat-openshift-mcp-server` version 0.3.0 was listed at https://charts.openshift.io/ on 20 October 2026. The same image tag is what this cluster runs. The Helm procedure below is how to install that chart on a cluster that does not already have it.

Product docs: [MCP server](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/ai_applications/mcp-server) (OpenShift Container Platform 5.0 AI applications). Upstream config: [openshift/openshift-mcp-server](https://github.com/openshift/openshift-mcp-server/blob/main/docs/configuration.md).

## Install read-only

Use this on a cluster that does not already have the server. It binds the chart's ServiceAccount to the built-in `view` role and sets `read_only` in the server config. It does not grant cluster-admin. The server on `cluster-84wvf` is the GitOps install above, and that one has `read_only` off.

```bash
helm repo add openshift-helm-charts https://charts.openshift.io/
helm repo update openshift-helm-charts
helm search repo redhat-openshift-mcp-server --versions

APPS_DOMAIN=$(oc get ingress.config.openshift.io cluster -o jsonpath='{.spec.domain}')
echo "mcp-server.${APPS_DOMAIN}"

helm upgrade -i openshift-mcp-server openshift-helm-charts/redhat-openshift-mcp-server \
  --version 0.3.0 \
  --namespace openshift-mcp-server \
  --create-namespace \
  --values ai/mcp-server/values-readonly.yaml \
  --set ingress.host="mcp-server.${APPS_DOMAIN}"
```

`values-readonly.yaml` is written for chart 0.3.0. The chart copies every key under `config` into `config.toml`. Keep `port` if you replace that map. `openshift: true` adds the Route annotation on the Ingress so the OpenShift router publishes `ingress.host`.

Check it:

```bash
oc get pods,svc,route,ingress -n openshift-mcp-server
oc logs -n openshift-mcp-server deploy/openshift-mcp-server --tail=50
```

The chart's probes call `/healthz` on port 8080. The default limit is 128Mi. If the pod is OOMKilled, raise `resources` in the values file and upgrade. Uninstall with `helm uninstall openshift-mcp-server -n openshift-mcp-server`.

## Toolsets

Chart 0.3.0 does not list toolsets in its default values, so the server's own defaults apply until you set `config.toolsets`. The 4.22 product table lists `core` and `config` as the defaults. Add others only when you need them:

| Toolset | Use |
| --- | --- |
| core | Pods, events, generic resources |
| config | Local kubeconfig view |
| helm | Helm releases |
| metrics | Prometheus and Alertmanager |
| netedge | NetEdge troubleshooting |
| ossm | Service mesh |
| kubevirt | Virtual machines (Developer Preview) |
| tekton | Pipelines (Developer Preview) |

`disabled_tools` and `enabled_tools` in the same config map are how you drop destructive calls (`pods_delete`, `resources_delete`) even if a toolset is on. Prefer `read_only: true` on this lab.

## Wire it to Lightspeed

After both are running, add the server under `spec.mcpServers` on `OLSConfig` as described in the [Lightspeed notes](../lightspeed/README.md). Use the in-cluster Service URL and `valueFrom.type: kubernetes` so each user hits the API as themselves.

A desktop client such as Cursor uses the Route hostname instead. Keep that client on a user token with `view`, and review any write the client proposes before it is sent.

## Placeholder

- [x] Record the running server on `cluster-84wvf` (9 November 2026): image `openshift-mcp-server-rhel9:0.3` from `registry.redhat.io`, route published, Lightspeed pointed at the in-cluster Service.
- [ ] Ask the assistant about the [sample app](../sample-app/README.md) after a fault is applied
- [x] Record the gateway that is actually installed. [gateway.md](gateway.md): Connectivity Link `rhcl-operator.v1.4.2`, MCP Gateway Operator `mcp-gateway.v0.7.1`, three Ready mock servers, Keycloak JWT, a tool-role check, and 30 requests per minute per token subject. No CR denylist object was present.
