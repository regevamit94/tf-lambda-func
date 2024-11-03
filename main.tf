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


module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.vpc_name
  cidr = "192.168.0.0/16"

  azs             = ["eu-west-1a", "eu-west-1b"]
  public_subnets = ["192.168.0.0/17"]
  private_subnets = ["192.168.128.0/17"]

  enable_nat_gateway = true
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

  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
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
  subnet_id      = module.vpc.private_subnets[0]
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


resource "aws_iam_role_policy" "lambda_to_vpc_policy" {
  name   = "lambda-vpc-policy"
  role   = aws_iam_role.iam_for_lambda.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_efs_access_point" "access_point_for_lambda" {
  file_system_id = aws_efs_file_system.my-efs.id
  root_directory {
    path = "/mnt/efs"
  }

  tags = {
    Name = "amit-access-point"
  }
}

resource "aws_lambda_function" "my_lambda_func" {
  function_name = "amit-lambda-function"
  filename      = "download_from_url_lambda_file.zip"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "download_from_url_lambda_file.lambda_handler"
  runtime = "python3.9"

  file_system_config {
    arn = aws_efs_access_point.access_point_for_lambda.arn
    local_mount_path = "/mnt/efs"
  }

  vpc_config {
    subnet_ids         = module.vpc.private_subnets
    security_group_ids = [aws_security_group.my_sg.id]
  }


  environment {
    variables = {
      FILE_URL = var.url
    }
  }
  depends_on = [aws_efs_mount_target.efs-location]
}

resource "aws_apigatewayv2_api" "my_http_api" {
  name          = "amit-http-api"
  protocol_type = "HTTP"

  tags = {
    Name = "amit-http-api"
  }
}

# Create a Lambda Integration for the HTTP API
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id             = aws_apigatewayv2_api.my_http_api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.my_lambda_func.arn
  integration_method = "POST"

  depends_on = [aws_lambda_function.my_lambda_func]
}

# Create a route for the HTTP API
resource "aws_apigatewayv2_route" "my_http_api_route" {
  api_id    = aws_apigatewayv2_api.my_http_api.id
  route_key = "POST /myendpoint" # Define the endpoint path

  target = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# Deploy the HTTP API
resource "aws_apigatewayv2_stage" "my_http_stage" {
  api_id = aws_apigatewayv2_api.my_http_api.id
  name   = "prod" 

  depends_on = [aws_apigatewayv2_route.my_http_api_route]
}


resource "aws_lambda_permission" "allow_api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.my_lambda_func.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.my_http_api.execution_arn}/*/*"
}