# Basic Private TCP NLB Example

Creates an intranet NLB with one availability zone, a TCP listener on port
8080, one TCP server group, and TCP health checks. The caller provides the
VPC, subnet, security group, and ECS backend.

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
| `security_group_ids` | Existing NLB security group IDs |
| `zone_id` | NLB availability zone |
| `subnet_id` | Existing NLB subnet ID |
| `backend_instance_id` | ECS backend instance ID |
| `backend_private_ip` | Backend private IPv4 address |
| `name_suffix` | NLB name suffix; defaults to `example` |

## Outputs

| Name | Description |
|---|---|
| `load_balancer_id` | NLB ID created by the module |
| `dns_name` | Provider-assigned NLB DNS name |

## Notes

- This example uses a private IPv4 entry point without an EIP. The caller owns
  the VPC, subnet, security groups, and ECS instance. The subnet and security
  groups must belong to the supplied VPC, and `zone_id` must match the subnet.
- The backend application must listen on TCP `8080`. NLB and backend security
  groups, subnet ACLs, and host firewalls must allow business and TCP
  health-check traffic. The example does not create or modify these rules.
- Registry installation uses a module version in the `~> 1.0` range. Local
  repository changes do not update the Registry module. To use the local
  module, change `source` to `../..` and remove `version`.
- The module does not configure TLS listeners or log collection and delivery.
- With Provider `v0.0.72`, a listener delete may return
  `GeneralServiceException: delete failed` and retain its state entry. Confirm
  the cloud listener is absent before reviewing another destroy plan and
  cleaning up remaining resources. See the [module notes](../../README.md#9-notes).
- When the example resources are no longer needed, review
  `terraform plan -destroy` before running `terraform destroy`. This removes
  only the example's NLB, listener, and server group. Manage caller-owned
  network and backend resources separately.
- Supply credentials through provider-supported configuration, not source files.
