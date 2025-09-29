# ---------------------------
# Terraform Variable Values
# ---------------------------

# IAM role ARN for EKS cluster control plane
eks_role_arn = "arn:aws:iam::094121082922:role/eks-cluster-demo-role"

# Uncomment and override defaults as needed:
# aws_region = "us-east-2"
# vpc_cidr   = "10.0.0.0/16"

# Explicit node group sizing to satisfy EKS constraints (min ≤ desired ≤ max)
min_size         = 1
desired_capacity = 2
max_size         = 3

# Baseline instance type suitable for Online Boutique
node_instance_type = "t3.small"

# Ensure free tier override is off so t3.small is respected
free_tier_mode = false
