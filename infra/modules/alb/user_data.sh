#!/bin/bash

# Define variables passed from Terraform
EFS_FS_ID="${efs_file_system_id}"
AWS_REGION="${aws_region}"
PROJECT_NAME="${project_name}"
ENVIRONMENT="${environment}"
EFS_MOUNT_POINT="/mnt/efs"
NGINX_HTML_PATH_ON_EFS="$${EFS_MOUNT_POINT}/$${PROJECT_NAME}/html"

# EFS DNS name for regional access
EFS_DNS="$${EFS_FS_ID}.efs.$${AWS_REGION}.amazonaws.com"

echo "### Starting user-data script for $${PROJECT_NAME} - $${ENVIRONMENT} ###"

# --- EFS Mounting ---
echo "Attempting to mount EFS $${EFS_DNS} to $${EFS_MOUNT_POINT}"

sudo mkdir -p "$${EFS_MOUNT_POINT}"

if ! mountpoint -q "$${EFS_MOUNT_POINT}"; then
    echo "EFS not mounted yet. Attempting to mount..."
    sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport "$${EFS_DNS}:/" "$${EFS_MOUNT_POINT}"
    if [ $? -eq 0 ]; then
        echo "EFS mounted successfully."
    else
        echo "Error: Failed to mount EFS. Nginx will not function without EFS."
        exit 1
    fi
else
    echo "EFS already mounted at $${EFS_MOUNT_POINT}."
fi

# --- Nginx Content and Permissions on EFS ---

# Ensure project and HTML directories exist on EFS.
sudo mkdir -p "$${EFS_MOUNT_POINT}/$${PROJECT_NAME}"
sudo mkdir -p "$${NGINX_HTML_PATH_ON_EFS}"
echo "Ensured Nginx HTML path on EFS exists: $${NGINX_HTML_PATH_ON_EFS}"

NGINX_USER="nginx"

echo "Setting ownership and permissions for Nginx user: $${NGINX_USER} on EFS path: $${NGINX_HTML_PATH_ON_EFS}"
sudo chown -R $${NGINX_USER}:$${NGINX_USER} "$${EFS_MOUNT_POINT}" 
sudo chmod 755 "$${EFS_MOUNT_POINT}" 

sudo chown -R $${NGINX_USER}:$${NGINX_USER} "$${EFS_MOUNT_POINT}/$${PROJECT_NAME}"
sudo chmod 755 "$${EFS_MOUNT_POINT}/$${PROJECT_NAME}" 

sudo chown -R $${NGINX_USER}:$${NGINX_USER} "$${NGINX_HTML_PATH_ON_EFS}"
sudo chmod -R 755 "$${NGINX_HTML_PATH_ON_EFS}"

# --- Nginx Symbolic Link ---

# Remove the original /usr/share/nginx/html if it's a directory (not a symlink)
# This is crucial so we can create the symlink in its place.
if [ -d "/usr/share/nginx/html" ] && [ ! -L "/usr/share/nginx/html" ]; then
    echo "Removing original /usr/share/nginx/html directory to create symlink."
    sudo rm -rf /usr/share/nginx/html
fi

# Create or update the symbolic link.
# We ensure /usr/share/nginx/html *is* the symlink, not a directory containing one.
if [ ! -L "/usr/share/nginx/html" ]; then
    echo "Creating symbolic link from /usr/share/nginx/html to $${NGINX_HTML_PATH_ON_EFS}."
    sudo ln -s "$${NGINX_HTML_PATH_ON_EFS}" /usr/share/nginx/html
elif [ "$(readlink -f /usr/share/nginx/html)" != "$(readlink -f "$${NGINX_HTML_PATH_ON_EFS}")" ]; then
    echo "Existing symlink /usr/share/nginx/html points to wrong location. Recreating."
    sudo rm /usr/share/nginx/html
    sudo ln -s "$${NGINX_HTML_PATH_ON_EFS}" /usr/share/nginx/html
else
    echo "Symbolic link /usr/share/nginx/html already exists and is correct."
fi

