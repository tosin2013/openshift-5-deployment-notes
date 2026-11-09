# Working Lightspeed on OpenShift 5

Recorded 28 October 2026 from `cluster-84wvf`. This is a workshop cluster that already had Lightspeed answering. It is the reference for a 5.0 install whose chat icon can render. Login needs `--insecure-skip-tls-verify`. Do not put the login token or the LLM API key in git.

| | |
| --- | --- |
| API | `https://api.cluster-84wvf.dyn.redhatworkshops.io:6443` |
| Console | `https://console-openshift-console.apps.cluster-84wvf.dyn.redhatworkshops.io` |
| User | `admin` |
| Version | `5.0.0-rc.7`, channel `simple` |
| Namespace created | 2026-10-28 15:27 UTC |

`oc get olsconfig cluster` reports `overallStatus=Ready`. Conditions `ConsolePluginReady`, `CacheReady`, `OtelCollectorReady`, `MCPServerReady`, `RHOKPReady`, `ApiReady`, `AgenticConsolePluginReady`, and `AlertsAdapterReady` are all `True`.

## What is running

The operator is in use. `lightspeed-operator-controller-manager` reconciles `OLSConfig` `cluster` and creates the app server, console plugin, Postgres, collector, and the offline knowledge portal. OpenShift GitOps applied that Deployment from the Helm chart. It has no owner reference and is labeled `app.kubernetes.io/managed-by=kustomize`. There is no `lightspeed-operator` Subscription or CSV.

