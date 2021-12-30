module "function_trigger_lambda" {
  source = "git::https://git@github.com/jeevan-cyriac/tf-lambda.git?ref=v0.6.4"

  application_name = var.application_name
  application_role = "invoke-runner"
  timeout          = "900"
  env              = var.env
  lambda_file      = "lambda"
  package_path     = "${path.module}/functions/invoke_runner"

  envvars = {
    REGION              = local.aws_region
    ECS_CLUSTER         = local.ecs_task_name
    ECS_TASK_DEFINITION = local.ecs_task_name
    ECS_CONTAINER_NAME  = local.ecs_task_name
    ECS_SECURITY_GRPS   = join(",", [aws_security_group.default.id])
    ECS_SUBNETS         = join(",", var.subnets)

    C7N_CONFIG_BUCKET = aws_s3_bucket.config.id

    POLICIES_CONFIG_DIR = local.policies_config_dir
    ENV_CONFIG_FILE     = local.env_config_path
  }

  cron_expression = var.cron_expression

  iam_permissions = {
    "*"                                = ["ecs:DescribeTaskDefinition"]
    (local.bucket_c7n_config_arn)      = ["s3:ListBucket"]
    "${local.bucket_c7n_config_arn}/*" = ["s3:GetObject"]
    (local.ecs_role_exec_arn)          = ["iam:PassRole"]
    (local.ecs_role_task_arn)          = ["iam:PassRole"]
    (local.task_definition_arn)        = ["ecs:RunTask"]
  }
}
