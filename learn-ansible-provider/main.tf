terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
    ansible = {
      version = "~> 1.0.0"
      source  = "ansible/ansible"
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
  map_public_ip_on_launch = true
  tags = {
    Name = "terraform-playground-public-subnet"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.terraform-playground-vpc.id

  tags = {
    Name = "terraform-playground"
  }
}

data aws_ssm_parameter amzn2_ami {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "role" {
  name               = "AmazonSSMManagedInstanceCoreRole"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy" "systems_manager" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "default" {
  role       = aws_iam_role.role.name
  policy_arn = data.aws_iam_policy.systems_manager.arn
}

resource "aws_iam_instance_profile" "systems_manager" {
  name = "AmazonSSMManagedInstanceCoreProfile"
  role = aws_iam_role.role.name
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.terraform-playground-vpc.id
  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route" "public" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route_table_association" "public-subnet-route-table-association" {
  subnet_id      = aws_subnet.terraform-playground-public-subnet.id
  route_table_id = aws_route_table.public.id
}


resource "aws_instance" "app-server" {
  ami           = data.aws_ssm_parameter.amzn2_ami.value
  instance_type = "t2.micro"
  subnet_id = aws_subnet.terraform-playground-public-subnet.id
  associate_public_ip_address = true
  iam_instance_profile = aws_iam_instance_profile.systems_manager.name
  tags = {
    Name = "app-server"
  }
}

resource "ansible_host" "ansible-host-server" {
  name   = aws_instance.app-server.public_dns
  variables = {
    ansible_user                 = "ansible",
    ansible_ssh_private_key_file = "~/.ssh/id_rsa",
    ansible_python_interpreter   = "/usr/bin/python3"
  }
}