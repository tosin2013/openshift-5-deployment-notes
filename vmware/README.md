# OpenShift on VMware vSphere

Install on vSphere with the installer, with machines you provide, or with the Assisted Installer. The step-by-step guides are still in the OpenShift 4 notes. Read them against the 5.0 vSphere chapter before you follow a command. The 4.13 and packer scripts are not copied here.

- [User-provisioned](https://github.com/tosin2013/openshift-4-deployment-notes/blob/master/vmware/vsphere-upi-installation.md)
- [User-provisioned with static IP](https://github.com/tosin2013/openshift-4-deployment-notes/blob/master/vmware/vsphere-upi-installation-static-ip.md)
- [Standard installer-provisioned](https://github.com/tosin2013/openshift-4-deployment-notes/blob/master/vmware/vmware-standard-ipi-install.md)
- [Three-node installer-provisioned](https://github.com/tosin2013/openshift-4-deployment-notes/blob/master/vmware/vmware-3-node-ipi-install.md)
- [VMware Cloud public environment](https://github.com/tosin2013/openshift-4-deployment-notes/blob/master/vmware/vmware_public_env.md)
- Storage after an Assisted Installer install: [vsphere-configure-storage-assisted-installer.sh](https://github.com/tosin2013/openshift-4-deployment-notes/blob/master/vmware/vsphere-configure-storage-assisted-installer.sh) and [Red Hat solution 6677901](https://access.redhat.com/solutions/6677901)
- Registry storage after install: [configuring-registry.md](https://github.com/tosin2013/openshift-4-deployment-notes/blob/master/vmware/configuring-registry.md)

Set `disk.EnableUUID` to `TRUE` on the virtual machines. vSphere 8.0 Update 1 or later is the floor called out for OpenShift 5.0.

Product docs: [Installing on VMware vSphere](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/installing_on_vmware_vsphere/) (OpenShift Container Platform 5.0).

Check the vCenter version and the installer flags on the build you are installing.
