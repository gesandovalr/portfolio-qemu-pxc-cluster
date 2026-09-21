# OpenTofu QEMU/KVM Infrastructure Automation Lab

A local Infrastructure as Code lab built with **OpenTofu**, **libvirt**, **QEMU/KVM**, **virt-manager**, and **Ansible**.

The goal of this project is to demonstrate how virtual infrastructure can be provisioned, configured, validated, destroyed, and recreated consistently using Infrastructure as Code and configuration management practices.

The infrastructure runs locally on a Linux workstation using QEMU/KVM, while the complete source code and project history are maintained in GitHub.

---

## Project Objectives

This project demonstrates practical experience with:

* Infrastructure as Code using OpenTofu
* Linux virtualization with QEMU/KVM
* libvirt resource management
* Virtual machine provisioning
* Virtual networking and storage
* Cloud-init
* Configuration management with Ansible
* Linux system administration
* Infrastructure lifecycle management
* Git branching and release management
* Reusable infrastructure components
* Infrastructure documentation
* Idempotent configuration
* Local development and testing workflows

The project is intentionally built incrementally so that its Git history also demonstrates how the infrastructure evolves from a basic virtual machine deployment into a reusable automation platform.

---

# Architecture

The infrastructure is executed directly from a physical Linux workstation.

```text
                         GitHub
                            │
                            │ Source Code
                            │
                            ▼
                ┌──────────────────────┐
                │  Linux Workstation   │
                │                      │
                │  Git                 │
                │  OpenTofu            │
                │  Ansible             │
                │  virt-manager        │
                └──────────┬───────────┘
                           │
                           │ libvirt API
                           ▼
                ┌──────────────────────┐
                │      libvirt         │
                └──────────┬───────────┘
                           │
                           ▼
                ┌──────────────────────┐
                │      QEMU/KVM        │
                └──────────┬───────────┘
                           │
              ┌────────────┼────────────┐
              │            │            │
              ▼            ▼            ▼
           web01          db01       monitor01
```

OpenTofu is responsible for provisioning the infrastructure.

Ansible is responsible for configuring the operating systems and applications after the virtual machines have been created.

---

# Technology Stack

| Technology   | Purpose                                               |
| ------------ | ----------------------------------------------------- |
| OpenTofu     | Infrastructure as Code                                |
| libvirt      | Virtualization API and resource management            |
| QEMU/KVM     | Hypervisor                                            |
| virt-manager | Graphical VM management and validation                |
| Linux        | Physical virtualization host                          |
| Cloud-init   | Initial guest operating system configuration          |
| Ansible      | Configuration management                              |
| Git          | Source control                                        |
| GitHub       | Repository, documentation, pull requests and releases |

---

# Infrastructure Lifecycle

The project follows a complete infrastructure lifecycle.

```text
Write Infrastructure Code
          │
          ▼
    tofu validate
          │
          ▼
      tofu plan
          │
          ▼
      tofu apply
          │
          ▼
    QEMU/KVM VM
          │
          ▼
      Cloud-init
          │
          ▼
       Ansible
          │
          ▼
     Validation
          │
          ▼
      Application
          │
          ▼
     tofu destroy
```

The goal is for the complete environment to be reproducible.

The environment should be capable of being destroyed and recreated using the source code stored in this repository.

---

# OpenTofu Responsibilities

OpenTofu manages infrastructure resources such as:

* libvirt networks
* virtual machine storage
* base images
* virtual disks
* CPU allocation
* memory allocation
* network interfaces
* virtual machines
* cloud-init configuration
* infrastructure outputs

OpenTofu is not used as a replacement for configuration management.

Application installation and operating system configuration are handled by Ansible.

---

# Ansible Responsibilities

Ansible is used after infrastructure provisioning to configure the guest operating systems.

Examples include:

* package installation
* user management
* SSH configuration
* firewall configuration
* web server installation
* application deployment
* security hardening
* monitoring agents
* service configuration
* health checks

This separation keeps infrastructure provisioning and operating system configuration independent.

```text
OpenTofu
   │
   ├── VM
   ├── CPU
   ├── Memory
   ├── Storage
   ├── Network
   └── Cloud-init
          │
          ▼
       Ansible
          │
          ├── Packages
          ├── Users
          ├── SSH
          ├── Firewall
          ├── Applications
          └── Monitoring
```

---

# Repository Structure

