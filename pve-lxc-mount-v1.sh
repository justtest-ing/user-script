#!/bin/bash

# === Ask for container ID ===
read -p "🔢 Enter the LXC container VMID: " VMID

# === Check if container exists ===
if ! pct config "$VMID" &>/dev/null; then
  echo "❌ Container with VMID $VMID does not exist."
  exit 1
fi

# === Set general variables ===
SHARE_TYPE="cifs"                         # "nfs" or "cifs"
REMOTE_HOST="192.168.1.100"              # NFS/SMB server IP
REMOTE_PATH="//192.168.1.100/share"      # CIFS/Samba path

MOUNT_NAME="shared-data"
HOST_MOUNT="/mnt/remote/${MOUNT_NAME}"
LXC_MOUNT="/mnt/remote/${MOUNT_NAME}"

# For CIFS: enforce credentials file
CREDENTIALS_FILE="/root/.smbcredentials"

# Check container status and start if not running
STATUS=$(pct status "$VMID" | awk '{print $2}')
if [ "$STATUS" != "running" ]; then
    echo "🔄 Container $VMID is not running. Starting container..."
    pct start "$VMID"
    # Give it a moment to fully start
    sleep 3
fi

# === Detect UID inside container ===
echo "🔍 Detecting main non-root user inside container $VMID..."
MAIN_USER=$(pct exec "$VMID" -- getent passwd | awk -F: '$3 >= 1000 && $3 < 65534 {print $1; exit}')

if [[ -z "$MAIN_USER" ]]; then
  echo "⚠️ No non-root user found. Falling back to root"
  CONTAINER_UID=0
  CONTAINER_GID=0
else
  echo "👤 Found user: $MAIN_USER"
  CONTAINER_UID=$(pct exec "$VMID" -- id -u "$MAIN_USER")
  CONTAINER_GID=$(pct exec "$VMID" -- id -g "$MAIN_USER")
fi

MAPPED_UID=$((100000 + CONTAINER_UID))
MAPPED_GID=$((100000 + CONTAINER_GID))

echo "🔑 Container UID:GID = $CONTAINER_UID:$CONTAINER_GID"
echo "🔐 Host-mapped UID:GID = $MAPPED_UID:$MAPPED_GID"

# === Check credential file ===
if [ "$SHARE_TYPE" = "cifs" ]; then
  if [ ! -f "$CREDENTIALS_FILE" ]; then
    echo "❌ Credentials file not found at $CREDENTIALS_FILE"
    echo "📝 Create the file with:"
    echo "  username=youruser"
    echo "  password=yourpassword"
    exit 1
  fi

  if [ "$(stat -c %a "$CREDENTIALS_FILE")" != "600" ]; then
    echo "⚠️ Credentials file permissions are too loose. Fixing..."
    chmod 600 "$CREDENTIALS_FILE"
  fi
fi

# === Mount on host ===
echo "📁 Creating host mount directory: $HOST_MOUNT"
mkdir -p "$HOST_MOUNT"

echo "🔗 Mounting remote share..."
if [ "$SHARE_TYPE" = "nfs" ]; then
  apt install -y nfs-common
  mount -t nfs "${REMOTE_HOST}:${REMOTE_PATH}" "$HOST_MOUNT"
  FSTAB_ENTRY="${REMOTE_HOST}:${REMOTE_PATH} ${HOST_MOUNT} nfs defaults 0 0"
elif [ "$SHARE_TYPE" = "cifs" ]; then
  apt install -y cifs-utils
  mount -t cifs "$REMOTE_PATH" "$HOST_MOUNT" \
    -o credentials=$CREDENTIALS_FILE,uid=$MAPPED_UID,gid=$MAPPED_GID,iocharset=utf8
  FSTAB_ENTRY="${REMOTE_PATH} ${HOST_MOUNT} cifs credentials=${CREDENTIALS_FILE},uid=${MAPPED_UID},gid=${MAPPED_GID},iocharset=utf8 0 0"
else
  echo "❌ Invalid share type: $SHARE_TYPE"
  exit 1
fi

# === Add fstab entry if missing ===
if grep -qF "$HOST_MOUNT" /etc/fstab; then
  echo "ℹ️ fstab entry already exists for $HOST_MOUNT"
else
  echo "$FSTAB_ENTRY" >> /etc/fstab
  echo "✅ fstab entry added"
fi

# === Bind mount into LXC container ===
LXC_CONF="/etc/pve/lxc/${VMID}.conf"
MOUNT_LINE="mp0: ${HOST_MOUNT},mp=${LXC_MOUNT},ro=0"

if grep -qF "$HOST_MOUNT" "$LXC_CONF"; then
  echo "ℹ️ LXC config already contains mount for $HOST_MOUNT"
else
  echo "$MOUNT_LINE" >> "$LXC_CONF"
  echo "✅ LXC config updated"
fi

# === Restart container ===
echo "🔁 Restarting container $VMID..."
pct reboot "$VMID"

echo "🎉 Done!"
echo "📦 Remote share is available inside container at: $LXC_MOUNT"
