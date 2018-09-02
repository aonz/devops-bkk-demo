# Step 3: ECS and Fargate

resource "aws_ecs_cluster" "main" {
  name = "${var.name}"
}

resource "aws_cloudwatch_log_group" "ecs" {
  name = "${var.name}"
}

resource "aws_iam_instance_profile" "ecs" {
  name = "${var.name}-instance-profile"
  role = "${aws_iam_role.ecs.name}"
}

resource "aws_iam_role" "ecs" {
  name = "${var.name}-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "ecs" {
  name = "ecs"
  role = "${aws_iam_role.ecs.name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_ecs_task_definition" "main" {
  family                   = "${var.name}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = "${aws_iam_role.ecs.arn}"
  cpu                      = 256
  memory                   = 512

  container_definitions = <<DEFINITION
[
  {
    "cpu": 256,
    "essential": true,
    "image": "ghost:latest",
    "memory": 512,
    "name": "${var.app_name}",
    "portMappings": [
      {
        "containerPort": 2368,
        "hostPort": 2368
      }
    ],
    "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
             "awslogs-group" : "${var.name}",
             "awslogs-region": "${var.aws_region}",
             "awslogs-stream-prefix": "${var.app_name}"
        }
    },
    "environment" : [
        { "name" : "database__client", "value" : "mysql" },
        { "name" : "database__connection__host", "value" : "${aws_rds_cluster.aurora.endpoint}" },
        { "name" : "database__connection__database", "value" : "${var.database_name}" },
        { "name" : "database__connection__user", "value" : "${var.database_username}" },
        { "name" : "database__connection__password", "value" : "${var.database_password}" }
    ]
  }
]
DEFINITION
}

module "fargate_sg" {
  source = "terraform-aws-modules/security-group/aws"
  name   = "${var.name}-fargate"
  vpc_id = "${module.vpc.vpc_id}"

  computed_ingress_with_source_security_group_id = [
    {
      from_port                = 2368
      to_port                  = 2368
      protocol                 = "tcp"
      source_security_group_id = "${module.alb_sg.this_security_group_id}"
    },
  ]

  number_of_computed_ingress_with_source_security_group_id = 1
  egress_cidr_blocks                                       = ["0.0.0.0/0"]
  egress_rules                                             = ["all-all"]
}

resource "aws_ecs_service" "main" {
  name            = "${var.name}"
  cluster         = "${aws_ecs_cluster.main.id}"
  task_definition = "${aws_ecs_task_definition.main.arn}"
  desired_count   = "1"
  launch_type     = "FARGATE"

  network_configuration {
    security_groups = ["${module.fargate_sg.this_security_group_id}"]
    subnets         = ["${module.vpc.private_subnets}"]
  }

  load_balancer {
    target_group_arn = "${element(module.alb.target_group_arns, 0)}"
    container_name   = "${var.app_name}"
    container_port   = "2368"
  }

  depends_on = ["module.alb"]
}
