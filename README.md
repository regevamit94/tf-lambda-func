# tf-lambda-func

# AWS Lambda and EC2 with EFS and VPC Setup using Terraform

This Terraform project deploys an AWS environment with the following resources:
- VPC with public and private subnets
- Security group with open ingress and egress rules
- EFS file system with a mount target and access point
- IAM roles and policies for Lambda and EFS access
- Lambda function with EFS access within the VPC
- EC2 instance with EFS mount configured on launch {Private key is available to discover with the command "terraform output -raw private_key( depends on your output name)}

## Project Structure
The Terraform code in this repository provisions:
1. **VPC**: Creates a VPC with both public and private subnets across two availability zones.
2. **Security Group**: Manages inbound and outbound traffic to allow unrestricted access.
3. **EFS**: Sets up an Elastic File System and configures a mount target in the private subnet.
4. **IAM Roles and Policies**: Creates IAM roles and policies required for Lambda function VPC access and EFS usage.
5. **Lambda Function**: Deploys a Python Lambda function that can access the EFS within the VPC.
6. **EC2 Instance**: Creates an EC2 instance and automatically mounts the EFS on startup.

## Requirements
- **Terraform v1.0+**
- **AWS CLI** configured with appropriate credentials, or can be applied locally on an AWS console or VM.
- **Python** Required for the lambda function.