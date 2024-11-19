#!/bin/bash

# easy-ssh.sh -c <node-group> <cluster-name>

cluster_name=$(jq -r .ClusterName cluster-config.json)
login_group_name=$(jq -r '.InstanceGroups[0].InstanceGroupName' cluster-config.json)

chmod +x awsome-distributed-training/1.architectures/5.sagemaker-hyperpod/easy-ssh.sh
./awsome-distributed-training/1.architectures/5.sagemaker-hyperpod/easy-ssh.sh -c $login_group_name $cluster_name
