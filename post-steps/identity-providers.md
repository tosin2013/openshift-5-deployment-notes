# Identity providers

Read the providers already on the cluster before you add one. Replacing `spec.identityProviders` drops every provider that is not in the file you apply.

```bash
oc get oauth cluster -o jsonpath='{range .spec.identityProviders[*]}{.name}{" "}{.type}{"\n"}{end}'
```

## HTPasswd

Create the password file on a machine that has `htpasswd`. Keep the password out of git.

```bash
htpasswd -c -B -b /tmp/users labuser "$(openssl rand -base64 16)"
oc create secret generic htpass-secret \
  --from-file=htpasswd=/tmp/users \
  -n openshift-config
```

Append another user with `htpasswd -b` (no `-c`). The OpenShift 4 notes also have [user_pass_generator.sh](https://github.com/tosin2013/openshift-4-deployment-notes/blob/master/post-steps/user_pass_generator.sh) for several users at once.

```yaml
apiVersion: config.openshift.io/v1
kind: OAuth
metadata:
  name: cluster
spec:
  identityProviders:
    - name: htpasswd
      mappingMethod: claim
      type: HTPasswd
      htpasswd:
        fileData:
          name: htpass-secret
```

If the cluster already has a provider, get the live object, append this entry, and apply the result. Applying the file above by itself removes the others. `oc adm policy add-cluster-role-to-user cluster-admin` is separate and is not required to log in.

Product docs: [Understanding identity provider configuration](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/authentication_and_authorization/understanding-identity-provider).

Check the login page on the build you are installing.
