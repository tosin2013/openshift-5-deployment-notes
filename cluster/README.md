# Cluster checks

Run this from a shell that already has `oc` pointed at the cluster (`~/.kube/config` or `KUBECONFIG`).

```bash
./baseline.sh
```

The script only reads cluster state. It prints versions, node OS, identity-provider names, installed operators, and whether a short list of feature gates is enabled.

## Client skew

On 20 October 2026 the workstation client was `oc` 4.22.18 and the server was 5.0.0-rc.7 / Kubernetes 1.36.5. Reads and applies used in these notes worked with that client. When the OpenShift 5 client is published, switch to it before relying on new `oc adm` flags.

## Console

```bash
oc get route console -n openshift-console -o jsonpath='https://{.spec.host}{"\n"}'
```

Current lab facts are in [this-lab.md](this-lab.md).
