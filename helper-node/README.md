# Helper node

One machine on the install network runs DNS, DHCP, PXE, HAProxy, and the HTTP server that hands out RHCOS and Ignition. Use a current RHEL host with a static address. The older note assumed RHEL 7.

Size that has been enough for a lab: 4 vCPU, 4 GB RAM, 40 GB disk. The host needs a route to the internet while you download the release. The install subnet should not already have a DHCP server.

```bash
sudo dnf install -y firewalld
sudo systemctl enable --now firewalld
```

Then follow, in this order:

1. [DHCP](../dhcp-configuration/README.md)
2. [DNS](../dns-server-configuration/README.md)
3. [PXE](../pxe-configuration/README.md)
4. [HAProxy](../haproxy-configuration/README.md)
5. [Web server](../webserver-configuration/README.md)

Install the web server with the other services. Copy `bootstrap.ign`, `master.ign`, and `worker.ign` after `openshift-install` writes them. If those files were created on another machine, copy them onto the helper and follow the same publish steps.

An Ansible role that builds the same helper is [christianh814/ocp4-upi-helpernode](https://github.com/christianh814/ocp4-upi-helpernode). Read its OpenShift version before you run it.

Product docs: [User-provisioned infrastructure](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/installing_on_bare_metal/user-provisioned-infrastructure) (OpenShift Container Platform 5.0 Installing on bare metal).

Check the helper's services on the build you are installing.
