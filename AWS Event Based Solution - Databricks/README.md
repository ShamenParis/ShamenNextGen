# AWS Event-Based Solution - Databricks

This project uses AWS object-created events to start Databricks processing for files uploaded to either of two S3 buckets.

## Architecture

1. An object is created in the primary or secondary S3 bucket.
2. Amazon S3 publishes the event to Amazon EventBridge.
3. An EventBridge rule routes the event to an Amazon SQS queue.
4. An AWS Lambda function reads one queue message and calls the Databricks Jobs API to submit a serverless job.
5. The job runs the existing Databricks notebook at `/Workspace/Shared/DataEngineering/Events/Process_S3_Event`, passing the bucket and object key as base parameters.

The Lambda function submits a job using the Databricks `jobs/runs/submit` API. The notebook must already exist in the workspace, and the workspace must support the serverless job environment used by the request.

## Repository Contents

- `demo-project/`: Terraform configuration and the Lambda source code.
- `demo-project/src/lambda_function.py`: Parses SQS-wrapped EventBridge messages and submits Databricks runs.
- `data/event_test_1.csv` and `data/event_test_2.csv`: Small sample files for testing S3 uploads.

Terraform generates `demo-project/lambda.zip` during planning. Terraform state, plan files, provider downloads, local variable files, and credentials are intentionally excluded from Git.

## Prerequisites

- Terraform 1.5 or later.
- AWS credentials configured through the standard AWS provider credential chain.
- AWS permissions to create the S3 buckets, EventBridge rule and target, SQS queue and policy, Lambda function, and IAM role/policy attachment.
- A Databricks workspace and a personal access token that can submit jobs.
- The notebook path above created in that workspace.
- Two globally unique S3 bucket names.

## Configure

From `demo-project/`, create a local `terraform.tfvars` file. It is ignored by Git; do not commit credentials.

```hcl
aws_region           = "eu-west-1"
primary_bucket_name  = "replace-with-a-globally-unique-name-1"
secondary_bucket_name = "replace-with-a-globally-unique-name-2"
databricks_host      = "your-workspace.cloud.databricks.com"
databricks_token     = "replace-with-a-personal-access-token"
databricks_user_email = "user@example.com"
```

Set `databricks_host` to the workspace hostname without `https://`. `databricks_user_email` is passed to the Lambda environment as `USER_EMAIL`; the current handler does not read it.

**Credential handling:** Terraform marks the token variable sensitive, but the token is still placed in the Lambda environment and stored in Terraform state. Protect the state and restrict access to it. For production use, prefer retrieving the token from a managed secret store rather than storing it directly in Lambda configuration.

## Deploy

Run these commands from `demo-project/`:

```sh
terraform init
terraform fmt -check
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

Configure AWS credentials before running Terraform. Keep the resulting state secure; this project uses local state unless you configure a remote backend.

## Test

After deployment, upload one of the sample CSVs to either bucket. For example, from `demo-project/`:

```sh
aws s3 cp ../data/event_test_1.csv s3://YOUR_PRIMARY_BUCKET/event_test_1.csv
```

Check the Lambda's CloudWatch logs for the submitted Databricks run ID, then check the run in the Databricks workspace. SQS standard queues and Lambda event source mappings can deliver messages more than once, so the notebook's processing should tolerate duplicate events.

## Clean Up

```sh
terraform destroy
```

Both S3 bucket resources set `force_destroy = true`. Destroying this stack can permanently delete objects in those buckets; back up any data you need first.

## Current Limitations

- The Databricks notebook path and serverless environment version are defined in the Lambda source.
- No SQS dead-letter queue is configured. Failed messages are retried according to the SQS/Lambda behavior until they are removed or expire.
- The Databricks token is supplied through Terraform and Lambda configuration; see the credential-handling note above.