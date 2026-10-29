# EC2 on Ubuntu with Terraform

Production-style EC2 setup: VPC, launch template, hardened instance, encrypted storage, SSM access.

## What it creates

| File | Resources |
|---|---|
| `network.tf` | VPC, 2 public + 2 private subnets, IGW, route tables, optional NAT gateway, VPC flow logs, locked-down default SG |
| `security.tf` | Instance security group: 80/443 in, SSH only from CIDRs you list, minimal egress |
| `iam.tf` | IAM role + instance profile (SSM Session Manager, CloudWatch agent) |
| `kms.tf` | Customer-managed KMS key (rotation on) for EBS and log group |
| `compute.tf` | Ubuntu AMI lookup (Canonical SSM parameter), launch template, EC2 instance, optional Elastic IP |
| `user_data.sh.tftpl` | Patching, nginx, unattended-upgrades, optional data-disk mount at `/data` |

## Best practices applied

- Latest official Ubuntu AMI resolved through Canonical's SSM parameter, no hardcoded AMI IDs
- IMDSv2 required (`http_tokens = required`)
- All EBS volumes encrypted with a customer-managed KMS key
- SSH closed by default; access through SSM Session Manager (no bastion, no open port 22)
- Validation blocks SSH from `0.0.0.0/0`
- Default security group stripped of all rules
- Least-privilege egress, VPC flow logs, 30-day log retention
- `default_tags` on every resource; pinned provider version; remote-state backend block ready to enable

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars   # edit values
terraform init
terraform fmt -check && terraform validate
terraform plan -out=tfplan
terraform apply tfplan

# connect without SSH
aws ssm start-session --target <instance_id> --region ap-south-1
```

## Notes

- `t3.*` is x86_64. For Graviton (`t4g.*`) change the AMI path in `compute.tf` from `amd64` to `arm64`.
- `private_subnet_cidrs` and `public_subnet_cidrs` must not have more entries than the region has AZs.
- To place the instance in a private subnet set `place_in_public_subnet = false` and `enable_nat_gateway = true` (or add SSM VPC endpoints), otherwise SSM cannot reach the instance.
- The AMI parameter always points at the newest image, so a new Ubuntu release can trigger instance replacement on the next `plan`. Pin the AMI ID if you need stability.
- Enable the S3 + DynamoDB backend in `versions.tf` before using this in a team.
- NAT gateway and Elastic IPs cost money; both are off by default.
