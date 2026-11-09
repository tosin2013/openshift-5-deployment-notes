# DHCP

DHCP gives each RHCOS machine the address and the name it boots with. The `filename` and `next-server` lines hand the machine to PXE.

Install the server on the helper:

```bash
sudo dnf install -y dhcp-server
```

Edit `/etc/dhcp/dhcpd.conf`. The addresses below are examples.

```
authoritative;
ddns-update-style interim;
default-lease-time 14400;
max-lease-time 14400;

option routers                  192.168.1.1;
option broadcast-address        192.168.1.255;
option subnet-mask              255.255.255.0;
option domain-name-servers      192.168.1.245;
option domain-name              "example.com";

subnet 192.168.1.0 netmask 255.255.255.0 {
  pool {
    range 192.168.1.75 192.168.1.90;

    host bootstrap-0 { hardware ethernet 52:54:00:x:x:x; fixed-address 192.168.1.76; }
    host master-01   { hardware ethernet 52:54:00:x:x:x; fixed-address 192.168.1.77; }
    host master-02   { hardware ethernet 52:54:00:x:x:x; fixed-address 192.168.1.78; }
    host master-03   { hardware ethernet 52:54:00:x:x:x; fixed-address 192.168.1.79; }
    host worker-01   { hardware ethernet 52:54:00:x:x:x; fixed-address 192.168.1.80; }
    host worker-02   { hardware ethernet 52:54:00:x:x:x; fixed-address 192.168.1.81; }

    deny unknown-clients;

    filename "pxelinux.0";
    next-server 192.168.1.80;
  }
}
```

```bash
sudo systemctl enable --now dhcpd
sudo systemctl status dhcpd
```

Product docs: [User-provisioned infrastructure](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/installing_on_bare_metal/user-provisioned-infrastructure) (OpenShift Container Platform 5.0 Installing on bare metal). This helper satisfies the networking requirements in that chapter.

Check the lease file and the PXE handoff on the build you are installing.
