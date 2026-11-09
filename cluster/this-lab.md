# Lab cluster snapshot

Captured 20 October 2026 from the cluster this workstation is logged into. Re-run [baseline.sh](baseline.sh) before trusting a number below on a later build.

| Item | Value |
| --- | --- |
| Version | 5.0.0-rc.7 |
| Channel | stable-5.0 |
| Kubernetes | v1.36.5 |
| History | Installed as 5.0.0-rc.7. No 4.x upgrade on this cluster. |
| Platform | AWS, highly available |
| API | https://api.ocp.2mrdz.sandbox1108.opentlc.com:6443 |
| Apps domain | apps.ocp.2mrdz.sandbox1108.opentlc.com |
| Console | https://console-openshift-console.apps.ocp.2mrdz.sandbox1108.opentlc.com |
| Nodes | 3 control-plane nodes that also schedule workloads, plus 3 workers. All Ready. |
| Node OS | Red Hat Enterprise Linux CoreOS 10.2.20261015-0 (Coughlan) |
| Kernel | 6.12.0-211.66.1.el10_2.x86_64 |
| Runtime | cri-o 1.36.6, crun 1.27 |
| CPU | AVX2 is present, so the x86-64-v3 requirement for RHCOS 10 is met |
| MachineConfigPools | master and worker, both updated, 3/3 |
| Default storage | gp3-csi (`ebs.csi.aws.com`). gp2-csi also exists. |
| Identity | OpenID provider named `rhbk` (Red Hat build of Keycloak). HTPasswd is not configured. |
| ClusterOperators | 34, all Available |
| Extra operators | cert-manager-operator v1.20.1, rhbk-operator v26.6.4-opr.1 |
| catalogd | Running in `openshift-catalogd` |
| Lightspeed | Installed 21 October 2026. CSV `lightspeed-operator.v1.1.1` `Succeeded` in `openshift-lightspeed`. Source is a copy of `quay.io/rhpds/olm_snapshot_redhat_catalog:v4.22_2026_08_03` named `rhbk-operator-catalogsource` in `openshift-marketplace`. The three v5.0 indexes still omit the package. The original catalog in namespace `keycloak` is not visible outside that namespace. |
| MCP server | Not installed. Chart `redhat-openshift-mcp-server` 0.3.0 is in https://charts.openshift.io/ |
| Sample app | Namespace `troubleshoot-lab`, route `hello-troubleshoot-lab.apps.ocp.2mrdz.sandbox1108.opentlc.com`, HTTP body `hello from troubleshoot-lab` |

Do not copy kubeconfig, pull secrets, or the OpenID client secret into this repo.
