provider "aws" {
  region = "eu-west-1"
}

terraform {
  backend "s3" {
    bucket = "wescale-slavayssiere-terraform"
    region = "eu-west-1"
    key    = "kubernetes/layer-bastion"
  }
}

data "terraform_remote_state" "layer-base" {
  backend = "s3"

  config {
    bucket = "${var.bucket_layer_base}"
    region = "eu-west-1"
    key    = "kubernetes/layer-base"
  }
}

variable "bucket_layer_base" {
  default = "wescale-slavayssiere-terraform"
}

variable "public_dns" {
  default = "aws-wescale.slavayssiere.fr."
}
