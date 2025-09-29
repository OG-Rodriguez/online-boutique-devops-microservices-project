# ---------------------------
# AWS Provider Configuration
# ---------------------------

# Configure the AWS provider
# The AWS region is provided by the variable aws_region
provider "aws" {
  region = var.aws_region
}
