# HAProxy

HAProxy is the API and ingress load balancer when you provision the machines yourself. It answers 6443 for the API, 22623 for the machine config server, and 80 and 443 for routes.

```bash
sudo dnf install -y haproxy
sudo firewall-cmd --add-port={80/tcp,443/tcp,6443/tcp,22623/tcp,1936/tcp} --permanent
sudo firewall-cmd --reload
sudo cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.bak
```

Start from [haproxy-tcp.cfg](https://github.com/tosin2013/openshift-4-deployment-notes/blob/master/haproxy-configuration/haproxy-tcp.cfg) and set the control-plane and worker addresses. Allow the extra ports in SELinux:

```bash
sudo semanage port -a -t http_port_t -p tcp 22623
sudo semanage port -a -t http_port_t -p tcp 6443
sudo semanage port -a -t http_port_t -p tcp 1936
sudo systemctl enable --now haproxy
sudo systemctl status haproxy
```

Stats listen on port 1936. Set your own user and password in the config. If the host has more than one interface and HAProxy cannot bind, check which address the frontend uses.

Product docs: [User-provisioned infrastructure](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/installing_on_bare_metal/user-provisioned-infrastructure) (OpenShift Container Platform 5.0 Installing on bare metal).

Check the backends on the build you are installing. Port 32700 from the older note is not part of this list.
