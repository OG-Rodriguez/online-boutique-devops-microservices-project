# ---------------------------
# Output Values (Secure)
# ---------------------------

# Output the EKS cluster endpoint (Kubernetes API server URL)
# Marked as sensitive to prevent it from appearing in plain-text logs
output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = aws_eks_cluster.main.endpoint
  sensitive   = true
}

# Output the EKS cluster name
output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.main.name
}

# Output the URLs of all ECR repositories
# Marked as sensitive since these URLs are used in CI/CD pipelines
output "ecr_repository_urls" {
  description = "ECR repository URLs for all microservices"
  value       = {
    for name, repo in aws_ecr_repository.microservices :
    name => repo.repository_url
  }
  sensitive = true
}

# Output the node group name
output "node_group_name" {
  description = "EKS managed node group name"
  value       = aws_eks_node_group.default.node_group_name
}

# Output the worker node IAM role ARN (helpful for IRSA or debugging)
output "node_group_role_arn" {
  description = "Effective IAM role ARN used by the EKS managed node group"
  value       = local.create_node_role ? aws_iam_role.eks_node_role[0].arn : var.node_group_role_arn
}

output "spot_node_group_name" {
  description = "Name of the spot node group (empty if disabled)"
  value       = var.enable_spot_node_group ? aws_eks_node_group.spot[0].node_group_name : ""
}

# ---------------------------
# Vault Server Outputs
# ---------------------------

output "vault_server_ip" {
  description = "Public IP address of the Vault server"
  value       = var.vault_use_elastic_ip ? aws_eip.vault[0].public_ip : aws_instance.vault.public_ip
}

output "vault_server_private_ip" {
  description = "Private IP address of the Vault server"
  value       = aws_instance.vault.private_ip
}

output "vault_server_dns" {
  description = "Public DNS name of the Vault server"
  value       = aws_instance.vault.public_dns
}

output "vault_server_id" {
  description = "EC2 instance ID of the Vault server"
  value       = aws_instance.vault.id
}

output "vault_ui_url" {
  description = "URL to access Vault UI"
  value       = "http://${var.vault_use_elastic_ip ? aws_eip.vault[0].public_ip : aws_instance.vault.public_ip}:8200"
}

output "vault_api_url" {
  description = "URL for Vault API access"
  value       = "http://${var.vault_use_elastic_ip ? aws_eip.vault[0].public_ip : aws_instance.vault.public_ip}:8200"
}

output "vault_ssh_command" {
  description = "SSH command to connect to Vault server"
  value       = "ssh -i ~/.ssh/${var.vault_key_name}.pem ubuntu@${var.vault_use_elastic_ip ? aws_eip.vault[0].public_ip : aws_instance.vault.public_ip}"
  sensitive   = true
}
