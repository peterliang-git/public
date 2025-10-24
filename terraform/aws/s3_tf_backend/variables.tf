variable "region" {
  description = "region"
  type        = string
  default     = "us-east-1"
}

variable "target_env" {
  description = "target environment, such as dev, testing, prod"
  type        = string
  default     = "dev"
}

variable "tf_dynamodb_tbl" {
  description = "tf_dynamodb_tbl"
  type        = string
  default     = "my-us-east-1.terraform-state-lock-tbl"
}

variable "tf_backend_bucket" {
  description = "tf_backend_bucket"
  type        = string
  default     = "my-use-east-1.terraform-backend-bucket"
}