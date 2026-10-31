############################
# General
############################
variable "aws_region" {
  description = "AWS region."
  type        = string
  default     = "ap-south-1"
}

variable "project" {
  description = "Project name, used in resource names."
  type        = string
  default     = "demo"
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "stage", "prod"], var.environment)
    error_message = "environment must be dev, stage or prod."
  }
}

############################
# Network (outputs of the vpc-terraform project)
############################
variable "vpc_id" {
  description = "ID of an existing VPC."
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for the ALB (at least 2, in different AZs)."
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_ids) >= 2
    error_message = "An ALB needs at least two subnets in different availability zones."
  }
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for the Auto Scaling group instances."
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_ids) >= 2
    error_message = "Provide at least two private subnets for high availability."
  }
}

############################
# Load balancer
############################
variable "alb_name" {
  description = "Short name for the load balancer (max 20 chars so the full name fits the 32 char AWS limit)."
  type        = string
  default     = "web"

  validation {
    condition     = length(var.alb_name) <= 20 && can(regex("^[a-zA-Z0-9-]+$", var.alb_name))
    error_message = "alb_name must be 20 characters or fewer and contain only letters, numbers and hyphens."
  }
}

variable "internal" {
  description = "true = internal ALB, false = internet-facing."
  type        = bool
  default     = false
}

variable "allowed_ingress_cidrs" {
  description = "CIDRs allowed to reach the ALB on 80/443."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "certificate_arn" {
  description = "ACM certificate ARN (same region). Leave null to run HTTP only (dev/testing)."
  type        = string
  default     = null
}

variable "ssl_policy" {
  description = "TLS policy for the HTTPS listener."
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "enable_deletion_protection" {
  description = "Protect the ALB from accidental deletion. Set true in prod."
  type        = bool
  default     = false
}

variable "enable_access_logs" {
  description = "Write ALB access logs to an S3 bucket created by this config."
  type        = bool
  default     = true
}

variable "access_log_retention_days" {
  description = "Days to keep ALB access logs in S3."
  type        = number
  default     = 90
}

############################
# Target group / health check
############################
variable "app_port" {
  description = "Port the application listens on."
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "HTTP path used for target health checks."
  type        = string
  default     = "/"
}

############################
# Launch template / Auto Scaling
############################
variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.micro"
}

variable "ubuntu_version" {
  description = "Ubuntu LTS version for the AMI."
  type        = string
  default     = "24.04"
}

variable "root_volume_size" {
  description = "Root EBS size in GiB."
  type        = number
  default     = 20
}

variable "asg_min_size" {
  description = "Minimum number of instances."
  type        = number
  default     = 2
}

variable "asg_max_size" {
  description = "Maximum number of instances."
  type        = number
  default     = 4
}

variable "asg_desired_capacity" {
  description = "Initial number of instances."
  type        = number
  default     = 2
}

variable "cpu_target_percent" {
  description = "Target average CPU for the scaling policy."
  type        = number
  default     = 60
}
