# To do

Open items for these notes. Check a box when the note exists or the upgrade has been re-read.

## Missing notes

- [ ] Web server configuration. Linked from the OpenShift 4 index and missing in both repositories.
- [ ] `run-ocp-installer`. Linked from the OpenShift 4 index and missing in both repositories.
- [ ] Re-run the VMware guides on OpenShift 5 and replace the index in [vmware/README.md](vmware/README.md) with the commands you used. Scripts stay in the [OpenShift 4 notes](https://github.com/tosin2013/openshift-4-deployment-notes/tree/master/vmware).
- [ ] Re-run the Assisted Installer scripts against a 5.0 release. Scripts stay in the [OpenShift 4 notes](https://github.com/tosin2013/openshift-4-deployment-notes/tree/master/assisted-installer).
- [ ] Re-run the ROSA create path and confirm the current `rosa` flags. The CLI install is in [pre-steps](pre-steps/README.md). The create scripts stay in the [OpenShift 4 notes](https://github.com/tosin2013/openshift-4-deployment-notes/tree/master/rosa).
- [ ] Re-run the ARO create path. The full command list stays in the [OpenShift 4 notes](https://github.com/tosin2013/openshift-4-deployment-notes/blob/master/aro/README.md).
- [ ] Write the Agent-based Installer commands in [agent-based/README.md](agent-based/README.md). The page currently points at the 5.0 book only.

## Upgrades to re-check

- [ ] Workstation `oc` was 4.22.18 on 20 October 2026. Install the 5.0 client when that is the tarball you want. See [pre-steps/README.md](pre-steps/README.md).
- [ ] Installer scripts in the OpenShift 4 notes are pinned at `4.2.`. See [configure-installers/README.md](configure-installers/README.md).
- [ ] `stable-5.0` on the OpenShift mirror returned 404 on 9 November 2026. `candidate-5.0` served the `5.0.0-rc.7` client and installer names. Numbered directories `5.0.0` and `5.0.1` contained the tarballs. See [aws/README.md](aws/README.md).
- [ ] [configure-openshift-packages.sh](https://github.com/tosin2013/openshift-4-deployment-notes/blob/master/pre-steps/configure-openshift-packages.sh) defaults to `stable-4.15`.
- [ ] ARO install book. The last search returned no ARO install book. The newest ARO page was OpenShift Data Foundation 4.22.
- [ ] OpenShift Virtualization install chapter. The last search returned 4.16 as the newest install page. The 5.0 hit was the release notes.
- [ ] ACM notes in the OpenShift 4 repository are 2.4 era. Do not apply them. Re-read when you install 2.17 or newer.
- [ ] Confirm the OpenShift Data Foundation channel for OpenShift 5 before you install it.

## Disabled on 5.0.0-rc.7

Look again after a feature-gate change. Do not add install folders until they are enabled.

- [ ] Bootc node management
- [ ] Cluster API install
- [ ] Machine API migration
- [ ] Karpenter operator

## Repos not folded in yet

- [ ] https://github.com/openshift/oc-mirror/
- [ ] https://github.com/tosin2013/ztp-pipeline-relocatable
- [ ] https://github.com/tosin2013/ztp-the-hard-way

## Your own cluster

File a cluster you built under [releases/](releases/README.md). [cluster/this-lab.md](cluster/this-lab.md) is one dated read and is not the front door.
