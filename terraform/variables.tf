variable "resource_group_name" {
  description = "The name of the resource group to deploy to."
  type        = string
}

variable "ingress_vnet_name" {
  description = "The Ingress VNet that has already been deployed."
  type        = string
}

variable "ingress_subnet_name" {
  description = "The name of the subnet to deploy to within the VNET specified in `vnet_name`."
  type        = string
}

variable "internal_cidr_range" {
  description = "The CIDR range to provision for the Internal VNet."
  type        = string
  default     = "10.0.4.0/22"
}

variable "internal_num_subnets" {
  description = "The number of regular subnets to deploy in the VNet."
  type        = number
  default     = 2
}

variable "hub_cidr_range" {
  description = "The CIDR range to provision for the Hub VNet"
  type        = string
  default     = "10.0.8.0/22"
}
