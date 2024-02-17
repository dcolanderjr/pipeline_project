# Backend for storing the state file in S3 bucket

terraform {
  backend "s3" {                            
    bucket = "pipe-line-project"         
    key    = "terraform.tfstate"           
    region = "us-east-1"                 
  }
}