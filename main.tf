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

resource "aws_instance" "my-ec2-inst" {
  ami           = var.ami
  instance_type = "t2.micro"
  subnet_id = module.vpc.public_subnets[0]


  tags = {
    Name = "amit-instance"
  }
}

resource "aws_eip_association" "eip-assignment" {
  instance_id = aws_instance.my-ec2-inst.id
  allocation_id = aws_eip.my-eip.id
}


