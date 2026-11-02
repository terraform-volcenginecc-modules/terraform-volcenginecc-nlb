# Basic 私网 TCP NLB 示例

## 概述

本示例创建一个私网单可用区 NLB、TCP Server Group、TCP 健康检查和 `8080`
TCP Listener。调用方需要提供 VPC、子网、安全组和 ECS 后端。

示例通过 Terraform Registry 安装
`terraform-volcenginecc-modules/nlb/volcenginecc`，版本约束为 `~> 1.0`。

## 用法

```shell
terraform init
terraform plan
terraform apply
```

执行前需配置 Provider 的认证与地域，并提供下表中的既有资源参数。

## 依赖要求

| 名称 | 版本 |
|---|---|
| Terraform | `= 1.5.7` |
| `volcengine/volcenginecc` | `>= 0.0.70, < 0.1.0` |

## 输入

| 名称 | 说明 |
|---|---|
| `vpc_id` | 既有 VPC ID。 |
| `security_group_ids` | 既有 NLB 安全组 ID。 |
| `zone_id` | NLB 所在可用区。 |
| `subnet_id` | NLB 所在子网 ID。 |
| `backend_instance_id` | ECS 后端实例 ID。 |
| `backend_private_ip` | ECS 后端私网 IPv4 地址。 |
| `name_suffix` | NLB 名称后缀，默认 `example`。 |

## 输出

| 名称 | 说明 |
|---|---|
| `load_balancer_id` | 模块创建的 NLB ID。 |
| `dns_name` | Provider 分配的 NLB 域名。 |

## 注意事项

- 本示例使用私网 IPv4 入口，不绑定公网 EIP。VPC、子网、安全组和 ECS 由调用方
  管理；子网与安全组应属于指定 VPC，`zone_id` 应与子网可用区一致。
- 后端应用需监听 TCP `8080`。NLB 和后端安全组、子网 ACL、主机防火墙应放通
  对应业务流量与 TCP 健康检查流量；示例不会创建或修改这些规则。
- 示例从 Registry 安装 `~> 1.0` 范围内的模块版本；本地仓库改动不会自动反映到
  Registry 模块中。需要使用本地模块时，将 `source` 改为 `../..`，并移除
  `version`。
- 当前模块不提供 TLS 加密监听或日志采集、投递配置。
- 使用 Provider `v0.0.72` 时，Listener 删除可能报
  `GeneralServiceException: delete failed` 并留下 State。先确认云端 Listener
  已不存在，再重新查看销毁计划并清理剩余资源；处理步骤见
  [根模块注意事项](../../README.zh-CN.md#9-注意事项)。
- 不再使用示例资源时，先执行 `terraform plan -destroy` 核对范围，再执行
  `terraform destroy`。这只删除示例管理的 NLB、Listener 和 Server Group，
  调用方的网络与后端资源仍需单独管理。
- 凭据应通过 Provider 支持的配置提供，不要写入源文件。
