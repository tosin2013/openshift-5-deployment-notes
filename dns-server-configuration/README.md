# DNS

The nodes, the API, and `*.apps` resolve through a DNS server you run for a user-provisioned install. OpenShift 5 needs `api`, `api-int`, and `*.apps`, plus an A record and a PTR record for the bootstrap machine, each control plane, and each compute machine. A PTR record is not required for `*.apps`. etcd SRV records are not part of this zone.

```bash
sudo dnf install -y bind bind-utils
sudo firewall-cmd --add-service=dns --permanent
sudo firewall-cmd --reload
```

`/etc/named.conf` listens on the helper's address, allows the install subnet, and forwards what it does not own. Replace the example addresses.

```
acl internal_nets { 192.168.1.0/24; };

options {
  listen-on port 53 { 127.0.0.1; 192.168.1.211; };
  listen-on-v6 port 53 { none; };
  directory "/var/named";
  allow-query { localhost; internal_nets; };
  recursion yes;
  allow-recursion { localhost; internal_nets; };
  forwarders { 8.8.8.8; 1.1.1.1; };
  dnssec-validation no;
  check-names master ignore;
  check-names slave ignore;
  check-names response ignore;
};

zone "." IN {
  type hint;
  file "named.ca";
};

include "/etc/named.rfc1912.zones";

zone "ocp.example.com" IN {
  type master;
  file "ocp.example.com.zone";
  allow-query { any; };
  allow-transfer { none; };
  allow-update { none; };
};

zone "1.168.192.in-addr.arpa" {
  type master;
  file "1.168.192.in-addr.arpa.zone";
  allow-query { any; };
  allow-transfer { none; };
  allow-update { none; };
};
```

`/var/named/ocp.example.com.zone`:

```
$ORIGIN ocp.example.com.
$TTL 900
@ IN SOA dns.ocp.example.com. root.ocp.example.com. (
  2026110901 1D 1H 1W 3H
)
@       IN NS dns.ocp.example.com.
dns     IN A  192.168.1.211
api     IN A  192.168.1.212
api-int IN A  192.168.1.212
*.apps  IN A  192.168.1.213
```

Point the helper's own resolver at `127.0.0.1`, then:

```bash
named-checkconf /etc/named.conf
sudo systemctl enable --now named
dig @localhost api-int.ocp.example.com
dig @localhost apps.ocp.example.com
```

The full older zone files, including the pre-4.6 etcd records, are in [dns-server-configuration](https://github.com/tosin2013/openshift-4-deployment-notes/tree/master/dns-server-configuration).

Product docs: [User-provisioned infrastructure](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/installing_on_bare_metal/user-provisioned-infrastructure) (OpenShift Container Platform 5.0 Installing on bare metal).

Check the API and apps names against the load balancer addresses on the build you are installing.
