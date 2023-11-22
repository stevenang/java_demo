data "aws_iam_policy_document" "sns_topic_policy" {
  statement {
    actions = [
      "SNS:Publish"
    ]
    effect = "Allow"
    resources = [
      var.sns_topic_arn
    ]
    principals {
      type = "Service"
      identifiers = [
        "s3.amazonaws.com"
      ]
    }
    condition {
      test = "ArnLike"
      values = [
        var.s3_bucket_arn
      ]
      variable = "aws:SourceArn"
    }
  }
}

resource "aws_sns_topic_policy" "this" {
  arn    = var.sns_topic_arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

resource "aws_sns_topic_subscription" "this" {
  count     = length(var.subscription_protocols)
  topic_arn = var.sns_topic_arn
  protocol  = var.subscription_protocols[count.index]
  endpoint  = var.subscription_endpoints[count.index]
}