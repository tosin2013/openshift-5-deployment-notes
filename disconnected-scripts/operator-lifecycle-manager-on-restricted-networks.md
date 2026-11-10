# Operator catalogs on a restricted network

Use this after the platform mirror when the cluster must install Operators from your registry. The 5.0 Red Hat catalog is a file-based index, `registry.redhat.io/redhat/redhat-operator-index:v5.0`. The preferred path is the `operators` list in the oc-mirror v2 image set. [mirror-ocp-full.sh](mirror-ocp-full.sh) writes that list when `PACKAGES` is set.

1. Install `oc` and `opm` from the 5.0 release. Do not download `opm` from `stable-4.10`.

```bash
../pre-steps/configure-openshift-packages.sh -i --opm
```

2. Mirror the packages you need with the local script. The catalog in the generated file is the v5.0 index.

```bash
PACKAGES=local-storage-operator,lvms-operator \
  REGISTRY=registry.example.com \
  REGISTRY_PASSWORD='<init_password>' \
  ./mirror-ocp-full.sh
```

Remove the `packages` field from `imageset-config.yaml` before you run `oc mirror` when you want the whole catalog. Do not commit the registry password.

3. After the cluster is up, disable the default catalogs and apply the resources oc-mirror wrote. Those resources are `ImageDigestMirrorSet`, `ImageTagMirrorSet`, and `CatalogSource`. Do not change `spec.imageDigestMirrors` or `spec.imageTagMirrors`.

```bash
oc patch OperatorHub cluster --type json \
  -p '[{"op": "add", "path": "/spec/disableAllDefaultSources", "value": true}]'
oc apply -f "$HOME/oc-mirror/working-dir/cluster-resources"
oc get catalogsource -n openshift-marketplace
oc get pods -n openshift-marketplace
```

To filter a file-based catalog by hand, render it and delete the `olm.package`, `olm.channel`, and `olm.bundle` entries for the packages you do not want:

```bash
opm render registry.redhat.io/redhat/redhat-operator-index:v5.0 -o yaml > index.yaml
```

`opm index prune`, `opm index add`, and `grpcurl` against `api.Registry/ListPackages` are the older note's tools. They belong to the SQLite index used through OpenShift 4.10. They do not prune the v5.0 file-based catalog.

## oc adm catalog mirror

The 5.0 `oc adm` chapter still documents this command. It is the alternative to the `operators` list above. Log in to `registry.redhat.io` and to the mirror, then mirror the v5.0 index. `--insecure` skips trust for the mirror. The command writes `catalogSource.yaml` and `imageContentSourcePolicy.yaml` under `manifests-redhat-operator-index-<number>`.

```bash
oc adm catalog mirror \
  registry.redhat.io/redhat/redhat-operator-index:v5.0 \
  registry.example.com:8443/olm-mirror \
  -a "${XDG_RUNTIME_DIR}/containers/auth.json" \
  --insecure
```

Apply those two files after the cluster is up. This path creates an `ImageContentSourcePolicy`. The oc-mirror v2 path creates an `ImageDigestMirrorSet` instead. Red Hat Quay rejects nested repository names from this command. The chapter's workaround is `--max-components=2`.

[disconnected-olm.sh](https://github.com/tosin2013/openshift-4-deployment-notes/blob/master/disconnected-scripts/disconnected-olm.sh) is the OpenShift 4 script. It targets a 4.y index. Do not run it for a 5.0 catalog.

Product docs: [Using Operator Lifecycle Manager in disconnected environments](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/disconnected_environments/olm-restricted-networks) (OpenShift Container Platform 5.0). Catalog mirroring is in [Mirroring images for a disconnected installation by using the oc adm command](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/disconnected_environments/installing-mirroring-installation-images). Filtering a file-based catalog is in [Administrator tasks](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/operators/administrator-tasks).

Check the catalog tag and `oc adm catalog mirror` on the build you are installing.
