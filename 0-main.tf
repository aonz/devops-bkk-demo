variable "aws_region" {
  default = "ap-northeast-1"
}

variable "name" {
  default = "devopsbkk"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "vpc_azs" {
  type    = "list"
  default = ["ap-northeast-1a", "ap-northeast-1c", "ap-northeast-1d"]
}

variable "vpc_private_subnets" {
  type    = "list"
  default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "vpc_public_subnets" {
  type    = "list"
  default = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

variable "bastion_ami" {
  default = "ami-08847abae18baa040"
}

provider "aws" {
  region = "${var.aws_region}"
}
