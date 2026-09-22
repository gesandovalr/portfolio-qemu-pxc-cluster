resource "libvirt_domain" "example" {
  for_each = var.VMS

  name        = each.value.name
  type        = "kvm"
  memory      = each.value.memory
  memory_unit = "MiB"
  vcpu        = each.value.vcpu

  os = {
    type         = "hvm"
    type_arch    = "x86_64"
    type_machine = "q35"
    dev = "hd"
  }

  devices = {
    disks = [
      {
        source = {
          volume = {
            pool   = var.vm_pool_name
            volume = libvirt_volume.local_template[each.key].name
          }
        }

        target = {
          dev = "vda"
          bus = "virtio"
        }
      },
      {
        source = {
          volume = {
            pool   = var.vm_pool_name
            volume = libvirt_volume.cloudinit_iso[each.key].name
          }
        }

        target = {
          dev = "sda"
          bus = "sata"
        }

        device = "cdrom"
      }
    ]

    interfaces = [
      {
        model = {
          type = "virtio"
        }

        source = {
          network = {
            network = var.vm_network_name
          }
        }
      }
    ]

    graphics = [
      {
        type = "spice"

        listen = {
          type = "address"
        }
      }
    ]
  }

  running   = true
  autostart = false
}