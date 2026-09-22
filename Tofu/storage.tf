# Define storage Pool

resource "libvirt_pool" "vm_pool" {
  name = var.vm_pool_name
  type = dir
  target = {
    path = var.vm_pool_path
  }
}