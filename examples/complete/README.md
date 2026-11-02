# Complete Public Multi-AZ TCP and UDP NLB Example

Creates an internet-facing NLB across at least two availability zones, with an
independently managed EIP attached to each zone mapping. It includes a
long-lived TCP gateway listener and a UDP game listener, separate TCP and UDP
server groups, protocol-specific health checks, and cross-zone forwarding.

The caller owns the VPC, subnets, security groups, EIPs, and backend instance.
Each EIP must be available for binding to its NLB zone mapping.

The example installs `terraform-volcenginecc-modules/nlb/volcenginecc` from
the Terraform Registry with version constraint `~> 1.0`.

## Usage

```shell
terraform init
terraform plan
terraform apply
```

Configure provider authentication and region, and supply the existing resource
inputs before running these commands.

## Requirements

| Name | Version |
|---|---|
| Terraform | `= 1.5.7` |
| `volcengine/volcenginecc` | `>= 0.0.70, < 0.1.0` |

## Inputs

| Name | Description |
|---|---|
| `vpc_id` | Existing VPC ID |
| `security_group_ids` | Existing public NLB security group IDs |
| `zone_mappings` | Subnet and distinct EIP mappings for at least two availability zones |
| `backend_instance_id` | ECS backend instance ID |
| `backend_private_ip` | Backend private IPv4 address |
| `name_suffix` | NLB, listener, and server group name suffix; defaults to `example` |

## Outputs

| Name | Description |
|---|---|
| `load_balancer_id` | NLB ID created by the module |
| `dns_name` | Provider-assigned NLB DNS name |
| `listener_ids` | TCP/UDP listener IDs keyed by logical name |

## Notes

- Supply at least two distinct availability zones in `zone_mappings`, each with
  its own subnet and an EIP available for binding. Resources must be in the
  provider's region, and subnets and security groups must belong to the supplied
  VPC.
- The caller owns the EIPs. NLB binding changes their names to
  `USED_BY_NLB.<NLB_ID>`; unbinding may change the names to EIP IDs. When using
  `volcenginecc_vpc_eip`, add `lifecycle { ignore_changes = [name] }` to avoid
  drift caused by platform renaming.
- The backend application must listen on TCP `7000` and UDP `9000`. NLB and
  backend security groups, subnet ACLs, and host firewalls must allow business
  and health-check traffic. UDP health checks also require ICMP to be allowed
  by the backend security group. The example does not create or modify these
  rules.
- The TCP listener's idle connection timeout and the TCP server group's session
  persistence timeout are both set to `900` seconds. These are independent
  settings and should be adjusted separately for the application's needs.
- Registry installation uses a module version in the `~> 1.0` range. Local
  repository changes do not update the Registry module. To use the local
  module, change `source` to `../..` and remove `version`.
- The module does not configure TLS listeners, certificates, log service
  resources, or automatic log collection and delivery. Configure collection
  resources, delivery targets, and indexes separately for log services or VPC
  flow logs.
- With Provider `v0.0.72`, a listener delete may return
  `GeneralServiceException: delete failed` and retain its state entry. Confirm
  the cloud listener is absent before reviewing another destroy plan and
  cleaning up remaining resources. See the [module notes](../../README.md#9-notes).
- When the example resources are no longer needed, review
  `terraform plan -destroy` before running `terraform destroy`. The example
  removes only its NLB, listeners, and server groups. Manage EIP, VPC, subnet,
  security group, and ECS retention or release separately.
- Supply credentials through provider-supported configuration, not source files.
