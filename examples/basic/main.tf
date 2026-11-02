module "nlb" {
  source  = "terraform-volcenginecc-modules/nlb/volcenginecc"
  version = "~> 1.0"

  load_balancer_name = "basic-private-tcp-nlb-${var.name_suffix}"
  vpc_id             = var.vpc_id
  security_group_ids = var.security_group_ids
  zone_mappings = [{
    zone_id   = var.zone_id
    subnet_id = var.subnet_id
  }]

  server_groups = {
    tcp_backend = {
      name     = "basic-tcp-backend"
      protocol = "TCP"
      health_check = {
        type = "TCP"
      }
      servers = {
        app = {
          instance_id = var.backend_instance_id
          private_ip  = var.backend_private_ip
          port        = 8080
        }
      }
    }
  }

  listeners = {
    tcp = {
      name             = "tcp-8080"
      protocol         = "TCP"
      port             = 8080
      server_group_key = "tcp_backend"
    }
  }

  tags = {
    purpose   = "terraform-nlb-basic-example"
    temporary = "true"
  }
}
