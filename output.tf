output "website_url" {
  description = "website url"
  value       = aws_cloudfront_distribution.distribution.domain_name
}

output "bucket_url" {
  description = "S3 bucket url"
  value       = aws_s3_bucket_website_configuration.hosting.website_endpoint

}
