# tang-operator

## Contents

- [Introduction](#specification)
- [Versions](#versions)
- [Installation](#installation)
- [Compilation](#compilation)
- [Cleanup](#cleanup)
- [Tests](#tests)
- [Links](#links)

## Introduction

This operator is a Proof of Concept of a tang operator,
and how it is deployed in top of OpenShift.

Up to date, it can be deployed as a CRD, containing its proper
configuration values to perform appropriate tang server operations.

## Versions

Versions released up to date of the tang operator and the
tang operator-bundle are:

- v0.0.1: Hello world version
- v0.0.2: Basic version with no fields still updated
- v0.0.3: First release correct version. PLEASE, DO NOT OVERWRITE
- v0.0.4: Version that fixes issues with deployments/pods/services permissions.
          PLEASE, DO NOT OVERWRITE
- v0.0.5: Version that publishes the service and exposes it on configurable port.
          PLEASE, DO NOT OVERWRITE
- v0.0.6: Types refactoring. Initial ginkgo based test.
          PLEASE, DO NOT OVERWRITE

## Installation

In order to install tang operator, you must have previously installed
an Open Shift cluster. For small computers, **Minishift** project
is recommended. In case normal OpenShift cluster is used, tang operator
installation should not differ from the Minishift one.

Instructions for **Minishift** installation can be observed
in the [Links](#links) section.
Apart from cluster, the corresponding client is required to check
the status of the different Pods, Deployments and Services. Required
OpenShift client to install is **oc**, whose installation can be
checked in the [Links](#links) section.

Once K8S/Openshift cluster is installed, tang operator can be installed
with operator-sdk.
operator-sdk installation is described in the [Links](#links) section.

In order to deploy the latest version of the tang operator, check latest released
version in the [Versions](#versions) section, and install the appropriate version
bundle. For example, in case latest version is **0.0.6**, the command to execute
will be:

```bash
$ operator-sdk run docker.io/sarroutbi/tang-operator-bundle:v.0.0.6
INFO[0008] Successfully created registry pod: docker-io-sarroutbi-tang-operator-bundle-v0-0-6
INFO[0009] Created CatalogSource: tang-operator-catalog
INFO[0009] OperatorGroup "operator-sdk-og" created
INFO[0009] Created Subscription: tang-operator-v0-0-6-sub
INFO[0011] Approved InstallPlan install-lqf9f for the Subscription: tang-operator-v0-0-6-sub
INFO[0011] Waiting for ClusterServiceVersion to reach 'Succeeded' phase
INFO[0012]   Waiting for ClusterServiceVersion "default/tang-operator.v0.0.6"
INFO[0018]   Found ClusterServiceVersion "default/tang-operator.v0.0.6" phase: Pending
INFO[0020]   Found ClusterServiceVersion "default/tang-operator.v0.0.6" phase: InstallReady
INFO[0021]   Found ClusterServiceVersion "default/tang-operator.v0.0.6" phase: Installing
INFO[0031]   Found ClusterServiceVersion "default/tang-operator.v0.0.6" phase: Succeeded
INFO[0031] OLM has successfully installed "tang-operator.v0.0.6"
```

If the message **OLM has successfully installed** is displayed, it is normally a
sign of a proper installation of the tang operator.

However, correct tang operator installation can be observed if an output like
the following is observed when prompting for installed pods:

```bash
$ oc get pods
NAME                                                READY STATUS    RESTARTS AGE
dbbd1837106ec169542546e7ad251b95d27c3542eb0409c1e   0/1   Completed 0        82s
docker-io-tang-operator-bundle-v0-0-6               1/1   Running   0        90s
tang-operator-controller-manager-5c9488d8dd-mgmsf   2/2   Running   0        52s
```

Note the **Completed** and **Running** state for the different tang operator pods.

Once operator is correctly installed, appropriate configuration can be applied
from **config** directory. Minimal installation, that just provides the number
of replicas (1) to use, is the recommended tang operator configuration to apply:

```bash
$ oc apply -f config/minimal
namespace/nbde created
tangserver.daemons.redhat.com/tangserver created
secret/tangserversecret created
```

In case tang operator is appropriately executed, **ndbe** namespace should contain
the service, deployment and pod associated to the tang operator:

```
$ oc -n nbde get services
NAME               TYPE         CLUSTER-IP     EXTERNAL-IP    PORT(S)        AGE
service-tangserver LoadBalancer 172.30.167.129 34.133.181.172 8080:30831/TCP 59s

$ oc -n nbde get deployments
NAME              READY   UP-TO-DATE   AVAILABLE   AGE
tsdp-tangserver   1/1     1            1           63s

$ oc -n nbde get pods
NAME                               READY   STATUS    RESTARTS   AGE
tsdp-tangserver-55f747757c-599j5   1/1     Running   0          40s
```

Note the **Running** state for the tangserver pods.

## Cleanup

For operator removal, execution of option **cleanup** from sdk-operator is the
recommended way:

```bash
$ $ operator-sdk cleanup tang-operator
INFO[0001] subscription "tang-operator-v0-0-6-sub" deleted
INFO[0001] customresourcedefinition "tangservers.daemons.redhat.com" deleted
INFO[0002] clusterserviceversion "tang-operator.v0.0.6" deleted
INFO[0002] catalogsource "tang-operator-catalog" deleted
INFO[0002] operatorgroup "operator-sdk-og" deleted
INFO[0002] Operator "tang-operator" uninstalled
```

## Tests

Execution of operator tests is pretty simple. Execute **make test** from top directory
and available tests will be executed:

```bash
$ make test
...
go fmt ./...
go vet ./...
...
setting up env vars
?   github.com/sarroutbi/tang-operator      [no test files]
?   github.com/sarroutbi/tang-operator/api/v1alpha1 [no test files]
ok  github.com/sarroutbi/tang-operator/controllers  6.2s coverage: 50.0% of statements
```

## Links

[Minishift Installation](https://www.redhat.com/sysadmin/learn-openshift-minishift)
[operator-sdk Installation](https://sdk.operatorframework.io/docs/building-operators/golang/installation/)
[OpenShift CLI Installation](https://docs.openshift.com/container-platform/4.2/cli_reference/openshift_cli/getting-started-cli.html#cli-installing-cli_cli-developer-commands)
