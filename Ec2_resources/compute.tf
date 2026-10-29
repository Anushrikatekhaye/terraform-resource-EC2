############################
# Ubuntu AMI (Canonical's official SSM parameter - always the latest patched image)
############################
data "aws_ssm_parameter" "ubuntu_ami" {
  name = "/aws/service/canonical/ubuntu/server/${var.ubuntu_version}/stable/current/amd64/hvm/ebs-gp3/ami-id"
}

locals {
  subnet_id = var.place_in_public_subnet ? aws_subnet.public[0].id : aws_subnet.private[0].id

  user_data = templatefile("${path.module}/user_data.sh.tftpl", {
    hostname            = "${local.name_prefix}-${var.instance_name}"
    data_volume_enabled = var.data_volume_size > 0
  })
}

############################
# Launch template
############################
resource "aws_launch_template" "this" {
  name_prefix            = "${local.name_prefix}-${var.instance_name}-"
  description            = "Launch template for ${var.instance_name} (Ubuntu ${var.ubuntu_version})"
  image_id               = nonsensitive(data.aws_ssm_parameter.ubuntu_ami.value)
  instance_type          = var.instance_type
  key_name               = var.key_name
  ebs_optimized          = true
  vpc_security_group_ids = [aws_security_group.ec2.id]
  update_default_version = true
  user_data              = base64encode(local.user_data)

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2.name
  }

  # IMDSv2 only - blocks SSRF-style credential theft
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "disabled"
  }

  monitoring {
    enabled = var.enable_detailed_monitoring
  }

  # Root volume (encrypted with the customer-managed key)
  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size           = var.root_volume_size
      volume_type           = var.root_volume_type
      encrypted             = true
      kms_key_id            = aws_kms_key.this.arn
      delete_on_termination = true
    }
  }

  # Optional extra data volume
  dynamic "block_device_mappings" {
    for_each = var.data_volume_size > 0 ? [1] : []

    content {
      device_name = "/dev/sdf"

      ebs {
        volume_size           = var.data_volume_size
        volume_type           = var.data_volume_type
        encrypted             = true
        kms_key_id            = aws_kms_key.this.arn
        delete_on_termination = false # keep data if the instance is replaced
      }
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${local.name_prefix}-${var.instance_name}"
    }
  }

  tag_specifications {
    resource_type = "volume"
    tags = {
      Name = "${local.name_prefix}-${var.instance_name}-vol"
    }
  }

  tags = {
    Name = "${local.name_prefix}-${var.instance_name}-lt"
  }

  lifecycle {
    create_before_destroy = true
  }
}

############################
# EC2 instance
############################
resource "aws_instance" "this" {
  subnet_id                   = local.subnet_id
  associate_public_ip_address = var.place_in_public_subnet && !var.associate_elastic_ip

  launch_template {
    id      = aws_launch_template.this.id
    version = aws_launch_template.this.latest_version
  }

  tags = {
    Name = "${local.name_prefix}-${var.instance_name}"
  }

  depends_on = [
    aws_iam_role_policy_attachment.ssm,
    aws_iam_role_policy_attachment.cloudwatch_agent,
  ]
}

############################
# Optional Elastic IP
############################
resource "aws_eip" "this" {
  count = var.associate_elastic_ip && var.place_in_public_subnet ? 1 : 0

  domain   = "vpc"
  instance = aws_instance.this.id

  tags = {
    Name = "${local.name_prefix}-${var.instance_name}-eip"
  }

  depends_on = [aws_internet_gateway.this]
}
