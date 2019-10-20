# Pancake EiriniX extension

Flatten `$VCAP_SERVICES` for all Eirini applications into many individual environment variables.

For example, the binding `credentials` below includes `uri` and `max_conns`. The former is converted into three variables for your application to choose from: `ELEPHANTSQL_URI` (based on the service name), `MYAPP_DB_URI` (based on the service instance name), and `POSTGRESQL_URI` (based on one of the tags):

```plain
$ kubectl describe pod myapp-dev-qwerty
...
    Environment:
      VCAP_SERVICES:          {"elephantsql":[{
                                "label": "elephantsql",
                                "plan": "turtle",
                                "name": "myapp-db",
                                "tags": [
                                  "postgresql"
                                ],
                                "instance_name": "myapp-db",
                                "credentials": {
                                  "uri": "postgres://efmpxxxa:wxVigKB_X8ACpkKjTHQ7WAqilCB9Rb9D@raja.db.elephantsql.com:5432/efmpxxxa",
                                  "max_conns": "5"
                                }
                              }]}
      ELEPHANTSQL_URI:        postgres://efmpxxxa:wxVigKB_X8ACpkKjTHQ7WAqilCB9Rb9D@raja.db.elephantsql.com:5432/efmpxxxa
      MYAPP_DB_URI:           postgres://efmpxxxa:wxVigKB_X8ACpkKjTHQ7WAqilCB9Rb9D@raja.db.elephantsql.com:5432/efmpxxxa
      POSTGRESQL_URI:         postgres://efmpxxxa:wxVigKB_X8ACpkKjTHQ7WAqilCB9Rb9D@raja.db.elephantsql.com:5432/efmpxxxa
      ELEPHANTSQL_MAX_CONNS:  5
      MYAPP_DB_MAX_CONNS:     5
      POSTGRESQL_MAX_CONNS:   5
```

Eirini is an extension for Cloud Foundry that runs applications as statefulsets/pods within Kubernetes. This in turn allows operators to extend the behavior of their own Cloud Foundry platform with mutating webhooks - when a pod is created by Eirini, our bespoke webhook can be run to mutate the pod before it commences.

One convenient starting point for writing mutating webhooks for Eirini-managed Pods is the SUSE [EiriniX](https://github.com/SUSE/eirinix) library (see [blog post](https://www.cloudfoundry.org/blog/introducing-eirinix-how-to-build-eirini-extensions/)).

In this project we have a mutating webhook that reads the `$VCAP_SERVICES` environment variable and appends many additional environment variables to the pod's containers.

This README will demonstrate how it works without you needing to run Cloud Foundry/Eirini.

This EiriniX extension should work with any Cloud Foundry/Eirini, including:

* [IBM Cloud Foundry Enterprise Edition](https://cloud.ibm.com/docs/cloud-foundry?topic=cloud-foundry-getting-started) with "Eirini Technical Preview" enabled
* [Pivotal Application Service for Kubernetes](https://pivotal.io/platform/pas-on-kubernetes)
* [SUSE Cloud Application Platform](https://www.suse.com/products/cloud-application-platform/cloud-foundry/), with [Eirini Enabled](https://documentation.suse.com/suse-cap/1/html/cap-guides/cha-cap-depl-eirini.html#sec-cap-eirini-enable).
* Any open source Cloud Foundry with [Eirini Release included](https://documentation.suse.com/suse-cap/1/html/cap-guides/cha-cap-depl-eirini.html#sec-cap-eirini-enable).
* Stark & Wayne's [Bootstrap Kubernetes Demos](https://documentation.suse.com/suse-cap/1/html/cap-guides/cha-cap-depl-eirini.html#sec-cap-eirini-enable) with `--scf` flag to run Cloud Foundry/Eirini on your Kubernetes cluster.

## Demonstration without Eirini on any Kubernetes

We can see this Pancake EiriniX extension running without Cloud Foundry nor Eirini itself. It will deploy the webhook and sample application into the `default` namespace. We will clean up at the end.

### Deploy Hello World Webhook

```plain
kubectl apply -f config/deployment-ns-default.yaml
```

To tail the logs of the `app=eirini-pancake-extension` pod:

```plain
stern -l app=eirini-pancake-extension
```

### Deploy Sample Pod

When we deploy an example Eirini-like pod (EiriniX webhooks match to any pod with a label `source_type: APP`):

```plain
kubectl apply -f config/fakes/eirini-fake-app-with-vcap-services.yaml
```

The logs of the extension will show:

```plain
... {"level":"info","logger":"cf-pancake","caller":"pancake/pancake.go:66","msg":"Found $VCAP_SERVICES in eirini-fake-app-with-vcap-services (default)"}
```

See the top of the README for the results of this `config/fakes/eirini-fake-app-with-vcap-services.yaml` fake Eirini pod.

### Tear it down

In addition to deleting the fake Eirini app and the webhook/service, we also need to delete a generated `mutatingwebhookconfiguration` and a `secret`:

```plain
./hack/delete.sh
```

### Separate namespaces for Webhook and app Pods

TODO

## Developers

Our EiriniX webhook above is installed as a Kubernetes deployment, so we need to package this source code as an OCI/Docker image. There is no `Dockerfile`. I'm trying to ween myself off them and the mystery meat they may contain.

Instead we will use [Cloud Native Buildpacks](https://buildpacks.io), and the [`pack` CLI](https://buildpacks.io/docs/install-pack/):

```plain
pack build starkandwayne/eirinix-sample --builder cloudfoundry/cnb:bionic --publish
```

One way to "update" the webhook is to delete and re-apply the webhook with this helper script:

```plain
./hacks/redeploy.sh
```

Any previously generated `mutatingwebhookconfiguration` and `secret` will be kept (these must be explicitly deleted to be removed).

See [Tear it down](#tear-it-down) for cleanup of webhook, secret, and `mutatingwebhookconfiguration`.

### Build Docker Image with kpack

In liue of running `pack build --publish` locally, you can use [kpack](https://github.com/pivotal/kpack) to automatically build OCIs from your fork/branch and publish to your own Docker Registry.

A helper script is provided to create two kpack resources:

* `Builder` describing the use of `cloudfoundry/cnb:bionic` builder, and
* `Image` describing your remote Git fork and branch, and your image registry details

The only requirement is a `ServiceAccount` containing authentication secrets for your Docker Registry account.

```plain
export SERVICE_ACCOUNT=service-account
cat ./hacks/kpack-builder-image.sh
```

A full example for forking, branch, and building these kpack resources:

```plain
hub fork
git checkout -b my-new-feature

export SERVICE_ACCOUNT=service-account
cat ./hacks/kpack-builder-image.sh
```

Confirm that everything looks good, and then install into Kubernetes:

```plain
cat ./hacks/kpack-builder-image.sh | kubectl apply -f -
```
