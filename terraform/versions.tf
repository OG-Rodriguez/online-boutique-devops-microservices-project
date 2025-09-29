# ---------------------------
# Terraform Core & Provider Requirements
# ---------------------------

# Specify the minimum required Terraform version for this project
terraform {
  required_version = ">= 1.6.0"

  # Declare required providers and their versions
  required_providers {
    aws = {
      source  = "hashicorp/aws"  # Use the official AWS provider from HashiCorp
      version = "~> 6.12"        # Allow any 6.12.x version, but not 6.13 or higher
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}
