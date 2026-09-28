# OpenTofu + Ansible Percona XtraDB Cluster 8.4 Lab

A local infrastructure automation portfolio project that provisions three AlmaLinux 9 virtual machines on QEMU/KVM with OpenTofu and the `dmacvicar/libvirt` provider, waits for SSH availability, installs project-local Ansible collection dependencies, and then runs Ansible to build an encrypted three-node Percona XtraDB Cluster (PXC) 8.4 LTS.

The repository demonstrates an end-to-end local workflow that combines infrastructure provisioning, cloud-init, static networking, configuration management, PXC/Galera bootstrap, TLS-encrypted cluster traffic, SST encryption, SELinux-aware configuration, firewall automation, Ansible Vault, and automated handoff from OpenTofu to Ansible.

## Current Implementation at a Glance

| Layer | Current implementation |
| --- | --- |
| Hypervisor | QEMU/KVM through libvirt |
| IaC | OpenTofu |
| Provider | `dmacvicar/libvirt` 0.9.9 (locked in `.terraform.lock.hcl`) |
| Guest OS | AlmaLinux 9 golden QCOW2 image |
| Provisioning | cloud-init with static networking and SSH key authentication |
| Configuration management | Ansible |
| Database | Percona XtraDB Cluster 8.4 LTS |
| SST tooling | Percona XtraBackup 8.4 |
| Replication | Galera / wsrep |
| Cluster encryption | Self-signed CA + shared server certificate/key |
| SST encryption | `encrypt=4` |
| Authentication plugin for MaxScale account | `caching_sha2_password` |
| Firewall | firewalld |
| Mandatory access control | SELinux retained; `mysql_connect_any` enabled on node 01 |
| Secrets | Ansible Vault file referenced by the playbook |
| IaC -> configuration handoff | `terraform_data.wait_for_ssh` -> `terraform_data.run_ansible` |

## What the Project Demonstrates

- OpenTofu resource orchestration with `for_each`
- QEMU/KVM and libvirt domain provisioning
- QCOW2 golden-image cloning
- Q35 virtual machines with host-passthrough CPU
- per-node cloud-init ISO generation
- static IPv4 configuration through cloud-init network data
- SSH key-only guest access
- automatic SSH readiness checks from OpenTofu
- automatic Ansible collection installation
- automatic Ansible execution from OpenTofu
- PXC 8.4 LTS installation and Galera configuration
- three-node wsrep topology
- self-signed TLS certificate generation on the bootstrap node
- TLS certificate distribution to all cluster members
- encrypted Galera traffic and encrypted XtraBackup SST
- PXC bootstrap through `mysql@bootstrap.service`
- `caching_sha2_password` account creation for the MaxScale service account
- firewalld configuration for PXC/Galera ports
- SELinux-aware file context restoration
- Ansible Vault-based credential loading

## Architecture

```text
                           OpenTofu
                               |
            +------------------+------------------+
            |                                     |
            v                                     v
   libvirt/QEMU/KVM                    terraform_data.wait_for_ssh
            |                                     |
            v                                     v
  3 AlmaLinux 9 VMs                     TCP/22 readiness check
            |                                     |
            +------------------+------------------+
                               |
                               v
                    terraform_data.run_ansible
                               |
                 install requirements.yml
                               |
                               v
                       ansible-playbook
                               |
             +-----------------+-----------------+
             |                 |                 |
             v                 v                 v
      PERCDBTEST01      PERCDBTEST02      PERCDBTEST03
       10.20.10.10       10.20.10.11       10.20.10.12
             |                 |                 |
             +-----------------+-----------------+
                               |
                               v
                  PXC 8.4 / Galera Cluster
                   TLS-encrypted replication
```

## Node Topology

The current `Tofu/terraform.tfvars` and Ansible variable files define:

| Node | IP | Prefix | vCPU | RAM | Server ID |
| --- | --- | ---: | ---: | ---: | ---: |
| `PERCDBTEST01` | `10.20.10.10` | `/24` | 2 | 2048 MiB | 1 |
| `PERCDBTEST02` | `10.20.10.11` | `/24` | 2 | 2048 MiB | 2 |
| `PERCDBTEST03` | `10.20.10.12` | `/24` | 2 | 2048 MiB | 3 |

