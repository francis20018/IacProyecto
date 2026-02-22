output "tfstate_bucket_name" {
  value = aws_s3_bucket.tfstate.bucket
}

output "tf_lock_table_name" {
  value = aws_dynamodb_table.tf_lock.name
}

output "aws_region" {
  value = var.aws_region
}
