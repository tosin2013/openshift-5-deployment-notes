# cert-manager: IBM Cloud KVM (Route53 DNS01)

Platform: `baremetal` | DNS: AWS Route53 | Solver: `route53`

Requires the cert-manager operator to be installed first:
```bash
oc apply -k cert-manager/operator/overlays/stable-v1
```

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
