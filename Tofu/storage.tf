resource "libvirt_volume" "base_image" {
  name = vm_base_image_path
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


resource "libvirt_volume" "vm_disk" {
  for_each = var.VMS

  name = "${each.key}-disk.qcow2"
  pool = var.vm_pool_name

  # Virtual disk capacity for the VM.
  #
  # Example:
  # disk_size = 50
  # capacity_unit = "GiB"
  #
  # The physical QCOW2 file will NOT immediately consume this amount.
  capacity      = each.value.disk_size
  capacity_unit = "GiB"

  target = {
    format = {
      type = "qcow2"
    }
  }

  backing_store = {
    path = libvirt_volume.base_image.path

    format = {
      type = "qcow2"
    }
  }

  depends_on = [
    libvirt_volume.base_image
  ]
}
