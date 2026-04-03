# ==========================================
# S3 Bucket cho Image Uploads
# ==========================================
# Thay vì lưu ảnh vào ổ đĩa tạm (ephemeral) của container,
# upload thẳng lên S3 để không bị mất khi Pod restart/scale.

resource "aws_s3_bucket" "uploads" {
  bucket        = "devops-final-uploads-dqc28664"
  force_destroy = true  # Cho phép Terraform xóa bucket kể cả khi còn ảnh bên trong

  tags = {
    Name        = "devops-final-uploads"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

# Cho phép public read (để browser đọc được ảnh sản phẩm)
resource "aws_s3_bucket_public_access_block" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "uploads_public_read" {
  bucket = aws_s3_bucket.uploads.id
  depends_on = [aws_s3_bucket_public_access_block.uploads]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.uploads.arn}/uploads/*"
      }
    ]
  })
}

# ==========================================
# IAM Policy cho EKS Pods ghi vào S3
# ==========================================
resource "aws_iam_policy" "s3_upload" {
  name        = "devops-final-s3-upload"
  description = "Allow EKS pods to upload images to S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.uploads.arn}/*"
      }
    ]
  })
}

# Output tên bucket để dùng trong Kubernetes deployment
output "s3_uploads_bucket_name" {
  value       = aws_s3_bucket.uploads.bucket
  description = "Tên S3 bucket dùng cho image uploads"
}

output "s3_uploads_bucket_region" {
  value       = aws_s3_bucket.uploads.region
  description = "Region của S3 bucket"
}
