#!/bin/bash

# HashiCorp Vault Initialization and Configuration Script
# Run this script after Ansible deployment to complete Vault setup

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}HashiCorp Vault Post-Deployment Configuration${NC}"
echo "=================================================="

# Check if VAULT_ADDR is set
if [ -z "$VAULT_ADDR" ]; then
    echo -e "${YELLOW}Setting VAULT_ADDR to localhost${NC}"
    export VAULT_ADDR='http://localhost:8200'
fi

echo -e "${GREEN}Step 1: Checking Vault status${NC}"
vault status || true

echo -e "\n${GREEN}Step 2: Initialize Vault${NC}"
echo -e "${YELLOW}IMPORTANT: Save the unseal keys and root token securely!${NC}"
read -p "Press Enter to continue with initialization..."

vault operator init > vault-init-output.txt
echo -e "${GREEN}Initialization complete. Output saved to vault-init-output.txt${NC}"

echo -e "\n${GREEN}Step 3: Extract unseal keys and root token${NC}"
UNSEAL_KEY_1=$(grep 'Unseal Key 1:' vault-init-output.txt | awk '{print $4}')
UNSEAL_KEY_2=$(grep 'Unseal Key 2:' vault-init-output.txt | awk '{print $4}')
UNSEAL_KEY_3=$(grep 'Unseal Key 3:' vault-init-output.txt | awk '{print $4}')
ROOT_TOKEN=$(grep 'Initial Root Token:' vault-init-output.txt | awk '{print $4}')

echo -e "\n${GREEN}Step 4: Unsealing Vault${NC}"
vault operator unseal $UNSEAL_KEY_1
vault operator unseal $UNSEAL_KEY_2
vault operator unseal $UNSEAL_KEY_3

echo -e "\n${GREEN}Step 5: Authenticating with root token${NC}"
vault auth -method=token token=$ROOT_TOKEN

echo -e "\n${GREEN}Step 6: Enabling KV v2 secret engine${NC}"
vault secrets enable -path=secret kv-v2

echo -e "\n${GREEN}Step 7: Creating test secrets${NC}"
vault kv put secret/webapp \
    db_password="MiPasswordSuperSeguro123!" \
    api_key="my-secret-api-key-$(date +%s)" \
    jwt_secret="jwt-secret-$(openssl rand -hex 32)"

echo -e "\n${GREEN}Step 8: Creating CI/CD policy${NC}"
cat > cicd-policy.hcl << EOF
# Policy for CI/CD pipeline access
path "secret/data/webapp" {
  capabilities = ["read"]
}

path "secret/data/webapp/*" {
  capabilities = ["read"]
}

path "secret/metadata/webapp" {
  capabilities = ["read"]
}

path "secret/metadata/webapp/*" {
  capabilities = ["read"]
}
EOF

vault policy write cicd-policy cicd-policy.hcl

echo -e "\n${GREEN}Step 9: Creating CI/CD token${NC}"
CICD_TOKEN=$(vault token create -policy=cicd-policy -ttl=87600h -display-name="cicd-pipeline" -format=json | jq -r '.auth.client_token')

echo -e "\n${GREEN}Setup Complete!${NC}"
echo "=================="
echo -e "${YELLOW}Important Information:${NC}"
echo "Vault UI: http://$(curl -s ifconfig.me):8200"
echo "Root Token: $ROOT_TOKEN"
echo "CI/CD Token: $CICD_TOKEN"
echo ""
echo -e "${YELLOW}GitHub Secrets to configure:${NC}"
echo "VAULT_ADDR: $VAULT_ADDR"
echo "VAULT_TOKEN: $CICD_TOKEN"
echo ""
echo -e "${RED}SECURITY REMINDER:${NC}"
echo "- Store unseal keys and root token securely"
echo "- Consider enabling auto-unseal for production"
echo "- Configure proper network security"
echo "- Enable audit logging for production use"

# Save configuration to file
cat > vault-config-summary.txt << EOF
Vault Configuration Summary
==========================
Vault Address: $VAULT_ADDR
Root Token: $ROOT_TOKEN
CI/CD Token: $CICD_TOKEN
Policy File: cicd-policy.hcl

Test Secret Path: secret/webapp
Available keys: db_password, api_key, jwt_secret

GitHub Secrets Configuration:
VAULT_ADDR=$VAULT_ADDR
VAULT_TOKEN=$CICD_TOKEN
EOF

echo -e "\n${GREEN}Configuration summary saved to vault-config-summary.txt${NC}"