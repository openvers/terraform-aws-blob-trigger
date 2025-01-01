<p float="left">
  <img id="b-0" src="https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white" height="25px"/>
  <img id="b-1" src="https://img.shields.io/badge/Amazon_AWS-FF9900?style=for-the-badge&logo=amazonaws&logoColor=white" height="25px"/>
  <img id="b-2" src="https://img.shields.io/github/actions/workflow/status/sim-parables/terraform-aws-blob-trigger/tf-integration-test.yml?style=flat&logo=github&label=CD%20(January%202025)" height="25px"/>
</p>

# Terraform GCP Blob Trigger Module

A reusable module for creating & configuring GCS Buckets with custom Blob Trigger Functions.

## Usage

Review the example under [Test](./test)

## Inputs

| Name                            | Description                            | Type           | Required |
|:--------------------------------|:---------------------------------------|:---------------|:---------|
| function_name                   | Lambda Function Name                   | string         | Yes      |
| function_contents               | Lambda Function Code Base file paths   | List(Object()) | Yes      |
| function_handler                | Lambda Function entrypoint func name   | String         | Yes      |
| trigger_bucket_name             | S3 Blob trigger bucket                 | String         | Yes      |
| results_bucket_name             | S3 Blob trigger results bucket         | String         | Yes      |
| function_bucket_name            | S3 Function Source Bucket Name         | String         | No       |
| function_trigger_events         | S3 Trigger events                      | List(String)   | No       |
| function_memory                 | GCP Function memory size               | Number         | No       |
| function_runtime                | GCP Function Runtime Environment       | String         | No       |
| function_timeout                | GCP Function Timeout Duration in Sec.  | Number         | No       |
| function_environment_variables  | Addition. GCP Cloud Function Env Vars  | Object()       | No       |  
| function_dependencies           | Lambda Function Layer pip dependencies | List(Object()) | No       |
| cloudwatch_logs_retention_days  | AWS Cloud Watch logs retention period  | Number         | No       |

## Outputs

| Name                   | Description                            |
|:-----------------------|:---------------------------------------|
