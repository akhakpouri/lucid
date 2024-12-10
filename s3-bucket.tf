resource "aws_s3_bucket" "lucid_bucket" {
  bucket = var.bucket_name
}

data "aws_s3_bucket" "bucket-data" {
  bucket = aws_s3_bucket.lucid_bucket.bucket
}

resource "aws_s3_bucket_acl" "bucket_acl" {
  bucket     = data.aws_s3_bucket.bucket-data.id
  acl        = "public-read"
  depends_on = [aws_s3_bucket_ownership_controls.bucket_ownership]
}

##versioning
resource "aws_s3_bucket_versioning" "bucket_version" {
  bucket = data.aws_s3_bucket.bucket-data.id
  versioning_configuration {
    status = "Enabled"
  }
}

##bucket policy
resource "aws_s3_bucket_ownership_controls" "bucket_ownership" {
  bucket = data.aws_s3_bucket.bucket-data.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
  depends_on = [aws_s3_bucket_public_access_block.bucket_access_block]
}

resource "aws_s3_bucket_public_access_block" "bucket_access_block" {
  bucket = data.aws_s3_bucket.bucket-data.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = data.aws_s3_bucket.bucket-data.id
  policy = data.aws_iam_policy_document.policy_document.json
}

data "aws_iam_policy_document" "policy_document" {
  statement {
    sid    = "AllowPublicRead"
    effect = "Allow"
    resources = [
      "arn:aws:s3:::www.${var.bucket_name}",
      "arn:aws:s3:::www.${var.bucket_name}/*",
    ]
    actions = ["S3:GetObject"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
  depends_on = [aws_s3_bucket_public_access_block.bucket_access_block]
}

resource "aws_s3_bucket_website_configuration" "website_config" {
  bucket = data.aws_s3_bucket.bucket-data.bucket
  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_object" "object_upload" {
  for_each     = fileset("src/", "*.*")
  bucket       = data.aws_s3_bucket.bucket-data.bucket
  key          = each.value
  source       = "src/${each.value}"
  content_type = "text/html"
  etag         = filemd5("src/${each.value}")
  acl          = "public-read"

}
