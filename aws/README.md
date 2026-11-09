# OpenShift on AWS

Use a bastion in the same AWS account to install the CLI, the OpenShift client, and the installer, then create the cluster.

1. Create the bastion.
2. Install the AWS CLI with [configure-aws-cli.sh](https://github.com/tosin2013/openshift-4-deployment-notes/blob/master/aws/configure-aws-cli.sh). Pass the access key, secret key, and region as arguments. Do not commit them.

```bash
curl -OL https://raw.githubusercontent.com/tosin2013/openshift-4-deployment-notes/master/aws/configure-aws-cli.sh
chmod +x configure-aws-cli.sh
./configure-aws-cli.sh -h
./configure-aws-cli.sh -i AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_REGION
```

3. On RHEL 9 or newer, install the client and the installer with [configure-openshift-packages.sh](../pre-steps/configure-openshift-packages.sh). With no `VERSION`, `-i` selects the newest numbered 5.x directory. `--ccoctl` and `--opm` are optional. See [Client packages](../pre-steps/README.md).

```bash
../pre-steps/configure-openshift-packages.sh -i
```

The package script in the OpenShift 4 notes still defaults to `stable-4.15`. The directory named `latest` is not the 5.0 client.
4. The script above downloads `openshift-install`. To fetch one release by hand, set `VERSION` to that numbered directory. See [Installer binary](../configure-installers/README.md).

The OpenShift 4 [configure-installers script](https://github.com/tosin2013/openshift-4-deployment-notes/blob/master/configure-installers/configure-openshift-installer.sh) is still `VERSION="4.2."` and reads `openshift-v4`. The [aws helper](https://raw.githubusercontent.com/tosin2013/openshift-4-deployment-notes/master/aws/configure-openshift-installer.sh) does not download a binary. It assumes `openshift-install` is already on the path, sends you to `cloud.openshift.com`, and runs `chmod 400 ~/.ssh/cluster-key .pub`. A `github.com/.../blob/...` URL saves the HTML page. On 9 November 2026 that HTML download was replaced with the raw helper; leave that helper out of this repo.

On 9 November 2026 [openshift-v5/clients/ocp/](https://mirror.openshift.com/pub/openshift-v5/clients/ocp/) listed `5.0.0/` and `5.0.1/`. Each directory contained `openshift-install-linux-<version>.tar.gz` and `openshift-install-linux.tar.gz`. `candidate-5.0/` served the `5.0.0-rc.7` filenames. `stable-5.0/` returned 404. The 5.0 AWS chapter still links [openshift-v4/clients/ocp/](https://mirror.openshift.com/pub/openshift-v4/clients/ocp/). These notes use `openshift-v5`.

```bash
VERSION=5.0.1
curl -fL -o openshift-install-linux.tar.gz \
  "https://mirror.openshift.com/pub/openshift-v5/clients/ocp/${VERSION}/openshift-install-linux.tar.gz"
tar -xvf openshift-install-linux.tar.gz
./openshift-install version
```

Change `VERSION` before you curl. `5.0.1` is a directory on the mirror. A search of the [5.0 release notes](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/release_notes/ocp-5-0-release-notes) did not return a 5.0.1 section. The client tarball in that same directory is `openshift-client-linux.tar.gz`.

5. Save the pull secret from [console.redhat.com](https://console.redhat.com/openshift/install/pull-secret). Do not commit it.
6. Create the install key. The 5.0 preparing steps use `ed25519`. Use `rsa` or `ecdsa` when the cluster is in FIPS mode.

```bash
ssh-keygen -t ed25519 -N '' -f ~/.ssh/cluster-key
chmod 400 ~/.ssh/cluster-key
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/cluster-key
```

7. Write `install-config.yaml` into an empty directory, then create the cluster. Back up `install-config.yaml` first if you want to keep it. The installer consumes that file. `debug` is one of the log levels named in the chapter.

```bash
./openshift-install create install-config --dir "$HOME/cluster"
cp "$HOME/cluster/install-config.yaml" "$HOME/cluster-install-config.yaml"
./openshift-install create cluster --dir "$HOME/cluster" --log-level=debug
```

At the prompts, select `aws`, the region, and the Route 53 base domain, and paste the pull secret. Keep the AWS keys in the environment or in `~/.aws/credentials`.

`oc` on OpenShift 5 includes kustomize. Install Helm only when you need it outside the cluster:

```bash
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
```

Product docs: [Installation methods](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/installing_on_aws/installing-methods-aws) (OpenShift Container Platform 5.0 Installing on AWS). Download, the SSH key, the pull secret, and `create cluster` are in [Installer-provisioned infrastructure](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/installing_on_aws/installer-provisioned-infrastructure).

Check these steps on the build you are installing. `stable-5.0` was missing from the mirror on 9 November 2026. The AWS CLI script is the one linked above.
