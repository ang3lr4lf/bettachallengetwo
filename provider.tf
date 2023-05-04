terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.65"
    }
  }
}
# Define los proveedores que utilizará Terraform
provider "aws" {
  region     = "us-east-1"
  access_key = var.awsAccessKey
  secret_key = var.awsSecretKey
}

provider "aws" {
  alias      = "replica"
  region     = "us-west-1"
  access_key = var.awsAccessKey
  secret_key = var.awsSecretKey
}
