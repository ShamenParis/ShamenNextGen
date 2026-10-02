resource "aws_sqs_queue" "dbx_queue" {
  name                       = "s3-to-databricks-queue"
  visibility_timeout_seconds = 60
}

resource "aws_sqs_queue_policy" "eb_to_sqs" {
  queue_url = aws_sqs_queue.dbx_queue.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowEventBridgeSend"
      Effect    = "Allow"
      Principal = { Service = "events.amazonaws.com" }
      Action    = "sqs:SendMessage"
      Resource  = aws_sqs_queue.dbx_queue.arn
      Condition = {
        ArnEquals = {
          "aws:SourceArn" = aws_cloudwatch_event_rule.s3_events.arn
        }
      }
    }]
  })
}