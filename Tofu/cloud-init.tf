locals {
  cloud_init_user_data = {
    preserve_hostname = false
    manage_etc_hosts  = true

    users = [
      {
        name        = "almalinux"
        lock_passwd = false
        sudo        = ["ALL=(ALL) NOPASSWD:ALL"]
        groups      = ["wheel"]
        shell       = "/bin/bash"
      }
    ]

    chpasswd = {
      expire = false

      users = [
        {
          name     = "almalinux"
          password = var.vm_user_password_hash
          type     = "hash"
        }
      ]
    }

    ssh_pwauth   = true
    disable_root = true
  }
}

resource "libvirt_cloudinit_disk" "commoninit" {
  for_each = var.VMS

  name = "${each.key}-cloudinit"

  meta_data = yamlencode({
    instance-id    = each.key
    local-hostname = each.value.name
  })

  user_data = "#cloud-config\n${yamlencode(merge(
    local.cloud_init_user_data,
    {
      hostname = each.value.name
    }
  ))}"

  network_config = yamlencode({
    version = 2

    ethernets = {
      eth0 = {
        dhcp4 = false

        addresses = [
          "${each.value.ipv4_add_nic}/${each.value.netmask}"
        ]
      }
    }
  })
}

resource "libvirt_volume" "cloudinit_iso" {
  for_each = var.VMS

  name = "${each.key}-cloudinit.iso"
  pool = var.vm_pool_name

  create = {
    content = {
      url = libvirt_cloudinit_disk.commoninit[each.key].path
    }
  }

  target = {
    permissions = {
      owner = "1000"
      group = "1000"
      mode  = "0644"
    }
  }

  depends_on = [
    libvirt_cloudinit_disk.commoninit
  ]
}