output "alb_dns_name" {
  description = "DNS name of the load balancer. Point a CNAME/alias record here."
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "Hosted zone ID of the ALB (for Route 53 alias records)."
  value       = aws_lb.this.zone_id
}

output "alb_arn" {
  description = "ALB ARN."
  value       = aws_lb.this.arn
}

output "app_url" {
  description = "URL to test."
  value       = "${local.has_https ? "https" : "http"}://${aws_lb.this.dns_name}"
}

output "target_group_arn" {
  description = "Target group ARN."
  value       = aws_lb_target_group.app.arn
}

output "alb_security_group_id" {
  description = "ALB security group ID."
  value       = aws_security_group.alb.id
}

output "app_security_group_id" {
  description = "Instance security group ID."
  value       = aws_security_group.app.id
}

output "launch_template_id" {
  description = "Launch template ID."
  value       = aws_launch_template.app.id
}

output "autoscaling_group_name" {
  description = "Auto Scaling group name."
  value       = aws_autoscaling_group.app.name
}

output "access_logs_bucket" {
  description = "S3 bucket receiving ALB access logs (null if disabled)."
  value       = try(aws_s3_bucket.alb_logs[0].id, null)
}
