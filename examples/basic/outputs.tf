output "load_balancer_id" {
  description = "Managed private NLB ID."
  value       = module.nlb.load_balancer_id
}

output "dns_name" {
  description = "Private NLB DNS name."
  value       = module.nlb.dns_name
}
