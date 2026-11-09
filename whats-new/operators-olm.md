# Operators and OLM

Product docs: [Understanding Operators](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/operators/understanding-operators) (OpenShift Container Platform 5.0 Operators).

OpenShift 5 on this lab runs catalogd plus the classic Operator Lifecycle Manager objects. Both are real APIs on the cluster:

```bash
oc get pods -n openshift-catalogd
oc get clustercatalog
oc get catalogsource -n openshift-marketplace
oc api-resources | grep -E 'clustercatalog|clusterextension|catalogsource|subscription'
```

`NewOLM` and `OLMLifecycleAndCompatibility` are enabled. These newer OLM gates are still off: `NewOLMBoxCutterRuntime`, `NewOLMCatalogdAPIV1Metas`, `NewOLMConfigAPI`, `NewOLMOwnSingleNamespace`.

Cluster catalogs currently serving:

- openshift-redhat-operators
- openshift-certified-operators
- openshift-community-operators

Classic `CatalogSource` objects are still in `openshift-marketplace` (redhat-operators, certified-operators, community-operators, plus the lab's RHBK catalog). Installed operators on this cluster still show up as `Subscription` and `ClusterServiceVersion` objects: cert-manager and the Red Hat build of Keycloak.

`GatewayAPIWithoutOLM` is enabled, so the Gateway API controller is not something you subscribe to through OLM on this build.

## What this means for the old disconnected notes

The OpenShift 4 mirror scripts under `disconnected-scripts/` index images for the classic catalog. A 5.0 disconnected lab has to mirror catalogd's `ClusterCatalog` content as well. Do not reuse the 4.10 package list in the old repo.

## Placeholder

- [ ] Install one operator with a `ClusterExtension` and record the difference from a `Subscription`
- [ ] Mirror redhat-operators for an air-gapped 5.0 cluster and note which of catalogd or the classic catalog was required
- [ ] Watch whether `NewOLMConfigAPI` flips to enabled in a later RC
