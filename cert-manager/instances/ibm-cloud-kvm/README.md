# cert-manager: IBM Cloud KVM (Route53 DNS01)

Platform: `baremetal` | DNS: AWS Route53 | Solver: `route53`

Requires the cert-manager operator to be installed first:
```bash
oc apply -k cert-manager/operator/overlays/stable-v1
```

## ⚠️ Step 0 (MANDATORY): Add Let's Encrypt CA to cluster trust bundle

Run this **before** any other step. Skipping it causes all nodes to go NotReady
when the kube-apiserver rolls out the new cert.

```bash
chmod +x cert-manager/instances/add-trusted-ca.sh
./cert-manager/instances/add-trusted-ca.sh
```

This distributes the Let's Encrypt CA chain to every RHCOS node via the MCO.
Without it, kubelets cannot verify the new API server cert → nodes go NotReady.

**Reference**: [OCP 5.0 — Proxy certificates (trustedCA)](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/security_and_compliance/certificate-types-and-descriptions)
> *"The trustedCA bundle is merged with the RHCOS trust bundle and injected into the truststore of platform components."*

---

## Steps

**1. Create secret and generate kustomize patch:**
```bash
chmod +x setup-secrets.sh
./setup-secrets.sh \
  <aws-access-key-id> \
  <aws-secret-access-key> \
  <your-email> \
  <route53-hosted-zone-id> \
  us-east-1
```

Zone/region must be passed explicitly — baremetal platform cannot auto-detect them from `oc get infrastructure`.

Get the hosted zone ID:
```bash
aws route53 list-hosted-zones \
  --query 'HostedZones[?contains(Name, `<your-domain>`)].Id' --output text
```

**2. Apply:**
```bash
oc apply -k cert-manager/instances/ibm-cloud-kvm/
```

**3. Verify:**
```bash
oc get clusterissuer letsencrypt-prod
oc get certificate -n openshift-ingress
oc get certificate -n openshift-config
```

Both certificates must show `Ready: True` before patching the ingress controller and API server. See [post-steps/create_custom_cert.sh](../../post-steps/create_custom_cert.sh) for the full patch sequence.
