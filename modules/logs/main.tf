# MÓDULO logs · Bucket S3 para los logs, con caducidad de los objetos

resource "aws_s3_bucket" "logs" {
  bucket        = var.nombre
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

# Excepción justificada: para una formación
# no hace falta cifrado KMS, basta con el AES256.
#trivy:ignore:AWS-0132
resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "logs" {
  bucket = aws_s3_bucket.logs.id

  versioning_configuration {
    status = "Enabled"
  }
}


resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "caducar-logs"
    status = "Enabled"

    filter {}

    expiration {
      days = var.dias_retencion
    }

    noncurrent_version_expiration {
      noncurrent_days = var.dias_retencion
    }
  }
}
