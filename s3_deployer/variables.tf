variable "awsAccessKey" {
  type = string
}

variable "awsSecretKey" {
  type = string
}

variable "s3_private" {
  type = bool
}

variable "s3_bucket_names" {
  type = list(any)
}

variable "s3_bucket_policies" {
  type = any
}
