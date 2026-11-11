# OpenShift Lightspeed

Lightspeed is the in-cluster assistant. It is a separate operator (`OLSConfig`), not a ClusterOperator in the 5.0 payload. Current product pages are [Installing OpenShift Lightspeed 2.0](https://docs.redhat.com/en/documentation/red_hat_openshift_lightspeed/2.0/html/install/ols-installing-lightspeed), [Configuring OpenShift Lightspeed 2.0](https://docs.redhat.com/en/documentation/red_hat_openshift_lightspeed/2.0/html/configure/ols-configuring-openshift-lightspeed), and [Google Vertex AI](https://docs.redhat.com/en/documentation/red_hat_openshift_lightspeed/2.0/html/configure/ols-configuring-integrating-google-vertex-ai). The 2.0 install guide says autonomous agents require OpenShift Container Platform 5.0. The 1.0 install guide, checked in October 2026, listed OpenShift 4.16 through 4.22 and described the chat control as the Lightspeed icon in the lower-right corner of the console. That icon is separate from the "OpenShift Lightspeed version" line on the overview.

On 28 October 2026 a working install was recorded on `cluster-84wvf` (also `5.0.0-rc.7`). That cluster's `redhat-operators` index (`registry.redhat.io/redhat/redhat-operator-index:v5.0`) contains `lightspeed-operator` **2.0.0** on channels `stable` and `alpha`. On 11 November 2026 the `ocp5` `redhat-operators` catalog listed the same package on `stable` and `alpha` at `lightspeed-operator.v2.0.1`. `ocp5` does not have the operator installed. An install needs an LLM provider secret. `cluster-84wvf` is using the operator: `lightspeed-operator-controller-manager` is running and it reconciles `OLSConfig`. OpenShift GitOps installed that Deployment from a Helm chart. There is no Subscription and no CSV, so it is not the 2.0.0 catalog install. The console plugin is the PatternFly 6 build, so the lower-right icon can render. Details and the setup steps are in [working-cluster.md](working-cluster.md).

The rest of this page is the 21 October sandbox, when the v5.0 indexes did not list the package and the only copy was Lightspeed 1.1.1 inside a 4.22 catalog snapshot. That 1.1.1 operator picks its console plugin from the OpenShift minor number. On 5.0 the minor is `0`, so it deploys the PatternFly 5 plugin and the chat icon has no size. Do not use 1.1.1 on OpenShift 5 when 2.0.0 is in the index.

Check again after each payload update:

```bash
oc get packagemanifest -A -o jsonpath='{range .items[*]}{.metadata.namespace}{"\t"}{.metadata.name}{"\t"}{.status.catalogSource}{"\n"}{end}' | grep lightspeed || echo "lightspeed package not in any catalog"
oc get olsconfig 2>/dev/null || true
oc get pods -n openshift-lightspeed 2>/dev/null || true
```

The October 2026 check used the 1.0 guides: [Installing](https://docs.redhat.com/en/documentation/red_hat_openshift_lightspeed/1.0/html-single/install/index), [Configuring](https://docs.redhat.com/en/documentation/red_hat_openshift_lightspeed/1.0/html/configure/ols-configuring-openshift-lightspeed), and [Google Vertex AI](https://docs.redhat.com/en/documentation/red_hat_openshift_lightspeed/1.0/html/configure/ols-configuring-integrating-google-vertex-ai). Use the 2.0 pages linked above for a current cluster.

## Install the operator

For a 5.0 cluster whose `redhat-operators` catalog lists 2.0.0, use [working-cluster.md](working-cluster.md). The procedure in this section is the 21 October sandbox, when that package was missing and 1.1.1 had to come from a 4.22 snapshot.

Do this before [configure-provider.sh](configure-provider.sh). The script creates the provider Secret and the `OLSConfig`. It exits unless namespace `openshift-lightspeed` exists and deployment `lightspeed-operator-controller-manager` has a ready pod.

On that sandbox, subscribe to source `rhbk-operator-catalogsource` after a copy of that catalog exists in `openshift-marketplace`. The original catalog in namespace `keycloak` is visible only there, so a Subscription in `openshift-lightspeed` cannot resolve it. `redhat-operators` on that cluster had no `lightspeed-operator` package. The 1.1.1 bundle supports `OwnNamespace` only, and the suggested namespace is `openshift-lightspeed`. The catalog is a 4.22 snapshot, `quay.io/rhpds/olm_snapshot_redhat_catalog:v4.22_2026_08_03`. On 21 October 2026 the marketplace copy went `READY`, the package resolved from namespace `default`, and `lightspeed-operator.v1.1.1` reached `Succeeded`. The controller pod `lightspeed-operator-controller-manager` was Running and `olsconfigs.ols.openshift.io` was created. The Software Catalog tile leaves Container image as `-`, Support as `-`, and Documentation as `N/A` because those annotations are unset. The bundle image is `registry.redhat.io/openshift-lightspeed/lightspeed-operator-bundle@sha256:ec7a6753930302bc3599b929f1a6599a9fc579e033215afa9bbd13285c5a2a04`, created 15 June 2026 10:11 UTC. Channel `alpha` heads at the same CSV.

### Console

The package tile is OpenShift Lightspeed Operator, channel `stable`, version 1.1.1, source `rhbk-operator-catalogsource`. The install form selects `OwnNamespace` ("A specific namespace on the cluster"), the recommended namespace `openshift-lightspeed`, and Automatic approval. All namespaces is greyed out because that install mode is unsupported.

On this cluster the Install button stays disabled and the form shows **Operator not available for selected Namespaces**. The console looks up `packagemanifest/lightspeed-operator` in the namespace you are installing into. `rhbk-operator-catalogsource` is in namespace `keycloak`. A catalog outside `openshift-marketplace` is visible only in its own namespace:

```bash
oc get packagemanifest lightspeed-operator -n keycloak
oc get packagemanifest lightspeed-operator -n default
```

The first command finds version 1.1.1. The second returns NotFound, and `openshift-lightspeed` does not exist yet, so the console's lookup fails and Install stays grey. Creating the namespace first does not change that. The same lookup is why a Subscription in `openshift-lightspeed` whose source is `rhbk-operator-catalogsource` does not resolve.

Copy the snapshot into `openshift-marketplace` so every namespace can see it. Priority `-500` matches the Keycloak catalog, so a package that also exists in the v5.0 indexes keeps the v5.0 copy.

```bash
oc apply -f - <<'EOF'
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: rhbk-operator-catalogsource
  namespace: openshift-marketplace
spec:
  displayName: Red Hat operators snapshot 4.22
  image: quay.io/rhpds/olm_snapshot_redhat_catalog:v4.22_2026_08_03
  priority: -500
  publisher: Red Hat AgnosticD
  sourceType: grpc
  updateStrategy:
    registryPoll:
      interval: 30m
EOF
oc get catalogsource rhbk-operator-catalogsource -n openshift-marketplace
oc get packagemanifest lightspeed-operator -n openshift-marketplace
```

Wait until that CatalogSource is `READY` and the packagemanifest exists in `openshift-marketplace`. Then open the install form again, keep channel `stable` and namespace `openshift-lightspeed`, and the Install button can enable. Confirm Ecosystem → Installed Operators shows `Succeeded`.

### CLI

```bash
oc get packagemanifest lightspeed-operator -n openshift-marketplace \
  -o jsonpath='source={.status.catalogSource}{"\n"}namespace={.status.catalogSourceNamespace}{"\n"}default={.status.defaultChannel}{"\n"}csv={.status.channels[?(@.name=="stable")].currentCSV}{"\n"}'
```

After the marketplace copy is `READY`, that prints `rhbk-operator-catalogsource`, namespace `openshift-marketplace`, channel `stable`, CSV `lightspeed-operator.v1.1.1`.

Create the namespace, an OperatorGroup that targets only that namespace, and the Subscription:

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
  source: rhbk-operator-catalogsource
  sourceNamespace: openshift-marketplace
EOF
```

Wait until the CSV phase is `Succeeded`:

```bash
oc get csv -n openshift-lightspeed
oc rollout status deploy/lightspeed-operator-controller-manager -n openshift-lightspeed
```

Then run the provider script. There is one `OLSConfig` named `cluster`. Applying a second provider file replaces that object.

## Examples

These two files are the configs to try first. Apply one, ask the same question, then apply the other. The second apply replaces the `cluster` object. Neither file sets `spec.featureGates` or `spec.mcpServers`, so your MCP tool stays out of both passes. Built-in cluster introspection stays at the operator default (`true`).

The [operator install](#install-the-operator) has to finish first. The script exits unless the operator deployment has a ready pod.

### Claude on Vertex

[providers/vertex-anthropic.yaml](providers/vertex-anthropic.yaml) uses `claude-sonnet-4-6` at location `global`. You need a GCP service-account JSON key, the Vertex AI API enabled, and permission for that model. The operator reads the secret key `apitoken` unless `credentialKey` is set, so this file sets `credentialKey: gcp-service-account.json`.

[configure-provider.sh](configure-provider.sh) creates Secret `llmcreds` from the key file and applies the config with your project id. The YAML in git stays a template.

```bash
GCP_SERVICE_ACCOUNT_JSON=/path/to/key.json GCP_PROJECT=my-project \
  ./ai/lightspeed/configure-provider.sh vertex-anthropic
```

Wait until `oc get olsconfig cluster` shows the object, then use [Ask a question](#ask-a-question) before you switch providers.

### OpenShift AI with the weak model

[providers/rhoai-vllm.yaml](providers/rhoai-vllm.yaml) points Lightspeed at a Red Hat OpenShift AI vLLM endpoint. The model id is `granite-4-0-h-tiny`, the smallest Granite 4 model in the Red Hat AI 3 validated catalog (the H Tiny image, about 8 GB in FP8). Lightspeed is weak at tool choice with a model this size, which is the point of this pass: see the assistant on that model before you add your MCP server.

The URL has to end in `/v1`. The model name has to be the id the endpoint returns. The default in the file is `granite-4-0-h-tiny`. Set `RHOAI_MODEL` when `/v1/models` shows a different string, such as `ibm-granite/granite-4.0-h-tiny`.

```bash
curl -k https://granite.apps.example.com/v1/models
```

The secret key is still `apitoken`. If the endpoint does not check a token, use any non-empty string. The script creates Secret `rhoai-api-keys` and applies the config:

```bash
RHOAI_API_TOKEN=... RHOAI_URL=https://granite.apps.example.com/v1 \
  ./ai/lightspeed/configure-provider.sh rhoai-vllm
```

Ask the same question again and compare it with the Claude answer.

### Ask a question

cluster-admin can query immediately. The console shows the Lightspeed button. From the CLI, expose the service and call the query API:

```bash
oc apply -f - <<'EOF'
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: lightspeed-app-server
  namespace: openshift-lightspeed
spec:
  port:
    targetPort: https
  tls:
    termination: reencrypt
    insecureEdgeTerminationPolicy: Redirect
  to:
    kind: Service
    name: lightspeed-app-server
EOF
TOKEN=$(oc whoami -t)
OLS_HOST=$(oc get route lightspeed-app-server -n openshift-lightspeed -o jsonpath='{.spec.host}')
curl -k -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  "https://${OLS_HOST}/v1/query" \
  -d '{"query":"What is a Deployment?"}'
```

Reencrypt keeps TLS from the router to the pod. `-k` skips verifying the cluster ingress certificate.

## Supported providers

Every `type` in the Lightspeed 1.0 configure guide has a file under `providers/`. [configure-provider.sh](configure-provider.sh) creates the Secret for any of them and applies that file. Run it with `--help` for the environment variables. Token providers store the raw token in `stringData.apitoken`. Kubernetes encodes it. Vertex providers use `credentialKey` because their secret is a JSON file, not `apitoken`.

OpenAI, Azure, RHEL AI, and watsonx leave the model id as a placeholder, because those catalogs are account-specific. The Vertex files and the OpenShift AI file pin a model id. The Vertex pins were checked on 21 October 2026. The OpenShift AI pin is Granite 4.0 H Tiny.

| type | File | Secret | Required extra fields |
| --- | --- | --- | --- |
| `google_vertex` | [gemini-vertex.yaml](providers/gemini-vertex.yaml) | `llmcreds`, key `gcp-service-account.json` | `googleVertexConfig.projectID`, `googleVertexConfig.location` |
| `openai` (Gemini API key) | [gemini-api.yaml](providers/gemini-api.yaml) | key `apitoken` | URL `https://generativelanguage.googleapis.com/v1beta/openai`, model `gemini-4-argon` |
| `google_vertex_anthropic` | [vertex-anthropic.yaml](providers/vertex-anthropic.yaml) | same JSON key | `googleVertexAnthropicConfig.projectID`, `googleVertexAnthropicConfig.location` |
| `openai` | [openai.yaml](providers/openai.yaml) | key `apitoken` | URL `https://api.openai.com/v1` |
| `azure_openai` | [azure-openai.yaml](providers/azure-openai.yaml) | key `apitoken`, or Entra ID keys `client_id`, `client_secret`, `tenant_id` | `apiVersion`, `deploymentName`, deployment URL |
| `rhelai_vllm` | [rhelai-vllm.yaml](providers/rhelai-vllm.yaml) | key `apitoken` | URL ending in `/v1`, model id `models/<name>` |
| `rhoai_vllm` | [rhoai-vllm.yaml](providers/rhoai-vllm.yaml) | key `apitoken` | URL ending in `/v1`, model `granite-4-0-h-tiny` |
| `watsonx` | [watsonx.yaml](providers/watsonx.yaml) | key `apitoken` | `projectID`, model id `ibm/<name>` |

A private certificate for the provider endpoint is covered in [providers/tls-ca.md](providers/tls-ca.md). Watsonx does not take that ConfigMap.

RHEL AI and OpenShift AI still need a secret when the endpoint does not check a token. Put any non-empty string in `apitoken`.

## Prove it is serving

```bash
oc get olsconfig cluster
oc get pods -n openshift-lightspeed
oc logs deployment/lightspeed-app-server -c lightspeed-service-api -n openshift-lightspeed | grep Uvicorn
```

A ready service logs `Uvicorn running on https://0.0.0.0:8443`.

Anyone who is not cluster-admin needs the role the operator creates:

```bash
oc adm policy add-cluster-role-to-user lightspeed-operator-query-access <user>
```

## Later: your MCP server

After both examples answer on their own, add the MCP tool. That is a Technology Preview gate on the same `OLSConfig`. The working cluster on 28 October 2026 uses the header name `kubernetes-authorization` and a 120 second timeout. Point the URL at the Service you actually installed. Use `valueFrom.type: kubernetes` so Lightspeed forwards the calling user's token.

```yaml
spec:
  featureGates:
    - MCPServer
  mcpServers:
    - name: openshift-mcp
      url: http://openshift-mcp-server.openshift-mcp.svc.cluster.local:8080/mcp
      timeout: 120
      headers:
        - name: kubernetes-authorization
          valueFrom:
            type: kubernetes
```

Confirm the Service name and the `/mcp` path with `oc get svc -A | grep mcp` before saving. The chart in [the MCP server notes](../mcp-server/README.md) uses namespace `openshift-mcp-server`. The workshop Service is in namespace `openshift-mcp`. Tool calling has to be enabled on the model.

## Placeholder

- [x] Install `lightspeed-operator.v1.1.1` from the 4.22 snapshot copied into `openshift-marketplace` (21 October 2026, CSV `Succeeded`). At that date the v5.0 indexes omitted the package.
- [x] Record the first 5.0 catalog that contains `lightspeed-operator`: `redhat-operators` (`registry.redhat.io/redhat/redhat-operator-index:v5.0`), channels `stable` and `alpha`, CSV `lightspeed-operator.v2.0.0` (seen 28 October 2026 on `cluster-84wvf`). The running install on that cluster is the GitOps chart in [working-cluster.md](working-cluster.md), not this CSV.
- [ ] Apply [providers/vertex-anthropic.yaml](providers/vertex-anthropic.yaml), then [providers/rhoai-vllm.yaml](providers/rhoai-vllm.yaml), and save both answers to the same question
- [ ] Add the MCP server in a second pass and compare the answer on the sample app
