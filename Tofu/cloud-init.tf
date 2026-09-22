resource "libvirt_cloudinit_config" "commoninit" {
  for_each = var.VMS

  name      = "${each.key}-init.iso"
  pool      = "default"

  user_data = <<EOF
#cloud-config
hostname: ${each.value.name}
manage_etc_hosts: true
EOF

  # This configures the network interface explicitly with your static IP inside the VM
  network_config = <<EOF
version: 2
ethernets:
  ens3:
    dhcp4: false
    addresses:
      - ${each.value.ipv4_add_nic}/${each.value.netmask}
EOF
}