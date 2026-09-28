# Deployment Guide

This guide follows the automation implemented in the delivered repository.

## 1. Host Requirements

The OpenTofu/Ansible controller needs:

- Linux host with KVM/QEMU/libvirt
- OpenTofu
- Ansible
- SSH client
- `nc` / netcat
- access to the configured SSH private key
- existing libvirt network `LAN` unless variables are changed
- existing libvirt pool `Virtual_Machines` unless variables are changed
- golden image at the path currently hard-coded in `Tofu/storage.tf`

The code also expects network reachability from the controller to:

```text
10.20.10.10
10.20.10.11
10.20.10.12
```

for the current tfvars.

## 2. Review Local Inputs

Current lab values are stored in `Tofu/terraform.tfvars`.

Before running on another workstation, review at least:

- `vm_pool_name`
- `vm_network_name`
- `vm_domain_name`
- `vm_gateway`
- `vm_ssh_public_key`
- `VMS`

Also review `Tofu/storage.tf`, because its base-image URL is hard-coded independently of `vm_base_image_path`.

## 3. Review Ansible Connectivity

`Ansible/inventory.yml` expects:

```text
ansible_user: almalinux
ansible_ssh_private_key_file: ~/.ssh/id_ed25519
```

The cloud-init public key and this private key need to correspond.

## 4. Review Vault Configuration

`Ansible/ansible.cfg` expects:

```text
vault_password_file = .vault_pass
```

The archive contains `.vault_pass`, but this file should be treated as a local secret and not committed/published.

The encrypted variable file is:

```text
Ansible/secrets/secrets.yml
```

The active bootstrap role expects at least values referenced as:

```text
secret.percona_root_password
secret.percona_maxscaleusr_password
```

## 5. Important Current Path Caveat

Before relying on automated Ansible execution, note that `Tofu/providers.tf` sets:

```text
ANSIBLE_CONFIG=${path.module}/../Ansible/config/ansible.cfg
```

while the archive contains:

```text
Ansible/ansible.cfg
```

There is no `Ansible/config/ansible.cfg` in the delivered tree.

This documentation records the mismatch rather than modifying the code.

## 6. Important Current Collection Caveat

OpenTofu installs `Ansible/requirements.yml`, which currently declares only:

```text
ansible.mysql
```

The active tasks also reference `ansible.posix` and `community.mysql`. On a clean controller, make sure the required FQCNs resolve in the installed environment or reconcile `requirements.yml` with the active modules before expecting a fully portable deployment.

## 7. Initialize OpenTofu

```bash
cd Tofu
tofu init
```

The lock file currently identifies libvirt provider 0.9.9.

## 8. Validate and Plan

```bash
tofu fmt -check
tofu validate
tofu plan
```

## 9. Apply

```bash
tofu apply
```

The intended automated flow after VM creation is:

```text
wait for SSH -> install Ansible collections -> run main.yml
```

You do not need a separate manual Ansible invocation when `terraform_data.run_ansible` executes successfully.

## 10. Observe Ansible Role Order

Expected playbook sequence:

```text
prerequisites_install
percona_install
percona_bootstraper
certificates_copy
database_init_start
clear_facts
```

During bootstrap, node 01 should create the CA/server TLS set before `mysql@bootstrap.service` starts.

## 11. Post-Deployment Validation

The code does not currently automate final wsrep health assertions, so validate the resulting cluster manually.

Useful SQL:

```sql
SHOW STATUS LIKE 'wsrep_cluster_size';
SHOW STATUS LIKE 'wsrep_cluster_status';
SHOW STATUS LIKE 'wsrep_local_state_comment';
```

Useful service checks:

```bash
systemctl status mysql
```

Useful TLS checks on each node:

```bash
sha256sum /etc/mysql/certs/ca.pem \
  /etc/mysql/certs/server-cert.pem \
  /etc/mysql/certs/server-key.pem
```

Because the runtime set is copied from node 01, those three files should be identical across the cluster after the copy roles finish.

Certificate verification:

```bash
openssl verify \
  -CAfile /etc/mysql/certs/ca.pem \
  /etc/mysql/certs/server-cert.pem
```

## 12. Destroy

```bash
cd Tofu
./destroy.sh
```

The wrapper runs `tofu destroy` and then removes known-host entries for the three hard-coded lab IP addresses.

## Re-running Ansible After Role-Only Changes

Current `terraform_data.run_ansible.triggers_replace` does not hash role task files or templates. Therefore an edit only inside a role/template may not cause OpenTofu to replace/re-run that `terraform_data` resource automatically.

If testing documentation/code changes, account for that trigger behavior when deciding whether OpenTofu will invoke Ansible again.
