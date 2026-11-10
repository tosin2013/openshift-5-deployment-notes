# PXE

A user-provisioned machine boots from DHCP, then from this TFTP server, and pulls the RHCOS image and its Ignition file.

```bash
sudo dnf install -y tftp-server
sudo firewall-cmd --add-service=tftp --permanent
sudo firewall-cmd --reload
```

The 5.0 boot files are the live kernel, initramfs, and rootfs from `openshift-install coreos print-stream-json`. The menu is in [OpenShift on bare metal](../bare-metal/README.md). The OpenShift 4 script [configure-pxe-server.sh](https://github.com/tosin2013/openshift-4-deployment-notes/blob/master/pxe-configuration/configure-pxe-server.sh) fills TFTP from a metal image named in an `oc-env` file. That metal image is the older note.

Product docs: [User-provisioned infrastructure](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/installing_on_bare_metal/user-provisioned-infrastructure) (OpenShift Container Platform 5.0 Installing on bare metal).

Check the boot files against the 5.0 release image before you power on a machine.
