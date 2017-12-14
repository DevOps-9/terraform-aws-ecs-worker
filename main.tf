/**
 * Variables.
 */

variable "name" {
  description = "The service name, if empty the service name is defaulted to the image name"
  default     = ""
}

variable "environment" {
  description = "Environment tag, e.g prod"
}

variable "cluster" {
  description = "The cluster name or ARN"
}

variable "desired_count" {
  description = "The desired count"
  default     = 2
}

variable "policy" {
  description = "IAM custom policy to be attached to the task role"
  default = ""
}

variable "container_definitions" {
  description = "here you should include the full container definitons"
}

/* * Resources.
 */

// Task Role could be useful to grant special permissions 
// conveniently to the containers running into
resource "aws_iam_role" "main" {
  name = "${var.name}-${var.environment}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "main" {
  count = "${var.policy == "" ? 0 : 1}"

  name = "${var.name}-${var.environment}"
  role = "${aws_iam_role.main.id}"
  policy = "${var.policy}"
}

resource "aws_ecs_service" "main" {
  name            = "${var.name}"
  cluster         = "${var.cluster}"
  task_definition = "${module.task.arn}"
  desired_count   = "${var.desired_count}"
  
  placement_strategy {
    type = "spread"
    field = "attribute:ecs.availability-zone"
  }

  placement_strategy {
    type = "binpack"
    field = "cpu"
  }

  placement_strategy {
    type = "binpack"
    field = "memory"
  }
}

module "task" {
  source                = "git::https://github.com/egarbi/terraform-aws-task-definition?ref=1.0.0"
  name                  = "${var.name}-${var.environment}"
  task_role             = "${aws_iam_role.main.arn}"
  container_definitions = "${var.container_definitions}"
}

// The task role name used by the task definition
output "task_role" {
  value = "${aws_iam_role.main.name}"
}

// The task role arn used by the task definition
output "task_role_arn" {
  value = "${aws_iam_role.main.arn}"
}
