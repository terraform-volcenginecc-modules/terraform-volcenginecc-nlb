output "load_balancer_id" {
  description = "ID of the managed NLB instance."
  value       = volcenginecc_clb_nlb.this.load_balancer_id
}

output "dns_name" {
  description = "Provider-assigned DNS name of the NLB instance."
  value       = volcenginecc_clb_nlb.this.dns_name
}

output "server_group_ids" {
  description = "Managed server group IDs keyed by their input logical names."
  value = {
    for key, group in volcenginecc_clb_nlb_server_group.this : key => group.server_group_id
  }
}

output "listener_ids" {
  description = "Managed listener IDs keyed by their input logical names."
  value = {
    for key, listener in volcenginecc_clb_nlb_listener.this : key => listener.listener_id
  }
}
