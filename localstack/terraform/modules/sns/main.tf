resource "aws_sns_topic" "this" {
  name       = var.fifo ? "${var.topic_name}.fifo" : var.topic_name
  fifo_topic = var.fifo
}

output "sns_topic_arn" {
  value = aws_sns_topic.this.arn
}