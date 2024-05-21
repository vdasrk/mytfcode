Here is an example Terraform configuration for AWS VPC, S3, and Lambda resources following security best practices:

```hcl
# Configure AWS provider with default region
provider "aws" {
  region = "us-east-1"
}

# VPC module to deploy a private VPC with public and private subnets
module "vpc" {
  source = "org/vpc/aws"

  name = "my-app-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
}

# S3 module to create a private bucket  
module "s3" {
  source = "org/s3/aws"

  bucket = "my-private-bucket"
  acl    = "private"

  versioning = {
    enabled = true
  }

  tags = {
    Name        = "My private bucket"
    Environment = "Dev"
  }
}  

# IAM role and policy for Lambda permissions
resource "aws_iam_role" "lambda_role" {
  name = "my-lambda-role"

  # Terraform's "jsonencode" function converts a 
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "lambda_logging_policy" {
  name        = "lambda-logging-policy"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  # Terraform's "jsonencode" function converts a 
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_logging_policy.arn
}

# Lambda resource with minimum privileges through IAM role
resource "aws_lambda_function" "test_lambda" {
  filename      = "lambda_function.zip"
  function_name = "my-test-lambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.7"

  environment {
    variables = {
      ENV = "dev"
    }
  }
}

# Allow Lambda to access S3 bucket 
resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.test_lambda.arn
  principal     = "s3.amazonaws.com"
  source_arn    = module.s3.arn  
}
```

This follows security best practices like:

- Using IAM roles and policies for least privilege permissions to Lambda 
- Making S3 bucket private 
- Enabling versioning on S3 bucket
- Following principle of least privilege for resource permissions
- Using modules to encapsulate and reuse VPC, S3, Lambda configs
- Adding comments explaining overall architecture

Let me know if you need any other specifics configured!