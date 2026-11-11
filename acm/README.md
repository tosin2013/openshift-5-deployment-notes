# Red Hat Advanced Cluster Management

Install ACM on a hub cluster from `redhat-operators`, then create `MultiClusterHub`. Creating that resource installs the multicluster engine operator and a `MultiClusterEngine`. Use namespace `open-cluster-management` when that name is free. If it already exists, pick another namespace and use it in both files.

On 11 November 2026 the `ocp5` `redhat-operators` catalog listed `advanced-cluster-management` with default channel `release-5.0` and CSV `advanced-cluster-management.v5.0.0`. Channel `stable-5.0` listed the same CSV. Channel `release-2.17` listed `advanced-cluster-management.v2.17.4`. The operator was not installed on `ocp5`. The 5.0 page sample still writes the channel as `release-<2.x>`. This catalog's 5.0 channel is `release-5.0`.

The OpenShift 4 notes are ACM 2.4, including an OpenShift 3.11 import. Do not apply those manifests. They stay as reading only:

- [Cluster upgrade policies](https://github.com/tosin2013/openshift-4-deployment-notes/blob/master/acm/cluster-upgrade-policies.md)
- [Custom image endpoints](https://github.com/tosin2013/openshift-4-deployment-notes/blob/master/acm/set-custom-repo-endpoints.md)
- [Import a GKE cluster](https://github.com/tosin2013/openshift-4-deployment-notes/blob/master/acm/configure-gke-with-acm.md)
- [Import a Rancher cluster](https://github.com/tosin2013/openshift-4-deployment-notes/blob/master/acm/configure-rancher-with-acm.md)
- [Infrastructure configuration](https://github.com/tosin2013/openshift-4-deployment-notes/blob/master/acm/configure-infra-acm.md)

A `ServiceAccount` with a `ClusterRoleBinding` gives cluster administrator privileges to ACM and to any user who can access the install namespace. Do not grant that namespace to a user who is not a cluster administrator. The hub reserves one namespace, `<your-local-cluster-name>`, for itself.

1. Point `oc` at the hub. See [Client packages](../pre-steps/README.md).

2. Subscribe to `advanced-cluster-management` from `redhat-operators` on channel `release-5.0`, with automatic approval.

```bash
oc apply -f acm/subscription.yaml
oc get csv -n open-cluster-management
```

[subscription.yaml](subscription.yaml) is the namespace, the operator group, and the subscription. Wait until the CSV phase is `Succeeded` before you create the hub. The console path is Ecosystem → Software Catalog, Advanced Cluster Management for Kubernetes, then channel, namespace, and approval.

3. Create `MultiClusterHub`. If the API returns `no matches for kind "MultiClusterHub"`, the CSV is still installing. Apply the file again after the CRD exists.

```bash
oc apply -f acm/multiclusterhub.yaml
oc get mch -n open-cluster-management
```

[multiclusterhub.yaml](multiclusterhub.yaml) is the default hub. Status `Running` can take 10 minutes. Creating the hub also installs multicluster engine.

Product docs: [Get started with Red Hat Advanced Cluster Management](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/5.0/html/get_started/get-started-acm) (Red Hat Advanced Cluster Management for Kubernetes 5.0).

Check these steps on the build you are installing. Confirm the channel against `oc get packagemanifest advanced-cluster-management -n openshift-marketplace` before you subscribe.
