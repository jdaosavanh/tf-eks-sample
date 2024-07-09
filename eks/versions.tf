terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.49"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = local.region
  default_tags {
    tags = {
      Naming-pattern   = local.default_name
    }
  }
}