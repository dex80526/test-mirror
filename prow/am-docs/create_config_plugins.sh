#!/usr/bin/env bash
# create job-config of Prow using yaml files under test-infra/prow/cluster/jobs/
#
kubectl get configmap config >/dev/null 2>&1
if [ $? != 0 ]; then
  kubectl create configmap config --from-file=config.yaml=../config.yaml 
  kubectl create configmap plugins --from-file=plugins.yaml=../plugins.yaml
else
  kubectl create configmap config --from-file=config.yaml=../config.yaml --dry-run=client -o yaml | kubectl replace configmap config -f -
  kubectl create configmap plugins --from-file=plugins.yaml=../plugins.yaml --dry-run=client -o yaml |kubectl replace configmap plugins -f -
fi
