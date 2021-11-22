# resource "aws_elb" "keycloak_elb" {

#   name               = "keycloak-elb"
#   subnets = [aws_subnet.keycloak_public[0].id, aws_subnet.keycloak_private.id]
#   security_groups = [aws_security_group.elb.id]

#   listener {
#     instance_port     = 8080
#     instance_protocol = "http"
#     lb_port           = 80
#     lb_protocol       = "http"
#   }

#   health_check {
#     healthy_threshold   = 2
#     unhealthy_threshold = 2
#     timeout             = 3
#     target              = "HTTP:8080/"
#     interval            = 30
#   }
#   instances                   = [aws_instance.keycloak.id]
#   cross_zone_load_balancing   = true
#   idle_timeout                = 100
#   connection_draining         = true
#   connection_draining_timeout = 300


#   tags = {
#     Name = "terraform-elb"
#   }
# }

resource "aws_lb" "test" {
  name               = "test-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.elb.id]
  subnets            = [aws_subnet.keycloak_public[0].id, aws_subnet.keycloak_private.id]

  enable_deletion_protection = false

  tags = {
    Environment = "production"
  }
}

resource "aws_lb_target_group" "test" {
  name     = "keycloacktarget"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.poc_keycloak.id
}
resource "aws_lb_target_group_attachment" "test" {
  target_group_arn = aws_lb_target_group.test.arn
  target_id        = aws_instance.keycloak.id
  port             = 8080
}
resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.test.arn
  port              = "80"
  protocol          = "HTTP"


  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.test.arn
  }
}