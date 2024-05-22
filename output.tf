output "lambda_function_arn" {
  description = "AWS Labda Function ARN"
  value       = aws_lambda_function.this.arn
}

output "lambda_function_iam_role_arn" {
  description = "AWS Lambda Function IAM Role ARN"
  value       = aws_iam_role.this.arn
}

output "lambda_function_assume_role_arn" {
  description = "AWS Lambda Function IAM Assume Role ARN"
  value       = "arn:aws:sts::${split(":", aws_iam_role.this.arn)[4]}:assumed-role/${var.function_name}-${local.suffix}-role/${var.function_name}"
}