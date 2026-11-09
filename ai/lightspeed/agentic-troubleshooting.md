# Agentic troubleshooting

Recorded 28 October 2026 on `cluster-84wvf` (`5.0.0-rc.7`). The demo applications and the showroom walkthrough come from [module-01-agentic-troubleshooting](https://showroom-showroom-84wvf-1.apps.cluster-84wvf.dyn.redhatworkshops.io/?t=Terminal&p=module-01-agentic-troubleshooting). This page is the cluster state and the switch that turns alert-driven runs on. The provider, the operator, and the MCP server are in [working-cluster.md](working-cluster.md).

Product docs: [Installing OpenShift Lightspeed 2.0](https://docs.redhat.com/en/documentation/red_hat_openshift_lightspeed/2.0/html/install/ols-installing-lightspeed). That guide says the 2.0 operator bundles the assistant and the autonomous agents, and that autonomous agents require OpenShift Container Platform 5.0. The observations below stay the 28 October record.

## Two ways in

You start an investigation from the Lightspeed chat. The button is the lower-right icon. Pick troubleshooting mode. The chat uses the MCP server already set on `OLSConfig` `cluster`, so questions about pods, events, and logs run as the user who is logged into the console. A tool such as `pod_exec` can stop and ask you to approve it. A failed exec is still useful: many OpenShift images have no shell tools, and the run continues from logs, events, and metrics.

An alert starts an investigation when the alerts adapter is allowed to see it. `alerts-adapter-config` in `openshift-lightspeed` polls Alertmanager. A matching alert becomes an `AgenticRun` in that namespace. The run moves through Analysis, Execution, and Verification. `ApprovalPolicy` `cluster` sets which of those stages proceed on their own. Agents `default` and `smart` both call `claude-sonnet-4-6` through `LLMProvider` `openai`.

## What was on the cluster

`ApprovalPolicy` `cluster` was still the install default:

```yaml
spec:
  maxConcurrentRuns: 5
  stages:
    - name: Analysis
      approval: Manual
    - name: Execution
      approval: Manual
    - name: Verification
      approval: Automatic
```

The adapter was polling, and it was not opening runs from alerts. In `alerts-adapter-config`, `pollInterval` is `30s` and `postRunDelay` is `1h`. `allowedReceivers` has the critical receiver commented out:

```yaml
filtering:
  allowedReceivers:
  #  - critical
```

Analysis is pinned to the skill image `quay.io/openshiftanalytics/agentic-skills:latest`, path `/skills/cluster-troubleshoot/investigate-alert`. Until `critical` is uncommented, that skill is not applied to firing alerts.

The workshop namespaces `payments`, `catalog-service`, `inventory`, `user-imports`, and `service-mesh` were already present. They are the pre-seeded applications for this demo. Look at them with `oc get pods` and at Observe → Alerting with the platform filter cleared. The two `AgenticRun` objects that existed were update runs, `ota-5-0-0-rc-7-to-5-0-1` and `ota-5-0-0-rc-7-to-5-1-0`, not runs for those applications.

`oc agentic` is not installed on this workstation. List and inspect runs with the API:

```bash
oc get agenticrun -n openshift-lightspeed
oc describe agenticrun -n openshift-lightspeed <name>
```

## Turn alert-driven runs on

Leave Execution on Manual so a person still authorizes the change. Set Analysis to Automatic so a critical alert is investigated without a separate approval. Verification stays Automatic.

```bash
oc patch approvalpolicy cluster --type merge \
  -p '{"spec":{"stages":[{"name":"Analysis","approval":"Automatic"},{"name":"Execution","approval":"Manual"},{"name":"Verification","approval":"Automatic"}]}}'
```

Uncomment the critical receiver in the adapter ConfigMap and apply it:

```bash
oc get configmap alerts-adapter-config -n openshift-lightspeed -o json \
  | jq '.data["config.yaml"] |= gsub("# +- critical"; "    - critical")' \
  | oc apply -f -
```

A still-firing critical alert gets an `AgenticRun` on a later poll (`pollInterval` is 30s). After a run reaches a terminal state, `postRunDelay` holds the next run for the same alert for an hour. Deleting that run lets the adapter create another one once the delay has passed.

```bash
oc get agenticrun -n openshift-lightspeed
oc delete agenticrun -n openshift-lightspeed <name>
```

The console lists the same objects under Agentic Runs. Open a run in the Proposed phase to read the steps. Execution stays Manual, so the change does not apply until you authorize it there.

## Charts

Troubleshooting mode can draw a Perses chart in the chat from a metrics question. Observe → Dashboards (Perses) is where that chart is saved. Add the chart to a dashboard in the namespace you care about, and the panel keeps updating after the chat is closed.
