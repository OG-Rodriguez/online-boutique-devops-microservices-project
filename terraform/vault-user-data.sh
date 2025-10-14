#!/bin/bash

# HashiCorp Vault Server User Data Script
# This script does basic server preparation before Ansible takes over

set -e

# Update system packages
apt-get update
apt-get upgrade -y

# Install basic dependencies
apt-get install -y \
    unzip \
    curl \
    jq \
    wget \
    python3 \
    python3-pip

# Install Python packages needed for Ansible
pip3 install boto3

# Create vault user (Ansible will configure this properly)
if ! id -u vault >/dev/null 2>&1; then
    useradd --system --shell /bin/false --home /opt/vault vault
fi

# Create basic directory structure (Ansible will set proper permissions)
mkdir -p /opt/vault
mkdir -p /etc/vault.d
mkdir -p /var/log/vault

# Download Vault binary (Ansible will handle the full installation)
cd /tmp
wget https://releases.hashicorp.com/vault/${vault_version}/vault_${vault_version}_linux_amd64.zip
unzip vault_${vault_version}_linux_amd64.zip
mv vault /usr/local/bin/
chmod +x /usr/local/bin/vault

# Set up log rotation
cat > /etc/logrotate.d/vault << EOF
/var/log/vault/*.log {
    daily
    rotate 7
    compress
    missingok
    notifempty
    create 0640 vault vault
}
EOF

# Create a marker file to indicate user-data completion
touch /var/log/user-data-complete
echo "$(date): User data script completed successfully" >> /var/log/user-data-complete

# Log completion
echo "Vault server user-data setup completed at $(date)" | tee -a /var/log/vault-setup.log