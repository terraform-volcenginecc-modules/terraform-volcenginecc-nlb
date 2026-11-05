# terraform-volcenginecc-nlb

基于 `volcenginecc` Provider 的 Terraform 模块，用于创建并管理火山引擎 NLB、
TCP/UDP Server Group、健康检查、后端服务器和 TCP/UDP Listener。

## 1. 概述

本模块用于在火山引擎上配置 TCP/UDP 四层负载均衡，适用于长连接网关、即时通信、
游戏服务和数据库代理等场景。支持公网或私网、单可用区或多可用区部署，统一管理
NLB、监听器、服务器组、后端注册和健康检查，并提供跨可用区转发、会话保持、
连接超时及连接排空配置。

调用方通过子网映射、服务器组和监听器配置定义流量入口与后端转发关系，并负责管理
VPC、子网、安全组、EIP 和后端 ECS。公网 IPv4 入口需为每个可用区提供独立 EIP。
当前模块仅支持 TCP/UDP 监听，不包含 TLS 加密监听及日志采集、投递配置。

## 2. 用法

```hcl
module "nlb" {
  source  = "terraform-volcenginecc-modules/nlb/volcenginecc"
  version = "~> 1.0"

  load_balancer_name = "private-tcp-entry"
  vpc_id             = "vpc-xxxxxxxx"
  security_group_ids = ["sg-xxxxxxxx"]
  zone_mappings = [{
    zone_id   = "cn-beijing-a"
    subnet_id = "subnet-xxxxxxxx"
  }]

  server_groups = {
    app = {
      name     = "app-tcp"
      protocol = "TCP"
      servers = {
        app_1 = {
          instance_id = "i-xxxxxxxx"
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

Provider 的认证与地域由调用方配置。请通过环境变量、profile 或 Provider 支持
的其他凭据来源提供认证信息，不要把访问密钥写入配置文件。

## 3. 示例

- `examples/basic`：私网单可用区 TCP NLB。
- `examples/complete`：公网多可用区 NLB，包含 TCP/UDP Listener、协议健康检查、
  TCP 会话保持与跨可用区转发。

## 4. 版本要求

| 名称 | 版本 |
|---|---|
| Terraform | `= 1.5.7` |
| `volcengine/volcenginecc` | `>= 0.0.70, < 0.1.0` |

## 5. Provider

| 名称 | 版本 |
|---|---|
| `volcengine/volcenginecc` | `>= 0.0.70, < 0.1.0` |

## 6. 资源

| 类型 | 名称 |
|---|---|
| NLB | `volcenginecc_clb_nlb.this` |
| NLB Server Group | `volcenginecc_clb_nlb_server_group.this` |
| NLB Listener | `volcenginecc_clb_nlb_listener.this` |

## 7. 输入

| 名称 | 是否必填 | 说明 |
|---|---:|---|
| `load_balancer_name` | 是 | NLB 名称。 |
| `vpc_id` | 是 | 既有 VPC ID。 |
| `security_group_ids` | 是 | 既有 NLB 安全组 ID。 |
| `zone_mappings` | 是 | 每个可用区的子网映射。 |
| `ipv_4_network_type` | 否 | `intranet` 或 `internet`，默认 `intranet`。 |
| `ip_address_version` | 否 | NLB 地址族：`ipv4` 或 `dualstack`，默认 `ipv4`。 |
| `ipv_6_network_type` | 否 | 双栈 NLB 的 IPv6 网络类型，默认 `null`。 |
| `ipv_4_bandwidth_package_id` | 否 | 调用方持有的 IPv4 共享带宽包 ID，默认 `null`。 |
| `ipv_6_bandwidth_package_id` | 否 | 调用方持有的 IPv6 共享带宽包 ID，默认 `null`。 |
| `cross_zone_enabled` | 否 | 是否启用跨可用区转发，默认 `true`。 |
| `description` | 否 | NLB 描述，默认空字符串。 |
| `project_name` | 否 | NLB 所属项目，默认 `default`。 |
| `modification_protection_status` | 否 | `NonProtection` 或 `ConsoleProtection`，默认 `NonProtection`。 |
| `tags` | 否 | 应用于所有管理资源的公共标签。 |
| `server_groups` | 否 | 使用稳定逻辑键管理的 Server Group、后端与健康检查，默认 `{}`。 |
| `listeners` | 否 | 使用稳定逻辑键管理的 TCP/UDP Listener，默认 `{}`。 |

## 8. 输出

| 名称 | 说明 |
|---|---|
| `load_balancer_id` | NLB ID。 |
| `dns_name` | Provider 分配的 NLB 域名。 |
| `server_group_ids` | 按逻辑键索引的 Server Group ID。 |
| `listener_ids` | 按逻辑键索引的 Listener ID。 |

## 9. 注意事项

- 当前模块仅支持 TCP/UDP Listener，不提供 TLS 加密监听、证书配置、日志服务资源
  或自动日志采集与投递。如需日志服务或 VPC 流日志，请另行配置采集对象、投递目标
  和索引。
- VPC、子网、安全组、EIP 和后端实例应位于 Provider 配置的地域；子网和安全组
  应属于传入的 VPC，`zone_id` 应与对应子网的可用区一致。
- 公网 NLB 需要设置 `ipv_4_network_type = "internet"`，并为每个
  `zone_mappings` 项传入独立、可绑定的 `ipv_4_eip_id`。模块不会创建、接管或释放
  EIP；删除 NLB 后，调用方仍需按 EIP 自身的生命周期决定是否释放。
- NLB 绑定会将 EIP 名称改为 `USED_BY_NLB.<NLB_ID>`，解绑后名称可能变为 EIP ID。
  调用方管理的 `volcenginecc_vpc_eip` 应配置
  `lifecycle { ignore_changes = [name] }`，避免平台自动改名产生配置漂移。
  创建时仍使用配置名称，后续 `name` 变更将被忽略；其他 EIP 属性仍由 Terraform
  管理。
- `server_groups` 和 `listeners` 使用稳定 map 键；变更键会改变 Terraform 地址，
  并可能重建关联资源。每个 Listener 的 `server_group_key` 必须指向已定义的
  Server Group，且两者的 TCP/UDP 协议必须一致。
- 后端应用需监听配置的后端端口；NLB 安全组、后端安全组、子网 ACL 和主机防火墙
  应允许业务流量与健康检查流量。UDP 健康检查还需要后端安全组放通 ICMP。
- 非全端口 Server Group 中，健康检查端口 `0` 会被规范化为省略该字段，因为 API
  将默认值回读为 `null`。全端口 Server Group 必须显式设置 `1` 至 `65535` 的健康
  检查端口。
- 使用 Provider `v0.0.72` 时，Listener 删除任务可能返回
  `GeneralServiceException: delete failed`，即使云端 Listener 已被删除，
  Terraform 仍可能保留对应 State。遇到此错误，先确认云端 Listener 是否存在；
  仅在确认不存在后，重新执行 `terraform plan -destroy`，核对删除范围，再执行
  `terraform destroy` 清理剩余资源。若 Listener 仍存在，应先排查删除任务；
  不要仅为消除报错而手工移除 State。
- 已有 NLB 可以按 NLB ID 导入。模块不接管部分由其他配置管理的 NLB。
