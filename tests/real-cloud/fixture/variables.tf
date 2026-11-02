variable "region" {
  type        = string
  description = "Validation region."
  default     = "cn-beijing"
}

variable "instance_password" {
  type        = string
  description = "Temporary ECS login password."
  sensitive   = true
}

variable "vpc_id" {
  type        = string
  description = "Existing VPC used only for temporary validation resources."
}

variable "zone_mappings" {
  type = list(object({
    zone_id   = string
    subnet_id = string
  }))
  description = "Existing validation subnets in at least two availability zones."

  validation {
    condition     = length(var.zone_mappings) >= 2
    error_message = "The real-cloud fixture requires at least two zone mappings."
  }
}

variable "name_suffix" {
  type        = string
  description = "Unique suffix for temporary validation resources."
}
