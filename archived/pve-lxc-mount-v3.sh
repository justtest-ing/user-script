#!/bin/bash
set -e

# === Helper: Confirm prompt ===
confirm() {
  read -p "❓ Proceed? (y/N): " CONFIRM
  [[ "$CONFIRM" =~ ^[Yy]$ ]]
}

# === Check for uninstall flag ===
if [[ "$1" == "--uninstall" ]]; then
  uninstall_mount
  exit 0
fi

# === Helper: Remove mount entry ===
uninstall_mount() {
  echo "🔢 Enter the LXC container VMID to uninstall from:"
  read -p "VMID: " VMID

  if ! pct config "$VMID" &>/dev/null; then
    echo "❌ Container with VMID $VMID does not exist."
    exit 1
  fi

  CONF_FILE="/etc/pve/lxc/${VMID}.conf"
  echo "📄 Looking for existing mount points in $CONF_FILE..."

  grep "^mp[0-9]*:" "$CONF_FILE" || {
    echo "⚠️ No mount points found in container config."
    exit 0
  }

  echo ""
  echo "🔍 Detected mount entries:"
  mapfile -t MOUNT_LINES < <(grep "^mp[0-9]*:" "$CONF_FILE")
  select ENTRY in "${MOUNT_LINES[@]}"; do
    if [[ -n "$ENTRY" ]]; then
      echo "✅ Selected: $ENTRY"
      sed -i "\|$ENTRY|d" "$CONF_FILE"

      # Remove mount from /etc/fstab
      HOST_PATH=$(echo "$ENTRY" | cut -d',' -f1 | cut -d':' -f2)
      echo "🧹 Cleaning up fstab..."
      sed -i "\|$HOST_PATH|d" /etc/fstab

      echo "🧹 Optionally remove the host folder $HOST_PATH"
      read -p "Delete host folder $HOST_PATH? (y/N): " DELFOLDER
      if [[ "$DELFOLDER" =~ ^[Yy]$ ]]; then
        rm -rf "$HOST_PATH"
        echo "🗑 Removed folder: $HOST_PATH"
      fi

      echo "🔁 Restarting container $VMID..."
      pct reboot "$VMID"

      echo "✅ Uninstallation complete!"
      exit 0
    else
      echo "❌ Invalid selection."
    fi
  done
}

# === Ask for container ID ===
read -p "🔢 Enter the LXC container VMID: " VMID

# === Check if container exists ===
if ! pct config "$VMID" &>/dev/null; then
  echo "❌ Container with VMID $VMID does not exist."
  exit 1
fi

# === Set general variables ===
SHARE_TYPE="cifs"
REMOTE_HOST="192.168.1.100"
REMOTE_PATH="//192.168.1.100/share"
MOUNT_NAME="shared-data"

HOST_MOUNT="/mnt/remote/${MOUNT_NAME}"
LXC_MOUNT="/mnt/remote/${MOUNT_NAME}"

CREDENTIALS_FILE="/root/.smbcredentials"

# === Show planned actions ===
echo ""
echo "🧾 Planned Setup:"
echo "🔹 Container VMID: $VMID"
echo "🔹 Share type: $SHARE_TYPE"
echo "🔹 Remote host: $REMOTE_HOST"
echo "🔹 Remote path: $REMOTE_PATH"
echo "🔹 Host mount path: $HOST_MOUNT"
echo "🔹 Container mount path: $LXC_MOUNT"
echo "🔹 Credentials file: $CREDENTIALS_FILE"
echo ""

confirm || { echo "❌ Aborted by user."; exit 1; }

# === Ensure container is running ===
STATUS=$(pct status "$VMID" | awk '{print $2}')
if [ "$STATUS" != "running" ]; then
  echo "🔄 Starting container $VMID..."
  pct start "$VMID"
  sleep 3
fi

# === Detect UID/GID ===
echo "🔍 Detecting main non-root user inside container..."
MAIN_USER=$(pct exec "$VMID" -- getent passwd | awk -F: '$3 >= 1000 && $3 < 65534 {print $1; exit}')
if [[ -z "$MAIN_USER" ]]; then
  echo "⚠️ No non-root user found. Using root (0)"
  CONTAINER_UID=0
  CONTAINER_GID=0
else
  echo "👤 Found user: $MAIN_USER"
  CONTAINER_UID=$(pct exec "$VMID" -- id -u "$MAIN_USER")
  CONTAINER_GID=$(pct exec "$VMID" -- id -g "$MAIN_USER")
fi

MAPPED_UID=$((100000 + CONTAINER_UID))
MAPPED_GID=$((100000 + CONTAINER_GID))

echo "🔐 Mapped UID:GID = $MAPPED_UID:$MAPPED_GID"

# === Check credential file ===
if [ "$SHARE_TYPE" = "cifs" ]; then
  if [ ! -f "$CREDENTIALS_FILE" ]; then
    echo "❌ Credentials file not found at $CREDENTIALS_FILE"
    echo "📝 Create it with:"
    echo "  username=youruser"
    echo "  password=yourpassword"
    exit 1
  fi
  chmod 600 "$CREDENTIALS_FILE"
fi

# === Mount share ===
echo "📁 Creating host mount folder..."
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
  echo "❌ Unknown share type: $SHARE_TYPE"
  exit 1
fi

# === Persist mount in fstab ===
if ! grep -qF "$HOST_MOUNT" /etc/fstab; then
  echo "$FSTAB_ENTRY" >> /etc/fstab
  echo "✅ Added to /etc/fstab"
else
  echo "ℹ️ fstab already contains entry for $HOST_MOUNT"
fi

# === Add LXC bind mount ===
LXC_CONF="/etc/pve/lxc/${VMID}.conf"
MOUNT_LINE="mp0: ${HOST_MOUNT},mp=${LXC_MOUNT},ro=0"

if ! grep -qF "$HOST_MOUNT" "$LXC_CONF"; then
  echo "$MOUNT_LINE" >> "$LXC_CONF"
  echo "✅ Added bind mount to container config"
else
  echo "ℹ️ LXC config already contains mount for $HOST_MOUNT"
fi

# === Reboot container ===
echo "🔁 Restarting container $VMID..."
pct reboot "$VMID"

echo "🎉 Done! Share mounted inside container at: $LXC_MOUNT"
