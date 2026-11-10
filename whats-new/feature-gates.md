# Feature gates on 5.0.0-rc.7

Product docs: [FeatureGate [config.openshift.io/v1]](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/config_apis/featuregate-config-openshift-io-v1) (OpenShift Container Platform 5.0 Config APIs).

Source: `oc get featuregate cluster` on 20 October 2026. `spec` is empty, so this is the default set for a self-managed HA cluster. Re-check after every upgrade. The engineering changelog from 4.22.2 to 5.0.0-ec.6 does not match this RC on every row.

On 10 November 2026 the same command on `ocp5` (5.0.1) also had an empty `spec`. `BootcNodeManagement`, `ImageModeStatusReporting`, `ClusterAPIInstall` and the `ClusterAPIMachineManagement*` gates, `MachineAPIMigration` and the per-platform migration gates, and `KarpenterOperator` were disabled. `UserNamespacesSupport` was still absent. `OSStreams`, `NewOLM`, `OLMLifecycleAndCompatibility`, and `GatewayAPIWithoutOLM` were enabled. None of the four install gates flipped on, so they stay without an install folder. That cluster is the lab read in [5.0.1](../releases/5.0.1.md).

## Enabled gates worth operating around

- `OSStreams` selects the RHCOS major version for node boot images.
- `NewOLM`, `OLMLifecycleAndCompatibility`, `NewOLMWebhookProviderOpenshiftServiceCA` are the OLM changes that are actually on.
- `GatewayAPIWithoutOLM` ships Gateway API without an OLM subscription.
- `IngressControllerMultipleHAProxyVersions` and `IngressControllerDynamicConfigurationManager` are on for the ingress operator.
- `NoRegistryClusterInstall` and `BootImageSkewEnforcement` affect install and machine-os rollouts.
- `CRIOCredentialProviderConfig` is on. The worker pool includes `97-worker-generated-credentialproviderconfig`.
- `MutatingAdmissionPolicy`, `SigstoreImageVerification`, `SigstoreImageVerificationPKI`, `ServiceAccountTokenNodeBinding`.
- `ExternalOIDC`, `ExternalOIDCWithUIDAndExtraClaimMappings`, `ExternalOIDCWithUpstreamParity`.
- `VolumeGroupSnapshot`, `AdditionalStorageConfig`.
- `AWSClusterHostedDNSInstall`, `AWSDualStackInstall`, `AWSServiceLBNetworkSecurityGroup` for AWS installs.
- `InsightsConfig`, `InsightsOnDemandDataGather`, `UpgradeStatus`, `IrreconcilableMachineConfig`.

## Still disabled

These show up in roadmap talk and are off on this build. Keep the matching folders as placeholders until a gate flips.

- `BootcNodeManagement`, `ImageModeStatusReporting`
- `ClusterAPIInstall` and the `ClusterAPIMachineManagement*` gates
- `MachineAPIMigration` and the per-platform migration gates
- `KarpenterOperator`
- `GatewayAPIManagementMode`, `NetworkObservabilityInstall`
- `OpenShiftPodSecurityAdmission`
- `NewOLMConfigAPI` and the other `NewOLM*` gates listed in [operators-olm.md](operators-olm.md)

`UserNamespacesSupport` is not in either list on this build.

## Refresh

```bash
oc get featuregate cluster -o yaml
```

Or run `../cluster/baseline.sh`, which prints a short allow-list.
