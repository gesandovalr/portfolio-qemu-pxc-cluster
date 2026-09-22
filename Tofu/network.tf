#resource "libvirt_network" "example" {
#  name = "local-net"
#  domain = {
#    name = "localhost.localdomain"
#  }

#  # Fixed: Use a standard list with a 'for' expression instead of a dynamic block
#  ips = [
#      address = vm.ipv4_add_nic
#      netmask = vm.netmask
#    }
#  ]
#}