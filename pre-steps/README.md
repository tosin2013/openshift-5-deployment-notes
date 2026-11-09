# Client packages

Install `oc`, `kubectl`, and `openshift-install` on RHEL 9 or newer from the OpenShift release you are installing. RHEL 8 is not supported. The script in this directory is [configure-openshift-packages.sh](configure-openshift-packages.sh).

The OpenShift 4 copy of that script still defaults to `stable-4.15` on RHEL 8 and `latest` on RHEL 9. On 9 November 2026 `latest` under [openshift-v5/clients/ocp](https://mirror.openshift.com/pub/openshift-v5/clients/ocp/latest/) served `openshift-client-linux-4.22.22.tar.gz`. Use the script here instead.

```bash
chmod +x configure-openshift-packages.sh
./configure-openshift-packages.sh -h
./configure-openshift-packages.sh -i
```

With no `VERSION`, `-i` selects the newest numbered `5.x.y` directory that contains the client and the installer. On 9 November 2026 that directory was `5.0.1`, which listed `openshift-client-linux-5.0.1.tar.gz` and `openshift-install-linux-5.0.1.tar.gz`. The client archive contains `oc` and `kubectl`. The installer file the script downloads is `openshift-install-linux.tar.gz`. The directory named `latest` is not used.

Pin a release when you need that build:

```bash
VERSION=5.0.1 ./configure-openshift-packages.sh -i
```

`--ccoctl` installs `ccoctl` from that same directory. Use it for manual cloud credentials or STS. `--opm` installs `opm` for catalog work. A normal `-i` does not install either one.

```bash
./configure-openshift-packages.sh -i --ccoctl --opm
```

Helm, `rosa`, `butane`, `coreos-installer`, and `mirror-registry` are not in the release directory. Helm is the optional command in [OpenShift on AWS](../aws/README.md). `oc` on OpenShift 5 includes kustomize. The installer curl is in [Installer binary](../configure-installers/README.md). `oc-mirror` is not in the `5.0.1` directory. See [todo.md](../todo.md).

On 20 October 2026 one workstation still had `oc` 4.22.18, Helm 4.3.1, and kustomize 5.7.1 bundled in `oc`, talking to a 5.0 server. Replace the client when the 5.0 tarball is the one you intend to use.

Product docs: [Installation overview](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/installation_overview/) (OpenShift Container Platform 5.0). The Linux client steps are in [Installer-provisioned infrastructure](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/installing_on_aws/installer-provisioned-infrastructure). An older `oc` does not run every 5.0 command.

Check the download URL on the build you are installing.
