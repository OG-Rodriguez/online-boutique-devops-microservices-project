# AWS region where all resources will be deployed
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-2"
}

# IAM Role ARN used by the EKS control plane for cluster operations
variable "eks_role_arn" {
  description = "IAM role ARN for the EKS cluster control plane"
  type        = string
}

# CIDR block for the primary VPC networking space
variable "vpc_cidr" {
  description = "CIDR block for the main VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# List of CIDR blocks for public subnets, typically one per Availability Zone (AZ)
variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets across availability zones"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.3.0/24"]
}

# List of CIDR blocks for private subnets, typically one per Availability Zone (AZ)
variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets across availability zones"
  type        = list(string)
  default     = ["10.0.2.0/24", "10.0.4.0/24"]
}

# Name to assign to the EKS cluster resource
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "online-boutique-cluster"
}

# Name to assign to the managed EKS node group
variable "node_group_name" {
  description = "Name of the EKS node group"
  type        = string
  default     = "online-boutique-node-group"
}

# EC2 instance type to use for the worker nodes in the EKS node group
variable "node_instance_type" {
  description = "EC2 instance type for EKS worker nodes"
  type        = string
  # Default set to a Free Tier eligible size for initial cluster bring-up on new accounts.
  # For real workloads you should override to at least t3.small or t3.medium in terraform.tfvars.
  default     = "t3.small"
}

# When true, overrides any larger instance type with a Free Tier eligible size (t3.micro) inside main.tf.
# This provides a quick bootstrap path without manually editing node_instance_type across environments.
variable "free_tier_mode" {
  description = "Force use of a Free Tier eligible instance type for the default node group (t3.micro)"
  type        = bool
  default     = false
}

# Desired number of worker nodes to run in the EKS node group initially
variable "desired_capacity" {
  description = "Desired number of nodes in the node group"
  type        = number
  # Keep low for Free Tier friendliness; override in terraform.tfvars for higher capacity.
  default     = 2
}

# Minimum number of worker nodes allowed in the node group autoscaling
variable "min_size" {
  description = "Minimum number of nodes in the node group"
  type        = number
  default     = 3
}

# Maximum number of worker nodes allowed in the node group autoscaling
variable "max_size" {
  description = "Maximum number of nodes in the node group"
  type        = number
  default     = 2
}

# IAM Role ARN assumed by the EC2 instances (managed node group) joining the EKS cluster.
# This role must have at least the following AWS managed policies attached:
# - AmazonEKSWorkerNodePolicy
# - AmazonEKS_CNI_Policy
# - AmazonEC2ContainerRegistryReadOnly
# And an inline or attached policy allowing logs/metrics if needed.
variable "node_group_role_arn" {
  description = "(Optional) Existing IAM role ARN for EKS worker nodes; if null a role will be created"
  type        = string
  default     = null
}

variable "enable_cloudwatch_agent" {
  description = "Attach CloudWatchAgentServerPolicy to the managed node IAM role (only if role is created)"
  type        = bool
  default     = false
}

variable "enable_ssm" {
  description = "Attach AmazonSSMManagedInstanceCore for Session Manager access (only if role is created)"
  type        = bool
  default     = false
}

variable "node_disk_size" {
  description = "Node group root volume size in GiB"
  type        = number
  default     = 20
}

variable "use_spot" {
  description = "Use spot instances for cost savings (mixed capacity via launch template not yet implemented)"
  type        = bool
  default     = false
}

# ---------------------
# Spot Node Group (Optional Second Group)
# ---------------------
variable "enable_spot_node_group" {
  description = "Create an additional spot-based managed node group"
  type        = bool
  default     = false
}

variable "spot_node_group_name" {
  description = "Name for the spot node group"
  type        = string
  default     = "online-boutique-node-group-spot"
}

variable "spot_instance_types" {
  description = "List of instance types for the spot node group (diversify for better availability)"
  type        = list(string)
  default     = ["t3.small", "t3.medium"]
}

variable "spot_desired_capacity" {
  description = "Desired number of spot nodes"
  type        = number
  default     = 1
}

variable "spot_min_size" {
  description = "Minimum number of spot nodes"
  type        = number
  default     = 0
}

variable "spot_max_size" {
  description = "Maximum number of spot nodes"
  type        = number
  default     = 3
}

# ---------------------------
# Vault Server Variables
# ---------------------------

variable "vault_instance_type" {
  description = "EC2 instance type for Vault server"
  type        = string
  default     = "t3.micro"  # Free tier eligible
}

variable "vault_disk_size" {
  description = "Root volume size for Vault server (GB)"
  type        = number
  default     = 20
}

variable "vault_version" {
  description = "HashiCorp Vault version to install"
  type        = string
  default     = "1.15.2"
}

variable "vault_key_name" {
  description = "Name for the EC2 key pair for Vault server SSH access"
  type        = string
  default     = "vault-server-key"
}

variable "vault_public_key" {
  description = "Public key content for Vault server SSH access"
  type        = string
  # This should be provided via terraform.tfvars or environment variable
}

variable "vault_use_elastic_ip" {
  description = "Whether to assign an Elastic IP to the Vault server"
  type        = bool
  default     = true
}
