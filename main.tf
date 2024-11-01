terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.74.0"
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
  public_subnets = ["192.168.1.0/17", "192.168.2.0/17"]

  tags = {
    Name = "My VPC configuration"
  }
}


data "aws_ami" "my-os" {
  most_recent = true

  filter {
    name   = "name"
    values = var.ami-pattern
  }

  owners = ["amazon"]
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.my-os.id
  instance_type = "t2.micro"
  subnet_id = module.vpc.public_subnets[0]


  tags = {
    Name = "My ec2 instance"
  }
}