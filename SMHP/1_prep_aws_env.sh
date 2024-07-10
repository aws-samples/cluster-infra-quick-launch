aws configure

pip3 install -U boto3 omegaconf

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install --update

# https://docs.aws.amazon.com/systems-manager/latest/userguide/install-plugin-debian-and-ubuntu.html
echo "--Install SSM on Ubuntu--"
curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb"
sudo dpkg -i session-manager-plugin.deb
echo `session-manager-plugin`

echo "--Check aws cli version--"
echo `aws --version`

echo "--Check aws cli command for HyperPod cluster--"
echo `aws sagemaker help | grep cluster`

git clone https://github.com/aws-samples/awsome-distributed-training/

# c9 ubuntu env
# sudo apt update
# sudo apt install jq -y

# change lifecycle config if need
# awsome-distributed-training/1.architectures/5.sagemaker-hyperpod/LifecycleScripts/base-config/config.py
