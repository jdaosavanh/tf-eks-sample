terraform {
  backend "s3" {
    bucket   = "devops-tf-global-bucket"
    key      = "terraform-example/eks/terraform.tfstate"
    region   = "us-west-2"
    dynamodb_table = "devops-tf-global-dynamodb"
  }
}