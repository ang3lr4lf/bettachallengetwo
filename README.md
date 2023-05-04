# AWS S3 IaC - BettaCloud Challenge Two

This Terraform code allows building an infrastructure based on S3 buckets for the client 'Project X'. Each bucket is deployed along with a replica in a different region for disaster recovery purposes. Buckets can be public or private and have an independent lifecycle configuration. Public buckets are used to host static websites.

## Instructions

Assign the variables 'privateBucketsList' and 'publicBucketsList' with the list of names of all private and public (static web hosting) buckets, respectively (preferably in `terraform.tfvars`). Example:

```hcl
...
privateBucketsList = ["challenge-two-payment", "challenge-two-checkout"]
publicBucketsList  = ["challenge-two-product"]
...

```

For each lifecycle configuration that you want to assign to one of the buckets, you must generate a variable with the name that you want to assign to the configuration and the body of the configuration (preferably in `terraform.tfvars`). Example:

```hcl
...
lcRulesetOne = { life_cycle_rules = [
  {
    id     = "Rule One"
    status = "Enabled"
    abort_incomplete_multipart_upload = {
      days_after_initiation = 7
    }
    transition = {
      days          = 30
      storage_class = "GLACIER"
    }
    expiration = {
      days = 600
    }
    noncurrent_version_transition = {
      newer_noncurrent_versions = 2
      noncurrent_days           = 15
      storage_class             = "GLACIER"
    }
    noncurrent_version_expiration = {
      newer_noncurrent_versions = 2
      noncurrent_days           = 30
    }
    filter = {
      prefix = "some"
    }
  }
] }
...
```

Finally, edit the locals in the main.tf file. You should create an element for each bucket/lifecycleConfiguration combination and place it in the 'privateBucketsRules' or 'publicBucketsRules' group as appropriate. The elements should have the exact bucket name as the key and the name of the variable containing the rules you want to assign as the value. Example:


```hcl
...
locals {
  privateBucketsRules = {
    "challenge-two-checkout" = var.lcRulesetOne,
  }
  publicBucketsRules = {
    "challenge-two-product" = var.lcRulesetOne,
  }
}
...
```
