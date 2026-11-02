variable "vpc_id" {
  type        = string
  description = "Existing VPC ID."
}

variable "security_group_ids" {
  type        = set(string)
  description = "Existing security group IDs for the private NLB."
}

variable "zone_id" {
  type        = string
  description = "Availability zone ID for the NLB subnet."
}

variable "subnet_id" {
  type        = string
  description = "Existing subnet ID for the NLB."
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
