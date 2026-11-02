variable "load_balancer_name" {
  type        = string
  description = "Name of the NLB instance."

  validation {
    condition     = length(trimspace(var.load_balancer_name)) >= 1 && length(var.load_balancer_name) <= 128
    error_message = "load_balancer_name must contain between 1 and 128 characters."
  }
}

variable "vpc_id" {
  type        = string
  description = "Existing VPC ID. The module does not create or manage the VPC."

  validation {
    condition     = length(trimspace(var.vpc_id)) > 0
    error_message = "vpc_id must not be empty."
  }
}

variable "security_group_ids" {
  type        = set(string)
  description = "Existing security groups associated with the NLB."

  validation {
    condition     = length(var.security_group_ids) > 0 && alltrue([for id in var.security_group_ids : length(trimspace(id)) > 0])
    error_message = "security_group_ids must contain at least one non-empty ID."
  }
}

variable "zone_mappings" {
  type = list(object({
    zone_id       = string
    subnet_id     = string
    ipv_4_address = optional(string)
    ipv_4_eip_id  = optional(string)
  }))
  description = "Existing subnet mapping for each NLB availability zone. Public NLBs need one caller-owned EIP ID per mapping."

  validation {
    condition     = length(var.zone_mappings) > 0 && alltrue([for mapping in var.zone_mappings : length(trimspace(mapping.zone_id)) > 0 && length(trimspace(mapping.subnet_id)) > 0])
    error_message = "zone_mappings must contain at least one non-empty zone_id and subnet_id pair."
  }
}

variable "ipv_4_network_type" {
  type        = string
  description = "IPv4 entry-point type: intranet for private NLB or internet for public NLB."
  default     = "intranet"

  validation {
    condition     = contains(["intranet", "internet"], var.ipv_4_network_type)
    error_message = "ipv_4_network_type must be intranet or internet."
  }
}

variable "ip_address_version" {
  type        = string
  description = "NLB address family."
  default     = "ipv4"

  validation {
    condition     = contains(["ipv4", "dualstack"], var.ip_address_version)
    error_message = "ip_address_version must be ipv4 or dualstack."
  }
}

variable "ipv_6_network_type" {
  type        = string
  description = "Optional IPv6 entry-point type when ip_address_version is dualstack."
  default     = null
  nullable    = true

  validation {
    condition     = try(contains(["intranet", "internet"], var.ipv_6_network_type), true)
    error_message = "ipv_6_network_type must be null, intranet, or internet."
  }
}

variable "ipv_4_bandwidth_package_id" {
  type        = string
  description = "Optional caller-owned IPv4 shared bandwidth package ID."
  default     = null
  nullable    = true
}

variable "ipv_6_bandwidth_package_id" {
  type        = string
  description = "Optional caller-owned IPv6 shared bandwidth package ID."
  default     = null
  nullable    = true
}

variable "cross_zone_enabled" {
  type        = bool
  description = "Whether backends can receive traffic from all NLB availability zones."
  default     = true
}

variable "description" {
  type        = string
  description = "NLB instance description."
  default     = ""
}

variable "project_name" {
  type        = string
  description = "Project owning the NLB instance."
  default     = "default"
}

