# Troubleshooting and Current Caveats

This document lists issues and behaviors visible directly in the delivered codebase.

## Ansible configuration path mismatch

### Code

`Tofu/providers.tf` invokes Ansible with:

```text
ANSIBLE_CONFIG=${path.module}/../Ansible/config/ansible.cfg
```

### Repository

The delivered file is:

```text
Ansible/ansible.cfg
```

There is no `Ansible/config/ansible.cfg` in the archive.

### Impact

The intended OpenTofu-to-Ansible automation is not fully portable until that path and the repository layout agree.

## Collection dependency mismatch

`requirements.yml` installs:

```text
ansible.mysql
```

Active task FQCNs include:

```text
ansible.posix.firewalld
ansible.posix.seboolean
community.mysql.mysql_user
```

A controller that already has compatible collections may work, but the delivered `requirements.yml` alone does not explicitly list every active FQCN namespace.

## OpenTofu does not re-run Ansible for every role change

`terraform_data.run_ansible` is replaced when these change:

- `var.VMS`
- `Ansible/requirements.yml`
- `Ansible/main.yml`

It does not currently hash role task files or Jinja templates. Editing only a role/template may therefore leave the `terraform_data` resource unchanged.

## Golden-image variable is not wired to storage.tf

The project declares and sets `vm_base_image_path`, but `storage.tf` currently uses a hard-coded URL:

```text
file:///home/gesora/Templates/al9-golden-build.qcow2
```

Changing the variable alone will not change that resource source.

## Unused variables

The delivered active resources do not reference:

```text
vm_pool_path
vm_base_template_name
vm_base_image_path
vm_disk_capacity
```

These may represent earlier/refactoring intent but are not active inputs to current resources.

## Duplicate PXC certificate distribution

`percona_bootstraper` already:

- creates controller buffer
- fetches runtime TLS files
- distributes them

Later, `certificates_copy` repeats the fetch/copy workflow for nodes 02/03.

This is redundant in the current playbook but is documented as implemented behavior.

## Duplicate firewalld task

`percona_install` contains the `4567-4568/tcp` rule twice.

## Package/install errors are ignored in several tasks

`percona_install` uses `ignore_errors: true` for multiple repository/package initialization commands. This can allow the playbook to continue after an installation failure and make the later error appear unrelated.

## MySQL initialization behavior

The code explicitly runs:

```text
/usr/sbin/mysqld --initialize --user=mysql
```

only on nodes 02 and 03.

Node 01 bootstrap logic expects a temporary root password to be discoverable in `/var/log/mysqld.log`.

If that log does not contain a `temporary password` entry, the root-password task will not have a usable value.

## TLS validation

The bootstrap role itself verifies node 01's server certificate with `openssl verify`.

If Galera reports certificate signature failures between nodes, compare the runtime files across all nodes:

```bash
sha256sum \
  /etc/mysql/certs/ca.pem \
  /etc/mysql/certs/server-cert.pem \
  /etc/mysql/certs/server-key.pem
```

The current automation is designed to distribute one shared runtime certificate set from node 01.

## PXC health is not asserted automatically

The playbook starts services but does not wait for or assert:

```text
wsrep_cluster_size = 3
wsrep_cluster_status = Primary
wsrep_local_state_comment = Synced
```

These should be checked after deployment while the project remains in its current form.

## Unused legacy template

`Ansible/roles/database_init_start/templates/bootstrap.cnf.j2` exists but is not rendered by the active role.

It contains older settings including:

```text
default-authentication-plugin=mysql_native_password
wsrep_slave_threads=8
```

Those values do not represent the active PXC templates in `Ansible/templates/`, which use `wsrep_applier_threads` and do not set the removed default-authentication-plugin option.

## Local artifacts in archive

The delivered ZIP includes `.vault_pass`, state, `.terraform`, and `terraform.tfvars` even though ignore rules exist. Do not infer public-repository safety from `.gitignore` alone; check tracked files and history before publishing.
