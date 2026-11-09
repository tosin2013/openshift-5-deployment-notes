# OpenShift on KVM

These notes are a user-provisioned bare metal install whose machines are libvirt guests. DHCP, DNS, TFTP, and HAProxy come up first. Then the guests boot the RHCOS image and their Ignition URL.

[virsh-vm-deployment.sh](https://github.com/tosin2013/openshift-4-deployment-notes/blob/master/kvm-scripts/virsh-vm-deployment.sh) creates a bootstrap disk and defines the guest with `virt-install`. It reads `oc-env` for the web server and the image URL. The script still uses `--os-variant rhel7` and a 4.y image path. Point the image at the 5.0 metal image and review the guest OS variant before you run it.

[openshift-deployment-kvm.sh](https://github.com/tosin2013/openshift-4-deployment-notes/blob/master/kvm-scripts/openshift-deployment-kvm.sh) starts the libvirt guests (`bootstrap`, then `master-01` through `master-03`, then the workers) after DHCP and HAProxy are running. [configure-local-images.sh](https://github.com/tosin2013/openshift-4-deployment-notes/blob/master/kvm-scripts/configure-local-images.sh) stages the RHCOS image on the KVM host. [cleanup-kvms.sh](https://github.com/tosin2013/openshift-4-deployment-notes/blob/master/kvm-scripts/cleanup-kvms.sh) removes the guests.

There is no separate KVM install book. Follow [Bare metal](../bare-metal/README.md) and the helper notes, with the guests in place of physical servers.

Product docs: [User-provisioned infrastructure](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/installing_on_bare_metal/user-provisioned-infrastructure) (OpenShift Container Platform 5.0 Installing on bare metal).

Check the image URL and the guest definition on the build you are installing.
