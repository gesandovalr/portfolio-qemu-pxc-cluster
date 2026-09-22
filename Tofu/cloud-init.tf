resource "libvirt_cloudinit_disk" "commoninit" {
  for_each = var.VMS

  name = "${each.key}-cloudinit"

  meta_data = yamlencode({
    instance-id    = each.key
    local-hostname = each.value.name
  })

  user_data = <<-EOF
    #cloud-config

    hostname: ${each.value.name}
    manage_etc_hosts: true

    users:
      - default
      - name: myuser
        groups:
          - sudo
        sudo: ALL=(ALL) NOPASSWD:ALL
        shell: /bin/bash
        ssh_authorized_keys:
          - ${var.ssh_public_key}

    ssh_pwauth: false
  EOF

  network_config = <<-EOF
    version: 2
    ethernets:
      ens3:
        dhcp4: false
        addresses:
          - ${each.value.ipv4_add_nic}/${each.value.netmask}
  EOF
}

resource "libvirt_volume" "cloudinit_iso" {
  for_each = var.VMS

  name = "${each.key}-cloudinit.iso"
  pool = var.vm_pool_name

  target = {
    format = {
      type = "raw"
    }
  }

  create = {
    content = {
      url = libvirt_cloudinit_disk.commoninit[each.key].path
    }
  }
}