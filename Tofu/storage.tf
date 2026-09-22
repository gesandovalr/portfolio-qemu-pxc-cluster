resource "libvirt_volume" "local_template" {
  for_each = var.VMS

  name = "${each.key}-disk.qcow2"
  pool = var.vm_pool_name

  target = {
    format = {
      type = "qcow2"
    }
  }

  create = {
    content = {
      url = "file://${var.vm_base_image_path}"
    }
  }
}