locals {
  private_buckets = {
    "challenge-two-checkout" = var.lc_ruleset1,
  }
  public_buckets = {
    "challenge-two-product" = var.lc_ruleset1,
  }
}

# Llama al modulo s3_deployer para crear todos los recursos
# relacionados con los buckets de tipo publico (web hosting)
module "public" {
  source = "./s3_deployer/"
  providers = {
    aws         = aws
    aws.replica = aws.replica
  }
  awsAccessKey       = var.awsAccessKey
  awsSecretKey       = var.awsSecretKey
  s3_private         = false
  s3_bucket_names    = ["challenge-two-product"]
  s3_bucket_policies = local.public_buckets
}

# Llama al modulo s3_deployer para crear todos los recursos
# relacionados con los buckets de tipo privado
module "private" {
  source = "./s3_deployer/"
  providers = {
    aws         = aws
    aws.replica = aws.replica
  }
  awsAccessKey       = var.awsAccessKey
  awsSecretKey       = var.awsSecretKey
  s3_private         = true
  s3_bucket_names    = ["challenge-two-payment", "challenge-two-checkout"]
  s3_bucket_policies = local.private_buckets
}
