#!/bin/bash

kubectl delete -f config/fakes/eirini_app.yaml
kubectl delete -f config/deployment-ns-default.yaml
kubectl delete mutatingwebhookconfigurations eirini-x-starkandwayne-pancake-mutating-hook-default
kubectl delete secret eirini-x-starkandwayne-pancake-setupcertificate

kubectl apply -f config/deployment-ns-default.yaml
kubectl wait pod --for condition=Ready -l app=eirini-pancake-extension -n default
sleep 5
kubectl apply -f config/fakes/eirini_app.yaml
