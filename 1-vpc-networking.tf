# Step 1: VPC Networking

module "vpc" {
  source                 = "terraform-aws-modules/vpc/aws"
  name                   = "${var.name}"
  cidr                   = "${var.vpc_cidr}"
  azs                    = "${var.vpc_azs}"
  private_subnets        = "${var.vpc_private_subnets}"
  public_subnets         = "${var.vpc_public_subnets}"
  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false
}

module "bastion_sg" {
  source              = "terraform-aws-modules/security-group/aws"
  name                = "${var.name}-bastion"
  vpc_id              = "${module.vpc.vpc_id}"
  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["ssh-tcp"]
  egress_cidr_blocks  = ["0.0.0.0/0"]
  egress_rules        = ["all-all"]
}

resource "aws_instance" "bastion" {
  ami                         = "${var.bastion_ami}"
  instance_type               = "t2.nano"
  key_name                    = "${var.name}"
  subnet_id                   = "${element(module.vpc.public_subnets, 0)}"
  vpc_security_group_ids      = ["${module.bastion_sg.this_security_group_id}"]
  associate_public_ip_address = true

  tags {
    Name = "${var.name}-bastion"
  }
}
