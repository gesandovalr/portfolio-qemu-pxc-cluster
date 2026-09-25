# OpenTofu + Ansible Percona XtraDB Cluster Lab

A local Infrastructure as Code and configuration-management project that provisions a three-node AlmaLinux virtual environment on QEMU/KVM with OpenTofu and libvirt, then configures a Percona XtraDB Cluster (PXC) with Ansible.

The project demonstrates a complete local automation workflow: VM provisioning, cloud-init bootstrap, static networking, SSH key authentication, Percona installation, Galera/PXC bootstrap, certificate distribution, database initialization, SSH hardening, and optional HashiCorp Vault/keyring integration.

## Project Goals

This repository is designed as a portfolio lab for demonstrating practical experience with:

- OpenTofu Infrastructure as Code
- QEMU/KVM and libvirt virtualization
- QCOW2 golden-image based provisioning
- AlmaLinux cloud images and cloud-init
- Static Linux networking
- SSH public-key authentication
- Ansible inventories, variables, roles, templates, and Vault
- Percona XtraDB Cluster 8.0
- Galera cluster bootstrap and node joining
- MySQL/PXC firewall requirements
- TLS certificate distribution between database nodes
- SELinux-aware automation
- SSH hardening and delegated administrative access
- HashiCorp Vault integration patterns for database key management
- Git-based infrastructure lifecycle management

## Architecture

The current implementation provisions three virtual machines from the same AlmaLinux golden image and attaches them to an existing libvirt network named `LAN` by default.

```text
                                  Git Repository
                                       |
                     +-----------------+-----------------+
                     |                                   |
                     v                                   v
               OpenTofu / libvirt                    Ansible
                     |                                   |
                     | provision                         | configure
                     v                                   v
              QEMU/KVM Hypervisor                PXC configuration
                     |
                  Existing
               libvirt network
                    LAN
                     |
        +------------+------------+
        |            |            |
        v            v            v
+---------------+ +---------------+ +---------------+
| PERCDBTEST01  | | PERCDBTEST02  | | PERCDBTEST03  |
| 10.20.10.10   | | 10.20.10.11   | | 10.20.10.12   |
| 2 vCPU        | | 2 vCPU        | | 2 vCPU        |
| 2 GiB RAM     | | 2 GiB RAM     | | 2 GiB RAM     |
+-------+-------+ +-------+-------+ +-------+-------+
        |                 |                 |
        +-----------------+-----------------+
                          |
                          v
              Percona XtraDB Cluster 8.0
```

## Provisioning Flow

```text
AlmaLinux Golden QCOW2
          |
          v
OpenTofu libvirt_volume
          |
          +--> PERCDBTEST01-disk.qcow2
          +--> PERCDBTEST02-disk.qcow2
          +--> PERCDBTEST03-disk.qcow2
          |
          v
Cloud-init ISO per VM
          |
          +--> hostname / FQDN
          +--> static IPv4
          +--> default gateway
          +--> DNS servers
          +--> DNS search domain
          +--> almalinux user
          +--> SSH public key
          +--> password SSH disabled
          |
          v
libvirt_domain
          |
          v
Running AlmaLinux VMs
          |
          v
Ansible
          |
          +--> prerequisites
          +--> Percona installation
          +--> bootstrap node 01
          +--> distribute certificates
          +--> start nodes 02 and 03
          +--> SSH hardening
```

## Infrastructure Topology

The current OpenTofu variable set defines the following nodes:

| Node | IPv4 address | Prefix | vCPU | Memory |
| --- | --- | ---: | ---: | ---: |
| `PERCDBTEST01` | `10.20.10.10` | `/24` | 2 | 2048 MiB |
| `PERCDBTEST02` | `10.20.10.11` | `/24` | 2 | 2048 MiB |
| `PERCDBTEST03` | `10.20.10.12` | `/24` | 2 | 2048 MiB |

The current environment values also define:

- Gateway: `10.20.10.1`
- Guest DNS: `8.8.8.8`, `8.8.4.4`
- Cloud-init search domain: `lab.local`
- Existing libvirt network: `LAN`
- Default libvirt storage pool: `Virtual_Machines`
- Golden image: `al9-golden-build.qcow2`

