output "kms_key_arn" {
  description = "KMS Encryption Key ARN"
  value       = aws_kms_key.this.arn
  sensitive   = true
}

output "kms_key_id" {
  description = "KMS Encryption Key ID"
  value       = aws_kms_key.this.key_id
  sensitive   = true
}

output "id" {
  description = "KMS Encryption ID"
  value       = aws_kms_key.this.id
  sensitive   = true
}