# Advanced Vault Configuration Examples

This directory contains additional examples and advanced configurations for HashiCorp Vault integration.

## Files in this directory:

### `github-actions-vault.yml`
Complete GitHub Actions workflow example showing how to:
- Retrieve secrets from Vault using the hashicorp/vault-action
- Use secrets securely in CI/CD pipeline
- Deploy applications with secret management

### `vault-setup.sh`
Automated script for post-deployment Vault configuration:
- Initialize Vault automatically
- Create initial secrets and policies
- Generate CI/CD tokens
- Provide configuration summary

## Advanced Examples

### Using Multiple Secret Engines

```bash
# Enable different secret engines
vault secrets enable -path=database database
vault secrets enable -path=aws aws
vault secrets enable -path=pki pki

# Configure database secrets engine
vault write database/config/my-mysql-database \
    plugin_name=mysql-database-plugin \
    connection_url="{{username}}:{{password}}@tcp(localhost:3306)/" \
    allowed_roles="my-role"
```

### Dynamic Secret Generation

```yaml
# GitHub Actions with dynamic secrets
- name: Get Dynamic Database Credentials
  uses: hashicorp/vault-action@v2
  with:
    url: ${{ secrets.VAULT_ADDR }}
    token: ${{ secrets.VAULT_TOKEN }}
    secrets: |
      database/creds/my-role username | DB_USERNAME ;
      database/creds/my-role password | DB_PASSWORD
```

### Authentication Methods

```bash
# Enable GitHub authentication
vault auth enable github
vault write auth/github/config organization=myorg

# Enable AWS IAM authentication
vault auth enable aws
vault write auth/aws/config/client secret_key=... access_key=...
```

### Vault Agent Configuration

```hcl
# vault-agent.hcl
pid_file = "./pidfile"

vault {
  address = "http://vault.example.com:8200"
}

auto_auth {
  method "aws" {
    mount_path = "auth/aws"
    config = {
      type = "iam"
      role = "my-role"
    }
  }

  sink "file" {
    config = {
      path = "/tmp/vault-token"
    }
  }
}

template {
  source      = "/etc/myapp/config.tpl"
  destination = "/etc/myapp/config.yaml"
  command     = "systemctl reload myapp"
}
```

## Security Best Practices

1. **Least Privilege**: Create minimal policies for each use case
2. **Token TTL**: Use short-lived tokens where possible
3. **Audit Logging**: Enable comprehensive audit logs
4. **Network Security**: Use TLS and restrict network access
5. **Regular Rotation**: Implement secret and token rotation

## Usage Instructions

1. Run vault-setup.sh after Ansible deployment
2. Configure GitHub secrets with provided values
3. Use the example workflow as a template
4. Customize policies based on your needs