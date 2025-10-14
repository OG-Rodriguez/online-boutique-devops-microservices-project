#!/bin/bash

# Integrated Deployment Script for Vault Infrastructure and Configuration
# This script deploys infrastructure with Terraform and configures Vault with Ansible

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
TERRAFORM_DIR="/mnt/c/online-boutique-devops-microservices-project-oldfiles - Copy/terraform"
ANSIBLE_DIR="."
SSH_KEY_NAME="vault-server-key"

echo -e "${GREEN}🚀 Starting Vault Infrastructure and Configuration Deployment${NC}"
echo "=================================================="

# Function to check prerequisites
check_prerequisites() {
    echo -e "${BLUE}📋 Checking prerequisites...${NC}"
    
    # Check if Terraform is installed
    if ! command -v terraform &> /dev/null; then
        echo -e "${RED}❌ Terraform is not installed${NC}"
        exit 1
    fi
    
    # Check if Ansible is installed
    if ! command -v ansible &> /dev/null; then
        echo -e "${RED}❌ Ansible is not installed${NC}"
        exit 1
    fi
    
    # Check if SSH key exists
    if [ ! -f ~/.ssh/${SSH_KEY_NAME} ]; then
        echo -e "${YELLOW}⚠️  SSH key not found. Generating new key pair...${NC}"
        ssh-keygen -t rsa -b 4096 -f ~/.ssh/${SSH_KEY_NAME} -N ""
        echo -e "${GREEN}✅ SSH key pair generated: ~/.ssh/${SSH_KEY_NAME}${NC}"
    fi
    
    echo -e "${GREEN}✅ Prerequisites check completed${NC}"
}

# Function to deploy infrastructure with Terraform
deploy_infrastructure() {
    echo -e "\n${BLUE}🏗️  Deploying infrastructure with Terraform...${NC}"
    
    cd "$TERRAFORM_DIR"
    
    # Check if terraform.tfvars exists
    if [ ! -f terraform.tfvars ]; then
        echo -e "${YELLOW}⚠️  terraform.tfvars not found. Creating from template...${NC}"
        if [ -f terraform.tfvars.template ]; then
            cp terraform.tfvars.template terraform.tfvars
            echo -e "${YELLOW}📝 Please edit terraform.tfvars with your values and run this script again${NC}"
            exit 1
        fi
    fi
    
    # Add vault public key to terraform.tfvars if not present
    if ! grep -q "vault_public_key" terraform.tfvars; then
        echo -e "${YELLOW}📝 Adding Vault public key to terraform.tfvars...${NC}"
        echo "" >> terraform.tfvars
        echo "# Vault Server Configuration" >> terraform.tfvars
        echo "vault_public_key = \"$(cat ~/.ssh/${SSH_KEY_NAME}.pub)\"" >> terraform.tfvars
    fi
    
    # Initialize Terraform
    echo -e "${BLUE}🔧 Initializing Terraform...${NC}"
    terraform init
    
    # Plan the deployment
    echo -e "${BLUE}📋 Planning Terraform deployment...${NC}"
    terraform plan -out=tfplan
    
    # Apply the deployment
    echo -e "${BLUE}🚀 Applying Terraform deployment...${NC}"
    terraform apply tfplan
    
    echo -e "${GREEN}✅ Infrastructure deployment completed${NC}"
    cd - > /dev/null
}

# Function to extract Terraform outputs and update Ansible inventory
update_ansible_inventory() {
    echo -e "\n${BLUE}📝 Updating Ansible inventory...${NC}"
    
    cd "$TERRAFORM_DIR"
    
    # Extract Terraform outputs
    VAULT_IP=$(terraform output -raw vault_server_ip)
    VAULT_UI_URL=$(terraform output -raw vault_ui_url)
    VAULT_API_URL=$(terraform output -raw vault_api_url)
    
    cd - > /dev/null
    
    # Update inventory file
    cat > inventory << EOF
[vault_servers]
vault-server ansible_host=${VAULT_IP} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/${SSH_KEY_NAME}

[vault_servers:vars]
ansible_python_interpreter=/usr/bin/python3

# Vault connection details
vault_ui_url=${VAULT_UI_URL}
vault_api_url=${VAULT_API_URL}
EOF
    
    echo -e "${GREEN}✅ Ansible inventory updated with Terraform outputs${NC}"
    echo -e "${BLUE}Server IP: $VAULT_IP${NC}"
    echo -e "${BLUE}Vault UI: $VAULT_UI_URL${NC}"
}

