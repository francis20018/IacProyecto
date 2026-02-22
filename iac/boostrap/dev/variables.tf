variable "aws_region" {
  type        = string
  description = "Región AWS"
  default     = "us-east-1"
}

variable "project_name" {
  type        = string
  description = "Nombre del proyecto"
  default     = "pedidos-pagos"
}

variable "env" {
  type        = string
  description = "Entorno"
  default     = "dev"
}

variable "tags" {
  type        = map(string)
  description = "Tags base"
  default = {
    Project     = "pedidos-pagos"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}
