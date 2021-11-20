resource "aws_instance" "bastion" {
  ami           = var.AMI
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.keycloak_public[0].id

  vpc_security_group_ids = [aws_security_group.keycloak_bastion_sg.id]
  key_name               = aws_key_pair.bastion_keypair.id
  # nginx installation
  provisioner "file" {
    source      = "test.sh"
    destination = "/tmp/test.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/test.sh",
      "sudo /tmp/test.sh"
    ]
  }
  connection {
    type        = "ssh"
    user        = var.EC2_USER
    private_key = file("${path.module}/test-ssh/id_rsa")
    host        = self.public_ip
  }
}
// Sends your public key to the instance
resource "aws_key_pair" "bastion_keypair" {
  key_name   = "bastion_keypair"
  public_key = file("${path.module}/test-ssh/id_rsa.pub")
}