# --- Write HTML content to EFS (English Version) ---
if [ ! -f "$${NGINX_HTML_PATH_ON_EFS}/index.html" ]; then
    echo "Creating default index.html (English) on EFS using tee."
    sudo tee "$${NGINX_HTML_PATH_ON_EFS}/index.html" > /dev/null <<EOF_HTML_EN
        <!DOCTYPE html>
        <html lang="en">

        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>$${PROJECT_NAME} &mdash; $${ENVIRONMENT}</title>
            <style>
                body {
                    font-family: 'Segoe UI', Arial, sans-serif;
                    margin: 0;
                    padding: 0;
                    background: linear-gradient(135deg, #e9f0fa 0%, #f4f4f4 100%);
                    color: #222;
                    min-height: 100vh;
                    display: flex;
                    flex-direction: column;
                }

                .container {
                    flex: 1;
                    display: flex;
                    flex-direction: column;
                    justify-content: center;
                    align-items: center;
                }

                .card {
                    background: #fff;
                    border-radius: 12px;
                    box-shadow: 0 4px 24px rgba(0, 86, 179, 0.08), 0 1.5px 4px rgba(0, 0, 0, 0.04);
                    padding: 40px 32px 32px 32px;
                    max-width: 520px;
                    width: 100%;
                    margin: 40px 16px;
                    text-align: center;
                }

                h1 {
                    color: #0056b3;
                    font-size: 2.2rem;
                    margin-bottom: 0.5em;
                    letter-spacing: -1px;
                }

                .subtitle {
                    color: #2d6ca2;
                    font-size: 1.1rem;
                    margin-bottom: 1.5em;
                    font-weight: 500;
                }

                ul {
                    text-align: left;
                    margin: 1.5em 0 2em 0;
                    padding-left: 1.2em;
                    color: #444;
                    font-size: 1rem;
                }

                ul li {
                    margin-bottom: 0.7em;
                    line-height: 1.5;
                }

                .env {
                    display: inline-block;
                    background: #e3f0ff;
                    color: #0056b3;
                    border-radius: 6px;
                    padding: 0.3em 0.9em;
                    font-size: 0.98em;
                    font-weight: 600;
                    margin-top: 1.2em;
                    letter-spacing: 0.5px;
                }

                .lang-switch {
                    margin-top: 1.5em;
                    font-size: 0.98em;
                }

                .lang-switch a {
                    color: #0056b3;
                    text-decoration: none;
                    font-weight: 500;
                    border-bottom: 1px dotted #0056b3;
                    transition: border 0.2s;
                }

                .lang-switch a:hover {
                    border-bottom: 1px solid #0056b3;
                }

                footer {
                    text-align: center;
                    color: #888;
                    font-size: 0.95em;
                    padding: 18px 0 10px 0;
                    letter-spacing: 0.5px;
                }
            </style>
        </head>

        <body>
            <div class="container">
                <div class="card">
                    <h1>$${PROJECT_NAME}</h1>
                    <div class="subtitle">AWS NGINX Application</div>
                    <ul>
                        <li>Automated infrastructure with <strong>Terraform</strong></li>
                        <li>Scalability and high availability via <strong>Auto Scaling</strong> and <strong>Load Balancer</strong></li>
                        <li>Shared content on <strong>Amazon EFS</strong></li>
                        <li>Consistent image built with <strong>Packer</strong></li>
                    </ul>
                    <div class="env">Environment: $${ENVIRONMENT}</div>
                    <div class="lang-switch">
                        <a href="index.pt-br.html" lang="pt-BR">Versão em Português</a>
                    </div>
                </div>
            </div>
            <footer>
                &copy; andresinho20049 &mdash; Cloud Architecture Demo
            </footer>
        </body>

        </html>
EOF_HTML_EN

    # Ensure correct permissions for the created index.html file
    sudo chmod 644 "$${NGINX_HTML_PATH_ON_EFS}/index.html"
    sudo chown $${NGINX_USER}:$${NGINX_USER} "$${NGINX_HTML_PATH_ON_EFS}/index.html"
    echo "Default index.html (English) created and permissions set on EFS."
else
    echo "index.html (English) already exists on EFS. Skipping default content creation."
fi

# --- Write HTML content to EFS (Portuguese Version) ---
if [ ! -f "$${NGINX_HTML_PATH_ON_EFS}/index.pt-br.html" ]; then
    echo "Creating index.pt-br.html (Portuguese) on EFS using tee."
    sudo tee "$${NGINX_HTML_PATH_ON_EFS}/index.pt-br.html" > /dev/null <<EOF_HTML_PTBR
        <!DOCTYPE html>
        <html lang="pt-BR">

        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>$${PROJECT_NAME} &mdash; $${ENVIRONMENT}</title>
            <style>
                body {
                    font-family: 'Segoe UI', Arial, sans-serif;
                    margin: 0;
                    padding: 0;
                    background: linear-gradient(135deg, #e9f0fa 0%, #f4f4f4 100%);
                    color: #222;
                    min-height: 100vh;
                    display: flex;
                    flex-direction: column;
                }

                .container {
                    flex: 1;
                    display: flex;
                    flex-direction: column;
                    justify-content: center;
                    align-items: center;
                }

                .card {
                    background: #fff;
                    border-radius: 12px;
                    box-shadow: 0 4px 24px rgba(0, 86, 179, 0.08), 0 1.5px 4px rgba(0, 0, 0, 0.04);
                    padding: 40px 32px 32px 32px;
                    max-width: 520px;
                    width: 100%;
                    margin: 40px 16px;
                    text-align: center;
                }

                h1 {
                    color: #0056b3;
                    font-size: 2.2rem;
                    margin-bottom: 0.5em;
                    letter-spacing: -1px;
                }

                .subtitle {
                    color: #2d6ca2;
                    font-size: 1.1rem;
                    margin-bottom: 1.5em;
                    font-weight: 500;
                }

                ul {
                    text-align: left;
                    margin: 1.5em 0 2em 0;
                    padding-left: 1.2em;
                    color: #444;
                    font-size: 1rem;
                }

                ul li {
                    margin-bottom: 0.7em;
                    line-height: 1.5;
                }

                .env {
                    display: inline-block;
                    background: #e3f0ff;
                    color: #0056b3;
                    border-radius: 6px;
                    padding: 0.3em 0.9em;
                    font-size: 0.98em;
                    font-weight: 600;
                    margin-top: 1.2em;
                    letter-spacing: 0.5px;
                }

                .lang-switch {
                    margin-top: 1.5em;
                    font-size: 0.98em;
                }
                .lang-switch a {
                    color: #0056b3;
                    text-decoration: none;
                    font-weight: 500;
                    border-bottom: 1px dotted #0056b3;
                    transition: border 0.2s;
                }
                .lang-switch a:hover {
                    border-bottom: 1px solid #0056b3;
                }

                footer {
                    text-align: center;
                    color: #888;
                    font-size: 0.95em;
                    padding: 18px 0 10px 0;
                    letter-spacing: 0.5px;
                }
            </style>
        </head>

        <body>
            <div class="container">
                <div class="card">
                    <h1>$${PROJECT_NAME}</h1>
                    <div class="subtitle">Aplicação AWS NGINX</div>
                    <ul>
                        <li>Infraestrutura automatizada com <strong>Terraform</strong></li>
                        <li>Escalabilidade e alta disponibilidade via <strong>Auto Scaling</strong> e <strong>Load Balancer</strong></li>
                        <li>Conteúdo compartilhado em <strong>Amazon EFS</strong></li>
                        <li>Imagem consistente criada com <strong>Packer</strong></li>
                    </ul>
                    <div class="env">Ambiente: $${ENVIRONMENT}</div>
                    <div class="lang-switch">
                        <a href="index.html" lang="en">English version</a>
                    </div>
                </div>
            </div>
            <footer>
                &copy; andresinho20049 &mdash; Cloud Architecture Demo
            </footer>
        </body>

        </html>
EOF_HTML_PTBR

    # Ensure correct permissions for the created index.pt-br.html file
    sudo chmod 644 "$${NGINX_HTML_PATH_ON_EFS}/index.pt-br.html"
    sudo chown $${NGINX_USER}:$${NGINX_USER} "$${NGINX_HTML_PATH_ON_EFS}/index.pt-br.html"
    echo "index.pt-br.html (Portuguese) created and permissions set on EFS."
else
    echo "index.pt-br.html (Portuguese) already exists on EFS. Skipping default content creation."
fi


# --- Nginx Core Configuration ---

# Define the minimalist nginx.conf content
echo "Creating a minimalist /etc/nginx/nginx.conf to ensure no conflicting server blocks."
sudo tee /etc/nginx/nginx.conf > /dev/null <<EOF_NGINX_CONF
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn; # Increased verbosity for error logging
pid /run/nginx.pid;

# Load dynamic modules.
include /usr/share/nginx/modules/*.conf;

events {
    worker_connections 1024;
}

http {
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile        on;
    tcp_nopush      on;
    tcp_nodelay     on;
    keepalive_timeout  65;
    types_hash_max_size 4096;

    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    # Load modular configuration files from the /etc/nginx/conf.d directory.
    # This is where our custom server block will reside.
    include /etc/nginx/conf.d/*.conf;

    # No default server block here to avoid conflicts.
    # All server blocks should be defined in /etc/nginx/conf.d/
}
EOF_NGINX_CONF

# Remove default Nginx configuration files to prevent conflicts.
# This ensures only our custom configuration is active.
echo "Removing or renaming default Nginx configuration files to prevent conflicts."
sudo rm -f /etc/nginx/conf.d/*.conf
sudo rm -f /etc/nginx/default.d/*.conf # Important for Amazon Linux default Nginx server block

# Create your custom Nginx server block in /etc/nginx/conf.d/
NGINX_CUSTOM_CONF_PATH="/etc/nginx/conf.d/$${PROJECT_NAME}.conf"

echo "Creating custom Nginx configuration at: $${NGINX_CUSTOM_CONF_PATH}"
sudo tee "$${NGINX_CUSTOM_CONF_PATH}" > /dev/null <<EOF_NGINX
server {
    listen 80;
    server_name _;
    root /usr/share/nginx/html; # This is the symbolic link that points to EFS
    index index.html index.htm; # Ensures Nginx looks for index.html as the directory index

    location / {
        try_files \$uri \$uri/ =404; # Standard try_files directive to serve files or directories
    }

    access_log /var/log/nginx/access.log main;
    error_log /var/log/nginx/error.log warn; # Set to 'debug' for more verbose logs if needed
}
EOF_NGINX

# --- Nginx Service Management ---

echo "Testing Nginx configuration..."
sudo nginx -t
if [ $? -eq 0 ]; then
    echo "Nginx configuration test successful. Restarting Nginx service."
    sudo systemctl restart nginx
    echo "Nginx service restarted."
    sudo systemctl status nginx --no-pager # --no-pager for cleaner output in logs
else
    echo "Error: Nginx configuration test failed. Check logs for details."
    exit 1
fi

echo "### User-data script completed successfully ###"