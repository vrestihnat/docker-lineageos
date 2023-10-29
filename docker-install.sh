#!/bin/bash -li
#ubuntu 20.04

sudo apt update -y
sudo apt install ca-certificates curl gnupg lsb-release
sudo mkdir /etc/apt/demokeyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/demokeyrings/demodocker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/demokeyrings/demodocker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list
sudo apt update -y
sudo apt install docker-ce docker-ce-cli containerd.io docker-compose-plugin

sudo usermod -aG docker ${USER}
sudo systemctl status docker
sudo systemctl start containerd
sudo systemctl enable containerd
sudo systemctl status containerd
systemctl is-enabled containerd.service

docker --version; docker compose version;sudo ctr version
