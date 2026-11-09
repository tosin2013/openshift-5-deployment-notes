# Sample application for troubleshooting

A small httpd application in the `troubleshoot-lab` namespace. The healthy set is what should be on the cluster. The files under `faults/` each break one thing so you can practice `oc` describe, events, and logs, or hand the namespace to Lightspeed or the MCP server.

Image: `registry.access.redhat.com/ubi9/httpd-24`, port 8080, which is the OpenShift-friendly port for that image. An empty `/var/www/html` on that image answers `/` with HTTP 403, so the healthy Deployment mounts a one-line `index.html` from a ConfigMap. A 403 on the readiness probe means that mount is missing.

## Deploy the healthy app

From the repo root:

```bash
oc apply -k ai/sample-app/base
oc wait -n troubleshoot-lab --for=condition=Available deploy/hello --timeout=180s
oc get route hello -n troubleshoot-lab -o jsonpath='https://{.spec.host}{"\n"}'
curl -kfsS "https://$(oc get route hello -n troubleshoot-lab -o jsonpath='{.spec.host}')/"
```

## Break it, then put it back

Apply one fault, look at the symptom, then re-apply the base kustomization. That restores the Deployment and Service.

```bash
oc apply -f ai/sample-app/faults/bad-image.yaml
oc get pods -n troubleshoot-lab
oc describe pod -n troubleshoot-lab -l app=hello | tail -30

oc apply -k ai/sample-app/base
oc rollout status deploy/hello -n troubleshoot-lab
```

| Fault | File | What you should see |
| --- | --- | --- |
| Image tag does not exist | `faults/bad-image.yaml` | `ImagePullBackOff` / `ErrImagePull` |
| Container exits immediately | `faults/crashloop.yaml` | `CrashLoopBackOff`, log line `crashloop-lab` |
| Service selects nothing | `faults/wrong-selector.yaml` | Pods stay Ready, the route returns a failure because endpoints are empty |

Useful reads while it is broken:

```bash
oc get pods,endpoints,svc,route -n troubleshoot-lab
oc get events -n troubleshoot-lab --sort-by='.lastTimestamp'
oc logs -n troubleshoot-lab -l app=hello --tail=20
oc describe endpoints hello -n troubleshoot-lab
```

## Remove

```bash
oc delete namespace troubleshoot-lab
```

## Verified on this lab

On 20 October 2026, `oc apply -k ai/sample-app/base` rolled out two Ready pods on 5.0.0-rc.7. `curl` of the edge route returned `hello from troubleshoot-lab`.

```text
https://hello-troubleshoot-lab.apps.ocp.2mrdz.sandbox1108.opentlc.com
```

## Placeholder

- [ ] Add a fourth fault that drops the ConfigMap mount and shows the 403 readiness failure
- [ ] Point Lightspeed at `troubleshoot-lab` and save a transcript that names the fault. Chat troubleshooting and alert-driven runs on `cluster-84wvf` are in [agentic troubleshooting](../lightspeed/agentic-troubleshooting.md). The three faults above stay the portable break-and-fix set.
