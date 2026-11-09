# PXE

A user-provisioned machine boots from DHCP, then from this TFTP server, and pulls the RHCOS image and its Ignition file.

```bash
sudo dnf install -y tftp-server
sudo firewall-cmd --add-service=tftp --permanent
sudo firewall-cmd --reload
```

The OpenShift 4 script that fills the TFTP root is [configure-pxe-server.sh](https://github.com/tosin2013/openshift-4-deployment-notes/blob/master/pxe-configuration/configure-pxe-server.sh). It reads an `oc-env` file for the web server and the RHCOS image. Point that image at the metal BIOS (or UEFI) image from the 5.0 release you are installing, not a 4.y filename.

```bash
sudo ./configure-pxe-server.sh
```

Product docs: [User-provisioned infrastructure](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/installing_on_bare_metal/user-provisioned-infrastructure) (OpenShift Container Platform 5.0 Installing on bare metal).

Check the boot files against the 5.0 release image before you power on a machine.
