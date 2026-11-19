# cert-manager: AWS IPI (Route53 DNS01)

Platform: `aws` | DNS: AWS Route53 | Solver: `route53`

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
  <your-email>
```

Region and hosted zone are auto-detected from `oc get infrastructure cluster` and `oc get dns cluster`.
Pass them as optional args 4 and 5 to override.

**2. Apply:**
```bash
oc apply -k cert-manager/instances/aws/
```

**3. Verify:**
```bash
oc get clusterissuer letsencrypt-prod
oc get certificate -n openshift-ingress
oc get certificate -n openshift-config
```

Both certificates must show `Ready: True`. See [post-steps/create_custom_cert.sh](../../post-steps/create_custom_cert.sh) for the full ingress/API server patch sequence.
