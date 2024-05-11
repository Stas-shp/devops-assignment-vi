variable "aws_region" {
    type = string
    default = "eu-central-1"
}

variable "vpc_name" {
    type = string
    default = "vi-vpc"
}

variable "mongo_pass" {
  type      = string
  sensitive = true
}
