terraform {
  backend "s3" {
    bucket  = "lanciere-terraform-state-657246200133"
    key     = "sap-training-lab/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
