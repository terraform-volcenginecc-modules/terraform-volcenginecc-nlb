module "nlb" {
  source  = "terraform-volcenginecc-modules/nlb/volcenginecc"
  version = "~> 1.0"

  load_balancer_name = "complete-public-nlb-${var.name_suffix}"
  description        = "Public multi-AZ TCP and UDP NLB example"
  vpc_id             = var.vpc_id
  security_group_ids = var.security_group_ids
  ipv_4_network_type = "internet"
  cross_zone_enabled = true
  zone_mappings = [
    for zone in var.zone_mappings : {
      zone_id      = zone.zone_id
      subnet_id    = zone.subnet_id
      ipv_4_eip_id = zone.ipv_4_eip_id
    }
  ]

  server_groups = {
    tcp_gateway = {
      name                        = "tcp-gateway-${var.name_suffix}"
      protocol                    = "TCP"
      scheduler                   = "wlc"
      session_persistence_enabled = true
      session_persistence_timeout = 900
      health_check = {
        type                = "TCP"
        interval            = 10
        timeout             = 3
        healthy_threshold   = 3
        unhealthy_threshold = 3
      }
      servers = {
        gateway = {
          instance_id = var.backend_instance_id
          private_ip  = var.backend_private_ip
          port        = 7000
        }
      }
    }
    udp_game = {
      name      = "udp-game-${var.name_suffix}"
      protocol  = "UDP"
      scheduler = "sh"
      health_check = {
        type                = "UDP"
        interval            = 10
        timeout             = 3
        healthy_threshold   = 3
        unhealthy_threshold = 3
      }
      servers = {
        game = {
          instance_id = var.backend_instance_id
          private_ip  = var.backend_private_ip
          port        = 9000
        }
      }
    }
  }

  listeners = {
    tcp = {
      name               = "tcp-7000-${var.name_suffix}"
      protocol           = "TCP"
      port               = 7000
      server_group_key   = "tcp_gateway"
      connection_timeout = 900
    }
    udp = {
      name             = "udp-9000-${var.name_suffix}"
      protocol         = "UDP"
      port             = 9000
      server_group_key = "udp_game"
    }
  }

  tags = {
    purpose   = "terraform-nlb-complete-example"
    temporary = "true"
  }
}
