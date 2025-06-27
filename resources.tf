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

## ---------------------------------------------------------------------------------------------------------------------
## AWS LAMBDA FUNCTION MODULE
## 
## Create a HTTP trigger AWS Lambda Function for Data Ingestion into S3 Data Lake.
## 
## Parameters:
## - `function_name`: AWS Lambda Function name.
## - `function_handler`: AWS Lambda Function source handler function name.
## - `bucket_ids`: S3 Bucket names for Lambda Permissions.
## - `function_runtime`: AWS Lambda Function runtime environment.
## - `kms_key_arn`: KMS encryption key ARN.
## - `sns_topic_arn`: SNS Topic ARN for Dead Letter Queue. 
## - `function_contents`: List of function source code to archive and artifact for Lambda Functions.
## - `function_dependencies`: List of Python packages to install as dependencies for the Lambda Function.
## - `function_environment_variables`: Environment variables to set for the Lambda Function.
## ---------------------------------------------------------------------------------------------------------------------
module "aws_lambda_function" {
  source = "github.com/sim-parables/terraform-aws-data-ingestion.git//modules/aws_lambda?ref=bfb2cf155731bad5873bde3531762b1b0f7e4154"

  function_name                  = var.function_name
  function_handler               = var.function_handler
  sns_topic_arn                  = var.sns_topic_arn
  kms_key_arn                    = var.kms_key_arn
  bucket_ids                     = var.bucket_ids
  function_contents              = var.function_contents
  function_dependencies          = var.function_dependencies
  function_environment_variables = var.function_environment_variables
  function_bucket_name           = var.function_bucket_name
  function_runtime               = var.function_runtime

  providers = {
    aws.auth_session = aws.auth_session
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## AWS S3 BUCKET NOTIFICATION RESOURCE
## 
## Trigger the pipeline execution on every new blob upload on the raw bucket.
## No where in the AWS Function resources does it define a target blob storage to
## store the ETL data - this is configured in the AWS Function source code.
## 
## Parameters:
## - `bucket`: AWS S3 trigger bucket ID.
## - `lambda_function_arn`: AWS Lambda Function ARN.
## - `events`: List of AWS S3 events.
## ---------------------------------------------------------------------------------------------------------------------
resource "aws_s3_bucket_notification" "this" {
  provider   = aws.auth_session
  depends_on = [aws_lambda_permission.this]

  bucket = var.source_bucket_id

  lambda_function {
    lambda_function_arn = module.aws_lambda_function.lambda_function_arn
    events              = var.function_trigger_events
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## AWS LAMBDA PERMISSION RESOURCE
## 
## Enable S3 bucket to invoke the Lamnda Function with the
## S3 Service Principal.
## 
## Parameters:
## - `statement_id`: AWS IAM policy SID.
## - `action`: AWS IAM policy action.
## - `function_name`: AWS Lambda Function name.
## - `principal`: AWS IAM policy principal.
## - `source_arn`: AWS S3 trigger bucket ARN.
## ---------------------------------------------------------------------------------------------------------------------
resource "aws_lambda_permission" "this" {
  provider = aws.auth_session

  statement_id  = "${replace(title(replace("${var.function_name}", "-", " ")), " ", "")}AllowS3InvokePolicyDoc"
  action        = "lambda:InvokeFunction"
  function_name = module.aws_lambda_function.lambda_function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${var.source_bucket_id}"
}