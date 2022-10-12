#!/bin/bash

sudo yum update -y
sudo amazon-linux-extras install docker
sudo systemctl start docker
sudo usermod -aG docker ec2-user
sudo chkconfig docker on
sudo docker run -itd --name nginxapp -p 8080:80 nginx