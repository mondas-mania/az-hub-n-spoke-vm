# Terraform Hub & Spoke VM

Deploying a simple Hub & Spoke network with a VM as a router.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | ~> 3.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_hub_vnet"></a> [hub\_vnet](#module\_hub\_vnet) | Azure/vnet/azurerm | ~> 4.0 |
| <a name="module_internal_vnet"></a> [internal\_vnet](#module\_internal\_vnet) | Azure/vnet/azurerm | ~> 4.0 |

## Resources

| Name | Type |
|------|------|
| [azurerm_resource_group.resource_group](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |
| [azurerm_subnet.ingress_subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subnet) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_hub_cidr_range"></a> [hub\_cidr\_range](#input\_hub\_cidr\_range) | The CIDR range to provision for the Hub VNet | `string` | `"10.0.8.0/22"` | no |
| <a name="input_ingress_subnet_name"></a> [ingress\_subnet\_name](#input\_ingress\_subnet\_name) | The name of the subnet to deploy to within the VNET specified in `vnet_name`. | `string` | n/a | yes |
| <a name="input_ingress_vnet_name"></a> [ingress\_vnet\_name](#input\_ingress\_vnet\_name) | The Ingress VNet that has already been deployed. | `string` | n/a | yes |
| <a name="input_internal_cidr_range"></a> [internal\_cidr\_range](#input\_internal\_cidr\_range) | The CIDR range to provision for the Internal VNet. | `string` | `"10.0.4.0/22"` | no |
| <a name="input_internal_num_subnets"></a> [internal\_num\_subnets](#input\_internal\_num\_subnets) | The number of regular subnets to deploy in the VNet. | `number` | `2` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The name of the resource group to deploy to. | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->