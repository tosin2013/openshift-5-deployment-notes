# Assisted Installer

The Assisted Installer on the Hybrid Cloud Console builds the discovery ISO, checks the hosts, and installs the cluster. You can drive the same API with the scripts in the OpenShift 4 notes. Those scripts are not copied here. They were written when the service reported 4.y releases. Point them at a 5.0 release before you rely on them.

You need `curl`, `jq`, `python3`, and `j2cli` (`pip3 install j2cli`).

1. Save an offline token from [access.redhat.com/management/api](https://access.redhat.com/management/api) to `~/rh-api-offline-token`. Do not commit it.
2. Save the pull secret from [console.redhat.com](https://console.redhat.com/openshift/install) to `~/ocp-pull-secret`.
3. Create an SSH key at `~/.ssh/id_rsa.pub`.
4. Copy [example.cluster-vars.sh](https://github.com/tosin2013/openshift-4-deployment-notes/blob/master/assisted-installer/example.cluster-vars.sh) to `cluster-vars.sh` and edit it. Multi-NIC examples are `example-mutli-network.cluster-vars.sh` and `example-mutli-network.demo-virt.cluster-vars.sh` in that directory.
5. Run [bootstrap.sh](https://github.com/tosin2013/openshift-4-deployment-notes/blob/master/assisted-installer/bootstrap.sh). It checks the tools, authenticates, creates the cluster, writes nmstate, builds the discovery ISO, and downloads it under `./.generated/`. [bootstrap-create.sh](https://github.com/tosin2013/openshift-4-deployment-notes/blob/master/assisted-installer/bootstrap-create.sh) stops after the ISO.
6. Boot each machine from that ISO.
7. Run [bootstrap-install.sh](https://github.com/tosin2013/openshift-4-deployment-notes/blob/master/assisted-installer/bootstrap-install.sh). In order it sources `authenticate-to-api.sh`, then `steps/check-nodes-ready.sh`, `steps/set-node-hostnames-and-roles.sh`, `steps/set-networking.sh`, `steps/check-cluster-ready-to-install.sh`, and `steps/start-install.sh`.

Day-two host adds are [steps/new-add-new-hosts.sh](https://github.com/tosin2013/openshift-4-deployment-notes/tree/master/assisted-installer/steps). [destroy.sh](https://github.com/tosin2013/openshift-4-deployment-notes/blob/master/assisted-installer/destroy.sh) removes the cluster from the service. A libvirt lab path is documented at the bottom of the [OpenShift 4 Assisted Installer note](https://github.com/tosin2013/openshift-4-deployment-notes/blob/master/assisted-installer/README.md). vSphere upload uses `govc`, also described there.

Product docs: [Installing on-premise with the Assisted Installer](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/installing_on-premise_with_assisted_installer/) (OpenShift Container Platform 5.0). The [installation overview](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/installation_overview/) also describes the Assisted Installer and the Agent-based Installer.

Check the release the API returns on the day you install. The scripts' sample output is from a 4.9 run.
