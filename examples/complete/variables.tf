variable "vpc_id" {
  type        = string
  description = "Existing VPC ID."
}

variable "security_group_ids" {
  type        = set(string)
  description = "Existing security group IDs for the public NLB."
}

variable "zone_mappings" {
  type = list(object({
    zone_id      = string
    subnet_id    = string
    ipv_4_eip_id = string
  }))
  description = "At least two existing subnet and independently managed EIP pairs, one for each NLB availability zone."

  validation {
    condition     = length(var.zone_mappings) >= 2
    error_message = "The multi-AZ example requires at least two zone mappings."
  }
}

variable "backend_instance_id" {
  type        = string
  description = "Existing ECS backend instance ID."
}

variable "backend_private_ip" {
  type        = string
  description = "Private IPv4 address of the backend instance."
}

variable "name_suffix" {
  type        = string
  description = "Unique suffix used in disposable resource names."
  default     = "example"
}
