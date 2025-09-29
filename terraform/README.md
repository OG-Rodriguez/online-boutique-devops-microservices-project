<!--
Copyright 2022 Google LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
-->

# Deploy Online Boutique on AWS EKS using Terraform

This project is a refactored version of the [Online Boutique](https://github.com/GoogleCloudPlatform/microservices-demo) sample application originally designed for Google Kubernetes Engine (GKE). It has been adapted to deploy infrastructure on **Amazon Web Services (AWS)** using **Terraform** and **Amazon EKS**.

## Refactor Summary

- Original repo: [`GoogleCloudPlatform/microservices-demo`](https://github.com/GoogleCloudPlatform/microservices-demo)
- Refactored to use:
  - AWS EKS instead of GKE
  - AWS VPC, subnets, IAM roles, and ECR
  - Modular Terraform files (`main.tf`, `variables.tf`, `outputs.tf`)
  - Infrastructure as Code (IaC) best practices

## Prerequisites

1. **AWS Account** with programmatic access (IAM user or role)
2. **AWS CLI** configured with credentials:
   ```powershell
   aws configure
   ```
3. **Terraform** installed (v1.6+ recommended)
4. **kubectl** installed for interacting with EKS

**Note**: All required IAM roles are automatically created by Terraform - no manual IAM setup required!

## Deploy the Complete Solution

### Step 1: Deploy Infrastructure

1. Navigate to the terraform directory:
   ```powershell
   cd terraform
   ```

2. Initialize Terraform:
   ```powershell
   terraform init
   ```

3. Preview the infrastructure:
   ```powershell
   terraform plan
   ```

4. Apply the configuration:
   ```powershell
   terraform apply
   ```
   Type `yes` when prompted.

5. Terraform will output:
   - EKS cluster name and endpoint
   - ECR repository URLs
   - IAM role ARNs

### Step 2: Deploy the Application

1. Configure kubectl to connect to your EKS cluster:
   ```powershell
   aws eks update-kubeconfig --region us-east-2 --name online-boutique-cluster
   ```

2. Verify cluster connectivity:
   ```powershell
   kubectl get nodes
   ```

3. Deploy all microservices using kustomize:
   ```powershell
   kubectl apply -k kustomize/
   ```

4. Create the LoadBalancer service for external access:
   ```powershell
   kubectl apply -f kustomize/base/frontend.yaml
   ```

5. Get the application URL:
   ```powershell
   kubectl get service frontend-external
   ```
   The `EXTERNAL-IP` column will show your LoadBalancer URL.

### Step 3: Access Your Application

Visit the LoadBalancer URL in your browser to see the Online Boutique e-commerce demo!

## Clean Up

**Important**: Always delete Kubernetes resources before destroying infrastructure!

### Step 1: Delete Application
```powershell
kubectl delete -k kustomize/
```

### Step 2: Wait for LoadBalancer Cleanup
Wait 2-3 minutes for AWS to clean up the LoadBalancer resources.

### Step 3: Destroy Infrastructure
```powershell
terraform destroy
```
Type `yes` when prompted.

This will remove:
* EKS cluster and node groups
* VPC, subnets, and networking components
* ECR repositories
* IAM roles and policies
* All associated AWS resources

## Architecture Overview

**Infrastructure Components:**
- **EKS Cluster**: Kubernetes control plane
- **Worker Nodes**: t3.small instances with autoscaling
- **VPC**: Custom VPC with public/private subnets across 2 AZs
- **ECR**: Container registries for all microservices
- **LoadBalancer**: AWS ELB for external access

**Application Components:**
- **12 Microservices**: Frontend, cart, checkout, payment, etc.
- **Redis**: In-cluster cache for cart service
- **gRPC Communication**: Inter-service communication
- **Load Generator**: Simulates realistic traffic

## Troubleshooting

**Common Issues:**

1. **Pods in ImagePullBackOff**: Uses Google's pre-built images by default
2. **LoadBalancer Pending**: Check security groups and subnet tags
3. **Permission Errors**: Verify AWS CLI credentials and region
4. **Terraform Destroy Fails**: Ensure all Kubernetes LoadBalancer services are deleted first

**Useful Commands:**
```powershell
# Check pod status
kubectl get pods

# View pod logs
kubectl logs deployment/frontend

# Check services
kubectl get services

# Scale deployment
kubectl scale deployment frontend --replicas=3
```

## Container Images

**Current Setup**: Uses Google's pre-built container images from Google Artifact Registry. This allows immediate deployment without building custom images.

**Custom Images** (Optional): 
If you want to build and use your own container images:

1. Install Docker Desktop
2. Authenticate with ECR:
   ```powershell
   aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin <ecr-url>
   ```
3. Build and push images for each microservice in `src/` directory
4. Update Kubernetes manifests to use your ECR image URLs

## Notes

* **Cost Optimization**: EKS cluster costs ~$0.10/hour + EC2 nodes (~$0.04/hour for t3.small)
* **Production Ready**: Includes autoscaling, security groups, and proper IAM roles
* **Reproducible**: Complete Infrastructure as Code with Terraform
* **Educational**: Great for learning microservices, Kubernetes, and AWS
* **Modular**: Easy to extend with monitoring, CI/CD, or additional services

For detailed commands and troubleshooting, see `QUICK_REFERENCE.md` in the root directory.


