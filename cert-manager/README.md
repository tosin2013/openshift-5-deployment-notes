# cert-manager

Install the cert-manager Operator for Red Hat OpenShift after the cluster API answers. The manifests in this folder are a kustomize base plus a channel overlay. `oc` applies the overlay. A separate kustomize binary is not required.

The 5.0 chapter uses channel `stable-v1`, namespace `cert-manager-operator`, catalog source `redhat-operators` in `openshift-marketplace`, and automatic approval. For operator 1.15 and later it recommends an `AllNamespaces` `OperatorGroup`, which is `targetNamespaces: []` in [operator/base/operator-group.yaml](operator/base/operator-group.yaml). The [gitops-catalog](https://github.com/tosin2013/gitops-catalog/tree/main/openshift-cert-manager-operator) overlay still sets `targetNamespaces` to `cert-manager-operator`. That is the older single-namespace mode. The chapter's second `OperatorGroup` example also nests `spec: {}` under `spec`. That is not an `OperatorGroup` field, so this manifest leaves it out.

On 10 November 2026 the `ocp5` package manifest in `redhat-operators` had default channel `stable-v1`. Both `stable-v1` and `stable-v1.20` listed `cert-manager-operator.v1.20.1`. That listing is this cluster on that date.

1. Point `oc` at the cluster. The kubeconfig from the AWS install stays on the host that ran `create cluster`. See [OpenShift on AWS](../aws/README.md).

2. From the repo root, apply the `stable-v1` overlay. The base subscription channel is a placeholder, so apply an overlay.

```bash
oc apply -k cert-manager/operator/overlays/stable-v1
```

`stable-v1.20` stays on the 1.20 line:

```bash
oc apply -k cert-manager/operator/overlays/stable-v1.20
```

3. Wait until the subscription, the CSV, the operator pod, and the cert-manager pods are up.

```bash
oc get subscription -n cert-manager-operator
oc get csv -n cert-manager-operator
oc get pods -n cert-manager-operator
oc get pods -n cert-manager
```

The CSV phase is `Succeeded`. The operator pod runs in `cert-manager-operator`. The cert-manager, cainjector, and webhook pods run in `cert-manager`.

The AWS example is [create_custom_cert.sh](../post-steps/create_custom_cert.sh). It uses the explicit Route 53 credentials from the 5.0 chapter: `accessKeyID`, `hostedZoneID`, `region`, and secret key `awsSecretAccessKey`.

## ⚠️ CRITICAL: Add Let's Encrypt CA to cluster trust bundle FIRST

**Before rotating any cluster certificate** (API server or ingress), you must add the Let's Encrypt CA chain to the OpenShift cluster's trusted CA bundle. Skipping this step causes:

- `Kubelet stopped posting node status` on all nodes
- kube-apiserver CrashLoopBackOff during cert rotation rollout
- All nodes going NotReady and cascading operator failures

**Why**: When the kube-apiserver operator rolls out the new cert (revisions restart on all control plane nodes), the kubelets and operators must already trust the new cert's CA. The MCO distributes the trust bundle to every RHCOS node — this must complete before the rollout starts.

Reference: [Certificate types — Proxy certificates (trustedCA)](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/security_and_compliance/certificate-types-and-descriptions) — OCP 5.0 Security and Compliance

```bash
# Run this BEFORE setup-secrets.sh or create_custom_cert.sh
chmod +x cert-manager/instances/add-trusted-ca.sh
./cert-manager/instances/add-trusted-ca.sh
# Script downloads the Let's Encrypt intermediate + root from AIA URLs,
# creates letsencrypt-ca ConfigMap, patches proxy/cluster trustedCA,
# then waits for MCO to finish rolling out to all nodes (~5-15 min).
```

Then apply credentials and certificates:

```bash
# Cloud-specific setup (creates credentials secret + DNS01 ClusterIssuer)
./cert-manager/setup-secrets.sh --provider <ibm-cloud-kvm|aws|gcp|azure> <args>

# Apply ClusterIssuer + Certificate resources
oc apply -k cert-manager/instances/<provider>/
```

See [instances/](instances/) for per-cloud provider directories with kustomize-compatible manifests.

## Product docs

- [cert-manager Operator for Red Hat OpenShift](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/security_and_compliance/cert-manager-operator-for-red-hat-openshift) (OCP 5.0 Security and compliance)
- [Certificate types and descriptions — Proxy certificates](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/security_and_compliance/certificate-types-and-descriptions) (trustedCA / MCO distribution)
- [Adding API server certificates](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/security_and_compliance/certificate-types-and-descriptions#add-api-server-certs)

Check these steps on the build you are installing.
