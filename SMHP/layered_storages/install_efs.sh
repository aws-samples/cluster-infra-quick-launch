#!/bin/bash

# must be run a sudo

set -x
set -e



export AWS_ACCESS_KEY_ID=AKIA-----------
export AWS_SECRET_ACCESS_KEY=---------------------------------
export AWS_DEFAULT_REGION=us-east-1




sudo apt-get update
sudo apt-get -y install git binutils rustc cargo pkg-config libssl-dev
git clone https://github.com/aws/efs-utils
cd efs-utils
./build-deb.sh
sudo apt-get -y install ./build/amazon-efs-utils*deb

