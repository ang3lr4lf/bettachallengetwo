terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 4.65"
      configuration_aliases = [aws.replica]
    }
  }
}
