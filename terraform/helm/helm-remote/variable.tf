variable "model_vpc_name" {
  type = string
}

variable "model_aws_region" {}

variable "model_mongo_pass" {
  type      = string
  sensitive = true
}

variable "eks_cluster_oidc_arn" {
  type = string
}
