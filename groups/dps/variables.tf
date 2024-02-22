variable "ami_owner_id" {
  type        = string
  description = "The AMI owner ID"
}

variable "ami_version_pattern" {
  type        = string
  description = "The pattern to use when filtering for AMI version by name"
  default     = "*"
}

variable "application_subnet_pattern" {
  type        = string
  description = "The pattern to use when filtering for application subnets by 'Name' tag"
  default     = "sub-application-*"
}

variable "aws_account" {
  type        = string
  description = "The name of the AWS account; used in Vault path when looking up account identifier"
}

variable "default_log_retention_in_days" {
  type        = string
  description = "The default log retention period in days for CloudWatch log groups"
  default     = 7
}

variable "dns_zone_suffix" {
  type        = string
  description = "The common DNS hosted zone suffix used across accounts"
  default     = "heritage.aws.internal"
}

variable "dps_log_groups" {
  type = list(object({
    name : string,
    log_retention_in_days : optional(number),
    kms_key_id : optional(string),
  }))
  description = "A list of objects representing log groups. Each object is expected to have at a minimum a 'name' key. Optional 'log_retention_in_days' and 'kms_key_id' attributes can be set to override the default values."
  default     = []
}

variable "environment" {
  type        = string
  description = "The environment name to be used when creating AWS resources"
}

variable "informix_services" {
  type        = map(number)
  description = "A map whose key-value pairs represent Informix servers and associated port numbers"
  default = {
    dps = 6000
  }
}

variable "instance_count" {
  type        = number
  description = "The number of instances to create"
  default     = 1
}

variable "instance_type" {
  type        = string
  description = "The instance type to use"
  default     = "t3.small"
}

variable "lvm_block_devices" {
  type = list(object({
    aws_volume_size_gb : string,
    filesystem_resize_tool : string,
    lvm_logical_volume_device_node : string,
    lvm_physical_volume_device_node : string,
  }))
  description = "A list of objects representing LVM block devices; each LVM volume group is assumed to contain a single physical volume and each logical volume is assumed to belong to a single volume group; the filesystem for each logical volume will be expanded to use all available space within the volume group using the filesystem resize tool specified; block device configuration applies only on resource creation. Set the 'filesystem_resize_tool' and 'lvm_logical_volume_device_node' fields to empty strings if the block device contains no filesystem and should be excluded from the automatic filesystem resizing, such as when the block device represents a swap volume"
  default     = []
}

variable "region" {
  type        = string
  description = "The AWS region in which resources will be administered"
}

variable "root_volume_size" {
  type        = number
  description = "The size of the root volume in gibibytes (GiB)"
  default     = 20
}

variable "service" {
  type        = string
  description = "The service name to be used when creating AWS resources"
  default     = "dps"
}

variable "ssh_master_public_key" {
  type        = string
  description = "The SSH master public key; EC2 instance connect should be used for regular connectivity"
}
