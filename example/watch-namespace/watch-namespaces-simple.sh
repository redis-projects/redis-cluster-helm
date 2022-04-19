#!/bin/bash

echo "Creating Namespace 'redis-test"
oc new-project redis-test

echo "Applying Role to 'redis-test'"
oc create -f role.yaml -n redis-test

echo "Applying Role to 'redis-test"
oc create -f role_binding.yaml -n redis-test

NAMESPACES=$(oc get configmap/operator-environment-config -n redis -o jsonpath="{.data['REDB_NAMESPACES']}")

echo "Current $NAMESPACES"
NAMESPACES="${NAMESPACES},redis-test"
echo "New redis watched namespaces list:  '${NAMESPACES}' "

NAMESPACES_FINAL="\x27{\x22data\x22:{\x22REDB_NAMESPACES\x22:\x22${NAMESPACES}\x22}}\x27"
echo -e "Final Patch Command: ${NAMESPACES_FINAL}"

echo "Patching the Redis Operator in 'redis' namespace to watch 'redis-test'"
oc patch configmap/operator-environment-config \
  -n redis \
  --type merge \
  -p "{\"data\":{\"REDB_NAMESPACES\":\"${NAMESPACES}\"}}"

echo "Redis Operator now watching namespaces :: $(oc get configmap/operator-environment-config -n redis -o jsonpath="{.data['REDB_NAMESPACES']}")"

