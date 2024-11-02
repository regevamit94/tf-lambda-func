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

variable ami {
  type        = string
  default     = "ami-00385a401487aefa4"
  description = "my ami"
}

variable url {
  type        = string
  default     = "https://api.apis.guru/v2/providers.json"
  description = "The file that will be downloaded with lambda function"
}

