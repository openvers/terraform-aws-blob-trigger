terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      configuration_aliases = [
        aws.auth_session,
      ]
    }
  }
}

data "aws_caller_identity" "current" {
  provider = aws.auth_session
}

## ---------------------------------------------------------------------------------------------------------------------
## AWS IAM POLICY DOCUMENT DATA SOURCE
## 
## Define a policy document to grant KMS Root access to enable IAM policies.
## https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html#key-policy-default-allow-root-enable-iam
## ---------------------------------------------------------------------------------------------------------------------
data "aws_iam_policy_document" "assume_role" {
  provider = aws.auth_session

  statement {
    sid       = "Enable IAM User Permissions"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## AWS KMS KEY RESOURCCE
## 
## Create an AWS KMS encryption key to share with downstream resources.
##
## Parameters:
## - `description`: KMS key description.
## - `deletion_window_in_days`: KMS key retention days.
## - `is_enabled`: KMS key status on creation.
## - `enable_key_rotation`: KMS key rotation status on creation.
## - `policy`: AWS IAM policy document
## ---------------------------------------------------------------------------------------------------------------------
resource "aws_kms_key" "this" {
  provider = aws.auth_session

  description             = var.kms_key_description
  deletion_window_in_days = var.kms_retention_days
  is_enabled              = true
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.assume_role.json
}