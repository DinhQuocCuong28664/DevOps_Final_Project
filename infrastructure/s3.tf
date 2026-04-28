# ==========================================
# S3 Bucket for Image Uploads
# ==========================================
# Instead of storing images on ephemeral container storage,
# upload directly to S3 so data persists across pod restarts/scaling.

resource "aws_s3_bucket" "uploads" {
  bucket        = "devops-final-uploads-dqc28664"
  force_destroy = true  # Allow Terraform to delete bucket even if it contains objects

  tags = {
    Name        = "devops-final-uploads"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

# Allow public read access (so browsers can load product images)
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
# IAM Policy for EKS Pods to write to S3
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

# Output bucket name for use in Kubernetes deployment
output "s3_uploads_bucket_name" {
  value       = aws_s3_bucket.uploads.bucket
  description = "Name of the S3 bucket used for image uploads"
}

# Attach S3 policy to EKS Node Group IAM Role
# Without this, pods will get AccessDenied when uploading images to S3
resource "aws_iam_role_policy_attachment" "s3_upload_attach" {
  role       = module.eks.eks_managed_node_groups["worker_nodes"].iam_role_name
  policy_arn = aws_iam_policy.s3_upload.arn
}

output "s3_uploads_bucket_region" {
  value       = aws_s3_bucket.uploads.region
  description = "AWS region of the S3 bucket"
}
