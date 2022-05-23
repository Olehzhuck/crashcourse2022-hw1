variable "region" {
    type = string
    default = "us-east-1"
}

variable "instance_type" {
    type = string
    default = "t2.micro"
}

variable "game_instance_count" {
    type = string
    default = "3"
}

variable "game_volume_size" {
    type = string
    default = "20"
}

variable "nginx_volume_size" {
    type = string
    default = "15"
}

variable "ssh_ip" {
    type = list(string)
    default = ["188.163.121.26/32"]
}

variable "jenkins_ip" {
    type = list(string)
    default = ["193.240.154.0/24"]
}

variable "allow_vpc_cidr" {
    type = list(string)
    default = ["10.0.0.0/16"]
}

variable "vpc_cidr" {
    type = string
    default = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
    type = list(string)
    default = ["10.0.10.0/24"]
}

variable "private_subnet_cidrs" {
    type = list(string)
    default = ["10.0.9.0/24"]
}