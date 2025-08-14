terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = var.vpc_name
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = true # Assign a public IP to instances launched in this subnet
  #availability_zone       = "${var.aws_region}a" # Use a specific AZ

  tags = {
    Name = var.subnet_name
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = var.igw_name
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0" # Allow all outbound traffic to the internet
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = var.rtb_name
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "web_server_sg" {
  vpc_id      = aws_vpc.main.id
  name        = "web_server_sg"
  description = "Allow HTTP and SSH traffic"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow HTTP from anywhere
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow SSH from anywhere (consider restricting this in production)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "WebServerSecurityGroup"
  }
}


resource "tls_private_key" "example_key" {
  algorithm = "RSA" # Or "ED25519" for more modern algorithms
  rsa_bits  = 2048  # Only for RSA
}

resource "aws_key_pair" "example_key_pair" {
  key_name   = "my-terraform-key" # Name for the key pair in AWS
  public_key = tls_private_key.example_key.public_key_openssh # Use the public key from the generated private key
}

resource "local_sensitive_file" "example_private_key" {
  content  = tls_private_key.example_key.private_key_pem
  filename = "my-terraform-key.pem" # Local path to store the private key
  file_permission = "0400" # Set appropriate permissions for the private key
}

data "aws_iam_role" "existing_role" {
  name = "EC2SSMManagedRole"
}
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "my-ec2-profile"
  role = data.aws_iam_role.existing_role.name
}

resource "aws_instance" "web_server" {
  ami           = var.ec2_ami # Replace with a valid AMI ID for your region
  instance_type = var.ec2_instance_type
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  
  subnet_id     = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web_server_sg.id]
  key_name      = aws_key_pair.example_key_pair.key_name

  user_data     = base64encode(templatefile("${path.module}/template/user-data.sh.tftpl", {
        username        = "Terraform User"
      }))

  tags = {
    Name = var.ec2_instance_name
  }
}

# Define the SQS Queue
resource "aws_sqs_queue" "my_queue" {
  name = "my-lambda-trigger-queue"
  visibility_timeout_seconds = 300 # Should be >= 6 * Lambda timeout
  message_retention_seconds = 86400
}

# Define the IAM Role for the Lambda Function
resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_stepfunction_execution_policy" {
  name        = "lambda_stepfunction_execution_policy"
  description = "IAM policy for stepfunction Lambda execution"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "states:StartExecutin"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:states:*:*:*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_stepfunction_execution_policy_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_stepfunction_execution_policy.arn
}

# Attach policies to the Lambda Execution Role
resource "aws_iam_role_policy_attachment" "lambda_sqs_policy_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution_policy_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_s3_bucket" "lambda_code_bucket" {
  bucket = "my-lambda-code-bucket-20250811"
  acl    = "private"
}

resource "aws_s3_object" "my_lambda_code_object" {
  bucket = aws_s3_bucket.lambda_code_bucket.id
  key    = "lambda.zip"
  source = data.archive_file.lambda_zip.output_path # Path to your local Lambda function zip file
  etag   = filemd5(data.archive_file.lambda_zip.output_path) # Triggers update on file change
}

# Define the Lambda Function
resource "aws_lambda_function" "my_lambda" {
  function_name = "my-sqs-processor-lambda"
  handler       = "mylambda.lambda_handler"
  runtime       = "python3.13"    # Or your preferred runtime
  role          = aws_iam_role.lambda_exec_role.arn
  #filename         = data.archive_file.lambda_zip.output_path
  #source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  s3_bucket = aws_s3_bucket.lambda_code_bucket.id
  s3_key    = aws_s3_object.my_lambda_code_object.key  
}

# Create the Event Source Mapping to link SQS to Lambda
resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.my_queue.arn
  function_name    = aws_lambda_function.my_lambda.arn
  batch_size       = 10 # Number of messages to process in one batch
  enabled          = true
}

# Add permission for SQS to invoke Lambda
resource "aws_lambda_permission" "allow_sqs_invocation" {
  statement_id  = "AllowExecutionFromSQS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.my_lambda.function_name
  principal     = "sqs.amazonaws.com"
  source_arn    = aws_sqs_queue.my_queue.arn
}

resource "aws_s3_bucket" "website_bucket" {
  bucket = "my-website-bucket-20250811"

  tags = {
    Name = "My website_bucket"
  }
}

resource "aws_s3_object" "my_s3_web_object" {
  bucket = aws_s3_bucket.website_bucket.id
  key    = "web_page_url"
  source = data.archive_file.lambda_zip.output_path
}

resource "aws_s3_bucket" "tfstate_bucket" {
  bucket = "my-tfstate-bucket-20250811"

  tags = {
    Name = "My tfstate_bucket"
  }
}