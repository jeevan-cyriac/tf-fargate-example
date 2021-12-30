resource "aws_s3_bucket" "results" {
  bucket = local.bucket_c7n_results
  acl    = "private"
  policy = data.aws_iam_policy_document.results_s3_bucket_policy.json

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = local.runner_tags
}

resource "aws_s3_bucket" "config" {
  bucket = local.bucket_c7n_config
  acl    = "private"
  policy = data.aws_iam_policy_document.config_s3_bucket_policy.json

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = local.runner_tags
}

data "aws_iam_policy_document" "results_s3_bucket_policy" {
  statement {
    sid     = "AllowSSLRequestsOnly"
    actions = ["s3:*"]
    effect  = "Deny"
    resources = [
      "arn:aws:s3:::${local.bucket_c7n_results}",
      "arn:aws:s3:::${local.bucket_c7n_results}/*"
    ]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "Bool"
      values   = ["false"]
      variable = "aws:SecureTransport"
    }
  }
}

data "aws_iam_policy_document" "config_s3_bucket_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [
      "arn:aws:s3:::${local.bucket_c7n_config}",
      "arn:aws:s3:::${local.bucket_c7n_config}/*"
    ]

    principals {
      type        = "AWS"
      identifiers = [local.pipeline_iam_role_arn]
    }
  }
  statement {
    sid     = "AllowSSLRequestsOnly"
    actions = ["s3:*"]
    effect  = "Deny"
    resources = [
      "arn:aws:s3:::${local.bucket_c7n_config}",
      "arn:aws:s3:::${local.bucket_c7n_config}/*"
    ]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "Bool"
      values   = ["false"]
      variable = "aws:SecureTransport"
    }
  }
}