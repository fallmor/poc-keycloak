output "bastion_ip" {
  value = aws_instance.bastion.public_ip
}
output "alb" {
  value = aws_lb.test.dns_name
}
output "keycloak_ip" {
  value = aws_instance.keycloak.private_ip
}