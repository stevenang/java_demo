terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.24.0"
    }
  }
}

provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_force_path_style         = true

  endpoints {
    acm            = "http://localhost:4566"
    apigateway     = "http://localhost:4566"
    cloudformation = "http://localhost:4566"
    cloudwatch     = "http://localhost:4566"
    dynamodb       = "http://localhost:4566"
    ec2            = "http://localhost:4566"
    es             = "http://localhost:4566"
    firehose        = "http://localhost:4566"
    iam            = "http://localhost:4566"
    kinesis        = "http://localhost:4566"
    lambda         = "http://localhost:4566"
    rds            = "http://localhost:4566"
    redshift       = "http://localhost:4566"
    route53        = "http://localhost:4566"
    s3             = "http://localhost:4566"
    secretsmanager = "http://localhost:4566"
    ses            = "http://localhost:4566"
    sns            = "http://localhost:4566"
    sqs            = "http://localhost:4566"
    ssm            = "http://localhost:4566"
    stepfunctions  = "http://localhost:4566"
    sts            = "http://localhost:4566"
  }
}

locals {
  s3_bucket_names = ["test-bucket-01", "test-bucket-02"]
  sqs_queues = {
    "test-bucket-01" = {
      name = "test-queue-01",
      fifo = false
    },
    "test-bucket-02" = {
      name = "test-queue-02",
      fifo = false
    }
  }
  sns_topics = {
    "test-bucket-01" = {
      name = "test-topic-01",
      fifo = false
    },
    "test-bucket-02" = {
      name = "test-topic-02",
      fifo = false
    }
  }
}

module "create_s3_buckets" {
  source      = "./modules/s3_bucket"
  for_each    = toset(local.s3_bucket_names)
  bucket_name = each.value
}

module "create_s3_buckets_test_bucket_03" {
  source      = "./modules/s3_bucket"
  bucket_name = "test-bucket-03"
}

module create_sqs_dlq {
  source     = "./modules/sqs"
  for_each   = local.sqs_queues
  queue_name = each.value.name
  fifo_queue = each.value.fifo
  is_dlq     = true
}

module "create_sqs_queue" {
  source     = "./modules/sqs"
  for_each   = local.sqs_queues
  queue_name = each.value.name
  fifo_queue = each.value.fifo
  dlq_arn    = module.create_sqs_dlq[each.key].queue_arn
  is_dlq     = false
}

module "create_sns_topics" {
  source     = "./modules/sns"
  for_each   = local.sns_topics
  topic_name = each.value.name
  fifo       = each.value.fifo
}

module "create_sns_topic_subscriptions" {
  source                 = "./modules/sns_topic_subscription"
  for_each               = local.sns_topics
  s3_bucket_arn          = module.create_s3_buckets[each.key].bucket_arn
  sns_topic_arn          = module.create_sns_topics[each.key].sns_topic_arn
  subscription_protocols = ["sqs"]
  subscription_endpoints = [module.create_sqs_queue[each.key].queue_arn]
}

module "create_s3_notifications" {
  source    = "./modules/s3_notification"
  for_each  = toset(local.s3_bucket_names)
  bucket_id = module.create_s3_buckets[each.value].bucket_id
  topic_arn = module.create_sns_topics[each.value].sns_topic_arn
}

module "create_lambda_for_sqs" {
  source = "./modules/lambda"
  function_name = "Sqs_Event_Lambda"
  file_name = "../../modules/SqsEventLambdaDemo/target/SqsEventLambdaDemo.jar"
  handler = "tw.idv.stevenang.lambda.SqsEventLambdaDemo::handleRequest"
}

resource "aws_lambda_event_source_mapping" "this" {
  event_source_arn = module.create_sqs_queue["test-bucket-01"].queue_arn
  function_name    = module.create_lambda_for_sqs.aws_lambda_function_arn
}

module "create_lambda_for_s3_event" {
  source = "./modules/lambda"
  function_name = "S3_Event_Lambda"
  file_name = "../../modules/S3EventLambdaDemo/target/S3EventLambdaDemo.jar"
  handler = "tw.idv.stevenang.lambda.S3EventLambdaDemo::handleRequest"
}

resource "aws_lambda_permission" "allow_s3_bucket" {
  statement_id = "AllowExecutionFromS3Bucket"
  action = "lambda:InvokeFunction"
  function_name = module.create_lambda_for_s3_event.aws_lambda_function_arn
  principal = "s3.amazonaws.com"
  source_arn = module.create_s3_buckets["test-bucket-02"].bucket_arn
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = module.create_s3_buckets["test-bucket-02"].bucket_id
  lambda_function {
    lambda_function_arn = module.create_lambda_for_s3_event.aws_lambda_function_arn
    events = ["s3:ObjectCreated:*"]
  }
  depends_on = [aws_lambda_permission.allow_s3_bucket]
}