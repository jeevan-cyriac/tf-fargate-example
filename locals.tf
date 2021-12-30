locals {

  account_id = data.aws_caller_identity.current.account_id
  aws_region = data.aws_region.current.name

  runner_role_name = "runner"

  ecs_task_name = "${var.application_name}-${local.runner_role_name}"

  runner_tags = merge(
    module.tag_mapping.tag_map[var.application_name][local.runner_role_name],
    {
      environment = var.env
    }
  )


  log_group_name = "/aws/ecs/${local.ecs_task_name}"

  # The whole block below of building the arn and then passing to
  # function_trigger_lambda module (sourced from tf-lambda) is a workaround
  # until we implement a better fix.
  # The issue is that on a fresh installation TF fails because the
  # child module (function_trigger_lambda) input map - ima_permissions has a
  # condition using 'count' fct and the elements are not known at TF plan stage
  #
  # We need to "guide" TF on the order excution of the parent and child module
  # revision in task arn has to be a * as task_definition's revision increments on every update
  task_definition_arn = "arn:aws:ecs:${local.aws_region}:${local.account_id}:task-definition/${local.ecs_task_name}:*"

  ecs_role_exec_name = "${local.ecs_task_name}-ecs-exec"
  ecs_role_task_name = "${local.ecs_task_name}-ecs-task"

  ecs_role_exec_desc = "Allow ${local.ecs_task_name} ECS task to execute"
  ecs_role_task_desc = "Allow ${local.ecs_task_name} ECS task to access S3 and RDS"

  ecs_role_exec_arn = "arn:aws:iam::${local.account_id}:role/${local.ecs_role_exec_name}"
  ecs_role_task_arn = "arn:aws:iam::${local.account_id}:role/${local.ecs_role_task_name}"

  cross_account_role    = "example-CS-CloudCustodian-ReadOnlyAccess"
  container_image       = "584102939696.dkr.ecr.us-east-1.amazonaws.com/${var.container_image_name}"
  bucket_c7n_results    = "example-cloud-custodian-results-${var.env}"
  bucket_c7n_config     = "example-cloud-custodian-config-${var.env}"
  bucket_c7n_config_arn = "arn:aws:s3:::${local.bucket_c7n_config}"

  policies_config_dir = "policies"
  env_config_path     = "env/${var.env}.json"

  num_of_weeks_to_persist_db_data = 6

  pipeline_iam_role_arn = "arn:aws:iam::584102939696:role/cbadmin"
}
