# OpenShift on bare metal

Most bare-metal clusters are installed with one of these two. Neither uses PXE or HAProxy.

- [Agent-based Installer](../agent-based/README.md). One ISO from `install-config.yaml` and `agent-config.yaml`. `apiVIPs` and `ingressVIPs` are the API and ingress addresses. The machines boot that ISO.
- [Assisted Installer](../assisted-installer/README.md) at [console.redhat.com](https://console.redhat.com/openshift/assisted-installer/clusters/~new). The console builds the discovery ISO, checks the hosts, and installs the cluster.

## User-provisioned

Use this path when you provide the load balancer and you boot RHCOS yourself. `platform` is `none: {}`. The Agent-based `platform.baremetal` VIPs do not apply here. HAProxy serves the API, the machine config server, and ingress. PXE applies only when the machines boot from the network. DNS is required on this path and on the two paths above.

1. Read the machine and network requirements in [Preparing for bare-metal cluster installation](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/installing_on_bare_metal/preparing-to-install-on-bare-metal). [RHCOS 10](../whats-new/rhcos-10.md) needs x86-64-v3 (AVX2) unless you select the RHCOS 9 image stream. The measured rows on that page stay the lab record.

2. Run the services from [Helper node](../helper-node/README.md), in this order: [DHCP](../dhcp-configuration/README.md), [DNS](../dns-server-configuration/README.md), [PXE](../pxe-configuration/README.md) when the machines boot from the network, and [HAProxy](../haproxy-configuration/README.md).

   For a cluster named `test` and a base domain `example.com`, the 5.0 chapter requires these names before the machines boot. Point `api` and `api-int` at the API load balancer. Point `*.apps` at the ingress load balancer. Add an A record and a PTR record for `bootstrap`, for each control plane, and for each compute machine. A PTR record is not required for `*.apps`. etcd SRV records are not required. The chapter's BIND example uses `ocp4.example.com` and `192.168.1.5` for both load balancers. The zone in [DNS](../dns-server-configuration/README.md) is `ocp.example.com` on `192.168.1.0/24`. Use one name and one subnet in both places.

   HAProxy listens on 6443 and 22623 for the bootstrap and control plane, and on 80 and 443 for ingress. Remove the bootstrap backend after the control plane is up. On a three-node cluster the ingress pods run on the control plane, so 80 and 443 point at those machines.

3. Install `openshift-install` from [Client packages](../pre-steps/README.md).

```bash
../pre-steps/configure-openshift-packages.sh -i
```

4. Create an install directory, an `ed25519` key, and `install-config.yaml`. For FIPS, create an `rsa` or `ecdsa` key instead. Do not commit the pull secret. `compute.replicas` stays `0` on this path even when you boot worker machines yourself. `controlPlane.replicas` is `3`, or `1` for a single node. Set `machineNetwork` to the subnet of the NIC the nodes use. The sample below is the 5.0 chapter sample.

```bash
ssh-keygen -t ed25519 -N '' -f ~/.ssh/cluster-key
chmod 400 ~/.ssh/cluster-key
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/cluster-key
mkdir -p "$HOME/ocp"
```

```yaml
apiVersion: v1
baseDomain: example.com
compute:
- hyperthreading: Enabled
  name: worker
  replicas: 0
controlPlane:
  hyperthreading: Enabled
  name: master
  replicas: 3
metadata:
  name: test
networking:
  clusterNetwork:
  - cidr: 10.128.0.0/14
    hostPrefix: 23
  networkType: OVNKubernetes
  machineNetwork:
  - cidr: 192.168.0.0/16
  serviceNetwork:
  - 172.30.0.0/16
platform:
  none: {}
fips: false
pullSecret: '<pull_secret>'
sshKey: '<ssh_pub_key>'
```

Paste the pull secret from [console.redhat.com](https://console.redhat.com/openshift/install/pull-secret) and the contents of `~/.ssh/cluster-key.pub`. A disconnected install also needs `additionalTrustBundle` and `imageContentSources` from [Disconnected install](../disconnected-scripts/README.md).

`openshift-install` consumes `install-config.yaml`. Copy it, generate the manifests, then generate Ignition. Ignition certificates are short-lived. Use the files within 12 hours, and do not reuse the install directory.

```bash
cp "$HOME/ocp/install-config.yaml" "$HOME/ocp-install-config.yaml"
openshift-install create manifests --dir "$HOME/ocp"
```

For a cluster that has worker machines, confirm `mastersSchedulable` is `false` in `$HOME/ocp/manifests/cluster-scheduler-02-config.yml`. For a three-node cluster, leave that value `true` so workloads can run on the control plane, and do not boot worker machines. Then:

```bash
openshift-install create ignition-configs --dir "$HOME/ocp"
```

The directory then contains `bootstrap.ign`, `master.ign`, `worker.ign`, and `auth/kubeconfig`. Do not commit `auth/`.

5. Publish the Ignition files and the RHCOS live images from the helper. The HTTP server steps are not written up in this repo yet. [Helper node](../helper-node/README.md) copies the `.ign` files to `/var/www/html/openshift/ignitions/`. Record the SHA512 digest of each Ignition file:

```bash
sha512sum "$HOME/ocp/bootstrap.ign" "$HOME/ocp/master.ign" "$HOME/ocp/worker.ign"
curl -k http://<HTTP_server>/bootstrap.ign
```

List the live images for this installer:

```bash
openshift-install coreos print-stream-json | grep '\.iso[^.]'
openshift-install coreos print-stream-json | grep -Eo '"https.*(kernel-|initramfs.|rootfs.)\w+(\.img)?"'
```

6. Boot the machines. Install the bootstrap machine and the control plane before you finish the cluster. When the control plane is not schedulable, also install at least two compute machines. Each machine gets the Ignition file for its role.

   ISO: boot the live ISO to a shell, then install. Do not pass kernel arguments for this path.

```bash
sudo coreos-installer install --ignition-url=http://<HTTP_server>/<node_type>.ign /dev/sda --ignition-hash=sha512-<digest>
```

`<node_type>` is `bootstrap`, `master`, or `worker`. The chapter's example URL is `http://192.168.1.2:80/installation_directory/bootstrap.ign` and the disk is `/dev/sda`. Reboot after the install. The console should show `Ignition: user-provided config was applied`.

   PXE: the 5.0 menu uses the live kernel, initramfs, and rootfs. `coreos.inst.image_url` and a `rhcos-*-metal` image are the older note. Swap `bootstrap.ign` for `master.ign` or `worker.ign` on those machines. The kernel URL must be HTTP, TFTP, or FTP.

```
DEFAULT pxeboot
TIMEOUT 20
PROMPT 0
LABEL pxeboot
    KERNEL http://<HTTP_server>/rhcos-<version>-live-kernel-<architecture>
    APPEND initrd=http://<HTTP_server>/rhcos-<version>-live-initramfs.<architecture>.img coreos.live.rootfs_url=http://<HTTP_server>/rhcos-<version>-live-rootfs.<architecture>.img coreos.inst.install_dev=/dev/sda coreos.inst.ignition_url=http://<HTTP_server>/bootstrap.ign
```

After the machines reboot, bootstrap starts on its own if DNS and the load balancer are already in place. The same chapter then covers taking the bootstrap machine out of the load balancer, approving the pending CSRs, and logging in with `auth/kubeconfig`. In the proxy section, the chapter uses this command when the installation program times out:

```bash
openshift-install wait-for install-complete --log-level debug
```

## Static addresses

For the ISO path in [Agent-based Installer](../agent-based/README.md), set the MAC, the NIC, the disk, and the address in the `hosts` block.

On this user-provisioned path, DHCP is how the 5.0 chapter expects the nodes to get an address and a hostname. A static ISO install copies the live system's network with `coreos-installer install --copy-network`. The older note set the address at the boot prompt with `coreos.inst.image_url`, and wrote `ifcfg-enp1s0` under `etc/sysconfig/network-scripts/` with an example address `192.168.7.20`.

Product docs: [Installing a user-provisioned cluster on bare metal](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/installing_on_bare_metal/user-provisioned-infrastructure) (OpenShift Container Platform 5.0 Installing on bare metal). Machine requirements are in [Preparing for bare-metal cluster installation](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/installing_on_bare_metal/preparing-to-install-on-bare-metal).

Check the image names and the Ignition URLs on the build you are installing.
