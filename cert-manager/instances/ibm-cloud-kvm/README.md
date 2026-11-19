# cert-manager: IBM Cloud KVM Instance

Applies cert-manager certificates to an OpenShift 5.0 cluster deployed via the Agent-Based Installer on an IBM Cloud KVM host (using the [openshift-agent-install](https://github.com/tosin2013/openshift-agent-install) tooling).

## Differences from the AWS install

| Item | AWS install | IBM Cloud KVM |
|---|---|---|
| kubeconfig | `~/cluster/auth/kubeconfig` | `~/generated_assets/<cluster>/auth/kubeconfig` |
| DNS | AWS Route53 (auto-provisioned) | AWS Route53 (manually configured via `configure-route53-dns.sh`) |
| Infrastructure | `platform: aws` | `platform: baremetal` |
| Region detection | `oc get infrastructure cluster` | Must be passed explicitly (Route53 zone is in `us-east-1`) |

## Prerequisites

1. Cluster installed and all operators Available
2. cert-manager operator installed (`oc apply -k cert-manager/operator/overlays/stable-v1`)
3. AWS credentials with Route53 write access (same creds used for DNS setup)
4. KUBECONFIG set:
   ```bash
   export KUBECONFIG=~/generated_assets/<cluster-name>/auth/kubeconfig
   ```

## Required DNS Records

The following DNS records must exist in your Route53 hosted zone **before** running the cert script. These are created by `configure-route53-dns.sh` during cluster setup.

```
Type   Name                                        Value
A      api.<cluster>.<domain>                      <ibm-cloud-floating-ip>
A      api-int.<cluster>.<domain>                  <ibm-cloud-floating-ip>
A      *.apps.<cluster>.<domain>                   <ibm-cloud-floating-ip>
```

Verify with:
```bash
dig api.<cluster>.<domain> +short          # must return floating IP
dig test.apps.<cluster>.<domain> +short    # must return floating IP
```

---

## DNS Entries by Cloud Provider

### IBM Cloud KVM (this guide)

Traffic path: `internet → IBM Cloud floating IP → HAProxy on KVM host → cluster VIPs`

```
Provider:  AWS Route53
Zone:      <sandbox>.opentlc.com  (or your domain)
Records:
  api.<cluster>.<domain>        A  <ibm-floating-ip>   e.g. 169.59.190.167
  api-int.<cluster>.<domain>    A  <ibm-floating-ip>
  *.apps.<cluster>.<domain>     A  <ibm-floating-ip>
```

HAProxy on the KVM host forwards ports 6443, 22623, 80, 443 to internal VIPs:
```
169.59.190.167:6443 → 192.168.50.253:6443   (API)
169.59.190.167:443  → 192.168.50.252:443    (Apps HTTPS)
169.59.190.167:80   → 192.168.50.252:80     (Apps HTTP)
```

---

### AWS IPI (platform: aws)

Traffic path: `internet → AWS NLB (auto-provisioned) → cluster`

```
Provider:  AWS Route53 (auto-provisioned by installer)
Zone:      <cluster>.<domain>  (private) + parent public zone
Records:   Auto-created by openshift-install — no manual DNS needed
```

The cert script auto-detects the region and zone from `oc get infrastructure cluster`. Run without zone/region args:
```bash
export KUBECONFIG=~/cluster/auth/kubeconfig
bash post-steps/create_custom_cert.sh \
  <aws-access-key-id> \
  <aws-secret-access-key> \
  <your-email>
```

---

### Google Cloud (platform: gcp)

Traffic path: `internet → GCP Load Balancer → cluster`

```
Provider:  Google Cloud DNS
Zone:      <domain> managed in Cloud DNS
Records:   Auto-provisioned by openshift-install
```

cert-manager uses the **Cloud DNS solver**, not Route53. Create a GCP service account with `roles/dns.admin`, then:

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: gcp-acme
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: <your-email>
    privateKeySecretRef:
      name: gcp-acme-account-key
    solvers:
    - dns01:
        cloudDNS:
          project: <gcp-project-id>
          serviceAccountSecretRef:
            name: gcp-dns-sa
            key: service-account.json
```

```bash
# Create service account secret
oc create secret generic gcp-dns-sa \
  --from-file=service-account.json=<path-to-sa-key>.json \
  -n cert-manager
oc apply -f clusterissuer-gcp.yaml
```

DNS records to verify before running:
```
api.<cluster>.<domain>        A  <gcp-lb-ip>
*.apps.<cluster>.<domain>     A  <gcp-ingress-ip>
```

---

### Azure (platform: azure)

Traffic path: `internet → Azure Load Balancer → cluster`

```
Provider:  Azure DNS
Zone:      <domain> in Azure DNS zone
Records:   Auto-provisioned by openshift-install
```

cert-manager uses the **Azure DNS solver**. Create a service principal with DNS Zone Contributor role, then:

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: azure-acme
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: <your-email>
    privateKeySecretRef:
      name: azure-acme-account-key
    solvers:
    - dns01:
        azureDNS:
          subscriptionID: <azure-subscription-id>
          resourceGroupName: <dns-resource-group>
          hostedZoneName: <domain>
          environment: AzurePublicCloud
          clientID: <service-principal-client-id>
          clientSecretSecretRef:
            name: azure-dns-sp
            key: client-secret
          tenantID: <azure-tenant-id>
```

```bash
oc create secret generic azure-dns-sp \
  --from-literal=client-secret=<sp-client-secret> \
  -n cert-manager
oc apply -f clusterissuer-azure.yaml
```

DNS records to verify before running:
```
api.<cluster>.<domain>        A  <azure-lb-ip>
*.apps.<cluster>.<domain>     A  <azure-ingress-ip>
```

---

## Run the cert script (IBM Cloud KVM)

Use `post-steps/create_custom_cert.sh` with KUBECONFIG and zone/region set explicitly (baremetal platform cannot auto-detect these from `oc get infrastructure`):

```bash
export KUBECONFIG=~/generated_assets/<cluster-name>/auth/kubeconfig

HOSTED_ZONE_ID=<your-route53-zone-id>   # from: aws route53 list-hosted-zones
AWS_REGION=us-east-1

bash post-steps/create_custom_cert.sh \
  <aws-access-key-id> \
  <aws-secret-access-key> \
  <your-email> \
  ${HOSTED_ZONE_ID} \
  ${AWS_REGION}
```

The script will:
1. Create the `aws-secret` in `cert-manager` namespace
2. Create a `route53-acme` ClusterIssuer using DNS01 challenge
3. Issue `*.apps.<cluster>.<domain>` and `api.<cluster>.<domain>` certificates
4. Patch the ingress controller and API server to use them
5. Wait for `kube-apiserver` to finish rolling out

## Verify

```bash
oc get certificate -n openshift-ingress
oc get certificate -n openshift-config
oc get clusterissuer route53-acme
```

Both certificates should show `Ready: True`. The console URL will serve a trusted Let's Encrypt certificate.

## Example values (IBM Cloud KVM, OPENTLC sandbox)

```
Cluster:        cnv-5-0.sandbox2401.opentlc.com
API:            api.cnv-5-0.sandbox2401.opentlc.com
Apps:           *.apps.cnv-5-0.sandbox2401.opentlc.com
Floating IP:    <your-ibm-cloud-floating-ip>
Route53 zone:   sandbox2401.opentlc.com
Region:         us-east-1
KUBECONFIG:     ~/generated_assets/cnv-5-0/auth/kubeconfig

# Get hosted zone ID:
aws route53 list-hosted-zones \
  --query 'HostedZones[?contains(Name, `sandbox2401.opentlc.com`)].Id' \
  --output text
```
