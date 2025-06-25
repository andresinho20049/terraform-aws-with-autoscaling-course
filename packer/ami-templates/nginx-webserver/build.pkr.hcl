build {
  sources = ["source.amazon-ebs.nginx_webserver"]

  provisioner "shell" {
    inline = [
      "sudo yum update -y",
      "sudo amazon-linux-extras install nginx1 -y",
      "sudo yum install -y nfs-utils", # Instalar o cliente NFS

      # Build EFS mount point
      "sudo mkdir -p /mnt/efs",
      
      # Not necessary to start Nginx again, as it should already be running
      "sudo systemctl enable nginx"
    ]
  }
}