# Function to test connectivity
test_connectivity() {
    echo -e "\n${BLUE}🔗 Testing connectivity to Vault server...${NC}"
    
    # Extract IP from inventory
    VAULT_IP=$(grep ansible_host inventory | cut -d'=' -f2 | cut -d' ' -f1)
    
    # Wait for server to be ready
    echo -e "${YELLOW}⏳ Waiting for server to be ready (this may take a few minutes)...${NC}"
    
    for i in {1..30}; do
        if ssh -i ~/.ssh/${SSH_KEY_NAME} -o ConnectTimeout=5 -o StrictHostKeyChecking=no ubuntu@${VAULT_IP} "echo 'Server is ready'" &> /dev/null; then
            echo -e "${GREEN}✅ Server is ready for Ansible configuration${NC}"
            break
        fi
        
        if [ $i -eq 30 ]; then
            echo -e "${RED}❌ Server is not responding after 5 minutes${NC}"
            exit 1
        fi
        
        echo -n "."
        sleep 10
    done
    
    # Test Ansible connectivity
    echo -e "${BLUE}🧪 Testing Ansible connectivity...${NC}"
    ansible vault_servers -m ping
    
    echo -e "${GREEN}✅ Connectivity test completed${NC}"
}

# Function to deploy Vault with Ansible
deploy_vault() {
    echo -e "\n${BLUE}⚙️  Deploying and configuring Vault with Ansible...${NC}"
    
    # Run the Ansible playbook
    ansible-playbook vault-playbook.yml -v
    
    echo -e "${GREEN}✅ Vault deployment and configuration completed${NC}"
}

# Function to display post-deployment information
show_completion_info() {
    echo -e "\n${GREEN}🎉 Deployment completed successfully!${NC}"
    echo "=============================================="
    
    cd "$TERRAFORM_DIR"
    VAULT_IP=$(terraform output -raw vault_server_ip)
    VAULT_UI_URL=$(terraform output -raw vault_ui_url)
    SSH_COMMAND=$(terraform output -raw vault_ssh_command)
    cd - > /dev/null
    
    echo -e "${BLUE}📊 Deployment Summary:${NC}"
    echo "Server IP: $VAULT_IP"
    echo "Vault UI: $VAULT_UI_URL"
    echo "SSH Command: $SSH_COMMAND"
    echo ""
    echo -e "${YELLOW}🔧 Next Steps:${NC}"
    echo "1. Initialize Vault:"
    echo "   ssh -i ~/.ssh/${SSH_KEY_NAME} ubuntu@${VAULT_IP}"
    echo "   export VAULT_ADDR='http://localhost:8200'"
    echo "   vault operator init"
    echo ""
    echo "2. Or use the automated setup script:"
    echo "   scp examples/vault-setup.sh ubuntu@${VAULT_IP}:/tmp/"
    echo "   ssh -i ~/.ssh/${SSH_KEY_NAME} ubuntu@${VAULT_IP}"
    echo "   chmod +x /tmp/vault-setup.sh && /tmp/vault-setup.sh"
    echo ""
    echo -e "${GREEN}✨ Your Vault server is ready!${NC}"
}

# Main execution flow
main() {
    check_prerequisites
    deploy_infrastructure
    update_ansible_inventory
    test_connectivity
    deploy_vault
    show_completion_info
}

# Handle script arguments
case "${1:-}" in
    "terraform-only")
        check_prerequisites
        deploy_infrastructure
        update_ansible_inventory
        ;;
    "ansible-only")
        test_connectivity
        deploy_vault
        ;;
    "test")
        test_connectivity
        ;;
    *)
        main
        ;;
esac