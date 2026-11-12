# OpenShift on AWS

Use a bastion in the same AWS account. From this directory, run the scripts in this repo. RHEL 9 or newer.

1. Create the bastion.
2. Install AWS CLI v2 and write the default profile with [configure-aws-cli.sh](configure-aws-cli.sh).

```bash
./configure-aws-cli.sh -h
./configure-aws-cli.sh -i aws_access_key_id aws_secret_access_key aws_region
```

`-i` writes the access key and secret to `~/.aws/credentials` and the region to `~/.aws/config`, then runs `aws sts get-caller-identity`. It does not print those files. Do not commit them. The same three values are in your shell history. The OpenShift 4 copy of this script unpacks `./aws/install` in the current directory, stores the region in the credentials file, and prints that file. Use this copy.

3. Install `oc`, `kubectl`, and `openshift-install` with [configure-openshift-packages.sh](../pre-steps/configure-openshift-packages.sh). With no `VERSION`, `-i` selects the newest numbered 5.x directory. `--ccoctl` and `--opm` are optional. See [Client packages](../pre-steps/README.md).

```bash
../pre-steps/configure-openshift-packages.sh -i
```

The OpenShift 4 copy of that package script is in the [OpenShift 4 notes](https://github.com/tosin2013/openshift-4-deployment-notes). Use the script in this repo.

4. Create the cluster with [configure-openshift-installer.sh](configure-openshift-installer.sh). It creates an `ed25519` key at `~/.ssh/cluster-key`. For FIPS, create an `rsa` or `ecdsa` key instead. Do not commit the pull secret.

```bash
./configure-openshift-installer.sh
```

`create cluster` reads `$HOME/cluster/install-config.yaml`. When that file is already there, the script copies it to `$HOME/cluster-install-config.yaml` and runs `create cluster`. The copy is the backup, because the installer consumes the original. The mode of the backup does not change the install. When the file is missing, the script runs `create install-config` and stops. Edit the file, including the pull secret from [console.redhat.com](https://console.redhat.com/openshift/install/pull-secret), then run the script again. The OpenShift 4 copy of this helper is in the [OpenShift 4 notes](https://github.com/tosin2013/openshift-4-deployment-notes). It curled a tmux config, ran `chmod 400 ~/.ssh/cluster-key .pub`, and sent you to `cloud.openshift.com`. Use this copy.

`oc` on OpenShift 5 includes kustomize. Install Helm only when you need it outside the cluster:

```bash
../pre-steps/configure-other-clients.sh -i --helm
```

## Options that are generally available in 5.0

The 10 November 2026 cluster used the installer's Route 53 zone. The [5.0 release notes](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/release_notes/ocp-5-0-release-notes) add three AWS options. This cluster was not rebuilt to try them.

- User-managed DNS is generally available. It was Technology Preview in 4.21. You provision the cluster, then publish `api.<cluster_name>.<base_domain>` and `*.apps.<cluster_name>.<base_domain>` yourself. See [Enabling a user-managed DNS](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html-single/installing_on_aws/#installation-aws-enabling-user-managed-DNS_installing-aws-vpc) and [Provisioning your own DNS records](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html-single/installing_on_aws/#installation-aws-provisioning-own-dns-records_installing-aws-vpc).
- Dual-stack networking on AWS is generally available. It was Technology Preview in 4.22. See [Installation configuration parameters for AWS](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html-single/installing_on_aws/#installation-config-parameters-aws).
- When the interactive installer generates `install-config.yaml`, the bastion needs outbound access to `ec2.us-east-1.amazonaws.com:443` so the installer can list regions. See [Configuring your firewall](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html-single/installation_configuration/#configuring-firewall-module_configuring-firewall). The 10 November install wrote `install-config.yaml` before `create cluster`.

Product docs: [Installation methods](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/installing_on_aws/installing-methods-aws) (OpenShift Container Platform 5.0 Installing on AWS). Download, the SSH key, the pull secret, and `create cluster` are in [Installer-provisioned infrastructure](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/installing_on_aws/installer-provisioned-infrastructure).

Check these steps on the build you are installing. `stable-5.0` returned 404 earlier on 9 November 2026. A later listing that day served the `5.0.1` client names.
