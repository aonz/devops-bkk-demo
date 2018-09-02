# Step 2: ALB and Aurora Serverless

## ALB
module "alb_sg" {
  source              = "terraform-aws-modules/security-group/aws"
  name                = "${var.name}-alb"
  vpc_id              = "${module.vpc.vpc_id}"
  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp"]
  egress_cidr_blocks  = ["0.0.0.0/0"]
  egress_rules        = ["all-all"]
}

module "alb" {
  source                   = "terraform-aws-modules/alb/aws"
  load_balancer_name       = "${var.name}"
  security_groups          = ["${module.alb_sg.this_security_group_id}"]
  subnets                  = "${module.vpc.public_subnets}"
  vpc_id                   = "${module.vpc.vpc_id}"
  logging_enabled          = false
  http_tcp_listeners       = "${list(map("port", "80", "protocol", "HTTP"))}"
  http_tcp_listeners_count = "1"
  target_groups            = "${list(map("name", "${var.name}", "backend_protocol", "HTTP", "backend_port", "2368", "target_type", "ip"))}"
  target_groups_count      = "1"
}

## Aurora Serverless

resource "aws_db_subnet_group" "aurora" {
  name       = "${var.name}"
  subnet_ids = ["${module.vpc.private_subnets}"]
}

module "aurora_sg" {
  source              = "terraform-aws-modules/security-group/aws"
  name                = "${var.name}-aurora"
  vpc_id              = "${module.vpc.vpc_id}"
  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["mysql-tcp"]
  egress_cidr_blocks  = ["0.0.0.0/0"]
  egress_rules        = ["all-all"]
}

resource "aws_rds_cluster" "aurora" {
  cluster_identifier     = "${var.name}"
  availability_zones     = "${var.vpc_azs}"
  database_name          = "${var.database_name}"
  master_username        = "${var.database_username}"
  master_password        = "${var.database_password}"
  db_subnet_group_name   = "${var.name}"
  vpc_security_group_ids = ["${module.aurora_sg.this_security_group_id}"]
  skip_final_snapshot    = true
  engine                 = "aurora"
  engine_mode            = "serverless"
  depends_on             = ["aws_db_subnet_group.aurora"]
}

output "alb_dns_name" {
  value = "${module.alb.dns_name}"
}

output "aurora_endpoint" {
  value = "${aws_rds_cluster.aurora.endpoint}"
}

output "aurora_ssh_tunnel" {
  value = "ssh -N -L 3306:${aws_rds_cluster.aurora.endpoint}:3306 ec2-user@${aws_instance.bastion.public_ip}"
}
