# Security and Secrets

This document separates security controls implemented by the code from publication risks present in the delivered archive.

## Implemented Guest Security Controls

### SSH

cloud-init configures:

- locked password for `almalinux`
- SSH public-key authentication
- `ssh_pwauth = false`
- root disabled
- passwordless sudo for the `almalinux` user

### Firewall

firewalld is installed, enabled, and configured for the PXC/Galera service ports used by this project.

### SELinux

The automation keeps SELinux-aware operations in the workflow:

- `restorecon` is run against distributed TLS files
- `mysql_connect_any` is enabled persistently on node 01

### PXC/Galera TLS

Node 01 generates a self-signed CA and a CA-signed server certificate.

Runtime cluster files:

```text
ca.pem
server-cert.pem
server-key.pem
```

The server private key uses mode `0600` and MySQL ownership.

The templates enable encrypted cluster traffic and encrypted XtraBackup SST.

### MySQL Authentication

The MaxScale account is configured with:

```text
caching_sha2_password
```

rather than `mysql_native_password`.

### Ansible Secrets

`Ansible/secrets/secrets.yml` is encrypted with Ansible Vault and loaded by the plays that require credentials.

## Publication Risks in the Delivered ZIP

The supplied archive contains several local files that should not be part of a public portfolio repository:

```text
Ansible/.vault_pass
Tofu/terraform.tfstate
Tofu/terraform.tfstate.backup
Tofu/.terraform/
Tofu/terraform.tfvars
```

The existing ignore rules indicate these are intended to stay local.

### Why these files matter

- `.vault_pass` can unlock the Ansible Vault file.
- Terraform/OpenTofu state can contain infrastructure metadata and, depending on resources, sensitive values.
- `.terraform/` contains provider runtime artifacts rather than source code.
- `terraform.tfvars` contains workstation/environment-specific values and should generally be replaced by an example file for a public portfolio.

This documentation update does not delete or rotate those files because the request was to update documentation based on the delivered code.

## Existing Ignore Rules

`Ansible/.gitignore` excludes:

```text
secrets/
.vault_pass
```

`Tofu/.gitignore` excludes:

```text
*.tfstate
*.tfstate.*
.terraform/
crash.log
crash.*.log
*.tfvars
*.tfvars.json
```

## Recommended Publication Check

Before publishing a refreshed repository, verify both the working tree and Git history for local/sensitive artifacts.

The current archive contains a `.git` directory, so a clean working tree alone does not establish that a file was never committed historically.

Do not expose the Vault password file publicly. If it has ever been published, treat the associated Vault secrets as potentially exposed and rotate credentials as appropriate.
