locals {
  privateBucketsRules = {
    "challenge-two-checkout" = var.lcRulesetOne,
  }
  publicBucketsRules = {
    "challenge-two-product" = var.lcRulesetOne,
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
  s3_bucket_names    = var.publicBucketsList
  s3_bucket_policies = local.publicBucketsRules
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
  s3_bucket_names    = var.privateBucketsList
  s3_bucket_policies = local.privateBucketsRules
}
