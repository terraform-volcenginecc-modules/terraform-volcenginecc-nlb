# terraform-volcenginecc-nlb

Creates and manages a Volcengine NLB, TCP/UDP server groups, health checks,
backends, and TCP/UDP listeners.

## 1. Overview

The module owns the NLB and its direct resources. Callers own VPCs, subnets,
security groups, EIPs, and backend instances. It is suitable for long
connections such as game, IM, proxy gateway, and database proxy entry points.

## 2. Usage

```hcl
module "nlb" {
  source  = "terraform-volcenginecc-modules/nlb/volcenginecc"
  version = "~> 1.0"

  load_balancer_name = "private-tcp-entry"
  vpc_id             = "vpc-..."
  security_group_ids = ["sg-..."]
  zone_mappings = [{
    zone_id   = "cn-beijing-a"
    subnet_id = "subnet-..."
  }]

  server_groups = {
    app = {
      name     = "app-tcp"
      protocol = "TCP"
      servers = {
        app_1 = {
          instance_id = "i-..."
          private_ip  = "192.168.1.10"
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
      server_group_key = "app"
    }
  }
}
```

Provider authentication and region configuration are supplied by the caller.

## 3. Examples

- `examples/basic`: Private NLB with a TCP listener, TCP server group, and
  health check.
- `examples/complete`: Public multi-AZ NLB with independently managed EIPs,
  TCP and UDP listeners, protocol-specific health checks, TCP session
  persistence, and cross-zone forwarding.

The example descriptions cover TCP, UDP, private NLB, and multi-AZ NLB
scenarios.

## 4. Requirements

| Name | Version |
|---|---|
| Terraform | `= 1.5.7` |
| `volcengine/volcenginecc` | `>= 0.0.70, < 0.1.0` |

## 5. Providers

| Name | Version |
|---|---|
| `volcengine/volcenginecc` | `>= 0.0.70, < 0.1.0` |

## 6. Resources

| Name | Type |
|---|---|
| `volcenginecc_clb_nlb.this` | NLB instance |
| `volcenginecc_clb_nlb_server_group.this` | NLB server group |
| `volcenginecc_clb_nlb_listener.this` | NLB TCP/UDP listener |

## 7. Inputs

| Name | Required | Description |
|---|---:|---|
| `load_balancer_name` | yes | NLB instance name |
| `vpc_id` | yes | Existing VPC ID |
| `security_group_ids` | yes | Existing NLB security group IDs |
| `zone_mappings` | yes | Existing subnet mapping per availability zone |
| `ipv_4_network_type` | no | `intranet` or `internet`, defaults to `intranet` |
| `ip_address_version` | no | NLB address family: `ipv4` or `dualstack`; defaults to `ipv4` |
| `ipv_6_network_type` | no | IPv6 network type for a dual-stack NLB; defaults to `null` |
| `ipv_4_bandwidth_package_id` | no | Caller-owned IPv4 shared bandwidth package ID; defaults to `null` |
| `ipv_6_bandwidth_package_id` | no | Caller-owned IPv6 shared bandwidth package ID; defaults to `null` |
| `cross_zone_enabled` | no | Cross-zone forwarding, defaults to `true` |
| `description` | no | NLB description; defaults to an empty string |
| `project_name` | no | NLB project name; defaults to `default` |
| `modification_protection_status` | no | `NonProtection` or `ConsoleProtection`; defaults to `NonProtection` |
| `tags` | no | Common tags for all managed resources |
| `server_groups` | no | Server groups, backends, and health checks keyed by stable logical names; defaults to `{}` |
| `listeners` | no | TCP/UDP listeners keyed by stable logical names; defaults to `{}` |

## 8. Outputs

| Name | Description |
|---|---|
| `load_balancer_id` | Managed NLB ID |
| `dns_name` | Provider-assigned NLB DNS name |
| `server_group_ids` | Server group IDs keyed by logical name |
| `listener_ids` | Listener IDs keyed by logical name |

## 9. Notes

- The module supports TCP/UDP listeners only. It does not configure TLS
  listeners, certificates, log service resources, or automatic log collection
  and delivery. Configure collection resources, delivery targets, and indexes
  separately when using a log service or VPC flow logs.
- VPCs, subnets, security groups, EIPs, and backend instances must be in the
  provider's region. Subnets and security groups must belong to the supplied
  VPC, and each `zone_id` must match its subnet's availability zone.
- Public NLBs require `ipv_4_network_type = "internet"` and an external
  `ipv_4_eip_id` in every `zone_mappings` item. Each EIP must be distinct and
  available for binding. The module never creates, adopts, or releases EIPs;
  after deleting the NLB, manage EIP release through its separate lifecycle.
- NLB binding changes an EIP name to `USED_BY_NLB.<NLB_ID>`; unbinding may
  change the name to the EIP ID. A caller-managed `volcenginecc_vpc_eip` should
  use `lifecycle { ignore_changes = [name] }` to avoid drift from these platform
  changes. The configured name is used on creation, but subsequent `name`
  changes are ignored. Other EIP attributes remain managed by Terraform.
- `server_groups` and `listeners` use stable map keys. Changing a key changes
  Terraform resource addresses and can recreate the associated resource. Each
  listener's `server_group_key` must reference a defined server group, and
  their TCP/UDP protocols must match.
- Backend applications must listen on the configured backend ports. NLB and
  backend security groups, subnet ACLs, and host firewalls must allow business
  and health-check traffic. UDP health checks also require ICMP to be allowed
  by the backend security group.
- Health-check port `0` is normalized to an omitted value for non-all-port
  server groups, because the API reads the default back as `null`. All-port
  server groups require an explicit health-check port from `1` through `65535`.
- With Provider `v0.0.72`, a listener delete task may return
  `GeneralServiceException: delete failed` even after the listener has been
  removed, leaving its entry in Terraform state. First check whether the
  listener exists in the cloud. Only after confirming it is absent, run
  `terraform plan -destroy`, review the deletion scope, and then run
  `terraform destroy` to clean up remaining resources. If the listener still
  exists, investigate the delete task before proceeding. Do not manually
  remove a state entry just to suppress the error.
- Existing NLB resources can be imported using their load balancer ID. This
  module does not provide an adoption mode for partially managed NLB resources.
