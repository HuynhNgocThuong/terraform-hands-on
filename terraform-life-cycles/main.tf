provider "aws" {
  region = "us-west-2"
}

resource "aws_s3_bucket" "terraform-thuonghuynh-bucket" {
  bucket = "terraform-thuonghuynh-bucket-update"

  tags = {
    Name = "Terraform Series"
  }
}
