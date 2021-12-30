############# #############
# Task exec role          #
############# #############
resource "aws_iam_role" "exec" {
  name               = local.ecs_role_exec_name
  assume_role_policy = data.aws_iam_policy_document.task_assume.json
  description        = local.ecs_role_exec_desc

  tags = merge(
    local.runner_tags,
    {
      description = local.ecs_role_exec_desc
    }
  )

}
resource "aws_iam_role_policy_attachment" "exec_policy" {
  role       = aws_iam_role.exec.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

###########################
# Task task role          #
###########################
resource "aws_iam_role" "task" {
  name               = local.ecs_role_task_name
  assume_role_policy = data.aws_iam_policy_document.task_assume.json
  description        = local.ecs_role_task_desc

  tags = merge(
    local.runner_tags,
    {
      description = local.ecs_role_task_desc
    }
  )
}

data "aws_iam_policy_document" "task_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"

      identifiers = [
        "ecs-tasks.amazonaws.com",
      ]
    }
  }
}

# terraform iam_role_policy does not seem to take description or tags, hence they are not added
resource "aws_iam_role_policy" "task_policy" {
  name   = "${local.ecs_task_name}-task-policy"
  role   = aws_iam_role.task.id
  policy = data.aws_iam_policy_document.task_policy.json
}

data "aws_iam_policy_document" "task_policy" {

  statement {
    sid       = "AssumeCrossAccountRole"
    actions   = ["sts:AssumeRole"]
    effect    = "Allow"
    resources = ["arn:aws:iam::*:role/${local.cross_account_role}"]
  }

  statement {
    sid     = "GetConfigS3Bucket"
    actions = ["s3:GetObject", "s3:ListBucket"]
    effect  = "Allow"
    resources = [
      aws_s3_bucket.config.arn,
      "${aws_s3_bucket.config.arn}/*",
    ]
  }

  statement {
    sid     = "GetResultsS3Bucket"
    actions = ["s3:GetObject", "s3:ListBucket", "s3:PutObject"]
    effect  = "Allow"
    resources = [
      aws_s3_bucket.results.arn,
      "${aws_s3_bucket.results.arn}/*",
    ]
  }

  statement {
    sid       = "RdsConnect"
    actions   = ["rds-db:connect"]
    effect    = "Allow"
    resources = ["arn:aws:rds-db:${local.aws_region}:${local.account_id}:dbuser:${data.aws_rds_cluster.db_access.cluster_resource_id}/${mysql_user.reporter.user}"]
  }

  statement {
    sid       = "RdsDescribe"
    actions   = ["rds:Describe*"]
    effect    = "Allow"
    resources = ["arn:aws:rds:${data.aws_region.current.name}:${local.account_id}:cluster:${data.aws_rds_cluster.db_access.cluster_identifier}"]
  }

  statement {
    sid       = "DescribeRegions"
    actions   = ["ec2:DescribeRegions"]
    effect    = "Allow"
    resources = ["*"]
  }

  statement {
    sid       = "WaiveLambdaInvoke"
    actions   = ["lambda:InvokeFunction"]
    effect    = "Allow"
    resources = [var.lambda_arn_waive_nc_resources]
  }
}

###########################
# ECS task                #
###########################
resource "aws_ecs_cluster" "main" {
  name               = local.ecs_task_name
  capacity_providers = ["FARGATE_SPOT", "FARGATE"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
  }

  tags = local.runner_tags
}

resource "aws_ecs_task_definition" "main" {
  family                   = local.ecs_task_name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.ecs_cpu_size
  memory                   = var.ecs_memory_size

  execution_role_arn = aws_iam_role.exec.arn
  task_role_arn      = aws_iam_role.task.arn

  container_definitions = <<DEFINITION
[
    {
        "name": "${local.ecs_task_name}",
        "image": "${local.container_image}:${var.container_version}",
        "environment": [
            {
                "name": "env",
                "value": "${var.env}"
            },
            {
                "name": "C7N_RESULTS_BUCKET",
                "value": "${aws_s3_bucket.results.id}"
            },
            {
                "name": "C7N_CONFIG_BUCKET",
                "value": "${aws_s3_bucket.config.id}"
            },
            {
                "name": "POLICIES_CONFIG_DIR",
                "value": "${local.policies_config_dir}"
            },
            {
                "name": "ENV_CONFIG_FILE",
                "value": "${local.env_config_path}"
            },
            {
                "name": "AWS_REGION",
                "value": "${local.aws_region}"
            },
            {
                "name": "RDS_CLUSTER",
                "value": "${var.rds_cluster}"
            },
            {
                "name": "RDS_DB_OPERATIONAL",
                "value": "${var.rds_db_operational}"
            },
            {
                "name": "RDS_DB_REPORTING",
                "value": "${var.rds_db_reporting}"
            },
            {
                "name": "RDS_TABLE_CAM",
                "value": "${var.rds_table_aws_cam}"
            },
            {
                "name": "RDS_TABLE_C7N_RESULTS",
                "value": "${var.rds_table_c7n}"
            },
            {
                "name": "RDS_TABLE_C7N_NON_COMPL_RESOURCES",
                "value": "${var.rds_table_c7n_non_compl_resources}"
            },
            {
                "name": "RDS_USER",
                "value": "${mysql_user.reporter.user}"
            },
            {
                "name": "NUM_OF_WEEKS_TO_PERSIST_DB_DATA",
                "value": "${local.num_of_weeks_to_persist_db_data}"
            },
            {
                "name": "TENANT_ACCESS_ROLE",
                "value": "${local.cross_account_role}"
            },
            {
                "name": "LAMBDA_ARN_WAIVE_NC_RESOURCES",
                "value": "${var.lambda_arn_waive_nc_resources}"
            }
        ],
        "logConfiguration": {
            "logDriver": "awslogs",
            "options": {
                "awslogs-group": "${local.log_group_name}",
                "awslogs-region": "${local.aws_region}",
                "awslogs-stream-prefix": "ecs"
            }
        }
    }
]
DEFINITION

  tags = local.runner_tags

}

resource "aws_cloudwatch_log_group" "logs" {
  name              = local.log_group_name
  retention_in_days = 30

  tags = local.runner_tags
}

##################
# Security Group #
##################
resource "aws_security_group" "default" {
  name        = local.ecs_task_name
  description = local.runner_tags.description
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = local.runner_tags

}
