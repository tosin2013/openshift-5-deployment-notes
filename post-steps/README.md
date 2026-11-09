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

Replace the default ingress certificate, or add an API certificate, from a CA your clients trust. [create_custom_cert.sh](https://github.com/tosin2013/openshift-4-deployment-notes/blob/master/post-steps/create_custom_cert.sh) uses acme.sh and Route 53. It takes an AWS access key, secret key, and email as arguments. Do not commit those. The script was written against OpenShift 4.16. Read it before you run it on 5.0.

Product docs: [Configuring certificates](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/security_and_compliance/configuring-certificates).

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
