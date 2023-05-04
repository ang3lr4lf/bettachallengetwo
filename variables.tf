variable "awsAccessKey" {
  type = string
}

variable "awsSecretKey" {
  type = string
}

variable "privateBucketsList" {
  type = list(any)
}

variable "publicBucketsList" {
  type = list(any)
}

variable "lcRulesetOne" {
  type = any
}
