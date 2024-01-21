terraform {
  required_version = ">=1.5.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.9.0"
    }
  }
     backend "s3" {
       bucket = "s7remotestatelock"
       key = "terraform/remotestate/terraform.tfstate"
       region = "us-east-1"
       dynamodb_table = "s7table"
       encrypt = "true"
     }
}