The infrastructure code does not create the `LAN` network. It expects that network to exist in libvirt before deployment.

## Technology Stack

| Technology | Role in the project |
| --- | --- |
| OpenTofu | Infrastructure provisioning and lifecycle management |
| dmacvicar/libvirt provider | Interface between OpenTofu and libvirt |
| QEMU/KVM | Local virtualization platform |
| libvirt | VM, storage, disk, network-interface, and domain management |
| QCOW2 | Golden image and VM disk format |
| AlmaLinux 9 | Guest operating system |
| cloud-init | First-boot guest identity, networking, and SSH configuration |
| Ansible | OS and application configuration |
| Percona XtraDB Cluster 8.0 | Synchronous multi-node MySQL-compatible cluster |
| Galera/wsrep | Replication and cluster membership layer used by PXC |
| firewalld | Host firewall configuration |
| SELinux | Mandatory access control retained by the guest configuration |
| Ansible Vault | Encrypted secrets storage |
| HashiCorp Vault | Optional keyring/token integration present in the project |

## Repository Structure

```text
portfolio-qemu-pxc-cluster/
├── readme.md
├── Ansible/
│   ├── ansible.cfg
│   ├── inventory.yml
│   ├── main.yml
│   ├── group_vars/
│   │   ├── all.yaml
│   │   └── deploy_info.yaml
│   ├── host_vars/
│   ├── secrets/
│   │   └── secrets.yml
│   ├── templates/
│   │   ├── encryption-percona-node-01.cnf.j2
│   │   ├── encryption-percona-node-02.cnf.j2
│   │   ├── encryption-percona-node-03.cnf.j2
│   │   ├── node-01-keyring-vault.conf.j2
│   │   ├── node-02-keyring-vault.conf.j2
│   │   ├── node-03-keyring-vault.conf.j2
│   │   └── vault-token-rotation.sh.j2
│   └── roles/
│       ├── prerequisites_install/
│       ├── percona_install/
│       ├── percona_bootstraper/
│       ├── certificates_copy/
│       ├── database_init_start/
│       ├── ssh_permissions/
│       ├── vault_agent/
│       └── keyring_install/
└── Tofu/
    ├── .terraform.lock.hcl
    ├── providers.tf
    ├── vars.tf
    ├── storage.tf
    ├── cloud-init.tf
    ├── vm.tf
    └── terraform.tfvars
```

## OpenTofu Design

### Provider

The project uses the `dmacvicar/libvirt` provider.

```hcl
terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
    }
  }
}
```

The connection URI is not hardcoded in the current provider configuration, so the active libvirt connection is determined by the environment/provider defaults used when OpenTofu runs.

### VM Definition

VMs are generated dynamically from the `VMS` map:

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

This lets the same OpenTofu resources create all cluster nodes through `for_each`.

### Golden Image and VM Storage

Each VM gets an individual QCOW2 volume populated from the AlmaLinux golden image.

Current source image:

```text
/home/gesora/Templates/al9-golden-build.qcow2
```

The generated disk naming convention is:

```text
PERCDBTEST01-disk.qcow2
PERCDBTEST02-disk.qcow2
PERCDBTEST03-disk.qcow2
```

The disks are stored in the configured libvirt pool and use `virtio` as the guest disk bus.

### VM Hardware

Each `libvirt_domain` currently uses:

- KVM virtualization
- x86_64 architecture
- Q35 machine type
- host-passthrough CPU mode
- ACPI
- VirtIO disk and network devices
- SATA cloud-init CD-ROM
- VNC bound to `127.0.0.1`
- VirtIO video

The domain is started automatically after creation, while libvirt autostart is disabled.

## Cloud-init Configuration

A separate cloud-init disk is generated for every VM.

Cloud-init configures:

- hostname
- FQDN
- `/etc/hosts` management
- `almalinux` administrative account
- passwordless sudo for the `wheel` user
- SSH public-key authentication
- disabled SSH password authentication
- disabled root login configuration through cloud-init
- static IPv4 addressing
- default route
- DNS servers
- DNS search domain

