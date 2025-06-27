output "lambda_function_arn" {
  description = "AWS Labda Function ARN"
  value       = module.aws_lambda_function.lambda_function_arn
}

output "lambda_function_iam_role_arn" {
  description = "AWS Lambda Function IAM Role ARN"
  value       = module.aws_lambda_function.lambda_function_iam_role_arn
}

output "lambda_function_assume_role_arn" {
  description = "AWS Lambda Function IAM Assume Role ARN"
  value       = module.aws_lambda_function.lambda_function_assume_role_arn
}