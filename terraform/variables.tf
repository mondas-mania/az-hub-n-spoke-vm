variable "resource_group_name" {
  description = "The name of the resource group to deploy to."
  type        = string
}

variable "ingress_vnet_name" {
  description = "The Ingress VNet that has already been deployed."
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

variable "router_password" {
  description = "The password for the Router VM. May be stored as plain text in the state."
  type        = string
  default     = null
  sensitive   = true
}

variable "enable_app_gw" {
  description = "A boolean to determine whether to enable the Application Gateway."
  type        = bool
  default     = false
}

variable "enable_webserver" {
  description = "A boolean to determine whether to enable the Web Server for testing out inbound connectivity."
  type        = bool
  default     = false
}
