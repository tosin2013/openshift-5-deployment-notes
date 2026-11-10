# Upgrades from OpenShift 4

Product docs: [Preparing to update a cluster](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/updating_clusters/preparing-to-update-a-cluster) (OpenShift Container Platform 5.0 Updating clusters).

This lab was installed as 5.0.0-rc.7. It does not demonstrate an upgrade. The release controller and the OKD 5 docs describe 4.x to 5.0 as an in-place cluster update, the same shape as a later 4.y minor update, on the `stable-5.0` or `candidate-5.0` channel. The path published for the early candidates starts at 4.22.

## RHCOS 10.2

The [5.0 release notes](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/release_notes/ocp-5-0-release-notes) say a new 5.0 install uses RHCOS 10.2 by default. After a 4.x to 5.0 update, moving nodes to RHCOS 10.2 means moving all of them. A mix of RHCOS 9 and RHCOS 10.2 is not supported. A cluster still using runc cannot move nodes to RHCOS 10.2, because runc is deprecated in 5.0. crun is required. See [Configuring the container runtime](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html-single/machine_configuration/#config-container-runtime_machine-configs-custom).

On 10 November 2026 the AWS cluster `ocp5` (5.0.1) was a fresh install. Every node was already RHCOS 10.2.20261102-1 with crun 1.30.1. That line is the lab record in [5.0.1](../releases/5.0.1.md).

## Before a real upgrade

- Confirm the channel offers 5.0: `oc adm upgrade`
- Confirm every node can boot RHCOS 10 before you move the pool, or keep every node on the RHEL 9 OS image stream. A mix of RHCOS 9 and RHCOS 10.2 is not supported. See [RHCOS 10](rhcos-10.md).
- Read `oc get clusterversion version -o yaml` and clear any `Upgradeable=False` condition.
- Plan for a MachineConfig rollout. The node OS changes.
- Treat third-party operators (virtualization, ODF, GitOps, ACM, Lightspeed) as separate support checks. Their 4.22 catalogs do not automatically mean 5.0 support.

## Placeholder

- [ ] Run 4.22 to 5.0 on a disposable cluster and record paused pools, etcd, and the time spent in `Progressing`
- [ ] Record the first 5.0 version the `stable-5.0` channel offers after GA
- [ ] Note any operator that had to be upgraded before the CVO would proceed

OKD reference: [Updating a cluster to OKD 5.0](https://docs.okd.io/latest/updating/updating_a_cluster/update-ocp-5.html).
