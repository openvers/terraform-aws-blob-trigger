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
## AWS S3 BUCKET RESOURCCE
## 
## Create an AWS Simple Storage Service (S3) Bucket.
##
## Parameters:
## - `bucket`: Unique AWS Bucket name.
## ---------------------------------------------------------------------------------------------------------------------
resource "aws_s3_bucket" "this" {
  provider = aws.auth_session

  bucket        = var.bucket_name
  force_destroy = true
}


## ---------------------------------------------------------------------------------------------------------------------
## AWS S3 BUCKET VERSIONING RESOURCCE
## 
## Enable AWS Simple Storage Service (S3) Bucket blob versioning.
##
## Parameters:
## - `bucket`: AWS Bucket name.
## - `status`: Versioning status on creation.
## ---------------------------------------------------------------------------------------------------------------------
resource "aws_s3_bucket_versioning" "this" {
  provider = aws.auth_session

  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = "Enabled"
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## AWS S3 BUCKET SERVER SIDE ENCRYPTION CONFIGURATION RESOURCCE
## 
## Configure encryption at rest for AWS Simple Storage Service (S3) Bucket blob data with KMS encryption key.
##
## Parameters:
## - `bucket`: Unique AWS Bucket name.
## - `kms_master_key_id`: KMS encryption key ID.
## - `sse_algorithm`: Stochastic Steady-state Embedding algorithm type.
## ---------------------------------------------------------------------------------------------------------------------
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  provider = aws.auth_session

  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_arn
      sse_algorithm     = var.kms_encryption_algorithm
    }
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## AWS S3 BUCKET LIFECYCLE CONFIGURATION RESOURCCE
## 
## Configure lifecycle rules against blob data stored in AWS Simple Storage Service (S3) Bucket.
##
## Parameters:
## - `bucket`: Unique AWS Bucket name.
## ---------------------------------------------------------------------------------------------------------------------
resource "aws_s3_bucket_lifecycle_configuration" "this" {
  provider = aws.auth_session

  bucket = aws_s3_bucket.this.id

  rule {
    id     = "example-s3-bucket-lifecycle-config"
    status = "Enabled"

    expiration {
      days = 90
    }

    filter {}

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 60
      storage_class = "GLACIER"
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## AWS S3 BUCKET PUBLIC ACCESS BLOCK RESOURCCE
## 
## Configure restrictions to securely protect against public user of AWS Simple Storage Service (S3) Bucket.
##
## Parameters:
## - `bucket`: Unique AWS Bucket name.
## - `block_public_acls`: Flag to block publich access control lists (ACL).
## - `block_public_policy`: Flag to block public policies.
## - `ignore_public_acls`: Flag to ignore public access control lists (ACL).
## - `restrict_public_buckets`: Flag to restrict public bucket access.
## ---------------------------------------------------------------------------------------------------------------------
resource "aws_s3_bucket_public_access_block" "this" {
  provider = aws.auth_session

  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}