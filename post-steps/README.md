# Day-two operations

Do these after the cluster API answers. Read what is already configured before you replace it.

## Identity providers

Steps are in [identity-providers.md](identity-providers.md). HTPasswd is the file-backed provider. An OpenID provider, when you add one, is another entry on the same `OAuth` object.

Product docs: [Understanding identity provider configuration](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/authentication_and_authorization/understanding-identity-provider).

## Internal registry on OpenShift Data Foundation

Point the internal registry at a NooBaa bucket after OpenShift Data Foundation is installed. Confirm the ODF channel supports your OpenShift 5 release before you install the operator.

```yaml
apiVersion: objectbucket.io/v1alpha1
kind: ObjectBucketClaim
metadata:
  name: noobaa-registry
  namespace: openshift-image-registry
spec:
  storageClassName: openshift-storage.noobaa.io
  bucketName: noobaa-registry-bucket
```

Wait until `oc get -n openshift-image-registry objectbucketclaim/noobaa-registry` is bound, then set the registry to use that claim. The longer 4.x note is [configure-registry-odf.md](https://github.com/tosin2013/openshift-4-deployment-notes/blob/master/post-steps/configure-registry-odf.md).

To expose the registry without ODF, patch `configs.imageregistry.operator.openshift.io/cluster` so `defaultRoute` is true.

Product docs: [Exposing the registry](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/registry/securing-exposing-registry).

## Certificates

Install the cert-manager operator with the kustomize overlay in [cert-manager](../cert-manager/README.md).

[create_custom_cert.sh](create_custom_cert.sh) is the AWS example. It creates a Route 53 `ClusterIssuer` with explicit credentials, then requests a certificate for `*.apps.<cluster>.<base>` and for the external API name. Pass the access key, the secret key, and the email. Do not commit those. The secret stays in the `cert-manager` namespace. The 5.0 sample directory is Let's Encrypt staging. This script uses the production directory unless `ACME_SERVER` is set. acme.sh is the older note's tool.

```bash
./create_custom_cert.sh aws_access_key_id aws_secret_access_key email
```

The script runs `oc whoami` before it changes the cluster. When `KUBECONFIG` is unset and `~/.kube/config` is absent, it uses `$HOME/cluster/auth/kubeconfig` from the AWS install.

The script patches `certmanager/cluster` with `--dns01-recursive-nameservers-only` and `--dns01-recursive-nameservers=1.1.1.1:53` because an AWS installer-provisioned cluster also has a private zone for the cluster domain. It then stores the last certificate in the issued chain as `custom-ca` and sets `proxy/cluster` `trustedCA`. That trusted CA update restarts kubelet and CRI-O on each node. The ingress controller secret is `router-certs`. The API secret is `api-cert`, and the named certificate is the external API host.

Product docs: [Configure an ACME issuer by using explicit credentials for AWS Route53](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/security_and_compliance/cert-manager-operator-for-red-hat-openshift) (OpenShift Container Platform 5.0). The ingress and API patches are in [Configuring certificates](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/security_and_compliance/configuring-certificates).

Check these steps on the build you are installing.

## Chrony

A MachineConfig that writes `/etc/chrony.conf` rolls the pool. The OpenShift 4 note set Butane's `version` to `4.10.0`. Use the newest `openshift` variant version that `butane` accepts for your release.

```yaml
variant: openshift
version: 4.19.0
metadata:
  name: 99-worker-chrony
  labels:
    machineconfiguration.openshift.io/role: worker
storage:
  files:
    - path: /etc/chrony.conf
      mode: 0644
      overwrite: true
      contents:
        inline: |
          pool 0.rhel.pool.ntp.org iburst
          driftfile /var/lib/chrony/drift
          makestep 1.0 3
          rtcsync
          logdir /var/log/chrony
```

Render with `butane` and `oc apply` the result. Repeat with role `master` for the control plane. Watch the nodes until the pool is updated.

Product docs: [Configuring MCO-related custom resources](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/machine_configuration/machine-configs-custom).

Check the Butane version on the build you are installing. A bad chrony drop-in rolls the node pool.

## Cluster resource override

Install the Cluster Resource Override Operator, then apply one `ClusterResourceOverride` named `cluster`:

```yaml
apiVersion: operator.autoscaling.openshift.io/v1
kind: ClusterResourceOverride
metadata:
  name: cluster
spec:
  podResourceOverride:
    spec:
      memoryRequestToLimitPercent: 50
      cpuRequestToLimitPercent: 25
      limitCPUToMemoryPercent: 200
```

The install script from the OpenShift 4 notes is [configure-cluster-override.sh](https://github.com/tosin2013/openshift-4-deployment-notes/blob/master/post-steps/configure-cluster-override.sh).

Product docs: [Postinstallation configuration overview](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/postinstallation_configuration/post-install-configuration-overview).

## NFS

Prefer a CSI driver for the platform. The older NFS provisioner role is [tosin2013/nfs-provisioner-role](https://github.com/tosin2013/nfs-provisioner-role).

## Quay

Install `quay-operator` from the `stable-3.18` channel and create a `QuayRegistry`. Do not follow [the OpenShift 4.2 Quay note](https://github.com/tosin2013/openshift-4-deployment-notes/blob/master/post-steps/deploy-red-hat-quay-3-on-openshift-4.2.md).

Product docs: [Deploying the Red Hat Quay Operator](https://docs.redhat.com/en/documentation/red_hat_quay/3.18/html/deploying_the_red_hat_quay_operator_on_openshift_container_platform/) (Quay 3.18).

## GitOps

Subscribe to `openshift-gitops-operator` from `redhat-operators` on the `latest` channel. The operator creates an Argo CD instance in `openshift-gitops`. When an Application has auto-sync and self-heal, an edit to a managed object comes back. Pause auto-sync on that Application before a change you need to keep.

Product docs: [Installing Red Hat OpenShift GitOps](https://docs.redhat.com/en/documentation/red_hat_openshift_gitops/1.22/html/installing_gitops/installing-openshift-gitops) (GitOps 1.22).

## Ansible Tower

Left as a legacy note: [configure-ansible-tower.md](https://github.com/tosin2013/openshift-4-deployment-notes/blob/master/post-steps/configure-ansible-tower.md). Do not treat it as the current install.

## Virtualization

See [OpenShift Virtualization](../openshift-virt/README.md).

Product docs: [OpenShift Container Platform 5.0 Virtualization release notes](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/virtualization/release-notes).
