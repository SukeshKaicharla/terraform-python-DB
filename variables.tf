# AWS region
variable "region" {
  description = "AWS region for deployment"
  type        = string
}

# EC2 instance settings
variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "Type of EC2 instance"
  type        = string
}

variable "instance_name" {
  description = "Name tag for the EC2 instance"
  type        = string
}

# Security Group name
variable "sg_name" {
  description = "Security group name"
  type        = string
}
variable "key_name" {
  description = "Key pair name to create and use for EC2 SSH access"
  type        = string
  default     = "terraform-generated-key"
}
