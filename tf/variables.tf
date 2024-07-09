locals {
  env = "sbx"
  region = "us-west-2"
  zone1 = "us-west2a"
  zone2 = "us-west2b"
  eks_name = "demo"
  eks_version = "1.29"
  default_name = "${var.domain}-${var.function}-${var.environment}"
}

variable "name" {
  default     = "Default"
  type        = string
  description = "Name of the VPC"
}

variable "domain" {
  default     = "devops"
  type        = string
  description = "domain"
}

variable "function" {
  default     = "tf"
  type        = string
  description = "function"
}

variable "environment" {
  default     = "sbx"
  type        = string
  description = "Name of environment this VPC is targeting"
}

variable "region" {
  default     = "us-west-2"
  type        = string
  description = "Region of the VPC"
}

variable "cidr_block" {
  default     = "10.220.0.0/21"
  type        = string
  description = "CIDR block for the VPC"
}

variable "public_subnet_cidr_blocks" {
  default     = ["10.220.0.0/24", "10.220.1.0/24"]
  type        = list(any)
  description = "List of public subnet CIDR blocks"
}

variable "private_subnet_cidr_blocks" {
  default     = ["10.220.2.0/24", "10.220.3.0/24"]
  type        = list(any)
  description = "List of private subnet CIDR blocks"
}

variable "availability_zones" {
  default     = ["us-west-2a", "us-west-2b"]
  type        = list(any)
  description = "List of availability zones"
}

variable "tags" {
  default     = {}
  type        = map(string)
  description = "Extra tags to attach to the VPC resources"
}