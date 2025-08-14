terraform {
      backend "s3" {
        bucket         = "my-tfstate-bucket-20250811"
        key            = "mytfkey/terraform.tfstate"
        region         = "us-east-1"  # Or your desired AWS region
        #dynamodb_table = "your-terraform-state-lock" # Optional
        encrypt        = true
      }
    }