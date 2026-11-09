# RHCOS 10 and OS image streams

Product docs: [Red Hat Enterprise Linux CoreOS (RHCOS)](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/architecture/architecture-rhcos) (OpenShift Container Platform 5.0 Architecture). The observations below stay the lab record.

## What this lab is running

Every node reports:

```text
Red Hat Enterprise Linux CoreOS 10.2.20261015-0 (Coughlan)
kernel 6.12.0-211.66.1.el10_2.x86_64
```

`OSStreams` is enabled. A worker node has the `avx2` CPU flag, which is the practical check for the x86-64-v3 microarchitecture that RHCOS 10 requires (Intel Haswell / AMD Excavator class or newer).

## What to check on the next cluster

```bash
oc get nodes -o custom-columns=NAME:.metadata.name,OS:.status.nodeInfo.osImage,RUNTIME:.status.nodeInfo.containerRuntimeVersion
oc get featuregate cluster -o jsonpath='{range .status.featureGates[*].enabled[*]}{.name}{"\n"}{end}' | grep OSStreams
```

On a machine that might be too old for RHCOS 10, read the flags before you install:

```bash
grep -m1 flags /proc/cpuinfo | grep -o avx2
```

Public cloud instance types from the last several years usually pass. Bare metal and older virtual machines are the ones to inventory. For a virtual machine, the hypervisor has to present AVX2 into the guest. `host-passthrough` or a Haswell-or-newer CPU model does that. A generic `kvm64` model often does not.

## Pinning RHCOS 9

With `OSStreams` on, a 5.0 node pool resolves to the RHEL 10 stream. An explicit OS image stream pin is how you keep RHEL 9. The exact `spec.osImageStream` field is a HyperShift / NodePool control. Self-managed MachineConfig details for a mixed 9/10 cluster still need a lab pass. Record the object you edited under `releases/` when you do it.

## Placeholder

- [ ] Bare-metal install on a host that fails the AVX2 check, and the RHCOS 9 pin that makes it boot
- [ ] Confirm the 5.0 installer image names (`rhcos-live`, qcow2, VMware template) once GA artifacts are published
- [ ] Compare `oc adm release info` boot image metadata between 4.22 and 5.0
