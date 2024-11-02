terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
    region = var.region
}



resource "aws_eip" "my-eip" {
  domain = "vpc"
  
  tags = {
    Name = "amit-eip"
  }
}



module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.vpc_name
  cidr = "192.168.0.0/16"

  azs             = ["eu-west-1a", "eu-west-1b"]
  public_subnets = ["192.168.0.0/17", "192.168.128.0/17"]
  
  map_public_ip_on_launch = true  

  tags = {
    Name = "amit-vpc"
  }
}

resource "aws_security_group" "my_sg" {
  name        = "amit-security-group"
  description = "amits hometask sg"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "amit-sg"
  }
}

resource "tls_private_key" "my-private-key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}


resource "aws_key_pair" "my-key-pair" {
  key_name   = "amit-keypair"
  public_key = tls_private_key.my-private-key.public_key_openssh
}

resource "aws_efs_file_system" "my-efs" {
  creation_token = "amit-efs"

  tags = {
    Name = "amit-efs"
  }
}

resource "aws_efs_mount_target" "efs-location" {
  file_system_id = aws_efs_file_system.my-efs.id
  subnet_id      = module.vpc.public_subnets[0]
}



resource "aws_instance" "my-ec2-inst" {
  ami           = var.ami
  instance_type = "t2.micro"
  subnet_id = module.vpc.public_subnets[0]
  key_name = aws_key_pair.my-key-pair.key_name
  vpc_security_group_ids = [aws_security_group.my_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              yum install -y amazon-efs-utils
              mkdir -p /efs
              mount -t efs ${aws_efs_file_system.my-efs.id}:/ /efs
              EOF

  tags = {
    Name = "amit-instance"
  }
}


data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_lambda_function" "my_lambda_func" {
  function_name = "amit-lambda-function"
  filename      = "download_from_url_lambda_file.zip"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "download_from_url_lambda_file.lambda_handler"

  runtime = "python3.9"

  environment {
    variables = {
      FILE_URL = var.url
    }
  }

}

resource "aws_eip_association" "eip-assignment" {
  instance_id = aws_instance.my-ec2-inst.id
  allocation_id = aws_eip.my-eip.id
}