Current environment values:

- domain: `lab.local`
- gateway: `10.20.10.1`
- DNS: `8.8.8.8`, `8.8.4.4`
- existing libvirt network: `LAN`
- libvirt storage pool: `Virtual_Machines`
- wsrep cluster name: `PERCDBTESTCLU01`
- golden image currently referenced by `storage.tf`: `/home/gesora/Templates/al9-golden-build.qcow2`

The OpenTofu code consumes an **existing** libvirt network and storage pool. It does not create them.

## End-to-End Deployment Flow

The current code executes this workflow:

```text
1. OpenTofu creates VM QCOW2 volumes
2. OpenTofu creates a cloud-init disk per VM
3. OpenTofu creates and starts all three libvirt domains
4. terraform_data.wait_for_ssh checks TCP/22 on every VM
5. terraform_data.run_ansible installs collections from requirements.yml
6. terraform_data.run_ansible launches main.yml
7. prerequisites_install prepares each AlmaLinux host
8. percona_install installs PXC 8.4 and XtraBackup 8.4
9. percona_bootstraper:
   - generates cluster TLS material on node 01
   - fetches TLS files to the controller
   - distributes runtime TLS files
   - renders encrypted PXC configuration
   - bootstraps node 01
   - sets the root password
   - creates maxscaleusr with caching_sha2_password
10. certificates_copy repeats runtime certificate synchronization to nodes 02/03
11. database_init_start starts nodes 02/03
12. database_init_start stops bootstrap mode on node 01 and starts normal mysql
13. gathered Ansible facts are cleared
```

For deeper detail, see:

- [Architecture](docs/ARCHITECTURE.md)
- [OpenTofu implementation](docs/OPENTOFU.md)
- [Ansible implementation](docs/ANSIBLE.md)
- [Deployment guide](docs/DEPLOYMENT.md)
- [Security and secrets](docs/SECURITY.md)
- [Troubleshooting and current caveats](docs/TROUBLESHOOTING.md)

## Repository Structure

The delivered repository currently contains:

```text
portfolio-qemu-pxc-cluster/
├── readme.md
├── docs/
│   ├── ARCHITECTURE.md
│   ├── ANSIBLE.md
│   ├── DEPLOYMENT.md
│   ├── OPENTOFU.md
│   ├── SECURITY.md
│   └── TROUBLESHOOTING.md
├── Ansible/
│   ├── .gitignore
│   ├── .vault_pass                 # present in delivered archive; do not publish
│   ├── ansible.cfg
│   ├── inventory.yml
│   ├── main.yml
│   ├── requirements.yml
│   ├── group_vars/
│   │   ├── all.yaml
│   │   └── deploy_info.yaml
│   ├── secrets/
│   │   └── secrets.yml             # Ansible Vault encrypted
│   ├── templates/
│   │   ├── encryption-percona-node-01.cnf.j2
│   │   ├── encryption-percona-node-02.cnf.j2
│   │   └── encryption-percona-node-03.cnf.j2
│   └── roles/
│       ├── prerequisites_install/
│       ├── percona_install/
│       ├── percona_bootstraper/
│       ├── certificates_copy/
│       └── database_init_start/
└── Tofu/
    ├── .gitignore
    ├── .terraform.lock.hcl
    ├── apply.sh
    ├── destroy.sh
    ├── cloud-init.tf
    ├── providers.tf
    ├── storage.tf
    ├── terraform.tfvars            # present in delivered archive
    ├── vars.tf
    └── vm.tf
```

The delivered archive also contains local `.terraform/`, `terraform.tfstate`, and `terraform.tfstate.backup` artifacts. These are runtime/local-state files rather than source documentation and should not be published in a clean portfolio repository.

## OpenTofu Design

### Provider

The repository declares:

```hcl
terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
    }
  }
}
```

The lock file currently pins `dmacvicar/libvirt` version `0.9.9`.

No provider URI is declared in the delivered `providers.tf`; therefore the effective libvirt connection is determined by the provider/environment defaults at runtime.

### VM Creation

`var.VMS` drives all node creation:

```hcl
variable "VMS" {
  type = map(object({
    name         = string
    memory       = number
    vcpu         = number
    ipv4_add_nic = string
    netmask      = number
  }))
}
```

