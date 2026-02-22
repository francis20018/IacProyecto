data "aws_caller_identity" "current" {}

locals {
  name_prefix    = "${var.project_name}-${var.env}"
  account_suffix = data.aws_caller_identity.current.account_id

  # Bucket debe ser globalmente único
  tfstate_bucket_name = "${local.name_prefix}-tfstate-${local.account_suffix}"
  lock_table_name     = "${local.name_prefix}-tf-lock"
}
