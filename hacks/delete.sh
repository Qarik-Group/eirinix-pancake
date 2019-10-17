#!/bin/bash

kubectl delete --wait=false -f config/fakes/eirini-fake-app-with-vcap-services.yaml
kubectl delete --wait=false -f config/fakes/eirini-fake-app-no-vcap-services.yaml
kubectl delete --wait=true  -f config/fakes/eirini-fake-app-empty-vcap-services.yaml
kubectl delete -f config/deployment-ns-default.yaml
kubectl delete mutatingwebhookconfigurations eirini-x-starkandwayne-pancake-mutating-hook-default
kubectl delete secret eirini-x-starkandwayne-pancake-setupcertificate
