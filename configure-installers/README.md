# Installer binary

`openshift-install` has to match the OpenShift release you are installing. Download the tarball from the numbered directory under [openshift-v5/clients/ocp](https://mirror.openshift.com/pub/openshift-v5/clients/ocp/) and put `openshift-install` on the path.

On 9 November 2026 `5.0.0/` and `5.0.1/` each listed `openshift-install-linux-<version>.tar.gz` and `openshift-install-linux.tar.gz`. `candidate-5.0/` served the `5.0.0-rc.7` filenames. `stable-5.0/` returned 404 earlier that day and later served the `5.0.1` filenames. The 5.0 AWS chapter still links [openshift-v4/clients/ocp](https://mirror.openshift.com/pub/openshift-v4/clients/ocp/). These notes use `openshift-v5`.

```bash
VERSION=5.0.1
curl -fL -o openshift-install-linux.tar.gz \
  "https://mirror.openshift.com/pub/openshift-v5/clients/ocp/${VERSION}/openshift-install-linux.tar.gz"
tar -xvf openshift-install-linux.tar.gz
./openshift-install version
```

Change `VERSION` to the build you are installing before you curl. `5.0.1` is a directory on the mirror. The [5.0 release notes](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/release_notes/ocp-5-0-release-notes) did not return a 5.0.1 section.

The scripts in the OpenShift 4 notes still contain `VERSION="4.2."`:

- [configure-openshift-installer.sh](https://github.com/tosin2013/openshift-4-deployment-notes/blob/master/configure-installers/configure-openshift-installer.sh) looks up `latest` and a `4.2.` tarball name on `openshift-v4`.
- [configure-openshift-nightly-installer.sh](https://github.com/tosin2013/openshift-4-deployment-notes/blob/master/configure-installers/configure-openshift-nightly-installer.sh) does the same for a nightly.

Leave those scripts until `VERSION` is the 5.0 release. A 4.2 tarball will not install this release.

The client that belongs with that installer is in [Client packages](../pre-steps/README.md). [configure-openshift-packages.sh](../pre-steps/configure-openshift-packages.sh) installs `oc`, `kubectl`, and `openshift-install` from this directory on RHEL 9 or newer. `--ccoctl` and `--opm` are optional. The AWS path is [OpenShift on AWS](../aws/README.md).

Product docs: [Installation overview](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/installation_overview/) (OpenShift Container Platform 5.0). The AWS download steps are in [Installer-provisioned infrastructure](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/installing_on_aws/installer-provisioned-infrastructure).

Check the mirror listing on the day you install.
