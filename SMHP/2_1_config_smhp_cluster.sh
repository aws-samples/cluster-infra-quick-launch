#!/bin/bash

export CONFIG_S3_BUCKET_NAME=YOUR_BUCKET_NAME
export CLUSTER_NAME=smhp-cluster-1

## AWS role arn for Hyperpod
export ROLE=arn:aws:iam::633205212955:role/ec2-adm-role

export CTRL_INSTANCE_TYPE=ml.c5.4xlarge
export INSTANCE_TYPE=ml.g5.4xlarge
export INSTANCE_COUNT=2
export VPC_ID=vpc-01607238f9a0e2cce
export SUBNET_ID=subnet-050c2bfcbd496bee5
export FSX_ID=fs-028893dcc052a6227
export FSX_MOUNTNAME=yvoarb4v
export SECURITY_GROUP=sg-01554433484158c48
# export EFS_ID=YOUR_EFS_ID e.g. fs-0fab9839d7e9a538b
# export MOUNT_S3_BUCKET_NAME=YOUR_MOUNT_S3_BUCKET_NAME


export LIFECYCLE_CONF_S3_PATH=s3://${CONFIG_S3_BUCKET_NAME}/${CLUSTER_NAME}-confs/
export AWS_REGION=$(aws configure get region)

cat > cluster-config.json << EOL
{
    "ClusterName": "${CLUSTER_NAME}",
    "InstanceGroups": [
      {
        "InstanceGroupName": "${CLUSTER_NAME}-login-node",
        "InstanceType": "${CTRL_INSTANCE_TYPE}",
        "InstanceStorageConfigs": [
          {
            "EbsVolumeConfig": {
              "VolumeSizeInGB": 500
            }
          }
        ],
        "InstanceCount": 1,
        "LifeCycleConfig": {
          "SourceS3Uri": "${LIFECYCLE_CONF_S3_PATH}",
          "OnCreate": "on_create.sh"
        },
        "ExecutionRole": "${ROLE}",
        "ThreadsPerCore": 2
      },
      {
        "InstanceGroupName": "${CLUSTER_NAME}-controller-node",
        "InstanceType": "${CTRL_INSTANCE_TYPE}",
        "InstanceStorageConfigs": [
          {
            "EbsVolumeConfig": {
              "VolumeSizeInGB": 500
            }
          }
        ],
        "InstanceCount": 1,
        "LifeCycleConfig": {
          "SourceS3Uri": "${LIFECYCLE_CONF_S3_PATH}",
          "OnCreate": "on_create.sh"
        },
        "ExecutionRole": "${ROLE}",
        "ThreadsPerCore": 2
      },
      {
        "InstanceGroupName": "${CLUSTER_NAME}-worker-group-1",
        "InstanceType": "${INSTANCE_TYPE}",
        "InstanceCount": ${INSTANCE_COUNT},
        "InstanceStorageConfigs": [
          {
            "EbsVolumeConfig": {
              "VolumeSizeInGB": 500
            }
          }
        ],
        "LifeCycleConfig": {
          "SourceS3Uri": "${LIFECYCLE_CONF_S3_PATH}",
          "OnCreate": "on_create.sh"
        },
        "ExecutionRole": "${ROLE}",
        "ThreadsPerCore": 2
      }
    ],
    "VpcConfig": {
      "SecurityGroupIds": ["$SECURITY_GROUP"],
      "Subnets":["$SUBNET_ID"]
    }
}
EOL


login_group_name=$(cat cluster-config.json | jq '.InstanceGroups[0].InstanceGroupName')
controller_group_name=$(cat cluster-config.json | jq '.InstanceGroups[1].InstanceGroupName')
worker_group_name=$(cat cluster-config.json | jq '.InstanceGroups[2].InstanceGroupName')
instance_type=$(cat cluster-config.json | jq '.InstanceGroups[1].InstanceType')



cat > provisioning_parameters.json << EOL
{
  "version": "1.0.0",
  "workload_manager": "slurm",
  "controller_group": ${controller_group_name},
  "login_group": ${login_group_name},
  "worker_groups": [
    {
      "instance_group_name": ${worker_group_name},
      "partition_name": ${instance_type}
    }
  ],
  "fsx_dns_name": "${FSX_ID}.fsx.${AWS_REGION}.amazonaws.com",
  "fsx_mountname": "${FSX_MOUNTNAME}"
}
EOL

## Add to provisioning_parameters.json if need EFS for visibility control
  # "efs_id": "${EFS_ID}",
  # "bucketname": "${MOUNT_S3_BUCKET_NAME}"

aws s3 cp awsome-distributed-training/1.architectures/5.sagemaker-hyperpod/LifecycleScripts/base-config ${LIFECYCLE_CONF_S3_PATH} --recursive
aws s3 cp provisioning_parameters.json ${LIFECYCLE_CONF_S3_PATH}
# aws s3 cp layered_storages ${LIFECYCLE_CONF_S3_PATH} --recursive

# Change configs in - 
# awsome-distributed-training/1.architectures/5.sagemaker-hyperpod/LifecycleScripts/base-config/config.py


python3 awsome-distributed-training/1.architectures/5.sagemaker-hyperpod/validate-config.py \
	--cluster-config cluster-config.json \
	--provisioning-parameters provisioning_parameters.json
