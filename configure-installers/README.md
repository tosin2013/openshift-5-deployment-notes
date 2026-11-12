# Installer binary

`openshift-install` has to match the OpenShift release you are installing. Download the tarball from the numbered directory under [openshift-v5/clients/ocp](https://mirror.openshift.com/pub/openshift-v5/clients/ocp/) and put `openshift-install` on the path.

On 9 November 2026 `5.0.0/` and `5.0.1/` each listed `openshift-install-linux-<version>.tar.gz` and `openshift-install-linux.tar.gz`. `candidate-5.0/` served the `5.0.0-rc.7` filenames. `stable-5.0/` returned 404 earlier that day and later served the `5.0.1` filenames. The 5.0 AWS chapter still links [openshift-v4/clients/ocp](https://mirror.openshift.com/pub/openshift-v4/clients/ocp/). These notes use `openshift-v5`.

On 12 November 2026 [5.0.1/](https://mirror.openshift.com/pub/openshift-v5/clients/ocp/5.0.1/) still listed `openshift-install-linux-5.0.1.tar.gz` and `openshift-install-linux.tar.gz`. [stable-5.0/](https://mirror.openshift.com/pub/openshift-v5/clients/ocp/stable-5.0/) and [latest/](https://mirror.openshift.com/pub/openshift-v5/clients/ocp/latest/) both served those `5.0.1` names. The same names were in [openshift-v4/clients/ocp/latest/](https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/). The unversioned `openshift-install-linux.tar.gz` there was the same size as `openshift-install-linux-5.0.1.tar.gz`, 465386764 bytes.

```bash
VERSION=5.0.1
curl -fL -o openshift-install-linux.tar.gz \
  "https://mirror.openshift.com/pub/openshift-v5/clients/ocp/${VERSION}/openshift-install-linux.tar.gz"
tar -xvf openshift-install-linux.tar.gz
./openshift-install version
```

Change `VERSION` to the build you are installing before you curl. `5.0.1` is a directory on the mirror. The [5.0 release notes](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/release_notes/ocp-5-0-release-notes) did not return a 5.0.1 section.

OpenShift 4 installer scripts stay in the [OpenShift 4 notes](https://github.com/tosin2013/openshift-4-deployment-notes). This page is the 5.0 download from a numbered `openshift-v5` directory.

The client that belongs with that installer is in [Client packages](../pre-steps/README.md). [configure-openshift-packages.sh](../pre-steps/configure-openshift-packages.sh) installs `oc`, `kubectl`, and `openshift-install` from this directory on RHEL 9 or newer. `--ccoctl` and `--opm` are optional. The AWS path is [OpenShift on AWS](../aws/README.md).

Product docs: [Installation overview](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/installation_overview/) (OpenShift Container Platform 5.0). The AWS download steps are in [Installer-provisioned infrastructure](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/installing_on_aws/installer-provisioned-infrastructure).

Check the mirror listing on the day you install.
