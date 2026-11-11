# Draft for redhat-cop/gitops-catalog

These texts are not opened. The files are on [tosin2013/gitops-catalog](https://github.com/tosin2013/gitops-catalog), branch `add-openshift-lightspeed`, directory `openshift-lightspeed-operator`, commit `c3208b9`. Open the issue and the pull request when the files look right. The pull request base is `redhat-cop/gitops-catalog` `main`. The head is `tosin2013/gitops-catalog` `add-openshift-lightspeed`.

`oc kustomize` succeeds for `operator/base`, `operator/overlays/stable`, `operator/overlays/alpha`, `instance/base`, and each instance overlay. The Subscription channel in `stable` is `stable`. There is no `startingCSV` and no `olm.providedAPIs` annotation.

## Issue

Title: Add OpenShift Lightspeed 2.0

```markdown
The catalog has no OpenShift Lightspeed component.

Lightspeed 2.0 is one operator. On a 5.0 cluster the `redhat-operators` catalog lists it on channels `stable` and `alpha`. The CLI install is a Namespace, an OperatorGroup, and a Subscription in `openshift-lightspeed`, source `redhat-operators`, approval automatic, and no `startingCSV`.

I would like to add `openshift-lightspeed-operator` with those two channel overlays and one instance overlay per provider. The instance overlays use placeholders. The token stays outside the catalog. `azure-entra` is the same Azure instance with different secret keys, so it is a note on `azure-openai` rather than another overlay.

The README would show one Argo CD Application for `operator/overlays/stable` and one for a single instance overlay. The Secret named by that overlay would be supplied by whatever secret manager the cluster already uses.
```

## Pull request

Title: Add the OpenShift Lightspeed 2.0 operator and provider overlays

```markdown
## Summary

- Add `openshift-lightspeed-operator` in the layout from CONTRIBUTING.md: one object per file, channel overlays named `stable` and `alpha`, and no `startingCSV`.
- Add an `OLSConfig` named `cluster` and one overlay per provider (`openai`, `azure-openai`, `gemini-api`, `gemini-vertex`, `vertex-anthropic`, `rhoai-vllm`, `rhelai-vllm`, `watsonx`). Placeholders only. No token.
- Document two Argo CD Applications. The Secret is created outside this component. This change does not install Sealed Secrets, External Secrets, or the GitOps operator.
- Allow the words `Entra`, `Lightspeed`, and `OLSConfig` in `.wordlist-md`.

## Test plan

- [ ] `oc kustomize` each new directory that contains `kustomization.yaml`
- [ ] Confirm `operator/overlays/stable` sets `spec.channel` to `stable` and `alpha` sets `alpha`
- [ ] Confirm the Subscription has no `startingCSV` and the OperatorGroup has no `olm.providedAPIs` annotation
- [ ] Do not apply a placeholder instance overlay onto a cluster that already has an `OLSConfig` named `cluster`
```
