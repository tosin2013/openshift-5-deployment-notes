# Agent-based Installer

The Agent-based Installer builds a bootable ISO from `install-config.yaml` and `agent-config.yaml`. One host becomes the rendezvous host and runs the Assisted Service. The other hosts boot the same ISO. Use it when the machines are bare metal and you do not want the user-provisioned path in [OpenShift on bare metal](../bare-metal/README.md): no HAProxy, no PXE, and no separate Ignition files.

This example is one control plane, which is the sample in the 5.0 chapter. Change `controlPlane.replicas` and `compute.replicas` for the cluster you are building. A three-node cluster is three control plane machines and `compute.replicas: 0`.

Install `openshift-install` with [Client packages](../pre-steps/README.md). [DNS](../dns-server-configuration/README.md) must answer `api`, `api-int`, and `*.apps`. The sample zone in that note uses `192.168.1.212` and `192.168.1.213` for `ocp.example.com`. For this example the records are:

```
api.sno-cluster.test.example.com.     IN A 192.168.111.3
api-int.sno-cluster.test.example.com. IN A 192.168.111.3
*.apps.sno-cluster.test.example.com.  IN A 192.168.111.4
```

Every host must reach the rendezvous host on TCP 8090. [openshift-agent-install](https://github.com/tosin2013/openshift-agent-install) automates this path and still downloads a 4.y client.

1. Install `nmstatectl`. The chapter does this before a static host config.

```bash
sudo dnf install /usr/bin/nmstatectl -y
```

2. Save the pull secret from [console.redhat.com](https://console.redhat.com/openshift/install/pull-secret). Create the SSH key and paste `~/.ssh/cluster-key.pub` into `sshKey`. Do not commit the pull secret or the private key.

```bash
ssh-keygen -t ed25519 -N '' -f ~/.ssh/cluster-key
```

3. Create an empty directory and write both files into it. The chapter prints `platform: none` in the main sample and `platform.baremetal` with `apiVIPs` on `192.168.11.3` in the bare-metal example. The host block uses `192.168.111.80` with prefix 23. Those samples are not one network. This file uses `192.168.110.0/23`, which is that host prefix, and puts the VIPs on it.

```bash
mkdir "$HOME/agent-cluster"
```

`install-config.yaml`:

```yaml
apiVersion: v1
baseDomain: test.example.com
metadata:
  name: sno-cluster
compute:
- architecture: amd64
  hyperthreading: Enabled
  name: worker
  replicas: 0
controlPlane:
  architecture: amd64
  hyperthreading: Enabled
  name: master
  replicas: 1
networking:
  networkType: OVNKubernetes
  clusterNetwork:
  - cidr: 10.128.0.0/14
    hostPrefix: 23
  machineNetwork:
  - cidr: 192.168.110.0/23
  serviceNetwork:
  - 172.30.0.0/16
platform:
  baremetal:
    apiVIPs:
    - 192.168.111.3
    ingressVIPs:
    - 192.168.111.4
pullSecret: '<pull_secret>'
sshKey: '<ssh_pub_key>'
```

`agent-config.yaml`:

```yaml
apiVersion: v1beta1
kind: AgentConfig
metadata:
  name: sno-cluster
rendezvousIP: 192.168.111.80
hosts:
- hostname: master-0
  interfaces:
  - name: eno1
    macAddress: 00:ef:44:21:e6:a5
  rootDeviceHints:
    deviceName: /dev/sdb
  networkConfig:
    interfaces:
    - name: eno1
      type: ethernet
      state: up
      mac-address: 00:ef:44:21:e6:a5
      ipv4:
        enabled: true
        address:
        - ip: 192.168.111.80
          prefix-length: 23
        dhcp: false
    dns-resolver:
      config:
        server:
        - 192.168.111.1
    routes:
      config:
      - destination: 0.0.0.0/0
        next-hop-address: 192.168.111.2
        next-hop-interface: eno1
        table-id: 254
```

Change the MAC, the NIC name, the disk, and the addresses in `agent-config.yaml` before you boot a machine. That block is the static network. From the user-provisioned list in [OpenShift on bare metal](../bare-metal/README.md):

- DNS still applies. Use the three records above. The sample zone in that note is a different subnet.
- HAProxy does not apply. `apiVIPs` and `ingressVIPs` are the API and ingress addresses.
- PXE does not apply. The machines boot the ISO.
- Ignition and `filetranspiler` do not apply. Those values are already in `agent-config.yaml`.
- The installer is [Client packages](../pre-steps/README.md).

For a disconnected mirror, add `additionalTrustBundle` and `imageContentSources` from [Disconnected install](../disconnected-scripts/README.md).

4. Create the ISO and boot it on the machines. The image is `agent.x86_64.iso`, `agent.aarch64.iso`, or `agent.s390x.iso`.

```bash
openshift-install --dir "$HOME/agent-cluster" agent create image
```

5. Wait until the install finishes. The command prints the path to `auth/kubeconfig`. Do not commit that file.

```bash
openshift-install --dir "$HOME/agent-cluster" agent wait-for install-complete
```

Product docs: [Installing an on-premise cluster with the Agent-based Installer](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/installing_an_on-premise_cluster_with_the_agent-based_installer/) (OpenShift Container Platform 5.0). The files and commands are in [Installing a cluster with customizations](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/installing_an_on-premise_cluster_with_the_agent-based_installer/installing-with-agent-based-installer). `agent create image` and `agent wait-for install-complete` are in [Installing a cluster](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/installing_an_on-premise_cluster_with_the_agent-based_installer/installing-with-agent-basic).

Check `openshift-install agent` on the build you are installing.
