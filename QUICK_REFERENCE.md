# Online Boutique - Quick Reference

## Starting the Application

### Step 1: Create Infrastructure (if destroyed)
```powershell
# Navigate to terraform directory
cd terraform

# Initialize, plan, and apply infrastructure
terraform init
terraform plan
terraform apply
# Type 'yes' when prompted
```

### Step 2: Configure kubectl
```powershell
# Configure kubectl (run once per machine or after infrastructure recreation)
aws eks update-kubeconfig --region us-east-2 --name online-boutique-cluster
```

### Step 3: Deploy Application
```powershell
# Navigate to project directory
cd C:\online-boutique-devops-microservices-project

# Deploy all microservices
kubectl apply -k kustomize/

# Ensure LoadBalancer service exists
kubectl apply -f kustomize/base/frontend.yaml

# Get application URL
kubectl get service frontend-external
```

### Check Status
```powershell
# Check all pods
kubectl get pods

# Check services
kubectl get services

# Check specific service
kubectl get service frontend-external

# Detailed pod information
kubectl describe pod <pod-name>
```

## Destroying Resources

### Delete Application Only
```powershell
# Delete Kubernetes resources
kubectl delete -k kustomize/

# Or delete everything in default namespace
kubectl delete all --all -n default
```

### Delete Everything (Application + Infrastructure)
```powershell
# 1. Delete Kubernetes application first
kubectl delete -k kustomize/

# 2. Wait 2-3 minutes for LoadBalancer cleanup

# 3. Destroy AWS infrastructure
cd terraform
terraform destroy
# Type 'yes' when prompted
```

## Monitoring & Troubleshooting

### View Logs
```powershell
# View logs for specific service
kubectl logs deployment/frontend
kubectl logs deployment/cartservice

# Follow logs in real-time
kubectl logs -f deployment/frontend
```

### Scale Services
```powershell
# Scale a service
kubectl scale deployment frontend --replicas=3

# Check scaling
kubectl get pods -l app=frontend
```

### Port Forward (for local testing)
```powershell
# Forward local port to service
kubectl port-forward service/frontend 8080:80

# Access via http://localhost:8080
```

## Infrastructure Info

- **Cluster Name**: online-boutique-cluster
- **Region**: us-east-2
- **Node Group**: online-boutique-node-group
- **ECR Registry**: 094121082922.dkr.ecr.us-east-2.amazonaws.com

## Important Notes

1. Always delete LoadBalancer services before destroying Terraform infrastructure
2. The application uses Google's pre-built container images
3. ECR repositories are available for custom images if needed
4. LoadBalancer URL changes each time it's recreated