# Complete 公网多可用区 TCP/UDP NLB 示例

## 概述

本示例创建公网多可用区 NLB，每个可用区绑定调用方提供的独立 EIP，包含
TCP/UDP Server Group、协议健康检查、TCP 会话保持、TCP/UDP Listener 和跨可用区转发。

调用方负责管理 VPC、子网、安全组、EIP 和 ECS 后端。每个 EIP 只能被一个 NLB
配置管理。

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
| `security_group_ids` | 既有公网 NLB 安全组 ID。 |
| `zone_mappings` | 至少两个可用区的子网和独立 EIP 映射。 |
| `backend_instance_id` | ECS 后端实例 ID。 |
| `backend_private_ip` | ECS 后端私网 IPv4 地址。 |
| `name_suffix` | NLB、Listener 和 Server Group 的名称后缀，默认 `example`。 |

## 输出

| 名称 | 说明 |
|---|---|
| `load_balancer_id` | 模块创建的 NLB ID。 |
| `dns_name` | Provider 分配的 NLB 域名。 |
| `listener_ids` | 按逻辑键索引的 TCP/UDP Listener ID。 |

## 注意事项

- `zone_mappings` 至少包含两个不同可用区，每项提供所属子网和独立、可绑定的
  EIP。资源应位于 Provider 配置的地域，子网与安全组应属于指定 VPC。
- EIP 由调用方管理。NLB 绑定时会将其名称改为 `USED_BY_NLB.<NLB_ID>`，解绑后
  名称可能变为 EIP ID。若调用方通过 `volcenginecc_vpc_eip` 管理 EIP，应添加
  `lifecycle { ignore_changes = [name] }`，避免自动改名产生配置漂移。
- 后端应用需监听 TCP `7000` 和 UDP `9000`。NLB 和后端安全组、子网 ACL、
  主机防火墙应放通业务与健康检查流量；UDP 健康检查还需后端安全组放通 ICMP。
  示例不会创建或修改这些规则。
- TCP Listener 的连接空闲超时和 TCP Server Group 的会话保持超时均配置为
  `900` 秒；连接超时和会话保持是两个独立配置，应按业务需要分别调整。
- 示例从 Registry 安装 `~> 1.0` 范围内的模块版本；本地仓库改动不会自动反映到
  Registry 模块中。需要使用本地模块时，将 `source` 改为 `../..`，并移除
  `version`。
- 当前模块不提供 TLS 加密监听、证书、日志服务资源或自动日志采集与投递。
  如需日志服务或 VPC 流日志，应另行配置采集对象、投递目标和索引。
- 使用 Provider `v0.0.72` 时，Listener 删除可能报
  `GeneralServiceException: delete failed` 并留下 State。先确认云端 Listener
  已不存在，再重新查看销毁计划并清理剩余资源；处理步骤见
  [根模块注意事项](../../README.zh-CN.md#9-注意事项)。
- 不再使用示例资源时，先执行 `terraform plan -destroy` 核对范围，再执行
  `terraform destroy`。示例只删除其管理的 NLB、Listener 和 Server Group；
  EIP、VPC、子网、安全组和 ECS 的保留或释放由调用方单独处理。
- 凭据应通过 Provider 支持的配置提供，不要写入源文件。
