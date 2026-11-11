# To do

Open items for these notes. Check a box when the note exists or the upgrade has been re-read.

## Missing notes

- [x] Web server configuration. The 5.0 HTTP server is in [webserver-configuration/README.md](webserver-configuration/README.md). The OpenShift 4 index still links `webserver-configuration/`, and that folder is missing there.
- [ ] Re-run the VMware guides on OpenShift 5 and replace the index in [vmware/README.md](vmware/README.md) with the commands you used. The 5.0 release notes, last modified 9 November 2026, add VMware Cloud Foundation 9.1 and an in-place upgrade from vCenter 8 to vCenter 9. The note still says vSphere 8.0 Update 1 is the floor. Scripts stay in the [OpenShift 4 notes](https://github.com/tosin2013/openshift-4-deployment-notes/tree/master/vmware).
- [ ] Re-run the Assisted Installer scripts against a 5.0 release. Scripts stay in the [OpenShift 4 notes](https://github.com/tosin2013/openshift-4-deployment-notes/tree/master/assisted-installer).
- [ ] Re-run the ROSA create path and confirm the current `rosa` flags. The CLI install is in [pre-steps](pre-steps/README.md). The create scripts stay in the [OpenShift 4 notes](https://github.com/tosin2013/openshift-4-deployment-notes/tree/master/rosa).
- [ ] Re-run the ARO create path. The full command list stays in the [OpenShift 4 notes](https://github.com/tosin2013/openshift-4-deployment-notes/blob/master/aro/README.md). On 10 November 2026 a search for an ARO 5.0 install book still did not return one.
- [x] Write the Agent-based Installer commands in [agent-based/README.md](agent-based/README.md). The commands and both config files are in the note.
- [x] Closing paragraph of [whats-new/README.md](whats-new/README.md). The [5.0 release notes](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/release_notes/ocp-5-0-release-notes) say OpenShift Container Platform 5.0 (`RHEA-2026:4893`) is available and uses Kubernetes 1.36.
- [x] [ai/mcp-server/README.md](ai/mcp-server/README.md). The 5.0 release notes say the MCP server is generally available, including the MCP Lifecycle Operator and the `MCPServer` resource. The MCP chapter still marks that operator Technology Preview. The Lightspeed `OLSConfig` MCP tool stays a separate claim.
- [x] RHCOS 10.2 constraint in [whats-new/upgrades-from-4.md](whats-new/upgrades-from-4.md). A cluster still using runc cannot move nodes to RHCOS 10.2. crun is required. A mix of RHCOS 9 and RHCOS 10.2 is not supported.
- [x] [aws/README.md](aws/README.md) records the 5.0 options: user-managed DNS, dual-stack, and outbound access to `ec2.us-east-1.amazonaws.com:443` when the interactive installer generates `install-config.yaml`.
- [ ] Hosted control planes. The 5.0 release notes say hosted control planes for 5.0 are available. This index has no note. Do not start a procedure until the 5.0 hosted control planes book is fetched.
- [ ] [virsh-vm-deployment.sh](https://github.com/tosin2013/openshift-4-deployment-notes/blob/master/kvm-scripts/virsh-vm-deployment.sh) still uses `--os-variant rhel7` and a 4.y image path. Do not run it until both match 5.0. See [kvm-scripts/README.md](kvm-scripts/README.md).

## Upgrades to re-check

- [x] Workstation `oc` was 4.22.18 on 20 October 2026. This host's client is 5.0.1, from [pre-steps/README.md](pre-steps/README.md).
- [ ] Do not run the OpenShift 4 client and installer scripts for 5.0. [configure-openshift-installer.sh](https://github.com/tosin2013/openshift-4-deployment-notes/blob/master/configure-installers/configure-openshift-installer.sh) is still `VERSION="4.2."`. [configure-openshift-packages.sh](https://github.com/tosin2013/openshift-4-deployment-notes/blob/master/pre-steps/configure-openshift-packages.sh) still defaults to `stable-4.15`. See [configure-installers/README.md](configure-installers/README.md).
- [x] OpenShift Virtualization install chapter. The 5.0 procedure is in [openshift-virt/README.md](openshift-virt/README.md). On 11 November 2026 `kubevirt-hyperconverged` on `ocp5` was channel `stable`, CSV `kubevirt-hyperconverged-operator.v5.0.0`. The workers are `m6i.xlarge`, so this cluster is not the AWS bare-metal install target.
- [x] ACM 5.0 procedure is in [acm/README.md](acm/README.md). On 11 November 2026 the `ocp5` catalog default was `release-5.0`, CSV `advanced-cluster-management.v5.0.0`. The operator was not installed. The OpenShift 4 notes stay ACM 2.4 and are not applied.
- [ ] Confirm the OpenShift Data Foundation channel for OpenShift 5 before you install it. On 11 November 2026 the `ocp5` `redhat-operators` catalog listed `odf-operator` default channel `stable-4.22`, CSV `odf-operator.v4.22.7-rhodf`. No 5.0 channel was present. The 5.0 storage chapter says OpenShift Data Foundation supports volume group snapshots and does not name the operator channel. Do not install from the 4.22 listing.
- [x] Confirm the Quay channel. On 11 November 2026 the `ocp5` `redhat-operators` catalog still had `stable-3.18` as the default and newest `quay-operator` channel, CSV `quay-operator.v3.18.2`. [README.md](README.md) and [post-steps/README.md](post-steps/README.md) stay on `stable-3.18`.

## Disabled on 5.0.0-rc.7

Look again after a feature-gate change. Do not add install folders until they are enabled.

Read on 10 November 2026 from the 5.0.1 cluster `ocp5` (`oc get featuregate cluster`, empty `spec`). The same four are still disabled. The 5.0 GA release notes fetched on 10 November 2026 do not promote them. The lists are in [feature gates](whats-new/feature-gates.md).

- [ ] Bootc node management (`BootcNodeManagement` disabled)
- [ ] Cluster API install (`ClusterAPIInstall` disabled)
- [ ] Machine API migration (`MachineAPIMigration` disabled)
- [ ] Karpenter operator (`KarpenterOperator` disabled)

## Repos not folded in yet

- [ ] https://github.com/openshift/oc-mirror/
- [ ] https://github.com/openshift/mirror-gui/ lists OpenShift 4.16 through 4.22 on 10 November 2026. Fold the install into [Disconnected install](disconnected-scripts/README.md) when that list includes 5.0.
- [ ] https://github.com/tosin2013/ztp-pipeline-relocatable — the 5.0 product page is [Preparing the hub cluster for GitOps ZTP](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/edge_computing/ztp-preparing-the-hub-cluster). Do not copy the repository.
- [ ] https://github.com/tosin2013/ztp-the-hard-way — same 5.0 edge chapter. Do not copy the repository.

## Your own cluster

File a cluster you built under [releases/](releases/README.md). [cluster/this-lab.md](cluster/this-lab.md) is one dated read and is not the front door.
