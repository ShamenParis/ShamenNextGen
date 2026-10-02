resource "aws_cloudwatch_event_rule" "s3_events" {
  name        = "s3-object-created-rule"
  description = "Captures Object Created events from both S3 buckets"

  event_pattern = jsonencode({
    source      = ["aws.s3"]
    detail-type = ["Object Created"]
    detail = {
      bucket = {
        name = [
          aws_s3_bucket.primary_bucket.bucket,
          aws_s3_bucket.secondary_bucket.bucket
        ]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "sqs_target" {
  rule      = aws_cloudwatch_event_rule.s3_events.name
  target_id = "SendToSQS"
  arn       = aws_sqs_queue.dbx_queue.arn
}