output "nlb_security_group_id" {
  description = "Temporary NLB listener security group ID."
  value       = volcenginecc_vpc_security_group.nlb.security_group_id
}

output "backend_instance_id" {
  description = "Temporary ECS backend ID."
  value       = volcenginecc_ecs_instance.backend.instance_id
}

output "backend_private_ip" {
  description = "Temporary ECS backend private IPv4 address."
  value       = volcenginecc_ecs_instance.backend.primary_network_interface.primary_ip_address
}

output "eip_ids_by_zone" {
  description = "Temporary EIP allocation IDs keyed by availability zone."
  value = {
    for zone_id, eip in volcenginecc_vpc_eip.complete : zone_id => eip.allocation_id
  }
}
