locals {
  tags = [
    for key, value in var.tags : {
      key   = key
      value = value
    }
  ]
}

resource "volcenginecc_clb_nlb" "this" {
  ipv_4_network_type             = var.ipv_4_network_type
  security_group_ids             = var.security_group_ids
  vpc_id                         = var.vpc_id
  zone_mappings                  = var.zone_mappings
  load_balancer_name             = var.load_balancer_name
  description                    = var.description
  project_name                   = var.project_name
  ip_address_version             = var.ip_address_version
  ipv_6_network_type             = var.ipv_6_network_type
  ipv_4_bandwidth_package_id     = var.ipv_4_bandwidth_package_id
  ipv_6_bandwidth_package_id     = var.ipv_6_bandwidth_package_id
  cross_zone_enabled             = var.cross_zone_enabled
  modification_protection_status = var.modification_protection_status
  tags                           = local.tags

  lifecycle {
    precondition {
      condition     = var.ipv_4_network_type != "internet" || alltrue([for mapping in var.zone_mappings : mapping.ipv_4_eip_id != null])
      error_message = "Internet NLBs require an externally managed ipv_4_eip_id for every zone mapping."
    }
  }
}

resource "volcenginecc_clb_nlb_server_group" "this" {
  for_each = var.server_groups

  vpc_id                        = var.vpc_id
  server_group_name             = each.value.name
  protocol                      = each.value.protocol
  type                          = each.value.type
  description                   = each.value.description
  project_name                  = each.value.project_name
  scheduler                     = each.value.scheduler
  ip_address_version            = each.value.ip_address_version
  any_port_enabled              = each.value.any_port_enabled
  bypass_security_group_enabled = each.value.bypass_security_group_enabled
  connection_drain_enabled      = each.value.connection_drain_enabled
  connection_drain_timeout      = each.value.connection_drain_timeout
  preserve_client_ip_enabled    = each.value.preserve_client_ip_enabled
  session_persistence_enabled   = each.value.session_persistence_enabled
  session_persistence_timeout   = each.value.session_persistence_timeout
  proxy_protocol_type           = each.value.proxy_protocol_type
  timestamp_remove_enabled      = each.value.timestamp_remove_enabled
  health_check = each.value.health_check == null ? null : {
    for key, value in each.value.health_check : key => value
    if value != null && !(key == "port" && !each.value.any_port_enabled && value == 0)
  }
  servers = [
    for server in values(each.value.servers) : {
      instance_id = server.instance_id
      ip          = server.private_ip
      port        = server.port
      type        = server.type
      weight      = server.weight
      description = server.description
      zone_id     = server.zone_id
    }
  ]
  tags = local.tags
}

resource "volcenginecc_clb_nlb_listener" "this" {
  for_each = var.listeners

  load_balancer_id   = volcenginecc_clb_nlb.this.load_balancer_id
  server_group_id    = volcenginecc_clb_nlb_server_group.this[each.value.server_group_key].server_group_id
  listener_name      = each.value.name
  protocol           = each.value.protocol
  port               = each.value.port
  end_port           = each.value.end_port
  start_port         = each.value.start_port
  connection_timeout = each.value.connection_timeout
  description        = each.value.description
  enabled            = each.value.enabled
  tags               = local.tags

  lifecycle {
    precondition {
      condition     = contains(keys(var.server_groups), each.value.server_group_key)
      error_message = "Every listener server_group_key must reference a key in server_groups."
    }

    precondition {
      condition     = var.server_groups[each.value.server_group_key].protocol == each.value.protocol
      error_message = "A listener protocol must match its server group protocol."
    }
  }
}
