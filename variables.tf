variable region {
  type        = string
  default     = "eu-west-1"
  description = "My current project region"
}

variable vpc_name {
  type        = string
  default     = "amit-vpc"
  description = "My VPC name"
}

variable ami-pattern {
  type        = string
  default     = ["amazon/al2023-ami-2023*-kernel-6.1-x86_64"]
  description = "description"
}
