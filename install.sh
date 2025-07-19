#!/bin/bash

echo "🛠️ Chromium Docker Kasm Installer"
echo "-------------------------------"

# 🔐 Ask for username and password
read -p "Enter Chromium login username [default: admin]: " CUSTOM_USER
read -s -p "Enter Chromium login password [default: pass123]: " PASSWORD
echo

# Set defaults if empty
CUSTOM_USER=${CUSTOM_USER:-admin}
PASSWORD=${PASSWORD:-pass123}

# 🌐 Get public IP
PUBLIC_IP=$(curl -s ifconfig.me || curl -s ipinfo.io/ip || hostname -I | awk '{print $1}')

echo "🔧 Updating system and removing old Docker packages..."
sudo apt update -y && sudo apt upgrade -y
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
    sudo apt-get remove -y $pkg
done

echo "🐳 Installing Docker..."
sudo apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "📁 Setting up Chromium Docker container (Kasm VNC version)..."
mkdir -p ~/chromium && cd ~/chromium

cat <<EOF > docker-compose.yaml
services:
  chromium:
    image: lscr.io/linuxserver/chromium:kasm
    container_name: chromium
    security_opt:
      - seccomp:unconfined
    environment:
      - CUSTOM_USER=${CUSTOM_USER}
      - PASSWORD=${PASSWORD}
      - PUID=1000
      - PGID=1000
      - TZ=Asia/Kolkata
      - CHROME_CLI=https://google.com
    volumes:
      - ~/chromium/config:/config
    ports:
      - 3010:3000
      - 3011:3001
    shm_size: "1gb"
    restart: unless-stopped
EOF

echo "🚀 Launching Chromium container..."
sudo docker compose up -d

echo ""
echo "🎉 Chromium is now running!"
echo "👉 Open: http://${PUBLIC_IP}:3010"
echo "🔐 Login:"
echo "   Username: ${CUSTOM_USER}"
echo "   Password: ${PASSWORD}"
echo ""
echo "💡 Script created by ask.rohitsen"
echo "🐦 Follow on Twitter: https://twitter.com/ask_rohitsen"
