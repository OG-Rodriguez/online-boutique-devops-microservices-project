# Conditional creation of an EKS worker node IAM role if caller does not supply one
# Best practice: allow override (for org-managed roles) while enabling turnkey defaults.

locals {
  create_node_role = var.node_group_role_arn == null
}

resource "aws_iam_role" "eks_node_role" {
  count = local.create_node_role ? 1 : 0
  name  = "online-boutique-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "online-boutique-eks-node-role"
  }
}

# Core required policies
resource "aws_iam_role_policy_attachment" "node_worker" {
  count      = local.create_node_role ? 1 : 0
  role       = aws_iam_role.eks_node_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}
resource "aws_iam_role_policy_attachment" "node_cni" {
  count      = local.create_node_role ? 1 : 0
  role       = aws_iam_role.eks_node_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}
resource "aws_iam_role_policy_attachment" "node_ecr" {
  count      = local.create_node_role ? 1 : 0
  role       = aws_iam_role.eks_node_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Optional policies
resource "aws_iam_role_policy_attachment" "node_cw" {
  count      = local.create_node_role && var.enable_cloudwatch_agent ? 1 : 0
  role       = aws_iam_role.eks_node_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}
resource "aws_iam_role_policy_attachment" "node_ssm" {
  count      = local.create_node_role && var.enable_ssm ? 1 : 0
  role       = aws_iam_role.eks_node_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Output-like local for convenience inside this module scope
locals {
  effective_node_role_arn = local.create_node_role ? aws_iam_role.eks_node_role[0].arn : var.node_group_role_arn
}
