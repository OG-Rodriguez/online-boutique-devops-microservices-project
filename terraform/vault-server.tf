# ---------------------------
# HashiCorp Vault Server
# ---------------------------

# Security Group for Vault Server
resource "aws_security_group" "vault" {
  name        = "vault-server-sg"
  description = "Security group for HashiCorp Vault server"
  vpc_id      = aws_vpc.main.id

  # SSH access from anywhere (restrict this in production)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }

  # Vault API and UI access
  ingress {
    from_port   = 8200
    to_port     = 8200
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Restrict this in production
    description = "Vault API and UI"
  }

  # Vault cluster communication (for HA setups)
  ingress {
    from_port   = 8201
    to_port     = 8201
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Vault cluster communication"
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name        = "vault-server-sg"
    Environment = "development"
    Purpose     = "vault-security"
  }
}

# Key Pair for Vault Server SSH Access
resource "aws_key_pair" "vault" {
  key_name   = var.vault_key_name
  public_key = var.vault_public_key

  tags = {
    Name        = "vault-server-key"
    Environment = "development"
    Purpose     = "vault-access"
  }
}

# Get the latest Ubuntu 22.04 LTS AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# EC2 Instance for Vault Server
resource "aws_instance" "vault" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.vault_instance_type
  key_name                    = aws_key_pair.vault.key_name
  vpc_security_group_ids      = [aws_security_group.vault.id]
  subnet_id                   = aws_subnet.public_az1.id
  associate_public_ip_address = true

  # Root volume configuration
  root_block_device {
    volume_type = "gp3"
    volume_size = var.vault_disk_size
    encrypted   = true
    
    tags = {
      Name = "vault-server-root"
    }
  }

  # User data script for basic setup (optional)
  user_data_base64 = base64encode(templatefile("${path.module}/vault-user-data.sh", {
    vault_version = var.vault_version
  }))

  tags = {
    Name        = "vault-server"
    Environment = "development"
    Purpose     = "secret-management"
    Backup      = "required"
  }

  # Prevent accidental termination
  disable_api_termination = false

  lifecycle {
    create_before_destroy = true
  }
}

# Elastic IP for Vault Server (optional but recommended)
resource "aws_eip" "vault" {
  count    = var.vault_use_elastic_ip ? 1 : 0
  instance = aws_instance.vault.id
  domain   = "vpc"

  tags = {
    Name        = "vault-server-eip"
    Environment = "development"
    Purpose     = "vault-static-ip"
  }

  depends_on = [aws_internet_gateway.igw]
}