# What is different in OpenShift 5

OpenShift 5 keeps the OpenShift 4 operating model: Kubernetes, operators, the Cluster Version Operator, and in-place updates. The version number moved to 5 because the node OS and the admin experience change enough that Red Hat did not want to call it 4.23.

Observed on this lab (`5.0.0-rc.7`) and checked against the 5.0 engineering changelog and the OKD 5 update docs.

| Change | Why it matters | Note |
| --- | --- | --- |
| RHCOS 10.2 is the default node OS, with RHCOS 9 still selectable | New CPU floor (x86-64-v3 / AVX2) and a new container runtime default | [RHCOS 10](rhcos-10.md) |
| Kubernetes 1.36 | API and kubelet move with the platform. This lab's kubelet is v1.36.5. | [Kubernetes and runtime](kubernetes-and-runtime.md) |
| crun is the runtime on RHCOS 10 | Debug and must-gather output will name crun, not runc | [Kubernetes and runtime](kubernetes-and-runtime.md) |
| OS image streams are on by default | Hosted and self-managed node pools resolve RHCOS 9 or 10 from the OpenShift version unless you pin them | [RHCOS 10](rhcos-10.md) |
| New OLM and catalogd are present | `ClusterCatalog` and `ClusterExtension` exist beside the classic `CatalogSource` / `Subscription` path | [Operators and OLM](operators-olm.md) |
| In-place upgrade from 4.22 | Documented as the same shape as a 4.y minor update. This lab was installed fresh, so the upgrade path is not proven here. | [Upgrades from 4](upgrades-from-4.md) |
| AI-assisted operations | Lightspeed and the OpenShift MCP server are the pieces to configure. [Lightspeed 2.0](https://docs.redhat.com/en/documentation/red_hat_openshift_lightspeed/2.0/html/install/ols-installing-lightspeed) documents the operator and says autonomous agents require OpenShift 5.0. The [5.0 MCP server](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/ai_applications/mcp-server) chapter is published. On 28 October 2026 `redhat-operators` for v5.0 listed Lightspeed 2.0.0. A working 5.0.0-rc.7 workshop runs a newer direct install, with the PatternFly 6 console plugin. | [Lightspeed](../ai/lightspeed/README.md), [working cluster](../ai/lightspeed/working-cluster.md), [MCP server](../ai/mcp-server/README.md) |

Still disabled on this build, so leave them as future folders rather than procedures: bootc node management, Cluster API install, Machine API migration, and the Karpenter operator. The live list is in [feature gates](feature-gates.md).

Product framing from Red Hat's intent-to-release note: OpenShift 5 builds on OpenShift 4, adds an AI-assisted onboarding and operations experience, and supports both RHCOS 9 and RHCOS 10. GA is planned around the end of 2026 or the start of 2027. OKD 5.0.0-okd-scos builds were already publishing in October 2026.
