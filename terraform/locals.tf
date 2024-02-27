locals {
  num_new_bits = ceil(log(var.internal_num_subnets, 2))

  private_subnets = [for i in range(var.internal_num_subnets) :
    {
      name = "private-subnet-${i}"
      cidr = cidrsubnet(var.internal_cidr_range, local.num_new_bits, i),
    }
  ]

  internal_subnets         = local.private_subnets
  internal_subnet_names    = [for subnet in local.internal_subnets : subnet.name]
  internal_subnet_prefixes = [for subnet in local.internal_subnets : subnet.cidr]
}