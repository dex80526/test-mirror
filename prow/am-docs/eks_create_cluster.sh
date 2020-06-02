#!/usr/bin/env bash
#Note: To create a cluster with a dedicated managed node group for each Availability Zonee
#Create EKS cluster using AWS eksctl:
if [ $# != 1 ]; then
        echo "Usage: $0 <cluster_name> " 
        exit 1
fi

eksctl create cluster --name $1 --version 1.15 --without-nodegroup

echo "Take notes on the standout of the above command about the abvailabily zones and subnets"
echo "like the following:"
echo "[ℹ]  setting availability zones to [region-codea region-codec region-codeb]"
echo "[ℹ]  subnets for region-codea - public:192.168.0.0/19 private:192.168.96.0/19"
echo "[ℹ]  subnets for region-codec - public:192.168.32.0/19 private:192.168.128.0/19"
echo "[ℹ]  subnets for region-codeb - public:192.168.64.0/19 private:192.168.160.0/19"
echo " Go to AWS console and find those subnets and enable 'Auto Assign IPv4 address'"
echo "Continue to create node groups for each avaibiliy zone listed in the above"
echo "eksctl create nodegroup --cluster $1 --node-zones <region-codea> --name <region-codea> --asg-access --node-type m5.12xlarge --node-volume-size 60 --nodes-min 1 --nodes 5 --nodes-max 10 --managed --ssh-access --ssh-public-key ${HOME}/.ssh/prow_id_rsa.pub "