### SSH Authentication

The VM account is configured for key-based authentication only:

```text
User: almalinux
Password SSH: disabled
SSH key: supplied through vm_ssh_public_key
```

The account password is locked and `ssh_pwauth` is disabled.

### Guest Networking

Each guest receives its address from the `VMS` variable map. The cloud-init network configuration uses `eth0` with DHCP disabled.

Example:

```text
PERCDBTEST01
IP:      10.20.10.10/24
Gateway: 10.20.10.1
DNS:     8.8.8.8, 8.8.4.4
Domain:  lab.local
```

The resulting FQDN is generated from the node name plus `vm_domain_name`.

Example:

```text
PERCDBTEST01.lab.local
```

## Ansible Design

The Ansible inventory defines the same three cluster nodes provisioned by OpenTofu:

```text
PERCDBTEST01 -> 10.20.10.10
PERCDBTEST02 -> 10.20.10.11
PERCDBTEST03 -> 10.20.10.12
```

Ansible connects as:

```text
ansible_user: almalinux
SSH key: ~/.ssh/id_ed25519
```

The project-local `ansible.cfg` disables host-key checking, which is useful for this disposable lab because VM SSH host keys can change when the nodes are recreated.

## Ansible Deployment Sequence

`Ansible/main.yml` currently executes the configuration in this order:

```text
1. prerequisites_install
          |
          v
2. percona_install
          |
          v
3. percona_bootstraper
          |
          v
4. certificates_copy
          |
          v
5. database_init_start
          |
          v
6. ssh_permissions
          |
          v
7. clear gathered facts
```

Two additional roles are present in the repository but are currently disabled/commented in the main playbook:

- `vault_agent`
- `keyring_install`

These represent the project’s HashiCorp Vault/keyring integration path and can be enabled when that part of the lab is required.

## Ansible Roles

### `prerequisites_install`

Prepares AlmaLinux for the database deployment by:

- importing the EPEL signing key
- installing the EPEL repository
- installing `jq`
- installing `yum-utils`
- installing `firewalld`
- installing `python3-pip`
- installing the Python `pymysql` module

### `percona_install`

Installs and prepares Percona XtraDB Cluster 8.0 by:

- resetting/disabling the default RHEL MySQL module
- importing the Percona packaging key
- installing the Percona repository
- enabling the `pxc-80` repository
- installing `percona-xtradb-cluster`
- installing `percona-xtrabackup-80`
- opening PXC firewall ports
- initializing MySQL data on nodes 02 and 03
- ensuring the MySQL service is stopped before cluster bootstrap

### PXC Firewall Ports

The role configures the following ports through `firewalld`:

| Port | Protocol | Purpose |
| --- | --- | --- |
| 3306 | TCP | MySQL client connections |
| 4444 | TCP | State Snapshot Transfer (SST) |
| 4567 | TCP/UDP | Galera replication traffic |
| 4568 | TCP | Incremental State Transfer (IST) |

### `percona_bootstraper`

Configures and bootstraps the cluster.

The role:

- installs node-specific `/etc/my.cnf` templates
- enables the SELinux `mysql_connect_any` boolean on node 01
- reloads systemd on the first node
- starts `mysql@bootstrap.service` on node 01
- retrieves the temporary MySQL root password
- sets the configured Percona root password
- creates a `maxscaleusr` account for load-balancer integration

Cluster-specific values are stored in `group_vars/deploy_info.yaml`, including node addresses, hostnames, short names, and the wsrep cluster name.

### `certificates_copy`

After the bootstrap node has generated the MySQL TLS material, this role:

1. fetches certificates and keys from node 01 to the Ansible controller buffer
2. copies them to nodes 02 and 03
3. applies MySQL ownership and file permissions
4. restores SELinux file contexts

The distributed material includes:

- `ca-key.pem`
- `ca.pem`
- `client-cert.pem`
- `client-key.pem`
- `private_key.pem`
- `public_key.pem`
- `server-cert.pem`
- `server-key.pem`

### `database_init_start`

