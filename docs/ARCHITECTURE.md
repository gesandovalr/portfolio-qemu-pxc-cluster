# Architecture

This document describes the architecture implemented by the delivered repository. It is derived from the OpenTofu and Ansible code in the project rather than from an intended/future design.

## Components

The project has four execution layers:

1. **OpenTofu** defines VM disks, cloud-init media, and libvirt domains.
2. **cloud-init** configures guest identity, static networking, and SSH access.
3. **OpenTofu local-exec** waits for SSH and hands execution to Ansible.
4. **Ansible** installs and configures PXC 8.4, TLS, firewall rules, and cluster startup.

## Infrastructure Diagram

```text
Host workstation
|
+-- OpenTofu
|   |
|   +-- libvirt_volume.vm_disk[*]
|   +-- libvirt_cloudinit_disk.commoninit[*]
|   +-- libvirt_volume.cloudinit_iso[*]
|   +-- libvirt_domain.virtual_machines[*]
|   +-- terraform_data.wait_for_ssh
|   +-- terraform_data.run_ansible
|
+-- Ansible controller process
    |
    +-- PERCDBTEST01 (10.20.10.10)
    +-- PERCDBTEST02 (10.20.10.11)
    +-- PERCDBTEST03 (10.20.10.12)
```

All VMs attach to the existing libvirt network configured by `vm_network_name` (`LAN` in the supplied tfvars).

## VM Profile

The three current nodes use the same hardware profile:

- 2 vCPU
- 2048 MiB RAM
- KVM domain type
- Q35 machine
- x86_64 architecture
- host-passthrough CPU
- VirtIO OS disk
- VirtIO network adapter
- SATA cloud-init CD-ROM
- VNC on loopback only

The VM domain is started on creation but `autostart` is disabled.

## Storage

`libvirt_volume.vm_disk` creates one QCOW2 volume per `VMS` entry.

The current code copies from:

```text
file:///home/gesora/Templates/al9-golden-build.qcow2
```

Although `vars.tf` declares `vm_base_image_path`, the delivered `storage.tf` does not use it.

## cloud-init

A unique cloud-init disk is built per VM.

Identity:

```text
hostname = VM name
fqdn     = VM name + vm_domain_name
```

User configuration:

- user `almalinux`
- locked password
- passwordless sudo
- member of `wheel`
- SSH public key from `vm_ssh_public_key`
- SSH password authentication disabled
- root disabled

Network configuration:

- DHCP disabled
- IP/prefix from `VMS`
- default route through `vm_gateway`
- DNS `8.8.8.8`, `8.8.4.4`
- search domain `vm_domain_name`

## OpenTofu to Ansible Handoff

`terraform_data.wait_for_ssh` runs only after all libvirt domains are created. It loops over each IP in `var.VMS` and waits for TCP/22 with:

```text
nc -z -w 2 <ip> 22
```

`terraform_data.run_ansible` then executes in the `Ansible` directory. It first installs collection requirements into `./collections` and then launches `main.yml`.

## PXC Cluster Topology

The cluster identity comes from `Ansible/group_vars/deploy_info.yaml`:

```text
cluster: PERCDBTESTCLU01
node 01: PERCDBTEST01.lab.local / 10.20.10.10
node 02: PERCDBTEST02.lab.local / 10.20.10.11
node 03: PERCDBTEST03.lab.local / 10.20.10.12
```

Every node is configured with the same wsrep cluster address containing all three IPs.

Unique node values:

| Node | server-id | wsrep_node_address | wsrep_node_name |
| --- | ---: | --- | --- |
| 01 | 1 | `10.20.10.10` | `PERCDBTEST01.lab.local` |
| 02 | 2 | `10.20.10.11` | `PERCDBTEST02.lab.local` |
| 03 | 3 | `10.20.10.12` | `PERCDBTEST03.lab.local` |

## TLS Architecture

Node 01 acts as the certificate-generation node.

It generates:

```text
ca-key.pem
ca.pem
server-key.pem
server-req.pem
server-cert.pem
```

The server certificate is signed with the generated CA and verified locally.

The runtime certificate set used by PXC and distributed through Ansible is:

```text
ca.pem
server-cert.pem
server-key.pem
```

All PXC templates reference `/etc/mysql/certs` explicitly.

Galera provider TLS:

```text
socket.ssl=yes
socket.ssl_ca=/etc/mysql/certs/ca.pem
socket.ssl_cert=/etc/mysql/certs/server-cert.pem
socket.ssl_key=/etc/mysql/certs/server-key.pem
```

SST encryption is configured with:

```text
[sst]
encrypt=4
```

## Cluster Startup Sequence

The Ansible code performs startup in this order:

1. install PXC 8.4 on all nodes
2. initialize MySQL explicitly on nodes 02 and 03
3. stop normal MySQL service on all nodes
4. generate and distribute TLS material
5. render `/etc/my.cnf` per node
6. bootstrap node 01 with `mysql@bootstrap.service`
7. set the root password on node 01
8. create the MaxScale service account
9. synchronize runtime certificates again via `certificates_copy`
10. start normal MySQL on nodes 02 and 03
11. stop bootstrap service on node 01
12. start normal MySQL on node 01

No automated post-start wsrep health assertion is currently present.