OpenTofu uses the map with `for_each` to create:

- one QCOW2 disk per VM
- one cloud-init disk per VM
- one libvirt domain per VM

### VM Hardware

The delivered `libvirt_domain` configuration uses:

- KVM
- x86_64
- Q35
- host-passthrough CPU
- ACPI
- VirtIO OS disk
- VirtIO network adapter
- SATA cloud-init CD-ROM
- VNC listening on `127.0.0.1`
- VirtIO video
- `running = true`
- `autostart = false`

### Cloud-init

The cloud-init configuration creates the `almalinux` user with:

- locked password
- passwordless sudo
- `wheel` membership
- `/bin/bash`
- SSH public key from `var.vm_ssh_public_key`
- SSH password authentication disabled
- root disabled through cloud-init

Network configuration is static and includes the configured IP/prefix, default route, Google DNS servers, and `vm_domain_name` as the DNS search domain.

### Automatic Ansible Handoff

After the VM domains exist, `terraform_data.wait_for_ssh` loops over all VM IP addresses and waits until `nc` can connect to TCP/22.

Then `terraform_data.run_ansible`:

1. changes into `../Ansible`
2. runs `ansible-galaxy collection install -r ./requirements.yml -p ./collections`
3. runs `ansible-playbook -i ./inventory.yml ./main.yml`

Its current replacement triggers are:

- hash of `var.VMS`
- hash of `Ansible/requirements.yml`
- hash of `Ansible/main.yml`

Changes only inside a role or template are **not** included in those triggers.

## Ansible Design

### Inventory

The inventory contains one `pxc` group with all three nodes. Ansible connects as:

```text
user: almalinux
private key: ~/.ssh/id_ed25519
```

### Main Playbook

`Ansible/main.yml` executes these roles in order:

1. `prerequisites_install`
2. `percona_install`
3. `percona_bootstraper`
4. `certificates_copy`
5. `database_init_start`
6. clear gathered facts

There are no active `ssh_permissions`, `vault_agent`, or `keyring_install` roles in the delivered repository.

### PXC Version

The installation role explicitly runs:

```text
percona-release setup pxc-84-lts
percona-release enable pxb-84-lts
dnf install percona-xtradb-cluster -y
dnf install percona-xtrabackup-84 -y
```

Therefore this repository documents **PXC 8.4 LTS**, not PXC 8.0.

### PXC/Galera Configuration

All three templates configure:

- `default_storage_engine=InnoDB`
- `wsrep_provider=/usr/lib64/galera4/libgalera_smm.so`
- identical three-node `wsrep_cluster_address`
- `wsrep_applier_threads=8`
- `wsrep_log_conflicts=ON`
- `innodb_autoinc_lock_mode=2`
- `pxc_strict_mode=PERMISSIVE`
- `pxc-encrypt-cluster-traffic=ON`
- `wsrep_sst_method=xtrabackup-v2`
- encrypted SST with `encrypt=4`

Each node receives a unique `server-id`, `wsrep_node_address`, and `wsrep_node_name`.

### TLS Workflow

`percona_bootstraper` generates on node 01:

```text
/etc/mysql/certs/ca-key.pem
/etc/mysql/certs/ca.pem
/etc/mysql/certs/server-key.pem
/etc/mysql/certs/server-req.pem
/etc/mysql/certs/server-cert.pem
```

The server certificate is signed by the self-signed cluster CA. The role verifies it with `openssl verify`.

Runtime TLS files distributed to the cluster are:

```text
ca.pem
server-cert.pem
server-key.pem
```

The CA private key remains generated on node 01; it is not part of the `certificates_copy` runtime distribution set.

### MaxScale Service Account

The bootstrap role creates:

```text
user: maxscaleusr
host: %
authentication plugin: caching_sha2_password
```

The task uses `plugin_auth_string` and a fixed 20-character salt for deterministic `caching_sha2_password` handling.

## Firewall Ports

`percona_install` enables:

| Port | Protocol | Use in the code |
| --- | --- | --- |
| 3306 | TCP | MySQL client traffic |
| 4444 | TCP | SST |
| 4567 | UDP | Galera traffic |
| 4567-4568 | TCP | Galera replication / IST-related traffic |

The `4567-4568/tcp` task is currently present twice in the role.

