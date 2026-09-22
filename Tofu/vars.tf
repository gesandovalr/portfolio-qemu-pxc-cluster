## Variables  

## Define Storage Pool Name
variable "vm_pool_name" {
  description = "Name of the libvirt storage pool"
  type        = string
  default     = "vms-templates"
}

## Define Storage Pool Path
variable "vm_pool_path" {
  description = "Filesystem path used by the libvirt storage pool"
  type        = string
  default     = "/srv/vms/virtual_machines"
}

## Define base image path
variable "vm_base_template_name" {
    description = "name of the local QCOW2 base image"
    type        = string
    default     = "al9.8-base.qcow2"

}

## Define base image path
variable "vm_base_image_path" {
    description = "Path to the local QCOW2 base image"
    type        = string
    default     = "/srv/vms/virtual_machines/al9.8-base.qcow2"

}

variable "ssh_public_key" {
    description = "Public SSH key for the VMs"
    type        = string
    default     = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEgInN0JnG0h1EtCcT/1cC+8mpQw6d1dpVku/f4pPP1K gesora@odin"
}


variable "VMS" {
  type = map(object({
    name         = string
    ipv4_add_nic = string
    netmask      = string
  }))
  default = {
    PERCDBTEST01 = {
      name         = "PERCDBTEST01"
      ipv4_add_nic = "10.20.10.10"
      netmask      = "255.255.255.0"
    },
    PERCDBTEST02 = {
      name         = "PERCDBTEST02"
      ipv4_add_nic = "10.20.10.11"
      netmask      = "255.255.255.0"
    },
    PERCDBTEST03 = {
      name         = "PERCDBTEST03"
      ipv4_add_nic = "10.20.10.12"
      netmask      = "255.255.255.0"
    }
  }
}