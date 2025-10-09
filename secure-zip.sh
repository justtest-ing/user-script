#!/bin/bash
# ------------------------------------------------------------
# Securely compress a directory with 7zip and password protect it
# Output file: ~/YYYYMMDD-<directoryname>.7z
# ------------------------------------------------------------

# Ensure 7zip is installed
if ! command -v 7z &> /dev/null; then
    echo "[INFO] 7zip not found. Installing..."
    sudo apt update -y && sudo apt install -y p7zip-full
fi

# Prompt for directory
read -rp "Enter the full path to the directory you want to compress: " DIR

# Check if directory exists
if [[ ! -d "$DIR" ]]; then
  echo "❌ Error: Directory '$DIR' not found."
  exit 1
fi

# Prompt for password (silent)
read -rsp "Enter password for the archive: " PASS
echo
read -rsp "Confirm password: " PASS2
echo

# Check passwords match
if [[ "$PASS" != "$PASS2" ]]; then
  echo "❌ Passwords do not match."
  exit 1
fi

# Determine output path (real user home, even under sudo)
if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
    user_home=$(eval echo "~$SUDO_USER")
else
    user_home="$HOME"
fi

# Extract directory name (no trailing slash)
BASENAME=$(basename "$DIR")

# Generate date-based filename
DATE=$(date +%Y%m%d)
OUTFILE="${user_home}/${DATE}-${BASENAME}.7z"

# Compress and encrypt
echo "🔐 Creating password-protected archive..."
7z a -t7z -mhe=on -p"$PASS" "$OUTFILE" "$DIR" >/dev/null

# Check success
if [[ $? -eq 0 ]]; then
  echo "[SUCCESS] Archive created successfully:"
  echo "   $OUTFILE"
else
  echo "[ERROR] Failed to create archive."
  exit 1
fi