terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
  cloud {
    organization = "SDNLab3"

    workspaces {
      name = "SDNTerraformExp1"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  access_key = "ASIA57FNZQL4N5K4QOZ7"
  secret_key = "DU4i4v+oAUQ7fBmY7qlY3ls2RhJ3XdQeN9zn1qWv"
  token = "FwoGZXIvYXdzEDMaDPA9qKt286v03M/ylCLIAakrOk4mby9WqmweRc2MVdH6WlHteEmXt6PE46xEhrFe+itJL8H2emykRmlRgzlkYnCoef4S0a03+VMegOPevMRKxRmE0e3/U9ADGUZJjXis85UQ9w13G2JXSqXt982UJNbfRI4+mETlZ3bUQp5WXNeffWM+lyBgAgp+mLUHTAasJCds4yJS7yvcH/xrGPgBWnhmk9m+yVMo7RvaR91GgJfxQnXxgMykAO8V/O5zjuNVi0bfCNCXC67DluF+iz/oNE2YYhHbV9yQKP+266EGMi0qYA9M4tTgHJNFiXWnX9xaFqwTfAe1y0+AByIeiPc9G0SRZVGqT93Tuz2q6dc="
}

# Creation of VPC
resource "aws_vpc" "L3_vpc" {
  cidr_block = "192.168.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true
  tags = { Name = "L3_vpc" }
}

# Creation of Internet Gateway
resource "aws_internet_gateway" "L3_igw" {
  vpc_id = aws_vpc.L3_vpc.id
  tags = { Name = "L3_igw" }
}

resource "aws_eip" "lb" {
  vpc      = true
}


# Configuration of public routing table
resource "aws_route_table" "RT-public" {
  vpc_id = aws_vpc.L3_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.L3_igw.id
  }
  tags = { Name = "public access routing table" }
}


#Creation of public subnet
resource "aws_subnet" "SN-public-1" {
  vpc_id = aws_vpc.L3_vpc.id
  cidr_block = "192.168.1.0/24"
  map_public_ip_on_launch = true
  tags = { Name = "SN-public-1" }
}

# Association of public subnet with public routing table
resource "aws_route_table_association" "public" {
  subnet_id = aws_subnet.SN-public-1.id
  route_table_id = aws_route_table.RT-public.id
}


# Configuration of security group
resource "aws_security_group" "L3_SecGr" {
  name = "L3_SecGr"
  description = "allow web traffic and SSH"
  vpc_id = aws_vpc.L3_vpc.id
  ingress {
    description = "Allow all traffic"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Allow all traffic"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create EC2 instance in the public subnet
resource "aws_instance" "Workspace2" {
  ami = "ami-00c39f71452c08778"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.SN-public-1.id
  security_groups = [aws_security_group.L3_SecGr.id]
  key_name = "keys144"
  tags = { Name = "Workspace2" }
  user_data = <<-E0F
    #!/bin/bash 
    sudo yum update -y 
    sudo yum install httpd -y
    sudo systemctl enable httpd
    cd /var/www/html 
    echo "<html><body><h1> Hello from Xerxes, Aidan, Joseph
    and Rana at
    Workspace2
    at $(hostname -f) 
    </html></body></h1>" | sudo tee -a  index.html
    sudo systemctl restart httpd
    E0F
}
