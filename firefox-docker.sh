#!/bin/bash

# Function to check for command existence
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Function to install Docker
install_docker() {
  echo "Installing Docker..."
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if command_exists pacman; then
      sudo pacman -Syu --noconfirm docker
    elif command_exists apt; then
      sudo apt update
      sudo apt install -y docker.io
    elif command_exists yum; then
      sudo yum install -y docker
    else
      echo "Unsupported package manager. Install Docker manually."
      exit 1
    fi
  else
    echo "Unsupported OS. Install Docker manually."
    exit 1
  fi
  sudo systemctl start docker
  sudo systemctl enable docker
  echo "Docker installed and running."
}

# Function to install Cloudflared
install_cloudflared() {
  echo "Installing Cloudflared..."
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if command_exists pacman; then
      sudo pacman -Syu --noconfirm cloudflared
    elif command_exists apt; then
      wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
      sudo dpkg -i cloudflared-linux-amd64.deb
      rm cloudflared-linux-amd64.deb
    elif command_exists yum; then
      wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.rpm
      sudo rpm -i cloudflared-linux-amd64.rpm
      rm cloudflared-linux-amd64.rpm
    else
      echo "Unsupported package manager. Install Cloudflared manually."
      exit 1
    fi
  else
    echo "Unsupported OS. Install Cloudflared manually."
    exit 1
  fi
  echo "Cloudflared installed."
}

# Check if Docker is installed
if ! command_exists docker; then
  install_docker
else
  echo "Docker is already installed."
fi

# Check if Cloudflared is installed
if ! command_exists cloudflared; then
  install_cloudflared
else
  echo "Cloudflared is already installed."
fi

docker run -d \
  --name=firefox \
  --security-opt seccomp=unconfined `#optional` \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=Etc/UTC \
  -e FIREFOX_CLI=https://www.duckduckgo.com/ `#optional` \
  -p 3000:3000 \
  -p 3001:3001 \
  --shm-size="1gb" \
  --restart unless-stopped \
  lscr.io/linuxserver/firefox:latest

echo "Exposing port 3000 with Cloudflared..."
cloudflared tunnel --url http://localhost:3000
