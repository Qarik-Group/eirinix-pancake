#!/bin/bash

kubectl apply -f config/fakes/eirini-fake-app-no-vcap-services.yaml
kubectl apply -f config/fakes/eirini-fake-app-empty-vcap-services.yaml
kubectl apply -f config/fakes/eirini-fake-app-with-vcap-services.yaml
