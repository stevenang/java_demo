variable "queue_name" {
  description = "The name of the queue"
  type        = string
}

variable "fifo_queue" {
  type    = bool
  default = false
}

variable "dlq_arn" {
  type = string
  default = ""
}

variable "is_dlq" {
  type    = bool
  default = false
}

variable "max_receive_count" {
  type    = number
  default = 5
}