Starts the remaining database nodes after bootstrap preparation by:

- creating the MySQL PID file on nodes 02 and 03
- starting the MySQL service on nodes 02 and 03

This allows the remaining nodes to join the bootstrapped PXC cluster.

### `ssh_permissions`

Implements the project’s additional SSH administration configuration by:

- creating `/home/fpnusr/.ssh`
- maintaining an `authorized_keys` file
- distributing multiple approved public keys
- deploying a templated `sshd_config`
- applying secure ownership and permissions
- restoring SELinux context on `sshd_config`
- granting the `fpnusr` account delegated sudo permissions
- restarting `sshd`

### `vault_agent`

The repository includes a role for HashiCorp Vault Agent integration. The role is currently not enabled in `main.yml`.

Its implementation includes:

- HashiCorp RPM repository configuration
- Vault package installation
- `/opt/vault` directory creation
- Vault Agent configuration deployment
- AppRole role ID and secret ID templates
- custom systemd units
- token-rotation service support

### `keyring_install`

The repository also includes a keyring integration role, currently disabled in the main playbook.

It contains automation for:

- node-specific encryption configuration
- `keyring_vault.conf`
- Vault token retrieval
- keyring token injection
- token-rotation scheduling
- Vault Agent startup
- SELinux context restoration

This demonstrates an intended database-at-rest encryption integration path using HashiCorp Vault.

## Secrets Management

`Ansible/secrets/secrets.yml` is stored in Ansible Vault format (`AES256`) and is referenced by the playbook for database credentials.

To edit it:

```bash
ansible-vault edit secrets/secrets.yml
```

To view it when authorized:

```bash
ansible-vault view secrets/secrets.yml
```

To run the playbook interactively with a Vault password:

```bash
ansible-playbook main.yml --ask-vault-pass
```

A Vault password file may also be used locally, but it must never be committed to Git.

## Required Ansible Collections

The current roles use modules from these collections:

```text
ansible.posix
community.mysql
community.general
```

They can be installed with:

```bash
ansible-galaxy collection install ansible.posix community.mysql community.general
```

## Prerequisites

The virtualization host should provide:

- Linux with KVM support
- QEMU
- libvirt
- an existing libvirt storage pool
- an existing libvirt network matching `vm_network_name`
- OpenTofu
- Ansible
- Python 3
- SSH client
- an SSH key pair
- a prepared AlmaLinux 9 golden QCOW2 image

Verify virtualization support:

```bash
lsmod | grep kvm
```

Verify libvirt networks:

```bash
virsh net-list --all
```

Verify storage pools:

```bash
virsh pool-list --all
```

## Deployment

### 1. Clone the repository

```bash
git clone https://github.com/gesandovalr/portfolio-qemu-pxc-cluster.git
cd portfolio-qemu-pxc-cluster
```

### 2. Prepare OpenTofu variables

The project expects environment-specific values through `terraform.tfvars`, including:

- storage pool name/path
- golden image path
- SSH public key
- existing libvirt network name
- domain name
- gateway
- VM definitions

Do not commit real `.tfvars` files containing environment-specific or sensitive data.

### 3. Initialize OpenTofu

```bash
cd Tofu
tofu init
```

### 4. Validate

```bash
tofu fmt -check
tofu validate
```

### 5. Review the plan

```bash
tofu plan
```

### 6. Provision the VMs

```bash
tofu apply
```

OpenTofu creates the VM disks, per-node cloud-init ISO volumes, and libvirt domains.

### 7. Validate SSH

After cloud-init finishes:

```bash
ssh almalinux@10.20.10.10
ssh almalinux@10.20.10.11
ssh almalinux@10.20.10.12
```

### 8. Validate Ansible connectivity

```bash
cd ../Ansible
ansible all -m ping
```

Expected result for all three nodes:

```text
SUCCESS => ping: pong
```

### 9. Run the configuration playbook

```bash
ansible-playbook main.yml --ask-vault-pass
```

### 10. Validate the PXC cluster

After deployment, connect to MySQL on the bootstrap node and inspect wsrep status:

