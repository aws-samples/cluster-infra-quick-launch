#!/bin/bash

# easy-ssh.sh -c <node-group> <cluster-name>


# cluster_name=sm-hp-cluster-1
cluster_name=${CLUSTER_NAME}

controller_group_name=${cluster_name}-controller-group

chmod +x awsome-distributed-training/1.architectures/5.sagemaker-hyperpod/easy-ssh.sh
./awsome-distributed-training/1.architectures/5.sagemaker-hyperpod/easy-ssh.sh -c $controller_group_name $cluster_name

# sm-hp-cluster-1-controller-group sm-hp-cluster-1
