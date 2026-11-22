# OpenShift 5 field notes

Field notes for installing and running OpenShift 5 on your cluster. OpenShift 4 install notes are at [tosin2013/openshift-4-deployment-notes](https://github.com/tosin2013/openshift-4-deployment-notes). The product manual starts at the [OpenShift Container Platform 5.0 installation overview](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/installation_overview/). Re-check a command on the build you are installing.

Agents working in this repo: [AGENTS.md](AGENTS.md) and [llms.txt](llms.txt).

## Install

* [OpenShift on AWS](aws/)
* [OpenShift on bare metal](bare-metal/) — [Agent-based Installer](agent-based/) or the [Assisted Installer](assisted-installer/); user-provisioned PXE and HAProxy when you supply them
* [OpenShift on KVM (IBM Cloud)](kvm-scripts/) — see also [openshift-agent-install](https://github.com/tosin2013/openshift-agent-install) for the full KVM deployment toolchain (VyOS router, dnsmasq, bond+VLAN networking)
* [OpenShift on VMware](vmware/)
* [Assisted Installer](assisted-installer/)
* [Agent-based Installer](agent-based/) — bare-metal cluster from one ISO
* [Red Hat OpenShift Service on AWS](rosa/)
* [Azure Red Hat OpenShift](aro/)

## Before the nodes boot

* [Client packages](pre-steps/)
* [Installer binary](configure-installers/) — OCP 5 uses `openshift-v5` mirror: `./download-openshift-cli.sh 5.0`
* [Ignition](configure-ignitionfiles/)
* [DHCP](dhcp-configuration/)
* [DNS](dns-server-configuration/)
* [HAProxy](haproxy-configuration/)
* [PXE](pxe-configuration/)
* [Web server](webserver-configuration/)
* [Helper node](helper-node/)
* [Disconnected mirroring](disconnected-scripts/)
* [Operator catalogs](disconnected-scripts/operator-lifecycle-manager-on-restricted-networks.md)

## After the cluster is up

* [Identity providers](post-steps/identity-providers.md)
* [Registry](post-steps/#internal-registry-on-openshift-data-foundation)
* [Certificates — cert-manager](cert-manager/) ⚠️ **Read the cert-manager README before rotating any cert**
* [Chrony](post-steps/#chrony)
* [Cluster resource override](post-steps/#cluster-resource-override)
* [NFS](post-steps/#nfs)
* [Quay 3.18](post-steps/#quay)
* [GitOps](post-steps/#gitops) — see [agent-gitops-quickstarts](https://github.com/tosin2013/agent-gitops-quickstarts) for Day 2 operator profiles (kvm-ocp-virt, ODF 5.0, CNV)
* [Red Hat Advanced Cluster Management 5.0](acm/)
* [OpenShift Virtualization](openshift-virt/)
* [OpenShift Data Foundation 5.0](https://docs.redhat.com/en/documentation/red_hat_openshift_data_foundation/5.0/) — channel `stable-5.0`; fresh installs on OCP 5 do not need `StorageSystem` CR
* [Ansible Tower (legacy)](https://github.com/tosin2013/openshift-4-deployment-notes/blob/master/post-steps/configure-ansible-tower.md)
* [Red Hat Single Sign-On 7.3 (older template)](https://github.com/tosin2013/openshift-4-deployment-notes/blob/master/post-steps/red-hat-sso-templates.md)

## cert-manager — critical notes

> See [cert-manager/README.md](cert-manager/README.md) for the full procedure.

**Before rotating any cluster certificate with cert-manager**, run:

```bash
./cert-manager/instances/add-trusted-ca.sh
```

This distributes the Let's Encrypt CA chain to every RHCOS node via the MCO before the rollout starts. Skipping it causes all nodes to go `NotReady` (`Kubelet stopped posting node status`).

**Default cert scope — `*.apps` only (safe)**. Rotating the API server cert separately risks breaking kubelet client cert rotation (nodes show `User: system:anonymous`). Use `--include-api` only on AWS IPI clusters.

```bash
# Apps wildcard only (recommended for KVM/baremetal):
./post-steps/create_custom_cert.sh KEY SECRET you@yourcompany.com ZONE_ID REGION

# Apps + API server cert (AWS IPI only, requires MachineConfig-based CA):
./post-steps/create_custom_cert.sh KEY SECRET you@yourcompany.com ZONE_ID REGION --include-api
```

Cloud-specific kustomize instances: [cert-manager/instances/](cert-manager/instances/) — IBM Cloud KVM, AWS, GCP, Azure.

Ref: [OCP 5.0 — Proxy certificates (trustedCA)](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/security_and_compliance/certificate-types-and-descriptions)

## Using the cluster

* [What changed from OpenShift 4](whats-new/)
* [OpenShift Lightspeed](ai/lightspeed/)
* [Lightspeed catalog draft](ai/lightspeed/gitops-catalog-upstream.md)
* [Agentic troubleshooting](ai/lightspeed/agentic-troubleshooting.md)
* [MCP server](ai/mcp-server/)
* [MCP gateway](ai/mcp-server/gateway.md)
* [Sample app](ai/sample-app/)
* [Release log](releases/) for a cluster you built
* [5.0.0](releases/5.0.0.md) — installer tarball is published under `openshift-v5/clients/ocp/5.0.0/`
* [5.0.1](releases/5.0.1.md) — AWS lab read from 10 November 2026; KVM/IBM Cloud validation November 2026

## Guides

* [Interactive experiences](https://www.redhat.com/en/interactive-experiences)
* [OpenShift Examples](https://examples.openshift.pub/)
* [OpenShift Quickstarts](https://github.com/kenmoini/openshift-quickstarts/tree/main)
* [OpenShift Networking](https://network-insight.net/2022/06/09/openshift-networking/)
* [Architect OpenShift Virtualization](https://redhatquickcourses.github.io/architect-the-ocpvirt/Red%20Hat%20OpenShift%20Virtualization%20-%20Architect%20the%20OpenShift%20Virtualization/1/index.html)
* [Storage considerations for OpenShift Virtualization](https://developers.redhat.com/articles/2025/07/10/storage-considerations-openshift-virtualization)
* [OCS training](https://red-hat-storage.github.io/ocs-training/training/index.html)
* [ODF Sizer](https://access.redhat.com/labs/ocsst/#/workloads)
* [RHODS quick courses](https://github.com/RedHatQuickCourses/rhods-qc-apps/tree/main)
* [DevSecOps pipeline demo](https://github.com/rcarrata/devsecops-demo)
* [Advanced Cluster Security workshop](https://redhat-scholars.github.io/acs-workshop/acs-workshop/index.html)
* [Advanced Cluster Security 5.0 release notes](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_security_for_kubernetes/5.0/html/release_notes/release-notes-50)
* [OpenShift demos](https://github.com/rhthsa/openshift-demo/tree/main)
* [Developer Hub documentation](https://maarten-vandeperre.github.io/developer-hub-documentation/index.html)
* [Argo CD and team topologies](https://github.com/redhat-cop/helm-charts/blob/master/charts/gitops-operator/TEAM_DOCS.md#platform-argocd-namespaced-argocd-per-team)
* [OpenShift GitOps workshop](https://openshiftdemos.github.io/openshift-gitops-workshop/openshift-gitops-workshop/index.html)

## OCP 5 key facts (November 2026)

| Item | Value |
|---|---|
| Latest release | 5.0.1 |
| Kubernetes | 1.36 |
| Default OS | RHCOS 10 (RHEL 10 based) |
| CPU requirement | x86-64-v3 or newer (Cascadelake, Zen 3+) |
| CLI mirror | `mirror.openshift.com/pub/openshift-v5/` |
| ODF channel | `stable-5.0` |
| ArgoCD (OpenShift GitOps) | v1.22.3 (ArgoCD 3.6, Kustomize v5.8.3) |
| Last OCP 4.x release | 4.22 |

## To do

* [todo.md](todo.md)
