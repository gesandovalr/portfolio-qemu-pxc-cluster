# Define storage Pool
resource "libvirt_pool" "vm_pool" {
  name = var.vm_pool_name
  type = dir
  target = {
    path = var.vm_pool_path
  }
}

## Define storage volume for base image
resource "libvirt_volume" "local_template" {
  for_each = var.VMS
  name   = "${each.key}-disk.qcow2"
  #name = "var.base_template_name"
  pool = "var.vm_pool_name"
  target = {
    format = {
      type = "qcow2"
    }
  }

  # Local paths or HTTP URLs must go inside the 'create.content.url' block
  create = {
    content = {
      url = "file://${var.vm_base_image_path}"
    }
  }
}