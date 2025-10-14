# 🚀 **QUICK START/STOP GUIDE** - Step-by-Step Order

## 🏗️ **FIRST-TIME SETUP** (Infrastructure Creation)

### Step 1: Setup Environment
```bash
# Start WSL Ubuntu terminal
# Navigate to terraform directory
cp -r "/mnt/c/online-boutique-devops-microservices-project-oldfiles - Copy/terraform" ~/terraform-vault
cd ~/terraform-vault
```

### Step 2: Deploy Infrastructure with Terraform
```bash
terraform init
terraform plan
terraform apply
# Type 'yes' when prompted
```

### Step 3: Initialize Vault (First Time Only)
```bash
# Copy and run the deployment script
cp "/mnt/c/online-boutique-devops-microservices-project-oldfiles - Copy/ansible/deploy-vault.sh" ~/ansible-vault-project/
cd ~/ansible-vault-project
./deploy-vault.sh

# SSH to Vault and save credentials
ssh -i ~/.ssh/vault-server-key ubuntu@$(cd ~/terraform-vault && terraform output -raw vault_server_ip)
cat vault-init-output.txt  # SAVE THESE CREDENTIALS!
exit
```

---

## 🔄 **DAILY USAGE** (Start/Stop Applications)

### 🚀 **TO START EVERYTHING:**

#### Step 1: Configure kubectl
```bash
# Can run from any directory
aws eks update-kubeconfig --region us-east-2 --name online-boutique-cluster
```

#### Step 2: Navigate to Project
```bash
cd "/mnt/c/online-boutique-devops-microservices-project-oldfiles - Copy"
```

#### Step 3: Start Application
```bash
kubectl apply -k kustomize/
```

#### Step 4: Get URLs
```bash
# Online Boutique URL
kubectl get service frontend-external

# Vault URL (if needed)  
cd ~/terraform-vault
terraform output vault_ui_url
```

### 🛑 **TO STOP APPLICATION ONLY** (Keep Infrastructure):
```bash
cd "/mnt/c/online-boutique-devops-microservices-project-oldfiles - Copy"
kubectl delete -k kustomize/
```

---

## 💥 **COMPLETE TEARDOWN** (Stop AWS Billing)

### ⚠️ **Step 1: Delete Application First** (CRITICAL ORDER!)
```bash
cd "/mnt/c/online-boutique-devops-microservices-project-oldfiles - Copy"
kubectl delete -k kustomize/

# Verify LoadBalancer is gone
kubectl get services
```

### ⏳ **Step 2: Wait for AWS Cleanup** (IMPORTANT!)
```bash
echo "⏳ Waiting 60 seconds for AWS LoadBalancer cleanup..."
sleep 60
```

### 🔥 **Step 3: Destroy Infrastructure**
```bash
cd ~/terraform-vault
terraform destroy
# Type 'yes' when prompted

# Clean up local copy
rm -rf ~/terraform-vault
```

---

## 🎯 **QUICK ACCESS** (When Everything is Running)

### Application URLs:
- **Online Boutique**: `kubectl get service frontend-external`
- **Vault UI**: http://3.147.124.108:8200 (or `terraform output vault_ui_url`)

### Status Checks:
```bash
# Check if app is running
kubectl get pods

# Check services
kubectl get services

# Check Vault status
ssh -i ~/.ssh/vault-server-key ubuntu@3.147.124.108
export VAULT_ADDR='http://localhost:8200'
vault status
exit
```

---

## 💡 **REMEMBER:**

- **Infrastructure** (Terraform) = Build once, costs money while running
- **Application** (Kubernetes) = Can start/stop quickly, no extra cost
- **Vault** = Always running when infrastructure exists
- **For school projects**: Always run complete teardown when done!

## ⚠️ **CRITICAL TEARDOWN ORDER:**
1. Delete Kubernetes app FIRST
2. Wait 60 seconds
3. Then destroy Terraform infrastructure
4. This prevents orphaned AWS resources and unexpected billing!