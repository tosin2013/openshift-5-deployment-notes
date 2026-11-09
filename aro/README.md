# Azure Red Hat OpenShift

ARO is a managed service on Azure. The full command list is [the OpenShift 4 ARO note](https://github.com/tosin2013/openshift-4-deployment-notes/blob/master/aro/README.md). The shape is below. A search for an ARO install book did not return one. The newest page in that search that is about ARO is [Deploying OpenShift Data Foundation on Azure Red Hat OpenShift](https://docs.redhat.com/en/documentation/red_hat_openshift_data_foundation/4.22/html/deploying_openshift_data_foundation_using_microsoft_azure/deploying-openshift-container-storage-on-azure-red-hat-openshift_aro) (OpenShift Data Foundation 4.22).

1. `az login` and select the subscription. Register the resource providers the 4 note lists (`Microsoft.RedHatOpenShift`, the network and compute providers, and the rest of that list).
2. Raise the regional quota if the subscription cannot hold the control-plane and worker VMs.
3. Save a pull secret from [console.redhat.com](https://console.redhat.com/openshift/install) as `rh-pull-secret.json`. Do not commit it.
4. Create a resource group for ARO and a resource group for the VNet. The infrastructure resource group is named in `az aro create` and created for you.
5. Create a VNet and two subnets, one for the control plane and one for workers. Disable private-link service network policies on both subnets.
6. Create the cluster. Public:

```bash
az aro create \
  --name "$ARO_CLUSTER_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --cluster-resource-group "$INFRASTRUCTURE_RESOURCE_GROUP" \
  --vnet-resource-group "$VNET_RESOURCE_GROUP" \
  --vnet "$VNET_NAME" \
  --master-subnet "$VNET_CONTROL_PLANE_SUBNET_NAME" \
  --worker-subnet "$VNET_APP_NODE_SUBNET_NAME" \
  --apiserver-visibility Public \
  --ingress-visibility Public \
  --pull-secret @rh-pull-secret.json
```

For a private API and ingress, set both visibility flags to `Private` and reach the VNet through a VPN or ExpressRoute. `az aro show` prints the console URL and the kubeadmin credentials. Do not commit that output.

Delete with `az aro delete` and then the resource groups you created.

Check `az aro create --help` on the day you install. The OpenShift version ARO offers is chosen by the service, not by the self-managed 5.0 installer.
