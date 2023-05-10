terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

resource "aws_vpc" "three-tie-app-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "three-tier-app-vpc"
  }
}

resource "aws_subnet" "public-subnet" {
  vpc_id = aws_vpc.three-tie-app-vpc.id
  cidr_block = "10.0.0.0/24"
  tags = {
    Name = "three-tier-app-public-subnet"
  }
}

resource "aws_subnet" "private-subnet" {
  vpc_id = aws_vpc.three-tie-app-vpc.id
  cidr_block = "10.0.1.0/24"
  tags = {
    Name = "three-tier-app-private-subnet"
  }
}

resource "aws_internet_gateway" "internet-gateway" {
  vpc_id = aws_vpc.three-tie-app-vpc.id
  tags = {
    Name = "three-tier-app-igw"
  }
}

resource "aws_route_table" "three-tier-app-route-public" {
  default_route_table_id = aws_vpc.three-tie-app-vpc.default_route_table_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet-gateway.id
  }
}


resource "aws_route_table" "three-tier-app-route-private" {
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet-gateway.id
  }
}