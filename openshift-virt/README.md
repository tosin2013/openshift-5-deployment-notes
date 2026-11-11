# OpenShift Virtualization

Install the OpenShift Virtualization operator from `redhat-operators` into `openshift-cnv`, then create `HyperConverged`. Use this after the cluster API answers, on a platform the 5.0 chapter lists. On AWS the workers have to be bare-metal instance types, for example `c5n.metal`.

On 11 November 2026 the `ocp5` `redhat-operators` catalog listed `kubevirt-hyperconverged` on channel `stable`, CSV `kubevirt-hyperconverged-operator.v5.0.0`. The workers on that cluster are `m6i.xlarge`. This cluster is not the install target, and the operator was not installed. The community package `community-kubevirt-hyperconverged` is a different operator.

The OpenShift 4 note in this area is a Migration Toolkit for Virtualization lab, not this install. It stays at [openshift-virt/README.md](https://github.com/tosin2013/openshift-4-deployment-notes/blob/master/openshift-virt/README.md).

1. Confirm the workers are a supported platform. For an AWS cluster, the installing chapter requires bare-metal instance types. `m6i.xlarge` is not one of them.

2. Subscribe to `kubevirt-hyperconverged` from `redhat-operators` on channel `stable`. The namespace has to be `openshift-cnv`.

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: openshift-cnv
  labels:
    openshift.io/cluster-monitoring: "true"
---
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: kubevirt-hyperconverged-group
  namespace: openshift-cnv
spec:
  targetNamespaces:
    - openshift-cnv
---
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: hco-operatorhub
  namespace: openshift-cnv
spec:
  source: redhat-operators
  sourceNamespace: openshift-marketplace
  name: kubevirt-hyperconverged
  startingCSV: kubevirt-hyperconverged-operator.v5.0.0
  channel: stable
```

```bash
oc apply -f openshift-virt/subscription.yaml
```

That file is [subscription.yaml](subscription.yaml). The console path is Ecosystem → Software Catalog, the Red Hat OpenShift Virtualization Operator tile, channel `stable`, the recommended namespace `openshift-cnv`, and approval `Automatic`.

3. Wait until the CSV phase is `Succeeded`.

```bash
oc get csv -n openshift-cnv
```

4. Create the `HyperConverged` object.

```yaml
apiVersion: hco.kubevirt.io/v1
kind: HyperConverged
metadata:
  name: kubevirt-hyperconverged
  namespace: openshift-cnv
spec: {}
```

```bash
oc apply -f openshift-virt/hyperconverged.yaml
oc get csv -n openshift-cnv
oc get hco -n openshift-cnv kubevirt-hyperconverged
```

That file is [hyperconverged.yaml](hyperconverged.yaml).

The CSV display name is `OpenShift Virtualization`. `HyperConverged` is ready when `Available` is `True` and `Progressing` is `False`.

Product docs: [Installing](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/virtualization/installing) (OpenShift Container Platform 5.0 Virtualization).

Check these steps on the build you are installing. The `startingCSV` above is the 5.0.0 CSV from that chapter and from the 11 November 2026 catalog.
