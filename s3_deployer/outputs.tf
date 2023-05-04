#Salida con los ARN de los buckets

output "main_bucket_arn" {
  #count = length(var.s3_bucket_names)
  value = aws_s3_bucket.main.*.arn
}

output "replica_bucket_arn" {
  #count = length(var.s3_bucket_names)
  value = aws_s3_bucket.replica.*.arn
}
