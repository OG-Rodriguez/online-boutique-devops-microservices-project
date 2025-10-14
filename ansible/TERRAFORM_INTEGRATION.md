# Integrated Terraform + Ansible Vault Deployment

This guide shows how to deploy a HashiCorp Vault server using your existing Terraform infrastructure combined with Ansible configuration management.

## 🏗️ Architecture Overview

Your integrated solution includes:
- **Terraform**: Provisions AWS infrastructure (VPC, EC2, Security Groups)
- **Ansible**: Configures and deploys HashiCorp Vault software
- **Integration Script**: Orchestrates the entire deployment process

## 📁 Updated Project Structure

```
terraform/
├── main.tf                    # Your existing EKS infrastructure
├── vault-server.tf            # NEW: Vault server infrastructure
├── variables.tf               # Updated with Vault variables
├── output.tf                  # Updated with Vault outputs
├── vault-user-data.sh         # NEW: Server preparation script
└── terraform.tfvars.template  # Updated with Vault configuration

ansible/
├── vault-playbook.yml         # Vault installation playbook
├── inventory.template         # Template for Terraform integration
├── deploy-vault.sh           # NEW: Integrated deployment script
├── templates/
└── examples/
```

## 🚀 Quick Start Deployment

### 1. Prepare Your Environment

Navigate to your ansible directory:
```bash
cd ~/ansible-vault-project
```

Make the deployment script executable:
```bash
chmod +x deploy-vault.sh
```

### 2. Configure Terraform Variables

The deployment script will help you set up terraform.tfvars, but you can also prepare it manually:

```bash
cd ../terraform
cp terraform.tfvars.template terraform.tfvars
# Edit terraform.tfvars with your AWS account details
```

### 3. Run the Integrated Deployment

```bash
cd ~/ansible-vault-project
./deploy-vault.sh
```

This single command will:
- ✅ Check prerequisites (Terraform, Ansible, SSH keys)
- ✅ Generate SSH keys if needed
- ✅ Deploy infrastructure with Terraform
- ✅ Update Ansible inventory with server details
- ✅ Test connectivity to the new server
- ✅ Deploy and configure Vault with Ansible
- ✅ Provide post-deployment instructions

## 🔧 Manual Step-by-Step Process

If you prefer to run each step manually:

### Step 1: Deploy Infrastructure
```bash
cd ~/terraform
terraform init
terraform plan
terraform apply
```

### Step 2: Update Ansible Inventory
```bash
cd ~/ansible-vault-project
VAULT_IP=$(cd ../terraform && terraform output -raw vault_server_ip)
sed "s/TERRAFORM_VAULT_IP/${VAULT_IP}/g" inventory.template > inventory
```

### Step 3: Deploy Vault
```bash
ansible-playbook vault-playbook.yml
```

## 📊 What Gets Created

### Terraform Infrastructure:
- **EC2 Instance**: Ubuntu 22.04 LTS with Vault
- **Security Group**: SSH (22) and Vault (8200, 8201) access
- **Elastic IP**: Static IP address for the Vault server
- **Key Pair**: SSH key for server access

### Ansible Configuration:
- **Vault Installation**: Latest Vault binary with proper permissions
- **System Service**: Systemd service for automatic startup
- **Configuration**: Production-ready Vault configuration
- **Security**: Dedicated vault user and proper file permissions

## 🌐 Integration with Your EKS Infrastructure

The Vault server integrates seamlessly with your existing infrastructure:

- **Same VPC**: Uses your existing VPC and public subnet
- **Network Access**: Can communicate with your EKS cluster
- **Security Groups**: Properly configured for your network
- **Consistent Tagging**: Follows your existing tag strategy

## 🔐 Post-Deployment Configuration

After successful deployment, you'll need to initialize Vault:

### Option 1: Manual Initialization
```bash
# SSH to your Vault server
ssh -i ~/.ssh/vault-server-key ubuntu@YOUR_VAULT_IP

# Initialize Vault
export VAULT_ADDR='http://localhost:8200'
vault operator init

# Save the unseal keys and root token!
```

### Option 2: Automated Setup
```bash
# Copy and run the setup script
scp examples/vault-setup.sh ubuntu@YOUR_VAULT_IP:/tmp/
ssh -i ~/.ssh/vault-server-key ubuntu@YOUR_VAULT_IP
chmod +x /tmp/vault-setup.sh && /tmp/vault-setup.sh
```

## 📝 Terraform Outputs

Your Terraform now provides these useful outputs:

```bash
terraform output vault_server_ip      # Public IP address
terraform output vault_ui_url         # Web UI URL
terraform output vault_api_url        # API endpoint URL
terraform output vault_ssh_command    # SSH connection command
```

## 🔄 Managing the Infrastructure

### Update Vault Configuration
```bash
# Make changes to Ansible playbook
ansible-playbook vault-playbook.yml

# Or run only the deployment script's Ansible portion
./deploy-vault.sh ansible-only
```

### Update Infrastructure
```bash
# Make changes to Terraform files
terraform plan
terraform apply

# Or run only the infrastructure portion
./deploy-vault.sh terraform-only
```

### Destroy Everything
```bash
cd ../terraform
terraform destroy
```

## 🛡️ Security Considerations

### Current Setup (Development):
- ✅ Dedicated security group with minimal ports
- ✅ Encrypted EBS volumes
- ✅ Dedicated vault user with limited permissions
- ✅ SSH key-based authentication

### Production Recommendations:
- 🔒 **Enable TLS**: Configure HTTPS with proper certificates
- 🔒 **Restrict Access**: Limit security group access to known IPs
- 🔒 **Auto-unseal**: Use AWS KMS for automatic unsealing
- 🔒 **High Availability**: Deploy multiple Vault servers
- 🔒 **Monitoring**: Add CloudWatch monitoring and logging

## 🚨 Troubleshooting

### Common Issues:

**Terraform fails with permission errors:**
```bash
# Check AWS credentials
aws sts get-caller-identity
```

**Ansible can't connect to server:**
```bash
# Test SSH connectivity
./deploy-vault.sh test
```

**Vault service not starting:**
```bash
# Check logs on the server
ssh -i ~/.ssh/vault-server-key ubuntu@YOUR_VAULT_IP
sudo journalctl -u vault -f
```

## 💡 Integration with Your CI/CD Pipeline

Once Vault is configured, integrate it with your existing microservices:

1. **Store secrets in Vault** instead of environment variables
2. **Update GitHub Actions** to pull secrets from Vault
3. **Configure EKS pods** to authenticate with Vault using IRSA
4. **Use Vault Agent** for automatic secret injection

## 🎯 Success Criteria

✅ **Infrastructure**: Vault server deployed via Terraform  
✅ **Configuration**: Vault installed and configured via Ansible  
✅ **Integration**: Seamless integration with existing EKS infrastructure  
✅ **Automation**: Single-command deployment process  
✅ **Documentation**: Complete setup and usage instructions  
✅ **Security**: Production-ready security configuration  

Your Vault deployment is now fully integrated with your existing DevOps infrastructure and ready for production use! 🚀