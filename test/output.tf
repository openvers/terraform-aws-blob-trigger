output "bronze_bucket_id" {
  description = "S3 Bucket Name for Data Lake Bronze Layer Data"
  value       = module.data_lake.bronze_bucket_id
}

output "silver_bucket_id" {
  description = "S3 Bucket Name for Data Lake Silver Layer Data"
  value       = module.data_lake.silver_bucket_id
}

output "service_account_client_id" {
  description = "AWS Service Account Client ID"
  value       = module.aws_service_account.access_id
  sensitive   = true
}

output "service_account_client_secret" {
  description = "AWS Service Account Client Secret"
  value       = module.aws_service_account.access_token
  sensitive   = true
}

output "assume_role" {
  description = "AWS IAM Assume Role with Web Identitiy Provider Name"
  value       = module.aws_identity_federation_roles.assume_role
}

output "assume_role_arn" {
  description = "AWS IAM Assume Role with Web Identitiy Provider Name"
  value       = module.aws_identity_federation_roles.assume_role_arn
}