variable "EC2_USER" {
  type = string
}
# variable "PUBLIC_KEY_PATH" {
#   type = string
# }
# variable "PRIVATE_KEY_PATH" {
#   type = string
# }

variable "private_subnet_cidr_block" {
  type = string

}
variable "availability_zone_count" {
  type = string
}
variable "vpc_cidr_block" {
  type = string
}
variable "AWS_REGION" {
  type = string

}

variable "AMI" {
  type    = string
  default = "ami-083654bd07b5da81d"
}
variable "dns_zone_name" {
  type = string
}
variable "domain_name" {
type = string
}