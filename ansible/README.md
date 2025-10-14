# HashiCorp Vault Deployment with Ansible

This guide provides complete instructions for deploying and configuring HashiCorp Vault using Ansible for CI/CD pipeline secret management.

## Prerequisites

1. **Target Server**: An EC2 instance or similar Linux server (Ubuntu/Debian recommended)
2. **SSH Access**: SSH key-based authentication configured
3. **Ansible**: Installed on your local machine
4. **Network Access**: Port 8200 open for Vault UI and API access

## Project Structure

```
ansible/
├── inventory                 # Server inventory file
├── ansible.cfg              # Ansible configuration
├── vault-playbook.yml       # Main installation playbook
├── templates/
│   ├── vault.hcl.j2         # Vault configuration template
│   └── vault.service.j2     # Systemd service template
└── README.md                # This documentation
```

## Step 1: Prepare Your Environment

### 1.1 Update Inventory File

Edit the `inventory` file and replace placeholders with your actual values:

```ini
[vault_servers]
vault-server ansible_host=YOUR_SERVER_IP ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/your-key.pem
```

### 1.2 Update Ansible Configuration

Modify `ansible.cfg` if needed to match your SSH key path:

```ini
private_key_file = ~/.ssh/your-key.pem
```

### 1.3 Verify Server Access

Test SSH connectivity:

```bash
ansible vault_servers -m ping
```

## Step 2: Deploy Vault

Run the Ansible playbook to install and configure Vault:

```bash
ansible-playbook -i inventory vault-playbook.yml
```

The playbook will:
- Update system packages
- Install required dependencies (unzip, curl, jq)
- Create vault user and group
- Download and install Vault binary
- Configure Vault with appropriate permissions
- Create and start systemd service
- Enable Vault UI on port 8200

## Step 3: Initialize and Configure Vault

### 3.1 Initialize Vault

SSH to your server and initialize Vault:

```bash
ssh -i ~/.ssh/your-key.pem ubuntu@YOUR_SERVER_IP
export VAULT_ADDR='http://localhost:8200'
vault operator init
```

**IMPORTANT**: Save the 5 Unseal Keys and Initial Root Token securely!

Example output:
```
Unseal Key 1: AbCdEfGhIjKlMnOpQrStUvWxYz...
Unseal Key 2: BcDeFgHiJkLmNoPqRsTuVwXyZa...
Unseal Key 3: CdEfGhIjKlMnOpQrStUvWxYzAb...
Unseal Key 4: DeFgHiJkLmNoPqRsTuVwXyZaBc...
Unseal Key 5: EfGhIjKlMnOpQrStUvWxYzAbCd...

Initial Root Token: hvs.AbCdEfGhIjKlMnOpQrSt...
```

### 3.2 Unseal Vault

Unseal Vault using any 3 of the 5 keys:

```bash
vault operator unseal  # Enter Unseal Key 1
vault operator unseal  # Enter Unseal Key 2
vault operator unseal  # Enter Unseal Key 3
```

### 3.3 Access Vault UI

1. Open your browser and navigate to: `http://YOUR_SERVER_IP:8200`
2. Log in using the Initial Root Token
3. Verify the UI is accessible and functional

## Step 4: Configure Vault for CI/CD

### 4.1 Enable Key-Value Secret Engine

```bash
# Login with root token
vault auth -method=token token=YOUR_ROOT_TOKEN

# Enable KV v2 secret engine
vault secrets enable -path=secret kv-v2
```

### 4.2 Create Test Secrets

Create a test secret for your pipeline:

```bash
vault kv put secret/webapp db_password="MiPasswordSuperSeguro123!" api_key="my-secret-api-key"
```

### 4.3 Create Access Policy

Create a policy file for CI/CD access:

```bash
# Create policy file
cat > cicd-policy.hcl << EOF
# Policy for CI/CD pipeline access
path "secret/data/webapp" {
  capabilities = ["read"]
}

path "secret/data/webapp/*" {
  capabilities = ["read"]
}
EOF

# Apply the policy
vault policy write cicd-policy cicd-policy.hcl
```

### 4.4 Create CI/CD Token

Generate a token with limited permissions:

```bash
vault token create -policy=cicd-policy -ttl=87600h -display-name="cicd-pipeline"
```

Save the generated token for GitHub Actions configuration.

## Step 5: GitHub Actions Integration

### 5.1 Configure GitHub Secrets

In your GitHub repository, go to **Settings > Secrets and variables > Actions** and add:

- `VAULT_ADDR`: `http://YOUR_SERVER_IP:8200`
- `VAULT_TOKEN`: The CI/CD token created above

### 5.2 Example Workflow Usage

See the example workflow in the next section for implementation details.

## Security Considerations

1. **Network Security**: Ensure port 8200 is only accessible from trusted sources
2. **TLS**: For production, enable TLS encryption
3. **Token Management**: Regularly rotate CI/CD tokens
4. **Backup**: Securely backup unseal keys and root token
5. **Monitoring**: Enable audit logging for production use

## Troubleshooting

### Common Issues

1. **Vault service not starting**: Check logs with `sudo journalctl -u vault -f`
2. **Permission issues**: Verify vault user owns data directories
3. **Network connectivity**: Ensure security groups allow port 8200
4. **Unseal required**: Vault needs to be unsealed after restart

### Useful Commands

```bash
# Check Vault status
vault status

# View logs
sudo journalctl -u vault -f

# Restart service
sudo systemctl restart vault

# Check service status
sudo systemctl status vault
```

## Production Recommendations

For production deployments, consider:

1. **High Availability**: Deploy multiple Vault nodes with shared storage
2. **Auto-unseal**: Use cloud KMS for automatic unsealing
3. **TLS Encryption**: Enable HTTPS with proper certificates
4. **Monitoring**: Implement comprehensive logging and monitoring
5. **Backup Strategy**: Regular encrypted backups of Vault data
6. **Network Security**: Use private subnets and proper firewall rules

## Next Steps

After successful deployment:

1. Configure additional secret engines as needed
2. Set up authentication methods (LDAP, AWS IAM, etc.)
3. Implement secret rotation policies
4. Configure audit logging
5. Set up monitoring and alerting