```text
portfolio-qemu-tofu-lab/
│
├── README.md
├── .gitignore
│
├── docs/
│   ├── architecture.md
│   └── screenshots/
│
├── tofu/
│   ├── versions.tf
│   ├── providers.tf
│   ├── variables.tf
│   ├── locals.tf
│   ├── network.tf
│   ├── storage.tf
│   ├── vm.tf
│   ├── outputs.tf
│   ├── terraform.tfvars.example
│   │
│   └── templates/
│       └── cloud-init.yaml
│
├── ansible/
│   ├── ansible.cfg
│   │
│   ├── inventory/
│   │
│   ├── playbooks/
│   │   └── site.yml
│   │
│   └── roles/
│
└── scripts/
    ├── deploy.sh
    ├── validate.sh
    └── destroy.sh
```

The structure will evolve as the project becomes more modular.

---

# Development Strategy

The repository uses a simple development workflow based on three branch types.

```text
main
  ▲
  │
dev
  ▲
  │
feature/*
```

## `main`

The `main` branch represents stable and release-ready versions of the infrastructure.

Only tested changes should be merged into `main`.

---

## `dev`

The `dev` branch acts as the integration branch.

New features are merged into `dev` and tested together before being promoted to `main`.

---

## `feature/*`

Individual features are developed in short-lived feature branches.

Examples:

```text
feature/libvirt-base
feature/libvirt-network
feature/storage-pool
feature/linux-vm
feature/cloud-init
feature/ansible
feature/windows-vm
feature/monitoring
```

The normal workflow is:

```text
feature/*
    │
    ▼
   dev
    │
    ▼
  main
    │
    ▼
Release
```

---

# Commit Strategy

The project follows a simple Conventional Commit style.

Examples:

```text
feat: configure libvirt provider
feat: add virtual network
feat: add Linux VM provisioning
feat: add cloud-init configuration

fix: correct storage pool path
fix: update network configuration

docs: add architecture documentation
docs: update installation instructions

refactor: convert VM configuration into reusable module

chore: update provider configuration
```

This makes the Git history easier to understand and demonstrates how each part of the project was introduced.

---

# Release Strategy

Stable versions are tagged using Semantic Versioning.

```text
MAJOR.MINOR.PATCH
```

Example releases:

```text
v1.0.0 - Initial QEMU/KVM OpenTofu deployment
v1.1.0 - Cloud-init support
v1.2.0 - Ansible configuration management
v1.3.0 - Multi-VM deployment
v1.4.0 - Windows VM support
v1.5.0 - Monitoring infrastructure
```

Tags represent stable versions of the project.

Feature development is performed in branches, not tags.

---

# Project Roadmap

## Phase 1 — OpenTofu and libvirt

Initial OpenTofu project configuration.

Goals:

* Configure OpenTofu
* Configure the libvirt provider
* Validate communication with QEMU/KVM
* Create the base project structure

---

## Phase 2 — Virtual Networking

Create the networking layer.

Goals:

* Create a libvirt virtual network
* Configure DHCP
* Configure IP addressing
* Validate VM connectivity

---

## Phase 3 — Storage

Configure virtual machine storage.

Goals:

* Create or use a libvirt storage pool
* Import a Linux base image
* Create virtual disks
* Manage qcow2 volumes

---

## Phase 4 — Linux Virtual Machine

Provision the first complete Linux VM.

Goals:

* Configure CPU
* Configure memory
* Attach storage
* Attach network interfaces
* Configure console access
* Validate the VM using virt-manager

---

## Phase 5 — Cloud-init

Automate the initial guest configuration.

Goals:

* Configure hostname
* Create initial user
* Configure SSH keys
* Configure basic networking
* Prepare the VM for Ansible

---

## Phase 6 — Ansible

Introduce configuration management.

Goals:

* Create Ansible inventory
* Validate SSH connectivity
* Install packages
* Configure services
* Implement reusable roles
* Verify Ansible idempotency

---

## Phase 7 — Multi-VM Environment

Expand the environment beyond a single VM.

Potential infrastructure:

```text
web01
db01
monitor01
```

This phase will demonstrate reusable infrastructure definitions and dependencies between services.

---

## Phase 8 — Windows Automation

Add Windows virtualization.

Potential goals:

* Create a generalized Windows QEMU image
* Use VirtIO drivers
* Use Sysprep for image preparation
* Provision Windows VMs from OpenTofu
* Automate post-deployment configuration

---

## Phase 9 — Monitoring

Introduce infrastructure monitoring.

Potential tools may include:

* Prometheus
* Grafana
* Node Exporter
* Linux system metrics

---

# Prerequisites

The following components are expected on the Linux workstation:

```text
OpenTofu
QEMU
KVM
libvirt
virt-manager
Git
Ansible
SSH client
```

Virtualization support must also be enabled in the system BIOS/UEFI.

The current user must have permission to interact with libvirt.

---

# Local Deployment Workflow

