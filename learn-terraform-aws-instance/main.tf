terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-west-2"
}

resource "aws_vpc" "terraform-playground-vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "terraform-playground-vpc"
  }
}

resource "aws_subnet" "terraform-playground-public-subnet" {
  vpc_id = aws_vpc.terraform-playground-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-west-2a"
  tags = {
    Name = "terraform-playground-public-subnet"
  }
}

resource "aws_instance" "app-server" {
  ami           = "ami-830c94e3"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.terraform-playground-public-subnet.id

  tags = {
    Name = "ExampleAppServerInstance"
  }
}
