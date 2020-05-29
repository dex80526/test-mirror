#!/usr/bin/env bash
#Create EKS cluster using was eksctl:
if [ $# != 1 ]; then
        echo "Usage: $0 <cluster_name> " 
        exit 1
fi

eksctl create cluster \
        --name $1 \
        --version 1.15 \
        --region us-west-2 \
        --nodegroup-name "$1-workers" \
        --node-type m5.12xlarge \
        --nodes 3 --nodes-min 1 --nodes-max 21 \
        --ssh-access --ssh-public-key ${HOME}/.ssh/prow_id_rsa.pub \
        --managed

exit $?
~           