## Deployment

### Host prerequisites inferred from the code

The machine running OpenTofu/Ansible needs:

- OpenTofu
- Ansible
- QEMU/KVM and libvirt
- an existing libvirt network matching `vm_network_name`
- an existing libvirt storage pool matching `vm_pool_name`
- the AlmaLinux golden QCOW2 image referenced by `storage.tf`
- SSH client/key pair
- `nc`/netcat because `wait_for_ssh` calls `nc -z -w 2`
- network reachability to all VM addresses

### Normal workflow

From the `Tofu` directory:

```bash
tofu init
tofu plan
tofu apply
```

With the current design, `tofu apply` is intended to provision the VMs **and then run Ansible automatically**. A separate manual `ansible-playbook` step is not part of the intended automated path.

The repository also provides:

```bash
./apply.sh
./destroy.sh
```

`apply.sh` runs `tofu apply`.

`destroy.sh` runs `tofu destroy`, then removes SSH known-host entries for the three hard-coded lab IPs.

See [DEPLOYMENT.md](docs/DEPLOYMENT.md) before running the delivered archive because it contains two current path/dependency caveats that affect portability.

## Validation

Useful post-deployment checks are:

```sql
SHOW STATUS LIKE 'wsrep_cluster_size';
SHOW STATUS LIKE 'wsrep_cluster_status';
SHOW STATUS LIKE 'wsrep_local_state_comment';
```

A completed three-node deployment should normally show cluster size `3`; this expectation is operational validation rather than something enforced by the current automation.

The repository does not currently contain an automated wsrep health-check task after startup.

## Security and Publication Notes

The implementation includes several security-oriented choices:

- SSH password authentication disabled by cloud-init
- root disabled through cloud-init
- key-based Ansible SSH access
- encrypted Ansible Vault file
- PXC replication encryption
- encrypted SST
- explicit private-key permissions
- SELinux context restoration for TLS material
- firewalld rules limited to required PXC/Galera ports
- `caching_sha2_password` for the MaxScale account

However, the **delivered ZIP itself** contains local/runtime artifacts that should not be published:

- `Ansible/.vault_pass`
- `Tofu/terraform.tfstate`
- `Tofu/terraform.tfstate.backup`
- `Tofu/.terraform/`
- `Tofu/terraform.tfvars`

The ignore files indicate these are intended to remain local. See [SECURITY.md](docs/SECURITY.md).

## Current Code Caveats

The documentation intentionally records the code exactly as delivered. Important current mismatches are:

1. `Tofu/providers.tf` sets:

   ```text
   ANSIBLE_CONFIG=${path.module}/../Ansible/config/ansible.cfg
   ```

   but the delivered archive contains `Ansible/ansible.cfg`, not `Ansible/config/ansible.cfg`.

2. `Ansible/requirements.yml` installs `ansible.mysql`, while `percona_bootstraper` currently invokes:

   ```text
   community.mysql.mysql_user
   ```

   and the playbook also uses `ansible.posix` modules. A clean machine therefore needs the module-resolution/dependency path reconciled or those collections available elsewhere.

3. OpenTofu's Ansible trigger hashes `main.yml` and `requirements.yml`, but not role/task/template files. Role-only changes may not cause `terraform_data.run_ansible` to be replaced automatically.

4. `storage.tf` currently hard-codes the golden-image URL instead of using the declared `vm_base_image_path` variable.

5. `vm_pool_path`, `vm_base_template_name`, `vm_base_image_path`, and `vm_disk_capacity` are declared/configured but are not consumed by the current resource definitions in the delivered code.

These are documented as current implementation facts; this documentation update does not alter application/IaC behavior.

## Portfolio Skills Demonstrated

```text
OpenTofu / IaC
      +
QEMU/KVM + libvirt
      +
cloud-init
      +
Ansible
      +
Linux/firewalld/SELinux
      +
Percona XtraDB Cluster 8.4
      +
Galera/wsrep
      +
TLS certificate automation
      +
Ansible Vault
```

## Author

**German Eduardo Sandoval**  
Sysadmin Engineer  
Mex Solutions IT

This repository is a hands-on infrastructure portfolio project demonstrating automated local virtualization and encrypted clustered database deployment with OpenTofu and Ansible.
