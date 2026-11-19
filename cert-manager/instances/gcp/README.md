# cert-manager: GCP IPI (Cloud DNS DNS01)

Platform: `gcp` | DNS: Google Cloud DNS | Solver: `cloudDNS`

Requires the cert-manager operator to be installed first:
```bash
oc apply -k cert-manager/operator/overlays/stable-v1
```

## Prerequisites

Create a GCP service account with `roles/dns.admin` on the Cloud DNS zone:
```bash
gcloud iam service-accounts create cert-manager-dns \
  --display-name "cert-manager DNS01"

gcloud projects add-iam-policy-binding <project-id> \
  --member "serviceAccount:cert-manager-dns@<project-id>.iam.gserviceaccount.com" \
  --role "roles/dns.admin"

gcloud iam service-accounts keys create sa-key.json \
  --iam-account cert-manager-dns@<project-id>.iam.gserviceaccount.com
```

## Steps

**1. Create secret and generate kustomize patch:**
```bash
chmod +x setup-secrets.sh
./setup-secrets.sh \
  <gcp-project-id> \
  ./sa-key.json \
  <your-email>
```

**2. Apply:**
```bash
oc apply -k cert-manager/instances/gcp/
```

**3. Verify:**
```bash
oc get clusterissuer letsencrypt-prod
oc get certificate -n openshift-ingress
oc get certificate -n openshift-config
```
