terraform {
  required_version = "= 1.5.7"

  required_providers {
    volcenginecc = {
      source  = "volcengine/volcenginecc"
      version = "= 0.0.71"
    }
  }
}

provider "volcenginecc" {
  region = var.region
}

resource "volcenginecc_vpc_security_group" "nlb" {
  vpc_id              = var.vpc_id
  security_group_name = "tf-nlb-validation-lb-${var.name_suffix}"
  description         = "Temporary NLB listener security group"
  project_name        = "default"

  ingress_permissions = [
    {
      cidr_ip         = "0.0.0.0/0"
      prefix_list_id  = ""
      source_group_id = ""
      description     = "Temporary TCP listener access"
      direction       = "ingress"
      policy          = "accept"
      port_start      = 443
      port_end        = 7000
      priority        = 1
      protocol        = "tcp"
    },
    {
      cidr_ip         = "0.0.0.0/0"
      prefix_list_id  = ""
      source_group_id = ""
      description     = "Temporary UDP listener access"
      direction       = "ingress"
      policy          = "accept"
      port_start      = 9000
      port_end        = 9000
      priority        = 2
      protocol        = "udp"
    },
  ]

  tags = [
    {
      key   = "purpose"
      value = "terraform-nlb-real-cloud-validation"
    },
    {
      key   = "temporary"
      value = "true"
    },
  ]
}

resource "volcenginecc_vpc_security_group" "backend" {
  vpc_id              = var.vpc_id
  security_group_name = "tf-nlb-validation-backend-${var.name_suffix}"
  description         = "Temporary NLB backend security group"
  project_name        = "default"

  ingress_permissions = [
    {
      cidr_ip         = ""
      prefix_list_id  = ""
      source_group_id = volcenginecc_vpc_security_group.nlb.security_group_id
      description     = "Basic TCP NLB backend access"
      direction       = "ingress"
      policy          = "accept"
      port_start      = 8080
      port_end        = 8080
      priority        = 1
      protocol        = "tcp"
    },
    {
      cidr_ip         = ""
      prefix_list_id  = ""
      source_group_id = volcenginecc_vpc_security_group.nlb.security_group_id
      description     = "TCP NLB backend access"
      direction       = "ingress"
      policy          = "accept"
      port_start      = 7000
      port_end        = 7000
      priority        = 2
      protocol        = "tcp"
    },
    {
      cidr_ip         = ""
      prefix_list_id  = ""
      source_group_id = volcenginecc_vpc_security_group.nlb.security_group_id
      description     = "UDP NLB backend access"
      direction       = "ingress"
      policy          = "accept"
      port_start      = 9000
      port_end        = 9000
      priority        = 3
      protocol        = "udp"
    },
    {
      cidr_ip         = ""
      prefix_list_id  = ""
      source_group_id = volcenginecc_vpc_security_group.nlb.security_group_id
      description     = "NLB health check ICMP access"
      direction       = "ingress"
      policy          = "accept"
      port_start      = -1
      port_end        = -1
      priority        = 4
      protocol        = "icmp"
    },
  ]

}

resource "volcenginecc_ecs_instance" "backend" {
  instance_name        = "tf-nlb-validation-${var.name_suffix}"
  instance_type        = "ecs.g3il.large"
  zone_id              = var.zone_mappings[0].zone_id
  instance_charge_type = "PostPaid"
  spot_strategy        = "NoSpot"
  password             = var.instance_password
  image = {
    image_id = "image-yc0efhx6jv4qwlql1jmt"
  }
  primary_network_interface = {
    subnet_id          = var.zone_mappings[0].subnet_id
    security_group_ids = [volcenginecc_vpc_security_group.backend.security_group_id]
  }
  system_volume = {
    volume_type          = "ESSD_PL0"
    size                 = 40
    delete_with_instance = true
  }
  user_data = base64encode(<<-EOT
    #!/bin/bash
    nohup python3 -m http.server 8080 >/tmp/nlb-basic-tcp.log 2>&1 &
    nohup python3 -m http.server 7000 >/tmp/nlb-tcp.log 2>&1 &
    cat >/tmp/nlb_udp.py <<'PY'
    import socket

    server = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    server.bind(("0.0.0.0", 9000))

    while True:
        _, address = server.recvfrom(2048)
        server.sendto(b"ok", address)
    PY
    nohup python3 /tmp/nlb_udp.py >/tmp/nlb-udp.log 2>&1 &
  EOT
  )
  tags = [
    {
      key   = "purpose"
      value = "terraform-nlb-real-cloud-validation"
    },
    {
      key   = "temporary"
      value = "true"
    },
  ]
}

resource "volcenginecc_vpc_eip" "complete" {
  for_each = {
    for mapping in var.zone_mappings : mapping.zone_id => mapping
  }

  lifecycle {
    ignore_changes = [name]
  }

  name         = "tf-nlb-validation-${each.key}-${var.name_suffix}"
  description  = "Temporary public NLB EIP"
  isp          = "BGP"
  billing_type = 3
  bandwidth    = 1
  project_name = "default"
  tags = [
    {
      key   = "purpose"
      value = "terraform-nlb-real-cloud-validation"
    },
    {
      key   = "temporary"
      value = "true"
    },
  ]
}
