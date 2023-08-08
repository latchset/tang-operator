#!/bin/bash
echo "-------------------------------------"
echo "oc status"
oc status
echo "-------------------------------------"
sleep 1
echo "oc create -f tang_catalog_source.yaml"
oc create -f tang_catalog_source.yaml
echo "-------------------------------------"
sleep 1
echo "oc get catsrc -nopenshift-marketplace"
oc get catsrc -nopenshift-marketplace
echo "-------------------------------------"
sleep 1
echo "oc get pods -nopenshift-marketplace"
oc get pods -nopenshift-marketplace
echo "-------------------------------------"
sleep 1
echo "oc create -f tang_subscription.yaml"
oc create -f tang_subscription.yaml
echo "-------------------------------------"
echo "oc project"
oc project
echo "-------------------------------------"
sleep 1
echo "oc get sub"
oc get sub
echo "-------------------------------------"
sleep 1
echo "oc get ip"
oc get ip
echo "-------------------------------------"
sleep 1
echo "oc get jobs -nopenshift-marketplace"
oc get jobs -nopenshift-marketplace
echo "-------------------------------------"
sleep 1
echo "oc get pods -nopenshift-marketplace"
oc get pods -nopenshift-marketplace
echo "-------------------------------------"
sleep 1
echo "oc get csv"
oc get csv
echo "-------------------------------------"
sleep 1
echo "oc get pods"
oc get pods
echo "-------------------------------------"
sleep 1
