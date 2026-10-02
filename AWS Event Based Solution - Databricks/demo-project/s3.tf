resource "aws_s3_bucket" "primary_bucket" {
  bucket        = var.primary_bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_notification" "primary_notify" {
  bucket      = aws_s3_bucket.primary_bucket.id
  eventbridge = true
}

resource "aws_s3_bucket" "secondary_bucket" {
  bucket        = var.secondary_bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_notification" "secondary_notify" {
  bucket      = aws_s3_bucket.secondary_bucket.id
  eventbridge = true
}