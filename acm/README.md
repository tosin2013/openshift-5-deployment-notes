# Red Hat Advanced Cluster Management

Install ACM on a hub cluster from `redhat-operators`, then create `MultiClusterHub`. Creating that resource installs the multicluster engine operator and a `MultiClusterEngine`. Use namespace `open-cluster-management` when that name is free. If it already exists, pick another namespace and use it in both files.

On 11 November 2026 the `ocp5` `redhat-operators` catalog listed `advanced-cluster-management` with default channel `release-5.0` and CSV `advanced-cluster-management.v5.0.0`. Channel `stable-5.0` listed the same CSV. Channel `release-2.17` listed `advanced-cluster-management.v2.17.4`. The operator was not installed on `ocp5`. On 12 November 2026 that catalog read was the same before the install: default `release-5.0`, both `release-5.0` and `stable-5.0` at `advanced-cluster-management.v5.0.0`, and no `open-cluster-management` namespace. Later that day the `stable-5.0` overlay was applied on `ocp5`. CSV `advanced-cluster-management.v5.0.0` reached `Succeeded`, and `MultiClusterHub` `multiclusterhub` reached `Running`. `MultiClusterEngine` `multiclusterengine` reached `Available`. The [5.0 release notes](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/5.0/html/release_notes/acm-release-notes), last modified 9 November 2026, say `stable-5.0` is the new install channel and `release-5.0` remains for compatibility. The get-started CLI sample still writes `channel: release-<2.x>` and subscription name `acm-operator-subscription`. This procedure uses `stable-5.0`.

The OpenShift 4 notes are ACM 2.4, including an OpenShift 3.11 import. Do not apply those manifests. They stay as reading only:

- [Cluster upgrade policies](https://github.com/tosin2013/openshift-4-deployment-notes/blob/master/acm/cluster-upgrade-policies.md)
- [Custom image endpoints](https://github.com/tosin2013/openshift-4-deployment-notes/blob/master/acm/set-custom-repo-endpoints.md)
- [Import a GKE cluster](https://github.com/tosin2013/openshift-4-deployment-notes/blob/master/acm/configure-gke-with-acm.md)
- [Import a Rancher cluster](https://github.com/tosin2013/openshift-4-deployment-notes/blob/master/acm/configure-rancher-with-acm.md)
- [Infrastructure configuration](https://github.com/tosin2013/openshift-4-deployment-notes/blob/master/acm/configure-infra-acm.md)

A `ServiceAccount` with a `ClusterRoleBinding` gives cluster administrator privileges to ACM and to any user who can access the install namespace. Do not grant that namespace to a user who is not a cluster administrator. The hub reserves one namespace, `<your-local-cluster-name>`, for itself.

1. Point `oc` at the hub. See [Client packages](../pre-steps/README.md).

2. Subscribe from the local [gitops-catalog](https://github.com/tosin2013/gitops-catalog) checkout, channel `stable-5.0`, source `redhat-operators`, approval automatic. `release-5.0` is the other overlay and selects the same CSV on this cluster.

```bash
oc apply -k /path/to/gitops-catalog/advanced-cluster-management/operator/overlays/stable-5.0
oc get csv -n open-cluster-management
```

[subscription.yaml](subscription.yaml) is the same namespace, operator group, and subscription. The operator group name is `advanced-cluster-management`. The subscription name is `advanced-cluster-management`. Wait until the CSV phase is `Succeeded` before you create the hub. The console path is Ecosystem → Software Catalog, Advanced Cluster Management for Kubernetes, then channel, namespace, and approval.

3. Create `MultiClusterHub`. If the API returns `no matches for kind "MultiClusterHub"`, the CSV is still installing. Apply again after the CRD exists.

```bash
oc apply -k /path/to/gitops-catalog/advanced-cluster-management/instance/base
oc get mch -n open-cluster-management
```

That apply creates the hub, creates [multiclusterengine.yaml](multiclusterengine.yaml) (`MultiClusterEngine` `multiclusterengine`, `spec: {}`), and binds `open-cluster-management:subscription-admin` to `kube:admin` and `system:admin`. If the API returns `no matches for kind "MultiClusterEngine"`, the engine operator is still installing. Apply the instance again after that CRD exists. [multiclusterhub.yaml](multiclusterhub.yaml) is the same hub, name `multiclusterhub`, with `spec.localClusterName: local-cluster` and `spec.networkPolicies.enabled: true`. The get-started sample is `spec: {}`. On this build the operator then writes `localClusterName: local-cluster`, and the validating webhook treats that write as a rename and lists `ManagedCluster` before the multicluster engine has created that kind. Set the name on create. Status `Running` can take 10 minutes. Creating the hub also installs multicluster engine.

Product docs: [Get started with Red Hat Advanced Cluster Management](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/5.0/html/get_started/get-started-acm) (Red Hat Advanced Cluster Management for Kubernetes 5.0).

Check these steps on the build you are installing. Confirm the channel against `oc get packagemanifest advanced-cluster-management -n openshift-marketplace` before you subscribe.
