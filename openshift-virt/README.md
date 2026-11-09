# OpenShift Virtualization

Install the OpenShift Virtualization operator from the catalog into `openshift-cnv` and create the `HyperConverged` object. A search for the install chapter returned [Installing](https://docs.redhat.com/en/documentation/openshift_container_platform/4.16/html/virtualization/installing) (OpenShift Container Platform 4.16) as the newest install page. The 5.0 book that did come back is the release notes below.

The OpenShift 4 note in this area is a Migration Toolkit for Virtualization lab, not the install. It SSHs to a KVM hypervisor, runs [deploy-vyos-router.sh](https://github.com/tosin2013/openshift-4-deployment-notes/blob/master/openshift-virt/deploy-vyos-router.sh) to put a VyOS router on that host, and then walks a static-IP Windows migration. The script's notes include the appliance login. Change that password. The full lab is [openshift-virt/README.md](https://github.com/tosin2013/openshift-4-deployment-notes/blob/master/openshift-virt/README.md). Networking after install is [configure-openshift-virtualization-networking.md](https://github.com/tosin2013/openshift-4-deployment-notes/blob/master/post-steps/configure-openshift-virtualization-networking.md).

Product docs: [OpenShift Container Platform 5.0 Virtualization release notes](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/virtualization/release-notes).

Check the operator channel against your OpenShift version before you install.
