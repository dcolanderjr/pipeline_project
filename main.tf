provider "aws" {
    region = "us-east-1"
}

module "ec2-sg" {
    source = "./ec2-sg"
}