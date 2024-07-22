# create a systemd service to check mount periodically and remount efs if necessary
# To stop the service, run: 
# `systemctl stop check_mount.service`
# To disable the service, run:
# `systemctl disable check_mount.service`




install_remount_service() {
  
  if [[ ! -d /opt/ml/scripts ]]; then
    mkdir -p /opt/ml/scripts
    chmod 644 /opt/ml/scripts
    echo "Created dir /opt/ml/scripts"
  fi

  CHECK_MOUNT_FILE=/opt/ml/scripts/check_mount_efs.sh

  cat > $CHECK_MOUNT_FILE << EOF
#!/bin/bash
if ! grep -qs "127.0.0.1:/" /proc/mounts; then
  /usr/bin/mount -a
else
  systemctl stop check_efs_mount.timer
fi
EOF

  chmod +x $CHECK_MOUNT_FILE

  cat > /etc/systemd/system/check_efs_mount.service << EOF
[Unit]
Description=Check and remount efs filesystems if necessary

[Service]
ExecStart=$CHECK_MOUNT_FILE
EOF

  cat > /etc/systemd/system/check_efs_mount.timer << EOF
[Unit]
Description=Run check_efs_mount.service every minute

[Timer]
OnBootSec=1min
OnUnitActiveSec=1min

[Install]
WantedBy=timers.target
EOF

  systemctl daemon-reload
  systemctl enable --now check_efs_mount.timer
}

main() {
  install_remount_service
}

main "$@"
