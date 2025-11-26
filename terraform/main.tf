# 1. IAM Roles Anywhere

resource "aws_rolesanywhere_trust_anchor" "homelab" {
  name    = "homelab-cm3588-anchor"
  enabled = true
  source {
    source_data {
      x509_certificate_data = file(var.ca_certificate_path)
    }
    source_type = "CERTIFICATE_BUNDLE"
  }
  tags = {
    Environment = "K3S-Homelab"
    ManagedBy   = "Terraform"
  }
}

resource "aws_rolesanywhere_profile" "homelab" {
  name      = "homelab-profile"
  role_arns = [aws_iam_role.ai_processor.arn]
  enabled   = true
}

# 2. The Identity (IAM Role)

resource "aws_iam_role" "ai_processor" {
  name = "HomelabAIProcessorRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "rolesanywhere.amazonaws.com"
        }
        Action = [
          "sts:AssumeRole",
          "sts:TagSession",
          "sts:SetSourceIdentity"
        ]
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_rolesanywhere_trust_anchor.homelab.arn
          }
        }
      }
    ]
  })
}

# 3. S3 Bucket (Data Plane)

resource "aws_s3_bucket" "images" {
  bucket_prefix = "homelab-ai-images-"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "images" {
  bucket = aws_s3_bucket.images.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 4. SQS Queue

resource "aws_sqs_queue" "jobs" {
  name                       = "image-processing-queue"
  visibility_timeout_seconds = 60
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.jobs_dlq.arn
    maxReceiveCount     = 3
  })
}

resource "aws_sqs_queue" "jobs_dlq" {
  name = "image-processing-queue-dlq"
}

# 5. Permissions Policy

resource "aws_iam_role_policy" "ai_access" {
  name = "AIProcessorAccess"
  role = aws_iam_role.ai_processor.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]
        Resource = [
          aws_s3_bucket.images.arn,
          "${aws_s3_bucket.images.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]
        Resource = aws_sqs_queue.jobs.arn
      }
    ]
  })
}
