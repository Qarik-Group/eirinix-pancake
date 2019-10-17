#!/bin/bash

kubectl apply -f config/deployment-ns-default.yaml
kubectl wait pod --for condition=Ready -l app=eirini-pancake-extension -n default
sleep 5
kubectl apply -f config/fakes/eirini-fake-app-no-vcap-services.yaml
kubectl apply -f config/fakes/eirini-fake-app-empty-vcap-services.yaml
kubectl apply -f config/fakes/eirini-fake-app-with-vcap-services.yaml
