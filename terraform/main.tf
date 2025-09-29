# ---------------------------
# Networking: VPC and Subnets
# ---------------------------

# Create a custom VPC for the application
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "online-boutique-vpc"
  }
}

# Create a public subnet in Availability Zone 1 (us-east-2a)
resource "aws_subnet" "public_az1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-2a"
  map_public_ip_on_launch = true

  tags = {
    Name                                      = "online-boutique-public-subnet-az1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                  = "1"
  }
}

# Create a public subnet in Availability Zone 2 (us-east-2b)
resource "aws_subnet" "public_az2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-east-2b"
  map_public_ip_on_launch = true

  tags = {
    Name                                      = "online-boutique-public-subnet-az2"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                  = "1"
  }
}

# Create a private subnet in Availability Zone 1 (us-east-2a)
resource "aws_subnet" "private_az1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-2a"

  tags = {
    Name                                      = "online-boutique-private-subnet-az1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"         = "1"
  }
}

# Create a private subnet in Availability Zone 2 (us-east-2b)
resource "aws_subnet" "private_az2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-2b"

  tags = {
    Name                                      = "online-boutique-private-subnet-az2"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"         = "1"
  }
}

# ---------------------------
# Internet Gateway & Routing
# ---------------------------

# Internet Gateway for outbound internet access from public subnets
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "online-boutique-igw"
  }
}

# Route table for public subnets with default route to Internet Gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "online-boutique-public-rt"
  }
}

# Associate public subnets with the public route table
resource "aws_route_table_association" "public_az1" {
  subnet_id      = aws_subnet.public_az1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_az2" {
  subnet_id      = aws_subnet.public_az2.id
  route_table_id = aws_route_table.public.id
}

# ---------------------------
# EKS Cluster
# ---------------------------

# Create an Amazon EKS cluster using the VPC subnets
resource "aws_eks_cluster" "main" {
  name     = "online-boutique-cluster"
  role_arn = var.eks_role_arn  # IAM role for EKS control plane

  vpc_config {
    subnet_ids = [
      aws_subnet.public_az1.id,
      aws_subnet.public_az2.id,
      aws_subnet.private_az1.id,
      aws_subnet.private_az2.id
    ]
  }

  tags = {
    Name = "online-boutique-eks"
  }
}

# ------------------------------------------
# ECR Repositories for All Microservices
# ------------------------------------------

locals {
  microservices = [
    "adservice",
    "cartservice",
    "checkoutservice",
    "currencyservice",
    "emailservice",
    "frontend",
    "loadgenerator",
    "paymentservice",
    "productcatalogservice",
    "recommendationservice",
    "shippingservice",
    "shoppingassistantservice"
  ]
  # Derive effective instance type respecting free_tier_mode flag
  effective_node_instance_type = var.free_tier_mode ? "t3.micro" : var.node_instance_type
}

resource "aws_ecr_repository" "microservices" {
  for_each = toset(local.microservices)
  name     = each.key

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = each.key
  }
}

# ---------------------------
# EKS Managed Node Group
# ---------------------------

resource "aws_eks_node_group" "default" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = var.node_group_name
  # Use provided role if given, else the one created conditionally in iam-node-role.tf
  node_role_arn   = local.create_node_role ? aws_iam_role.eks_node_role[0].arn : var.node_group_role_arn
  capacity_type   = var.use_spot ? "SPOT" : "ON_DEMAND"

  subnet_ids = [
    aws_subnet.public_az1.id,
    aws_subnet.public_az2.id
  ]

  scaling_config {
    desired_size = var.desired_capacity
    max_size     = var.max_size
    min_size     = var.min_size
  }

  instance_types = [local.effective_node_instance_type]
  disk_size      = var.node_disk_size

  tags = {
    Name                                        = var.node_group_name
    # Tags for Cluster Autoscaler auto-discovery
    "k8s.io/cluster-autoscaler/enabled"         = "true"
    "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
  }

  depends_on = [aws_eks_cluster.main]
}

# Optional secondary SPOT node group for cost-optimized workloads
resource "aws_eks_node_group" "spot" {
  count          = var.enable_spot_node_group ? 1 : 0
  cluster_name   = aws_eks_cluster.main.name
  node_group_name = var.spot_node_group_name
  node_role_arn  = local.create_node_role ? aws_iam_role.eks_node_role[0].arn : var.node_group_role_arn
  capacity_type  = "SPOT"

  subnet_ids = [
    aws_subnet.public_az1.id,
    aws_subnet.public_az2.id
  ]

  scaling_config {
    desired_size = var.spot_desired_capacity
    max_size     = var.spot_max_size
    min_size     = var.spot_min_size
  }

  instance_types = var.spot_instance_types
  disk_size      = var.node_disk_size

  labels = {
    lifecycle = "spot"
    role      = "workload"
  }

  tags = {
    Name                                        = var.spot_node_group_name
    Lifecycle                                   = "spot"
    # Tags for Cluster Autoscaler auto-discovery
    "k8s.io/cluster-autoscaler/enabled"         = "true"
    "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
  }

  # NOTE: To strictly schedule certain workloads onto spot nodes, add:
  # nodeSelector:
  #   lifecycle: spot
  # or use affinity/taints.

  depends_on = [aws_eks_cluster.main]
}

# ---------------------------
# IRSA for Cluster Autoscaler
# ---------------------------

data "aws_eks_cluster" "this" {
  name = aws_eks_cluster.main.name
}

data "aws_eks_cluster_auth" "this" {
  name = aws_eks_cluster.main.name
}

# Retrieve TLS cert to compute OIDC provider thumbprint
data "tls_certificate" "oidc" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

# Create IAM OIDC provider for the EKS cluster (required for IRSA)
resource "aws_iam_openid_connect_provider" "eks" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.oidc.certificates[0].sha1_fingerprint]
}

locals {
  ca_sa_name      = "cluster-autoscaler"
  ca_sa_namespace = "kube-system"
  ca_oidc_provider_url = replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")
}

# IAM policy for Cluster Autoscaler (minimal actions)
data "aws_iam_policy_document" "ca_policy" {
  statement {
    sid     = "CAClusterScaling"
    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "ec2:DescribeLaunchTemplateVersions",
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "autoscaling:UpdateAutoScalingGroup"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ca" {
  name        = "${var.cluster_name}-cluster-autoscaler"
  description = "Permissions for Kubernetes Cluster Autoscaler"
  policy      = data.aws_iam_policy_document.ca_policy.json
}

# Trust policy for service account via OIDC
data "aws_iam_policy_document" "ca_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
  identifiers = [aws_iam_openid_connect_provider.eks.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.ca_oidc_provider_url}:sub"
      values   = ["system:serviceaccount:${local.ca_sa_namespace}:${local.ca_sa_name}"]
    }
  }
}

resource "aws_iam_role" "ca" {
  name               = "${var.cluster_name}-cluster-autoscaler"
  assume_role_policy = data.aws_iam_policy_document.ca_trust.json
}

resource "aws_iam_role_policy_attachment" "ca_attach" {
  role       = aws_iam_role.ca.name
  policy_arn = aws_iam_policy.ca.arn
}

output "cluster_autoscaler_role_arn" {
  description = "IAM role ARN for Kubernetes Cluster Autoscaler (IRSA)"
  value       = aws_iam_role.ca.arn
}
