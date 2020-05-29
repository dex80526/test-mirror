##
# This script config and deploy Istio Prow resources
# It needs to be run after K8S secrects are created (see create_secrects.sh)#
#
# Create Persistent Volume using EFS (prow/cluster/build/aws_buildcache.yaml)
	#EFS is created via aws cli or console by following AWS EFS instructions
kubectl apply -f ../cluster/build/aws_buildcache.yaml

# tune sysctls 
kubectl apply -f ../cluster/build/tune-sysctls_daemonset.yaml

## bootstrap config and plugins -- Add/create configmaps of config, plugins and job-config  
./create_config_plugins.sh
## bootstrap configmap job-config
./create_am_jobconfig.sh
#
# deploy Prow resuources
kubectl apply -f ../cluster/aspenmesh/
