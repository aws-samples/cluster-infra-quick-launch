#!/bin/bash

# must be run a sudo

set -x
set -e

# EFS Endpoints
EFS_FSID="$1"
USER_NAME="$2"
USER_GROUP_ID="$3"
MOUNT_POINT="$4"
AccessPointId="$5"


AWS_DEFAULT_REGION="us-east-1"

add_to_fstab() {
  # Add FSx to /etc/fstab
  sudo echo "$EFS_FSID.efs.$AWS_DEFAULT_REGION.amazonaws.com:/ $MOUNT_POINT efs accesspoint=$AccessPointId,tls,_netdev,noresvport,iam 0 0" | sudo tee -a /etc/fstab  
}

mount_fs() {
  if [[ ! -d $MOUNT_POINT ]]; then
    sudo mkdir -p $MOUNT_POINT
    sudo chmod 644 $MOUNT_POINT
  fi

  sudo mount -t efs -o noresvport,iam,tls,accesspoint=$AccessPointId $EFS_FSID.efs.$AWS_DEFAULT_REGION.amazonaws.com:/ $MOUNT_POINT
  mount | grep nfs

}


main() {

  add_to_fstab
  mount_fs
  df -h


}

main "$@"

