locals {
  subnets_config = {
    for name, internal_vnet in var.internal_vnets_config : name => {
      cidr_range = internal_vnet.cidr_range
      subnets = merge({ for i in range(internal_vnet.num_subnets) :
        "private-subnet-${i}" => cidrsubnet(internal_vnet.cidr_range, ceil(log(internal_vnet.num_subnets + 1, 2)), i)
      }, internal_vnet.enable_bastion ? { "AzureBastionSubnet" = cidrsubnet(internal_vnet.cidr_range, ceil(log(internal_vnet.num_subnets + 1, 2)), pow(2, ceil(log(internal_vnet.num_subnets + 1, 2))) - 1) } : {})
    }
  }
}