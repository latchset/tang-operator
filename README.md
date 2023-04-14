# tang-operator

## Contents

- [Introduction](#introduction)
- [Versions](#versions)
- [Installation](#installation)
- [Compilation](#compilation)
- [Cross Compilation](#cross-compilation)
- [Cleanup](#cleanup)
- [Tests](#tests)
- [CI/CD](#cicd)
- [Scorecard](#scorecard)
- [Links](#links)

## Introduction

This operator helps on providing [NBDE](https://access.redhat.com/articles/6987053)
for K8S/OpenShift. It deploys one or several tang servers automatically.
The tang server container image to launch is configurable, and will use the latest one
available by default. It has been developed using operator-sdk.

The tang-operator avoids having to follow all tang installation steps, and leverages
some of the features provided by OpenShift: multi-replica deployment, scale-in/out,
scale up/down or traffic load balancing.

This operator also allows automation of certain operations, which are error prone
if executed manually. Examples of this operations are:
- server deployment and configuration
- key rotation
- hidden keys deletion

Up to date, it can be deployed as a CRD, containing its proper
configuration values to perform appropriate tang server operations.

An introductory video can be seen in next link:
[NBDE in OpenShift: tang-operator basics](https://youtu.be/hmMSIkBoGoY)

## Versions

Versions released up to date of the tang operator and the
tang operator-bundle are:

- v0.0.1:  Hello world version
- v0.0.2:  Basic version with no fields still updated
- v0.0.3:  First release correct version
- v0.0.4:  Version that fixes issues with deployments/pods/services permissions
- v0.0.5:  Version that publishes the service and exposes it on configurable port
- v0.0.6:  Types refactoring. Initial ginkgo based test
- v0.0.7:  Include finalizers to make deletion quicker
- v0.0.8:  Tang operator metadata homogenization
- v0.0.9:  Tang operator shared storage
- v0.0.10: Code Refactoring
- v0.0.11: Extend tests
- v0.0.12: Fix default keypath
- v0.0.13: Add type for Persistent Volume Claim attach
- v0.0.14: Fix issue on non 8080 service port deployment
- v0.0.15: Add resource request/limits
- v0.0.16: Fix scale up issues
- v0.0.17: Key rotation/deletion management via spec file
- v0.0.18: Advertise only signing keys
- v0.0.19: Add Events writing with important information
- v0.0.20: Use tangd-healthcheck only for aliveness
- v0.0.21: Use tangd-healthcheck for aliveness and readiness, separating intervals
- v0.0.22: Remove personal accounts and use organization ones
- v0.0.23: Selective hidden keys deletion
- v0.0.24: Execute tang container pod as non root user
- v0.0.25: Allow key handling without cluster role configuration
- v0.0.26: Use RHEL9 tang container version

## Installation

In order to install tang operator, you must have previously installed
an Open Shift cluster. For small computers, **CRC** (Code Ready Containers)
project is recommended. In case normal OpenShift cluster is used, tang operator
installation should not differ from the CRC one.

Instructions for **CRC** installation can be observed
in the [Links](#links) section.
Apart from cluster, the corresponding client is required to check
the status of the different Pods, Deployments and Services. Required
OpenShift client to install is **oc**, whose installation can be
checked in the [Links](#links) section.

Once K8S/OpenShift cluster is installed, tang operator can be installed
with operator-sdk.
operator-sdk installation is described in the [Links](#links) section.

In order to deploy the latest version of the tang operator, check latest released
version in the [Versions](#versions) section, and install the appropriate version
bundle. For example, in case latest version is **0.0.26**, the command to execute
will be:

```bash
$ operator-sdk run bundle quay.io/sec-eng-special/tang-operator-bundle:v0.0.26 --index-image=quay.io/operator-framework/opm:v1.23.0
INFO[0008] Successfully created registry pod: quay-io-sec-eng-special-tang-operator-bundle-v0.0.26
INFO[0009] Created CatalogSource: tang-operator-catalog
INFO[0009] OperatorGroup "operator-sdk-og" created
INFO[0009] Created Subscription: tang-operator-v0.0.26-sub
INFO[0011] Approved InstallPlan install-lqf9f for the Subscription: tang-operator-v0.0.26-sub
INFO[0011] Waiting for ClusterServiceVersion to reach 'Succeeded' phase
INFO[0012]   Waiting for ClusterServiceVersion "default/tang-operator.v0.0.26"
INFO[0018]   Found ClusterServiceVersion "default/tang-operator.v0.0.26" phase: Pending
INFO[0020]   Found ClusterServiceVersion "default/tang-operator.v0.0.26" phase: InstallReady
INFO[0021]   Found ClusterServiceVersion "default/tang-operator.v0.0.26" phase: Installing
INFO[0031]   Found ClusterServiceVersion "default/tang-operator.v0.0.26" phase: Succeeded
INFO[0031] OLM has successfully installed "tang-operator.v0.0.26"
```
To install latest multi-arch image, execute:
```bash
$ operator-sdk run bundle quay.io/sec-eng-special/tang-operator-bundle:multi-arch --index-image=quay.io/operator-framework/opm:v1.23.0
```

If the message **OLM has successfully installed** is displayed, it is normally a
sign of a proper installation of the tang operator.

If a message similar to **"failed open: failed to do request: context deadline exceeded"**,
it is possible that a timeout is taking place. Try to increase the timeout in case
your cluster takes long time to deploy. To do so, the option **--timeout** can be
used (if not used, default time is 2m, which stands for two minutes):

```bash
$ operator-sdk run bundle --timeout 3m quay.io/sec-eng-special/tang-operator-bundle:v0.0.26 --index-image=quay.io/operator-framework/opm:v1.23.0
INFO[0008] Successfully created registry pod: quay-io-sec-eng-special-tang-operator-bundle-v0.0.26
...
INFO[0031] OLM has successfully installed "tang-operator.v0.0.26"
```

Additionally, correct tang operator installation can be observed if an output like
the following is observed when prompting for installed pods:

```bash
$ oc get pods
NAME                                                READY STATUS    RESTARTS AGE
dbbd1837106ec169542546e7ad251b95d27c3542eb0409c1e   0/1   Completed 0        82s
quay-io-tang-operator-bundle-v0.0.26                1/1   Running   0        90s
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
```

In case tang operator is appropriately executed, **ndbe** namespace should contain
the service, deployment and pod associated to the tang operator:

```
$ oc -n nbde get services
NAME               TYPE         CLUSTER-IP     EXTERNAL-IP    PORT(S)        AGE
service-tangserver LoadBalancer 172.30.167.129 34.133.181.172 8080:30831/TCP 58s

$ oc -n nbde get deployments
NAME              READY   UP-TO-DATE   AVAILABLE   AGE
tsdp-tangserver   1/1     1            1           63s

$ oc -n nbde get pods
NAME                               READY   STATUS    RESTARTS   AGE
tsdp-tangserver-55f747757c-599j5   1/1     Running   0          40s
```

Note the **Running** state for the tangserver pods.

## Compilation

Compilation of tang operator can be released in top directory, by executing
**make docker-build**. The name of the image must be provided. In case there
is no requirement to update the version, same version compared to the last
version can be used. Otherwise, if new version of the tang operator is going
to be released, it is recommended to increase version appropriately.

In this case, same version is used. Last released version can be observed in
[Versions](#versions) section.

To summarize, taking into account that the last released version is **v0.0.26**
compilation can be done with next command:

```bash
$ make docker-build docker-push IMG="quay.io/sec-eng-special/tang-operator:v0.0.26"
...
Successfully built 4a88ba8e6426
Successfully tagged sec-eng-special/tang-operator:v0.0.26
docker push sec-eng-special/tang-operator:v0.0.26
The push refers to repository [quay.io/sec-eng-special/tang-operator]
79109912085a: Pushed
417cb9b79ade: Layer already exists
v0.0.26: digest: sha256:c97bed08ab71556542602b008888bdf23ce4afd86228a07 size: 739
```

In case a new release is planned to be done, the steps to follow will be:

- Modify Makefile so that it contains the new version:

```bash
$ git diff Makefile
diff --git a/Makefile b/Makefile
index 9a41c6a..db12a82 100644
--- a/Makefile
+++ b/Makefile
@@ -3,7 +3,7 @@
# To re-generate a bundle for another specific version without changing the
# standard setup, you can:
# - use the VERSION as arg of the bundle target (e.g make bundle VERSION=0.0.26)
# - use environment variables to overwrite this value (e.g export VERSION=0.0.26)
-VERSION ?= 0.0.24
+VERSION ?= 0.0.26
```

Apart from previous changes, it is recommended to generate a "latest" tag for tang-operator bundle:
```bash
$ docker tag quay.io/sec-eng-special/tang-operator-bundle:v0.0.26 quay.io/sec-eng-special/tang-operator-bundle:latest
$ docker push quay.io/sec-eng-special/tang-operator-bundle:latest
```

- Compile operator:

Compile tang operator code, specifying new version,
by using **make docker-build** command:

```bash
$ make docker-build docker-push IMG="quay.io/sec-eng-special/tang-operator:v0.0.26"
...
Successfully tagged sec-eng-special/tang-operator:v0.0.26
docker push sec-eng-special/tang-operator:v0.0.26
The push refers to repository [quay.io/sec-eng-special/tang-operator]
9ff8a4099c67: Pushed
417cb9b79ade: Layer already exists
v0.0.26: digest: sha256:01620ab19faae54fb382a2ff285f589cf0bde6e168f14f07 size: 739
```

- Bundle push:

In case the operator bundle is required to be pushed, generate
the bundle with **make bundle**, specifying appropriate image,
and push it with **make bundle-build bundle-push**:

```bash
$ make bundle IMG="quay.io/sec-eng-special/tang-operator:v0.0.26"
$ make bundle-build bundle-push BUNDLE_IMG="quay.io/sec-eng-special/tang-operator-bundle:v0.0.26"
...
docker push sec-eng-special/tang-operator-bundle:v0.0.26
The push refers to repository [quay.io/sec-eng-special/tang-operator-bundle]
02e3768cfc56: Pushed
df0c8060d328: Pushed
84774958bcf4: Pushed
v0.0.26: digest: sha256:925c2f844f941db2b53ce45cba9db7ee0be613321da8f0f05d size: 939
make[1]: Leaving directory '/home/user/RedHat/TASKS/TANG_OPERATOR/tang-operator'
```

**IMPORTANT NOTE**: After bundle generation, next change will appear on the bundle directory:

```bash
--- a/bundle/manifests/tang-operator.clusterserviceversion.yaml
+++ b/bundle/manifests/tang-operator.clusterserviceversion.yaml
@@ -36,17 +36,6 @@ spec:
       displayName: Tang Server
       kind: TangServer
       name: tangservers.daemons.redhat.com
-      resources:
-      - kind: Deployment
-        version: v1
-      - kind: ReplicaSet
-        version: v1
-      - kind: Pod
-        version: v1
-      - kind: Secret
-        version: v1
-      - kind: Service
-        version: v1
```

**DO NOT COMMIT PREVIOUS CHANGE**, as this metadata information is required by
scorecard tests to pass successfully

- Commit changes:

Remember to **modify README.md** to include the new release version, and commit changes
performed in the operator, together with README.md and Makefile changes

## Cross Compilation

In order to cross compile tang-operator, prepend **GOARCH** with required architecture to
**make docker-build**:

```bash
$ GOARCH=ppc64le make docker-build docker-push IMG="quay.io/sec-eng-special/tang-operator:v0.0.26"
...
Successfully built 4a88ba8e6426
Successfully tagged sec-eng-special/tang-operator:v0.0.26
docker push sec-eng-special/tang-operator:v0.0.26
The push refers to repository [quay.io/sec-eng-special/tang-operator]
79109912085a: Pushed
417cb9b79ade: Layer already exists
v0.0.26: digest: sha256:c97bed08ab71556542602b008888bdf23ce4afd86228a07 size: 739
```

## Cleanup

For operator removal, execution of option **cleanup** from sdk-operator is the
recommended way:

```bash
$ operator-sdk cleanup tang-operator
INFO[0001] subscription "tang-operator-v0.0.26-sub" deleted
INFO[0001] customresourcedefinition "tangservers.daemons.redhat.com" deleted
INFO[0002] clusterserviceversion "tang-operator.v0.0.26" deleted
INFO[0002] catalogsource "tang-operator-catalog" deleted
INFO[0002] operatorgroup "operator-sdk-og" deleted
INFO[0002] Operator "tang-operator" uninstalled
```

## Tests

Execution of operator tests is pretty simple. These tests don't require any k8s infrastructure installed.
Execute **make test** from top directory and available tests will be executed:

```bash
$ make test
...
go fmt ./...
go vet ./...
...
setting up env vars
?   github.com/latchset/tang-operator      [no test files]
?   github.com/latchset/tang-operator/api/v1alpha1 [no test files]
ok  github.com/latchset/tang-operator/controllers  6.541s  coverage: 24.8% of statements
```

In order to execute tests that require having a cluster ready, a k8s infrastructure (minikube/CRC)
must be running. To execute tang operator tests based on reconciliation, **CLUSTER_TANG_OPERATOR_TEST**
environment variable must be set:

```bash
$ CLUSTER_TANG_OPERATOR_TEST=1 make test
...
go fmt ./...
go vet ./...
...
setting up env vars
?   github.com/latchset/tang-operator      [no test files]
?   github.com/latchset/tang-operator/api/v1alpha1 [no test files]
ok  github.com/latchset/tang-operator/controllers  9.303s  coverage: 36.5% of statements
```

As shown previously, coverage is calculated after test execution. Coverage data is dumped
to file **coverage.out**. To inspect coverage graphically, it can be observed by executing
next command:

```bash
$ go tool cover -html=cover.out
```

Previous command will open a web browser with the different coverage reports of the different
files that are part of the controller.

## CI/CD

tang-operator uses Github Actions to perform CI/CD task. A verification job will run for each
commit to main or PR. The verify job perform following steps:

* Set up Go
* Minikube Installation
* Check Minikube Status
* Build
* Test
* Cluster Test
* Deployment
* Scorecard test execution

NOTE: CI/CD is in a "work in progress" state

## scorecard

Execution of operator-sdk scorecard tests are passing completely in version v0.0.26.
In order to execute these tests, run next command:

```bash
$ operator-sdk scorecard -w 60s quay.io/sec-eng-special/tang-operator-bundle:v0.0.26
...
Results:
Name: olm-status-descriptors
State: pass
...
Results:
Name: olm-spec-descriptors
State: pass
...
Results:
Name: olm-crds-have-resources
State: pass
...
Results:
Name: basic-check-spec
State: pass
...
Results:
Name: olm-crds-have-validation
State: pass
...
Results:
Name: olm-bundle-validation
State: pass
```

## Links

[NBDE](https://access.redhat.com/articles/6987053)\
[CodeReady Containers Installation](https://access.redhat.com/documentation/en-us/red_hat_codeready_containers/1.29/html/getting_started_guide/installation_gsg)\
[Minikube Installation](https://minikube.sigs.k8s.io/docs/start/)\
[operator-sdk Installation](https://sdk.operatorframework.io/docs/building-operators/golang/installation/)\
[OpenShift CLI Installation](https://docs.openshift.com/container-platform/4.2/cli_reference/openshift_cli/getting-started-cli.html#cli-installing-cli_cli-developer-commands)\
[Validating Operators using the scorecard tool](https://docs.okd.io/latest/operators/operator_sdk/osdk-scorecard.html)
