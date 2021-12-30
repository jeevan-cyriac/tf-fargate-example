data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_rds_cluster" "db_access" {
  cluster_identifier = var.rds_cluster
}
