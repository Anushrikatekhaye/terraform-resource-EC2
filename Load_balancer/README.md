# Application Load Balancer with Terraform

An internet-facing Application Load Balancer in front of an Auto Scaling group of Ubuntu instances built from a launch template. It plugs into the `vpc-terraform` project (use its outputs as inputs here).

## Architecture

```
Internet
   |  80 (redirect) / 443
[ALB  - public subnets, alb-sg]
   |  app port, only from alb-sg
[Target group, health checks]
   |
[ASG - private subnets, app-sg]  <- launch template (Ubuntu 24.04, nginx)
```

## Files

| File | Purpose |
|---|---|
| `alb.tf` | ALB, target group, HTTP and HTTPS listeners |
| `security.tf` | ALB security group and instance security group (SG-to-SG rules) |
| `compute.tf` | Ubuntu AMI lookup, SSM IAM role, launch template, Auto Scaling group, CPU scaling policy |
| `logs.tf` | Private encrypted S3 bucket for ALB access logs with lifecycle expiry |
| `variables.tf`, `outputs.tf`, `versions.tf` | Inputs, outputs, provider pinning, backend |
| `terraform.tfvars.example` | Copy to `terraform.tfvars` |

## Best practices applied

- ALB in public subnets across at least two AZs; instances in private subnets
- Instances accept traffic only from the ALB security group, never from the internet
- HTTPS with a modern TLS 1.3 policy; port 80 redirects to 443 when a certificate is set
- `drop_invalid_header_fields`, HTTP/2, deletion protection toggle for prod
- Target group health checks plus ASG `ELB` health check, so unhealthy instances are replaced
- Launch template with IMDSv2 only, encrypted gp3 root volume, detailed monitoring
- Rolling instance refresh when the launch template changes
- Target-tracking scaling on CPU
- Access logs in S3: public access blocked, SSE-S3, HTTPS-only policy, versioning, 90-day expiry
- SSM Session Manager instead of SSH
- Pinned versions, `default_tags`, consistent `<project>-<env>-<name>` naming

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars   # fill in vpc/subnet IDs
terraform init
terraform fmt -recursive
terraform validate
terraform plan -out=tfplan
terraform apply tfplan

curl $(terraform output -raw app_url)   # refresh a few times: the instance ID changes
```

## Enabling HTTPS

1. Request a certificate in ACM in the same region and validate it via DNS.
2. Set `certificate_arn` in `terraform.tfvars` and apply.
3. Create a Route 53 alias record pointing your domain at `alb_dns_name` / `alb_zone_id`.

## Notes

- The ALB needs at least two public subnets in different AZs.
- The private instances need a NAT gateway (or VPC endpoints) to install nginx and reach SSM.
- Access logs only work in regions supported by `aws_elb_service_account`. Newer opt-in regions need a different log-delivery principal.
- Run `terraform destroy` when you finish practicing; the ALB and NAT gateway bill hourly.
