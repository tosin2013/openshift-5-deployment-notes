# cert-manager: Azure IPI (Azure DNS DNS01)

Platform: `azure` | DNS: Azure DNS | Solver: `azureDNS`

Requires the cert-manager operator to be installed first:
```bash
oc apply -k cert-manager/operator/overlays/stable-v1
```

## Prerequisites

Create a service principal with DNS Zone Contributor on the Azure DNS zone:
```bash
az ad sp create-for-rbac --name cert-manager-dns \
  --role "DNS Zone Contributor" \
  --scope /subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.Network/dnszones/<zone-name>
```
Note the `appId` (clientID), `password` (clientSecret), and `tenant` (tenantID) from the output.

## Steps

**1. Create secret and generate kustomize patch:**
```bash
chmod +x setup-secrets.sh
./setup-secrets.sh \
  <tenant-id> \
  <client-id> \
  <client-secret> \
  <subscription-id> \
  <resource-group> \
  <zone-name> \
  <your-email>
```

**2. Apply:**
```bash
oc apply -k cert-manager/instances/azure/
```

**3. Verify:**
```bash
oc get clusterissuer letsencrypt-prod
oc get certificate -n openshift-ingress
oc get certificate -n openshift-config
```
