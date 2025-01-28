# Terraform Configuration for Magento 2 Deployment on AWS Lightsail

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0.0"
}

provider "aws" {
  region = var.aws_region
}

# Lightsail Container Service
resource "aws_lightsail_container_service" "magento" {
  name        = var.service_name
  power       = var.container_power
  scale       = var.container_scale
  is_disabled = false

  tags = {
    Environment = var.environment
    Project     = var.service_name
    ManagedBy   = "terraform"
  }

  public_domain_names {
    domain_names = [var.domain_name]
  }
}

# RDS Instance
resource "aws_lightsail_database" "magento_db" {
  name                 = "${var.service_name}-db"
  blueprint_id         = "mysql_8_0"
  bundle_id            = var.db_bundle_id
  master_database_name = var.database_name
  master_username      = var.database_user
  master_password      = var.database_password

  backup_retention_enabled = true
  preferred_backup_window  = "03:00-04:00"

  tags = {
    Environment = var.environment
    Project     = var.service_name
    ManagedBy   = "terraform"
  }

  availability_zone = "${var.aws_region}a"
}

# S3 Bucket for Media Storage
resource "aws_s3_bucket" "magento_media" {
  bucket = "${var.service_name}-media-${var.environment}"

  tags = {
    Environment = var.environment
    Project     = var.service_name
    ManagedBy   = "terraform"
  }
}

resource "aws_s3_bucket_versioning" "media_versioning" {
  bucket = aws_s3_bucket.magento_media.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "media_encryption" {
  bucket = aws_s3_bucket.magento_media.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "media_access" {
  bucket = aws_s3_bucket.magento_media.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "media_lifecycle" {
  bucket = aws_s3_bucket.magento_media.id

  rule {
    id     = "cleanup-old-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

# Lambda for GenAI Integration
resource "aws_iam_role" "genai_lambda_role" {
  name = "${var.service_name}-genai-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "genai_lambda_policy" {
  name = "${var.service_name}-genai-lambda-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "translate:TranslateText",
          "secretsmanager:GetSecretValue",
          "s3:GetObject",
          "s3:PutObject",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "genai_lambda_policy_attachment" {
  role       = aws_iam_role.genai_lambda_role.name
  policy_arn = aws_iam_policy.genai_lambda_policy.arn
}

resource "aws_lambda_function" "genai_translation" {
  filename         = "lambda/genai_lambda.zip"
  function_name    = "${var.service_name}-genai-translation"
  role             = aws_iam_role.genai_lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  timeout          = var.lambda_timeout
  source_code_hash = filebase64sha256("lambda/genai_lambda.zip")

  environment {
    variables = {
      AWS_REGION     = var.aws_region
      OPENAI_API_KEY = data.aws_secretsmanager_secret.openai_secret.value
    }
  }
}

resource "aws_secretsmanager_secret" "openai_secret" {
  name = "openai-api-key"
}

resource "aws_secretsmanager_secret_version" "openai_secret_version" {
  secret_id     = aws_secretsmanager_secret.openai_secret.id
  secret_string = var.openai_api_key
}

resource "aws_s3_bucket_notification" "media_bucket_notifications" {
  bucket = aws_s3_bucket.magento_media.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.genai_translation.arn
    events              = ["s3:ObjectCreated:*"]
  }
}

resource "aws_lambda_permission" "s3_trigger_permission" {
  statement_id  = "AllowS3Invocation"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.genai_translation.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.magento_media.arn
}
