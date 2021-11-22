resource "aws_instance" "keycloak" {
  ami           = var.AMI
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.keycloak_private.id

  vpc_security_group_ids = [aws_security_group.keycloak_admin_access.id, aws_security_group.keycloak_sg.id]
  key_name               = "bastion_keypair"
  # nginx installation
  provisioner "file" {
    source      = "test.sh"
    destination = "/tmp/test.sh"
  }
  provisioner "file" {
    source      = "keycloak.yml"
    destination = "/tmp/keycloak.yml"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/test.sh",
      "sudo /tmp/test.sh"
    ]
  }
  provisioner "remote-exec" {
    inline = [
      "nohup sudo docker-compose -f /tmp/keycloak.yml up &",
      "sleep 1"
    ]
  }
  connection {
    type                = "ssh"
    user                = var.EC2_USER
    bastion_host        = aws_instance.bastion.public_ip
    bastion_host_key    = file("${path.module}/test-ssh/id_rsa.pub")
    bastion_private_key = file("${path.module}/test-ssh/id_rsa")
    bastion_port        = 22
    bastion_user        = var.EC2_USER
    private_key         = file("${path.module}/test-ssh/id_rsa")
    host                = self.private_ip
  }
}