locals {
  queue_name = var.fifo_queue ? "${var.queue_name}.fifo" : var.queue_name
  dlq_name = var.fifo_queue ? "${var.queue_name}-dlq.fifo" : "${var.queue_name}-dlq"
  alarm_name = var.is_dlq ? "${var.queue_name}-dlq-not-empty-alarm" : "${var.queue_name}-flood-alarm"
  threshold = var.is_dlq ? 1 : 100
}

resource "aws_sqs_queue" "this" {
  name       = var.is_dlq ? local.dlq_name : local.queue_name
  fifo_queue = var.fifo_queue
  redrive_policy = var.is_dlq ? null : jsonencode({
    deadLetterTargetArn = var.dlq_arn
    maxReceiveCount     = var.max_receive_count
  })
}

resource "aws_cloudwatch_metric_alarm" "this" {
  alarm_name          = local.alarm_name
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Average"
  threshold           = local.threshold
  alarm_description   = "Alarm if there are messages exceeding the threshold."
  dimensions = {
    QueueName = var.is_dlq ? local.dlq_name : local.queue_name
  }
}

output "queue_url" {
  value = aws_sqs_queue.this.id
}

output "queue_arn" {
  value = aws_sqs_queue.this.arn
}