# OpenShift 5 field notes

Field notes for installing and running OpenShift 5 on your cluster. The product manual starts at the [OpenShift Container Platform 5.0 installation overview](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/installation_overview/). Re-check a command on the build you are installing.

These notes are a private working set until the end of November 2026. Agents working in this repo: [AGENTS.md](AGENTS.md) and [llms.txt](llms.txt).

## Install

* [OpenShift on AWS](aws/)
* [OpenShift on bare metal](bare-metal/) — [Agent-based Installer](agent-based/) or the [Assisted Installer](assisted-installer/); user-provisioned PXE and HAProxy when you supply them
* [OpenShift on KVM](kvm-scripts/)
* [OpenShift on VMware](vmware/)
* [Assisted Installer](assisted-installer/)
* [Agent-based Installer](agent-based/) — bare-metal cluster from one ISO
* [Red Hat OpenShift Service on AWS](rosa/)
* [Azure Red Hat OpenShift](aro/)

## Before the nodes boot

* [Client packages](pre-steps/)
* [Installer binary](configure-installers/)
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
* [Certificates](post-steps/#certificates)
* [cert-manager](cert-manager/)
* [Chrony](post-steps/#chrony)
* [Cluster resource override](post-steps/#cluster-resource-override)
* [NFS](post-steps/#nfs)
* [Quay 3.18](post-steps/#quay)
* [GitOps](post-steps/#gitops)
* [Red Hat Advanced Cluster Management](acm/)
* [OpenShift Virtualization](openshift-virt/)
* [Ansible Tower (legacy)](https://github.com/tosin2013/openshift-4-deployment-notes/blob/master/post-steps/configure-ansible-tower.md)
* [Red Hat Single Sign-On 7.3 (older template)](https://github.com/tosin2013/openshift-4-deployment-notes/blob/master/post-steps/red-hat-sso-templates.md)

## Using the cluster

* [What changed from OpenShift 4](whats-new/)
* [OpenShift Lightspeed](ai/lightspeed/)
* [Agentic troubleshooting](ai/lightspeed/agentic-troubleshooting.md)
* [MCP server](ai/mcp-server/)
* [MCP gateway](ai/mcp-server/gateway.md)
* [Sample app](ai/sample-app/)
* [Release log](releases/) for a cluster you built
* [5.0.0](releases/5.0.0.md) — installer tarball is published under `openshift-v5/clients/ocp/5.0.0/`; this file is not a lab read
* [5.0.1](releases/5.0.1.md) — AWS lab read from 10 November 2026; the 5.0 release-notes chapter has no 5.0.1 section

## Guides

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

## To do

* [todo.md](todo.md)
