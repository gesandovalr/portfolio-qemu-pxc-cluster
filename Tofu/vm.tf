# libvirt configuration options
provider "libvirt" {
  uri = "qemu:///system"
}

##
resource "libvirt_domain" "example" {
  name   = "example-vm"
  memory = 2048
  memory_unit   = "MiB"
  vcpu   = 2
  type   = "kvm"

  os = {
    type         = "hvm"
    type_arch    = "x86_64"
    type_machine = "q35"
    boot_devices = ["hd", "network"]
  }

  devices = {
    disk = [
    {
      volume = {
        pool   = var.vm_pool_name
        volume = libvirt_volume.local_template[each.key].name
    }
  },
  {
      volume = {
        pool   = var.vm_pool_name
        volume = libvirt_volume.cloudinit_iso[each.key].name
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
  }
}


