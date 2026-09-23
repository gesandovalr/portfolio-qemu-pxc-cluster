## Variables  

## Define Storage Pool Name
variable "vm_pool_name" {
  description = "Name of the libvirt storage pool"
  type        = string
  default     = "Virtual_Machines"
}

## Define Storage Pool Path
variable "vm_pool_path" {
  description = "Filesystem path used by the libvirt storage pool"
  type        = string
  default     = "/home/gesora/virtual_machines/VMs"
}

## Define base image path
variable "vm_base_template_name" {
    description = "name of the local QCOW2 base image"
    type        = string

}

## Define base image path
variable "vm_base_image_path" {
    description = "Path to the local QCOW2 base image"
    type        = string
}

variable "ssh_public_key" {
    description = "Public SSH key for the VMs"
    type        = string
    default     = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEgInN0JnG0h1EtCcT/1cC+8mpQw6d1dpVku/f4pPP1K gesora@odin"
}

variable "vm_network_name" {
  description = "Existing libvirt network used by the VMs"
  type        = string
  default     = "LAN"
}

variable "vm_disk_capacity" {
  description = "Existing libvirt network used by the VMs"
  type        = number
  default     = "50"
}

variable "vm_user_password_hash" {
  description = "Password hash for the VM user"
  type        = string
  sensitive   = true
}

variable "VMS" {
  type = map(object({
    name         = string
    memory       = number
    vcpu         = number
    ipv4_add_nic = string
    netmask      = number
  }))
  default = {
    PERCDBTEST01 = {
      name         = "PERCDBTEST01"
      memory       = 2048
      vcpu         = 2
      ipv4_add_nic = "10.20.10.10"
      netmask      = 24
    },
    PERCDBTEST02 = {
      name         = "PERCDBTEST02"
      memory       = 2048
      vcpu         = 2  
      ipv4_add_nic = "10.20.10.11"
      netmask      = 24
    },
    PERCDBTEST03 = {
      name         = "PERCDBTEST03"
      memory       = 2048
      vcpu         = 2
      ipv4_add_nic = "10.20.10.12"
      netmask      = 24
    }
  }
}