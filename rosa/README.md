# Red Hat OpenShift Service on AWS

ROSA is a managed service. This is not the self-managed OpenShift installer. Use the `rosa` CLI on a bastion that already has the AWS CLI. [configure-aws-cli.sh](../aws/configure-aws-cli.sh) installs that CLI. Pass the keys as arguments and do not commit them.

```bash
../pre-steps/configure-other-clients.sh -i --rosa
rosa login
rosa verify permissions
rosa verify quota --region us-west-2
rosa whoami
rosa init
rosa download oc
```

A cluster with the default settings:

```bash
rosa create cluster --cluster-name poc-cluster
rosa logs install --cluster poc-cluster --watch
rosa describe cluster --cluster poc-cluster
rosa create admin --cluster poc-cluster
```

`rosa create admin` prints the admin password. Do not commit that output. `rosa create cluster --interactive` asks for the same choices.

For a private STS cluster, [rosa-vpc-for-sts.sh](https://github.com/tosin2013/openshift-4-deployment-notes/blob/master/rosa/rosa-vpc-for-sts.sh) creates the VPC. Then:

```bash
rosa create cluster --private-link --cluster-name private-link \
  --machine-cidr 10.0.0.0/16 --subnet-ids "$PRIVATE_SUBNET" --region us-east-2
```

Add `--multi-az` and three subnet ids for a multi-AZ cluster. Delete with `rosa delete cluster --cluster poc-cluster --watch` and `rosa init --delete-stack`. [delete-vpc.sh](https://github.com/tosin2013/openshift-4-deployment-notes/blob/master/rosa/delete-vpc.sh) removes the VPC the script created.

Product docs: [Install clusters](https://docs.redhat.com/en/documentation/red_hat_openshift_service_on_aws/4/html/install_clusters/) (Red Hat OpenShift Service on AWS 4). ROSA has its own book.

Check `rosa version` and the install flags on the day you create the cluster. On 9 November 2026 the newest numbered directory was `1.2.53`. The [ROSA CLI](https://docs.redhat.com/en/documentation/red_hat_openshift_service_on_aws/4/html/cli_tools/rosa-cli) example still prints `1.2.15`.
