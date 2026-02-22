provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.tags
  }
}

# --- S3 bucket para tfstate ---
resource "aws_s3_bucket" "tfstate" {
  bucket = local.tfstate_bucket_name
}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket                  = aws_s3_bucket.tfstate.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# Política para forzar HTTPS
data "aws_iam_policy_document" "deny_insecure_transport" {
  statement {
    sid     = "DenyInsecureTransport"
    effect  = "Deny"
    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.tfstate.arn,
      "${aws_s3_bucket.tfstate.arn}/*"
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  policy = data.aws_iam_policy_document.deny_insecure_transport.json

  depends_on = [aws_s3_bucket_public_access_block.tfstate]
}

# --- DynamoDB para lock ---
# 1. Creamos la clave KMS gestionada por el cliente (CMK)
resource "aws_kms_key" "dynamo_lock_key" {
  description             = "Clave para cifrar la tabla de lock de Terraform"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

# 2. Recurso de DynamoDB actualizado
resource "aws_dynamodb_table" "tf_lock" {
  name         = local.lock_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  # SOLUCIÓN CKV_AWS_119: Cifrado con la clave creada arriba
  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.dynamo_lock_key.arn
  }

  # SOLUCIÓN CKV_AWS_28: Activa la recuperación 
  point_in_time_recovery {
    enabled = true
  }

  attribute {
    name = "LockID"
    type = "S"
  }
}