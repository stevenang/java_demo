resource "aws_s3_bucket_notification" "this" {
  bucket = var.bucket_id
  topic {
    topic_arn = var.topic_arn
    events    = ["s3:ObjectCreated:*"]
  }
}