# OpenShift on bare metal

You provide the machines, the network, and the load balancer. The installer writes Ignition. The helper serves it.

1. Read the machine and network requirements in the product chapter below. RHCOS 10 needs x86-64-v3 (AVX2) unless you select the RHCOS 9 image stream.
2. [DNS](../dns-server-configuration/README.md) for `api`, `api-int`, and `*.apps`.
3. [HAProxy](../haproxy-configuration/README.md) for the API, the machine config server, and ingress.
4. [PXE](../pxe-configuration/README.md) when the machines boot from the network.
5. [Installer binary](../configure-installers/README.md) for the 5.0 release.
6. [Ignition](../configure-ignitionfiles/README.md).
7. Power on the machines.

The HTTP server that publishes the images and Ignition files is not written up in this repo yet.

## Static addresses

[filetranspiler](https://github.com/ashcrow/filetranspiler) merges extra files into the Ignition the installer already wrote. Build a fake root for the node, then:

```bash
mkdir -p bootstrap/etc/NetworkManager/system-connections/
filetranspiler -i bootstrap.ign -f bootstrap -o bootstrap-static.ign
```

The older note wrote `ifcfg-enp1s0` under `etc/sysconfig/network-scripts/` with an example address `192.168.7.20`. On RHCOS 10, prefer a NetworkManager keyfile in that fake root. At the boot prompt, set the address and point `coreos.inst.image_url` and `coreos.inst.ignition_url` at the helper. Use the metal image from the 5.0 release, not `rhcos-4.2.0`.

Repeat for each control-plane and worker Ignition file.

Product docs: [Preparing for bare-metal cluster installation](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/installing_on_bare_metal/preparing-to-install-on-bare-metal) (OpenShift Container Platform 5.0 Installing on bare metal).

Check the image name and the Ignition URLs on the build you are installing.
