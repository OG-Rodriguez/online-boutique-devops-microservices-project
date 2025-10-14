# 🚀 Online Boutique + HashiCorp Vault - Deployment Commands Reference

## 📋 Prerequisites Setup

### Initial Environment Setup (WSL Ubuntu)
```bash
# Configure Python environment if needed
configure_python_environment

# Install/Update kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
export PATH="/usr/local/bin:$PATH"
echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.bashrc

# Configure AWS CLI (if not already done)
aws configure
```

---

## 🏗️ **STARTING EVERYTHING** (Complete Infrastructure)

### Step 1: Deploy Infrastructure with Terraform
```bash
# Navigate to terraform directory (use native Linux filesystem for best performance)
cp -r "/mnt/c/online-boutique-devops-microservices-project-oldfiles - Copy/terraform" ~/terraform-vault
cd ~/terraform-vault

# Initialize and deploy infrastructure
terraform init
terraform plan
terraform apply

# Get cluster information
terraform output
```

### Step 2: Configure kubectl for EKS
```bash
# Update kubeconfig to connect to EKS cluster
aws eks update-kubeconfig --region us-east-2 --name online-boutique-cluster

# Verify connection
kubectl get nodes
```

### Step 3: Deploy Online Boutique Application
```bash
# Navigate to project root
cd "/mnt/c/online-boutique-devops-microservices-project-oldfiles - Copy"

# Deploy application using kustomize
kubectl apply -k kustomize/

# Ensure LoadBalancer service is created
kubectl apply -f kustomize/base/frontend.yaml

# Wait for pods to be ready (may take 2-5 minutes)
kubectl get pods -w
# Press Ctrl+C when pods are running
```

### Step 4: Get Application URLs
```bash
# Get Online Boutique URL
kubectl get service frontend-external

# Get Vault information (from terraform output)
cd ~/terraform-vault
terraform output vault_ui_url
terraform output vault_server_ip
```

### Step 5: Initialize HashiCorp Vault (First Time Only)
```bash
# SSH to Vault server
ssh -i ~/.ssh/vault-server-key ubuntu@$(terraform output -raw vault_server_ip)

# Run the automated setup script
chmod +x /tmp/vault-setup.sh && /tmp/vault-setup.sh

# Save the unseal keys and root token from:
cat vault-init-output.txt

# Exit SSH session
exit
```

---

## ✅ **CHECKING STATUS** (Everything Running)

### Check Infrastructure Status
```bash
# Check EKS cluster nodes
kubectl get nodes

# Check all running pods
kubectl get pods --all-namespaces

# Check services and external IPs
kubectl get services --all-namespaces
```

### Check Application URLs
```bash
# Online Boutique Application
kubectl get service frontend-external

# HashiCorp Vault
cd ~/terraform-vault
terraform output vault_ui_url
```

### Check Vault Status
```bash
# SSH to Vault server
ssh -i ~/.ssh/vault-server-key ubuntu@$(cd ~/terraform-vault && terraform output -raw vault_server_ip)

# Check Vault status
export VAULT_ADDR='http://localhost:8200'
vault status

# Exit SSH session
exit
```

---

## 🛑 **STOPPING EVERYTHING** (Safe Shutdown)

### Option 1: Stop Application Only (Keep Infrastructure)
```bash
# Navigate to project root
cd "/mnt/c/online-boutique-devops-microservices-project-oldfiles - Copy"

# Delete the Kubernetes application
kubectl delete -k kustomize/

# Or delete everything in the default namespace
kubectl delete all --all -n default
```

### Option 2: Destroy Everything (Complete Teardown)
```bash
# Step 1: Delete Kubernetes application first
cd "/mnt/c/online-boutique-devops-microservices-project-oldfiles - Copy"
kubectl delete -k kustomize/

# Step 2: Wait for LoadBalancer cleanup (IMPORTANT!)
echo "⏳ Waiting 60 seconds for AWS LoadBalancer cleanup..."
sleep 60

# Step 3: Destroy all infrastructure
cd ~/terraform-vault
terraform destroy
# Type 'yes' when prompted

# Step 4: Clean up local terraform copy (optional)
rm -rf ~/terraform-vault
```

---

## 🔐 **VAULT-SPECIFIC COMMANDS**

### Access Vault UI
```bash
# Get Vault URL
cd ~/terraform-vault
terraform output vault_ui_url
# Open this URL in your browser and login with root token
```

### Vault CLI Commands
```bash
# SSH to Vault server
ssh -i ~/.ssh/vault-server-key ubuntu@$(cd ~/terraform-vault && terraform output -raw vault_server_ip)

# Set Vault address
export VAULT_ADDR='http://localhost:8200'

# Login with root token
vault login
# Enter your root token when prompted

# Basic Vault operations
vault status
vault secrets list
vault auth list

# Example: Store a secret
vault kv put secret/myapp username=admin password=secret123

# Example: Retrieve a secret
vault kv get secret/myapp

# Exit SSH session
exit
```

---

## 🚨 **IMPORTANT NOTES**

### Terraform Destroy Warnings
- ⚠️ **ALWAYS** delete Kubernetes LoadBalancer services before running `terraform destroy`
- ⚠️ LoadBalancers create AWS resources that Terraform doesn't track
- ⚠️ Wait at least 60 seconds after deleting Kubernetes services before destroying infrastructure
- ⚠️ You'll be prompted to confirm destruction - type `yes`

### Vault Security
- 🔐 **SAVE** your Vault unseal keys and root token securely
- 🔐 You need 3 of 5 unseal keys to unseal Vault if it gets sealed
- 🔐 Root token provides full administrative access
- 🔐 Vault data is stored on the EC2 instance in `/opt/vault/data`

### Cost Optimization
- 💰 Remember to destroy resources when not needed to avoid AWS charges
- 💰 EKS cluster, EC2 instances, and LoadBalancers incur ongoing costs
- 💰 Consider stopping (not destroying) for temporary shutdowns

---

## 🔗 **Quick Access URLs** (After Deployment)

Once everything is running, you'll have:

1. **Online Boutique Application**: 
   - Get URL: `kubectl get service frontend-external`
   - Example: `http://aedf8e8410ec84785b3a7a1aff2a08c7-17630928.us-east-2.elb.amazonaws.com`

2. **HashiCorp Vault UI**: 
   - Get URL: `cd ~/terraform-vault && terraform output vault_ui_url`
   - Example: `http://3.147.124.108:8200`

3. **Vault SSH Access**: 
   - Command: `ssh -i ~/.ssh/vault-server-key ubuntu@<vault-server-ip>`

---

## 📞 **Troubleshooting Quick Commands**

```bash
# Check pod logs if something isn't working
kubectl logs <pod-name>

# Describe a problematic pod
kubectl describe pod <pod-name>

# Check events
kubectl get events --sort-by=.metadata.creationTimestamp

# Restart a deployment
kubectl rollout restart deployment/<deployment-name>

# Check terraform state
cd ~/terraform-vault
terraform state list
terraform show
```

---

**📝 Keep this reference handy for managing your complete infrastructure!**