# Ignition

Ignition is how RHCOS comes up configured. Generate it on the install host after the 5.0 `openshift-install` binary is on the path.

```bash
ssh-keygen -t ed25519 -N '' -f ~/.ssh/cluster-key
chmod 400 ~/.ssh/cluster-key
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/cluster-key
mkdir -p "$HOME/ocp"
```

For FIPS, create an `rsa` or `ecdsa` key instead.

Get the pull secret from [console.redhat.com](https://console.redhat.com/openshift/install). Write `install-config.yaml` in `$HOME/ocp`. For a user-provisioned cluster, `platform` is `none: {}` and the network type is `OVNKubernetes`. `compute.replicas` stays `0`. You still boot the worker machines yourself. The OpenShift 4 sample used `OpenShiftSDN` and `OC_VERSION=4.2.0`. Do not copy those. The full bare-metal sample, including `machineNetwork`, is in [OpenShift on bare metal](../bare-metal/README.md).

```yaml
apiVersion: v1
baseDomain: example.com
metadata:
  name: ocp
compute:
  - name: worker
    replicas: 0
controlPlane:
  name: master
  replicas: 3
networking:
  networkType: OVNKubernetes
  clusterNetwork:
    - cidr: 10.128.0.0/14
      hostPrefix: 23
  serviceNetwork:
    - 172.30.0.0/16
platform:
  none: {}
pullSecret: 'pull secret'
sshKey: 'contents of ~/.ssh/cluster-key.pub'
```

`openshift-install` consumes `install-config.yaml`. Keep a copy before you generate:

```bash
cp "$HOME/ocp/install-config.yaml" "$HOME/ocp/install-config.yaml.bak"
openshift-install create manifests --dir="$HOME/ocp"
```

For a cluster that has worker machines, confirm `mastersSchedulable` is `false` in `$HOME/ocp/manifests/cluster-scheduler-02-config.yml`. For a three-node cluster, leave it `true`. Then:

```bash
openshift-install create ignition-configs --dir="$HOME/ocp"
```

Copy `bootstrap.ign`, `master.ign`, and `worker.ign` to the helper's web root. See [Helper node](../helper-node/README.md).

A vSphere `install-config` adds a `platform.vsphere` block (vCenter, datacenter, datastore, username). Put the password in the file on the install host and do not commit it. Proxy and extra CA fields, when you need them, go in the same file. The field list is in the product docs below.

Product docs: [Installation configuration parameters](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/installation_configuration/installation-config-parameters-generic) (OpenShift Container Platform 5.0). The [installation overview](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/installation_overview/) is the front door.

Check `create ignition-configs` on the build you are installing.
