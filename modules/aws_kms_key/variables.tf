## ---------------------------------------------------------------------------------------------------------------------
## MODULE PARAMETERS
## These variables are expected to be passed in by the operator
## ---------------------------------------------------------------------------------------------------------------------

variable "service_account_arn" {
  type        = string
  description = "AWS IAM Service Account ARN"
}

variable "assume_role_arn" {
  type        = string
  description = "AWS Web Identity Provider Assume Role ARN"
}

## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------

variable "kms_key_description" {
  type        = string
  description = "S3 KMS Encryption Key Description"
  default     = "Sim Parables Dataflow Example S3|KMS Encryption Key"
}

variable "kms_retention_days" {
  type        = number
  description = "KMS Encryption Key Retention Window in Days"
  default     = 7
}

variable "resource_list" {
  type        = list(any)
  description = "List of AWS Resources to bind acces to the IAM Policy Document"
  default     = ["*"]
}