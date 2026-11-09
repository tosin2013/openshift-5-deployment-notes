# Kubernetes 1.36 and the container runtime

Product docs: [Working with clusters](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/nodes/working-with-clusters) (OpenShift Container Platform 5.0 Nodes). A search for the container runtime also returned the [RHCOS architecture chapter](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/architecture/architecture-rhcos). The table below stays the lab record.

## Observed

| Piece | This lab |
| --- | --- |
| Kubernetes / kubelet | v1.36.5 |
| cri-o | 1.36.6 |
| Low-level runtime | crun 1.27 (`oc debug node/... -- chroot /host crun --version`) |
| Workstation `oc` | 4.22.18 |

RHCOS 10 nodes on this build use crun. A node still on RHCOS 9 can have both crun and runc. When a must-gather or `oc debug` transcript says `crun`, that is expected on 10.2.

`MutatingAdmissionPolicy` is enabled. Policies of that kind are a Kubernetes 1.32+ feature that is now part of the default gate set here. `VolumeGroupSnapshot` and `SELinuxMountGAReadiness` are enabled as well.

`UserNamespacesSupport` does not appear in the enabled or disabled lists returned by `featuregate/cluster` on 5.0.0-rc.7. An earlier engineering changelog (4.22.2 to 5.0.0-ec.6) marked it unconditionally enabled. Trust the live FeatureGate object for the build you are on.

## Checks

```bash
oc version
oc get nodes -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.status.nodeInfo.kubeletVersion}{" "}{.status.nodeInfo.containerRuntimeVersion}{"\n"}{end}'
oc debug node/$(oc get nodes -l node-role.kubernetes.io/worker -o jsonpath='{.items[0].metadata.name}') -- chroot /host crun --version
```

## Placeholder

- [ ] Diff `oc api-resources` against a 4.22 cluster and list APIs that 5.0 adds or removes
- [ ] Note any workload that pinned `runtimeClass` or expected runc annotation strings
- [ ] Replace the 4.22 client once an `oc` 5.0 tarball is the one documented for the release
