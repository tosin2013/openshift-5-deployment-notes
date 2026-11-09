# MCP Gateway

Checked 9 November 2026 on `cluster-84wvf` (`5.0.0-rc.7`). The [lab index](https://showroom-showroom-84wvf-1.apps.cluster-84wvf.dyn.redhatworkshops.io/?t=Terminal&p=index) calls this the third module. It is Red Hat Connectivity Link in front of several MCP servers. The OpenShift MCP server itself is on [the MCP server page](README.md).

Product docs: [MCP gateway introduction](https://docs.redhat.com/en/documentation/red_hat_connectivity_link/1.5/html/mcp_gateway/mcp-gateway-introduction) (Red Hat Connectivity Link 1.5). The objects below are the cluster record.

## What is installed

OpenShift GitOps applied two Applications from [rhpds/ocp5-first-look-lab](https://github.com/rhpds/ocp5-first-look-lab) at `ocp5-first-look-1.1.2`. Both were `Synced` and `Healthy`, with auto-sync and self-heal on.

| Application | Path |
| --- | --- |
| `mcp-gateway` | `automation/gitops/mcp-gateway` |
| `mock-mcp-servers` | `automation/gitops/mock-mcp-servers` |

Operators in namespace `mcp-gateway`, from catalog `redhat-operators-v422`:

| CSV | Channel | Phase |
| --- | --- | --- |
| `rhcl-operator.v1.4.2` (Red Hat Connectivity Link) | `stable` | Succeeded |
| `mcp-gateway.v0.7.1` (MCP Gateway Operator, Tech Preview) | `preview` | Succeeded |

Authorino, Limitador, and the DNS operator run in the same namespace. The console plugin is `kuadrant-console-plugin`. The lab opens it as Connectivity Link → Overview.

The public route is `https://mcp-gateway.apps.cluster-84wvf.dyn.redhatworkshops.io`. It lands on Gateway `mcp-gateway` in `openshift-ingress` (class `openshift-default`, listener section `mcp`). `MCPGatewayExtension` `mock-mcp-extension` in `mock-mcp-servers` is Ready and points at that Gateway. Its protected-resource metadata names the Keycloak realm `https://sso.apps.cluster-84wvf.dyn.redhatworkshops.io/realms/keycloak` and the scopes `openid`, `roles`, and `groups`.

## Backends

Three `MCPServerRegistration` objects in `mock-mcp-servers` were Ready on 9 November 2026. Each reported five tools and attaches to an HTTPRoute on Gateway `mcp-gateway`.

| Name | Prefix | HTTPRoute |
| --- | --- | --- |
| `inventory` | `inventory_` | `inventory-mcp-route` |
| `payments` | `payments_` | `payments-mcp-route` |
| `accounts` | `accounts_` | `accounts-mcp-route` |

The pods `inventory-mcp`, `payments-mcp`, and `accounts-mcp` were Running. These are the lab's mock servers. They are not the OpenShift MCP server in `openshift-mcp`.

## Policy

A caller presents a Keycloak bearer token. `AuthPolicy` `mcp-gateway-auth` checks that token on HTTPRoute `mcp-gateway-route`. Issuer is the `keycloak` realm above. `AuthPolicy` `mcp-tool-auth-policy` on the Gateway then allows a tool only when the token's `resource_access` roles for that MCP server include `tool:` plus the tool name. A missing token gets 401. A token without the role gets 403.

`RateLimitPolicy` `mcp-gateway-ratelimit` allows 30 requests per minute per token subject (`auth.identity.sub`) on the same route. Limitador is the counter.

Jaeger is running in `mock-mcp-servers` and has a route, `jaeger-mock-mcp-servers.apps.cluster-84wvf.dyn.redhatworkshops.io`. There is no `TelemetryPolicy` in the cluster, so this note does not claim that every gateway call is traced.

GitOps will put these objects back if you edit them. Pause auto-sync on `mcp-gateway` or `mock-mcp-servers` before a change you need to keep.
