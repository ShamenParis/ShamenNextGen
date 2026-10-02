resource "aws_iam_role" "lambda_exec" {
  name = "lambda_databricks_trigger_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_sqs" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "trigger_dbx" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "trigger-databricks-serverless"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "python3.12"
  timeout          = 30

  environment {
    variables = {
      DATABRICKS_HOST  = var.databricks_host
      DATABRICKS_TOKEN = var.databricks_token
      USER_EMAIL       = var.databricks_user_email
    }
  }
}

resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.dbx_queue.arn
  function_name    = aws_lambda_function.trigger_dbx.arn
  batch_size       = 1
}