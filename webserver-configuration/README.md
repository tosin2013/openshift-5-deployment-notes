# Web server

A user-provisioned machine downloads its Ignition file from an HTTP or HTTPS server after it has an address. A PXE boot also downloads the live kernel, initramfs, and rootfs from that server. The kernel URL is HTTP, TFTP, or FTP. The 5.0 chapter says HTTPS and NFS are not supported for that kernel URL. This server is the [helper](../helper-node/README.md). It is separate from the ingress load balancer, which also answers on port 80.

The 5.0 chapter assumes the HTTP server already exists. On the helper, that server is `httpd`.

```bash
sudo dnf install -y httpd
sudo firewall-cmd --add-service=http --permanent
sudo firewall-cmd --reload
sudo systemctl enable --now httpd
```

After [Ignition](../configure-ignitionfiles/README.md) writes `$HOME/ocp`, publish `bootstrap.ign`, `master.ign`, and `worker.ign`. Keep the files if you will add compute machines later. The chapter's example URL is `http://192.168.1.2:80/installation_directory/bootstrap.ign`. `192.168.1.2` is that chapter's helper address.

```bash
sudo mkdir -p /var/www/html/openshift
sudo cp "$HOME/ocp/bootstrap.ign" "$HOME/ocp/master.ign" "$HOME/ocp/worker.ign" /var/www/html/openshift/
sudo restorecon -RFv /var/www/html/openshift
sha512sum /var/www/html/openshift/bootstrap.ign /var/www/html/openshift/master.ign /var/www/html/openshift/worker.ign
curl -k http://192.168.1.2/openshift/bootstrap.ign
```

Repeat the `curl` for `master.ign` and `worker.ign`. The response starts with `{"ignition":`. Use the SHA512 digest in the `coreos-installer` command in [OpenShift on bare metal](../bare-metal/README.md).

When the machines boot from the network, also publish the live kernel, initramfs, and rootfs. The boot menu is in [PXE](../pxe-configuration/README.md). Read the three URLs for your architecture from the installer, then download those URLs into the same directory. Keep these files if you will add compute machines later.

```bash
openshift-install coreos print-stream-json | grep -Eo '"https.*(kernel-|initramfs.|rootfs.)\w+(\.img)?"'
sudo curl -fL -o /var/www/html/openshift/<file> '<url>'
sudo restorecon -RFv /var/www/html/openshift
```

The chapter also links the RHCOS files on `mirror.openshift.com` under `openshift-v4`. Take the URLs from `openshift-install` for the release you are installing.

Product docs: [Installing RHCOS and starting the OpenShift Container Platform bootstrap process](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/installing_on_bare_metal/user-provisioned-infrastructure#creating-machines-bare-metal_installing-bare-metal) (OpenShift Container Platform 5.0 Installing on bare metal).

Check the Ignition URLs on the build you are installing.
