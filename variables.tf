############################
# General
############################
variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "ap-south-1"
}

variable "project" {
  description = "Project name, used as a prefix for resource names."
  type        = string
  default     = "demo"
}

variable "environment" {
  description = "Environment name (dev, stage, prod)."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "stage", "prod"], var.environment)
    error_message = "environment must be one of: dev, stage, prod."
  }
}

variable "owner" {
  description = "Owner / team tag."
  type        = string
  default     = "devops"
}

############################
# Networking
############################
variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (one per AZ)."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (one per AZ)."
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "enable_nat_gateway" {
  description = "Create a single NAT gateway so private subnets have outbound internet (costs money)."
  type        = bool
  default     = false
}

variable "enable_flow_logs" {
  description = "Enable VPC flow logs to CloudWatch."
  type        = bool
  default     = true
}

############################
# Access / Security
############################
variable "place_in_public_subnet" {
  description = "Place the instance in a public subnet with a public IP. Set false to use a private subnet (needs NAT or VPC endpoints for SSM)."
  type        = bool
  default     = true
}

variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed to SSH (port 22). Leave empty to disable SSH and use SSM Session Manager only."
  type        = list(string)
  default     = []

  validation {
    condition     = !contains(var.allowed_ssh_cidrs, "0.0.0.0/0")
    error_message = "Do not open SSH to 0.0.0.0/0. Use your own /32 or SSM Session Manager."
  }
}

variable "allowed_http_cidrs" {
  description = "CIDR blocks allowed to reach HTTP/HTTPS (80/443)."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "key_name" {
  description = "Existing EC2 key pair name (only needed if you enable SSH). Null = no key pair."
  type        = string
  default     = null
}

############################
# Compute
############################
variable "instance_name" {
  description = "Value of the Name tag for the EC2 instance."
  type        = string
  default     = "web-server"
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.micro"
}

variable "ubuntu_version" {
  description = "Ubuntu LTS release for the AMI (e.g. 22.04, 24.04)."
  type        = string
  default     = "24.04"
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed (1-minute) CloudWatch monitoring."
  type        = bool
  default     = false
}

variable "associate_elastic_ip" {
  description = "Attach an Elastic IP (only when in a public subnet)."
  type        = bool
  default     = false
}

############################
# Storage
############################
variable "root_volume_size" {
  description = "Root EBS volume size in GiB."
  type        = number
  default     = 20
}

variable "root_volume_type" {
  description = "Root EBS volume type."
  type        = string
  default     = "gp3"
}

variable "data_volume_size" {
  description = "Additional data EBS volume size in GiB. 0 = no data volume."
  type        = number
  default     = 0
}

variable "data_volume_type" {
  description = "Data EBS volume type."
  type        = string
  default     = "gp3"
}
