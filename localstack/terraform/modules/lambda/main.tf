resource "aws_iam_role" "this" {
  name = "${var.function_name}-iam-role"
  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "lambda.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

resource "aws_iam_policy" "this" {
  name         = "${var.function_name}-iam-role-policy"
  path         = "/"
  description  = "AWS IAM Policy for managing aws lambda role"
  policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": [
       "logs:CreateLogGroup",
       "logs:CreateLogStream",
       "logs:PutLogEvents"
     ],
     "Resource": "arn:aws:logs:*:*:*",
     "Effect": "Allow"
   }
 ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
  role        = aws_iam_role.this.name
  policy_arn  = aws_iam_policy.this.arn
}

resource "aws_iam_role_policy_attachment" "lambda_sqs_role_policy" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
}

resource "aws_lambda_function" "this" {
  filename = var.file_name
  function_name = var.function_name
  role = aws_iam_role.this.arn
  handler = var.handler
  runtime = "java11"
  timeout = 600
  environment {
    variables = {
      AWS_ACCESS_KEY_ID = var.aws_access_key_id,
      AWS_SECRET_ACCESS_KEY = var.aws_secret_access_key,
      AWS_DEFAULT_REGION=var.region
    }
  }
}

resource "aws_lambda_event_source_mapping" "this" {
  event_source_arn = var.event_source_arn
  function_name    = aws_lambda_function.this.arn
}