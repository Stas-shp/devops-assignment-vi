variable "model_vpc_name" {}
variable "model_aws_region" {}
variable "model_mongo_pass" {
  type      = string
  sensitive = true
}
