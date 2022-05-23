### Terraform Reourece ###

provider "aws" {
  region = var.region
}

terraform {
  backend "s3" {
     bucket = "terraform-state-crashcourse2022"
     key    = "infra/terraform.tfstate"
     region = "us-east-1"
  }
}

### SSH key ###

resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "demo"
  public_key = "${tls_private_key.key.public_key_openssh}"
}

###### Network ######

  ### VPC ###
data "aws_availability_zones" "available" {}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "internet_gateway"
  }
}

  ### Private Subnet ###
resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.9.0/24"
#   availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "subnet-private"
  }
}

  ### Public Subnet ###
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.10.0/24"
#   availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "subnet-public"
  }
}

  ### Route tables ###
resource "aws_route_table" "public_subnet" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = {
    Name = "route-public_subnets"
  }
}

resource "aws_route_table" "private_subnet" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = {
    Name = "route-public_subnets"
  }
}

resource "aws_route_table_association" "public_routes" {
  count          = length(aws_subnet.public_subnet[*].id)
  route_table_id = aws_route_table.public_subnet.id
  subnet_id      = element(aws_subnet.public_subnet[*].id, count.index)
}

resource "aws_route_table_association" "private_routes" {
  count          = length(aws_subnet.private_subnet[*].id)
  route_table_id = aws_route_table.private_subnet.id
  subnet_id      = element(aws_subnet.private_subnet[*].id, count.index)
}

###### Security Groups ######


resource "aws_security_group" "game-sg" {
  name        = "games"
  description = "Allow ports for Games"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_ip
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = "${var.jenkins_ip}"
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.allow_vpc_cidr
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "game-sec-group"
  }
}

resource "aws_security_group" "nginx-sg" {
  name        = "nginx"
  description = "Allow ports for Nginx"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_ip
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = "${var.jenkins_ip}"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.allow_vpc_cidr
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "nginx-sec-group"
  }
}

###### EC2 instances ######
  ### Private Network ###
resource "aws_instance" "game_instance" {
  ami           = "ami-09d56f8956ab235b3"
  instance_type = "t2.micro"
  count         = var.game_instance_count
  key_name      = "${aws_key_pair.generated_key.key_name}"
  subnet_id     = aws_subnet.private_subnet.id
  vpc_security_group_ids = [aws_security_group.game-sg.id]


  root_block_device {
    volume_size = var.game_volume_size
  }

  tags = {
    Name    = "game-${count.index + 1}"
    Owner   = "Oleh Lozhynskyi"
  }
}

  ### Public Network ###

resource "aws_instance" "nginx_instance" {
  ami           = "ami-09d56f8956ab235b3"
  instance_type = "t2.micro"
  key_name      = "${aws_key_pair.generated_key.key_name}"
  subnet_id     = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.nginx-sg.id]


  root_block_device {
    volume_size = var.nginx_volume_size
  }

  tags = {
    Name    = "nginx"
    Owner   = "Oleh Lozhynskyi"
  }
}


