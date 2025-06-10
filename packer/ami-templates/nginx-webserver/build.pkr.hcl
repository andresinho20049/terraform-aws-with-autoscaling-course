build {
  sources = ["source.amazon-ebs.nginx_webserver"]

  provisioner "shell" {
    inline = [
      "sudo yum update -y",
      "sudo amazon-linux-extras install nginx1 -y",
      "sudo systemctl enable nginx",
      "sudo systemctl start nginx",
      "sudo echo '<h1>Hello from Packer & Terraform in ${var.environment} environment!</h1> <h2>NGINX WebServer</h2>' | sudo tee /usr/share/nginx/html/index.html",
      "sudo systemctl status nginx"
    ]
  }
}