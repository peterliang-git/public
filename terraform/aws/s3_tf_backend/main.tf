terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
  required_version = ">= 1.3"
}

provider "aws" {
  region = var.region
}

resource "aws_s3_bucket" "terraform_backend_bucket" {
  bucket = var.tf_backend_bucket

  tags = {
    Name        = "terraform_backend_bucket"
    Environment = var.target_env
  }
}

resource "aws_s3_bucket_ownership_controls" "s3_bucket_acl_ownership" {
  bucket = aws_s3_bucket.terraform_backend_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
  depends_on = [aws_s3_bucket_public_access_block.public_access_block]
}

resource "aws_s3_bucket_public_access_block" "public_access_block" {
  bucket = aws_s3_bucket.terraform_backend_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_dynamodb_table" "dynamodb_table" {
  name             = var.tf_dynamodb_tbl
  billing_mode     = "PROVISIONED" # Or "PAY_PER_REQUEST"
  read_capacity    = 5
  write_capacity   = 5
  hash_key         = "LockID"
  attribute {
    name = "LockID"
    type = "S" # String type for the partition key
  }
  tags = {
    Environment = var.target_env
    Name        = "terraform_backend_statelock_tbl"
  }
}