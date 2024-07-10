#!/bin/bash

export AWS_REGION=$(aws configure get region)

aws sagemaker create-cluster \
    --cli-input-json file://cluster-config.json \
    --region $AWS_REGION


echo `aws sagemaker list-clusters --output table`