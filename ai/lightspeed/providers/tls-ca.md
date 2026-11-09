# Trusted CA for the LLM endpoint

Use this when the provider presents a certificate that the Lightspeed pod does not already trust. Lightspeed 1.0 accepts `spec.ols.additionalCAConfigMapRef` for these provider types:

- `openai`
- `azure_openai`
- `rhelai_vllm`
- `rhoai_vllm`

`watsonx` does not take a custom CA. Vertex providers (`google_vertex`, `google_vertex_anthropic`) are not in that list. They call Google APIs with the service-account key.

The ConfigMap lives in `openshift-lightspeed`. The file name inside the ConfigMap is the key Lightspeed reads.

```bash
oc create configmap trusted-certs \
  --from-file=ca.crt=/path/to/ca.crt \
  -n openshift-lightspeed
```

Add the reference under `spec.ols` on the provider file you applied. `defaultProvider` and `defaultModel` stay as they are.

```yaml
spec:
  ols:
    additionalCAConfigMapRef:
      name: trusted-certs
```

Apply the updated `OLSConfig`, then confirm the app server pod rolled and `overallStatus` is `Ready`.
