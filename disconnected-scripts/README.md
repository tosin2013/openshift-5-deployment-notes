# Disconnected install and mirroring

Mirror the OpenShift release into a registry the cluster can reach, then point `install-config.yaml` at that registry.

On the mirror host:

```bash
sudo hostnamectl set-hostname registry.example.com
sudo dnf install -y ansible-core jq
sudo dnf install -y container-tools
```

Rootless Podman needs a user-namespace limit. The older note set `user.max_user_namespaces=28633` in `/etc/sysctl.d/userns.conf`. `mirror-ocp-full.sh` also expects libvirt on that host.

## Mirror registry

`openshift-v5/clients/mirror-registry/` returned 404 on 9 November 2026. The archive is [openshift-v4/clients/mirror-registry](https://mirror.openshift.com/pub/openshift-v4/clients/mirror-registry/). On that day the newest numbered directory was `1.3.11`, and `mirror-registry.tar.gz` was about 695 MB. There is no `latest` directory. The older note used GitHub `v1.3.10` and `mirror-registry-offline.tar.gz`.

[configure-other-clients.sh](../pre-steps/configure-other-clients.sh) extracts `mirror-registry`, `image-archive.tar`, and `execution-environment.tar` to `$HOME/mirror-registry`. It does not run the install.

```bash
../pre-steps/configure-other-clients.sh -i --mirror-registry
cd "$HOME/mirror-registry"
sudo mkdir -p /registry
sudo ./mirror-registry install --quayHostname "$(hostname)" --quayRoot /registry
sudo firewall-cmd --add-port=8443/tcp --permanent
sudo firewall-cmd --reload
sudo semanage port -a -t http_port_t -p tcp 8443
```

The registry CA is `/registry/quay-rootCA/rootCA.pem` after install. Uninstall with `sudo ./mirror-registry uninstall -v` from `$HOME/mirror-registry`.

## What to mirror

The OpenShift 5.0 disconnected book prefers the oc-mirror plugin v2. `oc adm release mirror` is deprecated as of 4.22. Use oc-mirror v2 for the release and the catalogs, then put the generated mirror config and the registry CA into `install-config.yaml` (`imageDigestSources` or the field your 5.0 installer documents, and `additionalTrustBundle`).

The scripts below are the older path. They still contain a 4.y package list. Do not run them for a 5.0 release until you have changed the release they mirror.

- [mirror-ocp-release.sh](https://github.com/tosin2013/openshift-4-deployment-notes/blob/master/disconnected-scripts/mirror-ocp-release.sh) mirrors one release. Set the registry URL. Replace `PASSWORD="CHANGEME"` with the registry password and do not commit the file.
- [mirror-ocp-full.sh](https://github.com/tosin2013/openshift-4-deployment-notes/blob/master/disconnected-scripts/mirror-ocp-full.sh) mirrors the release and extra images.
- [disconnected-oc-mirror.sh](https://github.com/tosin2013/openshift-4-deployment-notes/blob/master/disconnected-scripts/disconnected-oc-mirror.sh) and [disconnected-olm.sh](https://github.com/tosin2013/openshift-4-deployment-notes/blob/master/disconnected-scripts/disconnected-olm.sh) are the oc-mirror and catalog variants.
- [get-ai-svc-version.sh](https://github.com/tosin2013/openshift-4-deployment-notes/blob/master/disconnected-scripts/get-ai-svc-version.sh) asks the Assisted Installer which release it can install. It reads an offline token from `$HOME/rh-api-offline-token`. Do not commit the token.

Save the pull secret as `~/pull_secret.json` from [console.redhat.com](https://console.redhat.com/openshift/install). After the mirror, append the merged pull secret and the registry CA to `install-config.yaml`.

Product docs: [About disconnected environments](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/disconnected_environments/about-disconnected-environments) (OpenShift Container Platform 5.0).

Check the oc-mirror v2 command on the build you are installing. The scripts linked above are the 4.x path.