Clone the repository:

```bash
git clone <repository-url>
cd portfolio-qemu-tofu-lab
```

Move into the OpenTofu directory:

```bash
cd tofu
```

Initialize the project:

```bash
tofu init
```

Format the configuration:

```bash
tofu fmt -recursive
```

Validate the configuration:

```bash
tofu validate
```

Review the infrastructure plan:

```bash
tofu plan
```

Provision the infrastructure:

```bash
tofu apply
```

After the virtual machines are created, they can be inspected through:

```bash
virt-manager
```

---

# Ansible Deployment

After OpenTofu creates the infrastructure:

```bash
cd ../ansible
```

Validate connectivity:

```bash
ansible all -m ping
```

Run the configuration:

```bash
ansible-playbook -i inventory/hosts.ini playbooks/site.yml
```

The Ansible configuration should be idempotent.

A second execution should ideally produce no unexpected changes.

Example:

```text
First execution:

web01   ok=25   changed=12   failed=0

Second execution:

web01   ok=25   changed=0    failed=0
```

---

# Destroying the Environment

Because the environment is Infrastructure as Code, it should be possible to remove it completely and rebuild it.

To destroy the OpenTofu-managed resources:

```bash
cd tofu
tofu destroy
```

The ability to recreate the environment is part of the project's validation strategy.

---

# Infrastructure Validation

Before changes are committed, the OpenTofu configuration should be validated.

```bash
tofu fmt -recursive
tofu validate
tofu plan
```

Ansible configuration can also be checked before execution:

```bash
ansible-playbook --syntax-check playbooks/site.yml
```

Additional validation tools may be introduced later, including:

```text
TFLint
Checkov
ansible-lint
yamllint
```

---

# State Management

OpenTofu state files are local for the initial version of this lab.

State files must not be committed to GitHub.

Examples:

```text
terraform.tfstate
terraform.tfstate.backup
*.tfstate
*.tfstate.*
```

Future versions of the project may explore remote state management.

---

# Sensitive Information

The repository must not contain:

* passwords
* private SSH keys
* API credentials
* authentication tokens
* production secrets
* private configuration files

Environment-specific variables should use example files.

Example:

```text
terraform.tfvars.example
```

The real file:

```text
terraform.tfvars
```

should not be committed.

---

# Recommended `.gitignore`

```gitignore
# OpenTofu / Terraform
.terraform/
*.tfstate
*.tfstate.*
*.tfvars
crash.log
crash.*.log

# SSH
*.pem
*.key

# Ansible
*.retry

# OS / Editors
.DS_Store
.vscode/
.idea/
```

The OpenTofu dependency lock file should normally remain under version control:

```text
.terraform.lock.hcl
```

---

# Design Principles

This project follows several infrastructure automation principles.

## Reproducibility

Infrastructure should be recreated from code rather than manually rebuilt.

## Idempotency

Repeated configuration runs should result in the same system state.

## Separation of Responsibilities

OpenTofu provisions infrastructure.

Ansible configures operating systems and applications.

## Version Control

Infrastructure changes are tracked through Git.

## Small Changes

Features are introduced incrementally through dedicated branches.

## Documentation

Architecture decisions and deployment procedures are documented alongside the source code.

---

# Portfolio Purpose

This repository is also intended as a technical portfolio project.

It demonstrates practical knowledge across several infrastructure disciplines:

```text
Linux Administration
       +
Virtualization
       +
Infrastructure as Code
       +
Configuration Management
       +
Git
       +
Automation
       =
Reproducible Infrastructure
```

Rather than showing isolated examples of OpenTofu or Ansible, this project demonstrates how the tools can work together as part of a complete infrastructure lifecycle.

---

# Future Improvements

Potential future additions include:

* reusable OpenTofu modules
* multiple Linux distributions
* Windows Server deployment
* Windows client deployment
* dynamic Ansible inventory
* automated DNS
* multiple networks
* firewall segmentation
* reverse proxy
* load balancing
* database servers
* monitoring
* centralized logging
* security hardening
* automated infrastructure testing
* secrets management
* remote OpenTofu state
* additional virtualization environments

---

# Status

🚧 **Project under active development**

Current focus:

```text
OpenTofu
+
libvirt
+
QEMU/KVM
```

The project will be expanded incrementally using feature branches and versioned releases.

---

# Author

**German Eduardo Sandoval**

Sysadmin Engineer

Infrastructure, Cloud and Automation

GitHub: `gesandoval`

Portfolio: `germansandoval.tech`

---

## License

This project is intended for educational, laboratory, demonstration, and portfolio purposes.

A formal open-source license may be added as the project evolves.
