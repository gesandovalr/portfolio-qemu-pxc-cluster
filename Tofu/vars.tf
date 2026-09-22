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
variable "base_image_path" {
    description = "Path to the local QCOW2 base image"
    type        = string
    default     = "/srv/vms/virtual_machines/al9.8-base.qcow2"

}

variable "VMS" {
    type = map
    default = {
      EQFPERCDBTEST01 = {
        name         = "PERCDBTEST01"
        ipv4_add_nic = "10.20.10.20"    
    },
      EQFPERCDBTEST02 = {
        name         = "PERCDBTEST02"
        ipv4_add_nic = "10.20.10.21"        
    },
      EQFPERCDBTEST03 = {
        name         = "PERCDBTEST903"
        ipv4_add_nic = "10.20.10.22"
    },
  }
}
