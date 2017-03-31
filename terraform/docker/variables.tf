###########################
###########################
###                     ###
###   Input Variables   ###
###                     ###
###########################
###########################
variable "access_key" {}
variable "secret_key" {}

variable "ami" {
  default = "ami-87b08fe1"
}

variable "availability_zone" {
  default = "b"
}

variable "base_instance" {
  default = "t2.micro"
}

variable "key_pair" {
  default = ""
}

variable "manager_instances" {
  default = 0
}

variable "manager_instance_types" {
  type = "map"
  default = {}
}

variable "manager_name" {
  default = "Docker manager"
}

variable "region" {
  default = "eu-west-1"
}

variable "worker_instances" {
  default = 1
}

variable "worker_instance_types" {
  type = "map"
  default = {}
}

variable "worker_name" {
  default = "Docker worker"
}
