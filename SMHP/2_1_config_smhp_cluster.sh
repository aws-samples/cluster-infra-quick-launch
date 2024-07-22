#!/bin/bash

###############
## export AWS_REGION=us-west-2
## export INSTANCES=g5.12xlarge
## export VPC_ID=vpc-0a53ef2f27b1a7593
## export SUBNET_ID=subnet-068d440c0547a14d9
## export FSX_ID=fs-0505889b9c83939e0
## export FSX_MOUNTNAME=ub2ejbev
## export SECURITY_GROUP=sg-07b82de9f3afed48d
## export ROLE=arn:aws:iam::xxxxx:role/sagemakervpc-AmazonSagemakerClusterExecutionRole-xxxxxx
## export ROLENAME=sagemakervpc-AmazonSagemakerClusterExecutionRole-xxxxxx
## export BUCKET=sagemaker-lifecycle-xxxxxxxx
###############


CONFIG_S3_BUCKET_NAME=YOUR_BUCKET_NAME
CLUSTER_NAME=smhp-cluster-1

## AWS role arn for Hyperpod
export ROLE=arn:aws:iam::123456789123:role/service-role/AmazonSageMaker-ExecutionRole-20220923T160810
## AWS role name for Hyperpod
export ROLENAME=AmazonSageMaker-ExecutionRole-20220923T160810

export CTRL_INSTANCE_TYPE=ml.c5.4xlarge
export INSTANCE_TYPE=ml.g5.2xlarge
export INSTANCE_COUNT=1
export VPC_ID=vpc-01607238f9a0e2cce
export SUBNET_ID=subnet-050c2bfcbd496bee5
export FSX_ID=fs-028893dcc052a6227
export FSX_MOUNTNAME=yvoarb4v
export SECURITY_GROUP=sg-01554433484158c48
export EFS_ID=fs-0fab9839d7e9a538b
export MOUNT_S3_BUCKET_NAME=YOUR_MOUNT_S3_BUCKET_NAME

# Member must satisfy enum value set: [ml.m5.4xlarge, ml.trn1.32xlarge, ml.p5.48xlarge, ml.p4d.24xlarge, ml.t3.xlarge, ml.m5.8xlarge, ml.m5.large, ml.g5.2xlarge, ml.g5.4xlarge, ml.c5.2xlarge, ml.c5.4xlarge, ml.g5.8xlarge, ml.c5n.18xlarge, ml.c5.large, ml.c5.9xlarge, ml.c5.xlarge, ml.c5.12xlarge, ml.c5.24xlarge, ml.trn1n.32xlarge, ml.c5n.2xlarge, ml.g5.xlarge, ml.t3.2xlarge, ml.t3.medium, ml.g5.12xlarge, ml.c5n.4xlarge, ml.g5.24xlarge, ml.c5.18xlarge, ml.g5.48xlarge, ml.g5.16xlarge, ml.m5.xlarge, ml.c5n.large, ml.t3.large, ml.m5.12xlarge, ml.c5n.9xlarge, ml.m5.24xlarge, ml.m5.2xlarge, ml.m5.16xlarge, ml.p4de.24xlarge]
### 

export LIFECYCLE_CONF_S3_PATH=s3://${CONFIG_S3_BUCKET_NAME}/${CLUSTER_NAME}-confs/
export AWS_REGION=$(aws configure get region)

cat > cluster-config.json << EOL
{
    "ClusterName": "${CLUSTER_NAME}",
    "InstanceGroups": [
      {
        "InstanceGroupName": "${CLUSTER_NAME}-controller-group",
        "InstanceType": "${CTRL_INSTANCE_TYPE}",
        "InstanceCount": 1,
        "LifeCycleConfig": {
          "SourceS3Uri": "${LIFECYCLE_CONF_S3_PATH}",
          "OnCreate": "on_create.sh"
        },
        "ExecutionRole": "${ROLE}",
        "ThreadsPerCore": 1
      },
      {
        "InstanceGroupName": "${CLUSTER_NAME}-worker-group",
        "InstanceType": "${INSTANCE_TYPE}",
        "InstanceCount": ${INSTANCE_COUNT},
        "LifeCycleConfig": {
          "SourceS3Uri": "${LIFECYCLE_CONF_S3_PATH}",
          "OnCreate": "on_create.sh"
        },
        "ExecutionRole": "${ROLE}",
        "ThreadsPerCore": 1
      }
    ],
    "VpcConfig": {
      "SecurityGroupIds": ["$SECURITY_GROUP"],
      "Subnets":["$SUBNET_ID"]
    }
}
EOL


controller_group_name=$(cat cluster-config.json | jq '.InstanceGroups[0].InstanceGroupName')
worker_group_name=$(cat cluster-config.json | jq '.InstanceGroups[1].InstanceGroupName')
instance_type=$(cat cluster-config.json | jq '.InstanceGroups[1].InstanceType')

cat > provisioning_parameters.json << EOL
{
  "version": "1.0.0",
  "workload_manager": "slurm",
  "controller_group": ${controller_group_name},
  "worker_groups": [
    {
      "instance_group_name": ${worker_group_name},
      "partition_name": ${instance_type}
    }
  ],
  "fsx_dns_name": "${FSX_ID}.fsx.${AWS_REGION}.amazonaws.com",
  "fsx_mountname": "${FSX_MOUNTNAME}",
  "efs_id": "${EFS_ID}",
  "bucketname": "${MOUNT_S3_BUCKET_NAME}"
}
EOL

aws s3 cp awsome-distributed-training/1.architectures/5.sagemaker-hyperpod/LifecycleScripts/base-config ${LIFECYCLE_CONF_S3_PATH} --recursive
aws s3 cp provisioning_parameters.json ${LIFECYCLE_CONF_S3_PATH}
aws s3 cp layered_storages ${LIFECYCLE_CONF_S3_PATH} --recursive

python3 awsome-distributed-training/1.architectures/5.sagemaker-hyperpod/validate-config.py \
	--cluster-config cluster-config.json \
	--provisioning-parameters provisioning_parameters.json
	
