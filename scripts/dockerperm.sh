#!/bin/bash
sudo usermod -aG docker $USER
newgrp docker
groups $USER
sudo - u $USER docker ps
cat /etc/groups
