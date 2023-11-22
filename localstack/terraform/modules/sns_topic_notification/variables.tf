variable "s3_bucket_arn" {
  type = string
}

variable "subscription_protocols" {
  type = list(string)
}

variable "subscription_endpoints" {
  type = list(string)
}

variable "sns_topic_arn" {
  type = string
}