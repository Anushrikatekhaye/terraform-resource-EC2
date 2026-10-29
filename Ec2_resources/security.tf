############################
# Security group for the instance
############################
resource "aws_security_group" "ec2" {
  name_prefix = "${local.name_prefix}-${var.instance_name}-"
  description = "Security group for ${var.instance_name}"
  vpc_id      = aws_vpc.this.id

  tags = {
    Name = "${local.name_prefix}-${var.instance_name}-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Inbound HTTP
resource "aws_vpc_security_group_ingress_rule" "http" {
  for_each = toset(var.allowed_http_cidrs)

  security_group_id = aws_security_group.ec2.id
  description       = "HTTP"
  cidr_ipv4         = each.value
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

# Inbound HTTPS
resource "aws_vpc_security_group_ingress_rule" "https" {
  for_each = toset(var.allowed_http_cidrs)

  security_group_id = aws_security_group.ec2.id
  description       = "HTTPS"
  cidr_ipv4         = each.value
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

# Inbound SSH only from explicitly allowed CIDRs (empty by default -> SSM only)
resource "aws_vpc_security_group_ingress_rule" "ssh" {
  for_each = toset(var.allowed_ssh_cidrs)

  security_group_id = aws_security_group.ec2.id
  description       = "SSH from trusted CIDR"
  cidr_ipv4         = each.value
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
}

# Outbound: HTTPS (package repos, SSM endpoints) and HTTP (apt mirrors)
resource "aws_vpc_security_group_egress_rule" "https" {
  security_group_id = aws_security_group.ec2.id
  description       = "HTTPS out"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "http" {
  security_group_id = aws_security_group.ec2.id
  description       = "HTTP out (apt mirrors)"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "dns_udp" {
  security_group_id = aws_security_group.ec2.id
  description       = "DNS out (VPC resolver)"
  cidr_ipv4         = var.vpc_cidr
  from_port         = 53
  to_port           = 53
  ip_protocol       = "udp"
}

resource "aws_vpc_security_group_egress_rule" "dns_tcp" {
  security_group_id = aws_security_group.ec2.id
  description       = "DNS out TCP (VPC resolver)"
  cidr_ipv4         = var.vpc_cidr
  from_port         = 53
  to_port           = 53
  ip_protocol       = "tcp"
}
