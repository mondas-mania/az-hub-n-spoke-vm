variable "resource_group_name" {
  description = "The name of the resource group to deploy to."
  type        = string
}

variable "internal_vnets_config" {
  description = "A map of configuration for internal VNets to deploy and connect to the hub."
  type = map(object({
    cidr_range        = string
    num_subnets       = number
    deploy_wsi        = optional(bool, false)
    enable_bastion    = optional(bool, false)
    enable_nat_gw     = optional(bool, false)
    service_endpoints = optional(list(string), [])

    app_gw_config = optional(object({
      deploy_app_gw = optional(bool, false)
      target_vnets  = optional(list(string), [])
    }), {})
  }))
}

variable "supernet_cidr_range" {
  description = <<EOT
  The \"supernet\" cidr range that will be used to define routes through the hub.
  This should cover all of your VNet address spaces. Defaults to 10.0.0.0/8.
  EOT
  type        = string
  default     = "10.0.0.0/8"
}

variable "hub_cidr_range" {
  description = "The CIDR range to provision for the Hub VNet"
  type        = string
  default     = "10.0.0.0/22"
}

variable "router_password" {
  description = "The password for the Router VM. May be stored as plain text in the state."
  type        = string
  default     = null
  sensitive   = true
}

variable "enable_router_vm" {
  description = "A boolean to determine whether to enable the Router VM in the Hub VNet."
  type        = bool
  default     = false
}

variable "enable_central_bastion" {
  description = <<EOT
  A boolean to determine whether to enable a Bastion host in the hub virtual network.
  This Bastion will be able to connect to VMs in any spoke VNet.
  EOT
  type        = bool
  default     = false
}

variable "enable_central_nat_gateway" {
  description = <<EOT
  A boolean to determine whether to create a NAT Gateway in the hub virtual network.
  This will be used by all spoke VNets without dedicated NAT Gateways.
  EOT
  type        = bool
  default     = false
}

variable "enable_central_firewall" {
  description = <<EOT
  A boolean to determine whether to create an Azure Firewall in the hub virtual network.
  EOT
  type        = bool
  default     = false
}
