#!/bin/bash


# jq 'del(.VpcConfig)' cluster-config.json > cluster-config-update.json


aws sagemaker update-cluster \
     --cli-input-json file://cluster-config-update.json \
     --region us-east-1