locals {
  nat_gws = {
    for vnet_name, vnet_config in var.internal_vnets_config : vnet_name => [
      for subnet_name, subnet_id in module.spoke_vnet[vnet_name].vnet_subnets_name_id :
      subnet_id if subnet_name != "AzureBastionSubnet"
    ] if vnet_config.enable_nat_gw
  }
}
