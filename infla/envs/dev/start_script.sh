#!/bin/bash
yum update -y
amazon-linux-extras install nginx1 -y # Instala o NGINX 1.x
systemctl start nginx
systemctl enable nginx