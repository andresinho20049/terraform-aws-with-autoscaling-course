# packer/ami-templates/nginx-webserver/build.pkr.hcl

# Este arquivo define o bloco 'build' do Packer, que orquestra
# a execução dos provisioners sobre a fonte (source) definida para criar a AMI.

build {
  sources = ["source.amazon-ebs.httpd_webserver"]

  provisioner "shell" {
    inline = [
      "sudo yum update -y",
      "sudo yum install -y httpd",
      "sudo systemctl enable httpd",
      "sudo systemctl start httpd", 
      "echo '<h1>Hello from Packer & Apache HTTP Server in ${var.environment} environment!</h1>' | sudo tee /var/www/html/index.html",
      "sudo systemctl status httpd" 
    ]
  }
}
