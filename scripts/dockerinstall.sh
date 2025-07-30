#!/bin/bash

# Get OS name reliably
OSName=$(grep -oP '(?<=^ID=).+' /etc/os-release | tr -d '"')

if [[ "$OSName" == "ubuntu" ]]; then
    echo "✅ Detected OS: Ubuntu"
    echo ""
    echo "================ Removing all Old Packages =================="
    for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do 
        sudo apt-get remove -y "$pkg"
    done
    echo "✅ Removed old Docker-related packages"
    echo ""

    echo "============ Setting up apt Repository ================"
    sudo apt-get update -y
    sudo apt-get install -y ca-certificates curl gnupg lsb-release

    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt-get update -y
    echo "✅ Docker repository configured"
    echo ""

    echo "============ Installing Docker Engine and Dependencies ==========="
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    echo "✅ Docker installed successfully"
    echo ""

    echo "============ Verifying Docker Installation ==========="
    sudo docker run hello-world

    echo "✅ Docker container ran successfully"
    echo ""
    sudo docker ps
    echo "✅ Docker is working"

    echo ""
    echo "👉 Optional: Add your user to the 'docker' group to avoid using sudo with docker"
    echo "Run this command and restart your session:"
    echo "    sudo usermod -aG docker \$USER"
    exit 1

elif [[ "$OSName" == "rocky" || "$OSName" == "rhel" ]]; then
    echo "Detected OS: Rocky Linux / RHEL"

    echo "=========== Removing Old Docker & Podman =========="
    sudo dnf remove -y docker \
                     docker-client \
                     docker-client-latest \
                     docker-common \
                     docker-latest \
                     docker-latest-logrotate \
                     docker-logrotate \
                     docker-engine \
                     podman \
                     runc

    echo "=========== Updating System =========="
    sudo dnf update -y

    echo "=========== Installing Docker Dependencies =========="
    sudo dnf -y install dnf-plugins-core curl gnupg

    echo "=========== Adding Docker Repo =========="
    sudo dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo

    echo "=========== Importing and Verifying GPG Key =========="
    curl -fsSL https://download.docker.com/linux/rhel/gpg | gpg --with-fingerprint

    echo
    echo "🧾 Expected Fingerprint:"
    echo "060A 61C5 1B55 8A7F 742B 77AA C52F EB6B 621E 9F35"
    read -p "❓ Does the key fingerprint match? (y/n): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "🚫 Aborting installation. GPG key mismatch."
        exit 1
    fi

    echo "✅ GPG Key verified. Proceeding..."

    echo "=========== Installing Docker =========="
    sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    echo "=========== Enabling Required Kernel Modules =========="
    sudo modprobe overlay
    sudo modprobe br_netfilter

    echo -e "overlay\nbr_netfilter" | sudo tee /etc/modules-load.d/docker.conf > /dev/null

    echo "=========== Starting Docker =========="
    sudo systemctl enable --now docker

    echo "=========== Docker Installation Complete =========="
    echo "Note: Docker is started and the required kernel modules are loaded."
    echo "Note: Current user is NOT added to the Docker group. Use:"
    echo "  sudo usermod -aG docker \$USER && newgrp docker"

else
    echo "❌ Unsupported OS: $OSName"
    exit 1
fi
