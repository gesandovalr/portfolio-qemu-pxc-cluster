# Ansible Implementation

This document describes the active Ansible code in the delivered repository.

## Top-Level Configuration

`Ansible/ansible.cfg` currently contains:

```text
inventory = inventory.yml
collections_path = ./collections
host_key_checking = False
retry_files_enabled = False
vault_password_file = .vault_pass
```

The project therefore expects the vault password file to exist locally when Ansible runs with this configuration.

## Inventory

The `pxc` group contains:

```text
PERCDBTEST01 -> 10.20.10.10
PERCDBTEST02 -> 10.20.10.11
PERCDBTEST03 -> 10.20.10.12
```

Shared connection variables:

```text
ansible_user = almalinux
ansible_ssh_private_key_file = ~/.ssh/id_ed25519
```

`group_vars/all.yaml` sets Python to `/usr/bin/python3` and allows world-readable temporary files.

## Cluster Variables

`group_vars/deploy_info.yaml` defines:

- node IP addresses
- node FQDNs
- node short names
- wsrep cluster name `PERCDBTESTCLU01`

## Main Playbook Order

`main.yml` executes multiple plays against `all`:

```text
prerequisites_install
        |
        v
percona_install
        |
        v
percona_bootstraper
        |
        v
certificates_copy
        |
        v
database_init_start
        |
        v
clear_facts
```

The first three plays load the encrypted `secrets/secrets.yml` where needed. The certificate-copy and database-start plays only load `deploy_info.yaml`.

## requirements.yml

The delivered file contains:

```yaml
collections:
  - name: ansible.mysql
```

OpenTofu installs this into `Ansible/collections` before running the playbook.

### Current collection-name caveat

Active role tasks also invoke:

```text
ansible.posix.firewalld
ansible.posix.seboolean
community.mysql.mysql_user
```

Those FQCNs are present in the code even though `requirements.yml` declares only `ansible.mysql`. A clean deployment environment therefore needs compatible module resolution/dependencies available.

## Role: prerequisites_install

Runs on all nodes.

Actions:

- imports EPEL 9 signing key
- installs EPEL release package
- installs `jq`
- installs `yum-utils`
- installs `firewalld`
- enables and starts firewalld
- installs `python3-pip`
- installs latest `pymysql` through pip

A system update task exists but is commented out.

## Role: percona_install

Runs on all nodes.

Actions:

1. attempts to remove/reset/disable the RHEL MySQL module
2. imports Percona packaging key
3. installs Percona release package
4. runs `percona-release setup pxc-84-lts`
5. installs `percona-xtradb-cluster`
6. enables `pxb-84-lts`
7. installs `percona-xtrabackup-84`
8. opens PXC/Galera firewall ports
9. runs `mysqld --initialize --user=mysql` on nodes 02 and 03
10. stops normal MySQL service on all nodes

Several package/repository commands use `ignore_errors: true`, so failed package/setup steps may not immediately stop the play.

### Firewall Rules

```text
3306/tcp
4444/tcp
4567/udp
4567-4568/tcp
```

The `4567-4568/tcp` firewalld task appears twice in the current role.

## Role: percona_bootstraper

This role contains the main bootstrap workflow.

### 1. TLS generation

OpenSSL is installed on all nodes and `/etc/mysql/certs` is created.

Node 01 generates:

```text
ca-key.pem       4096-bit RSA
ca.pem           self-signed CA, 3650 days
server-key.pem   4096-bit RSA
server-req.pem   CSR
server-cert.pem  CA-signed certificate, 3650 days
```

Certificate subject values are currently hard-coded to the lab identity used in the tasks.

The server certificate is checked with `openssl verify`.

### 2. Controller buffer

The role creates:

```text
/tmp/pxc-cluster-certs
```

on the Ansible controller and fetches:

```text
ca.pem
server-cert.pem
server-key.pem
```

from node 01.

### 3. Runtime certificate distribution

The three runtime files are copied to `/etc/mysql/certs` on the cluster hosts with MySQL ownership and explicit modes.

SELinux contexts are restored with:

```text
restorecon -RFv /etc/mysql/certs
```

### 4. PXC configuration

Each node receives a separate Jinja template as `/etc/my.cnf`.

Common settings include:

```text
default_storage_engine=InnoDB
wsrep_provider=/usr/lib64/galera4/libgalera_smm.so
wsrep_cluster_name=PERCDBTESTCLU01
wsrep_applier_threads=8
wsrep_log_conflicts=ON
innodb_autoinc_lock_mode=2
pxc_strict_mode=PERMISSIVE
pxc-encrypt-cluster-traffic=ON
wsrep_sst_method=xtrabackup-v2
```

All templates point MySQL, Galera, and SST TLS settings to `/etc/mysql/certs`.

### 5. SELinux

Only node 01 is configured with:

```text
mysql_connect_any = true
```

persistently through `ansible.posix.seboolean`.

### 6. Bootstrap

Node 01 starts:

```text
mysql@bootstrap.service
```

The role then extracts the most recent `temporary password` from `/var/log/mysqld.log` and uses it to set the root password from Ansible Vault.

### 7. MaxScale account

The role creates:

```text
maxscaleusr@%
```

with:

```text
plugin: caching_sha2_password
plugin_auth_string: secret.percona_maxscaleusr_password
salt: 1234567890abcdefghij
privileges: *.*:ALL,GRANT
update_password: on_create
```

The task uses `no_log: true`.

## Role: certificates_copy

This role repeats the controller-buffer synchronization after bootstrap.

It:

- creates `/tmp/pxc-cluster-certs` on the controller
- fetches `ca.pem`, `server-cert.pem`, and `server-key.pem` from node 01
- ensures `/etc/mysql/certs` exists on nodes 02/03
- copies the three runtime TLS files to nodes 02/03
- restores SELinux context

Because `percona_bootstraper` already fetches/distributes the same three runtime files, the delivered playbook currently performs certificate distribution twice.

## Role: database_init_start

Node 02/03:

1. create `/var/run/mysqld/mysqld.pid`
2. start `mysql`

Node 01:

1. stop `mysql@bootstrap.service`
2. start normal `mysql`

The role does not contain a wsrep synchronization wait or explicit cluster-health assertion after these service starts.

## Unused Template

The archive contains:

```text
Ansible/roles/database_init_start/templates/bootstrap.cnf.j2
```

The active `database_init_start` task file does not render this template. Its contents include older options such as `default-authentication-plugin=mysql_native_password` and `wsrep_slave_threads`, but it is not referenced by the active playbook path.

## Secrets

`secrets/secrets.yml` is an Ansible Vault encrypted file. Its decrypted contents were not required to document the project and are not reproduced here.

The archive also contains `.vault_pass`; see `SECURITY.md` before publishing the repository.