variable "modification_protection_status" {
  type        = string
  description = "Console modification protection status."
  default     = "NonProtection"

  validation {
    condition     = contains(["NonProtection", "ConsoleProtection"], var.modification_protection_status)
    error_message = "modification_protection_status must be NonProtection or ConsoleProtection."
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to the NLB, all managed server groups, and listeners."
  default     = {}
}

variable "server_groups" {
  type = map(object({
    name                          = string
    protocol                      = string
    type                          = optional(string, "instance")
    description                   = optional(string, "")
    project_name                  = optional(string, "default")
    scheduler                     = optional(string, "wrr")
    ip_address_version            = optional(string, "ipv4")
    any_port_enabled              = optional(bool, false)
    bypass_security_group_enabled = optional(bool, false)
    connection_drain_enabled      = optional(bool, false)
    connection_drain_timeout      = optional(number)
    preserve_client_ip_enabled    = optional(bool, false)
    session_persistence_enabled   = optional(bool, false)
    session_persistence_timeout   = optional(number)
    proxy_protocol_type           = optional(string, "off")
    timestamp_remove_enabled      = optional(bool)
    health_check = optional(object({
      enabled             = optional(bool, true)
      type                = optional(string, "TCP")
      port                = optional(number)
      interval            = optional(number, 10)
      timeout             = optional(number, 3)
      healthy_threshold   = optional(number, 3)
      unhealthy_threshold = optional(number, 3)
      method              = optional(string)
      uri                 = optional(string)
      domain              = optional(string)
      http_code           = optional(string)
      udp_request         = optional(string)
      udp_expect          = optional(string)
    }))
    servers = map(object({
      instance_id = string
      private_ip  = string
      port        = optional(number, 0)
      type        = optional(string, "ecs")
      weight      = optional(number, 100)
      description = optional(string, "")
      zone_id     = optional(string)
    }))
  }))
  description = "Server groups keyed by stable logical names. Their backend servers, health checks, and protocol are managed by this module."
  default     = {}

  validation {
    condition     = alltrue([for group in values(var.server_groups) : length(trimspace(group.name)) > 0 && contains(["TCP", "UDP"], group.protocol) && contains(["instance", "ip"], group.type) && contains(["wrr", "wlc", "sh"], group.scheduler) && contains(["ipv4", "ipv6"], group.ip_address_version) && contains(["off", "standard"], group.proxy_protocol_type)])
    error_message = "Server groups must use supported name, protocol, type, scheduler, IP version, and Proxy Protocol values."
  }

  validation {
    condition = alltrue(flatten([
      for group in values(var.server_groups) : [
        for server in values(group.servers) : length(trimspace(server.instance_id)) > 0 && (
          group.ip_address_version == "ipv4" ?
          !strcontains(server.private_ip, ":") && can(cidrhost("${server.private_ip}/32", 0)) :
          strcontains(server.private_ip, ":") && can(cidrhost("${server.private_ip}/128", 0))
        ) && contains(["ecs", "eni", "ip"], server.type) && (group.any_port_enabled ? server.port >= 0 && server.port <= 65535 : server.port >= 1 && server.port <= 65535) && server.weight >= 0 && server.weight <= 100 && (server.type != "ip" || try(length(trimspace(server.zone_id)) > 0, false))
      ]
    ]))
    error_message = "Backends need IDs, IP addresses matching their server group address family, supported types, valid ports, weights 0-100, and a zone_id for IP backends; port 0 is only valid with any_port_enabled."
  }

  validation {
    condition = alltrue([
      for group in values(var.server_groups) : group.health_check == null ? true : (
        contains(["TCP", "HTTP", "UDP"], group.health_check.type) &&
        group.health_check.healthy_threshold >= 2 && group.health_check.healthy_threshold <= 10 &&
        group.health_check.unhealthy_threshold >= 2 && group.health_check.unhealthy_threshold <= 10 &&
        group.health_check.interval >= 1 && group.health_check.interval <= 300 &&
        group.health_check.timeout >= 1 && group.health_check.timeout <= 60 &&
        (
          group.health_check.port == null ?
          !group.any_port_enabled :
          group.health_check.port >= (group.any_port_enabled ? 1 : 0) && group.health_check.port <= 65535
        )
      )
    ])
    error_message = "Health checks must use supported protocol and documented threshold, interval, timeout, and port ranges; all-port groups require a health-check port from 1 to 65535."
  }
}

variable "listeners" {
  type = map(object({
    name               = string
    server_group_key   = string
    protocol           = string
    port               = number
    description        = optional(string, "")
    enabled            = optional(bool, true)
    connection_timeout = optional(number)
    start_port         = optional(number)
    end_port           = optional(number)
  }))
  description = "TCP or UDP listeners keyed by stable logical names."
  default     = {}

  validation {
    condition     = alltrue([for listener in values(var.listeners) : contains(["TCP", "UDP"], listener.protocol) && listener.port >= 0 && listener.port <= 65535 && (listener.port != 0 || try(listener.start_port >= 1 && listener.end_port <= 65535 && listener.start_port <= listener.end_port, false))])
    error_message = "Listeners must be TCP or UDP with a valid port; port 0 requires a valid range."
  }
}
