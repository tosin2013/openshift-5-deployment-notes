# Agent-based Installer

The Agent-based Installer builds a bootable ISO from `install-config.yaml` and `agent-config.yaml`. One host becomes the rendezvous host and runs the Assisted Service. The other hosts boot the same ISO. Use it when the machines are on a disconnected network or you do not want the hosted Assisted Installer service.

The 5.0 installer subcommand is `openshift-install agent create image`. The field steps for that command are not written here yet. Follow the product chapter, then add the commands you actually ran.

Product docs: [Installing an on-premise cluster with the Agent-based Installer](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/installing_an_on-premise_cluster_with_the_agent-based_installer/) (OpenShift Container Platform 5.0).

Check `openshift-install agent --help` on the build you are installing.
