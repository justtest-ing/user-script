# Define the directory and file path for the docker-compose.yaml
TARGET_DIR="/mnt/appdata/dockge"
COMPOSE_FILE="$TARGET_DIR/compose.yaml"

# Create the directory if it doesn't exist
sudo mkdir -p "$TARGET_DIR"

# Write the YAML content into the docker-compose.yaml file
sudo cat << EOF > "$COMPOSE_FILE"
version: "3.8"
services:
  dockge:
    image: louislam/dockge:latest
    restart: unless-stopped
    ports:
      - 5001:5001
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /mnt/appdata/dockge/data:/app/data
      - /mnt/appdata:/mnt/appdata
    environment:
      # Tell Dockge where is your stacks directory
      - DOCKGE_STACKS_DIR=/mnt/appdata/
EOF
