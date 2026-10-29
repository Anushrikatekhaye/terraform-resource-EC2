data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

############################
# Customer-managed KMS key (EBS + CloudWatch Logs)
############################
data "aws_iam_policy_document" "kms" {
  # Account root keeps full control (enables IAM policies to grant access)
  statement {
    sid       = "EnableIAMPolicies"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  # Allow CloudWatch Logs to use the key for the flow-log group
  statement {
    sid = "AllowCloudWatchLogs"
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*",
    ]
    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["logs.${data.aws_region.current.name}.amazonaws.com"]
    }

    condition {
      test     = "ArnLike"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values   = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:*"]
    }
  }
}

resource "aws_kms_key" "this" {
  description             = "${local.name_prefix} EBS and logs encryption key"
  enable_key_rotation     = true
  deletion_window_in_days = 7
  policy                  = data.aws_iam_policy_document.kms.json

  tags = {
    Name = "${local.name_prefix}-kms"
  }
}

resource "aws_kms_alias" "this" {
  name          = "alias/${local.name_prefix}-ec2"
  target_key_id = aws_kms_key.this.key_id
}