| Application | Repo | Path | Revision | Sync |
| --- | --- | --- | --- | --- |
| `openshift-lightspeed` | [rhpds/ocp5-first-look-lab](https://github.com/rhpds/ocp5-first-look-lab) | `automation/gitops/openshift-lightspeed` | `ocp5-first-look-1.1.2` | OutOfSync, Healthy |
| `openshift-agentic-lightspeed` | same repo | `automation/gitops/openshift-agentic-lightspeed` | `ocp5-first-look-1.1.2` | Synced, Healthy |

Both Applications live in namespace `openshift-gitops` and deploy into `openshift-lightspeed`. The chart description is "OpenShift Lightspeed Operator (direct install, not OLM)". The only OutOfSync object was `ClusterRoleBinding/lightspeed-operator-ols-metrics-reader`. The `OLSConfig` was still Ready.

The chart pins one console image. The operator args are `--console-image=...lightspeed-console-plugin-rhel9@sha256:5f3f1ce3...` and do not include `--console-image-pf5` or `--console-image-4-19`. The plugin pod's `OCP_VERSION` is `5.0`. Its `plugin-manifest.json` says version `1.1.5`, and the popover CSS uses `--pf-t--global--spacer--2xl`. The 5.0 console defines that PatternFly 6 token. The [1.0 operate guide](https://docs.redhat.com/en/documentation/red_hat_openshift_lightspeed/1.0/html/operate/ols-using-openshift-lightspeed), checked in October 2026, says the chat icon is in the lower-right corner. Current pages are [Installing OpenShift Lightspeed 2.0](https://docs.redhat.com/en/documentation/red_hat_openshift_lightspeed/2.0/html/install/ols-installing-lightspeed) and [Configuring OpenShift Lightspeed 2.0](https://docs.redhat.com/en/documentation/red_hat_openshift_lightspeed/2.0/html/configure/ols-configuring-openshift-lightspeed). The overview line "OpenShift Lightspeed version" is a separate dashboard extension and is not the chat button.

Lightspeed 1.1.1, used on the earlier sandbox, still chooses the plugin from the minor version only: minor below 19 gets the PatternFly 5 image. OpenShift 5.0 has minor `0`, so that operator deploys a button whose size is a PatternFly 5 variable the 5.0 console does not define. That is why the icon was missing there. This chart does not do that selection.

Pods in `openshift-lightspeed` that belong to this install:

- `lightspeed-operator-controller-manager`
- `lightspeed-app-server` (containers `lightspeed-service-api`, `lightspeed-to-dataverse-exporter`)
- `lightspeed-console-plugin`
- `lightspeed-postgres-server`
- `openshift-mcp-server` (image `registry.redhat.io/openshift-mcp/openshift-mcp-server-rhel9`)
- `lightspeed-otel-collector`
- `lightspeed-rhokp`
- `lightspeed-agentic-operator`
- `lightspeed-agentic-console-plugin`
- `lightspeed-agentic-alerts-adapter`

`consoles.operator.openshift.io/cluster` lists both `lightspeed-console-plugin` and `lightspeed-agentic-console-plugin`.

## Catalog 2.0.0, which this cluster did not install

`redhat-operators` (`registry.redhat.io/redhat/redhat-operator-index:v5.0`) lists `lightspeed-operator` 2.0.0 on `stable` and `alpha`. Install mode is `OwnNamespace` only. Its related images include one console plugin, `lightspeed-console-plugin-rhel9`, plus an agentic operator and an agentic console plugin. They are different digests from the chart pins above. The 4.22 snapshot catalogs on this cluster (`redhat-operators-v422` and `rhbk-operator-catalogsource` in `keycloak`) still list 1.1.1.

Use 2.0.0 from `redhat-operators` when you install with OLM. Keep the chart when you want the same bits as this workshop, including the agentic sandbox build.

## Provider

The Application's Helm `valuesObject.llm` is what the chart renders. The API key stays in that object and in Secret `llm-credentials`. The chart writes it as `stringData.apitoken`. The key length observed here was 25 characters. Do not copy it out.

Rendered `OLSConfig` `cluster`:

```yaml
apiVersion: ols.openshift.io/v1alpha1
kind: OLSConfig
metadata:
  name: cluster
spec:
  featureGates:
    - MCPServer
  llm:
    providers:
      - name: rhoai_vllm
        type: rhoai_vllm
        url: https://maas-rhdp.apps.maas.redhatworkshops.io/v1
        credentialsSecretRef:
          name: llm-credentials
        models:
          - name: claude-sonnet-4-6
            parameters:
              toolBudgetRatio: 0.5
  mcpServers:
    - name: openshift-mcp
      url: http://openshift-mcp-server.openshift-mcp.svc.cluster.local:8080/mcp
      timeout: 120
      headers:
        - name: kubernetes-authorization
          valueFrom:
            type: kubernetes
  ols:
    defaultModel: claude-sonnet-4-6
    defaultProvider: rhoai_vllm
    logLevel: DEBUG
    maxIterations: 30
    credentialHotReload: false
    conversationCache:
      type: postgres
      postgres:
        maxConnections: 2000
        sharedBuffers: 256MB
```

`type: rhoai_vllm` is the OpenShift AI / vLLM-compatible client. This URL is the workshop's shared MaaS endpoint, not a model server inside the cluster. The model id is `claude-sonnet-4-6`. The same URL, model, and secret feed the agentic `LLMProvider` named `openai` (`type: OpenAI`, secret `llm-creds-openai`). Agents `default` and `smart` both use that provider and model, with analysis, execution, and verification timeouts of 1800 seconds. `ApprovalPolicy` `cluster` and the alerts adapter that creates `AgenticRun` objects are in [agentic-troubleshooting.md](agentic-troubleshooting.md). No `AgenticOLSConfig` object exists.

The MCP URL is the Service in namespace `openshift-mcp` (image `registry.redhat.io/openshift-mcp-tech-preview/openshift-mcp-server-rhel9:0.3`). The operator also runs its own `openshift-mcp-server` in `openshift-lightspeed`. The `OLSConfig` points at the `openshift-mcp` one. The header name is `kubernetes-authorization`, not `Authorization`.

## Set it up on another 5.0 cluster

### OLM, Lightspeed 2.0.0

Confirm the package before you subscribe. Two catalogs can both publish `lightspeed-operator`. The v5.0 one is `redhat-operators`.

```bash
oc get packagemanifest -n openshift-marketplace -l catalog=redhat-operators \
  -o jsonpath='{range .items[?(@.metadata.name=="lightspeed-operator")]}{.status.catalogSource}{" "}{.status.channels[?(@.name=="stable")].currentCSV}{"\n"}{end}'
```

That should print `redhat-operators lightspeed-operator.v2.0.0`.

```bash
oc create namespace openshift-lightspeed
oc apply -f - <<'EOF'
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: openshift-lightspeed
  namespace: openshift-lightspeed
spec:
  targetNamespaces:
    - openshift-lightspeed
  upgradeStrategy: Default
---
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: lightspeed-operator
  namespace: openshift-lightspeed
spec:
  channel: stable
  installPlanApproval: Automatic
  name: lightspeed-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF
oc get csv -n openshift-lightspeed
oc rollout status deploy/lightspeed-operator-controller-manager -n openshift-lightspeed
```

Wait until the CSV is `Succeeded`. Then create the provider Secret and the `OLSConfig`. For the provider types already in this repo, [configure-provider.sh](configure-provider.sh) does both. The workshop provider is the `rhoai_vllm` shape with your own URL, model, and token:

```bash
oc create secret generic llm-credentials -n openshift-lightspeed \
  --from-literal=apitoken="$LLM_API_TOKEN"
```

Apply an `OLSConfig` with `type: rhoai_vllm`, `url` ending in `/v1`, and `credentialsSecretRef.name: llm-credentials`. Leave `spec.mcpServers` out until the MCP Service exists. A second apply of an `OLSConfig` named `cluster` replaces the first.

Check the plugin image after the operator reconciles. It should be `lightspeed-console-plugin-rhel9`, not `lightspeed-console-plugin-pf5-rhel9`.

```bash
oc get deploy lightspeed-console-plugin -n openshift-lightspeed \
  -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'
oc get olsconfig cluster -o jsonpath='{.status.overallStatus}{"\n"}'
```

`Ready` means the provider health check passed. The chat icon is the lower-right Lightspeed button. Reload the console once after `ConsolePluginReady` goes `True`.

Anyone who is not cluster-admin needs the query role:

```bash
oc adm policy add-cluster-role-to-user lightspeed-operator-query-access <user>
```

### Same bits as this workshop

The chart is not in this notes repo. It lives on the lab branch:

```bash
git clone --branch ocp5-first-look-1.1.2 --depth 1 https://github.com/rhpds/ocp5-first-look-lab.git
```

`automation/gitops/openshift-lightspeed/values.yaml` leaves `llm.apiUrl`, `llm.apiKey`, `llm.provider`, and `llm.model` empty. The chart skips the Secret and the `OLSConfig` until `llm.apiKey` is set. Pass them at install time. Do not commit the key.

```bash
helm upgrade -i openshift-lightspeed automation/gitops/openshift-lightspeed \
  --namespace openshift-lightspeed --create-namespace \
  --set llm.provider=rhoai_vllm \
  --set llm.model=claude-sonnet-4-6 \
  --set llm.apiUrl=https://your-endpoint.example.com/v1 \
  --set llm.apiKey="$LLM_API_TOKEN"
```

The agentic chart is a second install, `automation/gitops/openshift-agentic-lightspeed`. It reads the same four `llm` values and writes `LLMProvider` `openai` plus agents `default` and `smart`. Install it after the Lightspeed chart. The Lightspeed chart also builds a sandbox image in-cluster (`sandboxBuild.enabled`) so long MaaS calls are not dropped at 60 seconds. That build is specific to this workshop's MaaS endpoint.

Query from the CLI the same way as the rest of these notes: a reencrypt Route to Service `lightspeed-app-server` port `https`, then `POST /v1/query` with the user's bearer token.
