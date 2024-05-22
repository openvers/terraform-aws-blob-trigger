terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "remote" {
    # The name of your Terraform Cloud organization.
    organization = "sim-parables"

    # The name of the Terraform Cloud workspace to store Terraform state files in.
    workspaces {
      name = "ci-cd-aws-workspace"
    }
  }
}

locals {
  assume_role_policies = [
    {
      effect = "Allow"
      actions = [
        "sts:AssumeRoleWithWebIdentity"
      ]
      principals = [{
        type        = "Federated"
        identifiers = [var.OIDC_PROVIDER_ARN]
      }]
      conditions = [
        {
          test     = "StringLike"
          variable = "token.actions.githubusercontent.com:sub"
          values = [
            "repo:${var.GITHUB_REPOSITORY}:environment:${var.GITHUB_ENV}",
            "repo:${var.GITHUB_REPOSITORY}:ref:${var.GITHUB_REF}"
          ]
        },
        {
          test     = "ForAllValues:StringEquals"
          variable = "token.actions.githubusercontent.com:iss"
          values = [
            "https://token.actions.githubusercontent.com",
          ]
        },
        {
          test     = "ForAllValues:StringEquals"
          variable = "token.actions.githubusercontent.com:aud"
          values = [
            "sts.amazonaws.com",
          ]
        },
      ]
    },
    {
      effect = "Allow"
      actions = [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
      principals = [{
        type        = "AWS"
        identifiers = [module.aws_service_account.service_account_arn]
      }]
      conditions = []
    }
  ]

  service_account_roles_list = [
    "iam:DeleteRole",
    "iam:ListInstanceProfilesForRole",
    "iam:ListAttachedRolePolicies",
    "iam:ListRolePolicies",
    "iam:AttachRolePolicy",
    "iam:TagRole",
    "iam:GetRole",
    "iam:CreateRole",
    "iam:PassRole",
    "iam:CreatePolicy",
    "iam:GetPolicy",
    "iam:GetRolePolicy",
    "iam:PutRolePolicy",
    "iam:DeleteRolePolicy",
    "iam:GetPolicyVersion",
    "iam:ListPolicyVersions",
    "iam:DetachRolePolicy",
    "iam:DeletePolicy",
    "iam:CreatePolicyVersion",
    "iam:DeletePolicyVersion",
    "iam:ListAttachedGroupPolicies",
    "iam:AttachGroupPolicy",
    "iam:GetGroupPolicy",
    "iam:PutGroupPolicy",
    "iam:DeleteGroupPolicy",
    "iam:DetachGroupPolicy",
    "kms:ScheduleKeyDeletion",
    "kms:GenerateDataKey*",
    "kms:Encrypt",
    "kms:Decrypt",
    "kms:Create*",
    "kms:Describe*",
    "kms:Enable*",
    "kms:List*",
    "kms:Put*",
    "kms:Disable*",
    "kms:Get*",
    "kms:Delete*",
    "s3:*",
    "s3-object-lambda:*",
    "lambda:*",
    "logs:*",
    "sns:*"
  ]
}

## ---------------------------------------------------------------------------------------------------------------------
## AWS PROVIDER
##
## Configures the AWS provider with CLI Credentials.
## ---------------------------------------------------------------------------------------------------------------------
provider "aws" {
  alias = "accountgen"
}

##---------------------------------------------------------------------------------------------------------------------
## AWS SERVICE ACCOUNT MODULE
##
## This module provisions an AWS service account along with associated roles and security groups.
##
## Parameters:
## - `service_account_name`: The display name of the new AWS Service Account.
## - `service_account_path`: The new AWS Service Account IAM Path.
## - `roles_list`: List of IAM roles to bing to new AWS Service Account.
##
## Providers:
## - `aws.accountgen`: Alias for the AWS provider for generating service accounts.
##---------------------------------------------------------------------------------------------------------------------
module "aws_service_account" {
  source = "github.com/sim-parables/terraform-aws-service-account.git?ref=a18e50b961655a345a7fd2d8e573fe84484c7235"

  service_account_name = var.service_account_name
  service_account_path = var.service_account_path
  roles_list           = local.service_account_roles_list

  providers = {
    aws.accountgen = aws.accountgen
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## AWS PROVIDER
##
## Configures the AWS provider with new Service Account Authentication.
## ---------------------------------------------------------------------------------------------------------------------
provider "aws" {
  alias = "auth_session"

  access_key = module.aws_service_account.access_id
  secret_key = module.aws_service_account.access_token
}

##---------------------------------------------------------------------------------------------------------------------
## AWS IDENTITY FEDERATION ROLES MODULE
##
## This module configured IAM Trust policies to provide OIDC federated access from Github Actions to AWS.
##
## Parameters:
## - `assume_role_policies`: List of OIDC trust policies.
##
## Providers:
## - `aws.accountgen`: Alias for the AWS provider for generating service accounts.
##---------------------------------------------------------------------------------------------------------------------
module "aws_identity_federation_roles" {
  source     = "github.com/sim-parables/terraform-aws-service-account.git?ref=a18e50b961655a345a7fd2d8e573fe84484c7235//modules/identity_federation_roles"
  depends_on = [module.aws_service_account]

  assume_role_policies  = local.assume_role_policies
  service_account_group = module.aws_service_account.group_name
  policy_roles_list = [
    "iam:DeleteRole",
    "iam:ListInstanceProfilesForRole",
    "iam:ListAttachedRolePolicies",
    "iam:ListRolePolicies",
    "iam:GetRole",
    "iam:CreateRole",
    "iam:GetRolePolicy",
    "iam:PutRolePolicy",
    "iam:DeleteRolePolicy",
    "iam:CreatePolicyVersion",
    "iam:DeletePolicyVersion",
    "s3:Get*",
    "s3:Put*",
    "s3:List*",
    "kms:GenerateDataKey*",
    "kms:Encrypt",
    "kms:Decrypt",
  ]

  providers = {
    aws.auth_session = aws.auth_session
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## KMS KEY MODULE
## 
## Create an AWS KMS encryption key.
## 
## Parameters:
## - `kms_key_id`: KMS key name.
## ---------------------------------------------------------------------------------------------------------------------
module "kms_key" {
  source     = "../modules/aws_kms_key"
  depends_on = [module.aws_service_account]

  service_account_arn = module.aws_service_account.service_account_arn
  assume_role_arn     = module.aws_identity_federation_roles.assume_role_arn

  providers = {
    aws.auth_session = aws.auth_session
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## SNS TOPIC MODULE
## 
## Create an AWS SNS Topic.
## 
## Parameters:
## - `kms_key_id`: KMS key name.
## ---------------------------------------------------------------------------------------------------------------------
module "sns_topic" {
  source = "../modules/aws_sns_topic"

  sns_topic_name = "example-sns-topic"
  kms_key_id     = module.kms_key.kms_key_id

  providers = {
    aws.auth_session = aws.auth_session
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## TRIGGER BUCKET MODULE
## 
## S3 Bucket to store data with a blob trigger.
## 
## Parameters:
## - `bucket_name`: S3 bucket name
## ---------------------------------------------------------------------------------------------------------------------
module "trigger_bucket" {
  source = "../modules/s3_bucket"

  bucket_name = "example-blob-trigger-bucket"
  kms_key_arn = module.kms_key.kms_key_arn

  providers = {
    aws.auth_session = aws.auth_session
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## RESULTS BUCKET MODULE
## 
## S3 Bucket to store triggered ETL data.
## 
## Parameters:
## - `bucket_name`: S3 bucket name
## ---------------------------------------------------------------------------------------------------------------------
module "results_bucket" {
  source = "../modules/s3_bucket"

  bucket_name = "example-blob-results-bucket"
  kms_key_arn = module.kms_key.kms_key_arn

  providers = {
    aws.auth_session = aws.auth_session
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## AWS LAMBDA FUNCTION MODULE
## 
## Create an S3 blob trigger data flow pipeline using AWS Lambda Function.
## 
## Parameters:
## - `function_name`: AWS Lambda Function name.
## - `trigger_bucket_name`: S3 Bucket name to configure with blob trigger.
## - `trigger_bucket_arn`: S3 Bucket ARN to configure with blob trigger.
## - `results_bucket_arn`: S3 Bucket ARN for the blob trigger results data.
## - `kms_key_arn`: KMS encryption key ARN.
## - `sns_topic_arn`: SNS Topic ARN for Dead Letter Queue. 
## - `function_contents`: List of function source code to archive and artifact for Lambda Functions.
## ---------------------------------------------------------------------------------------------------------------------
module "aws_lambda_function" {
  source = "../"
  depends_on = [
    module.trigger_bucket,
    module.results_bucket,
    module.aws_identity_federation_roles
  ]

  function_name       = "example-aws-blob-trigger"
  function_handler    = "run"
  trigger_bucket_name = module.trigger_bucket.bucket_id
  results_bucket_name = module.results_bucket.bucket_id
  sns_topic_arn       = module.sns_topic.sns_topic_arn
  kms_key_id          = module.kms_key.kms_key_id
  kms_key_arn         = module.kms_key.kms_key_arn

  function_contents = [
    {
      filename = "main.py",
      filepath = abspath("./source/main.py")
    },
    {
      filename = "requirements.txt",
      filepath = abspath("./source/requirements.txt")
    }
  ]

  function_dependencies = [
    {
      package_name    = "s3fs",
      package_version = "2022.11.0",
      no_dependencies = false
    },
    {
      package_name    = "fsspec",
      package_version = "2022.11.0",
      no_dependencies = false
    },
    {
      package_name    = "typing-extensions",
      package_version = "4.10.0",
      no_dependencies = true
    }
  ]

  function_environment_variables = {
    OUTPUT_BUCKET = module.results_bucket.bucket_id
  }

  providers = {
    aws.auth_session = aws.auth_session
  }
}