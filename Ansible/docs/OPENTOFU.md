# OpenTofu Implementation

This document describes the OpenTofu code exactly as delivered in `Tofu/`.

## Files

| File | Purpose |
| --- | --- |
| `providers.tf` | provider declaration plus SSH wait and Ansible execution resources |
| `vars.tf` | input variable declarations |
| `storage.tf` | VM QCOW2 volumes |
| `cloud-init.tf` | cloud-init metadata/user-data/network-data and ISO volumes |
| `vm.tf` | libvirt domain definitions |
| `terraform.tfvars` | current workstation/lab values; local artifact |
| `apply.sh` | wrapper for `tofu apply` |
| `destroy.sh` | wrapper for destroy plus known_hosts cleanup |
| `.terraform.lock.hcl` | dependency lock file |

## Provider

The project declares `dmacvicar/libvirt`. The lock file records version `0.9.9`.

No `provider "libvirt"` block with an explicit URI is present in the delivered code.

## Variables

Declared variables:

- `vm_pool_name`
- `vm_pool_path`
- `vm_base_template_name`
- `vm_base_image_path`
- `vm_ssh_public_key`
- `vm_network_name`
- `vm_disk_capacity`
- `vm_domain_name`
- `vm_gateway`
- `VMS`

### Variables actually consumed by resources

The current resource definitions use:

- `vm_pool_name`
- `vm_ssh_public_key`
- `vm_network_name`
- `vm_domain_name`
- `vm_gateway`
- `VMS`

### Declared/current values not consumed by the delivered resource code

The following are declared or supplied but are not referenced by the active resources:

- `vm_pool_path`
- `vm_base_template_name`
- `vm_base_image_path`
- `vm_disk_capacity`

`storage.tf` instead hard-codes the golden-image URL.

## VM Disk Creation

For each `VMS` entry:

```text
<key>-disk.qcow2
```

is created in `vm_pool_name` with QCOW2 format and permissions:

```text
owner 1000
group 1000
mode  0644
```

The disk content source is currently:

```text
file:///home/gesora/Templates/al9-golden-build.qcow2
```

## cloud-init Media

For every VM the code creates:

1. a `libvirt_cloudinit_disk`
2. a libvirt ISO volume named `<key>-cloudinit.iso`

The ISO is attached as a SATA CD-ROM because the domain uses Q35.

## Domain Configuration

Each `libvirt_domain.virtual_machines` resource uses:

```text
type: kvm
machine: q35
arch: x86_64
cpu: host-passthrough
ACPI: enabled
OS disk: virtio
NIC: virtio
network: vm_network_name
VNC listen: 127.0.0.1
video: virtio
running: true
autostart: false
```

## SSH Wait Resource

`terraform_data.wait_for_ssh` depends on all VM domains.

Replacement trigger:

```text
sha256(jsonencode(var.VMS))
```

The local-exec command waits indefinitely until every configured IP accepts TCP connections on port 22.

Host dependency: `nc` must be installed and available in `PATH`.

## Ansible Execution Resource

`terraform_data.run_ansible` depends on `wait_for_ssh`.

Replacement triggers:

```text
hash(var.VMS)
filesha256(Ansible/requirements.yml)
filesha256(Ansible/main.yml)
```

The resource runs:

```text
ansible-galaxy collection install -r ./requirements.yml -p ./collections
```

then launches the playbook.

### Current path caveat

The command exports:

```text
ANSIBLE_CONFIG=${path.module}/../Ansible/config/ansible.cfg
```

The delivered archive contains:

```text
Ansible/ansible.cfg
```

and does not contain `Ansible/config/ansible.cfg`.

This is a current code/path mismatch that must be considered when running the archive on a clean system.

## Trigger Scope Caveat

The Ansible execution resource does not hash role task files or Jinja templates. For example, editing:

```text
Ansible/roles/percona_bootstraper/tasks/main.yml
```

without changing `main.yml`, `requirements.yml`, or `var.VMS` does not by itself change the declared `triggers_replace` value.

## Local Runtime Files

The delivered archive contains:

```text
.terraform/
terraform.tfstate
terraform.tfstate.backup
terraform.tfvars
```

The `Tofu/.gitignore` excludes these patterns. They should be considered workstation/runtime artifacts rather than portable source files for a public repository.
