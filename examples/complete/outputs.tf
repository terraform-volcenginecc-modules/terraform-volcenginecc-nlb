output "load_balancer_id" {
  description = "Managed public multi-AZ NLB ID."
  value       = module.nlb.load_balancer_id
}

output "dns_name" {
  description = "Public NLB DNS name for an external DNS record."
  value       = module.nlb.dns_name
}

output "listener_ids" {
  description = "TCP and UDP listener IDs."
  value       = module.nlb.listener_ids
}
