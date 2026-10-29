output "instance_id" {
  description = "EC2 instance ID."
  value       = aws_instance.this.id
}

output "instance_private_ip" {
  description = "Private IP of the instance."
  value       = aws_instance.this.private_ip
}

output "instance_public_ip" {
  description = "Public IP (Elastic IP if enabled, otherwise the auto-assigned one)."
  value       = try(aws_eip.this[0].public_ip, aws_instance.this.public_ip)
}

output "ami_id" {
  description = "Ubuntu AMI used by the launch template."
  value       = aws_launch_template.this.image_id
}

output "launch_template_id" {
  description = "Launch template ID."
  value       = aws_launch_template.this.id
}

output "security_group_id" {
  description = "Instance security group ID."
  value       = aws_security_group.ec2.id
}

output "vpc_id" {
  description = "VPC ID."
  value       = aws_vpc.this.id
}

output "kms_key_arn" {
  description = "KMS key used for EBS and log encryption."
  value       = aws_kms_key.this.arn
}

output "ssm_session_command" {
  description = "Connect without SSH using Session Manager."
  value       = "aws ssm start-session --target ${aws_instance.this.id} --region ${var.aws_region}"
}
