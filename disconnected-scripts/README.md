# Disconnected install and mirroring

Mirror the OpenShift release into a registry the cluster can reach, then install from that registry. The 5.0 book prefers oc-mirror plugin v2 for the images, and the Agent-based Installer for the cluster. A registry you run yourself has to stay up for the life of the cluster.

`oc adm release mirror` is deprecated as of 4.22. oc-mirror plugin v1 wrote `ImageContentSourcePolicy` and kept state in `storageConfig`. v2 writes `ImageDigestMirrorSet` and `ImageTagMirrorSet`, and it does not prune the registry for you. The binary stays named `oc-mirror`. The command is `oc mirror --v2`.

## Mirror registry

The clients index at [openshift-v5/clients](https://mirror.openshift.com/pub/openshift-v5/clients/) lists `mirror-registry/`. Fetching that URL returned 404 on 9 November 2026. The archive that listed is [openshift-v4/clients/mirror-registry](https://mirror.openshift.com/pub/openshift-v4/clients/mirror-registry/). On that day the newest numbered directory was `1.3.11`, and `mirror-registry.tar.gz` was about 695 MB. There is no `latest` directory. The older note used GitHub `v1.3.10` and `mirror-registry-offline.tar.gz`.

[configure-other-clients.sh](../pre-steps/configure-other-clients.sh) extracts `mirror-registry`, `image-archive.tar`, and `execution-environment.tar` to `$HOME/mirror-registry`. It does not run the install.

The 5.0 local install runs as your user, not as root. It creates `$HOME/quay-install` unless you pass `--quayRoot`. It creates an `init` user and prints the password. `--quayHostname` must be a DNS name. It does not accept an IP address. The flags default that name to `<host>:8443`, and the login command uses port 8443. The local-host section heading says the registry runs on port 443.

```bash
../pre-steps/configure-other-clients.sh -i --mirror-registry
cd "$HOME/mirror-registry"
./mirror-registry install --quayHostname registry.example.com --quayRoot "$HOME/quay-install"
sudo firewall-cmd --add-port=8443/tcp --permanent
sudo firewall-cmd --reload
podman login -u init -p '<init_password>' registry.example.com:8443 --tls-verify=false
```

Do not commit the init password. The registry CA is `$HOME/quay-install/rootCA.pem` when that is the quay root. Trust that file on the install host when you want `podman login` without `--tls-verify=false`. Uninstall from the same directory, and pass the same `--quayRoot`:

```bash
./mirror-registry uninstall -v --quayRoot "$HOME/quay-install"
```

`--autoApprove` skips the uninstall prompt and deletes that directory. The host needs Podman for the login. `sudo dnf install -y container-tools` provides it. The older note also installed `ansible-core`, set `user.max_user_namespaces=28633`, and expected libvirt for `mirror-ocp-full.sh`.

## oc-mirror v2

`oc-mirror` is not in the `5.0.1` client directory. `oc-mirror.tar.gz` returned 404 there on 9 November 2026. The chapter downloads `oc-mirror.tar.gz` from the [OpenShift downloads](https://console.redhat.com/openshift/downloads) page, under OpenShift disconnected installation tools. Install `oc` first from [Client packages](../pre-steps/README.md). Set `umask` to `0022` on the host that runs the plugin. Do not rename the binary.

```bash
tar xvzf oc-mirror.tar.gz
chmod +x oc-mirror
sudo mv oc-mirror /usr/local/bin/
oc mirror --v2 --help
```

Save the pull secret from [console.redhat.com](https://console.redhat.com/openshift/install/pull-secret) as `$XDG_RUNTIME_DIR/containers/auth.json`, then add the mirror registry user. That file is how the plugin logs in. Do not use it as the cluster pull secret. The chapter warns that every node would then have write access to the registry. The cluster pull secret still needs an `auths` entry for `registry.example.com:8443` so the nodes can pull. Do not commit either file.

```bash
mkdir -p "$XDG_RUNTIME_DIR/containers"
cp ~/pull-secret.json "$XDG_RUNTIME_DIR/containers/auth.json"
```

The image set below is the 5.0 chapter sample. `graph: true` also writes the `UpdateService` manifest. Remove `operators` and `additionalImages` when you only need the platform release. Remove `packages` when you want the whole catalog. On 9 November 2026 the `stable-5.0` update graph listed `5.0.0` and `5.0.1`. The sample pins both ends at `5.0.0`. Set `maxVersion` to the release you are installing. The same day, [openshift-v5/clients/ocp/stable-5.0](https://mirror.openshift.com/pub/openshift-v5/clients/ocp/stable-5.0/) served the `5.0.1` client names. An earlier check that day returned 404. `candidate-5.0` still served the `5.0.0-rc.7` names.

```yaml
kind: ImageSetConfiguration
apiVersion: mirror.openshift.io/v2alpha1
mirror:
  platform:
    channels:
    - name: stable-5.0
      minVersion: 5.0.0
      maxVersion: 5.0.0
    graph: true
  operators:
    - catalog: registry.redhat.io/redhat/redhat-operator-index:v5.0
      packages:
       - name: aws-load-balancer-operator
       - name: 3scale-operator
  additionalImages:
   - name: registry.redhat.io/ubi8/ubi:latest
   - name: registry.redhat.io/ubi9/ubi@sha256:20f695d2a91352d4eaa25107535126727b5945bff38ed36a3e59590f495046f0
```

When the mirror host can reach both the internet and the registry, mirror straight to the registry. `--workspace` is required for that path.

```bash
oc mirror -c imageset-config.yaml --workspace file://$HOME/oc-mirror --v2 docker://registry.example.com:8443
```

When the registry is on the other side of an air gap, mirror to disk, move the archive, then mirror from disk. Use the same `oc-mirror` binary for both steps.

```bash
oc mirror -c imageset-config.yaml file://$HOME/oc-mirror --v2
oc mirror -c imageset-config.yaml --from file://$HOME/oc-mirror docker://registry.example.com:8443 --v2
```

The generated manifests are in `$HOME/oc-mirror/working-dir/cluster-resources`. That directory holds `ImageDigestMirrorSet`, `ImageTagMirrorSet`, `CatalogSource`, `ClusterCatalog`, and, when `graph` is true, `UpdateService`.

## Install from the mirror

The Agent-based chapter still says to copy `repositoryDigestMirrors` from `oc-mirror-workspace/results-*/imageContentSourcePolicy.yaml`. That is the v1 results path. v2 does not write it. Copy each `source` and `mirrors` pair from the `ImageDigestMirrorSet` into `imageContentSources`, and paste `rootCA.pem` into `additionalTrustBundle`.

```yaml
imageContentSources:
- mirrors:
  - registry.example.com:8443/<repository>
  source: quay.io/openshift-release-dev/ocp-release
additionalTrustBundle: |
  <contents of rootCA.pem>
```

Put those two fields in the `install-config.yaml` for [Agent-based Installer](../agent-based/README.md) or the user-provisioned file in [OpenShift on bare metal](../bare-metal/README.md). After the cluster is up, apply the generated resources. Do not change `spec.imageDigestMirrors` or `spec.imageTagMirrors` in those files.

```bash
oc apply -f "$HOME/oc-mirror/working-dir/cluster-resources"
oc apply -f "$HOME/oc-mirror/working-dir/cluster-resources/signature-configmap.json"
oc get imagedigestmirrorset
oc get catalogsource -n openshift-marketplace
```

Skip the signature command when you mirrored Operators and not a release. To use only the mirrored catalogs, disable the default ones:

```bash
oc patch OperatorHub cluster --type json -p '[{"op": "add", "path": "/spec/disableAllDefaultSources", "value": true}]'
```

## Older scripts

The scripts below are the 4.y path. They still contain a 4.y package list. Do not run them for a 5.0 release.

- [mirror-ocp-release.sh](https://github.com/tosin2013/openshift-4-deployment-notes/blob/master/disconnected-scripts/mirror-ocp-release.sh) mirrors one release with `oc adm release mirror`.
- [mirror-ocp-full.sh](https://github.com/tosin2013/openshift-4-deployment-notes/blob/master/disconnected-scripts/mirror-ocp-full.sh) mirrors the release and extra images.
- [disconnected-oc-mirror.sh](https://github.com/tosin2013/openshift-4-deployment-notes/blob/master/disconnected-scripts/disconnected-oc-mirror.sh) and [disconnected-olm.sh](https://github.com/tosin2013/openshift-4-deployment-notes/blob/master/disconnected-scripts/disconnected-olm.sh) are the v1 oc-mirror and catalog variants.
- [get-ai-svc-version.sh](https://github.com/tosin2013/openshift-4-deployment-notes/blob/master/disconnected-scripts/get-ai-svc-version.sh) asks the Assisted Installer which release it can install. It reads an offline token from `$HOME/rh-api-offline-token`. Do not commit the token.

Product docs: [About disconnected environments](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/disconnected_environments/about-disconnected-environments) (OpenShift Container Platform 5.0). The mirror steps are in [Mirroring images for a disconnected installation by using the oc-mirror plugin v2](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/disconnected_environments/mirroring-images-by-using-oc-mirror-plugin). The registry install is in [Creating a mirror registry with mirror registry for Red Hat OpenShift](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/disconnected_environments/installing-mirroring-creating-registry). The install-config fields are in [Understanding disconnected installation mirroring](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/installing_an_on-premise_cluster_with_the_agent-based_installer/understanding-disconnected-installation-mirroring).

Check `oc mirror --v2` and the channel name on the build you are installing.
