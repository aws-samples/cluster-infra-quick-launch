#!/bin/bash

# must be run a sudo

set -x
set -e

# EFS Endpoints
BUCKET_NAME="$1"
MOUNT_POINT="/mount-s3"

export AWS_ACCESS_KEY_ID=AKIA-----------
export AWS_SECRET_ACCESS_KEY=---------------------------------
export AWS_DEFAULT_REGION=us-east-1

install_mountpoint_s3() {

  wget https://s3.amazonaws.com/mountpoint-s3-release/latest/x86_64/mount-s3.deb
  sudo apt-get install -y ./mount-s3.deb

}


mount_fs() {
  if [[ ! -d $MOUNT_POINT ]]; then
    sudo mkdir -p $MOUNT_POINT
    sudo chmod 777 $MOUNT_POINT
  fi

    /usr/bin/mount-s3  --allow-other --allow-delete  --allow-overwrite --maximum-throughput-gbps 100 --dir-mode 777 $BUCKET_NAME $MOUNT_POINT
    mount | grep mountpoint-s3

}



install_remount_service() {
  
  if [[ ! -d /opt/ml/scripts ]]; then
    mkdir -p /opt/ml/scripts
    chmod 644 /opt/ml/scripts
    echo "Created dir /opt/ml/scripts"
  fi

  CHECK_MOUNT_FILE=/opt/ml/scripts/check_mount_mount-s3.sh

  cat > $CHECK_MOUNT_FILE << EOF
#!/bin/bash
export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
export AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION

if ! grep -qs "mountpoint-s3" /proc/mounts; then
  /usr/bin/mount-s3  --allow-other --allow-delete  --allow-overwrite --maximum-throughput-gbps 100 --dir-mode 777 $BUCKET_NAME $MOUNT_POINT
  echo "mount-s3 mounted by check_service"

else
  systemctl stop check_mount_mount-s3.timer
  echo "mount-s3 already mounted"
fi
EOF

  chmod +x $CHECK_MOUNT_FILE

  cat > /etc/systemd/system/check_mount_mount-s3.service << EOF
[Unit]
Description=Mountpoint for Amazon S3 mount
Wants=network.target
AssertPathIsDirectory=$MOUNT_POINT

[Service]
Type=forking
User=root
Group=root
ExecStart=$CHECK_MOUNT_FILE
ExecStop=/usr/bin/fusermount -u $MOUNT_POINT

[Install]
WantedBy=remote-fs.target

EOF

  cat > /etc/systemd/system/check_mount_mount-s3.timer << EOF
[Unit]
Description=Run check_mount_mount-s3.service every minute

[Timer]
OnBootSec=1min
OnUnitActiveSec=1min

[Install]
WantedBy=timers.target
EOF

  systemctl daemon-reload
  systemctl start check_mount_mount-s3
  systemctl enable --now check_mount_mount-s3.timer
}

main() {

  install_mountpoint_s3
  mount_fs
  install_remount_service


}

main "$@"

