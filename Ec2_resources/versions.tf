terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
  }

  # Best practice: remote state with locking. Create the bucket + DynamoDB table first,
  # then uncomment.
  # backend "s3" {
  #   bucket         = "my-org-tfstate"
  #   key            = "ec2/dev/terraform.tfstate"
  #   region         = "ap-south-1"
  #   dynamodb_table = "tf-state-lock"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
      Owner       = var.owner
    }
  }
}
