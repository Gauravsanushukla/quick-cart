# backend.tf
terraform {
  backend "s3" {
    bucket         = "quickcart-tf-state-1601"   # Global unique bucket name
    key            = "prod/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "quickcart-tf-locks"
    encrypt        = true
  }
}