```sql
SHOW STATUS LIKE 'wsrep_cluster_size';
SHOW STATUS LIKE 'wsrep_cluster_status';
SHOW STATUS LIKE 'wsrep_local_state_comment';
```

For a healthy three-node cluster, the expected cluster size is `3` and the cluster status should report `Primary`.

## Infrastructure Lifecycle

```text
tofu init
    |
    v
tofu validate
    |
    v
tofu plan
    |
    v
tofu apply
    |
    v
cloud-init
    |
    v
ansible all -m ping
    |
    v
ansible-playbook main.yml
    |
    v
PXC validation
    |
    v
tofu destroy
```

To remove the provisioned VM infrastructure:

```bash
cd Tofu
tofu destroy
```

## Security Model

The current project contains several security-focused implementation choices:

- SSH password authentication disabled during cloud-init
- root access disabled through cloud-init configuration
- SSH public-key authentication
- Ansible Vault encrypted secret file
- SELinux-aware file-context restoration
- SELinux boolean configuration for MySQL network access where required
- firewalld restrictions for PXC services
- database TLS certificate propagation
- dedicated administrative SSH configuration
- optional Vault Agent and database keyring integration

## Git and Sensitive Files

The `Tofu/.gitignore` excludes:

```text
*.tfstate
*.tfstate.*
.terraform/
*.tfvars
*.tfvars.json
```

The `Ansible/.gitignore` excludes the `secrets/` directory.

Terraform/OpenTofu state files and real `.tfvars` files should not be published because state can contain infrastructure metadata and sensitive values.

The project archive currently contains local state and environment-specific files, so before publishing a clean portfolio repository, verify Git history as well as the working tree.

Recommended checks:

```bash
git ls-files | grep -E 'tfstate|terraform.tfvars|Ansible/secrets'
```

If state was previously committed, removing it from `.gitignore` alone is not sufficient; it should also be removed from Git history and any exposed credentials should be rotated.

## Current Implementation Notes

The documentation above describes what is present in the repository at the time of this scan. A few components are intentionally present but not active in the main deployment path:

- `vault_agent` is currently commented out in `Ansible/main.yml`.
- `keyring_install` is currently commented out in `Ansible/main.yml`.
- the OpenTofu configuration consumes an existing libvirt network instead of creating one.
- the golden image source in `storage.tf` is currently a host-specific absolute path.
- the current `ansible.cfg` uses a host-specific absolute inventory path.

Those host-specific paths are suitable for the current workstation but should eventually be converted to relative paths or variables if the project is intended to be cloned and executed unchanged on another system.

## Portfolio Skills Demonstrated

This project demonstrates the integration of multiple infrastructure disciplines rather than a single automation tool:

```text
Infrastructure as Code
        +
Virtualization
        +
Linux provisioning
        +
Configuration management
        +
Database clustering
        +
Security hardening
        +
Secrets management
        +
Operational validation
```

The primary design principle is separation of responsibilities:

- OpenTofu defines and creates infrastructure.
- cloud-init performs first-boot guest configuration.
- Ansible performs repeatable operating-system and database configuration.
- Ansible Vault protects deployment secrets.
- PXC provides the database cluster layer.

## Future Improvements

The current codebase already exposes several clear next steps for continued development:

- add an OpenTofu remote backend for state
- replace host-specific absolute paths with portable variables/relative paths
- generate Ansible inventory from OpenTofu outputs
- invoke Ansible automatically after VM provisioning
- add formal Ansible collection requirements
- make Vault Agent/keyring integration part of the supported deployment path
- add explicit PXC health-check automation
- add MaxScale deployment to complement the existing `maxscaleusr`
- add automated tests for SSH, MySQL, wsrep, firewall, and service state
- add CI validation for `tofu fmt`, `tofu validate`, YAML linting, and Ansible syntax checks
- add architecture screenshots or rendered diagrams to the repository

## Author

**German Eduardo Sandoval**  
Sysadmin Engineer  
Mex Solutions IT

---

This repository is a hands-on infrastructure portfolio project built to demonstrate reproducible local virtualization, automated Linux provisioning, and clustered database deployment using OpenTofu and Ansible.
