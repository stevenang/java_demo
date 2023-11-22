variable "function_name" {
  type = string
}

variable "file_name" {
  type = string
}

variable "handler" {
  type = string
}

variable "event_source_arn" {
  type = string
  default = null
}

variable "aws_access_key_id" {
  type = string
  default = "test"
}

variable "aws_secret_access_key" {
  type = string
  default = "test"
}

variable "region" {
  type = string
  default = "us-east-1"
}

