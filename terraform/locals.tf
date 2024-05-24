locals {
  subnets_config = {
    for name, internal_vnet in var.internal_vnets_config : name => {
      cidr_range = internal_vnet.cidr_range
      subnets = merge({ for i in range(internal_vnet.num_subnets) :
        "private-subnet-${i}" => cidrsubnet(internal_vnet.cidr_range, ceil(log(internal_vnet.num_subnets + 2, 2)), i)
        },
        internal_vnet.enable_bastion ? { "AzureBastionSubnet" = cidrsubnet(internal_vnet.cidr_range, ceil(log(internal_vnet.num_subnets + 2, 2)), pow(2, ceil(log(internal_vnet.num_subnets + 2, 2))) - 1) } : {},
        internal_vnet.app_gw_config.deploy_app_gw ? { "AppGWSubnet" = cidrsubnet(internal_vnet.cidr_range, ceil(log(internal_vnet.num_subnets + 2, 2)), pow(2, ceil(log(internal_vnet.num_subnets + 2, 2))) - 2) } : {}
      )
      service_endpoints = internal_vnet.service_endpoints
      subnet_delegation = internal_vnet.subnet_delegation
    }
  }

  hub_subnets_config = {
    cidr_range = var.hub_cidr_range
    subnets = merge(
      { "hub-subnet-0" = cidrsubnet(var.hub_cidr_range, 2, 0) },
      var.enable_central_bastion ? { "AzureBastionSubnet" = cidrsubnet(var.hub_cidr_range, 2, 1) } : {},
      var.enable_central_firewall ? { "AzureFirewallSubnet" = cidrsubnet(var.hub_cidr_range, 2, 2) } : {}
    )
  }
}